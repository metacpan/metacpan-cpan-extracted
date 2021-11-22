
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"



#include "math_gmpz_include.h"

SV * MATH_GMPz_IV_MAX(pTHX) {
     return newSViv((IV)IV_MAX);
}

SV * MATH_GMPz_IV_MIN(pTHX) {
     return newSViv((IV)IV_MIN);
}

SV * MATH_GMPz_UV_MAX(pTHX) {
     return newSVuv((UV)UV_MAX);
}

int _is_infstring(char * s) {
  int sign = 1;

  if(s[0] == '-') {
    sign = -1;
    s++;
  }
  else {
    if(s[0] == '+') s++;
  }

  if((s[0] == 'i' || s[0] == 'I') && (s[1] == 'n' || s[1] == 'N') && (s[2] == 'f' || s[2] == 'F'))
    return sign;

#ifdef _WIN32_BIZARRE_INFNAN /* older Win32 perls stringify infinities as(-)1.#INF */

   if(!strcmp(s, "1.#INF")) return sign;

#endif

  return 0;
}

SV * Rmpz_init_set_str_nobless(pTHX_ SV * num, SV * base) {
     mpz_t * mpz_t_obj;
     int b = (int)SvUV(base);
     SV * obj_ref, * obj;

     if(b == 1 || b > 62) croak("Second argument supplied to Rmpz_init_set_str_nobless is not in acceptable range");

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_create function");
     if(mpz_init_set_str (*mpz_t_obj, SvPV_nolen(num), b))
        croak("First argument supplied to Rmpz_create_init_nobless is not a valid base %u integer", b);

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * Rmpz_init2_nobless(pTHX_ SV * bits) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init2_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpz_init2 (*mpz_t_obj, SvUV(bits));

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * Rmpz_init_nobless(pTHX) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpz_init(*mpz_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_nobless(pTHX_ mpz_t * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpz_init_set(*mpz_t_obj, *p);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_ui_nobless(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_ui_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpz_init_set_ui(*mpz_t_obj, SvUV(p));

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_si_nobless(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_si_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpz_init_set_si(*mpz_t_obj, SvIV(p));

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}


SV * Rmpz_init_set_d_nobless(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     double d = SvNV(p);

     if(d != d) croak("In Rmpz_set_d, cannot coerce a NaN to a Math::GMPz value");
     if(d != 0 && (d / d != 1))
       croak("In Rmpz_init_set_d_nobless, cannot coerce an Inf to a Math::GMPz value");

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_d_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpz_init_set_d(*mpz_t_obj, d);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init(pTHX) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set(pTHX_ mpz_t * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init_set(*mpz_t_obj, *p);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_ui(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_ui function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init_set_ui(*mpz_t_obj, SvUV(p));

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_si(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_si function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init_set_si(*mpz_t_obj, SvIV(p));

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

void Rmpz_set_uj(mpz_t * copy, UV original) {
#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     mpz_set_ui(*copy, original >> 32);
     if(mpz_cmp_ui(*copy, 0))
       mpz_mul_2exp(*copy, *copy, 32);
     mpz_add_ui(*copy, *copy, original & 4294967295);

#else
     croak("Rmpz_set_uj function not implemented on this build of perl");

#endif

}

void Rmpz_set_sj(mpz_t * copy, IV original) {
#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(original >= 0) Rmpz_set_uj(copy, original);
     else {
       Rmpz_set_uj(copy, -original);
       mpz_neg(*copy, *copy);
     }

#else
     croak("Rmpz_set_sj function not implemented on this build of perl");

#endif

}

/* also handles UV values */

void Rmpz_set_IV(pTHX_ mpz_t * copy, SV * original) {

     if(SV_IS_IOK(original)) {
#ifndef MATH_GMPZ_NEED_LONG_LONG_INT
       if(SvUOK(original))   mpz_set_ui(*copy, SvUVX(original));
       else mpz_set_si(*copy, SvIVX(original));
     }

#else
       if(SvUOK(original))   Rmpz_set_uj(copy, SvUVX(original));
       else Rmpz_set_sj(copy, SvIVX(original));
     }

#endif
     else croak("Arg provided to Rmpz_set_IV is not an IV");
}

/* also handles UV values */
SV * Rmpz_init_set_IV(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_IV function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");

     mpz_init(*mpz_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     Rmpz_set_IV(aTHX_ mpz_t_obj, p);
     SvREADONLY_on(obj);
     return obj_ref;
}

/* also handles UV values */
SV * Rmpz_init_set_IV_nobless(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_IV_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "NULL");

     mpz_init(*mpz_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     Rmpz_set_IV(aTHX_ mpz_t_obj, p);
     SvREADONLY_on(obj);
     return obj_ref;
}

/* also handles UV values */
SV * _Rmpz_get_IV(pTHX_ mpz_t * n) {

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT

   int negative = 0;
   char * out;
   SV * outsv;
   mpz_t temp;
   mpz_t _uv_max;
   mpz_t _iv_max;
   mpz_t _iv_min;

#endif

   if(mpz_fits_slong_p(*n))
     return newSViv(mpz_get_si(*n));

   if(mpz_fits_ulong_p(*n))
     return newSVuv(mpz_get_ui(*n));

#ifndef MATH_GMPZ_NEED_LONG_LONG_INT

   if(mpz_cmp_ui(*n, 0) > 0)
     return newSVuv(mpz_get_ui(*n));

   return newSViv(mpz_get_si(*n));

#else

   if(mpz_sgn(*n) < 0) negative = 1;

   Newxz(out, 24, char);
   if(out == NULL)
     croak("Failed to allocate memory in Rmpz_get_IV function");

   if(negative) { /* must be less than LONG_MIN */
     mpz_init_set_str(_iv_min, SvPV_nolen(MATH_GMPz_IV_MIN(aTHX)), 10);
     if(mpz_cmp(*n, _iv_min) < 0) { /* must be less than IV_MIN */
       mpz_clear(_iv_min);
       mpz_init(temp);
       mpz_init_set_str(_iv_max, SvPV_nolen(MATH_GMPz_IV_MAX(aTHX)), 10);
       mpz_abs(temp, *n);
       mpz_and(temp, temp, _iv_max);
       mpz_clear(_iv_max);
       mpz_neg(temp, temp);
       mpz_get_str(out, 10, temp);
       mpz_clear(temp);
       outsv = newSVpv(out, 0);
       Safefree(out);
       return outsv;
     }
     else { /* must fit into an IV */
       mpz_clear(_iv_min);
       mpz_get_str(out, 10, *n);
       outsv = newSVpv(out, 0);
       Safefree(out);
       return outsv;
     }
   }
   else { /* it's +ve */
     mpz_init_set_str(_uv_max, SvPV_nolen(MATH_GMPz_UV_MAX(aTHX)), 10);
     if(mpz_cmp(*n, _uv_max) > 0) { /* needs to be truncated */
       mpz_init_set(temp, *n);
       mpz_and(temp, temp, _uv_max);
       mpz_clear(_uv_max);
       mpz_get_str(out, 10, temp);
       mpz_clear(temp);
       outsv = newSVpv(out, 0);
       Safefree(out);
       return outsv;
     }
     else { /* must fit into a UV */
       mpz_clear(_uv_max);
       mpz_get_str(out, 10, *n);
       outsv = newSVpv(out, 0);
       Safefree(out);
       return outsv;
     }
   }

#endif
}

/* also handles UVs */
int Rmpz_fits_IV_p(pTHX_ mpz_t * n) {

#ifndef MATH_GMPZ_NEED_LONG_LONG_INT
     if(mpz_fits_slong_p(*n) || mpz_fits_ulong_p(*n)) return 1;
     return 0;
#else
     mpz_t t;

     if(mpz_fits_slong_p(*n) || mpz_fits_ulong_p(*n)) return 1;

     mpz_init_set_str(t, SvPV_nolen(MATH_GMPz_UV_MAX(aTHX)), 10);
     if(mpz_cmp(*n, t) > 0) {
       mpz_clear(t);
       return 0;
     }

     mpz_set_str(t, SvPV_nolen(MATH_GMPz_IV_MIN(aTHX)), 10);
     if(mpz_cmp(*n, t) < 0) {
       mpz_clear(t);
       return 0;
     }

     mpz_clear(t);
     return 1;

#endif
}

double Rmpz_get_d(mpz_t * n) {
     return mpz_get_d(*n);
}

NV Rmpz_get_NV(mpz_t * n) {

#if NVSIZE == 8
     return mpz_get_d(*n);

#else
   /* Rely on strtold/strtoflt128 to correctly handle *
    * the stringified form of the mpz_t argument      */
     NV d;
     char * out;

     Newxz(out, mpz_sizeinbase(*n, 10) + 3, char);
     if(out == NULL) croak("Failed to allocate memory in Rmpz_get_NV function");

     mpz_get_str(out, 10, *n);

#  if defined(USE_LONG_DOUBLE)
       d = strtold(out, NULL);

#  elif defined(USE_QUADMATH)
       d = strtoflt128(out, NULL);

#  else
       Safefree(out);
       croak("Unrecognized nvtype");

#  endif
     Safefree(out);
     return d;

#endif
}

/* also handles UV values */

int Rmpz_cmp_IV(pTHX_ mpz_t * z, SV * iv) {
     int ret;

#ifndef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(iv)) {
       if(SvUOK(iv)) ret =  mpz_cmp_ui(*z, SvUVX(iv));
       else ret = mpz_cmp_si(*z, SvIVX(iv));
       return ret;
     }
     else croak("Arg provided to Rmpz_cmp_IV is not an IV");
#else
     mpz_t temp;
     if(SV_IS_IOK(iv)) mpz_init_set_str(temp, SvPV_nolen(iv), 10);
     else croak("Arg provided to Rmpz_cmp_IV is not an IV");
     ret = mpz_cmp(*z, temp);
     mpz_clear(temp);
     return ret;
#endif


}

SV * Rmpz_init_set_d(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     double d = SvNV(p);

     if(d != d) croak("In Rmpz_init_set_d, cannot coerce a NaN to a Math::GMPz value");
     if(d != 0 && (d / d != 1))
       croak("In Rmpz_init_set_d, cannot coerce an Inf to a Math::GMPz value");

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_d function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init_set_d(*mpz_t_obj, d);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

void _mpf_set_dd(mpf_t * q, SV * p) {
#if defined(NV_IS_DOUBLEDOUBLE)  /* double-double */
     double msd;                 /* Most Significant Double */
     mpf_t t, d;
     long double lsd;            /* Will be assigned the Least Siginficant Double */

     msd = (double)SvNV(p);
     if(msd != 0.0) {
       if(msd != msd) croak("In _Rmpf_set_ld, cannot coerce a NaN to a Math::GMPf object");
       if(msd / msd != 1.0) croak("In _Rmpf_set_ld, cannot coerce an Inf to a Math::GMPf object");
     }

     lsd = SvNV(p) - (long double)msd;

     mpf_init2(t, 2098);
     mpf_init2(d, 53);
     mpf_set_d(t, msd);
     mpf_set_d(d, (double)lsd);
     mpf_add(t, t, d);

     mpf_clear(d);

     mpf_set(*q, t);

     mpf_clear(t);
#else
     croak("_mpf_set_dd is unavailable because NV is not DoubleDouble");

#endif
}

void Rmpz_set_NV(pTHX_ mpz_t * copy, SV * original) {
   NV nv;

#if defined(USE_QUADMATH) || defined(USE_LONG_DOUBLE)
#  if defined(NV_IS_DOUBLEDOUBLE)
     mpf_t f;

#  else
     NV buffer_size;
     int returned;
     char * buffer;

#  endif

#endif

     if(!SV_IS_NOK(original))
       croak("In Rmpz_set_NV, 2nd argument is not an NV");

     nv = SvNV(original); /* First check that the NV flag is set   *
                           * else flags of "original" might change */

     if(nv != nv) croak("In Rmpz_set_NV, cannot coerce a NaN to a Math::GMPz value");

     if(nv != 0 && (nv / nv != 1))
       croak("In Rmpz_set_NV, cannot coerce an Inf to a Math::GMPz value");

#if defined(USE_QUADMATH)
     buffer_size = nv < 0.0Q ? nv * -1.0Q : nv;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, (int)buffer_size + 5, char);

     nv = nv >= 0 ? floorq(nv) : ceilq(nv);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", nv);
     if(returned < 0) croak("In Rmpz_set_NV, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Rmpz_set_NV, buffer given to quadmath_snprintf function was too small");
     mpz_set_str(*copy, buffer, 10);
     Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)
# if defined(NV_IS_DOUBLEDOUBLE)
     mpf_init2(f, 2098);
     _mpf_set_dd(&f, original);
     mpz_set_f(*copy, f);
     mpf_clear(f);

#  else
     buffer_size = nv < 0.0L ? nv * -1.0L : nv;
     buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);
     Newxz(buffer, buffer_size + 5, char);

     nv = nv >= 0 ? floorl(nv) : ceill(nv);
     if(sprintf(buffer, "%.0Lf", nv) >= (int)buffer_size + 5) croak("In Rmpz_set_NV, buffer overflow in sprintf function");

     mpz_set_str(*copy, buffer, 10);
     Safefree(buffer);

#  endif

#else
     mpz_set_d(*copy, nv);

#endif
}

SV * Rmpz_init_set_NV(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     Newx(mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_NV function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");

     mpz_init(*mpz_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     Rmpz_set_NV(aTHX_ mpz_t_obj, p);
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_NV_nobless(pTHX_ SV * p) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     Newx(mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_NV_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "NULL");

     mpz_init(*mpz_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     Rmpz_set_NV(aTHX_ mpz_t_obj, p);
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpz_init_set_str(pTHX_ SV * num, SV * base) {
     mpz_t * mpz_t_obj;
     int b = (int)SvUV(base);
     SV * obj_ref, * obj;

     if(b == 1 || b > 62) croak("Second argument supplied to Rmpz_init_set_str is not in acceptable range");

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init_set_str function");
     if(mpz_init_set_str (*mpz_t_obj, SvPV_nolen(num), b))
        croak("First argument supplied to Rmpz_init_set_str is not a valid base %u integer", b);

     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * Rmpz_init2(pTHX_ SV * bits) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Rmpz_init2 function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init2 (*mpz_t_obj, SvUV(bits));

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;

}

SV * Rmpz_get_str(pTHX_ mpz_t * p, SV * base) {
     char * out;
     SV * outsv;
     int c = (int)SvIV(base), b = (int)SvIV(base);

     if((b > -2 && b < 2) || b < -36 || b > 62) croak("Second argument supplied to Rmpz_get_str is not in acceptable range");

     if(c < 0) c *= -1;

     New(2, out, mpz_sizeinbase(*p, c) + 5, char);
     if(out == NULL) croak("Failed to allocate memory in Rmpz_deref function");

     mpz_get_str(out, b, *p);
     outsv = newSVpv(out, 0);
     Safefree(out);
     return outsv;
}

void DESTROY(pTHX_ mpz_t * p) {
/*     printf("Destroying mpz "); */
     mpz_clear(*p);
     Safefree(p);
/*     printf("...destroyed\n"); */
}

void Rmpz_clear(pTHX_ mpz_t * p) {
     mpz_clear(*p);
     Safefree(p);
}

void Rmpz_clear_mpz(mpz_t * p) {
     mpz_clear(*p);
}

void Rmpz_clear_ptr(pTHX_ mpz_t * p) {
     Safefree(p);
}

void Rmpz_realloc2(pTHX_ mpz_t * integer, SV * bits){
     mpz_realloc2(*integer, SvUV(bits));
}

void Rmpz_set(mpz_t * copy, mpz_t * original) {
     mpz_set(*copy, *original);
}

void Rmpz_set_q(mpz_t * copy, mpq_t * original) {
     mpz_set_q(*copy, *original);
}

void Rmpz_set_f(mpz_t * copy, mpf_t * original) {
     mpz_set_f(*copy, *original);
}

void Rmpz_set_si(mpz_t * copy, long original) {
     mpz_set_si(*copy, original);
}

void Rmpz_set_ui(mpz_t * copy, unsigned long original) {
     mpz_set_ui(*copy, original);
}

void Rmpz_set_d(mpz_t * copy, double d) {

     if(d != d) croak("In Rmpz_set_d, cannot coerce a NaN to a Math::GMPz value");
     if(d != 0 && (d / d != 1))
       croak("In Rmpz_set_d, cannot coerce an Inf to a Math::GMPz value");
     mpz_set_d(*copy, d);
}

void Rmpz_set_str(pTHX_ mpz_t * copy, SV * original, int base) {
    if(base == 1 || base > 62) croak("Second argument supplied to Rmpz_set_str is not in acceptable range");
    if(mpz_set_str(*copy, SvPV_nolen(original), base))
       croak("Second argument supplied to Rmpz_set_str is not a valid base %u integer", base);
}

void Rmpz_swap(mpz_t * a, mpz_t * b) {
     mpz_swap(*a, *b);
}

unsigned long Rmpz_get_ui(mpz_t * n) {
     return mpz_get_ui(*n);
}

long Rmpz_get_si(mpz_t * n) {
     return mpz_get_si(*n);
}

void Rmpz_get_d_2exp(pTHX_ mpz_t * n) {
     dXSARGS;
     double d;
     long exp;

     d = mpz_get_d_2exp(&exp, *n);

     /* sp = mark; */ /* not needed */
     EXTEND(SP, 2);
     ST(0) = sv_2mortal(newSVnv(d));
     ST(1) = sv_2mortal(newSVuv(exp));
     /* PUTBACK; */ /* not needed */
     XSRETURN(2);
}

SV * Rmpz_getlimbn(pTHX_ mpz_t * p, SV * n) {
     return newSVuv(mpz_getlimbn(*p, SvUV(n)));
}

void Rmpz_add(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_add(*dest, *src1, *src2 );
}

void Rmpz_add_ui(mpz_t * dest, mpz_t * src, unsigned long num) {
     mpz_add_ui(*dest, *src, num);
/*     return sv_setref_pv(newSViv(0), Nullch, INT2PTR(mpz_t *, SvIVX(SvRV(dest)))); */
}

void Rmpz_sub(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_sub(*dest, *src1, *src2 );
}

void Rmpz_sub_ui(mpz_t * dest, mpz_t * src, unsigned long num) {
     mpz_sub_ui(*dest, *src, num);
}

void Rmpz_ui_sub(mpz_t * dest, unsigned long num, mpz_t * src) {
     mpz_ui_sub(*dest, num, *src);
}

void Rmpz_mul(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_mul(*dest, *src1, *src2 );
}

void Rmpz_mul_si(mpz_t * dest, mpz_t * src, long num) {
     mpz_mul_si(*dest, *src, num);
}

/* NOT TO BE USED
void overload_mul_expt(SV * op, SV * iv, SV * unused) {
     mpz_mul_si(*(INT2PTR(mpz_t *, SvIVX(SvRV(op)))),
                *(INT2PTR(mpz_t *, SvIVX(SvRV(op)))),
                SvIV(iv));
}
*/

void Rmpz_mul_ui(mpz_t * dest, mpz_t * src, unsigned long num) {
     mpz_mul_ui(*dest, *src, num);
}

void Rmpz_addmul(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_addmul(*dest, *src1, *src2 );
}

void Rmpz_addmul_ui(mpz_t * dest, mpz_t * src, unsigned long num) {
     mpz_addmul_ui(*dest, *src, num);
}

void Rmpz_submul(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_submul(*dest, *src1, *src2 );
}

void Rmpz_submul_ui(mpz_t * dest, mpz_t * src, unsigned long num) {
     mpz_submul_ui(*dest, *src, num);
}

void Rmpz_mul_2exp(pTHX_ mpz_t * dest, mpz_t * src1, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_mul_2exp(*dest, *src1, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_div_2exp(pTHX_ mpz_t * dest, mpz_t * src1, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_div_2exp(*dest, *src1, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_neg(mpz_t * dest, mpz_t * src) {
     mpz_neg(*dest, *src );
}

void Rmpz_abs(mpz_t * dest, mpz_t * src) {
     mpz_abs(*dest, *src );
}

void Rmpz_cdiv_q( mpz_t * q, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_cdiv_q");
     mpz_cdiv_q(*q, *n, *d);
}

void Rmpz_cdiv_r( mpz_t * mod, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_cdiv_r");
     mpz_cdiv_r(*mod, *n, *d);
}

void Rmpz_cdiv_qr( mpz_t * q, mpz_t * r, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_cdiv_qr");
     mpz_cdiv_qr(*q, *r, *n, *d);
}

unsigned long Rmpz_cdiv_q_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_cdiv_q_ui");
     return mpz_cdiv_q_ui(*q, *n, d);
}

unsigned long Rmpz_cdiv_r_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_cdiv_r_ui");
     return mpz_cdiv_r_ui(*q, *n, d);
}

unsigned long Rmpz_cdiv_qr_ui( mpz_t * q, mpz_t * r, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_cdiv_qr_ui");
     return mpz_cdiv_qr_ui(*q, *r, *n, d);
}

unsigned long Rmpz_cdiv_ui( mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_cdiv_ui");
     return mpz_cdiv_ui(*n, d);
}

void Rmpz_cdiv_q_2exp(pTHX_  mpz_t * q, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_cdiv_q_2exp(*q, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_cdiv_r_2exp(pTHX_  mpz_t * r, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_cdiv_r_2exp(*r, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_fdiv_q( mpz_t * q, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_fdiv_q");
     mpz_fdiv_q(*q, *n, *d);
}

void Rmpz_div( mpz_t * q, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_div");
     mpz_div(*q, *n, *d);
}

/* % mpz-t (modulus) operator */
void Rmpz_fdiv_r( mpz_t * mod, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_fdiv_r");
     mpz_fdiv_r(*mod, *n, *d);
}

void Rmpz_fdiv_qr( mpz_t * q, mpz_t * r, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_fdiv_qr");
     mpz_fdiv_qr(*q, *r, *n, *d);
}

void Rmpz_divmod( mpz_t * q, mpz_t * r, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_divmod");
     mpz_divmod(*q, *r, *n, *d);
}

unsigned long Rmpz_fdiv_q_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_fdiv_q_ui");
     return mpz_fdiv_q_ui(*q, *n, d);
}

unsigned long Rmpz_div_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_div_ui");
     return mpz_div_ui(*q, *n, d);
}

unsigned long Rmpz_fdiv_r_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_fdiv_r_ui");
     return mpz_fdiv_r_ui(*q, *n, d);
}

unsigned long Rmpz_fdiv_qr_ui( mpz_t * q, mpz_t * r, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_fdiv_qr_ui");
     return mpz_fdiv_qr_ui(*q, *r, *n, d);
}

unsigned long Rmpz_divmod_ui( mpz_t * q, mpz_t * r, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_divmod_ui");
     return mpz_divmod_ui(*q, *r, *n, d);
}

/* % int (modulus) operator */
unsigned long Rmpz_fdiv_ui( mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_fdiv_ui");
     return mpz_fdiv_ui(*n, d);
}

void Rmpz_fdiv_q_2exp(pTHX_  mpz_t * q, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_fdiv_q_2exp(*q, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_fdiv_r_2exp(pTHX_  mpz_t * r, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_fdiv_r_2exp(*r, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_mod_2exp(pTHX_  mpz_t * r, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_mod_2exp(*r, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_tdiv_q( mpz_t * q, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_tdiv_q");
     mpz_tdiv_q(*q, *n, *d);
}

/* % mpz-t (modulus) operator */
void Rmpz_tdiv_r( mpz_t * mod, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_tdiv_r");
     mpz_tdiv_r(*mod, *n, *d);
}

void Rmpz_tdiv_qr( mpz_t * q, mpz_t * r, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_tdiv_qr");
     mpz_tdiv_qr(*q, *r, *n, *d);
}

unsigned long Rmpz_tdiv_q_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_tdiv_q_ui");
     return mpz_tdiv_q_ui(*q, *n, d);
}

unsigned long Rmpz_tdiv_r_ui( mpz_t * q, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_tdiv_r_ui");
     return mpz_tdiv_r_ui(*q, *n, d);
}

unsigned long Rmpz_tdiv_qr_ui( mpz_t * q, mpz_t * r, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_tdiv_qr_ui");
     return mpz_tdiv_qr_ui(*q, *r, *n, d);
}

/* % int (modulus) operator */
unsigned long Rmpz_tdiv_ui( mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_tdiv_ui");
     return mpz_tdiv_ui(*n, d);
}

void Rmpz_tdiv_q_2exp(pTHX_  mpz_t * q, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_tdiv_q_2exp(*q, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_tdiv_r_2exp(pTHX_  mpz_t * r, mpz_t *  n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     mpz_tdiv_r_2exp(*r, *n, (mp_bitcnt_t)SvUVX(b));
}

void Rmpz_mod( mpz_t * r, mpz_t *  n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_mod");
     mpz_mod(*r, *n, *d);
}

unsigned long Rmpz_mod_ui( mpz_t * r, mpz_t *  n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_mod_ui");
     return mpz_mod_ui(*r, *n, d);
}

void Rmpz_divexact(mpz_t * dest, mpz_t * n, mpz_t * d) {
     if(!mpz_cmp_ui(*d, 0))
       croak("Division by 0 not allowed in Rmpz_divexact");
     mpz_divexact(*dest, *n, *d );
}

void Rmpz_divexact_ui(mpz_t * dest, mpz_t * n, unsigned long d) {
     if(d == 0)
       croak("Division by 0 not allowed in Rmpz_divexact_ui");
     mpz_divexact_ui(*dest, *n, d);
}

int Rmpz_divisible_p(mpz_t * n, mpz_t * d) {
    return mpz_divisible_p(*n, *d);
}

int Rmpz_divisible_ui_p(mpz_t * n, unsigned long d) {
     return mpz_divisible_ui_p(*n, d);
}

int Rmpz_divisible_2exp_p(pTHX_ mpz_t * n, SV * b) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     return mpz_divisible_2exp_p(*n, SvUVX(b));
}

int Rmpz_congruent_p(mpz_t * n, mpz_t * c, mpz_t * d) {
     return mpz_congruent_p(*n, *c, *d);
}

int Rmpz_congruent_ui_p(mpz_t * n, unsigned long c, unsigned long d) {
     return mpz_congruent_ui_p(*n, c, d);
}

SV * Rmpz_congruent_2exp_p(pTHX_ mpz_t * n, mpz_t * c, SV * d) {

     CHECK_MP_BITCNT_T_OVERFLOW(d)

     return newSViv(mpz_congruent_2exp_p(*n, *c, SvUVX(d)));
}

void Rmpz_powm(mpz_t * dest, mpz_t * base, mpz_t * exp, mpz_t * mod) {
     mpz_powm(*dest, *base, *exp, *mod);
}

void Rmpz_powm_ui(mpz_t * dest, mpz_t * base, unsigned long exp, mpz_t * mod) {
     mpz_powm_ui(*dest, *base, exp, *mod);
}

void Rmpz_pow_ui(mpz_t * dest, mpz_t * base, unsigned long exp) {
     mpz_pow_ui(*dest, *base, exp);
}

void Rmpz_ui_pow_ui(mpz_t * dest, unsigned long base, unsigned long exp) {
     mpz_ui_pow_ui(*dest, base, exp);
}

int Rmpz_root(mpz_t * r, mpz_t * n, unsigned long d) {
     return mpz_root(*r, *n, d);
}

void Rmpz_sqrt(mpz_t * r, mpz_t * n) {
     mpz_sqrt(*r, *n);
}

void Rmpz_sqrtrem(mpz_t * root, mpz_t * rem, mpz_t * src) {
     mpz_sqrtrem(*root, *rem, *src);
}

int Rmpz_perfect_power_p(mpz_t * in) {
    return mpz_perfect_power_p(*in);
}

int Rmpz_perfect_square_p(mpz_t * in) {
    return mpz_perfect_square_p(*in);
}

int Rmpz_probab_prime_p(pTHX_ mpz_t * cand, SV * reps) {
     return mpz_probab_prime_p(*cand, (int)SvIV(reps));
}

void Rmpz_nextprime(mpz_t * prime, mpz_t * init) {
     mpz_nextprime(*prime, *init);
}

void Rmpz_gcd(mpz_t * gcd, mpz_t * src1, mpz_t * src2) {
     mpz_gcd(*gcd, *src1, *src2);
}

/* First arg can be either (the unblessed) $Math::GMPz::NULL or a
 * (blessed) Math::GMPz object.
 */
unsigned long Rmpz_gcd_ui(mpz_t * gcd, mpz_t * n, unsigned long d) {
     return mpz_gcd_ui(*gcd, *n, d);
}

void Rmpz_gcdext(mpz_t * g, mpz_t * s, mpz_t * t, mpz_t * a, mpz_t * b) {
     mpz_gcdext(*g, *s, *t, *a, *b);
}

void Rmpz_lcm(mpz_t * lcm, mpz_t * src1, mpz_t * src2) {
     mpz_lcm(*lcm, *src1, *src2);
}

void Rmpz_lcm_ui(mpz_t * lcm, mpz_t * src1, unsigned long src2) {
     mpz_lcm_ui(*lcm, *src1, src2);
}

int Rmpz_invert(mpz_t * inv, mpz_t * src1, mpz_t * src2) {
    return mpz_invert(*inv, *src1, *src2);
}

int Rmpz_jacobi(mpz_t * a, mpz_t * b) {
    return mpz_jacobi(*a, *b);
}

int Rmpz_legendre(mpz_t * a, mpz_t * b) {
    return mpz_legendre(*a, *b);
}

int Rmpz_kronecker(mpz_t * a, mpz_t * b) {
    return mpz_kronecker(*a, *b);
}

int Rmpz_kronecker_si(mpz_t * a, long b) {
     return mpz_kronecker_si(*a, b);
}

int Rmpz_kronecker_ui(mpz_t * a, unsigned long b) {
     return mpz_kronecker_ui(*a, b);
}

int Rmpz_si_kronecker(long a, mpz_t * b) {
     return mpz_si_kronecker(a, *b);
}

int Rmpz_ui_kronecker(unsigned long a, mpz_t * b) {
     return mpz_ui_kronecker(a, *b);
}

SV * Rmpz_remove(pTHX_ mpz_t * rem, mpz_t * src1, mpz_t * src2) {
     return newSVuv(mpz_remove(*rem, *src1, *src2));
}

void Rmpz_fac_ui(mpz_t * fac, unsigned long b) {
     mpz_fac_ui(*fac, b);
}

#if __GNU_MP_VERSION > 5 || (__GNU_MP_VERSION == 5 && __GNU_MP_VERSION_MINOR >= 1)

void Rmpz_2fac_ui(mpz_t * fac, unsigned long b) {
     mpz_2fac_ui(*fac, b);
}

void Rmpz_mfac_uiui(mpz_t * fac, unsigned long b, unsigned long c) {
     mpz_mfac_uiui(*fac, b, c);
}

void Rmpz_primorial_ui(mpz_t * fac, unsigned long b) {
     mpz_primorial_ui(*fac, b);
}

#else

void Rmpz_2fac_ui(mpz_t * fac, unsigned long b) {
     croak("Rmpz_2fac_ui not implemented - gmp-5.1.0 (or later) is needed");
}

void Rmpz_mfac_uiui(mpz_t * fac, unsigned long b, unsigned long c) {
     croak("Rmpz_mfac_uiui not implemented - gmp-5.1.0 (or later) is needed");
}

void Rmpz_primorial_ui(mpz_t * fac, unsigned long b) {
     croak("Rmpz_primorial_ui not implemented - gmp-5.1.0 (or later) is needed");
}

#endif

void Rmpz_bin_ui(mpz_t * dest, mpz_t * n, unsigned long d) {
     mpz_bin_ui(*dest, *n, d);
}

void Rmpz_bin_si(mpz_t * dest, mpz_t * n, long d) {
     signed long int t = d;
     if(t >= 0) mpz_bin_ui(*dest, *n, t);
     else {
       if(mpz_sgn(*n) >= 0 || mpz_cmp_si(*n, t) < 0)
         mpz_set_ui(*dest, 0);
       else
         mpz_bin_ui(*dest, *n, mpz_get_si(*n) - t);
     }
}

void Rmpz_bin_uiui(mpz_t * dest, unsigned long n, unsigned long d) {
     mpz_bin_uiui(*dest, n, d);
}

void Rmpz_fib_ui(mpz_t * dest, unsigned long b) {
     mpz_fib_ui(*dest, b);
}

void Rmpz_fib2_ui(mpz_t * fn, mpz_t * fnsub1, unsigned long b) {
     mpz_fib2_ui(*fn, *fnsub1, b);
}

void Rmpz_lucnum_ui(mpz_t * dest, unsigned long b) {
     mpz_lucnum_ui(*dest, b);
}

void Rmpz_lucnum2_ui(mpz_t * ln, mpz_t * lnsub1, unsigned long b) {
     mpz_lucnum2_ui(*ln, *lnsub1, b);
}

int Rmpz_cmp(mpz_t * n, mpz_t * d) {
    return mpz_cmp(*n, *d );
}

int Rmpz_cmp_d(mpz_t * n, double d) {
    if(d != d) croak("In Rmpz_cmp_d, cannot compare a NaN to a Math::GMPz value");
    return mpz_cmp_d(*n, d);
}

int Rmpz_cmp_NV(pTHX_ mpz_t * a, SV * b) {

#if defined(USE_QUADMATH)

     char * buffer;
     int ret, returned;
     __float128 buffer_size;
     __float128 ld;
     mpz_t t;

     if(!SvNOK(b))
       croak("In Rmpz_cmp_NV, 2nd argument is not an NV");

     ld = (__float128)SvNV(b) >= 0 ? floorq((__float128)SvNV(b)) : ceilq((__float128)SvNV(b));
     if(ld != ld) croak("In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value");
     if((ld != 0 && (ld / ld != 1))) {
       if(ld > 0) return -1;
       return 1;
     }
     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);
     Newxz(buffer, (int)buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Rmpz_cmp_NV, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Rmpz_cmp_NV, buffer given to quadmath_snprintf function was too small");
     mpz_init_set_str(t, buffer, 10);
     Safefree(buffer);
     ret = mpz_cmp(*a, t);
     mpz_clear(t);

     if(ld == (__float128)SvNV(b)) return ret;
     /* else cannot be equal - ie must be less than or greater than */
     if(!ret) {
       if(ld >= 0) ret = -1;
       else ret = 1;
     }

     return ret;

#elif defined(USE_LONG_DOUBLE)
     long double ld;
     int ret;

# if defined(NV_IS_DOUBLEDOUBLE)
     mpf_t f, f_trunc;
     mpz_t z;

     if(!SvNOK(b))
       croak("In Rmpz_cmp_NV, 2nd argument is not an NV");

     ld = SvNV(b);

     if(ld != ld) croak("In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value");
     if((ld != 0 && (ld / ld != 1))) {
       if(ld > 0) return -1;
       return 1;
     }

     mpf_init2(f, 2098);
     mpf_init2(f_trunc, 2098);
     mpz_init(z);

     _mpf_set_dd(&f, b);
     mpf_trunc(f_trunc, f);
     mpz_set_f(z, f_trunc);

     ret = mpf_cmp(f, f_trunc);

     if(ret == 0) {
       ret = mpz_cmp(*a, z);
     }
     else if(ret > 0) {
       if(mpz_cmp(*a, z) <= 0) ret = -1;
     }

     else {
       if(mpz_cmp(*a, z) >= 0) ret = 1;
     }

     mpf_clear(f);
     mpf_clear(f_trunc);
     mpz_clear(z);
     return ret;

# else
     char * buffer;
     long double buffer_size;
     mpz_t t;

     if(!SvNOK(b))
       croak("In Rmpz_cmp_NV, 2nd argument is not an NV");

     ld = SvNV(b);

     if(ld != ld) croak("In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value");
     if((ld != 0 && (ld / ld != 1))) {
       if(ld > 0) return -1;
       return 1;
     }

     ld = ld >= 0 ? floorl((long double)SvNV(b)) : ceill((long double)SvNV(b));

     buffer_size = ld < 0.0L ? ld * -1.0L : ld;
     buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);
     Newxz(buffer, (int)buffer_size + 5, char);

     if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Rmpz_cmp_NV, buffer overflow in sprintf function");
     mpz_init_set_str(t, buffer, 10);
     Safefree(buffer);
     ret = mpz_cmp(*a, t);
     mpz_clear(t);
     if(ld == (long double)SvNV(b)) return ret;
     /* else cannot be equal - ie must be less than or greater than */
     if(!ret) {
       if(ld >= 0) ret = -1;
       else ret = 1;
     }

     return ret;

#  endif

#else

     if(!SvNOK(b))
       croak("In Rmpz_cmp_NV, 2nd argument is not an NV");

     if((double)SvNV(b) != (double)SvNV(b))
       croak("In Rmpz_cmp_NV, cannot compare a NaN to a Math::GMPz value");

     return mpz_cmp_d(*a, (double)SvNV(b));

#endif

}

int Rmpz_cmp_si(mpz_t * n, long d) {
    return mpz_cmp_si(*n, d);
}

int Rmpz_cmp_ui(mpz_t * n, unsigned long d) {
     return mpz_cmp_ui(*n, d);
}

int Rmpz_cmpabs(mpz_t * n, mpz_t * d) {
    return mpz_cmpabs(*n, *d );
}

int Rmpz_cmpabs_d(mpz_t * n, double d) {
     return mpz_cmpabs_d(*n, d);
}

int Rmpz_cmpabs_ui(mpz_t * n, unsigned long d) {
     return mpz_cmpabs_ui(*n, d);
}

int Rmpz_sgn(mpz_t * n) {
    return mpz_sgn(*n);
}

void Rmpz_and(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_and(*dest, *src1, *src2 );
}

void Rmpz_ior(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_ior(*dest, *src1, *src2 );
}

void Rmpz_xor(mpz_t * dest, mpz_t * src1, mpz_t * src2) {
     mpz_xor(*dest, *src1, *src2 );
}

void Rmpz_com(mpz_t * dest, mpz_t * src) {
     mpz_com(*dest, *src );
}

SV * Rmpz_popcount(pTHX_ mpz_t * in) {
    return newSVuv(mpz_popcount(*in));
}

SV * Rmpz_hamdist(pTHX_ mpz_t * dest, mpz_t * src) {
     return newSVuv(mpz_hamdist(*dest, *src ));
}

SV * Rmpz_scan0(pTHX_ mpz_t * n, SV * start_bit) {

     CHECK_MP_BITCNT_T_OVERFLOW(start_bit)

    return newSVuv(mpz_scan0(*n, (mp_bitcnt_t)SvUV(start_bit)));
}

SV * Rmpz_scan1(pTHX_ mpz_t * n, SV * start_bit) {

     CHECK_MP_BITCNT_T_OVERFLOW(start_bit)

    return newSVuv(mpz_scan1(*n, (mp_bitcnt_t)SvUV(start_bit)));
}

void Rmpz_setbit(pTHX_ mpz_t * num, SV * bit_index) {

     CHECK_MP_BITCNT_T_OVERFLOW(bit_index)

     mpz_setbit(*num, (mp_bitcnt_t)SvUV(bit_index));
}

void Rmpz_clrbit(pTHX_ mpz_t * num, SV * bit_index) {

     CHECK_MP_BITCNT_T_OVERFLOW(bit_index)

     mpz_clrbit(*num, (mp_bitcnt_t)SvUV(bit_index));
}

SV * Rmpz_tstbit(pTHX_ mpz_t * num, SV * bit_index) {

     CHECK_MP_BITCNT_T_OVERFLOW(bit_index)

     return newSViv(mpz_tstbit(*num, (mp_bitcnt_t)SvUV(bit_index)));
}

/* Turn a binary string into an mpz_t */
void Rmpz_import(pTHX_ mpz_t * rop, SV * count, SV * order, SV * size, SV * endian, SV * nails, SV * op){
    int is_utf8 = 0;

    if(SvUTF8(op) && !SvIV(get_sv("Math::GMPz::utf8_no_downgrade", 0))) {
      if(!SvIV(get_sv("Math::GMPz::utf8_no_warn", 0))) {
        warn( "%s", RMPZ_IMPORT_UTF8_WARN ); /* RMPZ_IMPORT_UTF8_WARN defined in math_gmpz_include.h */
        warn("  To disable this warning set $Math::GMPz::utf8_no_warn to 1.");
      }

      is_utf8 = 1;
      if(!sv_utf8_downgrade(op, SvIV(get_sv("Math::GMPz::utf8_no_croak", 0)))) {
        /* downgrade has failed, and this will cause an immediate croak if     *
         * $Math::GMPz::utf8_no_croak is false. If $Math::GMPz::utf8_no_croak  *
         * is true && $Math::GMPz::utf8_no_fail is false, we warn as follows:  */

        if(!SvIV(get_sv("Math::GMPz::utf8_no_fail", 0))) {
          /* No need to check status of $Math::GMPz::utf8_no_croak. *
           * If we've reached here then it must be true.            */
          warn("%s", RMPZ_IMPORT_DOWNGRADE_WARN); /*RMPZ_IMPORT_DOWNGRADE_WARN defined in math_gmpz_include.h */
          warn("  To disable this warning set $Math::GMPz::utf8_no_fail to 1");
        }
      }
    }

    mpz_import(*rop, SvUV(count), SvIV(order), SvIV(size), SvIV(endian), SvUV(nails), SvPV_nolen(op));
    if(is_utf8) sv_utf8_upgrade(op);
}

/* Return an mpz_t to a binary string */
SV * Rmpz_export(pTHX_ SV * order, SV * size, SV * endian, SV * nails, mpz_t * op) {
    SV * outsv;
    char * arr;
    int count;
    int numb = (8 * SvIV(size)) - SvUV(nails);

    count = (mpz_sizeinbase (*op, 2) + numb - 1) / numb;

    Newxz(arr, count, char);
    if(arr == NULL) croak("Couldn't allocate memory in Rmpz_export");

    mpz_export(arr, NULL, SvIV(order), SvIV(size), SvIV(endian), SvIV(nails), *op);
    outsv = newSVpv(arr, count);
    Safefree(arr);
    return outsv;
}

/* Turn an array of UVs into an mpz_t */
void Rmpz_import_UV(pTHX_ mpz_t * rop, SV * count, SV * order, SV * size, SV * endian, SV * nails, AV * op){
    int len, i;
    UV * arr;

    len = av_len(op) + 1;

    Newxz(arr, len, UV);
    if(arr == NULL) croak("Couldn't allocate memory in Rmpz_import_UV");

    for(i = 0; i < len; i++) {
      arr[i] = SvUV(*(av_fetch(op, i, 0)));
    }

    mpz_import(*rop, SvUV(count), SvIV(order), SvIV(size), SvIV(endian), SvUV(nails), arr);

    Safefree(arr);
}


/* Return an mpz_t to an array of UVs */
void Rmpz_export_UV(pTHX_ SV * order, SV * size, SV * endian, SV * nails, mpz_t * op) {
    dXSARGS;
    UV * arr;
    int count, i;
    int numb = (8 * SvIV(size)) - SvUV(nails);

    count = (mpz_sizeinbase (*op, 2) + numb - 1) / numb;

    Newxz(arr, count, UV);
    if(arr == NULL) croak("Couldn't allocate memory in Rmpz_export_UV");

    mpz_export(arr, NULL, SvIV(order), SvIV(size), SvIV(endian), SvIV(nails), *op);

    sp = mark;

    for(i = 0; i < count; i++) {
      XPUSHs(sv_2mortal(newSVuv(arr[i])));
    }

    Safefree(arr);
    XSRETURN(count);
}

int Rmpz_fits_ulong_p(mpz_t * in) {
    return mpz_fits_ulong_p(*in);
}

int Rmpz_fits_slong_p(mpz_t * in) {
    return mpz_fits_slong_p(*in);
}

int Rmpz_fits_uint_p(mpz_t * in) {
    return mpz_fits_uint_p(*in);
}

int Rmpz_fits_sint_p(mpz_t * in) {
    return mpz_fits_sint_p(*in);
}

int Rmpz_fits_ushort_p(mpz_t * in) {
    return mpz_fits_ushort_p(*in);
}

int Rmpz_fits_sshort_p(mpz_t * in) {
    return mpz_fits_sshort_p(*in);
}

int Rmpz_odd_p(mpz_t * in) {
    return mpz_odd_p(*in);
}

int Rmpz_even_p(mpz_t * in) {
    return mpz_even_p(*in);
}

SV * Rmpz_size(pTHX_ mpz_t * in) {
    return newSVuv(mpz_size(*in));
}

SV * Rmpz_sizeinbase(pTHX_ mpz_t * in, int base) {
    if(base < 2 || base > 62) croak("Rmpz_sizeinbase handles only bases in the range 2..62");
    return newSVuv(mpz_sizeinbase(*in, base));
}

void Rsieve_gmp(pTHX_ int x_arg, int a, mpz_t *number) {
dXSARGS;
unsigned short *v, *addon, set[16] = {65534,65533,65531,65527,65519,65503,65471,65407,65279,65023,64511,63487,61439,57343,49151,32767};
unsigned long init, leap, abits, asize, i, size, b, imax, k, x = x_arg;

if(sizeof(short) != 2) croak("The sieve_gmp function is unsuitable for this architecture.\nContact the author and he may do something about it.");
if(a & 1) croak("max_add must be even in sieve_gmp function");
if(x & 1) croak("max_prime must be even in sieve_gmp function");

if(!mpz_tstbit(*number, 0)) croak("candidate must be odd in sieve_gmp function");

abits = (a / 2) + 1;

if(!(abits % 16)) asize = abits / 16;
else asize = (abits / 16) + 1;

Newz(1, addon, asize, unsigned short);
if(addon == NULL) croak("1: Unable to allocate memory in sieve_gmp function");

for(i = 0; i < asize; ++i) addon[i] = 65535;

imax = sqrt(x - 1) / 2;

b = (x + 1) / 2;

if(!(b % 16)) size = b / 16;
else size = (b / 16) + 1;

Newz(2, v, size, unsigned short);
if(v == NULL) croak("2: Unable to allocate memory in sieve_gmp function");

for(i = 1; i < size; ++i) v[i] = 65535;
v[0] = 65534;

for(i = 0; i <= imax; ++i) {

    if(v[i / 16] & (1 << (i % 16))) {
       leap = (2 * i) + 1;
       k = 2 * i * (i + 1);
       while(k < b) {
             v[k / 16] &= set[k % 16];
             k += leap;
             }
       }
}

size = 0;
sp = mark;

for(i = 0; i < b; ++i) {
    if(v[i / 16] & (1 << (i % 16))) {
      leap = 2 * i + 1;
        init = mpz_fdiv_ui(*number, leap);
      if(init) {
        if(init & 1) init = (leap - init) / 2;
        else init = leap - (init / 2);
        }
      while(init < abits) {
         addon[init / 16] &= set[init % 16];
         init += leap;
         }
      }
   }

Safefree(v);

for(i = 0; i < abits; ++i) {
    if(addon[i / 16] & (1 << (i % 16))) {
      XPUSHs(sv_2mortal(newSViv(2 * i)));
      ++size;
      }
   }

Safefree(addon);

PUTBACK;
XSRETURN(size);

}

SV * Rfermat_gmp(pTHX_ mpz_t * num, int base){
     mpz_t b, num_less_1;

     mpz_init_set_ui(b, base);
     mpz_init_set(num_less_1, *num);
     mpz_sub_ui(num_less_1, num_less_1, 1);
     mpz_powm(b, b, num_less_1, *num);

     if(!mpz_cmp_si(b, 1)) {
        mpz_clear(b);
        mpz_clear(num_less_1);
        return newSViv(1);
     }

     mpz_clear(b);
     mpz_clear(num_less_1);
     return newSViv(0);
}

SV * Rrm_gmp(pTHX_ mpz_t * num, int base){
     mpz_t c_less, r, y, bb;
     unsigned long i, s = 0, b = base;

     mpz_init(c_less);
     mpz_init(r);
     mpz_init(y);

     mpz_sub_ui(c_less, *num, 1);
     mpz_set(r, c_less);
     mpz_init_set_ui(bb, b);

     while(mpz_even_p(r)) {
       mpz_tdiv_q_2exp(r, r, 1);
       ++s;
     }

     mpz_powm(y, bb, r, *num);
     mpz_clear(r);
     mpz_clear(bb);
     if(mpz_cmp_ui(y, 1) && mpz_cmp(y, c_less)) {
       for(i = 0; i < s; ++i) {
          mpz_powm_ui(y, y, 2, *num);
          if(!mpz_cmp_ui(y, 1)) {
             mpz_clear(c_less);
             mpz_clear(y);
             return 0;
          }
          if(!mpz_cmp(y, c_less)) break;
       }
       if(mpz_cmp(y, c_less)) {
         mpz_clear(c_less);
         mpz_clear(y);
         return newSViv(0);
       }
     }

     mpz_clear(c_less);
     mpz_clear(y);
     return newSVuv(1);
}

SV * _Rmpz_out_str(pTHX_ mpz_t * p, int base) {
     unsigned long ret;
     if((base > -2 && base < 2) || base < -36 || base > 62)
       croak("2nd argument supplied to Rmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     ret = mpz_out_str(NULL, base, *p);
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpz_out_strS(pTHX_ mpz_t * p, SV * base, SV * suff) {
     unsigned long ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("2nd argument supplied to Rmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     ret = mpz_out_str(NULL, SvUV(base), *p);
     printf("%s", SvPV_nolen(suff));
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpz_out_strP(pTHX_ SV * pre, mpz_t * p, SV * base) {
     unsigned long ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("3rd argument supplied to Rmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     printf("%s", SvPV_nolen(pre));
     ret = mpz_out_str(NULL, SvUV(base), *p);
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpz_out_strPS(pTHX_ SV * pre, mpz_t * p, SV * base, SV * suff) {
     unsigned long ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("3rd argument supplied to Rmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     printf("%s", SvPV_nolen(pre));
     ret = mpz_out_str(NULL, SvUV(base), *p);
     printf("%s", SvPV_nolen(suff));
     fflush(stdout);
     return newSVuv(ret);
}

SV * _TRmpz_out_str(pTHX_ FILE * stream, SV * base, mpz_t * p) {
     size_t ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("2nd argument supplied to TRmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     ret = mpz_out_str(stream, (int)SvIV(base), *p);
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpz_out_strS(pTHX_ FILE * stream, SV * base, mpz_t * p, SV * suff) {
     size_t ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("2nd argument supplied to TRmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     ret = mpz_out_str(stream, (int)SvIV(base), *p);
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpz_out_strP(pTHX_ SV * pre, FILE * stream, SV * base, mpz_t * p) {
     size_t ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("3rd argument supplied to TRmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpz_out_str(stream, (int)SvIV(base), *p);
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpz_out_strPS(pTHX_ SV * pre, FILE * stream, SV * base, mpz_t * p, SV * suff) {
     size_t ret;
     if((SvIV(base) > -2 && SvIV(base) < 2) || SvIV(base) < -36 || SvIV(base) > 62)
       croak("3rd argument supplied to TRmpz_out_str is out of allowable range (must be in range -36..-2, 2..62)");
     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpz_out_str(stream, (int)SvIV(base), *p);
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * Rmpz_inp_str(pTHX_ mpz_t * p, int base) {
     size_t ret;
     if(base == 1 || base > 62)
       croak("2nd argument supplied to Rmpz_inp_str is out of allowable range (must be in range 0, 2..62)");
     ret = mpz_inp_str(*p, NULL, base);
     /* fflush(stdin); */
     return newSVuv(ret);
}

SV * TRmpz_inp_str(pTHX_ mpz_t * p, FILE * stream, int base) {
     size_t ret;
     if(base == 1 || base > 62)
       croak("4th argument supplied to TRmpz_inp_str is out of allowable range (must be in range 0, 2..62)");
     ret = mpz_inp_str(*p, stream, base);
     /* fflush(stream); */
     return newSVuv(ret);
}

void eratosthenes(pTHX_ SV * x_arg) {
dXSARGS;

unsigned short *v, set[16] = {65534,65533,65531,65527,65519,65503,65471,65407,65279,65023,64511,63487,61439,57343,49151,32767};
unsigned long leap, i, size, b, imax, k, x = SvUV(x_arg);

if(x & 1) croak("max_num argument must be even in eratosthenes function");

imax = sqrt(x - 1) / 2;

b = (x + 1) / 2;

if(!(b % 16)) size = b / 16;
else size = (b / 16) + 1;

Newz(2, v, size, unsigned short);
if(v == NULL) croak("2: Unable to allocate memory in eratosthenes function");

for(i = 1; i < size; ++i) v[i] = 65535;
v[0] = 65534;

for(i = 0; i <= imax; ++i) {

    if(v[i / 16] & (1 << (i % 16))) {
       leap = (2 * i) + 1;
       k = 2 * i * (i + 1);
       while(k < b) {
             v[k / 16] &= set[k % 16];
             k += leap;
             }
       }
}

size = 1;
sp = mark;
XPUSHs(sv_2mortal(newSVuv(2)));

for(i = 0; i < b; ++i) {
    if(v[i / 16] & (1 << (i % 16))) {
      XPUSHs(sv_2mortal(newSVuv(2 * i + 1)));
      ++size;
      }
   }

Safefree(v);

PUTBACK;
XSRETURN(size);

}


SV * trial_div_ul(pTHX_ mpz_t * num, SV * x_arg) {

     unsigned short *v, set[16] = {65534,65533,65531,65527,65519,65503,65471,65407,65279,65023,64511,63487,61439,57343,49151,32767};
     unsigned long leap, i, size, b, imax, k, x = SvUV(x_arg);

     if(x & 1) croak("Second argument supplied to trial_div_ul must be even");

     imax = sqrt(x - 1) / 2;

     b = (x + 1) / 2;

     if(!(b % 16)) size = b / 16;
     else size = (b / 16) + 1;

     Newz(2, v, size, unsigned short);
     if(v == NULL) croak("2: Unable to allocate memory in trial_div_ul function");

     for(i = 1; i < size; ++i) v[i] = 65535;
     v[0] = 65534;

     for(i = 0; i <= imax; ++i) {

       if(v[i / 16] & (1 << (i % 16))) {
         leap = (2 * i) + 1;
         k = 2 * i * (i + 1);
         while(k < b) {
           v[k / 16] &= set[k % 16];
           k += leap;
         }
       }
     }

     if(mpz_divisible_ui_p(*num, 2)) {
       Safefree(v);
       return newSViv(2);
     }

     for(i = 0; i < b; ++i) {
       if(v[i / 16] & (1 << (i % 16))) {
         if(mpz_divisible_ui_p(*num, 2 * i + 1)) {
           Safefree(v);
           return newSViv(2 * i + 1);
         }
       }
     }

     Safefree(v);

     return newSViv(1);
}

/* Next 2 functions became available with GMP-4.2 */

void Rmpz_rootrem(mpz_t * root, mpz_t * rem, mpz_t * u, unsigned long d) {
     mpz_rootrem(*root, *rem, *u, d);
}

void Rmpz_combit(pTHX_ mpz_t * num, SV * bitpos) {

     CHECK_MP_BITCNT_T_OVERFLOW(bitpos)

     mpz_combit(*num, (mp_bitcnt_t)SvUV(bitpos));
}

/* Finish typemapping - typemap 1st arg only */

SV * overload_mul(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     if(sv_isobject(b)) h = HvNAME(SvSTASH(SvRV(b)));

     if(!sv_isobject(b) || (strNE(h, "Math::MPFR") && strNE(h, "Math::GMPq"))) {
       New(1, mpz_t_obj, 1, mpz_t);
       if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_mul function");
       obj_ref = newSV(0);
       obj = newSVrv(obj_ref, "Math::GMPz");
       mpz_init(*mpz_t_obj);
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
     }

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       mpz_mul(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }
#else

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_mul_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return obj_ref;
       }

       mpz_mul_si(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
         croak(" Invalid string (%s) supplied to Math::GMPz::overload_mul", SvPV_nolen(b));
       mpz_mul(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_mul, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_mul, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) croak("In Math::GMPz::overload_mul, encoding error in quadmath_snprintf function");
       if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_mul, buffer given to quadmath_snprintf function was too small");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_mul, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_mul, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_mul, buffer overflow in sprintf function");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_mul, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_mul, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       mpz_mul(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       if(strEQ(h, "Math::GMPz")) {
         mpz_mul(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_mul", "Math::GMPz::overload_mul", newSViv(0));
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
         croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_mul");

         MBI_GMP_INSERT

         if(mpz) {
           mpz_mul(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           if(strEQ("-", sign)) mpz_neg(*mpz_t_obj, *mpz_t_obj);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_mul(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         _overload_callback("Math::GMPq::overload_mul", "Math::GMPz::overload_mul", newSViv(0));
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_mul");
}

SV * overload_add(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     if(sv_isobject(b)) h = HvNAME(SvSTASH(SvRV(b)));

     if(!sv_isobject(b) || (strNE(h, "Math::MPFR") && strNE(h, "Math::GMPq"))) {
       New(1, mpz_t_obj, 1, mpz_t);
       if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_add function");
       obj_ref = newSV(0);
       obj = newSVrv(obj_ref, "Math::GMPz");
       mpz_init(*mpz_t_obj);
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
     }

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_add_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return obj_ref;
       }

       if(SvIV(b) >= 0) {
         mpz_add_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
         return obj_ref;
       }
       mpz_sub_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b) * -1);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
         croak(" Invalid string (%s) supplied to Math::GMPz::overload_add", SvPV_nolen(b));
       mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_add, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_add, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) croak("In Math::GMPz::overload_add, encoding error in quadmath_snprintf function");
       if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_add, buffer given to quadmath_snprintf function was too small");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_add, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_add, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_add, buffer overflow in sprintf function");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_add, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_add, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       if(strEQ(h, "Math::GMPz")) {
         mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_add", "Math::GMPz::overload_add", newSViv(0));
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
         croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_add");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             return obj_ref;
           }

           mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         _overload_callback("Math::GMPq::overload_add", "Math::GMPz::overload_add", newSViv(0));
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_add function");

}

SV * overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     if(sv_isobject(b)) h = HvNAME(SvSTASH(SvRV(b)));

     if(!sv_isobject(b) || (strNE(h, "Math::MPFR") && strNE(h, "Math::GMPq"))) {
       New(1, mpz_t_obj, 1, mpz_t);
       if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_sub function");
       obj_ref = newSV(0);
       obj = newSVrv(obj_ref, "Math::GMPz");
       mpz_init(*mpz_t_obj);
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
     }


#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       if(third == &PL_sv_yes) mpz_sub(*mpz_t_obj, *mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
       else mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(third == &PL_sv_yes) {
           mpz_ui_sub(*mpz_t_obj, SvUVX(b), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
           return obj_ref;
         }
         mpz_sub_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return obj_ref;
       }

       if(SvIV(b) >= 0) {
         if(third == &PL_sv_yes) {
           mpz_ui_sub(*mpz_t_obj, SvIVX(b), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
           return obj_ref;
           }
         mpz_sub_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
         return obj_ref;
       }
       mpz_add_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b) * -1);
       if(third == &PL_sv_yes) mpz_neg(*mpz_t_obj, *mpz_t_obj);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
         croak(" Invalid string (%s) supplied to Math::GMPz::overload_sub", SvPV_nolen(b));
       if(third == &PL_sv_yes) mpz_sub(*mpz_t_obj, *mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
       else mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

     ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
     if(ld != ld) croak("In Math::GMPz::overload_sub, cannot coerce a NaN to a Math::GMPz value");
     if(ld != 0 && (ld / ld != 1))
       croak("In Math::GMPz::overload_sub, cannot coerce an Inf to a Math::GMPz value");

     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, (int)buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Math::GMPz::overload_sub, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_sub, buffer given to quadmath_snprintf function was too small");
     mpz_init_set_str(*mpz_t_obj, buffer, 10);
     Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

     ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
     if(ld != ld) croak("In Math::GMPz::overload_sub, cannot coerce a NaN to a Math::GMPz value");
     if(ld != 0 && (ld / ld != 1))
       croak("In Math::GMPz::overload_sub, cannot coerce an Inf to a Math::GMPz value");

     buffer_size = ld < 0.0L ? ld * -1.0L : ld;
     buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

     Newxz(buffer, (int)buffer_size + 5, char);

     if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_sub, buffer overflow in sprintf function");
     mpz_init_set_str(*mpz_t_obj, buffer, 10);
     Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_sub, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_sub, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, SvNVX(b));
#endif
       if(third == &PL_sv_yes) mpz_sub(*mpz_t_obj, *mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
       else mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       if(strEQ(h, "Math::GMPz")) {
         mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_sub", "Math::GMPz::overload_sub", &PL_sv_yes);
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
         croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_sub");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_add(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             return obj_ref;
           }

           mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_sub(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *mpz_t_obj);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         _overload_callback("Math::GMPq::overload_sub", "Math::GMPz::overload_sub", &PL_sv_yes);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_sub function");

}

SV * overload_div(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     if(sv_isobject(b)) h = HvNAME(SvSTASH(SvRV(b)));

     if(!sv_isobject(b) || (strNE(h, "Math::MPFR") && strNE(h, "Math::GMPq"))) {
       New(1, mpz_t_obj, 1, mpz_t);
       if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_div function");
       obj_ref = newSV(0);
       obj = newSVrv(obj_ref, "Math::GMPz");
       mpz_init(*mpz_t_obj);
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
     }

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       if(third == &PL_sv_yes) Rmpz_tdiv_q(mpz_t_obj, mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))));
       else Rmpz_tdiv_q(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(third == &PL_sv_yes) {
           mpz_set_ui(*mpz_t_obj, SvUVX(b));
           Rmpz_tdiv_q(mpz_t_obj, mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))));
           return obj_ref;
         }
         Rmpz_tdiv_q_ui(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), SvUVX(b));
         return obj_ref;
       }

       if(SvIVX(b) >= 0) {
         if(third == &PL_sv_yes) {
           mpz_set_si(*mpz_t_obj, SvIVX(b));
           Rmpz_tdiv_q(mpz_t_obj, mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))));
           return obj_ref;
         }
         Rmpz_tdiv_q_ui(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), SvIVX(b));
         return obj_ref;
       }

       if(third == &PL_sv_yes) {
         mpz_set_si(*mpz_t_obj, SvIVX(b));
         Rmpz_tdiv_q(mpz_t_obj, mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))));
         return obj_ref;
       }

       Rmpz_tdiv_q_ui(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), SvIVX(b) * -1);
       mpz_neg(*mpz_t_obj, *mpz_t_obj);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
          croak(" Invalid string (%s) supplied to Math::GMPz::overload_div", SvPV_nolen(b));
       if(third == &PL_sv_yes) Rmpz_tdiv_q(mpz_t_obj, mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))));
       else Rmpz_tdiv_q(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

     ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
     if(ld != ld) croak("In Math::GMPz::overload_div, cannot coerce a NaN to a Math::GMPz value");
     if(ld != 0 && (ld / ld != 1))
       croak("In Math::GMPz::overload_div, cannot coerce an Inf to a Math::GMPz value");

     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, (int)buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Math::GMPz::overload_div, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_div, buffer given to quadmath_snprintf function was too small");
     mpz_init_set_str(*mpz_t_obj, buffer, 10);
     Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

     ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
     if(ld != ld) croak("In Math::GMPz::overload_div, cannot coerce a NaN to a Math::GMPz value");
     if(ld != 0 && (ld / ld != 1))
       croak("In Math::GMPz::overload_div, cannot coerce an Inf to a Math::GMPz value");

     buffer_size = ld < 0.0L ? ld * -1.0L : ld;
     buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

     Newxz(buffer, (int)buffer_size + 5, char);

     if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_div, buffer overflow in sprintf function");
     mpz_init_set_str(*mpz_t_obj, buffer, 10);
     Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_div, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_div, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       if(third == &PL_sv_yes) Rmpz_tdiv_q(mpz_t_obj, mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))));
       else Rmpz_tdiv_q(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       if(strEQ(h, "Math::GMPz")) {
         Rmpz_tdiv_q(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return obj_ref;
       }
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_div", "Math::GMPz::overload_div", &PL_sv_yes);
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_div");

         MBI_GMP_INSERT

         if(mpz) {
           mpz_tdiv_q(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           if(strEQ("-", sign)) mpz_neg(*mpz_t_obj, *mpz_t_obj);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         Rmpz_tdiv_q(mpz_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(a))), mpz_t_obj);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         _overload_callback("Math::GMPq::overload_div", "Math::GMPz::overload_div", &PL_sv_yes);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_div function");

}

SV * overload_mod (pTHX_ mpz_t * a, SV * b, SV * third) {
     mpz_t *mpz_t_obj;
     SV * obj_ref, * obj;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_mod function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       if(third == &PL_sv_yes) {
         mpz_mod(*mpz_t_obj, *mpz_t_obj, *a);
         return obj_ref;
       }
       mpz_mod(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(third == &PL_sv_yes) {
           mpz_set_ui(*mpz_t_obj, SvUVX(b));
           mpz_mod(*mpz_t_obj, *mpz_t_obj, *a);
           return obj_ref;
         }
         mpz_mod_ui(*mpz_t_obj, *a, SvUVX(b));
         return obj_ref;
       }

       mpz_set_si(*mpz_t_obj, SvIVX(b));
       if(third == &PL_sv_yes) {
         mpz_mod(*mpz_t_obj, *mpz_t_obj, *a);
         return obj_ref;
       }
       mpz_mod(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
          croak(" Invalid string (%s) supplied to Math::GMPz::overload_mod", SvPV_nolen(b));
       if(third == &PL_sv_yes) {
         mpz_mod(*mpz_t_obj, *mpz_t_obj, *a);
         return obj_ref;
       }
       mpz_mod(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_mod, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_mod, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) croak("In Math::GMPz::overload_mod, encoding error in quadmath_snprintf function");
       if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_mod, buffer given to quadmath_snprintf function was too small");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_mod, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_mod, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_mod, buffer overflow in sprintf function");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_mod, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_mod, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       if(third == &PL_sv_yes) {
         mpz_mod(*mpz_t_obj, *mpz_t_obj, *a);
         return obj_ref;
       }
       mpz_mod(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_mod(*mpz_t_obj, *a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
         }
       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_mod");

         MBI_GMP_INSERT

         if(mpz) {
           mpz_mod(*mpz_t_obj, *a, (mpz_srcptr)mpz);
           /* if(strEQ("-", sign)) ...... sign of divisor has no bearing on mod */
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_mod(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_mod function");
}

SV * overload_string(pTHX_ mpz_t * p, SV * second, SV * third) {
     char * out;
     SV * outsv;

     New(2, out, mpz_sizeinbase(*p, 10) + 3, char);
     if(out == NULL) croak("Failed to allocate memory in overload_string function");

     mpz_get_str(out, 10, *p);
     outsv = newSVpv(out, 0);
     Safefree(out);
     return outsv;
}

SV * overload_copy(pTHX_ mpz_t * p, SV * second, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_copy function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");

     mpz_init_set(*mpz_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_abs(pTHX_ mpz_t * p, SV * second, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_abs function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);

     mpz_abs(*mpz_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_lshift(pTHX_ mpz_t * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_lshift function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_mul_2exp(*mpz_t_obj, *a, (mp_bitcnt_t)SvUV(b));
         sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
         SvREADONLY_on(obj);
         return obj_ref;
       }

       if(SvIV(b) < 0) croak("Invalid argument supplied to Math::GMPz::overload_lshift");
       mpz_mul_2exp(*mpz_t_obj, *a, SvUV(b));
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
       return obj_ref;
     }

     croak("Invalid argument supplied to Math::GMPz::overload_lshift");
}

SV * overload_rshift(pTHX_ mpz_t * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_rshift function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_tdiv_q_2exp(*mpz_t_obj, *a, (mp_bitcnt_t)SvUVX(b));
         sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
         SvREADONLY_on(obj);
         return obj_ref;
       }

       if(SvIV(b) < 0) croak("Invalid argument supplied to Math::GMPz::overload_rshift");
       mpz_tdiv_q_2exp(*mpz_t_obj, *a, (mp_bitcnt_t)SvUVX(b));
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
       return obj_ref;
     }

     croak("Invalid argument supplied to Math::GMPz::overload_rshift");
}

SV * overload_pow(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     unsigned long int ui = 0;

     if(mpz_fits_uint_p(*(INT2PTR(mpz_t *, SvIVX(SvRV(a))))))
       ui = mpz_get_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));

     if(!sv_isobject(b)) {
       New(1, mpz_t_obj, 1, mpz_t);
       if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_pow function");
       obj_ref = newSV(0);
       obj = newSVrv(obj_ref, "Math::GMPz");
       mpz_init(*mpz_t_obj);
       sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
       SvREADONLY_on(obj);
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(third == &PL_sv_yes) {
           if(ui) {
             mpz_ui_pow_ui(*mpz_t_obj, SvUVX(b), ui);
             return obj_ref;
           }
           croak("Exponent does not fit into unsigned long int in Math::GMPz::overload_pow");
         }
         mpz_pow_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))) , SvUVX(b));
         return obj_ref;
       }

       if(SvIVX(b) < 0) croak("Negative argument supplied to Math::GMPz::overload_pow");
       if(third == &PL_sv_yes) {
         if(ui) {
           mpz_ui_pow_ui(*mpz_t_obj, SvUVX(b), ui);
           return obj_ref;
         }
         croak("Exponent does not fit into unsigned long int in Math::GMPz::overload_pow");
       }
       mpz_pow_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         if(mpz_fits_uint_p(*(INT2PTR(mpz_t *, SvIVX(SvRV(b)))))) {
           New(1, mpz_t_obj, 1, mpz_t);
           if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_pow function");
           obj_ref = newSV(0);
           obj = newSVrv(obj_ref, "Math::GMPz");
           mpz_init(*mpz_t_obj);
           sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
           SvREADONLY_on(obj);
           ui = mpz_get_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
           mpz_pow_ui(*mpz_t_obj, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), ui);
           return obj_ref;
         }
       }
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_pow", "Math::GMPz:overload_pow", &PL_sv_yes);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_pow. Exponent must fit into unsigned long (or be a Math::MPFR object)");
}

SV * overload_sqrt(pTHX_ mpz_t * p, SV * second, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_sqrt function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);

     if(mpz_cmp_ui(*p, 0) < 0) croak("Negative value supplied as argument to overload_sqrt");
     mpz_sqrt(*mpz_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_and(pTHX_ mpz_t * a, SV * b, SV * third, ...) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_and function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       mpz_and(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_set_ui(*mpz_t_obj, SvUVX(b));
         mpz_and(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }

       mpz_set_si(*mpz_t_obj, SvIVX(b));
       mpz_and(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_and", SvPV_nolen(b));
       mpz_and(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_and, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_and, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) croak("In Math::GMPz::overload_and, encoding error in quadmath_snprintf function");
       if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_and, buffer given to quadmath_snprintf function was too small");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_and, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_and, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_and, buffer overflow in sprintf function");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_and, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_and, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       mpz_and(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_and(*mpz_t_obj, *a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_and");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             mpz_and(*mpz_t_obj, *a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return obj_ref;
           }

           mpz_and(*mpz_t_obj, *a, (mpz_srcptr)mpz);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_and(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_and");
}

SV * overload_ior(pTHX_ mpz_t * a, SV * b, SV * third, ...) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_ior function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       mpz_ior(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_set_ui(*mpz_t_obj, SvUVX(b));
         mpz_ior(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }

       mpz_set_si(*mpz_t_obj, SvIVX(b));
       mpz_ior(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_ior", SvPV_nolen(b));
       mpz_ior(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_ior, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_ior, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) croak("In Math::GMPz::overload_ior, encoding error in quadmath_snprintf function");
       if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_ior, buffer given to quadmath_snprintf function was too small");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_ior, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_ior, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_ior, buffer overflow in sprintf function");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_ior, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_ior, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       mpz_ior(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_ior(*mpz_t_obj, *a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_ior");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             mpz_ior(*mpz_t_obj, *a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return obj_ref;
           }

           mpz_ior(*mpz_t_obj, *a, (mpz_srcptr)mpz);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_ior(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_ior");
}

SV * overload_xor(pTHX_ mpz_t * a, SV * b, SV * third, ...) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_xor function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       Rmpz_set_IV(aTHX_ mpz_t_obj, b);
       mpz_xor(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_set_ui(*mpz_t_obj, SvUVX(b));
         mpz_xor(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }

       mpz_set_si(*mpz_t_obj, SvIVX(b));
       mpz_xor(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_xor", SvPV_nolen(b));
       mpz_xor(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_xor, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_xor, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) croak("In Math::GMPz::overload_xor, encoding error in quadmath_snprintf function");
       if(returned >= buffer_size + 5) croak("In Math::GMPz::overload_xor, buffer given to quadmath_snprintf function was too small");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) croak("In Math::GMPz::overload_xor, cannot coerce a NaN to a Math::GMPz value");
       if(ld != 0 && (ld / ld != 1))
         croak("In Math::GMPz::overload_xor, cannot coerce an Inf to a Math::GMPz value");

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Math::GMPz::overload_xor, buffer overflow in sprintf function");
       mpz_init_set_str(*mpz_t_obj, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) croak("In Math::GMPz::overload_xor, cannot coerce a NaN to a Math::GMPz value");
       if(d != 0 && (d / d != 1))
         croak("In Math::GMPz::overload_xor, cannot coerce an Inf to a Math::GMPz value");
       mpz_set_d(*mpz_t_obj, d);
#endif
       mpz_xor(*mpz_t_obj, *a, *mpz_t_obj);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_xor(*mpz_t_obj, *a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_xor");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             mpz_xor(*mpz_t_obj, *a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return obj_ref;
           }

           mpz_xor(*mpz_t_obj, *a, (mpz_srcptr)mpz);
           return obj_ref;
         }

         mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
         mpz_xor(*mpz_t_obj, *a, *mpz_t_obj);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_xor");
}

SV * overload_com(pTHX_ mpz_t * p, SV * second, SV * third) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in overload_com function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);

     mpz_com(*mpz_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

int my_cmp_z(mpq_t * p, mpz_t *z) {
    int ret;
    mpz_t temp;

    mpz_init_set(temp, *z);
    mpz_mul(temp, temp, mpq_denref(*p));
    ret = mpz_cmp(mpq_numref(*p), temp);
    mpz_clear(temp);
    return ret;
}

SV * overload_gt(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }


     if(SV_IS_POK(b)) {
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(0);
         return newSViv(1);
       }

       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_gt", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         if(ret < 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         if(ret < 0) return newSViv(1);
         return newSViv(0);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_gt");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             if(ret > 0) return newSViv(1);
             return newSViv(0);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           if(ret > 0) return newSViv(1);
           return newSViv(0);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         /* if(third == &PL_sv_yes) ret *= -1; */
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_gt");
}

SV * overload_gte(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(0);
         return newSViv(1);
       }

       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_gte", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_gte");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             if(ret >= 0) return newSViv(1);
             return newSViv(0);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           if(ret >= 0) return newSViv(1);
           return newSViv(0);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         /* if(third == &PL_sv_yes) ret *= -1; */
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_gte");
}

SV * overload_lt(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }

       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_lt", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         if(ret > 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         if(ret > 0) return newSViv(1);
         return newSViv(0);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_lt");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             if(ret < 0) return newSViv(1);
             return newSViv(0);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           if(ret < 0) return newSViv(1);
           return newSViv(0);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         /* if(third == &PL_sv_yes) ret *= -1; */
         if(ret < 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_lt");
}

SV * overload_lte(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }

       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_lte", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_lte");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             if(ret <= 0) return newSViv(1);
             return newSViv(0);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           if(ret <= 0) return newSViv(1);
           return newSViv(0);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         /* if(third == &PL_sv_yes) ret *= -1; */
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_lte");
}

SV * overload_spaceship(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) return newSViv(ret * -1);

       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_spaceship", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(third == &PL_sv_yes) ret *= -1;
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(third == &PL_sv_yes) ret *= -1;
       return newSViv(ret);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return newSViv(ret);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         return newSViv(ret * -1);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         return newSViv(ret * -1);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_spaceship");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return newSViv(ret);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           return newSViv(ret);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         /* if(third == &PL_sv_yes) ret *= -1; */
         return newSViv(ret);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_spaceship");
}

SV * overload_equiv(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret = 0;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {
       if(_is_infstring(SvPV_nolen(b))) return newSViv(0);
       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_equiv", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) { /* do not use the NV if POK is set */
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret == 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         if(ret == 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         if(ret == 0) return newSViv(1);
         return newSViv(0);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_equiv");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             if(ret == 0) return newSViv(1);
             return newSViv(0);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           if(ret == 0) return newSViv(1);
           return newSViv(0);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         if(ret == 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_equiv");
}

SV * overload_not_equiv(pTHX_ mpz_t * a, SV * b, SV * third) {
     int ret = 0;
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     if(SV_IS_IOK(b)) {
       ret = Rmpz_cmp_IV(aTHX_ a, b);
       if(ret != 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {
       if(_is_infstring(SvPV_nolen(b))) return newSViv(1);
       if(mpz_init_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string (%s) supplied to Math::GMPz::overload_not_equiv", SvPV_nolen(b));
       ret = mpz_cmp(*a, t);
       mpz_clear(t);
       if(ret != 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) { /* do not use the NV if POK is set */
       ret = Rmpz_cmp_NV(aTHX_ a, b);
       if(ret != 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         ret = mpz_cmp(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret != 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPq")) {
#if __GNU_MP_RELEASE < 60099
         ret = my_cmp_z(INT2PTR(mpq_t *, SvIVX(SvRV(b))), a);
         if(ret != 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), *a);
         if(ret != 0) return newSViv(1);
         return newSViv(0);
#endif
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_not_equiv");

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             ret = mpz_cmp(*a, (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             if(ret != 0) return newSViv(1);
             return newSViv(0);
           }

           ret = mpz_cmp(*a, (mpz_srcptr)mpz);
           if(ret != 0) return newSViv(1);
           return newSViv(0);
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         ret = mpz_cmp(*a, t);
         mpz_clear(t);
         if(ret != 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::GMPz::overload_not_equiv");
}

SV * overload_not(pTHX_ mpz_t * a, SV * second, SV * third) {
     if(mpz_cmp_ui(*a, 0)) return newSViv(0);
     return newSViv(1);
}

/* Finish typemapping */

SV * overload_xor_eq(pTHX_ SV * a, SV * b, SV * third, ...) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s)supplied to Math::GMPz::overload_xor_eq", SvPV_nolen(b));
         }
       mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_init_set_ui(t, SvUVX(b));
         mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }

       mpz_init_set_si(t, SvIVX(b));
       mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_xor_eq", SvPV_nolen(b));
         }
       mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_xor_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }


     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_xor_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return a;
           }

           mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_xor(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_xor_eq");
}

SV * overload_ior_eq(pTHX_ SV * a, SV * b, SV * third, ...) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_ior_eq", SvPV_nolen(b));
       }
       mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_init_set_ui(t, SvUVX(b));
         mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }

       mpz_init_set_si(t, SvIVX(b));
       mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_ior_eq", SvPV_nolen(b));
       }
       mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_ior_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_ior_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return a;
           }

           mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_ior(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_ior_eq");
}

SV * overload_and_eq(pTHX_ SV * a, SV * b, SV * third, ...) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_and_eq", SvPV_nolen(b));
         }
       mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_init_set_ui(t, SvUVX(b));
         mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }

       mpz_init_set_si(t, SvIVX(b));
       mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_and_eq", SvPV_nolen(b));
       }
       mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_and_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_and_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz);
             mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             mpz_neg((mpz_ptr)mpz, (mpz_srcptr)mpz); /* restore to original */
             return a;
           }

           mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_and(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_and_eq");
}

