# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


grandom: grandom.c Makefile
	gcc -Wall -g `pkg-config --cflags glib-2.0 gtk+-2.0` grandom.c \
	   `pkg-config --libs glib-2.0 gtk+-2.0` -o grandom

grandom-zero: grandom-zero.c Makefile
	gcc -Wall -O2 `pkg-config --cflags glib-2.0 gtk+-2.0` grandom-zero.c \
	   `pkg-config --libs glib-2.0 gtk+-2.0` -o grandom-zero

grandom-array: grandom-array.c Makefile
	gcc -Wall -O2 `pkg-config --cflags glib-2.0 gtk+-2.0` grandom-array.c \
	   `pkg-config --libs glib-2.0 gtk+-2.0` -o grandom-array
