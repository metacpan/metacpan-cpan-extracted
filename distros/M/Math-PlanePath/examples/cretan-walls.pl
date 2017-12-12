#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


# Usage: perl cretan-walls.pl
#
# This is a bit of fun carving out the CretanLabyrinth from a solid block of
# "*"s, thus leaving those "*"s representing the walls of the labyrinth.
#
# The $spacing variable is how widely to spread the path, for thicker walls.
# The $width,$height sizes are chosen to make a whole 4-way cycle.
#
# The way the arms align means the entrance to the labyrinth is at the
# bottom right corner.  In real labyrinths its usual to omit the lower right
# bit of wall so the entrance is in the middle of the right side.
#

use 5.004;
use strict;
use Math::PlanePath::CretanLabyrinth;

my $spacing = 2;
my $width = $spacing * 14 - 1;
my $height = $spacing * 16 - 1;

my $path = Math::PlanePath::CretanLabyrinth->new;
my $x_origin = int($width / 2) + $spacing;
my $y_origin = int($height / 2);

my @rows = ('*' x $width) x $height;  # array of strings

sub plot {
  my ($x,$y,$char) = @_;
  if ($x >= 0 && $x < $width
      && $y >= 0 && $y < $height) {
    substr($rows[$y], $x, 1) = $char;
  }
}

my ($n_lo, $n_hi)
  = $path->rect_to_n_range (-$x_origin,-$y_origin, $x_origin,$y_origin);

my $x = $x_origin;
my $y = $y_origin;
plot($x,$y,'_');

foreach my $n ($n_lo+1 .. $n_hi) {
  my ($next_x, $next_y) = $path->n_to_xy ($n);
  $next_x *= $spacing;
  $next_y *= $spacing;

  $next_x += $x_origin;
  $next_y += $y_origin;

  while ($x != $next_x) {
    $x -= ($x <=> $next_x);
    plot($x,$y,' ');
  }
  while ($y != $next_y) {
    $y -= ($y <=> $next_y);
    plot($x,$y,' ');
  }
}

foreach my $row (reverse @rows) {
  print "$row\n";
}

exit 0;
