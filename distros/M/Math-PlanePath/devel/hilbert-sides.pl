#!/usr/bin/perl -w

# Copyright 2015, 2019, 2020, 2021 Kevin Ryde

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

use 5.010;
use strict;
use FindBin;
use List::Util 'min','max','sum';
use Math::PlanePath::HilbertCurve;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # HilbertSides number of overlap segments

  # singles 0,3,13,53,209,829,3297,13149,52513
  #
  # doubles 0,0,1,5,23,97,399,1617,6511
  # A109765  gf x/( (1-4*x)*(1-2*x)*(1+x) )
  # recurrence_guess(OEIS_samples("A109765"))
  # 2/5*4^n - 1/3*2^n + vector_modulo([-1/15, 1/15],n)

  require Math::PlanePath::HilbertSides;
  my $path = Math::PlanePath::HilbertSides->new;
  my %count;
  my $n = 0;
  my ($prev_x,$prev_y) = $path->n_to_xy($n++);
  my (@v1,@v2);
  foreach my $k (0 .. 8) {
    my $limit = 4**$k;
    for ( ; $n < $limit; $n++) {
      my ($x,$y) = $path->n_to_xy($n);
      if ($x < $prev_x || $y < $prev_y) {
        $count{"$x,$y to $prev_x,$prev_y"}++;
      } else {
        $count{"$prev_x,$prev_y to $x,$y"}++;
      }
      ($prev_x,$prev_y) = ($x,$y);
    }
    my @hist = (0,0,0);
    foreach my $value (values %count) {
      $hist[$value]++;
    }
    ### @hist
    print "k=$k  $hist[1], $hist[2]\n";
    push @v1, $hist[1];
    push @v2, $hist[2];
    $hist[1] + 2*$hist[2] == 4**$k-1 or die;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@v1, name => "v1", verbose=>1);
  Math::OEIS::Grep->search(array => \@v2, name => "v2", verbose=>1);
  exit 0;

  # singles(k) = 9/10*4^k + 1/6*2^k - 1/15*(-1)^k - 1;
  # vector(8,k,k--; singles(k))
  # gsingles(x) = (x^2)/(1 - 5*x + 2*x^2 + 8*x^3);
  # gf_terms(gsingles(x), 8)
  # doubles(k) = 1/10*4^k - 1/6*2^k + 1/15*(-1)^k;
  # vector(8,k,k--; doubles(k))
  # gdoubles(x) = (x^2)/(1 - 5*x + 2*x^2 + 8*x^3);
  # gf_terms(gdoubles(x), 8)
  # vector(8,k,k--; singles(k)+doubles(k))

  # sub sides_count_1s {
  #   my ($k) = @_;
  #   # even
  #   + (1/15)/(1 + x)
  #   + (-1/6)/(1 - 2*x)
  #   + (1/10)/(1 - 4*x)
  # }
}

{
  # HilbertSides axis count

  #   3 |  5----6---7,9--10---11
  #     |  |         |         |
  #   2 |  4----3    8   13---12        24---23
  #     |       |         |                   |
  #   1 |       2        14   17---18---19   22
  #     |       |         |    |         |    |
  # Y=0 |  0----1        15---16        20---21
  #
  # X 1,1,2,3,6,11,22,43,86
  # A005578 a(n) = 2/3*2^n - 1/6*(-1)^n + 1/2
  #
  # Y 0,0,1,2,5,10,21,42,85
  # A000975 binary 1010...
  #
  # Xsegs(k) = 1/3*2^k + 1/2 + 1/6*(-1)^k;
  # Ysegs(k) = 1/3*2^k - 1/2 + 1/6*(-1)^k;
  # Xsegs(k) = if(k==0,1, k%2, Xsegs(k-1)+Ysegs(k-1), 2*Xsegs(k-1));
  # Ysegs(k) = if(k==0,0, k%2, 2*Ysegs(k-1), Xsegs(k-1)+Ysegs(k-1));
  # read("memoize.gp"); Xsegs = memoize(Xsegs); Ysegs = memoize(Ysegs);
  # vector(19,k,k--; Xsegs(k))
  # vector(19,k,k--; Ysegs(k))
  # vector(30,k,k--; Xsegs(k)) == vector(30,k,k--; Ysegs(k)+1)
  # D(k) = if(k==0,0, 4*D(k-1) + if(k%2,Ysegs(k-1),Xsegs(k-1)));
  # vector(9,k,k--; D(k))

  require Math::PlanePath::HilbertSides;
  my $path = Math::PlanePath::HilbertSides->new;
  foreach my $axis (0, 1) {
    my @values;
    foreach my $k (0 .. 8) {
      my $count = 0;
      foreach my $i (0 .. 2**$k-1) {
        my $x = ($axis ? 0 : $i);
        my $y = ($axis ? $i : 0);
        my $n = $path->xy_to_n($x,$y) // next;
        my ($dx,$dy) = $path->n_to_dxdy($n);
        $dy == $axis || next;
        $count++;
      }
      print "k=$k ($axis)   $count\n";
      push @values, $count;
    }
    require Math::OEIS::Grep;
    Math::OEIS::Grep->search(array => \@values, name => "$axis", verbose=>1);
  }
  exit 0;
}

