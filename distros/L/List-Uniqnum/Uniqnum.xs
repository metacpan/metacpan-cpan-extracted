
#define PERL_NO_GET_CONTEXT 1


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#ifndef sv_setpvs
#  define sv_setpvs(sv, str)             sv_setpvn(sv, str "", sizeof(str) - 1)
#endif

/* For uniqnum, define ACTUAL_NVSIZE to be the number *
 * of bytes that are actually used to store the NV    */

#if defined(USE_LONG_DOUBLE) && LDBL_MANT_DIG == 64
#define ACTUAL_NVSIZE 10
#else
#define ACTUAL_NVSIZE NVSIZE
#endif

int uv_fits_double(UV arg) {

  /* This function is no longer used.                   *
   * The value passed was always > 9007199254740992     *
   * and always <= 18446744073709551615.                *
   * Return true if there are no more than 51 bits	*
   * between the most significant set bit and the	*
   * least significant set bit - in which case the	*
   * value can be exactly represented by a double.	*/

  while(!(arg & 1)) {
    arg >>= 1;
    if(arg < 9007199254740992) return 1;
  }

  return 0;
}  

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
#if NVSIZE > IVSIZE                          /* $Config{nvsize} > $Config{ivsize} */
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
             * ACTUAL_NVSIZE == sizeof(NV) minus the number of bytes           *
             * that are allocated but never used. (It is only the 10-byte      *
             * extended precision long double that allocates bytes that are    *
             * never used. For all other NV types ACTUAL_NVSIZE == sizeof(NV). */
            sv_setpvn(keysv, (char *) &nv_arg, ACTUAL_NVSIZE);  
        }
#else                                       /* $Config{nvsize} == $Config{ivsize} == 8 */ 
        if(!SvOK(arg) || SvUOK(arg)) {
            UV uv = SvUV(arg);

            /* Set keysv to the bytes of SvNV(arg) if and only if *
               SvUV(arg) can be exactly represented as a double   */

            while(!(uv & 1) && uv > 9007199254740992)
                uv >>= 1;

            if(uv < 9007199254740993) { /* SvUV(arg) can be represented precisely by a double */
                nv_arg = SvNV(arg);
                sv_setpvn(keysv, (char *) &nv_arg, 8);
            }
            else
            sv_setpvf(keysv, "%" UVuf, SvUV(arg));
        }
        else if(SvIOK(arg)) {
            /* Set unsign to absolute value of SvIV(arg) */
            UV unsign = SvIV(arg) < 0 ? SvIV(arg) * -1 : SvIV(arg);
            
            /* Set keysv to the bytes of SvNV(arg) if and only if *
               SvIV(arg) can be exactly represented as a double   */
                 
            while(!(unsign & 1) && unsign > 9007199254740992)
                unsign >>= 1;

            if(unsign < 9007199254740993) { /* SvIV(arg) can be represented precisely by a double */
                nv_arg = SvNV(arg);
                sv_setpvn(keysv, (char *) &nv_arg, 8);
            }
            else
            sv_setpvf(keysv, "%" IVdf, SvIV(arg));
        }
        else {
            nv_arg = SvNV(arg);

            /* for NaN, use the platform's normal stringification */

            if (nv_arg != nv_arg) {
                sv_setpvf(keysv, "%" NVgf, nv_arg);
            }
            else {
                if(nv_arg == 0.0) {
                    nv_arg = 0.0; /* Ensure that nv_arg is 0.0, not -0.0 */
                }
                sv_setpvn(keysv, (char *) &nv_arg, 8);
            }
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

int _have_msc_ver(void) {
#ifdef _MSC_VER
  return _MSC_VER;
#else
  return 0;
#endif
}


MODULE = List::Uniqnum  PACKAGE = List::Uniqnum  

PROTOTYPES: DISABLE


int
uv_fits_double (arg)
	UV	arg

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

int
_have_msc_ver ()
		

