#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <SWI-Prolog.h>

#include "Low.h"
#include "opaque.h"
#include "callback.h"
#include "swi2perl.h"

SV *newSVatom(pTHX_ atom_t a);

#ifdef REP_UTF8
SV *newSVwchar(pTHX_ const pl_wchar_t *s, int len);
#endif

SV *swi2perl(pTHX_ term_t t, AV *cells) {
    int type = PL_term_type(t);
    switch (type) {
    case PL_INTEGER: {
	long v;
	PL_get_long(t, &v);
	return newSViv(v);
    }
    case PL_FLOAT: {
	double v;
	PL_get_float(t, &v);
	return newSVnv(v);
    }
    case PL_STRING:
    case PL_ATOM: {
        return swi2perl_atom_sv(aTHX_ t);
    }
    case PL_TERM: {
        if (PL_is_list(t)) {
            AV *array=newAV();
            SV *ref=newRV_noinc((SV *)array);
            int len=0;
            term_t head, tail;
            while(PL_is_list(t)) {
                if(PL_get_nil(t)) {
                    sv_bless(ref, gv_stashpv( len ?
                                              TYPEINTPKG "::list" :
                                              TYPEINTPKG "::nil", 1));
                    return ref;
                }
                head=PL_new_term_refs(2);
                tail=head+1;
                PL_get_list(t, head, tail);
                av_push(array, swi2perl(aTHX_ head, cells));
                t=tail;
                len++;
            }
            av_push(array, swi2perl(aTHX_ tail, cells));
            sv_bless(ref, gv_stashpv(TYPEINTPKG "::ulist", 1));
            return ref;
        }

        {
            /* any other compound */
            SV *ref;
            int i;
            int arity;
            atom_t atom;

            PL_get_name_arity(t, &atom, &arity);
	
            if ( arity==2 &&
                 strcmp(OPAQUE_FUNCTOR, PL_atom_chars(atom))==0 &&
                 pl_get_perl_opaque(aTHX_ t, &ref) ) {
                SvREFCNT_inc(ref);
            }
            else {
                AV *functor=newAV();
                ref=newRV_noinc((SV *)functor);
                sv_bless(ref, gv_stashpv(TYPEINTPKG "::functor", 1));
                av_extend(functor, arity+1);
                av_store(functor, 0, newSVatom(aTHX_ atom));
                for (i=1; i<=arity; i++) {
                    term_t arg=PL_new_term_ref();
                    PL_get_arg(i, t, arg);
                    av_store(functor, i, swi2perl(aTHX_
                                                  arg, cells));
                }
            }
            return ref;
        }
    }
    case PL_VARIABLE: {
	term_t var;
	int len=av_len(cells)+1;
	int i;
	SV *cell;
	SV *ref;
	for(i=0; i<len; i++) {
	    SV **ref_p=av_fetch(cells, i, 0);
	    if (!ref_p)
		die ("internal error, unable to fetch var from cache");
	    var=SvIV(*ref_p);
	    if (PL_compare(t, var)==0) {
		cell=*ref_p;
		break;
	    }
	}
	if (i==len) {
	    cell=newSViv(t);
	    /* SvREADONLY_on(cell); */
	    av_push(cells, cell);
	}
	ref=newRV_inc(cell);
	sv_bless(ref, gv_stashpv(TYPEINTPKG "::variable", 1));
	return ref;
    }
    }
    warn("unknown SWI-Prolog type 0x%x, using undef", type);
    return &PL_sv_undef;
}

SV *newSVatom(pTHX_ atom_t a) {
    size_t len;

    {
        const char *v;
        if (v = PL_atom_nchars(a, &len)) {
            /* fprintf(stderr, "latin1\n"); fflush(stderr); */
            return newSVpvn(v, len);
        }
    }
#ifdef REP_UTF8
    {
        const pl_wchar_t *w;
        if (w = PL_atom_wchars(a, &len)) {
            /* fprintf(stderr, "utf8\n"); fflush(stderr); */
            return newSVwchar(aTHX_ w, len);
        }
    }
#endif
    warn("unable to convert atom to SV, using undef");
    return &PL_sv_undef;
}

