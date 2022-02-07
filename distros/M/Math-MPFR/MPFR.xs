
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "math_mpfr_include.h"

#if NVSIZE == 8
#  include "grisu3.h"
#endif

int nnum = 0; /* flag that is incremented whenever a string containing
                 non-numeric characters is treated as a number */

int nok_pok = 0; /* flag that is incremented whenever a scalar that is both
                 NOK and POK is passed to new or an overloaded operator */

/* Has inttypes.h been included ? */
int _has_inttypes(void) {
#if defined MATH_MPFR_NEED_LONG_LONG_INT
return 1;
#else
return 0;
#endif
}

int NNW_val(pTHX) {
  /* return the numeric value of $Math::MPFR::NNW - ie the no. of non-numeric instances encountered */
  return (int)SvIV(get_sv("Math::MPFR::NNW", 0));
}

int NOK_POK_val(pTHX) {
  /* return the numeric value of $Math::MPFR::NOK_POK */
  return (int)SvIV(get_sv("Math::MPFR::NOK_POK", 0));
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
  croak("Math::MPFR::_win32_infnanstring not implemented for this build of perl");
#endif
}

/* _fmt_flt is used by nvtoa, doubletoa and mpfrtoa to format numeric strings */

SV * _fmt_flt(pTHX_ char * out, int k, int sign, int max_decimal_prec, int sf) {
/*

  out             : the string that contains the mantissa of the value as decimal digits;
                    does not contain a radix point.
  k               : the exponent of the value.
  sign            : is 0 if the value is non-negative; else is non-zero.
  max_decimal_prec: calculated as ceil(3.010299956639812e-1 * p) + 1, where p is the precision
                    in bits of the given floating point value.
  sf              : If non-zero, then Safefree(out) will be run prior to this function returning;
                    else Safefree(out) will not be run. The doubletoa function requires that
                    Safefree(out) is not run.

*/

  int k_index, critical, skip;
  SV * outsv;
  char *bstr;
  char str[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0'};

  k_index = (int)strlen(out);
  critical = k; /* formatting is based around this value */
  k -= k_index;

  if(critical < -3) {

    sprintf(str, "e%03d", critical - 1);
    if(sign || k_index > 1) {
      /* insert decimal point */
      for(skip = k_index + sign; skip > 1 + sign; skip--) {
        out[skip] = out[skip - 1 - sign];
      }

      if(k_index > 1) {
        out[1 + sign] = '.';
        out[k_index + 1 + sign] = 0;
      }

      if(sign) {
        out[1] = out[0];
        out[0] = '-';
      }
    }
    strcat(out, str);

    outsv = newSVpv(out, 0);
    if(sf) Safefree(out);
    return outsv;

  }

  if(critical <= 0 ) {

    /* bstr = concatenate "0." . ("0" x -critical) . out; */

    Newxz(bstr, 8 - critical + strlen(out), char); /* Note: 'critical' has -ve value */

    /* Newxz(bstr, (int)(16 + ceil(0.30103 * NVSIZE_BITS)), char); <= OLD VERSION */

    if(bstr == NULL) croak("Failed to allocate memory for 2nd output string in _fmt_flt sub");

    if(sign) bstr[0] = '-';

    bstr[0 + sign] = '0';
    bstr[1 + sign] = '.';

    sign += 2;

    for(skip = critical; skip < 0; skip++) {
      bstr[sign] = '0';
      sign++;
    }

    bstr[sign] = 0;
    strcat(bstr, out);

    outsv = newSVpv(bstr, 0);
    if(sf) Safefree(out);
    Safefree(bstr);
    return outsv;

  }

  if(critical < max_decimal_prec) {

    if(sign) {
      for(skip = k_index; skip > 0; skip--) out[skip] = out[skip - 1];
      out[0] = '-';
      out[k_index + 1] = 0;
    }

   if(k >= 0) {
      /* out = concatenate out . ('0' x k); */
      for(skip = 0; skip < k; skip++) out[k_index + skip + sign] = '0';
      out[k_index + k + sign] = '.';
      out[k_index + k + sign + 1] = '0';
      out[k_index + k + sign + 2] = 0;

      outsv = newSVpv(out, 0);
      if(sf) Safefree(out);
      return outsv;

    }

    /* insert decimal point; */
    for(skip = k_index + sign; skip > k_index + k + sign; skip--) out[skip] = out[skip - 1];
    out[k_index + k + sign] = '.';
    out[k_index + sign + 1] = 0;

    outsv = newSVpv(out, 0);
    if(sf) Safefree(out);
    return outsv;

  }

  if( k_index > 1) {
    /* insert decimal point */
    for(skip = k_index + sign; skip > 1 + sign; skip--) {
      out[skip] = out[skip - 1 - sign];
    }

    out[1 + sign] = '.';
    out[k_index + 1 + sign] = 0;
  }

  if(sign) {
    out[1] = out[0];
    out[0] = '-';
  }

  sprintf(str, "e+%d", critical - 1);
  strcat(out, str);

  outsv = newSVpv(out, 0);
  if(sf) Safefree(out);
  return outsv;

}

void Rmpfr_set_default_rounding_mode(pTHX_ SV * round) {
     CHECK_ROUNDING_VALUE
     mpfr_set_default_rounding_mode((mpfr_rnd_t)SvUV(round));
}

unsigned long Rmpfr_get_default_rounding_mode(void) {
     return __gmpfr_default_rounding_mode;
}

SV * Rmpfr_prec_round(pTHX_ mpfr_t * p, SV * prec, SV * round) {
     return newSViv(mpfr_prec_round(*p, (mpfr_prec_t)SvIV(prec), (mpfr_rnd_t)SvUV(round)));
}

void DESTROY(pTHX_ mpfr_t * p) {
     mpfr_clear(*p);
     Safefree(p);
}

void Rmpfr_clear(pTHX_ mpfr_t * p) {
     mpfr_clear(*p);
     Safefree(p);
}

void Rmpfr_clear_mpfr(mpfr_t * p) {
     mpfr_clear(*p);
}

void Rmpfr_clear_ptr(pTHX_ mpfr_t * p) {
     Safefree(p);
}

void Rmpfr_clears(pTHX_ SV * p, ...) {
     dXSARGS;
     unsigned long i;
     for(i = 0; i < items; i++) {
        mpfr_clear(*(INT2PTR(mpfr_t *, SvIVX(SvRV(ST(i))))));
        Safefree(INT2PTR(mpfr_t *, SvIVX(SvRV(ST(i)))));
     }
     XSRETURN(0);
}

SV * Rmpfr_init(pTHX) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * Rmpfr_init2(pTHX_ SV * prec) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init2) /* defined in math_mpfr_include.h */
     mpfr_init2 (*mpfr_t_obj, (mpfr_prec_t)SvIV(prec));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * Rmpfr_init_nobless(pTHX) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_nobless) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * Rmpfr_init2_nobless(pTHX_ SV * prec) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init2_nobless) /* defined in math_mpfr_include.h */
     mpfr_init2 (*mpfr_t_obj, (mpfr_prec_t)SvIV(prec));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

