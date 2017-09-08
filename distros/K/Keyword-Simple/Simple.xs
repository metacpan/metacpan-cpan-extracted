/*
Copyright 2012, 2013, 2017 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
 */

#ifdef __GNUC__
 #if __GNUC__ >= 5
  #define IF_HAVE_GCC_5(X) X
 #endif

 #if (__GNUC__ == 4 && __GNUC_MINOR__ >= 6) || __GNUC__ >= 5
  #define PRAGMA_GCC_(X) _Pragma(#X)
  #define PRAGMA_GCC(X) PRAGMA_GCC_(GCC X)
 #endif
#endif

#ifndef IF_HAVE_GCC_5
 #define IF_HAVE_GCC_5(X)
#endif

#ifndef PRAGMA_GCC
 #define PRAGMA_GCC(X)
#endif

#ifdef DEVEL
 #define WARNINGS_RESET PRAGMA_GCC(diagnostic pop)
 #define WARNINGS_ENABLEW(X) PRAGMA_GCC(diagnostic error #X)
 #define WARNINGS_ENABLE \
    WARNINGS_ENABLEW(-Wall) \
    WARNINGS_ENABLEW(-Wextra) \
    WARNINGS_ENABLEW(-Wundef) \
    WARNINGS_ENABLEW(-Wshadow) \
    WARNINGS_ENABLEW(-Wbad-function-cast) \
    WARNINGS_ENABLEW(-Wcast-align) \
    WARNINGS_ENABLEW(-Wwrite-strings) \
    WARNINGS_ENABLEW(-Wstrict-prototypes) \
    WARNINGS_ENABLEW(-Wmissing-prototypes) \
    WARNINGS_ENABLEW(-Winline) \
    WARNINGS_ENABLEW(-Wdisabled-optimization) \
    IF_HAVE_GCC_5(WARNINGS_ENABLEW(-Wnested-externs))

#else
 #define WARNINGS_RESET
 #define WARNINGS_ENABLE
#endif


#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>

#ifdef DEVEL
#undef NDEBUG
#endif
#include <assert.h>

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#ifndef STATIC_ASSERT_STMT
 #if (defined(static_assert) || (defined(__cplusplus) && __cplusplus >= 201103L)) && (!defined(__IBMC__) || __IBMC__ >= 1210)
 /* static_assert is a macro defined in <assert.h> in C11 or a compiler
    builtin in C++11.  But IBM XL C V11 does not support _Static_assert, no
    matter what <assert.h> says.
 */
 #  define STATIC_ASSERT_DECL(COND) static_assert(COND, #COND)
 #else
 /* We use a bit-field instead of an array because gcc accepts
    'typedef char x[n]' where n is not a compile-time constant.
    We want to enforce constantness.
 */
 #  define STATIC_ASSERT_2(COND, SUFFIX) \
     typedef struct { \
         unsigned int _static_assertion_failed_##SUFFIX : (COND) ? 1 : -1; \
     } _static_assertion_failed_##SUFFIX PERL_UNUSED_DECL
 #  define STATIC_ASSERT_1(COND, SUFFIX) STATIC_ASSERT_2(COND, SUFFIX)
 #  define STATIC_ASSERT_DECL(COND)    STATIC_ASSERT_1(COND, __LINE__)
 #endif
 /* We need this wrapper even in C11 because 'case X: static_assert(...);' is an
    error (static_assert is a declaration, and only statements can have labels).
 */
 #define STATIC_ASSERT_STMT(COND)      do { STATIC_ASSERT_DECL(COND); } while (0)
#endif

WARNINGS_ENABLE


#define MY_PKG "Keyword::Simple"

#define HINTK_KEYWORDS MY_PKG "/keywords"


#ifndef PL_rsfp_filters
#define PL_rsfp_filters (PL_parser->rsfp_filters)
#endif

#ifndef PL_parser_filtered
 #if HAVE_PERL_VERSION(5, 15, 5)
  #define PL_parser_filtered (PL_parser->filtered)
 #else
  #define PL_parser_filtered 0
 #endif
#endif


