#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::Base::Digits 'round_down_pow';
use Math::PlanePath::ToothpickTree;

# uncomment this to run the ### lines
# use Smart::Comments;




{
  # n_to_level()
  foreach my $parts (4, 1, 2, 3, 'octant', 'wedge') {
    print "parts=$parts\n";
    my $path = Math::PlanePath::ToothpickTree->new (parts => $parts);
    my $upto_level = -1;
    my $upto_level_n_lo;
    my $upto_level_n_hi = -1;
    foreach my $n ($path->n_start .. 50) {
      if ($n > $upto_level_n_hi) {
        $upto_level++;
        ($upto_level_n_lo,$upto_level_n_hi) = $path->level_to_n_range($upto_level);
        print "level $upto_level  $upto_level_n_lo..$upto_level_n_hi\n";
      }
      my $level = $path->n_to_level($n);
      my $depth = $path->tree_n_to_depth($n);
      my ($n_lo,$n_hi) = $path->level_to_n_range($level);
      print "$n  d=$depth l=$level  $n_lo..$n_hi\n";
    }
  }
  exit 0;
}

{
  # tree_depth_to_n() mod 2
  foreach my $parts (1, 2, 3, 4, 'octant', 'wedge') {
    my $path = Math::PlanePath::ToothpickTree->new (parts => $parts);
    my @values = map { $path->tree_depth_to_n($_) % 2 } 4 .. 40;
    require Math::OEIS::Grep;
    Math::OEIS::Grep->search(name => "parts=$parts",
                             array => \@values);
    print "\n";
  }
  exit 0;
}


{
  # count 2^k-1 terms to make n
  # A079559 ,1,1,0,1,1,0,0,1,1,0,1,1,0,0,0,1,1,0,1,1,0,0,1
  # A168002   ,1,0,1,1,0,0,1,1,0,1,1,0,0,0,1,1,0,1,1,0,0,1,1

  foreach my $n (1 .. 15) {
    my @list = list_2ksub1($n);
    print "$n  ",join('+',@list),"\n";
  }
  unshift @INC, 'xt'; require MyOEIS;
  # my @values = map { count_2ksub1($_)>0?1:0 } 1 .. 35;
  my @values = map { count_2ksub1($_)||() } 1 .. 35;
  my $values = join(',',@values);
  print "seek $values\n";
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array=>\@values);
  exit 0;

  # n >= 2^k-1
  # n+1 >= 2^k
  sub count_2ksub1 {
    my ($n) = @_;
    my @list = list_2ksub1($n);
    return scalar(@list);
  }
  sub list_2ksub1 {
    my ($n) = @_;
    my @ret;
    my $prev = 0;
    while ($n > 0) {
      my ($pow,$exp) = round_down_pow($n+1,2);
      my $term = $pow-1;
      if ($term == $prev) {
        return;
      }
      push @ret, $term;
      $n -= $term;
      $prev = $term;
    }
    return @ret;
  }

  # quad(pow) = (4^k-4)/6  
  sub Q {
    my ($n) = @_;
    die if $n < 2;
    my ($pow,$exp) = round_down_pow($n,2);
    my $rem = $n - $pow;
    if ($rem == 0) {
      return ($pow*$pow-4)/6;
    }
    if ($rem == 1) {
      return Q($pow) + 1;
    }
    return Q($pow) + Q($rem+1) + 2*Q($rem) + 2;
  }
}

BEGIN {
  my $path = Math::PlanePath::ToothpickTree->new;
  sub whole_total {
    my ($depth) = @_;
    return $path->tree_depth_to_n($depth);
  }
  sub whole_added {
    my ($depth) = @_;
    return $path->tree_depth_to_width($depth);
  }
  sub whole_vertical {   # A162794
    my ($depth) = @_;
    my $ret = 0;
    for (my $d = 0; $d < $depth; $d+=2) {
      $ret += $path->tree_depth_to_width($d);
    }
    return $ret;
  }
  sub whole_horizontal {  # A162796
    my ($depth) = @_;
    my $ret = 0;
    for (my $d = 1; $d < $depth; $d+=2) {
      $ret += $path->tree_depth_to_width($d);
    }
    return $ret;
  }
}
BEGIN {
  my $path = Math::PlanePath::ToothpickTree->new (parts => 'octant');
  sub oct_total {
    my ($depth) = @_;
    return $path->tree_depth_to_n($depth);
  }
  sub oct_added {
    my ($depth) = @_;
    return $path->tree_depth_to_width($depth);
  }
}
BEGIN {
  my $path = Math::PlanePath::ToothpickTree->new (parts => '1');
  sub quad_total {
    my ($depth) = @_;
    return $path->tree_depth_to_n($depth);
  }
  sub quad_vertical {
    my ($depth) = @_;
    my $ret = 0;
    for (my $d = 0; $d < $depth; $d+=2) {
      $ret += $path->tree_depth_to_width($d);
    }
    return $ret;
  }
  sub quad_horizontal {
    my ($depth) = @_;
    my $ret = 0;
    for (my $d = 1; $d < $depth; $d+=2) {
      $ret += $path->tree_depth_to_width($d);
    }
    return $ret;
  }
}

