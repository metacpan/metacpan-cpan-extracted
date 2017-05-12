#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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
use Math::PlanePath::DragonCurve;
my $path = Math::PlanePath::DragonCurve->new;
my $midpath = Math::PlanePath::DragonMidpoint->new;


#------------------------------------------------------------------------------
# MB = midpoint square figures boundary

{
  my @want = (4, 6, 10, 18, 30, 50, 86, 146, 246, 418, 710, 1202); # per POD
  foreach my $k (0 .. $#want) {
    my $got = MB_from_path($path,$k);
    ok ($want[$k],$got);
  }
}

{
  # MB[k] = B[k] + 4
  foreach my $k (0 .. 10) {
    my $mb = MB_from_path($path,$k);
    my $b2 = B_from_path($path,$k) + 4;
    ok ($mb,$b2, "k=$k");
  }
}

sub MB_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_n_to_figure_boundary($midpath, 2**$k-1);
}
BEGIN { memoize('MB_from_path'); }


#------------------------------------------------------------------------------
# P = points visited

ok ($path->_UNDOCUMENTED_level_to_visited(4), 16);
ok ($path->_UNDOCUMENTED_level_to_visited(5), 29);
ok ($path->_UNDOCUMENTED_level_to_visited(6), 54);

{
  foreach my $k (0 .. 10) {
    my $got = $path->_UNDOCUMENTED_level_to_visited($k);
    my $want = P_from_path($path,$k);
    ok ($got,$want, "k=$k");
  }
}

sub P_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_n_to_visited($path, 2**$k);
}
BEGIN { memoize('P_from_path'); }


#------------------------------------------------------------------------------
# RU = right U

{
  foreach my $k (0 .. 10) {
    my $got = $path->_UNDOCUMENTED_level_to_u_right_line_boundary($k);
    my $want = RU_from_path($path,$k);
    ok ($got,$want);
  }
}

sub RU_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_boundary_length($path, 3 * 2**$k,
                                      side => 'right');
}
BEGIN { memoize('RU_from_path'); }


#------------------------------------------------------------------------------
# BU = total U

{
  foreach my $k (0 .. 10) {
    my $got = $path->_UNDOCUMENTED_level_to_u_line_boundary($k);
    my $want = BU_from_path($path,$k);
    ok ($got,$want);
  }
}

sub BU_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_boundary_length($path, 3 * 2**$k);
}
BEGIN { memoize('BU_from_path'); }


#------------------------------------------------------------------------------
# U

{
  foreach my $k (0 .. 10) {
    my $got = $path->_UNDOCUMENTED_level_to_u_left_line_boundary($k);
    my $want = U_from_path($path,$k);
    ok ($got,$want);
  }
}

