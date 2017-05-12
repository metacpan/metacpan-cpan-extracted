#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # total count xenodromes of each radix
  # 4 + 4*4 + 4*4*3 + 4*4*3*2 + 4*4*3*2*1 = 260
  # 5 + 5*5 + 5*5*4 + 5*5*4*3 + 5*5*4*3*2 + 5*5*4*3*2*1 = 1630
  foreach my $radix (2 .. 10) {
    my $total = 0;
    foreach my $len (1 .. $radix) {
      my $part = $radix-1;
      my $prod = $radix-1;
      foreach my $i (2 .. $len) {
        $part *= $prod;
        $prod--;
      }
      $total += $part;
    }
    print "$total,";
  }
  print "\n";
  exit 0;
}
