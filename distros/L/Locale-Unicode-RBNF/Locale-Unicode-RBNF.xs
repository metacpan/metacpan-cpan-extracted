/*---------------------------------------------------------------------------
 * Locale::Unicode::RBNF - ~/Locale-Unicode-RBNF.xs
 * Version v0.1.0
 * Copyright(c) 2026 DEGUEST Pte. Ltd.
 * Author: Jacques Deguest <jack@deguest.jp>
 * Created  2026/10/22
 * Modified 2026/10/22
 *
 * XS implementations of keys functions for Locale-Unicode-RBNF.
 *
 * This program is free software; you can redistribute  it  and/or  modify  it
 * under the same terms as Perl itself.
 *---------------------------------------------------------------------------*/
/*
 * Parsing engine of Locale::Unicode::RBNF in C.
 * This is a port of the parse code paths of ICU4C 79.1 (NFRuleSet::parse, NFRule::doParse, 
 * NFRule::matchToDelimiter, NFRule::findText, NFRule::findTextLenient,
 * NFRule::prefixLength, NFSubstitution::doParse and its overrides, 
 * PluralFormat::parseType). It mirrors the pure-Perl implementation of this
 * distribution, which remains the fallback. Formatting is not done here.
 *
 * The rules are compiled from the Perl objects into flat arrays by
 * Locale::Unicode::RBNF::_xs_engine(). Strings are held as arrays of code points so that
 * positions are counted in characters, as in Perl.
 *
 * Unicode properties that are not trivial for ASCII (simple case folding, separators, NFC
 * boundaries, NFC normalisation and decimal digit values) are obtained from Perl callbacks
 * and cached per code point.
 */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_utf8_to_uvchr_buf
#include "ppport.h"
#include <math.h>
#include <float.h>
#include <string.h>

#define RECURSION_LIMIT 64
#define NON_NUMERICAL_RULE_LENGTH 6

/* Rule types, as in NFRule::ERuleType */
#define RULE_INFINITY -5
#define RULE_NAN -6

/* Substitution types */
#define SUB_SAME_VALUE 0
#define SUB_MULTIPLIER 1
#define SUB_MODULUS 2
#define SUB_INTEGRAL_PART 3
#define SUB_FRACTIONAL_PART 4
#define SUB_ABSOLUTE_VALUE 5
#define SUB_NUMERATOR 6

/* kMaxDouble in rbnf.cpp */
#define K_MAX_DOUBLE ( 4194304.0 * 4194304.0 )

typedef struct
{
    const U32 *s;
    IV len;
} uview;

typedef struct
{
    IV index;
    IV error;
} ppos_t;

typedef struct
{
    U32 *s;
    IV len;
} ustr;

typedef struct
{
    IV base;
    ustr text;
    int sub1;
    int sub2;
    int plural;
    /* For a rule with a plural pattern, the position of "$(" and the one following ")$" */
    IV pl_start;
    IV pl_suffix;
} rule_t;

typedef struct
{
    int type;
    IV pos;
    int rs;
    int nf;
    double divisor;
    int rule_to_use;
    int by_digits;
    int with_zeros;
    double denominator;
} sub_t;

typedef struct
{
    int is_fraction;
    int is_public;
    int is_parseable;
    int nrules;
    int *rules;
    int nnr[ NON_NUMERICAL_RULE_LENGTH ];
} ruleset_t;

typedef struct
{
    int n;
    ustr *variants;
} plural_t;

typedef struct
{
    ustr pos_prefix;
    ustr pos_suffix;
    int has_negative;
    ustr neg_prefix;
    ustr neg_suffix;
    ustr minus;
    ustr decimal;
    ustr group;
    ustr infinity;
    int grouping;
    int group_is_space;
    int multiplier_exp;
} numfmt_t;

/* Open addressing map from a code point to an integer, used as cache for the callbacks. */
typedef struct
{
    U32 *keys;
    I32 *vals;
    char *used;
    IV cap;
    IV n;
} cpmap;

/* Prepared rule text prefix for lenient matching: NFC characters, their folding, and whether
 * each one is a separator. Keyed by the address and length of the prefix, which always points
 * into the memory of the engine.
 */
typedef struct
{
    const U32 *key;
    IV key_len;
    IV n;
    U32 *folded;
    char *sep;
    int all_sep;
} pinfo_t;

typedef struct
{
    int nrulesets;
    ruleset_t *rulesets;
    int nrules;
    rule_t *rules;
    int nsubs;
    sub_t *subs;
    int nplurals;
    plural_t *plurals;
    int nnumfmts;
    numfmt_t *numfmts;
    int default_nf;
    int turkic;
    int lenient;
    SV *cb_fold;
    SV *cb_sep;
    SV *cb_boundary;
    SV *cb_nfc;
    SV *cb_digit;
    cpmap fold_cache;
    cpmap sep_cache;
    cpmap boundary_cache;
    cpmap digit_cache;
    pinfo_t *pinfos;
    IV npinfos;
    IV cap_pinfos;
    /* Hash index over pinfos: slot value is the index plus 1, 0 when empty */
    IV *pinfo_slots;
    IV pinfo_slot_cap;
} engine_t;

/* NOTE: code point map */
static void cpmap_init( cpmap *m )
{
    m->cap = 256;
    m->n = 0;
    Newxz( m->keys, m->cap, U32 );
    Newxz( m->vals, m->cap, I32 );
    Newxz( m->used, m->cap, char );
}

static void cpmap_free( cpmap *m )
{
    Safefree( m->keys );
    Safefree( m->vals );
    Safefree( m->used );
}

static int cpmap_get( cpmap *m, U32 k, I32 *v )
{
    IV i = ( k * 2654435761U ) & ( m->cap - 1 );
    while( m->used[i] )
    {
        if( m->keys[i] == k )
        {
            *v = m->vals[i];
            return( 1 );
        }
        i = ( i + 1 ) & ( m->cap - 1 );
    }
    return( 0 );
}

static void cpmap_put( cpmap *m, U32 k, I32 v );

static void cpmap_grow( cpmap *m )
{
    cpmap old = *m;
    IV i;
    m->cap = old.cap * 2;
    m->n = 0;
    Newxz( m->keys, m->cap, U32 );
    Newxz( m->vals, m->cap, I32 );
    Newxz( m->used, m->cap, char );
    for( i = 0; i < old.cap; i++ )
    {
        if( old.used[i] ) cpmap_put( m, old.keys[i], old.vals[i] );
    }
    cpmap_free( &old );
}

