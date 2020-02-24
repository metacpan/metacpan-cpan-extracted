#ifndef MARPAESLIF_INTERNAL_MATH_H
#define MARPAESLIF_INTERNAL_MATH_H

#include "marpaESLIF/internal/config.h"

#ifdef HAVE_MATH_H
#  include <math.h>
#endif
#ifdef HAVE_FLOAT_H
#  include <float.h>
#endif

/* ----------------------------- */
/* Common math portability hacks */
/* ----------------------------- */

/* HUGE_VAL is a 'double' Infinity.  */
#ifdef C_HUGE_VAL_REPLACEMENT
#  define MARPAESLIF_HUGE_VAL (__builtin_huge_val())
#else
#  ifdef C_HUGE_VAL
#    define MARPAESLIF_HUGE_VAL C_HUGE_VAL
#  endif
#endif

/* HUGE_VALF is a 'float' Infinity.  */
#ifdef C_HUGE_VALF_REPLACEMENT
#  define MARPAESLIF_HUGE_VALF (__builtin_huge_valf())
#else
#  ifdef C_HUGE_VALF
#    define MARPAESLIF_HUGE_VALF C_HUGE_VALF
#  endif
#endif

/* HUGE_VALL is a 'long double' Infinity. */
#ifdef C_HUGE_VALL_REPLACEMENT
#  define MARPAESLIF_HUGE_VALL (__builtin_huge_vall())
#else
#  ifdef C_HUGE_VALL
#    define MARPAESLIF_HUGE_VALL C_HUGE_VALL
#  endif
#endif

#ifdef C_INFINITY_REPLACEMENT_USING_DIVISION
#  define MARPAESLIF_INFINITY (1.0 / 0.0)
#else
#  ifdef C_INFINITY_REPLACEMENT
#    define MARPAESLIF_INFINITY (__builtin_inff())
#  else
#    ifdef C_INFINITY
#      define MARPAESLIF_INFINITY C_INFINITY
#    endif
#  endif
#endif

#ifdef C_NAN_REPLACEMENT_USING_DIVISION
#  define MARPAESLIF_NAN (0.0 / 0.0)
#else
#  ifdef C_NAN_REPLACEMENT
#    define MARPAESLIF_NAN (__builtin_nanf(""))
#  else
#    ifdef C_NAN
#      define MARPAESLIF_NAN C_NAN
#    endif
#  endif
#endif

#ifdef C_ISINF_REPLACEMENT
#  define MARPAESLIF_ISINF(f) (__builtin_isinf(f))
#else
#  ifdef C_ISINF
#    define MARPAESLIF_ISINF(f) C_ISINF(f)
#  endif
#endif

#ifdef C_ISNAN_REPLACEMENT
#  define MARPAESLIF_ISNAN(f) (__builtin_isnan(f))
#else
#  ifdef C_ISNAN
#    define MARPAESLIF_ISNAN(f) C_ISNAN(f)
#  endif
#endif

/* ====================================================================== */
/*                         Math and float fallbacks                       */
/* ====================================================================== */
/* HUGE_VALx fallbacks - we do not use promotions but the  */
/* contrary so that we sure that the the HUGE value, if it can */
/* be defined, is really what we expect for the appropriate type */
/* Note that by definition HUGE_VALL >= HUGE_VAL => HUGE_VALF */
#ifndef MARPAESLIF_HUGE_VAL
/* Only a downgrade of MARPAESLIF_HUGE_VALL is supported */
#  ifdef MARPAESLIF_HUGE_VALL
#    define MARPAESLIF_HUGE_VAL (double)(MARPAESLIF_HUGE_VALL)
#    ifdef __GNUC__
#      warning MARPAESLIF_HUGE_VAL fallback using MARPAESLIF_HUGE_VALL
#    else
#      ifdef _MSC_VER
#        pragma message("MARPAESLIF_HUGE_VAL fallback using MARPAESLIF_HUGE_VALL")
#      endif
#    endif
#  endif
#endif
#ifndef MARPAESLIF_HUGE_VALF
/* Downgrades of MARPAESLIF_HUGE_VALL and MARPAESLIF_HUGE_VAL are supported */
#  ifdef MARPAESLIF_HUGE_VALL
#    define MARPAESLIF_HUGE_VALF (float)(MARPAESLIF_HUGE_VALL)
#    ifdef __GNUC__
#      warning MARPAESLIF_HUGE_VALF fallback using MARPAESLIF_HUGE_VALL
#    else
#      ifdef _MSC_VER
#        pragma message("MARPAESLIF_HUGE_VALF fallback using MARPAESLIF_HUGE_VALL")
#      endif
#    endif
#  else
#    ifdef MARPAESLIF_HUGE_VAL
#      define MARPAESLIF_HUGE_VALF (float)(MARPAESLIF_HUGE_VAL)
#      ifdef __GNUC__
#        warning MARPAESLIF_HUGE_VALF fallback using MARPAESLIF_HUGE_VAL
#      else
#        ifdef _MSC_VER
#          pragma message("MARPAESLIF_HUGE_VALF fallback using MARPAESLIF_HUGE_VAL")
#        endif
#      endif
#    endif
#  endif
#endif

