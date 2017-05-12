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


use 5.004;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::GcdRationals;

my $height = 20;

my $path = Math::PlanePath::GcdRationals->new;
my $n_lo = $path->n_start;
my $n_hi = $height*($height+1)/2 - 1;

my @array;
foreach my $n ($n_lo .. $n_hi) {
  my ($x,$y) = $path->n_to_xy ($n);
  my $int = int($x/$y);
  if ($int >= 10) { $int = 'z' }
  $array[$y]->[$x] = $int;
}

my $cell_width = max (map {length}
                      grep {defined}
                      map {@$_}
                      grep {defined}
                      @array);
foreach my $y (reverse 1 .. $#array) {
  foreach my $x (1 .. $#{$array[$y]}) {
    my $int = $array[$y]->[$x];
    if (! defined $int) { $int = ''; }
    printf '%*s', $cell_width, $int;
  }
  print "\n";
}



print "\n";

foreach my $y (reverse 1 .. 20) {
  foreach my $x (1 .. $y) {
    my $int = Math::PlanePath::GcdRationals::_gcd($x,$y) - 1;
    if ($int >= 10) { $int = 'z' }
    print "$int";
  }
  print "\n";
}

exit 0;
