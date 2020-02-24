/* We do not want to depend on the floating point format representation */
/* so we use only an interation on the sprintf presision plus verification */
/* using C_STRTOx functions. This is very slow, you are warned. */
/* Note that gnulib uses the same technique. */

#ifdef HAVE_MATH_H
#  include <math.h>
#endif
#ifdef HAVE_FLOAT_H
#  include <float.h>
#endif

#undef  FILENAMES
#define FILENAMES "floattos.c" /* For logging */

/* Sane values are derived from http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2006/n2005.pdf */
/* We do not mind if we ask a bit more than the real precision - sprintf will handle that. */
#ifndef FLT_DECIMAL_DIG
#define FLT_DECIMAL_DIG (9)
#endif
#ifndef DBL_DECIMAL_DIG
#define DBL_DECIMAL_DIG (17)
#endif
#ifndef LDBL_DECIMAL_DIG
#define LDBL_DECIMAL_DIG ((sizeof(long double) == sizeof(double)) ? DBL_DECIMAL_DIG : 36) /* Compiler will optimize that */
#endif

#if defined(MARPAESLIF_ISINF) && defined(MARPAESLIF_INFINITY)
#  define MARPAESLIF_FLOATTOS_INFINITY(x) do {                  \
    if (MARPAESLIF_ISINF(x)) {                                  \
      /* Get native inf representation - this must not fail */  \
      marpaESLIF_stringGenerator.marpaESLIFp = marpaESLIFp;     \
      marpaESLIF_stringGenerator.s           = NULL;            \
      marpaESLIF_stringGenerator.l           = 0;               \
      marpaESLIF_stringGenerator.okb         = 0;               \
      marpaESLIF_stringGenerator.allocl      = 0;                       \
                                                                        \
      genericLoggerp = GENERICLOGGER_CUSTOM(_marpaESLIF_generateStringWithLoggerCallback, (void *) &marpaESLIF_stringGenerator, GENERICLOGGER_LOGLEVEL_TRACE); \
      if (genericLoggerp == NULL) {                                     \
        goto err;                                                       \
      }                                                                 \
      GENERICLOGGER_TRACEF(genericLoggerp, "%f", (double) MARPAESLIF_INFINITY); \
      if (! marpaESLIF_stringGenerator.okb) {                           \
        goto err;                                                       \
      }                                                                 \
      goto done;                                                        \
    }                                                                   \
} while (0)
#else
#  define MARPAESLIF_FLOATTOS_INFINITY(x)
#endif

#if defined(MARPAESLIF_ISNAN) && defined(MARPAESLIF_NAN)
#  define MARPAESLIF_FLOATTOS_NAN(x) do {                       \
    if (MARPAESLIF_ISNAN(x)) {                                  \
      /* Get native inf representation - this must not fail */  \
      marpaESLIF_stringGenerator.marpaESLIFp = marpaESLIFp;     \
      marpaESLIF_stringGenerator.s           = NULL;            \
      marpaESLIF_stringGenerator.l           = 0;               \
      marpaESLIF_stringGenerator.okb         = 0;                       \
      marpaESLIF_stringGenerator.allocl      = 0;                       \
                                                                        \
      genericLoggerp = GENERICLOGGER_CUSTOM(_marpaESLIF_generateStringWithLoggerCallback, (void *) &marpaESLIF_stringGenerator, GENERICLOGGER_LOGLEVEL_TRACE); \
      if (genericLoggerp == NULL) {                                     \
        goto err;                                                       \
      }                                                                 \
      GENERICLOGGER_TRACEF(genericLoggerp, "%f", (double) MARPAESLIF_NAN); \
      if (! marpaESLIF_stringGenerator.okb) {                           \
        goto err;                                                       \
      }                                                                 \
      goto done;                                                        \
    }                                                                   \
} while (0)
#else
#  define MARPAESLIF_FLOATTOS_NAN(x)
#endif

#define MARPAESLIF_FLOATTOS(name, type, fmts, fmts_type, strtox, decimal_dig) \
  static inline char *_##name##_minDigits(marpaESLIF_t *marpaESLIFp, type x); \
  char *name(marpaESLIF_t *marpaESLIFp, type x)                         \
  {                                                                     \
    if (marpaESLIFp == NULL) {                                          \
      errno = EINVAL;                                                   \
      return NULL;                                                      \
    }                                                                   \
                                                                        \
    return _##name##_minDigits(marpaESLIFp, x);                         \
  }                                                                     \
                                                                        \
  static inline char *_##name##_minDigits(marpaESLIF_t *marpaESLIFp, type x) \
  {                                                                     \
    genericLogger_t              *genericLoggerp = NULL;                \
    marpaESLIF_stringGenerator_t  marpaESLIF_stringGenerator;           \
                                                                        \
    if (marpaESLIFp == NULL) {                                          \
      errno = EINVAL;                                                   \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    MARPAESLIF_FLOATTOS_INFINITY(x);                                    \
    MARPAESLIF_FLOATTOS_NAN(x);                                         \
                                                                        \
    marpaESLIF_stringGenerator.marpaESLIFp = marpaESLIFp;               \
    marpaESLIF_stringGenerator.s           = NULL;                      \
    marpaESLIF_stringGenerator.l           = 0;                         \
    marpaESLIF_stringGenerator.okb         = 0;                         \
    marpaESLIF_stringGenerator.allocl      = 0;                         \
                                                                        \
    genericLoggerp = GENERICLOGGER_CUSTOM(_marpaESLIF_generateStringWithLoggerCallback, (void *) &marpaESLIF_stringGenerator, GENERICLOGGER_LOGLEVEL_TRACE); \
    if (genericLoggerp == NULL) {                                       \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    GENERICLOGGER_TRACEF(genericLoggerp, fmts, (int) decimal_dig, (fmts_type) x); \
    if (! marpaESLIF_stringGenerator.okb) {                             \
      goto err;                                                         \
    }                                                                   \
                                                                        \
    goto done;                                                          \
                                                                        \
  err:                                                                  \
    if (marpaESLIF_stringGenerator.s != NULL) {                         \
      free(marpaESLIF_stringGenerator.s);                               \
      marpaESLIF_stringGenerator.s = NULL;                              \
    }                                                                   \
                                                                        \
  done:                                                                 \
    GENERICLOGGER_FREE(genericLoggerp);                                 \
    return marpaESLIF_stringGenerator.s;                                \
  }

MARPAESLIF_FLOATTOS(marpaESLIF_ftos, float, "%.*g", double, C_STRTOF, FLT_DECIMAL_DIG)
MARPAESLIF_FLOATTOS(marpaESLIF_dtos, double, "%.*g", double, C_STRTOD, DBL_DECIMAL_DIG)
MARPAESLIF_FLOATTOS(marpaESLIF_ldtos, long double, "%.*Lg", long double, C_STRTOLD, LDBL_DECIMAL_DIG)

