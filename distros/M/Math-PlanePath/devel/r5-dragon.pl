#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

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
use Math::BaseCnv;
use List::MoreUtils;
use POSIX 'floor';
use Math::Libm 'M_PI', 'hypot';
use List::Util 'min', 'max';
use Math::PlanePath::R5DragonCurve;
use Math::BigInt try => 'GMP';
use Math::BigFloat;

use lib 'devel/lib';
use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # partial fractions
  require Math::Polynomial;
  Math::Polynomial->string_config({ascending=>1});

  # x^3/((x-1)*(2*x-1)*(x^2-x+1))

  require Math::Complex;
  my $b = Math::Complex->make(1,1);
  my @numerators = MyOEIS::polynomial_partial_fractions
    (Math::Polynomial->new(Math::Complex->make(  3,  -2),
                           Math::Complex->make(-10,   1),
                           Math::Complex->make( 11,   5),
                           Math::Complex->make(  2, -24),
                           Math::Complex->make(-18,  18),
                           Math::Complex->make(  8, -16),
                           Math::Complex->make( 16, -32),
                          ), # numerator
     # ((   16 - 32*I)*x^6
     #  + (  8 - 16*I)*x^5
     #  + (-18 + 18*I)*x^4
     #  + (  2 - 24*I)*x^3
     #  + ( 11 +  5*I)*x^2
     #  + (-10 +    I)*x
     #  + (  3 -  2*I))
     Math::Polynomial->new(1,-$b),            # 1-b*x
     Math::Polynomial->new(1,1)**2,              # 1+x
     Math::Polynomial->new(1,-2,2)**2,           # 1 - 2x + 2x^2
     Math::Polynomial->new(1, -$b, -2*$b**3), # 1 - b*x - 2*b^3*x^3
    );
  print "@numerators\n";

  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (Math::Polynomial->new(0,0,0,3), # numerator x^3
  #    Math::Polynomial->new(1,-1),     # 1-x
  #    Math::Polynomial->new(1,-2),     # 1-2x
  #    Math::Polynomial->new(1, -1, 1), # 1 - x + x^2
  #   );
  # print "@numerators\n";

  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (1640 * Math::Polynomial->new(1), # numerator 1
  #    Math::Polynomial->new(1,-1),     # 1-x
  #    Math::Polynomial->new(1, 1),     # 1+x
  #    Math::Polynomial->new(1, -2, 2), # 1 - 2*x + 2*x^2
  #   );
  # print "@numerators\n";

  # use Math::BigRat;
  # my $o = Math::BigRat->new(1);
  # $o = 1;
  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (1640 * Math::Polynomial->new(0*$o/10, 65*$o/10, 18*$o/10, 13*$o/10), # numerator 13*x^2 + 18*x + 65
  #    Math::Polynomial->new(25*$o, 6*$o, 1*$o),  # (25 + 6*x + x^2)
  #    Math::Polynomial->new(1*$o, -5*$o),        #  * (1-5*x)
  #    Math::Polynomial->new(1*$o, -1*$o));       # (1-x)
  # print "@numerators\n";

  # dragon dir N touching next level
  # p = (1-2*x^3)/(1-2*x-x^3+2*x^4)
  # (1-2*x^3)/((1-2*x)*(1-x)*(1+x+x^2)) * 21 == (18+12*x)/(1+x+x^2) + 3/(1-2*x)
  # p*21 == ((3 + 6*x + 12*x^2)/(1-x^3) + 3/(1-2*x)
  # p*21 == (-4 -5*x)/(1+x+x^2) + 7/(1-x) + 18/(1-2*x)

  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (21 * Math::Polynomial->new(1,0,0,-2), # numerator 1-2*x^3
  #     Math::Polynomial->new(1,0,0,-1),     # 1-x^3
  #    # Math::Polynomial->new(1,1,1),    # 1+x+x^2
  #    # Math::Polynomial->new(1,-1),     # 1-x
  #    Math::Polynomial->new(1,-2));    # 1-2x
  # print "@numerators\n";

  # # dragon JA[k] area
  # # x^4/ ((1 - x - 2*x^3)*(1-x)*(1-2*x))
  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (Math::Polynomial->new(1),         # numerator
  #    Math::Polynomial->new(1,-1,0,-2), # 1-x-2*x^3
  #    Math::Polynomial->new(1,-1));     # 1-x
  # print "@numerators\n";

  # # dragon A[k] area
  # # x^4/ ((1 - x - 2*x^3)*(1-x)*(1-2*x))
  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (Math::Polynomial->new(2),         # numerator
  #    Math::Polynomial->new(1,-1,0,-2), # 1-x-2*x^3
  #    Math::Polynomial->new(1,-2),      # 1-2*x
  #    Math::Polynomial->new(1,-1));     # 1-x
  # print "@numerators\n";

  # # dragon B[k]=R[k+1] total boundary
  # # (4 + 2 x + 4 x^2)/(1-x-2*x^3) +  (-2)/(1-x)
  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (Math::Polynomial->new(2,0,2),     # numerator reduced 2*x + 2*x^3
  #    Math::Polynomial->new(1,-1,0,-2), # 1-x-2*x^3
  #    Math::Polynomial->new(1,-1));     # 1-x
  # print "@numerators\n";

  # # dragon R right boundary
  # my @numerators = MyOEIS::polynomial_partial_fractions
  #   (Math::Polynomial->new(1,0,1,0,2),
  #    Math::Polynomial->new(1,-1,0,-2),
  #    Math::Polynomial->new(1,-1));
  # print "@numerators\n";
  exit 0;
}

{
  # convex hull
  # hull 8 new vertices

  require Math::Geometry::Planar;
  my $points = [ [0,0], [1,0], [0,0] ];
  $points = [ [Math::BigInt->new(0), Math::BigInt->new(0)],
              [Math::BigInt->new(1), Math::BigInt->new(0)],
              [Math::BigInt->new(0), Math::BigInt->new(0)] ];
  my $end_x = Math::BigInt->new(1);
  my $end_y = Math::BigInt->new(0);

  my $path = Math::PlanePath::R5DragonCurve->new;
  my $num_points_prev = 0;
  for (my $k = Math::BigInt->new(0);
       $k < 40;
       $k++) {
    my $angle = 0; # Math::BigFloat->new($end_y)->batan2(Math::BigFloat->new($end_x), 10);
    my $num_points = scalar(@$points);
    my $num_points_diff = $num_points - $num_points_prev;
    print "k=$k end=$end_x,$end_y a=$angle  $num_points diff=$num_points_diff\n";

    my @new_points = @$points;
    {
      my $p = Math::Geometry::Planar->new;
      $p->points(points_copy($points));
      $p->move (-$end_y, $end_x);
      push @new_points, @{$p->points};
      ### move 1: $p->points
    }
    {
      my $p = Math::Geometry::Planar->new;
      $p->points(points_copy($points));
      $p->move (2*-$end_y, 2*$end_x);
      push @new_points, @{$p->points};
      ### move 2: $p->points
    }
    {
      my $p = Math::Geometry::Planar->new;
      $p->points(points_copy($points));
      planar_rotate_plus90($p);
      push @new_points, @{$p->points};
      ### rot: $p->points
    }
    {
      my $p = Math::Geometry::Planar->new;
      $p->points(points_copy($points));
      planar_rotate_plus90($p);
      $p->move ($end_x + -$end_y, $end_y + $end_x);
      push @new_points, @{$p->points};
      ### rot move: $p->points
    }

    my $p = Math::Geometry::Planar->new;
    $p->points(\@new_points);
    $p = $p->convexhull2;
    $points = $p->points;

    ($end_x,$end_y) = ($end_x - 2*$end_y,
                       $end_y + 2*$end_x);
    $num_points_prev = $num_points;

    my ($x,$y) = $path->n_to_xy(5**($k+1));
    ### $end_y
    ### $y
    $x == $end_x or die;
    $y == $end_y or die;
  }
  exit 0;

  sub planar_rotate_plus90 {
    my ($planar) = @_;
    my $points = $planar->points;
    foreach my $p (@$points) {
      ($p->[0],$p->[1]) = (- $p->[1], $p->[0]);
    }
    return $planar;
  }

  sub points_copy {
    my ($points) = @_;
    return [ map {[$_->[0],$_->[1]]} @$points ];
  }
  # {
  #   my $pl = Math::Geometry::Planar->new;
  #   $pl->points($points);
  #   $pl->rotate(- atan2(2,1));
  #   $pl->scale(1/sqrt(5));
  #   $points = $pl->points;
  # }
}

{
  # extents  h->4/5 w->2/5

  #            1/sqrt(5)
  #           *--*              1/5 + 4/5 = 1
  # 2/sqrt(5) | /  1
  #           |/
  #           *
  #
  my $h = 0;
  my $w = 0;
  my $sum = 0;
  foreach my $k (0 .. 20) {
    print "$h $w $sum\n";
    $sum += (3/5)**$k;
    $h /= sqrt(5);
    $w /= sqrt(5);
    my $s = 1/sqrt(5);
    my $add = $s * 2/sqrt(5);
    ($h, $w) = ($h*2/sqrt(5) + $w*1/sqrt(5) + $add,
                $h*2/sqrt(5) + $w*1/sqrt(5));
  }
  exit 0;
}

{
  # min/max for level

  # radial extent
  #
  # dist0to5 = sqrt(1*1+2*2) = sqrt(5)
  #
  #   4-->5
  #   ^
  #   |
  #   3<--2
  #       ^
  #       |
  #   0-->1
  #
  # Rlevel = sqrt(5)^level + Rprev
  #        = sqrt(5) + sqrt(5)^2 + ... + sqrt(5)^(level-1) + sqrt(5)^level
  # if level 
  #        = sqrt(5) + sqrt(5)^2 + sqrt(5)*sqrt(5)^2 + ... 
  #        = sqrt(5) + (1+sqrt(5))*5^1 + (1+sqrt(5))*5^2 + ... 
  #        = sqrt(5) + (1+sqrt(5))* [ 5^1 + 5^2 + ... ]
  #        = sqrt(5) + (1+sqrt(5))* (5^k - 1)/4
  #        <= 5^k
  # Rlevel^2 <= 5^level

  require Math::BaseCnv;
  require Math::PlanePath::R5DragonCurve;
  my $path = Math::PlanePath::R5DragonCurve->new;
  my $prev_min = 1;
  my $prev_max = 1;
  for (my $level = 1; $level < 10; $level++) {
    my $n_start = 5**($level-1);
    my $n_end = 5**$level;

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

      if ($h < $min_hypot) {
        $min_hypot = $h;
        $min_pos = "$x,$y";
      }
      if ($h > $max_hypot) {
        $max_hypot = $h;
        $max_pos = "$x,$y";
      }
    }
    # print "  min $min_hypot   at $min_x,$min_y\n";
    # print "  max $max_hypot   at $max_x,$max_y\n";
    {
      my $factor = $min_hypot / $prev_min;
      my $min_hypot_5 = Math::BaseCnv::cnv($min_hypot,10,5);
      print "  min r^2 $min_hypot ${min_hypot_5}[5]  at $min_pos  factor $factor\n";
    }
    {
      my $factor = $max_hypot / $prev_max;
      my $max_hypot_5 = Math::BaseCnv::cnv($max_hypot,10,5);
      print "  max r^2 $max_hypot ${max_hypot_5}[5])  at $max_pos  factor $factor\n";
    }
    $prev_min = $min_hypot;
    $prev_max = $max_hypot;
  }
  exit 0;
}
{
  # boundary length between arms = 2*3^k
  #
  #         *---1    length=6
  #         |
  # 2   *---*---*
  # |   |   |   |
  # *---*   0---*
  #
  # T[0] = 2
  # T[k+1] = R[k] + T[k] + U[k]
  # T[k+1] = 4*3^k + T[k]
  #              i=k-1
  # T[k] = 2 +  sum    4*3^i
  #              i=0
  #      = 2 + 4*(3^k - 1)/(3-1)
  #      = 2 + 2*(3^k - 1)
  #      = 2*3^k

  my $arms = 2;
  my $path = Math::PlanePath::R5DragonCurve->new (arms => $arms);
  my @values;
  foreach my $k (0 .. 8) {
    my $n_limit = $arms * 5**$k + $arms-1;
    my $n_from = $n_limit-1;
    my $n_to = $n_limit;
    print "k=$k  n_limit=$n_limit\n";
    my $points = MyOEIS::path_boundary_points_ft ($path, $n_limit,
                                                  $path->n_to_xy($n_from),
                                                  $path->n_to_xy($n_to),
                                                  side => 'right',
                                                 );
    if (@$points < 10) {
      foreach my $p (@$points) {
        print " $p->[0],$p->[1]";
      }
      print "\n";
    }
    my $length = scalar(@$points) - 1;
    print "  length $length\n";
    push @values, $length;
  }

  shift @values;
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # right boundary N

  my $path = Math::PlanePath::R5DragonCurve->new;
  my %non_values;
  my %n_values;
  my @n_values;
  my @values;
  foreach my $k (3){
    my $n_limit = 5**$k;
    print "k=$k  n_limit=$n_limit\n";
    foreach my $n (0 .. $n_limit-1) {
      $non_values{$n} = 1;
    }
    my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                               side => 'right',
                                              );
    ### $points
    for (my $i = 0; $i+1 <= $#$points; $i++) {
      my ($x,$y) = @{$points->[$i]};
      my ($x2,$y2) = @{$points->[$i+1]};
      # my @n_list = $path->xy_to_n_list($x,$y);
      my @n_list = path_xyxy_to_n($path, $x,$y, $x2,$y2);
      foreach my $n (@n_list) {
        delete $non_values{$n};
        if ($n <= $n_limit) { $n_values{$n} = 1; }
        my $n5 = Math::BaseCnv::cnv($n,10,5);
        my $pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n);
        my $diff = $pred ? '' : '  ***';
        if ($k <= 4) { print "$n  $n5$diff\n"; }
      }
    }
    @n_values = keys %n_values;
    @n_values = sort {$a<=>$b} @n_values;
    my @non_values = keys %non_values;
    @non_values = sort {$a<=>$b} @non_values;
    my $count = scalar(@n_values);
    print "count $count\n";

    # push @values, $count;
    @values = @n_values;

    if ($k <= 4) {
      foreach my $n (@non_values) {
        my $pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n);
        my $diff = $pred ? '  ***' : '';
        my $n5 = Math::BaseCnv::cnv($n,10,5);
        print "non $n  $n5$diff\n";
      }
    }
    # @values = @non_values;

    # print "func ";
    # foreach my $i (0 .. $count-1) {
    #   my $n = $path->_UNDOCUMENTED__right_boundary_i_to_n($i);
    #   my $n5 = Math::BaseCnv::cnv($n,10,5);
    #   print "$n,";
    # }
    # print "\n";

    print "vals ";
    foreach my $i (0 .. $count-1) {
      my $n = $values[$i];
      my $n5 = Math::BaseCnv::cnv($n,10,5);
      print "$n,";
    }
    print "\n";
  }

  @values = MyOEIS::first_differences(@values);
  shift @values;
  shift @values;
  shift @values;
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub path_xyxy_to_n {
    my ($path, $x1,$y1, $x2,$y2) = @_;
    ### path_xyxy_to_n(): "$x1,$y1, $x2,$y2"
    my @n_list = $path->xy_to_n_list($x1,$y1);
    ### @n_list
    my $arms = $path->arms_count;
    foreach my $n (@n_list) {
      my ($x,$y) = $path->n_to_xy($n + $arms);
      if ($x == $x2 && $y == $y2) {
        return $n;
      }
    }
    return;
  }
}

{
  my $C = sub {
    my ($k) = @_;
    return 3**$k - $k;    # A024024
  };
  my $E = sub {
    my ($k) = @_;
    return 3**$k + $k;    # A104743
  };
  my @values = map { $E->($_) } 0 .. 10;
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit;
}

{
  # left boundary N

  my $path = Math::PlanePath::R5DragonCurve->new;
  my %non_values;
  my %n_values;
  my @n_values;
  my @values;
  foreach my $k (2) {
    my $n_limit = 3*5**$k;
    print "k=$k  n_limit=$n_limit\n";
    foreach my $n (0 .. $n_limit-1) {
      $non_values{$n} = 1;
    }
    my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                               side => 'left',
                                              );
    @$points = reverse @$points; # for left
    ### $points
    for (my $i = 0; $i+1 <= $#$points; $i++) {
      my ($x,$y) = @{$points->[$i]};
      my ($x2,$y2) = @{$points->[$i+1]};
      # my @n_list = $path->xy_to_n_list($x,$y);
      my @n_list = path_xyxy_to_n($path, $x,$y, $x2,$y2);
      foreach my $n (@n_list) {
        delete $non_values{$n};
        if ($n <= $n_limit) { $n_values{$n} = 1; }
        my $n5 = Math::BaseCnv::cnv($n,10,5);
        my $pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n);
        my $diff = $pred ? '' : '  ***';
        if ($k <= 4) { print "$n  $n5$diff\n"; }
      }
    }
    @n_values = keys %n_values;
    @n_values = sort {$a<=>$b} @n_values;
    my @non_values = keys %non_values;
    @non_values = sort {$a<=>$b} @non_values;
    my $count = scalar(@n_values);
    print "count $count\n";

    # push @values, $count;
    @values = @n_values;

    if ($k <= 4) {
      foreach my $n (@non_values) {
        my $pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n);
        my $diff = $pred ? '  ***' : '';
        my $n5 = Math::BaseCnv::cnv($n,10,5);
        print "non $n  $n5$diff\n";
      }
    }
    # @values = @non_values;

    # print "func ";
    # foreach my $i (0 .. $count-1) {
    #   my $n = $path->_UNDOCUMENTED__left_boundary_i_to_n($i);
    #   my $n5 = Math::BaseCnv::cnv($n,10,5);
    #   print "$n,";
    # }
    # print "\n";

    print "vals ";
    foreach my $i (0 .. $count-1) {
      my $n = $values[$i];
      my $n5 = Math::BaseCnv::cnv($n,10,5);
      print "$n5,";
    }
    print "\n";
  }

  # @values = MyOEIS::first_differences(@values);
  shift @values;
  shift @values;
  shift @values;
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}


