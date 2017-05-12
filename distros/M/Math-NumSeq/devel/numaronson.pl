#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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

use 5.004;
use strict;

{
  print "1, 4,\n";
  foreach my $k (0 .. 5) {
    my $pow = 2**$k;
    foreach my $j (-3 * $pow .. 3 * $pow - 1) {
      my $value = 12*$pow - 3 + (3*$j + abs($j))/2;
      print "$value, ";
    }
    print "\n";
  }
  exit 0;
}
