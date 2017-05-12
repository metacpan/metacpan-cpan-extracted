/* Copyright 2013 Kevin Ryde

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
#include <string.h>
#include <time.h>
#include <unistd.h>

#define LIKELY(cond)    __builtin_expect ((cond) != 0, 1)
#define UNLIKELY(cond)  __builtin_expect ((cond) != 0, 0)

unsigned want_flimsy[] = {
  11, 13, 19, 22, 23, 25, 26, 27, 29, 37, 38, 39, 41, 43, 44, 46, 47, 50,   
  52, 53, 54, 55, 57, 58, 59, 61, 67, 71, 74, 76, 77, 78, 79, 81, 82, 83,   
  86, 87, 88, 91, 92, 94, 95, 97, 99, 100, 101, 103, 104, 106, 107, 108,    
  109, 110, 111, 113, 114, 115, 116, 117, 118, 119, 121
};
int
want_is_flimsy (unsigned n)
{
  int i;
  for (i = 0; i < sizeof(want_flimsy)/sizeof(want_flimsy[0]); i++) {
    if (want_flimsy[i] == n) {
      return 1;
    }
  }
  return 0;
}

const int verbose = 0;
const unsigned limit = 0;
/* const unsigned limit = 5*140000000; */
  /* limit = 0xFFFFFFF; */

                                                           
int
is_flimsy (unsigned n)
{
  int n_count = __builtin_popcount (n);
  if (n_count == 1) {
    return 0;
  }
  
  register unsigned long long p = n;
  unsigned k;
  for (k = 2; LIKELY (k != limit); k++) {
    p += n;  /* p = k*n */
    int p_count = __builtin_popcountll (p);
    if (UNLIKELY (p_count < n_count)) {
      if (verbose) {
        printf ("n=%u=%X=%d found k=%u=%X product %#LX=%d\n",
                n, n, n_count, k, k, p, p_count);
      }
      return 1;
    }
  }
  return 0;
}

int
main (int argc, char **argv)
{
  static int table[200];
  
  if (nice(20) < 0) {
    perror("nice");
    abort();
  }

  unsigned n = 1;
  if (argc > 1) {
    n = atoi(argv[1]);
  }

  printf ("starting from %u\n", n);
  printf ("limit %#08X\n", limit);

  for (; n < 200; n++) {
    int want = want_is_flimsy(n);
    int got = is_flimsy(n);
    char *diff = (want==got ? "" : "  ********");
    printf ("%u  got=%d want=%d%s\n", n, got, want, diff);
    table[n] = got;
  }

  for (n = 1; n < 200; n++) {
    if (table[n]) {
      printf ("%d, ", n);
    }
  }
  printf ("\n");
  return 0;
}
