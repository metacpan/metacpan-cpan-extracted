#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

MODULE = Hash::Util::Pick    PACKAGE = Hash::Util::Pick

PROTOTYPES: DISABLED

void
pick(...)
PROTOTYPE: $@
PPCODE:
{
    SV **args = &PL_stack_base[ax];
    HV *src = SvROK(args[0]) ?
        (HV*)SvRV(args[0]) : (HV*)sv_2mortal((SV*)newHV());

    I32 i;
    HV *dest = (HV*)sv_2mortal((SV*)newHV());

    for (i = 1; i < items; ++i) {
        if (hv_exists_ent(src, args[i], 0)) {
            HE *he = hv_fetch_ent(src, args[i], 0, 0);
            if (he) {
                SV *v = HeVAL(he);
                hv_store_ent(dest, args[i], v, 0);
            }
        }
    }

    XPUSHs(newRV_inc((SV*)dest));
    XSRETURN(1);
}

void
pick_by(...)
PROTOTYPE: $&
PPCODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;

    HV *src = SvROK(ST(0)) ?
        (HV*)SvRV(ST(0)) : (HV*)sv_2mortal((SV*)newHV());

    if (!SvROK(ST(1)) || SvTYPE((SV*)SvRV(ST(1))) != SVt_PVCV) {
        XPUSHs(newRV_noinc((SV*)newHV()));
        XSRETURN(1);
    }

    CV *code = sv_2cv(SvRV(ST(1)), &stash, &gv, 0);

    char *hkey;
    I32 hkeylen;
    SV *value;
    HV *dest = (HV*)sv_2mortal((SV*)newHV());

    PUSH_MULTICALL(code);
    SAVESPTR(GvSV(PL_defgv));

    hv_iterinit(src);

    while ((value = hv_iternextsv(src, &hkey, &hkeylen)) != NULL) {
        GvSV(PL_defgv) = value;
        MULTICALL;
        if (SvTRUE(*PL_stack_sp)) {
            hv_store(dest, hkey, hkeylen, value, 0);
        }
    }

    POP_MULTICALL;

    XPUSHs(newRV_inc((SV*)dest));
    XSRETURN(1);
}

void
omit(...)
PROTOTYPE: $@
PPCODE:
{
    SV **args = &PL_stack_base[ax];
    HV *src = SvROK(args[0]) ?
        (HV*)SvRV(args[0]) : (HV*)sv_2mortal((SV*)newHV());

    I32 i;
    HV *dest = (HV*)sv_2mortal((SV*)newHV());
    HV *omit_key_to_exist = (HV*)sv_2mortal((SV*)newHV());

    for (i = 1; i < items; ++i) {
        hv_store_ent(omit_key_to_exist, args[i], &PL_sv_yes, 0);
    }

    char *hkey;
    I32 hkeylen;
    SV *value;

    hv_iterinit(omit_key_to_exist);

    while ((value = hv_iternextsv(src, &hkey, &hkeylen)) != NULL) {
        if (!hv_exists(omit_key_to_exist, hkey, hkeylen)) {
            SV **svp = hv_fetch(src, hkey, hkeylen, 0);
            if (svp) {
                hv_store(dest, hkey, hkeylen, *svp, 0);
            }
        }
    }

    XPUSHs(newRV_inc((SV*)dest));
    XSRETURN(1);
}

void
omit_by(...)
PROTOTYPE: $&
PPCODE:
{
    dMULTICALL;
    GV *gv;
    HV *stash;
    I32 gimme = G_SCALAR;

    HV *src = SvROK(ST(0)) ?
        (HV*)SvRV(ST(0)) : (HV*)sv_2mortal((SV*)newHV());
    HV *dest = (HV*)sv_2mortal((SV*)newHV());

    char *hkey;
    I32 hkeylen;
    SV *value;

    if (!SvROK(ST(1)) || SvTYPE((SV*)SvRV(ST(1))) != SVt_PVCV) {
        while ((value = hv_iternextsv(src, &hkey, &hkeylen)) != NULL) {
            hv_store(dest, hkey, hkeylen, value, 0);
        }

        XPUSHs(newRV_inc((SV*)dest));
        XSRETURN(1);
    }

    CV *code = sv_2cv(SvRV(ST(1)), &stash, &gv, 0);

    PUSH_MULTICALL(code);
    SAVESPTR(GvSV(PL_defgv));

    hv_iterinit(src);

    while ((value = hv_iternextsv(src, &hkey, &hkeylen)) != NULL) {
        GvSV(PL_defgv) = value;
        MULTICALL;
        if (!SvTRUE(*PL_stack_sp)) {
            hv_store(dest, hkey, hkeylen, value, 0);
        }
    }

    POP_MULTICALL;

    XPUSHs(newRV_inc((SV*)dest));
    XSRETURN(1);
}

