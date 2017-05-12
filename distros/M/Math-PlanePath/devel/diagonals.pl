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

use Math::PlanePath::Diagonals;
use Math::NumSeq::PlanePathDelta;

{
  my $dir = 'up';

  foreach my $y_start (reverse -7 .. 7) {
    printf "Ystart=%2d", $y_start;
    foreach my $x_start (-7 .. 7) {
      my $seq = Math::NumSeq::PlanePathDelta->new
        (planepath => "Diagonals,x_start=$x_start,y_start=$y_start,direction=$dir",
         delta_type => 'dSumAbs');
      printf " %3d", $seq->values_max;
    }
    print "\n";
  }
  print "\n";
  foreach my $y_start (reverse -7 .. 7) {
    printf "Ystart=%2d", $y_start;
    foreach my $x_start (-7 .. 7) {
      my $max = dsumabs_max($x_start,$y_start);
      my $seq = Math::NumSeq::PlanePathDelta->new
        (planepath => "Diagonals,x_start=$x_start,y_start=$y_start,direction=$dir",
         delta_type => 'dSumAbs');
      my $diff = ($seq->values_max == $max ? ' ' : '*');
      printf "%3d%s", $max, $diff;
    }
    print "\n";
  }
  print "\n";

  foreach my $y_start (reverse -7 .. 7) {
    printf "Ystart=%2d", $y_start;
    foreach my $x_start (-7 .. 7) {
      my $seq = Math::NumSeq::PlanePathDelta->new
        (planepath => "Diagonals,x_start=$x_start,y_start=$y_start,direction=$dir",
         delta_type => 'dSumAbs');
      printf " %3d", $seq->values_min;
    }
    print "\n";
  }
  print "\n";
  foreach my $y_start (reverse -7 .. 7) {
    printf "Ystart=%2d ", $y_start;
    foreach my $x_start (-7 .. 7) {
      my $min = dsumabs_min($x_start,$y_start);
      my $seq = Math::NumSeq::PlanePathDelta->new
        (planepath => "Diagonals,x_start=$x_start,y_start=$y_start,direction=$dir",
         delta_type => 'dSumAbs');
      my $diff = ($seq->values_min == $min ? ' ' : '*');
      printf "%3d%s", $min, $diff;
    }
    print "\n";
  }
  print "\n";

  exit 0;

  sub dsumabs_min {
    my ($x_start, $y_start) = @_;
    my $seq = Math::NumSeq::PlanePathDelta->new
      (planepath => "Diagonals,x_start=$x_start,y_start=$y_start,direction=$dir",
       delta_type => 'dSumAbs');
    my $i_start = $seq->i_start;
    my $min = $seq->ith($i_start);
    foreach my $i ($i_start .. 500) {
      $min = min($min, $seq->ith($i));
    }
    return $min;
  }

  sub dsumabs_max {
    my ($x_start, $y_start) = @_;
    my $seq = Math::NumSeq::PlanePathDelta->new
      (planepath => "Diagonals,x_start=$x_start,y_start=$y_start,direction=$dir",
       delta_type => 'dSumAbs');
    my $i_start = $seq->i_start;
    my $max = $seq->ith($i_start);
    foreach my $i ($i_start .. 500) {
      $max = max($max, $seq->ith($i));
    }
    return $max;
  }
}

