
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_gmpq_include.h"
#include "math_gmpq_unused.h"

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

void Rmpq_canonicalize (mpq_t * p) {
     mpq_canonicalize(*p);
}

SV * Rmpq_init(pTHX) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;

     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in Rmpq_init function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init (*mpq_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpq_init_nobless(pTHX) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;

     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in Rmpq_init_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     mpq_init (*mpq_t_obj);

     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

void DESTROY(pTHX_ mpq_t * p) {
/*     printf("Destroying mpq "); */
     mpq_clear(*p);
     Safefree(p);
/*     printf("...destroyed\n"); */
}

void Rmpq_clear(pTHX_ mpq_t * p) {
     mpq_clear(*p);
     Safefree(p);
}

void Rmpq_clear_mpq(mpq_t * p) {
     mpq_clear(*p);
}

void Rmpq_clear_ptr(pTHX_ mpq_t * p) {
     Safefree(p);
}

void Rmpq_set(mpq_t * p1, mpq_t * p2) {
     mpq_set(*p1, *p2);
}

void Rmpq_swap(mpq_t * p1, mpq_t * p2) {
     mpq_swap(*p1, *p2);
}

void Rmpq_set_z(mpq_t * p1, mpz_t * p2) {
     mpq_set_z(*p1, *p2);
}

void Rmpq_set_ui(mpq_t * p1, unsigned long p2, unsigned long p3) {
     mpq_set_ui(*p1, p2, p3);
}

void Rmpq_set_si(mpq_t * p1, long p2, long p3) {
     mpq_set_si(*p1, p2, p3);
}

void _Rmpq_set_str(pTHX_ mpq_t * p1, SV * p2, int base) {
     if(base < 0 || base == 1 || base > 62) croak ("%d is not a valid base in Rmpq_set_str", base);
     if(mpq_set_str(*p1, SvPV_nolen(p2), base))
       croak("String supplied to Rmpq_set_str function (%s) is not a valid base %d number", SvPV_nolen(p2), base);
}


double Rmpq_get_d(mpq_t * p) {
     return mpq_get_d(*p);
}

void Rmpq_set_d(mpq_t * p, double d){
     if(d != d) croak ("In Rmpq_set_d, cannot coerce a NaN to a Math::GMPq value");
     if(d != 0 && d / d != 1) croak ("In Rmpq_set_d, cannot coerce an Inf to a Math::GMPq value");
     mpq_set_d(*p, d);
}

void _mpf_set_doubledouble(mpf_t * q, SV * p) {
#if defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098
     double msd;                     /* Most Significant Double */
     mpf_t t, d;
     long double lsd;                /* Will be assigned the Least Siginficant Double */

     msd = (double)SvNV(p);
     if(msd != 0.0) {
       if(msd != msd) croak("In _mpf_set_doubledouble (called from Rmpq_set_NV), cannot coerce a NaN to a Math::GMPf object");
       if(msd / msd != 1.0) croak("In _mpf_set_doubledouble (called from Rmpq_set_NV), cannot coerce an Inf to a Math::GMPf object");
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
     PERL_UNUSED_ARG2(q, p);
     croak("_mpf_set_doubledouble not implemented because NV is not a doubledouble");

#endif
}

void Rmpq_set_NV(pTHX_ mpq_t * copy, SV * original) {

#if defined(USE_QUADMATH)

     char * buffer;
     int exp, exp2 = 0;
     __float128 ld, buffer_size;
     int returned;

     if(!SV_IS_NOK(original))
       croak("In Rmpq_set_NV, 2nd argument is not an NV");

     ld = (__float128)SvNV(original);
     if(ld != ld) croak("In Rmpq_set_NV, cannot coerce a NaN to a Math::GMPq value");
     if(ld != 0 && (ld / ld != 1))
       croak("In Rmpq_set_NV, cannot coerce an Inf to a Math::GMPq value");

     ld = frexpq((__float128)SvNV(original), &exp);

     while(ld != floorq(ld)) {
          ld *= 2;
          exp2 += 1;
     }

     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceill(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, (int)buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Rmpq_set_NV, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Rmpq_set_NV, buffer given to quadmath_snprintf function was too small");
     mpq_set_str(*copy, buffer, 10);
     Safefree(buffer);

     if (exp2 > exp) mpq_div_2exp(*copy, *copy, exp2 - exp);
     else mpq_mul_2exp(*copy, *copy, exp - exp2);

#elif defined(USE_LONG_DOUBLE)

#  if REQUIRED_LDBL_MANT_DIG == 2098
     mpf_t t;

     if(!SV_IS_NOK(original))
       croak("In Rmpq_set_NV, 2nd argument is not an NV");

     mpf_init2(t, 2098);
     _mpf_set_doubledouble(&t, original);
     mpq_set_f(*copy, t);
     mpf_clear(t);

#  else
     char * buffer;
     int exp, exp2 = 0;
     long double ld, buffer_size;

     if(!SV_IS_NOK(original))
       croak("In Rmpq_set_NV, 2nd argument is not an NV");

     ld = (long double)SvNV(original);
     if(ld != ld) croak("In Rmpq_set_NV, cannot coerce a NaN to a Math::GMPq value");
     if(ld != 0 && (ld / ld != 1))
       croak("In Rmpq_set_NV, cannot coerce an Inf to a Math::GMPq value");

     ld = frexpl((long double)SvNV(original), &exp);

     while(ld != floorl(ld)) {
          ld *= 2;
          exp2 += 1;
     }

     buffer_size = ld < 0.0L ? ld * -1.0L : ld;
     buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

     Newxz(buffer, (int)buffer_size + 5, char);

     if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Rmpq_set_NV, buffer overflow in sprintf function");

     mpq_set_str(*copy, buffer, 10);
     Safefree(buffer);

     if (exp2 > exp) mpq_div_2exp(*copy, *copy, exp2 - exp);
     else mpq_mul_2exp(*copy, *copy, exp - exp2);
#  endif

#else
     double d;

     if(!SV_IS_NOK(original))
       croak("In Rmpq_set_NV, 2nd argument is not an NV");

     d = SvNV(original);
     if(d != d) croak("In Rmpq_set_NV, cannot coerce a NaN to a Math::GMPq value");
     if(d != 0 && (d / d != 1))
       croak("In Rmpq_set_NV, cannot coerce an Inf to a Math::GMPq value");

     mpq_set_d(*copy, d);
#endif
}

int Rmpq_cmp_NV(pTHX_ mpq_t * a, SV * b) {

     mpq_t t;
     int returned;

     if(!SvNOK(b))
       croak("In Rmpq_cmp_NV, 2nd argument is not an NV");

#if defined(USE_QUADMATH)

     char * buffer;
     int exp, exp2 = 0;
     __float128 ld, buffer_size;

     ld = (__float128)SvNV(b);
     if(ld != ld) croak("In Rmpq_cmp_NV, cannot compare a NaN to a Math::GMPq value");
     if(ld != 0 && (ld / ld != 1)) {
       if(ld > 0) return -1;
       return 1;
     }

     ld = frexpq((__float128)SvNV(b), &exp);

     while(ld != floorq(ld)) {
          ld *= 2;
          exp2 += 1;
     }

     buffer_size = ld < 0.0Q ? ld * -1.0Q : ld;
     buffer_size = ceilq(logq(buffer_size + 1) / 2.30258509299404568401799145468436418Q);

     Newxz(buffer, (int)buffer_size + 5, char);

     returned = quadmath_snprintf(buffer, (size_t)buffer_size + 5, "%.0Qf", ld);
     if(returned < 0) croak("In Rmpq_cmp_NV, encoding error in quadmath_snprintf function");
     if(returned >= buffer_size + 5) croak("In Rmpq_cmp_NV, buffer given to quadmath_snprintf function was too small");
     mpq_init(t);
     mpq_set_str(t, buffer, 10);
     Safefree(buffer);

     if (exp2 > exp) mpq_div_2exp(t, t, exp2 - exp);
     else mpq_mul_2exp(t, t, exp - exp2);

#elif defined(USE_LONG_DOUBLE)
# if REQUIRED_LDBL_MANT_DIG == 2098
     mpf_t temp;
     long double ld = (long double)SvNV(b);
     if(ld != ld) croak("In Rmpq_cmp_NV, cannot compare a NaN to a Math::GMPq value");
     if(ld != 0 && ld / ld != 1) {
       if(ld > 0) return -1;
       return 1;
     }
     mpq_init(t);
     mpf_init2(temp, 2098);
     _mpf_set_doubledouble(&temp, b);
     mpq_set_f(t, temp);
     mpf_clear(temp);

#  else
     char * buffer;
     int exp, exp2 = 0;
     long double ld, buffer_size;

     ld = (long double)SvNV(b);
     if(ld != ld) croak("In Rmpq_cmp_NV, cannot compare a NaN to a Math::GMPq value");
     if(ld != 0 && (ld / ld != 1)) {
       if(ld > 0) return -1;
       return 1;
     }

     ld = frexpl((long double)SvNV(b), &exp);

     while(ld != floorl(ld)) {
          ld *= 2;
          exp2 += 1;
     }

     buffer_size = ld < 0.0L ? ld * -1.0L : ld;
     buffer_size = ceill(logl(buffer_size + 1) / 2.30258509299404568401799145468436418L);

     Newxz(buffer, (int)buffer_size + 5, char);

     if(sprintf(buffer, "%.0Lf", ld) >= (int)buffer_size + 5) croak("In Rmpq_cmp_NV, buffer overflow in sprintf function");
     mpq_init(t);
     mpq_set_str(t, buffer, 10);
     Safefree(buffer);

     if (exp2 > exp) mpq_div_2exp(t, t, exp2 - exp);
     else mpq_mul_2exp(t, t, exp - exp2);

#  endif
#else
     double d = SvNV(b);
     if(d != d) croak("In Rmpq_cmp_NV, cannot compare a NaN to a Math::GMPq value");
     if(d != 0 && (d / d != 1)) {
       if(d > 0) return -1;
       return 1;
     }
     mpq_init(t);
     mpq_set_d(t, d);
#endif

     returned = mpq_cmp(*a, t);
     mpq_clear(t);
     return returned;
}

void Rmpq_set_f(mpq_t * p, mpf_t * f) {
     mpq_set_f(*p, *f);
}

SV * Rmpq_get_str(pTHX_ mpq_t * p, int base){
     char * out;
     SV * outsv;

     New(123, out, mpz_sizeinbase(mpq_numref(*p), base) + mpz_sizeinbase(mpq_denref(*p), base) + 3, char);
     if(out == NULL) croak ("Failed to allocate memory in Rmpq_get_str function");

     mpq_get_str(out, base, *p);
     outsv = newSVpv(out, 0);
     Safefree(out);
     return outsv;
}

int Rmpq_cmp(mpq_t * p1, mpq_t * p2) {
     return mpq_cmp(*p1, *p2);
}

int Rmpq_cmp_ui(mpq_t * p1, unsigned long n, unsigned long d) {
     return mpq_cmp_ui(*p1, n, d);
}

int Rmpq_cmp_si(mpq_t * p1, long n, unsigned long d) {
     return mpq_cmp_si(*p1, n, d);
}

int Rmpq_cmp_z(mpq_t * p, mpz_t * z) {
#if __GNU_MP_RELEASE >= 60099
     return mpq_cmp_z(*p, *z);
#else
     int ret;
     mpz_t temp;

     mpz_init_set(temp, *z);
     mpz_mul(temp, temp, mpq_denref(*p));
     ret = mpz_cmp(mpq_numref(*p), temp);
     mpz_clear(temp);
     return ret;

#endif
}

int Rmpq_sgn(mpq_t * p) {
     return mpq_sgn(*p);
}

int Rmpq_equal(mpq_t * p1, mpq_t * p2) {
     return mpq_equal(*p1, *p2);
}

void Rmpq_add(mpq_t * p1, mpq_t * p2, mpq_t * p3) {
     mpq_add(*p1, *p2, *p3);
}

void Rmpq_sub(mpq_t * p1, mpq_t * p2, mpq_t * p3) {
     mpq_sub(*p1, *p2, *p3);
}

void Rmpq_mul(mpq_t * p1, mpq_t * p2, mpq_t * p3) {
     mpq_mul(*p1, *p2, *p3);
}

void Rmpq_div(mpq_t * p1, mpq_t * p2, mpq_t * p3) {
     if(!mpq_cmp_ui(*p3, 0, 1))
       croak("Division by 0 not allowed in Math::GMPq::Rmpq_div");
     mpq_div(*p1, *p2, *p3);
}

void Rmpq_mul_2exp(pTHX_ mpq_t * p1, mpq_t * p2, SV * p3) {
     mpq_mul_2exp(*p1, *p2, (mp_bitcnt_t)SvUV(p3));
}

void Rmpq_div_2exp(pTHX_ mpq_t * p1, mpq_t * p2, SV * p3) {
     mpq_div_2exp(*p1, *p2, (mp_bitcnt_t)SvUV(p3));
}

void Rmpq_neg(mpq_t * p1, mpq_t * p2) {
     mpq_neg(*p1, *p2);
}

void Rmpq_abs(mpq_t * p1, mpq_t * p2) {
     mpq_abs(*p1, *p2);
}

void Rmpq_inv(mpq_t * p1, mpq_t * p2) {
     mpq_inv(*p1, *p2);
}

SV * _Rmpq_out_str(pTHX_ mpq_t * p, int base){
     size_t ret;
     if(base < 2 || base > 36)
       croak("2nd argument supplied to Rmpq_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     ret = mpq_out_str(NULL, base, *p);
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpq_out_strS(pTHX_ mpq_t * p, int base, SV * suff) {
     size_t ret;
     if(base < 2 || base > 36)
       croak("2nd argument supplied to Rmpq_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     ret = mpq_out_str(NULL, base, *p);
     printf("%s", SvPV_nolen(suff));
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpq_out_strP(pTHX_ SV * pre, mpq_t * p, int base) {
     size_t ret;
     if(base < 2 || base > 36)
       croak("2nd argument supplied to Rmpq_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     printf("%s", SvPV_nolen(pre));
     ret = mpq_out_str(NULL, base, *p);
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpq_out_strPS(pTHX_ SV * pre, mpq_t * p, int base, SV * suff) {
     size_t ret;
     if(base < 2 || base > 36)
       croak("2nd argument supplied to Rmpq_out_str is out of allowable range (must be between 2 and 36 inclusive)");
     printf("%s", SvPV_nolen(pre));
     ret = mpq_out_str(NULL, base, *p);
     printf("%s", SvPV_nolen(suff));
     fflush(stdout);
     return newSVuv(ret);
}



SV * _TRmpq_out_str(pTHX_ FILE * stream, int base, mpq_t * p) {
     size_t ret;
     ret = mpq_out_str(stream, base, *p);
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpq_out_strS(pTHX_ FILE * stream, int base, mpq_t * p, SV * suff) {
     size_t ret;
     ret = mpq_out_str(stream, base, *p);
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpq_out_strP(pTHX_ SV * pre, FILE * stream, int base, mpq_t * p) {
     size_t ret;
     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpq_out_str(stream, base, *p);
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpq_out_strPS(pTHX_ SV * pre, FILE * stream, int base, mpq_t * p, SV * suff) {
     size_t ret;
     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpq_out_str(stream, base, *p);
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * TRmpq_inp_str(pTHX_ mpq_t * p, FILE * stream, SV * base) {
     size_t ret;
     ret = mpq_inp_str(*p, stream, (int)SvIV(base));
     /* fflush(stream); */
     return newSVuv(ret);
}

SV * Rmpq_inp_str(pTHX_ mpq_t * p, int base){
     size_t ret;
     ret = mpq_inp_str(*p, NULL, base);
     /* fflush(stdin); */
     return newSVuv(ret);
}

void Rmpq_numref(mpz_t * z, mpq_t * r) {
     mpz_set(*z, mpq_numref(*r));
}

void Rmpq_denref(mpz_t * z, mpq_t * r) {
     mpz_set(*z, mpq_denref(*r));
}

void Rmpq_get_num(mpz_t * z, mpq_t * r) {
     mpq_get_num(*z, *r);
}

void Rmpq_get_den(mpz_t * z, mpq_t * r) {
     mpq_get_den(*z, *r);
}

void Rmpq_set_num(mpq_t * r, mpz_t * z) {
     mpq_set_num(*r, *z);
}

void Rmpq_set_den(mpq_t * r, mpz_t * z) {
     mpq_set_den(*r, *z);
}

SV * get_refcnt(pTHX_ SV * s) {
     return newSVuv(SvREFCNT(s));
}

void Rmpq_add_z(mpq_t * rop, mpq_t * op, mpz_t * z) {
     if(rop != op) mpq_set(*rop, *op);
     mpz_addmul(mpq_numref(*rop), mpq_denref(*rop), *z);
}

void Rmpq_sub_z(mpq_t * rop, mpq_t * op, mpz_t * z) {
     if(rop != op) mpq_set(*rop, *op);
     mpz_submul(mpq_numref(*rop), mpq_denref(*rop), *z);
}

void Rmpq_z_sub(mpq_t * rop, mpz_t * z, mpq_t * op) {
     if(rop != op) mpq_set(*rop, *op);
     mpz_submul(mpq_numref(*rop), mpq_denref(*rop), *z);
     mpz_neg(mpq_numref(*rop), mpq_numref(*rop));
}

void Rmpq_mul_z(mpq_t * rop, mpq_t * op, mpz_t * z) {
     if(rop != op) mpq_set(*rop, *op);
     mpz_mul(mpq_numref(*rop), mpq_numref(*rop), *z);
     mpq_canonicalize(*rop);
}

void Rmpq_div_z(mpq_t * rop, mpq_t * op, mpz_t * z) {
     if(!mpz_cmp_ui(*z, 0))
       croak("Division by 0 not allowed in Math::GMPq::Rmpq_div_z");
     if(rop != op) mpq_set(*rop, *op);
     mpz_mul(mpq_denref(*rop), mpq_denref(*rop), *z);
     mpq_canonicalize(*rop);
}

void Rmpq_z_div(mpq_t * rop, mpz_t * z, mpq_t * op) {
     if(!mpq_cmp_ui(*op, 0, 1))
       croak("Division by 0 not allowed in Math::GMPq::Rmpq_z_div");
     if(rop != op) mpq_set(*rop, *op);
     mpq_inv(*rop, *rop);
     mpz_mul(mpq_numref(*rop), mpq_numref(*rop), *z);
     mpq_canonicalize(*rop);
}

void Rmpq_pow_ui(mpq_t * rop, mpq_t * op, unsigned long ui) {
     mpz_pow_ui(mpq_numref(*rop), mpq_numref(*op), ui);
     mpz_pow_ui(mpq_denref(*rop), mpq_denref(*op), ui);
}

/* Also handles UV values */
void Rmpq_set_IV(pTHX_ mpq_t * a, SV * my_iv1, SV * my_iv2) {
     mpq_t temp;

     if(SV_IS_IOK(my_iv1) && SV_IS_IOK(my_iv2)) {
       mpq_init(temp);

#ifdef MATH_GMPQ_NEED_LONG_LONG_INT
       mpq_set_str(*a,   SvPV_nolen(my_iv1), 10);
       mpq_set_str(temp, SvPV_nolen(my_iv2), 10);
       mpq_div(*a, *a, temp);

#else
       if(SvUOK(my_iv1)) mpq_set_ui(*a, SvUVX(my_iv1), SvUV(my_iv2));
       else mpq_set_si(*a, SvIVX(my_iv1), SvUV(my_iv2));

#endif
       mpq_clear(temp);
     }

     else croak("Arg provided to Rmpq_set_IV not an IV");
}

int Rmpq_cmp_IV(pTHX_ mpq_t * q, SV * iv1, SV * iv2) {
    mpq_t temp;
    int ret;

    if(!SvIOK(iv1) || !SvIOK(iv2))
      croak("Arg provided to Rmpq_cmp_IV is not an IV");

    mpq_init(temp);

    Rmpq_set_IV(aTHX_ &temp, iv1, iv2);
    ret = mpq_cmp(*q, temp);

    mpq_clear(temp);
    return ret;
}

/* Finish typemapping - typemap 1st arg only */

SV * _overload_mul(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     const char * h;
     int object = 0;
     PERL_UNUSED_ARG(third);

     if(sv_isobject(b)) {
       object = 1;
       h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) { /* will return */
         _overload_callback("Math::MPFR::overload_mul", "Math::GMPq::overload_mul", newSViv(0));
       }
     }

     /* create new object */
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_mul function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);

     if(SV_IS_IOK(b)) {
       Rmpq_set_IV(aTHX_ mpq_t_obj, b, newSViv(1));
       mpq_mul(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       if(mpq_set_str(*mpq_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_mul");
       mpq_canonicalize(*mpq_t_obj);
       mpq_mul(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

       Rmpq_set_NV(aTHX_ mpq_t_obj, b);

       mpq_mul(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(object) {
       if(strEQ(h, "Math::GMPq")) {
         mpq_mul(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         Rmpq_mul_z(mpq_t_obj, INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_mul");
}

void Rmpq_and (mpq_t * rop, mpq_t * a, mpq_t * b) {
     mpz_t az, bz;
     mpz_init(az);
     mpz_init(bz);

     mpz_set_q( az, *a );
     mpz_set_q( bz, *b );
     mpz_and  ( az, az, bz );

     mpq_set_z(*rop, az);
     mpz_clear(az);
     mpz_clear(bz);
}

void Rmpq_ior (mpq_t * rop, mpq_t * a, mpq_t * b) {
     mpz_t az, bz;
     mpz_init(az);
     mpz_init(bz);

     mpz_set_q( az, *a );
     mpz_set_q( bz, *b );
     mpz_ior  ( az, az, bz );

     mpq_set_z(*rop, az);
     mpz_clear(az);
     mpz_clear(bz);
}

void Rmpq_xor (mpq_t * rop, mpq_t * a, mpq_t * b) {
     mpz_t az, bz;
     mpz_init(az);
     mpz_init(bz);

     mpz_set_q( az, *a );
     mpz_set_q( bz, *b );
     mpz_xor  ( az, az, bz );

     mpq_set_z(*rop, az);
     mpz_clear(az);
     mpz_clear(bz);
}

void Rmpq_com (mpq_t * rop, mpq_t * a) {
     mpz_t az;
     mpz_init(az);

     mpz_set_q( az, *a );
     mpz_com  (az, az);
     mpq_set_z(*rop, az);
     mpz_clear(az);
}

SV * _overload_add(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     int object = 0;
     PERL_UNUSED_ARG(third);

     if(sv_isobject(b)) {
       object = 1;
       h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) { /* will return */
         _overload_callback("Math::MPFR::overload_add", "Math::GMPq::overload_add", newSViv(0));
       }
     }

     /* create new object */
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_add function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);

     if(SV_IS_IOK(b)) {
       Rmpq_set_IV(aTHX_ mpq_t_obj, b, newSViv(1));
       mpq_add(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       if(mpq_set_str(*mpq_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_add");
       mpq_canonicalize(*mpq_t_obj);
       mpq_add(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

       Rmpq_set_NV(aTHX_ mpq_t_obj, b);

       mpq_add(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(object) {
       if(strEQ(h, "Math::GMPq")) {
         mpq_add(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         Rmpq_add_z(mpq_t_obj, INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_add");
}

SV * _overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     int object = 0;

     if(sv_isobject(b)) {
       object = 1;
       h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) { /* will return */
         _overload_callback("Math::MPFR::overload_sub", "Math::GMPq::overload_sub", &PL_sv_yes);
       }
     }

     /* create new object */
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_sub function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);

     if(SV_IS_IOK(b)) {
       Rmpq_set_IV(aTHX_ mpq_t_obj, b, newSViv(1));
       if(SWITCH_ARGS) mpq_sub(*mpq_t_obj, *mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))));
       else mpq_sub(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       if(mpq_set_str(*mpq_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_sub");
       mpq_canonicalize(*mpq_t_obj);
       if(SWITCH_ARGS) mpq_sub(*mpq_t_obj, *mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))));
       else mpq_sub(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

       Rmpq_set_NV(aTHX_ mpq_t_obj, b);

       if(SWITCH_ARGS) mpq_sub(*mpq_t_obj, *mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))));
       else mpq_sub(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(object) {
       if(strEQ(h, "Math::GMPq")) {
         mpq_sub(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         if(SWITCH_ARGS) {
           Rmpq_z_sub(mpq_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(b))), INT2PTR(mpq_t *, SvIVX(SvRV(a))));
         }
         else {
           Rmpq_sub_z(mpq_t_obj, INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         }
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_sub function");

}

SV * _overload_div(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     const char *h;
     int object = 0;

     if(sv_isobject(b)) {
       object = 1;
       h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {      /* will return */
         /* divby0 is allowed here */
         _overload_callback("Math::MPFR::overload_div", "Math::GMPq::overload_div", &PL_sv_yes);
       }
     }

     /* create new object */
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_div function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);

     if(SV_IS_IOK(b)) {
       if(SvIV(b) == 0)
         croak("Division by 0 not allowed in Math::GMPq::overload_div");
       Rmpq_set_IV(aTHX_ mpq_t_obj, b, newSViv(1));
       if(SWITCH_ARGS) mpq_div(*mpq_t_obj, *mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))));
       else mpq_div(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       if(mpq_set_str(*mpq_t_obj, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_div");
       mpq_canonicalize(*mpq_t_obj);
       if(!mpq_cmp_ui(*mpq_t_obj, 0, 1))
         croak("Division by 0 not allowed in Math::GMPq::overload_div");
       if(SWITCH_ARGS) mpq_div(*mpq_t_obj, *mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))));
       else mpq_div(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

       if(SvNV(b) == 0)
         croak("Division by 0 not allowed in Math::GMPq::overload_div");

       /* If SvNV(b) is Inf or Nan, this will be caught by Rmpq_set_NV */

       Rmpq_set_NV(aTHX_ mpq_t_obj, b);

       if(SWITCH_ARGS) mpq_div(*mpq_t_obj, *mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))));
       else mpq_div(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *mpq_t_obj);
       return obj_ref;
     }

     if(object) {
       if(strEQ(h, "Math::GMPq")) {
         if(!mpq_cmp_ui(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), 0, 1))
           croak("Division by 0 not allowed in Math::GMPq::overload_div");
         mpq_div(*mpq_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         if(SWITCH_ARGS) {
           /* Rmpq_z_div will catch divby0 */
           Rmpq_z_div(mpq_t_obj, INT2PTR(mpz_t *, SvIVX(SvRV(b))), INT2PTR(mpq_t *, SvIVX(SvRV(a))));
         }
         else {
           /* Rmpq_z_div will catch divby0 */
           Rmpq_div_z(mpq_t_obj, INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         }
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_div function");

}

SV * overload_string(pTHX_ mpq_t * p, SV * second, SV * third) {
     char * out;
     SV * outsv;
     PERL_UNUSED_ARG2(second, third);

     New(123, out, mpz_sizeinbase(mpq_numref(*p), 10) + mpz_sizeinbase(mpq_denref(*p), 10) + 3, char);
     if(out == NULL) croak ("Failed to allocate memory in overload_string function");

     mpq_get_str(out, 10, *p);
     outsv = newSVpv(out, 0);
     Safefree(out);
     return outsv;
}

NV _mpf_get_float128(mpf_t * x) {

#if defined(USE_QUADMATH)
     mpf_t t;
     long i, exp, retract = 0, bits = 113;
     char *out;
     __float128 ret = 0.0Q, sign = 1.0Q;
     __float128 add_on[113] = {
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

     mpf_init2(t, mpf_get_prec(*x));
     mpf_set(t, *x);

     Newxz(out, mpf_get_prec(t) + 2, char);
     if(out == NULL) croak("Failed to allocate memory in _mpf_get_float128 function");

     mpf_get_str(out, &exp, 2, mpf_get_prec(t), t);

     mpf_clear(t);

     if(exp < -16493) {
       Safefree(out);
       return 0.0Q;
     }

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

     if(exp > -16494 && exp < -16381)
       bits = exp + 16494;

     for(i = 0; i < bits; i++) {
       if(out[i] == '1') ret += add_on[i];
       if(out[i] == 0) break; /* end of string */
     }

     if(retract) out--;
     Safefree(out);

     /* re-using the 'i' variable */
     i = exp < -16381 ? exp + 16381 : 0;	/* function has already returned if exp < -16493 */

     if(i) { 				/* powq(2.0Q, exp) will be zero - so do the calculation in 2 steps */
       ret *= powq(2.0Q, i);
       exp -= i;			/* exp += abs(i) */
     }

     ret *= powq(2.0Q, exp - 113);
     return ret * sign;

#else
     PERL_UNUSED_ARG(x);
     croak("_mpf_get_float128 not implemented for this build of Math::GMPq");

#endif

}

int _rndaz(char *a, IV exponent, UV prec, int display) {
  size_t len, i, ulp_pos = ULP_INDEX;
  PERL_UNUSED_ARG(prec);

  if(exponent < LOW_SUBNORMAL_EXP) return 0;

  if(exponent < HIGH_SUBNORMAL_EXP) ulp_pos -= HIGH_SUBNORMAL_EXP - exponent;

  len = strlen(a);

  if(a[0] == '-' || a[0] == '+') ++ulp_pos;

  if(len <= ulp_pos + 1) return 0;          /* no rounding required */

  if(display) printf("len: %u ULP index: %d\n", (unsigned int)len, (int)ulp_pos);

  if(a[ulp_pos + 1] == '0') return 0;       /* no rounding required */

  /* will get to here only if a[ulp_pos + 1] == '1' */

  if(a[ulp_pos] == '1') return 1; /* rnda */

  if(len > ulp_pos + 2) {

    for(i = ulp_pos + 2; i < len; ++i) {
      if(a[i] == '1') return 1;         /* rnda */
    }
  }

  return 0;                             /* no rounding required */
}

double _mpf_get_d_rndn(mpf_t * p) {
  char * buf;
  mp_exp_t exponent;
  size_t n_digits;
  mpf_t temp, dbl_min;
  double d;

  n_digits = (size_t)mpf_get_prec(*p);

  Newxz(buf, n_digits + 2, char);

  mpf_get_str(buf, &exponent, 2, n_digits, *p);

  /* printf("exponent: %d\n", exponent); */

  if(_rndaz(buf, (IV)exponent, (UV)n_digits, 0)) {
    /* printf("ROUNDING AWAY FROM ZERO\n"); */
    Safefree(buf);
    mpf_init2(temp, (mp_bitcnt_t)n_digits);
    mpf_set_ui(temp, 1);
    if(exponent <= 53) mpf_div_2exp(temp, temp, 53 - exponent);
    else mpf_mul_2exp(temp, temp, exponent - 53);

    /***********************************************

    For the (subnormal) exponent range -1074 ..-1021, rounding away
    from zero will be achieved by simply adding the smallest
    representable (subnormal) value (0.1e-1073)

    ***********************************************/

    if(exponent < -1021 && exponent > -1075) { /* handle subnormal doubles */
      mpf_init2(dbl_min, 64);
      mpf_set_ui(dbl_min, 1);

      mpf_div_2exp(dbl_min, dbl_min, 1074); /*********************************
                                             dbl_min set to smallest non-zero
                                             positive (subnormal) value
                                             ********************************/

      if(mpf_sgn(*p) > 0) mpf_add(temp, *p, dbl_min);
      else mpf_sub(temp, *p, dbl_min);
      mpf_clear(dbl_min);
    }
    else { /* handle normal doubles */
      if(mpf_sgn(*p) > 0) mpf_add(temp, *p, temp);
      else mpf_sub(temp, *p, temp);
    }

    d = mpf_get_d(temp);
    mpf_clear(temp);
    return d;
  }

  Safefree(buf);
  return mpf_get_d(*p);

}

NV _mpf_get_ld(mpf_t * x) {

/* we replicate rounding towards zero because this is what mpf_get_d does */

#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
#if REQUIRED_LDBL_MANT_DIG == 2098

     double msd, lsd;
     long double ret;
     mpf_t t, d;

     msd = _mpf_get_d_rndn(x);

     if(msd == 0.0 || msd != msd || msd / msd != 1)
       return (long double)msd;

     if(mpf_get_prec(*x) > 2112) mpf_init2(t, mpf_get_prec(*x));
     else mpf_init2(t, 2112);
     mpf_set(t, *x);

     mpf_init2(d, 64);
     mpf_set_d(d, msd);

     mpf_sub(t, t, d);
     mpf_clear(d);

     lsd = mpf_get_d(t); /* round to zero for least siginificant double only */

     mpf_clear(t);

     ret = (long double)msd + lsd;

     /* return newSVnv(ret); */
     return ret;

#else

     mpf_t t;
     long i, exp, retract = 0, bits = REQUIRED_LDBL_MANT_DIG;
     char *out;
     long double ret = 0.0L, sign = 1.0L;
     long double add_on[113] = {
      5192296858534827628530496329220096e0L, 2596148429267413814265248164610048e0L,
      1298074214633706907132624082305024e0L, 649037107316853453566312041152512e0L,
      324518553658426726783156020576256e0L, 162259276829213363391578010288128e0L,
      81129638414606681695789005144064e0L, 40564819207303340847894502572032e0L,
      20282409603651670423947251286016e0L, 10141204801825835211973625643008e0L,
      5070602400912917605986812821504e0L, 2535301200456458802993406410752e0L,
      1267650600228229401496703205376e0L, 633825300114114700748351602688e0L,
      316912650057057350374175801344e0L, 158456325028528675187087900672e0L, 79228162514264337593543950336e0L,
      39614081257132168796771975168e0L, 19807040628566084398385987584e0L, 9903520314283042199192993792e0L,
      4951760157141521099596496896e0L, 2475880078570760549798248448e0L, 1237940039285380274899124224e0L,
      618970019642690137449562112e0L, 309485009821345068724781056e0L, 154742504910672534362390528e0L,
      77371252455336267181195264e0L, 38685626227668133590597632e0L, 19342813113834066795298816e0L,
      9671406556917033397649408e0L, 4835703278458516698824704e0L, 2417851639229258349412352e0L,
      1208925819614629174706176e0L, 604462909807314587353088e0L, 302231454903657293676544e0L,
      151115727451828646838272e0L, 75557863725914323419136e0L, 37778931862957161709568e0L,
      18889465931478580854784e0L, 9444732965739290427392e0L, 4722366482869645213696e0L,
      2361183241434822606848e0L, 1180591620717411303424e0L, 590295810358705651712e0L, 295147905179352825856e0L,
      147573952589676412928e0L, 73786976294838206464e0L, 36893488147419103232e0L, 18446744073709551616e0L,
      9223372036854775808e0L, 4611686018427387904e0L, 2305843009213693952e0L, 1152921504606846976e0L,
      576460752303423488e0L, 288230376151711744e0L, 144115188075855872e0L, 72057594037927936e0L,
      36028797018963968e0L, 18014398509481984e0L, 9007199254740992e0L, 4503599627370496e0L,
      2251799813685248e0L, 1125899906842624e0L, 562949953421312e0L, 281474976710656e0L, 140737488355328e0L,
      70368744177664e0L, 35184372088832e0L, 17592186044416e0L, 8796093022208e0L, 4398046511104e0L,
      2199023255552e0L, 1099511627776e0L, 549755813888e0L, 274877906944e0L, 137438953472e0L, 68719476736e0L,
      34359738368e0L, 17179869184e0L, 8589934592e0L, 4294967296e0L, 2147483648e0L, 1073741824e0L, 536870912e0L,
      268435456e0L, 134217728e0L, 67108864e0L, 33554432e0L, 16777216e0L, 8388608e0L, 4194304e0L, 2097152e0L,
      1048576e0L, 524288e0L, 262144e0L, 131072e0L, 65536e0L, 32768e0L, 16384e0L, 8192e0L, 4096e0L, 2048e0L,
      1024e0L, 512e0L, 256e0L, 128e0L, 64e0L, 32e0L, 16e0L, 8e0L, 4e0L, 2e0L, 1e0L };

     mpf_init2(t, mpf_get_prec(*x));
     mpf_set(t, *x);

     Newxz(out, mpf_get_prec(t) + 2, char);
     if(out == NULL) croak("Failed to allocate memory in _mpf_get_ld function");

     mpf_get_str(out, &exp, 2, mpf_get_prec(t), t);

     if(exp < LOW_SUBNORMAL_EXP + 1) {
       PERL_UNUSED_ARG(x);
       Safefree(out);
       return 0.0L;
     }

     mpf_clear(t);

     if(out[0] == '-') {
       sign = -1.0L;
       out++;
       retract++;
     }
     else {
       if(out[0] == '+') {
         out++;
         retract++;
       }
     }

     if(exp > LOW_SUBNORMAL_EXP && exp < HIGH_SUBNORMAL_EXP)
       bits = exp - LOW_SUBNORMAL_EXP;

     for(i = 0; i < bits; i++) {
       if(out[i] == '1') ret += add_on[i];
       if(out[i] == 0) break; /* end of string */
     }

     if(retract) out--;
     Safefree(out);

     i = HIGH_SUBNORMAL_EXP + 113 - REQUIRED_LDBL_MANT_DIG;

     /* re-using the 'bits' variable */
     bits = exp < i ? exp - i : 0;	/* function has already returned if exp < low_subnormal_exp */

     if(bits) { 			/* powl(2.0L, exp) will be zero - so do the calculation in 2 steps */
       ret *= powl(2.0L, bits);
       exp -= bits;			/* exp += abs(bits) */
     }

     ret *= powl(2.0L, exp - 113);
     /* return newSVnv(ret * sign); */
     return ret * sign;

#endif
#else
     PERL_UNUSED_ARG(x);
     croak("_mpf_get_ld not implemented for this build of Math::GMPq");

#endif

}

SV * Rmpq_get_NV(pTHX_ mpq_t * x) {
     mpf_t t;
     NV ret;

#if defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098
     mpf_init2(t, 2098);
#else
     mpf_init2(t, 128);
#endif
     mpf_set_q(t, *x) ;

#if defined(USE_QUADMATH)
     ret = (NV)_mpf_get_float128(&t);
#elif defined(USE_LONG_DOUBLE)
     ret = (NV)_mpf_get_ld(&t);
#else
     ret = (NV)mpf_get_d(t);
#endif
     mpf_clear(t);

     return newSVnv(ret);
}

SV * overload_num(pTHX_ mpq_t * p, SV * second, SV * third) {
     PERL_UNUSED_ARG2(second, third);
  return Rmpq_get_NV(aTHX_ p);
}

SV * overload_copy(pTHX_ mpq_t * p, SV * second, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_copy function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");

     mpq_init(*mpq_t_obj);
     mpq_set(*mpq_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * overload_abs(pTHX_ mpq_t * p, SV * second, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_abs function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);

     mpq_abs(*mpq_t_obj, *p);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_gt(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret;

     if(SV_IS_IOK(b)) {
       ret = Rmpq_cmp_IV(aTHX_ a, b, newSViv(1));
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(0);
         return newSViv(1);
       }
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_gt");
       mpq_canonicalize(t);
       ret = mpq_cmp(*a, t);
       mpq_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpq_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         ret = mpq_cmp(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         ret = Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
#endif
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_gt");
}

SV * _overload_gte(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret;

     if(SV_IS_IOK(b)) {
       ret = Rmpq_cmp_IV(aTHX_ a, b, newSViv(1));
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(0);
         return newSViv(1);
       }
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_gte");
       mpq_canonicalize(t);
       ret = mpq_cmp(*a, t);
       mpq_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpq_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         ret = mpq_cmp(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         ret = Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
#endif
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_gte");
}

SV * _overload_lt(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret;

     if(SV_IS_IOK(b)) {
       ret = Rmpq_cmp_IV(aTHX_ a, b, newSViv(1));
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_lt");
       mpq_canonicalize(t);
       ret = mpq_cmp(*a, t);
       mpq_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpq_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         ret = mpq_cmp(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         ret = Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
#endif
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_lt");
}

SV * _overload_lte(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret;

     if(SV_IS_IOK(b)) {
       ret = Rmpq_cmp_IV(aTHX_ a, b, newSViv(1));
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_lte");
       mpq_canonicalize(t);
       ret = mpq_cmp(*a, t);
       mpq_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpq_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         ret = mpq_cmp(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         ret = Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
#else
         ret = mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
#endif
       }

     }

     croak("Invalid argument supplied to Math::GMPq::overload_lte");
}

SV * _overload_spaceship(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret;

     if(SV_IS_IOK(b)) {
       ret = Rmpq_cmp_IV(aTHX_ a, b, newSViv(1));
       if(SWITCH_ARGS) ret *= -1;
       return newSViv(ret);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       ret = _is_infstring(SvPV_nolen(b));
       if(ret) {
         if(ret > 0) return newSViv(-1);
         return newSViv(1);
       }
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_spaceship");
       mpq_canonicalize(t);
       ret = mpq_cmp(*a, t);
       mpq_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = Rmpq_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       return newSViv(ret);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         ret = mpq_cmp(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return newSViv(ret);
       }
       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         ret = Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return newSViv(ret);
#else
         ret = mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         return newSViv(ret);
#endif
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_spaceship");
}

SV * _overload_equiv(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret = 0;
     PERL_UNUSED_ARG(third);

     if(SV_IS_IOK(b)) {
       if(Rmpq_cmp_IV(aTHX_ a, b, newSViv(1))) return newSViv(0);
       return newSViv(1);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       if(_is_infstring(SvPV_nolen(b))) return newSViv(0);
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_equiv");
       mpq_canonicalize(t);
       ret = mpq_equal(*a, t);
       mpq_clear(t);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       if(Rmpq_cmp_NV(aTHX_ a, b)) return newSViv(0);
       return newSViv(1);
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         return newSViv(mpq_equal(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b))))));
       }

       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         if(Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))))) return newSViv(0);
         return newSViv(1);
#else
         if(mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))))) return newSViv(0);
         return newSViv(1);
#endif
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_equiv");
}

SV * _overload_not_equiv(pTHX_ mpq_t * a, SV * b, SV * third) {
     mpq_t t;
     int ret = 0;
     PERL_UNUSED_ARG(third);


     if(SV_IS_IOK(b)) {
       if(Rmpq_cmp_IV(aTHX_ a, b, newSViv(1))) return newSViv(1);
       return newSViv(0);
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       if(_is_infstring(SvPV_nolen(b))) return newSViv(1);
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0))
         croak("Invalid string supplied to Math::GMPq::overload_not_equiv");
       mpq_canonicalize(t);
       ret = mpq_equal(*a, t);
       mpq_clear(t);
       if(ret) return newSViv(0);
       return newSViv(1);
     }

     if(SV_IS_NOK(b)) {
       if(Rmpq_cmp_NV(aTHX_ a, b)) return newSViv(1);
       return newSViv(0);
     }


     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::GMPq")) {
         ret = mpq_equal(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret) return newSViv(0);
         return newSViv(1);
       }

       if(strEQ(h, "Math::GMPz")) {
#if __GNU_MP_RELEASE < 60099
         if(Rmpq_cmp_z(a, INT2PTR(mpz_t *, SvIVX(SvRV(b))))) return newSViv(1);
         return newSViv(0);
#else
         if(mpq_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))))) return newSViv(1);
         return newSViv(0);
#endif
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_not_equiv");
}

SV * overload_not(pTHX_ mpq_t * a, SV * second, SV * third) {
     PERL_UNUSED_ARG2(second, third);
     if(mpq_cmp_ui(*a, 0, 1)) return newSViv(0);
     return newSViv(1);
}

SV * overload_int(pTHX_ mpq_t * p, SV * second, SV * third) {
     mpz_t z;
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     PERL_UNUSED_ARG2(second, third);

     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_int function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);

     if( !mpz_cmp_ui(mpq_denref(*p), 1) ) {
       mpq_set(*mpq_t_obj, *p);
     }
     else {
       mpz_init(z);
       mpz_set_q(z, *p);
       mpq_set_z(*mpq_t_obj, z);
       mpz_clear(z);
     }

     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_lshift(pTHX_ mpq_t * p, SV * ls, SV * third) {
     mpz_t z;
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;

     PERL_UNUSED_ARG(third);

     CHECK_MP_BITCNT_T_OVERFLOW(ls)
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_int function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);

     mpz_init(z);
     mpz_set_q(z, *p);
     mpz_mul_2exp(z, z, (mp_bitcnt_t)SvUV(ls)); /* ls is always >= 0 */
     mpq_set_z(*mpq_t_obj, z);
     mpz_clear(z);

     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_lshift_eq(pTHX_ SV * p, SV * ls, SV * third) {
     mpz_t z;

     PERL_UNUSED_ARG(third);

     CHECK_MP_BITCNT_T_OVERFLOW(ls)
     SvREFCNT_inc(p);
     mpz_init(z);
     mpz_set_q(z, *(INT2PTR(mpq_t *, SvIVX(SvRV(p)))));
     mpz_mul_2exp(z, z, (mp_bitcnt_t)SvUV(ls));  /* ls is always >= 0 */
     mpq_set_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(p)))), z);
     mpz_clear(z);

     return p;
}

SV * _overload_rshift(pTHX_ mpq_t * p, SV * rs, SV * third) {
     mpz_t z;
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;

     PERL_UNUSED_ARG(third);

     CHECK_MP_BITCNT_T_OVERFLOW(rs)
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_int function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);

     mpz_init(z);
     mpz_set_q(z, *p);
     mpz_div_2exp(z, z, (mp_bitcnt_t)SvUV(rs));  /* rs is always >= 0 */
     mpq_set_z(*mpq_t_obj, z);
     mpz_clear(z);

     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * _overload_rshift_eq(pTHX_ SV * p, SV * rs, SV * third) {
     mpz_t z;

     PERL_UNUSED_ARG(third);

     CHECK_MP_BITCNT_T_OVERFLOW(rs)
     SvREFCNT_inc(p);
     mpz_init(z);
     mpz_set_q(z, *(INT2PTR(mpq_t *, SvIVX(SvRV(p)))));
     mpz_div_2exp(z, z, (mp_bitcnt_t)SvUV(rs));  /* rs is always >= 0 */
     mpq_set_z(*(INT2PTR(mpq_t *, SvIVX(SvRV(p)))), z);
     mpz_clear(z);

     return p;
}

/* Finish typemapping */

SV * _overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t t;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       mpq_init(t);
       Rmpq_set_IV(aTHX_ &t, b, newSViv(1));
       mpq_mul(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string supplied to Math::GMPq::overload_mul_eq");
       }
       mpq_canonicalize(t);
       mpq_mul(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

       mpq_init(t);
       Rmpq_set_NV(aTHX_ &t, b);
       mpq_mul(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::GMPq")) {
         mpq_mul(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         Rmpq_mul_z(INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return a;
       }

       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_mul", "Math::GMPq::overload_mul", newSViv(0));
       }

     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPq::overload_mul_eq");

}

SV * _overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t t;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       mpq_init(t);
       Rmpq_set_IV(aTHX_ &t, b, newSViv(1));
       mpq_add(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string supplied to Math::GMPq::overload_add_eq");
       }
       mpq_canonicalize(t);
       mpq_add(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {
       mpq_init(t);
       Rmpq_set_NV(aTHX_ &t, b);
       mpq_add(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::GMPq")) {
         mpq_add(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         Rmpq_add_z(INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return a;
       }

       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_add", "Math::GMPq::overload_add", newSViv(0));
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPq::overload_add_eq");
}

SV * _overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t t;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       mpq_init(t);
       Rmpq_set_IV(aTHX_ &t, b, newSViv(1));
       mpq_sub(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string supplied to Math::GMPq::overload_sub_eq");
       }
       mpq_canonicalize(t);
       mpq_sub(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

       mpq_init(t);
       Rmpq_set_NV(aTHX_ &t, b);
       mpq_sub(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::GMPq")) {
         mpq_sub(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         Rmpq_sub_z(INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return a;
       }

       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_sub", "Math::GMPq::overload_sub", &PL_sv_yes);
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPq::overload_sub_eq function");

}

SV * _overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t t;
     PERL_UNUSED_ARG(third);

     SvREFCNT_inc(a);

     if(SV_IS_IOK(b)) {
       if(SvIV(b) == 0)
         croak("Division by 0 not allowed in Math::GMPq::overload_div_eq");
       mpq_init(t);
       Rmpq_set_IV(aTHX_ &t, b, newSViv(1));
       mpq_div(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

#if defined(GMPQ_PV_NV_BUG)
     if( (SV_IS_POK(b) && !SV_IS_NOK(b))
           ||
         (SV_IS_POK(b) && SV_IS_NOK(b) && SvIOKp(b)) ) {
#else
     if(SV_IS_POK(b)) {
#endif
       mpq_init(t);
       if(mpq_set_str(t, SvPV_nolen(b), 0)) {
         SvREFCNT_dec(a);
         croak("Invalid string supplied to Math::GMPq::overload_div_eq");
       }
       mpq_canonicalize(t);
       if(!mpq_cmp_ui(t, 0, 1))
         croak("Division by 0 not allowed in Math::GMPq::overload_div_eq");
       mpq_div(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

       if(SvNV(b) == 0)
         croak("Division by 0 not allowed in Math::GMPq::overload_div_eq");

       /* If SvNV(b) is Inf or Nan, this will be caught by Rmpq_set_NV */

       mpq_init(t);
       Rmpq_set_NV(aTHX_ &t, b);
       mpq_div(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);
       mpq_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::GMPq")) {
         if(!mpq_cmp_ui(*(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), 0, 1))
           croak("Division by 0 not allowed in Math::GMPq::overload_div_eq");
         mpq_div(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         return a;
       }

       if(strEQ(h, "Math::GMPz") || strEQ(h, "Math::GMP")) {
         /* Rmpq_div_z will catch divby0 */
         Rmpq_div_z(INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpz_t *, SvIVX(SvRV(b))));
         return a;
       }

       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_div", "Math::GMPq::overload_div", &PL_sv_yes);
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPq::overload_div_eq function");

}

SV * _overload_pow_eq(pTHX_ SV * a, SV * b, SV * third) {
     PERL_UNUSED_ARG(third);
     SvREFCNT_inc(a);
     if(SvUOK(b) || (SV_IS_IOK(b) && SvIVX(b) >= 0)) {
       Rmpq_pow_ui(INT2PTR(mpq_t *, SvIVX(SvRV(a))), INT2PTR(mpq_t *, SvIVX(SvRV(a))), (unsigned long)SvUVX(b));
       return a;
     }

     if(sv_isobject(b)) {
       const char *h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_pow", "Math::GMPq::overload_pow", &PL_sv_yes);
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::GMPq::overload_pow_eq function");
}

SV * gmp_v(pTHX) {
#if __GNU_MP_VERSION >= 4
     return newSVpv(gmp_version, 0);
#else
     warn("From Math::GMPq::gmp_v(aTHX): 'gmp_version' is not implemented - returning '0'");
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

       croak("Unrecognised object supplied as argument to Rmpq_printf");
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

     croak("Unrecognised type supplied as argument to Rmpq_printf");
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

       else croak("Unrecognised object supplied as argument to Rmpq_fprintf");
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

     croak("Unrecognised type supplied as argument to Rmpq_fprintf");
}

SV * wrap_gmp_sprintf(pTHX_ SV * s, SV * a, SV * b, int buflen) {
     int ret;
     char * stream;

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

       Safefree(stream); /* In case the ensuing croak() is encased in an eval{} block */
       croak("Unrecognised object supplied as argument to Rmpq_sprintf");
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

     Safefree(stream); /* In case the ensuing croak() is encased in an eval{} block */
     croak("Unrecognised type supplied as argument to Rmpq_sprintf");
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

       Safefree(stream); /* In case the ensuing croak() is encased in an eval{} block */
       croak("Unrecognised object supplied as argument to Rmpq_snprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvUV(b));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvIV(b));
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
       ret = gmp_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvNV(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     Safefree(stream); /* In case the ensuing croak() is encased in an eval{} block */
     croak("Unrecognised type supplied as argument to Rmpq_snprintf");
}


SV * _itsa(pTHX_ SV * a) {
  if(SV_IS_IOK(a)) {
    if(SvUOK(a)) return newSVuv(1);
    return newSVuv(2);
  }
  if(SV_IS_POK(a)) {
#if defined(GMPQ_PV_NV_BUG)        /* perl can set the POK flag when it should not */
    if(SvNOK(a) && !SvIOKp(a))
      return newSVuv(3);        /* designate it as NV */
#endif
    return newSVuv(4);          /* designate it as PV */
  }
  if(SV_IS_NOK(a)) return newSVuv(3);
  if(sv_isobject(a)) {
    const char* h = HvNAME(SvSTASH(SvRV(a)));

    if(strEQ(h, "Math::MPFR")) return newSVuv(5);
    if(strEQ(h, "Math::GMPf")) return newSVuv(6);
    if(strEQ(h, "Math::GMPq")) return newSVuv(7);
    if(strEQ(h, "Math::GMPz")) return newSVuv(8);
    if(strEQ(h, "Math::GMP")) return newSVuv(9);
  }
  return newSVuv(0);
}

int _has_longlong(void) {
#ifdef MATH_GMPQ_NEED_LONG_LONG_INT
    return 1;
#else
    return 0;
#endif
}

int _has_longdouble(void) {
#ifdef USE_LONG_DOUBLE
    return 1;
#else
    return 0;
#endif
}

/* Has inttypes.h been included ? */
int _has_inttypes(void) {

#if defined MATH_GMPQ_NEED_LONG_LONG_INT
return 1;
#else
return 0;
#endif
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

void overload_inc(pTHX_ SV * p, SV * second, SV * third) {
     mpq_t one;
     PERL_UNUSED_ARG2(second, third);

     mpq_init(one);
     mpq_set_ui(one, 1, 1);

     mpq_add(*(INT2PTR(mpq_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(p)))), one);
     mpq_clear(one);
}

void overload_dec(pTHX_ SV * p, SV * second, SV * third) {
     mpq_t one;
     PERL_UNUSED_ARG2(second, third);

     mpq_init(one);
     mpq_set_ui(one, 1, 1);

     mpq_sub(*(INT2PTR(mpq_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(p)))), one);
     mpq_clear(one);
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

SV * _overload_pow(pTHX_ SV * a, SV * b, SV * third) {
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;
     const char *h;

     if(SWITCH_ARGS) croak("Raising a value to an mpq_t power is not allowed in '**' operation in Math::GMPq::overload_pow");

     if(SvUOK(b) || (SV_IS_IOK(b) && SvIVX(b) >= 0)) {
       New(1, mpq_t_obj, 1, mpq_t);
       if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_pow function");
       obj_ref = newSV(0);
       obj = newSVrv(obj_ref, "Math::GMPq");
       mpq_init(*mpq_t_obj);
       sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
       SvREADONLY_on(obj);
       Rmpq_pow_ui(mpq_t_obj, INT2PTR(mpq_t *, SvIVX(SvRV(a))), (unsigned long)SvUVX(b));
       return obj_ref;
     }
     if(sv_isobject(b)) {
       h = HvNAME(SvSTASH(SvRV(b)));
       if(strEQ(h, "Math::MPFR")) {
         _overload_callback("Math::MPFR::overload_pow", "Math::GMPq:overload_pow", &PL_sv_yes);
       }
     }

     croak("Invalid argument supplied to Math::GMPq::overload_pow");
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

int Rmpq_integer_p(mpq_t * q) {
    if(mpz_cmp_si(mpq_denref(*q), 1)) return 0;
    return 1;
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

long _long_min(void) {
   return (long)LONG_MIN;
}

long _long_max(void) {
   return (long)LONG_MAX;
}

unsigned long _ulong_max(void) {
   return (unsigned long)ULONG_MAX;
}

int _int_min(void) {
   return (int)INT_MIN;
}

int _int_max(void) {
   return (int)INT_MAX;
}

unsigned int _uint_max(void) {
   return (unsigned int)UINT_MAX;
}

int _SvPOK(pTHX_ SV * in) {
   if(SV_IS_POK(in)) return 1;
   return 0;
}

int _required_ldbl_mant_dig(void) {
    return REQUIRED_LDBL_MANT_DIG;
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

int _has_pv_nv_bug(void) {
#if defined(GMPQ_PV_NV_BUG)
     return 1;
#else
     return 0;
#endif
}

int _looks_like_number(pTHX_ SV * in) {
  if(looks_like_number(in)) return 1;
  return 0;
}

SV * _overload_fmod (pTHX_ mpq_t * a, mpq_t *b, SV * third) {
     mpz_t z;
     mpq_t * mpq_t_obj;
     SV * obj_ref, * obj;

     mpz_init(z);

     /* create new object */
     New(1, mpq_t_obj, 1, mpq_t);
     if(mpq_t_obj == NULL) croak("Failed to allocate memory in overload_div function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, "Math::GMPq");
     mpq_init(*mpq_t_obj);
     sv_setiv(obj, INT2PTR(IV, mpq_t_obj));
     SvREADONLY_on(obj);

     if(SWITCH_ARGS) {
       mpq_div(*mpq_t_obj, *b, *a);
       mpz_set_q(z, *mpq_t_obj);
       mpq_set_z(*mpq_t_obj, z);
       mpq_mul(*mpq_t_obj, *a, *mpq_t_obj);
       mpq_sub(*mpq_t_obj, *b, *mpq_t_obj);
     }
     else {
       mpq_div(*mpq_t_obj, *a, *b);
       mpz_set_q(z, *mpq_t_obj);
       mpq_set_z(*mpq_t_obj, z);
       mpq_mul(*mpq_t_obj, *b, *mpq_t_obj);
       mpq_sub(*mpq_t_obj, *a, *mpq_t_obj);
     }
     mpz_clear(z);
     return obj_ref;
}

SV * _overload_fmod_eq (pTHX_ SV * a, mpq_t *b, SV * third) {
     mpq_t t;
     mpz_t z;

     PERL_UNUSED_ARG(third);
     SvREFCNT_inc(a);

     mpq_init(t);
     mpz_init(z);
     mpq_div(t, *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *b);
     mpz_set_q(z, t);
     mpq_set_z(t, z);
     mpq_mul(t, *b, t);
     mpq_sub(*(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(a)))), t);

     mpq_clear(t);
     mpz_clear(z);

     return a;
}

SV * _to_base(pTHX_ SV * str, int base) {
    /* Convert the value held in the string *
     * from the specified base to base 10   */

    char buf[16];
    mpz_t t;

    if(mpz_init_set_str(t, SvPV_nolen(str), base))
      croak("Exponent portion of string supplied to Rmpq_set_str function (%s) is not a valid base %d number", SvPV_nolen(str), base);
    gmp_sprintf (buf, "%Zd", t);

    mpz_clear(t);
    return newSVpv(buf, 0);
}






MODULE = Math::GMPq  PACKAGE = Math::GMPq

PROTOTYPES: DISABLE


int
_is_infstring (s)
	char *	s

void
Rmpq_canonicalize (p)
	mpq_t *	p
        PPCODE:
        Rmpq_canonicalize(p);
        XSRETURN_EMPTY; /* return empty stack */

SV *
Rmpq_init ()
CODE:
  RETVAL = Rmpq_init (aTHX);
OUTPUT:  RETVAL


SV *
Rmpq_init_nobless ()
CODE:
  RETVAL = Rmpq_init_nobless (aTHX);
OUTPUT:  RETVAL


void
DESTROY (p)
	mpq_t *	p
        PPCODE:
        DESTROY(aTHX_ p);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_clear (p)
	mpq_t *	p
        PPCODE:
        Rmpq_clear(aTHX_ p);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_clear_mpq (p)
	mpq_t *	p
        PPCODE:
        Rmpq_clear_mpq(p);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_clear_ptr (p)
	mpq_t *	p
        PPCODE:
        Rmpq_clear_ptr(aTHX_ p);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set (p1, p2)
	mpq_t *	p1
	mpq_t *	p2
        PPCODE:
        Rmpq_set(p1, p2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_swap (p1, p2)
	mpq_t *	p1
	mpq_t *	p2
        PPCODE:
        Rmpq_swap(p1, p2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_z (p1, p2)
	mpq_t *	p1
	mpz_t *	p2
        PPCODE:
        Rmpq_set_z(p1, p2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_ui (p1, p2, p3)
	mpq_t *	p1
	unsigned long	p2
	unsigned long	p3
        PPCODE:
        Rmpq_set_ui(p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_si (p1, p2, p3)
	mpq_t *	p1
	long	p2
	long	p3
        PPCODE:
        Rmpq_set_si(p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
_Rmpq_set_str (p1, p2, base)
	mpq_t *	p1
	SV *	p2
	int	base
        PPCODE:
        _Rmpq_set_str(aTHX_ p1, p2, base);
        XSRETURN_EMPTY; /* return empty stack */

double
Rmpq_get_d (p)
	mpq_t *	p

void
Rmpq_set_d (p, d)
	mpq_t *	p
	double	d
        PPCODE:
        Rmpq_set_d(p, d);
        XSRETURN_EMPTY; /* return empty stack */

void
_mpf_set_doubledouble (q, p)
	mpf_t *	q
	SV *	p
        PPCODE:
        _mpf_set_doubledouble(q, p);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_NV (copy, original)
	mpq_t *	copy
	SV *	original
        PPCODE:
        Rmpq_set_NV(aTHX_ copy, original);
        XSRETURN_EMPTY; /* return empty stack */

int
Rmpq_cmp_NV (a, b)
	mpq_t *	a
	SV *	b
CODE:
  RETVAL = Rmpq_cmp_NV (aTHX_ a, b);
OUTPUT:  RETVAL

void
Rmpq_set_f (p, f)
	mpq_t *	p
	mpf_t *	f
        PPCODE:
        Rmpq_set_f(p, f);
        XSRETURN_EMPTY; /* return empty stack */

SV *
Rmpq_get_str (p, base)
	mpq_t *	p
	int	base
CODE:
  RETVAL = Rmpq_get_str (aTHX_ p, base);
OUTPUT:  RETVAL

int
Rmpq_cmp (p1, p2)
	mpq_t *	p1
	mpq_t *	p2

int
Rmpq_cmp_ui (p1, n, d)
	mpq_t *	p1
	unsigned long	n
	unsigned long	d

int
Rmpq_cmp_si (p1, n, d)
	mpq_t *	p1
	long	n
	unsigned long	d

int
Rmpq_cmp_z (p, z)
	mpq_t *	p
	mpz_t *	z

int
Rmpq_sgn (p)
	mpq_t *	p

int
Rmpq_equal (p1, p2)
	mpq_t *	p1
	mpq_t *	p2

void
Rmpq_add (p1, p2, p3)
	mpq_t *	p1
	mpq_t *	p2
	mpq_t *	p3
        PPCODE:
        Rmpq_add(p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_sub (p1, p2, p3)
	mpq_t *	p1
	mpq_t *	p2
	mpq_t *	p3
        PPCODE:
        Rmpq_sub(p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_mul (p1, p2, p3)
	mpq_t *	p1
	mpq_t *	p2
	mpq_t *	p3
        PPCODE:
        Rmpq_mul(p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_div (p1, p2, p3)
	mpq_t *	p1
	mpq_t *	p2
	mpq_t *	p3
        PPCODE:
        Rmpq_div(p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_mul_2exp (p1, p2, p3)
	mpq_t *	p1
	mpq_t *	p2
	SV *	p3
        PPCODE:
        Rmpq_mul_2exp(aTHX_ p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_div_2exp (p1, p2, p3)
	mpq_t *	p1
	mpq_t *	p2
	SV *	p3
        PPCODE:
        Rmpq_div_2exp(aTHX_ p1, p2, p3);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_neg (p1, p2)
	mpq_t *	p1
	mpq_t *	p2
        PPCODE:
        Rmpq_neg(p1, p2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_abs (p1, p2)
	mpq_t *	p1
	mpq_t *	p2
        PPCODE:
        Rmpq_abs(p1, p2);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_inv (p1, p2)
	mpq_t *	p1
	mpq_t *	p2
        PPCODE:
        Rmpq_inv(p1, p2);
        XSRETURN_EMPTY; /* return empty stack */

SV *
_Rmpq_out_str (p, base)
	mpq_t *	p
	int	base
CODE:
  RETVAL = _Rmpq_out_str (aTHX_ p, base);
OUTPUT:  RETVAL

SV *
_Rmpq_out_strS (p, base, suff)
	mpq_t *	p
	int	base
	SV *	suff
CODE:
  RETVAL = _Rmpq_out_strS (aTHX_ p, base, suff);
OUTPUT:  RETVAL

SV *
_Rmpq_out_strP (pre, p, base)
	SV *	pre
	mpq_t *	p
	int	base
CODE:
  RETVAL = _Rmpq_out_strP (aTHX_ pre, p, base);
OUTPUT:  RETVAL

SV *
_Rmpq_out_strPS (pre, p, base, suff)
	SV *	pre
	mpq_t *	p
	int	base
	SV *	suff
CODE:
  RETVAL = _Rmpq_out_strPS (aTHX_ pre, p, base, suff);
OUTPUT:  RETVAL

SV *
_TRmpq_out_str (stream, base, p)
	FILE *	stream
	int	base
	mpq_t *	p
CODE:
  RETVAL = _TRmpq_out_str (aTHX_ stream, base, p);
OUTPUT:  RETVAL

SV *
_TRmpq_out_strS (stream, base, p, suff)
	FILE *	stream
	int	base
	mpq_t *	p
	SV *	suff
CODE:
  RETVAL = _TRmpq_out_strS (aTHX_ stream, base, p, suff);
OUTPUT:  RETVAL

SV *
_TRmpq_out_strP (pre, stream, base, p)
	SV *	pre
	FILE *	stream
	int	base
	mpq_t *	p
CODE:
  RETVAL = _TRmpq_out_strP (aTHX_ pre, stream, base, p);
OUTPUT:  RETVAL

SV *
_TRmpq_out_strPS (pre, stream, base, p, suff)
	SV *	pre
	FILE *	stream
	int	base
	mpq_t *	p
	SV *	suff
CODE:
  RETVAL = _TRmpq_out_strPS (aTHX_ pre, stream, base, p, suff);
OUTPUT:  RETVAL

SV *
TRmpq_inp_str (p, stream, base)
	mpq_t *	p
	FILE *	stream
	SV *	base
CODE:
  RETVAL = TRmpq_inp_str (aTHX_ p, stream, base);
OUTPUT:  RETVAL

SV *
Rmpq_inp_str (p, base)
	mpq_t *	p
	int	base
CODE:
  RETVAL = Rmpq_inp_str (aTHX_ p, base);
OUTPUT:  RETVAL

void
Rmpq_numref (z, r)
	mpz_t *	z
	mpq_t *	r
        PPCODE:
        Rmpq_numref(z, r);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_denref (z, r)
	mpz_t *	z
	mpq_t *	r
        PPCODE:
        Rmpq_denref(z, r);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_get_num (z, r)
	mpz_t *	z
	mpq_t *	r
        PPCODE:
        Rmpq_get_num(z, r);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_get_den (z, r)
	mpz_t *	z
	mpq_t *	r
        PPCODE:
        Rmpq_get_den(z, r);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_num (r, z)
	mpq_t *	r
	mpz_t *	z
        PPCODE:
        Rmpq_set_num(r, z);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_den (r, z)
	mpq_t *	r
	mpz_t *	z
        PPCODE:
        Rmpq_set_den(r, z);
        XSRETURN_EMPTY; /* return empty stack */

SV *
get_refcnt (s)
	SV *	s
CODE:
  RETVAL = get_refcnt (aTHX_ s);
OUTPUT:  RETVAL

void
Rmpq_add_z (rop, op, z)
	mpq_t *	rop
	mpq_t *	op
	mpz_t *	z
        PPCODE:
        Rmpq_add_z(rop, op, z);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_sub_z (rop, op, z)
	mpq_t *	rop
	mpq_t *	op
	mpz_t *	z
        PPCODE:
        Rmpq_sub_z(rop, op, z);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_z_sub (rop, z, op)
	mpq_t *	rop
	mpz_t *	z
	mpq_t *	op
        PPCODE:
        Rmpq_z_sub(rop, z, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_mul_z (rop, op, z)
	mpq_t *	rop
	mpq_t *	op
	mpz_t *	z
        PPCODE:
        Rmpq_mul_z(rop, op, z);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_div_z (rop, op, z)
	mpq_t *	rop
	mpq_t *	op
	mpz_t *	z
        PPCODE:
        Rmpq_div_z(rop, op, z);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_z_div (rop, z, op)
	mpq_t *	rop
	mpz_t *	z
	mpq_t *	op
        PPCODE:
        Rmpq_z_div(rop, z, op);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_pow_ui (rop, op, ui)
	mpq_t *	rop
	mpq_t *	op
	unsigned long	ui
        PPCODE:
        Rmpq_pow_ui(rop, op, ui);
        XSRETURN_EMPTY; /* return empty stack */

void
Rmpq_set_IV (a, my_iv1, my_iv2)
	mpq_t *	a
	SV *	my_iv1
	SV *	my_iv2
        PPCODE:
        Rmpq_set_IV(aTHX_ a, my_iv1, my_iv2);
        XSRETURN_EMPTY; /* return empty stack */

int
Rmpq_cmp_IV (q, iv1, iv2)
	mpq_t *	q
	SV *	iv1
	SV *	iv2
CODE:
  RETVAL = Rmpq_cmp_IV (aTHX_ q, iv1, iv2);
OUTPUT:  RETVAL

SV *
_overload_mul (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_mul (aTHX_ a, b, third);
OUTPUT:  RETVAL

void
Rmpq_and (rop, a, b)
	mpq_t *	rop
	mpq_t *	a
	mpq_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpq_and(rop, a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
Rmpq_ior (rop, a, b)
	mpq_t *	rop
	mpq_t *	a
	mpq_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpq_ior(rop, a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
Rmpq_xor (rop, a, b)
	mpq_t *	rop
	mpq_t *	a
	mpq_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpq_xor(rop, a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

void
Rmpq_com (rop, a)
	mpq_t *	rop
	mpq_t *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpq_com(rop, a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return;

SV *
_overload_add (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sub (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_div (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_div (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_string (p, second, third)
	mpq_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_string (aTHX_ p, second, third);
OUTPUT:  RETVAL

NV
_mpf_get_float128 (x)
	mpf_t *	x

int
_rndaz (a, exponent, prec, display)
	char *	a
	IV	exponent
	UV	prec
	int	display

double
_mpf_get_d_rndn (p)
	mpf_t *	p

NV
_mpf_get_ld (x)
	mpf_t *	x

SV *
Rmpq_get_NV (x)
	mpq_t *	x
CODE:
  RETVAL = Rmpq_get_NV (aTHX_ x);
OUTPUT:  RETVAL

SV *
overload_num (p, second, third)
	mpq_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_num (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_copy (p, second, third)
	mpq_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_copy (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
overload_abs (p, second, third)
	mpq_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_abs (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
_overload_gt (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_gte (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_lt (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_lte (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_spaceship (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_equiv (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_not_equiv (a, b, third)
	mpq_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_not_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_not (a, second, third)
	mpq_t *	a
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_not (aTHX_ a, second, third);
OUTPUT:  RETVAL

SV *
overload_int (p, second, third)
	mpq_t *	p
	SV *	second
	SV *	third
CODE:
  RETVAL = overload_int (aTHX_ p, second, third);
OUTPUT:  RETVAL

SV *
_overload_lshift (p, ls, third)
	mpq_t *	p
	SV *	ls
	SV *	third
CODE:
  RETVAL = _overload_lshift (aTHX_ p, ls, third);
OUTPUT:  RETVAL

SV *
_overload_lshift_eq (p, ls, third)
	SV *	p
	SV *	ls
	SV *	third
CODE:
  RETVAL = _overload_lshift_eq (aTHX_ p, ls, third);
OUTPUT:  RETVAL

SV *
_overload_rshift (p, rs, third)
	mpq_t *	p
	SV *	rs
	SV *	third
CODE:
  RETVAL = _overload_rshift (aTHX_ p, rs, third);
OUTPUT:  RETVAL

SV *
_overload_rshift_eq (p, rs, third)
	SV *	p
	SV *	rs
	SV *	third
CODE:
  RETVAL = _overload_rshift_eq (aTHX_ p, rs, third);
OUTPUT:  RETVAL

SV *
_overload_mul_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_mul_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_add_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_add_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_sub_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_sub_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_div_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_div_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_pow_eq (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_pow_eq (aTHX_ a, b, third);
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

int
_has_longlong ()


int
_has_longdouble ()


int
_has_inttypes ()


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
overload_inc (p, second, third)
	SV *	p
	SV *	second
	SV *	third
        PPCODE:
        overload_inc(aTHX_ p, second, third);
        XSRETURN_EMPTY; /* return empty stack */

void
overload_dec (p, second, third)
	SV *	p
	SV *	second
	SV *	third
        PPCODE:
        overload_dec(aTHX_ p, second, third);
        XSRETURN_EMPTY; /* return empty stack */

SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


SV *
_overload_pow (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = _overload_pow (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


int
Rmpq_integer_p (q)
	mpq_t *	q

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


long
_long_min ()


long
_long_max ()


unsigned long
_ulong_max ()


int
_int_min ()


int
_int_max ()


unsigned int
_uint_max ()


int
_SvPOK (in)
	SV *	in
CODE:
  RETVAL = _SvPOK (aTHX_ in);
OUTPUT:  RETVAL

int
_required_ldbl_mant_dig ()


int
IOK_flag (sv)
	SV *	sv

int
POK_flag (sv)
	SV *	sv

int
NOK_flag (sv)
	SV *	sv

int
_has_pv_nv_bug ()


int
_looks_like_number (in)
	SV *	in
CODE:
  RETVAL = _looks_like_number (aTHX_ in);
OUTPUT:  RETVAL

SV *
_overload_fmod (a, b, third)
	mpq_t *	a
	mpq_t *	b
	SV *	third
CODE:
  RETVAL = _overload_fmod (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_overload_fmod_eq (a, b, third)
	SV *	a
	mpq_t *	b
	SV *	third
CODE:
  RETVAL = _overload_fmod_eq (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
_to_base (str, base)
	SV *	str
	int	base
CODE:
  RETVAL = _to_base (aTHX_ str, base);
OUTPUT:  RETVAL

