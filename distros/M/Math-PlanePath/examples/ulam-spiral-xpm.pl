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


# Usage: perl ulam-spiral-xpm.pl >/tmp/foo.xpm     # write image file
#        xzgv /tmp/foo.xpm                         # view file
#
# This is a bit of fun drawing Ulam's spiral of primes in the SquareSpiral
# path.  The output is XPM format (which is plain text) and any good image
# viewer program should display it.
#
# Optional args
#
#     perl ulam-spiral-xpm.pl SIZE
# or
#     perl ulam-spiral-xpm.pl SIZE SCALE
#
# make the image SIZExSIZE pixels, and SCALE to expand each point to a
# SCALExSCALE square instead of a single pixel.
#

use 5.004;
use strict;
use Math::PlanePath::SquareSpiral;

my $size = 200;
my $scale = 1;

if (@ARGV >= 2) {
  $scale = $ARGV[1];
}
if (@ARGV >= 1) {
  $size = $ARGV[0];
}

my $path = Math::PlanePath::SquareSpiral->new;
my $x_origin = int($size / 2);
my $y_origin = int($size / 2);

my ($n_lo, $n_hi)
  = $path->rect_to_n_range (-$x_origin, -$y_origin,
                            -$x_origin+$size, -$y_origin+$size);

# Find the prime numbers 2 to $n_hi by sieve of Eratosthenes.
# Could also use Math::Prime::TiedArray or Math::Prime::XS.
#
my @primes = (0,    # 0
              0,    # 1
              1,    # 2  prime
              1,    # 3  prime
              (0,1) x ($n_hi/2));  # rest alternately even/odd
my $i = 3;
foreach my $i (3 .. int(sqrt($n_hi)) + 1) {
  next unless $primes[$i];
  foreach (my $j = 2*$i; $j <= $n_hi; $j += $i) {
    $primes[$j] = 0;
  }
}

# Draw the primes into an array of rows strings.
#
my @rows = (' ' x $size) x $size;

foreach my $n ($n_lo .. $n_hi) {
  next unless $primes[$n];

  my ($x, $y) = $path->n_to_xy ($n);

  $x = $x + $x_origin;
  $y = $y_origin - $y;  # inverted

  # $n_hi is an over-estimate in general, check x,y actually in desired size
  if ($x >= 0 && $x < $size && $y >= 0 && $y < $size) {
    substr ($rows[$y], $x,1) = '*';
  }
}

# Expand @rows points by $scale, horizontally and vertically.
#
if ($scale > 1) {
  foreach (@rows) {
    s{(.)}{$1 x $scale}eg;             # expand horizontally
  }
  @rows = map { ($_) x $scale} @rows;  # expand vertically

  $size *= $scale;
}

# XPM format is easy to print.
# Output is about 1 byte per pixel.
#
print <<"HERE";
/* XPM */
static char *ulam_spiral_xpm_pl[] = {
"$size $size 2 1",
" 	c black",
"*	c white",
HERE
foreach my $row (@rows) {
  print "\"$row\",\n";
}
print "};\n";

exit 0;
