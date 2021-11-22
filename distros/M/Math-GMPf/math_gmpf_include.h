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

The following can be used by the (internal)  _Rmpf_get_* functions, which
could be called by Rmpf_get_NV:

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

#if defined MATH_GMPF_NEED_LONG_LONG_INT
#ifndef _MSC_VER
#include <inttypes.h>
#endif
#endif

#include <stdlib.h>
#include <gmp.h>
#include<float.h>

#if defined(USE_QUADMATH)
#include <quadmath.h>
typedef __float128 float128;
#endif

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

#ifdef _MSC_VER
#pragma warning(disable:4700 4715 4716)
#endif

#if defined MATH_GMPF_NEED_LONG_LONG_INT
#ifndef _MSC_VER
#include <inttypes.h>
#endif
#endif

#define NEG_ZERO_BUG 50103 /* A bug affecting mpf_fits_u*_p functions     */
                           /* Fixed in gmp after __GNU_MP_RELEASE 50103 ? */

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

#define NOK_POK_DUALVAR_CHECK \
        if(SvNOK(b)) { \
         nok_pok++; \
         if(SvIVX(get_sv("Math::GMPf::NOK_POK", 0))) \
           warn("Scalar passed to %s is both NV and PV. Using PV (string) value"

