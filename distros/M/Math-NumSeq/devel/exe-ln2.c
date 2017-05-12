/* Copyright 2010, 2012 Kevin Ryde

   This file is part of Math-NumSeq.

   Math-NumSeq is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along
   with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.  */

#include <stdio.h>
#include <gmp.h>
#include <mpfr.h>

int
main (void)
{
  {
    mpfr_t pi;
    mpz_t z;
    unsigned long bits = 1000000;
    unsigned long i, j, prev;

    mpfr_init2 (pi, bits);
/*     mpfr_const_pi (pi, GMP_RNDZ); */
    mpfr_const_log2 (pi, GMP_RNDZ);
    mpfr_mul_2exp (pi, pi, bits-1, GMP_RNDZ);
    mpz_init (z);
    mpfr_get_z (z, pi, GMP_RNDZ);

    i = bits;
    j = 1;
    prev = 1;
    for (;;) {
      if (mpz_tstbit (z, i)) {
        printf ("%lu\n", j-prev);
        prev = j;
      } else {
        /* printf ("0"); */
      }
      if (i == 0) break;
      i--; j++;
    }
    printf ("\n");
    return 0;
  }

  {
    mpz_t total, num, q;
    unsigned long bits = 1000000;
    unsigned long k, den;

    /* quadratic in bits, about 125000 fracs to accumulate */

    mpz_init_set_ui (total, 0);
    mpz_init_set_ui (num, 1);
    mpz_init (q);
    mpz_mul_2exp (num, num, bits);

    for (k = 0; ; k++) {
      den = 2*k + 1;
      /* printf("1 / 4**%-2lu * %2lu\n", k, den); */

      mpz_div_ui (q, num, den);
      mpz_add (total, total, q);
      mpz_cdiv_q_2exp (num, num, 2);

      if (mpz_cmp_ui (num, den) < 0) {
        break;
      }
    }
    return 0;
  }

  {
    mpfr_t ln;
    unsigned long bits = 1000000;
    mpfr_init2 (ln, bits);
    mpfr_set_ui (ln, 3, GMP_RNDZ);
    mpfr_log (ln, ln, GMP_RNDZ);
    return 0;
  }
}
