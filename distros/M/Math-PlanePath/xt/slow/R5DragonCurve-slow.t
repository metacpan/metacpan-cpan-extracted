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
plan tests => 218;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

use Memoize;
use Math::PlanePath::R5DragonCurve;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh';
use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;



#------------------------------------------------------------------------------
# right boundary N

{
  my $bad = 0;
  foreach my $arms (1) {
    my $path = Math::PlanePath::R5DragonCurve->new (arms => $arms);
    my $i = 0;
    foreach my $n (0 .. 5**5-1) {
      my ($x1,$y1) = $path->n_to_xy($n);
      my ($x2,$y2) = $path->n_to_xy($n + $arms);
      my $want_pred = path_xyxy_is_right_boundary($path, $x1,$y1, $x2,$y2) ? 1 : 0;
      foreach my $method
        ('_UNDOCUMENTED__n_segment_is_right_boundary',
         'main::n_segment_is_right_boundary__by_digitpairs_allowed',
         'main::n_segment_is_right_boundary__by_digitpairs_disallowed',
         'main::n_segment_is_right_boundary_by_hightolow_states',
        ) {
        my $got_pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n) ? 1 : 0;
        unless ($want_pred == $got_pred) {
          MyTestHelpers::diag ("oops, $method() arms=$arms n=$n pred traverse=$want_pred method=$got_pred");
          last if $bad++ > 10;
        }
      }
    }
  }
  ok ($bad, 0);
}

BEGIN {
  my @table
    = (undef,
       [    1, 1, 2, 3, 4 ],   # R -> RRCDE
       [    1, 2          ],   # C -> RC___
       [undef, 3          ],   # D -> _D___
       [undef, 4, 2, 3, 4 ],   # E -> _ECDE
      );

  sub n_segment_is_right_boundary_by_hightolow_states {
    my ($self, $n) = @_;
    my $state = 1;
    foreach my $digit (reverse digit_split_lowtohigh($n,5)) { # high to low
      $state = $table[$state][$digit] || return 0;
    }
    return 1;
  }
}
BEGIN {
  my @allowed_pairs
    = ([ 1, '', 1, 1, 1 ],  # 00, __, 02, 03, 04  0s all allowed
       '',                  # 1s deleted
       [ 1, '', 0, 0, 0 ],  # 20, __, __, __, __
       [ 0, '', 0, 0, 0 ],  # __, __, __, __, __  3s none allowed
       [ 0, '', 1, 1, 1 ],  # __, __, 42, 43, 44
      );
  my @disallowed_pairs
    = ([ 0, '', 0, 0, 0 ],  # __, __, __, __, __  0s none disallowed
       '',                  # 1s deleted
       [ 0, '', 1, 1, 1 ],  # __, __, 22, 23, 24
       [ 1, '', 1, 1, 1 ],  # 30, __, 32, 33, 34  3s all disallowed
       [ 1, '', 0, 0, 0 ],  # 40, __, __, __, __
      );
  sub n_segment_is_right_boundary__by_digitpairs_disallowed {
    my ($self, $n) = @_;
    ### n_segment_is_right_boundary__by_digitpairs(): "n=$n"
    my $prev = 0;
    if (_divrem_mutate($n, $self->{'arms'})) {
      # FIXME: is this right ?
      $prev = 4;
    }
    foreach my $digit (reverse digit_split_lowtohigh($n,5)) { # high to low
      next if $digit == 1;
      ### pair: "$prev $digit   table=".($table[$prev][$digit] || 0)
      if ($disallowed_pairs[$prev][$digit]) {
        ### no ...
        return 0;
      }
      $prev = $digit;
    }
    ### yes ...
    return 1;
  }
  sub n_segment_is_right_boundary__by_digitpairs_allowed {
    my ($self, $n) = @_;
    ### n_segment_is_right_boundary__by_digitpairs(): "n=$n"
    my $prev = 0;
    if (_divrem_mutate($n, $self->{'arms'})) {
      # FIXME: is this right ?
      $prev = 4;
    }
    foreach my $digit (reverse digit_split_lowtohigh($n,5)) { # high to low
      next if $digit == 1;
      ### pair: "$prev $digit   table=".($table[$prev][$digit] || 0)
      if (! $allowed_pairs[$prev][$digit]) {
        ### no ...
        return 0;
      }
      $prev = $digit;
    }
    ### yes ...
    return 1;
  }
}

