#ifndef JSF_FRJ_H
#define JSF_FRJ_H

/* JSON decode through File::Raw::JSON's C ABI (frj_abi.h), resolved lazily at
 * runtime via File::Raw::JSON::_abi_ptr - schema text and fetched documents are
 * parsed in C with no per-call Perl codec dispatch. Mirrors jsf_fetch.h's
 * resolve idiom. Reached through ExtUtils::Depends (no vendored header). Needs
 * the Perl API (perl.h, included by the .xs). */

#include "frj_abi.h"

static const frj_abi *JSF_FRJ = NULL;   /* resolved on first decode */
static int            JSF_FRJ_TRIED = 0;

/* Resolve File::Raw::JSON's ABI table once; NULL if unavailable. */
static const frj_abi *jsf_frj(pTHX) {
    if (!JSF_FRJ && !JSF_FRJ_TRIED) {
        dSP; int count; IV p = 0;
        JSF_FRJ_TRIED = 1;
        eval_pv("require File::Raw::JSON;", FALSE);
        /* The require runs arbitrary Perl and may have grown the value stack,
         * which reallocates it; SP was captured before that and would then be
         * a pointer into the freed block, published straight back to the
         * interpreter by the PUTBACK below. */
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const frj_abi *a = INT2PTR(const frj_abi *, p);
                if (a && a->abi_version == FRJ_ABI_VERSION) JSF_FRJ = a;
            }
        }
    }
    return JSF_FRJ;
}

/* Decode JSON bytes -> a mortal SV, or NULL if File::Raw::JSON is unavailable
 * (the caller decides whether that is fatal). Croaks on malformed JSON. */
static SV *jsf_frj_decode(pTHX_ SV *text) {
    const frj_abi *J = jsf_frj(aTHX);
    STRLEN len;
    const char *pv;
    if (!J) return NULL;
    pv = SvPV(text, len);
    return sv_2mortal(J->decode(aTHX_ pv, len, NULL));
}

#endif /* JSF_FRJ_H */
