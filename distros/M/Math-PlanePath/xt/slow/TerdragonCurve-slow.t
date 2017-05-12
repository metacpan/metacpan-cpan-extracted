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
plan tests => 339;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

use Memoize;
use Math::PlanePath::TerdragonCurve;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh','round_down_pow';
use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;



#------------------------------------------------------------------------------
# left boundary samples
{
  my $path = Math::PlanePath::TerdragonCurve->new;

  # examples in terdragon paper
  ok ($path->_UNDOCUMENTED__left_boundary_i_to_n(8),
      50);

  ok (!! $path->_UNDOCUMENTED__n_segment_is_left_boundary(0,0), 1);
  ok (!! $path->_UNDOCUMENTED__n_segment_is_left_boundary(0,1), 1);
  ok (!! $path->_UNDOCUMENTED__n_segment_is_left_boundary(0,-1), 1);

  ok (!! $path->_UNDOCUMENTED__n_segment_is_left_boundary(2,0), '');
  ok (!! $path->_UNDOCUMENTED__n_segment_is_left_boundary(2,1), 1);
  ok (!! $path->_UNDOCUMENTED__n_segment_is_left_boundary(2,-1), 1);
}

#------------------------------------------------------------------------------
# left boundary infinite data

my @left_infinite = (0, 1, 5, 15, 16, 17, 45, 46, 50, 51, 52, 53);
my %left_infinite = map {$_=>1} @left_infinite;

{
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $bad = 0;
  foreach my $n (0 .. $left_infinite[-1]) {
    my $want = $left_infinite{$n} ? 1 : 0;

    foreach my $method ('_UNDOCUMENTED__n_segment_is_left_boundary',
                        sub {
                          my ($path, $n) = @_;
                          my ($x1,$y1) = $path->n_to_xy($n);
                          my ($x2,$y2) = $path->n_to_xy($n+1);
                          return path_triangular_xyxy_is_left_boundary
                            ($path, $x1,$y1, $x2,$y2);
                        }) {
      my $got = $path->$method($n) ? 1 : 0;
      if ($got != $want) {
        MyTestHelpers::diag("oops, $method n=$n want=$want got=$got");
        die;
        last if $bad++ > 10;
      }
    }
  }
  ok ($bad, 0);
}

{
  my $path = Math::PlanePath::TerdragonCurve->new;
  foreach my $i (0 .. $#left_infinite) {
    my $want = $left_infinite[$i];
    my $got = $path->_UNDOCUMENTED__left_boundary_i_to_n($i);
    ok ($got, $want,
        "i=$i want=$want got=$got");
  }
}

#------------------------------------------------------------------------------
# left boundary levels data

my @left_levels = ([0],
                   [0,1,2],
                   [0,1, 5,6,7,8],
                   [0,1,5, 15,16,17,18,19,23,24,25,26]);
my @left_levels_hash = map { my $h = {map {$_=>1} @$_};
                             $h } @left_levels;

{
  my $path = Math::PlanePath::TerdragonCurve->new;
  foreach my $level (0 .. $#left_levels) {
    my $hash = $left_levels_hash[$level];
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    foreach my $n ($n_lo .. $n_hi-1) {
      my $want = $hash->{$n} ? 1 : 0;

      foreach my $method ('_UNDOCUMENTED__n_segment_is_left_boundary',
                          sub {
                            my ($path, $n, $level) = @_;
                            my ($x1,$y1) = $path->n_to_xy($n);
                            my ($x2,$y2) = $path->n_to_xy($n+1);
                            return path_triangular_xyxy_is_left_boundary
                              ($path, $x1,$y1, $x2,$y2, $level);
                          }) {
        my $got = $path->$method($n,$level) ? 1 : 0;
        ok ($got, $want,
            "level=$level $method n=$n want=$want got=$got");
      }
    }

    my $aref = $left_levels[$level];
    foreach my $i (0 .. $#$aref) {
      my $want = $aref->[$i];
      my $got = $path->_UNDOCUMENTED__left_boundary_i_to_n($i,$level);
      ok ($got, $want,
          "i=$i want=$want got=".(defined $got ? $got : '[undef]'));
    }
  }
}

my %left_all_hash = map {map {$_=>1} @$_} @left_levels;
my @left_all = sort {$a<=>$b} keys %left_all_hash;

