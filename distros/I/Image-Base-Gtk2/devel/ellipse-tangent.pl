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

use 5.008;
use strict;
use warnings;
use List::Util 'min';

my $a = 100;
my $b = 5;
my $l = 3;
my $A = $a + $l;
my $B = $b + $l;

foreach my $x (1 .. $a) {
  my $x = $x - .01;
  my $y = $b * sqrt(1 - ($x/$a)**2);
  my $slope = ($b/$a)**2 * $x/$y;
  my $angle = atan2($b*$b*$x, $a*$a*$y);
  my $w = $l * sin($angle);
  my $h = $l * cos($angle);
  my $X = $x + $w;
  my $Y = $y + $h;
  my $E = ($X/$A)**2 + ($Y/$B)**2;
  printf "%.2f,%.2f  %.2f %.2f %.2f,%.2f  %.3f\n",
    $x,$y, $slope, $angle, $w,$h, $E;
}
exit 0;
