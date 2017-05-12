#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015 Kevin Ryde

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
use Math::PlanePath::SierpinskiTriangle;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


#
#
#
#
#
#
#
#
#
#
#
#
#
#
# 8  14
# 7     10  11  12  13
# 6        8       9
# 5          6   7
# 4            5
# 3              3   4
# 2                2
# 1                  1
# 0                    0
#

{
  # number of children
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  for (my $n = $path->n_start; $n < 180; $n++) {
    my @n_children = $path->tree_n_children($n);
    my $num_children = scalar(@n_children);
    print "$num_children,";
    print "\n" if path_tree_n_is_depth_end($path,$n);
  }
  print "\n";
  exit 0;

  sub path_tree_n_is_depth_end {
    my ($path, $n) = @_;
    my $depth = $path->tree_n_to_depth($n);
    return defined($depth) && $n == $path->tree_depth_to_n_end($depth);
  }
}
{
  # Pascal's triangle as a graph
  my $max_row = 4;
  require Graph::Easy;
  require Math::BigInt;
  my $graph = Graph::Easy->new;
  foreach my $row (0 .. $max_row) {
    foreach my $col (0 .. $row) {
      my $n = Math::BigInt->new($row)->bnok($col);
      next unless $n % 2;
      $graph->add_vertex("$row,$col=$n");
      next if $row >= $max_row;

      my $row2 = $row + 1;
      foreach my $col2 ($col, $col+1) {
        my $n2 = Math::BigInt->new($row2)->bnok($col2);
        ### consider: "$row2,$col2=$n2"
        next unless $n2 % 2;
        $graph->add_edge("$row,$col=$n", "$row2,$col2=$n2");
      }
    }
  }
  print $graph->as_ascii();

  exit 0;
}


{
  # 41                                     81
  #    33  34  35  36  37  38  39  40         65  66  67  68  69  70  71  72  73  74  75  76  77  78  79  80   15
  #      29      30      31      32             57      58      59      60      61      62      63      64     14
  #        25  26          27  28                 49  50          51  52          53  54          55  56       13
  #          23              24                     45              46              47              48         12
  #            19  20  21  22                         37  38  39  40                  41  42  43  44           11
  #              17      18                             33      34                      35      36             10
  #                15  16                                 29  30                          31  32                9
  #                  14                        8            27                              28
  #                    10  11  12  13          7              19  20  21  22  23  24  25  26
  #                       8       9            6                15      16      17      18
  #                         6   7              5                  11  12          13  14
  #                           5                4                     9              10
  #                             3   4          3                       5   6   7   8
  #                               2            2                         3       4
  #                                 1          1                           1   2
  #                                   0   <- Y=0                             0
  #
  #  0,1,2,3,3, 4,5,5

  Math::PlanePath::SierpinskiTriangle::_n0_to_depthbits(81,'all');

  my $parts = 'left';
  foreach my $n (0 .. 41) {
    my ($depthbits, $ndepth, $nwidth) = Math::PlanePath::SierpinskiTriangle::_n0_to_depthbits($n,$parts);
    my $depth = digit_join_lowtohigh ($depthbits, 2);
    print "n=$n   depth= $depth   ndepth= $ndepth\n";
  }
  exit 0;
}


{
  # centroid
  # X = 0  midpoint
  # Y = (2^n - 2)/3
  # I = (4*12^n-3^n)/3 * 24/9
  #   = 8/9 * (4*12^n-3^n)
  #   = 8/3 * 3^k * (4*4^k - 1)/3
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  my @values;
  foreach my $level (0 .. 7) {
    my ($n_lo, $n_hi) = $path->level_to_n_range($level);
    my $gx = 0;
    my $gy = 0;
    my $count = 0;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      $gx += $x;
      $gy += $y;
      $count++;
    }
    $gx = to_bigrat($gx);
    $gy = to_bigrat($gy);
    $gx /= $count;
    $gy /= $count;

    my $I = 0;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      $I += ($x - $gx)**2 + ($y - $gy)**2;
    }
    $I /= 3**$level;

    push @values, $I*9/24;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose => 1);
  exit 0;

  sub to_bigrat {
    my ($n) = @_;
    require Math::BigRat;
    return Math::BigRat->new($n);
    # return $n;
  }
}


