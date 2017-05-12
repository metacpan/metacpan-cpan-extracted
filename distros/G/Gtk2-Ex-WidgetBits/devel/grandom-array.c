/* Copyright 2010 Kevin Ryde

   This file is part of Gtk2-Ex-WidgetBits.

   Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option)
   any later version.

   Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>. */

#include <stdio.h>
#include <stdlib.h>
#include <glib.h>

#define N 624

struct _GRand
{
  guint32 mt[N]; /* the array for the state vector  */
  guint mti;
};

int
main (int argc, char **argv)
{
  static guint32 seed[2*N] = {
    0
    ,
  };

  GRand *r = g_rand_new_with_seed_array (seed, 2*N);

  struct _GRand *rs = (struct _GRand *) r;
  printf ("%X\n", rs->mt[1]);

  return 0;
}
