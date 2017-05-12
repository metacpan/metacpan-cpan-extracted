#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
use List::Util 'min', 'max';
use Math::PlanePath::TerdragonCurve;
use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
use List::Pairwise;
use Math::BaseCnv;
use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

# # skip low zeros
# # 1 left
# # 2 right
# ones(n) - ones(n+1)

# 1*3^k  left
# 2*3^k  right

{
  # A062756 == 1-abs(A229215)  mod 3
  # A062756(n) = vecsum(apply(d->d==1,digits(n,3)));
  # A229215(n) = [1,-3,-2,-1,3,2][(A062756(n-1) % 6)+1];
  # A229215(n) = [1,2,3,-1,-2,-3][(-A062756(n-1) % 6)+1];
  # vector(20,n,n--; A062756(n))
  # vector(20,n, A229215(n))
  # A229215(n) = (digits(n,3))
  # A229215
  # 1, -3, 1, -3, -2, -3, 1, -3, 1, -3, -2, -3, -2, -1, -2, -3, -2, -3, 1,    


  require Math::NumSeq::OEIS;
  my $A062756 = Math::NumSeq::OEIS->new(anum=>'A062756');
  my $A229215 = Math::NumSeq::OEIS->new(anum=>'A229215');
  my @map = (1,2,3,-1,-2,-3);
  for (;;) {
    my ($i1,$value1) = $A062756->next or last;
    my ($i2,$value2) = $A229215->next or last;
    # $value1 %= 3;
    # $value2 = (1 - abs($value2)) % 3;

    $value1 = $map[-$value1 % 6];

    print "i=$i1  $value1 $value2\n";
     $value1 == $value2 or die;
  }
  exit 0;
}
{
  # some variations

  # cf A106154 terdragon 6 something
  #    A105499 terdragon permute something
  #     1->{2,1,2}, 2->{1,3,1}, 3->{3,2,3}.
  #     212323212131212131212323212323131323212323212323

  #  *   *              3   2 
  #   \ / \              \ /
  #    *---*        -1 ---*--- 1
  #     \                / \
  #  *---*             -2   -3      
  #    
  # A062756
  # 0, 1, 0, 1, 2, 1, 0, 1, 0, 1, 2, 1, 2, 3, 2, 1, 2, 1, 0, 1, 0, 1, 2, 1,   


  # 1,2,3 = 0,1,2
  # -1,-2,-3 = 3,4,5
  my @map123 = (undef, 0,1,2, 5,4,3);

  require Math::NumSeq::OEIS;
  my $seq;
  $seq = Math::NumSeq::OEIS->new(anum=>'A105969');
  $seq = Math::NumSeq::OEIS->new(anum=>'A106154');
  $seq = Math::NumSeq::OEIS->new(anum=>'A229215');

  require Language::Logo;
  my $lo = Logo->new(update => 2, port => 8200 + (time % 100));
  my $draw;
  # $lo->command("seth 135; backward 200; seth 90");
  $lo->command("pendown; hideturtle");
  my $angle = 0;
  while (my ($i,$value) = $seq->next) {
    last if $i > 3**3;
    $value = $map123[$value];
    $angle = $value*120;
    # $angle = 90-$angle;
    $angle += 90;
    $lo->command("seth $angle; forward 13");
  }
  $lo->disconnect("Finished...");
  exit 0;
}

