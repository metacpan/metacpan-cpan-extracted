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

use strict;
use Math::NumSeq;

{
  my $pow = Math::NumSeq::_to_bigint(1);
  for my $i (1 .. 100000) {
    $pow *= 2;
    if ($pow =~ /.*(010|101)/) {
      my $pos = $+[0];
      $pos = length($pow)-$pos; # from end
      my $end = substr ($pow, -60);
      printf "%4d  pos=%3d  %s\n", $i, $pos, $end;
    }
  }
  exit 0;
}
