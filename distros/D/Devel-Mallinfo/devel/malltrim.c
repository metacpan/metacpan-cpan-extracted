/* Copyright 2010, 2011 Kevin Ryde

   This file is part of Devel-Mallinfo.

   Devel-Mallinfo is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Devel-Mallinfo is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <malloc.h>
#include <unistd.h>

#define PCOUNT  50000

int
main (void)
{
  int ret;
  struct mallinfo m;
  static char *p[PCOUNT];
  int i;

  mallopt (M_TRIM_THRESHOLD, 1000000);
  mallopt (M_TOP_PAD, 1);
  mallopt (M_MMAP_THRESHOLD, 10000000);

  /* malloc (1); */
  /* m = mallinfo(); */
  /* printf ("malloc:  arena %d  keepcost %d  fordblks %d  uord=%d,usm=%d  hblkhd %d\n", */
  /*         m.arena, m.keepcost, m.fordblks, m.uordblks, m.usmblks, m.hblkhd); */

  for (i = 0; i < PCOUNT; i++)
    p[i] = malloc (256);
  m = mallinfo();
  printf ("malloc:  arena %d  keepcost %d  fordblks %d  uord=%d,usm=%d  hblkhd %d\n",
          m.arena, m.keepcost, m.fordblks, m.uordblks, m.usmblks, m.hblkhd);

  for (i = PCOUNT-1; i >= 0; i--)
    free(p[i]);
  m = mallinfo();
  printf ("malloc:  arena %d  keepcost %d  fordblks %d  uord=%d,usm=%d  hblkhd %d\n",
          m.arena, m.keepcost, m.fordblks, m.uordblks, m.usmblks, m.hblkhd);

  ret = malloc_trim(0);
  printf ("ret %d\n", ret);

  m = mallinfo();
  printf ("keepcost %d\n", m.keepcost);

  ret = malloc_trim(0);
  printf ("ret %d\n", ret);

  m = mallinfo();
  printf ("keepcost %d\n", m.keepcost);

  return 0;
}
