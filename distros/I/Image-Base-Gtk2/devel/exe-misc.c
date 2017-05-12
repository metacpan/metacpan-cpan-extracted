/* Copyright 2010 Kevin Ryde

   This file is part of Image-Base-Gtk2.

   Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Image-Base-Gtk2 is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License along
   with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.  */

#include <stdio.h>
#include <stdlib.h>
#include <gtk-2.0/gtk/gtk.h>

int
main (int argc, char **argv)
{
  static guchar data[99999];
  gint height = 8;
  gint rowstride = 256;

  gdk_init (&argc, &argv);
  GdkPixbuf *pixbuf = gdk_pixbuf_new_from_data (data,
                                                GDK_COLORSPACE_RGB,
                                                0,
                                                8,
                                                2,height,
                                                rowstride,
                                                NULL,
                                                NULL);
  printf ("%p\n", gdk_pixbuf_get_pixels(pixbuf));

  GdkPixbuf *p2 = gdk_pixbuf_copy (pixbuf);
  printf ("%p\n", gdk_pixbuf_get_pixels(p2));

  printf ("%p\n", gdk_pixbuf_get_pixels(p2) + rowstride*height);

  return 0;
}
