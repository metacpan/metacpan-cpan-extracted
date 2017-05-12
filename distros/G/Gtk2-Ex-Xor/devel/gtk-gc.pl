#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Xor.
#
# Gtk2-Ex-Xor is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Xor is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Xor.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Gtk2 '-init';
use Scalar::Util;

my $toplevel = Gtk2::Window->new('toplevel');
$toplevel->show;

my $win = $toplevel->window;
my $depth = $win->get_depth;
my $colormap = $win->get_colormap;

my $gc1;
{
  my $pixmap = Gtk2::Gdk::Pixmap->new ($win, 1, 1, $depth);
  $gc1 = Gtk2::GC->get ($depth, $colormap,  {tile=>$pixmap});
}

my $gc2;
{
  my $pixmap = Gtk2::Gdk::Pixmap->new ($win, 1, 1, $depth);
  $gc2 = Gtk2::GC->get ($depth, $colormap,  {tile=>$pixmap});
  Scalar::Util::weaken ($pixmap);
  print $pixmap,"\n";
}

print "$gc1\n";
print "$gc2\n";