{
  # powers (1+w)^k
  # w^2 = -1+w
  # (a+bw)*(1+w) = a+bw + aw+bw^2
  #              = a + bw + aw - b + bw
  #              = (a-b) + (a+2b)w
  # a+bw = (a+b) + bw^2
  my $a = 1;
  my $b = 0;
  my @values;
  for (1 .. 30) {
    push @values, -($a+$b);
    ($a,$b) = ($a-$b, $a+2*$b);
  }
  for (1 .. 20) {
    print "$_\n";
    Math::OEIS::Grep->search(array=>\@values);
  }
  exit 0;
}
{
  # mixed ternary grep
  my @values;
  foreach my $n (1 .. 3*2**3) {
    my @digits = Math::PlanePath::TerdragonCurve::_digit_split_mix23_lowtohigh($n);
    push @values, digit_join_lowtohigh(\@digits,3);
  }
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

=head2 Left Boundary Turn Sequence

The left boundary turn sequence is

    Lt(i) = / if i == 1 mod 3 then  turn -120   (right)
            | otherwise
            | let b = bit above lowest 1-bit of i-floor((i+1)/3)
            | if b = 0 then         turn 0      (straight ahead)
            \ if b = 1 then         turn +120   (left)

    = 1, 0, 0, 1, -1, 0, 1, 0, -1, 1, -1, 0, 1, 0, 0, 1, -1, -1, ...
      starting i=1, multiple of 120 degrees

The sequence can be calculated in a similar way to the right boundary, but
from an initial V part since the "0" and "2" points are on the left boundary
(and "1" is not).

         2
    Vrev  \
           \
      0-----1

This expands as

    2     *      initial
     \   / \       Vtrev[0] = 1
      \ /   \      Rtrev[0] = empty
       a-----1
        \          Vtrev[1] = Vtrev[0], 0, Rtrev[0]
         \                  = 1, 0   (at "*" and "a")
    0-----*

     Vtrev[k+1] = Vtrev[k], 0, Rtrev[k]
     Rtrev[k+1] = Vtrev[k], 1, Rtrev[k]
  The
R and V parts are the same on the left, but are to be taken in reverse.

The left side 0 to 2 is the same V shape as on the right (by symmetry), but
the points are in reverse.

=head2 Right and Left Turn Matching

=cut

{
  # segments by direction
  # A092236, A135254, A133474
  # A057083 half term, offset from 3^k, A103312 similar

  require Math::PlanePath::TerdragonCurve;
  my $path = Math::PlanePath::TerdragonCurve->new;
  my %count;
  my %count_arrays;
  my $n = 0;
  my @dxdy_strs = List::Pairwise::mapp {"$a,$b"} $path->_UNDOCUMENTED__dxdy_list;
  my $width = 36;
  foreach my $k (12 .. 23) {
    my $n_end = 3**$k * 0;
    for ( ; $n < $n_end; $n++) {
      my ($dx,$dy) = $path->n_to_dxdy($n);
      $count{"$dx,$dy"}++;
    }
    # printf "k=%2d ", $k;
    # foreach my $dxdy (@dxdy_strs) {
    #   my $a = $count{$dxdy} || 0;
    #   my $aref = ($count_arrays{$dxdy} ||= []);
    #   push @$aref, $a;
    #
    #   my $ar = Math::BaseCnv::cnv($a,10,3);
    #   printf " %18s", $ar;
    # }
    # print "\n";

    printf "k=%2d ", $k;
    foreach my $dxdy (@dxdy_strs) {
      my $a = _UNDOCUMENTED__level_to_segments_dxdy($path, $k, split(/,/, $dxdy));
      my $ar = Math::BaseCnv::cnv($a,10,3);
      printf " %*s", $width, $ar;
    }
    print "\n";
    print "     ";
    foreach my $dxdy (@dxdy_strs) {
      my $a = _UNDOCUMENTED__level_to_segments_dxdy_2($path, $k, split(/,/, $dxdy));
      my $ar = Math::BaseCnv::cnv($a,10,3);
      printf " %*s", $width, $ar;
    }
    print "\n";
    print "\n";
  }
  my $trim = 1;
  foreach my $dxdy (@dxdy_strs) {
    my $aref = $count_arrays{$dxdy} || [];
    splice @$aref, 0, $trim;
    # @$aref = MyOEIS::first_differences(@$aref);
    print "$dxdy\n";
    print "is ", join(',',@$aref),"\n";
    Math::OEIS::Grep->search (array => \@$aref, name => $dxdy);
  }

  sub _UNDOCUMENTED__level_to_segments_dxdy {
    my ($self, $level, $dx,$dy) = @_;
    my $a = 1;
    my $b = 0;
    my $c = 0;
    for (1 .. $level) {
      ($a,$b,$c) = (2*$a + $c,
                    2*$b + $a,
                    2*$c + $b);
    }
    if ($dx == 2 && $dy == 0) {
      return $a;
    }
    if ($dx == -1) {
      if ($dy == 1) {
        return $b;
      }
      if ($dy == -1) {
        return $c;
      }
    }
    return undef;
  }
  BEGIN {
    my @dir3_to_offset = (0,8,4);
    my @table = (2,1,1, 0,-1,-1, -2,-1,-1, 0,1,1);
    sub _UNDOCUMENTED__level_to_segments_dxdy_2 {
      my ($self, $level, $dx,$dy) = @_;
      my $ret = _dxdy_to_dir3($dx,$dy);
      if (! defined $ret) { return undef; }
      $ret = $table[($dir3_to_offset[$ret] + $level) % 12];
      $level -= 1;
      if ($ret) {
        $ret *= 3**int($level/2);
      }
      return 3**$level + $ret;
    }
  }
  sub _dxdy_to_dir3 {
    my ($dx,$dy) = @_;
    if ($dx == 2 && $dy == 0) {
      return 0;
    }
    if ($dx == -1) {
      if ($dy == 1) {
        return 1;
      }
      if ($dy == -1) {
        return 2;
      }
    }
    return undef;
  }
  # print "\n";
  # foreach my $k (0 .. $#a) {
  #   my $h = int($k/2);
  #   printf "%3d,", $d[$k];
  # }
  # print "\n";
  exit 0;
}

{
  # left boundary N

  # left_boundary_n_pred(14);
  # ### exit 0

  my $path = Math::PlanePath::TerdragonCurve->new;
  my %non_values;
  my %n_values;
  my @n_values;
  my @values;
  foreach my $k (4){
    print "k=$k\n";
    my $n_limit = 2*3**$k;
    foreach my $n (0 .. $n_limit-1) {
      $non_values{$n} = 1;
    }
    my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                               lattice_type => 'triangular',
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
        my $n3 = Math::BaseCnv::cnv($n,10,3);
        my $pred = $path->_UNDOCUMENTED__n_segment_is_left_boundary($n);
        my $diff = $pred ? '' : '  ***';
        if ($k <= 4) { print "$n  $n3$diff\n"; }
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
        my $n3 = Math::BaseCnv::cnv($n,10,3);
        print "non $n  $n3$diff\n";
      }
    }
    # @values = @non_values;

    print "func ";
    foreach my $i (0 .. $count-1) {
      my $n = $path->_UNDOCUMENTED__left_boundary_i_to_n($i);
      my $n3 = Math::BaseCnv::cnv($n,10,3);
      print "$n,";
    }
    print "\n";

    print "vals ";
    foreach my $i (0 .. $count-1) {
      my $n = $values[$i];
      my $n3 = Math::BaseCnv::cnv($n,10,3);
      print "$n3,";
    }
    print "\n";
  }

  # @values = MyOEIS::first_differences(@values);
  # shift @values;
  # shift @values;
  # shift @values;
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # right boundary N

  # $path->_UNDOCUMENTED__n_segment_is_right_boundary(14);
  # ### exit 0

  my $path = Math::PlanePath::TerdragonCurve->new;
  my %non_values;
  my %n_values;
  my @n_values;
  my @values;
  foreach my $k (4){
    print "k=$k\n";
    my $n_limit = 3**$k;
    foreach my $n (0 .. $n_limit-1) {
      $non_values{$n} = 1;
    }
    my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                               lattice_type => 'triangular',
                                               side => 'right',
                                              );

    # $points = points_2of3($points);
    for (my $i = 0; $i+1 <= $#$points; $i++) {
      my ($x,$y) = @{$points->[$i]};
      my ($x2,$y2) = @{$points->[$i+1]};
      # my @n_list = $path->xy_to_n_list($x,$y);
      my @n_list = path_xyxy_to_n($path, $x,$y, $x2,$y2);
      foreach my $n (@n_list) {
        delete $non_values{$n};
        if ($n <= $n_limit) { $n_values{$n} = 1; }
        my $n3 = Math::BaseCnv::cnv($n,10,3);
        my $pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n);
        my $diff = $pred ? '' : '  ***';
        if ($k <= 4) { print "$n  $n3$diff\n"; }
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
        my $n3 = Math::BaseCnv::cnv($n,10,3);
        print "non $n  $n3$diff\n";
      }
    }
    # @values = @non_values;

    print "func ";
    foreach my $i (0 .. $count-1) {
      my $n = $path->_UNDOCUMENTED__right_boundary_i_to_n($i);
      my $n3 = Math::BaseCnv::cnv($n,10,3);
      print "$n3,";
    }
    print "\n";

    print "vals ";
    foreach my $i (0 .. $count-1) {
      my $n = $values[$i];
      my $n3 = Math::BaseCnv::cnv($n,10,3);
      print "$n,";
    }
    print "\n";
  }

  # @values = MyOEIS::first_differences(@values);
  # shift @values;
  # shift @values;
  # shift @values;
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