{
  # recurrence
  # v3 = a*v0 + b*v1 + c*v2
  #  [v0 v1 v2] [a]   [v3]
  #  [v1 v2 v3] [b] = [v4]
  #  [v2 v3 v4] [c]   [v5]
  #  [a]   [v0 v1 v2] -1   [v1]
  #  [b] = [v1 v2 v3]    * [v2]
  #  [c]   [v2 v3 v4]      [v3]

  $|=1;
  my @array = (
54,90,150,250,422,714,1206,2042,3462
              );
  # @array = ();
  # foreach my $k (5 .. 10) {
  #   push @array, R_formula(2*$k+1);
  # }
  # require MyOEIS;
  # my $path = Math::PlanePath::R5DragonCurve->new;
  # foreach my $k (0 .. 30) {
  #   my $value = MyOEIS::path_boundary_length($path, 5**$k,
  #                                            # side => 'left',
  #                                           );
  #   last if $value > 10_000;
  #   push @array, $value;
  #   print "$value,";
  # }
  print "\n";
  array_to_recurrence_pari(\@array);
  print "\n";
  my @recurr = array_to_recurrence(\@array);
  print join(', ',@recurr),"\n";
  exit 0;

  sub array_to_recurrence_pari {
    my ($aref) = @_;
    my $order = int(scalar(@array)/2); # 2*order-1 = @array-1
    my $str = "m=[";
    foreach my $i (0 .. $order-1) {
      if ($i) { $str .= "; " }
      foreach my $j (0 .. $order-1) {
        if ($j) { $str .= "," }
        $str .= $aref->[$i+$j];
      }
    }
    $str .= "]\n";
    $str .= "v=[";
    foreach my $i ($order .. 2*$order-1) {
      if ($i > $order) { $str .= ";" }
      $str .= $aref->[$i];
    }
    $str .= "];";
    $str .= "(m^-1)*v\n";
    print $str;
    require IPC::Run;
    IPC::Run::run(['gp'],'<',\$str);
  }
  sub array_to_recurrence {
    my ($aref) = @_;
    # 2*order-1 = @array-1
    my $order = int(scalar(@array)/2);
    require Math::Matrix;
    my $m = Math::Matrix->new(map {[
                                    map { $array[$_]
                                        } $_ .. $_+$order-1
                                   ]}
                              0 .. $order-1);
    print $m;
    print $m->determinant,"\n";

    my $v = Math::Matrix->new(map {[ $array[$_] ]} $order .. 2*$order-1);
    print $v;

    $m = $m->invert;
    print $m;

    $v = $m*$v;
    print $v;
    return (map {$v->[$_][0]} reverse 0 .. $order-1);
  }
}
{
  # at N=29
  require Math::NumSeq::PlanePathDelta;
  require Math::PlanePath::R5DragonMidpoint;
  my $path = Math::PlanePath::R5DragonMidpoint->new;
  my $n = 29;
  my ($x,$y) = $path->n_to_xy($n);
  my ($dx,$dy) = $path->n_to_dxdy($n);
  my $tradius = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n);
  my $next_tradius = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n + $path->arms_count);
  my $dtradius = Math::NumSeq::PlanePathDelta::_path_n_to_dtradius($path,$n);
  print "$n  x=$x,y=$y   $dx,$dy  dtradius=$dtradius\n";
  print "   tradius $tradius to $next_tradius\n";
  exit 0;
}