{
  # Pascal's triangle
  require Math::BigInt;
  my @array;
  my $rows = 10;
  my $width = 0;
  foreach my $y (0 .. $rows) {
    foreach my $x (0 .. $y) {
      my $n = Math::BigInt->new($y);
      my $k = Math::BigInt->new($x);
      $n->bnok($k);
      my $str = "$n";
      $array[$x][$y] = $str;
      $width = max($width,length($str));
    }
  }
  $width += 2;
  if ($width & 1) { $width++; }
  # $width |= 1;
  foreach my $y (0 .. $rows) {
    print ' ' x (($rows-$y) * int($width/2));
    foreach my $x (0 .. $y) {
      my $value = $array[$x][$y];
      unless ($value & 1) { $value = ''; }
      printf "%*s", $width, $value;
    }
    print "\n";
  }
  exit 0;
}

{
  # NumSiblings run lengths
  # lowest 1-bit of pos k

  # NumChildren run lengths
  # is same lowest 1-bit if NumChildren=0 leaf coalesced with NumChildren=1

  my $path = Math::PlanePath::SierpinskiTriangle->new (align => 'diagonal');
  require Math::NumSeq::PlanePathCoord;
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath_object => $path,
                                               # coordinate_type => 'NumChildren',
                                               coordinate_type => 'NumSiblings',
                                              );

  my $prev = 0;
  my $run = 1;
  for (my $n = $path->n_start+1; $n < 500; $n++) {
    my ($i,$value) = $seq->next;
    $value = 1-$value;
    # if ($value == 1) { $value = 0; }
    # if ($value == $prev) {
    #   $run++;
    # } else {
    #   print "$run,";
    #   $run = 1;
    #   $prev = $value;
    # }
    # printf "%4b  %d\n", $i, $value;
    print "$value,";
  }
  print "\n";
  exit 0;

  sub path_tree_n_num_siblings {
    my ($path, $n) = @_;
    $n = $path->tree_n_parent($n);
    return (defined $n
            ? $path->tree_n_num_children($n) - 1  # not including self
            : 0);  # any tree root considered to have no siblings
  }
}

{
  # height

  use constant _INFINITY => do {
    my $x = 999;
    foreach (1 .. 20) {
      $x *= $x;
    }
    $x;
  };

  my $path = Math::PlanePath::SierpinskiTriangle->new (align => 'diagonal');
  require Math::NumSeq::PlanePathCoord;
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath_object => $path,
                                               coordinate_type => 'SubHeight');

  for (my $n = $path->n_start; $n < 500; $n++) {
    my ($x,$y) = $path->n_to_xy($n);
    my $s = $seq->ith($n);
    # my $c = $path->_UNTESTED__NumSeq__tree_n_to_leaflen($n);
    my $c = n_to_subheight($n);
    if (! defined $c) { $c = _INFINITY; }
    my $diff = ($s == $c ? '' : ' ***');
    print "$x,$y  $s  $c$diff\n";
  }
  print "\n";
  exit 0;

  sub n_to_subheight {
    my ($n) = @_;

    # this one correct based on diagonal X,Y bits
    my ($x,$y) = $path->n_to_xy($n);
    if ($x == 0 || $y == 0) {
      return _INFINITY();
    }
    my $mx = ($x ^ ($x-1)) >> 1;
    my $my = ($y ^ ($y-1)) >> 1;
    return max ($mx - ($y & $mx),
                $my - ($x & $my));


    # Must stretch out $n remainder to make X.
    # my ($depthbits, $ndepth, $nwidth) = Math::PlanePath::SierpinskiTriangle::_n0_to_depthbits($n);
    # $n -= $ndepth;  # X
    # my $y = digit_join_lowtohigh ($depthbits, 2, $n*0) - $n;
    #
    # if ($n == 0 || $y == 0) {
    #   return undef;
    # }
    # my $mx = ($n ^ ($n-1)) >> 1;
    # my $my = ($y ^ ($y-1)) >> 1;
    # return max ($mx - ($y & $mx),
    #             $my - ($n & $my));

    # my $h = high_bit($y);
    # my $m = ($h<<1)-1;
    # return $y ^ $m;
    # # return count_0_bits($y); # - count_0_bits($x);
  }
  sub high_bit {
    my ($n) = @_;
    my $bit = 1;
    while ($bit <= $n) {
      $bit <<= 1;
    }
    return $bit >> 1;
  }
  sub count_0_bits {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += ($n & 1) ^ 1;
      $n >>= 1;
    }
    return $count;
  }
  sub count_1_bits {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += ($n & 1);
      $n >>= 1;
    }
    return $count;
  }
}


