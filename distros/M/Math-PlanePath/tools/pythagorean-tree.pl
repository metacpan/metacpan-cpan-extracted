#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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


# Usage: perl pythagorean-tree.pl
#
# Print tree diagrams used in the Math::PlanePath::PythagoreanTree docs.
#

use 5.010;
use strict;
use Math::PlanePath::PythagoreanTree;

foreach my $tree_type ('UAD','UArD','FB','UMT') {
  my $str = <<"HERE";
    tree_type => "$tree_type"

                      +-> 00005
          +-> 00002 --+-> 00006
          |           +-> 00007
          |
          |           +-> 00008
    001 --+-> 00003 --+-> 00009
          |           +-> 00010
          |
          |           +-> 00011
          +-> 00004 --+-> 00012
                      +-> 00013

HERE
    my $path = Math::PlanePath::PythagoreanTree->new(tree_type => $tree_type,
                                                    coordinates => 'AB');
    $str =~ s{(\d+)}
             {
               my ($x,$y) = $path->n_to_xy($1);
               my $len = length($1);
               sprintf '%-*s', $len, "$x,$y";
             }ge;
  print $str;
}