SV * overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {
     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_pow_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }

       if(SvIVX(b) < 0) {
         SvREFCNT_dec(a);
         croak("Negative argument supplied to Math::GMPz::overload_pow_eq");
       }
       mpz_pow_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         if(mpz_fits_uint_p(*(INT2PTR(mpz_t *, SvIVX(SvRV(b)))))) {
           mpz_pow_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))),
                      *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))),
                      mpz_get_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(b))))));
           return a;
         }
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_pow_eq. Exponent must fit into an unsigned long");
}

SV * overload_rshift_eq(pTHX_ SV * a, SV * b, SV * third) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_tdiv_q_2exp(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mp_bitcnt_t)SvUVX(b));
         return a;
       }

       if(SvIV(b) < 0) {
         SvREFCNT_dec(a);
         croak("Invalid argument supplied to Math::GMPz::overload_rshift_eq");
       }
       mpz_tdiv_q_2exp(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mp_bitcnt_t)SvUVX(b));
       return a;
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_rshift_eq");
}

SV * overload_lshift_eq(pTHX_ SV * a, SV * b, SV * third) {

     CHECK_MP_BITCNT_T_OVERFLOW(b)

     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_mul_2exp(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mp_bitcnt_t)SvUV(b));
         return a;
       }

       if(SvIV(b) < 0) {
         SvREFCNT_dec(a);
         croak("Invalid argument supplied to Math::GMPz::overload_lshift_eq");
       }
       mpz_mul_2exp(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mp_bitcnt_t)SvUV(b));
       return a;
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_lshift_eq");
}

