/* Copyright 2009, 2010, 2011 Kevin Ryde

   This file is part of Gtk2-Ex-Xor.

   Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any later
   version.

   Gtk2-Ex-Xor is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdlib.h>
#include <gtk/gtk.h>

int
main (int argc, char **argv)
{
  gtk_init (&argc, &argv);

  GdkWindow *window = gdk_get_default_root_window ();
  gint depth = gdk_drawable_get_depth (GDK_DRAWABLE (window));
  GdkColormap *colormap = gdk_window_get_colormap (GDK_WINDOW (window));

  static GdkColor color;
  color.red = 0;
  color.blue = 0;
  color.green = 0;
  color.pixel = 0;

  static GdkGCValues values;
  values.foreground = &color;
  GdkGC *gc = gtk_gc_get (depth, colormap, &values, GDK_GC_FOREGROUND);
  printf ("%p\n", gc);

  return 0;
}
