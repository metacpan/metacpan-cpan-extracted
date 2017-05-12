#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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

use 5.010;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use Math::PlanePath::LCornerTree;
use Math::PlanePath::LCornerSingle;

# {
#   my $prev_depth = -1;
#   foreach my $n (64 .. 64) {
#     my ($depthbits, $ndepth, $nwidth)
#       = Math::PlanePath::LCornerTree::_n0_to_depthbits($n,4);
#     my $depth = digit_join_lowtohigh ($depthbits, 2);
#     if ($depth != $prev_depth) {
#       print "$depth  $ndepth $nwidth\n";
#       $prev_depth = $depth;
#     }
#   }
# }
{
  my $prev_depth = -1;
  foreach my $n (49 .. 225) {
    my ($depthbits, $ndepth, $nwidth)
      = Math::PlanePath::LCornerSingle::_n0_to_depthbits($n);
    my $depth = digit_join_lowtohigh ($depthbits, 2);
    if ($depth != $prev_depth) {
      print "$depth  $ndepth $nwidth\n";
      $prev_depth = $depth;
    }
  }
  exit 0;
}