/* INFINITY fallback - only on MSVC */
#ifndef MARPAESLIF_INFINITY
#  ifdef _MSC_VER
/* We do like ReactOS  - c.f. https://doxygen.reactos.org/d3/d22/sdk_2include_2reactos_2wine_2port_8h_source.html */
static inline float __port_infinity(void)
{
  static const unsigned __inf_bytes = 0x7f800000;
  return *(const float *)&__inf_bytes;
}
#    define MARPAESLIF_INFINITY __port_infinity()
#    ifdef __GNUC__
#      warning MARPAESLIF_INFINITY fallback using 0x7f800000
#    else
#      ifdef _MSC_VER
#        pragma message("MARPAESLIF_INFINITY fallback using 0x7f800000")
#      endif
#    endif
#  endif
#endif

/* INFINITY fallback - only on MSVC */
#ifndef MARPAESLIF_NAN
#  ifdef _MSC_VER
/* We do like ReactOS  - c.f. https://doxygen.reactos.org/d3/d22/sdk_2include_2reactos_2wine_2port_8h_source.html */
static inline float __port_nan(void)
{
  static const unsigned __nan_bytes = 0x7fc00000;
  return *(const float *)&__nan_bytes;
}
#    define MARPAESLIF_NAN __port_nan()
#    ifdef __GNUC__
#      warning MARPAESLIF_NAN fallback using 0x7fc00000
#    else
#      ifdef _MSC_VER
#        pragma message("MARPAESLIF_NAN fallback using 0x7fc00000")
#      endif
#    endif
#  endif
#endif

/* isinf fallback - we use fpclassify. In case it is internall _fpclass, */
/* that is MSVC specific, we explicitly cast to a double */
#ifndef MARPAESLIF_ISINF
#  ifdef C_FPCLASSIFY
#    ifdef C_FP_INFINITE
#      define MARPAESLIF_ISINF(x) (C_FPCLASSIFY(x) == C_FP_INFINITE)
#      ifdef __GNUC__
#        warning MARPAESLIF_ISINF fallback using FP_INFINITE
#      else
#        ifdef _MSC_VER
#          pragma message("MARPAESLIF_ISINF fallback using FP_INFINITE")
#        endif
#      endif
#    else
#      if defined(C__FPCLASS_NINF) && defined(C__FPCLASS_PINF)
#        define MARPAESLIF_ISINF(x) ((C_FPCLASSIFY(x) == C__FPCLASS_NINF) || (C_FPCLASSIFY(x) == C__FPCLASS_PINF))
#        ifdef __GNUC__
#          warning MARPAESLIF_ISINF fallback using _FPCLASS_NINF and _FPCLASS_PNINF
#        else
#          ifdef _MSC_VER
#            pragma message("MARPAESLIF_ISINF fallback using _FPCLASS_NINF and _FPCLASS_PNINF")
#          endif
#        endif
#      endif
#    endif
#  endif
#endif

/* isnan fallback - we use fpclassify. In case it is internall _fpclass, */
/* that is MSVC specific, cast to double is implicit, and on MSVC long double is a double */
#ifndef MARPAESLIF_ISNAN
#  ifdef C_FPCLASSIFY
#    ifdef C_FP_NAN
#      define MARPAESLIF_ISNAN(x) (C_FPCLASSIFY(x) == C_FP_NAN)
#      ifdef __GNUC__
#        warning MARPAESLIF_ISNAN fallback using FP_NAN
#      else
#        ifdef _MSC_VER
#          pragma message("MARPAESLIF_ISNAN fallback using FP_NAN")
#        endif
#      endif
#    else
#      if defined(C__FPCLASS_SNAN) && defined(C__FPCLASS_QNAN)
#        define MARPAESLIF_ISNAN(x) ((C_FPCLASSIFY(x) == C__FPCLASS_SNAN) || (C_FPCLASSIFY(x) == C__FPCLASS_QNAN))
#        ifdef __GNUC__
#          warning MARPAESLIF_ISNAN fallback using _FPCLASS_SNAN and _FPCLASS_QNAN
#        else
#          ifdef _MSC_VER
#            pragma message("MARPAESLIF_ISNAN fallback using _FPCLASS_SNAN and _FPCLASS_QNAN")
#          endif
#        endif
#      endif
#    endif
#  endif
#endif

#if defined(MARPAESLIF_NAN) && defined(MARPAESLIF_ISNAN)
#  define MARPAESLIF_HAVENAN 1
#else
#  ifdef __GNUC__
#    warning NaN is not fully supported
#  else
#    ifdef _MSC_VER
#      pragma message("NaN is not fully supported")
#   endif
#  endif
#  ifndef MARPAESLIF_NAN
#    define MARPAESLIF_NAN 0
#  endif
#  ifndef MARPAESLIF_ISNAN
#    define MARPAESLIF_ISNAN(x) 0
#  endif
#endif

#if defined(MARPAESLIF_INFINITY) && defined(MARPAESLIF_ISINF)
#  define MARPAESLIF_HAVEINF 1
#else
#  ifdef __GNUC__
#    warning Infinity is not fully supported
#  else
#    ifdef _MSC_VER
#      pragma message("Infinity is not fully supported")
#   endif
#  endif
#  ifndef MARPAESLIF_INFINITY
#    define MARPAESLIF_INFINITY 0
#  endif
#  ifndef MARPAESLIF_ISINF
#    define MARPAESLIF_ISINF(x) 0
#  endif
#endif


#endif /* MARPAESLIF_INTERNAL_MATH_H */
