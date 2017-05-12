#!/usr/bin/perl -w

# Copyright 2014, 2016, 2017 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
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
use List::Util 'min','max';
use Test;
plan tests => 87;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use lib 'xt';
use MyOEIS;
use Memoize;

# uncomment this to run the ### lines
# use Smart::Comments;

use Math::PlanePath::CCurve 124;  # v.124 for n_to_n_list()

my $path = Math::PlanePath::CCurve->new;

#------------------------------------------------------------------------------
# convex hull

{
  require Math::Geometry::Planar;
  my @points;
  my $n = $path->n_start;
  foreach my $k (0 .. 14) {
    my $n_end = 2**$k;
    while ($n <= $n_end) {
      push @points, [ $path->n_to_xy($n) ];
      $n++;
    }

    my ($want_area, $want_boundary);
    if ($k == 0) {
      # N=0 to N=1
      $want_area = 0;
      $want_boundary = 2;
    } else {
      my $polygon = Math::Geometry::Planar->new;
      $polygon->points([@points]);
      if (@points > 3) {
        $polygon = $polygon->convexhull2;
        ### convex: $polygon
      }
      $want_area = $polygon->area;
      $want_boundary = $polygon->perimeter;
    }
    my ($want_a,$want_b) = to_sqrt2_parts($want_boundary);

    my $got_boundary = $path->_UNDOCUMENTED_level_to_hull_boundary($k);
    my ($got_a,$got_b) = $path->_UNDOCUMENTED_level_to_hull_boundary_sqrt2($k);
    ok ($got_a, $want_a, "k=$k");
    ok ($got_b, $want_b, "k=$k");
    ok (abs($got_boundary - $want_boundary) < 0.00001, 1);

    my $got_area = $path->_UNDOCUMENTED_level_to_hull_area($k);
    ok ($got_area, $want_area, "k=$k");
  }
}

sub to_sqrt2_parts {
  my ($x) = @_;
  if (! defined $x) { return $x; }
  foreach my $b (0 .. int($x)) {
    my $a = $x - $b*sqrt(2);
    my $a_int = int($a+.5);
    if (abs($a - $a_int) < 0.00000001) {
      return $a_int, $b;
    }
  }
  return (undef,undef);
}

#------------------------------------------------------------------------------
# boundary lengths

sub B_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit);
  return scalar(@$points);
}
memoize('B_from_path');

sub L_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit, side => 'left');
  return scalar(@$points) - 1;
}
memoize('L_from_path');

sub R_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit, side => 'right');
  return scalar(@$points) - 1;
}
memoize('R_from_path');

# R[k] = 2*R[k-1] + R[k-2] - 4*R[k-3] + 2*R[k-4]
sub R_recurrence {
  my ($recurrence, $k) = @_;
  if ($k <= 0) { return 1; }
  if ($k == 1) { return 2; }
  if ($k == 2) { return 4; }
  if ($k == 3) { return 8; }
  return (2*R_recurrence($k-4)
          - 4*R_recurrence($k-3)
          + R_recurrence($k-2)
          + 2*R_recurrence($k-1));
}
memoize('R_from_path');


#------------------------------------------------------------------------------
# R

{
  # POD samples
  my @want = (1, 2, 4, 8, 14, 24, 38, 60, 90, 136, 198, 292, 418);
  foreach my $k (0 .. $#want) {
    my $got = R_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}

{
  # recurrence
  my @want = (1, 2, 4, 8, 14, 24, 38, 60, 90, 136, 198, 292, 418);
  foreach my $k (0 .. $#want) {
    my $got = R_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}


#------------------------------------------------------------------------------
# claimed in the pod N overlaps always have different count 1-bits mod 4

{
  foreach my $n (0 .. 100_000) {
    my @n_list = $path->n_to_n_list($n);
    my @seen;
    foreach my $n (@n_list) {
      my $c = count_1_bits($n) % 4;
      if ($seen[$c]++) {
        die;
      }
    }
  }
  ok (1,1);
}

sub count_1_bits {
  my ($n) = @_;
  my $count = 0;
  while ($n) {
    $count += ($n & 1);
    $n >>= 1;
  }
  return $count;
}


#------------------------------------------------------------------------------
exit 0;
