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
use warnings;
use Math::NumSeq::Tetrahedral;

use Math::NumSeq::Cubes;
*_cbrt_floor = \&Math::NumSeq::Cubes::_cbrt_floor;

#use Smart::Comments;

{
  # tetrahedral vs cbrt

  my $seq = Math::NumSeq::Tetrahedral->new;
  my $target = 2;
  foreach my $i (0 .. 100) {
    my $value = $seq->ith($i);
    my $c = _cbrt_floor($value*6);
    if (! ($c == $i || $c == $i)) {
      print "$i $c $value\n";
    }
  }
  exit 0;
}