SV * overload_inc(pTHX_ SV * p, SV * second, SV * third) {
     SvREFCNT_inc(p);
     mpz_add_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(p)))), 1);
     return p;
}

SV * overload_dec(pTHX_ SV * p, SV * second, SV * third) {
     SvREFCNT_inc(p);
     mpz_sub_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(p)))), 1);
     return p;
}

SV * overload_mod_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_mod_eq", SvPV_nolen(b));
         }
       mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_mod_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }

       if(SvIV(b) > 0) {
         mpz_mod_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }
       mpz_init_set_si(t, SvIVX(b)); /* was SvNV(b) ?? */
       mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_mod_eq", SvPV_nolen(b));
       }
       mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mod_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_mod_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           /* if(strEQ("-", sign)) ...... not an issue for the divisor in a mod operation */
           mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_mod(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_mod_eq");
}

SV * get_refcnt(pTHX_ SV * s) {
     return newSVuv(SvREFCNT(s));
}

SV * overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_div_eq", SvPV_nolen(b));
       }
       mpz_tdiv_q(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_tdiv_q_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }

       if(SvIV(b) >= 0) {
         mpz_tdiv_q_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
         return a;
       }
       mpz_tdiv_q_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b) * -1);
       mpz_neg(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_div_eq", SvPV_nolen(b));
       }
       mpz_tdiv_q(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_div_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_tdiv_q(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_tdiv_q(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
         SvREFCNT_dec(a);
         croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_div_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           mpz_tdiv_q(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           if(strEQ("-", sign)) mpz_neg(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_tdiv_q(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_div_eq function");

}

SV * overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_sub_eq", SvPV_nolen(b));
         }
       mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_sub_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }

       if(SvIV(b) >= 0) {
         mpz_sub_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
         return a;
       }
       mpz_add_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b) * -1);
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_sub_eq", SvPV_nolen(b));
       }
       mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_sub_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_sub_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             return a;
           }

           mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_sub_eq function");

}

