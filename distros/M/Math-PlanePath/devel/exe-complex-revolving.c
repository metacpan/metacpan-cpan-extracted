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
binary (unsigned long long n)
{
  static char str[sizeof(n)*8+1];
  int pos = sizeof(str)-1;
  do {
    str[pos] = (n&1)+'0';
    n >>= 1;
    pos--;
  } while (n);
  return str+pos+1;
}

int
main (void)
{
  int level;

  for (level = 0; level < 8*sizeof(my_unsigned)-1; level++) {

    unsigned long long min_h = ~0ULL;
    my_unsigned min_n = 0;
    my_signed min_x = 0;
    my_signed min_y = 0;

    {
      my_unsigned lo = (my_unsigned)1 << level;
      my_unsigned hi = (my_unsigned)1 << (level+1);

      /* printf ("%2d lo=%lu hi=%lu\n", level, lo, hi); */

      my_unsigned n;
      for (n = lo; n < hi; n++) {

        my_signed x = 0;
        my_signed y = 0;
        my_signed bx = 1;
        my_signed by = 0;

        my_unsigned bits;
        for (bits = n; bits != 0; bits >>= 1) {
          if (bits & 1) {
            x += bx;
            y += by;

            /* (bx,by) * i, rotate +90 */
            my_signed new_bx = -by;
            my_signed new_by = bx;
            bx = new_bx;
            by = new_by;
          }

          /* (bx,by) * (i+1) */
          my_signed new_bx = bx-by;
          my_signed new_by = bx+by;
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
    char *binary_str = binary(min_h);
    int binary_len = strlen(binary_str);
    printf (" %s [%d]", binary(min_h), binary_len);
    printf ("\n");
    /* printf ("\n"); */
  }

  return 0;
}
