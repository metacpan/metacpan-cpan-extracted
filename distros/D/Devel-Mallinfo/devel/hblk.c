/* Copyright 2007, 2009 Kevin Ryde

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

#include <stdio.h>
#include <malloc.h>

int
main (void)
{
  struct mallinfo m;
  void *p, *q;

#define SHOW()                                          \
  m = mallinfo();                                       \
  printf ("%8d  %d = %d + %d\n",                        \
          m.hblkhd, m.arena, m.uordblks, m.fordblks)

  SHOW();

  q = malloc (16*1024);
  SHOW();

  p = malloc (1024*1024);
  SHOW();

  free (q);
  SHOW();

  free (p);
  SHOW();

  return 0;
}
