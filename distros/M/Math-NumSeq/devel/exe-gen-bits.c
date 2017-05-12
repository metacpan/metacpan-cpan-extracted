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

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <gmp.h>
#include <mpfr.h>

void
output (mpfr_t f, const char *basename)
{
  mpfr_prec_t prec;
  unsigned long  i, pos, prev;
  char byte;
  char *filename, *command;
  FILE *fp;
  mpz_t z;

  if (asprintf (&filename, "../lib/App/MathImage/%s", basename) < 0) {
    perror ("asprintf");
    abort ();
  }
  printf ("output to %s\n", filename);
  
  fp = fopen (filename, "wb");
  if (! fp) abort();

  while (mpfr_cmp_ui (f, 1) < 0)
    mpfr_mul_2exp (f, f, 1, GMP_RNDZ);
  while (mpfr_cmp_ui (f, 1) >= 0)
    mpfr_div_2exp (f, f, 1, GMP_RNDZ);

  prec = mpfr_get_prec(f);
  mpfr_mul_2exp (f, f, prec, GMP_RNDZ);


  mpz_init (z);
  mpfr_get_z (z, f, GMP_RNDZ);

  pos = 1;
  prev = 1;
  i = prec;
  while (i--) {
    if (mpz_tstbit (z, i)) {
      if (pos - prev > 255) {
        printf ("bigger than a byte\n");
        abort ();
      }
      byte = pos - prev;
      if (fwrite (&byte, 1, 1, fp) != 1) {
        perror ("fwrite");
        abort ();
      }
      prev = pos;
      /* printf ("%lu\n", pos); */
    } else {
      /* printf ("0"); */
    }
    pos++;
  }
  if (fclose(fp) != 0) {
    perror ("error closing");
    abort ();
  }

  mpz_clear (z);

  if (asprintf (&command, "ls -l %s", filename) < 0) {
    perror ("asprintf");
    abort ();
  }
  if (system (command) != 0) abort();

  if (asprintf (&command, "gzip -9f %s", filename) < 0) {
    perror ("asprintf");
    abort ();
  }
  printf ("%s\n", command);
  if (system (command) != 0) abort();

  if (asprintf (&command, "ls -l %s.gz", filename) < 0) {
    perror ("asprintf");
    abort ();
  }
  if (system (command) != 0) abort();
  printf ("\n");
}

int
main (void)
{
  mpfr_t f;
  unsigned long bits = 1000000;

  mpfr_init2 (f, bits);

  mpfr_const_pi (f, GMP_RNDZ);
  output(f,"pi");
  mpfr_const_log2 (f, GMP_RNDZ);
  output(f,"ln2");

  return 0;
}