{
  my $path = Math::PlanePath::TerdragonCurve->new;
  foreach my $n (0 .. max(keys %left_all_hash)) {
    my $want = $left_all_hash{$n} ? 1 : 0;

    foreach my $method ('_UNDOCUMENTED__n_segment_is_left_boundary',
                        sub {
                          my ($path, $n, $level) = @_;
                          my ($x1,$y1) = $path->n_to_xy($n);
                          my ($x2,$y2) = $path->n_to_xy($n+1);
                          return path_triangular_xyxy_is_left_boundary
                            ($path, $x1,$y1, $x2,$y2, $level);
                        }) {
      my $got = $path->$method($n,-1) ? 1 : 0;
      ok ($got, $want,
          "all $method n=$n want=$want got=$got");
    }
  }

  # NOT WORKING YET
  # foreach my $i (0 .. $#left_all) {
  #   my $want = $left_all[$i];
  #   my $got = $path->_UNDOCUMENTED__left_boundary_i_to_n($i,-1);
  #   ok ($got, $want,
  #       "i=$i want=$want got=".(defined $got ? $got : '[undef]'));
  # }
}

#------------------------------------------------------------------------------
# left boundary vs xyxy func

{
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $bad = 0;
 OUTER: foreach my $level (-1,
                           0 .. 6,
                           undef) {
    my $name = (! defined $level ? 'infinite'
                : $level < 0 ? 'all'
                : "level=$level");
    my $i = 0;
    my $ni = $path->_UNDOCUMENTED__left_boundary_i_to_n($i);
    foreach my $n (0 .. 3**6-1) {
      my ($x1,$y1) = $path->n_to_xy($n);
      my ($x2,$y2) = $path->n_to_xy($n+1);

      my $want_pred = path_triangular_xyxy_is_left_boundary($path, $x1,$y1, $x2,$y2, $level) ? 1 : 0;
      my $got_pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n,$level) ? 1 : 0;
      if ($want_pred != $got_pred) {
        MyTestHelpers::diag("oops, $name n=$n pred want $want_pred got $got_pred");
        last if $bad++ > 10;
      }

      my $got_ni = (defined $ni && $n == $ni ? 1 : 0);
      if ($got_ni != $want_pred) {
        MyTestHelpers::diag("oops, $name n=$n ni=".(defined $ni ? $ni : '[undef]')." want_pred=$want_pred");
        last OUTER if $bad++ > 10;
      }

      if (defined $ni && $n >= $ni) {
        $i++;
        $ni = $path->_UNDOCUMENTED__left_boundary_i_to_n($i, $level);
      }
    }
  }
  ok ($bad, 0);
}

# return true if line segment $x1,$y1 to $x2,$y2 is on the left boundary
# of triangular path $path
# use Smart::Comments;
sub path_triangular_xyxy_is_left_boundary {
  my ($path, $x1,$y1, $x2,$y2, $level) = @_;
  ### path_triangular_xyxy_is_left_boundary(): "$x1,$y1 to $x2,$y2"

  my $n = $path->xyxy_to_n ($x1,$y1, $x2,$y2);
  my $n_hi;
  if (defined $level) {
    if ($level < 0) {
      ($n_hi) = round_down_pow($n,3);
      $n_hi *= 3;
    } else {
      $n_hi = 3**$level;
      if ($n >= $n_hi) {
        ### segment beyond level, so not boundary ...
        return 0;
      }
    }
  }
  ### $n_hi

  my $dx = $x2-$x1;
  my $dy = $y2-$y1;
  my $x3 = $x1 + ($dx-3*$dy)/2;   # dx,dy rotate +60
  my $y3 = $y1 + ($dy+$dx)/2;
  ### points: "left side $x3,$y2"

  foreach my $n1 ($path->xyxy_to_n_either ($x1,$y1, $x3,$y3),
                  $path->xyxy_to_n_either ($x2,$y2, $x3,$y3)) {
    ### $n1
    if (! defined $n1) {
      ### never traversed, so boundary ...
      return 1;
    }
    if ($n_hi && $n1 >= $n_hi) {
      ### traversed beyond our target level, so boundary ...
      return 1;
    }
  }
  return 0;
}


#------------------------------------------------------------------------------
# right boundary N
{
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $i = 0;
  my $ni = $path->_UNDOCUMENTED__right_boundary_i_to_n($i);
  foreach my $n (0 .. 3**4-1) {
    my ($x1,$y1) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    my $want_pred = path_triangular_xyxy_is_right_boundary($path, $x1,$y1, $x2,$y2) ? 1 : 0;
    my $got_pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n) ? 1 : 0;
    ok ($want_pred, $got_pred, "n=$n pred want $want_pred got $got_pred");
    ok (($n == $ni) == $want_pred, 1);

    if ($n >= $ni) {
      $i++;
      $ni = $path->_UNDOCUMENTED__right_boundary_i_to_n($i);
    }
  }
}

# return true if line segment $x1,$y1 to $x2,$y2 is on the right boundary
# of triangular path $path
sub path_triangular_xyxy_is_right_boundary {
  my ($path, $x1,$y1, $x2,$y2) = @_;
  my $dx = $x2-$x1;
  my $dy = $y2-$y1;
  my $x3 = $x1 + ($dx+3*$dy)/2;   # dx,dy rotate -60 so right
  my $y3 = $y1 + ($dy-$dx)/2;
  ### path_triangular_xyxy_is_right_boundary(): "$x1,$y1  $x2,$y2   $x3,$y3"
  return (! defined ($path->xyxy_to_n_either ($x1,$y1, $x3,$y3))
          || ! defined ($path->xyxy_to_n_either ($x2,$y2, $x3,$y3)));
}