void Rmpfr_init_set(pTHX_ mpfr_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_ui(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_ui) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_ui(*mpfr_t_obj, (unsigned long)SvUV(q), (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_si(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_si) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_si(*mpfr_t_obj, (long)SvIV(q), (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_d(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_d) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_d(*mpfr_t_obj, (double)SvNV(q), (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_ld(pTHX_ SV * q, SV * round) {
#ifdef USE_LONG_DOUBLE
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_ld) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_ld(*mpfr_t_obj, (long double)SvNV(q), (mpfr_rnd_t)SvUV(round));
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
#else
     croak("Rmpfr_init_set_ld not implemented on this build of perl");
#endif
}

void Rmpfr_init_set_f(pTHX_ mpf_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_f) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_f(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_z(pTHX_ mpz_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_z) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_z(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_q(pTHX_ mpq_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_q) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_q(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_str(pTHX_ SV * q, SV * base, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif


     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_INPUT_BASE )
        croak("2nd argument supplied to Rmpfr_init_set str is out of allowable range");

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_str) /* defined in math_mpfr_include.h */
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(q));
       if(inf_or_nan) {
         mpfr_init(*mpfr_t_obj);
         if(inf_or_nan != 2) mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
       }
       else {
         ret = mpfr_init_set_str(*mpfr_t_obj, SvPV_nolen(q), (int)SvIV(base), (mpfr_rnd_t)SvUV(round));
       }
#else
       ret = mpfr_init_set_str(*mpfr_t_obj, SvPV_nolen(q), (int)SvIV(base), (mpfr_rnd_t)SvUV(round));

#endif

     NON_NUMERIC_CHAR_CHECK, "Rmpfr_init_set_str");}
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_nobless(pTHX_ mpfr_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_ui_nobless(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_ui_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_ui(*mpfr_t_obj, (unsigned long)SvUV(q), (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_si_nobless(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_si_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_si(*mpfr_t_obj, (long)SvIV(q), (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_d_nobless(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_d_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_d(*mpfr_t_obj, (double)SvNV(q), (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_ld_nobless(pTHX_ SV * q, SV * round) {
#ifdef USE_LONG_DOUBLE
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_ld_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_ld(*mpfr_t_obj, (long double)SvNV(q), (mpfr_rnd_t)SvUV(round));
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */

#else
     croak("Rmpfr_init_set_ld_nobless not implemented on this build of perl");

#endif
}

void Rmpfr_init_set_f_nobless(pTHX_ mpf_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_f_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_f(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_z_nobless(pTHX_ mpz_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_z_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_z(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_q_nobless(pTHX_ mpq_t * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_q_nobless) /* defined in math_mpfr_include.h */
     ret = mpfr_init_set_q(*mpfr_t_obj, *q, (mpfr_rnd_t)SvUV(round));

     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_str_nobless(pTHX_ SV * q, SV * base, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_INPUT_BASE )
        croak("2nd argument supplied to Rmpfr_init_set_str_nobless is out of allowable range");

     NEW_MATH_MPFR_OBJECT(NULL,Rmpfr_init_set_str_nobless) /* defined in math_mpfr_include.h */
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     ret = mpfr_init_set_str(*mpfr_t_obj, SvPV_nolen(q), (int)SvIV(base), (mpfr_rnd_t)SvUV(round));

     NON_NUMERIC_CHAR_CHECK, "Rmpfr_init_set_str_nobless");}
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_deref2(pTHX_ mpfr_t * p, SV * base, SV * n_digits, SV * round) {
     dXSARGS;
     char * out;
     mpfr_exp_t ptr;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
        croak("Second argument supplied to Rmpfr_get_str is not in acceptable range");

     out = mpfr_get_str(0, &ptr, (int)SvIV(base), (unsigned long)SvUV(n_digits), *p, (mpfr_rnd_t)SvUV(round));

     if(out == NULL) croak("An error occurred in memory allocation in mpfr_get_str\n");

     ST(0) = MORTALIZED_PV(out);    /* defined in math_mpfr_include.h */
     mpfr_free_str(out);
     ST(1) = sv_2mortal(newSViv(ptr));
     XSRETURN(2);
}

void Rmpfr_set_default_prec(pTHX_ SV * prec) {

#if MPFR_VERSION < 262144      /* earlier than version 4.0.0 */
     if(SvIV(prec) < 2) croak("Precision must be set to at least 2 for this version (%s) of the mpfr library", MPFR_VERSION_STRING);
#endif

     mpfr_set_default_prec((mpfr_prec_t)SvIV(prec));
}

SV * Rmpfr_get_default_prec(pTHX) {
     return newSViv(mpfr_get_default_prec());
}

SV * Rmpfr_min_prec(pTHX_ mpfr_t * x) {
     return newSViv((mpfr_prec_t)mpfr_min_prec(*x));
}

void Rmpfr_set_prec(pTHX_ mpfr_t * p, SV * prec) {

#if MPFR_VERSION < 262144      /* earlier than version 4.0.0 */
     if(SvIV(prec) < 2) croak("Precision must be set to at least 2 for this version (%s) of the mpfr library", MPFR_VERSION_STRING);
#endif

     mpfr_set_prec(*p, (mpfr_prec_t)SvIV(prec));
}

void Rmpfr_set_prec_raw(pTHX_ mpfr_t * p, SV * prec) {

#if MPFR_VERSION < 262144      /* earlier than version 4.0.0 */
     if(SvIV(prec) < 2) croak("Precision must be set to at least 2 for this version (%s) of the mpfr library", MPFR_VERSION_STRING);
#endif

     mpfr_set_prec_raw(*p, (mpfr_prec_t)SvIV(prec));
}

SV * Rmpfr_get_prec(pTHX_ mpfr_t * p) {
     return newSViv(mpfr_get_prec(*p));
}

SV * Rmpfr_set(pTHX_ mpfr_t * p, mpfr_t * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set(*p, *q, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_ui(pTHX_ mpfr_t * p, SV * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set_ui(*p, (unsigned long)SvUV(q), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_si(pTHX_ mpfr_t * p, SV * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set_si(*p, (long)SvIV(q), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_uj(pTHX_ mpfr_t * p, SV * q, SV * round) {
     CHECK_ROUNDING_VALUE
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_set_uj(*p, SvUV(q), (mpfr_rnd_t)SvUV(round)));

#else
     croak("Rmpfr_set_uj not implemented on this build of perl");

#endif
}

SV * Rmpfr_set_sj(pTHX_ mpfr_t * p, SV * q, SV * round) {
     CHECK_ROUNDING_VALUE
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_set_sj(*p, SvIV(q), (mpfr_rnd_t)SvUV(round)));

#else
     croak("Rmpfr_set_sj not implemented on this build of perl");

#endif
}


int Rmpfr_set_NV(pTHX_ mpfr_t * p, SV * q, unsigned int round) {

#if MPFR_VERSION_MAJOR < 3
     if((mpfr_rnd_t)round > 3)
       croak("Illegal rounding value supplied for this version (%s) of the mpfr library", MPFR_VERSION_STRING);
#endif

#if defined(USE_LONG_DOUBLE)

     if(!SV_IS_NOK(q))
       croak("In Rmpfr_set_NV, 2nd argument is not an NV");

     return mpfr_set_ld(*p, (long double)SvNV(q), (mpfr_rnd_t)round);

#elif defined(CAN_PASS_FLOAT128)

     if(!SV_IS_NOK(q))
       croak("In Rmpfr_set_NV, 2nd argument is not an NV");

     return mpfr_set_float128(*p, (float128)SvNV(q), (mpfr_rnd_t)round);

#elif defined(USE_QUADMATH)
     char buffer[45];
     int exp;
     float128 ld;
     int returned;

     if(!SV_IS_NOK(q))
       croak("In Rmpfr_set_NV, 2nd argument is not an NV");

     ld = (float128)SvNV(q);

     if(ld != ld) {
       mpfr_set_nan(*p);
       return 0;
     }

     if(ld != 0.0Q && (ld / ld != 1)) {
       returned = ld > 0.0Q ? 1 : -1;
       mpfr_set_inf(*p, returned);
       return 0;
     }

     ld = frexpq(ld, &exp); /* 0.5 <= returned value < 1.0 */

     /* Convert ld to an integer by right shifting it 113 bits */
     ld *= 1.0384593717069655257060992658440192e34Q;      /* ld *= powq(2.0Q, 113); */

     returned = quadmath_snprintf(buffer, 45, "%.0Qf", ld);
     if(returned < 0) croak("In Rmpfr_set_NV, encoding error in quadmath_snprintf function");
     if(returned >= 45) croak("In Rmpfr_set_NV, buffer given to quadmath_snprintf function was too small");

     returned = mpfr_set_str(*p, buffer, 10, (mpfr_rnd_t)round);

     mpfr_mul_2si(*p, *p, exp - 113, GMP_RNDN);

     return returned;

#else

     if(!SV_IS_NOK(q))
       croak("In Rmpfr_set_NV, 2nd argument is not an NV");

     return mpfr_set_d (*p, SvNV(q), (mpfr_rnd_t)round);

#endif
}


void Rmpfr_init_set_NV(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_NV) /* defined in math_mpfr_include.h */

     mpfr_init(*mpfr_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
     ret = Rmpfr_set_NV(aTHX_ mpfr_t_obj, q, (mpfr_rnd_t)SvUV(round));
     SvREADONLY_on(obj);
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_NV_nobless(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("NULL",Rmpfr_init_set_NV_nobless) /* defined in math_mpfr_include.h */

     mpfr_init(*mpfr_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
     ret = Rmpfr_set_NV(aTHX_ mpfr_t_obj, q, (mpfr_rnd_t)SvUV(round));
     SvREADONLY_on(obj);
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

int Rmpfr_cmp_float128(pTHX_ mpfr_t * a, SV * b) {

#if defined(CAN_PASS_FLOAT128)

     mpfr_t t;
     int ret;
     mpfr_init2(t, FLT128_MANT_DIG);
     mpfr_set_float128(t, SvNV(b), GMP_RNDN);
     ret = mpfr_cmp(*a, t);
     mpfr_clear(t);
     return ret;

#elif defined(USE_QUADMATH)

     mpfr_t t;
     char buffer[45];
     int exp;
     float128 ld;
     int returned;

     ld = (float128)SvNV(b);
     if(ld != ld || mpfr_nan_p(*a)) {
       mpfr_set_erangeflag();
       return 0;
     }

     if(ld != 0.0Q && (ld / ld != 1)) {
       if(ld > 0.0Q) {
         if(mpfr_inf_p(*a)) {
           if(mpfr_signbit(*a)) return -1;
           return 0;
         }
         return -1;
       }
       if(mpfr_inf_p(*a)) {
         if(mpfr_signbit(*a)) return 0;
         return 1;
       }
       return 1;
     }

     if(ld == 0.0Q) {
       if(mpfr_zero_p (*a)) return 0;
       if(mpfr_signbit(*a)) return -1;
       return 1;
     }


     ld = frexpq(ld, &exp); /* 0.5 <= returned value < 1.0 */

     /* Convert ld to an integer by right shifting it 113 bits */
     ld *= 1.0384593717069655257060992658440192e34Q;      /* ld *= powq(2.0Q, 113); */

     returned = quadmath_snprintf(buffer, 45, "%.0Qf", ld);
     if(returned < 0) croak("In Rmpfr_set_NV, encoding error in quadmath_snprintf function");
     if(returned >= 45) croak("In Rmpfr_set_NV, buffer given to quadmath_snprintf function was too small");

     mpfr_init2(t, FLT128_MANT_DIG);
     returned = mpfr_set_str(t, buffer, 10, GMP_RNDN);

     mpfr_mul_2si(t, t, exp - 113, GMP_RNDN);

     returned = mpfr_cmp(*a, t);
     mpfr_clear(t);
     return returned;

#else

     croak("Rmpfr_cmp_float128 not available on this build of perl");

#endif
}

int Rmpfr_cmp_NV(pTHX_ mpfr_t * a, SV * b) {

     if(!SvNOK(b))
       croak("In Rmpfr_cmp_NV, 2nd argument is not an NV");

#if defined(USE_LONG_DOUBLE)

     return mpfr_cmp_ld(*a, SvNV(b));

#elif defined(USE_QUADMATH)

     return Rmpfr_cmp_float128(aTHX_ a, b);

#else

     return mpfr_cmp_d(*a, SvNV(b));

#endif
}

SV * Rmpfr_set_ld(pTHX_ mpfr_t * p, SV * q, SV * round) {
     CHECK_ROUNDING_VALUE
#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
     return newSViv(mpfr_set_ld(*p, (long double)SvNV(q), (mpfr_rnd_t)SvUV(round)));

#else
     croak("Rmpfr_set_ld not implemented on this build of perl");

#endif
}

SV * Rmpfr_set_d(pTHX_ mpfr_t * p, SV * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set_d(*p, (double)SvNV(q), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_z(pTHX_ mpfr_t * p, mpz_t * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set_z(*p, *q, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_q(pTHX_ mpfr_t * p, mpq_t * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set_q(*p, *q, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_f(pTHX_ mpfr_t * p, mpf_t * q, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_set_f(*p, *q, (mpfr_rnd_t)SvUV(round)));
}

int Rmpfr_set_str(pTHX_ mpfr_t * p, SV * num, SV * base, SV * round) {
    int ret;
#ifdef _WIN32_BIZARRE_INFNAN
    int inf_or_nan;
#endif

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_INPUT_BASE )
        croak("3rd argument supplied to Rmpfr_set_str is out of allowable range");

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(num));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*p);
         }

         else mpfr_set_inf(*p, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(*p, SvPV_nolen(num), (int)SvIV(base), (mpfr_rnd_t)SvUV(round));
       }
#else
       ret = mpfr_set_str(*p, SvPV_nolen(num), (int)SvIV(base), (mpfr_rnd_t)SvUV(round));

#endif

     NON_NUMERIC_CHAR_CHECK, "Rmpfr_set_str");}

     return ret;
}

/*
Removed in Math-MPFR-3.30. Should have been removed much earlier
void Rmpfr_set_str_binary(pTHX_ mpfr_t * p, SV * str) {
     mpfr_set_str_binary(*p, SvPV_nolen(str));
}
*/

void Rmpfr_set_inf(mpfr_t * p, int sign) {
     mpfr_set_inf(*p, sign);
}

void Rmpfr_set_nan(mpfr_t * p) {
     mpfr_set_nan(*p);
}

void Rmpfr_swap(mpfr_t *p, mpfr_t * q) {
     mpfr_swap(*p, *q);
}

SV * Rmpfr_get_d(pTHX_ mpfr_t * p, SV * round){
     CHECK_ROUNDING_VALUE
     return newSVnv(mpfr_get_d(*p, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_d_2exp(pTHX_ SV * exp, mpfr_t * p, SV * round){
     long _exp;
     double ret;
     CHECK_ROUNDING_VALUE
     ret = mpfr_get_d_2exp(&_exp, *p, (mpfr_rnd_t)SvUV(round));
     sv_setiv(exp, _exp);
     return newSVnv(ret);
}

SV * Rmpfr_get_ld_2exp(pTHX_ SV * exp, mpfr_t * p, SV * round){
#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
#  if defined(USE_QUADMATH) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
  /*
     Casting long double Inf to float128 might result in NaN.
     This is GCC bug 77265, which was fixed for GCC 7:
     https://gcc.gnu.org/bugzilla/show_bug.cgi?id=77265
     The fix might yet be backported to GCC 6. (Not sure.)
     It was earlier reported (also by me) to MinGW:
     https://sourceforge.net/p/mingw-w64/bugs/479/
     Let us take the cautious approach and simply avoid
     making that cast. Instead, we will cast the double Inf
     to a float128.
  */
     if(mpfr_inf_p(*p))
       return newSVnv(mpfr_get_d(*p, (mpfr_rnd_t)SvUV(round)));
#  endif
     long _exp;
     long double ret;
     CHECK_ROUNDING_VALUE
     ret = mpfr_get_ld_2exp(&_exp, *p, (mpfr_rnd_t)SvUV(round));
     sv_setiv(exp, _exp);
     return newSVnv(ret);

#else
     croak("Rmpfr_get_ld_2exp not implemented on this build of perl");

#endif
}

SV * Rmpfr_get_ld(pTHX_ mpfr_t * p, SV * round){
     CHECK_ROUNDING_VALUE
#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
#  if defined(USE_QUADMATH) && defined(__GNUC__) && ((__GNUC__ > 4 && __GNUC__ < 7) || (__GNUC__ == 4 && __GNUC_MINOR__ >= 9))
      /*
      Casting long double Inf to float128 might result in NaN.
      This is GCC bug 77265, which was fixed for GCC 7:
      https://gcc.gnu.org/bugzilla/show_bug.cgi?id=77265
      The fix might yet be backported to GCC 6. (Not sure.)
      It was earlier reported (also by me) to MinGW:
      https://sourceforge.net/p/mingw-w64/bugs/479/
      Let us take the cautious approach and simply avoid
      making that cast. Instead, we will cast the double Inf
      to a float128.
      */
      if(mpfr_inf_p(*p))
        return newSVnv(mpfr_get_d(*p, (mpfr_rnd_t)SvUV(round)));

#  elif LDBL_MANT_DIG == 106
#    if !defined(MPFR_VERSION) || (defined(MPFR_VERSION) && MPFR_VERSION <= DD_INF_BUG)
        double d = mpfr_get_ld(*p, (mpfr_rnd_t)SvUV(round));

        if(d == 0.0 || d != d || d / d != 1) return newSVnv((long double)d);
#    endif
#  endif

#  if defined MPFR_VERSION && MPFR_VERSION > 196868            /* mpfr_get_ld handles subnormals correctly */
        return newSVnv(mpfr_get_ld(*p, (mpfr_rnd_t)SvUV(round)));
#  else                                                        /* mpfr_get_ld handling of subnormals is buggy */

        if(strtold("2e-4956", NULL) == 0.0L) { /* extended precision (80-bit) long double */
          if(mpfr_regular_p(*p) && mpfr_get_exp(*p) < -16381 && mpfr_get_exp(*p) >= -16445) {
            warn("\n mpfr_get_ld is buggy (subnormal values only)\n for this version (%s) of the MPFR library\n", MPFR_VERSION_STRING);
            croak(" Version 3.1.5 or later is required");
          }
        }
        return newSVnv(mpfr_get_ld(*p, (mpfr_rnd_t)SvUV(round)));

#  endif

#else
     croak("Rmpfr_get_ld not implemented on this build of perl");

#endif
}

double Rmpfr_get_d1(mpfr_t * p) {
     return mpfr_get_d1(*p);
}

/* Alias for the perl function Rmpfr_get_z_exp
*  (which will perhaps one day be removed).
*  The mpfr headers define 'mpfr_get_z_exp' to
*  'mpfr_get_z_2exp' when that function is
*  available.
*/
SV * Rmpfr_get_z_2exp(pTHX_ mpz_t * z, mpfr_t * p){
     return newSViv(mpfr_get_z_exp(*z, *p));
}

SV * Rmpfr_add(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_add(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_add_ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     DEAL_WITH_NANFLAG_BUG
     return newSViv(mpfr_add_ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_add_d(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_add_d(*a, *b, (double)SvNV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_add_si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     DEAL_WITH_NANFLAG_BUG
     return newSViv(mpfr_add_si(*a, *b, (int)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_add_z(pTHX_ mpfr_t * a, mpfr_t * b, mpz_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_add_z(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

/* No need for rounding as result will be exact */
void Rmpfr_get_q(mpq_t * a, mpfr_t * b) {

#if defined(MPFR_VERSION_MAJOR) && MPFR_VERSION_MAJOR >= 4

     mpfr_get_q(*a, *b);

#else
     mpf_t temp;

     if(!mpfr_number_p(*b)) {
       mpq_set_ui(*a, 0, 1);
       mpfr_set_erangeflag();
     }
     else {
       mpf_init2 (temp, (mp_bitcnt_t)mpfr_get_prec(*b));
       mpfr_get_f(temp, *b, GMP_RNDN);
       mpq_set_f (*a, temp);
       mpf_clear(temp);
     }
#endif
}

SV * Rmpfr_add_q(pTHX_ mpfr_t * a, mpfr_t * b, mpq_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_add_q(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

void q_add_fr(mpq_t * a, mpq_t * b, mpfr_t * c) {
     mpq_t temp;
     mpq_init(temp);
#if defined(MPFR_VERSION_MAJOR) && MPFR_VERSION_MAJOR >= 4
     mpfr_get_q(temp, *c);
#else
     Rmpfr_get_q(&temp, c);
#endif
     mpq_add(*a, *b, temp);
     mpq_clear(temp);
}

SV * Rmpfr_sub(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sub(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sub_ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     DEAL_WITH_NANFLAG_BUG
     return newSViv(mpfr_sub_ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sub_d(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sub_d(*a, *b, (double)SvNV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sub_z(pTHX_ mpfr_t * a, mpfr_t * b, mpz_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sub_z(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sub_q(pTHX_ mpfr_t * a, mpfr_t * b, mpq_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sub_q(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

void q_sub_fr(mpq_t * a, mpq_t * b, mpfr_t * c) {
     mpq_t temp;
     mpq_init(temp);
#if defined(MPFR_VERSION_MAJOR) && MPFR_VERSION_MAJOR >= 4
     mpfr_get_q(temp, *c);
#else
     Rmpfr_get_q(&temp, c);
#endif
     mpq_sub(*a, *b, temp);
     mpq_clear(temp);
}

SV * Rmpfr_ui_sub(pTHX_ mpfr_t * a, SV * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_ui_sub(*a, (unsigned long)SvUV(b), *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_d_sub(pTHX_ mpfr_t * a, SV * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_d_sub(*a, (double)SvNV(b), *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_d(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_d(*a, *b, (double)SvNV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_z(pTHX_ mpfr_t * a, mpfr_t * b, mpz_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_z(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_q(pTHX_ mpfr_t * a, mpfr_t * b, mpq_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_q(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

void q_mul_fr(mpq_t * a, mpq_t * b, mpfr_t * c) {
     mpq_t temp;
     mpq_init(temp);
#if defined(MPFR_VERSION_MAJOR) && MPFR_VERSION_MAJOR >= 4
     mpfr_get_q(temp, *c);
#else
     Rmpfr_get_q(&temp, c);
#endif
     mpq_mul(*a, *b, temp);
     mpq_clear(temp);
}

SV * Rmpfr_dim(pTHX_ mpfr_t * rop, mpfr_t * op1, mpfr_t * op2, SV * round) {
     CHECK_ROUNDING_VALUE
         int ret = mpfr_dim( *rop, *op1, *op2, (mpfr_rnd_t)SvUV(round));
         return newSViv(ret);
}

SV * Rmpfr_div(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_d(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_d(*a, *b, (double)SvNV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_z(pTHX_ mpfr_t * a, mpfr_t * b, mpz_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_z(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_q(pTHX_ mpfr_t * a, mpfr_t * b, mpq_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_q(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

void q_div_fr(mpq_t * a, mpq_t * b, mpfr_t * c) {
     mpq_t temp;
     mpq_init(temp);
#if defined(MPFR_VERSION_MAJOR) && MPFR_VERSION_MAJOR >= 4
     mpfr_get_q(temp, *c);
#else
     Rmpfr_get_q(&temp, c);
#endif
     mpq_div(*a, *b, temp);
     mpq_clear(temp);
}

SV * Rmpfr_ui_div(pTHX_ mpfr_t * a, SV * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_ui_div(*a, (unsigned long)SvUV(b), *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_d_div(pTHX_ mpfr_t * a, SV * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_d_div(*a, (double)SvNV(b), *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sqrt(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sqrt(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_rec_sqrt(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_rec_sqrt(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_cbrt(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_cbrt(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sqrt_ui(pTHX_ mpfr_t * a, SV * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sqrt_ui(*a, (unsigned long)SvUV(b), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_pow_ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_pow_ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_pow_uj(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
#if MPFR_VERSION >= 262656
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_pow_uj(*a, *b, (uintmax_t)SvUV(c), (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_pow_uj not implemented for this build of perl");
#endif
#else
     croak("Rmpfr_pow_uj function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_pow_IV(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {

   if(SV_IS_IOK(c)) {

#if defined(MATH_MPFR_NEED_LONG_LONG_INT)
#  if MPFR_VERSION >= 262656
       if(SvUOK(c)) {
         return newSViv(mpfr_pow_uj(*a, *b, (uintmax_t)SvUV(c), (mpfr_rnd_t)SvUV(round)));
       }
       return newSViv(mpfr_pow_sj(*a, *b, (intmax_t)SvIV(c), (mpfr_rnd_t)SvUV(round)));
#  else
       mpfr_t t;
       int ret;
       mpfr_init2(t, 64);
       if(SvUOK(c)) {
         mpfr_set_uj(t, (uintmax_t)SvUV(c), (mpfr_rnd_t)SvUV(round));
       }
       else {
         mpfr_set_sj(t, (intmax_t)SvIV(c), (mpfr_rnd_t)SvUV(round));
       }
       ret = mpfr_pow(*a, *b, t, (mpfr_rnd_t)SvUV(round));
       mpfr_clear(t);
       return newSViv(ret);
#  endif
#else
       if(SvUOK(c)) {
         return newSViv(mpfr_pow_ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
       }
       return newSViv(mpfr_pow_si(*a, *b, (unsigned long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
#endif
    }
    croak("Arg provided to Rmpfr_pow_IV is not an IV");
}

SV * Rmpfr_ui_pow_ui(pTHX_ mpfr_t * a, SV * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_ui_pow_ui(*a, (unsigned long)SvUV(b), (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_ui_pow(pTHX_ mpfr_t * a, SV * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_ui_pow(*a, (unsigned long)SvUV(b), *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_pow_si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_pow_si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_pow_sj(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
#if MPFR_VERSION >= 262656
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_pow_sj(*a, *b, (intmax_t)SvIV(c), (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_pow_sj not implemented for this build of perl");
#endif
#else
     croak("Rmpfr_pow_sj function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_pow(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_pow(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_powr(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_powr(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_powr function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_pown(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
#if MPFR_VERSION >= 262656
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_pown(*a, *b, (intmax_t)SvIV(c), (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_pown not implemented for this build of perl");
#endif
#else
     croak("Rmpfr_pown function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_compound_si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_compound_si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_compound_si function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_neg(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_neg(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_abs(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_abs(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_2exp(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_2exp(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_2ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_2ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_2si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_2si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_2exp(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_2exp(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_2ui(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_2ui(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_2si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_2si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

int Rmpfr_total_order_p(mpfr_t * a, mpfr_t * b) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= 262400 /* version 4.1.0 */
    return mpfr_total_order_p(*a, *b);
#else
    if(mpfr_nan_p(*a)) {
      if(mpfr_signbit(*a)) return 1;    /* *a <= *b */
      if(mpfr_nan_p(*b)) {
        if(mpfr_signbit(*b)) return 0;
        return 1;
      }
      return 0;
    }

    if(mpfr_nan_p(*b)) {
      if(mpfr_signbit(*b)) return 0;    /* *a > *b */
      return 1;
    }

    if(mpfr_zero_p(*a) && mpfr_zero_p(*b)) {
      if(!mpfr_signbit(*a) && mpfr_signbit(*b)) return 0; /* (*a, *b) is (+0, -0) */
      return 1; /* (*a, *b) is either (-0, -0) or (-0, +0) or (+0, +0) */
    }

    return mpfr_lessequal_p(*a, *b);
#endif
}

int Rmpfr_cmp(mpfr_t * a, mpfr_t * b) {
     return mpfr_cmp(*a, *b);
}

int Rmpfr_cmpabs(mpfr_t * a, mpfr_t * b) {
     return mpfr_cmpabs(*a, *b);
}

int Rmpfr_cmpabs_ui(mpfr_t * a, unsigned long b) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= 262400 /* version 4.1.0 */
     return mpfr_cmpabs_ui(*a, b);
#else
     croak("The Rmpfr_cmpabs_ui function requires mpfr-4.1.0");
#endif
}

int Rmpfr_cmp_ui(mpfr_t * a, unsigned long b) {
     return mpfr_cmp_ui(*a, b);
}

int Rmpfr_cmp_si(mpfr_t * a, long b) {
     return mpfr_cmp_si(*a, b);
}

int Rmpfr_cmp_uj(pTHX_ mpfr_t * a, UV b) {
#if defined(MATH_MPFR_NEED_LONG_LONG_INT)
    int ret;
    mpfr_t temp;
    mpfr_init2(temp, 64);

    mpfr_set_uj(temp, b, GMP_RNDN);
    ret = mpfr_cmp(*a, temp);
    mpfr_clear(temp);
    return ret;
#else
    croak("Rmpfr_cmp_uj is unavailable because MATH_MPFR_NEED_LONG_LONG_INT is not defined");
#endif
}

int Rmpfr_cmp_sj(pTHX_ mpfr_t * a, IV b) {
#if defined(MATH_MPFR_NEED_LONG_LONG_INT)
    int ret;
    mpfr_t temp;
    mpfr_init2(temp, 64);

    mpfr_set_sj(temp, b, GMP_RNDN);
    ret = mpfr_cmp(*a, temp);
    mpfr_clear(temp);
    return ret;
#else
    croak("Rmpfr_cmp_sj is unavailable because MATH_MPFR_NEED_LONG_LONG_INT is not defined");
#endif
}

int Rmpfr_cmp_IV(pTHX_ mpfr_t *a, SV * b) {

    int call_uv = 0;

    if(SV_IS_IOK(b)) {
      if(SvUOK(b)) call_uv = 1;
    }
    else
      croak("Arg provided to Rmpfr_cmp_IV is not an IV");

#if defined(MATH_MPFR_NEED_LONG_LONG_INT)
    if(call_uv) {
      return Rmpfr_cmp_uj(aTHX_ a, SvUV(b));
    }
    return Rmpfr_cmp_sj(aTHX_ a, SvIV(b));
#else
    if(call_uv) {
      return mpfr_cmp_ui(*a, SvUV(b));
    }
    return mpfr_cmp_si(*a, SvIV(b));
#endif

}

int Rmpfr_cmp_d(mpfr_t * a, double b) {
     return mpfr_cmp_d(*a, b);
}

int Rmpfr_cmp_ld(pTHX_ mpfr_t * a, SV * b) {
#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
     return mpfr_cmp_ld(*a, (long double)SvNV(b));

#else
     croak("Rmpfr_cmp_ld not implemented on this build of perl");

#endif
}

int Rmpfr_cmp_ui_2exp(pTHX_ mpfr_t * a, SV * b, SV * c) {
     return mpfr_cmp_ui_2exp(*a, (unsigned long)SvUV(b), (mpfr_exp_t)SvIV(c));
}

int Rmpfr_cmp_si_2exp(pTHX_ mpfr_t * a, SV * b, SV * c) {
     return mpfr_cmp_si_2exp(*a, (long)SvIV(b), (mpfr_exp_t)SvIV(c));
}

int Rmpfr_eq(mpfr_t * a, mpfr_t * b, unsigned long c) {
     return mpfr_eq(*a, *b, c);
}

int Rmpfr_nan_p(mpfr_t * p) {
     return mpfr_nan_p(*p);
}

int Rmpfr_inf_p(mpfr_t * p) {
     return mpfr_inf_p(*p);
}

int Rmpfr_number_p(mpfr_t * p) {
     return mpfr_number_p(*p);
}

void Rmpfr_reldiff(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     mpfr_reldiff(*a, *b, *c, (mpfr_rnd_t)SvUV(round));
}

int Rmpfr_sgn(mpfr_t * p) {
     return mpfr_sgn(*p);
}

int Rmpfr_greater_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_greater_p(*a, *b);
}

int Rmpfr_greaterequal_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_greaterequal_p(*a, *b);
}

int Rmpfr_less_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_less_p(*a, *b);
}

int Rmpfr_lessequal_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_lessequal_p(*a, *b);
}

int Rmpfr_lessgreater_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_lessgreater_p(*a, *b);
}

int Rmpfr_equal_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_equal_p(*a, *b);
}

int Rmpfr_unordered_p(mpfr_t * a, mpfr_t * b) {
     return mpfr_unordered_p(*a, *b);
}

SV * Rmpfr_sin_cos(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sin_cos(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sinh_cosh(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sinh_cosh(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sin(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sin(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sinu(pTHX_ mpfr_t *a, mpfr_t *b, unsigned long c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_sinu(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_sinu function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_sinpi(pTHX_ mpfr_t *a, mpfr_t *b, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_sinpi(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_sinpi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_cos(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_cos(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_cosu(pTHX_ mpfr_t *a, mpfr_t *b, unsigned long c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_cosu(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_cosu function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_cospi(pTHX_ mpfr_t *a, mpfr_t *b, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_cospi(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_cospi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_tan(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_tan(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_tanu(pTHX_ mpfr_t *a, mpfr_t *b, unsigned long c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_tanu(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_tanu function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_tanpi(pTHX_ mpfr_t *a, mpfr_t *b, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_tanpi(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_tanpi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_asin(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_asin(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_asinu(pTHX_ mpfr_t *a, mpfr_t *b, unsigned long c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_asinu(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_asinu function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_asinpi(pTHX_ mpfr_t *a, mpfr_t *b, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_asinpi(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_asinpi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_acos(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_acos(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_acosu(pTHX_ mpfr_t *a, mpfr_t *b, unsigned long c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_acosu(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_acosu function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_acospi(pTHX_ mpfr_t *a, mpfr_t *b, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_acospi(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_acospi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_atan(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_atan(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_atanu(pTHX_ mpfr_t *a, mpfr_t *b, unsigned long c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_atanu(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_atanu function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_atanpi(pTHX_ mpfr_t *a, mpfr_t *b, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_atanpi(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_atanpi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_sinh(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sinh(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_cosh(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_cosh(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_tanh(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_tanh(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_asinh(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_asinh(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_acosh(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_acosh(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_atanh(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_atanh(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fac_ui(pTHX_ mpfr_t * a, SV * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_fac_ui(*a, (unsigned long)SvUV(b), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_log1p(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_log1p(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_expm1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_expm1(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_exp2m1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_exp2m1(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_exp2m1 function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_exp10m1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_exp10m1(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_exp10m1 function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_log2(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_log2(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_log2p1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_log2p1(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_log2p1 function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_log10(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_log10(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_log10p1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_log10p1(*a, *b, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_log10p1 function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_fma(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, mpfr_t * d, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_fma(*a, *b, *c, *d, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fms(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, mpfr_t * d, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_fms(*a, *b, *c, *d, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_agm(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_agm(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_hypot(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_hypot(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_const_log2(pTHX_ mpfr_t * p, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_const_log2(*p, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_const_pi(pTHX_ mpfr_t * p, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_const_pi(*p, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_const_euler(pTHX_ mpfr_t * p, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_const_euler(*p, (mpfr_rnd_t)SvUV(round)));
}

/*
Removed in Math-MPFR-3.30. Should have been removed much earlier
void Rmpfr_print_binary(mpfr_t * p) {
     mpfr_print_binary(*p);
}
*/

SV * Rmpfr_rint(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_rint(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

int Rmpfr_ceil(mpfr_t * a, mpfr_t * b) {
     return mpfr_ceil(*a, *b);
}

int Rmpfr_floor(mpfr_t * a, mpfr_t * b) {
     return mpfr_floor(*a, *b);
}

int Rmpfr_round(mpfr_t * a, mpfr_t * b) {
     return mpfr_round(*a, *b);
}

int Rmpfr_trunc(mpfr_t * a, mpfr_t * b) {
     return mpfr_trunc(*a, *b);
}

/* NO LONGER SUPPORTED - use Rmpfr_nextabove instead
SV * Rmpfr_add_one_ulp(mpfr_t * p, SV * round) {
     return newSViv(mpfr_add_one_ulp(*p, (mpfr_rnd_t)SvUV(round)));
} */

/* NO LONGER SUPPORTED - use Rmpfr_nextbelow instead
SV * Rmpfr_sub_one_ulp(mpfr_t * p, SV * round) {
     return newSViv(mpfr_sub_one_ulp(*p, (mpfr_rnd_t)SvUV(round)));
} */

SV * Rmpfr_can_round(pTHX_ mpfr_t * p, SV * err, SV * round1, SV * round2, SV * prec) {
#if MPFR_VERSION_MAJOR < 3
    if((mpfr_rnd_t)SvUV(round1) > 3 || (mpfr_rnd_t)SvUV(round2) > 3)
      croak("Illegal rounding value supplied for this version (%s) of the mpfr library", MPFR_VERSION_STRING);
#endif
     return newSViv(mpfr_can_round(*p, (mpfr_exp_t)SvIV(err), SvUV(round1), SvUV(round2), (mpfr_prec_t)SvIV(prec)));
}

SV * Rmpfr_print_rnd_mode(pTHX_ SV * rnd) {
     const char * x = mpfr_print_rnd_mode((mpfr_rnd_t)SvIV(rnd));
     if(x == NULL) return &PL_sv_undef;
     return newSVpv(x, 0);
}

SV * Rmpfr_get_emin(pTHX) {
     return newSViv(mpfr_get_emin());
}

SV * Rmpfr_get_emax(pTHX) {
     return newSViv(mpfr_get_emax());
}

int Rmpfr_set_emin(pTHX_ SV * e) {
     return mpfr_set_emin((mpfr_exp_t)SvIV(e));
}

int Rmpfr_set_emax(pTHX_ SV * e) {
     return mpfr_set_emax((mpfr_exp_t)SvIV(e));
}

SV * Rmpfr_check_range(pTHX_ mpfr_t * p, SV * t, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_check_range(*p, (int)SvIV(t), (mpfr_rnd_t)SvUV(round)));
}

void Rmpfr_clear_underflow(void) {
     mpfr_clear_underflow();
}

void Rmpfr_clear_overflow(void) {
     mpfr_clear_overflow();
}

void Rmpfr_clear_nanflag(void) {
     mpfr_clear_nanflag();
}

void Rmpfr_clear_inexflag(void) {
     mpfr_clear_inexflag();
}

void Rmpfr_clear_flags(void) {
     mpfr_clear_flags();
}

int Rmpfr_underflow_p(void) {
     return mpfr_underflow_p();
}

int Rmpfr_overflow_p(void) {
     return mpfr_overflow_p();
}

int Rmpfr_nanflag_p(void) {
     return mpfr_nanflag_p();
}

int Rmpfr_inexflag_p(void) {
     return mpfr_inexflag_p();
}

SV * Rmpfr_log(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_log(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_exp(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_exp(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_exp2(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_exp2(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_exp10(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_exp10(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

void Rmpfr_urandomb(pTHX_ SV * x, ...) {
     dXSARGS;
     unsigned long i, t;

     t = items;
     --t;

     for(i = 0; i < t; ++i) {
        mpfr_urandomb(*(INT2PTR(mpfr_t *, SvIVX(SvRV(ST(i))))), *(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(ST(t))))));
        }
     XSRETURN(0);
}

void Rmpfr_random2(pTHX_ mpfr_t * p, SV * s, SV * exp) {
#if MPFR_VERSION_MAJOR > 2
     croak("Rmpfr_random2 no longer implemented. Use Rmpfr_urandom or Rmpfr_urandomb");
#else
     mpfr_random2(*p, (int)SvIV(s), (mpfr_exp_t)SvIV(exp));
#endif
}

SV * _TRmpfr_out_str(pTHX_ FILE * stream, SV * base, SV * dig, mpfr_t * p, SV * round) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
        croak("2nd argument supplied to TRmpfr_out_str is out of allowable range" );

     ret = mpfr_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     fflush(stream);
     return newSVuv(ret);
}

SV * _Rmpfr_out_str(pTHX_ mpfr_t * p, SV * base, SV * dig, SV * round) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
        croak("2nd argument supplied to Rmpfr_out_str is out of allowable range" );

     ret = mpfr_out_str(stdout, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     fflush(stdout);
     return newSVuv(ret);
}

SV * _TRmpfr_out_strS(pTHX_ FILE * stream, SV * base, SV * dig, mpfr_t * p, SV * round, SV * suff) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
       croak("2nd argument supplied to TRmpfr_out_str is out of allowable range" );

     ret = mpfr_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpfr_out_strP(pTHX_ SV * pre, FILE * stream, SV * base, SV * dig, mpfr_t * p, SV * round) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
        croak("3rd argument supplied to TRmpfr_out_str is out of allowable range" );

     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpfr_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     fflush(stream);
     return newSVuv(ret);
}

SV * _TRmpfr_out_strPS(pTHX_ SV * pre, FILE * stream, SV * base, SV * dig, mpfr_t * p, SV * round, SV * suff) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
        croak("3rd argument supplied to TRmpfr_out_str is out of allowable range" );

     fprintf(stream, "%s", SvPV_nolen(pre));
     fflush(stream);
     ret = mpfr_out_str(stream, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     fflush(stream);
     fprintf(stream, "%s", SvPV_nolen(suff));
     fflush(stream);
     return newSVuv(ret);
}

SV * _Rmpfr_out_strS(pTHX_ mpfr_t * p, SV * base, SV * dig, SV * round, SV * suff) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
       croak("2nd argument supplied to Rmpfr_out_str is out of allowable range" );

     ret = mpfr_out_str(stdout, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     printf("%s", SvPV_nolen(suff));
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpfr_out_strP(pTHX_ SV * pre, mpfr_t * p, SV * base, SV * dig, SV * round) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
        croak("3rd argument supplied to Rmpfr_out_str is out of allowable range" );

     printf("%s", SvPV_nolen(pre));
     ret = mpfr_out_str(stdout, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     fflush(stdout);
     return newSVuv(ret);
}

SV * _Rmpfr_out_strPS(pTHX_ SV * pre, mpfr_t * p, SV * base, SV * dig, SV * round, SV * suff) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_OUTPUT_BASE )
       croak("3rd argument supplied to Rmpfr_out_str is out of allowable range" );

     printf("%s", SvPV_nolen(pre));
     ret = mpfr_out_str(stdout, (int)SvIV(base), (size_t)SvUV(dig), *p, (mpfr_rnd_t)SvUV(round));
     printf("%s", SvPV_nolen(suff));
     fflush(stdout);
     return newSVuv(ret);
}

SV * TRmpfr_inp_str(pTHX_ mpfr_t * p, FILE * stream, SV * base, SV * round) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_INPUT_BASE )
        croak("3rd argument supplied to TRmpfr_inp_str is out of allowable range" );

     ret = mpfr_inp_str(*p, stream, (int)SvIV(base), (mpfr_rnd_t)SvUV(round));
     if(!ret) {
       nnum++;
       if(SvIV(get_sv("Math::MPFR::NNW", 0)))
         warn("input to TRmpfr_inp_str contains non-numeric characters");
     }
     /* fflush(stream); */
     return newSVuv(ret);
}

SV * Rmpfr_inp_str(pTHX_ mpfr_t * p, SV * base, SV * round) {
     size_t ret;

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_INPUT_BASE )
        croak("2nd argument supplied to Rmpfr_inp_str is out of allowable range" );

     ret = mpfr_inp_str(*p, stdin, (int)SvIV(base), (mpfr_rnd_t)SvUV(round));
     if(!ret) {
       nnum++;
       if(SvIV(get_sv("Math::MPFR::NNW", 0)))
         warn("input to Rmpfr_inp_str contains non-numeric characters");
     }
     /* fflush(stdin); */
     return newSVuv(ret);
}

SV * Rmpfr_gamma(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_gamma(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_zeta(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_zeta(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_zeta_ui(pTHX_ mpfr_t * a, SV * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_zeta_ui(*a, (unsigned long)SvUV(b), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_erf(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_erf(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_frac(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_frac(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_remainder(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_remainder(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_modf(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_modf(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fmod(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_fmod(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fmod_ui(pTHX_ mpfr_t * a, mpfr_t * b, unsigned long c, SV * round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_fmod_ui(*a, *b, c, (mpfr_rnd_t)SvUV(round)));
#else
     mpfr_t temp;
     int ret;
     CHECK_ROUNDING_VALUE
     mpfr_init2(temp, LONGSIZE * 8);
     mpfr_set_ui(temp, c, GMP_RNDN);
     ret = mpfr_fmod(*a, *b, temp, (mpfr_rnd_t)SvUV(round));
     mpfr_clear(temp);
     return newSViv(ret);
#endif
}

void Rmpfr_remquo(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     dXSARGS;
     long ret, q;
     CHECK_ROUNDING_VALUE
     ret = mpfr_remquo(*a, &q, *b, *c, (mpfr_rnd_t)SvUV(round));
     ST(0) = sv_2mortal(newSViv(q));
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

int Rmpfr_integer_p(mpfr_t * p) {
     return mpfr_integer_p(*p);
}

void Rmpfr_nexttoward(mpfr_t * a, mpfr_t * b) {
     mpfr_nexttoward(*a, *b);
}

void Rmpfr_nextabove(mpfr_t * p) {
     mpfr_nextabove(*p);
}

void Rmpfr_nextbelow(mpfr_t * p) {
     mpfr_nextbelow(*p);
}

SV * Rmpfr_min(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_min(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_max(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_max(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_exp(pTHX_ mpfr_t * p) {
     return newSViv(mpfr_get_exp(*p));
}

SV * Rmpfr_set_exp(pTHX_ mpfr_t * p, SV * exp) {
     return newSViv(mpfr_set_exp(*p, (mpfr_exp_t)SvIV(exp)));
}

int Rmpfr_signbit(mpfr_t * op) {
     return mpfr_signbit(*op);
}

SV * Rmpfr_setsign(pTHX_ mpfr_t * rop, mpfr_t * op, SV * sign, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_setsign(*rop, *op, SvIV(sign), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_copysign(pTHX_ mpfr_t * rop, mpfr_t * op1, mpfr_t * op2, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_copysign(*rop, *op1, *op2, (mpfr_rnd_t)SvUV(round)));
}

SV * get_refcnt(pTHX_ SV * s) {
     return newSVuv(SvREFCNT(s));
}

SV * get_package_name(pTHX_ SV * x) {
     if(sv_isobject(x)) return newSVpv(HvNAME(SvSTASH(SvRV(x))), 0);
     return newSViv(0);
}

void Rmpfr_dump(mpfr_t * a) { /* Once took a 'round' argument */
     mpfr_dump(*a);
}

SV * gmp_v(pTHX) {
#if __GNU_MP_VERSION >= 4
     return newSVpv(gmp_version, 0);
#else
     warn("From Math::MPFR::gmp_v(aTHX): 'gmp_version' is not implemented - returning '0'");
     return newSVpv("0", 0);
#endif
}

/* NEW in MPFR-2.1.0 */

SV * Rmpfr_set_ui_2exp(pTHX_ mpfr_t * a, SV * b, SV * c, SV * round) {
     return newSViv(mpfr_set_ui_2exp(*a, (unsigned long)SvUV(b), (mpfr_exp_t)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_si_2exp(pTHX_ mpfr_t * a, SV * b, SV * c, SV * round) {
     return newSViv(mpfr_set_si_2exp(*a, (long)SvIV(b), (mpfr_exp_t)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_uj_2exp(pTHX_ mpfr_t * a, SV * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_set_uj_2exp(*a, SvUV(b), SvIV(c), (mpfr_rnd_t)SvUV(round)));

#else
     croak ("Rmpfr_set_uj_2exp not implemented on this build of perl");

#endif
}

SV * Rmpfr_set_sj_2exp(pTHX_ mpfr_t * a, SV * b, SV * c, SV * round) {
     CHECK_ROUNDING_VALUE
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_set_sj_2exp(*a, SvIV(b), SvIV(c), (mpfr_rnd_t)SvUV(round)));

#else
     croak ("Rmpfr_set_sj_2exp not implemented on this build of perl");

#endif
}

SV * Rmpfr_get_z(pTHX_ mpz_t * a, mpfr_t * b, SV * round) {
#if MPFR_VERSION_MAJOR < 3
     CHECK_ROUNDING_VALUE
     mpfr_get_z(*a, *b, (mpfr_rnd_t)SvUV(round));
     return &PL_sv_undef;
#else
     return newSViv(mpfr_get_z(*a, *b, (mpfr_rnd_t)SvUV(round)));
#endif
}

SV * Rmpfr_si_sub(pTHX_ mpfr_t * a, SV * c, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     DEAL_WITH_NANFLAG_BUG
     return newSViv(mpfr_si_sub(*a, (long)SvIV(c), *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sub_si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     DEAL_WITH_NANFLAG_BUG
     return newSViv(mpfr_sub_si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_mul_si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_mul_si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_si_div(pTHX_ mpfr_t * a, SV * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_si_div(*a, (long)SvIV(b), *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_div_si(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round){
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_div_si(*a, *b, (long)SvIV(c), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sqr(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sqr(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

int Rmpfr_cmp_z(mpfr_t * a, mpz_t * b) {
     return mpfr_cmp_z(*a, *b);
}

int Rmpfr_cmp_q(mpfr_t * a, mpq_t * b) {
     return mpfr_cmp_q(*a, *b);
}

int fr_cmp_q_rounded(pTHX_ mpfr_t * a, mpq_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     mpfr_t temp;
     int ret;
     mpfr_init(temp);
     mpfr_set_q(temp, *b, (mpfr_rnd_t)SvUV(round));
     ret = mpfr_cmp(*a, temp);
     mpfr_clear(temp);
     return ret;
}

int Rmpfr_cmp_f(mpfr_t * a, mpf_t * b) {
     return mpfr_cmp_f(*a, *b);
}

int Rmpfr_zero_p(mpfr_t * a) {
     return mpfr_zero_p(*a);
}

void Rmpfr_free_cache(void) {
     mpfr_free_cache();
}

void Rmpfr_free_cache2(unsigned int way) {
#if MPFR_VERSION_MAJOR >= 4
     mpfr_free_cache2((mpfr_free_cache_t) way);
#else
     croak("Rmpfr_free_cache2 not implemented with this mpfr version (%s) - need 4.0.0 or later", MPFR_VERSION_STRING);
#endif
}

void Rmpfr_free_pool(void) {
#if MPFR_VERSION_MAJOR >= 4
     mpfr_free_pool();
#else
     croak("Rmpfr_free_pool not implemented with this mpfr version (%s) - need 4.0.0 or later", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_get_version(pTHX) {
     return newSVpv(mpfr_get_version(), 0);
}

SV * Rmpfr_get_patches(pTHX) {
     return newSVpv(mpfr_get_patches(), 0);
}

SV * Rmpfr_get_emin_min(pTHX) {
     return newSViv(mpfr_get_emin_min());
}

SV * Rmpfr_get_emin_max(pTHX) {
     return newSViv(mpfr_get_emin_max());
}

SV * Rmpfr_get_emax_min(pTHX) {
     return newSViv(mpfr_get_emax_min());
}

SV * Rmpfr_get_emax_max(pTHX) {
     return newSViv(mpfr_get_emax_max());
}

void Rmpfr_clear_erangeflag(void) {
     mpfr_clear_erangeflag();
}

int Rmpfr_erangeflag_p(void) {
     return mpfr_erangeflag_p();
}

SV * Rmpfr_rint_round(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_rint_round(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_rint_trunc(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_rint_trunc(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_rint_ceil(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_rint_ceil(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_rint_floor(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_rint_floor(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_ui(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSVuv(mpfr_get_ui(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_si(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_get_si(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_uj(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSVuv(mpfr_get_uj(*a, (mpfr_rnd_t)SvUV(round)));
#else
     croak ("Rmpfr_get_uj not implemented on this build of perl");
#endif
}

SV * Rmpfr_get_sj(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     return newSViv(mpfr_get_sj(*a, (mpfr_rnd_t)SvUV(round)));
#else
     croak ("Rmpfr_get_sj not implemented on this build of perl");
#endif
}

SV * Rmpfr_get_IV(pTHX_ mpfr_t * x, SV * round) {

     CHECK_ROUNDING_VALUE

    /* FLAGS:                                                                *
     * This will set the erange flag if *x is NaN or if *x overflows the IV  *
     * If the erangeflag does not get set, then the inexact flag will be set *
     * if *x is not an integer.                                              */

#if defined MATH_MPFR_NEED_LONG_LONG_INT

     if(mpfr_fits_uintmax_p(*x, (mpfr_rnd_t)SvNV(round)))
       return newSVuv(mpfr_get_uj(*x, (mpfr_rnd_t)SvUV(round)));
     if(mpfr_fits_intmax_p(*x, (mpfr_rnd_t)SvNV(round)))
       return newSViv(mpfr_get_sj(*x, (mpfr_rnd_t)SvUV(round)));

     if(mpfr_sgn(*x) < 0)
       return newSViv(mpfr_get_sj(*x, (mpfr_rnd_t)SvUV(round))); /* returns IV_MIN     */

     return newSVuv(mpfr_get_uj(*x, (mpfr_rnd_t)SvUV(round)));   /* returns UV_MAX, or *
                                                                  * 0 if *x is NaN     */

#else
     if(mpfr_fits_ulong_p(*x, (mpfr_rnd_t)SvNV(round)))
       return newSVuv(mpfr_get_ui(*x, (mpfr_rnd_t)SvUV(round)));
     if(mpfr_fits_slong_p(*x, (mpfr_rnd_t)SvNV(round)))
       return newSViv(mpfr_get_si(*x, (mpfr_rnd_t)SvUV(round)));

     if(mpfr_sgn(*x) < 0)
       return newSViv(mpfr_get_si(*x, (mpfr_rnd_t)SvUV(round))); /* returns IV_MIN     */

     return newSVuv(mpfr_get_ui(*x, (mpfr_rnd_t)SvUV(round)));   /* returns UV_MAX, or *
                                                                  * 0 if *x is NaN     */
#endif

}

int Rmpfr_set_IV(pTHX_ mpfr_t * x, SV * sv,  SV * round) {
     int call_uv = 0;

     CHECK_ROUNDING_VALUE

     if(SV_IS_IOK(sv)) {
       if(SvUOK(sv)) call_uv = 1;
     }
     else croak("Arg provided to Rmpfr_set_IV is not an IV");

#if defined MATH_MPFR_NEED_LONG_LONG_INT
     if(call_uv)
       return mpfr_set_uj(*x, SvUV(sv), (mpfr_rnd_t)SvNV(round));

     return mpfr_set_sj(*x, SvIV(sv), (mpfr_rnd_t)SvNV(round));

#else
     if(call_uv)
       return mpfr_set_ui(*x, SvUV(sv), (mpfr_rnd_t)SvNV(round));

     return mpfr_set_si(*x, SvIV(sv), (mpfr_rnd_t)SvNV(round));
#endif

}

void Rmpfr_init_set_IV(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_IV) /* defined in math_mpfr_include.h */

     mpfr_init(*mpfr_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
     ret = Rmpfr_set_IV(aTHX_ mpfr_t_obj, q, round);
     SvREADONLY_on(obj);
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

void Rmpfr_init_set_IV_nobless(pTHX_ SV * q, SV * round) {
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_IV_nobless) /* defined in math_mpfr_include.h */

     mpfr_init(*mpfr_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
     ret = Rmpfr_set_IV(aTHX_ mpfr_t_obj, q, round);
     SvREADONLY_on(obj);
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
}

SV * Rmpfr_get_NV(pTHX_ mpfr_t * x, SV * round) {

     CHECK_ROUNDING_VALUE

#if defined(CAN_PASS_FLOAT128)

     return newSVnv(mpfr_get_float128(*x, (mpfr_rnd_t)SvUV(round)));

#elif defined(USE_QUADMATH)

     mpfr_t t;
     int i, c = 0;
     mpfr_prec_t exp, bits = 113;
     mpfr_rnd_t r = (mpfr_rnd_t)SvUV(round);
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

     if(!mpfr_regular_p(*x)) return newSVnv((float128)mpfr_get_d(*x, GMP_RNDZ));

     exp = mpfr_get_exp(*x);
     if(exp < -16381)
       bits = exp + 16494;

     if(bits <= 0) {
       mpfr_init2(t, 53);
       if(mpfr_sgn(*x) > 0) {	/* positive */
         mpfr_set_str(t, "0.1e-16494", 2, GMP_RNDZ);
         c = mpfr_cmp(*x, t);
         mpfr_clear(t);
         if(c <= 0) {
           if(r == GMP_RNDN || r == GMP_RNDD || r == GMP_RNDZ) return newSVnv(0.0Q);
           return newSVnv(6.475175119438025110924438958227646552e-4966Q);
         }
         else {
           if(r == GMP_RNDN || r == GMP_RNDU || r == MPFR_RNDA)
             return newSVnv(6.475175119438025110924438958227646552e-4966Q);
           return newSVnv(0.0Q);
         }
       }
       else {			/* negative */
         mpfr_set_str(t, "-0.1e-16494", 2, GMP_RNDZ);
         c = mpfr_cmp(*x, t);
         mpfr_clear(t);
         if(c >= 0) {
           if(r == GMP_RNDN || r == GMP_RNDU || r == GMP_RNDZ) return newSVnv(0.0Q);
           return newSVnv(-6.475175119438025110924438958227646552e-4966Q);
         }
         if(c < 0) {
           if(r == GMP_RNDN || r == GMP_RNDD || r == MPFR_RNDA)
             return newSVnv(-6.475175119438025110924438958227646552e-4966Q);
           return newSVnv(0.0Q);
         }
       }
     }
     else {
       mpfr_init2(t, bits);
       mpfr_set(t, *x, r);
     }

     Newxz(out, 115, char);
     if(out == NULL) croak("Failed to allocate memory in Rmpfr_get_NV function");

     mpfr_get_str(out, &exp, 2, 113, t, (mpfr_rnd_t)SvUV(round));

     mpfr_clear(t);

     if(out[0] == '-') {
       sign = -1.0Q;
       out++;
       c++;
     }
     else {
       if(out[0] == '+') {
         out++;
         c++;
       }
     }

     for(i = 0; i < bits; i++) {
       if(out[i] == '1') ret += add_on[i];
     }

     if(c) out--;
     Safefree(out);

     c = exp < -16381 ? exp + 16381 : 0;	/* function has already returned if exp < -16494 */

     if(c) { 			/* powq(2.0Q, exp) will be zero - so do the calculation in 2 steps */
       ret *= powq(2.0Q, c);
       exp -= c;		/* exp += abs(c) */
     }

     ret *= powq(2.0Q, exp - 113);
     return newSVnv(ret * sign);

#elif defined(USE_LONG_DOUBLE)
#  if defined(LD_SUBNORMAL_BUG)

       if(mpfr_get_exp(*x) < -16381 && mpfr_regular_p(*x) && mpfr_get_exp(*x) >= -16445 ) {
         warn("\n mpfr_get_ld is buggy (subnormal values only)\n for this version (%s) of the MPFR library\n", MPFR_VERSION_STRING);
         croak(" Version 3.1.5 or later is required");
       }

       return newSVnv(mpfr_get_ld(*x, (mpfr_rnd_t)SvUV(round)));

#  else
       return newSVnv(mpfr_get_ld(*x, (mpfr_rnd_t)SvUV(round)));
#  endif
#else
     return newSVnv(mpfr_get_d(*x, (mpfr_rnd_t)SvUV(round)));
#endif

}

SV * Rmpfr_fits_ulong_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
#if defined(MPFR_VERSION) && MPFR_VERSION > NEG_ZERO_BUG
     return newSVuv(mpfr_fits_ulong_p(*a, (mpfr_rnd_t)SvUV(round)));
#else
     if((mpfr_rnd_t)SvUV(round) < 3) {
       if((mpfr_rnd_t)SvUV(round) == 0) {
         if((mpfr_cmp_d(*a, -0.5) >= 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
       else {
         if((mpfr_cmp_d(*a, -1.0) > 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
     }
     return newSVuv(mpfr_fits_ulong_p(*a, (mpfr_rnd_t)SvUV(round)));
#endif
}

SV * Rmpfr_fits_slong_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSVuv(mpfr_fits_slong_p(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fits_ushort_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
#if defined(MPFR_VERSION) && MPFR_VERSION > NEG_ZERO_BUG
     return newSVuv(mpfr_fits_ushort_p(*a, (mpfr_rnd_t)SvUV(round)));
#else
     if((mpfr_rnd_t)SvUV(round) < 3) {
       if((mpfr_rnd_t)SvUV(round) == 0) {
         if((mpfr_cmp_d(*a, -0.5) >= 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
       else {
         if((mpfr_cmp_d(*a, -1.0) > 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
     }
     return newSVuv(mpfr_fits_ushort_p(*a, (mpfr_rnd_t)SvUV(round)));
#endif
}

SV * Rmpfr_fits_sshort_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSVuv(mpfr_fits_sshort_p(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fits_uint_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
#if defined(MPFR_VERSION) && MPFR_VERSION > NEG_ZERO_BUG
     return newSVuv(mpfr_fits_uint_p(*a, (mpfr_rnd_t)SvUV(round)));
#else
     if((mpfr_rnd_t)SvUV(round) < 3) {
       if((mpfr_rnd_t)SvUV(round) == 0) {
         if((mpfr_cmp_d(*a, -0.5) >= 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
       else {
         if((mpfr_cmp_d(*a, -1.0) > 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
     }
     return newSVuv(mpfr_fits_uint_p(*a, (mpfr_rnd_t)SvUV(round)));
#endif
}

SV * Rmpfr_fits_sint_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSVuv(mpfr_fits_sint_p(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fits_uintmax_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
#if defined(MPFR_VERSION) && MPFR_VERSION > NEG_ZERO_BUG
     return newSVuv(mpfr_fits_uintmax_p(*a, (mpfr_rnd_t)SvUV(round)));
#else
     if(mpfr_zero_p(*a)) return newSVuv(1);
     if((mpfr_rnd_t)SvUV(round) < 3) {
       if((mpfr_rnd_t)SvUV(round) == 0) {
         if((mpfr_cmp_d(*a, -0.5) >= 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
       else {
         if((mpfr_cmp_d(*a, -1.0) > 0) && (mpfr_cmp_d(*a, 0.0) <= 0)) return newSVuv(1);
       }
     }
     return newSVuv(mpfr_fits_uintmax_p(*a, (mpfr_rnd_t)SvUV(round)));
#endif
}

SV * Rmpfr_fits_intmax_p(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSVuv(mpfr_fits_intmax_p(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_fits_IV_p(pTHX_ mpfr_t * x, SV * round) {
     CHECK_ROUNDING_VALUE
#if defined(MATH_MPFR_NEED_LONG_LONG_INT)
    if(mpfr_fits_uintmax_p(*x, (mpfr_rnd_t)SvUV(round))
        ||
       mpfr_fits_intmax_p (*x, (mpfr_rnd_t)SvUV(round))) return newSViv(1);
    return newSViv(0);
#else
    if(mpfr_fits_ulong_p(*x, (mpfr_rnd_t)SvUV(round))
        ||
       mpfr_fits_slong_p (*x, (mpfr_rnd_t)SvUV(round))) return newSViv(1);
    return newSViv(0);

#endif

}


SV * Rmpfr_strtofr(pTHX_ mpfr_t * a, SV * str, SV * base, SV * round) {
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     CHECK_ROUNDING_VALUE

     if( FAILS_CHECK_INPUT_BASE )
       croak("3rd argument supplied to Rmpfr_strtofr is out of allowable range");

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(str));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*a);
           return newSViv(0);
         }

         mpfr_set_inf(*a, inf_or_nan);
         return newSViv(0);
       }
       else {
         return newSViv(mpfr_strtofr(*a, SvPV_nolen(str), NULL, (int)SvIV(base), (mpfr_rnd_t)SvUV(round)));
       }
#else
       return newSViv(mpfr_strtofr(*a, SvPV_nolen(str), NULL, (int)SvIV(base), (mpfr_rnd_t)SvUV(round)));

#endif
}

void Rmpfr_set_erangeflag(void) {
     mpfr_set_erangeflag();
}

void Rmpfr_set_underflow(void) {
     mpfr_set_underflow();
}

void Rmpfr_set_overflow(void) {
     mpfr_set_overflow();
}

void Rmpfr_set_nanflag(void) {
     mpfr_set_nanflag();
}

void Rmpfr_set_inexflag(void) {
     mpfr_set_inexflag();
}

SV * Rmpfr_erfc(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_erfc(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_j0(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_j0(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_j1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_j1(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_jn(pTHX_ mpfr_t * a, SV * n, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_jn(*a, (long)SvIV(n), *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_y0(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_y0(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_y1(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_y1(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_yn(pTHX_ mpfr_t * a, SV * n, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_yn(*a, (long)SvIV(n), *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_atan2(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_atan2(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_atan2u(pTHX_ mpfr_t *a, mpfr_t *b, mpfr_t *c, unsigned long d, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_atan2u(*a, *b, *c, d, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_atan2u function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_atan2pi(pTHX_ mpfr_t *a, mpfr_t *b, mpfr_t *c, SV *round) {
#if MPFR_VERSION >= 262656
     return newSViv(mpfr_atan2pi(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_atan2pi function not implemented until mpfr-4.2.0. (You have only version %s) ", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_pow_z(pTHX_ mpfr_t * a, mpfr_t * b, mpz_t * c,  SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_pow_z(*a, *b, *c, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_subnormalize(pTHX_ mpfr_t * a, SV * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_subnormalize(*a, (int)SvIV(b), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_const_catalan(pTHX_ mpfr_t * a, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_const_catalan(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sec(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sec(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_csc(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_csc(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_cot(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_cot(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_root(pTHX_ mpfr_t * a, mpfr_t * b, SV * c, SV * round) {
#if MPFR_VERSION_MAJOR >= 4
     croak("Rmpfr_root is deprecated, and now removed - use Rmpfr_rootn_ui instead");
#else
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_root(*a, *b, (unsigned long)SvUV(c), (mpfr_rnd_t)SvUV(round)));
#endif
}

SV * Rmpfr_eint(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_eint(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_li2(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_li2(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_f(pTHX_ mpf_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_get_f(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_sech(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_sech(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_csch(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_csch(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_coth(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
     return newSViv(mpfr_coth(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_lngamma(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     CHECK_ROUNDING_VALUE
#if !defined(MPFR_VERSION) || (defined(MPFR_VERSION) && MPFR_VERSION <= LNGAMMA_BUG)
     if(!mpfr_nan_p(*b) && mpfr_sgn(*b) <= 0) {
       mpfr_set_inf(*a, 1);
       return newSViv(0);
     }
#endif
     return newSViv(mpfr_lngamma(*a, *b, (mpfr_rnd_t)SvUV(round)));
}

void Rmpfr_lgamma(pTHX_ mpfr_t * a, mpfr_t * b, SV * round) {
     dXSARGS;
     int ret, signp;
     CHECK_ROUNDING_VALUE
     ret = mpfr_lgamma(*a, &signp, *b, (mpfr_rnd_t)SvUV(round));
     ST(0) = sv_2mortal(newSViv(signp));
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
}

SV * _MPFR_VERSION(pTHX) {
#if defined(MPFR_VERSION)
     return newSVuv(MPFR_VERSION);
#else
     return &PL_sv_undef;
#endif
}

SV * _MPFR_VERSION_MAJOR(pTHX) {
     return newSVuv(MPFR_VERSION_MAJOR);
}

SV * _MPFR_VERSION_MINOR(pTHX) {
     return newSVuv(MPFR_VERSION_MINOR);
}

SV * _MPFR_VERSION_PATCHLEVEL(pTHX) {
     return newSVuv(MPFR_VERSION_PATCHLEVEL);
}

SV * _MPFR_VERSION_STRING(pTHX) {
     return newSVpv(MPFR_VERSION_STRING, 0);
}

SV * RMPFR_VERSION_NUM(pTHX_ SV * a, SV * b, SV * c) {
     return newSVuv(MPFR_VERSION_NUM((unsigned long)SvUV(a), (unsigned long)SvUV(b), (unsigned long)SvUV(c)));
}

SV * Rmpfr_sum(pTHX_ mpfr_t * rop, SV * avref, SV * len, SV * round) {
     mpfr_ptr *p;
     SV ** elem;
     int ret, i;
     unsigned long s = (unsigned long)SvUV(len);

     if(s > av_len((AV*)SvRV(avref)) + 1)croak("2nd last arg to Rmpfr_sum is greater than the size of the array");

     CHECK_ROUNDING_VALUE

     Newx(p, s, mpfr_ptr);
     if(p == NULL) croak("Unable to allocate memory in Rmpfr_sum");

     for(i = 0; i < s; ++i) {
        elem = av_fetch((AV*)SvRV(avref), i, 0);
        p[i] = *(INT2PTR(mpfr_t *, SvIVX(SvRV(*elem))));
     }

     ret = mpfr_sum(*rop, p, s, (mpfr_rnd_t)SvUV(round));

     Safefree(p);
     return newSViv(ret);
}

void _fr_to_q(mpq_t * q, mpfr_t * fr) {
   mpfr_exp_t exponent, denpow;
   char * str;
   size_t numlen;

   if(!mpfr_number_p(*fr)) {
     if(mpfr_nan_p(*fr))
       croak ("In Math::MPFR::_fr_to_q, cannot coerce a NaN to a Math::GMPq value");
     croak ("In Math::MPFR::_fr_to_q, cannot coerce an Inf to a Math::GMPq value");
   }

   str = mpfr_get_str(NULL, &exponent, 2, 0, *fr, GMP_RNDN);
   mpz_set_str(mpq_numref(*q), str, 2);
   mpz_set_ui (mpq_denref(*q), 1);
   mpfr_free_str(str);
   numlen = mpz_sizeinbase(mpq_numref(*q), 2);
   denpow = (mpfr_exp_t)(numlen - exponent);

   if(denpow < 0) {
     mpz_mul_2exp(mpq_numref(*q), mpq_numref(*q), -denpow);
   }
   else {
     mpz_mul_2exp(mpq_denref(*q), mpq_denref(*q), denpow);
   }

   mpq_canonicalize(*q);
}

int Rmpfr_q_div(mpfr_t * rop, mpq_t * q, mpfr_t * fr, int round) {
    mpq_t t;
    int ret;

    /* Handle Inf, NaN and zero values of *fr */
    if(!mpfr_regular_p(*fr)) {
      ret = mpfr_si_div(*rop, mpz_sgn(mpq_numref(*q)), *fr, (mpfr_rnd_t)round);
      return ret;
    }

    mpq_init(t);

    _fr_to_q(&t, fr);
    mpq_div(t, *q, t);
    ret = mpfr_set_q(*rop, t, (mpfr_rnd_t)round);
    mpq_clear(t);
    return ret;
}

int Rmpfr_z_div(mpfr_t * rop, mpz_t * z, mpfr_t * fr, int round) {
    mpq_t t, tz;
    int ret;

    /* Handle Inf, NaN and zero values of *fr */
    if(!mpfr_regular_p(*fr)) {
      ret = mpfr_si_div(*rop, mpz_sgn(*z), *fr, (mpfr_rnd_t)round);
      return ret;
    }

    mpq_init(t);
    mpq_init(tz);
    mpq_set_z(tz, *z);

    _fr_to_q(&t, fr);
    mpq_div(t, tz, t);
    ret = mpfr_set_q(*rop, t, (mpfr_rnd_t)round);
    mpq_clear(t);
    mpq_clear(tz);
    return ret;
}

SV * overload_mul(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj, t;
     SV * obj_ref, * obj;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_mul) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_mul(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_mul_ui(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }

       mpfr_mul_si(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_mul");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*mpfr_t_obj);
           mpfr_set_nanflag();
           return obj_ref;
         }

         mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_mul subroutine");}

       mpfr_mul(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *mpfr_t_obj, __gmpfr_default_rounding_mode);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);
       mpfr_mul(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);
       mpfr_mul(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else
       mpfr_mul_d(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), (double)SvNVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_mul(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz")) {

         mpfr_mul_z(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                 *(INT2PTR(mpz_t * , SvIVX(SvRV(b)))),
                                 __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {

         mpfr_mul_q(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                 *(INT2PTR(mpq_t * , SvIVX(SvRV(b)))),
                                 __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_mul(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_mul");
}

SV * overload_add(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj, t;
     SV * obj_ref, * obj;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_add) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_add(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else

     DEAL_WITH_NANFLAG_BUG_OVERLOADED
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_add_ui(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }

       mpfr_add_si(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_add");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*mpfr_t_obj);
           mpfr_set_nanflag();
           return obj_ref;
         }

         mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_add subroutine");}

       mpfr_add(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *mpfr_t_obj, __gmpfr_default_rounding_mode);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, GMP_RNDN);
       mpfr_add(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);
       mpfr_add(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else
       mpfr_add_d(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), (double)SvNVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_add(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                               *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))),
                               __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_add_z(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                 *(INT2PTR(mpz_t * , SvIVX(SvRV(b)))),
                                 __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_add_q(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                 *(INT2PTR(mpq_t * , SvIVX(SvRV(b)))),
                                 __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_add(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_add");
}

SV * overload_sub(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj, t;
     SV * obj_ref, * obj;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_sub) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       if(SWITCH_ARGS) mpfr_sub(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_sub(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else
     DEAL_WITH_NANFLAG_BUG_OVERLOADED
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(SWITCH_ARGS) mpfr_ui_sub(*mpfr_t_obj, SvUVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
         else mpfr_sub_ui(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }

       if(SWITCH_ARGS) mpfr_si_sub(*mpfr_t_obj, SvIVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_sub_si(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_sub");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*mpfr_t_obj);
           mpfr_set_nanflag();
           return obj_ref;
         }

         mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_sub subroutine");}

       if(SWITCH_ARGS) mpfr_sub(*mpfr_t_obj, *mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_sub(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *mpfr_t_obj, __gmpfr_default_rounding_mode);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, GMP_RNDN);
       if(SWITCH_ARGS)
         mpfr_sub(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else
         mpfr_sub(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }
#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);
       if(SWITCH_ARGS) mpfr_sub(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_sub(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else

       if(SWITCH_ARGS) mpfr_d_sub(*mpfr_t_obj, SvNVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_sub_d(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvNVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_sub(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_sub_z(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                      *(INT2PTR(mpz_t * , SvIVX(SvRV(b)))),
                                      __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfr_neg(*mpfr_t_obj, *mpfr_t_obj, GMP_RNDN);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_sub_q(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                      *(INT2PTR(mpq_t * , SvIVX(SvRV(b)))),
                                      __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfr_neg(*mpfr_t_obj, *mpfr_t_obj, GMP_RNDN);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfr_sub(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
         else mpfr_sub(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_sub function");
}

SV * overload_div(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj, t;
     SV * obj_ref, * obj;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_div) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       if(SWITCH_ARGS) mpfr_div(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_div(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(SWITCH_ARGS) mpfr_ui_div(*mpfr_t_obj, SvUVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
         else mpfr_div_ui(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }

       if(SWITCH_ARGS) mpfr_si_div(*mpfr_t_obj, SvIVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_div_si(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_div");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*mpfr_t_obj);
           mpfr_set_nanflag();
           return obj_ref;
         }

         mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_div subroutine");}

       if(SWITCH_ARGS) mpfr_div(*mpfr_t_obj, *mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_div(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *mpfr_t_obj, __gmpfr_default_rounding_mode);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, GMP_RNDN);
       if(SWITCH_ARGS)
         mpfr_div(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else
         mpfr_div(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);
       if(SWITCH_ARGS) mpfr_div(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_div(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else

       if(SWITCH_ARGS) mpfr_d_div(*mpfr_t_obj, SvNVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
       else mpfr_div_d(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvNVX(b), __gmpfr_default_rounding_mode);
       return obj_ref;
     }

#endif

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_div(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz")) {

         if(SWITCH_ARGS) {
           Rmpfr_z_div(mpfr_t_obj, INT2PTR(mpz_t * , SvIVX(SvRV(b))),
                                   INT2PTR(mpfr_t *, SvIVX(SvRV(a))),
                                   __gmpfr_default_rounding_mode);
         }
         else {
           mpfr_div_z(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                   *(INT2PTR(mpz_t * , SvIVX(SvRV(b)))),
                                   __gmpfr_default_rounding_mode);
         }
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {

         if(SWITCH_ARGS) {
           Rmpfr_q_div(mpfr_t_obj, INT2PTR(mpq_t * , SvIVX(SvRV(b))),
                                   INT2PTR(mpfr_t *, SvIVX(SvRV(a))),
                                   __gmpfr_default_rounding_mode);
         }
         else {
           mpfr_div_q(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))),
                                   *(INT2PTR(mpq_t * , SvIVX(SvRV(b)))),
                                   __gmpfr_default_rounding_mode);
         }
         return obj_ref;
       }

       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfr_div(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), __gmpfr_default_rounding_mode);
         else mpfr_div(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_div function");
}

SV * overload_copy(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_copy) /* defined in math_mpfr_include.h */

     mpfr_init2(*mpfr_t_obj, mpfr_get_prec(*p));
     mpfr_set(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_abs(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_abs) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     mpfr_abs(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_gt(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)){
       mpfr_set_erangeflag();
       return newSVuv(0);
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_gt");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_gt subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_gt subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return newSViv(0);
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
         mpfr_set_erangeflag();
         return newSVuv(0);
       }

       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
          return newSVuv(mpfr_greater_p(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b))))));
       }

       if(strEQ(h, "Math::GMPq")) {
         ret = mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
         ret = mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret > 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_gt");
}

SV * overload_gte(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)){
       mpfr_set_erangeflag();
       return newSVuv(0);
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_gte");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_gte subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_gte subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return newSViv(0);
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
         mpfr_set_erangeflag();
         return newSVuv(0);
       }

       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret >= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         return newSVuv(mpfr_greaterequal_p(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b))))));
         }

       if(strEQ(h, "Math::GMPq")) {
         ret = mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
         ret = mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret >= 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_gte");
}

SV * overload_lt(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)){
       mpfr_set_erangeflag();
       return newSVuv(0);
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_lt");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_lt subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_lt subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return newSViv(0);
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
         mpfr_set_erangeflag();
         return newSVuv(0);
       }

       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         return newSVuv(mpfr_less_p(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b))))));
       }

       if(strEQ(h, "Math::GMPq")) {
         ret = mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
         ret = mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret < 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_lt");
}

SV * overload_lte(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)){
       mpfr_set_erangeflag();
       return newSVuv(0);
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_lte(aTHX_ <=)");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_lte subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_lte subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return newSViv(0);
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
         mpfr_set_erangeflag();
         return newSVuv(0);
       }

       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret <= 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR"))
         return newSVuv(mpfr_lessequal_p(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b))))));

       if(strEQ(h, "Math::GMPq")) {
         ret = mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
         ret = mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))));
         if(ret <= 0) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_lte");
}

SV * overload_spaceship(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)) {
       mpfr_set_erangeflag();
       return &PL_sv_undef;
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(-1);
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_spaceship");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return &PL_sv_undef;
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_spaceship subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return &PL_sv_undef;
         }
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_spaceship subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return &PL_sv_undef;
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(-1);
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {

       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
       mpfr_set_erangeflag();
       return &PL_sv_undef;
       }

       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(SWITCH_ARGS) ret *= -1;
       if(ret < 0) return newSViv(-1);
       if(ret > 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         return newSViv(mpfr_cmp(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b))))));
       }

       if(strEQ(h, "Math::GMPq")) {
         return newSViv(mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b))))));
       }

       if(strEQ(h, "Math::GMPz")) {
         return newSViv(mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b))))));
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_spaceship");
}

SV * overload_equiv(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)){
       mpfr_set_erangeflag();
       return newSVuv(0);
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }


     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_equiv");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_equiv subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return newSViv(0);
         }
       }
#else
       ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_equiv subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return newSViv(0);
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_NOK(b)) {
       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
         mpfr_set_erangeflag();
         return newSVuv(0);
       }

       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(ret == 0) return newSViv(1);
       return newSViv(0);
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         return newSVuv(mpfr_equal_p(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b))))));
       }

       if(strEQ(h, "Math::GMPq")) {
         if(mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))))) return newSViv(0);
         return newSViv(1);
       }

       if(strEQ(h, "Math::GMPz")) {
         if(mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))))) return newSViv(0);
         return newSViv(1);
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_equiv");
}

SV * overload_not_equiv(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     if(mpfr_nan_p(*a)){
       mpfr_set_erangeflag();
       return newSVuv(1);
     }

     if(SV_IS_IOK(b)) {
       ret = Rmpfr_cmp_IV(aTHX_ a, b);
       if(ret != 0) return newSViv(1);
       return newSViv(0);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_not_equiv");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_init(t);
           mpfr_set_inf(t, inf_or_nan);
         }
         else { /* it's a NaN */
           mpfr_set_erangeflag();
           return newSViv(1);
         }
       }
       else {
         ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

         NON_NUMERIC_CHAR_CHECK, "overload_not_equiv subroutine");}

         if(mpfr_nan_p(t)) {
           mpfr_clear(t);
           mpfr_set_erangeflag();
           return newSViv(1);
         }
       }
#else
       ret = mpfr_init_set_str(t, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

       NON_NUMERIC_CHAR_CHECK, "overload_not_equiv subroutine");}

       if(mpfr_nan_p(t)) {
         mpfr_clear(t);
         mpfr_set_erangeflag();
         return newSViv(1);
       }
#endif
       ret = mpfr_cmp(*a, t);
       mpfr_clear(t);
       if(ret != 0) return newSViv(1);
       return newSViv(0);
       }

     if(SV_IS_NOK(b)) {
       if(SvNVX(b) != SvNVX(b)) { /* it's a NaN */
         mpfr_set_erangeflag();
         return newSVuv(1);
       }
       ret = Rmpfr_cmp_NV(aTHX_ a, b);
       if(ret != 0) return newSViv(1);
       return newSViv(0);
     }


     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         if(mpfr_equal_p(*a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))))) return newSViv(0);
         return newSViv(1);
       }

       if(strEQ(h, "Math::GMPq")) {
         if(mpfr_cmp_q(*a, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))))) return newSViv(1);
         return newSViv(0);
       }

       if(strEQ(h, "Math::GMPz")) {
         if(mpfr_cmp_z(*a, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))))) return newSViv(1);
         return newSViv(0);
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_not_equiv");
}

SV * overload_true(pTHX_ mpfr_t *a, SV *b, SV * third) {
     if(mpfr_nan_p(*a)) return newSVuv(0);
     if(mpfr_cmp_ui(*a, 0)) return newSVuv(1);
     return newSVuv(0);
}

SV * overload_not(pTHX_ mpfr_t * a, SV * b, SV * third) {
     if(mpfr_nan_p(*a)) return newSViv(1);
     if(mpfr_cmp_ui(*a, 0)) return newSViv(0);
     return newSViv(1);
}

SV * overload_sqrt(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_sqrt) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     /* No - this was wrong. If a negative value is supplied, a NaN should be returned instad */
     /* if(mpfr_cmp_ui(*p, 0) < 0) croak("Negative value supplied as argument to overload_sqrt"); */

     mpfr_sqrt(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_pow(pTHX_ SV * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj, t;
     SV * obj_ref, * obj;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_pow) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       if(SWITCH_ARGS) mpfr_pow(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
       else mpfr_pow(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         if(SWITCH_ARGS) mpfr_ui_pow(*mpfr_t_obj, SvUVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
         else mpfr_pow_ui(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }

       /* Need to do it this way as there's no mpfr_si_pow function */
       if(SvIV(b) >= 0) {
         if(SWITCH_ARGS) mpfr_ui_pow(*mpfr_t_obj, SvUVX(b), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
         else mpfr_pow_ui(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(NO_SWITCH_ARGS) {
         mpfr_pow_si(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvIV(b), __gmpfr_default_rounding_mode);
         return obj_ref;
       }
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_pow");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(*mpfr_t_obj);
           mpfr_set_nanflag();
           return obj_ref;
         }

         mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_pow subroutine");}

       if(SWITCH_ARGS) mpfr_pow(*mpfr_t_obj, *mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
       else mpfr_pow(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *mpfr_t_obj, __gmpfr_default_rounding_mode);
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);

#else

       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);

#endif

       if(SWITCH_ARGS) mpfr_pow(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
       else mpfr_pow(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_pow(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPz")) {
         if(SWITCH_ARGS) {
           mpfr_init2(t, (mpfr_prec_t)mpz_sizeinbase(*(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), 2));
           mpfr_set_z(t, *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
           mpfr_pow(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
           mpfr_clear(t);
         }
         else mpfr_pow_z(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p     )))),
                                      *(INT2PTR(mpz_t * , SvIVX(SvRV(b)))),
                                      __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_set_q(*mpfr_t_obj, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfr_pow(*mpfr_t_obj, *mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
         else mpfr_pow(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *mpfr_t_obj, __gmpfr_default_rounding_mode);
         return obj_ref;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS) mpfr_pow(*mpfr_t_obj, t, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), __gmpfr_default_rounding_mode);
         else mpfr_pow(*mpfr_t_obj, *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_pow.");
}

SV * overload_log(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_log) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     mpfr_log(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_exp(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_exp) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     mpfr_exp(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */;
     return obj_ref;
}

SV * overload_sin(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_sin) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     mpfr_sin(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_cos(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_cos) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     mpfr_cos(*mpfr_t_obj, *p, __gmpfr_default_rounding_mode);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_int(pTHX_ mpfr_t * p, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_int) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

     mpfr_trunc(*mpfr_t_obj, *p);
     OBJ_READONLY_ON /*defined in math_mpfr_include.h */
     return obj_ref;
}

SV * overload_atan2(pTHX_ mpfr_t * a, SV * b, SV * third) {
     mpfr_t * mpfr_t_obj, t;
     SV * obj_ref, * obj;
#ifdef _WIN32_BIZARRE_INFNAN
     int ret, inf_or_nan;
#else
     int ret;
#endif

     NEW_MATH_MPFR_OBJECT("Math::MPFR",overload_atan2) /* defined in math_mpfr_include.h */
     mpfr_init(*mpfr_t_obj);

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       if(SWITCH_ARGS){
         mpfr_atan2(*mpfr_t_obj, t, *a, __gmpfr_default_rounding_mode);
       }
       else {
         mpfr_atan2(*mpfr_t_obj, *a, t, __gmpfr_default_rounding_mode);
       }
       mpfr_clear(t);
       OBJ_READONLY_ON /*defined in math_mpfr_include.h */
       return obj_ref;
     }

#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_init2(t, 8 * sizeof(long));
         mpfr_set_ui(t, SvUVX(b), __gmpfr_default_rounding_mode);
         if(SWITCH_ARGS){
           mpfr_atan2(*mpfr_t_obj, t, *a, __gmpfr_default_rounding_mode);
         }
         else {
           mpfr_atan2(*mpfr_t_obj, *a, t, __gmpfr_default_rounding_mode);
         }
         mpfr_clear(t);
         OBJ_READONLY_ON /*defined in math_mpfr_include.h */
         return obj_ref;
       }

       mpfr_init2(t, 8 * sizeof(long));
       mpfr_set_si(t, SvIVX(b), __gmpfr_default_rounding_mode);
       if(SWITCH_ARGS){
         mpfr_atan2(*mpfr_t_obj, t, *a, __gmpfr_default_rounding_mode);
       }
       else {
         mpfr_atan2(*mpfr_t_obj, *a, t, __gmpfr_default_rounding_mode);
       }
       mpfr_clear(t);
       OBJ_READONLY_ON /*defined in math_mpfr_include.h */
       return obj_ref;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_atan2");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       if(inf_or_nan) {
         if(inf_or_nan != 2) {
           mpfr_set_inf(*mpfr_t_obj, inf_or_nan);
         }
         /* else we want *mpfr_t_obj to be a NaN ... which it already is !! :-) */
       }
       else {
         ret = mpfr_init_set_str(*mpfr_t_obj, (char *)SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_set_str(*mpfr_t_obj, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
#endif

       NON_NUMERIC_CHAR_CHECK, "overload_atan2");}

       if(SWITCH_ARGS){
         mpfr_atan2(*mpfr_t_obj, *mpfr_t_obj, *a, __gmpfr_default_rounding_mode);
         }
       else {
         mpfr_atan2(*mpfr_t_obj, *a, *mpfr_t_obj, __gmpfr_default_rounding_mode);
         }
       OBJ_READONLY_ON /*defined in math_mpfr_include.h */
       return obj_ref;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)
       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);
#elif defined(USE_LONG_DOUBLE)
       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);
#else
       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);
#endif

       if(SWITCH_ARGS){
         mpfr_atan2(*mpfr_t_obj, t, *a, __gmpfr_default_rounding_mode);
       }
       else {
         mpfr_atan2(*mpfr_t_obj, *a, t, __gmpfr_default_rounding_mode);
       }
       mpfr_clear(t);
       OBJ_READONLY_ON /*defined in math_mpfr_include.h */
       return obj_ref;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_atan2(*mpfr_t_obj, *a, *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         OBJ_READONLY_ON /*defined in math_mpfr_include.h */
         return obj_ref;
       }
     }

     croak("Invalid argument supplied to Math::MPFR::overload_atan2 function");
}

/* Finish typemapping */

SV * Rmpfr_randinit_default_nobless(pTHX) {
     gmp_randstate_t * state;
     SV * obj_ref, * obj;

     Newx(state, 1, gmp_randstate_t);
     if(state == NULL) croak("Failed to allocate memory in Rmpfr_randinit_default function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_default(*state);

     sv_setiv(obj, INT2PTR(IV,state));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfr_randinit_mt_nobless(pTHX) {
     gmp_randstate_t * rand_obj;
     SV * obj_ref, * obj;

     Newx(rand_obj, 1, gmp_randstate_t);
     if(rand_obj == NULL) croak("Failed to allocate memory in Math::GMPz::Random::Rmpfr_randinit_mt function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     gmp_randinit_mt(*rand_obj);

     sv_setiv(obj, INT2PTR(IV, rand_obj));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfr_randinit_lc_2exp_nobless(pTHX_ SV * a, SV * c, SV * m2exp ) {
     gmp_randstate_t * state;
     mpz_t aa;
     SV * obj_ref, * obj;

     Newx(state, 1, gmp_randstate_t);
     if(state == NULL) croak("Failed to allocate memory in Rmpfr_randinit_lc_2exp function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);
     if(sv_isobject(a)) {
       const char* h = HvNAME(SvSTASH(SvRV(a)));

       if(strEQ(h, "Math::GMP") ||
          strEQ(h, "GMP::Mpz")  ||
          strEQ(h, "Math::GMPz"))
            gmp_randinit_lc_2exp(*state, *(INT2PTR(mpz_t *, SvIVX(SvRV(a)))), (unsigned long)SvUV(c), (unsigned long)SvUV(m2exp));
       else croak("First arg to Rmpfr_randinit_lc_2exp is of invalid type");
     }

     else {
       if(!mpz_init_set_str(aa, SvPV_nolen(a), 0)) {
         gmp_randinit_lc_2exp(*state, aa, (unsigned long)SvUV(c), (unsigned long)SvUV(m2exp));
         mpz_clear(aa);
       }
       else croak("Seedstring supplied to Rmpfr_randinit_lc_2exp is not a valid number");
     }

     sv_setiv(obj, INT2PTR(IV,state));
     SvREADONLY_on(obj);
     return obj_ref;
}

SV * Rmpfr_randinit_lc_2exp_size_nobless(pTHX_ SV * size) {
     gmp_randstate_t * state;
     SV * obj_ref, * obj;

     if(SvUV(size) > 128) croak("The argument supplied to Rmpfr_randinit_lc_2exp_size_nobless function is too large - ie greater than 128");

     Newx(state, 1, gmp_randstate_t);
     if(state == NULL) croak("Failed to allocate memory in Rmpfr_randinit_lc_2exp_size_nobless function");
     obj_ref = newSV(0);
     obj = newSVrv(obj_ref, NULL);

     if(gmp_randinit_lc_2exp_size(*state, (unsigned long)SvUV(size))) {
       sv_setiv(obj, INT2PTR(IV,state));
       SvREADONLY_on(obj);
       return obj_ref;
       }

     croak("Rmpfr_randinit_lc_2exp_size_nobless function failed");
}

void Rmpfr_randclear(pTHX_ SV * p) {
     gmp_randclear(*(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(p)))));
     Safefree(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(p))));
}

void Rmpfr_randseed(pTHX_ SV * state, SV * seed) {
     mpz_t s;

     if(sv_isobject(seed)) {
       const char* h = HvNAME(SvSTASH(SvRV(seed)));

       if(strEQ(h, "Math::GMP") ||
          strEQ(h, "GMP::Mpz") ||
          strEQ(h, "Math::GMPz"))
            gmp_randseed(*(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(state)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(seed)))));
       else croak("2nd arg to Rmpfr_randseed is of invalid type");
     }

     else {
       if(!mpz_init_set_str(s, SvPV_nolen(seed), 0)) {
         gmp_randseed(*(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(state)))), s);
         mpz_clear(s);
       }
       else croak("Seedstring supplied to Rmpfr_randseed is not a valid number");
     }
}

void Rmpfr_randseed_ui(pTHX_ SV * state, SV * seed) {
     gmp_randseed_ui(*(INT2PTR(gmp_randstate_t *, SvIVX(SvRV(state)))), (unsigned long)SvUV(seed));
}

SV * overload_pow_eq(pTHX_ SV * p, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     SvREFCNT_inc(p);

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
#  if MPFR_VERSION >= 262656 /* have mpfr_pow_uj, mpfr_pow_sj */
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_pow_uj(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return p;
       }

       mpfr_pow_sj(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return p;
     }
#  else
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_pow(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return p;
     }

#  endif
#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_pow_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return p;
       }

       mpfr_pow_si(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return p;
     }
#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_pow_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       mpfr_init(t);
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(t);
         }

         else mpfr_set_inf(t, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_pow_eq subroutine");}

       mpfr_pow(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return p;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)
       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);
#elif defined(USE_LONG_DOUBLE)
       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);
#else
       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);
#endif

       mpfr_pow(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return p;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_pow(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return p;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_pow_z(*(INT2PTR(mpfr_t *, SvIV(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIV(SvRV(p)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return p;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_pow(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return p;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_init(t);
         mpfr_set_q(t, *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_pow(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return p;
       }
     }

     SvREFCNT_dec(p);
     croak("Invalid argument supplied to Math::MPFR::overload_pow_eq.");
}

SV * overload_div_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     SvREFCNT_inc(a);

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_div(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_div_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return a;
       }

       mpfr_div_si(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return a;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_div_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       mpfr_init(t);
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(t);
         }

         else mpfr_set_inf(t, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_div_eq subroutine");}

       mpfr_div(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);

#else

       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);
#endif

       mpfr_div(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_div(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_div_z(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_div(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return a;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_div_q(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::MPFR::overload_div_eq function");
}

SV * overload_sub_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     SvREFCNT_inc(a);

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_sub(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

#else
     DEAL_WITH_NANFLAG_BUG_OVERLOADED
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_sub_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return a;
       }

       mpfr_sub_si(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return a;
       /*
       if(SvIV(b) >= 0) {
         mpfr_sub_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return a;
       }
       mpfr_add_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b) * -1, __gmpfr_default_rounding_mode);
       return a;
       */
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_sub_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       mpfr_init(t);
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(t);
         }

         else mpfr_set_inf(t, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_sub_eq subroutine");}

       mpfr_sub(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);

#else

       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_init_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);

#endif

       mpfr_sub(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_sub(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_sub_z(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_sub(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return a;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_sub_q(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::MPFR::overload_sub_eq function");
}

SV * overload_add_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     SvREFCNT_inc(a);

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_add(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

#else
     DEAL_WITH_NANFLAG_BUG_OVERLOADED
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_add_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return a;
       }

       mpfr_add_si(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return a;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_add_eq(aTHX_ +=)");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       mpfr_init(t);
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(t);
         }

         else mpfr_set_inf(t, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_add_eq subroutine");}

       mpfr_add(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);

#else

       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);

#endif

       mpfr_add(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_add(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_add_z(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_add(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return a;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_add_q(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::MPFR::overload_add_eq");
}

SV * overload_mul_eq(pTHX_ SV * a, SV * b, SV * third) {
     mpfr_t t;
     int ret;
#ifdef _WIN32_BIZARRE_INFNAN
     int inf_or_nan;
#endif

     SvREFCNT_inc(a);

#ifdef MATH_MPFR_NEED_LONG_LONG_INT
     if(SV_IS_IOK(b)) {
       mpfr_init2(t, (mpfr_prec_t)IVSIZE_BITS);
       if(SvUOK(b)) mpfr_set_uj(t, SvUVX(b), __gmpfr_default_rounding_mode);
       else         mpfr_set_sj(t, SvIVX(b), __gmpfr_default_rounding_mode);

       mpfr_mul(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

#else
     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) {
         mpfr_mul_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvUVX(b), __gmpfr_default_rounding_mode);
         return a;
       }

       mpfr_mul_si(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), SvIVX(b), __gmpfr_default_rounding_mode);
       return a;
     }

#endif

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "overload_mul_eq");}

#ifdef _WIN32_BIZARRE_INFNAN
       inf_or_nan = _win32_infnanstring(SvPV_nolen(b));
       mpfr_init(t);
       if(inf_or_nan) {
         if(inf_or_nan == 2) {
           mpfr_set_nan(t);
         }

         else mpfr_set_inf(t, inf_or_nan);
       }
       else {
         ret = mpfr_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);
       }
#else
       ret = mpfr_init_set_str(t, SvPV_nolen(b), 0, __gmpfr_default_rounding_mode);

#endif

       NON_NUMERIC_CHAR_CHECK, "overload_mul_eq subroutine");}

       mpfr_mul(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(SV_IS_NOK(b)) {

#if defined(USE_QUADMATH)

       mpfr_init2(t, FLT128_MANT_DIG);
       Rmpfr_set_NV(aTHX_ &t, b, __gmpfr_default_rounding_mode);

#elif defined(USE_LONG_DOUBLE)

       mpfr_init2(t, REQUIRED_LDBL_MANT_DIG);
       mpfr_set_ld(t, (long double)SvNVX(b), __gmpfr_default_rounding_mode);

#else

       mpfr_init2(t, DBL_MANT_DIG);
       mpfr_init_set_d(t, (double)SvNVX(b), __gmpfr_default_rounding_mode);

#endif

       mpfr_mul(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
       mpfr_clear(t);
       return a;
     }

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         mpfr_mul(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPz")) {
         mpfr_mul_z(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpz_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
       if(strEQ(h, "Math::GMPf")) {
         mpfr_init2(t, (mpfr_prec_t)mpf_get_prec(*(INT2PTR(mpf_t *, SvIVX(SvRV(b))))));
         mpfr_set_f(t, *(INT2PTR(mpf_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         mpfr_mul(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), t, __gmpfr_default_rounding_mode);
         mpfr_clear(t);
         return a;
       }
       if(strEQ(h, "Math::GMPq")) {
         mpfr_mul_q(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpq_t *, SvIVX(SvRV(b)))), __gmpfr_default_rounding_mode);
         return a;
       }
     }

     SvREFCNT_dec(a);
     croak("Invalid argument supplied to Math::MPFR::overload_mul_eq");
}

SV * _itsa(pTHX_ SV * a) {
     if(SV_IS_IOK(a)) {
       if(SvUOK(a)) return newSVuv(1);
       return newSVuv(2);
     }
     if(SV_IS_POK(a)) return newSVuv(4);
     if(SV_IS_NOK(a)) return newSVuv(3);
     if(sv_isobject(a)) {
       const char* h = HvNAME(SvSTASH(SvRV(a)));

       if(strEQ(h, "Math::MPFR")) return newSVuv(5);
       if(strEQ(h, "Math::GMPf")) return newSVuv(6);
       if(strEQ(h, "Math::GMPq")) return newSVuv(7);
       if(strEQ(h, "Math::GMPz")) return newSVuv(8);
       if(strEQ(h, "Math::GMP")) return newSVuv(9);        }
     return newSVuv(0);
}

int _has_longlong(void) {
#ifdef MATH_MPFR_NEED_LONG_LONG_INT
    return 1;
#else
    return 0;
#endif
}

int _has_longdouble(void) {
#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
    return 1;
#else
    return 0;
#endif
}

int _ivsize_bits(void) {
   int ret = 0;
#ifdef IVSIZE_BITS
   ret = IVSIZE_BITS;
#endif
   return ret;
}

/*
int _mpfr_longsize(void) {
    mpfr_t x, y;

    mpfr_init2(x, 100);
    mpfr_init2(y, 100);

    mpfr_set_str(x, "18446744073709551615", 10, GMP_RNDN);
    mpfr_set_ui(y, 18446744073709551615, GMP_RNDN);

    if(!mpfr_cmp(x,y)) return 64;
    return 32;
}
*/

SV * RMPFR_PREC_MAX(pTHX) {
     return newSViv(MPFR_PREC_MAX);
}

SV * RMPFR_PREC_MIN(pTHX) {
     return newSViv(MPFR_PREC_MIN);
}

SV * wrap_mpfr_printf(pTHX_ SV * a, SV * b) {
     int ret;
     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")){
         ret = mpfr_printf(SvPV_nolen(a), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         fflush(stdout);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")){
         ret = mpfr_printf(SvPV_nolen(a), *(INT2PTR(mpfr_prec_t *, SvIVX(SvRV(b)))));
         fflush(stdout);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpfr_printf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = mpfr_printf(SvPV_nolen(a), SvUVX(b));
       else         ret = mpfr_printf(SvPV_nolen(a), SvIVX(b));

       fflush(stdout);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "wrap_mpfr_printf");}

       ret = mpfr_printf(SvPV_nolen(a), SvPV_nolen(b));
       fflush(stdout);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = mpfr_printf(SvPV_nolen(a), SvNVX(b));
       fflush(stdout);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpfr_printf");
}

SV * wrap_mpfr_fprintf(pTHX_ FILE * stream, SV * a, SV * b) {
     int ret;
     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         ret = mpfr_fprintf(stream, SvPV_nolen(a), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         fflush(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")) {
         ret = mpfr_fprintf(stream, SvPV_nolen(a), *(INT2PTR(mpfr_prec_t *, SvIVX(SvRV(b)))));
         fflush(stream);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpfr_fprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = mpfr_fprintf(stream, SvPV_nolen(a), SvUVX(b));
       else         ret = mpfr_fprintf(stream, SvPV_nolen(a), SvIVX(b));

       fflush(stream);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "wrap_mpfr_fprintf");}

       ret = mpfr_fprintf(stream, SvPV_nolen(a), SvPV_nolen(b));
       fflush(stream);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = mpfr_fprintf(stream, SvPV_nolen(a), SvNVX(b));
       fflush(stream);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpfr_fprintf");
}

SV * wrap_mpfr_sprintf(pTHX_ SV * s, SV * a, SV * b, int buflen) {
     int ret;
     char * stream;

     Newx(stream, buflen, char);

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         ret = mpfr_sprintf(stream, SvPV_nolen(a), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")) {
         ret = mpfr_sprintf(stream, SvPV_nolen(a), *(INT2PTR(mpfr_prec_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpfr_sprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = mpfr_sprintf(stream, SvPV_nolen(a), SvUVX(b));
       else         ret = mpfr_sprintf(stream, SvPV_nolen(a), SvIVX(b));

       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "wrap_mpfr_sprintf");}

       ret = mpfr_sprintf(stream, SvPV_nolen(a), SvPV_nolen(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = mpfr_sprintf(stream, SvPV_nolen(a), SvNVX(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpfr_sprintf");
}

SV * wrap_mpfr_snprintf(pTHX_ SV * s, SV * bytes, SV * a, SV * b, int buflen) {
     int ret;
     char * stream;

     Newx(stream, buflen, char);

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")) {
         ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), *(INT2PTR(mpfr_prec_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       croak("Unrecognised object supplied as argument to Rmpfr_snprintf");
     }

     if(SV_IS_IOK(b)) {
       if(SvUOK(b)) ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvUVX(b));
       else         ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvIVX(b));

       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_POK(b)) {

       NOK_POK_DUALVAR_CHECK , "wrap_mpfr_snprintf");}

       ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvPV_nolen(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     if(SV_IS_NOK(b)) {
       ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), SvNVX(b));
       sv_setpv(s, stream);
       Safefree(stream);
       return newSViv(ret);
     }

     croak("Unrecognised type supplied as argument to Rmpfr_snprintf");
}

SV * wrap_mpfr_printf_rnd(pTHX_ SV * a, SV * round, SV * b) {
     int ret;
     if((mpfr_rnd_t)SvUV(round) > 4) croak("Invalid 2nd argument (rounding value) of %u passed to Rmpfr_printf", (mpfr_rnd_t)SvUV(round));
     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")){
         ret = mpfr_printf(SvPV_nolen(a), (mpfr_rnd_t)SvUV(round), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         fflush(stdout);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")){
         croak("You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_printf");
       }

       croak("Unrecognised object supplied as argument to Rmpfr_printf");
     }

     croak("In Rmpfr_printf: The rounding argument is specific to Math::MPFR objects");
}

SV * wrap_mpfr_fprintf_rnd(pTHX_ FILE * stream, SV * a, SV * round, SV * b) {
     int ret;
     if((mpfr_rnd_t)SvUV(round) > 4) croak("Invalid 3rd argument (rounding value) of %u passed to Rmpfr_fprintf", (mpfr_rnd_t)SvUV(round));
     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         ret = mpfr_fprintf(stream, SvPV_nolen(a), (mpfr_rnd_t)SvUV(round), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         fflush(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")) {
         croak("You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_fprintf");
       }

       croak("Unrecognised object supplied as argument to Rmpfr_fprintf");
     }

     croak("In Rmpfr_fprintf: The rounding argument is specific to Math::MPFR objects");
}

SV * wrap_mpfr_sprintf_rnd(pTHX_ SV * s, SV * a, SV * round, SV * b, int buflen) {
     int ret;
     char * stream;

     Newx(stream, buflen, char);

     if((mpfr_rnd_t)SvUV(round) > 4) croak("Invalid 3rd argument (rounding value) of %u passed to Rmpfr_sprintf", (mpfr_rnd_t)SvUV(round));

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         ret = mpfr_sprintf(stream, SvPV_nolen(a), (mpfr_rnd_t)SvUV(round), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")) {
         croak("You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_sprintf");
       }

       croak("Unrecognised object supplied as argument to Rmpfr_sprintf");
     }

     croak("In Rmpfr_sprintf: The rounding argument is specific to Math::MPFR objects");
}

SV * wrap_mpfr_snprintf_rnd(pTHX_ SV * s, SV * bytes, SV * a, SV * round, SV * b, int buflen) {
     int ret;
     char * stream;

     Newx(stream, buflen, char);

     if((mpfr_rnd_t)SvUV(round) > 4) croak("Invalid 3rd argument (rounding value) of %u passed to Rmpfr_snprintf", (mpfr_rnd_t)SvUV(round));

     if(sv_isobject(b)) {
       const char* h = HvNAME(SvSTASH(SvRV(b)));

       if(strEQ(h, "Math::MPFR")) {
         ret = mpfr_snprintf(stream, (size_t)SvUV(bytes), SvPV_nolen(a), (mpfr_rnd_t)SvUV(round), *(INT2PTR(mpfr_t *, SvIVX(SvRV(b)))));
         sv_setpv(s, stream);
         Safefree(stream);
         return newSViv(ret);
       }

       if(strEQ(h, "Math::MPFR::Prec")) {
         croak("You've provided both a rounding arg and a Math::MPFR::Prec object to Rmpfr_snprintf");
       }

       croak("Unrecognised object supplied as argument to Rmpfr_snprintf");
     }

     croak("In Rmpfr_snprintf: The rounding argument is specific to Math::MPFR objects");
}



SV * Rmpfr_buildopt_tls_p(pTHX) {
     return newSViv(mpfr_buildopt_tls_p());
}

SV * Rmpfr_buildopt_decimal_p(pTHX) {
     return newSViv(mpfr_buildopt_decimal_p());
}

SV * Rmpfr_regular_p(pTHX_ mpfr_t * a) {
     return newSViv(mpfr_regular_p(*a));
}

void Rmpfr_set_zero(pTHX_ mpfr_t * a, SV * sign) {
     mpfr_set_zero(*a, (int)SvIV(sign));
}

SV * Rmpfr_digamma(pTHX_ mpfr_t * rop, mpfr_t * op, SV * round) {
     return newSViv(mpfr_digamma(*rop, *op, (mpfr_rnd_t)SvIV(round)));
}

SV * Rmpfr_ai(pTHX_ mpfr_t * rop, mpfr_t * op, SV * round) {
     return newSViv(mpfr_ai(*rop, *op, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_get_flt(pTHX_ mpfr_t * a, SV * round) {
     return newSVnv(mpfr_get_flt(*a, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_flt(pTHX_ mpfr_t * rop, SV * f, SV * round) {
     return newSViv(mpfr_set_flt(*rop, (float)SvNV(f), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_urandom(pTHX_ mpfr_t * rop, gmp_randstate_t* state, SV * round) {
     return newSViv(mpfr_urandom(*rop, *state, (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_set_z_2exp(pTHX_ mpfr_t * rop, mpz_t * op, SV * exp, SV * round) {
     return newSViv(mpfr_set_z_2exp(*rop, *op, (mpfr_exp_t)SvIV(exp), (mpfr_rnd_t)SvUV(round)));
}

SV * Rmpfr_buildopt_tune_case(pTHX) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     return newSVpv(mpfr_buildopt_tune_case(), 0);
#else
     croak("Rmpfr_buildopt_tune_case not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_frexp(pTHX_ SV * exp, mpfr_t * rop, mpfr_t * op, SV * round) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     mpfr_exp_t _exp;
     int ret;

     ret = mpfr_frexp(&_exp, *rop, *op, (mpfr_rnd_t)SvUV(round));
     sv_setiv(exp, _exp);
     return newSViv(ret);
#else
     croak("Rmpfr_frexp not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_z_sub(pTHX_ mpfr_t * rop, mpz_t * op1, mpfr_t * op2, SV * round) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     return newSViv(mpfr_z_sub(*rop, *op1, *op2, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_z_sub not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_grandom(pTHX_ mpfr_t * rop1, mpfr_t * rop2, gmp_randstate_t * state, SV * round) {
#if MPFR_VERSION_MAJOR >= 4
     croak("Rmpfr_grandom is deprecated, and now removed - use Rmpfr_nrandom instead");
#elif (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     return newSViv(mpfr_grandom(*rop1, *rop2, *state, (mpfr_rnd_t)SvUV(round)));
#else
     croak("Rmpfr_grandom was not introduced until mpfr-3.1.0 and was then deprecated & replaced by Rmpfr_nrandom as of mpfr-4.0.0");
#endif
}

void Rmpfr_clear_divby0(pTHX) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     mpfr_clear_divby0();
#else
     croak("Rmpfr_clear_divby0 not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

void Rmpfr_set_divby0(pTHX) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     mpfr_set_divby0();
#else
     croak("Rmpfr_set_divby0 not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_divby0_p(pTHX) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     return newSViv(mpfr_divby0_p());
#else
     croak("Rmpfr_divby0_p not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_buildopt_gmpinternals_p(pTHX) {
#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3
     return newSViv(mpfr_buildopt_gmpinternals_p());
#else
     croak("Rmpfr_buildopt_gmpinternals_p not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

SV * _get_xs_version(pTHX) {
     return newSVpv(XS_VERSION, 0);
}

SV * overload_inc(pTHX_ SV * a, SV * b, SV * third) {
     DEAL_WITH_NANFLAG_BUG_OVERLOADED
     SvREFCNT_inc(a);
     mpfr_add_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), 1, __gmpfr_default_rounding_mode);
     return a;
}

SV * overload_dec(pTHX_ SV * p, SV * b, SV * third) {
     SvREFCNT_inc(p);
     mpfr_sub_ui(*(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), *(INT2PTR(mpfr_t *, SvIVX(SvRV(p)))), 1, __gmpfr_default_rounding_mode);
     return p;
}

SV * _wrap_count(pTHX) {
     return newSVuv(PL_sv_count);
}

SV * Rmpfr_set_LD(pTHX_ mpfr_t * rop, SV * op, SV *rnd) {
     if(sv_isobject(op)) {
       const char* h = HvNAME(SvSTASH(SvRV(op)));

       if(strEQ(h, "Math::LongDouble")) {
         return newSViv(mpfr_set_ld(*rop, *(INT2PTR(long double *, SvIVX(SvRV(op)))), (mpfr_rnd_t)SvUV(rnd)));
       }
       croak("2nd arg (a %s object) supplied to Rmpfr_set_LD needs to be a Math::LongDouble object",
              HvNAME(SvSTASH(SvRV(op))));
     }
     else croak("2nd arg (which needs to be a Math::LongDouble object) supplied to Rmpfr_set_LD is not an object");
}

/*
int mpfr_set_decimal64 (mpfr_t rop, _Decimal64 op, mpfr_rnd_t rnd)
*/

SV * Rmpfr_set_DECIMAL64(pTHX_ mpfr_t * rop, SV * op, SV * rnd) {
#if (!defined(MPFR_VERSION) || (MPFR_VERSION<MPFR_VERSION_NUM(3,1,0)))
     croak("Perl interface to Rmpfr_set_DECIMAL64 not available for this version (%s) of the mpfr library. We need at least version 3.1.0",
            MPFR_VERSION_STRING);
#endif

/*
 MPFR_WANT_DECIMAL_FLOATS needs to have been defined prior to inclusion of mpfr.h.
 MPFR_WANT_DECIMAL164 also needs to be defined.
 See the Makefile.PL
*/

#if defined(MPFR_WANT_DECIMAL_FLOATS) && defined(MPFR_WANT_DECIMAL64)
    if(sv_isobject(op)) {
      const char* h = HvNAME(SvSTASH(SvRV(op)));

      if(strEQ(h, "Math::Decimal64"))
        return newSViv(mpfr_set_decimal64(*rop, *(INT2PTR(_Decimal64 *, SvIVX(SvRV(op)))), (mpfr_rnd_t)SvUV(rnd)));
       croak("2nd arg (a %s object) supplied to Rmpfr_set_DECIMAL64 needs to be a Math::Decimal64 object",
               HvNAME(SvSTASH(SvRV(op))));
    }
    else croak("2nd arg (which needs to be a Math::Decimal64 object) supplied to Rmpfr_set_DECIMAL64 is not an object");

#else

#  if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(3,1,0)
      if( mpfr_buildopt_decimal_p() ) {
        warn("To make Rmpfr_set_DECIMAL64 available, rebuild Math::MPFR and pass \"D64=1\" as an arg to the Makefile.PL\n");
        croak("See \"PASSING _Decimal64 & _Decimal128 VALUES\" in the Math::MPFR documentation");
      }
#  endif

    croak("Both MPFR_WANT_DECIMAL_FLOATS and MPFR_WANT_DECIMAL64 need to have been defined when building Math::MPFR - see \"PASSING _Decimal64 & _Decimal128 VALUES\" in the Math::MPFR documentation");

#endif
}

/**********************************************
 **********************************************/


SV * Rmpfr_set_DECIMAL128(pTHX_ mpfr_t * rop, SV * op, SV * rnd) {
#if (!defined(MPFR_VERSION) || (MPFR_VERSION<MPFR_VERSION_NUM(4,1,0)))
     croak("Perl interface to Rmpfr_set_DECIMAL128 not available for this version (%s) of the mpfr library. We need at least version 4.1.0",
            MPFR_VERSION_STRING);
#endif

/*
 MPFR_WANT_DECIMAL_FLOATS needs to have been defined prior to inclusion of mpfr.h.
 MPFR_WANT_DECIMAL1128 also needs to be defined.
 See the Makefile.PL
*/

#if defined(MPFR_WANT_DECIMAL_FLOATS) && defined(MPFR_WANT_DECIMAL128)
    if(sv_isobject(op)) {
      const char* h = HvNAME(SvSTASH(SvRV(op)));

      if(strEQ(h, "Math::Decimal128"))
        return newSViv(mpfr_set_decimal128(*rop, *(INT2PTR(D128 *, SvIVX(SvRV(op)))), (mpfr_rnd_t)SvUV(rnd)));
       croak("2nd arg (a %s object) supplied to Rmpfr_set_DECIMAL128 needs to be a Math::Decimal128 object",
               HvNAME(SvSTASH(SvRV(op))));
    }
    else croak("2nd arg (which needs to be a Math::Decimal128 object) supplied to Rmpfr_set_DECIMAL128 is not an object");

#else

#  if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,1,0)
      if( mpfr_buildopt_decimal_p() ) {
        warn("To make Rmpfr_set_DECIMAL128 available, rebuild Math::MPFR and pass \"D128=1\"  as separate args to the Makefile.PL\n");
        croak("See \"PASSING _Decimal64 & _Decimal128 VALUES\" in the Math::MPFR documentation");
      }
#  endif

    croak("Both MPFR_WANT_DECIMAL_FLOATS and MPFR_WANT_DECIMAL128 need to have been defined when building Math::MPFR");

#endif
}



/**********************************************
 **********************************************/

void Rmpfr_get_LD(pTHX_ SV * rop, mpfr_t * op, SV * rnd) {
     if(sv_isobject(rop)) {
       const char* h = HvNAME(SvSTASH(SvRV(rop)));

       if(strEQ(h, "Math::LongDouble")) {
         *(INT2PTR(long double *, SvIVX(SvRV(rop)))) = mpfr_get_ld(*op, (mpfr_rnd_t)SvUV(rnd));
       }
       else croak("1st arg (a %s object) supplied to Rmpfr_get_LD needs to be a Math::LongDouble object",
                  HvNAME(SvSTASH(SvRV(rop))));
     }
     else croak("1st arg (which needs to be a Math::LongDouble object) supplied to Rmpfr_get_LD is not an object");
}

/**********************************************
 **********************************************/

void Rmpfr_get_DECIMAL64(pTHX_ SV * rop, mpfr_t * op, SV * rnd) {
#if (!defined(MPFR_VERSION) || (MPFR_VERSION<MPFR_VERSION_NUM(3,1,0)))
     croak("Perl interface to Rmpfr_get_DECIMAL64 not available for this version (%s) of the mpfr library. We need at least version 3.1.0",
              MPFR_VERSION_STRING);
#endif

/*
 MPFR_WANT_DECIMAL_FLOATS needs to have been defined prior to inclusion of mpfr.h.
 MPFR_WANT_DECIMAL164 also needs to be defined.
 See the Makefile.PL
*/

#if defined(MPFR_WANT_DECIMAL_FLOATS) && defined(MPFR_WANT_DECIMAL64)
    if(sv_isobject(rop)) {
      const char* h = HvNAME(SvSTASH(SvRV(rop)));

      if(strEQ(h, "Math::Decimal64"))
        *(INT2PTR(_Decimal64 *, SvIVX(SvRV(rop)))) = mpfr_get_decimal64(*op, (mp_rnd_t)SvUV(rnd));

       else croak("1st arg (a %s object) supplied to Rmpfr_get_DECIMAL64 needs to be a Math::Decimal64 object",
                      HvNAME(SvSTASH(SvRV(rop))));
    }
    else croak("1st arg (which needs to be a Math::Decimal64 object) supplied to Rmpfr_get_DECIMAL64 is not an object");

#else

#  if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(3,1,0)
      if( mpfr_buildopt_decimal_p() ) {
        warn("To make Rmpfr_get_DECIMAL64 available, rebuild Math::MPFR and pass \"D64=1\" as an arg to the Makefile.PL\n");
        croak("See \"PASSING _Decimal64 & _Decimal128 VALUES\" in the Math::MPFR documentation");
      }
#  endif

    croak("Both MPFR_WANT_DECIMAL_FLOATS and MPFR_WANT_DECIMAL64 need to have been defined when building Math::MPFR");

#endif
}

/**********************************************
 **********************************************/

void Rmpfr_get_DECIMAL128(pTHX_ SV * rop, mpfr_t * op, SV * rnd) {
#if (!defined(MPFR_VERSION) || (MPFR_VERSION<MPFR_VERSION_NUM(4,1,0)))
     croak("Perl interface to Rmpfr_get_DECIMAL128 not available for this version (%s) of the mpfr library. We need at least version 4.1.0",
              MPFR_VERSION_STRING);
#endif

/*
 MPFR_WANT_DECIMAL_FLOATS needs to have been defined prior to inclusion of mpfr.h.
 MPFR_WANT_DECIMAL1128 also needs to be defined.
 See the Makefile.PL
*/

#if defined(MPFR_WANT_DECIMAL_FLOATS) && defined(MPFR_WANT_DECIMAL128)
    if(sv_isobject(rop)) {
      const char* h = HvNAME(SvSTASH(SvRV(rop)));

      if(strEQ(h, "Math::Decimal128"))
        *(INT2PTR(D128 *, SvIVX(SvRV(rop)))) = mpfr_get_decimal128(*op, (mp_rnd_t)SvUV(rnd));

       else croak("1st arg (a %s object) supplied to Rmpfr_get_DECIMAL128 needs to be a Math::Decimal128 object",
                      HvNAME(SvSTASH(SvRV(rop))));
    }
    else croak("1st arg (which needs to be a Math::Decimal128 object) supplied to Rmpfr_get_DECIMAL128 is not an object");

#else

#  if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,1,0)
      if( mpfr_buildopt_decimal_p() ) {
        warn("To make Rmpfr_get_DECIMAL128 available, rebuild Math::MPFR and pass \"D128=1\" as an arg to the Makefile.PL\n");
        croak("See \"PASSING _Decimal64 & _Decimal128 VALUES\" in the Math::MPFR documentation");
      }
#  endif

    croak("Both MPFR_WANT_DECIMAL_FLOATS and MPFR_WANT_DECIMAL128 need to have been defined when building Math::MPFR");

#endif
}


/**********************************************
 **********************************************/

int _MPFR_WANT_DECIMAL_FLOATS(void) {
#ifdef MPFR_WANT_DECIMAL_FLOATS
 return 1;
#else
 return 0;
#endif
}

int _MPFR_WANT_DECIMAL64(void) {
#ifdef MPFR_WANT_DECIMAL64
 return 1;
#else
 return 0;
#endif
}

int _MPFR_WANT_DECIMAL128(void) {
#ifdef MPFR_WANT_DECIMAL128
 return 1;
#else
 return 0;
#endif
}

int _MPFR_WANT_FLOAT128(void) {
#ifdef MPFR_WANT_FLOAT128
 return 1;
#else
 return 0;
#endif
}

SV * _max_base(pTHX) {
     return newSViv(62);
}

SV * _isobject(pTHX_ SV * x) {
    if(sv_isobject(x))return newSVuv(1);
    return newSVuv(0);
}

void _mp_sizes(void) {
     dTHX;
     dXSARGS;
     XPUSHs(sv_2mortal(newSVuv(sizeof(mpfr_exp_t))));
     XPUSHs(sv_2mortal(newSVuv(sizeof(mpfr_prec_t))));
     XPUSHs(sv_2mortal(newSVuv(sizeof(mpfr_rnd_t))));

     XSRETURN(3);
}

SV * _ivsize(pTHX) {
     return newSVuv(sizeof(IV));
}

SV * _nvsize(pTHX) {
     return newSVuv(sizeof(NV));
}

SV * _FLT128_DIG(pTHX) {
#ifdef FLT128_DIG
     return newSViv(FLT128_DIG);
#else
     return &PL_sv_undef;
#endif
}

SV * _LDBL_DIG(pTHX) {
#ifdef LDBL_DIG
     return newSViv(LDBL_DIG);
#else
     return &PL_sv_undef;
#endif
}

SV * _DBL_DIG(pTHX) {
#ifdef DBL_DIG
     return newSViv(DBL_DIG);
#else
     return &PL_sv_undef;
#endif
}

SV * _FLT128_MANT_DIG(pTHX) {
#ifdef FLT128_MANT_DIG
     return newSViv(FLT128_MANT_DIG);
#else
     return &PL_sv_undef;
#endif
}

SV * _LDBL_MANT_DIG(pTHX) {
#ifdef LDBL_MANT_DIG
     return newSViv(LDBL_MANT_DIG);
#else
     return &PL_sv_undef;
#endif
}

SV * _DBL_MANT_DIG(pTHX) {
#ifdef DBL_MANT_DIG
     return newSViv(DBL_MANT_DIG);
#else
     return &PL_sv_undef;
#endif
}


/*///////////////////////////////////////////
////////////////////////////////////////////*/
/* All randinit functions now moved to Math::MPFR::Random */
/*

*/
/***********************************************
************************************************/

SV * Rmpfr_get_float128(pTHX_ mpfr_t * op, SV * rnd) {

#ifdef CAN_PASS_FLOAT128
     return newSVnv(mpfr_get_float128(*op, (mpfr_rnd_t)SvUV(rnd)));
#else
#  if MPFR_VERSION_MAJOR >= 4
       if(mpfr_buildopt_float128_p()) {
         warn("To make Rmpfr_get_float128 available, rebuild Math::MPFR and pass \"F128=1\" as an arg to the Makefile.PL\n");
         croak("See \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
       }
#  endif
     croak("Cannot use Rmpfr_get_float128 to return an NV - see \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
#endif
}

void Rmpfr_get_FLOAT128(pTHX_ SV * rop, mpfr_t * op, SV * rnd) {
#if (!defined(MPFR_VERSION) || (MPFR_VERSION < MPFR_VERSION_NUM(4,0,0)))
     croak("Perl interface to Rmpfr_get_FLOAT128 not available for this version (%s) of the mpfr library. We need at least version 4.0.0",
              MPFR_VERSION_STRING);
#endif

/*
 MPFR_WANT_FLOAT128 needs to have been defined prior to inclusion of mpfr.h - this is done by
 defining it at the 'Makefile.PL' step - see the Makefile.PL
*/

#ifdef MPFR_WANT_FLOAT128

    if(sv_isobject(rop)) {
      const char* h = HvNAME(SvSTASH(SvRV(rop)));

      if(strEQ(h, "Math::Float128"))
        *(INT2PTR(float128 *, SvIVX(SvRV(rop)))) = mpfr_get_float128(*op, (mpfr_rnd_t)SvUV(rnd));
      else croak("1st arg (a %s object) supplied to Rmpfr_get_FLOAT128 needs to be a Math::Float128 object",
                      HvNAME(SvSTASH(SvRV(rop))));
    }
    else croak("1st arg (which needs to be a Math::Float128 object) supplied to Rmpfr_get_FLOAT128 is not an object");

#else
#  if MPFR_VERSION_MAJOR >= 4
       if(mpfr_buildopt_float128_p()) {
         warn("To make Rmpfr_get_FLOAT128 available, rebuild Math::MPFR and pass \"F128=1\" as an arg to the Makefile.PL\n");
         croak("See \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
       }
#  endif
    croak("MPFR_WANT_FLOAT128 needs to have been defined when building Math::MPFR - - see \"PASSING __float128 VALUES\" in the Math::MPFR documentation");

#endif
}

SV * Rmpfr_set_FLOAT128(pTHX_ mpfr_t * rop, SV * op, SV * rnd) {
#if (!defined(MPFR_VERSION) || (MPFR_VERSION < MPFR_VERSION_NUM(4,0,0)))
     croak("Perl interface to Rmpfr_set_FLOAT128 not available for this version (%s) of the mpfr library. We need at least version 4.0.0",
            MPFR_VERSION_STRING);
#endif

/*
 MPFR_WANT_FLOAT128 needs to have been defined prior to inclusion of mpfr.h - this is done by
 defining it at the 'Makefile.PL' step - see the Makefile.PL
*/

#ifdef MPFR_WANT_FLOAT128
    if(sv_isobject(op)) {
      const char* h = HvNAME(SvSTASH(SvRV(op)));

      if(strEQ(h, "Math::Float128"))
        return newSViv(mpfr_set_float128(*rop, *(INT2PTR(float128 *, SvIVX(SvRV(op)))), (mpfr_rnd_t)SvUV(rnd)));
       croak("2nd arg (a %s object) supplied to Rmpfr_set_FLOAT128 needs to be a Math::Float128 object",
               HvNAME(SvSTASH(SvRV(op))));
    }
    else croak("2nd arg (which needs to be a Math::Float128 object) supplied to Rmpfr_set_FLOAT128 is not an object");

#else
#  if MPFR_VERSION_MAJOR >= 4
       if(mpfr_buildopt_float128_p()) {
         warn("To make Rmpfr_set_FLOAT128 available, rebuild Math::MPFR and pass \"F128=1\" as an arg to the Makefile.PL\n");
         croak("See \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
       }
#  endif
    croak("MPFR_WANT_FLOAT128 needs to have been defined when building Math::MPFR - see \"PASSING __float128 VALUES\" in the Math::MPFR documentation");

#endif
}

SV * Rmpfr_set_float128(pTHX_ mpfr_t * rop, SV * q, SV * rnd) {

#ifdef CAN_PASS_FLOAT128
     return newSViv(mpfr_set_float128(*rop, (float128)SvNV(q), (mpfr_rnd_t)SvUV(rnd)));
#else
#  if MPFR_VERSION_MAJOR >= 4
       if(mpfr_buildopt_float128_p()) {
         warn("To make Rmpfr_set_float128 available, rebuild Math::MPFR and pass \"F128=1\" as an arg to the Makefile.PL\n");
         croak("See \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
       }
#  endif

     croak("Cannot use Rmpfr_set_float128 to set an NV - see \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
#endif

}

void Rmpfr_init_set_float128(pTHX_ SV * q, SV * round) {

#ifdef CAN_PASS_FLOAT128
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("Math::MPFR",Rmpfr_init_set_float128) /* defined in math_mpfr_include.h */

     mpfr_init(*mpfr_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
     ret = mpfr_set_float128(*mpfr_t_obj, SvNV(q), (mpfr_rnd_t)SvUV(round));
     SvREADONLY_on(obj);
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
#else

     croak("Cannot use Rmpfr_init_set_float128 to set an NV - see \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
#endif

}

void Rmpfr_init_set_float128_nobless(pTHX_ SV * q, SV * round) {

#ifdef CAN_PASS_FLOAT128
     dXSARGS;
     mpfr_t * mpfr_t_obj;
     SV * obj_ref, * obj;
     int ret;

     CHECK_ROUNDING_VALUE

     NEW_MATH_MPFR_OBJECT("NULL",Rmpfr_init_set_float128_nobless) /* defined in math_mpfr_include.h */

     mpfr_init(*mpfr_t_obj);
     sv_setiv(obj, INT2PTR(IV,mpfr_t_obj));
     ret = mpfr_set_float128(*mpfr_t_obj, SvNV(q), (mpfr_rnd_t)SvUV(round));
     SvREADONLY_on(obj);
     RETURN_STACK_2  /*defined in math_mpfr_include.h */
#else

     croak("Cannot use Rmpfr_init_set_float128_nobless to set an NV - see \"PASSING __float128 VALUES\" in the Math::MPFR documentation");
#endif

}

SV * _is_readonly(pTHX_ SV * sv) {
     if SvREADONLY(sv) return newSVuv(1);
     return newSVuv(0);
}

void _readonly_on(pTHX_ SV * sv) {
     SvREADONLY_on(sv);
}

void _readonly_off(pTHX_ SV * sv) {
     SvREADONLY_off(sv);
}

/* Do not remove _can_pass_float128 - it's used by the Math::MPFI Makefile.PL */

int _can_pass_float128(void) {

#ifdef CAN_PASS_FLOAT128
   return 1;
#else
   return 0;
#endif

}

int _mpfr_want_float128(void) {

#ifdef MPFR_WANT_FLOAT128
   return 1;
#else
   return 0;
#endif

}

int nnumflag(void) {
  return nnum;
}

int nok_pokflag(void) {
  return nok_pok;
}

void clear_nnum(void) {
  nnum = 0;
}

void clear_nok_pok(void){
  nok_pok = 0;
}

void set_nnum(int x) {
  nnum = x;
}

void set_nok_pok(int x) {
  nok_pok = x;
}

SV * _d_bytes(pTHX_ SV * str) {

 /* Assumes 64-bit double (53-bit precision mantissa) *
  * Assumes also that the arg is a PV.                *
  * Assumptions are not checked because the function  *
  * is private.                                       *
  * Corrected to handle subnormal values in 4.02      */

  mpfr_t temp;
  double d;
  mpfr_prec_t emin;
  SV * sv;
#if !defined(MPFR_VERSION) || MPFR_VERSION <= 196869 /* avoid mpfr_subnormalize */
  int signbit;
  mpfr_t temp2, DENORM_MIN;
#else
  int inex;
  mpfr_prec_t emax;
#endif

  mpfr_init2(temp, DBL_MANT_DIG);

#if defined(MPFR_VERSION) && MPFR_VERSION > 196869 /* use mpfr_subnormalize */
  emin = mpfr_get_emin();
  emax = mpfr_get_emax();

  mpfr_set_emin(-1073);
  mpfr_set_emax(1024);

  inex = mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
  mpfr_subnormalize(temp, inex, GMP_RNDN);

  mpfr_set_emin(emin);
  mpfr_set_emax(emax);

  d = mpfr_get_d(temp, GMP_RNDN);

#else     /* mpfr_strtofr can return incorrect inex in 3.1.5 and  *
           * earlier - which renders mpfr_subnormalize unreliable */

  mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);

  emin = mpfr_get_exp(temp) + 1074;
  signbit = mpfr_signbit(temp) ? -1 : 1;

  if(emin <= 1) {
    if(emin < 0) {
      d = 0.0 *signbit;
    }
    else {
      if(emin == 0) {
        mpfr_init2(temp2, 2);
        mpfr_set_ui(temp2, 2, GMP_RNDN);
        mpfr_div_2ui(temp2, temp2, 1076, GMP_RNDN);
        mpfr_abs(temp, temp, GMP_RNDN);
        if(mpfr_cmp(temp, temp2) > 0) {
          mpfr_mul_2ui(temp2, temp2, 1, GMP_RNDN);
          d = mpfr_get_d(temp2, GMP_RNDN);
          mpfr_clear(temp2);
        }
        else {
          d = 0.0;
        }
        d *= signbit;
      }
      else {  /* emin == 1 *//* Can't set precision to 1 with older versions of mpfr */

        mpfr_abs(temp, temp, GMP_RNDN);
        mpfr_init2(temp2, 2);
        mpfr_init2(DENORM_MIN, 2);
        mpfr_set_ui(DENORM_MIN, 2, GMP_RNDN);
        mpfr_div_2ui(DENORM_MIN, DENORM_MIN, 1075, GMP_RNDN);
        mpfr_set(temp2, DENORM_MIN, GMP_RNDN);
        mpfr_div_ui(temp2, temp2, 2, GMP_RNDN);
        mpfr_add(temp2, temp2, DENORM_MIN, GMP_RNDN);
        if(mpfr_cmp(temp, temp2) >= 0) mpfr_mul_si(temp, DENORM_MIN, 2 * signbit, GMP_RNDN);
        else mpfr_mul_si(temp, temp, signbit, GMP_RNDN);
        mpfr_clear(temp2);
        mpfr_clear(DENORM_MIN);
        d = mpfr_get_d(temp, GMP_RNDN);
      }
    }
  }  /* close "if(emin <= 1)" */
  else {
    if(emin < 53) {
      mpfr_set_prec(temp, emin);
      mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
    }
    d = mpfr_get_d(temp, GMP_RNDN);
  }   /* close "else" */
#endif

  mpfr_clear(temp);

  sv = NEWSV(0, 8);
  sv_setpvn(sv, (char *) &d, 8);
  return sv;
}

SV * _bytes_fr(pTHX_ mpfr_t * str, unsigned int bits) {

  /* Explicit Calls to mpfr_subnormalize() are unnecessary */

  SV * sv;
  double msd, lsd;
  long double ld;
  mpfr_t temp;

#ifdef MPFR_WANT_FLOAT128
  float128 f128;
#endif

  if(mpfr_get_prec(*str) != bits)
    croak("Precision of 1st arg supplied to _bytes_fr != 2nd arg (%d)", bits );

  if(bits == 53) {
    msd = mpfr_get_d(*str, GMP_RNDN);
    sv = NEWSV(0, 8);
    sv_setpvn(sv, (char *) &msd, 8);
    return sv;
  }

  if(bits == 64) {
#  if LDBL_MANT_DIG != 64
    croak("Byte structure of 10-byte long double not provided for this architecture");
#  endif
    ld = mpfr_get_ld(*str, GMP_RNDN);
    sv = NEWSV(0, 10);
    sv_setpvn(sv, (char *) &ld, 10);
    return sv;
  }

  if(bits == 2098) {

    mpfr_init2(temp, 2098);
    mpfr_set(temp, *str, GMP_RNDN); /* Avoid altering the value held by *str */

    msd = mpfr_get_d(temp, GMP_RNDN);
    if(msd == 0 || msd != msd || msd / msd != 1) { /* zero, nan or inf */
      lsd = 0.0;
    }
    else {
      mpfr_sub_d(temp, temp, msd, GMP_RNDN);
      lsd = mpfr_get_d(temp, GMP_RNDN);
    }

    mpfr_clear(temp);
    sv = NEWSV(0, 16);

   /* Work around sneaky DoubleDouble gotcha */
   if( (msd ==  DBL_MAX && lsd ==   pow(2.0, 970.0))
         ||
       (msd == -DBL_MAX && lsd == -(pow(2.0, 970.0))) ) {
     msd += lsd; /* set msd to infinity */
     lsd = 0.0;  /* set lsd to zero     */
   }

#  ifdef MPFR_HAVE_BENDIAN
    sv_setpvn(sv, (char *) &msd, 8);
    sv_catpvn(sv, (char *) &lsd, 8);
#  else
    sv_setpvn(sv, (char *) &lsd, 8);
    sv_catpvn(sv, (char *) &msd, 8);
#  endif

    return sv;
  }

  if(bits == 113) {
#  if !defined(MPFR_WANT_FLOAT128) && LDBL_MANT_DIG != 113
    croak("Byte structure of 113-bit NV types not provided for this architecture and mpfr configuration");
#endif

   sv = NEWSV(0, 16);

#  if defined(MPFR_WANT_FLOAT128)
    f128 = mpfr_get_float128(*str, GMP_RNDN);
    sv_setpvn(sv, (char *) &f128, 16);
    return sv;
#  endif
    ld = mpfr_get_ld(*str, GMP_RNDN);
    sv_setpvn(sv, (char *) &ld, 16);
    return sv;
  }
}

SV * _dd_bytes(pTHX_ SV * str) {

 /* Assumes 128-bit long double (106-bit precision mantissa) *
  * Assumes also that the arg is a PV.                       *
  * Assumptions are not checked because the function         *
  * is private.                                              */

  mpfr_t temp;
  double msd, lsd;
  SV * sv;

  mpfr_init2(temp, 2098);

  mpfr_set_str(temp, SvPV_nolen(str), 0, GMP_RNDN);

  msd = mpfr_get_d(temp, GMP_RNDN);
  if(msd == 0 || msd != msd || msd / msd != 1) { /* zero, nan or inf */
    lsd = 0.0;
  }
  else {
    mpfr_sub_d(temp, temp, msd, GMP_RNDN);
    lsd = mpfr_get_d(temp, GMP_RNDN);
  }

  mpfr_clear(temp);

  sv = NEWSV(0, 16);

  /* Work around sneaky DoubleDouble gotcha */
  if( (msd ==  DBL_MAX && lsd ==   pow(2.0, 970.0))
        ||
      (msd == -DBL_MAX && lsd == -(pow(2.0, 970.0))) ) {
    msd += lsd; /* set msd to infinity */
    lsd = 0.0;  /* set lsd to zero     */
  }

#ifdef MPFR_HAVE_BENDIAN
  sv_setpvn(sv, (char *) &msd, 8);
  sv_catpvn(sv, (char *) &lsd, 8);
#else
  sv_setpvn(sv, (char *) &lsd, 8);
  sv_catpvn(sv, (char *) &msd, 8);
#endif
  return sv;
}

SV * _ld_bytes(pTHX_ SV * str) {

 /* Assumes 10-byte long double (64-bit precision mantissa)  *
  * 53-bit long doubles are handled by _d_bytes.             *
  * 113-bit long doubles are handled by _f128_bytes - but    *
  * only if LDBL_MANT_DIG == 113 or MPFR_WANT_FLOAT128 is    *
  * is defined.                                              *
  * Assumes also that the arg is a PV.                       *
  * Assumptions are not checked because the function         *
  * is private and should have already been checked.         *
  * Corrected to handle subnormal values in 4.02             */

#if LDBL_MANT_DIG != 64
    croak("Byte structure of 10-byte long double not provided for this architecture");
#else

    mpfr_t temp;
    long double ld;
    mpfr_prec_t emin, emax;
    SV * sv;

#  if !defined(MPFR_VERSION) || MPFR_VERSION <= 196869 /* avoid mpfr_subnormalize */
    int signbit;
    mpfr_t temp2, DENORM_MIN;
#  else
    int inex;
#  endif

    mpfr_init2(temp, 64);

#  if defined(MPFR_VERSION) && MPFR_VERSION > 196869 /* use mpfr_subnormalize */

    emin = mpfr_get_emin();
    emax = mpfr_get_emax();

    mpfr_set_emin(-16444);
    mpfr_set_emax(16384);

    inex = mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
    mpfr_subnormalize(temp, inex, GMP_RNDN);

    mpfr_set_emin(emin);
    mpfr_set_emax(emax);

    ld = mpfr_get_ld(temp, GMP_RNDN);

#  else /* mpfr_strtofr can return incorrect inex in 3.1.5 and   *
       * earlier - which renders mpfr_subnormalize unreliable  */


    mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
    emax = 16445;
    emin = mpfr_get_exp(temp) + 16445;

   /* mpfr_get_ld is buggy for extended precision subnormal    *
    * values with 3.1.4 and earlier. Hence, croak when this    *
    * condition exists (ie when LD_SUBNORMAL_BUG is dsefined.) */

#  ifdef LD_SUBNORMAL_BUG

         if(mpfr_regular_p(temp) && emin >= 0 && emin < 64) {
           warn("\n mpfr_get_ld is buggy (subnormal values only)\n for this version (%s) of the MPFR library\n", MPFR_VERSION_STRING);
           croak(" Version 3.1.5 or later is required");
         }

#  endif


    signbit = mpfr_signbit(temp) ? -1 : 1;

    if(emin <= 1) {
      if(emin < 0) {
        ld = 0.0L;
        ld *= signbit;
      }
      else {
        if(emin == 0) {
          mpfr_init2(temp2, 2);
          mpfr_set_ui(temp2, 2, GMP_RNDN);
          mpfr_div_2ui(temp2, temp2, emax + 2, GMP_RNDN);
          mpfr_abs(temp, temp, GMP_RNDN);
          if(mpfr_cmp(temp, temp2) > 0) {
            mpfr_mul_2ui(temp2, temp2, 1, GMP_RNDN);
            ld = mpfr_get_ld(temp2, GMP_RNDN);
            mpfr_clear(temp2);
          }
          else {
            ld = 0.0L;
          }
          ld *= signbit;
        }
        else {  /* emin == 1 *//* Can't set precision to 1 with older versions of mpfr */

          mpfr_abs(temp, temp, GMP_RNDN);
          mpfr_init2(temp2, 2);
          mpfr_init2(DENORM_MIN, 2);
          mpfr_set_ui(DENORM_MIN, 2, GMP_RNDN);
          mpfr_div_2ui(DENORM_MIN, DENORM_MIN, emax + 1, GMP_RNDN);
          mpfr_set(temp2, DENORM_MIN, GMP_RNDN);
          mpfr_div_ui(temp2, temp2, 2, GMP_RNDN);
          mpfr_add(temp2, temp2, DENORM_MIN, GMP_RNDN);
          if(mpfr_cmp(temp, temp2) >= 0) mpfr_mul_si(temp, DENORM_MIN, 2 * signbit, GMP_RNDN);
          else mpfr_mul_si(temp, temp, signbit, GMP_RNDN);
          mpfr_clear(temp2);
          mpfr_clear(DENORM_MIN);
          ld = mpfr_get_ld(temp, GMP_RNDN);
        }
      }
    }  /* close "if(emin <= 1)" */
    else {
      if(emin < 64) {
        mpfr_set_prec(temp, emin);
        mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
      }
    ld = mpfr_get_ld(temp, GMP_RNDN);
    }

#  endif

    mpfr_clear(temp);

    sv = NEWSV(0, 10);
    sv_setpvn(sv, (char *) &ld, 10);
    return sv;
#endif
}

SV * _f128_bytes(pTHX_ SV * str) {

 /* Assumes 113-bit NV (either long double or __float128).   *
  * Assumes also that the arg is a Math::MPFR object.        *
  * Assumptions are not checked because the function         *
  * is private and should have already been checked.         *
  * Corrected to handle subnormal values in 4.02             */


#if !defined(MPFR_WANT_FLOAT128) && LDBL_MANT_DIG != 113
  croak("Byte structure of 113-bit NV types not provided for this architecture and mpfr configuration");
#else

  mpfr_t temp;

#if defined(MPFR_WANT_FLOAT128)
  float128 f128;
#else
  long double f128;
#endif

  mpfr_prec_t emin;
  SV * sv;

#if !defined(MPFR_VERSION) || MPFR_VERSION <= 196869 /* avoid mpfr_subnormalize */
  int signbit;
  mpfr_t temp2, DENORM_MIN;
#else
  int inex;
  mpfr_prec_t emax;
#endif

  mpfr_init2(temp, 113);

#  if defined(MPFR_VERSION) && MPFR_VERSION > 196869 /* use mpfr_subnormalize */
    emin = mpfr_get_emin();
    emax = mpfr_get_emax();

    mpfr_set_emin(-16493);
    mpfr_set_emax(16384);

    inex = mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
    mpfr_subnormalize(temp, inex, GMP_RNDN);

    mpfr_set_emin(emin);
    mpfr_set_emax(emax);

#  if defined(MPFR_WANT_FLOAT128)
    f128 = mpfr_get_float128(temp, GMP_RNDN);
#  else
    f128 = mpfr_get_ld(temp, GMP_RNDN);
#  endif

#  else   /* mpfr_strtofr can return incorrect inex in 3.1.5 and  *
           * earlier - which renders mpfr_subnormalize unreliable */

    mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);

    emin = mpfr_get_exp(temp) + 16494;
    signbit = mpfr_signbit(temp) ? -1 : 1;

    if(emin < 1) {
      if(emin < 0) {
        ld = 0.0Q;
        ld *= signbit;
      }
      else {
        if(emin == 0) {
          mpfr_init2(temp2, 2);
          mpfr_set_ui(temp2, 2, GMP_RNDN);
          mpfr_div_2ui(temp2, temp2, 16496, GMP_RNDN);
          mpfr_abs(temp, temp, GMP_RNDN);
          if(mpfr_cmp(temp, temp2) > 0) {
            mpfr_mul_2ui(temp2, temp2, 1, GMP_RNDN);
            ld = mpfr_get_float128(temp2, GMP_RNDN);
            mpfr_clear(temp2);
          }
          else {
            ld = 0.0Q;
          }
          ld *= signbit;
        }
        else {  /* emin == 1 *//* Can't set precision to 1 with older versions of mpfr */
          mpfr_abs(temp, temp, GMP_RNDN);
          mpfr_init2(temp2, 2);
          mpfr_init2(DENORM_MIN, 2);
          mpfr_set_ui(DENORM_MIN, 2, GMP_RNDN);
          mpfr_div_2ui(DENORM_MIN, DENORM_MIN, 16495, GMP_RNDN);
          mpfr_set(temp2, DENORM_MIN, GMP_RNDN);
          mpfr_div_ui(temp2, temp2, 2, GMP_RNDN);
          mpfr_add(temp2, temp2, DENORM_MIN, GMP_RNDN);
          if(mpfr_cmp(temp, temp2) >= 0) mpfr_mul_si(temp, DENORM_MIN, 2 * signbit, GMP_RNDN);
          else mpfr_mul_si(temp, temp, signbit, GMP_RNDN);
          mpfr_clear(temp2);
          mpfr_clear(DENORM_MIN);
          f128 = mpfr_get_float128(temp, GMP_RNDN);
        }
      }
    }  /* close "if(emin <= 1)" */
    else {
      if(emin < 113) {
        mpfr_set_prec(temp, emin);
        mpfr_strtofr(temp, SvPV_nolen(str), NULL, 0, GMP_RNDN);
      }

#  if defined(MPFR_WANT_FLOAT128)
      f128 = mpfr_get_float128(temp, GMP_RNDN);
#  else
      f128 = mpfr_get_ld(temp, GMP_RNDN);
#  endif

    }   /* close "else" */

#  endif

  mpfr_clear(temp);

  sv = NEWSV(0, 16);
  sv_setpvn(sv, (char *) &f128, 16);
  return sv;

#endif

}

int _required_ldbl_mant_dig(void) {
    return REQUIRED_LDBL_MANT_DIG;
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

/* New in 3.2.0 */

void Rmpfr_fmodquo(pTHX_ mpfr_t * a, mpfr_t * b, mpfr_t * c, SV * round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     dXSARGS;
     long ret, q;
     ret = mpfr_fmodquo(*a, &q, *b, *c, (mpfr_rnd_t)SvUV(round));
     ST(0) = sv_2mortal(newSViv(q));
     ST(1) = sv_2mortal(newSViv(ret));
     XSRETURN(2);
#else
     croak("Rmpfr_fmodquo not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_fpif_export(pTHX_ FILE * stream, mpfr_t * op) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     int ret = mpfr_fpif_export(stream, *op);
     fflush(stream);
     return ret;
#else
     croak("Rmpfr_fpif_export not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_fpif_import(pTHX_ mpfr_t * op, FILE * stream) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     int ret = mpfr_fpif_import(*op, stream);
     fflush(stream);
     return ret;
#else
     croak("Rmpfr_fpif_import not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

void Rmpfr_flags_clear(unsigned int mask) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     mpfr_flags_clear((mpfr_flags_t) mask);
#else
     croak("Rmpfr_flags_clear not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

void Rmpfr_flags_set(unsigned int mask) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     mpfr_flags_set((mpfr_flags_t) mask);
#else
     croak("Rmpfr_flags_set not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

unsigned int Rmpfr_flags_test(unsigned int mask) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     mpfr_flags_t ret = mpfr_flags_test((mpfr_flags_t) mask);
     return (unsigned int)ret;
#else
     croak("Rmpfr_flags_test not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

unsigned int Rmpfr_flags_save(void) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     mpfr_flags_t ret = mpfr_flags_save();
     return (unsigned int)ret;
#else
     croak("Rmpfr_flags_save not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

void Rmpfr_flags_restore(unsigned int flags, unsigned int mask) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     mpfr_flags_restore((mpfr_flags_t) flags, (mpfr_flags_t) mask);
#else
     croak("Rmpfr_flags_restore not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_rint_roundeven(mpfr_t * rop, mpfr_t * op, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_rint_roundeven(*rop, *op, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_rint_roundeven not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_roundeven(mpfr_t * rop, mpfr_t * op) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     return(mpfr_roundeven(*rop, *op));
#else
     croak("Rmpfr_roundeven not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_nrandom(mpfr_t * rop, gmp_randstate_t * state, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     return(mpfr_nrandom(*rop, *state, (mpfr_rnd_t)round));
#else
     croak("Rmpfr_nrandom not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_erandom(mpfr_t * rop, gmp_randstate_t * state, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
     return(mpfr_erandom(*rop, *state, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_erandom not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_fmma(mpfr_t * rop, mpfr_t * op1, mpfr_t * op2, mpfr_t * op3, mpfr_t * op4, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_fmma(*rop, *op1, *op2, *op3, *op4, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_fmma not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_fmms(mpfr_t * rop, mpfr_t * op1, mpfr_t * op2, mpfr_t * op3, mpfr_t * op4, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_fmms(*rop, *op1, *op2, *op3, *op4, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_fmms not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_log_ui(mpfr_t * rop, unsigned long op, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_log_ui(*rop, op, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_log_ui not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_gamma_inc(mpfr_t * rop, mpfr_t * op1, mpfr_t * op2, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_gamma_inc(*rop, *op1, *op2, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_gamma_inc not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int _have_IEEE_754_long_double(void) {
#if defined(HAVE_IEEE_754_LONG_DOUBLE)
    return 1;
#else
    return 0;
#endif
}

int _have_extended_precision_long_double(void) {
#if defined(HAVE_EXTENDED_PRECISION_LONG_DOUBLE)
    return 1;
#else
    return 0;
#endif
}

int nanflag_bug(void) {
#if !defined(MPFR_VERSION) || (defined(MPFR_VERSION) && MPFR_VERSION <= NANFLAG_BUG)
    return 1;
#else
    return 0;
#endif
}

SV * Rmpfr_buildopt_float128_p(pTHX) {
#if MPFR_VERSION_MAJOR >= 4
     return newSViv(mpfr_buildopt_float128_p());
#else
     croak("Rmpfr_buildopt_float128_p not implemented with this version of the mpfr library - we have %s but need at least 4.0.0", MPFR_VERSION_STRING);
#endif
}

SV * Rmpfr_buildopt_sharedcache_p(pTHX) {
#if MPFR_VERSION_MAJOR >= 4
     return newSViv(mpfr_buildopt_sharedcache_p());
#else
     croak("Rmpfr_buildopt_sharedcache_p not implemented with this version of the mpfr library - we have %s but need at least 4.0.0", MPFR_VERSION_STRING);
#endif
}

int _nv_is_float128(void) {
#if defined(USE_QUADMATH)
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

/*
Expects to return either 0 or 1:
*/

int _get_bit(pTHX_ char * s, mpfr_prec_t p) {

  if(s[p] == '1') return 1;
  if(s[p] != '0') croak ("Invalid bit value in Math::MPFR::_get_bit");
  return 0;

}

/*
 A function to return the least
 significant bit of the mantissa:
*/

SV * _lsb(pTHX_ mpfr_t * a) {

  char * buffer;
  mpfr_exp_t exponent;
  mpfr_prec_t p = mpfr_get_prec(*a);

  if(mpfr_nan_p(*a)) {
    mpfr_set_nanflag();
    return newSVuv(0);
  }

  if(mpfr_inf_p(*a)) return newSVuv(0);

  Newxz(buffer, p + 2, char);
  if(buffer == NULL) croak("Failed to allocate memory in _lsb function");

  mpfr_get_str(buffer, &exponent, 2, (size_t)p, *a, GMP_RNDN);

  if(!mpfr_signbit(*a)) p--;

  p = (mpfr_prec_t)_get_bit(aTHX_ buffer, p);

  Safefree(buffer);

  return newSVuv((UV)p);
}

int Rmpfr_rec_root(pTHX_ mpfr_t * rop, mpfr_t * op, unsigned long root, SV * round) {

  /*
    Originally supplied by Vincent Lefevre to mpfr mailing list.
    See https://sympa.inria.fr/sympa/arc/mpfr/2016-12/msg00032.html
    Sisyphus re-arranged it as an XSub and added handling of special
    cases (inf/nan/zero).
    Requires mpfr-3.1.0 or later.
  */

#if (MPFR_VERSION_MAJOR == 3 && MPFR_VERSION_MINOR >= 1) || MPFR_VERSION_MAJOR > 3

  mpfr_prec_t p;
  mpfr_t t, u;
  int inex1, inex2 = -1, inex3= 1;

  CHECK_ROUNDING_VALUE

  if(root == 0) {
    mpfr_set_nan(*rop);
    mpfr_set_nanflag();
    return 0;
  }

 /* At this point we know that "root" is greater than 0 */

  if(mpfr_zero_p(*op)) {
    mpfr_set_divby0();
    if(root % 2) {
      mpfr_set_inf(*rop, mpfr_signbit(*op) * -1);
      return 0;
    }
    mpfr_set_inf(*rop, 1);
    return 0;
  }

  /* and we now also know that op != 0 */

  if(mpfr_signbit(*op) && root % 2 == 0) {
      mpfr_set_nan(*rop);
      mpfr_set_nanflag();
      return 0;
  }

  /*
   All other special cases are handled correctly by the following code.
   This is all checked in t/Rmpfr_rec_root.t. (At least, that's the intention.)
  */

  p = mpfr_get_prec(*rop);
  mpfr_init2(t, p);
  mpfr_init2(u, p);

  while(
        (inex2 != inex3 && inex2 * inex3 <= 0)
        || mpfr_cmp(*rop, u)
       ) {
    mpfr_set_prec(t, mpfr_get_prec(t) + 8);
    inex1 = mpfr_ui_div(t, 1, *op, GMP_RNDZ);
#  if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
      inex2 = mpfr_rootn_ui(*rop, t, root, (mpfr_rnd_t)SvUV(round));
#  else
      inex2 = mpfr_root(*rop, t, root, (mpfr_rnd_t)SvUV(round));
#  endif
    if(!inex1) return inex2;
    mpfr_nextabove(t);
#  if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
      inex3 = mpfr_rootn_ui(u, t, root, (mpfr_rnd_t)SvUV(round));
#  else
      inex3 = mpfr_root(u, t, root, (mpfr_rnd_t)SvUV(round));
#  endif
  }
  return inex2;
#else
    croak("Rmpfr_set_divby0 not implemented with this version of the mpfr library - we have %s but need at least 3.1.0", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_beta(mpfr_t * rop, mpfr_t * op1, mpfr_t * op2, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_beta(*rop, *op1, *op2, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_beta not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int Rmpfr_rootn_ui (mpfr_t * rop, mpfr_t * op, unsigned long k, int round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= MPFR_VERSION_NUM(4,0,0)
    return(mpfr_rootn_ui(*rop, *op, k, (mpfr_rnd_t)round));
#else
    croak("Rmpfr_rec_root not implemented - need at least mpfr-4.0.0, have only %s", MPFR_VERSION_STRING);
#endif
}

int _ld_subnormal_bug(void) {

#if defined(LD_SUBNORMAL_BUG)
    return 1;
#else
    return 0;
#endif
}

/*
*  The atodouble function was written as a means to check that the atonv
*  function  handles subnormal double-doubles correctly.
*  But it is readily available for any other purpose, too.
*  On a perl whose nvtype is double it should return the same value as atonv,
*  though atodouble is not as efficient as atonv.
*/

double atodouble(char * str) {


#if defined(MPFR_VERSION) && MPFR_VERSION > 196869

    mpfr_t workspace;
    mpfr_prec_t emin, emax;
    int inex;
    double d;

    mpfr_init2(workspace, 53);

    emin = mpfr_get_emin();
    emax = mpfr_get_emax();

    mpfr_set_emin(-1073);
    mpfr_set_emax(1024);

    inex = mpfr_strtofr(workspace, str, NULL, 0, GMP_RNDN);
    mpfr_subnormalize(workspace, inex, GMP_RNDN);

    mpfr_set_emin(emin);
    mpfr_set_emax(emax);

    d = mpfr_get_d(workspace, GMP_RNDN);

    mpfr_clear(workspace);

    return d;

#else

    croak("The atodouble function requires mpfr-3.1.6 or later");

#endif
}

SV * atonv(pTHX_ SV * str) {


#if defined(MPFR_VERSION) && MPFR_VERSION > 196869
    mpfr_t workspace;
#  if NVSIZE == 8 || LDBL_MANT_DIG == 53        /* D */
      mpfr_prec_t emin, emax;
      int inex;
      double ret;

      mpfr_init2(workspace, 53);

      emin = mpfr_get_emin();
      emax = mpfr_get_emax();

      mpfr_set_emin(-1073);
      mpfr_set_emax(1024);

      inex = mpfr_strtofr(workspace, SvPV_nolen(str), NULL, 0, GMP_RNDN);
      mpfr_subnormalize(workspace, inex, GMP_RNDN);

      mpfr_set_emin(emin);
      mpfr_set_emax(emax);

      ret = mpfr_get_d(workspace, GMP_RNDN);
      mpfr_clear(workspace);

      return newSVnv(ret);

#  endif                                                  /* close D */

#  if defined(USE_LONG_DOUBLE) && LDBL_MANT_DIG != 53   /* LD */
#    if REQUIRED_LDBL_MANT_DIG == 64

        mpfr_prec_t emin, emax;
        int inex;
        long double ret;

        mpfr_init2(workspace, 64);

        emin = mpfr_get_emin();
        emax = mpfr_get_emax();

        mpfr_set_emin(-16444);
        mpfr_set_emax(16384);

        inex = mpfr_strtofr(workspace, SvPV_nolen(str), NULL, 0, GMP_RNDN);
        mpfr_subnormalize(workspace, inex, GMP_RNDN);

        mpfr_set_emin(emin);
        mpfr_set_emax(emax);

        ret = mpfr_get_ld(workspace, GMP_RNDN);
        mpfr_clear(workspace);

       return newSVnv(ret);

#    endif

#    if REQUIRED_LDBL_MANT_DIG == 113

        mpfr_prec_t emin, emax;
        int inex;
        long double ret;

        mpfr_init2(workspace, 113);

        emin = mpfr_get_emin();
        emax = mpfr_get_emax();

        mpfr_set_emin(-16493);
        mpfr_set_emax(16384);

        inex = mpfr_strtofr(workspace, SvPV_nolen(str), NULL, 0, GMP_RNDN);
        mpfr_subnormalize(workspace, inex, GMP_RNDN);

        mpfr_set_emin(emin);
        mpfr_set_emax(emax);

        ret = mpfr_get_ld(workspace, GMP_RNDN);
        mpfr_clear(workspace);

        return newSVnv(ret);

#    endif

#    if REQUIRED_LDBL_MANT_DIG == 2098

        mpfr_t dspace;
        double msd, lsd;        /* 'most' and 'least' significant doubles */
        mpfr_prec_t emin, emax;
        int inex;
        long double ret;

        mpfr_init2(workspace, 2098);
        mpfr_init2(dspace, 53);

        emin = mpfr_get_emin();
        emax = mpfr_get_emax();

        mpfr_set_emin(-1073);
        mpfr_set_emax(1024);

        inex = mpfr_strtofr(dspace, SvPV_nolen(str), NULL, 0, GMP_RNDN);
        mpfr_subnormalize(dspace, inex, GMP_RNDN);

        msd = mpfr_get_d(dspace, GMP_RNDN);

        if(!mpfr_regular_p(dspace)) {
          mpfr_clear(dspace);
          mpfr_set_emin(emin); /* restore to original value */
          mpfr_set_emax(emax); /* restore to original value */
          return newSVnv(msd);
        }

        mpfr_strtofr(workspace, SvPV_nolen(str), NULL, 0, GMP_RNDN);
        inex = mpfr_sub(dspace, workspace, dspace, GMP_RNDN);
        mpfr_subnormalize(dspace, inex, GMP_RNDN);
        lsd = mpfr_get_d(dspace, GMP_RNDN);

        mpfr_clear(dspace);
        mpfr_clear(workspace);

        mpfr_set_emin(emin); /* restore to original value */
        mpfr_set_emax(emax); /* restore to original value */

        return newSVnv((long double)msd + (long double)lsd);

#    endif
#  endif                                                  /* close LD */

#  if defined(USE_QUADMATH)                             /* F128 */
#    if defined(MPFR_WANT_FLOAT128)

        mpfr_prec_t emin, emax;
        int inex;
        __float128 ret;

        mpfr_init2(workspace, 113);

        emin = mpfr_get_emin();
        emax = mpfr_get_emax();

        mpfr_set_emin(-16493);
        mpfr_set_emax(16384);

        inex = mpfr_strtofr(workspace, SvPV_nolen(str), NULL, 0, GMP_RNDN);
        mpfr_subnormalize(workspace, inex, GMP_RNDN);

        mpfr_set_emin(emin);
        mpfr_set_emax(emax);

        ret = mpfr_get_float128(workspace, GMP_RNDN);
        mpfr_clear(workspace);
        return newSVnv(ret);

#    else
        croak("The atonv function is unavailable for this __float128 build of perl\n");
#    endif
#  endif                                                  /* close F128 */

      croak("The atonv function has encountered an unrecognized nvtype");

#else

    croak("The atonv function requires mpfr-3.1.6 or later");

#endif

} /* close atonv */

SV * Rmpfr_get_str_ndigits_alt(pTHX_ int base, UV prec) {

    /* Can use this if mpfr version is less than 4.1.0.    *
     * If mpfr version is at least 4.1.0, then the         *
     * Math::MPFR test suite checks that this function     *
     * produces the same results as Rmpfr_get_str_ndigits. */

    UV m = 1;
    int inexflag;
    mpfr_t temp1, temp2;

    inexflag = mpfr_inexflag_p();
    mpfr_init2(temp1, 128);
    mpfr_init2(temp2, 128);
    mpfr_set_ui(temp1, base, GMP_RNDN);
    mpfr_log2(temp2, temp1, GMP_RNDN);
    mpfr_trunc(temp1, temp2);

    if(mpfr_equal_p(temp1, temp2))
      mpfr_ui_div(temp1, (unsigned long)(prec - 1), temp2, GMP_RNDN);
    else
      mpfr_ui_div(temp1, (unsigned long)prec, temp2, GMP_RNDN);

    mpfr_ceil(temp1, temp1);
    m += mpfr_get_ui(temp1, GMP_RNDN);

    mpfr_clear(temp1);
    mpfr_clear(temp2);

    /* Clear the inex flag if it *
     * was unset to begin with   */

    if(!inexflag) mpfr_clear_inexflag();

    return newSVuv(m);

}

/* new in 4.1.0 (262400) */

SV * Rmpfr_get_str_ndigits(pTHX_ int base, SV * prec) {

    if(base < 2 || base > 62)
      croak("1st argument given to Rmpfr_get_str_ndigits must be in the range 2..62");

#if defined(MPFR_VERSION) && MPFR_VERSION >= 262400 /* version 4.1.0 */
#  if MPFR_VERSION == 262400
      int inexflag;
      size_t ret;

      inexflag = mpfr_inexflag_p();
      ret = mpfr_get_str_ndigits(base, (mpfr_prec_t)SvUV(prec));
      if(!inexflag) mpfr_clear_inexflag(); /* In case mpfr_get_str_ndigits changed it from *
                                            * unset to set. This was fixed after 4.1.0     */
      return newSVuv(ret);
#  else
      return newSVuv(mpfr_get_str_ndigits(base, (mpfr_prec_t)SvUV(prec)));
#  endif
#else
    return Rmpfr_get_str_ndigits_alt(aTHX_ base, SvUV(prec));
#endif
}


SV * Rmpfr_dot(pTHX_ mpfr_t * rop, SV * avref_A, SV * avref_B, SV * len, SV * round) {
#if defined(MPFR_VERSION) && MPFR_VERSION >= 262400 /* version 4.1.0 */
     mpfr_ptr *p_A, *p_B;
     SV ** elem;
     int ret, i;
     unsigned long s = (unsigned long)SvUV(len);

     if(s > av_len((AV*)SvRV(avref_A)) + 1 || s > av_len((AV*)SvRV(avref_B)) + 1)
       croak("2nd last arg to Rmpfr_dot is too large");

     Newx(p_A, s, mpfr_ptr);
     if(p_A == NULL) croak("Unable to allocate memory for first array in Rmpfr_dot");

     Newx(p_B, s, mpfr_ptr);
     if(p_B == NULL) croak("Unable to allocate memory for second array in Rmpfr_dot");

     for(i = 0; i < s; ++i) {
        elem = av_fetch((AV*)SvRV(avref_A), i, 0);
        p_A[i] = *(INT2PTR(mpfr_t *, SvIVX(SvRV(*elem))));
     }

     for(i = 0; i < s; ++i) {
        elem = av_fetch((AV*)SvRV(avref_B), i, 0);
        p_B[i] = *(INT2PTR(mpfr_t *, SvIVX(SvRV(*elem))));
     }

     ret = mpfr_dot(*rop, p_A, p_B, s, (mpfr_rnd_t)SvUV(round));

     Safefree(p_A);
     Safefree(p_B);
     return newSViv(ret);
#else
    croak("The Rmpfr_dot function requires mpfr-4.1.0 or later");
#endif
}

/********************************************************
 * Set exponent and precision for nvtoa to utilize. *
 *******************************************************/

void _get_exp_and_bits(mpfr_exp_t * exp, int * bits, NV nv_in) {

  int subnormal_prec_adjustment = 0, tmp;
  void *nvptr = &nv_in;

#if defined(USE_QUADMATH) || (defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 113)	/* 113 bit prec */

  int i = QIND_2;				/* big endian: 2, little endian: 13 */

  *exp = ((unsigned char *)nvptr)[QIND_0];	/* big endian: 0, little endian: 15 */
  *exp <<= 8;
  tmp = ((unsigned char *)nvptr)[QIND_1];	/* big endian: 1, little endian: 14 */
  *exp += tmp - 16382;

  if(*exp == -16382) {
    while(Q_CONDITION_1(i)) {	/* big endian:    (i <= 15) */
				/* little endian: (i >= 0 ) */
      tmp = ((unsigned char *)nvptr)[i];
      if(tmp) {
        BITSEARCH_8		/* defined in math_mpfr_include.h */
        break;
      }

      subnormal_prec_adjustment += 8;

      INC_OR_DEC(i);		/* big endian:    i++; */
				/* little endian: i--; */

    }			/* close while loop */
  }

  *exp  -= subnormal_prec_adjustment - 1;
  *bits =  113 - subnormal_prec_adjustment;

  if(!subnormal_prec_adjustment) (*exp)--;

/*********************
 * START DOUBLEDOUBLE*
 *********************/

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098	/* double-double */

  /***********************************************************************
   * This all works well enough (AFAIK), but needs reviewing with an eye *
   * towards tidying up and refactoring.                                 *
   * We don't need to determine the correct value of *exp as that value  *
   * is calculated after this sub returns - except for the case that     *
   * *bits == 1. Otherwise, all we need here is a correct evaluation of  *
   * *bits - for which we do need to look at the exponents of both       *
   * doubles.                                                            *
   * In the event that it might be useful at some point in the future,   *
   * I'm including the additional code (albeit, commented out) that also *
   * derives the correct value of *exp when *bits != 1.                  *
   ***********************************************************************/

  int msd_exp, lsd_exp, t, lsd_is_zero = 0;
  /**************************************************************************************************
   * Include next line for accurate calculation of *exp:                                            *
   *                                                                                                *
   * int lsd_is_negative_reduction = 0;                                                             *
   **************************************************************************************************/

  /*******************************************************
   * Determine if the least siginificant double is zero. *
   * If so, set lsd_is_zero to 1 and set *bits to 53.    *
   *******************************************************/

  if( (128 == ((unsigned char *)nvptr)[LSD_IND_0] || 0 == ((unsigned char *)nvptr)[LSD_IND_0])  &&
         0 == ((unsigned char *)nvptr)[LSD_IND_1] && 0 == ((unsigned char *)nvptr)[LSD_IND_2]   &&
         0 == ((unsigned char *)nvptr)[LSD_IND_3] && 0 == ((unsigned char *)nvptr)[LSD_IND_4]   &&
         0 == ((unsigned char *)nvptr)[LSD_IND_5] && 0 == ((unsigned char *)nvptr)[LSD_IND_6]   &&
         0 == ((unsigned char *)nvptr)[LSD_IND_7]
      ) {
    lsd_is_zero = 1;
    *bits = 53;
  }

  /* else *bits is currently still set at its initial value of 2098 */

  int i = MSD_IND_1;

  if(*bits == 53) { /* if the NV is subnormal, *bits need to be reduced accordingly */
    *exp = ((unsigned char *)nvptr)[MSD_IND_0];
    *exp <<= 4;
    tmp = ((unsigned char *)nvptr)[MSD_IND_1];
    *exp += (tmp >> 4) - 1022;

    if(*exp == -1022) {

      while(DD_CONDITION_1(i)) {			/* big endian:    (i <= 7) */
						/* little endian: (i >= 0) */

        tmp = ((unsigned char *)nvptr)[i];
        if(tmp) {
          if(i == MSD_IND_1) {
            BITSEARCH_4				/* defined in math_mpfr_include.h */
            break;
          }
          else {
            BITSEARCH_8				/* defined in math_mpfr_include.h */
            break;
          }
        }

        if(i == MSD_IND_1) subnormal_prec_adjustment += 4;
        else subnormal_prec_adjustment += 8;

        INC_OR_DEC(i);				/* big endian:    i++ */
						/* little endian: i-- */
      }
    }

    if(!subnormal_prec_adjustment){

      (*exp)--;

      if(*exp > 53) *bits = *exp;
      else if(*exp < 53) *bits += 1022 + *exp;
/****************************************************************************************************
 * Include next line for accurate calculation of *exp:                                              *
 *                                                                                                  *
 *     *exp += lsd_is_zero;                                                                         *
 ****************************************************************************************************/
    }
    else {
      *bits =  53 - subnormal_prec_adjustment;
      *exp  -= subnormal_prec_adjustment - 1; /* This line is currently needed when *bits == 1 */
    }

  }

  else {
    msd_exp = ((unsigned char *)nvptr)[MSD_IND_0];
    msd_exp <<= 4;
    tmp = ((unsigned char *)nvptr)[MSD_IND_1];
    msd_exp += (tmp >> 4) - 1022;

    lsd_exp = ((unsigned char *)nvptr)[LSD_IND_0];


    lsd_exp <<= 4;
    tmp = ((unsigned char *)nvptr)[LSD_IND_1];
    lsd_exp += tmp >> 4;
    if(lsd_exp > 2047) {
      lsd_exp -= 2048;
/****************************************************************************************************
 * Include next line for accurate calculation of *exp:                                              *
 *                                                                                                  *
 *     if(!lsd_is_zero) lsd_is_negative_reduction = 1;                                              *
 ****************************************************************************************************/
    }
    lsd_exp -= 1022;

    if(lsd_is_zero) *bits = 53;
    else *bits = 53 + msd_exp - lsd_exp;
/*****************************************************************************************************
 * Include this slab of code to correctly calculate *exp                                             *
 *                                                                                                   *
 *   if(lsd_is_negative_reduction) {		*//* lsd is negative and not zero *//*               *
 *     if(msd_exp - lsd_exp > 53) {		*//* need to check that msd is not a power of 2 *//* *
 *                                                                                                   *
 *       for(DD_CONDITION_2(i)) {			*//* big endian:    (i=2 ;i<8;i++) *//*              *
 *						*//* little endian: (i=13;i>7;i--) *//*              *
 *                                                                                                   *
 *         t = ((unsigned char *)nvptr)[i];                                                          *
 *         if(t != 0) {                                                                              *
 *           lsd_is_negative_reduction = 0;                                                          *
 *           break;                                                                                  *
 *         }                                                                                         *
 *       }                                                                                           *
 *                                                                                                   *
 *       if(lsd_is_negative_reduction) {                                                             *
 *         t = ((unsigned char *)nvptr)[MSD_IND_1];                                                      *
 *         if(t & 15) {                                                                              *
 *           lsd_is_negative_reduction = 0;                                                          *
 *         }                                                                                         *
 *       }                                                                                           *
 *     }                                                                                             *
 *     else lsd_is_negative_reduction = 0;                                                           *
 *   }                                                                                               *
 *****************************************************************************************************/
    if(lsd_exp < -1022) *bits += (lsd_exp + 1022);
    if(lsd_exp == -1022) *bits -= 1;

/****************************************************************************************************
 * Include next line for accurate calculation of *exp:                                              *
 *                                                                                                  *
 * *exp = msd_exp - lsd_is_negative_reduction;                                                      *
 ****************************************************************************************************/

  }

/*******************
 * END DOUBLEDOUBLE*
 *******************/

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 64	/* 64 bit prec */

  int i = LDIND_2;				/* big endian: 2, little endian: 7 */

  *exp = ((unsigned char *)nvptr)[LDIND_0];	/* big endian: 0, little endian: 9 */
  *exp <<= 8;
  tmp = ((unsigned char *)nvptr)[LDIND_1];	/* big endian: 1, little endian: 8 */
  *exp += tmp - 16382;

  if(*exp == -16382) {

    while(LD_CONDITION_1(i)) {			/* big endian:    (i <= 9) */
						/* little endian: (i >= 0) */
      tmp = ((unsigned char *)nvptr)[i];
      if(tmp) {
        BITSEARCH_8		/* defined in math_mpfr_include.h */
        break;
      }

      subnormal_prec_adjustment += 8;

      INC_OR_DEC(i);		/* big endian: i++; */
                                /* little endian: i--; */

    }			/* close while loop */
  }

  /* for both endians (64 bit) */
  if(subnormal_prec_adjustment) subnormal_prec_adjustment--;

  *exp  -= subnormal_prec_adjustment;
  *bits =  64 - subnormal_prec_adjustment;

  if(subnormal_prec_adjustment) (*exp)++;

#else									/* 53 bit prec */

  int i = DIND_1;				/* big endian: 1, little endian: 6 */

  *exp = ((unsigned char *)nvptr)[DIND_0];	/* big endian: 0, little endian: 7 */
  *exp <<= 4;
  tmp = ((unsigned char *)nvptr)[i];
  *exp += (tmp >> 4) - 1022;

  if(*exp == -1022) {

    while(D_CONDITION_1(i)) {	/* big endian:   (i <= 7) */
				/* little endan: (i >= 0) */
      tmp = ((unsigned char *)nvptr)[i];
      if(tmp) {
        if(i == 1) {
          BITSEARCH_4		/* defined in math_mpfr_include.h */
          break;
        }
        else {
          BITSEARCH_8		/* defined in math_mpfr_include.h */
          break;
        }
      }

      if(i == 1) subnormal_prec_adjustment += 4;
      else subnormal_prec_adjustment += 8;

      INC_OR_DEC(i);		/* big endian:    i++; */
				/* little endian: i--; */
    }
  }

  /* for both endians (53 bit) */
  *exp  -= subnormal_prec_adjustment - 1;
  *bits =  53 - subnormal_prec_adjustment;

  if(!subnormal_prec_adjustment) (*exp)--;

#endif

}



/* nvtoa function is adapted from p120 of  "How to Print Floating-Point Numbers Accurately" */
/* by Guy L. Steele Jr and Jon L. White                                                     */

SV * nvtoa(pTHX_ NV pnv) {
  int k = 0, k_index, lsb, skip = 0, sign = 0;
  int bits = NVSIZE_BITS, is_subnormal = 0, shift1, shift2, low, high, cmp, u;
  mpfr_exp_t e;    /* Change to 'int' when mpfr dependency for doubledouble is removed */
  NV nv;
  void *nvptr = &nv;
#if NVSIZE == 8
  char f[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0'};

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 64
  char f[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
              '\0','\0','\0','\0'};

#elif REQUIRED_LDBL_MANT_DIG == 2098 && defined(USE_LONG_DOUBLE)
  char *f;
  mpfr_t ws;

#else
  char f[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0',
              '\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0'};

#endif
  mpz_t R, S, M_minus, M_plus, LHS, TMP;
  char str[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0'};
  char * c = "0123456789abcdef";
  char *out;

  nv = pnv; /* Don't fiddle with pnv - instead fiddle with a copy */

#if defined(MPFR_HAVE_BENDIAN)

  if(((unsigned char *)nvptr)[0] >= 128) {
#  if defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098
      nv = -nv;
#  else
      ((unsigned char *)nvptr)[0] &= 127;
#  endif

#elif NVSIZE == 8
  if(((unsigned char *)nvptr)[7] >= 128) {
    ((unsigned char *)nvptr)[7] &= 127;
#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 64
  if(((unsigned char *)nvptr)[9] >= 128) {
    ((unsigned char *)nvptr)[9] &= 127;
#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098
  if(((unsigned char *)nvptr)[15] >= 128) {
    nv = -nv;
#else
  if(((unsigned char *)nvptr)[15] >= 128) {
    ((unsigned char *)nvptr)[15] &= 127;
#endif
    sign = 1;
  }

  if(nv == 0) {
    if(sign) return newSVpv("-0.0", 0);
    return newSVpv("0.0", 0);
  }

  if(nv != nv) {
    return newSVpv("NaN", 0);
  }

  if(nv > MATH_MPFR_NV_MAX) {
    if(sign) return newSVpv("-Inf", 0);
    return newSVpv("Inf", 0);
  }

  mpz_init(R);
  mpz_init(S);
  mpz_init(M_plus);
  mpz_init(M_minus);
  mpz_init(LHS);
  mpz_init(TMP);

/***********************************************************************************
 * Set bits to the precision of the mantissa, including any implicit leading bit.  *
 * If the value is subnormal, then bits will be set to the actual precision of the *
 * subnormal value. See the examples given a couple of lines below.                *
 * Also set exp to the (binary) exponent.                                          *
 * eg (for nvtype of double):                                                      *
 *  if nv == 10000000000.0 (0x1.2a05f2p+33)         then e == 34    and bits == 53 *
 *  if nv == 1.125e-100    (0x1.f7f14c11fc5d6p-333) then e == -332  and bits == 53 *
 *  if nv == 2 ** -1073    (0x1p-1073)              then e == -1072 and bits == 2  *
 *  if nv == 2 ** -1074    (0x1p-1074)              then e == -1073 and bits == 1  *
 ***********************************************************************************/
  _get_exp_and_bits( &e, &bits, nv);

#if REQUIRED_LDBL_MANT_DIG == 2098 && defined(USE_LONG_DOUBLE)

  if(bits < 53) is_subnormal = 1;

#else

  if(bits < NVSIZE_BITS) is_subnormal = 1; /* NVSIZE_BITS == precision of NV's mantissa */

#endif

/***************
 * Assign to f *
 ***************/

  if(bits == 1) {
#if defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098			/* doubledouble */
    Newxz(f, 4, char);
    if(f == NULL) croak("Failed to allocate memory for string buffer in nvtoa XSub");
#endif
    f[0] = c[1];
  }
  else {

#if defined(USE_QUADMATH) || (defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 113)	/* 113 bit prec */

    f[0] = is_subnormal ? c[0] : c[1];
    k++;

   for(skip = QIND_2; Q_CONDITION_1(skip); INC_OR_DEC(skip)) { /* big endian:
                                                                *   skip=2;skip<=15;skip++ */
                                                               /* little endian:
                                                                *   skip=13;skip>=0;skip-- */
      low = ((unsigned char *)nvptr)[skip];
      f[k] = c[low >> 4];
      f[k + 1] = c[low & 15];
      k += 2;
    }

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098			/* doubledouble */

    /*********************************************
     * TODO: Remove the mpfr dependency entirely *
     ********************************************/

    mpfr_init2(ws, bits);
    mpfr_set_ld(ws, nv, GMP_RNDN);

    Newxz(f, bits + 8, char);
    if(f == NULL) croak("Failed to allocate memory for string buffer in nvtoa XSub");

    mpfr_get_str(f, &e, 2, bits, ws, GMP_RNDN);		/* using mpfr to set both f and e */
    mpfr_clear(ws);

#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 64	/* 64 bit prec */

    for(skip = LDIND_2; LD_CONDITION_1(skip); INC_OR_DEC(skip)) { /* big endian:             *
                                                                   *   skip=2;skip<=9;skip++ */
                                                                  /* little endian:          *
                                                                   *   skip=7;skip>=0;skip-- */

      low = ((unsigned char *)nvptr)[skip];
      f[k] = c[low >> 4];
      f[k + 1] = c[low & 15];
      k += 2;
    }

#else									/* 53 bit prec */

    for(skip = DIND_1; D_CONDITION_1(skip); INC_OR_DEC(skip)) { /* big endian:             *
                                                                 *   skip=1;skip<=7;skip++ */
                                                                /* little endian:          *
                                                                 *   skip=6;skip>=0;skip-- */
      low = ((unsigned char *)nvptr)[skip];
      if(!k) {
        f[0] = is_subnormal ? c[0] : c[1];
        f[1] = c[low & 15];
      }
      else {
        f[k] = c[low >> 4];
        f[k + 1] = c[low & 15];
      }
      k += 2;
    }
#endif

  }

/********************************
 * assignment to f is completed *
 ********************************/

#ifdef NVTOA_DEBUG
  warn(" f is %s\n exponent is %d\n precision is %d\n", f, (int)e, bits);

/******************************************************************************
 * eg (for nvtype of double):                                                 *
 *  if nv == 10000000000.0 (0x1.2a05f2p+33) then f is 12a05f20000000 and      *
 *           e == 34, bits == 53. (Note that nv == 0x0.12a05f20000000p34)     *
 *  if nv == 1.125e-100 (0x1.f7f14c11fc5d6p-333) then f is 1f7f14c11fc5d6 and *
 *           e == -332, bits == 53. (Note that nv == 0x0.1f7f14c11fc5d6p-333) *
 *  if nv == 2 **-1073 (0x2p-1073) then f is 2 and e == -1072, bits == 2.     *
 *           (Note that nv == 0x0.2p-1072)                                    *
 *  if nv == 2 **-1074 (0x1p-1074) then f is 1 and e == -1073, bits == 1.     *
 *           (Note that nv == 0x0.1p-1073)                                    *
 ******************************************************************************/

#endif

#if defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098			/* doubledouble */

  mpz_set_str(R, f, 2);
  Safefree(f);

#else

  mpz_set_str(R, f, 16);

#endif

  lsb = mpz_tstbit(R, 0); /* Set lsb to the value of R's least significant bit */
  mpz_set(TMP, R);

  if(mpz_sgn(R) < 1) croak("Negative value in nvtoa XSub is not allowed");
  mpz_set_ui(S, 1);

  shift2 = e - bits;

  shift1 = shift2 > 0 ? shift2 : 0;
  mpz_mul_2exp(R, R, shift1);

  shift2 = shift1       ? 0 : -shift2;
  mpz_mul_2exp(S, S, shift2);

  mpz_set_ui(M_minus, 1);
  mpz_mul_2exp(M_minus, M_minus, shift1);
  mpz_set(M_plus, M_minus);

  /*************** start simple fixup **************/

  if(!is_subnormal) {
    mpz_set_ui(LHS, 1);
    mpz_mul_2exp(LHS, LHS, bits - 1);
    if(!mpz_cmp(LHS, TMP)) {
      mpz_mul_2exp(M_plus, M_plus, 1);
      mpz_mul_2exp(R,      R,      1);
      mpz_mul_2exp(S,      S,      1);
    }
  }

  k = 0;	/* used above, so we reset to zero */
  skip = 0;	/* used above, so we reset to zero */

  mpz_cdiv_q_ui(LHS, S, 10); /* LHS = ceil(S / 10) */

  if(mpz_cmp(LHS, R) > 0) {

    /* Set k to be close to, but not greater than, the number of     *
     * decimal digits needed to represent the value of LHS. This     *
     * reduces the number of times that we need to loop through the  *
     * the next while{} loop.                                        *
     * Note that 0.30102999566398118 is slightly less than log2(10). */

    k = (int)floor(mpz_sizeinbase(LHS, 2) * 0.30102999566398118);
    if(k) k--;    /* Do not decrement if k is zero */
    mpz_ui_pow_ui(TMP, 10, k);
    k *= -1;

#ifdef NVTOA_DEBUG
    warn(" k init: %d\n", k);
#endif

    mpz_mul(R, R, TMP);
    mpz_mul(M_minus, M_minus, TMP);
    mpz_mul(M_plus, M_plus, TMP);
  }
  else {
    skip = 1; /* No need to enter the following while() loop */
  }

  if(!skip) {
    while(1) {

#ifdef NVTOA_DEBUG
      warn("In first loop\n");
#endif

      if(mpz_cmp(LHS, R) <= 0) break;
      k--;
      mpz_mul_ui(R, R, 10);
      mpz_mul_ui(M_minus, M_minus, 10);
      mpz_mul_ui(M_plus, M_plus, 10);
    }                                   /* close first while loop */

#ifdef NVTOA_DEBUG
    warn(" k post 1st loop: %d\n", k);
#endif

  }

  mpz_mul_2exp(LHS, R, 1);
  mpz_add(LHS, LHS, M_plus);
  mpz_mul_2exp(TMP, S, 1);

  if(mpz_cmp(LHS, TMP) >= 0) {

#ifdef NVTOA_DEBUG
    gmp_printf("LHS: %Zd\nTMP: %Zd\n", LHS, TMP);
#endif

    skip = 0;
    mpz_div(TMP, LHS, TMP);

#ifdef NVTOA_DEBUG
    gmp_printf("TMP (= LHS / TMP): %Zd\n", TMP);
#endif

    /* Set u to be close to, but not greater than, the number of     *
     * decimal digits needed to represent the value of TMP. This     *
     * reduces the number of times that we need to loop through the  *
     * the next while{} loop.                                        *
     * Note that 0.30102999566398118 is slightly less than log2(10). */

    u = (int)floor(mpz_sizeinbase(TMP, 2) * 0.30102999566398118);
    /* if(u) u--; *//* Decrement not needed here, AFAIK. */
    mpz_ui_pow_ui(TMP, 10, u);
    k += u;

#ifdef NVTOA_DEBUG
    gmp_printf("TMP (= 10 ** %d): %Zd\n", u, TMP);
    warn(" u init: %d\n k set to: %d\n", u, k);
#endif

    mpz_mul(S, S, TMP);
  }
  else {
    skip = 1; /* No need to enter the following while() loop */
  }

  if(!skip) {
    while(1) {

#ifdef NVTOA_DEBUG
      warn("In second loop\n");
#endif

      mpz_mul_2exp(TMP, S, 1);

      if(mpz_cmp(LHS, TMP) < 0) break;

      mpz_mul_ui(S, S, 10);
      k++;
    }                                 /* close second while loop */

#ifdef NVTOA_DEBUG
    warn(" k post 2nd loop: %d\n", k);
#endif

  }

  /*********************** finish simple fixup **********************/

  k_index = -1;

  Newxz(out, (int)(12 + ceil(0.30103 * bits)), char); /* 1 + ceil(log(2) / log(10) * bits), but allow a few extra for
                                                       exponent and sign */

  if(out == NULL) croak("Failed to allocate memory for output string in nvtoa XSub");

  /* Each iteration of the following while() loop outputs, one at a time, the *
   * digits of the final mantissa - except for the final (least significant)  *
   * digit Which is set following the termination of the loop.                */

  while(1) {

    k_index++;

    mpz_mul_ui(TMP, R, 10);
    mpz_fdiv_qr(LHS, R, TMP, S);
    u = mpz_get_ui(LHS);

    mpz_mul_ui(M_minus, M_minus, 10);
    mpz_mul_ui(M_plus, M_plus, 10);

    mpz_mul_2exp(LHS, R, 1);

    cmp = mpz_cmp(LHS, M_minus);

    if(!cmp && !lsb && !is_subnormal) { /* !lsb implies that f is even */
      low = 1;
    }
    else {
      low = cmp < 0 ? 1 : 0;
    }

    mpz_mul_2exp(TMP, S, 1);
    mpz_sub(TMP, TMP, M_plus);

    cmp = mpz_cmp(LHS, TMP);

    if(!cmp && !lsb && !is_subnormal) { /* !lsb implies that f is even */
      high = 1;
    }
    else {
      high = cmp > 0 ? 1 : 0;
    }

    if(low | high) break;

    out[k_index] = 48 + u;

  }                                   /* close while loop */

  /* Next we set the final digit, rounding up where appropriate */

  if(low & high) {                                  /* ( low &&  high) */
    mpz_mul_2exp(LHS, R, 1);
    cmp = mpz_cmp(LHS, S);
    if        (cmp >  0) out[k_index] = 49 + u;
    else if   (cmp <  0) out[k_index] = 48 + u;
    else { /* (cmp == 0) */
      if(u & 1)          out[k_index] = 49 + u;
      else               out[k_index] = 48 + u;
    }
  }
  else if(high)          out[k_index] = 49 + u; /* (!low &&  high) */
  else                   out[k_index] = 48 + u; /* ( low && !high) */

  mpz_clear(R);
  mpz_clear(S);
  mpz_clear(M_plus);
  mpz_clear(M_minus);
  mpz_clear(LHS);
  mpz_clear(TMP);

#ifdef NVTOA_DEBUG
  warn("nvtoa: %s %d %d\n", out, k, bits);
#endif

/*******************************************************************************************
 * eg (for nvtype of double):                                                              *
 *  if nv == 10000000000.0, final string is set to 1, k == 11.  Note that nv == 0.1e11     *
 *  if nv == 1.125e-100, final string is set to 1125, k == -99. Note that nv == 0.1125e-99 *
 *  if nv == 2 ** -1073, final string is set to 1, k == -322.   Note that nv == 0.1e-322   *
 *  if nv == 2 ** -1074, final string is set to 5, k == -323.   Note that nv == 0.5e-323   *
 *******************************************************************************************/

  /*******************************
   * Return the formatted result *
   *******************************/

  /* printf("# nvtoa: %s %d\n", out, k); */

  return _fmt_flt(aTHX_ out, k, sign, MATH_MPFR_MAX_DIG, 1);

}

/****************************
 * END nvtoa                *
 ****************************/

/****************************
 * BEGIN mpfrtoa            *
 ****************************/

/* mpfrtoa is, like nvtoa, adapted from p120 of     *
 * "How to Print Floating-Point Numbers Accurately" *
 * by Guy L. Steele Jr and Jon L. White             */

SV * mpfrtoa(pTHX_ mpfr_t * pnv) {
  int k = 0, k_index, lsb, skip = 0, sign = 0;
  int bits, shift1, shift2, low, high, cmp, u;
  mpfr_exp_t e;
  mpz_t R, S, M_plus, M_minus, LHS, TMP;

  /* Assign 24 bytes to str[] */
  char str[] = {'\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0','\0'};

  char * f, *out;

  sign = mpfr_signbit(*pnv);

  if(!mpfr_regular_p(*pnv)) {
    if(mpfr_zero_p(*pnv)) {
      if(sign) return newSVpv("-0.0", 0);
      return newSVpv("0.0", 0);
    }

    if(mpfr_nan_p(*pnv)) {
      return newSVpv("NaN", 0);
    }

    /* Must be Inf */

    if(sign) return newSVpv("-Inf", 0);
    return newSVpv("Inf", 0);
  }

  mpz_init(R);
  mpz_init(S);
  mpz_init(M_plus);
  mpz_init(M_minus);
  mpz_init(LHS);
  mpz_init(TMP);

/***************
 * Assign to f *
 ***************/

  bits = mpfr_get_prec(*pnv);

  Newxz(f, bits + 8, char);
  if(f == NULL) croak("Failed to allocate memory for string buffer in mpfrtoa XSub");

  mpfr_get_str(f, &e, 2, bits, *pnv, GMP_RNDN);


/********************************
 * assignment to f is completed *
 ********************************/

#ifdef NVTOA_DEBUG
   warn(" f is %s\n exponent is %d\n precision is %d\n", f, (int)e, bits);
#endif

  if(sign) f++;

  mpz_set_str(R, f, 2);

  if(sign) f--;
  Safefree(f);

  lsb = mpz_tstbit(R, 0); /* Set lsb to the value of R's least significant bit */
  mpz_set(TMP, R);

  if(mpz_sgn(R) < 1) croak("Negative value in mpfrtoa XSub is not allowed");
  mpz_set_ui(S, 1);

  shift2 = e - bits;

  shift1 = shift2 > 0 ? shift2 : 0;
  mpz_mul_2exp(R, R, shift1);

  shift2 = shift1       ? 0 : -shift2;
  mpz_mul_2exp(S, S, shift2);

  mpz_set_ui(M_minus, 1);
  mpz_mul_2exp(M_minus, M_minus, shift1);
  mpz_set(M_plus, M_minus);

  /*************** start simple fixup **************/

  mpz_set_ui(LHS, 1);
  mpz_mul_2exp(LHS, LHS, bits - 1);
  if(!mpz_cmp(LHS, TMP)) {
    mpz_mul_2exp(M_plus, M_plus, 1);
    mpz_mul_2exp(R,      R,      1);
    mpz_mul_2exp(S,      S,      1);
  }

  k = 0;	/* used above, so we reset to zero */
  skip = 0;	/* used above, so we reset to zero */

  mpz_cdiv_q_ui(LHS, S, 10); /* LHS = ceil(S / 10) */

  if(mpz_cmp(LHS, R) > 0) {

    /* Set k to be close to, but not greater than, the number of     *
     * decimal digits needed to represent the value of LHS. This     *
     * reduces the number of times that we need to loop through the  *
     * the next while{} loop.                                        *
     * Note that 0.30102999566398118 is slightly less than log2(10). */

    k = (int)floor(mpz_sizeinbase(LHS, 2) * 0.30102999566398118);
    if(k) k--;    /* Do not decrement if k is zero */
    mpz_ui_pow_ui(TMP, 10, k);
    k *= -1;
#ifdef NVTOA_DEBUG
    warn(" k init: %d\n", k);
#endif
    mpz_mul(R, R, TMP);
    mpz_mul(M_minus, M_minus, TMP);
    mpz_mul(M_plus, M_plus, TMP);
  }
  else {
    skip = 1; /* No need to enter the following while() loop */
  }

  if(!skip) {
    while(1) {
      if(mpz_cmp(LHS, R) <= 0) break;
      k--;
      mpz_mul_ui(R, R, 10);
      mpz_mul_ui(M_minus, M_minus, 10);
      mpz_mul_ui(M_plus, M_plus, 10);
    }                                   /* close first while loop */
#ifdef NVTOA_DEBUG
    warn(" k post 1st loop: %d\n", k);
#endif
  }

  mpz_mul_2exp(LHS, R, 1);
  mpz_add(LHS, LHS, M_plus);
  mpz_mul_2exp(TMP, S, 1);

  if(mpz_cmp(LHS, TMP) >= 0) {
    skip = 0;
    mpz_div(TMP, LHS, TMP);

    /* Set u to be close to, but not greater than, the number of     *
     * decimal digits needed to represent the value of TMP. This     *
     * reduces the number of times that we need to loop through the  *
     * the next while{} loop.                                        *
     * Note that 0.30102999566398118 is slightly less than log2(10). */

    u = (int)floor(mpz_sizeinbase(TMP, 2) * 0.30102999566398118);
    /* if(u) u--; *//* Decrement not needed here, AFAIK. */
    mpz_ui_pow_ui(TMP, 10, u);
    k += u;
#ifdef NVTOA_DEBUG
    warn(" u init: %d\n k set to: %d\n", u, k);
#endif
    mpz_mul(S, S, TMP);
  }
  else {
    skip = 1; /* No need to enter the following while() loop */
  }

  if(!skip) {
    while(1) {
      mpz_mul_2exp(TMP, S, 1);

      if(mpz_cmp(LHS, TMP) < 0) break;

      mpz_mul_ui(S, S, 10);
      k++;
    }                                 /* close second while loop */
#ifdef NVTOA_DEBUG
    warn(" k post 2nd loop: %d\n", k);
#endif
  }

  /*********************** finish simple fixup **********************/

  k_index = -1;

  Newxz(out, (int)(12 + ceil(0.30103 * bits)), char); /* 1 + ceil(log(2) / log(10) * bits), but  *
                                                       * allow a few extra for exponent and sign */

  if(out == NULL) croak("Failed to allocate memory for output string in mpfrtoa XSub");

  /* Each iteration of the following while() loop outputs, one at a time, the *
   * digits of the final mantissa - except for the final (least significant)  *
   * digit Which is set following the termination of the loop.                */

  while(1) {

    k_index++;

    mpz_mul_ui(TMP, R, 10);
    mpz_fdiv_qr(LHS, R, TMP, S);
    u = mpz_get_ui(LHS);

    mpz_mul_ui(M_minus, M_minus, 10);
    mpz_mul_ui(M_plus, M_plus, 10);

    mpz_mul_2exp(LHS, R, 1);

    cmp = mpz_cmp(LHS, M_minus);

    if(!cmp && !lsb) { /* !lsb implies that f is even */
      low = 1;
    }
    else {
      low = cmp < 0 ? 1 : 0;
    }

    mpz_mul_2exp(TMP, S, 1);
    mpz_sub(TMP, TMP, M_plus);

    cmp = mpz_cmp(LHS, TMP);

    if(!cmp && !lsb) { /* !lsb implies that f is even */
      high = 1;
    }
    else {
      high = cmp > 0 ? 1 : 0;
    }

    if(low | high) break;

    out[k_index] = 48 + u;

  }                                   /* close while loop */

  /* Next we set the final digit, rounding up where appropriate */

  if(low & high) {                                  /* ( low &&  high) */
    mpz_mul_2exp(LHS, R, 1);
    cmp = mpz_cmp(LHS, S);
    if        (cmp >  0) out[k_index] = 49 + u;
    else if   (cmp <  0) out[k_index] = 48 + u;
    else { /* (cmp == 0) */
      if(u & 1)          out[k_index] = 49 + u;
      else               out[k_index] = 48 + u;
    }
  }
  else if(high)          out[k_index] = 49 + u; /* (!low &&  high) */
  else                   out[k_index] = 48 + u; /* ( low && !high) */

  mpz_clear(R);
  mpz_clear(S);
  mpz_clear(M_plus);
  mpz_clear(M_minus);
  mpz_clear(LHS);
  mpz_clear(TMP);

#ifdef NVTOA_DEBUG
  warn(" final string: %s\n k = %d\n", out, k);
#endif

  /*********************
   * Return the formatted the result *
   *********************/

  return _fmt_flt(aTHX_ out, k, sign, (int)ceil(3.010299956639812e-1 * mpfr_get_prec(*pnv)) + 1, 1);
}

/****************************
 * END mpfrtoa              *
 ****************************/

/****************************
 * BEGIN doubletoa          *
 ****************************/

void set_fallback_flag(pTHX) {
 dSP;

 PUSHMARK(SP);
 call_pv("Math::MPFR::perl_set_fallback_flag", G_DISCARD|G_NOARGS);
}

SV * doubletoa(pTHX_ SV * sv, ...) {

  /* calls functions contained in grisu3.c */

#if NVSIZE == 8

  dXSARGS;

  double v = SvNV(sv);
  int d_exp, len, success, sign = 1;
  uint64_t u64;

  char dst [] = {'\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0',
                 '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0', '\0'};

  char *s2 = dst;

  int fallback = items > 1 ? 0 : 1; /* A true value for sign implies that nvtoa(aTHX) will be used  *
                                 * if grisu3() fails to produce a result. Else sprintf()    *
                                 * will be used when grisu3() fails. See pod documentation. */
#ifdef DTOA_ASSERT
  if(!dst) croak("dst does not hold a true value");
  /* assert(dst); */
#endif

  if(v < 0) {
    v = -v;
    sign = -1;
  }

  u64 = CAST_U64(v);

  /* Prehandle NaNs */
  if((u64 << 1) > 0xFFE0000000000000ULL) {
    sprintf(dst, "NaN");
    return newSVpv(dst, 0);
  }

  /* Prehandle zero. */
  if(v == 0) {
    if(u64) *s2++ = '-';
    *s2++ = '0';
    *s2++ = '.';
    *s2++ = '0';
    *s2 = '\0';
    return newSVpv(dst, 0);
  }

  /* Prehandle infinity. */
  if(u64 == D64_EXP_MASK) {
    if(sign < 0) *s2++ = '-';
    *s2++ = 'I';
    *s2++ = 'n';
    *s2++ = 'f';
    *s2 = '\0';
    return newSVpv(dst, 0);
  }

  success = grisu3(v, s2, &len, &d_exp);

  /* If grisu3 was not able to convert the number to a string, then use either nvtoa or sprintf. */
  /* Both are accurate - and sprintf is quicker than nvtoa. However, unlike nvtoa, sprintf will  */
  /* sometimes deliver more digits than are necessary.                                           */

  if(!success) {
#if defined FALLBACK_NOTIFY
    set_fallback_flag(aTHX);
#endif

    if(fallback) return nvtoa(aTHX_ v * sign);

    sprintf(s2, "%.16e", (v * sign));
    return newSVpv(dst, 0);
  }

  /* We have an integer string of form "151324135" and a base-10 exponent for that number. */
  /* Now, we just need to format it ...                                                    */

  /* printf("# doubletoa: %s %d\n", dst, d_exp + strlen(dst)); */

  return _fmt_flt(aTHX_ dst, (int)(d_exp + strlen(dst)), sign < 0 ? 1 : 0, MATH_MPFR_MAX_DIG, 0);

#else
  croak("The doubletoa function is unavailable - it requires that $Config{nvsize} == 8");
#endif
}


/****************************
 *  END doubletoa           *
 ****************************/

int _fallback_notify(void) {
#if defined(FALLBACK_NOTIFY)
  return 1;
#else
  return 0;
#endif
}

SV * numtoa(pTHX_ SV * in) {
  char buffer[IVSIZE * 3];

  if(!SvOK(in) || SvUOK(in)) {
    sprintf(buffer, "%" UVuf, SvUV(in));
    return newSVpv(buffer, 0);
  }

  if(SV_IS_IOK(in)) {
    sprintf(buffer, "%" IVdf, SvIV(in));
    return newSVpv(buffer, 0);
  }

  if(SV_IS_NOK(in)) {
    return nvtoa(aTHX_ SvNV(in));
  }

  croak("Not a numeric argument given to numtoa function");
}

void decimalize(pTHX_ SV * a, ...) {
  dXSARGS;
  mpfr_prec_t prec, i;
  mpfr_exp_t exp, high_exp, low_exp;
  char * buff;
  char * dec_buff;
  int is_neg = 0;
  double digits = 0;
  double div = 3.32192809488736;	/* log2(10) */
  double mul = 0.698970004336019;	/* log10(5) */

  if(!mpfr_regular_p(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))))) {
    if(items > 1) {
      ST(0) = sv_2mortal(newSViv(0));
      XSRETURN(1);
    }
    Newxz(buff, 8, char);
    mpfr_sprintf(buff, "%Rg", *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))));
    ST(0) = MORTALIZED_PV(buff);    /* defined in math_mpfr_include.h */
    Safefree(buff);
    XSRETURN(1);
  }

  prec = mpfr_get_prec(*(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))));

#if 262146 > MPFR_VERSION
  if(prec < 2) croak("Precision of 1 not allowed in decimalize function until mpfr-4.0.2");
#endif

  Newxz(buff, prec + 2, char);

  mpfr_get_str(buff, &exp, 2, prec, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))), GMP_RNDN);

  /* The decimal point is implicitly located at the very *
   * beginning of the string. Therefore, the power of 2  *
   * to which the highest set bit is raised is exp - 1   */

  high_exp = exp - 1;

  if(high_exp >= prec - 1) low_exp = 0; /* No need to locate the lowest set bit */

  else {

    /* We do need to locate the lowest set bit */

    if(buff[0] == '-') {
      buff++;
      is_neg = -1;
    }

    /* The power to which the lowest set bit is raised is  *
     * calculated in the following for{} loop:             */

    for(i = prec - 1; i >= 0; i--) {
      if(buff[i] == '1') {
        low_exp = high_exp - i;
        break;
      }
    }

    if(is_neg) buff--;
  }

  Safefree(buff);

  /* Next determine the number of decimal digits that are needed to   *
   * exactly express the function's argument in base 10               */

  if(low_exp >= 0) {
    /* Both low_exp and high_exp are >= 0.                            *
     * The number of digits is calculated solely from high_exp.       *
     * We add on "1" to allow for cases where the value of high_exp   *
     * does not alone determine how many siginificant digits are      *
     * required - eg the value 2 ** 13 (8192) requires 4 decimal      *
     * digits, but if the second highest bit is also set, then 5      *
     * decimal digits are needed because (2**13) + (2**12) == 12288   */

    digits = 1 + ceil( high_exp / div );
  }

  else if(high_exp < 0) {
    /* Both low_exp and high_exp are < 0 */

    digits = ceil( -low_exp * mul ) + ceil( -low_exp / div ) - floor( -high_exp / div );
  }

  else {
    /* low_exp < 0, high_exp >= 0        *
     * Add 1, as in the above if{} block */

    digits = 1 + ceil( high_exp / div ) + ceil( -low_exp * mul ) + floor( -low_exp / div );
  }

  if(digits > INT_MAX - 30)
    croak("Too many digits (%.0f) requested in decimalize function", digits);

  if(items > 1) {
    ST(0) = sv_2mortal(newSViv((IV)digits));
    XSRETURN(1);
  }

  Newxz(dec_buff, (int)digits + 30, char); /* allow for a 20-digit exponent, a radix point, *
                                            * a leading '-', an 'e-', a terminating NULL,   *
                                            * and a saftety net of 5 bytes (== 30, total)   */
  if(dec_buff == NULL)
    croak("Unable to allocate %.0f bytes of memory in decimalize function",
          digits + 30.0);

  mpfr_sprintf(dec_buff, "%.*Rg", (int)digits, *(INT2PTR(mpfr_t *, SvIVX(SvRV(a)))));
  ST(0) = MORTALIZED_PV(dec_buff);    /* defined in math_mpfr_include.h */
  Safefree(dec_buff);
  XSRETURN(1);

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

int _sis_perl_version(void) {
    return SIS_PERL_VERSION;
}



MODULE = Math::MPFR  PACKAGE = Math::MPFR

PROTOTYPES: DISABLE


int
_has_inttypes ()


int
NNW_val ()
CODE:
  RETVAL = NNW_val (aTHX);
OUTPUT:  RETVAL


int
NOK_POK_val ()
CODE:
  RETVAL = NOK_POK_val (aTHX);
OUTPUT:  RETVAL


int
_win32_infnanstring (s)
	char *	s

SV *
_fmt_flt (out, k, sign, max_decimal_prec, sf)
	char *	out
	int	k
	int	sign
	int	max_decimal_prec
	int	sf
CODE:
  RETVAL = _fmt_flt (aTHX_ out, k, sign, max_decimal_prec, sf);
OUTPUT:  RETVAL

void
Rmpfr_set_default_rounding_mode (round)
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_default_rounding_mode(aTHX_ round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned long
Rmpfr_get_default_rounding_mode ()


SV *
Rmpfr_prec_round (p, prec, round)
	mpfr_t *	p
	SV *	prec
	SV *	round
CODE:
  RETVAL = Rmpfr_prec_round (aTHX_ p, prec, round);
OUTPUT:  RETVAL

void
DESTROY (p)
	mpfr_t *	p
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
Rmpfr_clear (p)
	mpfr_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clear_mpfr (p)
	mpfr_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_mpfr(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clear_ptr (p)
	mpfr_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_ptr(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clears (p, ...)
	SV *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clears(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_init ()
CODE:
  RETVAL = Rmpfr_init (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_init2 (prec)
	SV *	prec
CODE:
  RETVAL = Rmpfr_init2 (aTHX_ prec);
OUTPUT:  RETVAL

SV *
Rmpfr_init_nobless ()
CODE:
  RETVAL = Rmpfr_init_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_init2_nobless (prec)
	SV *	prec
CODE:
  RETVAL = Rmpfr_init2_nobless (aTHX_ prec);
OUTPUT:  RETVAL

void
Rmpfr_init_set (q, round)
	mpfr_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_ui (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_ui(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_si (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_si(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_d (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_d(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_ld (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_ld(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_f (q, round)
	mpf_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_f(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_z (q, round)
	mpz_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_z(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_q (q, round)
	mpq_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_q(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_str (q, base, round)
	SV *	q
	SV *	base
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_str(aTHX_ q, base, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_nobless (q, round)
	mpfr_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_ui_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_ui_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_si_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_si_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_d_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_d_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_ld_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_ld_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_f_nobless (q, round)
	mpf_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_f_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_z_nobless (q, round)
	mpz_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_z_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_q_nobless (q, round)
	mpq_t *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_q_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_str_nobless (q, base, round)
	SV *	q
	SV *	base
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_str_nobless(aTHX_ q, base, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_deref2 (p, base, n_digits, round)
	mpfr_t *	p
	SV *	base
	SV *	n_digits
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_deref2(aTHX_ p, base, n_digits, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_default_prec (prec)
	SV *	prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_default_prec(aTHX_ prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_get_default_prec ()
CODE:
  RETVAL = Rmpfr_get_default_prec (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_min_prec (x)
	mpfr_t *	x
CODE:
  RETVAL = Rmpfr_min_prec (aTHX_ x);
OUTPUT:  RETVAL

void
Rmpfr_set_prec (p, prec)
	mpfr_t *	p
	SV *	prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_prec(aTHX_ p, prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_prec_raw (p, prec)
	mpfr_t *	p
	SV *	prec
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_prec_raw(aTHX_ p, prec);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_get_prec (p)
	mpfr_t *	p
CODE:
  RETVAL = Rmpfr_get_prec (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpfr_set (p, q, round)
	mpfr_t *	p
	mpfr_t *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_ui (p, q, round)
	mpfr_t *	p
	SV *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_ui (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_si (p, q, round)
	mpfr_t *	p
	SV *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_si (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_uj (p, q, round)
	mpfr_t *	p
	SV *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_uj (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_sj (p, q, round)
	mpfr_t *	p
	SV *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_sj (aTHX_ p, q, round);
OUTPUT:  RETVAL

int
Rmpfr_set_NV (p, q, round)
	mpfr_t *	p
	SV *	q
	unsigned int	round
CODE:
  RETVAL = Rmpfr_set_NV (aTHX_ p, q, round);
OUTPUT:  RETVAL

void
Rmpfr_init_set_NV (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_NV(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_NV_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_NV_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_cmp_float128 (a, b)
	mpfr_t *	a
	SV *	b
CODE:
  RETVAL = Rmpfr_cmp_float128 (aTHX_ a, b);
OUTPUT:  RETVAL

int
Rmpfr_cmp_NV (a, b)
	mpfr_t *	a
	SV *	b
CODE:
  RETVAL = Rmpfr_cmp_NV (aTHX_ a, b);
OUTPUT:  RETVAL

SV *
Rmpfr_set_ld (p, q, round)
	mpfr_t *	p
	SV *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_ld (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_d (p, q, round)
	mpfr_t *	p
	SV *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_d (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_z (p, q, round)
	mpfr_t *	p
	mpz_t *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_z (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_q (p, q, round)
	mpfr_t *	p
	mpq_t *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_q (aTHX_ p, q, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_f (p, q, round)
	mpfr_t *	p
	mpf_t *	q
	SV *	round
CODE:
  RETVAL = Rmpfr_set_f (aTHX_ p, q, round);
OUTPUT:  RETVAL

int
Rmpfr_set_str (p, num, base, round)
	mpfr_t *	p
	SV *	num
	SV *	base
	SV *	round
CODE:
  RETVAL = Rmpfr_set_str (aTHX_ p, num, base, round);
OUTPUT:  RETVAL

void
Rmpfr_set_inf (p, sign)
	mpfr_t *	p
	int	sign
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_inf(p, sign);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_nan (p)
	mpfr_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_nan(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_swap (p, q)
	mpfr_t *	p
	mpfr_t *	q
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_swap(p, q);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_get_d (p, round)
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_get_d (aTHX_ p, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_d_2exp (exp, p, round)
	SV *	exp
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_get_d_2exp (aTHX_ exp, p, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_ld_2exp (exp, p, round)
	SV *	exp
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_get_ld_2exp (aTHX_ exp, p, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_ld (p, round)
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_get_ld (aTHX_ p, round);
OUTPUT:  RETVAL

double
Rmpfr_get_d1 (p)
	mpfr_t *	p

SV *
Rmpfr_get_z_2exp (z, p)
	mpz_t *	z
	mpfr_t *	p
CODE:
  RETVAL = Rmpfr_get_z_2exp (aTHX_ z, p);
OUTPUT:  RETVAL

SV *
Rmpfr_add (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_add (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_add_ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_add_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_add_d (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_add_d (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_add_si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_add_si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_add_z (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpz_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_add_z (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

void
Rmpfr_get_q (a, b)
	mpq_t *	a
	mpfr_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_get_q(a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_add_q (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpq_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_add_q (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

void
q_add_fr (a, b, c)
	mpq_t *	a
	mpq_t *	b
	mpfr_t *	c
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        q_add_fr(a, b, c);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_sub (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sub (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sub_ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sub_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sub_d (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sub_d (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sub_z (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpz_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sub_z (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sub_q (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpq_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sub_q (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

void
q_sub_fr (a, b, c)
	mpq_t *	a
	mpq_t *	b
	mpfr_t *	c
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        q_sub_fr(a, b, c);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_ui_sub (a, b, c, round)
	mpfr_t *	a
	SV *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_ui_sub (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_d_sub (a, b, c, round)
	mpfr_t *	a
	SV *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_d_sub (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_d (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_d (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_z (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpz_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_z (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_q (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpq_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_q (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

void
q_mul_fr (a, b, c)
	mpq_t *	a
	mpq_t *	b
	mpfr_t *	c
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        q_mul_fr(a, b, c);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_dim (rop, op1, op2, round)
	mpfr_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2
	SV *	round
CODE:
  RETVAL = Rmpfr_dim (aTHX_ rop, op1, op2, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_d (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_d (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_z (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpz_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_z (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_q (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpq_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_q (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

void
q_div_fr (a, b, c)
	mpq_t *	a
	mpq_t *	b
	mpfr_t *	c
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        q_div_fr(a, b, c);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_ui_div (a, b, c, round)
	mpfr_t *	a
	SV *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_ui_div (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_d_div (a, b, c, round)
	mpfr_t *	a
	SV *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_d_div (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sqrt (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sqrt (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_rec_sqrt (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_rec_sqrt (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_cbrt (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_cbrt (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sqrt_ui (a, b, round)
	mpfr_t *	a
	SV *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sqrt_ui (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow_ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow_uj (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow_uj (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow_IV (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow_IV (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_ui_pow_ui (a, b, c, round)
	mpfr_t *	a
	SV *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_ui_pow_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_ui_pow (a, b, c, round)
	mpfr_t *	a
	SV *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_ui_pow (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow_si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow_si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow_sj (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow_sj (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_powr (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_powr (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pown (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pown (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_compound_si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_compound_si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_neg (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_neg (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_abs (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_abs (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_2exp (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_2exp (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_2ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_2ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_2si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_2si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_2exp (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_2exp (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_2ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_2ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_2si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_2si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

int
Rmpfr_total_order_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_cmp (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_cmpabs (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_cmpabs_ui (a, b)
	mpfr_t *	a
	unsigned long	b

int
Rmpfr_cmp_ui (a, b)
	mpfr_t *	a
	unsigned long	b

int
Rmpfr_cmp_si (a, b)
	mpfr_t *	a
	long	b

int
Rmpfr_cmp_uj (a, b)
	mpfr_t *	a
	UV	b
CODE:
  RETVAL = Rmpfr_cmp_uj (aTHX_ a, b);
OUTPUT:  RETVAL

int
Rmpfr_cmp_sj (a, b)
	mpfr_t *	a
	IV	b
CODE:
  RETVAL = Rmpfr_cmp_sj (aTHX_ a, b);
OUTPUT:  RETVAL

int
Rmpfr_cmp_IV (a, b)
	mpfr_t *	a
	SV *	b
CODE:
  RETVAL = Rmpfr_cmp_IV (aTHX_ a, b);
OUTPUT:  RETVAL

int
Rmpfr_cmp_d (a, b)
	mpfr_t *	a
	double	b

int
Rmpfr_cmp_ld (a, b)
	mpfr_t *	a
	SV *	b
CODE:
  RETVAL = Rmpfr_cmp_ld (aTHX_ a, b);
OUTPUT:  RETVAL

int
Rmpfr_cmp_ui_2exp (a, b, c)
	mpfr_t *	a
	SV *	b
	SV *	c
CODE:
  RETVAL = Rmpfr_cmp_ui_2exp (aTHX_ a, b, c);
OUTPUT:  RETVAL

int
Rmpfr_cmp_si_2exp (a, b, c)
	mpfr_t *	a
	SV *	b
	SV *	c
CODE:
  RETVAL = Rmpfr_cmp_si_2exp (aTHX_ a, b, c);
OUTPUT:  RETVAL

int
Rmpfr_eq (a, b, c)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c

int
Rmpfr_nan_p (p)
	mpfr_t *	p

int
Rmpfr_inf_p (p)
	mpfr_t *	p

int
Rmpfr_number_p (p)
	mpfr_t *	p

void
Rmpfr_reldiff (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_reldiff(aTHX_ a, b, c, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_sgn (p)
	mpfr_t *	p

int
Rmpfr_greater_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_greaterequal_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_less_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_lessequal_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_lessgreater_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_equal_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_unordered_p (a, b)
	mpfr_t *	a
	mpfr_t *	b

SV *
Rmpfr_sin_cos (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sin_cos (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sinh_cosh (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sinh_cosh (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sin (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sin (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sinu (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sinu (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sinpi (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sinpi (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_cos (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_cos (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_cosu (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_cosu (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_cospi (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_cospi (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_tan (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_tan (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_tanu (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_tanu (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_tanpi (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_tanpi (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_asin (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_asin (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_asinu (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_asinu (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_asinpi (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_asinpi (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_acos (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_acos (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_acosu (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_acosu (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_acospi (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_acospi (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atan (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_atan (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atanu (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_atanu (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atanpi (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_atanpi (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sinh (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sinh (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_cosh (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_cosh (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_tanh (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_tanh (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_asinh (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_asinh (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_acosh (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_acosh (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atanh (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_atanh (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fac_ui (a, b, round)
	mpfr_t *	a
	SV *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_fac_ui (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_log1p (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_log1p (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_expm1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_expm1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_exp2m1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_exp2m1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_exp10m1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_exp10m1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_log2 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_log2 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_log2p1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_log2p1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_log10 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_log10 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_log10p1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_log10p1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fma (a, b, c, d, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	mpfr_t *	d
	SV *	round
CODE:
  RETVAL = Rmpfr_fma (aTHX_ a, b, c, d, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fms (a, b, c, d, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	mpfr_t *	d
	SV *	round
CODE:
  RETVAL = Rmpfr_fms (aTHX_ a, b, c, d, round);
OUTPUT:  RETVAL

SV *
Rmpfr_agm (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_agm (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_hypot (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_hypot (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_const_log2 (p, round)
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_const_log2 (aTHX_ p, round);
OUTPUT:  RETVAL

SV *
Rmpfr_const_pi (p, round)
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_const_pi (aTHX_ p, round);
OUTPUT:  RETVAL

SV *
Rmpfr_const_euler (p, round)
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = Rmpfr_const_euler (aTHX_ p, round);
OUTPUT:  RETVAL

SV *
Rmpfr_rint (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_rint (aTHX_ a, b, round);
OUTPUT:  RETVAL

int
Rmpfr_ceil (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_floor (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_round (a, b)
	mpfr_t *	a
	mpfr_t *	b

int
Rmpfr_trunc (a, b)
	mpfr_t *	a
	mpfr_t *	b

SV *
Rmpfr_can_round (p, err, round1, round2, prec)
	mpfr_t *	p
	SV *	err
	SV *	round1
	SV *	round2
	SV *	prec
CODE:
  RETVAL = Rmpfr_can_round (aTHX_ p, err, round1, round2, prec);
OUTPUT:  RETVAL

SV *
Rmpfr_print_rnd_mode (rnd)
	SV *	rnd
CODE:
  RETVAL = Rmpfr_print_rnd_mode (aTHX_ rnd);
OUTPUT:  RETVAL

SV *
Rmpfr_get_emin ()
CODE:
  RETVAL = Rmpfr_get_emin (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_emax ()
CODE:
  RETVAL = Rmpfr_get_emax (aTHX);
OUTPUT:  RETVAL


int
Rmpfr_set_emin (e)
	SV *	e
CODE:
  RETVAL = Rmpfr_set_emin (aTHX_ e);
OUTPUT:  RETVAL

int
Rmpfr_set_emax (e)
	SV *	e
CODE:
  RETVAL = Rmpfr_set_emax (aTHX_ e);
OUTPUT:  RETVAL

SV *
Rmpfr_check_range (p, t, round)
	mpfr_t *	p
	SV *	t
	SV *	round
CODE:
  RETVAL = Rmpfr_check_range (aTHX_ p, t, round);
OUTPUT:  RETVAL

void
Rmpfr_clear_underflow ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_underflow();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clear_overflow ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_overflow();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clear_nanflag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_nanflag();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clear_inexflag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_inexflag();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_clear_flags ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_flags();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_underflow_p ()


int
Rmpfr_overflow_p ()


int
Rmpfr_nanflag_p ()


int
Rmpfr_inexflag_p ()


SV *
Rmpfr_log (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_log (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_exp (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_exp (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_exp2 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_exp2 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_exp10 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_exp10 (aTHX_ a, b, round);
OUTPUT:  RETVAL

void
Rmpfr_urandomb (x, ...)
	SV *	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_urandomb(aTHX_ x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_random2 (p, s, exp)
	mpfr_t *	p
	SV *	s
	SV *	exp
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_random2(aTHX_ p, s, exp);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_TRmpfr_out_str (stream, base, dig, p, round)
	FILE *	stream
	SV *	base
	SV *	dig
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = _TRmpfr_out_str (aTHX_ stream, base, dig, p, round);
OUTPUT:  RETVAL

SV *
_Rmpfr_out_str (p, base, dig, round)
	mpfr_t *	p
	SV *	base
	SV *	dig
	SV *	round
CODE:
  RETVAL = _Rmpfr_out_str (aTHX_ p, base, dig, round);
OUTPUT:  RETVAL

SV *
_TRmpfr_out_strS (stream, base, dig, p, round, suff)
	FILE *	stream
	SV *	base
	SV *	dig
	mpfr_t *	p
	SV *	round
	SV *	suff
CODE:
  RETVAL = _TRmpfr_out_strS (aTHX_ stream, base, dig, p, round, suff);
OUTPUT:  RETVAL

SV *
_TRmpfr_out_strP (pre, stream, base, dig, p, round)
	SV *	pre
	FILE *	stream
	SV *	base
	SV *	dig
	mpfr_t *	p
	SV *	round
CODE:
  RETVAL = _TRmpfr_out_strP (aTHX_ pre, stream, base, dig, p, round);
OUTPUT:  RETVAL

SV *
_TRmpfr_out_strPS (pre, stream, base, dig, p, round, suff)
	SV *	pre
	FILE *	stream
	SV *	base
	SV *	dig
	mpfr_t *	p
	SV *	round
	SV *	suff
CODE:
  RETVAL = _TRmpfr_out_strPS (aTHX_ pre, stream, base, dig, p, round, suff);
OUTPUT:  RETVAL

SV *
_Rmpfr_out_strS (p, base, dig, round, suff)
	mpfr_t *	p
	SV *	base
	SV *	dig
	SV *	round
	SV *	suff
CODE:
  RETVAL = _Rmpfr_out_strS (aTHX_ p, base, dig, round, suff);
OUTPUT:  RETVAL

SV *
_Rmpfr_out_strP (pre, p, base, dig, round)
	SV *	pre
	mpfr_t *	p
	SV *	base
	SV *	dig
	SV *	round
CODE:
  RETVAL = _Rmpfr_out_strP (aTHX_ pre, p, base, dig, round);
OUTPUT:  RETVAL

SV *
_Rmpfr_out_strPS (pre, p, base, dig, round, suff)
	SV *	pre
	mpfr_t *	p
	SV *	base
	SV *	dig
	SV *	round
	SV *	suff
CODE:
  RETVAL = _Rmpfr_out_strPS (aTHX_ pre, p, base, dig, round, suff);
OUTPUT:  RETVAL

SV *
TRmpfr_inp_str (p, stream, base, round)
	mpfr_t *	p
	FILE *	stream
	SV *	base
	SV *	round
CODE:
  RETVAL = TRmpfr_inp_str (aTHX_ p, stream, base, round);
OUTPUT:  RETVAL

SV *
Rmpfr_inp_str (p, base, round)
	mpfr_t *	p
	SV *	base
	SV *	round
CODE:
  RETVAL = Rmpfr_inp_str (aTHX_ p, base, round);
OUTPUT:  RETVAL

SV *
Rmpfr_gamma (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_gamma (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_zeta (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_zeta (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_zeta_ui (a, b, round)
	mpfr_t *	a
	SV *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_zeta_ui (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_erf (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_erf (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_frac (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_frac (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_remainder (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_remainder (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_modf (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_modf (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fmod (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_fmod (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fmod_ui (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	unsigned long	c
	SV *	round
CODE:
  RETVAL = Rmpfr_fmod_ui (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

void
Rmpfr_remquo (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_remquo(aTHX_ a, b, c, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_integer_p (p)
	mpfr_t *	p

void
Rmpfr_nexttoward (a, b)
	mpfr_t *	a
	mpfr_t *	b
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_nexttoward(a, b);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_nextabove (p)
	mpfr_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_nextabove(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_nextbelow (p)
	mpfr_t *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_nextbelow(p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_min (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_min (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_max (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_max (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_exp (p)
	mpfr_t *	p
CODE:
  RETVAL = Rmpfr_get_exp (aTHX_ p);
OUTPUT:  RETVAL

SV *
Rmpfr_set_exp (p, exp)
	mpfr_t *	p
	SV *	exp
CODE:
  RETVAL = Rmpfr_set_exp (aTHX_ p, exp);
OUTPUT:  RETVAL

int
Rmpfr_signbit (op)
	mpfr_t *	op

SV *
Rmpfr_setsign (rop, op, sign, round)
	mpfr_t *	rop
	mpfr_t *	op
	SV *	sign
	SV *	round
CODE:
  RETVAL = Rmpfr_setsign (aTHX_ rop, op, sign, round);
OUTPUT:  RETVAL

SV *
Rmpfr_copysign (rop, op1, op2, round)
	mpfr_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2
	SV *	round
CODE:
  RETVAL = Rmpfr_copysign (aTHX_ rop, op1, op2, round);
OUTPUT:  RETVAL

SV *
get_refcnt (s)
	SV *	s
CODE:
  RETVAL = get_refcnt (aTHX_ s);
OUTPUT:  RETVAL

SV *
get_package_name (x)
	SV *	x
CODE:
  RETVAL = get_package_name (aTHX_ x);
OUTPUT:  RETVAL

void
Rmpfr_dump (a)
	mpfr_t *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_dump(a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
gmp_v ()
CODE:
  RETVAL = gmp_v (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_set_ui_2exp (a, b, c, round)
	mpfr_t *	a
	SV *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_set_ui_2exp (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_si_2exp (a, b, c, round)
	mpfr_t *	a
	SV *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_set_si_2exp (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_uj_2exp (a, b, c, round)
	mpfr_t *	a
	SV *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_set_uj_2exp (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_sj_2exp (a, b, c, round)
	mpfr_t *	a
	SV *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_set_sj_2exp (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_z (a, b, round)
	mpz_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_get_z (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_si_sub (a, c, b, round)
	mpfr_t *	a
	SV *	c
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_si_sub (aTHX_ a, c, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sub_si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_sub_si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_mul_si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_mul_si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_si_div (a, b, c, round)
	mpfr_t *	a
	SV *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_si_div (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_div_si (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_div_si (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sqr (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sqr (aTHX_ a, b, round);
OUTPUT:  RETVAL

int
Rmpfr_cmp_z (a, b)
	mpfr_t *	a
	mpz_t *	b

int
Rmpfr_cmp_q (a, b)
	mpfr_t *	a
	mpq_t *	b

int
fr_cmp_q_rounded (a, b, round)
	mpfr_t *	a
	mpq_t *	b
	SV *	round
CODE:
  RETVAL = fr_cmp_q_rounded (aTHX_ a, b, round);
OUTPUT:  RETVAL

int
Rmpfr_cmp_f (a, b)
	mpfr_t *	a
	mpf_t *	b

int
Rmpfr_zero_p (a)
	mpfr_t *	a

void
Rmpfr_free_cache ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_free_cache();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_free_cache2 (way)
	unsigned int	way
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_free_cache2(way);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_free_pool ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_free_pool();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_get_version ()
CODE:
  RETVAL = Rmpfr_get_version (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_patches ()
CODE:
  RETVAL = Rmpfr_get_patches (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_emin_min ()
CODE:
  RETVAL = Rmpfr_get_emin_min (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_emin_max ()
CODE:
  RETVAL = Rmpfr_get_emin_max (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_emax_min ()
CODE:
  RETVAL = Rmpfr_get_emax_min (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_emax_max ()
CODE:
  RETVAL = Rmpfr_get_emax_max (aTHX);
OUTPUT:  RETVAL


void
Rmpfr_clear_erangeflag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_erangeflag();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_erangeflag_p ()


SV *
Rmpfr_rint_round (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_rint_round (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_rint_trunc (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_rint_trunc (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_rint_ceil (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_rint_ceil (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_rint_floor (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_rint_floor (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_ui (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_get_ui (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_si (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_get_si (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_uj (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_get_uj (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_sj (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_get_sj (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_IV (x, round)
	mpfr_t *	x
	SV *	round
CODE:
  RETVAL = Rmpfr_get_IV (aTHX_ x, round);
OUTPUT:  RETVAL

int
Rmpfr_set_IV (x, sv, round)
	mpfr_t *	x
	SV *	sv
	SV *	round
CODE:
  RETVAL = Rmpfr_set_IV (aTHX_ x, sv, round);
OUTPUT:  RETVAL

void
Rmpfr_init_set_IV (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_IV(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_IV_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_IV_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_get_NV (x, round)
	mpfr_t *	x
	SV *	round
CODE:
  RETVAL = Rmpfr_get_NV (aTHX_ x, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_ulong_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_ulong_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_slong_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_slong_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_ushort_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_ushort_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_sshort_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_sshort_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_uint_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_uint_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_sint_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_sint_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_uintmax_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_uintmax_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_intmax_p (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_intmax_p (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_fits_IV_p (x, round)
	mpfr_t *	x
	SV *	round
CODE:
  RETVAL = Rmpfr_fits_IV_p (aTHX_ x, round);
OUTPUT:  RETVAL

SV *
Rmpfr_strtofr (a, str, base, round)
	mpfr_t *	a
	SV *	str
	SV *	base
	SV *	round
CODE:
  RETVAL = Rmpfr_strtofr (aTHX_ a, str, base, round);
OUTPUT:  RETVAL

void
Rmpfr_set_erangeflag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_erangeflag();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_underflow ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_underflow();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_overflow ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_overflow();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_nanflag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_nanflag();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_inexflag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_inexflag();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_erfc (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_erfc (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_j0 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_j0 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_j1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_j1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_jn (a, n, b, round)
	mpfr_t *	a
	SV *	n
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_jn (aTHX_ a, n, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_y0 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_y0 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_y1 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_y1 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_yn (a, n, b, round)
	mpfr_t *	a
	SV *	n
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_yn (aTHX_ a, n, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atan2 (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_atan2 (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atan2u (a, b, c, d, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	unsigned long	d
	SV *	round
CODE:
  RETVAL = Rmpfr_atan2u (aTHX_ a, b, c, d, round);
OUTPUT:  RETVAL

SV *
Rmpfr_atan2pi (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_atan2pi (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_pow_z (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpz_t *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_pow_z (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_subnormalize (a, b, round)
	mpfr_t *	a
	SV *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_subnormalize (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_const_catalan (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_const_catalan (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sec (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sec (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_csc (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_csc (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_cot (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_cot (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_root (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	c
	SV *	round
CODE:
  RETVAL = Rmpfr_root (aTHX_ a, b, c, round);
OUTPUT:  RETVAL

SV *
Rmpfr_eint (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_eint (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_li2 (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_li2 (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_f (a, b, round)
	mpf_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_get_f (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_sech (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_sech (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_csch (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_csch (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_coth (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_coth (aTHX_ a, b, round);
OUTPUT:  RETVAL

SV *
Rmpfr_lngamma (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
CODE:
  RETVAL = Rmpfr_lngamma (aTHX_ a, b, round);
OUTPUT:  RETVAL

void
Rmpfr_lgamma (a, b, round)
	mpfr_t *	a
	mpfr_t *	b
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_lgamma(aTHX_ a, b, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_MPFR_VERSION ()
CODE:
  RETVAL = _MPFR_VERSION (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_MAJOR ()
CODE:
  RETVAL = _MPFR_VERSION_MAJOR (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_MINOR ()
CODE:
  RETVAL = _MPFR_VERSION_MINOR (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_PATCHLEVEL ()
CODE:
  RETVAL = _MPFR_VERSION_PATCHLEVEL (aTHX);
OUTPUT:  RETVAL


SV *
_MPFR_VERSION_STRING ()
CODE:
  RETVAL = _MPFR_VERSION_STRING (aTHX);
OUTPUT:  RETVAL


SV *
RMPFR_VERSION_NUM (a, b, c)
	SV *	a
	SV *	b
	SV *	c
CODE:
  RETVAL = RMPFR_VERSION_NUM (aTHX_ a, b, c);
OUTPUT:  RETVAL

SV *
Rmpfr_sum (rop, avref, len, round)
	mpfr_t *	rop
	SV *	avref
	SV *	len
	SV *	round
CODE:
  RETVAL = Rmpfr_sum (aTHX_ rop, avref, len, round);
OUTPUT:  RETVAL

void
_fr_to_q (q, fr)
	mpq_t *	q
	mpfr_t *	fr
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _fr_to_q(q, fr);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_q_div (rop, q, fr, round)
	mpfr_t *	rop
	mpq_t *	q
	mpfr_t *	fr
	int	round

int
Rmpfr_z_div (rop, z, fr, round)
	mpfr_t *	rop
	mpz_t *	z
	mpfr_t *	fr
	int	round

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
overload_copy (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_copy (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_abs (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_abs (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_gt (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_gt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_gte (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_gte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lt (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lt (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_lte (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_lte (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_spaceship (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_spaceship (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_equiv (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_not_equiv (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_not_equiv (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_true (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_true (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_not (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_not (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_sqrt (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_sqrt (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_pow (p, b, third)
	SV *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_pow (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_log (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_log (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_exp (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_exp (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_sin (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_sin (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_cos (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_cos (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_int (p, b, third)
	mpfr_t *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_int (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
overload_atan2 (a, b, third)
	mpfr_t *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_atan2 (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
Rmpfr_randinit_default_nobless ()
CODE:
  RETVAL = Rmpfr_randinit_default_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_randinit_mt_nobless ()
CODE:
  RETVAL = Rmpfr_randinit_mt_nobless (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_randinit_lc_2exp_nobless (a, c, m2exp)
	SV *	a
	SV *	c
	SV *	m2exp
CODE:
  RETVAL = Rmpfr_randinit_lc_2exp_nobless (aTHX_ a, c, m2exp);
OUTPUT:  RETVAL

SV *
Rmpfr_randinit_lc_2exp_size_nobless (size)
	SV *	size
CODE:
  RETVAL = Rmpfr_randinit_lc_2exp_size_nobless (aTHX_ size);
OUTPUT:  RETVAL

void
Rmpfr_randclear (p)
	SV *	p
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_randclear(aTHX_ p);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_randseed (state, seed)
	SV *	state
	SV *	seed
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_randseed(aTHX_ state, seed);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_randseed_ui (state, seed)
	SV *	state
	SV *	seed
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_randseed_ui(aTHX_ state, seed);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
overload_pow_eq (p, b, third)
	SV *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_pow_eq (aTHX_ p, b, third);
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
_ivsize_bits ()


PROTOTYPES: ENABLE


SV *
RMPFR_PREC_MAX ()
CODE:
  RETVAL = RMPFR_PREC_MAX (aTHX);
OUTPUT:  RETVAL


SV *
RMPFR_PREC_MIN ()
CODE:
  RETVAL = RMPFR_PREC_MIN (aTHX);
OUTPUT:  RETVAL


PROTOTYPES: DISABLE


SV *
wrap_mpfr_printf (a, b)
	SV *	a
	SV *	b
CODE:
  RETVAL = wrap_mpfr_printf (aTHX_ a, b);
OUTPUT:  RETVAL

SV *
wrap_mpfr_fprintf (stream, a, b)
	FILE *	stream
	SV *	a
	SV *	b
CODE:
  RETVAL = wrap_mpfr_fprintf (aTHX_ stream, a, b);
OUTPUT:  RETVAL

SV *
wrap_mpfr_sprintf (s, a, b, buflen)
	SV *	s
	SV *	a
	SV *	b
	int	buflen
CODE:
  RETVAL = wrap_mpfr_sprintf (aTHX_ s, a, b, buflen);
OUTPUT:  RETVAL

SV *
wrap_mpfr_snprintf (s, bytes, a, b, buflen)
	SV *	s
	SV *	bytes
	SV *	a
	SV *	b
	int	buflen
CODE:
  RETVAL = wrap_mpfr_snprintf (aTHX_ s, bytes, a, b, buflen);
OUTPUT:  RETVAL

SV *
wrap_mpfr_printf_rnd (a, round, b)
	SV *	a
	SV *	round
	SV *	b
CODE:
  RETVAL = wrap_mpfr_printf_rnd (aTHX_ a, round, b);
OUTPUT:  RETVAL

SV *
wrap_mpfr_fprintf_rnd (stream, a, round, b)
	FILE *	stream
	SV *	a
	SV *	round
	SV *	b
CODE:
  RETVAL = wrap_mpfr_fprintf_rnd (aTHX_ stream, a, round, b);
OUTPUT:  RETVAL

SV *
wrap_mpfr_sprintf_rnd (s, a, round, b, buflen)
	SV *	s
	SV *	a
	SV *	round
	SV *	b
	int	buflen
CODE:
  RETVAL = wrap_mpfr_sprintf_rnd (aTHX_ s, a, round, b, buflen);
OUTPUT:  RETVAL

SV *
wrap_mpfr_snprintf_rnd (s, bytes, a, round, b, buflen)
	SV *	s
	SV *	bytes
	SV *	a
	SV *	round
	SV *	b
	int	buflen
CODE:
  RETVAL = wrap_mpfr_snprintf_rnd (aTHX_ s, bytes, a, round, b, buflen);
OUTPUT:  RETVAL

SV *
Rmpfr_buildopt_tls_p ()
CODE:
  RETVAL = Rmpfr_buildopt_tls_p (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_buildopt_decimal_p ()
CODE:
  RETVAL = Rmpfr_buildopt_decimal_p (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_regular_p (a)
	mpfr_t *	a
CODE:
  RETVAL = Rmpfr_regular_p (aTHX_ a);
OUTPUT:  RETVAL

void
Rmpfr_set_zero (a, sign)
	mpfr_t *	a
	SV *	sign
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_zero(aTHX_ a, sign);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_digamma (rop, op, round)
	mpfr_t *	rop
	mpfr_t *	op
	SV *	round
CODE:
  RETVAL = Rmpfr_digamma (aTHX_ rop, op, round);
OUTPUT:  RETVAL

SV *
Rmpfr_ai (rop, op, round)
	mpfr_t *	rop
	mpfr_t *	op
	SV *	round
CODE:
  RETVAL = Rmpfr_ai (aTHX_ rop, op, round);
OUTPUT:  RETVAL

SV *
Rmpfr_get_flt (a, round)
	mpfr_t *	a
	SV *	round
CODE:
  RETVAL = Rmpfr_get_flt (aTHX_ a, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_flt (rop, f, round)
	mpfr_t *	rop
	SV *	f
	SV *	round
CODE:
  RETVAL = Rmpfr_set_flt (aTHX_ rop, f, round);
OUTPUT:  RETVAL

SV *
Rmpfr_urandom (rop, state, round)
	mpfr_t *	rop
	gmp_randstate_t *	state
	SV *	round
CODE:
  RETVAL = Rmpfr_urandom (aTHX_ rop, state, round);
OUTPUT:  RETVAL

SV *
Rmpfr_set_z_2exp (rop, op, exp, round)
	mpfr_t *	rop
	mpz_t *	op
	SV *	exp
	SV *	round
CODE:
  RETVAL = Rmpfr_set_z_2exp (aTHX_ rop, op, exp, round);
OUTPUT:  RETVAL

SV *
Rmpfr_buildopt_tune_case ()
CODE:
  RETVAL = Rmpfr_buildopt_tune_case (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_frexp (exp, rop, op, round)
	SV *	exp
	mpfr_t *	rop
	mpfr_t *	op
	SV *	round
CODE:
  RETVAL = Rmpfr_frexp (aTHX_ exp, rop, op, round);
OUTPUT:  RETVAL

SV *
Rmpfr_z_sub (rop, op1, op2, round)
	mpfr_t *	rop
	mpz_t *	op1
	mpfr_t *	op2
	SV *	round
CODE:
  RETVAL = Rmpfr_z_sub (aTHX_ rop, op1, op2, round);
OUTPUT:  RETVAL

SV *
Rmpfr_grandom (rop1, rop2, state, round)
	mpfr_t *	rop1
	mpfr_t *	rop2
	gmp_randstate_t *	state
	SV *	round
CODE:
  RETVAL = Rmpfr_grandom (aTHX_ rop1, rop2, state, round);
OUTPUT:  RETVAL

void
Rmpfr_clear_divby0 ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_clear_divby0(aTHX);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_set_divby0 ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_set_divby0(aTHX);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_divby0_p ()
CODE:
  RETVAL = Rmpfr_divby0_p (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_buildopt_gmpinternals_p ()
CODE:
  RETVAL = Rmpfr_buildopt_gmpinternals_p (aTHX);
OUTPUT:  RETVAL


SV *
_get_xs_version ()
CODE:
  RETVAL = _get_xs_version (aTHX);
OUTPUT:  RETVAL


SV *
overload_inc (a, b, third)
	SV *	a
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_inc (aTHX_ a, b, third);
OUTPUT:  RETVAL

SV *
overload_dec (p, b, third)
	SV *	p
	SV *	b
	SV *	third
CODE:
  RETVAL = overload_dec (aTHX_ p, b, third);
OUTPUT:  RETVAL

SV *
_wrap_count ()
CODE:
  RETVAL = _wrap_count (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_set_LD (rop, op, rnd)
	mpfr_t *	rop
	SV *	op
	SV *	rnd
CODE:
  RETVAL = Rmpfr_set_LD (aTHX_ rop, op, rnd);
OUTPUT:  RETVAL

SV *
Rmpfr_set_DECIMAL64 (rop, op, rnd)
	mpfr_t *	rop
	SV *	op
	SV *	rnd
CODE:
  RETVAL = Rmpfr_set_DECIMAL64 (aTHX_ rop, op, rnd);
OUTPUT:  RETVAL

SV *
Rmpfr_set_DECIMAL128 (rop, op, rnd)
	mpfr_t *	rop
	SV *	op
	SV *	rnd
CODE:
  RETVAL = Rmpfr_set_DECIMAL128 (aTHX_ rop, op, rnd);
OUTPUT:  RETVAL

void
Rmpfr_get_LD (rop, op, rnd)
	SV *	rop
	mpfr_t *	op
	SV *	rnd
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_get_LD(aTHX_ rop, op, rnd);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_get_DECIMAL64 (rop, op, rnd)
	SV *	rop
	mpfr_t *	op
	SV *	rnd
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_get_DECIMAL64(aTHX_ rop, op, rnd);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_get_DECIMAL128 (rop, op, rnd)
	SV *	rop
	mpfr_t *	op
	SV *	rnd
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_get_DECIMAL128(aTHX_ rop, op, rnd);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_MPFR_WANT_DECIMAL_FLOATS ()


int
_MPFR_WANT_DECIMAL64 ()


int
_MPFR_WANT_DECIMAL128 ()


int
_MPFR_WANT_FLOAT128 ()


SV *
_max_base ()
CODE:
  RETVAL = _max_base (aTHX);
OUTPUT:  RETVAL


SV *
_isobject (x)
	SV *	x
CODE:
  RETVAL = _isobject (aTHX_ x);
OUTPUT:  RETVAL

void
_mp_sizes ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _mp_sizes();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_ivsize ()
CODE:
  RETVAL = _ivsize (aTHX);
OUTPUT:  RETVAL


SV *
_nvsize ()
CODE:
  RETVAL = _nvsize (aTHX);
OUTPUT:  RETVAL


SV *
_FLT128_DIG ()
CODE:
  RETVAL = _FLT128_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_DIG ()
CODE:
  RETVAL = _LDBL_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_DIG ()
CODE:
  RETVAL = _DBL_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_FLT128_MANT_DIG ()
CODE:
  RETVAL = _FLT128_MANT_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_LDBL_MANT_DIG ()
CODE:
  RETVAL = _LDBL_MANT_DIG (aTHX);
OUTPUT:  RETVAL


SV *
_DBL_MANT_DIG ()
CODE:
  RETVAL = _DBL_MANT_DIG (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_get_float128 (op, rnd)
	mpfr_t *	op
	SV *	rnd
CODE:
  RETVAL = Rmpfr_get_float128 (aTHX_ op, rnd);
OUTPUT:  RETVAL

void
Rmpfr_get_FLOAT128 (rop, op, rnd)
	SV *	rop
	mpfr_t *	op
	SV *	rnd
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_get_FLOAT128(aTHX_ rop, op, rnd);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
Rmpfr_set_FLOAT128 (rop, op, rnd)
	mpfr_t *	rop
	SV *	op
	SV *	rnd
CODE:
  RETVAL = Rmpfr_set_FLOAT128 (aTHX_ rop, op, rnd);
OUTPUT:  RETVAL

SV *
Rmpfr_set_float128 (rop, q, rnd)
	mpfr_t *	rop
	SV *	q
	SV *	rnd
CODE:
  RETVAL = Rmpfr_set_float128 (aTHX_ rop, q, rnd);
OUTPUT:  RETVAL

void
Rmpfr_init_set_float128 (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_float128(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_init_set_float128_nobless (q, round)
	SV *	q
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_init_set_float128_nobless(aTHX_ q, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_is_readonly (sv)
	SV *	sv
CODE:
  RETVAL = _is_readonly (aTHX_ sv);
OUTPUT:  RETVAL

void
_readonly_on (sv)
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _readonly_on(aTHX_ sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
_readonly_off (sv)
	SV *	sv
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _readonly_off(aTHX_ sv);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
_can_pass_float128 ()


int
_mpfr_want_float128 ()


int
nnumflag ()


int
nok_pokflag ()


void
clear_nnum ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        clear_nnum();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
clear_nok_pok ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        clear_nok_pok();
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_nnum (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_nnum(x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
set_nok_pok (x)
	int	x
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_nok_pok(x);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
_d_bytes (str)
	SV *	str
CODE:
  RETVAL = _d_bytes (aTHX_ str);
OUTPUT:  RETVAL

SV *
_bytes_fr (str, bits)
	mpfr_t *	str
	unsigned int	bits
CODE:
  RETVAL = _bytes_fr (aTHX_ str, bits);
OUTPUT:  RETVAL

SV *
_dd_bytes (str)
	SV *	str
CODE:
  RETVAL = _dd_bytes (aTHX_ str);
OUTPUT:  RETVAL

SV *
_ld_bytes (str)
	SV *	str
CODE:
  RETVAL = _ld_bytes (aTHX_ str);
OUTPUT:  RETVAL

SV *
_f128_bytes (str)
	SV *	str
CODE:
  RETVAL = _f128_bytes (aTHX_ str);
OUTPUT:  RETVAL

int
_required_ldbl_mant_dig ()


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


void
Rmpfr_fmodquo (a, b, c, round)
	mpfr_t *	a
	mpfr_t *	b
	mpfr_t *	c
	SV *	round
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_fmodquo(aTHX_ a, b, c, round);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_fpif_export (stream, op)
	FILE *	stream
	mpfr_t *	op
CODE:
  RETVAL = Rmpfr_fpif_export (aTHX_ stream, op);
OUTPUT:  RETVAL

int
Rmpfr_fpif_import (op, stream)
	mpfr_t *	op
	FILE *	stream
CODE:
  RETVAL = Rmpfr_fpif_import (aTHX_ op, stream);
OUTPUT:  RETVAL

void
Rmpfr_flags_clear (mask)
	unsigned int	mask
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_flags_clear(mask);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

void
Rmpfr_flags_set (mask)
	unsigned int	mask
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_flags_set(mask);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

unsigned int
Rmpfr_flags_test (mask)
	unsigned int	mask

unsigned int
Rmpfr_flags_save ()


void
Rmpfr_flags_restore (flags, mask)
	unsigned int	flags
	unsigned int	mask
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        Rmpfr_flags_restore(flags, mask);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

int
Rmpfr_rint_roundeven (rop, op, round)
	mpfr_t *	rop
	mpfr_t *	op
	int	round

int
Rmpfr_roundeven (rop, op)
	mpfr_t *	rop
	mpfr_t *	op

int
Rmpfr_nrandom (rop, state, round)
	mpfr_t *	rop
	gmp_randstate_t *	state
	int	round

int
Rmpfr_erandom (rop, state, round)
	mpfr_t *	rop
	gmp_randstate_t *	state
	int	round

int
Rmpfr_fmma (rop, op1, op2, op3, op4, round)
	mpfr_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2
	mpfr_t *	op3
	mpfr_t *	op4
	int	round

int
Rmpfr_fmms (rop, op1, op2, op3, op4, round)
	mpfr_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2
	mpfr_t *	op3
	mpfr_t *	op4
	int	round

int
Rmpfr_log_ui (rop, op, round)
	mpfr_t *	rop
	unsigned long	op
	int	round

int
Rmpfr_gamma_inc (rop, op1, op2, round)
	mpfr_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2
	int	round

int
_have_IEEE_754_long_double ()


int
_have_extended_precision_long_double ()


int
nanflag_bug ()


SV *
Rmpfr_buildopt_float128_p ()
CODE:
  RETVAL = Rmpfr_buildopt_float128_p (aTHX);
OUTPUT:  RETVAL


SV *
Rmpfr_buildopt_sharedcache_p ()
CODE:
  RETVAL = Rmpfr_buildopt_sharedcache_p (aTHX);
OUTPUT:  RETVAL


int
_nv_is_float128 ()


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

SV *
_lsb (a)
	mpfr_t *	a
CODE:
  RETVAL = _lsb (aTHX_ a);
OUTPUT:  RETVAL

int
Rmpfr_rec_root (rop, op, root, round)
	mpfr_t *	rop
	mpfr_t *	op
	unsigned long	root
	SV *	round
CODE:
  RETVAL = Rmpfr_rec_root (aTHX_ rop, op, root, round);
OUTPUT:  RETVAL

int
Rmpfr_beta (rop, op1, op2, round)
	mpfr_t *	rop
	mpfr_t *	op1
	mpfr_t *	op2
	int	round

int
Rmpfr_rootn_ui (rop, op, k, round)
	mpfr_t *	rop
	mpfr_t *	op
	unsigned long	k
	int	round

int
_ld_subnormal_bug ()


double
atodouble (str)
	char *	str

SV *
atonv (str)
	SV *	str
CODE:
  RETVAL = atonv (aTHX_ str);
OUTPUT:  RETVAL

SV *
Rmpfr_get_str_ndigits_alt (base, prec)
	int	base
	UV	prec
CODE:
  RETVAL = Rmpfr_get_str_ndigits_alt (aTHX_ base, prec);
OUTPUT:  RETVAL

SV *
Rmpfr_get_str_ndigits (base, prec)
	int	base
	SV *	prec
CODE:
  RETVAL = Rmpfr_get_str_ndigits (aTHX_ base, prec);
OUTPUT:  RETVAL

SV *
Rmpfr_dot (rop, avref_A, avref_B, len, round)
	mpfr_t *	rop
	SV *	avref_A
	SV *	avref_B
	SV *	len
	SV *	round
CODE:
  RETVAL = Rmpfr_dot (aTHX_ rop, avref_A, avref_B, len, round);
OUTPUT:  RETVAL

SV *
nvtoa (pnv)
	NV	pnv
CODE:
  RETVAL = nvtoa (aTHX_ pnv);
OUTPUT:  RETVAL

SV *
mpfrtoa (pnv)
	mpfr_t *	pnv
CODE:
  RETVAL = mpfrtoa (aTHX_ pnv);
OUTPUT:  RETVAL

void
set_fallback_flag ()

        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        set_fallback_flag(aTHX);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

SV *
doubletoa (sv, ...)
	SV *	sv
        PREINIT:
        I32* temp;
        CODE:
        temp = PL_markstack_ptr++;
        RETVAL = doubletoa(aTHX_ sv);
        PL_markstack_ptr = temp;
        OUTPUT:
        RETVAL

int
_fallback_notify ()


SV *
numtoa (in)
	SV *	in
CODE:
  RETVAL = numtoa (aTHX_ in);
OUTPUT:  RETVAL

void
decimalize (a, ...)
	SV *	a
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        decimalize(aTHX_ a);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

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
_sis_perl_version ()


