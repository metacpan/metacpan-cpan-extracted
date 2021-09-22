/*************************************************
Documentation of symbols defined by Math::GMPf

REQUIRED_LDBL_MANT_DIG   : Defined to float.h's LDBL_MANT_DIG unless
                           LDBL_MANT_DIG is 106 (ie long double is
                           double-double) - in which case it is defined to
                           be 2098.
                           This is needed to ensure that the mpfr value is
                           an accurate rendition of the double-double value.

_WIN32_BIZARRE_INFNAN    : Defined (on Windows only) when the perl version
                           (as expressed by $]) is less than 5.022.
                           These earlier perl versions generally stringified
                           NaNs as (-)1.#IND and Infs as (-)1.#INF.

The following can be used by the (internal)  _mpf_get_* functions, which can
be called by Rmpq_get_NV:

#################################################

ULP_INDEX                : The index of the mantissa's ULP (unit of least
                           precision) for perl's NV type (long double or
                           __float128). Value = REQUIRED_LDBL_MANT_DIG - 1,
                           except for DoubleDouble when it is set to 52 (ie
                           DBL_MANT_DIG - 1).

LOW_SUBNORMAL_EXP        : Lowest subnormal exponent value for perl's NV type.
                           If the exponent is less than this value, then it
                           will be 0 when converted to an NV.

HIGH_SUBNORMAL_EXP       : Highest subnormal exponent value for perl's NV type.
                           If the exponent is higher than this value, then it
                           will convert to a normalized NV.

#################################################

*************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>
#include <limits.h>
#include <float.h>

#if LDBL_MANT_DIG == 106
#define REQUIRED_LDBL_MANT_DIG 2098
#else
#define REQUIRED_LDBL_MANT_DIG LDBL_MANT_DIG
#endif

#if NVSIZE == 8 || (defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 2098)
#define ULP_INDEX			52
#define LOW_SUBNORMAL_EXP		-1074
#define HIGH_SUBNORMAL_EXP		-1021
#elif defined(USE_LONG_DOUBLE) && REQUIRED_LDBL_MANT_DIG == 64
#define ULP_INDEX			63
#define LOW_SUBNORMAL_EXP		-16445
#define HIGH_SUBNORMAL_EXP		-16381
#else
#define ULP_INDEX			112
#define LOW_SUBNORMAL_EXP		-16494
#define HIGH_SUBNORMAL_EXP		-16381
#endif

#if defined(USE_QUADMATH)
#include <quadmath.h>
#endif

#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#endif

#if defined MATH_GMPQ_NEED_LONG_LONG_INT
#ifndef _MSC_VER
#include <inttypes.h>
#endif
#endif

#ifdef OLDPERL
#define SvUOK SvIsUV
#endif

#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#ifndef Newxz
#  define Newxz(v,n,t) Newz(0,v,n,t)
#endif

#define SV_IS_IOK(x) \
     SvIOK(x)

#define SV_IS_POK(x) \
     SvPOK(x)

#define SV_IS_NOK(x) \
     SvNOK(x)

#define _overload_callback(_1st_arg,_2nd_arg,_3rd_arg)					\
  dSP;											\
  SV * ret;										\
  int count;										\
  char buf[32];										\
  ENTER;										\
  PUSHMARK(SP);										\
  XPUSHs(b);										\
  XPUSHs(a);										\
  XPUSHs(sv_2mortal(_3rd_arg));								\
  PUTBACK;										\
  sprintf(buf, "%s", _1st_arg);								\
  count = call_pv(buf, G_SCALAR);							\
  SPAGAIN;										\
  if (count != 1)									\
   croak("Error in %s callback to %s\n", _2nd_arg, _1st_arg);				\
  ret = POPs;										\
  SvREFCNT_inc(ret);									\
  LEAVE;										\
  return ret