static void cpmap_put( cpmap *m, U32 k, I32 v )
{
    IV i;
    if( ( m->n + 1 ) * 2 > m->cap ) cpmap_grow( m );
    i = ( k * 2654435761U ) & ( m->cap - 1 );
    while( m->used[i] && m->keys[i] != k ) i = ( i + 1 ) & ( m->cap - 1 );
    if( !m->used[i] ) m->n++;
    m->used[i] = 1;
    m->keys[i] = k;
    m->vals[i] = v;
}

/* NOTE: string helpers */
/* Decodes a Perl string into an array of code points. */
static ustr sv_to_ustr( pTHX_ SV *sv )
{
    ustr r;
    STRLEN blen;
    const U8 *p, *end;
    IV n = 0;
    r.s = NULL;
    r.len = 0;
    if( !sv || !SvOK( sv ) )
    {
        Newxz( r.s, 1, U32 );
        return( r );
    }
    if( SvUTF8( sv ) )
    {
        p = (const U8 *)SvPV( sv, blen );
        end = p + blen;
        Newxz( r.s, blen + 1, U32 );
        while( p < end )
        {
            STRLEN clen;
            UV c = utf8_to_uvchr_buf( p, end, &clen );
            if( !clen ) break;
            r.s[ n++ ] = (U32)c;
            p += clen;
        }
    }
    else
    {
        p = (const U8 *)SvPV( sv, blen );
        Newxz( r.s, blen + 1, U32 );
        for( n = 0; n < (IV)blen; n++ ) r.s[n] = p[n];
    }
    r.len = n;
    return( r );
}

static SV *cp_to_sv( pTHX_ const U32 *s, IV len )
{
    SV *sv = newSVpvs( "" );
    IV i;
    SvUTF8_on( sv );
    for( i = 0; i < len; i++ )
    {
        U8 buf[ UTF8_MAXBYTES + 1 ];
        U8 *e = uvchr_to_utf8( buf, s[i] );
        sv_catpvn( sv, (char *)buf, e - buf );
    }
    return( sv );
}

static uview v_of( ustr u )
{
    uview v;
    v.s = u.s;
    v.len = u.len;
    return( v );
}

/* Substring with pinned indices, as UnicodeString::compare( start, length, ... ) does. */
static uview v_pinned( uview v, IV start, IV len )
{
    uview r;
    if( start < 0 ) start = 0;
    if( start > v.len ) start = v.len;
    if( len < 0 ) len = 0;
    if( len > v.len - start ) len = v.len - start;
    r.s = v.s + start;
    r.len = len;
    return( r );
}

static int v_eq( uview a, uview b )
{
    if( a.len != b.len ) return( 0 );
    return( a.len == 0 || memcmp( a.s, b.s, a.len * sizeof( U32 ) ) == 0 );
}

/* substr( str, offset, length( prefix ) ) eq prefix */
static int v_starts_at( uview str, IV off, uview prefix )
{
    if( off < 0 || off > str.len ) return( prefix.len == 0 && off == str.len );
    if( str.len - off < prefix.len ) return( 0 );
    return( prefix.len == 0 || memcmp( str.s + off, prefix.s, prefix.len * sizeof( U32 ) ) == 0 );
}

/* index( str, key, start ) for a non-empty key; -1 when not found. */
static IV v_index( uview str, uview key, IV start )
{
    IV i;
    if( key.len == 0 ) return( -1 );
    if( start < 0 ) start = 0;
    for( i = start; i + key.len <= str.len; i++ )
    {
        if( str.s[i] == key.s[0] && memcmp( str.s + i, key.s, key.len * sizeof( U32 ) ) == 0 ) return( i );
    }
    return( -1 );
}

/* NOTE: Perl callbacks */
static SV *call_cb( pTHX_ SV *cb, U32 c, int with_flag, int flag )
{
    dSP;
    int count;
    SV *ret;
    SV *arg = cp_to_sv( aTHX_ &c, 1 );
    ENTER;
    SAVETMPS;
    PUSHMARK( SP );
    XPUSHs( sv_2mortal( arg ) );
    if( with_flag ) XPUSHs( sv_2mortal( newSViv( flag ) ) );
    PUTBACK;
    count = call_sv( cb, G_SCALAR );
    SPAGAIN;
    ret = count ? newSVsv( POPs ) : newSV( 0 );
    PUTBACK;
    FREETMPS;
    LEAVE;
    return( ret );
}

/* Simple case folding, as Locale::Unicode::RBNF::Rule::_fold_case() does. */
static U32 fold_case( pTHX_ engine_t *e, U32 c )
{
    I32 v;
    if( c < 0x80 )
    {
        if( c == 'I' && e->turkic ) return( 0x0131 );
        if( c >= 'A' && c <= 'Z' ) return( c + 32 );
        return( c );
    }
    if( cpmap_get( &e->fold_cache, c, &v ) ) return( (U32)v );
    {
        SV *r = call_cb( aTHX_ e->cb_fold, c, 1, e->turkic );
        ustr u = sv_to_ustr( aTHX_ r );
        U32 f = u.len ? u.s[0] : c;
        Safefree( u.s );
        SvREFCNT_dec( r );
        cpmap_put( &e->fold_cache, c, (I32)f );
        return( f );
    }
}

static int is_sep( pTHX_ engine_t *e, U32 c )
{
    I32 v;
    if( c < 0x80 ) return( c == ' ' || c == '-' || c == ',' || c == '.' );
    if( cpmap_get( &e->sep_cache, c, &v ) ) return( v );
    {
        SV *r = call_cb( aTHX_ e->cb_sep, c, 0, 0 );
        int b = SvTRUE( r ) ? 1 : 0;
        SvREFCNT_dec( r );
        cpmap_put( &e->sep_cache, c, b );
        return( b );
    }
}

static int has_boundary( pTHX_ engine_t *e, U32 c )
{
    I32 v;
    if( c < 0x80 ) return( 1 );
    if( cpmap_get( &e->boundary_cache, c, &v ) ) return( v );
    {
        SV *r = call_cb( aTHX_ e->cb_boundary, c, 0, 0 );
        int b = SvTRUE( r ) ? 1 : 0;
        SvREFCNT_dec( r );
        cpmap_put( &e->boundary_cache, c, b );
        return( b );
    }
}

/* The decimal digit value of a character, or -1 */
static int digit_value( pTHX_ engine_t *e, U32 c )
{
    I32 v;
    if( c < 0x80 ) return( ( c >= '0' && c <= '9' ) ? (int)( c - '0' ) : -1 );
    if( cpmap_get( &e->digit_cache, c, &v ) ) return( v );
    {
        SV *r = call_cb( aTHX_ e->cb_digit, c, 0, 0 );
        int d = SvOK( r ) ? (int)SvIV( r ) : -1;
        SvREFCNT_dec( r );
        cpmap_put( &e->digit_cache, c, d );
        return( d );
    }
}