{
  # number of children in replicate style

  my $levels = 5;
  my $height = 2**$levels;

  sub replicate_n_to_xy {
    my ($n) = @_;
    my $zero = $n * 0;
    my @xpos_bits;
    my @xneg_bits;
    my @y_bits;
    foreach my $ndigit (digit_split_lowtohigh($n,3)) {
      if ($ndigit == 0) {
        push @xpos_bits, 0;
        push @xneg_bits, 0;
        push @y_bits, 0;
      } elsif ($ndigit == 1) {
        push @xpos_bits, 0;
        push @xneg_bits, 1;
        push @y_bits, 1;
      } else {
        push @xpos_bits, 1;
        push @xneg_bits, 0;
        push @y_bits, 1;
      }
    }

    return (digit_join_lowtohigh(\@xpos_bits, 2, $zero)
            - digit_join_lowtohigh(\@xneg_bits, 2, $zero),

            digit_join_lowtohigh(\@y_bits, 2, $zero));
  }

  # xxx0    = 2    low digit 0 then num children = 2
  # xxx0111 = 1  \ low digit != 0 then all low non-zeros must be same
  # xxx0222 = 1  /
  # other   = 0    otherwise num children = 0

  sub replicate_tree_n_num_children {
    my ($n) = @_;
    $n = int($n);
    my $low_digit = _divrem_mutate($n,3);
    if ($low_digit == 0) {
      return 2;
    }
    while (my $digit = _divrem_mutate($n,3)) {
      if ($digit != $low_digit) {
        return 0;
      }
    }
    return 1;
  }

  my $path = Math::PlanePath::SierpinskiTriangle->new;
  my %grid;
  for (my $n = 0; $n < 3**$levels; $n++) {
    my ($x,$y) = replicate_n_to_xy($n);
    my $path_num_children = path_xy_num_children($path,$x,$y);
    my $repl_num_children = replicate_tree_n_num_children($n);
    if ($path_num_children != $repl_num_children) {
      print "$x,$y  $path_num_children $repl_num_children\n";
      exit 1;
    }
    $grid{$x}{$y} = $repl_num_children;
  }

  foreach my $y (0 .. $height) {
    foreach my $x (-$height .. $y) {
      print $grid{$x}{$y} // ' ';
    }
    print "\n";
  }
  exit 0;

  sub path_xy_num_children {
    my ($path, $x,$y) = @_;
    my $n = $path->xy_to_n($x,$y);
    return (defined $n
            ? $path->tree_n_num_children($n)
            : undef);
  }
}


{
  my $path = Math::PlanePath::SierpinskiTriangle->new;
  foreach my $y (0 .. 10) {
    foreach my $x (-$y .. $y) {
      if ($path->xy_to_n($x,$y)) {
        print "1,";
      } else {
        print "0,";
      }
    }
  }
  print "\n";
  exit 0;
}
