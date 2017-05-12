#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef CHAR_BIT
# define BYTE_BITS CHAR_BIT /* limits.h */
#else
# define BYTE_BITS 8        /* at least 8 bits wide */
#endif

#define BIT_VECTOR(num) ((num) / 2) /* double space for uneven numbers */

#define EVEN_NUM(num) ((num) % 2 == 0)

#define NUM_SET(num_entry, var_ptr, num_pos, num_val) \
    (*num_entry).ptr = var_ptr;                       \
    (*num_entry).pos = num_pos;                       \
    (*num_entry).val = num_val;                       \

#define NUM_LEN(nums) (sizeof (nums) / sizeof (num_entry))

/* ULONG_MAX_IS_ODD_COMPOSITE is true if ULONG_MAX is odd and composite.
   Checking mod 3 is enough to detect 2^32-1 and 2^64-1 (and other even
   number of bits).  */
#define ULONG_MAX_IS_ODD_COMPOSITE              \
  ((ULONG_MAX % 2) == 0 || (ULONG_MAX % 3) == 0)

typedef struct {
    unsigned long **ptr;
    unsigned int pos;
    unsigned long val;
} num_entry;

static void
store (const num_entry *numbers, unsigned int len, unsigned int *pos)
{
    unsigned int i;
    for (i = 0; i < len; i++)
      {
        unsigned long **p      = numbers[i].ptr;
        const unsigned int pos = numbers[i].pos;
        if (*p)
          {
            Renew (*p, pos + 1, unsigned long);
            Zero  (*p + pos, 1, unsigned long);
          }
        else
          Newxz (*p, 1, unsigned long);
        (*p)[pos] = numbers[i].val;
      }
    if (pos) /* keep it optional */
      (*pos)++;
}

MODULE = Math::Prime::XS                PACKAGE = Math::Prime::XS

bool
is_prime (n)
      unsigned long n
    PREINIT:
      /* Bit table of numbers 0 to 31 which are primes. */
      const unsigned long small_table = (( (1 << 2))
                                          | (1 << 3)
                                          | (1 << 5)
                                          | (1 << 7)
                                          | (1 << 11)
                                          | (1 << 13)
                                          | (1 << 17)
                                          | (1 << 19)
                                          | (1 << 23)
                                          | (1 << 29)
                                          | (1 << 31));

      /* Bit table of the remainders mod 30 which might be primes, ie. which
         aren't divisible by 2, 3 or 5. */
      const unsigned long mod_table = ~ (( (1 << 0))
                                         | (1 << 2)
                                         | (1 << 4)
                                         | (1 << 6)
                                         | (1 << 8)
                                         | (1 << 10)
                                         | (1 << 12)
                                         | (1 << 14)
                                         | (1 << 16)
                                         | (1 << 18)
                                         | (1 << 20)
                                         | (1 << 22)
                                         | (1 << 24)
                                         | (1 << 26)
                                         | (1 << 28)
                                         | (1 << 30)

                                         | (1 << 3)
                                         | (1 << 6)
                                         | (1 << 9)
                                         | (1 << 12)
                                         | (1 << 15)
                                         | (1 << 18)
                                         | (1 << 21)
                                         | (1 << 24)
                                         | (1 << 27)
                                         | (1 << 30)

                                         | (1 << 5)
                                         | (1 << 10)
                                         | (1 << 15)
                                         | (1 << 20)
                                         | (1 << 25));

    INIT:
      unsigned long i;
    CODE:
      {
        double d = SvNV(ST(0));
        if (! (d >= 0 && d <= ULONG_MAX)) {
          croak ("Cannot isprime() on %g", d);
        }
      }

      if (n < 32) {
        RETVAL = (small_table >> n) & 1;
      } else {
        RETVAL = 0;
        if ((mod_table >> (n%30)) & 1) {
          unsigned long limit = (unsigned long) floor(sqrt(n));

          /* At this point n is not a multiple of 2, 3 or 5, so can skip odd
             i, and i multiple of 3, and i multiple of 5.

             For reference, doing all odd i would be 15 out of each 30
             divisors.  Excluding i multiples of 3 reduces to 10 out of 30.
             Excluding i multiples of 5 reduces to 8 out of 30. */

          i = 7;
          for (;;) {
            if (n % i == 0)  goto done;   /* i == 30*k+7 */

            if ((i += 4) > limit) break;  /* i == 30*k+11 */
            if (n % i == 0)  goto done;

            if ((i += 2) > limit) break;  /* i == 30*k+13 */
            if (n % i == 0)  goto done;

            if ((i += 4) > limit) break;  /* i == 30*k+17 */
            if (n % i == 0)  goto done;

            if ((i += 2) > limit) break;  /* i == 30*k+19 */
            if (n % i == 0)  goto done;

            if ((i += 4) > limit) break;  /* i == 30*k+23 */
            if (n % i == 0)  goto done;

            if ((i += 6) > limit) break;  /* i == 30*k+29 */
            if (n % i == 0)  goto done;

            if ((i += 2) > limit) break;  /* i == 30*k+1 */
            if (n % i == 0)  goto done;

            if ((i += 6) > limit) break;  /* back to i == 30*k+7 */
          }
          RETVAL = 1;
        }
      }
      done:
      ;
    OUTPUT:
      RETVAL