/* NFC of a segment; the result is allocated. */
static ustr nfc( pTHX_ engine_t *e, uview seg )
{
    ustr r;
    IV i;
    int ascii = 1;
    for( i = 0; i < seg.len; i++ )
    {
        if( seg.s[i] >= 0x80 )
        {
            ascii = 0;
            break;
        }
    }
    if( ascii )
    {
        Newx( r.s, seg.len + 1, U32 );
        if( seg.len ) Copy( seg.s, r.s, seg.len, U32 );
        r.len = seg.len;
        return( r );
    }
    {
        dSP;
        int count;
        SV *arg = cp_to_sv( aTHX_ seg.s, seg.len );
        SV *ret;
        ENTER;
        SAVETMPS;
        PUSHMARK( SP );
        XPUSHs( sv_2mortal( arg ) );
        PUTBACK;
        count = call_sv( e->cb_nfc, G_SCALAR );
        SPAGAIN;
        ret = count ? newSVsv( POPs ) : newSV( 0 );
        PUTBACK;
        FREETMPS;
        LEAVE;
        r = sv_to_ustr( aTHX_ ret );
        SvREFCNT_dec( ret );
        return( r );
    }
}

static IV pinfo_hash( const U32 *p, IV len, IV cap )
{
    UV h = PTR2UV( p );
    h = ( h >> 2 ) * 2654435761U + (UV)len * 40503U;
    return( (IV)( h & (UV)( cap - 1 ) ) );
}

static void pinfo_index( engine_t *e, IV idx )
{
    IV slot = pinfo_hash( e->pinfos[ idx ].key, e->pinfos[ idx ].key_len, e->pinfo_slot_cap );
    while( e->pinfo_slots[ slot ] ) slot = ( slot + 1 ) & ( e->pinfo_slot_cap - 1 );
    e->pinfo_slots[ slot ] = idx + 1;
}

static pinfo_t *prefix_info( pTHX_ engine_t *e, uview prefix )
{
    IV i, slot;
    pinfo_t *pi;
    ustr n;
    if( e->pinfo_slot_cap )
    {
        slot = pinfo_hash( prefix.s, prefix.len, e->pinfo_slot_cap );
        while( e->pinfo_slots[ slot ] )
        {
            pi = &e->pinfos[ e->pinfo_slots[ slot ] - 1 ];
            if( pi->key == prefix.s && pi->key_len == prefix.len ) return( pi );
            slot = ( slot + 1 ) & ( e->pinfo_slot_cap - 1 );
        }
    }
    if( e->npinfos == e->cap_pinfos )
    {
        e->cap_pinfos = e->cap_pinfos ? e->cap_pinfos * 2 : 64;
        Renew( e->pinfos, e->cap_pinfos, pinfo_t );
        /* Rebuild the index with twice the capacity of the array, to keep it sparse. */
        Safefree( e->pinfo_slots );
        e->pinfo_slot_cap = e->cap_pinfos * 2;
        Newxz( e->pinfo_slots, e->pinfo_slot_cap, IV );
        for( i = 0; i < e->npinfos; i++ ) pinfo_index( e, i );
    }
    pi = &e->pinfos[ e->npinfos++ ];
    pi->key = prefix.s;
    pi->key_len = prefix.len;
    n = nfc( aTHX_ e, prefix );
    pi->n = n.len;
    Newx( pi->folded, n.len + 1, U32 );
    Newx( pi->sep, n.len + 1, char );
    pi->all_sep = 1;
    for( i = 0; i < n.len; i++ )
    {
        pi->folded[i] = fold_case( aTHX_ e, n.s[i] );
        pi->sep[i] = (char)is_sep( aTHX_ e, n.s[i] );
        if( !pi->sep[i] ) pi->all_sep = 0;
    }
    Safefree( n.s );
    pinfo_index( e, e->npinfos - 1 );
    return( pi );
}

/* NOTE: lenient matching */
/* NFRule::prefixLength() for the text of str starting at off. */
static IV prefix_length_at( pTHX_ engine_t *e, uview str, IV off, uview prefix )
{
    pinfo_t *pi;
    IV str_idx, prefix_idx = 0, str_nfc_idx = 0;
    int matched = 1;
    ustr str_nfc;
    if( !prefix.len ) return( 0 );
    if( v_starts_at( str, off, prefix ) ) return( prefix.len );
    if( !e->lenient ) return( 0 );
    pi = prefix_info( aTHX_ e, prefix );
    str_idx = off;
    str_nfc.s = NULL;
    str_nfc.len = 0;
    while( prefix_idx < pi->n )
    {
        /* Separators in str are only skipped when the NFC buffer is exhausted. */
        IV str_sep_count = 0;
        while( str_nfc_idx >= str_nfc.len && str_idx < str.len && is_sep( aTHX_ e, str.s[ str_idx ] ) )
        {
            ++str_idx;
            ++str_sep_count;
        }
        while( prefix_idx < pi->n && pi->sep[ prefix_idx ] ) ++prefix_idx;
        if( pi->all_sep && prefix_idx >= pi->n && str_sep_count == 0 )
        {
            matched = 0;
            break;
        }
        if( prefix_idx >= pi->n ) break;
        if( str_nfc_idx >= str_nfc.len )
        {
            IV seg_start;
            uview seg;
            if( str_idx >= str.len )
            {
                matched = 0;
                break;
            }
            /* Read the next normalisation segment, up to the next NFC boundary. */
            seg_start = str_idx++;
            while( str_idx < str.len && !has_boundary( aTHX_ e, str.s[ str_idx ] ) ) ++str_idx;
            seg.s = str.s + seg_start;
            seg.len = str_idx - seg_start;
            Safefree( str_nfc.s );
            str_nfc = nfc( aTHX_ e, seg );
            str_nfc_idx = 0;
        }
        if( fold_case( aTHX_ e, str_nfc.s[ str_nfc_idx++ ] ) != pi->folded[ prefix_idx ] )
        {
            matched = 0;
            break;
        }
        ++prefix_idx;
    }
    Safefree( str_nfc.s );
    /* The collator tailored with %%lenient-parse rules, ICU's last resort, is not available. */
    return( matched ? str_idx - off : 0 );
}

/* NFRule::findTextLenient() */
static IV find_text_lenient( pTHX_ engine_t *e, uview str, uview key, IV start, IV *len )
{
    IV p;
    for( p = start; p < str.len; ++p )
    {
        IV kl = prefix_length_at( aTHX_ e, str, p, key );
        if( kl != 0 )
        {
            *len = kl;
            return( p );
        }
    }
    *len = 0;
    return( -1 );
}