=head2 Boundary Straight 2s

1 x straight
Right
j=2  010    left        j == 2 mod 8
j=3   11    straight    i == 3 mod 12
j=   1100   straight    trailing 0s >= 2
j=   1101   left

2 x straight
Right
i=9  j=6  110
i=10 j=7  111
even ...110    so j == 6 mod 8
odd  ...111       i == 9 mod 12
i=21 +12
i=22 +12

Left
odd   even
N and N+1 both bit-above-low-1 = 1 both straight
2m-1  2m
odd must be ...11
odd+1  x100
must be ...1100
so odd 1011  is 11 mod 16

=cut

       # A083575 length=1
       # 2^(k-2) - 1  length=2
       # 2^(k-3)      length=3
       #
       # 3*2^(k-1) - 2*(2^(k-2) - 1) - 3*2^(k-3)
       # = 12*2^(k-3) - 4*2^(k-3) + 1 - 3*2^(k-3)
       # = 5*2^(k-3) + 1
       #
       require Math::NumSeq::PlanePathTurn;
       my $path = Math::PlanePath::TerdragonCurve->new;
       my $seq = Math::NumSeq::PlanePathTurn->new(planepath_object => $path,
                                                  turn_type => 'LSR');
       my @values;
       foreach my $k (1 .. 12) {
         print "k=$k\n";
         my $points = MyOEIS::path_boundary_points ($path, 3**$k,
                                                    lattice_type => 'triangular',
                                                    side => 'right',
                                                   );
         my $run = 0;
         my @count = (0,0,0);
         for (my $i = 0; $i+2 <= $#$points; $i++) {
           my $tturn6 = points_to_tturn6($points->[$i], $points->[$i+1], $points->[$i+2]);
           if ($tturn6 == 0) {
             $run++;
           } else {
             $count[$run]++;
             $run = 0;
           }
         }
         print "$count[0]  $count[1]  $count[2]\n";
         push @values, $count[0];
       }
       shift @values;
       shift @values;
       Math::OEIS::Grep->search(array => \@values);
       exit 0;
     }



=head2 Boundary Isolated Triangles

When the boundary visits a point twice it does so by enclosing a single unit
triangle.  This is seen for example in the turn sequence diagram above where
turns 5 and 8 are at the same point and the turns go -1, 1, 1, -1 to enclose
a single unit triangle.

    \     7  Rt(7)=1
     \   / \
      \8/   \
       *-----6  Rt(6)=1
        \5  Rt(5)=-1
         \
          \

             *     *
            / \   / \
           /   \ /   \
    \     *-----*-----*
     \   / \   / \
      \ /   \ /   \
       *     *-----*
              \
               \
                \

=cut

{
  # shortcut boundary length = 2^k  area = 2*3^(k-1)
  #
  #        *-----*
  #         \
  #          \
  #     *-----*
  #
  my $path = Math::PlanePath::TerdragonCurve->new;
  my @values;
  foreach my $k (1 .. 7) {
    print "k=$k\n";
    my $points = MyOEIS::path_boundary_points ($path, 3**$k,
                                               lattice_type => 'triangular',
                                               # side => 'right',
                                              );
    $points = points_2of3($points);
    # points_shortcut_triangular($points);
    if (@$points < 10) {
      print join(" ", map{"$_->[0],$_->[1]"} @$points),"\n";
    }
    my $length = scalar(@$points) - 0;

    require Math::Geometry::Planar;
    my $polygon = Math::Geometry::Planar->new;
    $polygon->points($points);
    my $area = $polygon->area;

    print "  shortcut boundary $length area $area\n";
    push @values, $area;
  }
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub points_2of3 {
    my ($points) = @_;
    my @ret;
    foreach my $i (0 .. $#$points) {
      if ($i % 3 != 2) { push @ret, $points->[$i]; }
    }
    return \@ret;
  }

  sub points_shortcut_triangular {
    my ($points) = @_;
    my $print = (@$points < 20);
    my $i = 0;
    while ($i+2 <= $#$points) {
      my $tturn6 = points_to_tturn6($points->[$i], $points->[$i+1], $points->[$i+2]);
      if ($tturn6 == 4) {
        splice @$points, $i+1, 1;
        if ($print) { print "  delete point ",$i+1,"\n"; }
      } else {
        if ($print) { print "  keep point ",$i+1,"\n"; }
        $i++;
      }
      # my $p1 = $points->[$i];
      # my $p2 = $points->[$i+2];
      # if (abs($p1->[0] - $p2->[0]) + abs($p1->[1] - $p2->[1]) == 2) {
      #   splice @$points, $i+1, 1;
      #   if ($print) { print "  delete point ",$i+1,"\n"; }
      # } else {
      #   if ($print) { print "  keep point ",$i+1,"\n"; }
      #   $i++;
      # }
    }
  }
}

