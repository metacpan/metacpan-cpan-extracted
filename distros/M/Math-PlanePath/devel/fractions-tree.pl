#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl fractions-tree.pl
#
# Print the FractionsTree paths in tree form.
#

use 5.004;
use strict;
use Math::PlanePath::FractionsTree;

foreach my $tree_type ('Kepler') {
  print "$tree_type tree\n";

  my $path = Math::PlanePath::FractionsTree->new
    (tree_type => $tree_type);

  printf "%31s", '';
  foreach my $n (1) {
    my ($x,$y) = $path->n_to_xy($n);
    print "$x/$y";
  }
  print "\n";

  printf "%15s", '';
  foreach my $n (2 .. 3) {
    my ($x,$y) = $path->n_to_xy($n);
    printf "%-32s", "$x/$y";
  }
  print "\n";

  printf "%7s", '';
  foreach my $n (4 .. 7) {
    my ($x,$y) = $path->n_to_xy($n);
    printf "%-16s", "$x/$y";
  }
  print "\n";

  printf "%3s", '';
  foreach my $n (8 .. 15) {
    my ($x,$y) = $path->n_to_xy($n);
    printf "%-8s", "$x/$y";
  }
  print "\n";

  foreach my $n (16 .. 31) {
    my ($x,$y) = $path->n_to_xy($n);
    printf "%4s", "$x/$y";
  }
  print "\n";

  print "\n";
}

exit 0;