SV * overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_add_eq", SvPV_nolen(b));
       }
       mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_add_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }


       if(SvIV(b) >= 0) {
         mpz_add_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
         return a;
       }
       mpz_sub_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b) * -1);
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string (%s) supplied to Math::GMPz::overload_add_eq", SvPV_nolen(b));
       }
       mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_add_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_add_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           if(strEQ("-", sign)) {
             mpz_sub(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
             return a;
           }

           mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_add(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_add_eq function");

}

SV * overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpz_t t;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

#if defined(USE_QUADMATH)

     char * buffer;
     int returned;
     __float128 buffer_size;
     __float128 ld;

#elif defined(USE_LONG_DOUBLE)

     char * buffer;
     long double buffer_size;
     long double ld;

#endif

     SvREFCNT_inc(a);

#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak(" Invalid string (%s) supplied to Math::GMPz::overload_mul_eq", SvPV_nolen(b));
       }
       mpz_mul(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpz_mul_ui(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvUVX(b));
         return a;
       }

       mpz_mul_si(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), SvIVX(b));
       return a;
     }
#endif

     if(SV_IS_POK(b)) {
       if(mpz_init_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak(" Invalid string (%s) supplied to Math::GMPz::overload_mul_eq", SvPV_nolen(b));
       }
       mpz_mul(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       ld = (__float128)SvNVX(b) >= 0 ? floorq((__float128)SvNVX(b)) : ceilq((__float128)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
       buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

       Newxz(buffer, (int)buffer_size + 5, char);

       returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
       if(returned < 0) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, encoding error in quadmath_snprintf function");
       }
       if(returned >= buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, buffer given to quadmath_snprintf function was too small");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);

#elif defined(USE_LONG_DOUBLE)

       ld = (long double)SvNVX(b) >= 0 ? floorl((long double)SvNVX(b)) : ceill((long double)SvNVX(b));
       if(ld != ld) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(ld != 0 && (ld / ld != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, cannot coerce an Inf to a Math::GMPz value");
       }

       buffer_size = ld < 0.0L ? ld * -1.0L : ld;
       buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

       Newxz(buffer, (int)buffer_size + 5, char);

       if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, buffer overflow in sprintf function");
       }
       mpz_init_set_str(t, buffer, 10);
       Safefree(buffer);
#else
       double d = SvNVX(b);
       if(d != d) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, cannot coerce a NaN to a Math::GMPz value");
       }
       if(d != 0 && (d / d != 1)) {
         SvREFCNT_dec(a);
         croak("In Math::GMPz::overload_mul_eq, cannot coerce an Inf to a Math::GMPz value");
       }
       mpz_init_set_d(t, d);
#endif
       mpz_mul(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
       mpz_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz")) {
         mpz_mul(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::BigInt")) {
         VALIDATE_MBI_OBJECT {
           SvREFCNT_dec(a);
           croak("Invalid Math::BigInt object supplied to Math::GMPz::overload_mul_eq");
         }

         MBI_GMP_INSERT

         if(mpz) {
           mpz_mul(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (mpz_srcptr)mpz);
           if(strEQ("-", sign)) mpz_neg(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))));
           return a;
         }

         mpz_init_set_str(t, SvPV_nolen(b), 0);
         mpz_mul(*(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), t);
         mpz_clear(t);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPz::overload_mul_eq");
}



