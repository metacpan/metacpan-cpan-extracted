#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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
use List::Util 'sum';
use Math::BaseCnv 'cnv';
use Math::PlanePath;
use Math::PlanePath::ZOrderCurve;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # Numbers Samples
  # A(0,0), A(0,1), A(1,0), A(0,2), A(1,1), A(2,0), ...

  my $path = Math::PlanePath::ZOrderCurve->new (radix => 3);
  {
    print "%e         X=";
    foreach my $x (0 .. 8) {
      printf "%d   ", $x;
    }
    print "\n";
    print '%e       +', '-' x 40, "\n";
    foreach my $y (0 .. 8) {
      print "%e   ", ($y==0 ? "Y=" : "  "), "$y |  ";
      foreach my $x (0 .. 8) {
        last if $x+$y > 8;
        my $n = $path->xy_to_n($x,$y);
        printf "%2d, ", $n;
      }
      print "\n";
    }
  }
{
    foreach my $y (0 .. 8) {
      print "%e   ";
      foreach my $x (0 .. 8) {
        last if $x+$y > 8;
        my $n = $path->xy_to_n($x,$y);
        printf "%2d, ", $n;
      }
      print "\n";
    }
  }
  exit 0;
}
