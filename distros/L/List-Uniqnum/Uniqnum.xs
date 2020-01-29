
#ifdef _WIN32
#  ifndef __USE_MINGW_ANSIO_STDIO

     /* Satisfy uniqnum formatting requirements *
      * when using mingw ports of gcc           */
#     define __USE_MINGW_ANSI_STDIO 1

     /* Identify that perl's ccflags have  *
      * not defined __USE_MINGW_STDIO_ANSI */
#     define WIN32_PERL_NO_ANSI 1

#  endif
#endif

#define PERL_NO_GET_CONTEXT 1


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#ifndef sv_setpvs
#  define sv_setpvs(sv, str)             sv_setpvn(sv, str "", sizeof(str) - 1)
#endif

void uniqnum(pTHX_ SV * input_sv, ...) {
    dXSARGS;
    int retcount = 0;
    int index;
    SV **args = &PL_stack_base[ax];
    HV *seen;

    SV *keysv;
    SV *arg;
    NV nv_arg;

#ifdef HV_FETCH_EMPTY_HE
        HE* he;
#endif
#ifdef WIN32_PERL_NO_ANSI
        char buffer[32];
#endif

    if(items == 0 || (items == 1 && !SvGAMAGIC(args[0]) && SvOK(args[0]))) {
        /* Optimise for the case of the empty list or a defined nonmagic
         * singleton. Leave a singleton magical||undef for the regular case */
        retcount = items;
        goto finish;
    }

    sv_2mortal((SV *)(seen = newHV()));


    /* uniqnum */
    /* A temporary buffer for number stringification */
    keysv = sv_newmortal();

    for(index = 0 ; index < items ; index++) {
        arg = args[index];

        if(SvGAMAGIC(arg))
            /* clone the value so we don't invoke magic again */
            arg = sv_mortalcopy(arg);

        if(SvOK(arg) && !(SvUOK(arg) || SvIOK(arg) || SvNOK(arg))) {
#if PERL_VERSION >= 8
            SvIV(arg); /* sets SVf_IOK/SVf_IsUV if it's an integer */
#else
            SvNV(arg); /* SvIV() sets SVf_IOK even on floats on 5.6 */
#endif
        }
#ifdef NVSIZE_EQUAL_IVSIZE      /* Defined by Makefile.PL if $Config{nvsize} == $Config{ivsize} */
        if(!SvOK(arg) || SvUOK(arg)) {
            sv_setpvf(keysv, "%" UVuf, SvUV(arg));
        }
        else if(SvIOK(arg)) {
            sv_setpvf(keysv, "%" IVdf, SvIV(arg));
        }
        else {
            nv_arg = SvNV(arg);
            /* use 0 for both 0 and -0.0 */
            if(nv_arg == 0) {
                sv_setpvs(keysv, "0");
            }
            /* for NaN, use the platform's normal stringification */
            else if (nv_arg != nv_arg) {
                sv_setpvf(keysv, "%" NVgf, nv_arg);
            }
            /* for numbers outside of the IV or UV range, we don't need to
             * use a comparable format, so just use the raw bytes, adding
             * 'f' to ensure not matching a stringified number */
            else if (nv_arg < (NV)IV_MIN || nv_arg > (NV)UV_MAX) {
                sv_setpvn(keysv, (char *) &nv_arg, 8);  /* sizeof(NV) == 8 */
                sv_catpvn(keysv, "f", 1);
            }
            /* smaller floats get formatted using %g and could be equal to
             * a UV or IV */
            else {
#ifdef WIN32_PERL_NO_ANSI

               /* Because perl was not built with ansi compliance, doing: *
                * sv_setpvf(keysv, "%0.20" NVgf, nv_arg)                  *
                * will not always work as intended.                       *
                * But the following workaround does what we want.         */

                sprintf(buffer, "%0.20" NVgf, nv_arg);
                sv_setpvf(keysv, "%s", buffer);                    
#else
                sv_setpvf(keysv, "%0.20" NVgf, nv_arg);
#endif
            }
        }
#else                          /* $Config{nvsize} > $Config{ivsize} */
        nv_arg = SvNV(arg);

        if(nv_arg == 0) {
            /* use 0 for both 0 and -0.0 */
            sv_setpvs(keysv, "0");
        }
        else if (nv_arg != nv_arg) {
            /* for NaN, use the platform's normal stringification */
            sv_setpvf(keysv, "%" NVgf, nv_arg);
        }
        else {
            /* Use the byte structure of the NV.                               *
             * USED_NV_BYTES == sizeof(NV) minus the number of bytes           *
             * that are allocated but never used. (It is only the 10-byte      *
             * extended precision long double that allocates bytes that are    *
             * never used. For all other NV types USED_NV_BYTES == sizeof(NV). */
            sv_setpvn(keysv, (char *) &nv_arg, USED_NV_BYTES);  
        }
#endif
#ifdef HV_FETCH_EMPTY_HE
        he = (HE*) hv_common(seen, NULL, SvPVX(keysv), SvCUR(keysv), 0, HV_FETCH_LVALUE | HV_FETCH_EMPTY_HE, NULL, 0);
        if (HeVAL(he))
            continue;
        HeVAL(he) = &PL_sv_undef;
#else
        if(hv_exists(seen, SvPVX(keysv), SvCUR(keysv)))
            continue;
         hv_store(seen, SvPVX(keysv), SvCUR(keysv), &PL_sv_yes, 0);
#endif

        if(GIMME_V == G_ARRAY)
            ST(retcount) = SvOK(arg) ? arg : sv_2mortal(newSViv(0));
        retcount++;
    }

  finish:
    if(GIMME_V == G_ARRAY) {
        XSRETURN(retcount);
    }
    else {
        ST(0) = sv_2mortal(newSViv(retcount));
        XSRETURN(1);       
    }
}


MODULE = List::Uniqnum  PACKAGE = List::Uniqnum  

PROTOTYPES: DISABLE


void
uniqnum (input_sv, ...)
	SV *	input_sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        uniqnum(aTHX_ input_sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