SV * eratosthenes_string(pTHX_ SV * x_arg) {

unsigned char *v, set[8] = {254,253,251,247,239,223,191,127};
unsigned long leap, i, size, b, imax, k, x = (unsigned long)SvUV(x_arg);
SV * ret;

if(x & 1) croak("max_num argument must be even in eratosthenes_string");

imax = sqrt(x - 1) / 2;

b = (x + 1) / 2;

if(!(b % 8)) size = b / 8;
else size = (b / 8) + 1;

ret = NEWSV(0, size);

for(i = 1; i < size; ++i) SvPVX(ret)[i] = 255;
SvPVX(ret)[0] = 254;

for(i = 0; i <= imax; ++i) {

    if(SvPVX(ret)[i / 8] & (1 << (i % 8))) {
       leap = (2 * i) + 1;
       k = 2 * i * (i + 1);
       while(k < b) {
             SvPVX(ret)[k / 8] &= set[k % 8];
             k += leap;
             }
       }
}

SvPOK_on(ret);
SvCUR_set(ret, size);
*SvEND(ret) = 0;

return ret;

}

SV * gmp_v(pTHX) {
#if __GNU_MP_VERSION >= 4
     return newSVpv(gmp_version, 0);
#else
     warn("From Math::GMPz::gmp_v function: 'gmp_version' is not implemented - returning '0'");
     return newSVpv("0", 0);
#endif
}

SV * wrap_gmp_printf(pTHX_ SV * a, SV * b) {
     int ret;
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz") ||
         strEQ(h, "Math::GMP") ||
         strEQ(h, "GMP::Mpz")) {
         ret = gmp_printf(SvPV_nolen(a), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         fflush(stdout);
         return newSViv(ret);
       }
       if(strEQ(h, "Math::GMPq") ||
         strEQ(h, "GMP::Mpq")) {
         ret = gmp_printf(SvPV_nolen(a), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         fflush(stdout);
         return newSViv(ret);
       }
       if(strEQ(h, "Math::GMPf") ||
         strEQ(h, "GMP::Mpf")) {
         ret = gmp_printf(SvPV_nolen(a), *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))));
         fflush(stdout);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpz_printf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         ret = gmp_printf(SvPV_nolen(a), SvUVX(b));
         fflush(stdout);
         return newSViv(ret);
       }

       ret = gmp_printf(SvPV_nolen(a), SvIVX(b));
       fflush(stdout);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {
       ret = gmp_printf(SvPV_nolen(a), SvPV_nolen(b));
       fflush(stdout);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = gmp_printf(SvPV_nolen(a), SvNVX(b));
       fflush(stdout);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpz_printf");
}

SV * wrap_gmp_fprintf(pTHX_ FILE * stream, SV * a, SV * b) {
     int ret;
     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz") ||
         strEQ(h, "Math::GMP") ||
         strEQ(h, "GMP::Mpz")) {
         ret = gmp_fprintf(stream, SvPV_nolen(a), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         fflush(stream);
         return newSViv(ret);
       }
       if(strEQ(h, "Math::GMPq") ||
         strEQ(h, "GMP::Mpq")) {
         ret = gmp_fprintf(stream, SvPV_nolen(a), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         fflush(stream);
         return newSViv(ret);
       }
       if(strEQ(h, "Math::GMPf") ||
         strEQ(h, "GMP::Mpf")) {
         ret = gmp_fprintf(stream, SvPV_nolen(a), *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))));
         fflush(stream);
         return newSViv(ret);
       }

       else croak("Unrecognised object supplied as argument to Rmpz_fprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         ret = gmp_fprintf(stream, SvPV_nolen(a), SvUVX(b));
         fflush(stream);
         return newSViv(ret);
       }

       ret = gmp_fprintf(stream, SvPV_nolen(a), SvIVX(b));
       fflush(stream);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {
       ret = gmp_fprintf(stream, SvPV_nolen(a), SvPV_nolen(b));
       fflush(stream);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = gmp_fprintf(stream, SvPV_nolen(a), SvNVX(b));
       fflush(stream);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpz_fprintf");
}