{
  # shortcut turn sequence, is dragon turn sequence by 60 degrees
  #
  my $path = Math::PlanePath::TerdragonCurve->new;
  my @values;
  foreach my $k (1 .. 7) {
    print "k=$k\n";
    my $points = MyOEIS::path_boundary_points ($path, 3**$k,
                                               lattice_type => 'triangular',
                                                side => 'right',
                                              );
    points_shortcut_triangular($points);
    for (my $i = 0; $i+2 <= $#$points; $i++) {
      my $tturn6 = points_to_tturn6($points->[$i], $points->[$i+1], $points->[$i+2]);
      print "$tturn6";
      if ($k == 5) {
        push @values, ($tturn6 == 1 ? 1 : $tturn6 == 5 ? -1 : die);
      }
    }
    print "\n";
  }
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}



{
  # boundary turn sequence

  #    26----27      0 to 8    2 4 2 0 4
  #      \           9 to 26   2 2 4 0 0 4
  #       \         27         2 2 4 2 0 4 0 2 4 0 0 4
  #       22        81         2 2 4 2 0 4 2 2 4 0 0 4 0 2 4 2 0 4 0 2 4 0 0 4
  #         \                  2 2 4 2 0 4 2 2 4 0 0 4 2 2 4 2 0 4 0 2 4 0 0 4 0 2 4 2 0 4 2 2 4 0 0 4 0 2 4 2 0 4 0 2 4 0 0 4
  #          \
  #          12    10
  #          / \   / \
  #         /   \ /   \
  # 18    13-----8-----9          Rlen = 1, 3*2^(k-1)
  #   \   / \   / \  V            Vlen = 2, 3*2^(k-1)
  #    \ /   \ /   \
  #    17     6----7,4            R -> R,2,V      R[1] = 2,4
  #            \   / \  R         V -> R,0,V      V[1] = 0,4
  #             \ /   \
  #             5,2----3          R[2] = 2,4 2 0,4
  #               \   V           V[2] = 2,4 0 0,4
  #                \
  #           0-----1             bit above lowest 1 like dragon
  #              R
  #
  # R[k+1]

  my $side = 'left';

  my (@R, @V);
  if ($side eq 'right') {
    @R = ('');
    @V = ('4');
  } else {
    @R = ('');
    @V = ('2');
  }

  #   2 4     0    0    turn = ternary lowest non-zero 1=left 2=right
  # 2 0 4     1    1
  # 2 2 4    10    2
  # 0 0 4    11   10
  # 2 2 4   100   11
  # 2 0 4   101   12
  # 0 2 4   110   20
  # 0 0 4   111   21
  # 2 2 4  1000   22
  # 2 0 4        100
  # 2 2 4        101
  # 0 0 4        102
  # 0 2 4        110
  # 2 0 4        111
  # 0 2 4        112
  # 0 0 4        120
  # 2 2 4        121
  # 2 0 4        122
  # 2 2 4        200
  # 0 0 4        201
  # 2 2 4
  # 2 0 4
  # 0 2 4
  # 0 0 4
  # 0 2 4
  # 2 0 4
  # 2 2 4
  # 0 0 4
  # 0 2 4
  # 2 0 4
  # 0 2 4
  # 0 0 4

  sub Tt_to_tturn6 {
    if ($side eq 'right') {
      goto &Rt_to_tturn6;
    } else {
      goto &Lt_to_tturn6;
    }
  }

  sub Rt_to_tturn6 {
    my ($i) = @_;
    {
      if ($i % 3 == 2) { return 4; }
      my $j = $i - int($i/3);
      return (bit_above_lowest_zero($j) ? 0 : 2);
    }
    {
      my $mod = _divrem_mutate($i, 3);
      if ($mod == 2) { return 4; }
      if ($mod == 1) { return ($i % 2 ? 0 : 2); }
      do {
        $mod = _divrem_mutate($i, 2);
      } while ($mod == 0);
      $mod = _divrem_mutate($i, 2);
      return ($mod % 2 ? 0 : 2);
    }
  }

  # i=0
  # i=1  2
  # i=2     j=1
  # i=3     j=2
  # i=4  2
  # i=5     j=3
  # i=6     j=4
  # i=7  2
  # i=8     j=5
  # i=9     j=6
  sub Lt_to_tturn6 {
    my ($i) = @_;
    {
      if ($i % 3 == 1) { return 2; }
      my $j = $i - int(($i+1)/3);
      # print "i=$i j=$j\n";
      return (bit_above_lowest_one($j) ? 4 : 0);
    }
  }

  sub bit_above_lowest_one {
    my ($n) = @_;
    for (;;) {
      if (! $n || ($n % 2) != 0) {
        last;
      }
      $n = int($n/2);
    }
    $n = int($n/2);
    return ($n % 2);
  }
  sub bit_above_lowest_zero {
    my ($n) = @_;
    for (;;) {
      if (($n % 2) == 0) {
        last;
      }
      $n = int($n/2);
    }
    $n = int($n/2);
    return ($n % 2);
  }

  my @dir6_to_dx = (2, 1,-1,-2, -1, 1);
  my @dir6_to_dy = (0, 1, 1, 0, -1,-1);

  my $path = Math::PlanePath::TerdragonCurve->new;
  require Math::NumSeq::PlanePathTurn;
  require Math::NumSeq::PlanePathDelta;

  foreach my $k (1 .. 7) {
    print "k=$k\n";
    if ($side eq 'right') {
      $R[$k] = $R[$k-1] . '2' . $V[$k-1];
      $V[$k] = $R[$k-1] . '0' . $V[$k-1];
    } else {
      $V[$k] = $V[$k-1] . '0' . $R[$k-1];
      $R[$k] = $V[$k-1] . '4' . $R[$k-1];
    }

    my $n_limit = ($side eq 'right' ? 3**$k : 2*3**$k);
    my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                               lattice_type => 'triangular',
                                               side => $side);
    if ($side eq 'left') {
      @$points = reverse @$points;
    }
    if (@$points < 20) {
      print "points";
      foreach my $p (@$points) {
        print "  $p->[0],$p->[1]";
      }
      print "\n";
    }
    my @values;
    foreach my $i (1 .. $#$points - 1) {
      my $tturn6 = points_to_tturn6($points->[$i-1], $points->[$i], $points->[$i+1]);
      # if ($tturn6 > 3) { $tturn6 -= 6; }
      # my $dir6 = Math::NumSeq::PlanePathDelta::_delta_func_TDir6($dx,$dy);
      # if ($dir6 > 3) { $dir6 -= 6; }
      push @values, $tturn6;
    }

    # {
    #   my @new_values;
    #   for (my $i = 2; $i <= $#values; $i += 3) {
    #     push @new_values, $values[$i] / 2;
    #   }
    #   @values = @new_values;
    # }

    Math::OEIS::Grep->search(array => \@values);

    my $v = join('',@values);
    print "p $v\n";
    if ($side eq 'right') {
      print "R $R[$k]\n";
      if ($v ne $R[$k]) {
        print "  wrong\n";
      }
    } else {
      print "V $V[$k]\n";
      if ($v ne $V[$k]) {
        print "  wrong\n";
      }
    }
    my $f = join('', map {Tt_to_tturn6($_)} 1 .. scalar(@values));
    print "f $f\n";
    if ($v ne $f) {
      print "  wrong\n";
    }
  }

  foreach my $i (1 .. 18) {
    my $tturn6 =  Tt_to_tturn6($i);
    my $pn = ($tturn6 == 2 ? 1 : $tturn6 == 0 ? 0 : $tturn6 == 4 ? -1 : die);
    print "$pn, ";
  }
  print "\n";

  exit 0;

  sub points_to_tturn6 {
    my ($p1,$p2,$p3) = @_;
    my ($x1,$y1) = @$p1;
    my ($x2,$y2) = @$p2;
    my ($x3,$y3) = @$p3;
    my $dx = $x2-$x1;
    my $dy = $y2-$y1;
    my $next_dx = $x3-$x2;
    my $next_dy = $y3-$y2;
    require Math::NumSeq::PlanePathTurn;
    return Math::NumSeq::PlanePathTurn::_turn_func_TTurn6($dx,$dy, $next_dx,$next_dy);
  }
}




