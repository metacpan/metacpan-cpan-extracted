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

int
main (int argc, char **argv)
{
  guint32 i = 0;
  time_t t1 = time(NULL);

  /* putenv ("G_RANDOM_VERSION=2.0"); */

  if (argv[1]) {
    i = atoi(argv[1]);
  }
  
  do {
    g_random_set_seed (i);
    if (g_random_int() == 0) {
      printf ("zero from %u\n", i);
    }
    i++;

    if ((i & 0xFFFF) == 0) {
      time_t t2 = time(NULL);
      if (t1 != t2) {
        printf ("upto %u\r", i);
        fflush (stdout);
        t1 = t2;
      }
    }

  } while (i != 0);

  return 0;
}
