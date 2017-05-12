#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.

use Gtk2;
my $data = "\0" x 999999;
my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
  ($data,
   'rgb', # colorspace
   0,     # has_alpha
   8,     # bits per sample
   2,2,   # width,height
   256);  # rowstride

my $p2 = $pixbuf->copy;
$p2->get_pixels;
