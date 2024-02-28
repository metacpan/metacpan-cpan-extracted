#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <ryu.h>
#include <ryu_parse.h>

#if defined(COMPILER_HAS_UINT128_T) && !defined(AVOID_GENERIC_128)
#  include <generic_128.h>    /* modified to include stdbool.h */
#  include <ryu_generic_128.h>
#  include <stdbool.h>
#  ifdef USE_QUADMATH
#    include <quadmath.h> /* do we actually need this ? */
#  endif
#endif

#define QUAD_MANTISSA_BITS 112
#define QUAD_EXPONENT_BITS 15

#include "math_ryu_include.h"

typedef struct floating_decimal_128 t_fd128;

#if defined(COMPILER_HAS_UINT128_T) && !defined(AVOID_GENERIC_128)
struct floating_decimal_128 quad_to_fd128(NV d) {
  uint128_t bits = 0;
  memcpy(&bits, &d, sizeof(NV));
  return generic_binary_to_decimal(bits, QUAD_MANTISSA_BITS, QUAD_EXPONENT_BITS, false);
}
#endif

double _s2d(char * buffer) {
#if NVSIZE == 8
  double nv;
  s2d(buffer, &nv);
  return nv;
#else
  PERL_UNUSED_ARG(buffer);
  croak("s2d() is available only to perls whose NV is of type 'double'");
#endif
}

SV * M_RYU_d2s(pTHX_ SV * nv) {
#if NVSIZE == 8
  return newSVpv(d2s(SvNV(nv)), 0);
#else
  PERL_UNUSED_ARG(nv);
  croak("d2s() is available only to perls whose NV is of type 'double'");
#endif
}

SV * ld2s(pTHX_ SV * nv) {
#if MAX_DEC_DIG == 21
  char * buff;
  SV * outsv;

  Newxz(buff, LD_BUF, char); /* LD_BUF defined in math_ryu_l)include.h, along with D_BUF and F128_BUF */

  if(buff == NULL) croak("Failed to allocate memory for string buffer in ld2s sub");
  generic_to_chars(long_double_to_fd128(SvNV(nv)), buff);
  outsv = newSVpv(buff, 0);
  Safefree(buff);
  return outsv;
#else
  PERL_UNUSED_ARG(nv);
  croak("ld2s() is available only to perls whose NV is of type 80-bit extended precision 'long double'");
#endif
}

SV * q2s(pTHX_ SV * nv) {
#if MAX_DEC_DIG == 36
  char * buff;
  SV * outsv;

   Newxz(buff, F128_BUF, char);

  if(buff == NULL) croak("Failed to allocate memory for string buffer in ld2s sub");
  generic_to_chars(quad_to_fd128(SvNV(nv)), buff);
  outsv = newSVpv(buff, 0);
  Safefree(buff);
  return outsv;
#else
  PERL_UNUSED_ARG(nv);
  croak("q2s() is available only to perls whose NV is either '__float128' or IEEE 754 'long double'");
#endif
}

int _SvIOK(SV * sv) {
    if(SvIOK(sv)) return 1;
    return 0;
}

int _SvNOK(SV * sv) {
    if(SvNOK(sv)) return 1;
    return 0;
}

int _SvPOK(SV * sv) {
    if(SvPOK(sv)) return 1;
    return 0;
}

int _SvIOKp(SV * sv) {
    if(SvIOKp(sv)) return 1;
    return 0;
}

int ryu_lln(pTHX_ SV * sv) {
  return looks_like_number(sv);
}

int _compiler_has_uint128(void) {
#ifdef COMPILER_HAS_UINT128_T
   return 1;
#else
   return 0;
#endif
}

int _get_max_dec_dig(void) {
#ifdef MAX_DEC_DIG
   return MAX_DEC_DIG;
#else
   return 0;
#endif
}

