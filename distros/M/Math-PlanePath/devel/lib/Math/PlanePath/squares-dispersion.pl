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
use Math::NumSeq::Squares;

# uncomment this to run the ### lines
#use Smart::Comments;


# diagonals slope=2

# Classic Sequences
# http://oeis.org/classic.html
#
# A082156

# 1  4  9 16  25        d^2
#   +3 +5 +7  +9
#
# 2  6 12 20  30       (d^2 + 3 d + 2)
#   +4 +6 +8 +10
#
# 3  8 15 24  35       (d^2 + 4 d + 3)
#   +5 +7 +9 +11
#
# 5 11 19 29 41        (d^2 + 5 d + 5)
#   +6 +8 +10 +12
#
# 7 14 23 34 47        (d^2 + 6 d + 7)
#   +7 +9 +11 +13

{
  # rows
  my @non_squares = (0);
  foreach my $n (0 .. 100) {
    push @non_squares, $n if ! is_square($n);
  }
  print join(',',@non_squares),"\n";

  #  1  4  9 16 25 36 49 64 81 100 121 144
  #  2  6 12 20 30 42 56 72 90 110 132
  #  3  8 15 24 35 48 63 80 99 120
  #  5 11 19 29 41 55 71 89 109
  #  7 14 23 34 47 62 79
  # 10 18 28 40 54 70
  # 13 22 33 46 61
  # 17 27 39 53
  # 21 32 45
  # 26 38
  # 31
  #

  #        0  1  2  3  4  5  6  7   8   9  10
  my @o = (0, 0, 0, 1, 2, 4, 6, 9, 12, 16, 20);
  #          +0 +0 +1 +1 +2 +2 +3  +3  +4  +4

  # (2x+y+2)(2x+y-2) = 4xx+4xy+yy

  # N = (x+1)**2 + (x+1)*y + (y*y - 2*y + odd)/4
  #   = x^2 + 2x + 1+ xy + y + y^2/4 - y/2 + odd/4
  #   = x^2 + 2x + 1+ xy + y^2/4 + y/2 + odd/4
  #   = (4x^2 + 8x + 4+ 4xy + y^2 + 2y + odd)/4

  #   = (4x^2 + 4xy + 8x  + y^2 + 2y + 4 + odd)/4
  #   = ((2x+y+2)^2 + 2y+odd) / 4

  my @seen;
  foreach my $y (0 .. 10) {
    foreach my $x (0 .. 14) {
      my $odd = ($y & 1);
      my $o = ($odd
               ? ($y*$y - 2*$y + 1)/4
               : ($y*$y - 2*$y)/4);     # even
       if ($o != $o[$y]) { die }
      #my $o = ($o[$y]||0);
      my $n = ($x+1)**2 + ($x+1)*$y + $o;
      # my $n = ((2*$x+$y+2)**2 + 2*$y + $odd) / 4;
      my $dup = ($seen[$n]++ ? '*' : ' ');
      printf ' %3d%s', $n, $dup;
    }
    print "\n";
  }
  exit 0;
}
{
  # non-squares
  my $next_root = 1;
  my $next_square = 1;
  my $prev = 0;
  foreach my $n (1 .. 50) {
    my $non = non_square($n);
    if ($non != $prev+1) {
      print "--\n";
    }
    my $sq = is_square($non) ? '  ***' : '';
    print "$non$sq\n";
    $prev = $non;
  }
  sub non_square {
    my ($n) = @_;
    return $n + int(sqrt($n))-1;
  }
  sub is_square {
    my ($n) = @_;
    return Math::NumSeq::Squares->pred($n);
  }
  exit 0;
}

