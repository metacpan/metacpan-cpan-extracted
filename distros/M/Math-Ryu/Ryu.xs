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

double M_RYU_s2d(char * buffer) {
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


MODULE = Math::Ryu  PACKAGE = Math::Ryu PREFIX = M_RYU_

PROTOTYPES: DISABLE

double
M_RYU_s2d (buffer)
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
