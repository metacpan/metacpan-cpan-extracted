# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-GD.
#
# Image-Base-GD is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-GD is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-GD.  If not, see <http://www.gnu.org/licenses/>.

CFLAGS := -Wall -g $(shell gdlib-config --cflags)
# LOADLIBES := -lgd $(shell gdlib-config --libs)
# LOADLIBES := /so/gd/libgd2-2.0.36~rc1~dfsg/debian/tmp-libgd2-xpm/usr/lib/libgd.a $(shell gdlib-config --libs)
LOADLIBES := /so/gd/libgd2-2.0.36~rc1~dfsg/.libs/libgd.a $(shell gdlib-config --libs)


exe-gd-format: exe-gd-format.c
	gcc -I /so/gd/libgd-1.3 gd-format.c \
	  /so/gd/libgd-1.3/libgd.a -lm \
	  -o exe-gd-format
