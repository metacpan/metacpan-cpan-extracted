#ifndef FT_JSON_H
#define FT_JSON_H

/* JSON for the `json =>` request option (encode) and Fetch::Response->json
 * (decode), through File::Raw::JSON's C ABI (frj_abi.h) - decoded/encoded
 * entirely in C, with no per-call Perl dispatch and no Cpanel::JSON::XS /
 * JSON::PP dependency. Encoding is canonical UTF-8 (allow_nonref); true/false
 * decode to File::Raw::JSON::Boolean, null to undef. The versioned ABI table is
 * resolved lazily on first use. Needs the Perl API (perl.h, via the .xs). */

#include "frj_abi.h"      /* reached through ExtUtils::Depends */

static const frj_abi *FT_FRJ = NULL;   /* resolved on first JSON op */
static int            FT_FRJ_TRIED = 0;

/* Resolve File::Raw::JSON's ABI table once. It is a hard dependency (loaded by
 * Fetch.pm), so a failure to resolve is fatal rather than a silent fallback. */
static const frj_abi *ft_frj(pTHX) {
    if (!FT_FRJ && !FT_FRJ_TRIED) {
        dSP; int count; IV p = 0;
        FT_FRJ_TRIED = 1;
        eval_pv("require File::Raw::JSON;", FALSE);
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const frj_abi *a = INT2PTR(const frj_abi *, p);
                if (a && a->abi_version == FRJ_ABI_VERSION) FT_FRJ = a;
            }
        }
    }
    if (!FT_FRJ)
        croak("Fetch: JSON needs File::Raw::JSON with a compatible C ABI "
              "(FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
    return FT_FRJ;
}

/* $data -> canonical UTF-8 JSON bytes (SV +1, owned). Croaks on a bad shape. */
static SV *ft_json_encode(pTHX_ SV *data) {
    const frj_abi *J = ft_frj(aTHX);
    frj_opts o;
    J->opts_init(&o);
    o.canonical = 1;                 /* was ->utf8->allow_nonref->canonical */
    return J->encode(aTHX_ data, &o);
}

/* JSON bytes -> Perl data (SV +1, owned). Croaks on malformed JSON. */
static SV *ft_json_decode(pTHX_ SV *bytes) {
    const frj_abi *J = ft_frj(aTHX);
    STRLEN len;
    const char *pv = SvPV(bytes, len);
    return J->decode(aTHX_ pv, len, NULL);   /* NULL opts => defaults (utf8 on) */
}

#endif /* FT_JSON_H */