SV * wrap_gmp_sprintf(pTHX_ SV * s, SV * a, SV * b, int buflen) {
     int ret;
     char *stream;

     Newx(stream, buflen, char);

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz") ||
         strEQ(h, "Math::GMP") ||
         strEQ(h, "GMP::Mpz")) {
         ret = gmp_sprintf(stream, SvPV_nolen(a), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::GMPq") ||
         strEQ(h, "GMP::Mpq")) {
         ret = gmp_sprintf(stream, SvPV_nolen(a), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::GMPf") ||
         strEQ(h, "GMP::Mpf")) {
         ret = gmp_sprintf(stream, SvPV_nolen(a), *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpz_sprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         ret = gmp_sprintf(stream, SvPV_nolen(a), SvUVX(b));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       ret = gmp_sprintf(stream, SvPV_nolen(a), SvIVX(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {
       ret = gmp_sprintf(stream, SvPV_nolen(a), SvPV_nolen(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = gmp_sprintf(stream, SvPV_nolen(a), SvNVX(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpz_sprintf");
}

SV * wrap_gmp_snprintf(pTHX_ SV * s, SV * bytes, SV * a, SV * b, int buflen) {
     int ret;
     char * stream;

     Newx(stream, buflen, char);

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPz") ||
         strEQ(h, "Math::GMP") ||
         strEQ(h, "GMP::Mpz")) {
         ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::GMPq") ||
         strEQ(h, "GMP::Mpq")) {
         ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::GMPf") ||
         strEQ(h, "GMP::Mpf")) {
         ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpz_snprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvUVX(b));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvIVX(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {
       ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvPV_nolen(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvNVX(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpz_snprintf");
}

SV * _itsa(pTHX_ SV * a) {
     if(SV_IS_IOK(a)) {
       if(SvUOK(a)) return newSViv(1);
       return newSViv(2);
     }
     if(SV_IS_POK(a)) return newSViv(4);
     if(SV_IS_NOK(a)) return newSViv(3);
     if(sv_isobject(a)) {
       const char *h = HvNAME(SvSTASH(SvRV(a)));
       if(strEQ(h, "Math::GMPz"))        return newSViv(8);
       if(strEQ(h, "Math::GMP"))         return newSViv(9);
       if(strEQ(h, "Math::BigInt"))      return newSViv(-1);
     }
     return newSVuv(0);
}

void Rmpz_urandomb(pTHX_ SV * p, ...) {
     dXSARGS;
     unsigned long q, i, thingies;

     thingies = items;
     q = SvUV(ST(thingies - 1));

     if((q + 3) != thingies) croak ("Wrong args supplied to mpz_urandomb function");

     for(i = 0; i < q; ++i) {
        mpz_urandomb(*(INT2PTR(mpz_t *, SvIVX(SvRV(ST(i))))), *(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(ST(thingies - 3))))), SvUV(ST(thingies - 2)));
        }

     XSRETURN(0);
}

void Rmpz_urandomm(pTHX_ SV * x, ...){
     dXSARGS;
     unsigned long q, i, thingies;

     thingies = items;
     q = SvUV(ST(thingies - 1));

     if((q + 3) != thingies) croak ("Wrong args supplied to mpz_urandomm function");

     for(i = 0; i < q; ++i) {
        mpz_urandomm(*(INT2PTR(mpz_t *, SvIVX(SvRV(ST(i))))), *(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(ST(thingies - 3))))), *(INT2PTR(mpz_t *, SvIVX(SvRV(ST(thingies - 2))))));
        }

     XSRETURN(0);
}

void Rmpz_rrandomb(pTHX_ SV * x, ...) {
     dXSARGS;
     unsigned long q, i, thingies;

     thingies = items;
     q = SvUV(ST(thingies - 1));

     if((q + 3) != thingies) croak ("Wrong args supplied to mpz_rrandomb function");

     for(i = 0; i < q; ++i) {
        mpz_rrandomb(*(INT2PTR(mpz_t *, SvIVX(SvRV(ST(i))))), *(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(ST(thingies - 3))))), SvUV(ST(thingies - 2)));
        }

     XSRETURN(0);
}

SV * rand_init(pTHX_ SV * seed) {
     gmp_randstate_t * state;
     SV * obj_ref, * obj;

     New(1, state, 1, gmp_randstate_t);
     if(state == NULL) croak("Failed to allocate memory in rand_init function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_default(*state);
     gmp_randseed(*state, *(INT2PTR(mpz_t *, SvIVX(SvRV(seed)))));
     sv_setiv(obj, INT2PTR(IV, state));
     SvREADONLY_on(obj);
     return obj_ref;
     }

void rand_clear(pTHX_ SV * p) {
     gmp_randclear(*(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(p)))));
     Safefree(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(p))));
     }

int _has_longlong(void) {
#ifdef MATH_GMPZ_NEED_LONG_LONG_INT
    return 1;
#else
    return 0;
#endif
}

int _has_longdouble(void) {
#if defined(USE_LONG_DOUBLE)
    return 1;
#else
    return 0;
#endif
}

int _has_float128(void) {
#if defined(USE_QUADMATH)
    return 1;
#else
    return 0;
#endif
}

/* Has inttypes.h been included ? */
int _has_inttypes(void) {
#ifdef _MSC_VER
return 0;
#else
#if defined MATH_GMPZ_NEED_LONG_LONG_INT
return 1;
#else
return 0;
#endif
#endif
}

SV * Rmpz_inp_raw(pTHX_ mpz_t * a, FILE * stream) {
     size_t ret = mpz_inp_raw(*a, stream);
     fflush(stream);
     return newSVuv(ret);
}

SV * Rmpz_out_raw(pTHX_ FILE * stream, mpz_t * a) {
     size_t ret = mpz_out_raw(stream, *a);
     fflush(stream);
     return newSVuv(ret);
}

SV * ___GNU_MP_VERSION(pTHX) {
     return newSVuv(__GNU_MP_VERSION);
}

SV * ___GNU_MP_VERSION_MINOR(pTHX) {
     return newSVuv(__GNU_MP_VERSION_MINOR);
}

SV * ___GNU_MP_VERSION_PATCHLEVEL(pTHX) {
     return newSVuv(__GNU_MP_VERSION_PATCHLEVEL);
}

SV * ___GNU_MP_RELEASE(pTHX) {
#if defined(__GNU_MP_RELEASE)
     return newSVuv(__GNU_MP_RELEASE);
#else
     return &PL_sv_undef;
#endif
}

SV * ___GMP_CC(pTHX) {
#ifdef __GMP_CC
     char * ret = __GMP_CC;
     return newSVpv(ret, 0);
#else
     return &PL_sv_undef;
#endif
}

SV * ___GMP_CFLAGS(pTHX) {
#ifdef __GMP_CFLAGS
     char * ret = __GMP_CFLAGS;
     return newSVpv(ret, 0);
#else
     return &PL_sv_undef;
#endif
}

#if __GNU_MP_VERSION >= 5
#ifndef __MPIR_VERSION
void Rmpz_powm_sec(mpz_t * dest, mpz_t * base, mpz_t * exp, mpz_t * mod) {
     mpz_powm_sec(*dest, *base, *exp, *mod);
}
#else
void Rmpz_powm_sec(mpz_t * dest, mpz_t * base, mpz_t * exp, mpz_t * mod) {
     croak("Rmpz_powm_sec not implemented by the mpir library");
}
#endif
#else
void Rmpz_powm_sec(mpz_t * dest, mpz_t * base, mpz_t * exp, mpz_t * mod) {
     croak("Rmpz_powm_sec not implemented - gmp-5 or later needed, this is gmp-%d", __GNU_MP_VERSION);
}
#endif

int _using_mpir(void) {
#ifdef __MPIR_VERSION
return 1;
#else
return 0;
#endif
}

SV * _Rmpz_NULL(pTHX) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;

     mpz_t_obj = NULL;
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);

     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

void Rprbg_ms(pTHX_ mpz_t * outref, mpz_t * p, mpz_t * q, mpz_t * seed, int bits_required) {
     mpz_t n, phi, pless1, qless1, mod, keep;
     unsigned long e, k, bign, r, its, i, r_shift, check;
     double kdoub;
     gmp_randstate_t state;

     mpz_init(n);
     mpz_init(phi);
     mpz_init(pless1);
     mpz_init(qless1);

     mpz_sub_ui(qless1, *q, 1);
     mpz_sub_ui(pless1, *p, 1);

     mpz_mul(n, *p, *q);

     mpz_mul(phi, pless1, qless1);
     mpz_clear(pless1);
     mpz_clear(qless1);

     bign = mpz_sizeinbase(n, 2);
     e = bign / 80;

     while(1) {
        if(e < 1) croak("You need to choose larger primes P and Q. The product of P-1 and Q-1 needs to be at least an 80-bit number");
        if(mpz_gcd_ui(NULL, phi, e) == 1) break;
        --e;
        if(e < 3) croak("The chosen primes are unsuitable in prbg_ms() function");
        }

     mpz_clear(phi);

     kdoub = (double) 2 / (double) e;
     kdoub = (double) 1 - kdoub;
     kdoub *= (double) bign;
     k = kdoub;
     r = bign - k;

     gmp_randinit_default(state);
     gmp_randseed(state, *seed);
     mpz_urandomb(*seed, state, r);
     gmp_randclear(state);

     r_shift = bits_required % k;

     if(r_shift) its = (bits_required / k) + 1;
     else its = bits_required / k;

     mpz_init(mod);
     mpz_init(keep);
     mpz_set_ui(*outref, 0);
     mpz_ui_pow_ui(mod, 2, k);

     for(i = 0; i < its; ++i) {
         mpz_powm_ui(*seed, *seed, e, n);
         mpz_mod(keep, *seed, mod);
         mpz_mul_2exp(*outref, *outref, k);
         mpz_add(*outref, *outref, keep);
         mpz_fdiv_q_2exp(*seed, *seed, k);
         if(!i) check = k - mpz_sizeinbase(keep, 2);
         }
     mpz_clear(n);
     mpz_clear(keep);
     mpz_clear(mod);

     if(r_shift) mpz_fdiv_q_2exp(*outref, *outref, k - r_shift);

     if(check + mpz_sizeinbase(*outref, 2) != bits_required)
        croak("Bug in csprng() function");

}

void Rprbg_bbs(pTHX_ mpz_t * outref, mpz_t * p, mpz_t * q, mpz_t * seed, int bits_required) {
     mpz_t n, gcd, one;
     unsigned long i, k;
     gmp_randstate_t state;

     if(mpz_fdiv_ui(*p, 4) != 3) croak ("First prime is unsuitable for Blum-Blum-Shub prbg (must be congruent to 3, mod 4)");
     if(mpz_fdiv_ui(*q, 4) != 3) croak ("Second prime is unsuitable for Blum-Blum-Shub prbg (must be congruent to 3, mod 4)");
     mpz_init(n);

     mpz_mul(n, *p, *q);

     mpz_init(gcd);
     gmp_randinit_default(state);
     gmp_randseed(state, *seed);
     mpz_urandomm(*seed, state, n);
     gmp_randclear(state);

     while(1) {
           if(mpz_cmp_ui(*seed, 100) < 0)croak("Blum-Blum-Shub seed is ridiculously small. How did this happen ?");
           mpz_gcd(gcd, *seed, n);
           if(!mpz_cmp_ui(gcd, 1)) break;
           mpz_sub_ui(*seed, *seed, 1);
           }

     mpz_powm_ui(*seed, *seed, 2, n);

     mpz_init_set_ui(*outref, 0);
     mpz_init_set_ui(one, 1);

     for(i = 0; i < bits_required; ++i) {
         mpz_powm_ui(*seed, *seed, 2, n);
         k = mpz_tstbit(*seed, 0);
         if(k) {
            mpz_mul_2exp(gcd, one, i);
            mpz_add(*outref, gcd, *outref);
            }
         }

     mpz_clear(n);
     mpz_clear(gcd);
     mpz_clear(one);

}

int Rmonobit(mpz_t * bitstream) {
    unsigned long len, i, count = 0;

    len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000) croak("Wrong size random sequence for monobit test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in Rmonobit test\n");
       return 0;
       }

    count = mpz_popcount(*bitstream);

    if(count > 9654 && count < 10346) return 1;
    return 0;

}

int Rlong_run(mpz_t * bitstream) {
    unsigned int i, el, init = 0, count = 0, len, t;

    len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000) croak("Wrong size random sequence for Rlong_run test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in long_run test\n");
       return 0;
       }

    el = mpz_tstbit(*bitstream, 0);

    for(i = 0; i < len; ++i) {
        t = mpz_tstbit(*bitstream, i);
        if(t == el) ++count;
        else {
           el = t;
           if(count > init) init = count;
           count = 1;
           }
        }

    if(init < 34 && count < 34) return 1;
    else warn("init: %u count: %u", init, count);
    return 0;

}

int Rruns(mpz_t * bitstream) {
    int b[6] = {0,0,0,0,0,0}, g[6] = {0,0,0,0,0,0},
    len, count = 1, i, t, diff;

    len = mpz_sizeinbase(*bitstream, 2);
    diff = 20000 - len;

    if(len > 20000) croak("Wrong size random sequence for monobit test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in runs test\n");
       return 0;
       }

    --len;

    for(i = 0; i < len; ++i) {
      t = mpz_tstbit(*bitstream, i);
      if(t == mpz_tstbit(*bitstream, i + 1)) ++ count;
      else {
        if(t) {
          if(count >= 6) ++b[5];
          else ++b[count - 1];
        }
        else {
          if(count >= 6) ++g[5];
          else ++g[count - 1];
        }
        count = 1;
      }
    }

    if(count >= 6) {
      if(mpz_tstbit(*bitstream, len)) {
        ++b[5];
        if(diff >= 6) {
          ++g[5];
        }
        else {
          if(diff) ++g[diff - 1];
        }
      }
      else ++g[5];
      }
    else {
      if(mpz_tstbit(*bitstream, len)) {
        ++b[count - 1];
        if(diff >= 6) {
          ++g[5];
        }
        else {
          if(diff) ++ g[diff - 1];
        }
      }
      else {
        count += diff;
        count >= 6 ? ++g[5] : ++g[count - 1];
      }
    }


    if (
            b[0] <= 2267 || g[0] <= 2267 ||
            b[0] >= 2733 || g[0] >= 2733 ||
            b[1] <= 1079 || g[1] <= 1079 ||
            b[1] >= 1421 || g[1] >= 1421 ||
            b[2] <= 502  || g[2] <= 502  ||
            b[2] >= 748  || g[2] >= 748  ||
            b[3] <= 223  || g[3] <= 223  ||
            b[3] >= 402  || g[3] >= 402  ||
            b[4] <= 90   || g[4] <= 90   ||
            b[4] >= 223  || g[4] >= 223  ||
            b[5] <= 90   || g[5] <= 90   ||
            b[5] >= 223  || g[5] >= 223
           ) return 0;

    return 1;

}

int Rpoker (mpz_t * bitstream) {
    int counts[16] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
       len, i, st, diff;
    double n = 0;

    len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000) croak("Wrong size random sequence for poker test");
    if(len < 19967) {
       warn("More than 33 leading zeroes in poker test\n");
       return 0;
       }

/* pad with trailing zeroes (if necessary) to achieve length of 20000 bits. */
    diff = 20000 - len;
    if(diff) mpz_mul_2exp(*bitstream, *bitstream, diff);
    if(mpz_sizeinbase(*bitstream, 2) != 20000) croak("Bug in bit sequence manipulation in poker() function");

    for(i = 0; i < 20000; i += 4) {
        st = mpz_tstbit(*bitstream, i) +
             (mpz_tstbit(*bitstream, i + 1) * 2) +
             (mpz_tstbit(*bitstream, i + 2) * 4) +
             (mpz_tstbit(*bitstream, i + 3) * 8);
        ++counts[st];
        }


    for(i = 0; i < 16; ++i) n += counts[i] * counts[i];

    n /= 5000;
    n *= 16;
    n -= 5000;

    if(n > 1.03 && n < 57.4) return 1;

    return 0;
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

SV * query_eratosthenes_string(pTHX_ int candidate, char * str) {
     int cand = candidate - 1;
     if(cand == 1) return newSVuv(1);
     if(cand & 1 || cand <= 0) return newSVuv(0);
     if(str[cand / 16] & 1 << (cand / 2) % 8)
       return newSVuv(1);
     return newSVuv(0);
}

void autocorrelation(pTHX_ mpz_t * bitstream, int offset) {
     dXSARGS;
     int i, index, last, count = 0, short_ = 0;
     mpz_t temp;
     double x, diff;
     int len = mpz_sizeinbase(*bitstream, 2);

     if(len > 20000) croak("Wrong size random sequence for autocorrelation test");
     if(len < 19967) {
        warn("More than 33 leading zeroes in autocorrelation test\n");
        ST(0) = sv_2mortal(newSViv(0));
        ST(1) = sv_2mortal(newSVnv(0.0));
        XSRETURN(2);
        }

/* make sure *bitstream has a length of 20000 bits. */
     if(20000 - len) {
       short_ = 1;
       mpz_init_set_ui(temp, 1);
       mpz_mul_2exp(temp, temp, 19999);
       mpz_add(*bitstream, *bitstream, temp);
     }
     if(mpz_sizeinbase(*bitstream, 2) != 20000) croak("Bit sequence has length of %d bits in autocorrelation function", (int)mpz_sizeinbase(*bitstream, 2));

     index = 19999 - offset;
     for(i = 0; i < index - 1; ++i) {
       if(mpz_tstbit(*bitstream, i) ^ mpz_tstbit(*bitstream, i + offset)) count += 1;
     }

     last = short_ ? 0 : 1;

     if(mpz_tstbit(*bitstream, index - 1) ^ last) count += 1;

/* restore *bitstream to its original value && free temp (iff necessary) */
     if(short_) {
       mpz_sub(*bitstream, *bitstream, temp);
       mpz_clear(temp);
     }

   ST(0) = sv_2mortal(newSViv(count));

   diff = 20000.0 - (double)offset;
   x = (2 * ((double)count - (diff / 2))) / (sqrt(diff));

   ST(1) = sv_2mortal(newSVnv(x));
   XSRETURN(2);
}

