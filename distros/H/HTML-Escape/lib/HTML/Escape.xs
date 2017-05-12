#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newSVpvn_flags
#define NEED_sv_2pv_flags

#include "ppport.h"

/* Characters to escape:
 *  0x22 "   0x26 &   0x27 '   0x3c <   0x3e >   0x60 `   0x7b {   0x7d }
 *
 * Note that we don't care whether the input uses Perl's single-byte
 * (Latin-1) or multi-byte (UTF-8) encoding, because every byte >= 0x80 is
 * safe regardless.
 */
static const char unsafe[256] = {
    /*                 0 1 2 3   4 5 6 7   8 9 a b   c d e f */
    /* 0x00 .. 0x0f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0x10 .. 0x1f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0x20 .. 0x2f */ 0,0,1,0,  0,0,1,1,  0,0,0,0,  0,0,0,0,
    /* 0x30 .. 0x3f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  1,0,1,0,
    /* 0x40 .. 0x4f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0x50 .. 0x5f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0x60 .. 0x6f */ 1,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0x70 .. 0x7f */ 0,0,0,0,  0,0,0,0,  0,0,0,1,  0,1,0,0,
    /* 0x80 .. 0x8f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0x90 .. 0x9f */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0xa0 .. 0xaf */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0xb0 .. 0xbf */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0xc0 .. 0xcf */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0xd0 .. 0xdf */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0xe0 .. 0xef */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
    /* 0xf0 .. 0xff */ 0,0,0,0,  0,0,0,0,  0,0,0,0,  0,0,0,0,
};

/* This is essentially a version of standard strcspn() that (a) handles
 * arbitrary memory buffers, possibly containing \0 bytes, and (b) knows at
 * compile-time which characters to detect, rather than having to build an
 * internal data structure representing them on every call. */
static size_t safe_character_span(const char *start, const char *end) {
    const char *cur = start;
    while(cur != end) {
        unsigned char c = (unsigned char) *cur;
        if(unsafe[c]) {
            break;
        }
        cur++;
    }
    return cur - start;
}

static void /* doesn't care about raw-ness */
tx_sv_cat_with_escape_html_force(pTHX_ SV* const dest, SV* const src) {
    STRLEN len;
    const char*       cur = SvPV_const(src, len);
    const char* const end = cur + len;
    STRLEN const dest_cur = SvCUR(dest);
    char* d;

    (void)SvGROW(dest, dest_cur + ( len * ( sizeof("&quot;") - 1) ) + 1);
    if(!SvUTF8(dest) && SvUTF8(src)) {
        sv_utf8_upgrade(dest);
    }

    d = SvPVX(dest) + dest_cur;

#define CopyToken(token, to) STMT_START {          \
        Copy(token "", to, sizeof(token)-1, char); \
        to += sizeof(token)-1;                     \
    } STMT_END

    while(cur != end) {
        size_t span = safe_character_span(cur, end);
        Copy(cur, d, span, char);
        cur += span;
        d += span;
        if(cur != end) {
            const char c = *(cur++);
            if(c == '&') {
                CopyToken("&amp;", d);
            }
            else if(c == '<') {
                CopyToken("&lt;", d);
            }
            else if(c == '>') {
                CopyToken("&gt;", d);
            }
            else if(c == '"') {
                CopyToken("&quot;", d);
            }
            else if(c == '`') {
                CopyToken("&#96;", d);
            }
            else if(c == '{') {
                CopyToken("&#123;", d);
            }
            else if(c == '}') {
                CopyToken("&#125;", d);
            }
            else {              /*  c == '\'' */
                /* XXX: Internet Explorer (at least version 8) doesn't support &apos; in title */
                /* CopyToken("&apos;", d); */
                CopyToken("&#39;", d);
            }
        }
    }

#undef CopyToken

    SvCUR_set(dest, d - SvPVX(dest));
    *SvEND(dest) = '\0';
}

static SV*
tx_escape_html(pTHX_ SV* const str) {
    SvGETMAGIC(str);
    if(!( !SvOK(str) )) {
        SV* const dest = newSVpvs_flags("", SVs_TEMP);
        tx_sv_cat_with_escape_html_force(aTHX_ dest, str);
        return dest;
    }
    else {
        return str;
    }
}

MODULE = HTML::Escape    PACKAGE = HTML::Escape

PROTOTYPES: DISABLE

void
escape_html(SV* str)
CODE:
{
    ST(0) = tx_escape_html(aTHX_ str);
}

