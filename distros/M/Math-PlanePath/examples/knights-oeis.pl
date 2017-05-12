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


# Usage: perl knights-oeis.pl
#
# This spot of code prints sequence A068608 of Sloane's On-Line Encyclopedia
# of Integer Sequences
#
#     http://oeis.org/A068608
#
# which is the infinite knight's tour path of Math::PlanePath::KnightSpiral
# with the X,Y positions numbered according to the SquareSpiral and thus
# giving an integer sequence
#
#     1, 10, 3, 16, 19, 22, 9, 12, 15, 18, 7, 24, 11, 14, ...
#
# All points in the first quadrant are reached by both paths, so this is a
# permutation of the integers.
#
# There's eight variations on the sequence.  2 directions clockwise and
# anti-clockwise and 4 sides to start from relative to the side the square
# spiral numbering starts from.
#
#     A068608
#     A068609
#     A068610
#     A068611
#     A068612
#     A068613
#     A068614
#     A068615
#

use 5.004;
use strict;
use Math::PlanePath::KnightSpiral;
use Math::PlanePath::SquareSpiral;

my $knights = Math::PlanePath::KnightSpiral->new;
my $square  = Math::PlanePath::SquareSpiral->new;

foreach my $n ($knights->n_start .. 20) {
  my ($x, $y) = $knights->n_to_xy ($n);
  my $sq_n = $square->xy_to_n ($x, $y);
  print "$sq_n, ";
}
print "...\n";
exit 0;