{
  # octant = quadhoriz;

  # oct(d) = floor(d/2) + quad(d) - quad(d-1) + quad(d-2) - quad(d-3) ...
  # those successive differences being quadhoriz or quadvert for d odd/even
  sub oct_total_by_quad_sum {
    my ($depth) = @_;
    my $sign = 1;
    my $ret = int($depth/2);
    for ( ; $depth >= 0; $depth--) {
      $ret += $sign * quad_total($depth);
      $sign *= -1;
    }
    return $ret;
  }
  # oct(d) = quadhoriz(d) + floor(d/2)  if d even
  #        = quadvert(d)  + floor(d/2)  if d odd
  sub oct_total_by_quad_vh {
    my ($depth) = @_;
    if ($depth & 1) {
      return quad_vertical($depth) + int($depth/2);
    } else {
      return quad_horizontal($depth) + int($depth/2);
    }
  }

  sub quad_horizontal_by_whole_horizontal {
    my ($depth) = @_;
    return (whole_horizontal($depth+2)-2)/4;
  }
  sub quad_vertical_by_whole_vertical {
    my ($depth) = @_;
    return (whole_vertical($depth+2)-1)/4;
  }

  # whole(d) = 4*oct(d) + 4*oct(d-1)
  #          = 4*quadhoriz + 4*quadvert
  sub whole_total_by_whole_vh {
    my ($depth) = @_;
    return 2*whole_horizontal($depth) - 2*oct_added($depth);
  }

  # quadvert(d) = quadhoriz(d) + oct_added(d-1)        d odd, vert grew
  #             = quadhoriz(d) - oct_added(d-1) + 1    d even, vert same
  #             = quadhoriz(d-1) + oct_added(d-2) + 1    d even
  # quad_added(d) = oct_added(d) + oct_added(d-1) - 1
  # interpret as octant growth onto horiz or vert alternately ???
  #
  sub quad_vertical_from_horizontal {
    my ($depth) = @_;
    if ($depth == 0) { return 0; }
    if ($depth & 1) {
      return quad_horizontal($depth) + oct_added($depth-1);
    } else {
      return quad_horizontal($depth-1) + oct_added($depth-2);
      return quad_horizontal($depth) - oct_added($depth-1) + 1;
    }
  }

  # for (my $depth = 0; $depth < 160; $depth += 1) {
  #   my $q = quad_vertical($depth);
  #   my $qw = quad_vertical_from_horizontal($depth);
  #   my $diff = $qw - $q;
  #   print "$depth  $q $qw   $diff\n";
  # }

  for (my $depth = 0; $depth < 60; $depth += 2) {
    #    print quad_horizontal($depth),",";
    my $oct = oct_total($depth);
    my $osum = oct_total_by_quad_vh($depth);
    my $diff = $osum - $oct;
    print "$depth  $oct $osum   $diff\n";
  }
  exit 0;
}

{
  # oct(2^k) in binary
  my $path = Math::PlanePath::ToothpickTree->new (parts => '1');
  foreach my $k (0 .. 20) {
    my $n = $path->tree_depth_to_n(2**$k+2);
    printf "%2d %40b\n", $k,$n;
  }
  exit 0;
}

{
  # two_horiz
  require Math::PlanePath::ToothpickTreeByCells;
  my $seq = Math::PlanePath::ToothpickTree->new (parts => 'two_horiz');
  my $bycells = Math::PlanePath::ToothpickTreeByCells->new (parts => 'two_horiz');
  my $prev_got = 0;
  my $prev_want = 0;
  foreach my $depth (0 .. 43) {
    my $want = $bycells->tree_depth_to_n($depth) / 4;
    my $got = $seq->tree_depth_to_n($depth) / 4;
    my $diff = $got - $want;
    my $dgot = $got - $prev_got;
    my $dwant = $want - $prev_want;
    printf "%2d  %3d %3d %3d   %2d %2d\n",
      $depth, $want, $got, $diff,
        $dwant, $dgot;
    $prev_want = $want;
    $prev_got = $got;
  }
  exit 0;
}