{
  # dRadius range
  my $n = 118088;
  require Math::PlanePath::TerdragonMidpoint;
  my $path = Math::PlanePath::TerdragonMidpoint->new;
  my ($x1,$y1) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
  print "$x1,$y1   $x2,$y2\n";
  exit 0;
}
{
  # A+Yw  A=X-Y
  require Math::BaseCnv;
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $dx_min = 0;
  my $dx_max = 0;
  foreach my $n (1 .. 3**10) {
    my ($dx,$dy) = $path->n_to_dxdy($n);
    if ($dx == 299) {
      my $n3 = Math::BaseCnv::cnv($n,10,3);
      printf "%3d  %s\n", $n, $n3;
    }
    $dx_min = min($dx_min,$dx);
    $dx_max = max($dx_max,$dx);
  }
  print "$dx_min $dx_max\n";
  exit 0;
}
{
  # A+Yw  A=X-Y
  require Math::BaseCnv;
  my $path = Math::PlanePath::TerdragonCurve->new;
  my @values;
  foreach my $n (1 .. 3**6) {
    my @n_list = $path->n_to_n_list($n);
    if (@n_list == 1) {
      push @values, $n;
    }

    if (@n_list == 1 && $n == $n_list[0]) {
      my $n3 = Math::BaseCnv::cnv($n,10,3);
      printf "%3d  %s\n", $n, $n3;
    }
  }

  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array=>\@values);
  exit 0;
}
{
  # A+Yw  A=X-Y
  my $path = Math::PlanePath::TerdragonCurve->new;
  my @values;
  foreach my $n (1 .. 20) {
    my ($x,$y) = $path->n_to_xy($n);
    push @values, ($x-$y);
  }
  Math::OEIS::Grep->search(array=>\@values);
  exit 0;
}


