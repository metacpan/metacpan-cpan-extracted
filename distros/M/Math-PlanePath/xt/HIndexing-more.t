#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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
use Math::PlanePath::HIndexing;

use Test;
plan tests => 35;

use lib 't','xt';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }
use MyOEIS;

# uncomment this to run the ### lines
#use Smart::Comments '###';


#------------------------------------------------------------------------------
# area

sub points_to_area {
  my ($points) = @_;
  if (@$points < 3) {
    return 0;
  }
  require Math::Geometry::Planar;
  my $polygon = Math::Geometry::Planar->new;
  $polygon->points($points);
  return $polygon->area;
}
{
  my $path = Math::PlanePath::HIndexing->new;
  foreach my $level (0 .. 10) {
    my $a = $path->_UNDOCUMENTED__level_to_area($level);
    my $Y = $path->_UNDOCUMENTED__level_to_area_Y($level);
    my $up = $path->_UNDOCUMENTED__level_to_area_up($level);
    ok ($Y+$up, $a);
  }
}

{
  my $path = Math::PlanePath::HIndexing->new;
  foreach my $level (0 .. 7) {
    my $got_area = $path->_UNDOCUMENTED__level_to_area($level);
    my @points;
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    my $y_max = 0;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
      if ($y > $y_max) { $y_max = $y; }
    }
    push @points, [0,$y_max];

    my $want_area = points_to_area(\@points);
    ok ($got_area, $want_area);
    #    print "$want_area, ";
  }
}

{
  my $path = Math::PlanePath::HIndexing->new;
  foreach my $level (0 .. 7) {
    my $got_area = $path->_UNDOCUMENTED__level_to_area_up($level);
    my @points;
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    $n_lo = ($n_hi + 1)/2 - 1;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }
    my $want_area = points_to_area(\@points);
    ok ($got_area, $want_area);
  }
}

{
  my $path = Math::PlanePath::HIndexing->new;
  foreach my $level (0 .. 7) {
    my $got_area = $path->_UNDOCUMENTED__level_to_area_Y($level);
    my @points;
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    $n_hi = ($n_hi + 1)/2 - 1;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }
    my $want_area = points_to_area(\@points);
    ok ($got_area, $want_area);
  }
}

#------------------------------------------------------------------------------
exit 0;