/* PluralFormat::parseType() with the rule as lenient scanner */
static void plural_parse_type( pTHX_ engine_t *e, int pli, uview src, IV start, IV *begin, IV *end )
{
    plural_t *pl = &e->plurals[ pli ];
    IV matched_index = -1, matched_len = 0;
    int i;
    if( start < 0 ) start = 0;
    for( i = 0; i < pl->n; i++ )
    {
        uview arg = v_of( pl->variants[i] );
        IV curr = -1;
        if( arg.len )
        {
            curr = start > src.len ? -1 : v_index( src, arg, start );
            if( curr < 0 )
            {
                IV l;
                curr = find_text_lenient( aTHX_ e, src, arg, start, &l );
            }
        }
        if( curr >= 0 && curr >= matched_index && arg.len > matched_len )
        {
            matched_index = curr;
            matched_len = arg.len;
        }
    }
    if( matched_index >= 0 )
    {
        *begin = matched_index;
        *end = matched_index + matched_len;
    }
    else
    {
        *begin = -1;
        *end = -1;
    }
}

/* NFRule::findText() */
static IV find_text( pTHX_ engine_t *e, int ri, uview str, uview key, IV start, IV *len )
{
    rule_t *r = &e->rules[ ri ];
    if( r->plural >= 0 )
    {
        IV begin, end;
        plural_parse_type( aTHX_ e, r->plural, str, start, &begin, &end );
        if( begin >= 0 )
        {
            uview text = v_of( r->text );
            uview prefix = v_pinned( text, 0, r->pl_start );
            uview suffix = v_pinned( text, r->pl_suffix, text.len - r->pl_suffix );
            IV match_len = end - begin;
            if( v_eq( v_pinned( str, begin - prefix.len, prefix.len ), prefix ) &&
                v_eq( v_pinned( str, begin + match_len, suffix.len ), suffix ) )
            {
                *len = match_len + prefix.len + suffix.len;
                return( begin - prefix.len );
            }
        }
        *len = 0;
        return( -1 );
    }
    {
        IV pos = start > str.len ? -1 : v_index( str, key, start );
        if( pos >= 0 || !e->lenient )
        {
            *len = key.len;
            return( pos );
        }
    }
    return( find_text_lenient( aTHX_ e, str, key, start, len ) );
}

/* NOTE: decimal format parse */
static int is_zs( U32 c )
{
    return( c == 0x20 || c == 0xA0 || c == 0x1680 || ( c >= 0x2000 && c <= 0x200A ) || c == 0x202F || c == 0x205F || c == 0x3000 );
}

/* Locale::Unicode::RBNF::DecimalFormat::parse() */
static double nf_parse( pTHX_ engine_t *e, int nfi, uview text, ppos_t *pp )
{
    numfmt_t *nf = &e->numfmts[ nfi ];
    IV start = pp->index;
    IV i = start;
    int neg = 0;
    uview suffix = v_of( nf->pos_suffix );
    uview minus = v_of( nf->minus );
    uview decimal = v_of( nf->decimal );
    uview infinity = v_of( nf->infinity );
    char *buf;
    IV nint = 0, nfrac = 0, blen;
    double value;
    if( nf->has_negative && nf->neg_prefix.len && v_starts_at( text, i, v_of( nf->neg_prefix ) ) )
    {
        neg = 1;
        i += nf->neg_prefix.len;
        suffix = v_of( nf->neg_suffix );
    }
    else if( nf->pos_prefix.len && v_starts_at( text, i, v_of( nf->pos_prefix ) ) )
    {
        i += nf->pos_prefix.len;
    }
    else if( i < text.len && ( v_starts_at( text, i, minus ) || text.s[i] == '-' || text.s[i] == 0x2212 ) )
    {
        neg = 1;
        i += v_starts_at( text, i, minus ) ? minus.len : 1;
    }
    if( infinity.len && v_starts_at( text, i, infinity ) )
    {
        pp->index = i + infinity.len;
        return( neg ? -INFINITY : INFINITY );
    }
    blen = text.len - i + 4;
    Newx( buf, blen + 2, char );
    while( i < text.len )
    {
        U32 c = text.s[i];
        int d = digit_value( aTHX_ e, c );
        if( d >= 0 )
        {
            buf[ nint++ ] = (char)( '0' + d );
            i++;
            continue;
        }
        /* A grouping separator is accepted between digits only. */
        if( nint && nf->grouping && ( ( nf->group.len == 1 && c == nf->group.s[0] ) || ( nf->group_is_space && is_zs( c ) ) ) &&
            i + 1 < text.len && digit_value( aTHX_ e, text.s[ i + 1 ] ) >= 0 )
        {
            i++;
            continue;
        }
        break;
    }
    if( i < text.len && v_starts_at( text, i, decimal ) && i + decimal.len < text.len && digit_value( aTHX_ e, text.s[ i + decimal.len ] ) >= 0 )
    {
        i += decimal.len;
        buf[ nint + nfrac++ ] = '.';
        while( i < text.len )
        {
            int d = digit_value( aTHX_ e, text.s[i] );
            if( d < 0 ) break;
            buf[ nint + nfrac++ ] = (char)( '0' + d );
            i++;
        }
    }
    if( !nint && !nfrac )
    {
        Safefree( buf );
        pp->error = start;
        return( 0 );
    }
    if( suffix.len && v_starts_at( text, i, suffix ) ) i += suffix.len;
    pp->index = i;
    buf[ nint + nfrac ] = '\0';
    /* Digits only, with an optional fraction: strtod() reads ".5" as well. */
    value = strtod( buf, NULL );
    Safefree( buf );
    if( nf->multiplier_exp ) value = value / pow( 10.0, nf->multiplier_exp );
    return( neg ? -value : value );
}

/* NOTE: parse engine */
static int ruleset_parse( pTHX_ engine_t *e, int rsi, uview text, ppos_t *pos, double upper, U32 mask, int rc, double *result );
static int rule_parse( pTHX_ engine_t *e, int ri, uview text, ppos_t *parse_pos, int is_fraction_rule, double upper, U32 mask, int rc, double *result );

static double calc_upper_bound( sub_t *s, double upper )
{
    switch( s->type )
    {
        case SUB_MULTIPLIER:
        case SUB_MODULUS: return( s->divisor );
        case SUB_INTEGRAL_PART:
        case SUB_ABSOLUTE_VALUE: return( DBL_MAX );
        case SUB_FRACTIONAL_PART: return( 0.0 );
        case SUB_NUMERATOR: return( s->denominator );
        default: return( upper );
    }
}