{
  # first South step dY=-1 on Y axis

  require Math::PlanePath::R5DragonMidpoint;
  my $path = Math::PlanePath::R5DragonMidpoint->new;

  require Math::NumSeq::PlanePathDelta;
  my $seq = Math::NumSeq::PlanePathDelta->new (path => $path);

  my @values;
  my $n = 0;
 OUTER: for ( ; ; $n++) {
    my ($x,$y) = $path->n_to_xy($n);
    my ($dx,$dy) = $path->n_to_dxdy($n);

    if ($x == 0 && $dx == 0 && $dy == -($y < 0 ? -1 : 1)) {
      my $tradius = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n);
      my $next_tradius = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n + $path->arms_count);
      my $dtradius = Math::NumSeq::PlanePathDelta::_path_n_to_dtradius($path,$n);
      print "$n  $x,$y   $dx,$dy  dtradius=$dtradius\n";
      print "   tradius $tradius to $next_tradius\n";
      push @values, $n;
      last OUTER if @values > 20;
    }
  }

  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}
{
  # any South step dY=-1 on Y axis

  # use Math::BigInt try => 'GMP';
  # use Math::BigFloat;

  require Math::PlanePath::R5DragonMidpoint;
  my $path = Math::PlanePath::R5DragonMidpoint->new;

  require Math::NumSeq::PlanePathDelta;
  my $seq = Math::NumSeq::PlanePathDelta->new (path => $path);

  my @values;
  my $x = 0;
  my $y = 0;
  # $x = Math::BigFloat->new($x);
  # $y = Math::BigFloat->new($y);

  OUTER: for ( ; ; $y++) {
    ### y: "$y"
    foreach my $sign (1,-1) {
      ### at: "$x, $y  sign=$sign"
      if (defined (my $n = $path->xy_to_n($x,$y))) {
        my ($dx,$dy) = $path->n_to_dxdy($n);
        ### dxdy: "$dx, $dy"
        if ($dx == 0 && $dy == $sign) {
          my $tradius = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n);
          my $next_tradius = Math::NumSeq::PlanePathCoord::_path_n_to_tradius($path,$n + $path->arms_count);
          my $dtradius = Math::NumSeq::PlanePathDelta::_path_n_to_dtradius($path,$n);
          print "$n  $x,$y   $dx,$dy  dtradius=$dtradius\n";
          print "   tradius $tradius to $next_tradius\n";
          push @values, $y;
          last OUTER if @values > 20;
        }
      }
      $y = -$y;
    }
  }

  print join(',',@values),"\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}
{
  # boundary join 4,13,40,121,364
  # A003462 (3^n - 1)/2.

  require Math::PlanePath::R5DragonCurve;
  my $path = Math::PlanePath::R5DragonCurve->new;
  my @values;
  $| = 1;
  foreach my $exp (2 .. 6) {
    my $t_lo = 5**$exp;
    my $t_hi = 2*5**$exp - 1;
    my $count = 0;
    foreach my $n (0 .. $t_lo-1) {
      my ($x,$y) = $path->n_to_xy($n);
      my @n_list = $path->xy_to_n_list($x,$y);
      if (@n_list >= 2
          && $n_list[0] < $t_lo
          && $n_list[1] >= $t_lo
          && $n_list[1] < $t_hi) {
        $count++;
      }
    }
    push @values, $count;
    print "$count,";
  }
  print "\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}
{
  # overlaps
  require Math::PlanePath::R5DragonCurve;
  require Math::BaseCnv;

  my $path = Math::PlanePath::R5DragonCurve->new;
  my $width = 5;
  foreach my $n (0 .. 5**($width-1)) {
    my ($x,$y) = $path->n_to_xy($n);
    my @n_list = $path->xy_to_n_list($x,$y);
    next unless @n_list >= 2;

    if ($n_list[1] == $n) { ($n_list[0],$n_list[1]) = ($n_list[1],$n_list[0]); }
    my $n_list = join(',',@n_list);
    my @n5_list = map { sprintf '%*s', $width, Math::BaseCnv::cnv($_,10,5) } @n_list;
    print "$n5_list[0]  $n5_list[1]  ($n_list)\n";
  }
  exit 0;
}
{
  # tiling

  require Image::Base::Text;
  require Math::PlanePath::R5DragonCurve;
  my $path = Math::PlanePath::R5DragonCurve->new;

  my $width = 37;
  my $height = 21;
  my $image = Image::Base::Text->new (-width => $width,
                                      -height => $height);
  my $xscale = 3;
  my $yscale = 2;
  my $w2 = int(($width+1)/2);
  my $h2 = int($height/2);
  $w2 -= $w2 % $xscale;
  $h2 -= $h2 % $yscale;

  my $affine = sub {
    my ($x,$y) = @_;
    return ($x*$xscale + $w2,
            -$y*$yscale + $h2);
  };

  my ($n_lo, $n_hi) = $path->rect_to_n_range(-$w2/$xscale, -$h2/$yscale,
                                             $w2/$xscale, $h2/$yscale);
  print "n to $n_hi\n";
  foreach my $n ($n_lo .. $n_hi) {
    next if ($n % 5) == 2;
    my ($x,$y) = $path->n_to_xy($n);
    my ($next_x,$next_y) = $path->n_to_xy($n+1);
    foreach (1 .. 4) {
      $image->line ($affine->($x,$y),
                    $affine->($next_x,$next_y),
                    ($x==$next_x ? '|' : '-'));

      $image->xy ($affine->($x,$y),
                  '+');
      $image->xy ($affine->($next_x,$next_y),
                  '+');

      ($x,$y) = (-$y,$x); # rotate +90
      ($next_x,$next_y) = (-$next_y,$next_x); # rotate +90
    }
  }
  $image->xy ($affine->(0,0),
              'o');

  foreach my $x (0 .. $width-1) {
    foreach my $y (0 .. $height-1) {
      next unless $image->xy($x,$y) eq '+';

      if ($x > 0 && $image->xy($x-1,$y) eq ' ') {
        $image->xy($x,$y, '|');
      } elsif ($x < $width-1 && $image->xy($x+1,$y) eq ' ') {
        $image->xy($x,$y, '|');

      } elsif ($y > 0 && $image->xy($x,$y-1) eq ' ') {
        $image->xy($x,$y, '-');
      } elsif ($y < $height-1 && $image->xy($x,$y+1) eq ' ') {
        $image->xy($x,$y, '-');
      }
    }
  }
  $image->save('/dev/stdout');
  exit 0;
}
{
  # area recurrence
  foreach my $i (0 .. 10) {
    print recurrence($i),",";
  }
  print "\n";

  print "wrong():              ";
  foreach my $i (0 .. 10) { print wrong($i),","; }
  print "\n";

  print "recurrence_area815(): ";
  foreach my $i (0 .. 10) { print recurrence_area815($i),","; }
  print "\n";

  print "recurrence_area43():  ";
  foreach my $i (0 .. 10) { print recurrence_area43($i),","; }
  print "\n";
  print "formula_pow():        ";
  foreach my $i (0 .. 10) { print formula_pow($i),","; }
  print "\n";

  print "recurrence_areaSU():  ";
  foreach my $i (0 .. 10) { print recurrence_areaSU($i),","; }
  print "\n";
  print "recurrence_area2S():  ";
  foreach my $i (0 .. 10) { print recurrence_area2S($i),","; }
  print "\n";
  exit 0;

  # A[n+1] = 4*A[n] - 3*A[n-1] + 4*5^(n-1)
  # - A[n+1] + 4*A[n] + 4*5^(n-1) = 3*A[n-1]
  # 3*A[n-1] = - A[n+1] + 4*A[n] + 4*5^(n-1)
  # 3*A[n-2] = - A[n] + 4*A[n-1] + 4*5^(n-2)

  # D[n+1] = 4*A[n] - 3*A[n-1]            + 4*5^(n-1)
  #          -       (4*A[n-1] - 3*A[n-2] + 4*5^(n-2))
  #        = 4*A[n] - 3*A[n-1]            + 4*5^(n-1)
  #                 - 4*A[n-1] + 3*A[n-2] - 4*5^(n-2))
  #        = 4*A[n] - 3*A[n-1]            + 4*5^(n-1)
  #                 - 4*A[n-1] - A[n] + 4*A[n-1] + 4*5^(n-2) - 4*5^(n-2))
  #        = 4*A[n] - 3*A[n-1]            + 4*5^(n-1)
  #          - A[n]
  # D[n+1] = 4*A[n] - 3*A[n-1]            + 4*5^(n-1)
  #          - A[n]
  # D[n+1] = 3*A[n] - 3*A[n-1]            + 4*5^(n-1)
  # D[n+1] = 3*D[n] + 4*5^(n-1)

  #      = 4*A[n] - 7*A[n-1] + 3*A[n-2] + (4*5-4)*5^(n-2)
  #      = 4*A[n] - 7*A[n-1] + 3*A[n-2] + 16*5^(n-2)
  #      = 4*A[n] - 7*A[n-1] + A[n] + 4*A[n-1] + 4*5^(n-2) + 16*5^(n-2)
  #      = 3*A[n] - 3*A[n-1] + 20*5^(n-2)
  # 4*A[n] - 12*A[n-1] + 4 - 4*5^(n-1) = 0 ??

  sub wrong {
    my ($n) = @_;
    if ($n <= 0) { return 0; }
    if ($n == 1) { return 0; }
    return 4*wrong($n-1) + 4*5**($n-2);
  }


  # A[n] = (5^k - 2*3^k + 1)/2
  sub formula_pow {
    my ($n) = @_;
    return (5**$n - 2*3**$n + 1) / 2;
  }

  sub recurrence_area43 {
    my ($n) = @_;
    if ($n <= 0) { return 0; }
    if ($n == 1) { return 0; }
    return 4*recurrence_area43($n-1) - 3*recurrence_area43($n-2) + 4*5**($n-2);
  }

  # A[n+1] = 8*A[n] - 15*A[n-1] + 4
  sub recurrence_area815 {
    my ($n) = @_;
    if ($n <= 0) { return 0; }
    if ($n == 1) { return 0; }
    return 8*recurrence_area815($n-1) - 15*recurrence_area815($n-2) + 4;
  }
  sub recurrence {
    my ($n) = @_;
    if ($n <= 0) { return 0; }
    if ($n == 1) { return 2; }
    return 8*recurrence($n-1) - 15*recurrence($n-2) + 2;
  }

  sub recurrence_area2S {
    my ($n) = @_;
    return 2*recurrence_S($n+1);
  }
  sub recurrence_areaSU {
    my ($n) = @_;
    return 4*recurrence_S($n) + 2*recurrence_U($n);
  }
  sub recurrence_S {
    my ($n) = @_;
    if ($n <= 0) { return 0; }
    if ($n == 1) { return 0; }
    return 2*recurrence_S($n-1) + recurrence_U($n-1);
  }
  sub recurrence_U {
    my ($n) = @_;
    if ($n <= 0) { return 0; }
    if ($n == 1) { return 0; }
    return recurrence_S($n-1) + 2*recurrence_U($n-1) + 2*5**($n-2);
  }

  # A(n)=a(n)*2
  # A(n)/2 = 8*A(n-1)/2 - 15*A(n-2)/2 + 2
  # A(n) = 8*A(n-1) - 15*A(n-2) + 4
}
{
  # arm xy modulus
  require Math::PlanePath::R5DragonMidpoint;
  my $path = Math::PlanePath::R5DragonMidpoint->new (arms => 4);

  my %dxdy_to_digit;
  my %seen;
  for (my $n = 0; $n < 6125; $n++) {
    my $digit = $n % 5;

    foreach my $arm (0 .. 3) {
      my ($x,$y) = $path->n_to_xy(4*$n+$arm);
      my $nb = int($n/5);
      my ($xb,$yb) = $path->n_to_xy(4*$nb+$arm);

      # (x+iy)*(1+2i) = x-2y + 2x+y
      ($xb,$yb) = ($xb-2*$yb, 2*$xb+$yb);
      my $dx = $xb - $x;
      my $dy = $yb - $y;

      my $dxdy = "$dx,$dy";
      my $show = "${dxdy}[$digit]";
      $seen{$x}{$y} = $show;
      if ($dxdy eq '0,0') {
      }

      # if (defined $dxdy_to_digit{$dxdy} && $dxdy_to_digit{$dxdy} != $digit) {
      #   die;
      # }
      $dxdy_to_digit{$dxdy} = $digit;
    }
  }

  foreach my $y (reverse -45 .. 45) {
    foreach my $x (-5 .. 5) {
      printf " %9s", $seen{$x}{$y}//'e'
    }
    print "\n";
  }
  ### %dxdy_to_digit

  exit 0;
}

{
  # Midpoint xy to n
  require Math::PlanePath::DragonMidpoint;
  require Math::BaseCnv;

  my @yx_adj_x = ([0,1,1,0],
                  [1,0,0,1],
                  [1,0,0,1],
                  [0,1,1,0]);
  my @yx_adj_y = ([0,0,1,1],
                  [0,0,1,1],
                  [1,1,0,0],
                  [1,1,0,0]);
  sub xy_to_n {
    my ($self, $x,$y) = @_;

    my $n = ($x * 0 * $y) + 0; # inherit bignum 0
    my $npow = $n + 1;         # inherit bignum 1

    while (($x != 0 && $x != -1) || ($y != 0 && $y != 1)) {

      # my $ax = ((($x+1) ^ ($y+1)) >> 1) & 1;
      # my $ay = (($x^$y) >> 1) & 1;
      # ### assert: $ax == - $yx_adj_x[$y%4]->[$x%4]
      # ### assert: $ay == - $yx_adj_y[$y%4]->[$x%4]

      my $y4 = $y % 4;
      my $x4 = $x % 4;
      my $ax = $yx_adj_x[$y4]->[$x4];
      my $ay = $yx_adj_y[$y4]->[$x4];

      ### at: "$x,$y  n=$n  axy=$ax,$ay  bit=".($ax^$ay)

      if ($ax^$ay) {
        $n += $npow;
      }
      $npow *= 2;

      $x -= $ax;
      $y -= $ay;
      ### assert: ($x+$y)%2 == 0
      ($x,$y) = (($x+$y)/2,   # rotate -45 and divide sqrt(2)
                 ($y-$x)/2);
    }

    ### final: "xy=$x,$y"
    my $arm;
    if ($x == 0) {
      if ($y) {
        $arm = 1;
        ### flip ...
        $n = $npow-1-$n;
      } else { #  $y == 1
        $arm = 0;
      }
    } else { # $x == -1
      if ($y) {
        $arm = 2;
      } else {
        $arm = 3;
        ### flip ...
        $n = $npow-1-$n;
      }
    }
    ### $arm

    my $arms_count = $self->arms_count;
    if ($arm > $arms_count) {
      return undef;
    }
    return $n * $arms_count + $arm;
  }

  foreach my $arms (4,3,1,2) {
    ### $arms

    my $path = Math::PlanePath::DragonMidpoint->new (arms => $arms);
    for (my $n = 0; $n < 50; $n++) {
      my ($x,$y) = $path->n_to_xy($n)
        or next;

      my $rn = xy_to_n($path,$x,$y);

      my $good = '';
      if (defined $rn && $rn == $n) {
        $good .= "good N";
      }

      my $n2 = Math::BaseCnv::cnv($n,10,2);
      my $rn2 = Math::BaseCnv::cnv($rn,10,2);
      printf "n=%d xy=%d,%d got rn=%d    %s\n",
        $n,$x,$y,
          $rn,
            $good;
    }
  }
  exit 0;
}



{
  # 2i+1 powers
  my $x = 1;
  my $y = 0;
  foreach (1 .. 10) {
    ($x,$y) = ($x - 2*$y,
                 $y + 2*$x);
    print "$x  $y\n";
  }
  exit 0;
}

{
  # turn sequence
  require Math::NumSeq::PlanePathTurn;
  my @want = (0);
  foreach (1 .. 5) {
    @want = map { $_ ? (0,0,1,1,1) : (0,0,1,1,0) } @want;
  }

  my @got;
  foreach my $i (1 .. @want) {
    push @got, calc_n_turn($i);
  }
  # my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'R5DragonCurve',
  #                                             turn_type => 'Right');
  # while (@got < @want) {
  #   my ($i,$value) = $seq->next;
  #   push @got, $value;
  # }

  my $got = join(',',@got);
  my $want = join(',',@want);
  print "$got\n";
  print "$want\n";

  if ($got ne $want) {
    die;
  }
  exit 0;

  # return 0 for left, 1 for right
  sub calc_n_turn {
    my ($n) = @_;
    $n or die;
    for (;;) {
      if (my $digit = $n % 5) {
        return ($digit >= 3 ? 1 : 0);
      }
      $n = int($n/5);
    }
  }
}