{
  # TerdragonCurve direction away from a point

  require Image::Base::Text;
  my $arms = 6;
  my $path = Math::PlanePath::TerdragonCurve->new (arms => $arms);

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

  my ($n_lo, $n_hi) = $path->rect_to_n_range($x_lo-2,$y_lo-2, $x_hi+2,$y_hi+2);
  print "n_hi $n_hi\n";
  for my $n (0 .. $n_hi) {
    my $arm = $n % $arms;

    my ($x,$y) = $path->n_to_xy($n);
    next if $x < $x_lo || $y < $y_lo || $x > $x_hi || $y > $y_hi;

    my ($nx,$ny) = $path->n_to_xy($n + $arms);
    my $dir = dxdy_to_dir6($nx-$x,$ny-$y);
    if ($dir == 2) {
      $plot->($x, $y, $dir);
    }
  }
  $plot->(0,0, '+');
  $image->save('/dev/stdout');

  exit 0;
}

{
  # TerdragonCurve xy_to_n offsets to Midpoint

  require Math::PlanePath::TerdragonMidpoint;
  my $arms = 6;
  my $curve = Math::PlanePath::TerdragonCurve->new (arms => $arms);
  my $midpoint = Math::PlanePath::TerdragonMidpoint->new (arms => $arms);
  my %seen;
  for my $n (0 .. 1000) {
    my ($x,$y) = $curve->n_to_xy($n);
    $x *= 2;
    $y *= 2;

    for my $dx (-2 .. 2) {
      for my $dy (-1 .. 1) {

        my $m = $midpoint->xy_to_n($x+$dx,$y+$dy) // next;
        if ($m == $n) {
          $seen{"$dx,$dy"} = 1;
        }
      }
    }
  }
  ### %seen
  exit 0;
}

{
  # TerdragonCurve xy cf Midpoint

  require Image::Base::Text;
  require Math::PlanePath::TerdragonMidpoint;
  my $arms = 6;
  my $curve = Math::PlanePath::TerdragonCurve->new (arms => $arms);
  my $midpoint = Math::PlanePath::TerdragonMidpoint->new (arms => $arms);

  my $width = 50;
  my $height = 30;
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

  my ($n_lo, $n_hi) = $curve->rect_to_n_range($x_lo-2,$y_lo-2, $x_hi+2,$y_hi+2);
  print "n_hi $n_hi\n";
  for my $y ($y_lo .. $y_hi) {
    for my $x ($x_lo .. $x_hi) {
      my $n = $curve->xy_to_n($x,$y) // next;
      my $arm = $n % $arms;

      my ($nx,$ny) = $curve->n_to_xy($n + $arms);
      my $dir = dxdy_to_dir6($nx-$x,$ny-$y);
      $plot->($x, $y, $dir);
    }
  }
  $plot->(0,0, '+');
  $image->save('/dev/stdout');

  exit 0;
}

{
  # TerdragonMidpoint xy absolute direction

  require Image::Base::Text;
  require Math::PlanePath::TerdragonMidpoint;
  my $arms = 6;
  my $path = Math::PlanePath::TerdragonMidpoint->new (arms => $arms);

  my $width = 50;
  my $height = 30;
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

  my ($n_lo, $n_hi) = $path->rect_to_n_range($x_lo-2,$y_lo-2, $x_hi+2,$y_hi+2);
  print "n_hi $n_hi\n";
  for my $n (0 .. $n_hi) {
    my $arm = $n % $arms;

    my ($x,$y) = $path->n_to_xy($n);
    # if (($n % $arms) == 1) {
    #   $x += 1;
    #   $y += 1;
    # }
    next if $x < $x_lo || $y < $y_lo || $x > $x_hi || $y > $y_hi;

    my ($nx,$ny) = $path->n_to_xy($n + $arms);
    # if (($n % $arms) == 1) {
    #   $nx += 1;
    #   $ny += 1;
    # }

    # if ($nx == $x+1) {
    #   $image->xy($x,$y,$n&3);
    # }
    # if ($ny == $y+1) {
    #   $image->xy($x,$y,$n&3);
    # }
    # if ($ny == $y) {
    # }

    my $show;
    my $dir = dxdy_to_dir6($nx-$x,$ny-$y);
    my $digit = (($x + 3*$y) + 0) % 3;
    my $d9 = ((2*$x + $y) + 0) % 9;
    my $c = ($x+$y)/2;
    my $flow = sprintf "%X", ($x + 3*$y) % 12;

    my $prev_dir = -1;
    if ($n >= $arms) {
      my ($px,$py) = $path->n_to_xy($n - $arms);
      $prev_dir = dxdy_to_dir6($x-$px,$y-$py);
    }

    foreach my $r (0,1,2) {
      $flow = ($r == 0 ? '-'
               : $r == 1 ? '/'
               : '\\');
      if ($arm & 1) {
        if (($digit == 0 || $digit == 1)
            && (($dir%3) == $r)) {
          $show = $flow;
        }
        if (($digit == 2)
            && (($prev_dir%3) == $r)) {
          $show = $flow;
        }
      } else {
        if (($digit == 0 || $digit == 2)
            && (($dir%3) == $r)) {
          $show = $flow;
        }
        if (($digit == 1)
            && (($prev_dir%3) == $r)) {
          $show = $flow;
        }
      }
    }
    if (! defined $show) {
      $show = '.';
    }


    # if ($digit == 1) {
    #   if ($dir == 0 || $dir == 3) {
    #     $show = $dir;
    #     $show = 'x';
    #   }
    # }
    # if ($digit == 2) {
    #   if ($dir == 0 || $dir == 3) {
    #     $show = $prev_dir;
    #     $show = 'x';
    #   }
    # }
    # if ($digit == 0) {
    #   $show = 'x';
    # }

    my $mod = (int($n/$arms) % 3);

    # if (($arm == 0 && $mod == 0)
    #     || ($arm == 1 && $mod == 2)
    #     || ($arm == 2 && $mod == 0)
    #     || ($arm == 3 && $mod == 2)
    #     || ($arm == 4 && $mod == 0)
    #     || ($arm == 5 && $mod == 2)) {
    #   # $show = '0';
    #   # $show = $digit;
    #   if ($n < 3*$arms) {
    #     print "n=$n $x,$y  mod=$mod\n";
    #   }
    # }
    # if (($arm == 0 && $mod == 1)
    #     || ($arm == 1 && $mod == 1)
    #     || ($arm == 2 && $mod == 1)
    #     || ($arm == 3 && $mod == 1)
    #     || ($arm == 4 && $mod == 1)
    #     || ($arm == 5 && $mod == 1)) {
    #   # $show = '1';
    # }
    # if (($arm == 0 && $mod == 2)
    #     || ($arm == 1 && $mod == 0)
    #     || ($arm == 2 && $mod == 2)
    #     || ($arm == 3 && $mod == 0)
    #     || ($arm == 4 && $mod == 2)
    #     || ($arm == 5 && $mod == 0)) {
    #   #      $show = '2';
    # }

    if (defined $show) {
      $plot->($x, $y, $show);
    }
    # if ($dir == 0) {
    #   $image->xy($x-$x_lo,$y-$y_lo, $dir);
    # }
  }
#  $plot->(0,0, '+');
  $image->save('/dev/stdout');

  exit 0;
}