{
  # _depth_to_octant_added()

  require Math::PlanePath::ToothpickTreeByCells;
  require Math::BaseCnv;
  my $cells = Math::PlanePath::ToothpickTreeByCells->new (parts => 'octant');
  my $path = Math::PlanePath::ToothpickTree->new (parts => 'octant');
  for (my $depth = 0; $depth <= 66; $depth++) {
    my $c = $cells->tree_depth_to_width($depth);
    my $p = Math::PlanePath::ToothpickTree::_depth_to_octant_added
      ([$depth+2], [1], 0);
    my $diff = ($p == $c ? '' : '***');
    my $d2 = $depth + 2;
    if (is_pow2($d2)) { print "\n"; }
    print "$depth  $d2  c=$c  p=$p$diff\n";
  }
  exit 0;
}

{
  # tree_depth_to_n() octant
  # d=2  n=2           1
  # d=6  n=8         100
  # d=14 n=28      11100
  # d=30 n=100   1100100
  # d=62 n=372 101110100
  # oct(2^(k+1)) = 4*oct(2^k)  base,extend,upper,lower
  #              + 2           middle two unvisited
  #              - (2^k - 2)   unduplicate upper,lower diagonal
  #   = 4*oct(2^k) + 4 - 2^k
  # oct(2^k)
  #   = 4 - 2^(k-1) + 4*oct(2^(k-1))
  #   = 4 - 2^(k-1) + 4*(4 - 2^(k-2) + oct(2^(k-2)))
  #   = 4 - 2^(k-1) + 4*(4 - 2^(k-2) + 4*(4 - 2^(k-3) + 4*oct(2^(k-3))))
  # 4*(1 + 4 + 16 + ... + 4^(k-2))
  #   = 4*(4^(k-1) - 1)/3
  # 2^(k-1) + 4*2^(k-2) + 16*2^(k-3) + ... + 4^(k-1)*1
  #   = 2^(k-1) + 2^(k+0) + 2^(k+1) + ... + 2^(2k-2)
  #   = 2^(k-1)*(1 + 2 + 4 + ... + 2^(k-2))
  #   = 2^(k-1) * (2^(k-1) - 1)
  #
  # k=2;  (4 - 2^1 + 0) = 2
  # k=3; 4 - 2^2 + 4*(4 - 2^1 + 0) = 8
  # k=4; 4 - 2^3 + 4*(4 - 2^2 + 4*(4 - 2^1 + 0)) = 28
  #      = 4 + 4*(4 + 4*(4))  - 2^3 + 4*(-2^2 + 4*(-2^1))
  #
  # oct(2^k) = 4*(4^(k-1) - 1)/3 - 2^(k-1)*(2^(k-1)-1)
  #          = (4*(4^(k-1) - 1) - 3*2^(k-1)*(2^(k-1)-1) ) / 3
  #          = (4*4^(k-1) - 4 - 3*4^(k-1) + 3*2^(k-1) ) / 3
  #          = (4^(k-1) - 4 + 3*2^(k-1) ) / 3
  #          = (4^(k-1) - 4)/3 + 2^(k-1)
  #          = (4^k - 16)/12 + 2^(k-1)
  # pow = 2^(k-1)
  # oct(2*pow) = (pow*pow + 3*pow - 4)/3
  # oct(pow) = (pow*(pow + 3) - 4)/3
  #
  # oct(pow+rem) = oct(pow) + 2*oct(rem) + oct(rem+1) - rem + 4
  # oct(36) = oct(32) + 2*oct(4) + oct(5) - 4 + 4    want 107
  #           100     + 2*2      + 3 - 4 + 4
  #
  # oct(pow + pow-1)
  #   = oct(pow) + 2*oct(pow-1) + oct(pow) - (pow-1) + 4
  #   = 2*oct(pow) - (pow-1) + 4 + 2*oct(pow-1)
  #   = 2*oct(2^(k-1)) + 4*oct(2^(k-1)) + 8*oct(2^(k-1)) + ... + 2^(k-1)*oct(2)
  #     + 2^(k-1) - 1 + 2^(k-2) - 1 + ... + 2^1 - 1
  #     + 2^(k-1) * oct(3)
  #
  # 2^(k-1) - 1 + 2^(k-2) - 1 + ... + 2^1 - 1
  #   = 2^k - 1 - k
  #
  require Math::PlanePath::ToothpickTreeByCells;
  require Math::BaseCnv;
  my $cells = Math::PlanePath::ToothpickTreeByCells->new (parts => 'octant');
  my $path = Math::PlanePath::ToothpickTree->new (parts => 'octant');
  for (my $depth = 2; $depth <= 36; $depth++) {
    my $depth = $depth-2;
    my $n = $cells->tree_depth_to_n($depth);
    my $n2 = Math::BaseCnv::cnv($n,10,2);
    my $f = oct_pow_by_formula($depth);
    my $p = $path->tree_depth_to_n($depth);
    my $diff = ($p == $n ? '' : '***');
    my $d2 = $depth + 2;
    if (is_pow2($d2)) { print "\n"; }
    print "$depth  $d2  n=$n  $n2  p=$p$diff   f=$f\n";
  }

  sub oct_pow_by_formula {
    my ($depth) = @_;
    $depth += 2;  # parts=4 basis
    if ($depth <= 2) { return 0; }
    if ($depth == 4) { return 2; }
    $depth /= 2;
    return (4*oct_pow_by_formula($depth-2)
            + 4
            - $depth
           );
  }
  sub is_pow2 {
    my ($n) = @_;
    while ($n > 1) {
      if ($n & 1) {
        return 0;
      }
      $n >>= 1;
    }
    return ($n == 1);
  }
  exit 0;
}
{
  # tree_n_to_depth()
  require Math::PlanePath::ToothpickTreeByCells;
  my $path = Math::PlanePath::ToothpickTreeByCells->new (parts => 'octant');
  my $prev = -999;
  my $count = 0;
  my $total = 0;
  for (my $n = 2; $n <= 256; $n *= 2) {
    my $depth = $path->tree_n_to_depth($n);
    if ($depth != $prev) {
      print "$depth n=$n  added=$count  $total\n";
      $count = 0;
      $prev = $depth;
    }
    $count++;
    $total++;
  }
  exit 0;
}

