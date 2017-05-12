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

# Usage: perl square-numbers.pl
#
# Print the SquareSpiral numbers in a grid like
#
#       37  36  35  34  33  32  31
#       38  17  16  15  14  13  30
#       39  18   5   4   3  12  29
#       40  19   6   1   2  11  28
#       41  20   7   8   9  10  27
#       42  21  22  23  24  25  26
#       43  44  45  46  47 ...
#
# See numbers.pl for a more sophisticated program.


use 5.004;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::SquareSpiral;

my $n_max = 115;

my $path = Math::PlanePath::SquareSpiral->new;
my %rows;
my $x_min = 0;
my $x_max = 0;
my $y_min = 0;
my $y_max = 0;

foreach my $n ($path->n_start .. $n_max) {
  my ($x, $y) = $path->n_to_xy ($n);
  $rows{$x}{$y} = $n;

  $x_min = min($x_min, $x);
  $x_max = max($x_max, $x);
  $y_min = min($y_min, $y);
  $y_max = max($y_max, $y);
}

my $cellwidth = length($n_max) + 2;

foreach my $y (reverse $y_min .. $y_max) {
  foreach my $x ($x_min .. $x_max) {
    printf ('%*s', $cellwidth, $rows{$x}{$y} || '');
  }
  print "\n";
}

exit 0;
