/* Copyright 2012 Kevin Ryde

   This file is part of Math-PlanePath.

   Math-PlanePath is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Math-PlanePath is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

typedef unsigned long my_unsigned;

typedef long long my_signed;
#define MY_SIGNED_ABS llabs

#define HYPOT_LIMIT 0x7FFFFFFF

char *
to_base (unsigned long long n, int radix)
{
  static char str[256];
  static char dstr[256];
  int pos = sizeof(str)-1;
  do {
    int digit = n % radix;
    n /= radix;
    sprintf (dstr, "[%d]", digit);
    int dlen = strlen(dstr);
    pos -= dlen;
    memcpy (str+pos, dstr, dlen);
  } while (n);
  return str+pos;
}

int
base_len (unsigned long long n, int radix)
{
  int len = 0;
  while (n) {
    n /= radix;
    len++;
  }
  return len;
}

int
main (void)
{
  int realpart, level;

  for (realpart = 3; realpart < 10; realpart++) {
    int norm = realpart*realpart + 1;
    int level_limit = 20;
    if (realpart == 2) level_limit = 10;
    if (realpart == 3) level_limit = 9;
    if (realpart == 4) level_limit = 9;
    
    for (level = 0; level < level_limit; level++) {

      unsigned long long min_h = ~0ULL;
      my_unsigned min_n = 0;
      my_signed min_x = 0;
      my_signed min_y = 0;

      {
        my_unsigned lo = pow(norm, level);
        my_unsigned hi = lo * norm;

        printf ("%2d lo=%lu hi=%lu\n", level, lo, hi);

        my_unsigned n;
        for (n = lo; n < hi; n++) {

          my_signed x = 0;
          my_signed y = 0;
          my_signed bx = 1;
          my_signed by = 0;

          my_unsigned digits = n;
          while (digits != 0) {
            int digit = digits % norm;
            digits /= norm;

            x += digit * bx;
            y += digit * by;

            /* (bx,by) = (bx + i*by)*(i+$realpart) */
            my_signed new_bx = bx*realpart - by;
            my_signed new_by = bx + by*realpart;
            bx = new_bx;
            by = new_by;
          }

          unsigned long long abs_x = MY_SIGNED_ABS(x);
          unsigned long long abs_y = MY_SIGNED_ABS(y);

          if (abs_x > HYPOT_LIMIT
              || abs_y > HYPOT_LIMIT) {
            continue;
          }

          unsigned long long h = abs_x*abs_x + abs_y*abs_y;

          /* printf ("%2d %lu %Ld,%Ld %LX\n", level, n, x,y, h); */

          if (h < min_h) {
            min_h = h;
            min_n = n;
            min_x = abs_x;
            min_y = abs_y;
          }
        }
      }
    
      /* printf ("%lX %Ld,%Ld %s\n", min_n, min_x,min_y, */
      /*         binary(min_h)); */
      printf ("%2d", level);
      printf (" %s [%d]", to_base(min_h,norm), base_len(min_h,norm));
      printf ("\n");
      /* printf ("\n"); */
    }
  }

  return 0;
}