# return true if line segment $x1,$y1 to $x2,$y2 is on the right boundary
sub path_xyxy_is_right_boundary {
  my ($path, $x1,$y1, $x2,$y2) = @_;
  ### path_xyxy_is_right_boundary() ...
  my $dx = $x2-$x1;
  my $dy = $y2-$y1;
  ($dx,$dy) = ($dy,-$dx); # rotate -90
  ### one: "$x1,$y1 to ".($x1+$dx).",".($y1+$dy)
  ### two: "$x2,$y2 to ".($x2+$dx).",".($y2+$dy)
  return (! defined ($path->xyxy_to_n_either ($x1,$y1, $x1+$dx,$y1+$dy))
          || ! defined ($path->xyxy_to_n_either ($x2,$y2, $x2+$dx,$y2+$dy))
          || ! defined ($path->xyxy_to_n_either ($x1+$dx,$y1+$dy, $x2+$dx,$y2+$dy)));
}

#------------------------------------------------------------------------------
# left boundary N

{
  my $bad = 0;
  foreach my $arms (1) {
    my $path = Math::PlanePath::R5DragonCurve->new (arms => $arms);
    my $i = 0;
    foreach my $level (0 .. 7) {
      my ($n_start, $n_end) = $path->level_to_n_range($level);
      foreach my $n ($n_start .. $n_end-1) {
        my ($x1,$y1) = $path->n_to_xy($n);
        my ($x2,$y2) = $path->n_to_xy($n + $arms);
        my $want_pred = path_xyxy_is_left_boundary($path, $x1,$y1, $x2,$y2, $level) ? 1 : 0;
        {
          my $got_pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n, $level) ? 1 : 0;
          unless ($want_pred == $got_pred) {
            MyTestHelpers::diag ("oops, _UNDOCUMENTED__n_segment_is_left_boundary() arms=$arms level=$level n=$n pred traverse=$want_pred method=$got_pred");
            last if $bad++ > 10;
          }
        }
      }
    }
  }
  ok ($bad, 0);
  exit 0;
}
{
  my $bad = 0;
  foreach my $arms (1) {
    my $path = Math::PlanePath::R5DragonCurve->new (arms => $arms);
    my $i = 0;
    foreach my $n (0 .. 5**7-1) {
      my ($x1,$y1) = $path->n_to_xy($n);
      my ($x2,$y2) = $path->n_to_xy($n + $arms);
      my $want_pred = path_xyxy_is_left_boundary($path, $x1,$y1, $x2,$y2) ? 1 : 0;
      {
        my $got_pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n) ? 1 : 0;
        unless ($want_pred == $got_pred) {
          MyTestHelpers::diag ("oops, _UNDOCUMENTED__n_segment_is_left_boundary() arms=$arms n=$n pred traverse=$want_pred method=$got_pred");
          last if $bad++ > 10;
        }
      }
      # {
      #   my $got_pred = n_segment_is_left_boundary__by_digitpairs($path,$n) ? 1 : 0;
      #   unless ($want_pred == $got_pred) {
      #     MyTestHelpers::diag ("oops, n_segment_is_left_boundary__by_digitpairs() arms=$arms n=$n pred traverse=$want_pred method=$got_pred");
      #     last if $bad++ > 10;
      #   }
      # }
      # {
      #   my $got_pred = n_segment_is_left_boundary_by_hightolow_states($path,$n) ? 1 : 0;
      #   unless ($want_pred == $got_pred) {
      #     MyTestHelpers::diag ("n_segment_is_left_boundary_by_hightolow_states(), n_segment_is_left_boundary__by_digitpairs() arms=$arms n=$n pred traverse=$want_pred method=$got_pred");
      #     last if $bad++ > 10;
      #   }
      # }
    }
  }
  ok ($bad, 0);
}

