#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use List::Util 'min', 'max';

# uncomment this to run the ### lines
use Smart::Comments;

use Math::PlanePath::CornerReplicate;

{
  my $path = Math::PlanePath::CornerReplicate->new;
  foreach my $n (0x0FFF, 0x1FFF, 0x2FFF, 0x3FFF) {
    my ($x,$y) = $path->n_to_xy ($n);
    my ($x2,$y2) = $path->n_to_xy ($n+1);
    my $dsum = ($x2+$y2) - ($x+$y);
    printf "%4X to %4X   %2X,%2X to %2X,%2X  dSum=%d\n",
      $n,$n+1, $x,$y, $x2,$y2, $dsum;
  }
  exit 0;
}

