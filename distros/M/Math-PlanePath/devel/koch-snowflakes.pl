#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Math::PlanePath::KochSnowflakes;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # num angles taking points pairwise
  #
  # one direction, so modulo 180
  # can go outside:    3,12,102,906,7980
  # not going outside: 3,12,90,666
  #
  # both directions
  # can go outside:    3,18,155,1370
  # not going outside: 3,18,124,917,6445

  # 12, one direction always X increasing
  # 0,-1  12->6 south
  # 1,-3  12->7
  # 1,-1  12->11
  # 2,-1  14->7
  # 3,-1  12->10
  # 5,-1  14->9
  # 1,0   14->13 east
  # 5,1 3,1 2,1 1,1 1,3
  #
  #            12        
  #           /  \       
  #   14----13    11----10
  #     \              / 
  #      15           9  
  #                    \ 
  #    4---- 5    7---- 8
  #           \  /       
  #             6        

  require Math::Geometry::Planar;
  my $path = Math::PlanePath::KochSnowflakes->new;
  my @values;
  require Math::PlanePath::GcdRationals;
  foreach my $level (0 .. 7) {
    my $n_level = 4**$level;
    my $n_end = 4**($level+1) - 1;
    my @points;
    foreach my $n ($n_level .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      push @points, [$x,$y];
    }

    sub points_equal {
      my ($p1, $p2) = @_;
      return (abs($p1->[0] - $p2->[0]) < 0.00001
              && abs($p1->[1] - $p2->[1]) < 0.00001);
    }

    # Return true if line $p1--$p2 is entirely within the snowflake.
    # If $p1--$p2 intersects any boundary segment then it's not entirely
    # within.
    #

    #  -3,-1 ---- -1,-1
    my $segment_inside = sub {
      my ($p1,$p2) = @_;
      ### segment_inside: join(',',@$p1).'  '.join(',',@$p2)
      foreach my $i (0 .. $#points) {
        my $pint = Math::Geometry::Planar::SegmentIntersection([$p1,$p2, $points[$i-1],$points[$i]]) || next;
        ### intersects: join(',',@{$points[$i-1]}).'  '.join(',',@{$points[$i]}).'  at '.join(',',@$pint)
        if (points_equal($pint,$p1) || points_equal($pint,$p1)
            || points_equal($pint,$points[$i-1]) || points_equal($pint,$points[$i])) {
          ### is an endpoint ...
          next;
        }
        if (Math::Geometry::Planar::Colinear([$p1,$pint,$points[$i]])) {
          ### but colinear ...
          next;
        }
        ### no, crosses boundary ...
        return 0;
      }
      ### yes, all inside ...
      return 1;
    };

    my %seen;
    foreach my $i (0 .. $#points) {
      foreach my $j ($i+1 .. $#points) {
        ### pair: "$i -- $j"

        my $p1 = $points[$i];
        my $p2 = $points[$j];
        my $dx = $p1->[0] - $p2->[0];
        my $dy = $p1->[1] - $p2->[1];

        my $rdx = $dx;
        my $rdy = $dy;

        if ($rdx < 0 || ($rdx == 0 && $rdy < 0)) {
          $rdx = -$rdx;
          $rdy = -$rdy;
        }

        my $g = Math::PlanePath::GcdRationals::_gcd($rdx,$rdy);
        $rdx /= $g;
        $rdy /= $g;
        next if $seen{"$rdx,$rdy"};

        next unless $segment_inside->($p1, $p2);

        $seen{"$rdx,$rdy"} = 1;
      }
    }
    my $count = scalar(keys %seen);

    if ($count <= 12) {
      my @strs = keys %seen;
      @strs = sort strpoint_cmp_by_atan2 @strs;
      print join(' ',@strs),"\n";
    }

    push @values, $count;
    print "$level $count\n";
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub strpoint_cmp_by_atan2 {
    my ($ax,$ay) = split /,/, $a;
    my ($bx,$by) = split /,/, $b;
    return atan2($ay,$ax) <=> atan2($by,$bx);
  }
}

