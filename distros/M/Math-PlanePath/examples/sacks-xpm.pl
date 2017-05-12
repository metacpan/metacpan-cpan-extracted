#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl sacks-xpm.pl >/tmp/foo.xpm     # write image file
#        xgzv /tmp/foo.xpm                   # view file
#
# This spot of code generates a big .xpm file showing all points of the
# SacksSpiral.  XPM is a text format and can be generated quite easily as
# row strings.  Use a graphics viewer program to look at it.
# 

use 5.004;
use strict;
use POSIX ();
use Math::PlanePath::SacksSpiral;

my $width = 800;
my $height = 600;
my $spacing = 10;

my $path = Math::PlanePath::SacksSpiral->new;
my $x_origin = int($width / 2);
my $y_origin = int($height / 2);
my $n_max = ($x_origin/$spacing+2)**2 + ($y_origin/$spacing+2)**2;

my @rows = (' ' x $width) x $height;

foreach my $n ($path->n_start .. $n_max) {
  my ($x, $y) = $path->n_to_xy ($n);
  $x *= $spacing;
  $y *= $spacing;

  $x = $x + $x_origin;
  $y = $y_origin - $y;  # inverted

  $x = POSIX::floor ($x + 0.5); # round
  $y = POSIX::floor ($y + 0.5);

  if ($x >= 0 && $x < $width && $y >= 0 && $y < $height) {
    substr ($rows[$y], $x,1) = '*';
  }

}

print <<"HERE";
/* XPM */
static char *sacks_xpm_pl[] = {
"$width $height 2 1",
" 	c black",
"*	c white",
HERE
foreach my $row (@rows) {
  print "\"$row\",\n";
}
print "};\n";

exit 0;