{
  # HilbertSides axis N

  # hex digit    0 1                            E F
  my @table = ([ 0,1,9,9, 9,9,9,9, 9,9,9,9, 9,9,2,0 ],
               [ 1,9,9,2, 0,1,9,9, 9,9,9,9, 9,9,9,9 ],
               [ 9,9,9,9, 9,9,9,9, 9,9,2,0, 1,9,9,2 ]);
  # hex digit    0     3  4 5          A B  C     F
  #           0,F
  #            x 
  #          /^ \^
  #       1 //   \\ B
  #        //4   E\\
  #       v/   C   v\
  #  0,5 y <-------- z A,F
  #        --------> 
  #            3

  sub n_is_side {
    my ($n, $side) = @_;
    my @digits = digit_split_lowtohigh($n,16);
    foreach my $digit (reverse @digits) {
      $side = $table[$side][$digit];
      if ($side == 9) { return 0; }
    }
    return 1;
  }

  require Math::PlanePath::HilbertSides;
  my $path = Math::PlanePath::HilbertSides->new;
  foreach my $n (0 .. 2**16) {
    my ($x,$y) = $path->n_to_xy($n);
    my ($dx,$dy) = $path->n_to_dxdy($n);
    my $want_side = ($y == 0 && $dy == 0 ? 0
                     : $x == 0 && $dx == 0 ? 1
                     : next);
    my $got_side = (n_is_side($n,0) ? 0
                    : n_is_side($n,1) ? 1
                    : -1);
    $want_side == $got_side or die;
  }
  exit 0;
}

{
  # HilbertSides axis N

  # X=0,F  0x 1y  Ez Fx        y   z
  # Y=4    0y 3z  4x 5y        --x--
  # Z=B    Az Bx  Cy Fz

  #           0,F
  #            x 
  #          /^ \^
  #       1 //   \\ B
  #        //4   E\\
  #       v/   C   v\
  #  0,5 y <-------- z A,F
  #        --------> 
  #            3

  require Math::PlanePath::HilbertSides;
  my $path = Math::PlanePath::HilbertSides->new;
  my @values;
  foreach my $x (0 .. 255) {
    my $n = $path->xy_to_n($x,0) // next;
    $path->xy_to_n($x+1,0) // next;
    printf "%3x\n", $n;
    push @values, $n;
  }
  shift @values; shift @values;
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # HilbertSides straight/not

  # turn left or right at 4^k
  # straight at 2^k

  #   3 |  5----6---7,9--10---11
  #     |  |         |         |
  #   2 |  4----3    8   13---12        24---23
  #     |       |         |                   |
  #   1 |       2        14   17---18---19   22
  #     |       |         |    |         |    |
  # Y=0 |  0----1        15---16        20---21
  
  # A096268
  # Straight 
  # 0,1,0, 0,0,1,0, 1,0,1,0,0,0,1,0, 0,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,
  # vector(25,n,valuation(n,2)%2)
  # even,odd trailing 0 bits, period doubling sequence

  require Math::NumSeq::PlanePathTurn;
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath => 'HilbertSides',
                                              turn_type => 'Straight');
  foreach (1 .. 40) {
    my ($i, $value) = $seq->next;
    print "$value,"
  }
  print "\n";
  exit 0;
}

{
  require Math::PlanePath::HilbertSides;
  my $path = Math::PlanePath::HilbertSides->new;
  my @want = ([0,0], [1,0], [1,1], [1,2], [0,2],
              [0,3], [1,3], [2,3], [2,2],
              [2,3], [3,3], [4,3], [4,2],
              [3,2], [3,1], [3,0], [4,0],
             );
  foreach my $n (0 .. 16) {
    my ($x,$y) = $path->n_to_xy($n);
    my $diff = ($n > $#want || ($x == $want[$n]->[0] && $y == $want[$n]->[1])
                ? '' : ' ***');
    print "n=$n  $x,$y$diff\n";
  }
  exit 0;
}