SV *swi2perl_atom_sv(pTHX_ term_t t) {
    atom_t a;
    if (PL_get_atom(t, &a))
        return newSVatom(aTHX_ a);

    {
        char * v;
        size_t len;

#ifdef REP_UTF8
        if (PL_get_nchars(t, &len, &v, CVT_STRING|BUF_DISCARDABLE|REP_ISO_LATIN_1)) {
            return newSVpv(v, len);
        }
        if (PL_get_nchars(t, &len, &v, CVT_STRING|BUF_DISCARDABLE|REP_UTF8)) {
            SV *ret;
            ret = newSVpv(v, len);
            SvUTF8_on(ret);
            return ret;
        }
#else
        if (PL_get_string_chars(t, &v, &len)) {
            return newSVpv(v, len);
        }
#endif
    }
    return NULL;
}

static void
raise_atom_expected(term_t nonatom) {
    term_t e=PL_new_term_ref();
    PL_unify_term(e,
		  PL_FUNCTOR_CHARS, "type_error", 2,
		  PL_CHARS, "atom",
		  PL_TERM, nonatom);
    PL_raise_exception(e);
}

SV *swi2perl_atom_sv_ex(pTHX_ term_t t) {
    SV *ret = swi2perl_atom_sv(aTHX_ t);
    if (ret)
	return ret;

    raise_atom_expected(t);
    return NULL;
}

#ifdef REP_UTF8

SV *newSVwchar(pTHX_ const pl_wchar_t *s, int len) {
    SV *sv;
    int i;
    int noascii;
    char *head, *end;
    for (i=0, noascii=0; i < len; i++)
        if (s[i] >= 0x80)
            noascii++;

    /* sv = newSV(UTF8_MAXBYTES + 1); */
    sv = newSV(len + noascii + UTF8_MAXBYTES + 1);
    SvPOK_on(sv);

    head = SvPVX(sv);
    end = SvPVX(sv) + SvLEN(sv) - UTF8_MAXBYTES - 1;
    for (i = 0; i < len; i++) {
        int chr = s[i];
        if (head >= end) {
            int cur = head - SvPVX(sv);
            SvCUR_set(sv, cur);
            SvGROW(sv, cur + len - i + UTF8_MAXBYTES + 1);
            /* SvGROW(sv, 2 * (len - i) + UTF8_MAXBYTES + 1) */
            head = SvPVX(sv) + SvCUR(sv);
            end = SvPVX(sv) + SvLEN(sv) - UTF8_MAXBYTES - 1;
        }

        if ( chr < 0x80 ) {
            *head++ = chr;
        }
        else if ( chr < 0x800 ) {
            *head++ = 0xc0 | ((chr >> 6) & 0x1f);
            *head++ = 0x80 | (chr & 0x3f);
        }
        else if ( chr < 0x10000 ) {
            *head++ = 0xe0 | ((chr >> 12) & 0x0f);
            *head++ = 0x80 | ((chr >> 6) & 0x3f);
            *head++ = 0x80 | (chr & 0x3f);
        }
        else if ( chr < 0x200000 ) {
            *head++ = 0xf0 | ((chr >> 18) & 0x07);
            *head++ = 0x80 | ((chr >> 12) & 0x3f);
            *head++ = 0x80 | ((chr >> 6) & 0x3f);
            *head++ = 0x80 | (chr & 0x3f);
        }
        else if ( chr < 0x4000000 ) {
            *head++ = 0xf8 | ((chr >> 24) & 0x03);
            *head++ = 0x80 | ((chr >> 18) & 0x3f);
            *head++ = 0x80 | ((chr >> 12) & 0x3f);
            *head++ = 0x80 | ((chr >> 6) & 0x3f);
            *head++ = 0x80 | (chr & 0x3f);
        }
        else if ( chr < 0x80000000 ) {
            *head++ = 0xfc | ((chr >> 30) & 0x01);
            *head++ = 0x80 | ((chr >> 24) & 0x3f);
            *head++ = 0x80 | ((chr >> 18) & 0x3f);
            *head++ = 0x80 | ((chr >> 12) & 0x3f);
            *head++ = 0x80 | ((chr >> 6) & 0x3f);
            *head++ = 0x80 | (chr & 0x3f);
        }
    }

    SvCUR_set(sv, head - SvPVX(sv));
    *head = 0;

    SvUTF8_on(sv);
    return sv;
}

#endif
