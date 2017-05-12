#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'min', 'max';

# uncomment this to run the ### lines
#use Smart::Comments;


{
  # tree_n_to_depth()
  require Math::PlanePath::ToothpickUpist;
  foreach my $n (0 .. 9*2+1) {
    my ($depthbits, $lowbit, $ndepth, $nwidth)
      = Math::PlanePath::ToothpickUpist::_n0_to_depthbits ($n);
    print "$n  $ndepth ($nwidth)   $lowbit, ",join(',',@$depthbits), "\n";
  }
  exit 0;
}
