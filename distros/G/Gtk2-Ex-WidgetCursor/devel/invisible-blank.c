/* Copyright 2009, 2010 Kevin Ryde

   This file is part of Gtk2-Ex-WidgetCursor.

   Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option)
   any later version.

   Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdlib.h>
#include <gtk/gtk.h>

int
main (int argc, char **argv)
{
  GdkDisplay *display;
  GdkCursor *cursor;

  gtk_init (&argc, &argv);
  display = gdk_display_get_default();

  cursor = gdk_cursor_new_for_display (display, GDK_BLANK_CURSOR);
  printf ("%p\n", cursor);

  cursor = gdk_cursor_new_for_display (display, GDK_BLANK_CURSOR);
  printf ("%p\n", cursor);

  return 0;
}