{
  require Math::PlanePath::TerdragonMidpoint;
  my $path = Math::PlanePath::TerdragonMidpoint->new;
  $path->xy_to_n(5,3);
  exit 0;
}

{
  # TerdragonMidpoint modulo

  require Math::PlanePath::TerdragonMidpoint;
  my $arms = 2;
  my $path = Math::PlanePath::TerdragonMidpoint->new (arms => $arms);

  for my $n (0 .. 3**4) {
    my $arm = $n % $arms;
    my $mod = (int($n/$arms) % 3);

    my ($x,$y) = $path->n_to_xy($n);
    my $digit = (($x + 3*$y) + 0) % 3;
    print "n=$n $x,$y  mod=$mod  k=$digit\n";
  }
  exit 0;
}

{
  # cumulative turn +/- 1 list
  require Math::BaseCnv;
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $cumulative = 0;
  for (my $n = $path->n_start + 1; $n < 35; $n++) {
    my $n3 = Math::BaseCnv::cnv($n,10,3);
    my $turn = calc_n_turn ($n);
    #    my $turn = path_n_turn($path, $n);
    if ($turn == 2) { $turn = -1 }
    $cumulative += $turn;
    printf "%3s  %4s  %d\n", $n, $n3, $cumulative;
  }
  print "\n";
  exit 0;
}

{
  # cumulative turn +/- 1
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $cumulative = 0;
  my $max = 0;
  my $min = 0;
  for (my $n = $path->n_start + 1; $n < 35; $n++) {
    my $turn = calc_n_turn ($n);
    #    my $turn = path_n_turn($path, $n);
    if ($turn == 2) { $turn = -1 }
    $cumulative += $turn;
    $max = max($cumulative,$max);
    $min = min($cumulative,$min);
        print "$cumulative,";
  }
  print "\n";
  print "min $min  max $max\n";
  exit 0;

  sub calc_n_turn {
    my ($n) = @_;

    die if $n == 0;
    while (($n % 3) == 0) {
      $n = int($n/3); # skip low 0s
    }
    return ($n % 3);  # next digit is the turn
  }
}

{
  # turn
  my $path = Math::PlanePath::TerdragonCurve->new;

  my $n = $path->n_start;
  # my ($n0_x, $n0_y) = $path->n_to_xy ($n);
  # $n++;
  # my ($prev_x, $prev_y) = $path->n_to_xy ($n);
  # my ($prev_dx, $prev_dy) = ($prev_x - $n0_x, $prev_y - $n0_y);
  # my $prev_dir = dxdy_to_dir ($prev_dx, $prev_dy);
  $n++;

  my $pow = 3;
  for ( ; $n < 128; $n++) {
    # my ($x, $y) = $path->n_to_xy ($n);
    # my $dx = $x - $prev_x;
    # my $dy = $y - $prev_y;
    # my $dir = dxdy_to_dir ($dx, $dy);
    # my $turn = ($dir - $prev_dir) % 3;
    #
    # $prev_dir = $dir;
    # ($prev_x,$prev_y) = ($x,$y);

    my $turn = path_n_turn($path, $n);

    my $azeros = digit_above_low_zeros($n);
    my $azx = ($azeros == $turn ? '' : '*');

    # my $aones = digit_above_low_ones($n-1);
    # if ($aones==0) { $aones=1 }
    # elsif ($aones==1) { $aones=0 }
    # elsif ($aones==2) { $aones=2 }
    # my $aox = ($aones == $turn ? '' : '*');
    #
    # my $atwos = digit_above_low_twos($n-2);
    # if ($atwos==0) { $atwos=1 }
    # elsif ($atwos==1) { $atwos=2 }
    # elsif ($atwos==2) { $atwos=0 }
    # my $atx = ($atwos == $turn ? '' : '*');
    #
    # my $lzero = digit_above_low_zeros($n);
    # my $lone = digit_above_lowest_one($n);
    # my $ltwo = digit_above_lowest_two($n);
    # print "$n  $turn   ones $aones$aox   twos $atwos$atx  zeros $azeros${azx}[$lzero]    $lone $ltwo\n";

    print "$n  $turn   zeros got=$azeros ${azx}\n";
  }
  print "\n";
  exit 0;

  sub digit_above_low_zeros {
    my ($n) = @_;
    if ($n == 0) {
      return 0;
    }
    while (($n % 3) == 0) {
      $n = int($n/3);
    }
    return ($n % 3);
  }

  sub path_n_turn {
    my ($path, $n) = @_;
    my $prev_dir = path_n_dir ($path, $n-1);
    my $dir = path_n_dir ($path, $n);
    return ($dir - $prev_dir) % 3;
  }
  sub path_n_dir {
    my ($path, $n) = @_;
    my ($prev_x, $prev_y) = $path->n_to_xy ($n);
    my ($x, $y) = $path->n_to_xy ($n+1);
    return dxdy_to_dir($x - $prev_x, $y - $prev_y);
  }
}

