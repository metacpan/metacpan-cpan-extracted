#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_sv_2pv_flags 1
#include "ppport.h"

#if PERL_BCDVERSION >= 0x5006000
#  include "multicall.h"
#endif

#if PERL_BCDVERSION < 0x5023008
#  define UNUSED_VAR_newsp PERL_UNUSED_VAR(newsp)
#else
#  define UNUSED_VAR_newsp NOOP
#endif

#ifndef CvISXSUB
#  define CvISXSUB(cv) CvXSUB(cv)
#endif

#if PERL_VERSION < 13 || (PERL_VERSION == 13 && PERL_SUBVERSION < 9)
#  define PERL_HAS_BAD_MULTICALL_REFCOUNT
#endif

#ifdef __cplusplus
} /* extern "C" */
#endif

MODULE = List::ToHash    PACKAGE = List::ToHash

PROTOTYPES: DISABLE

void
to_hash(block,...)
    SV *block
PROTOTYPE: &@
CODE:
{
    HV *hv = newHV();
    SV *ret = sv_2mortal(newRV_noinc((SV *)hv));
    int index;
    GV *gv;
    HV *stash;
    SV **args = &PL_stack_base[ax];
    CV *cv    = sv_2cv(block, &stash, &gv, 0);
    char *key;
    STRLEN keylen;

    if(cv == Nullcv)
        croak("Not a subroutine reference");

    ST(0) = ret;

    if(items <= 1)
        XSRETURN(1);

    SAVESPTR(GvSV(PL_defgv));
#ifdef dMULTICALL
    assert(cv);
    if(!CvISXSUB(cv)) {
        dMULTICALL;
        I32 gimme = G_SCALAR;

        UNUSED_VAR_newsp;
        PUSH_MULTICALL(cv);

        for(index = 1 ; index < items ; index++) {
            SV *def_sv = GvSV(PL_defgv) = args[index];
#  ifdef SvTEMP_off
            SvTEMP_off(def_sv);
#  endif
            MULTICALL;
            if (SvOK(*PL_stack_sp)) {
                key = SvPV(*PL_stack_sp, keylen);
                (void)hv_store(hv,
                            key,
                            keylen,
                            SvREFCNT_inc(args[index]), 0);
            }
        }
#  ifdef PERL_HAS_BAD_MULTICALL_REFCOUNT
        if(CvDEPTH(multicall_cv) > 1)
            SvREFCNT_inc_simple_void_NN(multicall_cv);
#  endif
        POP_MULTICALL;
    }
    else
#endif
    {
        for(index = 1 ; index < items ; index++) {
            dSP;
            GvSV(PL_defgv) = args[index];

            PUSHMARK(SP);
            call_sv((SV*)cv, G_SCALAR);
            if (SvOK(*PL_stack_sp)) {
                key = SvPV(*PL_stack_sp, keylen);
                (void)hv_store(hv,
                            key,
                            keylen,
                            SvREFCNT_inc(args[index]), 0);
            }
        }
    }

    XSRETURN(1);
}
