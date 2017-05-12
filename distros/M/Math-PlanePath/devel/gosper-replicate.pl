#!/usr/bin/perl -w

# Copyright 2016 Kevin Ryde

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
use Math::BaseCnv 'cnv';
use Math::Libm 'M_PI', 'hypot';
use Math::PlanePath::GosperReplicate;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


# GP-DEFINE  nearly_equal_epsilon = 1e-15;
# GP-DEFINE  nearly_equal(x,y, epsilon=nearly_equal_epsilon) = \
# GP-DEFINE    abs(x-y) < epsilon;

# GP-DEFINE  b_angle = arg(b)
# not in OEIS: 0.333473172251832115336090
# GP-DEFINE  b_angle_degrees = b_angle * 180/Pi
# not in OEIS: 19.1066053508690943945174
# GP-Test  nearly_equal( b_angle, atan(sqrt3/5) )

# GP-Test  b_angle_degrees > 19.10
# GP-Test  b_angle_degrees < 19.10+1/10^2


{
  require Math::BigInt; Math::BigInt->import(try => 'GMP');
  my $path = Math::PlanePath::GosperReplicate->new;
  my $n_max = Math::BigInt->new(0);
  my $pow = Math::BigInt->new(1);
  foreach my $k (0 .. 50) {
    my $m_max = 0;
    my $new_n_max = 0;
    foreach my $d (1 .. 6) {
      my $try_n = $n_max + $pow*$d;
      my ($x,$y) = $path->n_to_xy($try_n);
      my $m;
      $m = $x;
      $m = $x+$y;  # 30 deg
      ### $try_n
      ### $m
      if ($m > $m_max) {
        $m_max = $m;
        $new_n_max = $try_n;
      }
    }
    $n_max = $new_n_max;
    my $n7 = cnv($n_max,10,7);
    my $m7 = cnv($m_max,10,7);
    print "k=$k  $n_max\n   $n7\n   X=$m_max $m7\n";
    $pow *= 7;
  }
  exit 0;
}
{
  # X maximum in level by points
  # k=0  0 0   0 0
  # k=1  1 1   2 2
  # k=2  8 11   7 10
  # k=3  302 611   20 26
  # k=4  2360 6611   57 111
  # k=5  16766 66611   151 304
  # k=6  100801 566611   387 1062
  # k=7  689046 5566611   1070 3056
  # k=8  4806761 55566611   2833 11155

  my $path = Math::PlanePath::GosperReplicate->new;
  foreach my $k (0 .. 10) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($k);
    my $m_max = 0;
    my $n_max = 0;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      my $m;
      $m = -$x+$y;
      $m = $x;
      $m = $x+3*$y;  # 60 deg
      $m = $x+$y;    # 30 deg
      if ($m > $m_max) {
        $m_max = $m;
        $n_max = $n;
      }
    }
    my $n7 = cnv($n_max,10,7);
    my $m7 = cnv($m_max,10,7);
    print "k=$k  $n_max $n7   $m_max $m7\n";
  }
  exit 0;
}

