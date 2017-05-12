#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc_GLOBAL
#include "ppport.h"

/* double_ulong_max_plus_1 is ULONG_MAX+1.  This is usually a power of 2 and
   thus can be represented exactly in a double.  The calculation avoids
   round-off if ulong is bigger than the mantissa of a double.  */
static const double double_ulong_max_plus_1
  = ((double) ((ULONG_MAX >> 1)+1)) * 2.0;

#define COUNT_OR_PUSH(prime)                            \
  do {                                                  \
    if (ix) {                                           \
      count++;         /* count_prime_factors() */      \
    } else {                                            \
      mXPUSHu(prime);  /* prime_factors() */            \
    }                                                   \
  } while (0)

MODULE = Math::Factor::XS               PACKAGE = Math::Factor::XS

void
factors (number)
      unsigned long number
    PROTOTYPE: $
    INIT:
      unsigned long i, square_root;
      AV *factors;
    PPCODE:
      /* range check */
      {
        double d = SvNV(ST(0));
        if (! (d >= 0 && d < double_ulong_max_plus_1)) {
          croak ("Cannot factors() on %g", d);
        }
      }

      factors = newAV ();
      square_root = sqrt (number);

      for (i = 2; i <= number; i++)
        {
          if (i > square_root)
            break;
          if (number % i == 0)
            {
              unsigned long quot = number / i;
              mXPUSHu(i);
              if (quot > i)
                av_push (factors, newSVuv(quot));
            }
        }

      i = av_len(factors) + 1;
      EXTEND (SP, i);
      while (i--)
        PUSHs (sv_2mortal(av_pop(factors)));

      SvREFCNT_dec (factors);

void
xs_matches (number, factors_aref, ...)
      unsigned long number
      SV *factors_aref
    PROTOTYPE: $\@
    INIT:
      AV *factors;
      unsigned long *prev_base = NULL;
      unsigned int b, c, p = 0;
      unsigned int top = items - 1;
      bool Skip_multiples = FALSE;
      bool skip = FALSE;
    PPCODE:
      factors = (AV*)SvRV (factors_aref);

      if (av_len (factors) == -1)
        XSRETURN_EMPTY;

      if (SvROK (ST(top)) && SvTYPE (SvRV(ST(top))) == SVt_PVHV)
        {
          const char *opt = "skip_multiples";
          unsigned int len = strlen (opt);
          HV *opts = (HV*)SvRV (ST(top));

          if (hv_exists (opts, opt, len))
            {
              SV **val = hv_fetch (opts, opt, len, 0);
              if (val)
                Skip_multiples = SvTRUE (*val);
            }
        }

      for (b = 0; b <= av_len (factors); b++)
        {
          unsigned long base = SvUV (*av_fetch(factors, b, 0));
          for (c = 0; c <= av_len (factors); c++)
            {
              unsigned long cmp = SvUV (*av_fetch(factors, c, 0));
              if ((cmp >= base) && (base * cmp == number))
                {
                  if (Skip_multiples)
                    {
                      unsigned int i;
                      skip = FALSE;
                      for (i = 0; i < p; i++)
                        if (base % prev_base[i] == 0)
                          skip = TRUE;
                    }
                  if (!skip)
                    {
                      AV *match = newAV ();
                      av_push (match, newSVuv(base));
                      av_push (match, newSVuv(cmp));

                      EXTEND (SP, 1);
                      PUSHs (sv_2mortal(newRV_noinc((SV*)match)));

                      if (Skip_multiples)
                        {
                          if (!prev_base)
                            Newx (prev_base, 1, unsigned long);
                          else
                            Renew (prev_base, p + 1, unsigned long);
                          prev_base[p++] = base;
                        }
                    }
                }
            }
        }

      Safefree (prev_base);

# prime_factors() and count_prime_factors() done in a combined XSUB so
# as to use the share the factorizing loop and to save a few bytes of
# object code by sharing the boilerplate sub entry and exit.
#
# No PROTOTYPE since might add a "distinct" option.
#
void
prime_factors (number)
      unsigned long number
    ALIAS:
     count_prime_factors = 1
    INIT:
     unsigned long i, limit;
     unsigned incr;
     unsigned long count = 0;
    PPCODE:
      /* range check */
      {
        double d = SvNV(ST(0));
        if (! (d >= 0 && d < double_ulong_max_plus_1)) {
          croak ("Cannot prime_factors() on %g", d);
        }
      }

      if (number > 0) {
        /* or perhaps __builtin_ctz() in new enough gcc, but usually there
           won't be many twos */
        while (! (number & 1)) {
          COUNT_OR_PUSH(2);
          number >>= 1;
        }

        while (! (number % 3)) {
          COUNT_OR_PUSH(3);
          number /= 3;
        }

        /* "incr" is alternately 2 and 4, giving i==5mod6 and i==1mod6, so
           skip multiples of 2 and multiples of 3 */
        limit = sqrt (number);
        incr = 2;
        for (i = 5; i <= limit; i += incr, incr ^= 6)
          {
            if (number % i == 0)
              {
                do {
                  number /= i;
                  COUNT_OR_PUSH(i);
                } while (number % i == 0);
                limit = sqrt (number); /* new smaller limit */
              }
          }
      }

      if (ix) {
        /* count_prime_factors() */
        count += (number > 1);  /* possible prime left in number */
        mXPUSHu(count);
      } else {
        /* prime_factors() */
        if (number > 1) {
          mXPUSHu(number);  /* possible prime left in number */
        }
      }