{
  # min/max for level
  require Math::BaseCnv;
  my $path = Math::PlanePath::TerdragonCurve->new;
  my $prev_min = 1;
  my $prev_max = 1;
  for (my $level = 1; $level < 25; $level++) {
    my $n_start = 3**($level-1);
    my $n_end = 3**$level;

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
      my $h = $x*$x + 3*$y*$y;

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
      my $min_hypot3 = Math::BaseCnv::cnv($min_hypot,10,3);
      print "  min h= $min_hypot  [$min_hypot3]   at $min_pos  factor $factor\n";
      my $calc = (4/3/3) * 2.9**$level;
      print "    cf $calc\n";
    }
    # {
    #   my $factor = $max_hypot / $prev_max;
    # my $max_hypot3 = Math::BaseCnv::cnv($max_hypot,10,3);
    #   print "  max h= $max_hypot  [$max_hypot3]  at $max_pos  factor $factor\n";
    #   # my $calc = 4 * 3**($level*.9) * 4**($level*.1);
    #   # print "    cf $calc\n";
    # }
    $prev_min = $min_hypot;
    $prev_max = $max_hypot;
  }
  exit 0;
}




{
  # turn
  my $path = Math::PlanePath::TerdragonCurve->new;

  my $n = $path->n_start;
  my ($n0_x, $n0_y) = $path->n_to_xy ($n);
  $n++;
  my ($prev_x, $prev_y) = $path->n_to_xy ($n);
  my ($prev_dx, $prev_dy) = ($prev_x - $n0_x, $prev_y - $n0_y);
  my $prev_dir = dxdy_to_dir ($prev_dx, $prev_dy);
  $n++;

  my $pow = 3;
  for ( ; $n < 128; $n++) {
    my ($x, $y) = $path->n_to_xy ($n);
    my $dx = ($x - $prev_x);
    my $dy = ($y - $prev_y);
    my $dir = dxdy_to_dir ($dx, $dy);
    my $turn = ($dir - $prev_dir) % 3;

    $prev_dir = $dir;
    ($prev_x,$prev_y) = ($x,$y);

    print "$turn";
    if ($n-1 == $pow) {
      $pow *= 3;
      print "\n";
    }
  }
  print "\n";
  exit 0;
}

sub path_to_dir6 {
  my ($path,$n) = @_;
  my ($x,$y) = $path->n_to_xy($n);
  my ($nx,$ny) = $path->n_to_xy($n + $path->arms_count);
  return dxdy_to_dir6($nx-$x,$ny-$y);
}
sub dxdy_to_dir6 {
  my ($dx,$dy) = @_;
  if ($dy == 0) {
    if ($dx == 2) { return 0; }
    if ($dx == -2) { return 3; }
  }
  if ($dy == 1) {
    if ($dx == 1) { return 1; }
    if ($dx == -1) { return 2; }
  }
  if ($dy == -1) {
    if ($dx == 1) { return 5; }
    if ($dx == -1) { return 4; }
  }
  die "unrecognised $dx,$dy";
}

# per KochCurve.t
sub dxdy_to_dir {
  my ($dx,$dy) = @_;
  if ($dy == 0) {
    if ($dx == 2) { return 0/2; }
    # if ($dx == -2) { return 3; }
  }
  if ($dy == 1) {
    # if ($dx == 1) { return 1; }
    if ($dx == -1) { return 2/2; }
  }
  if ($dy == -1) {
    # if ($dx == 1) { return 5; }
    if ($dx == -1) { return 4/2; }
  }
  die "unrecognised $dx,$dy";
}

sub digit_above_low_ones {
  my ($n) = @_;
  if ($n == 0) {
    return 0;
  }
  while (($n % 3) == 1) {
    $n = int($n/3);
  }
  return ($n % 3);
}
sub digit_above_low_twos {
  my ($n) = @_;
  if ($n == 0) {
    return 0;
  }
  while (($n % 3) == 2) {
    $n = int($n/3);
  }
  return ($n % 3);
}

sub digit_above_lowest_zero {
  my ($n) = @_;
  for (;;) {
    if (($n % 3) == 0) {
      last;
    }
    $n = int($n/3);
  }
  $n = int($n/3);
  return ($n % 3);
}
sub digit_above_lowest_one {
  my ($n) = @_;
  for (;;) {
    if (! $n || ($n % 3) != 0) {
      last;
    }
    $n = int($n/3);
  }
  $n = int($n/3);
  return ($n % 3);
}
sub digit_above_lowest_two {
  my ($n) = @_;
  for (;;) {
    if (! $n || ($n % 3) != 0) {
      last;
    }
    $n = int($n/3);
  }
  $n = int($n/3);
  return ($n % 3);
}