{
  # ascii art with toothpick lines

  require Image::Base::Text;

  my $run = sub {
    my ($path, $n_hi) = @_;

    my $width = 78;
    my $height = 40;
    my $x_lo = -$width/2;
    my $y_lo = -$height/2;

    my $x_hi = $x_lo + $width - 1;
    my $y_hi = $y_lo + $height - 1;
    my $image = Image::Base::Text->new (-width => $width,
                                        -height => $height);
    my $plot = sub {
      my ($x,$y,$char) = @_;
      $x -= $x_lo;
      $y -= $y_lo;
      return if $x < 0 || $y < 0 || $x >= $width || $y >= $height;
      $image->xy ($x,$height-1-$y,$char);
    };
    my $plot_get = sub {
      my ($x,$y,$char) = @_;
      $x -= $x_lo;
      $y -= $y_lo;
      return ' ' if $x < 0 || $y < 0 || $x >= $width || $y >= $height;
      return $image->xy($x, $height-1-$y);
    };
    my $plot_nooverwrite = sub {
      my ($x,$y,$char) = @_;
      if ($plot_get->($x,$y) eq ' ') {
        $plot->($x,$y,$char);
      }
    };

    print "n_hi $n_hi\n";
    for my $n ($path->n_start .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      my $odd = ($x+$y) & 1;
      $x *= 4;
      $y *= 2;
      my $str = "$n";
      $plot->($x+1, $y, $str);
      if ($n < 10) {
      } else {
        $plot->($x,   $y, substr($str,0,1));
        $plot->($x+1, $y, substr($str,1,1));
      }
      if ($odd) {
        $plot_nooverwrite->($x-2, $y, '-');
        $plot_nooverwrite->($x-1, $y, '-');
        $plot_nooverwrite->($x, $y, '-');
        $plot_nooverwrite->($x+2, $y, '-');
        $plot_nooverwrite->($x+3, $y, '-');
        $plot_nooverwrite->($x+4, $y, '-');
      } else {
        $plot_nooverwrite->($x+1, $y-1, '|');
        $plot_nooverwrite->($x+1, $y+1, '|');
      }
    }
    $image->save('/dev/stdout');
  };

  {
    my $path = Math::PlanePath::ToothpickTree->new;
    $run->($path, 54);
  }
  {
    my $path = Math::PlanePath::ToothpickTree->new (parts => 1);
    $run->($path, 47);
  }
  {
    my $path = Math::PlanePath::ToothpickTree->new (parts => 2);
    $run->($path, 22);
  }
  {
    my $path = Math::PlanePath::ToothpickTree->new (parts => 3);
    $run->($path, 32);
  }

  require Math::PlanePath::ToothpickReplicate;
  {
    my $path = Math::PlanePath::ToothpickReplicate->new;
    $run->($path, 43);
  }
  {
    my $path = Math::PlanePath::ToothpickReplicate->new (parts => 1);
    $run->($path, 42);
  }
  {
    my $path = Math::PlanePath::ToothpickReplicate->new (parts => 2);
    $run->($path, 53);
  }
  {
    my $path = Math::PlanePath::ToothpickReplicate->new (parts => 3);
    $run->($path, 31);
  }

  exit 0;
}