{
  # num acute angle turns, being num right hand turns
  # A178789

  my $path = Math::PlanePath::KochSnowflakes->new;
  my @values;
  require Math::NumSeq::PlanePathTurn;
  foreach my $level (0 .. 8) {
    my $n_level = 4**$level;
    my $n_end = 4**($level+1) - 1;
    my @x;
    my @y;
    foreach my $n ($n_level .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      push @x, $x;
      push @y, $y;
    }
    my $count = 0;
    foreach my $i (0 .. $#x) {
      my $dx = $x[$i-1] - $x[$i-2];
      my $dy = $y[$i-1] - $y[$i-2];
      my $next_dx = $x[$i] - $x[$i-1];
      my $next_dy = $y[$i] - $y[$i-1];
      my $tturn6 = Math::NumSeq::PlanePathTurn::_turn_func_TTurn6($dx,$dy, $next_dx,$next_dy);
      ### $tturn6
      if ($tturn6 == 2 || $tturn6 == 4) {
        $count++;
      }
    }
    $count = ($n_end - $n_level + 1) - $count;  # non-acute ones
    push @values, $count;
    my $calc = 4**$level + 2;
    print "$level $count $calc\n";
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}
{
  # num lines at 60deg angles, A110593 2*3^n
  # 3,6,18,54,162
  # 18*3=54
  #
  my $path = Math::PlanePath::KochSnowflakes->new;
  my @values;
  require Math::NumSeq::PlanePathDelta;
  foreach my $level (0 .. 7) {
    my $n_level = 4**$level;
    my $n_end = 4**($level+1) - 1;
    my %seen;
    foreach my $n ($n_level .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      my ($dx,$dy) = $path->n_to_dxdy($n);
      if ($n == $n_end) {
        my ($x2,$y2) = $path->n_to_xy($n_level);
        $dx = $x2 - $x;
        $dy = $y2 - $y;
      }
      my $tdir6 = Math::NumSeq::PlanePathDelta::_delta_func_TDir6($dx,$dy);
      my $value;
      if ($tdir6 % 3 == 0) {
        $value = "H-$y";
      } elsif ($tdir6 % 3 == 1) {
        $value = "I-".($x-$y);
      } else {
        $value = "J-".($x+$y);
      }
      # print "  $n $value\n";
      $seen{$value} = 1;
    }
    my $count = scalar(keys %seen);
    push @values, $count;
    print "$level $count\n";
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # area
  require Math::Geometry::Planar;
  my $path = Math::PlanePath::KochSnowflakes->new;
  my @values;
  my $prev_a_log = 0;
  my $prev_len_log = 0;

  # area of an equilateral triangle of side length 1
  use constant AREA_EQUILATERAL_1 => sqrt(3)/4;

  foreach my $level (0 .. 7) {
    my $n_level = 4**$level;
    my $n_end = 4**($level+1) - 1;
    my @points;
    foreach my $n ($n_level .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      # ($x,$y) = triangular_to_unit_side($x,$y);
      push @points, [$x,$y];
    }
    my $polygon = Math::Geometry::Planar->new;
    $polygon->points(\@points);
    my $a = $polygon->area;
    my $len = $polygon->perimeter;

    # $a /= 3**$len;
    # $len /= sqrt(3)**$len;

    my $a_log = log($a);
    my $len_log = log($len);

    my $d_a_log = $a_log - $prev_a_log;
    my $d_len_log = $len_log - $prev_len_log;
    my $f = $d_a_log / $d_len_log;

    # $a /= AREA_EQUILATERAL_1();

    print "$level  $a\n";
    # print "$level  $d_len_log  $d_a_log   $f\n";
    push @values, $a;

    $prev_a_log = $a_log;
    $prev_len_log = $len_log;
  }
  shift @values;
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub triangular_to_unit_side {
    my ($x,$y) = @_;
    return ($x/2, $y*(sqrt(3)/2));
  }
}

{
  # area
  print sqrt(48)/10,"\n";
  my $sum = 0;
  foreach my $level (1 .. 10) {
    my $area = (1 + 3/9*$sum) * sqrt(3)/4;
    print "$level $area\n";
    $sum += (4/9)**$level;
  }
  exit 0;
}

{
  # X axis N increasing
  my $path = Math::PlanePath::KochSnowflakes->new;
  my $prev_n = 0;
  foreach my $x (0 .. 10000000) {
    my $n = $path->xy_to_n($x,0) // next;
    if ($n < $prev_n) {
      print "decrease N at X=$x N=$n prev_N=$prev_n\n";
    }
    $prev_n = $n;
  }
}