# MyOEIS triangular boundary bits broken
exit 0;

#------------------------------------------------------------------------------
# B

my $path = Math::PlanePath::TerdragonCurve->new;

{
  #  samples values from terdragon.tex
  my @want = (2, 6, 12, 24, 48, 96);
  foreach my $k (0 .. $#want) {
    my $got = B_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # B[k+1] = R[k] + U[k]
  foreach my $k (0 .. 5) {
    my $r = R_from_path($path,$k);
    my $u = U_from_path($path,$k);
    my $b = B_from_path($path,$k+1);
    ok ($r+$u, $b, "k=$k  R+U=B");
  }
}
{
  # B[k] = 2, 3*2^k
  foreach my $k (0 .. 10) {
    my $want = b_from_path($path,$k);
    my $got = B_from_formula($k);
    ok ($got,$want);
  }
  sub B_from_formula {
    my ($k) = @_;
    return ($k==0 ? 2 : 3*2**$k);
  }
}

#------------------------------------------------------------------------------
# R

{
  # R[k] = B[k]/2
  my $sum = 1;
  foreach my $k (0 .. 8) {
    my $b = B_from_path($path,$k);
    my $r = R_from_path($path,$k);
    ok ($r,$b/2);
  }
}
{
  # samples from terdragon.tex
  my @want = (1, 3, 6, 12, 24, 48);
  foreach my $k (0 .. $#want) {
    my $got = R_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # R[k+1] = R[k] + U[k]

  foreach my $k (1 .. 8) {
    my $r0 = R_from_path($path,$k);
    my $r1 = R_from_path($path,$k+1);
    my $u = R_from_path($path,$k);
    ok ($r0+$u, $r1);
  }
}

#------------------------------------------------------------------------------
# Area

{
  # A[k] = (2*3^k - B[k])/4

  foreach my $k (0 .. 8) {
    my $b = B_from_path($path,$k);
    my $got = (2*3**$k - $b)/4;
    my $want = A_from_path($path,$k);
    ok ($got,$want);
  }
}
{
  # A[k] = if(k==0,0, 2*(3^(k-1)-2^(k-1)))

  foreach my $k (0 .. 8) {
    my $got = A_from_formula($k);
    my $want = A_from_path($path,$k);
    ok ($got,$want);
  }
  sub A_from_formula {
    my ($k) = @_;
    return ($k==0 ? 0 : 2*(3**($k-1) - 2**($k-1)));
  }
}


#------------------------------------------------------------------------------
# boundary lengths

sub B_from_path {
  my ($path, $k) = @_;
  my $n_limit = 3**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit,
                                            lattice_type => 'triangular');
  return scalar(@$points);
}
BEGIN { memoize('B_from_path') }

sub L_from_path {
  my ($path, $k) = @_;
  my $n_limit = 3**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit,
                                            lattice_type => 'triangular',
                                            side => 'left');
  return scalar(@$points) - 1;
}
BEGIN { memoize('L_from_path') }

sub R_from_path {
  my ($path, $k) = @_;
  my $n_limit = 3**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit,
                                            lattice_type => 'triangular',
                                            side => 'right');
  return scalar(@$points) - 1;
}
BEGIN { memoize('R_from_path') }

sub U_from_path {
  my ($path, $k) = @_;
  my $n_limit = 3**$k;
  my ($x,$y) = $path->n_to_xy($n_limit);
  my ($to_x,$to_y) = $path->n_to_xy(0);
  my $points = MyOEIS::path_boundary_points_ft($path, 3*$n_limit,
                                               $x,$y, $to_x,$to_y,
                                               lattice_type => 'triangular',
                                               dir => 1);
  return scalar(@$points) - 1;
}
BEGIN { memoize('U_from_path') }

sub A_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_enclosed_area($path, 3**$k,
                                    lattice_type => 'triangular');
}
BEGIN { memoize('A_from_path') }

#------------------------------------------------------------------------------
# U

{
  # samples from terdragon.tex
  my @want = (2, 3, 6, 12, 24, 48);
  foreach my $k (0 .. $#want) {
    my $got = U_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # U[k+1] = R[k] + U[k]

  foreach my $k (0 .. 10) {
    my $u = U_from_path($path,$k);
    my $r = R_from_path($path,$k);
    my $got = $r + $u;
    my $want = U_from_path($path,$k+1);
    ok ($got,$want);
  }
}

#------------------------------------------------------------------------------
exit 0;
