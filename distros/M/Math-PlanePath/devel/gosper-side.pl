#!/usr/bin/perl -w

# Copyright 2011, 2014 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use Math::Libm 'M_PI', 'hypot';

{
  # horizontals have count_1_digits == 0 mod 3
  # Easts       have count_1_digits == 0 mod 6
  #
  require Math::PlanePath::GosperSide;
  require Math::BaseCnv;
  my $path = Math::PlanePath::GosperSide->new;

  foreach my $n (0 .. 500) {
    my ($dx,$dy) = $path->n_to_dxdy($n);
    my $n3 = Math::BaseCnv::cnv($n, 10, 3);
    # next if $n3 =~ /1/;
    next if $dy != 0;
    # next if $dx < 0;
    print "$n $n3  $dx $dy\n";
  }
  exit 0;
}

{
  # minimum hypot beyond N=3^level
  #
  require Math::PlanePath::GosperSide;
  require Math::BaseCnv;
  my $path = Math::PlanePath::GosperSide->new;

  my $prev_min_hypot = 1;
  foreach my $level (0 .. 40) {
    my $n_level = 3**$level;

    my $min_n = $n_level;
    my ($x,$y) = $path->n_to_xy($min_n);
    my $min_hypot = hypot($x,sqrt(3)*$y);

    foreach my $n ($n_level .. 1.0001*$n_level) {
      my ($x,$y) = $path->n_to_xy($n);
      my $h = hypot($x,sqrt(3)*$y);
      if ($h < $min_hypot) {
        $min_n = $n;
        $min_hypot = $h;
      }
    }
    my $min_n3 = Math::BaseCnv::cnv($min_n, 10, 3);
    my $factor = $min_hypot / $prev_min_hypot;
    printf "%2d  %8d %15s   %9.2f %7.4f %7.4g\n",
      $level, $min_n, "[$min_n3]", $min_hypot, $factor, $factor-sqrt(7);
    $prev_min_hypot = $min_hypot;
  }
  exit 0;
}

{
  # growth of 3^level hypot
  #
  require Math::PlanePath::GosperSide;
  my $path = Math::PlanePath::GosperSide->new;
  my $prev_angle = 0;
  my $prev_dist = 0;
  foreach my $level (0 .. 20) {
    my ($x,$y) = $path->n_to_xy(3**$level);
    $y *= sqrt(3);
    my $angle = atan2($y,$x);
    $angle *= 180/M_PI();
    if ($angle < 0) { $angle += 360; }
    my $delta_angle = $angle - $prev_angle;
    my $dist = log(hypot($x,$y));
    my $delta_dist = $dist - $prev_dist;
    printf "%d  %d,%d   %.1f  %+.3f   %.3f %+.5f\n",
      $level, $x, $y, $angle, $delta_angle,
        $dist, $delta_dist;

    $prev_angle = $angle;
    $prev_dist = $dist;
  }
  exit 0;
}
