#ifndef EASYXS_NUMERIC_H
#define EASYXS_NUMERIC_H 1

#include "init.h"

UV _easyxs_SvUV (pTHX_ SV* sv) {
    if (!SvOK(sv)) _EASYXS_CROAK_UNDEF("unsigned integer");

    if (SvROK(sv)) _EASYXS_CROAK_STRINGIFY_REFERENCE(sv);

    if (SvUOK(sv)) return SvUV(sv);

    if (SvIOK(sv)) {
        IV myiv = SvIV(sv);

        if (myiv >= 0) return myiv;
    }
    else {
        STRLEN pvlen;
        const char* pv = SvPVbyte(sv, pvlen);

        UV myuv;
        int grokked = grok_number(pv, pvlen, &myuv);

        if (grokked & (IS_NUMBER_IN_UV | !IS_NUMBER_NEG)) {
            const char* uvstr = form("%" UVuf, myuv);

            if (strlen(uvstr) == pvlen && strEQ(uvstr, pv)) return myuv;
        }
    }

    croak("`%" SVf "` given where unsigned integer expected!", sv);
}

#define exs_SvUV(sv) _easyxs_SvUV(aTHX_ sv)

UV _easyxs_SvIV (pTHX_ SV* sv) {
    if (!SvOK(sv)) _EASYXS_CROAK_UNDEF("integer");

    if (SvROK(sv)) _EASYXS_CROAK_STRINGIFY_REFERENCE(sv);

    if (SvIOK(sv)) return SvIV(sv);

    STRLEN pvlen;
    const char* pv = SvPVbyte(sv, pvlen);

    IV myiv;
    int grokked = grok_number(pv, pvlen, (UV*) &myiv);

    if (!(grokked & IS_NUMBER_NOT_INT) && !(grokked & IS_NUMBER_IN_UV)) {
        const char* ivstr = form("%" IVdf, myiv);

        if (strlen(ivstr) == pvlen && strEQ(ivstr, pv)) return myiv;
    }

    croak("`%" SVf "` given where integer expected!", sv);
}

#define exs_SvIV(sv) _easyxs_SvIV(aTHX_ sv)

#endif