BEGIN {
  my @table
    = (undef,
       [    1, 1, 2, 3, 4 ],   # R -> RRCDE
       [    1, 2          ],   # C -> RC___
       [undef, 3          ],   # D -> _D___
       [undef, 4, 2, 3, 4 ],   # E -> _ECDE
      );

  sub n_segment_is_left_boundary_by_hightolow_states {
    my ($self, $n) = @_;
    my $state = 1;
    foreach my $digit (reverse digit_split_lowtohigh($n,5)) { # high to low
      $state = $table[$state][$digit] || return 0;
    }
    return 1;
  }
}
BEGIN {
  my @table
    = ([     1, undef, 1, 1, 1 ],  # 00, 02, 03, 04
       undef,
       [     1                 ],  # 20
       [                       ],  # 3 none
       [ undef, undef, 1, 1, 1 ],  # 4
      );
  sub n_segment_is_left_boundary__by_digitpairs {
    my ($self, $n) = @_;
    ### n_segment_is_left_boundary__by_digitpairs(): "n=$n"
    my $prev = 0;
    {
      my $arms = $self->{'arms'};
      if (_divrem_mutate($n, $arms) != $arms-1) {
        $prev = 1;
      }
    }
    foreach my $digit (reverse digit_split_lowtohigh($n,5)) { # high to low
      next if $digit == 1;
      ### pair: "$prev $digit   table=".($table[$prev][$digit] || 0)
      unless ($table[$prev][$digit]) {
        ### no ...
        return 0;
      }
      $prev = $digit;
    }
    ### yes ...
    return 1;
  }
}

# return true if line segment $x1,$y1 to $x2,$y2 is on the left boundary
sub path_xyxy_is_left_boundary {
  my ($path, $x1,$y1, $x2,$y2, $level) = @_;
  ### path_xyxy_is_left_boundary() ...
  my $dx = $x2-$x1;
  my $dy = $y2-$y1;
  ($dx,$dy) = (-$dy,$dx); # rotate +90
  ### one: "$x1,$y1 to ".($x1+$dx).",".($y1+$dy)
  ### two: "$x2,$y2 to ".($x2+$dx).",".($y2+$dy)
  return (! path_xyxy_is_traversed_in_level ($path, $x1,$y1, $x1+$dx,$y1+$dy, $level)
          || ! path_xyxy_is_traversed_in_level ($path, $x2,$y2, $x2+$dx,$y2+$dy, $level)
          || ! path_xyxy_is_traversed_in_level ($path, $x1+$dx,$y1+$dy, $x2+$dx,$y2+$dy, $level));
}

# return true if line segment $x1,$y1 to $x2,$y2 is traversed,
# ie. consecutive N goes from $x1,$y1 to $x2,$y2, in either direction.
sub path_xyxy_is_traversed_in_level {
  my ($path, $x1,$y1, $x2,$y2, $level) = @_;
  ### path_xyxy_is_traversed_in_level(): "$x1,$y1, $x2,$y2"
  my $arms = $path->arms_count;
  my $n_limit;
  if (defined $level) { $n_limit = 5**$level; }
  foreach my $n1 ($path->xy_to_n_list($x1,$y1)) {
    next if defined $n_limit && $n1 >= $n_limit;
    foreach my $n2 ($path->xy_to_n_list($x2,$y2)) {
      next if defined $n_limit && $n2 >= $n_limit;
      if (abs($n1-$n2) == $arms) {
        ### yes: "$n1 to $n2"
        return 1;
      }
    }
  }
  ### no ...
  return 0;
}

my $path = Math::PlanePath::R5DragonCurve->new;

#------------------------------------------------------------------------------
# B