static double compose_rule_value( sub_t *s, double nv, double old )
{
    switch( s->type )
    {
        case SUB_MULTIPLIER: return( nv * s->divisor );
        case SUB_MODULUS: return( old - fmod( old, s->divisor ) + nv );
        case SUB_INTEGRAL_PART:
        case SUB_FRACTIONAL_PART: return( nv + old );
        case SUB_ABSOLUTE_VALUE: return( -nv );
        case SUB_NUMERATOR: return( nv / old );
        default: return( nv );
    }
}

/* Formattable::getLong(): truncation, clamped to the int32 range */
static double get_long( double v )
{
    if( v != v ) return( 0 );
    if( v > 2147483647.0 ) return( 2147483647.0 );
    if( v < -2147483648.0 ) return( -2147483648.0 );
    return( (double)(IV)v );
}

/* NFSubstitution::doParse() */
static int sub_parse_base( pTHX_ engine_t *e, sub_t *s, uview text, ppos_t *pp, double base, double upper, int lenient, U32 mask, int rc, double *result )
{
    double r = 0;
    upper = calc_upper_bound( s, upper );
    if( s->rs >= 0 )
    {
        ruleset_parse( aTHX_ e, s->rs, text, pp, upper, mask, rc, &r );
        if( lenient && !e->rulesets[ s->rs ].is_fraction && pp->index == 0 && e->default_nf >= 0 )
        {
            r = nf_parse( aTHX_ e, e->default_nf, text, pp );
        }
    }
    else if( s->nf >= 0 )
    {
        r = nf_parse( aTHX_ e, s->nf, text, pp );
    }
    if( pp->index != 0 )
    {
        *result = compose_rule_value( s, r, base );
        return( 1 );
    }
    *result = 0;
    return( 0 );
}

static int sub_parse( pTHX_ engine_t *e, int si, uview text, ppos_t *pp, double base, double upper, int lenient, U32 mask, int rc, double *result )
{
    sub_t *s = &e->subs[ si ];
    if( s->type == SUB_MODULUS && s->rule_to_use >= 0 )
    {
        /* A >>> substitution uses the specific rule's doParse(). */
        double r = 0;
        rule_parse( aTHX_ e, s->rule_to_use, text, pp, 0, upper, mask, rc + 1, &r );
        if( pp->index != 0 ) r = compose_rule_value( s, r, base );
        *result = r;
        return( 1 );
    }
    if( s->type == SUB_FRACTIONAL_PART )
    {
        uview work;
        ppos_t work_pos;
        char *digits;
        IV total = 0, ndigits = 0;
        double value = 0, r;
        int all_digits = 1;
        if( !s->by_digits ) return( sub_parse_base( aTHX_ e, s, text, pp, base, 0, lenient, mask, rc, result ) );
        /* In "by digits" mode, the text is parsed one digit at a time with an upper bound of 10. */
        work = text;
        work_pos.index = 1;
        work_pos.error = -1;
        Newx( digits, text.len + 32, char );
        while( work.len > 0 && work_pos.index != 0 )
        {
            double temp = 0, digit;
            work_pos.index = 0;
            ruleset_parse( aTHX_ e, s->rs, work, &work_pos, 10, mask, rc, &temp );
            digit = get_long( temp );
            if( lenient && work_pos.index == 0 && e->default_nf >= 0 )
            {
                temp = nf_parse( aTHX_ e, e->default_nf, work, &work_pos );
                digit = get_long( temp );
            }
            if( work_pos.index != 0 )
            {
                value = value * 10 + digit;
                if( digit >= 0 && digit <= 9 ) digits[ ndigits++ ] = (char)( '0' + (int)digit );
                else all_digits = 0;
                total++;
                pp->index += work_pos.index;
                work.s += work_pos.index;
                work.len -= work_pos.index;
                while( work.len > 0 && work.s[0] == ' ' )
                {
                    work.s++;
                    work.len--;
                    pp->index++;
                }
            }
        }
        r = 0;
        if( total )
        {
            if( all_digits )
            {
                sprintf( digits + ndigits, "e-%ld", (long)total );
                r = strtod( digits, NULL );
            }
            else
            {
                r = value / pow( 10.0, (double)total );
            }
        }
        Safefree( digits );
        *result = compose_rule_value( s, r, base );
        return( 1 );
    }
    if( s->type == SUB_NUMERATOR )
    {
        IV zero_count = 0;
        uview work = text;
        double r = 0;
        if( s->with_zeros && s->rs >= 0 )
        {
            ppos_t work_pos;
            work_pos.index = 1;
            work_pos.error = -1;
            while( work.len > 0 && work_pos.index != 0 )
            {
                double t;
                work_pos.index = 0;
                /* Parse zero, or nothing at all. */
                ruleset_parse( aTHX_ e, s->rs, work, &work_pos, 1, mask, rc, &t );
                if( work_pos.index == 0 ) break;
                ++zero_count;
                pp->index += work_pos.index;
                work.s += work_pos.index;
                work.len -= work_pos.index;
                while( work.len > 0 && work.s[0] == ' ' )
                {
                    work.s++;
                    work.len--;
                    pp->index++;
                }
            }
            work = v_pinned( text, pp->index, text.len - pp->index );
            pp->index = 0;
        }
        /* Lenient parsing is turned off here: it seriously messes up the algorithm. */
        sub_parse_base( aTHX_ e, s, work, pp, s->with_zeros ? 1 : base, upper, 0, mask, rc, &r );
        if( s->with_zeros )
        {
            double n = get_long( r );
            double d = 1;
            while( d <= n )
            {
                if( d > 922337203685477580.0 )
                {
                    *result = 0;
                    return( 0 );
                }
                d *= 10;
            }
            while( zero_count > 0 )
            {
                if( d > 922337203685477580.0 )
                {
                    *result = 0;
                    return( 0 );
                }
                d *= 10;
                --zero_count;
            }
            r = n / d;
        }
        *result = r;
        return( 1 );
    }
    return( sub_parse_base( aTHX_ e, s, text, pp, base, upper, lenient, mask, rc, result ) );
}

