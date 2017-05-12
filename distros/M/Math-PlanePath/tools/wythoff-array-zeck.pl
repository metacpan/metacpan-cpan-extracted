#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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


# Usage: perl wythoff-array-zeck.pl
#
# Print some of the Wythoff array with N values in Zeckendorf base.
#

use 5.010;
use strict;
use List::Util 'max';
use Math::NumSeq::Fibbinary;
use Math::PlanePath::WythoffArray;

my $class = 'Math::PlanePath::WythoffArray';
# $class = 'Math::PlanePath::WythoffDifference';
# $class = 'Math::PlanePath::WythoffPreliminaryTriangle';

my $width = 4;
my $height = 9;

eval "require $class";
my $path = $class->new;
my $fib = Math::NumSeq::Fibbinary->new;

my @z;
my @colwidth;
foreach my $x (0 .. $width) {
  foreach my $y (0 .. $height) {
    my $n = $path->xy_to_n ($x,$y);
    my $z = $n && $fib->ith($n);
    my $zb = $z && sprintf '%b', $z;
    # $zb = $n && sprintf '%d', $n;
    if (! defined $n) { $zb = ''; }
    $z[$x][$y] = $zb;
    $colwidth[$x] = max($colwidth[$x]||0, length($z[$x][$y]));
  }
}

my $ywidth = length($height);
foreach my $y (reverse 0 .. $height) {
  printf "%*d |", $ywidth, $y;
  foreach my $x (0 .. $width) {
    my $value = $z[$x][$y] // '';
    printf " %*s", $colwidth[$x], $z[$x][$y];
  }
  print "\n";
}

printf "%*s +-", $ywidth, '';
foreach my $x (0 .. $width) {
  print '-' x ($colwidth[$x]+1);
}
print "\n";

printf "%*s  ", $ywidth, '';
foreach my $x (0 .. $width) {
  printf " %*s", $colwidth[$x], $x;
}
print "\n";

exit 0;
