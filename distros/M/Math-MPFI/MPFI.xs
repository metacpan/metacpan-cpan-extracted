
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_mpfi_include.h"
#include "math_mpfi_unused.h"

int nok_pok = 0; /* flag that is incremented whenever a scalar that is both *
                  * NOK and POK is passed to new or an overloaded operator  */

int NOK_POK_val(pTHX) {
  /* return the numeric value of $Math::MPFI::NOK_POK */
  return SvIV(get_sv("Math::MPFI::NOK_POK", 0));
}

int _win32_infnanstring(char * s) { /* MS Windows only - detect 1.#INF and 1.#IND
                                     * Need to do this to correctly handle a scalar
                                     * that is both NOK and POK on older win32 perls */

  /*************************************
  * if input string    =~ /^\-1\.#INF$/ return -1
  * elsif input string =~ /^\+?1\.#INF$/i return 1
  * elsif input string =~ /^(\-|\+)?1\.#IND$/i return 2
  * else return 0
  **************************************/

#ifdef _WIN32_BIZARRE_INFNAN

  int sign = 1;
  int factor = 1;

  if(s[0] == '-') {
    sign = -1;
    s++;
  }
  else {
    if(s[0] == '+') s++;
  }

  if(!strcmp(s, "1.#INF")) return sign;
  if(!strcmp(s, "1.#IND")) return 2;

  return 0;
#else
  PERL_UNUSED_ARG(s);
  croak("Math::MPFI::_win32_infnanstring not implemented for this build of perl");
#endif
}

/* Has inttypes.h been included ?
              &&
 Do we have MATH_MPFI_NEED_LONG_LONG_INT ? */

int _has_inttypes(void) {
#ifdef _MSC_VER
return 0;
#else
#if defined MATH_MPFI_NEED_LONG_LONG_INT
return 1;
#else
return 0;
#endif
#endif
}

int _has_longlong(void) {
#ifdef MATH_MPFI_NEED_LONG_LONG_INT
    return 1;
#else
    return 0;
#endif
}

int _has_longdouble(void) {
#if defined(NV_IS_LONG_DOUBLE) || defined(NV_IS_FLOAT128)
    return 1;
#else
    return 0;
#endif
}

int _nv_is_float128(void) {
#if defined(NV_IS_FLOAT128)
 return 1;
#else
 return 0;
#endif
}

int _required_ldbl_mant_dig(void) {
    return REQUIRED_LDBL_MANT_DIG;
}

int _ivsize_bits(void) {
   int ret = 0;
#ifdef IVSIZE_BITS
   ret = IVSIZE_BITS;
#endif
   return ret;
}

SV * _my_mpfr_set_float128(pTHX_ mpfr_t *p, SV * q, unsigned int round) { /* internal use only */
#if defined(NV_IS_FLOAT128)
     char * buffer;
     int exp, exp2 = 0;
     float128 ld, buffer_size;
     int returned;

     ld = (float128)SvNVX(q);

     if(ld != ld) {
       mpfr_set_nan(*p);
       return newSViv(0);
     }

     if(ld != 0.0Q && (ld / ld != 1)) {
       returned = ld > 0.0Q ? 1 : -1;
       mpfr_set_inf(*p, returned);
       return newSViv(0);
     }

     ld = frexpq((float128)SvNVX(q), &exp);

     while(ld != floorq(ld)) {
          ld *= 2;
          exp2 += 1;
     }

     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Math::MPFI::_my mpfr_set_float128, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In In Math::MPFI::_my mpfr_set_float128, buffer given to quadmath_snprintf function was too small");
     returned = mpfr_set_str(*p, buffer, 10, (mp_rnd_t)round);
     Safefree(buffer);

     if (exp2 > exp) mpfr_div_2ui(*p, *p, exp2 - exp, GMP_RNDN);
     else mpfr_mul_2ui(*p, *p, exp - exp2, GMP_RNDN);
     return newSViv(returned);
#else
     PERL_UNUSED_ARG3(p, q, round);
     croak("Math::MPFI::_my_mpfr_set_float128 not implemented for this build of perl");
#endif
}

/*******************************
Rounding Modes and Precision Handling
*******************************/

SV * RMPFI_BOTH_ARE_EXACT (pTHX_ int ret) {
     if(ret > 3 || ret < 0) croak("Unacceptable value passed to RMPFI_BOTH_ARE_EXACT");
     if(MPFI_BOTH_ARE_EXACT(ret)) return &PL_sv_yes;
     return &PL_sv_no;
}

SV * RMPFI_LEFT_IS_INEXACT (pTHX_ int ret) {
     if(ret > 3 || ret < 0) croak("Unacceptable value passed to RMPFI_LEFT_IS_INEXACT");
     if(MPFI_LEFT_IS_INEXACT(ret)) return &PL_sv_yes;
     return &PL_sv_no;
}

SV * RMPFI_RIGHT_IS_INEXACT (pTHX_ int ret) {
     if(ret > 3 || ret < 0) croak("Unacceptable value passed to RMPFI_RIGHT_IS_INEXACT");
     if(MPFI_RIGHT_IS_INEXACT(ret)) return &PL_sv_yes;
     return &PL_sv_no;
}

SV * RMPFI_BOTH_ARE_INEXACT (pTHX_ int ret) {
     if(ret > 3 || ret < 0) croak("Unacceptable value passed to RMPFI_BOTH_ARE_INEXACT");
     if(MPFI_BOTH_ARE_INEXACT(ret)) return &PL_sv_yes;
     return &PL_sv_no;
}

void _Rmpfi_set_default_prec(pTHX_ SV * p) {
     mpfr_set_default_prec((mp_prec_t)SvUV(p));
}

SV * Rmpfi_get_default_prec(pTHX) {
     return newSVuv(mpfr_get_default_prec());
}

void Rmpfi_set_prec(pTHX_ mpfi_t * op, SV * prec) {
     mpfi_set_prec(*op, (mp_prec_t)SvUV(prec));
}

SV * Rmpfi_get_prec(pTHX_ mpfi_t * op) {
     return newSVuv(mpfi_get_prec(*op));
}

SV * Rmpfi_round_prec(pTHX_ mpfi_t * op, SV * prec) {
     return newSViv(mpfi_round_prec(*op, (mp_prec_t)SvUV(prec)));
}

/*******************************
Initialization Functions
*******************************/

SV * Rmpfi_init(pTHX) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfi_init_nobless(pTHX) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpfi_init(*mpfi_t_obj);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfi_init2(pTHX_ SV * prec) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init2 function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init2 (*mpfi_t_obj, (mp_prec_t)SvUV(prec));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfi_init2_nobless(pTHX_ SV * prec) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init2_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpfi_init2 (*mpfi_t_obj, (mp_prec_t)SvUV(prec));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

void DESTROY(pTHX_ mpfi_t * p) {
     mpfi_clear(*p);
     Safefree(p);
}

void Rmpfi_clear(pTHX_ mpfi_t * p) {
     mpfi_clear(*p);
     Safefree(p);
}

/*******************************
Assignment Functions
*******************************/

int Rmpfi_set (mpfi_t * rop, mpfi_t * op) {
    return mpfi_set(*rop, *op);
}

int Rmpfi_set_ui (mpfi_t * rop, unsigned long op) {
    return mpfi_set_ui(*rop, op);
}

int Rmpfi_set_si (mpfi_t * rop, long op) {
    return mpfi_set_si(*rop, op);
}

int Rmpfi_set_d (pTHX_ mpfi_t * rop, SV * op) {
    return mpfi_set_d(*rop, (double)SvNV(op));
}

int Rmpfi_set_NV (pTHX_ mpfi_t * rop, SV * op) {

#if defined(NV_IS_DOUBLE)
    if(!SV_IS_NOK(op)) croak("Second arg given to Rmpfi_set_NV is not an NV");
    return mpfi_set_d(*rop, (double)SvNVX(op));

#elif defined(NV_IS_LONG_DOUBLE)
    mpfr_t t;
    int ret;
    if(!SV_IS_NOK(op)) croak("Second arg given to Rmpfi_set_NV is not an NV");
    mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
    mpfr_set_ld(t, (long double)SvNVX(op), GMP_RNDN);
    ret = mpfi_set_fr(*rop, t);
    mpfr_clear(t);
    return ret;

#elif defined(MPFI_CAN_PASS_FLOAT128)
    mpfr_t t;
    int ret;
    if(!SV_IS_NOK(op)) croak("Second arg given to Rmpfi_set_NV is not an NV");
    mpfr_init2(t, 113);
    mpfr_set_float128(t, (float128)SvNVX(op), GMP_RNDN);
    ret = mpfi_set_fr(*rop, t);
    mpfr_clear(t);
    return ret;

#else
/* NV_IS_FLOAT128 */
     char * buffer;
     mpfr_t t;
     int exp, exp2 = 0;
     float128 ld, buffer_size;
     int returned;

     if(!SV_IS_NOK(op)) croak("Second arg given to Rmpfi_set_NV is not an NV");

     mpfr_init2(t, 113);
     ld = (float128)SvNVX(op);

     if(ld != ld) {
       mpfr_set_nan(t);
       mpfi_set_fr(*rop, t);
       mpfr_clear(t);
       return 0;
     }

     if(ld != 0.0Q && (ld / ld != 1)) {
       returned = ld > 0.0Q ? 1 : -1;
       mpfr_set_inf(t, returned);
       mpfi_set_fr(*rop, t);
       mpfr_clear(t);
       return 0;
     }

     ld = frexpq((float128)SvNVX(op), &exp);

     while(ld != floorq(ld)) {
          ld *= 2;
          exp2 += 1;
     }

     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Rmpfi_set_NV, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Rmpfi_set_NV, buffer given to quadmath_snprintf function was too small");
     mpfr_set_str(t, buffer, 10, (mp_rnd_t)round);
     Safefree(buffer);

     if (exp2 > exp) mpfr_div_2ui(t, t, exp2 - exp, GMP_RNDN);
     else mpfr_mul_2ui(t, t, exp - exp2, GMP_RNDN);
     returned = mpfi_set_fr(*rop, t);
     mpfr_clear(t);
     return returned;

#endif
}

int Rmpfi_set_z (mpfi_t * rop, mpz_t * op) {
    return mpfi_set_z(*rop, *op);
}

int Rmpfi_set_q (mpfi_t * rop, mpq_t * op) {
     return mpfi_set_q(*rop, *op);
}

int Rmpfi_set_fr (mpfi_t * rop, mpfr_t * op) {
    return mpfi_set_fr(*rop, *op);
}