/* NFRule::matchToDelimiter() */
static double match_to_delimiter( pTHX_ engine_t *e, int ri, uview text, IV start_pos, double base, uview delim, ppos_t *pp, int si, U32 mask, int rc, double upper )
{
    int lenient = e->lenient;
    if( delim.len )
    {
        ppos_t temp_pp;
        IV curr_pos = start_pos;
        double best_result = 0;
        int best_set = 0;
        temp_pp.index = 0;
        temp_pp.error = -1;
        while( 1 )
        {
            IV d_len, d_pos;
            uview sub_text;
            temp_pp.index = 0;
            d_pos = find_text( aTHX_ e, ri, text, delim, curr_pos, &d_len );
            if( d_pos < 0 ) break;
            sub_text = v_pinned( text, 0, d_pos );
            if( sub_text.len && si >= 0 )
            {
                double r = 0;
                int ok = sub_parse( aTHX_ e, si, sub_text, &temp_pp, base, upper, lenient, mask, rc, &r );
                if( ok && temp_pp.index == d_pos )
                {
                    pp->index = d_pos + d_len;
                    best_result = r;
                    best_set = 1;
                }
                else
                {
                    /* We matched the delimiter once already and did not find a better match. */
                    if( best_set ) return( best_result );
                    pp->error = temp_pp.error > 0 ? temp_pp.error : temp_pp.index;
                }
            }
            /* ICU would loop forever on a zero-length match; we always move forward. */
            curr_pos = d_pos + ( d_len > 0 ? d_len : 1 );
            temp_pp.index = 0;
        }
        if( best_set ) return( best_result );
        pp->index = 0;
        return( 0 );
    }
    else if( si < 0 )
    {
        return( base );
    }
    else
    {
        /* The delimiter is empty: match as much of the text as possible. */
        ppos_t temp_pp;
        double r = 0;
        int ok;
        temp_pp.index = 0;
        temp_pp.error = -1;
        ok = sub_parse( aTHX_ e, si, text, &temp_pp, base, upper, lenient, mask, rc, &r );
        if( ok && temp_pp.index != 0 )
        {
            pp->index = temp_pp.index;
            return( r );
        }
        pp->error = temp_pp.error;
        return( 0 );
    }
}

/* NFRule::doParse() */
static int rule_parse( pTHX_ engine_t *e, int ri, uview text, ppos_t *parse_pos, int is_fraction_rule, double upper, U32 mask, int rc, double *result )
{
    rule_t *r = &e->rules[ ri ];
    uview rt = v_of( r->text );
    ppos_t pp;
    uview work = text;
    IV sub1_pos = r->sub1 >= 0 ? e->subs[ r->sub1 ].pos : rt.len;
    IV sub2_pos = r->sub2 >= 0 ? e->subs[ r->sub2 ].pos : rt.len;
    uview prefix = v_pinned( rt, 0, sub1_pos );
    IV prefix_length, hwm = 0, start = 0;
    double res = 0, temp_base;
    pp.index = 0;
    pp.error = -1;

    /* Strip the text before the first substitution, if it matches. */
    if( prefix.len )
    {
        IV pfl = prefix_length_at( aTHX_ e, work, 0, prefix );
        if( pfl != 0 )
        {
            pp.index += pfl;
            work.s += pfl;
            work.len -= pfl;
        }
    }
    prefix_length = text.len - work.len;
    if( pp.index == 0 && sub1_pos != 0 )
    {
        parse_pos->error = pp.error;
        *result = 0;
        return( 1 );
    }
    if( r->base == RULE_INFINITY )
    {
        parse_pos->index = pp.index;
        *result = INFINITY;
        return( 1 );
    }
    if( r->base == RULE_NAN )
    {
        parse_pos->index = pp.index;
        *result = NAN;
        return( 1 );
    }
    temp_base = r->base <= 0 ? 0 : (double)r->base;
    do
    {
        double partial;
        pp.index = 0;
        partial = match_to_delimiter( aTHX_ e, ri, work, start, temp_base, v_pinned( rt, sub1_pos, sub2_pos - sub1_pos ), &pp, r->sub1, mask, rc, upper );
        if( pp.index != 0 || r->sub1 < 0 )
        {
            uview work2;
            ppos_t pp2;
            start = pp.index;
            work2 = v_pinned( work, pp.index, work.len - pp.index );
            pp2.index = 0;
            pp2.error = -1;
            partial = match_to_delimiter( aTHX_ e, ri, work2, 0, partial, v_pinned( rt, sub2_pos, rt.len - sub2_pos ), &pp2, r->sub2, mask, rc, upper );
            if( pp2.index != 0 || r->sub2 < 0 )
            {
                if( prefix_length + pp.index + pp2.index > hwm )
                {
                    hwm = prefix_length + pp.index + pp2.index;
                    res = partial;
                }
            }
            else
            {
                IV i_temp = pp2.error + sub1_pos + pp.index;
                if( i_temp > parse_pos->error ) parse_pos->error = i_temp;
            }
        }
        else
        {
            IV i_temp = sub1_pos + pp.error;
            if( i_temp > parse_pos->error ) parse_pos->error = i_temp;
        }
    } while( sub1_pos != sub2_pos && pp.index > 0 && pp.index < work.len && pp.index != start );

    parse_pos->index = hwm;
    if( hwm > 0 ) parse_pos->error = 0;
    /* A rule in a fraction rule set without any substitution has a numerator of 1. */
    if( is_fraction_rule && hwm > 0 && r->sub1 < 0 ) res = res != 0 ? 1 / res : INFINITY;
    *result = res;
    return( 1 );
}

/* Matches the IV conversion of util64_fromDouble() for the upper bound. */
static double from_double( double d )
{
    double mant = 18014398509481983.0;
    int neg;
    if( d != d ) return( 0 );
    if( d < -mant ) d = -mant;
    else if( d > mant ) d = mant;
    neg = d < 0;
    if( neg ) d = -d;
    d = floor( d );
    return( neg ? -d : d );
}

/* NFRuleSet::parse() */
static int ruleset_parse( pTHX_ engine_t *e, int rsi, uview text, ppos_t *pos, double upper, U32 mask, int rc, double *result )
{
    ruleset_t *rs = &e->rulesets[ rsi ];
    ppos_t hwm, working;
    double ub;
    int i;
    *result = 0;
    if( rc >= RECURSION_LIMIT ) return( 0 );
    if( !text.len ) return( 0 );
    hwm.index = 0;
    hwm.error = -1;
    working = *pos;
    /* The negative, fraction, infinity and NaN rules */
    for( i = 0; i < NON_NUMERICAL_RULE_LENGTH; i++ )
    {
        if( rs->nnr[i] >= 0 && ( ( mask >> i ) & 1 ) == 0 )
        {
            double temp = 0;
            int ok;
            mask |= ( 1U << i );
            ok = rule_parse( aTHX_ e, rs->nnr[i], text, &working, 0, upper, mask, rc + 1, &temp );
            if( ok && working.index > hwm.index )
            {
                *result = temp;
                hwm = working;
            }
            working = *pos;
        }
    }
    /* Then the regular rules, from the most significant one, below the upper bound */
    ub = from_double( upper );
    for( i = rs->nrules; --i >= 0 && hwm.index < text.len; )
    {
        rule_t *r = &e->rules[ rs->rules[i] ];
        double temp = 0;
        int ok;
        if( !rs->is_fraction && (double)r->base >= ub ) continue;
        ok = rule_parse( aTHX_ e, rs->rules[i], text, &working, rs->is_fraction, upper, mask, rc + 1, &temp );
        if( ok && working.index > hwm.index )
        {
            *result = temp;
            hwm = working;
        }
        working = *pos;
    }
    *pos = hwm;
    return( 1 );
}

