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


# Usage: perl hilbert-lines.pl
#
# This is a bit of fun printing the HilbertCurve path in ascii.  It follows
# the terminal width if you've got Term::Size, otherwise 79x23.
#
# Enough curve is drawn to fill the whole output size, clipped when the path
# goes outside the output bounds.  You could instead stop at say
#
#     $n_hi = 2**6;
#
# to see just a square portion of the curve.
#
# The $scale variable spaces out the points.  3 apart is good, or tighten it
# up to 2 to fit more on the screen.
#
# The output has Y increasing down the screen.  It could be instead printed
# up the screen in the final output by going $y from $height-1 down to 0.
#

use 5.004;
use strict;
use Math::PlanePath::HilbertCurve;

my $width = 79;
my $height = 23;
my $scale = 3;

if (eval { require Term::Size }) {
  my ($w, $h) = Term::Size::chars();
  if ($w) { $width = $w - 1; }
  if ($h) { $height = $h - 1; }
}

my $x = 0;
my $y = 0;
my %grid;

# write $char at $x,$y in %grid
sub plot {
  my ($char) = @_;
  if ($x < $width && $y < $height) {
    $grid{$x}{$y} = $char;
  }
}

# at the origin 0,0
plot('+');

my $path = Math::PlanePath::HilbertCurve->new;
my $path_width = int($width / $scale) + 1;
my $path_height = int($height / $scale) + 1;
my ($n_lo, $n_hi) = $path->rect_to_n_range (0,0, $path_width,$path_height);

foreach my $n (1 .. $n_hi) {

  my ($next_x, $next_y) = $path->n_to_xy ($n);
  $next_x *= $scale;
  $next_y *= $scale;

  while ($x > $next_x) {  # draw to left
    $x--;
    plot ('-');
  }
  while ($x < $next_x) {  # draw to right
    $x++;
    plot ('-');
  }

  while ($y > $next_y) {  # draw up
    $y--;
    plot ('|');
  }
  while ($y < $next_y) {  # draw down
    $y++;
    plot ('|');
  }

  plot ('+');
}

foreach my $y (0 .. $height-1) {
  foreach my $x (0 .. $width-1) {
    print $grid{$x}{$y} || ' ';
  }
  print "\n";
}

exit 0;
