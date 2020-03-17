
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

        /* use 0 for all zeros */
        if(nv_arg == 0) sv_setpvs(keysv, "0");

        /* for NaN, use the platform's normal stringification */
        else if (nv_arg != nv_arg) sv_setpvf(keysv, "%" NVgf, nv_arg);
#ifdef NV_IS_DOUBLEDOUBLE
        /* If the least significant double is zero, it could be either 0.0     *
         * or -0.0. We therefore ignore the least significant double and       *
         * assign to keysv the bytes of the most significant double only.      */
        else if(nv_arg == (double)nv_arg) {
            double double_arg = (double)nv_arg;
            sv_setpvn(keysv, (char *) &double_arg, 8);
        }
#endif
        else {
            /* Use the byte structure of the NV.                               *
             * ACTUAL_NVSIZE == sizeof(NV) minus the number of bytes           *
             * that are allocated but never used. (It is only the 10-byte      *
             * extended precision long double that allocates bytes that are    *
             * never used. For all other NV types ACTUAL_NVSIZE == sizeof(NV). */
            sv_setpvn(keysv, (char *) &nv_arg, ACTUAL_NVSIZE);  
        }
#else                                    /* $Config{nvsize} == $Config{ivsize} == 8 */ 
        if( SvIOK(arg) || !SvOK(arg) ) {

           /* It doesn't matter if SvUOK(arg) is TRUE */
            IV iv = SvIV(arg);

           /* use "0" for all zeros */
            if(iv == 0) sv_setpvs(keysv, "0");

            else {
                int uok = SvUOK(arg);
                int sign = ( iv > 0 || uok ) ? 1 : -1;

                /* Set keysv to the bytes of SvNV(arg) if and only if the integer value  *
                 * held by arg can be represented exactly as a double - ie if there are  *
                 * no more than 51 bits between its least significant set bit and its    *
                 * most significant set bit.                                             *
                 * The neatest approach I could find was provided by roboticus at:       *
                 *     https://www.perlmonks.org/?node_id=11113490                       *
                 * First, identify the lowest set bit and assign its value to an IV.     *
                 * Note that this value will always be > 0, and always a power of 2.     */
                IV lowest_set = iv & -iv;

                /* Second, shift it left 53 bits to get location of arg's highest        *
                 * "allowed" set bit.                                                    *
                 * NOTE: If lowest set bit is initially far enough left, then this left  *
                 * shift operation will result in a value of 0, which is fine.           *
                 * Then subtract 1 so that all of the ("allowed") bits below the set bit *
                 * are 1 && all other ("disallowed") bits are set to 0.                  *
                 * (If the value prior to subtraction was 0, then subtracing 1 will set  *
                 * all bits - which is also fine.)                                       */ 
                UV valid_bits = (lowest_set << 53) - 1;

                /* The value of arg can be exactly represented by a double unless one    *
                 * or more of its "disallowed" bits are set - ie if iv & (~valid_bits)   *
                 * is untrue. However, if (iv < 0 && !SvUOK(arg)) we need to multiply it *
                 * by -1 prior to performing that '&' operation.                         */
                if( !((iv * sign) & (~valid_bits)) ) {
                    nv_arg = SvNV(arg);
                    sv_setpvn(keysv, (char *) &nv_arg, 8);
                }          
                else {
                    sv_setpvn(keysv, (char *) &iv, 8);
                   /* We add an extra byte to distinguish between IV/UV and an NV.       *
                    * We also use that byte to distinguish between a -ve IV and a UV.    *
                    * This is more efficient than reading in the value of the IV/UV.     */
                    if(uok) sv_catpvn(keysv, "U", 1);
                    else    sv_catpvn(keysv, "I", 1);
                }
            }
        }
        else {
            nv_arg = SvNV(arg);

            /* for NaN, use the platform's normal stringification */
            if (nv_arg != nv_arg) sv_setpvf(keysv, "%" NVgf, nv_arg);

            /* use "0" for all zeros */
            else if(nv_arg == 0) sv_setpvs(keysv, "0");
            else sv_setpvn(keysv, (char *) &nv_arg, 8);
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
		