/* NOTE: compilation from the Perl structure */
static SV *hv_fetch_sv( pTHX_ HV *hv, const char *key )
{
    SV **svp = hv_fetch( hv, key, strlen( key ), 0 );
    return( svp ? *svp : NULL );
}

static IV hv_iv( pTHX_ HV *hv, const char *key, IV def )
{
    SV *sv = hv_fetch_sv( aTHX_ hv, key );
    return( ( sv && SvOK( sv ) ) ? SvIV( sv ) : def );
}

static NV hv_nv( pTHX_ HV *hv, const char *key, NV def )
{
    SV *sv = hv_fetch_sv( aTHX_ hv, key );
    return( ( sv && SvOK( sv ) ) ? SvNV( sv ) : def );
}

static ustr hv_ustr( pTHX_ HV *hv, const char *key )
{
    return( sv_to_ustr( aTHX_ hv_fetch_sv( aTHX_ hv, key ) ) );
}

static AV *hv_av( pTHX_ HV *hv, const char *key )
{
    SV *sv = hv_fetch_sv( aTHX_ hv, key );
    if( !sv || !SvROK( sv ) || SvTYPE( SvRV( sv ) ) != SVt_PVAV ) croak( "Locale::Unicode::RBNF::XS: missing array '%s'", key );
    return( (AV *)SvRV( sv ) );
}

static HV *av_hv( pTHX_ AV *av, IV i )
{
    SV **svp = av_fetch( av, i, 0 );
    if( !svp || !SvROK( *svp ) || SvTYPE( SvRV( *svp ) ) != SVt_PVHV ) croak( "Locale::Unicode::RBNF::XS: element %ld is not a hash", (long)i );
    return( (HV *)SvRV( *svp ) );
}

static SV *hv_cb( pTHX_ HV *hv, const char *key )
{
    SV *sv = hv_fetch_sv( aTHX_ hv, key );
    if( !sv || !SvROK( sv ) || SvTYPE( SvRV( sv ) ) != SVt_PVCV ) croak( "Locale::Unicode::RBNF::XS: missing callback '%s'", key );
    return( newSVsv( sv ) );
}

static engine_t *engine_new( pTHX_ HV *spec )
{
    engine_t *e;
    AV *av;
    IV i, j;
    Newxz( e, 1, engine_t );
    e->default_nf = (int)hv_iv( aTHX_ spec, "default_nf", -1 );
    e->turkic = (int)hv_iv( aTHX_ spec, "turkic", 0 );
    e->cb_fold = hv_cb( aTHX_ spec, "cb_fold" );
    e->cb_sep = hv_cb( aTHX_ spec, "cb_sep" );
    e->cb_boundary = hv_cb( aTHX_ spec, "cb_boundary" );
    e->cb_nfc = hv_cb( aTHX_ spec, "cb_nfc" );
    e->cb_digit = hv_cb( aTHX_ spec, "cb_digit" );
    cpmap_init( &e->fold_cache );
    cpmap_init( &e->sep_cache );
    cpmap_init( &e->boundary_cache );
    cpmap_init( &e->digit_cache );

    av = hv_av( aTHX_ spec, "rule_sets" );
    e->nrulesets = (int)( av_len( av ) + 1 );
    Newxz( e->rulesets, e->nrulesets + 1, ruleset_t );
    for( i = 0; i < e->nrulesets; i++ )
    {
        HV *h = av_hv( aTHX_ av, i );
        AV *rav = hv_av( aTHX_ h, "rules" );
        AV *nav = hv_av( aTHX_ h, "nnr" );
        ruleset_t *rs = &e->rulesets[i];
        rs->is_fraction = (int)hv_iv( aTHX_ h, "is_fraction", 0 );
        rs->is_public = (int)hv_iv( aTHX_ h, "is_public", 0 );
        rs->is_parseable = (int)hv_iv( aTHX_ h, "is_parseable", 0 );
        rs->nrules = (int)( av_len( rav ) + 1 );
        Newxz( rs->rules, rs->nrules + 1, int );
        for( j = 0; j < rs->nrules; j++ ) rs->rules[j] = (int)SvIV( *av_fetch( rav, j, 0 ) );
        for( j = 0; j < NON_NUMERICAL_RULE_LENGTH; j++ )
        {
            SV **svp = av_fetch( nav, j, 0 );
            rs->nnr[j] = ( svp && SvOK( *svp ) ) ? (int)SvIV( *svp ) : -1;
        }
    }

    av = hv_av( aTHX_ spec, "rules" );
    e->nrules = (int)( av_len( av ) + 1 );
    Newxz( e->rules, e->nrules + 1, rule_t );
    for( i = 0; i < e->nrules; i++ )
    {
        HV *h = av_hv( aTHX_ av, i );
        rule_t *r = &e->rules[i];
        r->base = hv_iv( aTHX_ h, "base", 0 );
        r->text = hv_ustr( aTHX_ h, "text" );
        r->sub1 = (int)hv_iv( aTHX_ h, "sub1", -1 );
        r->sub2 = (int)hv_iv( aTHX_ h, "sub2", -1 );
        r->plural = (int)hv_iv( aTHX_ h, "plural", -1 );
        r->pl_start = hv_iv( aTHX_ h, "pl_start", 0 );
        r->pl_suffix = hv_iv( aTHX_ h, "pl_suffix", 0 );
    }

    av = hv_av( aTHX_ spec, "subs" );
    e->nsubs = (int)( av_len( av ) + 1 );
    Newxz( e->subs, e->nsubs + 1, sub_t );
    for( i = 0; i < e->nsubs; i++ )
    {
        HV *h = av_hv( aTHX_ av, i );
        sub_t *s = &e->subs[i];
        s->type = (int)hv_iv( aTHX_ h, "type", 0 );
        s->pos = hv_iv( aTHX_ h, "pos", 0 );
        s->rs = (int)hv_iv( aTHX_ h, "rs", -1 );
        s->nf = (int)hv_iv( aTHX_ h, "nf", -1 );
        s->divisor = hv_nv( aTHX_ h, "divisor", 1 );
        s->rule_to_use = (int)hv_iv( aTHX_ h, "rule_to_use", -1 );
        s->by_digits = (int)hv_iv( aTHX_ h, "by_digits", 0 );
        s->with_zeros = (int)hv_iv( aTHX_ h, "with_zeros", 0 );
        s->denominator = hv_nv( aTHX_ h, "denominator", 0 );
    }

    av = hv_av( aTHX_ spec, "plurals" );
    e->nplurals = (int)( av_len( av ) + 1 );
    Newxz( e->plurals, e->nplurals + 1, plural_t );
    for( i = 0; i < e->nplurals; i++ )
    {
        SV **svp = av_fetch( av, i, 0 );
        AV *vav;
        if( !svp || !SvROK( *svp ) ) croak( "Locale::Unicode::RBNF::XS: plural %ld is not an array", (long)i );
        vav = (AV *)SvRV( *svp );
        e->plurals[i].n = (int)( av_len( vav ) + 1 );
        Newxz( e->plurals[i].variants, e->plurals[i].n + 1, ustr );
        for( j = 0; j < e->plurals[i].n; j++ ) e->plurals[i].variants[j] = sv_to_ustr( aTHX_ *av_fetch( vav, j, 0 ) );
    }

    av = hv_av( aTHX_ spec, "number_formats" );
    e->nnumfmts = (int)( av_len( av ) + 1 );
    Newxz( e->numfmts, e->nnumfmts + 1, numfmt_t );
    for( i = 0; i < e->nnumfmts; i++ )
    {
        HV *h = av_hv( aTHX_ av, i );
        numfmt_t *nf = &e->numfmts[i];
        nf->pos_prefix = hv_ustr( aTHX_ h, "pos_prefix" );
        nf->pos_suffix = hv_ustr( aTHX_ h, "pos_suffix" );
        nf->has_negative = (int)hv_iv( aTHX_ h, "has_negative", 0 );
        nf->neg_prefix = hv_ustr( aTHX_ h, "neg_prefix" );
        nf->neg_suffix = hv_ustr( aTHX_ h, "neg_suffix" );
        nf->minus = hv_ustr( aTHX_ h, "minus" );
        nf->decimal = hv_ustr( aTHX_ h, "decimal" );
        nf->group = hv_ustr( aTHX_ h, "group" );
        nf->infinity = hv_ustr( aTHX_ h, "infinity" );
        nf->grouping = (int)hv_iv( aTHX_ h, "grouping", 0 );
        nf->group_is_space = (int)hv_iv( aTHX_ h, "group_is_space", 0 );
        nf->multiplier_exp = (int)hv_iv( aTHX_ h, "multiplier_exp", 0 );
    }
    return( e );
}