int autocorrelation_20000(pTHX_ mpz_t * bitstream, int offset) {
    dXSARGS;
    int i, last, count = 0, short_ = 0;
    mpz_t temp;
    double x, diff;
    int len = mpz_sizeinbase(*bitstream, 2);

    if(len > 20000 + offset) croak("Wrong size random sequence for autocorrelation_20000 test");
    if(len < 19967 + offset) {
      warn("More than 33 leading zeroes in autocorrelation_20000 test\n");
      return 0;
    }

/* make sure *bitstream has a length of 20000 + offset bits. */
    if(20000 + offset - len) {
      short_ = 1;
      mpz_init_set_ui(temp, 1);
      mpz_mul_2exp(temp, temp, 19999 + offset);
      mpz_add(*bitstream, *bitstream, temp);
    }
   if(mpz_sizeinbase(*bitstream, 2) != 20000 + offset) croak("Bit sequence has length of %d bits in autocorrelation_20000 function; should have size of %d bits", (int)mpz_sizeinbase(*bitstream, 2), 20000 + offset);

    for(i = 0; i < 19999; ++i) {
      if(mpz_tstbit(*bitstream, i) ^ mpz_tstbit(*bitstream, i + offset)) count += 1;
    }

    last = short_ ? 0 : 1;

    if(mpz_tstbit(*bitstream, 19999) ^ last) count += 1;

/* restore *bitstream to its original value && free temp (iff necessary) */
    if(short_) {
      mpz_sub(*bitstream, *bitstream, temp);
      mpz_clear(temp);
    }
    if(count > 9654 && count < 10346) return 1;
    return 0;
}

SV * _GMP_LIMB_BITS(pTHX) {
#ifdef GMP_LIMB_BITS
     return newSVuv(GMP_LIMB_BITS);
#else
     return &PL_sv_undef;
#endif
}

SV * _GMP_NAIL_BITS(pTHX) {
#ifdef GMP_NAIL_BITS
     return newSVuv(GMP_NAIL_BITS);
#else
     return &PL_sv_undef;
#endif
}

SV * _new_from_MBI(pTHX_ SV * b) {
     mpz_t * mpz_t_obj;
     SV * obj_ref, * obj;
     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

/*
     This function gets called only if it has already been ascertained that b is
     an object && HvNAME(SvSTASH(SvRV(b))) is "Math::BigInt", but we still need to
     check that the object is not NaN or Inf.
*/
     VALIDATE_MBI_OBJECT
       croak("Invalid Math::BigInt object supplied to Math::GMPz::_new_from_MBI");

     New(1, mpz_t_obj, 1, mpz_t);
     if(mpz_t_obj == NULL) croak("Failed to allocate memory in Math::GMPz::_new_from_MBI function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPz");
     mpz_init(*mpz_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpz_t_obj));
     SvREADONLY_on(obj);

     MBI_GMP_INSERT

     if(mpz) {
       mpz_set(*mpz_t_obj, (mpz_srcptr)mpz);
       if(strEQ("-", sign)) mpz_neg(*mpz_t_obj, *mpz_t_obj);
       return obj_ref;
     }

     mpz_set_str(*mpz_t_obj, SvPV_nolen(b), 0);
     return obj_ref;
}


SV * _magic_status(pTHX) {
#ifdef MATH_GMPz_HAS_MAGICEXT
    return newSVuv(MATH_GMPz_HAS_MAGICEXT);
#endif
    return &PL_sv_undef;
}

void _dump_mbi_gmp(pTHX_ SV * b) {

     MBI_DECLARATIONS
     MBI_GMP_DECLARATIONS

     VALIDATE_MBI_OBJECT
       croak("Invalid Math::BigInt object supplied to Math::GMPz::_new_from_MBI");

     MBI_GMP_INSERT

     if(mpz) {
       mpz_out_str(NULL, 10, (mpz_srcptr)mpz);
       printf(" %s\n", sign);
     }

     else printf("Unable to obtain information. (Perhaps NA ?)\n");
}

int _SvIOK(pTHX_ SV * sv) {
  if(SV_IS_IOK(sv)) return 1;
  return 0;
}

int _SvPOK(SV * sv) {
  if(SV_IS_POK(sv)) return 1;
  return 0;
}

int _SvNOK(SV * sv) {
  if(SV_IS_NOK(sv)) return 1;
  return 0;
}

int IOK_flag(SV * sv) {
  if(SvUOK(sv)) return 2;
  if(SvIOK(sv)) return 1;
  return 0;
}

int POK_flag(SV * sv) {
  if(SvPOK(sv)) return 1;
  return 0;
}

int NOK_flag(SV * sv) {
  if(SvNOK(sv)) return 1;
  return 0;
}

SV * _sizeof_mp_bitcnt_t(pTHX) {
  return newSVuv(sizeof(mp_bitcnt_t));
}

int _gmp_index_overflow(void) {
#if defined(_GMP_INDEX_OVERFLOW)
  return 1;
#else
  return 0;
#endif
}


MODULE = Math::GMPz  PACKAGE = Math::GMPz

PROTOTYPES: ENABLE


SV *
MATH_GMPz_IV_MAX ()
CODE:
  RETVAL = MATH_GMPz_IV_MAX (aTHX);
OUTPUT:  RETVAL


SV *
MATH_GMPz_IV_MIN ()
CODE:
  RETVAL = MATH_GMPz_IV_MIN (aTHX);
OUTPUT:  RETVAL


SV *
MATH_GMPz_UV_MAX ()
CODE:
  RETVAL = MATH_GMPz_UV_MAX (aTHX);
OUTPUT:  RETVAL

PROTOTYPES: DISABLE

int
_is_infstring (s)
	char *	s

SV *
Rmpz_init_set_str_nobless (num, base)
	SV *	num
	SV *	base
CODE:
  RETVAL = Rmpz_init_set_str_nobless (aTHX_ num, base);
OUTPUT:  RETVAL

SV *
Rmpz_init2_nobless (bits)
	SV *	bits
CODE:
  RETVAL = Rmpz_init2_nobless (aTHX_ bits);
OUTPUT:  RETVAL

SV *
Rmpz_init_nobless ()
CODE:
  RETVAL = Rmpz_init_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rmpz_init_set_nobless (p)
	mpz_t *	p
