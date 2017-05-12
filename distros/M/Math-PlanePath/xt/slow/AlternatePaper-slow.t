#!/usr/bin/perl -w

# Copyright 2014, 2015 Kevin Ryde

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

use Math::PlanePath::AlternatePaper;

my $path = Math::PlanePath::AlternatePaper->new;


#------------------------------------------------------------------------------
# right boundary N

{
  my $bad = 0;
  foreach my $arms (1 .. 8) {
    my $path = Math::PlanePath::AlternatePaper->new (arms => $arms);
    my $i = 0;
    foreach my $n (0 .. 4**6-1) {
      my ($x1,$y1) = $path->n_to_xy($n);
      my ($x2,$y2) = $path->n_to_xy($n + $arms);
      my $want_pred = path_xyxy_is_right_boundary($path, $x1,$y1, $x2,$y2) ? 1 : 0;
      my $got_pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n) ? 1 : 0;
      unless ($want_pred == $got_pred) {
        MyTestHelpers::diag ("oops, _UNDOCUMENTED__n_segment_is_right_boundary() arms=$arms n=$n pred traverse=$want_pred method=$got_pred");
        last if $bad++ > 10;
      }
    }
  }
  ok ($bad, 0);
}

# Return true if line segment $x1,$y1 to $x2,$y2 is on the right boundary.
# Assumes a square grid and every enclosed unit square has all 4 sides.
sub path_xyxy_is_right_boundary {
  my ($path, $x1,$y1, $x2,$y2) = @_;
  ### path_xyxy_is_right_boundary() ...
  my $dx = $x2-$x1;
  my $dy = $y2-$y1;
  ($dx,$dy) = ($dy,-$dx); # rotate -90
  ### one: "$x1,$y1 to ".($x1+$dx).",".($y1+$dy)
  ### two: "$x2,$y2 to ".($x2+$dx).",".($y2+$dy)
  return (! defined $path->xyxy_to_n_either ($x1,$y1, $x1+$dx,$y1+$dy)
          || ! defined $path->xyxy_to_n_either ($x2,$y2, $x2+$dx,$y2+$dy)
          || ! defined $path->xyxy_to_n_either ($x1+$dx,$y1+$dy, $x2+$dx,$y2+$dy));
}

#------------------------------------------------------------------------------
# left boundary N

{
  my $bad = 0;
  foreach my $arms (4 .. 8) {
    my $path = Math::PlanePath::AlternatePaper->new (arms => $arms);
    my $i = 0;
    foreach my $n (0 .. 4**6-1) {
      my ($x1,$y1) = $path->n_to_xy($n);
      my ($x2,$y2) = $path->n_to_xy($n + $arms);
      my $want_pred = path_xyxy_is_left_boundary($path, $x1,$y1, $x2,$y2) ? 1 : 0;
      my $got_pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n) ? 1 : 0;
      unless ($want_pred == $got_pred) {
        MyTestHelpers::diag ("oops, _UNDOCUMENTED__n_segment_is_left_boundary() arms=$arms n=$n pred traverse=$want_pred method=$got_pred");
        last if $bad++ > 10;
      }
    }
  }
  ok ($bad, 0);
}

# Return true if line segment $x1,$y1 to $x2,$y2 is on the left boundary.
# Assumes a square grid and every enclosed unit square has all 4 sides.
sub path_xyxy_is_left_boundary {
  my ($path, $x1,$y1, $x2,$y2) = @_;
  my $dx = $x2-$x1;
  my $dy = $y2-$y1;
  ($dx,$dy) = (-$dy,$dx); # rotate +90
  return (! defined ($path->xyxy_to_n_either ($x1,$y1, $x1+$dx,$y1+$dy))
          || ! defined ($path->xyxy_to_n_either ($x2,$y2, $x2+$dx,$y2+$dy))
          || ! defined ($path->xyxy_to_n_either ($x1+$dx,$y1+$dy, $x2+$dx,$y2+$dy)));
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
BEGIN { memoize('R_from_path'); }


#------------------------------------------------------------------------------
# B boundary
{
  # _UNDOCUMENTED_level_to_line_boundary()
  # is sum left and right

  foreach my $k (0 .. 14) {
    my $got = $path->_UNDOCUMENTED_level_to_line_boundary($k);
    my $want = ($path->_UNDOCUMENTED_level_to_right_line_boundary($k)
                + $path->_UNDOCUMENTED_level_to_left_line_boundary($k));
    ok ($got, $want, "boundary sum k=$k");
  }
}

{
  # _UNDOCUMENTED_level_to_line_boundary()

  foreach my $k (0 .. 14) {
    my $got = $path->_UNDOCUMENTED_level_to_line_boundary($k);
    my $want = B_from_path($path,$k);
    ok ($got, $want, "_UNDOCUMENTED_level_to_line_boundary() k=$k");
  }
}

#------------------------------------------------------------------------------
# L
{
  # _UNDOCUMENTED_level_to_left_line_boundary()

  foreach my $k (0 .. 14) {
    my $got = $path->_UNDOCUMENTED_level_to_left_line_boundary($k);
    my $want = L_from_path($path,$k);
    ok ($got, $want, "_UNDOCUMENTED_level_to_left_line_boundary() k=$k");
  }
}

#------------------------------------------------------------------------------
# R
{
  # _UNDOCUMENTED_level_to_right_line_boundary()

  foreach my $k (0 .. 14) {
    my $got = $path->_UNDOCUMENTED_level_to_right_line_boundary($k);
    my $want = R_from_path($path,$k);
    ok ($got, $want, "_UNDOCUMENTED_level_to_right_line_boundary() k=$k");
  }
}


#------------------------------------------------------------------------------
# convex hull area

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
    } else {
      my $polygon = Math::Geometry::Planar->new;
      $polygon->points([@points]);
      if (@points > 3) {
        $polygon = $polygon->convexhull2;
        ### convex: $polygon
      }
      $want_area = $polygon->area;
    }

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
exit 0;
