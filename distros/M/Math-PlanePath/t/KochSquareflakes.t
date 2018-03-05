#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
use Test;
plan tests => 382;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::KochSquareflakes;


# uncomment this to run the ### lines
#use Devel::Comments;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 126;
  ok ($Math::PlanePath::KochSquareflakes::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::KochSquareflakes->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::KochSquareflakes->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::KochSquareflakes->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::KochSquareflakes->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::KochSquareflakes->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 1, 'x_negative()');
  ok ($path->y_negative, 1, 'y_negative()');
}

#------------------------------------------------------------------------------
# level_to_n_range()

{
  my $path = Math::PlanePath::KochSquareflakes->new;
  { my ($n_lo,$n_hi) = $path->level_to_n_range(0);
    ok ($n_lo, 1);
    ok ($n_hi, 4); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(1);
    ok ($n_lo, 5);
    ok ($n_hi, 20); }
  { my ($n_lo,$n_hi) = $path->level_to_n_range(2);
    ok ($n_lo, 21);
    ok ($n_hi, 84); }

  foreach my $level (0 .. 6) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($level);
    my ($x_lo,$y_lo) =  $path->n_to_xy($n_lo);
    my ($x_hi,$y_hi) =  $path->n_to_xy($n_hi);
    my $dx = $x_hi - $x_lo;
    my $dy = $y_hi - $y_lo;
    ok($dx,0);
    ok($dy,1);
  }
}

#------------------------------------------------------------------------------
# xy_to_n() coverage

foreach my $inward (0, 1) {
  my $path = Math::PlanePath::KochSquareflakes->new (inward => $inward);
  foreach my $x (-10 .. 10) {
    foreach my $y (-10 .. 10) {
      next if $x == 0 && $y == 0;
      my $n = $path->xy_to_n ($x, $y);
      next if ! defined $n;
      ### $n
      my ($nx,$ny) = $path->n_to_xy ($n);
      ok ($nx,$x, "x=$x,y=$y  n=$n  nxy=$nx,$ny");
      ok ($ny,$y);
    }
  }
}

#------------------------------------------------------------------------------
# Xstart claimed in the POD

foreach my $inward (0, 1) {
  my $path = Math::PlanePath::KochSquareflakes->new (inward => $inward);
  foreach my $level (0 .. 7) {
    my $nstart = (4**($level+1) - 1)/3;
    my ($xstart,$ystart) = $path->n_to_xy ($nstart);
    ok ($xstart, $ystart);
    my $calc_xstart = calc_xstart($level);
    ok ($calc_xstart, $xstart);
  }
}
sub calc_xstart {
  my ($level) = @_;
  if ($level == 0) {
    return -0.5;
  }
  if ($level == 1) {
    return -2;
  }
  my $x1 = -0.5;
  my $x2 = -2;
  foreach (2 .. $level) {
    ($x1,$x2) = ($x2, 4*$x2 - 2*$x1);
  }
  return $x2;
}

exit 0;
