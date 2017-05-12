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

#include <glib.h>
#include <gtk/gtk.h>

/* #define N 624 */
/* struct _GRand */
/* { */
/*   guint32 mt[N]; /\* the array for the state vector  *\/ */
/*   guint mti;  */
/* }; */
/*   printf ("%d\n", sizeof(struct _GRand)); */

/* guint32 */
/* g_random_int (void) */
/* { */
/*   return 0; */
/* } */

int
main (int argc, char **argv)
{
  gtk_init (&argc, &argv);

  g_random_set_seed (0);
  printf ("rand %d\n", g_random_int ());

  GtkListStore *l = gtk_list_store_new(1, G_TYPE_STRING);
  GtkTreeIter i;
  gtk_list_store_append (l, &i);
  printf ("stamp %d\n", i.stamp);


  for (;;) {
    if (g_random_int() == 0)
      {
        printf ("zero\n");
        break;
      }
  }

  return 0;
}
     