SV * fmtpy(pTHX_ SV * in) {
  int is_neg = 0, pointpos = 0, exponent, dec = 0, zero_pad = 0;
  char *man_str, *exp_str;
  size_t i, len, seen = 0;
  char *s = SvPV_nolen(in);
  SV * outsv;

  if(s[0] == '-') {
    is_neg = 1;
    s++;
  }

  /* If the given argument contains a decimal point, then that *
   * decimal point will immediately follow the first digit.    *
   * Otherwise, the argument does not contain a decimal point. */
  if(s[1] == '.') pointpos = 1;

  if(pointpos) {
    /*** STRING CONTAINS A DECIMAL POINT ***/
    Newxz(man_str, MAN_BUF, char);
    if(man_str == NULL) croak("Failed (in 'if' block) to allocate memory for man_str in fmtpy function");
    Newxz(exp_str, EXP_BUF, char);
    if(exp_str == NULL) croak("Failed (in 'if' block) to allocate memory for exp_str in fmtpy function");

    /* Split into mantissa and exponent around 'E'         *
     * The input string (s) has the 'E' replaced by a NULL *
     * and the exponent portion of s is copied to exp_str  */
    len = strlen(s);
    for(i = 0; i < len; i++) {
      if(seen) { /* will be set when 'E' is encountered' */
        exp_str[i - seen] = s[i];
      }
      else if(s[i] == 'E') {
        seen = i + 1;
        s[i] = '\0';
      }
    }
    exp_str[i - seen] = '\0';
    exponent = atoi(exp_str);

    if(exponent > 0 && exponent < MAX_DEC_DIG) {
      len = strlen(s);
      zero_pad = exponent - (len - 2);
      if(zero_pad >= 0 && (zero_pad + len < MAX_DEC_DIG + 1)) {
        /* Return, eg, '1.23E15' as '1230000000000000.0' */
        if(is_neg) man_str[0] = '-';
        man_str[0 + is_neg] = s[0];
        for(i = 2; i < len; i++) {
          man_str[i + is_neg - 1] = s[i];
        }
        for(dec = 0; dec < zero_pad; dec++) {
          man_str[i + is_neg - 1] = '0';
          i++;
        }
        man_str[i + is_neg - 1] = '.';
        man_str[i + is_neg] = '0';
        man_str[i + is_neg + 1] = '\0';

        outsv = newSVpv(man_str, 0);
        Safefree(man_str);
        Safefree(exp_str);
        if(is_neg) s--;
        return outsv;
      }
      else if(zero_pad < 0) {
        /* We want, eg,  1.23625E2 to be returned as "123.625". *
         * This involves relocation of the decimal point.       */
        len = strlen(s);
        zero_pad--;
        if(is_neg) man_str[0] = '-';
        man_str[0 + is_neg] = s[0];
        man_str[1 + is_neg] = s[2]; /* s[1] is the decimal point */
        dec = 1; /* set to 0 when the decimal point is encountered */
        for(i = 2; i < len; i++) {
           if(i == zero_pad + len) {
             man_str[i + is_neg] = '.';
             dec--;
           }
           else man_str[i + is_neg] = s[i + dec];
        }

        man_str[i + is_neg] = '\0';

        outsv = newSVpv(man_str, 0);
        Safefree(man_str);
        Safefree(exp_str);
        if(is_neg) s--;
        return outsv;
      }
    }

    len = strlen(s); /* now different to when initially set     *
                      * because 'E' has been replaced with '\0' */
    if(exponent < -4 || exponent >= 0) {
       if(is_neg) man_str[0] = '-';
      for(i = 0; i < len; i++) man_str[i + is_neg] = s[i];
      if(!exponent) {
        man_str[i + is_neg] = '\0';
        outsv = newSVpv(man_str, 0);
        Safefree(man_str);
        Safefree(exp_str);
        if(is_neg) s--;
        return outsv;
      }
      man_str[i + is_neg] = 'e';
      len = strlen(exp_str);
      if(exponent > 0) {
        man_str[i + 1 + is_neg] = '+';
        dec = i + 2 + is_neg;
        for(i = 0; i < len; i ++) man_str[dec + i] = exp_str[i];
        man_str[dec + i] = '\0';
        outsv = newSVpv(man_str, 0);
        Safefree(man_str);
        Safefree(exp_str);
        if(is_neg) s--;
        return outsv;
      }
      /* exponent < -4 */
      dec = i + 1 + is_neg;
      if(len == 2) {
        man_str[dec] = '-';
        man_str[dec + 1] = '0';
        man_str[dec + 2] = exp_str[1];
        man_str[dec + 3] = '\0';
      }
      else {
        for(i = 0; i < len; i++) man_str[dec + i] = exp_str[i];
        man_str[dec + i] = '\0';
      }
      outsv = newSVpv(man_str, 0);
      Safefree(man_str);
      Safefree(exp_str);
      if(is_neg) s--;
      return outsv;
    }
    /* exponent is in range -1 to -4 (inclusive). *
     * Return, eg 6.25E1 as "0.625". **************/
     if(is_neg) man_str[0] = '-';
     man_str[is_neg] = '0';
     man_str[1 + is_neg] = '.';
     zero_pad = -exponent;
     zero_pad --;
     for(i = 0; i < zero_pad; i++) man_str[i + 2 + is_neg] = '0';
     man_str[i + 2 + is_neg] = s[0];
     dec = i + 1 + is_neg;
     len = strlen(s);
     for(i = 2; i < len; i++) man_str[dec + i] = s[i];
     man_str[dec + i] = '\0';
     outsv = newSVpv(man_str, 0);
     Safefree(man_str);
     Safefree(exp_str);
     if(is_neg) s--;
     return outsv;
  }
  else {
    /*** NO DECIMAL POINT IN STRING ***/
    if(s[0] == 'I') {
      if(is_neg) return newSVpv("-inf", 0);
      else return newSVpv("inf", 0);
    }
    if(s[0] == 'N') {
      if(is_neg) {
        s--;
        croak("rubbish input of '%s'", s);
      }
      return newSVpv("nan", 0);
    }
    /* mantissa is single-digit */
    len = strlen(s);
    Newxz(exp_str, MAX_DEC_DIG + 6, char);
    if(exp_str == NULL) croak("Failed (in 'else' block) to allocate memory for exp_str in fmtpy function");
    for(i = 2; i <= len; i++) exp_str[i - 2] = s[i];
    exponent = atoi(exp_str);
    if(exponent < -9) {
      /* Return, eg, '5E-10' as '5e-10' */
      s[1] = 'e';
      if(is_neg) s--;
      Safefree(exp_str);
      return newSVpv(s, 0);
    }
    /* Put the string to return into exp_str */
    if(exponent < -4) {
      /* Return, eg, '5E-9' as '5e-09'. */
      if(is_neg) exp_str[0] = '-';
      exp_str[0 + is_neg] = s[0];
      exp_str[1 + is_neg] = 'e';
      exp_str[2 + is_neg] = '-';
      exp_str[3 + is_neg] = '0';
      exp_str[4 + is_neg] = s[3];
      exp_str[5 + is_neg] = '\0';
      outsv = newSVpv(exp_str, 0);
      Safefree(exp_str);
      if(is_neg) s--;
      return outsv;
    }

    if(exponent >= 0 && exponent <= MAX_DEC_DIG - 2) {
      /* Return, eg, '5E13' as '50000000000000.0' */
      if(is_neg) exp_str[0] = '-';
      exp_str[0 + is_neg] = s[0];
      for(dec = 0; dec < exponent; dec++) exp_str[1 + is_neg + dec] = '0';
      exp_str[1 + is_neg + dec] = '.';
      exp_str[2 + is_neg + dec] = '0';
      exp_str[3 + is_neg + dec] = '\0';

      outsv = newSVpv(exp_str, 0);
      Safefree(exp_str);
      if(is_neg) s--;
      return outsv;
    }

    if(exponent > MAX_DEC_DIG - 2) {
      /* Return, eg, '8E50' as '8e+50' */
      if(is_neg) exp_str[0] = '-';
      exp_str[0 + is_neg] = s[0];
      exp_str[1 + is_neg] = 'e';
      exp_str[2 + is_neg] = '+';
      for(dec = 2; dec < len; dec++) exp_str[dec + 1 + is_neg] = s[dec];
      exp_str[dec + 1 + is_neg] = '\0';
      outsv = newSVpv(exp_str, 0);
      Safefree(exp_str);
      if(is_neg) s--;
      return outsv;
    }

    /* Exponent is in  the range -1 to -4. We   *
     * want, eg, '7E-1' to be returned as '0.7' *
     * and '-9E-4' to be returned as '-0.0009'  */

    if(is_neg)  exp_str[0] = '-';
    exp_str[0 + is_neg] = '0';
    exp_str[1 + is_neg] = '.';
    for(dec = -1; dec > exponent; dec--)  exp_str[1 + is_neg - dec] = '0';
    exp_str[1 + is_neg - dec] = s[0];
    exp_str[2 + is_neg - dec] = '\0';

    outsv = newSVpv(exp_str, 0);
    Safefree(exp_str);
    if(is_neg) s--;
    return outsv;
  }
}


MODULE = Math::Ryu  PACKAGE = Math::Ryu PREFIX = M_RYU_

PROTOTYPES: DISABLE

double
_s2d (buffer)
	char *	buffer

SV *
M_RYU_d2s (nv)
	SV *	nv
CODE:
  RETVAL = M_RYU_d2s (aTHX_ nv);
OUTPUT:  RETVAL

SV *
ld2s (nv)
	SV *	nv
CODE:
  RETVAL = ld2s (aTHX_ nv);
OUTPUT:  RETVAL

SV *
q2s (nv)
	SV *	nv
CODE:
  RETVAL = q2s (aTHX_ nv);
OUTPUT:  RETVAL

int
_SvIOK (sv)
	SV *	sv

int
_SvNOK (sv)
	SV *	sv

int
_SvPOK (sv)
	SV *	sv

int
_SvIOKp (sv)
	SV *	sv

int ryu_lln (sv)
	SV *	sv
CODE:
  RETVAL = ryu_lln (aTHX_ sv);
OUTPUT:  RETVAL

int
_compiler_has_uint128 ()

int
_get_max_dec_dig ()

SV *
fmtpy (in)
	SV *	in
CODE:
  RETVAL = fmtpy (aTHX_ in);
OUTPUT:  RETVAL
