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

#endif