int Rmpfi_set_str (pTHX_ mpfi_t * rop, SV * s, SV * base) {
#ifdef _WIN32_BIZARRE_INFNAN
       int ret;
       mpfr_t t;

       ret = _win32_infnanstring(SvPV_nolen(s));
       if(ret) {
         mpfr_init(t);
         if(ret != 2) {
           mpfr_set_inf(t, ret);
         }
         ret = mpfi_set_fr(*rop, t);
         mpfr_clear(t);
         return ret;
       }
       else {
         return mpfi_set_str(*rop, (char *)SvPV_nolen(s),SvIV(base));
       }
#else
     return mpfi_set_str(*rop, SvPV_nolen(s), SvIV(base));
#endif
}

void Rmpfi_swap (mpfi_t * x, mpfi_t * y) {
     mpfi_swap(*x, *y);
}

/*******************************
Combined Initialization and Assignment Functions
*******************************/

void Rmpfi_init_set(pTHX_ mpfi_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_ui(pTHX_ SV * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_ui function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set_ui(*mpfi_t_obj, (unsigned long)SvUV(q));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_si(pTHX_ SV * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_si function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set_si(*mpfi_t_obj, (long)SvIV(q));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_d(pTHX_ SV * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_d function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set_d(*mpfi_t_obj, (double)SvNV(q));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_z(pTHX_ mpz_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_z function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set_z(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_q(pTHX_ mpq_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_q function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set_q(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_fr(pTHX_ mpfr_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_fr function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     ret = mpfi_init_set_fr(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_str(pTHX_ SV * q, SV * base) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret = (int)SvIV(base);
     mpfr_t t;
     PERL_UNUSED_ARG(items);

     if(ret < 0 || ret > 36 || ret == 1) croak("2nd argument supplied to Rmpfi_init_set str is out of allowable range");

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_str function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(q));
       if(ret) {
         mpfr_init(t);
         if(ret != 2) {
           mpfr_set_inf(t, ret);
         }
         ret = mpfi_init_set_fr(*mpfi_t_obj, t);
         mpfr_clear(t);
       }
       else {
         ret = mpfi_init_set_str(*mpfi_t_obj, (char *)SvPV_nolen(q),SvIV(base));
       }
#else
     PERL_UNUSED_VAR(t);
     ret = mpfi_init_set_str(*mpfi_t_obj, SvPV_nolen(q), ret);

#endif

     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

/**********************************
 The nobless variants
***********************************/

void Rmpfi_init_set_nobless(pTHX_ mpfi_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_ui_nobless(pTHX_ SV * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_ui_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set_ui(*mpfi_t_obj, (unsigned long)SvUV(q));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_si_nobless(pTHX_ SV * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_si_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set_si(*mpfi_t_obj, (long)SvIV(q));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_d_nobless(pTHX_ SV * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_d_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set_d(*mpfi_t_obj, (double)SvNV(q));

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_z_nobless(pTHX_ mpz_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_z_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set_z(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_q_nobless(pTHX_ mpq_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_q_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set_q(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_fr_nobless(pTHX_ mpfr_t * q) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(items);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_fr_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     ret = mpfi_init_set_fr(*mpfi_t_obj, *q);

     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

void Rmpfi_init_set_str_nobless(pTHX_ SV * q, SV * base) {
     dXSARGS;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret = (int)SvIV(base);
     PERL_UNUSED_ARG(items);

     if(ret < 0 || ret > 36 || ret == 1) croak("2nd argument supplied to Rmpfi_init_set str is out of allowable range");

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_init_set_str_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     ret = mpfi_init_set_str(*mpfi_t_obj, SvPV_nolen(q), ret);

     ST(0) = sv_2mortal(obj_ref);
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}


/*******************************
Interval Functions with Floating-point Results
*******************************/

int Rmpfi_diam_abs(mpfr_t * rop, mpfi_t * op) {
    return mpfi_diam_abs(*rop, *op);
}

int Rmpfi_diam_rel(mpfr_t * rop, mpfi_t * op) {
    return mpfi_diam_rel(*rop, *op);
}

int Rmpfi_diam(mpfr_t * rop, mpfi_t * op) {
    return mpfi_diam(*rop, *op);
}

int Rmpfi_mag(mpfr_t * rop, mpfi_t * op) {
    return mpfi_mag(*rop, *op);
}

int Rmpfi_mig(mpfr_t * rop, mpfi_t * op) {
    return mpfi_mig(*rop, *op);
}

int Rmpfi_mid(mpfr_t * rop, mpfi_t * op) {
    return mpfi_mid(*rop, *op);
}

void Rmpfi_alea(mpfr_t * rop, mpfi_t * op) {
     mpfi_alea(*rop, *op);
}

/*******************************
Conversion Functions
*******************************/

double Rmpfi_get_d (mpfi_t * op) {
       return mpfi_get_d(*op);
}

void Rmpfi_get_fr(mpfr_t * rop, mpfi_t * op) {
     mpfi_get_fr(*rop, *op);
}

SV * Rmpfi_get_NV(pTHX_ mpfi_t * op) {

#if defined(NV_IS_DOUBLE)
     return newSVnv(mpfi_get_d(*op));

#elif defined(NV_IS_LONG_DOUBLE)
     mpfr_t t;
     long double ld;
     mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
     mpfi_get_fr(t, *op);
     ld = mpfr_get_ld(t, GMP_RNDN);
     mpfr_clear(t);
     return newSVnv(ld);

#elif defined(MPFI_CAN_PASS_FLOAT128)
     mpfr_t t;
     float128 ld;
     mpfr_init2(t, 113);
     mpfi_get_fr(t, *op);
     ld = mpfr_get_float128(t, GMP_RNDN);
     mpfr_clear(t);
     return newSVnv(ld);

#else
/* NV_IS_FLOAT128 */
     mpfr_t t;
     long i, exp, retract = 0;
     char *out;
     float128 ret = 0.0Q, sign = 1.0Q;
     float128 add_on[113] = {
      5192296858534827628530496329220096e0Q, 2596148429267413814265248164610048e0Q,
      1298074214633706907132624082305024e0Q, 649037107316853453566312041152512e0Q,
      324518553658426726783156020576256e0Q, 162259276829213363391578010288128e0Q,
      81129638414606681695789005144064e0Q, 40564819207303340847894502572032e0Q,
      20282409603651670423947251286016e0Q, 10141204801825835211973625643008e0Q,
      5070602400912917605986812821504e0Q, 2535301200456458802993406410752e0Q,
      1267650600228229401496703205376e0Q, 633825300114114700748351602688e0Q,
      316912650057057350374175801344e0Q, 158456325028528675187087900672e0Q, 79228162514264337593543950336e0Q,
      39614081257132168796771975168e0Q, 19807040628566084398385987584e0Q, 9903520314283042199192993792e0Q,
      4951760157141521099596496896e0Q, 2475880078570760549798248448e0Q, 1237940039285380274899124224e0Q,
      618970019642690137449562112e0Q, 309485009821345068724781056e0Q, 154742504910672534362390528e0Q,
      77371252455336267181195264e0Q, 38685626227668133590597632e0Q, 19342813113834066795298816e0Q,
      9671406556917033397649408e0Q, 4835703278458516698824704e0Q, 2417851639229258349412352e0Q,
      1208925819614629174706176e0Q, 604462909807314587353088e0Q, 302231454903657293676544e0Q,
      151115727451828646838272e0Q, 75557863725914323419136e0Q, 37778931862957161709568e0Q,
      18889465931478580854784e0Q, 9444732965739290427392e0Q, 4722366482869645213696e0Q,
      2361183241434822606848e0Q, 1180591620717411303424e0Q, 590295810358705651712e0Q, 295147905179352825856e0Q,
      147573952589676412928e0Q, 73786976294838206464e0Q, 36893488147419103232e0Q, 18446744073709551616e0Q,
      9223372036854775808e0Q, 4611686018427387904e0Q, 2305843009213693952e0Q, 1152921504606846976e0Q,
      576460752303423488e0Q, 288230376151711744e0Q, 144115188075855872e0Q, 72057594037927936e0Q,
      36028797018963968e0Q, 18014398509481984e0Q, 9007199254740992e0Q, 4503599627370496e0Q,
      2251799813685248e0Q, 1125899906842624e0Q, 562949953421312e0Q, 281474976710656e0Q, 140737488355328e0Q,
      70368744177664e0Q, 35184372088832e0Q, 17592186044416e0Q, 8796093022208e0Q, 4398046511104e0Q,
      2199023255552e0Q, 1099511627776e0Q, 549755813888e0Q, 274877906944e0Q, 137438953472e0Q, 68719476736e0Q,
      34359738368e0Q, 17179869184e0Q, 8589934592e0Q, 4294967296e0Q, 2147483648e0Q, 1073741824e0Q, 536870912e0Q,
      268435456e0Q, 134217728e0Q, 67108864e0Q, 33554432e0Q, 16777216e0Q, 8388608e0Q, 4194304e0Q, 2097152e0Q,
      1048576e0Q, 524288e0Q, 262144e0Q, 131072e0Q, 65536e0Q, 32768e0Q, 16384e0Q, 8192e0Q, 4096e0Q, 2048e0Q,
      1024e0Q, 512e0Q, 256e0Q, 128e0Q, 64e0Q, 32e0Q, 16e0Q, 8e0Q, 4e0Q, 2e0Q, 1e0Q };

     mpfr_init2(t, 113);
     mpfi_get_fr(t, *op);

     if(mpfr_nan_p(t) || mpfr_inf_p(t)) {
       mpfr_clear(t);
       return newSVnv((float128)mpfr_get_d(t, GMP_RNDN));
     }

     Newxz(out, 115, char);
     if(out == NULL) croak("Failed to allocate memory in Rmpfi_get_NV function");

     mpfr_get_str(out, &exp, 2, 113, t, 0);

     mpfr_clear(t);

     if(out[0] == '-') {
       sign = -1.0Q;
       out++;
       retract++;
     }
     else {
       if(out[0] == '+') {
         out++;
         retract++;
       }
     }

     for(i = 0; i < 113; i++) {
       if(out[i] == '1') ret += add_on[i];
     }

     if(retract) out--;
     Safefree(out);

     if(exp > 113) {
       retract = exp - 113; /* re-using 'retract' */
       for(i = 0; i < retract; i++) ret *= 2.0Q;
     }

     if(exp < 113) {
       for(i = exp; i < 113; i++) ret /= 2.0Q;
     }

     return newSVnv(ret * sign);

#endif

}

/*******************************
Basic Arithmetic Functions
*******************************/

int Rmpfi_add (mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_add(*rop, *op1, *op2);
}

int Rmpfi_add_d (pTHX_ mpfi_t * rop, mpfi_t * op1, SV * op2) {
    return mpfi_add_d(*rop, *op1, (double)SvNV(op2));
}

int Rmpfi_add_ui (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_add_ui(*rop, *op1, op2);
}

int Rmpfi_add_si (mpfi_t * rop, mpfi_t * op1, long op2) {
    return mpfi_add_si(*rop, *op1, op2);
}

int Rmpfi_add_z (mpfi_t * rop, mpfi_t * op1, mpz_t * op2) {
    return mpfi_add_z(*rop, *op1, *op2);
}

int Rmpfi_add_q (mpfi_t * rop, mpfi_t * op1, mpq_t * op2) {
    return mpfi_add_q(*rop, *op1, *op2);
}

int Rmpfi_add_fr (mpfi_t * rop, mpfi_t * op1, mpfr_t * op2) {
    return mpfi_add_fr(*rop, *op1, *op2);
}

int Rmpfi_sub (mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_sub(*rop, *op1, *op2);
}

int Rmpfi_sub_d (pTHX_ mpfi_t * rop, mpfi_t * op1, SV * op2) {
    return mpfi_sub_d(*rop, *op1, (double)SvNV(op2));
}

int Rmpfi_d_sub (pTHX_ mpfi_t * rop, SV * op1, mpfi_t * op2) {
    return mpfi_d_sub(*rop, (double)SvNV(op1), *op2);
}

int Rmpfi_sub_ui (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_sub_ui(*rop, *op1, op2);
}

int Rmpfi_ui_sub (mpfi_t * rop, unsigned long op1, mpfi_t * op2) {
    return mpfi_ui_sub(*rop, op1, *op2);
}

int Rmpfi_sub_si (mpfi_t * rop, mpfi_t * op1, long op2) {
    return mpfi_sub_si(*rop, *op1, op2);
}

int Rmpfi_si_sub (mpfi_t * rop, long op1, mpfi_t * op2) {
    return mpfi_si_sub(*rop, op1, *op2);
}

int Rmpfi_sub_z (mpfi_t * rop, mpfi_t * op1, mpz_t * op2) {
    return mpfi_sub_z(*rop, *op1, *op2);
}

int Rmpfi_z_sub (mpfi_t * rop, mpz_t * op1, mpfi_t * op2) {
    return mpfi_z_sub(*rop, *op1, *op2);
}

int Rmpfi_sub_q (mpfi_t * rop, mpfi_t * op1, mpq_t * op2) {
    return mpfi_sub_q(*rop, *op1, *op2);
}

int Rmpfi_q_sub (mpfi_t * rop, mpq_t * op1, mpfi_t * op2) {
    return mpfi_q_sub(*rop, *op1, *op2);
}

int Rmpfi_sub_fr (mpfi_t * rop, mpfi_t * op1, mpfr_t * op2) {
    return mpfi_sub_fr(*rop, *op1, *op2);
}

int Rmpfi_fr_sub (mpfi_t * rop, mpfr_t * op1, mpfi_t * op2) {
    return mpfi_fr_sub(*rop, *op1, *op2);
}

int Rmpfi_mul (mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_mul(*rop, *op1, *op2);
}

int Rmpfi_mul_d (pTHX_ mpfi_t * rop, mpfi_t * op1, SV * op2) {
    return mpfi_mul_d(*rop, *op1, (double)SvNV(op2));
}

int Rmpfi_mul_ui (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_mul_ui(*rop, *op1, op2);
}

int Rmpfi_mul_si (mpfi_t * rop, mpfi_t * op1, long op2) {
    return mpfi_mul_si(*rop, *op1, op2);
}

int Rmpfi_mul_z (mpfi_t * rop, mpfi_t * op1, mpz_t * op2) {
    return mpfi_mul_z(*rop, *op1, *op2);
}

int Rmpfi_mul_q (mpfi_t * rop, mpfi_t * op1, mpq_t * op2) {
    return mpfi_mul_q(*rop, *op1, *op2);
}

int Rmpfi_mul_fr (mpfi_t * rop, mpfi_t * op1, mpfr_t * op2) {
    return mpfi_mul_fr(*rop, *op1, *op2);
}

int Rmpfi_div (mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_div(*rop, *op1, *op2);
}

int Rmpfi_div_d (pTHX_ mpfi_t * rop, mpfi_t * op1, SV * op2) {
    return mpfi_div_d(*rop, *op1, (double)SvNV(op2));
}

int Rmpfi_d_div (pTHX_ mpfi_t * rop, SV * op1, mpfi_t * op2) {
    return mpfi_d_div(*rop, (double)SvNV(op1), *op2);
}

int Rmpfi_div_ui (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_div_ui(*rop, *op1, op2);
}

int Rmpfi_ui_div (mpfi_t * rop, unsigned long op1, mpfi_t * op2) {
    return mpfi_ui_div(*rop, op1, *op2);
}

int Rmpfi_div_si (mpfi_t * rop, mpfi_t * op1, long op2) {
     return mpfi_div_si(*rop, *op1, op2);
}

int Rmpfi_si_div (mpfi_t * rop, long op1, mpfi_t * op2) {
    return mpfi_si_div(*rop, op1, *op2);
}

int Rmpfi_div_z (mpfi_t * rop, mpfi_t * op1, mpz_t * op2) {
    return mpfi_div_z(*rop, *op1, *op2);
}

int Rmpfi_z_div (mpfi_t * rop, mpz_t * op1, mpfi_t *op2) {
    return mpfi_z_div(*rop, *op1, *op2);
}

int Rmpfi_div_q (mpfi_t * rop, mpfi_t * op1, mpq_t * op2) {
    return mpfi_div_q(*rop, *op1, *op2);
}

int Rmpfi_q_div (mpfi_t * rop, mpq_t * op1, mpfi_t * op2) {
    return mpfi_q_div(*rop, *op1, *op2);
}

int Rmpfi_div_fr (mpfi_t * rop, mpfi_t * op1, mpfr_t * op2) {
    return mpfi_div_fr(*rop, *op1, *op2);
}

int Rmpfi_fr_div (mpfi_t * rop, mpfr_t *op1, mpfi_t * op2) {
     return mpfi_fr_div(*rop, *op1, *op2);
}

int Rmpfi_neg(mpfi_t * rop, mpfi_t * op) {
    return mpfi_neg(*rop, *op);
}

int Rmpfi_sqr(mpfi_t * rop, mpfi_t * op) {
    return mpfi_sqr(*rop, *op);
}

int Rmpfi_inv(mpfi_t * rop, mpfi_t * op) {
    return mpfi_inv(*rop, *op);
}

int Rmpfi_sqrt(mpfi_t * rop, mpfi_t * op) {
    return mpfi_sqrt(*rop, *op);
}

int Rmpfi_abs(mpfi_t * rop, mpfi_t * op) {
    return mpfi_abs(*rop, *op);
}

int Rmpfi_mul_2exp (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_mul_2exp(*rop, *op1, op2);
}

int Rmpfi_mul_2ui (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_mul_2ui(*rop, *op1, op2);
}

int Rmpfi_mul_2si (mpfi_t * rop, mpfi_t * op1, long op2) {
    return mpfi_mul_2si(*rop, *op1, op2);
}

int Rmpfi_div_2exp (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_div_2exp(*rop, *op1, op2);
}

int Rmpfi_div_2ui (mpfi_t * rop, mpfi_t * op1, unsigned long op2) {
    return mpfi_div_2ui(*rop, *op1, op2);
}

int Rmpfi_div_2si (mpfi_t * rop, mpfi_t * op1, long op2) {
    return mpfi_div_2si(*rop, *op1, op2);
}

/*******************************
Special Functions
*******************************/

int Rmpfi_log(mpfi_t * rop, mpfi_t * op) {
     return mpfi_log(*rop, *op);
}

int Rmpfi_exp(mpfi_t * rop, mpfi_t * op) {
    return mpfi_exp(*rop, *op);
}

int Rmpfi_exp2(mpfi_t * rop, mpfi_t * op) {
    return mpfi_exp2(*rop, *op);
}

int Rmpfi_cos(mpfi_t * rop, mpfi_t * op) {
    return mpfi_cos(*rop, *op);
}

int Rmpfi_sin(mpfi_t * rop, mpfi_t * op) {
    return mpfi_sin(*rop, *op);
}

int Rmpfi_tan(mpfi_t * rop, mpfi_t * op) {
    return mpfi_tan(*rop, *op);
}

int Rmpfi_acos(mpfi_t * rop, mpfi_t * op) {
    return mpfi_acos(*rop, *op);
}

int Rmpfi_asin(mpfi_t * rop, mpfi_t * op) {
    return mpfi_asin(*rop, *op);
}

int Rmpfi_atan(mpfi_t * rop, mpfi_t * op) {
    return mpfi_atan(*rop, *op);
}

int Rmpfi_cosh(mpfi_t * rop, mpfi_t * op) {
    return mpfi_cosh(*rop, *op);
}

int Rmpfi_sinh(mpfi_t * rop, mpfi_t * op) {
    return mpfi_sinh(*rop, *op);
}

int Rmpfi_tanh(mpfi_t * rop, mpfi_t * op) {
    return mpfi_tanh(*rop, *op);
}

int Rmpfi_acosh(mpfi_t * rop, mpfi_t * op) {
    return mpfi_acosh(*rop, *op);
}

int Rmpfi_asinh(mpfi_t * rop, mpfi_t * op) {
    return mpfi_asinh(*rop, *op);
}

int Rmpfi_atanh(mpfi_t * rop, mpfi_t * op) {
    return mpfi_atanh(*rop, *op);
}

int Rmpfi_log1p(mpfi_t * rop, mpfi_t * op) {
    return mpfi_log1p(*rop, *op);
}

int Rmpfi_expm1(mpfi_t * rop, mpfi_t * op) {
    return mpfi_expm1(*rop, *op);
}

int Rmpfi_log2(mpfi_t * rop, mpfi_t * op) {
    return mpfi_log2(*rop, *op);
}

int Rmpfi_log10(mpfi_t * rop, mpfi_t * op) {
    return mpfi_log10(*rop, *op);
}

int Rmpfi_const_log2(mpfi_t * op) {
    return mpfi_const_log2(*op);
}

int Rmpfi_const_pi(mpfi_t * op) {
    return mpfi_const_pi(*op);
}

int Rmpfi_const_euler(mpfi_t * op) {
    return mpfi_const_euler(*op);
}

/*******************************
Comparison Functions
*******************************/

int Rmpfi_cmp (mpfi_t * op1, mpfi_t * op2) {
    return MPFI_CMP(*op1,*op2);
}

int Rmpfi_cmp_d (pTHX_ mpfi_t * op1, SV * op2) {
    return MPFI_CMP_D(*op1, (double)SvNV(op2));
}

int Rmpfi_cmp_ui (mpfi_t * op1, unsigned long op2) {
    return MPFI_CMP_UI(*op1, op2);
}

int Rmpfi_cmp_si (mpfi_t * op1, long op2) {
    return MPFI_CMP_SI(*op1, op2);
}

int Rmpfi_cmp_z (mpfi_t * op1, mpz_t * op2) {
    return MPFI_CMP_Z(*op1, *op2);
}

int Rmpfi_cmp_q (mpfi_t * op1, mpq_t * op2) {
    return MPFI_CMP_Q(*op1, *op2);
}

int Rmpfi_cmp_fr (mpfi_t * op1, mpfr_t * op2) {
    return MPFI_CMP_FR(*op1, *op2);
}

int Rmpfi_is_pos(mpfi_t * op) {
    return MPFI_IS_POS(*op);
}

int Rmpfi_is_strictly_pos(mpfi_t * op) {
    return MPFI_IS_STRICTLY_POS(*op);
}

int Rmpfi_is_nonneg(mpfi_t * op) {
    return MPFI_IS_NONNEG(*op);
}

int Rmpfi_is_neg(mpfi_t * op) {
    return MPFI_IS_NEG(*op);
}

int Rmpfi_is_strictly_neg(mpfi_t * op) {
    return MPFI_IS_STRICTLY_NEG(*op);
}

int Rmpfi_is_nonpos(mpfi_t * op) {
    return MPFI_IS_NONPOS(*op);
}

int Rmpfi_is_zero(mpfi_t * op) {
    return MPFI_IS_ZERO_PORTABLE(*op);
}

int Rmpfi_has_zero(mpfi_t * op) {
    return mpfi_has_zero(*op);
}

int Rmpfi_nan_p(mpfi_t * op) {
    return mpfi_nan_p(*op);
}

int Rmpfi_inf_p(mpfi_t * op) {
    return mpfi_inf_p(*op);
}

int Rmpfi_bounded_p(mpfi_t * op) {
    return mpfi_bounded_p(*op);
}

/*******************************
Input and Output Functions
*******************************/

SV * _Rmpfi_out_str(pTHX_ FILE * stream, SV * base, SV * dig, mpfi_t * p) {
     size_t ret;
     if(SvIV(base) < 2 || SvIV(base) > 36) croak("2nd argument supplied to Rmpfi_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     ret = mpfi_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p);
     fflush(stream);
     return newSVuv(ret);
}

SV * _Rmpfi_out_strS(pTHX_ FILE * stream, SV * base, SV * dig, mpfi_t * p, SV * suff) {
     size_t ret;
     if(SvIV(base) < 2 || SvIV(base) > 36) croak("2nd argument supplied to Rmpfi_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     ret = mpfi_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p);
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * _Rmpfi_out_strP(pTHX_ SV * pre, FILE * stream, SV * base, SV * dig, mpfi_t * p) {
     size_t ret;
     if(SvIV(base) < 2 || SvIV(base) > 36) croak("3rd argument supplied to Rmpfi_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpfi_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p);
     fflush(stream);
     return newSVuv(ret);
}

SV * _Rmpfi_out_strPS(pTHX_ SV * pre, FILE * stream, SV * base, SV * dig, mpfi_t * p, SV * suff) {
     size_t ret;
     if(SvIV(base) < 2 || SvIV(base) > 36) croak("3rd argument supplied to Rmpfi_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpfi_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p);
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * Rmpfi_inp_str(pTHX_ mpfi_t * p, FILE * stream, SV * base) {
     size_t ret;
     if(SvIV(base) < 2 || SvIV(base) > 36) croak("3rd argument supplied to Rmpfi_inp_str is out of allowable range (must be between 2 and 36 inclusive)");
     ret = mpfi_inp_str(*p, stream, (int)SvIV(base));
     return newSVuv(ret);
}

void Rmpfi_print_binary(mpfi_t * op) {
     mpfi_print_binary(*op);
}

/*******************************
Functions Operating on Endpoints
*******************************/

int Rmpfi_get_left(mpfr_t * rop, mpfi_t * op) {
    return mpfi_get_left(*rop, *op);
}

int Rmpfi_get_right(mpfr_t * rop, mpfi_t * op) {
    return mpfi_get_right(*rop, *op);
}

int Rmpfi_revert_if_needed(mpfi_t * op) {
    return mpfi_revert_if_needed(*op);
}

int Rmpfi_put (mpfi_t * rop, mpfi_t * op) {
    return mpfi_put(*rop, *op);
}

int Rmpfi_put_d (pTHX_ mpfi_t * rop, SV * op) {
    return mpfi_put_d(*rop, (double)SvNV(op));
}

int Rmpfi_put_ui (mpfi_t * rop, unsigned long op) {
    return mpfi_put_ui(*rop, op);
}

int Rmpfi_put_si (mpfi_t * rop, long op) {
    return mpfi_put_si(*rop, op);
}

int Rmpfi_put_z (mpfi_t * rop, mpz_t * op) {
    return mpfi_put_z(*rop, *op);
}

int Rmpfi_put_q (mpfi_t * rop, mpq_t * op) {
    return mpfi_put_q(*rop, *op);
}

int Rmpfi_put_fr (mpfi_t * rop, mpfr_t * op) {
    return mpfi_put_fr(*rop, *op);
}

int Rmpfi_interv_d (pTHX_ mpfi_t * rop, SV * op1, SV * op2) {
    return mpfi_interv_d(*rop, (double)SvNV(op1), (double)SvNV(op2));
}

int Rmpfi_interv_ui (mpfi_t * rop, unsigned long op1, unsigned long op2) {
    return mpfi_interv_ui(*rop, op1, op2);
}

int Rmpfi_interv_si (mpfi_t * rop, long op1, long op2) {
     return mpfi_interv_si(*rop, op1, op2);
}

int Rmpfi_interv_z (mpfi_t * rop, mpz_t * op1, mpz_t * op2) {
    return mpfi_interv_z(*rop, *op1, *op2);
}

int Rmpfi_interv_q (mpfi_t * rop, mpq_t * op1, mpq_t * op2) {
    return mpfi_interv_q(*rop, *op1, *op2);
}

int Rmpfi_interv_fr (mpfi_t * rop, mpfr_t * op1, mpfr_t * op2) {
    return mpfi_interv_fr(*rop, *op1, *op2);
}

/*******************************
Set Functions on Intervals
*******************************/

int Rmpfi_is_strictly_inside (mpfi_t * op1, mpfi_t * op2) {
    return mpfi_is_strictly_inside(*op1, *op2);
}

int Rmpfi_is_inside (mpfi_t * op1, mpfi_t * op2) {
    return mpfi_is_inside(*op1, *op2);
}

int Rmpfi_is_inside_d (pTHX_ SV * op2, mpfi_t * op1) {
    return mpfi_is_inside_d((double)SvNV(op2), *op1);
}

int Rmpfi_is_inside_ui (unsigned long op2, mpfi_t * op1) {
    return mpfi_is_inside_ui(op2, *op1);
}

int Rmpfi_is_inside_si (long op2, mpfi_t * op1) {
    return mpfi_is_inside_si(op2, *op1);
}

int Rmpfi_is_inside_z (mpz_t * op2, mpfi_t * op1) {
    return mpfi_is_inside_z(*op2, *op1);
}

int Rmpfi_is_inside_q (mpq_t * op2, mpfi_t * op1) {
    return mpfi_is_inside_q(*op2, *op1);
}

int Rmpfi_is_inside_fr (mpfr_t * op2, mpfi_t * op1) {
    return mpfi_is_inside_fr(*op2, *op1);
}

int Rmpfi_is_empty (mpfi_t * op) {
    return mpfi_is_empty(*op);
}

int Rmpfi_intersect (mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_intersect(*rop, *op1, *op2);
}

int Rmpfi_union (mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
     return mpfi_union(*rop, *op1, *op2);
}

/*******************************
Miscellaneous Interval Functions
*******************************/

int Rmpfi_increase (mpfi_t * rop, mpfr_t * op) {
    return mpfi_increase(*rop, *op);
}

int Rmpfi_blow (pTHX_ mpfi_t * rop, mpfi_t * op1, SV * op2) {
    return mpfi_blow(*rop, *op1, (double)SvNV(op2));
}

int Rmpfi_bisect (mpfi_t * rop1, mpfi_t * rop2, mpfi_t * op) {
    return mpfi_bisect(*rop1, *rop2, *op);
}

/*******************************
Error Handling
*******************************/

void RMPFI_ERROR (pTHX_ SV * msg) {
#ifndef _MSC_VER
     MPFI_ERROR(SvPV_nolen(msg));
#else
     croak("RMPFI_ERROR is not yet available for this architecture");
#endif
}

int Rmpfi_is_error(void) {
    return mpfi_is_error();
}

void Rmpfi_set_error(int op) {
     mpfi_set_error(op);
}

void Rmpfi_reset_error(void) {
     mpfi_reset_error();
}

SV * _itsa(pTHX_ SV * a) {
     if(SV_IS_IOK(a)) {
       if(SvUOK(a)) return newSVuv(1);
       return newSVuv(2);
     }

     if(SV_IS_POK(a)) {
#if defined(MPFI_PV_NV_BUG)        /* perl can set the POK flag when it should not */
       if(SV_IS_NOK(a) && !SvIOKp(a))
         return newSVuv(3);        /* designate it as NV */
#endif
       return newSVuv(4);          /* designate it as PV */
     }

     if(SV_IS_NOK(a)) return newSVuv(3);
     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::MPFR")) return newSVuv(5);
       if(strEQ(h, "Math::GMPf")) return newSVuv(6);
       if(strEQ(h, "Math::GMPq")) return newSVuv(7);
       if(strEQ(h, "Math::GMPz")) return newSVuv(8);
       if(strEQ(h, "Math::GMP")) return newSVuv(9);
       if(strEQ(h, "Math::MPC")) return newSVuv(10);
       if(strEQ(h, "Math::MPFI")) return newSVuv(11);
       }
     return newSVuv(0);
}

SV * gmp_v(pTHX) {
#if __GNU_MP_VERSION >= 4
     return newSVpv(gmp_version, 0);
#else
     warn("From Math::MPFI::gmp_v: 'gmp_version' is not implemented - returning '0'");
     return newSVpv("0", 0);
#endif
}

SV * mpfr_v(pTHX) {
     return newSVpv(mpfr_get_version(), 0);
}

/*******************************
Overloading
*******************************/

SV * overload_spaceship(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret = 0;

     if(mpfi_nan_p(*a)) return &PL_sv_undef;

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = MPFI_CMP_UI(*a,SvUVX(b));
       else ret = MPFI_CMP_SI(*a,SvIVX(b));
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) ret = -1;
       if(ret > 0) ret = 1;
       return newSViv(ret);
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);
       if(ret < 0) ret = -1;
       if(ret > 0) ret = 1;
       return newSViv(ret);
     }

#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_spaceship");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         if(ret == 2) {
           return &PL_sv_undef;
         }
         else {
           mpfr_init(t);
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_spaceship");
       }
#else
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_spaceship");
#endif
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) ret = -1;
       if(ret > 0) ret = 1;
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_spaceship");}
#endif
       if(SvNVX(b) != SvNVX(b)) return &PL_sv_undef; /* NaN */

#ifdef NV_IS_DOUBLE

       ret = MPFI_CMP_D(*a, SvNVX(b));
       if(SWITCH_ARGS) ret *= -1;


#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a, t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a, t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       ret = MPFI_CMP_FR(*a, t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#endif
       if(ret < 0) ret = -1;
       if(ret > 0) ret = 1;
       return newSViv(ret);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         ret = MPFI_CMP(*a, *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         if(ret < 0) ret = -1;
         if(ret > 0) ret = 1;
         return newSViv(ret);
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_spaceship");
}

SV * overload_gte(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;

     if(mpfi_nan_p(*a)) return newSViv(0);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = MPFI_CMP_UI(*a, SvUVX(b));
       else         ret = MPFI_CMP_SI(*a, SvIVX(b));

       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       ret = MPFI_CMP_FR(*a, t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_gte");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_gte");
       }
#else
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_gte");
#endif
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_gte");}
#endif
       if(SvNVX(b) != SvNVX(b)) return 0; /* NaN */

#ifdef NV_IS_DOUBLE

       ret = MPFI_CMP_D(*a,SvNVX(b));
       if(SWITCH_ARGS) ret *= -1;


#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#endif

       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         ret = MPFI_CMP(*a, *(INT2PTR(mpfi_t *,SvIVX(SvRV(b)))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_gte");
}

SV * overload_lte(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;

     if(mpfi_nan_p(*a)) return newSViv(0);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = MPFI_CMP_UI(*a,SvUVX(b));
       else         ret = MPFI_CMP_SI(*a,SvIVX(b));

       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_lte");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_lte");
       }
#else
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_lte");
#endif

       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_lte");}
#endif
       if(SvNVX(b) != SvNVX(b)) return 0;

#ifdef NV_IS_DOUBLE

       ret = MPFI_CMP_D(*a,SvNVX(b));
       if(SWITCH_ARGS) ret *= -1;

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#endif

       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         ret = MPFI_CMP(*a,*(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_lte");
}

SV * overload_gt(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;

     if(mpfi_nan_p(*a)) return newSViv(0);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = MPFI_CMP_UI(*a,SvUVX(b));
       else         ret = MPFI_CMP_SI(*a,SvIVX(b));

       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_gt");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_gt");
       }
#else
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_gt");
#endif

       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_gt");}
#endif
       if(SvNVX(b) != SvNVX(b)) return 0;

#ifdef NV_IS_DOUBLE

       ret = MPFI_CMP_D(*a,SvNVX(b));
       if(SWITCH_ARGS) ret *= -1;

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#endif

       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         ret = MPFI_CMP(*a,*(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_gt");
}

SV * overload_lt(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;

     if(mpfi_nan_p(*a)) return newSViv(0);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = MPFI_CMP_UI(*a,SvUVX(b));
       else         ret = MPFI_CMP_SI(*a,SvIVX(b));

       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else  mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_lt");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_lt");
       }
#else
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_lt");
#endif
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_lt");}
#endif
       if(SvNVX(b) != SvNVX(b)) return 0;

#ifdef NV_IS_DOUBLE

       ret = MPFI_CMP_D(*a,SvNVX(b));
       if(SWITCH_ARGS) ret *= -1;

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       if(SWITCH_ARGS) ret *= -1;
       mpfr_clear(t);

#endif

       if(ret < 0) return newSViv(1);
       return newSViv(0);
   }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         ret = MPFI_CMP(*a,*(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_lt");
}

SV * overload_equiv(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
     PERL_UNUSED_ARG(third);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = MPFI_CMP_UI(*a,SvUVX(b));
       else         ret = MPFI_CMP_SI(*a,SvIVX(b));

       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_equiv");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_equiv");
       }
#else
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_equiv");
#endif
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_equiv");}
#endif

#ifdef NV_IS_DOUBLE

       ret = MPFI_CMP_D(*a,SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       ret = MPFI_CMP_FR(*a,t);
       mpfr_clear(t);

#endif

       if(ret == 0) return newSViv(1);
       return newSViv(0);
   }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         ret = MPFI_CMP(*a,*(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         if(ret == 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_equiv");
}

SV * overload_add(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("%s", "Failed to allocate memory in overload_add function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_add_ui(*mpfi_t_obj, *a, SvUVX(b));
       else         mpfi_add_si(*mpfi_t_obj, *a, SvIVX(b));

       return obj_ref;
     }
#else

     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_add_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);
       return obj_ref;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_add");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_add");
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_add");
#endif
       mpfi_add_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_add");}
#endif

#ifdef NV_IS_DOUBLE

       mpfi_add_d(*mpfi_t_obj, *a, SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       mpfi_add_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       mpfi_add_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       mpfi_add_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#endif

       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_add(*mpfi_t_obj, *a, *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_add");
}

SV * overload_mul(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;
     PERL_UNUSED_ARG(third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("%s", "Failed to allocate memory in overload_mul function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_mul_ui(*mpfi_t_obj, *a, SvUVX(b));
       else         mpfi_mul_si(*mpfi_t_obj, *a, SvIVX(b));

       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_mul_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);
       return obj_ref;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_mul");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_mul");
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_mul");
#endif
       mpfi_mul_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_mul");}
#endif

#ifdef NV_IS_DOUBLE

       mpfi_mul_d(*mpfi_t_obj, *a, SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       mpfi_mul_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       mpfi_mul_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       mpfi_mul_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#endif

       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_mul(*mpfi_t_obj, *a, *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_mul");
}

SV * overload_sub(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("%s", "Failed to allocate memory in overload_sub function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(SWITCH_ARGS) mpfi_ui_sub(*mpfi_t_obj, SvUVX(b), *a);
         else mpfi_sub_ui(*mpfi_t_obj, *a, SvUVX(b));
       }
       else {
         if(SWITCH_ARGS) mpfi_si_sub(*mpfi_t_obj, SvIVX(b), *a);
         else mpfi_sub_si(*mpfi_t_obj, *a, SvIVX(b));
       }

       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) {
         mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfi_fr_sub(*mpfi_t_obj, t, *a);
         else mpfi_sub_fr(*mpfi_t_obj, *a, t);
       }
       else {
         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfi_fr_sub(*mpfi_t_obj, t, *a);
         else mpfi_sub_fr(*mpfi_t_obj, *a, t);
       }
       mpfr_clear(t);
       return obj_ref;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_sub");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_sub");
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_sub");
#endif
       if(SWITCH_ARGS) mpfi_fr_sub(*mpfi_t_obj, t, *a);
       else mpfi_sub_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_sub");}
#endif


#ifdef NV_IS_DOUBLE

       if(SWITCH_ARGS) mpfi_d_sub(*mpfi_t_obj, SvNVX(b), *a);
       else mpfi_sub_d(*mpfi_t_obj, *a, SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       if(SWITCH_ARGS) mpfi_fr_sub(*mpfi_t_obj, t, *a);
       else mpfi_sub_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       if(SWITCH_ARGS) mpfi_fr_sub(*mpfi_t_obj, t, *a);
       else mpfi_sub_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       if(SWITCH_ARGS) mpfi_fr_sub(*mpfi_t_obj, t, *a);
       else mpfi_sub_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#endif

       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_sub(*mpfi_t_obj, *a, *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_sub");
}

SV * overload_div(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfr_t t;
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     int ret;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("%s", "Failed to allocate memory in overload_div function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(SWITCH_ARGS) mpfi_ui_div(*mpfi_t_obj, SvUVX(b), *a);
         else mpfi_div_ui(*mpfi_t_obj, *a, SvUVX(b));
       }
       else {
         if(SWITCH_ARGS) mpfi_si_div(*mpfi_t_obj, SvIVX(b), *a);
         else mpfi_div_si(*mpfi_t_obj, *a, SvIVX(b));
       }
       return obj_ref;
     }

#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) {
         mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfi_fr_div(*mpfi_t_obj, t, *a);
         else mpfi_div_fr(*mpfi_t_obj, *a, t);
       }
       else {
         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfi_fr_div(*mpfi_t_obj, t, *a);
         else mpfi_div_fr(*mpfi_t_obj, *a, t);
       }

       mpfr_clear(t);
       return obj_ref;
     }

#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_div");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
           croak("%s", "Invalid string supplied to Math::MPFI::overload_div");
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode))
         croak("%s", "Invalid string supplied to Math::MPFI::overload_div");
#endif
       if(SWITCH_ARGS) mpfi_fr_div(*mpfi_t_obj, t, *a);
       else mpfi_div_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_div");}
#endif

#ifdef NV_IS_DOUBLE

       if(SWITCH_ARGS) mpfi_d_div(*mpfi_t_obj, SvNVX(b), *a);
       else mpfi_div_d(*mpfi_t_obj, *a, SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       if(SWITCH_ARGS) mpfi_fr_div(*mpfi_t_obj, t, *a);
       else mpfi_div_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       if(SWITCH_ARGS) mpfi_fr_div(*mpfi_t_obj, t, *a);
       else mpfi_div_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       if(SWITCH_ARGS) mpfi_fr_div(*mpfi_t_obj, t, *a);
       else mpfi_div_fr(*mpfi_t_obj, *a, t);
       mpfr_clear(t);

#endif

       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_div(*mpfi_t_obj, *a, *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
     }

     croak("%s", "Invalid argument supplied to Math::MPFI::overload_div");
}

SV * overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_add_ui(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvUVX(b));
       else         mpfi_add_si(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvIVX(b));
       return a;
     }

#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_add_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_add_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
           SvREFCNT_dec(a);
           croak("%s", "Invalid string supplied to Math::MPFI::overload_add_eq");
         }
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
         SvREFCNT_dec(a);
         croak("%s", "Invalid string supplied to Math::MPFI::overload_add_eq");
       }
#endif
       mpfi_add_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_add_eq");}
#endif

#ifdef NV_IS_DOUBLE

       mpfi_add_d(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       mpfi_add_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       mpfi_add_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */

       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       mpfi_add_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#endif

       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_add(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("%s", "Invalid argument supplied to Math::MPFI::overload_add_eq");
}

SV * overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_mul_ui(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvUVX(b));
       else         mpfi_mul_si(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvIVX(b));

       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_mul_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_mul_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
           SvREFCNT_dec(a);
           croak("%s", "Invalid string supplied to Math::MPFI::overload_mul_eq");
         }
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
         SvREFCNT_dec(a);
         croak("%s", "Invalid string supplied to Math::MPFI::overload_mul_eq");
       }
#endif
       mpfi_mul_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_mul_eq");}
#endif

#ifdef NV_IS_DOUBLE

       mpfi_mul_d(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       mpfi_mul_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       mpfi_mul_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       mpfi_mul_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#endif

       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_mul(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("%s", "Invalid argument supplied to Math::MPFI::overload_mul_eq");
}

SV * overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_sub_ui(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvUVX(b));
       else         mpfi_sub_si(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvIVX(b));

       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_sub_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_sub_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
           SvREFCNT_dec(a);
           croak("%s", "Invalid string supplied to Math::MPFI::overload_sub_eq");
         }
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
         SvREFCNT_dec(a);
         croak("%s", "Invalid string supplied to Math::MPFI::overload_sub_eq");
       }
#endif
       mpfi_sub_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_sub_eq");}
#endif

#ifdef NV_IS_DOUBLE

       mpfi_sub_d(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       mpfi_sub_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       mpfi_sub_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       mpfi_sub_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#endif

       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_sub(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("%s", "Invalid argument supplied to Math::MPFI::overload_sub_eq");
}

SV * overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

#ifndef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_div_ui(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvUVX(b));
       else         mpfi_div_si(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvIVX(b));

       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_div_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_div_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(t);
         if(ret == 2) {
           mpfr_set_nan(t);
         }
         else {
           mpfr_set_inf(t, ret);
         }
       }
       else {
         if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
           SvREFCNT_dec(a);
           croak("%s", "Invalid string supplied to Math::MPFI::overload_div_eq");
         }
       }
#else
       PERL_UNUSED_VAR(ret);
       if(mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode)) {
         SvREFCNT_dec(a);
         croak("%s", "Invalid string supplied to Math::MPFI::overload_div_eq");
       }
#endif
       mpfi_div_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_div_eq");}
#endif

#ifdef NV_IS_DOUBLE

       mpfi_div_d(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, SvNVX(b), GMP_RNDN);
       mpfi_div_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(t, FLT128_MANT_DIG);
       mpfr_set_float128(t, SvNVX(b), GMP_RNDN);
       mpfi_div_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(t, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &t, b, GMP_RNDN);
       mpfi_div_fr(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), t);
       mpfr_clear(t);

#endif

       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_div(*(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("%s", "Invalid argument supplied to Math::MPFI::overload_div_eq");
}

SV * overload_sqrt(pTHX_ mpfi_t * p, SV * second, SV * third) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in overload_sqrt function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     mpfi_sqrt(*mpfi_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfi_get_version(pTHX) {
     return newSVpv(mpfi_get_version(), 0);
}

int Rmpfi_const_catalan(mpfi_t * rop) {
    return mpfi_const_catalan(*rop);
}

int Rmpfi_cbrt(mpfi_t * rop, mpfi_t * op) {
    return mpfi_cbrt(*rop, *op);
}

int Rmpfi_sec(mpfi_t * rop, mpfi_t * op) {
    return mpfi_sec(*rop, *op);
}

int Rmpfi_csc(mpfi_t * rop, mpfi_t * op) {
    return mpfi_csc(*rop, *op);
}

int Rmpfi_cot(mpfi_t * rop, mpfi_t * op) {
    return mpfi_cot(*rop, *op);
}

int Rmpfi_sech(mpfi_t * rop, mpfi_t * op) {
    return mpfi_sech(*rop, *op);
}

int Rmpfi_csch(mpfi_t * rop, mpfi_t * op) {
    return mpfi_csch(*rop, *op);
}

int Rmpfi_coth(mpfi_t * rop, mpfi_t * op) {
    return mpfi_coth(*rop, *op);
}

int Rmpfi_atan2(mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_atan2(*rop, *op1, *op2);
}

int Rmpfi_hypot(mpfi_t * rop, mpfi_t * op1, mpfi_t * op2) {
    return mpfi_hypot(*rop, *op1, *op2);
}

void Rmpfi_urandom(mpfr_t * rop, mpfi_t * op, gmp_randstate_t * state) {
     mpfi_urandom(*rop, *op, *state);
}

SV * overload_true(pTHX_ mpfi_t * op, SV * second, SV * third) {
     PERL_UNUSED_ARG2(second, third);
     if(MPFI_IS_ZERO_PORTABLE(*op)) return newSViv(0);
     if(mpfi_nan_p(*op)) return newSViv(0);
     return newSViv(1);
}

SV * overload_not(pTHX_ mpfi_t * op, SV * second, SV * third) {
     PERL_UNUSED_ARG2(second, third);
     if(MPFI_IS_ZERO_PORTABLE(*op)) return newSViv(1);
     if(mpfi_nan_p(*op)) return newSViv(1);
     return newSViv(0);
}

SV * overload_abs(pTHX_ mpfi_t * op, SV * second, SV * third) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_abs function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     mpfi_abs(*mpfi_t_obj, *op);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_sin(pTHX_ mpfi_t * op, SV * second, SV * third) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_sin function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     mpfi_sin(*mpfi_t_obj, *op);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_cos(pTHX_ mpfi_t * op, SV * second, SV * third) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_cos function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     mpfi_cos(*mpfi_t_obj, *op);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_log(pTHX_ mpfi_t * op, SV * second, SV * third) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_log function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     mpfi_log(*mpfi_t_obj, *op);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_exp(pTHX_ mpfi_t * op, SV * second, SV * third) {
     mpfi_t * mpfi_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in Rmpfi_exp function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

     mpfi_exp(*mpfi_t_obj, *op);
     sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_atan2(pTHX_ mpfi_t * a, SV * b, SV * third) {
     mpfi_t * mpfi_t_obj;
     mpfr_t tr;
     SV * obj_ref, * obj;
     int ret;

     Newxz(mpfi_t_obj, 1, mpfi_t);
     if(mpfi_t_obj == NULL) croak("Failed to allocate memory in overload_atan2 function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::MPFI");
     mpfi_init(*mpfi_t_obj);

#ifdef MATH_MPFI_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(tr, IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(tr, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(tr, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfi_set_fr(*mpfi_t_obj, tr);
       mpfr_clear(tr);
       if(SWITCH_ARGS){
         mpfi_atan2(*mpfi_t_obj, *mpfi_t_obj, *a);
       }
       else {
         mpfi_atan2(*mpfi_t_obj, *a, *mpfi_t_obj);
       }
       sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
       SvREADONLY_on(obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) mpfi_set_ui(*mpfi_t_obj, SvUVX(b));
       else         mpfi_set_si(*mpfi_t_obj, SvIVX(b));

       if(SWITCH_ARGS){
         mpfi_atan2(*mpfi_t_obj, *mpfi_t_obj, *a);
       }
       else {
         mpfi_atan2(*mpfi_t_obj, *a, *mpfi_t_obj);
       }
       sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
       SvREADONLY_on(obj);
       return obj_ref;
     }
#endif

#if defined(MPFI_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif

       NOK_POK_DUALVAR_CHECK , "Math::MPFI::overload_atan2");}

#ifdef _WIN32_BIZARRE_INFNAN
       ret = _win32_infnanstring(SvPV_nolen(b));
       if(ret) {
         mpfr_init(tr);
         if(ret == 2) {
           mpfr_set_nan(tr);
         }
         else {
           mpfr_set_inf(tr, ret);
         }

         mpfi_set_fr(*mpfi_t_obj, tr);
         mpfr_clear(tr);
       }
       else {
         if(mpfi_set_str(*mpfi_t_obj, SvPV_nolen(b), 10))
           croak("Invalid string supplied to Math::MPFI::overload_atan2");
       }
#else
       PERL_UNUSED_VAR(tr);
       PERL_UNUSED_VAR(ret);
       if(mpfi_set_str(*mpfi_t_obj, SvPV_nolen(b), 10))
         croak("Invalid string supplied to Math::MPFI::overload_atan2");
#endif
       if(SWITCH_ARGS){
         mpfi_atan2(*mpfi_t_obj, *mpfi_t_obj, *a);
       }
       else {
         mpfi_atan2(*mpfi_t_obj, *a, *mpfi_t_obj);
       }
       sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
       SvREADONLY_on(obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(MPFI_PV_NV_BUG)
       NOK_POK_DUALVAR_CHECK , "overload_atan2");}
#endif


#ifdef NV_IS_DOUBLE

       mpfi_set_d(*mpfi_t_obj, SvNVX(b));

#elif defined(NV_IS_LONG_DOUBLE)

       mpfr_init2(tr, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(tr, SvNVX(b), GMP_RNDN);
       mpfi_set_fr(*mpfi_t_obj, tr);
       mpfr_clear(tr);

#elif defined(MPFI_CAN_PASS_FLOAT128)

       mpfr_init2(tr, FLT128_MANT_DIG);
       mpfr_set_float128(tr, SvNVX(b), GMP_RNDN);
       mpfi_set_fr(*mpfi_t_obj, tr);
       mpfr_clear(tr);

#else
/* NV_IS_FLOAT128 */
       mpfr_init2(tr, FLT128_MANT_DIG);
       _my_mpfr_set_float128(aTHX_ &tr, b, GMP_RNDN);
       mpfi_set_fr(*mpfi_t_obj, tr);
       mpfr_clear(tr);


#endif
       if(SWITCH_ARGS){
         mpfi_atan2(*mpfi_t_obj, *mpfi_t_obj, *a);
       }
       else {
         mpfi_atan2(*mpfi_t_obj, *a, *mpfi_t_obj);
       }
       sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
       SvREADONLY_on(obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFI")) {
         mpfi_atan2(*mpfi_t_obj, *a, *(INT2PTR(mpfi_t *, SvIVX(SvRV(b)))));
         sv_setiv(obj, INT2PTR(IV,mpfi_t_obj));
         SvREADONLY_on(obj);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFI::overload_atan2 function");
}

SV * _MPFI_VERSION_MAJOR(pTHX) {
#ifdef MPFI_VERSION_MAJOR
     return newSVuv(MPFI_VERSION_MAJOR);
#else
     croak("MPFI_VERSION_MAJOR not defined in mpfi.h until mpfi-1.5.1. Library version is %s", mpfi_get_version());
#endif
}

SV * _MPFI_VERSION_MINOR(pTHX) {
#ifdef MPFI_VERSION_MINOR
     return newSVuv(MPFI_VERSION_MINOR);
#else
     croak("MPFI_VERSION_MINOR not defined in mpfi.h until mpfi-1.5.1. Library version is %s", mpfi_get_version());
#endif
}

SV * _MPFI_VERSION_PATCHLEVEL(pTHX) {
#ifdef MPFI_VERSION_PATCHLEVEL
     return newSVuv(MPFI_VERSION_PATCHLEVEL);
#else
     croak("MPFI_VERSION_PATCHLEVEL not defined in mpfi.h until mpfi-1.5.1. Library version is %s", mpfi_get_version());
#endif
}

SV * _MPFI_VERSION_STRING(pTHX) {
#ifdef MPFI_VERSION_STRING
     return newSVpv(MPFI_VERSION_STRING, 0);
#else
     croak("MPFI_VERSION_STRING not defined in mpfi.h until mpfi-1.5.1. Library version is %s", mpfi_get_version());
#endif
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

int _can_pass_float128(void) {

#ifdef MPFI_CAN_PASS_FLOAT128
   return 1;
#else
   return 0;
#endif

}

int _SvNOK(pTHX_ SV * in) {
  if(SV_IS_NOK(in)) return 1;
  return 0;
}

int _SvPOK(pTHX_ SV * in) {
  if(SV_IS_POK(in)) return 1;
  return 0;
}

int nok_pokflag(void) {
  return nok_pok;
}

void clear_nok_pok(void){
  nok_pok = 0;
}

void set_nok_pok(int x) {
  nok_pok = x;
}

int _has_pv_nv_bug(void) {
#if defined(MPFI_PV_NV_BUG)
     return 1;
#else
     return 0;
#endif
}

int _msc_ver_defined(void) {
#ifdef _MSC_VER
     return 1;
#else
     return 0;
#endif
}


MODULE = Math::MPFI  PACKAGE = Math::MPFI

PROTOTYPES: DISABLE


int
NOK_POK_val ()
CODE:
  RETVAL = NOK_POK_val (aTHX);
OUTPUT:  RETVAL


int
_win32_infnanstring (s)
	char *	s

int
_has_inttypes ()


int
_has_longlong ()


int
_has_longdouble ()


int
_nv_is_float128 ()


int
_required_ldbl_mant_dig ()


int
_ivsize_bits ()


SV *
_my_mpfr_set_float128 (p, q, round)
	mpfr_t *	p
	SV *	q
	unsigned int	round
CODE:
  RETVAL = _my_mpfr_set_float128 (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
RMPFI_BOTH_ARE_EXACT (ret)
	int	ret
CODE:
  RETVAL = RMPFI_BOTH_ARE_EXACT (aTHX_ ret);
OUTPUT:  RETVAL

SV *
RMPFI_LEFT_IS_INEXACT (ret)
	int	ret
CODE:
  RETVAL = RMPFI_LEFT_IS_INEXACT (aTHX_ ret);
OUTPUT:  RETVAL

SV *
RMPFI_RIGHT_IS_INEXACT (ret)
	int	ret
CODE:
  RETVAL = RMPFI_RIGHT_IS_INEXACT (aTHX_ ret);
OUTPUT:  RETVAL

SV *
RMPFI_BOTH_ARE_INEXACT (ret)
	int	ret
CODE:
  RETVAL = RMPFI_BOTH_ARE_INEXACT (aTHX_ ret);
OUTPUT:  RETVAL

void
_Rmpfi_set_default_prec (p)
	SV *	p
        PPCODE:
        _Rmpfi_set_default_prec(aTHX_ p);
        XSRETURN_EMPTY; /* return empty stack */

SV *
Rmpfi_get_default_prec ()
CODE:
  RETVAL = Rmpfi_get_default_prec (aTHX);
OUTPUT:  RETVAL


void
Rmpfi_set_prec (op, prec)
	mpfi_t *	op
	SV *	prec
        PPCODE:
        Rmpfi_set_prec(aTHX_ op, prec);
        XSRETURN_EMPTY; /* return empty stack */

SV *
Rmpfi_get_prec (op)
	mpfi_t *	op
CODE:
  RETVAL = Rmpfi_get_prec (aTHX_ op);
OUTPUT:  RETVAL

SV *
Rmpfi_round_prec (op, prec)
	mpfi_t *	op
	SV *	prec
CODE:
  RETVAL = Rmpfi_round_prec (aTHX_ op, prec);
OUTPUT:  RETVAL

SV *
Rmpfi_init ()
CODE:
  RETVAL = Rmpfi_init (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfi_init_nobless ()
CODE:
  RETVAL = Rmpfi_init_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfi_init2 (prec)
	SV *	prec
CODE:
  RETVAL = Rmpfi_init2 (aTHX_ prec);
OUTPUT:  RETVAL

SV *
Rmpfi_init2_nobless (prec)
	SV *	prec
CODE:
  RETVAL = Rmpfi_init2_nobless (aTHX_ prec);
OUTPUT:  RETVAL

void
DESTROY (p)
	mpfi_t *	p
        PPCODE:
        DESTROY(aTHX_ p);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpfi_clear (p)
	mpfi_t *	p
        PPCODE:
        Rmpfi_clear(aTHX_ p);
        XSRETURN_EMPTY; /* return empty stack */

int
Rmpfi_set (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_set_ui (rop, op)
	mpfi_t *	rop
	unsigned long	op

int
Rmpfi_set_si (rop, op)
	mpfi_t *	rop
	long	op

int
Rmpfi_set_d (rop, op)
	mpfi_t *	rop
	SV *	op
CODE:
  RETVAL = Rmpfi_set_d (aTHX_ rop, op);
OUTPUT:  RETVAL

int
Rmpfi_set_NV (rop, op)
	mpfi_t *	rop
	SV *	op
CODE:
  RETVAL = Rmpfi_set_NV (aTHX_ rop, op);
OUTPUT:  RETVAL

int
Rmpfi_set_z (rop, op)
	mpfi_t *	rop
	mpz_t *	op

int
Rmpfi_set_q (rop, op)
	mpfi_t *	rop
	mpq_t *	op

int
Rmpfi_set_fr (rop, op)
	mpfi_t *	rop
	mpfr_t *	op

int
Rmpfi_set_str (rop, s, base)
	mpfi_t *	rop
	SV *	s
	SV *	base
CODE:
  RETVAL = Rmpfi_set_str (aTHX_ rop, s, base);
OUTPUT:  RETVAL

void
Rmpfi_swap (x, y)
	mpfi_t *	x
	mpfi_t *	y
        PPCODE:
        Rmpfi_swap(x, y);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpfi_init_set (q)
	mpfi_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set(aTHX_ q);
        return;

void
Rmpfi_init_set_ui (q)
	SV *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_ui(aTHX_ q);
        return;

void
Rmpfi_init_set_si (q)
	SV *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_si(aTHX_ q);
        return;

void
Rmpfi_init_set_d (q)
	SV *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_d(aTHX_ q);
        return;

void
Rmpfi_init_set_z (q)
	mpz_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_z(aTHX_ q);
        return;

void
Rmpfi_init_set_q (q)
	mpq_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_q(aTHX_ q);
        return;

void
Rmpfi_init_set_fr (q)
	mpfr_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_fr(aTHX_ q);
        return;

void
Rmpfi_init_set_str (q, base)
	SV *	q
	SV *	base
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_str(aTHX_ q, base);
        return;

void
Rmpfi_init_set_nobless (q)
	mpfi_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_ui_nobless (q)
	SV *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_ui_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_si_nobless (q)
	SV *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_si_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_d_nobless (q)
	SV *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_d_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_z_nobless (q)
	mpz_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_z_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_q_nobless (q)
	mpq_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_q_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_fr_nobless (q)
	mpfr_t *	q
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_fr_nobless(aTHX_ q);
        return;

void
Rmpfi_init_set_str_nobless (q, base)
	SV *	q
	SV *	base
        PPCODE:
        PL_markstack_ptr++;
        Rmpfi_init_set_str_nobless(aTHX_ q, base);
        return;

int
Rmpfi_diam_abs (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_diam_rel (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_diam (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_mag (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_mig (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_mid (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

void
Rmpfi_alea (rop, op)
	mpfr_t *	rop
	mpfi_t *	op
        PPCODE:
        Rmpfi_alea(rop, op);
        XSRETURN_EMPTY; /* return empty stack */

double
Rmpfi_get_d (op)
	mpfi_t *	op

void
Rmpfi_get_fr (rop, op)
	mpfr_t *	rop
	mpfi_t *	op
        PPCODE:
        Rmpfi_get_fr(rop, op);
        XSRETURN_EMPTY; /* return empty stack */

SV *
Rmpfi_get_NV (op)
	mpfi_t *	op
CODE:
  RETVAL = Rmpfi_get_NV (aTHX_ op);
OUTPUT:  RETVAL

int
Rmpfi_add (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_add_d (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_add_d (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_add_ui (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_add_si (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	long	op2

int
Rmpfi_add_z (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpz_t *	op2

int
Rmpfi_add_q (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpq_t *	op2

int
Rmpfi_add_fr (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfr_t *	op2

int
Rmpfi_sub (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_sub_d (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_sub_d (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_d_sub (rop, op1, op2)
	mpfi_t *	rop
	SV *	op1
	mpfi_t *	op2
CODE:
  RETVAL = Rmpfi_d_sub (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_sub_ui (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_ui_sub (rop, op1, op2)
	mpfi_t *	rop
	unsigned long	op1
	mpfi_t *	op2

int
Rmpfi_sub_si (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	long	op2

int
Rmpfi_si_sub (rop, op1, op2)
	mpfi_t *	rop
	long	op1
	mpfi_t *	op2

int
Rmpfi_sub_z (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpz_t *	op2

int
Rmpfi_z_sub (rop, op1, op2)
	mpfi_t *	rop
	mpz_t *	op1
	mpfi_t *	op2

int
Rmpfi_sub_q (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpq_t *	op2

int
Rmpfi_q_sub (rop, op1, op2)
	mpfi_t *	rop
	mpq_t *	op1
	mpfi_t *	op2

int
Rmpfi_sub_fr (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfr_t *	op2

int
Rmpfi_fr_sub (rop, op1, op2)
	mpfi_t *	rop
	mpfr_t *	op1
	mpfi_t *	op2

int
Rmpfi_mul (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_mul_d (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_mul_d (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_mul_ui (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_mul_si (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	long	op2

int
Rmpfi_mul_z (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpz_t *	op2

int
Rmpfi_mul_q (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpq_t *	op2

int
Rmpfi_mul_fr (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfr_t *	op2

int
Rmpfi_div (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_div_d (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_div_d (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_d_div (rop, op1, op2)
	mpfi_t *	rop
	SV *	op1
	mpfi_t *	op2
CODE:
  RETVAL = Rmpfi_d_div (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_div_ui (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_ui_div (rop, op1, op2)
	mpfi_t *	rop
	unsigned long	op1
	mpfi_t *	op2

int
Rmpfi_div_si (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	long	op2

int
Rmpfi_si_div (rop, op1, op2)
	mpfi_t *	rop
	long	op1
	mpfi_t *	op2

int
Rmpfi_div_z (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpz_t *	op2

int
Rmpfi_z_div (rop, op1, op2)
	mpfi_t *	rop
	mpz_t *	op1
	mpfi_t *	op2

int
Rmpfi_div_q (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpq_t *	op2

int
Rmpfi_q_div (rop, op1, op2)
	mpfi_t *	rop
	mpq_t *	op1
	mpfi_t *	op2

int
Rmpfi_div_fr (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfr_t *	op2

int
Rmpfi_fr_div (rop, op1, op2)
	mpfi_t *	rop
	mpfr_t *	op1
	mpfi_t *	op2

int
Rmpfi_neg (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_sqr (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_inv (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_sqrt (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_abs (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_mul_2exp (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_mul_2ui (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_mul_2si (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	long	op2

int
Rmpfi_div_2exp (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_div_2ui (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_div_2si (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	long	op2

int
Rmpfi_log (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_exp (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_exp2 (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_cos (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_sin (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_tan (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_acos (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_asin (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_atan (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_cosh (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_sinh (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_tanh (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_acosh (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_asinh (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_atanh (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_log1p (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_expm1 (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_log2 (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_log10 (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_const_log2 (op)
	mpfi_t *	op

int
Rmpfi_const_pi (op)
	mpfi_t *	op

int
Rmpfi_const_euler (op)
	mpfi_t *	op

int
Rmpfi_cmp (op1, op2)
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_cmp_d (op1, op2)
	mpfi_t *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_cmp_d (aTHX_ op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_cmp_ui (op1, op2)
	mpfi_t *	op1
	unsigned long	op2

int
Rmpfi_cmp_si (op1, op2)
	mpfi_t *	op1
	long	op2

int
Rmpfi_cmp_z (op1, op2)
	mpfi_t *	op1
	mpz_t *	op2

int
Rmpfi_cmp_q (op1, op2)
	mpfi_t *	op1
	mpq_t *	op2

int
Rmpfi_cmp_fr (op1, op2)
	mpfi_t *	op1
	mpfr_t *	op2

int
Rmpfi_is_pos (op)
	mpfi_t *	op

int
Rmpfi_is_strictly_pos (op)
	mpfi_t *	op

int
Rmpfi_is_nonneg (op)
	mpfi_t *	op

int
Rmpfi_is_neg (op)
	mpfi_t *	op

int
Rmpfi_is_strictly_neg (op)
	mpfi_t *	op

int
Rmpfi_is_nonpos (op)
	mpfi_t *	op

int
Rmpfi_is_zero (op)
	mpfi_t *	op

int
Rmpfi_has_zero (op)
	mpfi_t *	op

int
Rmpfi_nan_p (op)
	mpfi_t *	op

int
Rmpfi_inf_p (op)
	mpfi_t *	op

int
Rmpfi_bounded_p (op)
	mpfi_t *	op

SV *
_Rmpfi_out_str (stream, base, dig, p)
	FILE *	stream
	SV *	base
	SV *	dig
	mpfi_t *	p
CODE:
  RETVAL = _Rmpfi_out_str (aTHX_ stream, base, dig, p);
OUTPUT:  RETVAL

SV *
_Rmpfi_out_strS (stream, base, dig, p, suff)
	FILE *	stream
	SV *	base
	SV *	dig
	mpfi_t *	p
	SV *	suff
CODE:
  RETVAL = _Rmpfi_out_strS (aTHX_ stream, base, dig, p, suff);
OUTPUT:  RETVAL

SV *
_Rmpfi_out_strP (pre, stream, base, dig, p)
	SV *	pre
	FILE *	stream
	SV *	base
	SV *	dig
	mpfi_t *	p
CODE:
  RETVAL = _Rmpfi_out_strP (aTHX_ pre, stream, base, dig, p);
OUTPUT:  RETVAL

SV *
_Rmpfi_out_strPS (pre, stream, base, dig, p, suff)
	SV *	pre
	FILE *	stream
	SV *	base
	SV *	dig
	mpfi_t *	p
	SV *	suff
CODE:
  RETVAL = _Rmpfi_out_strPS (aTHX_ pre, stream, base, dig, p, suff);
OUTPUT:  RETVAL

SV *
Rmpfi_inp_str (p, stream, base)
	mpfi_t *	p
	FILE *	stream
	SV *	base
CODE:
  RETVAL = Rmpfi_inp_str (aTHX_ p, stream, base);
OUTPUT:  RETVAL

void
Rmpfi_print_binary (op)
	mpfi_t *	op
        PPCODE:
        Rmpfi_print_binary(op);
        XSRETURN_EMPTY; /* return empty stack */

int
Rmpfi_get_left (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_get_right (rop, op)
	mpfr_t *	rop
	mpfi_t *	op

int
Rmpfi_revert_if_needed (op)
	mpfi_t *	op

int
Rmpfi_put (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_put_d (rop, op)
	mpfi_t *	rop
	SV *	op
CODE:
  RETVAL = Rmpfi_put_d (aTHX_ rop, op);
OUTPUT:  RETVAL

int
Rmpfi_put_ui (rop, op)
	mpfi_t *	rop
	unsigned long	op

int
Rmpfi_put_si (rop, op)
	mpfi_t *	rop
	long	op

int
Rmpfi_put_z (rop, op)
	mpfi_t *	rop
	mpz_t *	op

int
Rmpfi_put_q (rop, op)
	mpfi_t *	rop
	mpq_t *	op

int
Rmpfi_put_fr (rop, op)
	mpfi_t *	rop
	mpfr_t *	op

int
Rmpfi_interv_d (rop, op1, op2)
	mpfi_t *	rop
	SV *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_interv_d (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_interv_ui (rop, op1, op2)
	mpfi_t *	rop
	unsigned long	op1
	unsigned long	op2

int
Rmpfi_interv_si (rop, op1, op2)
	mpfi_t *	rop
	long	op1
	long	op2

int
Rmpfi_interv_z (rop, op1, op2)
	mpfi_t *	rop
	mpz_t *	op1
	mpz_t *	op2

int
Rmpfi_interv_q (rop, op1, op2)
	mpfi_t *	rop
	mpq_t *	op1
	mpq_t *	op2

int
Rmpfi_interv_fr (rop, op1, op2)
	mpfi_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2

int
Rmpfi_is_strictly_inside (op1, op2)
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_is_inside (op1, op2)
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_is_inside_d (op2, op1)
	SV *	op2
	mpfi_t *	op1
CODE:
  RETVAL = Rmpfi_is_inside_d (aTHX_ op2, op1);
OUTPUT:  RETVAL

int
Rmpfi_is_inside_ui (op2, op1)
	unsigned long	op2
	mpfi_t *	op1

int
Rmpfi_is_inside_si (op2, op1)
	long	op2
	mpfi_t *	op1

int
Rmpfi_is_inside_z (op2, op1)
	mpz_t *	op2
	mpfi_t *	op1

int
Rmpfi_is_inside_q (op2, op1)
	mpq_t *	op2
	mpfi_t *	op1

int
Rmpfi_is_inside_fr (op2, op1)
	mpfr_t *	op2
	mpfi_t *	op1

int
Rmpfi_is_empty (op)
	mpfi_t *	op

int
Rmpfi_intersect (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_union (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_increase (rop, op)
	mpfi_t *	rop
	mpfr_t *	op

int
Rmpfi_blow (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	SV *	op2
CODE:
  RETVAL = Rmpfi_blow (aTHX_ rop, op1, op2);
OUTPUT:  RETVAL

int
Rmpfi_bisect (rop1, rop2, op)
	mpfi_t *	rop1
	mpfi_t *	rop2
	mpfi_t *	op

void
RMPFI_ERROR (msg)
	SV *	msg
        PPCODE:
        RMPFI_ERROR(aTHX_ msg);
        XSRETURN_EMPTY; /* return empty stack */

int
Rmpfi_is_error ()


void
Rmpfi_set_error (op)
	int	op
        PPCODE:
        Rmpfi_set_error(op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpfi_reset_error ()

        PPCODE:
        Rmpfi_reset_error();
        XSRETURN_EMPTY; /* return empty stack */

SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

SV *
gmp_v ()
CODE:
  RETVAL = gmp_v (aTHX);
OUTPUT:  RETVAL


SV *
mpfr_v ()
CODE:
  RETVAL = mpfr_v (aTHX);
OUTPUT:  RETVAL


SV *
overload_spaceship (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_gte (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lte (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_gt (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lt (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_equiv (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_add (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_add (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_mul (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_mul (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_sub (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_sub (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_div (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_div (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_add_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_add_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_mul_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_mul_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_sub_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_sub_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_div_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_div_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_sqrt (p, second, third)
	mpfi_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_sqrt (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
Rmpfi_get_version ()
CODE:
  RETVAL = Rmpfi_get_version (aTHX);
OUTPUT:  RETVAL


int
Rmpfi_const_catalan (rop)
	mpfi_t *	rop

int
Rmpfi_cbrt (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_sec (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_csc (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_cot (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_sech (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_csch (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_coth (rop, op)
	mpfi_t *	rop
	mpfi_t *	op

int
Rmpfi_atan2 (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

int
Rmpfi_hypot (rop, op1, op2)
	mpfi_t *	rop
	mpfi_t *	op1
	mpfi_t *	op2

void
Rmpfi_urandom (rop, op, state)
	mpfr_t *	rop
	mpfi_t *	op
	gmp_randstate_t *	state
        PPCODE:
        Rmpfi_urandom(rop, op, state);
        XSRETURN_EMPTY; /* return empty stack */

SV *
overload_true (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_true (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_not (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_not (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_abs (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_abs (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_sin (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_sin (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_cos (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_cos (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_log (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_log (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_exp (op, second, third)
	mpfi_t *	op
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_exp (aTHX_ op, second, third);
OUTPUT:  RETVAL

SV *
overload_atan2 (a, b, third)
	mpfi_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_atan2 (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_MPFI_VERSION_MAJOR ()
CODE:
  RETVAL = _MPFI_VERSION_MAJOR (aTHX);
OUTPUT:  RETVAL


SV *
_MPFI_VERSION_MINOR ()
CODE:
  RETVAL = _MPFI_VERSION_MINOR (aTHX);
OUTPUT:  RETVAL


SV *
_MPFI_VERSION_PATCHLEVEL ()
CODE:
  RETVAL = _MPFI_VERSION_PATCHLEVEL (aTHX);
OUTPUT:  RETVAL


SV *
_MPFI_VERSION_STRING ()
CODE:
  RETVAL = _MPFI_VERSION_STRING (aTHX);
OUTPUT:  RETVAL


SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


int
_can_pass_float128 ()


int
_SvNOK (in)
	SV *	in
CODE:
  RETVAL = _SvNOK (aTHX_ in);
OUTPUT:  RETVAL

int
_SvPOK (in)
	SV *	in
CODE:
  RETVAL = _SvPOK (aTHX_ in);
OUTPUT:  RETVAL

int
nok_pokflag ()


void
clear_nok_pok ()

        PPCODE:
        clear_nok_pok();
        XSRETURN_EMPTY; /* return empty stack */

void
set_nok_pok (x)
	int	x
        PPCODE:
        set_nok_pok(x);
        XSRETURN_EMPTY; /* return empty stack */

int
_has_pv_nv_bug ()


int
_msc_ver_defined ()


