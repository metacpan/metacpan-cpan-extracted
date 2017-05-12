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

use Math::NumSeq;
*_to_bigint = \&Math::NumSeq::_to_bigint;


{
  foreach my $k (1 .. 20) {
    my $power = _to_bigint(10) ** $k;
    my $step = _to_bigint(2) ** $k;
    my $value = $power + (-$power % $step);
      print "$k  $power $step $value\n";

    die if $value % $step;
    if ($value % 5) {
      print "$k  $value\n";
    }
  }
  exit 0;
}