{
  # http://user42.tuxfamily.org/temporary/
  chdir "$ENV{HOME}/tux/web/temporary" or die;

  system ('math-image --path=ToothpickTree,parts=4 --all --scale=5 --size=200x200 --png >toothpick-squares.png') == 0
    or die;
  system ('math-image --path=ToothpickTree,parts=4 --values=PlanePathCoord,coordinate_type=IsNonLeaf,planepath=ToothpickTree --scale=5 --size=200x200 --png >toothpick-nonleaf.png') == 0
    or die;

  # system ('math-image --path=ToothpickTree,parts=1 --values=LinesTree --scale=7 --size=450x458 --figure=circle --png >toothpick-tree.png') == 0
  #   or die;
  system ('ls -l *.png');
  system ('xzgv toothpick-squares.png toothpick-nonleaf.png');
  exit 0;
}
{
  # http://user42.tuxfamily.org/temporary/

  chdir "$ENV{HOME}/tux/web/temporary" or die;

  system ('math-image --path=ToothpickTree,parts=1 --values=LinesTree --scale=14 --size=452x464 --figure=circle --png >toothpick-dots.png') == 0
    or die;
  system ('math-image --path=ToothpickTree,parts=1 --values=LinesTree --scale=14 --size=452x464 --figure=point --png >toothpick-lines.png') == 0
    or die;

  # system ('math-image --path=ToothpickTree,parts=1 --values=LinesTree --scale=7 --size=450x458 --figure=circle --png >toothpick-tree.png') == 0
  #   or die;
  system ('ls -l *.png');
  system ('xzgv toothpick-*.png');
  exit 0;
}

{
  # count including endpoints

  my $path = Math::PlanePath::ToothpickTree->new (parts => 2);
  my $prev = -999;
  my $count = 0;
  for (my $depth = 0; $depth <= 20; $depth++) {
    my $total = 0;
    my $n_end = $path->tree_depth_to_n_end($depth);
    foreach my $n ($path->n_start .. $n_end) {
      $total += 3;
      foreach my $c ($path->tree_n_children($n)) {
        if ($n <= $n_end) {
          $total--;  # no double-counting of child midpoint
        }
      }
    }
    print "$total,";
  }
  print "\n";
  exit 0;
}




