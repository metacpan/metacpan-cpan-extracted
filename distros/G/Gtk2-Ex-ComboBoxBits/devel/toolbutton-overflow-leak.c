/* Copyright 2011 Kevin Ryde

   This file is part of Gtk2-Ex-ComboBoxBits.

   Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option) any
   later version.

   Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>. */

#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>
#include <gtk/gtk.h>

int old_used;
gboolean my_check_memory (gpointer user_data)
{
  int used;
  struct mallinfo m;
  m = mallinfo ();
  used = m.hblkhd + m.uordblks + m.usmblks;
  if (used > old_used) {
    printf ("mallinfo increased to %d   (%d,%d,%d)\n",
            used, m.hblkhd, m.uordblks, m.usmblks);
    old_used = used;
  }
  return 1; /* continue */
}

int
main (int argc, char **argv)
{
  GtkWidget *toplevel, *toolbar;
  GtkToolItem *toolitem;

  gtk_init (&argc, &argv);
  toplevel = gtk_window_new (GTK_WINDOW_TOPLEVEL);

  toolbar = gtk_toolbar_new ();
  gtk_container_add (GTK_CONTAINER(toplevel), toolbar);

  toolitem = gtk_tool_button_new (NULL, "FJSDKLFJDSKLFJSDLK");
  gtk_toolbar_insert (GTK_TOOLBAR(toolbar), toolitem, 0);

  g_timeout_add (250, my_check_memory, NULL); /* 4 times/sec */
  
  gtk_widget_show_all (toplevel);
  gtk_main ();

  return 0;
}