{
  # POD samples
  my @want = (2, 10, 34, 106, 322, 970, 2914);
  foreach my $k (0 .. $#want) {
    my $got = B_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # B[k] = 4*R[k] + 2*U[k]

  foreach my $k (0 .. 10) {
    my $r = R_from_path($path,$k);
    my $u = U_from_path($path,$k);
    my $b = B_from_path($path,$k+1);
    ok (4*$r+2*$u,$b);
  }
}
{
  # B[k+2] = 4*B[k+1] - 3*B[k]

  foreach my $k (0 .. 10) {
    my $b0 = B_from_path($path,$k);
    my $b1 = B_from_path($path,$k+1);
    my $got = 4*$b1 - 3*$b0;
    my $want = B_from_path($path,$k+2);
    ok ($got,$want);
  }
}
{
  # B[k] = 4*3^k - 2

  foreach my $k (0 .. 10) {
    my $want = b_from_path($path,$k);
    my $got = 4*3**$k - 2;
    ok ($got,$want);
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
  # POD samples
  my @want = (1,5,17,53);
  foreach my $k (0 .. $#want) {
    my $got = R_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # R[k+1] = 2*R[k] + U[k]

  foreach my $k (1 .. 8) {
    my $r0 = R_from_path($path,$k);
    my $r1 = R_from_path($path,$k+1);
    my $u = R_from_path($path,$k);
    ok (2*$r0+$u, $r1);
  }
}

#------------------------------------------------------------------------------
# Area

sub A_recurrence {
  my ($k) = @_;
  if ($k <= 0) { return 0; }
  if ($k == 1) { return 0; }
  if ($k == 2) { return 4; }
  if ($k == 3) { return 36; }
  return (9*A_recurrence($k-1)
          - 23*A_recurrence($k-2)
          + 15*A_recurrence($k-3));
}
BEGIN { memoize('A_recurrence') }

{
  # A[k] = (2*5^k - B[k])/4

  foreach my $k (0 .. 8) {
    my $b = B_from_path($path,$k);
    ### $b
    my $got = (2*5**$k - $b)/4;
    my $want = A_from_path($path,$k);
    ok ($got,$want);
  }
}
{
  # A[k] recurrence

  foreach my $k (0 .. 8) {
    my $n_limit = 5**$k;
    my $got = A_recurrence($k);
    my $want = A_from_path($path,$k);
    ok ($got,$want, "k=$k");
  }
}
{
  # A[k] = (5^k - 2*3^k + 1)/2

  foreach my $k (0 .. 8) {
    my $got = (5**$k - 2*3**$k + 1)/2;
    my $want = A_from_path($path,$k);
    ok ($got,$want);
  }
}


#------------------------------------------------------------------------------
# boundary lengths

sub B_from_path {
  my ($path, $k) = @_;
  my $n_limit = 5**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit);
  return scalar(@$points);
}
BEGIN { memoize('B_from_path') }

sub L_from_path {
  my ($path, $k) = @_;
  my $n_limit = 5**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit, side => 'left');
  return scalar(@$points) - 1;
}
BEGIN { memoize('L_from_path') }

sub R_from_path {
  my ($path, $k) = @_;
  my $n_limit = 5**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit, side => 'right');
  return scalar(@$points) - 1;
}
BEGIN { memoize('R_from_path') }

sub U_from_path {
  my ($path, $k) = @_;
  my $n_limit = 5**$k;
  my ($x,$y) = $path->n_to_xy(3*$n_limit);
  my ($to_x,$to_y) = $path->n_to_xy(0);
  my $points = MyOEIS::path_boundary_points_ft($path, 5*$n_limit,
                                               $x,$y, $to_x,$to_y,
                                               dir => 1);
  return scalar(@$points) - 1;
}
BEGIN { memoize('U_from_path') }

sub A_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_enclosed_area($path, 5**$k);
}
BEGIN { memoize('A_from_path') }

# #------------------------------------------------------------------------------
# # U
# 
# {
#   # POD samples
#   my @want = (3, 6, 8, 12, 20, 32, 52, 88, 148, 248, 420, 712, 1204, 2040);
#   foreach my $k (0 .. $#want) {
#     my $got = U_from_path($path,$k);
#     my $want = $want[$k];
#     ok ($got,$want);
#   }
# }
# {
#   # U[k+1] = U[k] + V[k]
# 
#   foreach my $k (0 .. 10) {
#     my $u = U_from_path($path,$k);
#     my $v = V_from_path($path,$k);
#     my $got = $u + $v;
#     my $want = U_from_path($path,$k+1);
#     ok ($got,$want);
#   }
# }
# {
#   # U[k+1] = U[k] + L[k]      k>=1
#   foreach my $k (1 .. 10) {
#     my $u = U_from_path($path,$k);
#     my $l = L_from_path($path,$k);
#     my $got = $u + $l;
#     my $want = U_from_path($path,$k+1);
#     ok ($got,$want);
#   }
# }
# {
#   # U[k+4] = 2*U[k+3] - U[k+2] + 2*U[k+1] - 2*U[k]    for k >= 1
# 
#   foreach my $k (1 .. 10) {
#     my $u0 = U_from_path($path,$k);
#     my $u1 = U_from_path($path,$k+1);
#     my $u2 = U_from_path($path,$k+2);
#     my $u3 = U_from_path($path,$k+3);
#     my $got = 2*$u3 - $u2 + 2*$u1 - 2*$u0;
#     my $want = U_from_path($path,$k+4);
#     ok ($got,$want);
#   }
# }
# {
#   # U[k] = L[k+2] - R[k]
#   foreach my $k (0 .. 10) {
#     my $l = L_from_path($path,$k+2);
#     my $r = R_from_path($path,$k);
#     my $got = $l - $r;
#     my $want = U_from_path($path,$k);
#     ok ($got,$want);
#   }
# }

#------------------------------------------------------------------------------
exit 0;