static void engine_free( pTHX_ engine_t *e )
{
    IV i, j;
    for( i = 0; i < e->nrulesets; i++ ) Safefree( e->rulesets[i].rules );
    Safefree( e->rulesets );
    for( i = 0; i < e->nrules; i++ ) Safefree( e->rules[i].text.s );
    Safefree( e->rules );
    Safefree( e->subs );
    for( i = 0; i < e->nplurals; i++ )
    {
        for( j = 0; j < e->plurals[i].n; j++ ) Safefree( e->plurals[i].variants[j].s );
        Safefree( e->plurals[i].variants );
    }
    Safefree( e->plurals );
    for( i = 0; i < e->nnumfmts; i++ )
    {
        numfmt_t *nf = &e->numfmts[i];
        Safefree( nf->pos_prefix.s );
        Safefree( nf->pos_suffix.s );
        Safefree( nf->neg_prefix.s );
        Safefree( nf->neg_suffix.s );
        Safefree( nf->minus.s );
        Safefree( nf->decimal.s );
        Safefree( nf->group.s );
        Safefree( nf->infinity.s );
    }
    Safefree( e->numfmts );
    for( i = 0; i < e->npinfos; i++ )
    {
        Safefree( e->pinfos[i].folded );
        Safefree( e->pinfos[i].sep );
    }
    Safefree( e->pinfos );
    Safefree( e->pinfo_slots );
    cpmap_free( &e->fold_cache );
    cpmap_free( &e->sep_cache );
    cpmap_free( &e->boundary_cache );
    cpmap_free( &e->digit_cache );
    SvREFCNT_dec( e->cb_fold );
    SvREFCNT_dec( e->cb_sep );
    SvREFCNT_dec( e->cb_boundary );
    SvREFCNT_dec( e->cb_nfc );
    SvREFCNT_dec( e->cb_digit );
    Safefree( e );
}

MODULE = Locale::Unicode::RBNF    PACKAGE = Locale::Unicode::RBNF::XS

PROTOTYPES: DISABLE

SV *
new( class, spec )
        const char *class
        SV *spec
    PREINIT:
        engine_t *e;
    CODE:
        if( !SvROK( spec ) || SvTYPE( SvRV( spec ) ) != SVt_PVHV ) croak( "Locale::Unicode::RBNF::XS->new requires a hash reference" );
        e = engine_new( aTHX_ (HV *)SvRV( spec ) );
        RETVAL = sv_setref_pv( newSV( 0 ), class, (void *)e );
    OUTPUT:
        RETVAL

void
parse( self, text, lenient )
        SV *self
        SV *text
        int lenient
    PREINIT:
        engine_t *e;
        ustr u;
        uview t;
        ppos_t high;
        double high_result = 0;
        int i;
    PPCODE:
        /* RuleBasedNumberFormat::parse(): every public and parseable rule set is tried. */
        /* The engine calls back into Perl, so the stack pointer must be handed over and taken back. */
        PUTBACK;
        e = INT2PTR( engine_t *, SvIV( SvRV( self ) ) );
        e->lenient = lenient ? 1 : 0;
        u = sv_to_ustr( aTHX_ text );
        t = v_of( u );
        high.index = 0;
        high.error = -1;
        for( i = 0; i < e->nrulesets; i++ )
        {
            ruleset_t *rs = &e->rulesets[i];
            ppos_t working;
            double r = 0;
            if( !rs->is_public || !rs->is_parseable ) continue;
            working.index = 0;
            working.error = -1;
            ruleset_parse( aTHX_ e, i, t, &working, K_MAX_DOUBLE, 0, 0, &r );
            if( working.index > high.index )
            {
                high = working;
                high_result = r;
                if( high.index == t.len ) break;
            }
        }
        Safefree( u.s );
        SPAGAIN;
        EXTEND( SP, 3 );
        PUSHs( sv_2mortal( newSVnv( high_result ) ) );
        PUSHs( sv_2mortal( newSViv( high.index ) ) );
        PUSHs( sv_2mortal( newSViv( high.error ) ) );

void
DESTROY( self )
        SV *self
    CODE:
        engine_free( aTHX_ INT2PTR( engine_t *, SvIV( SvRV( self ) ) ) );
