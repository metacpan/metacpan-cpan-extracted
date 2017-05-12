/**
 * This header file contains static functions adapted from
 * Marc Lehmanns' JSON::XS, particularly because it's fast,
 * doesn't seem to rely on any external structures, and because
 * numeric conversions aren't my ideas of fun.
 */

#ifndef JSONXS_INLINE_H_
#define JSONXS_INLINE_H_

#include "perl-jsonsl.h"
#if __GNUC__ >= 3
# define expect(expr,value)         __builtin_expect ((expr), (value))
# define INLINE                     static inline
#else
# define expect(expr,value)         (expr)
# define INLINE                     static
#endif

#define ERR die
#define expect_false(expr) expect ((expr) != 0, 0)
#define expect_true(expr)  expect ((expr) != 0, 1)

#define jsonxs__atof_scan1(s,a,e,p,m) jsonxs__atof_scan1_THX(aTHX_ s,a,e,p,m)
INLINE void
jsonxs__atof_scan1_THX(pTHX_ const char *s,
                        NV *accum, int *expo, int postdp,
                        int maxdepth)
{
  UV  uaccum = 0;
  int eaccum = 0;

  /* if we recurse too deep, skip all remaining digits
   to avoid a stack overflow attack */
  if (expect_false (--maxdepth <= 0))
    while (((U8)*s - '0') < 10)
      ++s;

  for (;;)
    {
      U8 dig = (U8)*s - '0';

      if (expect_false (dig >= 10))
        {
          if (dig == (U8)((U8)'.' - (U8)'0'))
            {
              ++s;
              jsonxs__atof_scan1(s, accum, expo, 1, maxdepth);
            }
          else if ((dig | ' ') == 'e' - '0')
            {
              int exp2 = 0;
              int neg  = 0;

              ++s;

              if (*s == '-')
                {
                  ++s;
                  neg = 1;
                }
              else if (*s == '+')
                ++s;

              while ((dig = (U8)*s - '0') < 10)
                exp2 = exp2 * 10 + *s++ - '0';

              *expo += neg ? -exp2 : exp2;
            }

          break;
        }

      ++s;

      uaccum = uaccum * 10 + dig;
      ++eaccum;

      /*
      if we have too many digits, then recurse for more
      we actually do this for rather few digits
       */
      if (uaccum >= (UV_MAX - 9) / 10)
        {
          if (postdp) *expo -= eaccum;
          jsonxs__atof_scan1 (s, accum, expo, postdp, maxdepth);
          if (postdp) *expo += eaccum;

          break;
        }
    }

  /*
  // this relies greatly on the quality of the pow ()
  // implementation of the platform, but a good
  // implementation is hard to beat.
  // (IEEE 754 conformant ones are required to be exact)
   *
   */
  if (postdp) *expo -= eaccum;
  *accum += uaccum * Perl_pow (10., *expo);
  *expo += eaccum;
}

#define jsonxs__atof(s) jsonxs__atof_THX(aTHX_ s)
INLINE NV
jsonxs__atof_THX (pTHX_ const char *s)
{
  NV accum = 0.;
  int expo = 0;
  int neg  = 0;

  if (*s == '-')
    {
      ++s;
      neg = 1;
    }

  /* a recursion depth of ten gives us >>500 bits */
  jsonxs__atof_scan1(s, &accum, &expo, 0, 10);

  return neg ? -accum : accum;
}

#define jsonxs_inline_process_number(s) jsonxs_inline_process_number_THX(aTHX_ s)

INLINE SV *
jsonxs_inline_process_number_THX(pTHX_ const char *start)
{

    int is_nv = 0;
    const char *c = start;

    if (*c == '-')
        ++c;

    if (*c == '0') {
        ++c;
        if (*c >= '0' && *c <= '9') {
            ERR("malformed number (leading zero must not be followed by another digit)");
        }
    } else if (*c < '0' || *c > '9') {
        ERR("malformed number (no digits after initial minus)");
    } else {
        do {
            ++c;
        } while (*c >= '0' && *c <= '9');
    }

    if (*c == '.') {
        ++c;

        if (*c < '0' || *c > '9')
            ERR("malformed number (no digits after decimal point)");

        do {
            ++c;
        } while (*c >= '0' && *c <= '9');

        is_nv = 1;
    }

    if (*c == 'e' || *c == 'E') {
        ++c;

        if (*c == '-' || *c == '+')
            ++c;

        if (*c < '0' || *c > '9')
            ERR("malformed number (no digits after exp sign)");

        do {
            ++c;
        } while (*c >= '0' && *c <= '9');

        is_nv = 1;
    }

    if (!is_nv) {
        int len = c - start;

        /* special case the rather common 1..5-digit-int case */
        if (*start == '-')
            switch (len) {
            case 2:
                return newSViv (-(IV)( start [1] - '0' * 1));
            case 3:
                return newSViv (-(IV)( start [1] * 10 + start [2] - '0' * 11));
            case 4:
                return newSViv (-(IV)( start [1] * 100 + start [2] * 10 + start [3] - '0' * 111));
            case 5:
                return newSViv (-(IV)( start [1] * 1000 + start [2] * 100 + start [3] * 10 + start [4] - '0' * 1111));
            case 6:
                return newSViv (-(IV)(start [1] * 10000 + start [2] * 1000 + start [3] * 100 + start [4] * 10 + start [5] - '0' * 11111));
            }
        else
            switch (len) {
            case 1:
                return newSViv ( start [0] - '0' * 1);
            case 2:
                return newSViv ( start [0] * 10 + start [1] - '0' * 11);
            case 3:
                return newSViv ( start [0] * 100 + start [1] * 10 + start [2] - '0' * 111);
            case 4:
                return newSViv ( start [0] * 1000 + start [1] * 100 + start [2] * 10 + start [3] - '0' * 1111);
            case 5:
                return newSViv ( start [0] * 10000 + start [1] * 1000 + start [2] * 100 + start [3] * 10 + start [4] - '0' * 11111);
            }

        {
            UV uv;
            int numtype = grok_number (start, len, &uv);
            if (numtype & IS_NUMBER_IN_UV
                ) {
                if (numtype & IS_NUMBER_NEG)
                {
                    if (uv < (UV) IV_MIN
                        )
                        return newSViv (-(IV)uv);
                } else
                    return newSVuv (uv);
            }
        }

        len -= *start == '-' ? 1 : 0;

        /* does not fit into IV or UV, try NV */
        if (len <= NV_DIG
            )
            /* fits into NV without loss of precision */
            return newSVnv (jsonxs__atof (start));

        /* everything else fails, convert it to a string */
        return newSVpvn (start, c - start);
    }

    /* loss of precision here */
    return newSVnv (jsonxs__atof (start));
}

#undef ERR
#undef expect_false
#undef expect_true

#endif /* JSONXS_INLINE_H_ */