{
  #         |               |
  # 6|     23--19--  --18--22
  #  |      |   |       |   |
  # 5|         16--13--15
  #  |              |   |
  # 4|-10--  ---9--11
  #  |  |       |   |   |
  # 3|  8---5---7 -12--14
  #  |      |   |       |   |
  # 2| -2---3      20--17--21
  #  |  |   |   |   |       |
  # 1|--1 --4---6
  #  |  |       |
  # 0|
  #  +--------------------
  #     0

  #         |               |
  # 6|     10---9--  ---9--10
  #  |      |   |       |   |
  # 5|          8---7---8
  #  |              |   |
  # 4|--5--  ---5---6
  #  |  |       |   |   |
  # 3|  4---3---4 --7---8
  #  |      |   |       |   |
  # 2| -1---2      10---9--10
  #  |  |   |   |   |       |
  # 1|--0 --3---4
  #  |  |       |
  # 0|
  #  +--------------------
  #     0

  # total 1-quad A153000 OFFSET=0
  #   0,1,2, 3,5,8,10, 11,13,16,19,23,30,38,42,
  #   0 1 2  3 4 5 6   7  8  9  10 11 12 13 14
  #
  #   43,45,48,51,55,62,70,75,79,86,95,105,120,142,162,170, 171,173,176,
  #   15 16 17 18 19 20 21 22 23 24 25 26  27  28  29  30   31  32  33
  #      +2 +3 +3 +4 +7 +8 +5 +4 +7 +9 +10 +15 +22 +20 +18  +1  +2  +
  #
  #  43 =
  #  45 = 44 + 1
  #  48 = 44 + 2*0+1 = +4
  #  51 = 44 + 2*2+3 = +7  +3
  #  55   44 + 2*3+5 = +11 +4
  #  62 = 44   2*5+8 = +18 +7
  #  70 = 44 + 2*8+10 = +26 +8
  #  75 = 44 + 2*10+11 = +31 +5
  #  79 = 44 + 2*11+13
  # 162 = 44 + 2*38+42
  # 170 = 44 + 2*42+42
  # 171
  #
  my @total = (0,0,1,2,3,5,8,10);
  print join(',',@total),"\n";
 OUTER: for (my $len = 8; ; $len *= 2) {
    my $t = $total[-1] + $len/8;
    # push @total, $t;
    print "[t=$t] ";
    for my $i (0 .. $len-1) {
      my $nt = $t + 2*$total[max($i,0)] + $total[min($i+1,$len-1)];
      # print "<$total[$i+1],$total[$i]>";
      print "$nt,";
      push @total, $nt;

      last OUTER if $#total > 33;
    }

    my $tsize = scalar(@total);
    print "  [tsize=$tsize]\n";
  }
  print "\n";
  exit 0;
}

{
  # added 4-quads
  my @added = (0, 1, 2, 4);
  print "0,1,\n2,4,\n";
  for (my $len = 4; $len <= 16; $len *= 2) {
    my $add = $len;
    push @added, $add;
    print "$add,";
    for my $i (1 .. $len-1) {
      my $add = $added[$i+1] + 2*$added[$i];
      print "$add,";
      push @added, $add;
    }
    my $asize = scalar(@added);
    print "  [asize=$asize]\n";
  }
  exit 0;
}
{
  #  0;
  #  1;
  #  2,4;
  #  4,4,8,12;
  #  8,4,8,12,12,16,28,32;
  # 16,4,8,12,12,16,28,32,20,16,28,36,40,60,88,80;
  # 32,4,8,12,12,16,28,32,20,16,28,36,40,60,88,80,36,16,28,36,40,60,88,84,56,..

  # 1, 1,
  # 1, 2, 3, 2,
  # 1, 2, 3, 3, 4, 7, 8, 4,
  # 1, 2, 3, 3, 4, 7, 8, 5, 4, 7, 9, 10, 15, 22, 20, 8,
  # 1, 2, 3, 3, 4, 7, 8, 5, 4, 7, 9, 10, 15, 22, 20, 9, 4, 7, 9, 10, 15, 22, 21, 14, 15, 23, 28, 35, 52, 64, 48, 16,
  # 1, 2, 3, 3, 4, 7, 8, 5, 4, 7, 9, 10, 15, 22, 20, 9, 4, 7, 9, 10, 15, 22, 21, 14, 15, 23

  #   0,
  #   1, 2,
  #   4, 4,
  #   4, 8, 12, 8,
  #   4, 8, 12, 12, 16, 28, 32, 16,
  #   4, 8, 12, 12, 16, 28, 32, 20, 16, 28, 36, 40, 60, 88, 80, 32,
  #   4, 8, 12, 12, 16, 28, 32, 20, 16, 28, 36, 40, 60, 88, 80, 36, 16, 28, 36, 40, 60, 88, 84, 56, 60, 92, 112, 140, 208, 256, 192, 64,
  #   4, 8, 12, 12, 16, 28, 32, 20, 16, 28

  my @add = (0,1);
  my $dpower = 2;
  my $d = 0;
  my $n = 1000;
  for (;;) {
    my $add;
    ### $d
    ### $dpower
    if ($d == 0) {
      $add = $dpower;
    } else {
      $add = 2*$add[$d] + $add[$d+1];
    }
    if (++$d >= $dpower) {
      $dpower *= 2;
      $d = 0;
    }
    ### $add
    if ($n <= $add) {
      last;
    }
    $n -= $add;
    push @add, $add;
  }
  print join(',',@add);
  exit 0;
}