static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static SV *kw_handler(pTHX_ const char *kw_ptr, STRLEN kw_len) {
    HV *hints;
    SV **psv, *sv, *sv2;
    I32 kw_xlen;


    /* don't bother doing anything fancy after a syntax error */
    if (PL_parser && PL_parser->error_count) {
        return NULL;
    }

    STATIC_ASSERT_STMT(~(STRLEN)0 > (U32)I32_MAX);
    if (kw_len > (STRLEN)I32_MAX) {
        return NULL;
    }

    if (!(hints = GvHV(PL_hintgv))) {
        return NULL;
    }

    if (!(psv = hv_fetchs(hints, HINTK_KEYWORDS, 0))) {
        return NULL;
    }

    sv = *psv;
    if (!(SvROK(sv) && (sv2 = SvRV(sv), SvTYPE(sv2) == SVt_PVHV))) {
        croak("%s: internal error: $^H{'%s'} not a hashref: %"SVf, MY_PKG, HINTK_KEYWORDS, SVfARG(sv));
    }

    kw_xlen = kw_len;
    if (lex_bufutf8()) {
        kw_xlen = -kw_xlen;
    }
    if (!(psv = hv_fetch((HV *)sv2, kw_ptr, kw_xlen, 0))) {
        return NULL;
    }

    sv = *psv;
    if (!(SvROK(sv) && (sv2 = SvRV(sv), SvTYPE(sv2) == SVt_PVCV))) {
        croak("%s: internal error: $^H{'%s'}{'%.*s'} not a coderef: %"SVf, MY_PKG, HINTK_KEYWORDS, (int)kw_len, kw_ptr, SVfARG(sv));
    }

    return sv2;
}

static I32 playback(pTHX_ int idx, SV *buf, int n) {
    char *ptr;
    STRLEN len, d;
    SV *sv = FILTER_DATA(idx);

    ptr = SvPV(sv, len);
    if (!len) {
        return 0;
    }

    if (!n) {
        char *nl = memchr(ptr, '\n', len);
        d = nl ? (STRLEN)(nl - ptr + 1) : len;
    } else {
        d = n < 0 ? INT_MAX : n;
        if (d > len) {
            d = len;
        }
    }

    sv_catpvn(buf, ptr, d);
    sv_chop(sv, ptr + d);
    return 1;
}

static void total_recall(pTHX_ SV *cb) {
    SV *sv;
    dSP;

    ENTER;
    SAVETMPS;

    sv = sv_2mortal(newSVpvs(""));
    if (lex_bufutf8()) {
        SvUTF8_on(sv);
    }

    /* sluuuuuurrrrp */

    sv_setpvn(sv, PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr);
    lex_unstuff(PL_parser->bufend); /* you saw nothing */

    if (PL_parser->rsfp || PL_parser_filtered) {
        if (!PL_rsfp_filters) {
            /* because FILTER_READ fails with filters=null but DTRT with filters=[] */
            PL_rsfp_filters = newAV();
        }
        while (FILTER_READ(0, sv, 4096) > 0)
            ;
    }

    PUSHMARK(SP);
    mXPUSHs(newRV_inc(sv));
    PUTBACK;

    call_sv(cb, G_VOID);
    SPAGAIN;

    { /* $sv .= "\n" */
        char *p;
        STRLEN n;
        SvPV_force(sv, n);
        p = SvGROW(sv, n + 2);
        p[n] = '\n';
        p[n + 1] = '\0';
        SvCUR_set(sv, n + 1);
    }

    if (PL_parser->rsfp || PL_parser_filtered) {
        filter_add(playback, SvREFCNT_inc_simple_NN(sv));
        CopLINE_dec(PL_curcop);
    } else {
        lex_stuff_sv(sv, 0);
    }

    FREETMPS;
    LEAVE;
}

static int my_keyword_plugin(pTHX_ char *keyword_ptr, STRLEN keyword_len, OP **op_ptr) {
    SV *cb;

    if ((cb = kw_handler(aTHX_ keyword_ptr, keyword_len))) {
        total_recall(aTHX_ cb);
        *op_ptr = newOP(OP_NULL, 0);
        return KEYWORD_PLUGIN_STMT;
    }

    return next_keyword_plugin(aTHX_ keyword_ptr, keyword_len, op_ptr);
}


static void my_boot(pTHX) {
    HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);

    newCONSTSUB(stash, "HINTK_KEYWORDS", newSVpvs(HINTK_KEYWORDS));

    next_keyword_plugin = PL_keyword_plugin;
    PL_keyword_plugin = my_keyword_plugin;
}

WARNINGS_RESET

MODULE = Keyword::Simple   PACKAGE = Keyword::Simple
PROTOTYPES: ENABLE

BOOT:
    my_boot(aTHX);
