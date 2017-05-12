#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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
use warnings;

# uncomment this to run the ### lines
use Smart::Comments;


{
  require Math::PlanePath::SacksSpiral;
  foreach my $i (0 .. 40) {
    my $n;
    $n = $i*$i + $i;
    $n = $i*$i;
    my ($x, $y) = Math::PlanePath::SacksSpiral->n_to_xy($n);
    printf "%d  %d, %d\n", $i, $x, $y;
  }
  exit 0;
}


