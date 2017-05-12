#!/usr/bin/perl -w

# Copyright 2011, 2012, 2016 Kevin Ryde

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
use Math::PlanePath::QuintetReplicate;
$|=1;

{
  # X+Y maximum NE in level

  # k=0  0 0   0 0
  # k=1  1,2 1,2   1 1
  # k=2  6,7 11,12   4 4
  # k=3  31,32 111,112   11 21
  # k=4  156,157 1111,1112   24 44
  # k=5  2656,2657 41111,41112   55 210
  # k=6  15156,15157 441111,441112   134 1014
  # k=7  77656,77657 4441111,4441112   295 2140
  # k=8  312031,312032 34441111,34441112   602 4402
  # k=9   1483906,1483907 334441111,334441112   1465 21330
  # k=10  7343281,7343282 3334441111,3334441112   3382 102012

  my $path = Math::PlanePath::QuintetReplicate->new;
  foreach my $k (0 .. 10) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($k);
    my $sum_max = 0;
    my @n_max;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      my $sum = $x+$y;
      if ($sum == $sum_max) {
        push @n_max, $n;
      } elsif ($sum > $sum_max) {
        $sum_max = $sum;
        @n_max = ($n);
      }
    }
    my @n5 = map {cnv($_,10,5)} @n_max;
    my $sum5 = cnv($sum_max,10,5);
    print "k=$k  ",join(',',@n_max)," ",join(',',@n5),"   $sum_max $sum5\n";
  }
  exit 0;
}
{
  require Math::BigInt; Math::BigInt->import(try => 'GMP');
  my $path = Math::PlanePath::QuintetReplicate->new;
  my $n_max = Math::BigInt->new(0);
  my $pow = Math::BigInt->new(1);
  foreach my $k (0 .. 50) {
    my $x_max = 0;
    my $new_n_max = 0;
    foreach my $d (1 .. 4) {
      my $try_n = $n_max + $pow*$d;
      my ($x,$y) = $path->n_to_xy($try_n);
      if ($x > $x_max) {
        $x_max = $x;
        $new_n_max = $try_n;
      }
    }
    $n_max = $new_n_max;
    my $n5 = cnv($n_max,10,5);
    my $x5 = cnv($x_max,10,5);
    print "k=$k  $n_max\n   $n5\n   X=$x_max $x5\n";
    $pow *= 5;
  }
  exit 0;
}
{
  # X maximum in level
  # k=0  0 0   0 0
  # k=1  1 1   1 1
  # k=2  6 11   3 3
  # k=3  106 411   7 12
  # k=4  606 4411   18 33
  # k=5  3106 44411   42 132
  # k=6  15606 444411   83 313
  # k=7  62481 3444411   200 1300
  # k=8  296856 33444411   478 3403
  # k=9  1468731 333444411   1005 13010
  # k=10  5374981 2333444411   2204 32304

  # high digit 1 at b^k, so I^(d-1)*b^k
  # when angle atan(1/2) steps past 90 deg
  # atan(1/2)*180/Pi   \\ 26.565 deg
  # frac(x) = x-floor(x);
  # a=(Pi/2)/atan(1/2)
  # a=atan(1/2)/(Pi/2)
  # a=2*atan(1/2)/Pi
  # 1/h+1/a
  # h = Pi/(2*atan(2))
  # vector(20,n,n--; (floor((a+0)*n+1/2)))
  # vector(20,n,n--; frac(n/a))
  # vector(20,n, (-sum(n=0,n-1,frac((n+1+1/2)/a)<frac((n+1/2)/a)))%4+1)
  # vector(20,n,n--; (-floor(a*n+1/2))%4+1)
  # vector(20,n,n--; (ceil(-a*n-1/2))%4+1)

  my $path = Math::PlanePath::QuintetReplicate->new;
  foreach my $k (0 .. 10) {
    my ($n_lo,$n_hi) = $path->level_to_n_range($k);
    my $x_max = 0;
    my $n_max = 0;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      if ($x > $x_max) {
        $x_max = $x;
        $n_max = $n;
      }
    }
    my $n5 = cnv($n_max,10,5);
    my $x5 = cnv($x_max,10,5);
    print "k=$k  $n_max $n5   $x_max $x5\n";
  }
  exit 0;
}
{
  my $level = 6;
  my $path = Math::PlanePath::QuintetReplicate->new;
  my ($n_lo, $n_hi) = $path->level_to_n_range($level);

  print "\\fill foreach \\p in {";
  foreach my $n ($n_lo .. $n_hi) {
    my ($x,$y) = $path->n_to_xy($n);
    print "($x,$y),";
  }
  print "} ";
  print "{ \\p rectangle +(1,1) };\n";

  exit 0;
}
{
  # min/max for level
  require Math::BaseCnv;
  require Math::PlanePath::QuintetReplicate;
  my $path = Math::PlanePath::QuintetReplicate->new;
  my $prev_min = 1;
  my $prev_max = 1;
  my @mins;
  for (my $level = 0; $level < 20; $level++) {
    my $n_start = 5**$level;
    my $n_end = 5**($level+1) - 1;

    my $min_hypot = 128*$n_end*$n_end;
    my $min_x = 0;
    my $min_y = 0;
    my $min_pos = '';

    my $max_hypot = 0;
    my $max_x = 0;
    my $max_y = 0;
    my $max_pos = '';

    print "level $level  n=$n_start .. $n_end\n";

    foreach my $n ($n_start .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      my $h = $x*$x + $y*$y;
      # my $h = abs($x) + abs($y);

      if ($h < $min_hypot) {
        my $n5 = Math::BaseCnv::cnv($n,10,5) . '[5]';
        $min_hypot = $h;
        $min_pos = "$x,$y  $n $n5";
      }
      if ($h > $max_hypot) {
        my $n5 = Math::BaseCnv::cnv($n,10,5) . '[5]';
        $max_hypot = $h;
        $max_pos = "$x,$y  $n $n5";
      }
    }
    # print "  min $min_hypot   at $min_x,$min_y\n";
    # print "  max $max_hypot   at $max_x,$max_y\n";
    # {
    #   my $factor = $min_hypot / $prev_min;
    #   my $base5 = Math::BaseCnv::cnv($min_hypot,10,5) . '[5]';
    #   print "  min $min_hypot $base5   at $min_pos  factor $factor\n";
    # }
    {
      my $factor = $max_hypot / $prev_max;
      my $base5 = Math::BaseCnv::cnv($max_hypot,10,5) . '[5]';
      print "  max $max_hypot $base5   at $max_pos  factor $factor\n";
    }
    $prev_min = $min_hypot;
    $prev_max = $max_hypot;

    push @mins, $min_hypot;
  }

  print join(',',@mins),"\n";
  exit 0;
}


{
  # Dir4 maximum
  require Math::PlanePath::QuintetReplicate;
  require Math::NumSeq::PlanePathDelta;
  require Math::BigInt;
  require Math::BaseCnv;
  my $path = Math::PlanePath::QuintetReplicate->new;
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath_object => $path,
                                               delta_type => 'Dir4');
  my $dir4_max = 0;
  foreach my $n (0 .. 600000) {
    # my $n = Math::BigInt->new(2)**$level - 1;
    my $dir4 = $seq->ith($n);
    if ($dir4 > $dir4_max) {
      $dir4_max = $dir4;
      my ($dx,$dy) = $path->n_to_dxdy($n);
      my $n5 = Math::BaseCnv::cnv($n,10,5);
      printf "%7s  %2b,\n    %2b %8.6f\n", $n5, abs($dx),abs($dy), $dir4;
    }
  }
  exit 0;
}