CODE:
  RETVAL = Rmpz_init_set_nobless (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_ui_nobless (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_ui_nobless (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_si_nobless (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_si_nobless (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_d_nobless (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_d_nobless (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init ()
CODE:
  RETVAL = Rmpz_init (aTHX);
OUTPUT:  RETVAL


SV *
Rmpz_init_set (p)
	mpz_t *	p
CODE:
  RETVAL = Rmpz_init_set (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_ui (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_ui (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_si (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_si (aTHX_ p);
OUTPUT:  RETVAL

void
Rmpz_set_uj (copy, original)
	mpz_t *	copy
	UV	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_uj(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_sj (copy, original)
	mpz_t *	copy
	IV	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_sj(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_IV (copy, original)
	mpz_t *	copy
	SV *	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_IV(aTHX_ copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpz_init_set_IV (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_IV (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_IV_nobless (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_IV_nobless (aTHX_ p);
OUTPUT:  RETVAL

SV *
_Rmpz_get_IV (n)
	mpz_t *	n
CODE:
  RETVAL = _Rmpz_get_IV (aTHX_ n);
OUTPUT:  RETVAL

int
Rmpz_fits_IV_p (n)
	mpz_t *	n
CODE:
  RETVAL = Rmpz_fits_IV_p (aTHX_ n);
OUTPUT:  RETVAL

double
Rmpz_get_d (n)
	mpz_t *	n

NV
Rmpz_get_NV (n)
	mpz_t *	n

int
Rmpz_cmp_IV (z, iv)
	mpz_t *	z
	SV *	iv
CODE:
  RETVAL = Rmpz_cmp_IV (aTHX_ z, iv);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_d (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_d (aTHX_ p);
OUTPUT:  RETVAL

void
_mpf_set_dd (q, p)
	mpf_t *	q
	SV *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _mpf_set_dd(q, p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_NV (copy, original)
	mpz_t *	copy
	SV *	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_NV(aTHX_ copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpz_init_set_NV (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_NV (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_NV_nobless (p)
	SV *	p
CODE:
  RETVAL = Rmpz_init_set_NV_nobless (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpz_init_set_str (num, base)
	SV *	num
	SV *	base
CODE:
  RETVAL = Rmpz_init_set_str (aTHX_ num, base);
OUTPUT:  RETVAL

SV *
Rmpz_init2 (bits)
	SV *	bits
CODE:
  RETVAL = Rmpz_init2 (aTHX_ bits);
OUTPUT:  RETVAL

SV *
Rmpz_get_str (p, base)
	mpz_t *	p
	SV *	base
CODE:
  RETVAL = Rmpz_get_str (aTHX_ p, base);
OUTPUT:  RETVAL

void
DESTROY (p)
	mpz_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        DESTROY(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_clear (p)
	mpz_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_clear(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_clear_mpz (p)
	mpz_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_clear_mpz(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_clear_ptr (p)
	mpz_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_clear_ptr(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_realloc2 (integer, bits)
	mpz_t *	integer
	SV *	bits
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_realloc2(aTHX_ integer, bits);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set (copy, original)
	mpz_t *	copy
	mpz_t *	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_q (copy, original)
	mpz_t *	copy
	mpq_t *	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_q(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_f (copy, original)
	mpz_t *	copy
	mpf_t *	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_f(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_si (copy, original)
	mpz_t *	copy
	long	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_si(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_ui (copy, original)
	mpz_t *	copy
	unsigned long	original
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_ui(copy, original);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_d (copy, d)
	mpz_t *	copy
	double	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_d(copy, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_set_str (copy, original, base)
	mpz_t *	copy
	SV *	original
	int	base
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_set_str(aTHX_ copy, original, base);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_swap (a, b)
	mpz_t *	a
	mpz_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_swap(a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpz_get_ui (n)
	mpz_t *	n

long
Rmpz_get_si (n)
	mpz_t *	n

void
Rmpz_get_d_2exp (n)
	mpz_t *	n
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_get_d_2exp(aTHX_ n);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpz_getlimbn (p, n)
	mpz_t *	p
	SV *	n
CODE:
  RETVAL = Rmpz_getlimbn (aTHX_ p, n);
OUTPUT:  RETVAL

void
Rmpz_add (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_add(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_add_ui (dest, src, num)
	mpz_t *	dest
	mpz_t *	src
	unsigned long	num
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_add_ui(dest, src, num);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_sub (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_sub(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_sub_ui (dest, src, num)
	mpz_t *	dest
	mpz_t *	src
	unsigned long	num
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_sub_ui(dest, src, num);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_ui_sub (dest, num, src)
	mpz_t *	dest
	unsigned long	num
	mpz_t *	src
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_ui_sub(dest, num, src);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mul (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mul(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mul_si (dest, src, num)
	mpz_t *	dest
	mpz_t *	src
	long	num
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mul_si(dest, src, num);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mul_ui (dest, src, num)
	mpz_t *	dest
	mpz_t *	src
	unsigned long	num
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mul_ui(dest, src, num);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_addmul (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_addmul(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_addmul_ui (dest, src, num)
	mpz_t *	dest
	mpz_t *	src
	unsigned long	num
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_addmul_ui(dest, src, num);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_submul (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_submul(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_submul_ui (dest, src, num)
	mpz_t *	dest
	mpz_t *	src
	unsigned long	num
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_submul_ui(dest, src, num);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mul_2exp (dest, src1, b)
	mpz_t *	dest
	mpz_t *	src1
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mul_2exp(aTHX_ dest, src1, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_div_2exp (dest, src1, b)
	mpz_t *	dest
	mpz_t *	src1
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_div_2exp(aTHX_ dest, src1, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_neg (dest, src)
	mpz_t *	dest
	mpz_t *	src
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_neg(dest, src);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_abs (dest, src)
	mpz_t *	dest
	mpz_t *	src
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_abs(dest, src);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_cdiv_q (q, n, d)
	mpz_t *	q
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_cdiv_q(q, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_cdiv_r (mod, n, d)
	mpz_t *	mod
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_cdiv_r(mod, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_cdiv_qr (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_cdiv_qr(q, r, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpz_cdiv_q_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_cdiv_r_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_cdiv_qr_ui (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_cdiv_ui (n, d)
	mpz_t *	n
	unsigned long	d

void
Rmpz_cdiv_q_2exp (q, n, b)
	mpz_t *	q
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_cdiv_q_2exp(aTHX_ q, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_cdiv_r_2exp (r, n, b)
	mpz_t *	r
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_cdiv_r_2exp(aTHX_ r, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_fdiv_q (q, n, d)
	mpz_t *	q
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fdiv_q(q, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_div (q, n, d)
	mpz_t *	q
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_div(q, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_fdiv_r (mod, n, d)
	mpz_t *	mod
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fdiv_r(mod, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_fdiv_qr (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fdiv_qr(q, r, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_divmod (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_divmod(q, r, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpz_fdiv_q_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_div_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_fdiv_r_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_fdiv_qr_ui (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_divmod_ui (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_fdiv_ui (n, d)
	mpz_t *	n
	unsigned long	d

void
Rmpz_fdiv_q_2exp (q, n, b)
	mpz_t *	q
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fdiv_q_2exp(aTHX_ q, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_fdiv_r_2exp (r, n, b)
	mpz_t *	r
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fdiv_r_2exp(aTHX_ r, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mod_2exp (r, n, b)
	mpz_t *	r
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mod_2exp(aTHX_ r, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_tdiv_q (q, n, d)
	mpz_t *	q
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_tdiv_q(q, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_tdiv_r (mod, n, d)
	mpz_t *	mod
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_tdiv_r(mod, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_tdiv_qr (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_tdiv_qr(q, r, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpz_tdiv_q_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_tdiv_r_ui (q, n, d)
	mpz_t *	q
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_tdiv_qr_ui (q, r, n, d)
	mpz_t *	q
	mpz_t *	r
	mpz_t *	n
	unsigned long	d

unsigned long
Rmpz_tdiv_ui (n, d)
	mpz_t *	n
	unsigned long	d

void
Rmpz_tdiv_q_2exp (q, n, b)
	mpz_t *	q
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_tdiv_q_2exp(aTHX_ q, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_tdiv_r_2exp (r, n, b)
	mpz_t *	r
	mpz_t *	n
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_tdiv_r_2exp(aTHX_ r, n, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mod (r, n, d)
	mpz_t *	r
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mod(r, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpz_mod_ui (r, n, d)
	mpz_t *	r
	mpz_t *	n
	unsigned long	d

void
Rmpz_divexact (dest, n, d)
	mpz_t *	dest
	mpz_t *	n
	mpz_t *	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_divexact(dest, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_divexact_ui (dest, n, d)
	mpz_t *	dest
	mpz_t *	n
	unsigned long	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_divexact_ui(dest, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpz_divisible_p (n, d)
	mpz_t *	n
	mpz_t *	d

int
Rmpz_divisible_ui_p (n, d)
	mpz_t *	n
	unsigned long	d

int
Rmpz_divisible_2exp_p (n, b)
	mpz_t *	n
	SV *	b
CODE:
  RETVAL = Rmpz_divisible_2exp_p (aTHX_ n, b);
OUTPUT:  RETVAL

int
Rmpz_congruent_p (n, c, d)
	mpz_t *	n
	mpz_t *	c
	mpz_t *	d

int
Rmpz_congruent_ui_p (n, c, d)
	mpz_t *	n
	unsigned long	c
	unsigned long	d

SV *
Rmpz_congruent_2exp_p (n, c, d)
	mpz_t *	n
	mpz_t *	c
	SV *	d
CODE:
  RETVAL = Rmpz_congruent_2exp_p (aTHX_ n, c, d);
OUTPUT:  RETVAL

void
Rmpz_powm (dest, base, exp, mod)
	mpz_t *	dest
	mpz_t *	base
	mpz_t *	exp
	mpz_t *	mod
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_powm(dest, base, exp, mod);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_powm_ui (dest, base, exp, mod)
	mpz_t *	dest
	mpz_t *	base
	unsigned long	exp
	mpz_t *	mod
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_powm_ui(dest, base, exp, mod);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_pow_ui (dest, base, exp)
	mpz_t *	dest
	mpz_t *	base
	unsigned long	exp
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_pow_ui(dest, base, exp);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_ui_pow_ui (dest, base, exp)
	mpz_t *	dest
	unsigned long	base
	unsigned long	exp
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_ui_pow_ui(dest, base, exp);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpz_root (r, n, d)
	mpz_t *	r
	mpz_t *	n
	unsigned long	d

void
Rmpz_sqrt (r, n)
	mpz_t *	r
	mpz_t *	n
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_sqrt(r, n);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_sqrtrem (root, rem, src)
	mpz_t *	root
	mpz_t *	rem
	mpz_t *	src
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_sqrtrem(root, rem, src);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpz_perfect_power_p (in)
	mpz_t *	in

int
Rmpz_perfect_square_p (in)
	mpz_t *	in

int
Rmpz_probab_prime_p (cand, reps)
	mpz_t *	cand
	SV *	reps
CODE:
  RETVAL = Rmpz_probab_prime_p (aTHX_ cand, reps);
OUTPUT:  RETVAL

void
Rmpz_nextprime (prime, init)
	mpz_t *	prime
	mpz_t *	init
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_nextprime(prime, init);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_gcd (gcd, src1, src2)
	mpz_t *	gcd
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_gcd(gcd, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpz_gcd_ui (gcd, n, d)
	mpz_t *	gcd
	mpz_t *	n
	unsigned long	d

void
Rmpz_gcdext (g, s, t, a, b)
	mpz_t *	g
	mpz_t *	s
	mpz_t *	t
	mpz_t *	a
	mpz_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_gcdext(g, s, t, a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_lcm (lcm, src1, src2)
	mpz_t *	lcm
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_lcm(lcm, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_lcm_ui (lcm, src1, src2)
	mpz_t *	lcm
	mpz_t *	src1
	unsigned long	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_lcm_ui(lcm, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpz_invert (inv, src1, src2)
	mpz_t *	inv
	mpz_t *	src1
	mpz_t *	src2

int
Rmpz_jacobi (a, b)
	mpz_t *	a
	mpz_t *	b

int
Rmpz_legendre (a, b)
	mpz_t *	a
	mpz_t *	b

int
Rmpz_kronecker (a, b)
	mpz_t *	a
	mpz_t *	b

int
Rmpz_kronecker_si (a, b)
	mpz_t *	a
	long	b

int
Rmpz_kronecker_ui (a, b)
	mpz_t *	a
	unsigned long	b

int
Rmpz_si_kronecker (a, b)
	long	a
	mpz_t *	b

int
Rmpz_ui_kronecker (a, b)
	unsigned long	a
	mpz_t *	b

SV *
Rmpz_remove (rem, src1, src2)
	mpz_t *	rem
	mpz_t *	src1
	mpz_t *	src2
CODE:
  RETVAL = Rmpz_remove (aTHX_ rem, src1, src2);
OUTPUT:  RETVAL

void
Rmpz_fac_ui (fac, b)
	mpz_t *	fac
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fac_ui(fac, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_2fac_ui (fac, b)
	mpz_t *	fac
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_2fac_ui(fac, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_mfac_uiui (fac, b, c)
	mpz_t *	fac
	unsigned long	b
	unsigned long	c
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_mfac_uiui(fac, b, c);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_primorial_ui (fac, b)
	mpz_t *	fac
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_primorial_ui(fac, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_bin_ui (dest, n, d)
	mpz_t *	dest
	mpz_t *	n
	unsigned long	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_bin_ui(dest, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_bin_si (dest, n, d)
	mpz_t *	dest
	mpz_t *	n
	long	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_bin_si(dest, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_bin_uiui (dest, n, d)
	mpz_t *	dest
	unsigned long	n
	unsigned long	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_bin_uiui(dest, n, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_fib_ui (dest, b)
	mpz_t *	dest
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fib_ui(dest, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_fib2_ui (fn, fnsub1, b)
	mpz_t *	fn
	mpz_t *	fnsub1
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_fib2_ui(fn, fnsub1, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_lucnum_ui (dest, b)
	mpz_t *	dest
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_lucnum_ui(dest, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_lucnum2_ui (ln, lnsub1, b)
	mpz_t *	ln
	mpz_t *	lnsub1
	unsigned long	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_lucnum2_ui(ln, lnsub1, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpz_cmp (n, d)
	mpz_t *	n
	mpz_t *	d

int
Rmpz_cmp_d (n, d)
	mpz_t *	n
	double	d

int
Rmpz_cmp_NV (a, b)
	mpz_t *	a
	SV *	b
CODE:
  RETVAL = Rmpz_cmp_NV (aTHX_ a, b);
OUTPUT:  RETVAL

int
Rmpz_cmp_si (n, d)
	mpz_t *	n
	long	d

int
Rmpz_cmp_ui (n, d)
	mpz_t *	n
	unsigned long	d

int
Rmpz_cmpabs (n, d)
	mpz_t *	n
	mpz_t *	d

int
Rmpz_cmpabs_d (n, d)
	mpz_t *	n
	double	d

int
Rmpz_cmpabs_ui (n, d)
	mpz_t *	n
	unsigned long	d

int
Rmpz_sgn (n)
	mpz_t *	n

void
Rmpz_and (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_and(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_ior (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_ior(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_xor (dest, src1, src2)
	mpz_t *	dest
	mpz_t *	src1
	mpz_t *	src2
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_xor(dest, src1, src2);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_com (dest, src)
	mpz_t *	dest
	mpz_t *	src
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_com(dest, src);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpz_popcount (in)
	mpz_t *	in
CODE:
  RETVAL = Rmpz_popcount (aTHX_ in);
OUTPUT:  RETVAL

SV *
Rmpz_hamdist (dest, src)
	mpz_t *	dest
	mpz_t *	src
CODE:
  RETVAL = Rmpz_hamdist (aTHX_ dest, src);
OUTPUT:  RETVAL

SV *
Rmpz_scan0 (n, start_bit)
	mpz_t *	n
	SV *	start_bit
CODE:
  RETVAL = Rmpz_scan0 (aTHX_ n, start_bit);
OUTPUT:  RETVAL

SV *
Rmpz_scan1 (n, start_bit)
	mpz_t *	n
	SV *	start_bit
CODE:
  RETVAL = Rmpz_scan1 (aTHX_ n, start_bit);
OUTPUT:  RETVAL

void
Rmpz_setbit (num, bit_index)
	mpz_t *	num
	SV *	bit_index
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_setbit(aTHX_ num, bit_index);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_clrbit (num, bit_index)
	mpz_t *	num
	SV *	bit_index
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_clrbit(aTHX_ num, bit_index);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpz_tstbit (num, bit_index)
	mpz_t *	num
	SV *	bit_index
CODE:
  RETVAL = Rmpz_tstbit (aTHX_ num, bit_index);
OUTPUT:  RETVAL

void
Rmpz_import (rop, count, order, size, endian, nails, op)
	mpz_t *	rop
	SV *	count
	SV *	order
	SV *	size
	SV *	endian
	SV *	nails
	SV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_import(aTHX_ rop, count, order, size, endian, nails, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpz_export (order, size, endian, nails, op)
	SV *	order
	SV *	size
	SV *	endian
	SV *	nails
	mpz_t *	op
CODE:
  RETVAL = Rmpz_export (aTHX_ order, size, endian, nails, op);
OUTPUT:  RETVAL

void
Rmpz_import_UV (rop, count, order, size, endian, nails, op)
	mpz_t *	rop
	SV *	count
	SV *	order
	SV *	size
	SV *	endian
	SV *	nails
	AV *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_import_UV(aTHX_ rop, count, order, size, endian, nails, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_export_UV (order, size, endian, nails, op)
	SV *	order
	SV *	size
	SV *	endian
	SV *	nails
	mpz_t *	op
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_export_UV(aTHX_ order, size, endian, nails, op);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpz_fits_ulong_p (in)
	mpz_t *	in

int
Rmpz_fits_slong_p (in)
	mpz_t *	in

int
Rmpz_fits_uint_p (in)
	mpz_t *	in

int
Rmpz_fits_sint_p (in)
	mpz_t *	in

int
Rmpz_fits_ushort_p (in)
	mpz_t *	in

int
Rmpz_fits_sshort_p (in)
	mpz_t *	in

int
Rmpz_odd_p (in)
	mpz_t *	in

int
Rmpz_even_p (in)
	mpz_t *	in

SV *
Rmpz_size (in)
	mpz_t *	in
CODE:
  RETVAL = Rmpz_size (aTHX_ in);
OUTPUT:  RETVAL

SV *
Rmpz_sizeinbase (in, base)
	mpz_t *	in
	int	base
CODE:
  RETVAL = Rmpz_sizeinbase (aTHX_ in, base);
OUTPUT:  RETVAL

void
Rsieve_gmp (x_arg, a, number)
	int	x_arg
	int	a
	mpz_t *	number
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rsieve_gmp(aTHX_ x_arg, a, number);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rfermat_gmp (num, base)
	mpz_t *	num
	int	base
CODE:
  RETVAL = Rfermat_gmp (aTHX_ num, base);
OUTPUT:  RETVAL

SV *
Rrm_gmp (num, base)
	mpz_t *	num
	int	base
CODE:
  RETVAL = Rrm_gmp (aTHX_ num, base);
OUTPUT:  RETVAL

SV *
_Rmpz_out_str (p, base)
	mpz_t *	p
	int	base
CODE:
  RETVAL = _Rmpz_out_str (aTHX_ p, base);
OUTPUT:  RETVAL

SV *
_Rmpz_out_strS (p, base, suff)
	mpz_t *	p
	SV *	base
	SV *	suff
CODE:
  RETVAL = _Rmpz_out_strS (aTHX_ p, base, suff);
OUTPUT:  RETVAL

SV *
_Rmpz_out_strP (pre, p, base)
	SV *	pre
	mpz_t *	p
	SV *	base
CODE:
  RETVAL = _Rmpz_out_strP (aTHX_ pre, p, base);
OUTPUT:  RETVAL

SV *
_Rmpz_out_strPS (pre, p, base, suff)
	SV *	pre
	mpz_t *	p
	SV *	base
	SV *	suff
CODE:
  RETVAL = _Rmpz_out_strPS (aTHX_ pre, p, base, suff);
OUTPUT:  RETVAL

SV *
_TRmpz_out_str (stream, base, p)
	FILE *	stream
	SV *	base
	mpz_t *	p
CODE:
  RETVAL = _TRmpz_out_str (aTHX_ stream, base, p);
OUTPUT:  RETVAL

SV *
_TRmpz_out_strS (stream, base, p, suff)
	FILE *	stream
	SV *	base
	mpz_t *	p
	SV *	suff
CODE:
  RETVAL = _TRmpz_out_strS (aTHX_ stream, base, p, suff);
OUTPUT:  RETVAL

SV *
_TRmpz_out_strP (pre, stream, base, p)
	SV *	pre
	FILE *	stream
	SV *	base
	mpz_t *	p
CODE:
  RETVAL = _TRmpz_out_strP (aTHX_ pre, stream, base, p);
OUTPUT:  RETVAL

SV *
_TRmpz_out_strPS (pre, stream, base, p, suff)
	SV *	pre
	FILE *	stream
	SV *	base
	mpz_t *	p
	SV *	suff
CODE:
  RETVAL = _TRmpz_out_strPS (aTHX_ pre, stream, base, p, suff);
OUTPUT:  RETVAL

SV *
Rmpz_inp_str (p, base)
	mpz_t *	p
	int	base
CODE:
  RETVAL = Rmpz_inp_str (aTHX_ p, base);
OUTPUT:  RETVAL

SV *
TRmpz_inp_str (p, stream, base)
	mpz_t *	p
	FILE *	stream
	int	base
CODE:
  RETVAL = TRmpz_inp_str (aTHX_ p, stream, base);
OUTPUT:  RETVAL

void
eratosthenes (x_arg)
	SV *	x_arg
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        eratosthenes(aTHX_ x_arg);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
trial_div_ul (num, x_arg)
	mpz_t *	num
	SV *	x_arg
CODE:
  RETVAL = trial_div_ul (aTHX_ num, x_arg);
OUTPUT:  RETVAL

void
Rmpz_rootrem (root, rem, u, d)
	mpz_t *	root
	mpz_t *	rem
	mpz_t *	u
	unsigned long	d
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_rootrem(root, rem, u, d);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_combit (num, bitpos)
	mpz_t *	num
	SV *	bitpos
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_combit(aTHX_ num, bitpos);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
overload_mul (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_mul (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_add (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_add (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_sub (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_sub (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_div (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_div (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_mod (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_mod (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_string (p, second, third)
	mpz_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_string (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_copy (p, second, third)
	mpz_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_copy (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_abs (p, second, third)
	mpz_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_abs (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_lshift (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lshift (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_rshift (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_rshift (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_pow (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_pow (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_sqrt (p, second, third)
	mpz_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_sqrt (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_and (a, b, third, ...)
	mpz_t *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = overload_and(aTHX_ a, b, third);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
overload_ior (a, b, third, ...)
	mpz_t *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = overload_ior(aTHX_ a, b, third);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
overload_xor (a, b, third, ...)
	mpz_t *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = overload_xor(aTHX_ a, b, third);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
overload_com (p, second, third)
	mpz_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_com (aTHX_ p, second, third);
OUTPUT:  RETVAL

int
my_cmp_z (p, z)
	mpq_t *	p
	mpz_t *	z

SV *
overload_gt (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_gte (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lt (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lte (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_spaceship (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_equiv (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_not_equiv (a, b, third)
	mpz_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_not_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_not (a, second, third)
	mpz_t *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_not (aTHX_ a, second, third);
OUTPUT:  RETVAL

SV *
overload_xor_eq (a, b, third, ...)
	SV *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = overload_xor_eq(aTHX_ a, b, third);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
overload_ior_eq (a, b, third, ...)
	SV *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = overload_ior_eq(aTHX_ a, b, third);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
overload_and_eq (a, b, third, ...)
	SV *	a
	SV *	b
	SV *	third
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = overload_and_eq(aTHX_ a, b, third);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

SV *
overload_pow_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_pow_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_rshift_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_rshift_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lshift_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lshift_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_inc (p, second, third)
	SV *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_inc (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_dec (p, second, third)
	SV *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_dec (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_mod_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_mod_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
get_refcnt (s)
	SV *	s
CODE:
  RETVAL = get_refcnt (aTHX_ s);
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
overload_sub_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_sub_eq (aTHX_ a, b, third);
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
eratosthenes_string (x_arg)
	SV *	x_arg
CODE:
  RETVAL = eratosthenes_string (aTHX_ x_arg);
OUTPUT:  RETVAL

SV *
gmp_v ()
CODE:
  RETVAL = gmp_v (aTHX);
OUTPUT:  RETVAL


SV *
wrap_gmp_printf (a, b)
	SV *	a
	SV *	b
CODE:
  RETVAL = wrap_gmp_printf (aTHX_ a, b);
OUTPUT:  RETVAL

SV *
wrap_gmp_fprintf (stream, a, b)
	FILE *	stream
	SV *	a
	SV *	b
CODE:
  RETVAL = wrap_gmp_fprintf (aTHX_ stream, a, b);
OUTPUT:  RETVAL

SV *
wrap_gmp_sprintf (s, a, b, buflen)
	SV *	s
	SV *	a
	SV *	b
	int	buflen
CODE:
  RETVAL = wrap_gmp_sprintf (aTHX_ s, a, b, buflen);
OUTPUT:  RETVAL

SV *
wrap_gmp_snprintf (s, bytes, a, b, buflen)
	SV *	s
	SV *	bytes
	SV *	a
	SV *	b
	int	buflen
CODE:
  RETVAL = wrap_gmp_snprintf (aTHX_ s, bytes, a, b, buflen);
OUTPUT:  RETVAL

SV *
_itsa (a)
	SV *	a
CODE:
  RETVAL = _itsa (aTHX_ a);
OUTPUT:  RETVAL

void
Rmpz_urandomb (p, ...)
	SV *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_urandomb(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_urandomm (x, ...)
	SV *	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_urandomm(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpz_rrandomb (x, ...)
	SV *	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_rrandomb(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
rand_init (seed)
	SV *	seed
CODE:
  RETVAL = rand_init (aTHX_ seed);
OUTPUT:  RETVAL

void
rand_clear (p)
	SV *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        rand_clear(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_has_longlong ()


int
_has_longdouble ()


int
_has_float128 ()


int
_has_inttypes ()


SV *
Rmpz_inp_raw (a, stream)
	mpz_t *	a
	FILE *	stream
CODE:
  RETVAL = Rmpz_inp_raw (aTHX_ a, stream);
OUTPUT:  RETVAL

SV *
Rmpz_out_raw (stream, a)
	FILE *	stream
	mpz_t *	a
CODE:
  RETVAL = Rmpz_out_raw (aTHX_ stream, a);
OUTPUT:  RETVAL

SV *
___GNU_MP_VERSION ()
CODE:
  RETVAL = ___GNU_MP_VERSION (aTHX);
OUTPUT:  RETVAL


SV *
___GNU_MP_VERSION_MINOR ()
CODE:
  RETVAL = ___GNU_MP_VERSION_MINOR (aTHX);
OUTPUT:  RETVAL


SV *
___GNU_MP_VERSION_PATCHLEVEL ()
CODE:
  RETVAL = ___GNU_MP_VERSION_PATCHLEVEL (aTHX);
OUTPUT:  RETVAL


SV *
___GNU_MP_RELEASE ()
CODE:
  RETVAL = ___GNU_MP_RELEASE (aTHX);
OUTPUT:  RETVAL


SV *
___GMP_CC ()
CODE:
  RETVAL = ___GMP_CC (aTHX);
OUTPUT:  RETVAL


SV *
___GMP_CFLAGS ()
CODE:
  RETVAL = ___GMP_CFLAGS (aTHX);
OUTPUT:  RETVAL


void
Rmpz_powm_sec (dest, base, exp, mod)
	mpz_t *	dest
	mpz_t *	base
	mpz_t *	exp
	mpz_t *	mod
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpz_powm_sec(dest, base, exp, mod);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_using_mpir ()


SV *
_Rmpz_NULL ()
CODE:
  RETVAL = _Rmpz_NULL (aTHX);
OUTPUT:  RETVAL


SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


void
Rprbg_ms (outref, p, q, seed, bits_required)
	mpz_t *	outref
	mpz_t *	p
	mpz_t *	q
	mpz_t *	seed
	int	bits_required
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rprbg_ms(aTHX_ outref, p, q, seed, bits_required);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rprbg_bbs (outref, p, q, seed, bits_required)
	mpz_t *	outref
	mpz_t *	p
	mpz_t *	q
	mpz_t *	seed
	int	bits_required
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rprbg_bbs(aTHX_ outref, p, q, seed, bits_required);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmonobit (bitstream)
	mpz_t *	bitstream

int
Rlong_run (bitstream)
	mpz_t *	bitstream

int
Rruns (bitstream)
	mpz_t *	bitstream

int
Rpoker (bitstream)
	mpz_t *	bitstream

SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


SV *
query_eratosthenes_string (candidate, str)
	int	candidate
	char *	str
CODE:
  RETVAL = query_eratosthenes_string (aTHX_ candidate, str);
OUTPUT:  RETVAL

void
autocorrelation (bitstream, offset)
	mpz_t *	bitstream
	int	offset
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        autocorrelation(aTHX_ bitstream, offset);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
autocorrelation_20000 (bitstream, offset)
	mpz_t *	bitstream
	int	offset
CODE:
  RETVAL = autocorrelation_20000 (aTHX_ bitstream, offset);
OUTPUT:  RETVAL

SV *
_GMP_LIMB_BITS ()
CODE:
  RETVAL = _GMP_LIMB_BITS (aTHX);
OUTPUT:  RETVAL


SV *
_GMP_NAIL_BITS ()
CODE:
  RETVAL = _GMP_NAIL_BITS (aTHX);
OUTPUT:  RETVAL


SV *
_new_from_MBI (b)
	SV *	b
CODE:
  RETVAL = _new_from_MBI (aTHX_ b);
OUTPUT:  RETVAL

SV *
_magic_status ()
CODE:
  RETVAL = _magic_status (aTHX);
OUTPUT:  RETVAL


void
_dump_mbi_gmp (b)
	SV *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _dump_mbi_gmp(aTHX_ b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_SvIOK (sv)
	SV *	sv
CODE:
  RETVAL = _SvIOK (aTHX_ sv);
OUTPUT:  RETVAL

int
_SvPOK (sv)
	SV *	sv

int
_SvNOK (sv)
	SV *	sv

int
IOK_flag (sv)
	SV *	sv

int
POK_flag (sv)
	SV *	sv

int
NOK_flag (sv)
	SV *	sv

SV *
_sizeof_mp_bitcnt_t ()
CODE:
  RETVAL = _sizeof_mp_bitcnt_t (aTHX);
OUTPUT:  RETVAL


int
_gmp_index_overflow ()