{
  # POD samples
  my @want = (3, 6, 8, 12, 20, 32, 52, 88, 148, 248, 420, 712, 1204, 2040);
  foreach my $k (0 .. $#want) {
    my $got = U_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # U[k+1] = U[k] + V[k]

  foreach my $k (0 .. 10) {
    my $u = U_from_path($path,$k);
    my $v = V_from_path($path,$k);
    my $got = $u + $v;
    my $want = U_from_path($path,$k+1);
    ok ($got,$want);
  }
}
{
  # U[k+1] = U[k] + L[k]      k>=1
  foreach my $k (1 .. 10) {
    my $u = U_from_path($path,$k);
    my $l = L_from_path($path,$k);
    my $got = $u + $l;
    my $want = U_from_path($path,$k+1);
    ok ($got,$want);
  }
}
{
  # U[k+4] = 2*U[k+3] - U[k+2] + 2*U[k+1] - 2*U[k]    for k >= 1

  foreach my $k (1 .. 10) {
    my $u0 = U_from_path($path,$k);
    my $u1 = U_from_path($path,$k+1);
    my $u2 = U_from_path($path,$k+2);
    my $u3 = U_from_path($path,$k+3);
    my $got = 2*$u3 - $u2 + 2*$u1 - 2*$u0;
    my $want = U_from_path($path,$k+4);
    ok ($got,$want);
  }
}
{
  # U[k] = L[k+2] - R[k]
  foreach my $k (0 .. 10) {
    my $l = L_from_path($path,$k+2);
    my $r = R_from_path($path,$k);
    my $got = $l - $r;
    my $want = U_from_path($path,$k);
    ok ($got,$want);
  }
}

#------------------------------------------------------------------------------
# B

{
  MyOEIS::poly_parse('1 - 2*x^3');
  my $num = MyOEIS::poly_parse('2 + 2*x^2');
  my $den = MyOEIS::poly_parse('1 - x - 2*x^3')*MyOEIS::poly_parse('1-x');
  print MyOEIS::poly_parse('2 + 2*x^2'),"\n";
  print MyOEIS::poly_parse('1 - x - 2*x^3'),"\n";
  print MyOEIS::poly_parse('1-x'),"\n";
  print $den,"\n";
  exit;
}

{
  # _UNDOCUMENTED_level_to_line_boundary()

  foreach my $k (0 .. 14) {
    my $got = $path->_UNDOCUMENTED_level_to_line_boundary($k);
    my $want = B_from_path($path,$k);
    ok ($got, $want, "_UNDOCUMENTED_level_to_line_boundary() k=$k");
  }
}
{
  # POD samples
  my @want = (2, 4, 8, 16, 28, 48, 84, 144, 244, 416, 708, 1200, 2036);
  foreach my $k (0 .. $#want) {
    my $got = B_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # B[k+4] = 2*B[k+3] - B[k+2] + 2*B[k+1] - 2*B[k]    for k >= 0

  foreach my $k (0 .. 10) {
    my $b0 = B_from_path($path,$k);
    my $b1 = B_from_path($path,$k+1);
    my $b2 = B_from_path($path,$k+2);
    my $b3 = B_from_path($path,$k+3);
    my $got = 2*$b3 - $b2 + 2*$b1 - 2*$b0;
    my $want = B_from_path($path,$k+4);
    ok ($got,$want);
  }
}
{
  # B[k] = L[k] + R[k]

  foreach my $k (0 .. 10) {
    my $l = L_from_path($path,$k);
    my $r = R_from_path($path,$k);
    my $got = $l + $r;
    my $want = B_from_path($path,$k);
    ok ($got,$want);
  }
}

#------------------------------------------------------------------------------
# S = Singles

{
  # S[k] = 1 + B[k]/2

  foreach my $k (0 .. 10) {
    my $got = 1 + B_from_path($path,$k)/2;
    my $want = MyOEIS::path_n_to_singles($path, 2**$k);
    ok ($got,$want);
  }
}
{
  # Single[N] = N+1 - 2*Doubled[N]    points 0 to N inclusive

  my $n_start = $path->n_start;
  for (my $length = 0; $length < 128; $length++) {
    my $n_end = $n_start + $length;
    my $singles = MyOEIS::path_n_to_singles($path, $n_end);
    my $doubles = MyOEIS::path_n_to_doubles($path, $n_end);
    ### $n_start
    ### $n_end
    ### $singles
    ### $doubles
    my $got = $singles + 2*$doubles;
    ok ($got, $length+1);
  }
}
{
  # S[k] recurrence

  foreach my $k (0 .. 10) {
    my $got = S_recurrence($k);
    my $want = MyOEIS::path_n_to_singles($path, 2**$k);
    ok ($got,$want);
  }

  sub S_recurrence {
    my ($k) = @_;
    if ($k < 0) { die; }
    if ($k == 0) { return 2; }
    if ($k == 1) { return 3; }
    if ($k == 2) { return 5; }
    if ($k == 3) { return 9; }
    return (S_recurrence($k-1) + 2*S_recurrence($k-3));
  }
  BEGIN { memoize('S_recurrence'); }
}

#------------------------------------------------------------------------------
# Doubles

{
  foreach my $k (0 .. 10) {
    my $n_limit = 2**$k;
    my $got = $path->_UNDOCUMENTED_level_to_doubled_points($k);
    my $want = MyOEIS::path_n_to_doubles($path, $n_limit);
    ok ($got,$want);
  }
}

# Doubles[N] = Area[N] for all N
{
  foreach my $k (0 .. 10) {
    my $n_limit = 2**$k;
    my $got = A_recurrence($k);
    my $want = MyOEIS::path_n_to_doubles($path, $n_limit);
    ok ($got,$want);
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
{
  # POD samples
  my @want = (1, 2, 4, 8, 12, 20, 36, 60, 100, 172, 292, 492, 836, 1420);
  foreach my $k (0 .. $#want) {
    my $got = L_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # L[k+1] = T[k]

  foreach my $k (0 .. 10) {
    my $l = L_from_path($path,$k+1);
    my $t = T_from_path($path,$k);
    ok ($l,$t);
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
{
  # R[k] = L[k-1] + L[k-2] + ... + L[0] + 1
  my $sum = 1;
  foreach my $k (0 .. 14) {
    my $r = R_from_path($path,$k);
    ok ($sum,$r);

    $sum += L_from_path($path,$k);
  }
}
{
  # POD samples
  my @want = (1, 2, 4, 8, 16, 28, 48, 84, 144, 244, 416, 708, 1200, 2036);
  foreach my $k (0 .. $#want) {
    my $got = R_from_path($path,$k);
    my $want = $want[$k];
    ok ($got,$want);
  }
}
{
  # R[k+4] = 2*R[k+3] - R[k+2] + 2*R[k+1] - 2*R[k]    for k >= 1

  foreach my $k (1 .. 10) {
    my $r0 = R_from_path($path,$k);
    my $r1 = R_from_path($path,$k+1);
    my $r2 = R_from_path($path,$k+2);
    my $r3 = R_from_path($path,$k+3);
    my $got = 2*$r3 - $r2 + 2*$r1 - 2*$r0;
    my $want = R_from_path($path,$k+4);
    ok ($got,$want);
  }
}
{
  # R[k+1] = L[k] + R[k]

  foreach my $k (0 .. 10) {
    my $l = L_from_path($path,$k);
    my $r = R_from_path($path,$k);
    my $got = $l + $r;
    my $want = R_from_path($path,$k+1);
    ok ($got,$want);
  }
}

#------------------------------------------------------------------------------
# 4^k extents in the POD

{
  foreach my $k (1 .. 12) {
    next unless $k & 1;
    my $n_end = 4**$k;
    my ($xmin,$ymin, $xmax,$ymax) = path_n_to_extents_rect($path,$n_end);
    $xmin < $xmax or die;
    $ymin < $ymax or die;

    my $wmin = $xmin;
    my $wmax = $xmax;
    my $lmin = $ymin;
    my $lmax = $ymax;
    foreach (-2 .. $k) {
      ($wmax,$wmin, $lmax,$lmin) = ($lmax,$lmin,  -$wmin,-$wmax);
    }
    $wmin < $wmax or die;
    $lmin < $lmax or die;

    my ($f_lmin,$f_lmax, $f_wmin,$f_wmax) = formula_k_to_lw_extents($k);
    $f_wmin < $f_wmax or die;
    $f_lmin < $f_lmax or die;

    ### $k
    ### xy extents: "$xmin to $xmax    $ymin to $ymax"
    ### lw extents: "$lmin to $lmax    $wmin to $wmax"
    ### lw f exts : "$f_lmin to $f_lmax    $f_wmin to $f_wmax"

    ok ($f_lmin, $lmin, "k=$k");
    ok ($f_lmax, $lmax, "k=$k");
    ok ($f_wmin, $wmin, "k=$k");
    ok ($f_wmax, $wmax, "k=$k");
  }
}

# return ($xmin,$xmax, $ymin,$ymax)
sub formula_k_to_lw_extents {
  my ($k) = @_;
  my $lmax = ($k % 2 == 0
              ? (7*2**$k - 4)/6
              : (7*2**$k - 2)/6);
  my $lmin = ($k % 2 == 0
              ? - (2**$k - 1)/3
              : - (2**$k - 2)/3);
  my $wmax = ($k % 2 == 0
              ? (2*2**$k - 2) / 3
              : (2*2**$k - 1) / 3);
  my $wmin = $lmin;
  return ($lmin,$lmax, $wmin,$wmax);
}

# return ($xmin,$ymin, $xmax,$ymax)
# which is rectangle containing all points n_start() to $n inclusive
sub path_n_to_extents_rect {
  my ($path, $n) = @_;
  my $xmin = 0;
  my $xmax = 0;
  my $ymin = 0;
  my $ymax = 0;
  for my $i ($path->n_start .. $n) {
    my ($x,$y) = $path->n_to_xy($i);
    $xmin = min($xmin,$x);
    $xmax = max($xmax,$x);
    $ymin = min($ymin,$y);
    $ymax = max($ymax,$y);
  }
  return ($xmin,$ymin, $xmax,$ymax);
}

#------------------------------------------------------------------------------
# path calculations

sub B_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit);
  return scalar(@$points);
}
BEGIN { memoize('B_from_path'); }

sub L_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit, side => 'left');
  return scalar(@$points) - 1;
}
BEGIN { memoize('L_from_path'); }

sub R_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my $points = MyOEIS::path_boundary_points($path, $n_limit, side => 'right');
  return scalar(@$points) - 1;
}
BEGIN { memoize('R_from_path'); }

sub T_from_path {
  my ($path, $k) = @_;
  # 2 to 4
  my $n_limit = 2**$k;
  my ($x,$y) = $path->n_to_xy(2*$n_limit);
  my ($to_x,$to_y) = $path->n_to_xy(4*$n_limit);
  my $points = MyOEIS::path_boundary_points_ft($path, 4*$n_limit,
                                               $x,$y, $to_x,$to_y,
                                               dir => 2);
  return scalar(@$points) - 1;
}
BEGIN { memoize('T_from_path'); }

sub U_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my ($x,$y) = $path->n_to_xy(3*$n_limit);
  my ($to_x,$to_y) = $path->n_to_xy(0);
  my $points = MyOEIS::path_boundary_points_ft($path, 3*$n_limit,
                                               $x,$y, $to_x,$to_y,
                                               dir => 1);
  return scalar(@$points) - 1;
}
BEGIN { memoize('U_from_path'); }

sub V_from_path {
  my ($path, $k) = @_;
  my $n_limit = 2**$k;
  my ($x,$y) = $path->n_to_xy(6*$n_limit);
  my ($to_x,$to_y) = $path->n_to_xy(3*$n_limit);
  my $points = MyOEIS::path_boundary_points_ft($path, 8*$n_limit,
                                               $x,$y, $to_x,$to_y,
                                               dir => 0);
  return scalar(@$points) - 1;
}
BEGIN { memoize('V_from_path'); }

sub A_from_path {
  my ($path, $k) = @_;
  return MyOEIS::path_enclosed_area($path, 2**$k);
}
BEGIN { memoize('A_from_path'); }


#------------------------------------------------------------------------------
# Area

sub A_recurrence {
  my ($k) = @_;
  if ($k <= 0) { return 0; }
  if ($k == 1) { return 0; }
  if ($k == 2) { return 0; }
  if ($k == 3) { return 0; }
  if ($k == 4) { return 1; }
  return (4*A_recurrence($k-1)
          - 5*A_recurrence($k-2)
          + 4*A_recurrence($k-3)
          - 6*A_recurrence($k-4)
          + 4*A_recurrence($k-5));
}
memoize('A_from_path');

{
  # A[k] recurrence

  foreach my $k (0 .. 10) {
    my $got = A_recurrence($k);
    my $want = A_from_path($path,$k);
    ok ($got,$want);
  }
}

{
  # A[k] = 2^k - B[k]/2

  foreach my $k (0 .. 10) {
    my $b = B_from_path($path,$k);
    my $got = 2**($k-1) - $b/4;
    my $want = A_from_path($path,$k);
    ok ($got,$want);
  }
}

#------------------------------------------------------------------------------
# subst eliminating U

{
  # L[k+3]-R[k+1] = L[k+2]-R[k] + L[k]     k >= 1

  foreach my $k (1 .. 10) {
    my $lhs = L_from_path($path,$k+3) - R_from_path($path,$k+1);
    my $rhs = (L_from_path($path,$k+2) - R_from_path($path,$k)
               + L_from_path($path,$k));
    ok ($lhs,$rhs);
  }
}

#------------------------------------------------------------------------------
# T

{
  # T[k+1] = U[k] + R[k]

  foreach my $k (0 .. 10) {
    my $r = R_from_path($path,$k);
    my $u = U_from_path($path,$k);
    my $got = $r + $u;
    my $want = T_from_path($path,$k+1);
    ok ($got,$want, "k=$k");
  }
}

#------------------------------------------------------------------------------
# V

{
  # V[k+1] = T[k]

  foreach my $k (0 .. 10) {
    my $v = V_from_path($path,$k+1);
    my $t = T_from_path($path,$k);
    ok ($v,$t);
  }
}


#------------------------------------------------------------------------------
exit 0;
