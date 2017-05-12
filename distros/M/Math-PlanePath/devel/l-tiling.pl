#!/usr/bin/perl -w

# Copyright 2011, 2013 Kevin Ryde

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

use strict;
use Math::PlanePath::LTiling;



#  LTiling A112539 Half-baked Thue-Morse: at successive steps the sequence or its bit-inverted form is appended to itself.

{
  # A139351 count 1-bits at even positions
  # A139352 count 1-bits at odd positions

  # A112539  1,0,1,0,0,1,0,1,1,0,1,0,0,1,0,1,0,1,0,1,1,0,1,0,   OFFSET=1
  # A139351  0,1,0,1,1,2,1,2,0,1,0,1,1,2,1,2,1,2,1,2,2,3,2,3,   OFFSET=0

  # A139352  0,0,1,1,0,0,1,1,1,1,2,2,1,1,2,2,0,0,1,1,0,0,1,1,   OFFSET=0
 
  sub count_even_1_bits {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += ($n & 1);
      $n >>= 2;
    }
    return $count;
  }

  foreach my $n (2 .. 30) {
    print count_even_1_bits($n),",";
  }
  print "\n";
  exit 0;
}

{
  # X,Y parity
  # block 0, 2 unchanged    00 10
  # block 1, 3 flip         01 11
  # so flip by every second bit starting from lowest
  #
  # "middle" invert each
  # "ends"   duplicate each
  # "all"    011 base then floor(n/3) inversions

  my $path = Math::PlanePath::LTiling->new;
  foreach my $n ($path->n_start .. 70) {
    my ($x,$y) = $path->n_to_xy($n);
    print(($x+$y)%2);
  }
  print "\n";

  $path = Math::PlanePath::LTiling->new (L_fill => 'left');
  foreach my $n ($path->n_start .. 70) {
    my ($x,$y) = $path->n_to_xy($n);
    print(($x+$y)%2);
  }
  print "\n";

  $path = Math::PlanePath::LTiling->new (L_fill => 'upper');
  foreach my $n ($path->n_start .. 70) {
    my ($x,$y) = $path->n_to_xy($n);
    print(($x+$y)%2);
  }
  print "\n";

  $path = Math::PlanePath::LTiling->new (L_fill => 'ends');
  for (my $n = $path->n_start+0; $n < 70; $n+=2) {
    my ($x,$y) = $path->n_to_xy($n);
    print(($x+$y)%2);
  }
  print "\n";

  exit 0;
}


#
#     +-------+
#     |       |
#     |       |
#     |       |
#     |   +---+
#     |   |   |
#     |   | +-+
#     |   | | |
#     +---+-| +-+-+---+
#     |   | |   | |   |
#     | +-| +---+ |   |
#     | | |   |   |   |
#     +-| +---+---+   |
#     | |   | |       |
#     | +---+ |       |
#     |   |   |       |
#     +---+---+-------+
#
#
#