void
xs_mod_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long i, n;
    PPCODE:
      /* For the sqrt(), casting double->ulong probably follows the fpu
         rounding mode, so might round either up or down.  If up then the
         last trial division may be unnecessary, but not harmful.
       */

      /* special case for 2 if it's in range, then can use n+=2 for odd n in
         the loop */
      if (base <= 2) {
        base = 3;
        if (number >= 2) {
          XPUSHs (sv_2mortal(newSVuv(2)));
        }
      }

      /* next higher odd number, if not odd already */
      base |= 1;

      /* If number==ULONG_MAX then n<=number is always true and would be an
         infinite loop.  If ULONG_MAX and ULONG_MAX-1 are both composites
         (which is so for 2^32-1 and 2^64-1) then can stop before them, by
         shortening "number" to ULONG_MAX-2.  If not (some strange ULONG_MAX
         value) then check for n>=ULONG_MAX-1 below so n+=2 doesn't
         overflow.
       */
      if (ULONG_MAX_IS_ODD_COMPOSITE) {
        /* usual case of 2^32-1 or 2^64-1 */
        if (number > ULONG_MAX-2)
          number = ULONG_MAX-2;
      }

      for (n = base; n <= number; n += 2)
        {
          unsigned long limit = (unsigned long) floor(sqrt(n));
          for (i = 3; i <= limit; i+=2)
            {
              if (n % i == 0)
                goto NEXT_OUTER;
            }
          /* (n % 1 == 0) && (n % n == 0) */
          XPUSHs (sv_2mortal(newSVuv(n)));

        NEXT_OUTER:
          if (! ULONG_MAX_IS_ODD_COMPOSITE) { /* some unusual ULONG_MAX */
            if (n >= ULONG_MAX-1)
              break;
          }
        }

void
xs_sieve_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    ALIAS:
     xs_sieve_count_primes = 1
    INIT:
      unsigned long *composite = NULL;
      unsigned long i, n;
      unsigned long count = 0;
    PPCODE:
      const unsigned long square_root = sqrt (number); /* truncates */
      const unsigned int size_bits = sizeof (unsigned long) * BYTE_BITS;

      Newxz (composite, (BIT_VECTOR (number) / size_bits) + 1, unsigned long);

      for (n = 3; n <= square_root; n += 2) /* uneven numbers only */
        {
          /* (n * n) - start with square */
          /* (2 * n) - skip even number  */
          for (i = (n * n); i <= number; i += (2 * n))
            {
              const unsigned int bits  = BIT_VECTOR (i - 2) % size_bits;
              const unsigned int field = BIT_VECTOR (i - 2) / size_bits;

              composite[field] |= (unsigned long)1 << bits;
            }
        }
      for (n = 2; n <= number; n++)
        {
          if (n > 2 && EVEN_NUM (n))
            continue;
          else if (!EVEN_NUM (n) && composite[BIT_VECTOR (n - 2) / size_bits] & ((unsigned long)1 << (BIT_VECTOR (n - 2) % size_bits)))
            continue;
          else if (n >= base)
            {
              if (ix) {
                /* xs_sieve_count_primes() */
                count++;
              } else {
                /* xs_sieve_primes() */
                mXPUSHu(n);
              }
            }
        }

      Safefree (composite);

      if (ix) {
        /* xs_sieve_count_primes() */
        mXPUSHu(count);
      }

void
xs_sum_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long *primes = NULL, *sums = NULL;
      unsigned int pos = 0;
      unsigned long n;
    PPCODE:
      for (n = 2; n <= number; n++)
        {
          bool is_prime = TRUE;
          const unsigned long square_root = sqrt (n); /* truncates */
          unsigned int c;
          for (c = 0; c < pos && primes[c] <= square_root; c++)
            {
              unsigned long sum = sums[c];
              while (sum < n)
                sum += primes[c];
              sums[c] = sum;
              if (sum == n)
                {
                  is_prime = FALSE;
                  break;
                }
            }
          if (is_prime)
            {
              num_entry numbers[2];
              NUM_SET (&numbers[0], &primes, pos, n);
              NUM_SET (&numbers[1], &sums,   pos, 0);
              store (numbers, NUM_LEN (numbers), &pos);

              if (n >= base)
                {
                  EXTEND (SP, 1);
                  PUSHs (sv_2mortal(newSVuv(n)));
                }
            }
        }

      Safefree (primes);
      Safefree (sums);

void
xs_trial_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long *primes = NULL;
      unsigned int pos = 0;
      unsigned long start = 1;
      unsigned long i, n;
    PPCODE:
      for (n = 2; n <= number; n++)
        {
          bool is_prime = TRUE;
          unsigned long square_root; /* calculate later for efficiency */
          if (n > 2 && EVEN_NUM (n))
            continue;
          square_root = sqrt (n); /* truncates */
          for (i = start; i <= square_root; i++)
            {
              bool save_as_prime = TRUE;
              unsigned long c;
              /* not prime */
              if (i == 1)
                continue;
              /* even number */
              else if (EVEN_NUM (i))
                continue;
              /* number to resume from equals square root */
              else if (start == square_root)
                continue;
              /* check for non-uniqueness */
              else if (primes && i <= primes[pos - 1])
                continue;
              for (c = 2; c < i; c++)
                {
                  if (i % c == 0)
                    {
                      save_as_prime = FALSE;
                      break;
                    }
                }
              /* (i % 1 == 0) && (i % i == 0) */
              if (save_as_prime)
                {
                  num_entry numbers[1];
                  NUM_SET (&numbers[0], &primes, pos, i);
                  store (numbers, NUM_LEN (numbers), &pos);
                }
            }
          if (primes)
            {
              unsigned int c;
              for (c = 0; c < pos; c++)
                {
                  if (n % primes[c] == 0)
                    {
                      is_prime = FALSE;
                      break;
                    }
                }
            }
          if (is_prime && n >= base)
            {
              EXTEND (SP, 1);
              PUSHs (sv_2mortal(newSVuv(n)));
            }
          /* Optimize calculating the minor primes for trial division
             by starting from the previous square root.  */
          start = square_root;
        }

      Safefree (primes);
