#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

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
use List::Util 'min', 'max';
use Math::Libm 'hypot';
use Math::PlanePath::PythagoreanTree;
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_join_lowtohigh',
  'digit_split_lowtohigh';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # powers
  foreach my $k (0 .. 41) {
    print 3**$k,"\n";
  }
  exit 0;
}

{
  # repeated "U" or "M1" on initial P=2,Q=1
  require Math::BaseCnv;
  my $path = Math::PlanePath::PythagoreanTree->new
    (
     # tree_type => 'UAD',
     tree_type => 'FB',
     coordinates => 'PQ',
    );
  foreach my $depth (0 .. 5) {
    my $n = $path->tree_depth_to_n($depth);
    my ($x,$y) = $path->n_to_xy($n);
    print "depth=$depth N=$n  P=$x / Q=$y\n";
  }
  exit 0;
}
{
  # X,Y list

  # PQ UAD
  # N=1  2 / 1     
  #
  # N=2  3 / 2      5,12
  # N=3  5 / 2     21,20
  # N=4  4 / 1     15,8
  #
  # N=5  4 / 3
  # N=6  8 / 3
  # N=7  7 / 2
  # N=8  8 / 5
  # N=9  12 / 5
  # N=10  9 / 2
  # N=11  7 / 4
  # N=12  9 / 4
  # N=13  6 / 1

  # PQ FB
  # N=1  2,1
  #
  # N=2  3,2
  # N=3  4,1
  # N=4  4,3
  #
  # N=5  5,4
  # N=6  6,1
  # N=7  6,5
  # N=8  5,2
  # N=9  8,3
  # N=10  8,5
  # N=11  7,6
  # N=12  8,1
  # N=13  8,7


  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new
    (
     # tree_type => 'UMT',
      tree_type => 'UAD',
     # tree_type => 'FB',
      coordinates => 'AB',
     # coordinates => 'PQ',   # P>Q one odd other even
    );
  my $n = $path->n_start;
  foreach my $level (0 .. 5) {
    foreach (1 .. 3**$level) {
      my ($x,$y) = $path->n_to_xy($n);
      #  $x -= $y;
      my $flag = '';
      if ($x <= $y) {
        $flag = '  ***';
      }
      print "N=$n  $x,$y$flag\n";
      $n++;
    }
    print "\n";
  }
  exit 0;
}

{
  # TMU parent/child
  foreach my $n (1 .. 40) {
    if (n_is_row_start($n)) { print "\n"; }
    my $n_str = n_to_pythagstr($n);
    my ($p,$q) = tmu_n_to_pq($n);
    my @pq_children = tmu_pq_children($p,$q);
    my ($p1,$q1,$p2,$q2,$p3,$q3) = @pq_children;
    print "$n = $n_str  $p,$q   children $p1,$q1  $p2,$q2  $p3,$q3\n";
    while (@pq_children) {
      my $child_p = shift @pq_children;
      my $child_q = shift @pq_children;
      my ($parent_p,$parent_q) = tmu_pq_parent($child_p,$child_q);
      if ($parent_p != $p || $parent_q != $q) {
        print "oops\n";
      }
    }
  }
  exit 0;

  sub tmu_pq_children {
    my ($p,$q) = @_;
    return ($p+3*$q, 2*$q,  # T
            2*$p, $p-$q,    # M2 (2p, p-q)
            2*$p-$q, $p);   # "U" = (2p-q, p)
  }
  sub tmu_pq_parent {
    my ($p,$q) = @_;
    if ($p > 2*$q) {
      if ($p % 2) {

        # T  1 3    p -> p+3q      p > 2q,     p odd, q even
        #    0 2    q -> 2q        det=2
        # inverse  1 -3/2
        #          0  1/2
        $q /= 2;
        $p -= 3*$q;
      } else {
        # M2 2  0   p -> 2p        p > 2q,     p even, q odd
        #    1 -1   q -> p-q       det=-2
        # inverse -1  0 / -2 = 1/2  0
        #         -1  2        1/2 -1
        $p /= 2;
        $q = $p - $q;
      }
    } else {
      # U  2 -1   p -> 2p-q      2q > p > q  small p
      #    1  0   q -> p         det=1
      # inverse  0  1  = 0 -1
      #         -1  2    1 -2
      ($p,$q) = ($q, 2*$q-$p);
    }
    return ($p,$q);
  }
}
{
  # 1^2 = 1  3^2 = 9 = 1 mod 4
  # A^2 + B^2 = C^2
  #  1     0     1
  #  0     1     1
  # A = 1 mod 4, B = 0 mod 4
  # even 3mod4, any 1mod4

  exit 0;
}


{
  my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'UMT',
                                                    coordinates => 'PQ');
  $path->xy_to_n(4,5);
  exit 0;
}

{
  # UAD to TMU
  my $uad = Math::PlanePath::PythagoreanTree->new (tree_type => 'UAD',
                                                   coordinates => 'PQ');
  foreach my $n (1 .. 40) {
    if (n_is_row_start($n)) { print "\n"; }
    my ($p,$q) = $uad->n_to_xy($n);
    my $umt_n = umt_pq_to_n($p,$q);
    my $umt_n_str = n_to_pythagstr($umt_n);
    my $n_str = n_to_pythagstr($n);
    print "$n = $n_str  $p,$q   UMT=$n $umt_n_str\n";
  }
  exit 0;

  sub umt_pq_to_n {
    my ($p,$q) = @_;
    my @ndigits;
    while ($p > 2) {

      if ($p > 2*$q) {
        if ($p % 2) {
          $q /= 2;    # T
          $p -= 3*$q;
          push @ndigits, 1;
        } else {
          $p /= 2;   # M2
          $q = $p - $q;
          push @ndigits, 2;
        }
      } else {
        ($p,$q) = ($q, 2*$q-$p);  # U
        push @ndigits, 0;
      }
    }
    my $zero = $p*0*$q;
    return ((3+$zero)**scalar(@ndigits) + 1)/2    # tree_depth_to_n()
      + digit_join_lowtohigh(\@ndigits,3,$zero);  # digits within this depth
  }
}

{
  # U = 2,-1,1,0
  # A = 2,1, 1,0
  # D = 1,2, 0,1

  # M1 = 1,1, 0,2
  # M2 = 2,0, 1,-1
  # M3 = 2,0, 1,1

  # p+2q = unchanged
  # p+q = odd
  # 2p or 2q = even

  # 2a+b>2c+d
  # ap+b>cp+d
  #
  # ap+b(p-1) > cp+d(p-1)
  # (c-1)p+b(p-1) > cp+d(p-1)
  # cp-p+b(p-1) > cp+d(p-1)
  # -p+b(p-1) > d(p-1)
  # b(p-1) > d(p-1)+p
  # b > d+p/(p-1)
  # b > d+1

  #   D        A         U
  # 1,2,0,1  2,-1,1,0  2,1,1,0
  #
  # U  2 -1   p -> 2p-q      2q > p > q    small p
  #    1  0   q -> p         det=1
  #
  # A  2  1   p -> 2p+q      3q > p > 2q    mid p
  #    1  0   q -> p         det=-1
  #
  # D  1  2   p -> p+2q      p > 3q         big p
  #    0  1   q -> q         det=1

  #   M1       M2        M3
  # 1,1,0,2  2,0,1,-1  2,0,1,1
  #
  # M1 1 1    p -> p+q       p > 2q,  p odd, q even
  #    0 2    q -> 2q        det=2
  #
  # M2 2  0   p -> 2p        p > 2q,  p even, q odd
  #    1 -1   q -> p-q       det=-2
  #
  # M3 2  0   p -> 2p        2q > p,  small p,  p even, q odd
  #    1  1   q -> p+q       det=2

  #             U        M2
  # 1,3,0,2  2,-1,1,0  2,0,1,-1
  #
  #
  # T  1 3    p -> p+3q      p > 2q,     p odd, q even
  #    0 2    q -> 2q        det=2
  #
  # M2 2  0   p -> 2p        p > 2q,     p even, q odd
  #    1 -1   q -> p-q       det=-2
  #
  # U  2  1   p -> 2p-q      2q > p > q  small p
  #    1  0   q -> p         det=-1

  my $uad = Math::PlanePath::PythagoreanTree->new (tree_type => 'UAD',
                                                   coordinates => 'PQ');
  my $fb = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB',
                                                  coordinates => 'PQ');
  my $len = 0;
  foreach my $n (1 .. 40) {
    if (n_is_row_start($n)) { print "\n"; }
    my ($p,$q) = tmu_n_to_pq($n);
    my $uad_n = n_to_pythagstr($uad->xy_to_n($p,$q));
    my $fb_n = n_to_pythagstr($fb->xy_to_n($p,$q));
    my $n_str = n_to_pythagstr($n);
    print "$n = $n_str  $p,$q   UAD N=$uad_n   FB N=$fb_n\n";
  }
  exit 0;

  sub n_is_row_start {
    my ($n) = @_;
    my ($pow, $exp) = round_down_pow (2*$n-1, 3);
    return ($n == ($pow+1)/2);
  }
  sub tmu_n_to_pq {
    my ($n) = @_;
    my $p = 2;
    my $q = 1;
    foreach my $digit (n_to_pythag_digits_lowtohigh($n)) {
      if ($digit == 0) {
        $p += 3*$q;    # T
        $q *= 2;
      } elsif ($digit == 1) {
        $q = $p-$q;                   # (2p, p-q)  M2
        $p *= 2;
      } else {
        ($p,$q) = (2*$p-$q, $p);      # "U" = (2p-q, p)
      }
    }
    return ($p,$q);
  }

  sub n_to_pythagstr {
    my ($n) = @_;
    if (! defined $n) { return '[undef]' }
    if ($n < 1) { return "($n)"; }
    my @digits = n_to_pythag_digits_lowtohigh($n);
    return '1.'.join('',reverse @digits);
  }

  # ($pow+1)/2 = row start
  # pow = 3^exp
  # N - rowstart + 3^exp = N - (pow+1)/2 + pow
  #                      = N - pow/2 - 1/2 + pow
  #                      = N + pow/2 - 1/2
  #                      = N + (pow-1)/2
  sub n_to_pythag_digits_lowtohigh {
    my ($n) = @_;
    my ($pow, $exp) = round_down_pow (2*$n-1, 3);
    my @digits = digit_split_lowtohigh($n + ($pow-1)/2,3);
    pop @digits;  # high 1
    return @digits;
  }
}

{
  # P,Q tables
    my $path = Math::PlanePath::PythagoreanTree->new(coordinates => 'PQ');
  foreach my $n ($path->n_start .. $path->tree_depth_to_n_end(2)) {
    my ($p,$q) = $path->n_to_xy($n);
    print "$p,";
  }
  print "\n";
  foreach my $n ($path->n_start .. $path->tree_depth_to_n_end(2)) {
    my ($p,$q) = $path->n_to_xy($n);
    print "$q,";
  }
  print "\n";
  exit 0;
}



{
  require Devel::TimeThis;
  require Math::PlanePath::FractionsTree;
  my $path = Math::PlanePath::FractionsTree->new
    (
     # tree_type => 'FB',
     # tree_type => 'UAD',
     # coordinates => 'BC',
     # coordinates => 'PQ',   # P>Q one odd other even
    );
  {
    my $t = Devel::TimeThis->new('xy_is_visited');
    foreach my $x (0 .. 200) {
      foreach my $y (0 .. 200) {
        $path->xy_is_visited($x,$y);
      }
    }
  }
  {
    my $t = Devel::TimeThis->new('xy_to_n');
    foreach my $x (0 .. 200) {
      foreach my $y (0 .. 200) {
        $path->xy_to_n($x,$y);
      }
    }
  }
  exit 0;
}

{
  # numbers in a grid

  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new
    (
     # tree_type => 'FB',
     # tree_type => 'UAD',
     # coordinates => 'AB',
     coordinates => 'MC',
    );
  my @rows;
  foreach my $n (1 .. 100000) {
    my ($orig_x,$orig_y) = $path->n_to_xy($n);
    my $x = $orig_x / 2;
    my $y = $orig_y / 4;
    next if $y > 25;
    next if $x > 80;
    print "$n      $orig_x,$orig_y\n";
    $rows[$y] ||= ' 'x80;
    substr($rows[$y],$x,length($n)) = $n;
  }
  for (my $y = $#rows; $y >= 0; $y--) {
    $rows[$y] ||= '';
    $rows[$y] =~ s/ +$//;
    print $rows[$y],"\n";
  }
  exit 0;
}

{
  # repeated "M1" as p,q matrix
  # P+(2^k-1)*Q, 2^k*Q
  # applied to P=2,Q=1
  # 2+(2^k-1) = 2^k + 1, 2^k
  require Math::Matrix;
  my $u = Math::Matrix->new ([1,1],
                             [0,2]);
  my $m = $u;
  foreach (1 .. 5) {
    print "$m\n";
    $m *= $u;
  }
  exit 0;
}



{
  # repeated "U" as p,q matrix
  require Math::Matrix;
  my $u = Math::Matrix->new ([2,-1],
                             [1,0]);
  my $m = $u;
  foreach (1 .. 5) {
    print "$m\n";
    $m *= $u;
  }
  exit 0;
}

{
  # high bit 1 in ternary
  require Math::BaseCnv;
  for (my $n = 1; $n < 65536; $n *= 2) {
    my $n3 = Math::BaseCnv::cnv($n,10,3);
    my $n2 = Math::BaseCnv::cnv($n,10,2);
    printf "$n $n2 $n3\n";
  }
  exit 0;
}

{
  # Fibonacci's method for primitive triples.
  # odd numbers 1,3,5,7,...,k being n terms n=(k+1)/2 with k square
  # sum 1+3+5+7+...+k = n^2  the gnomons around a square
  # a^2 = k                      = 2n-1
  # b^2 = sum 1+3+5+...+k-2      = (n-1)^2
  # c^2 = sum 1+3+5+...+k-2+k    = n^2
  # so a^2+b^2 = c^2
  # (n-1)^2 + 2n-1 = n^2-2n+1 + 2n-1 = n^2
  #
  # i=3
  # o=2i-1=5
  # k=o^2 = 5^2 = 25
  # n=(k+1)/2 = (25+1)/2=13
  # a=o = 5
  # b = n-1 = 12
  #
  # i=4
  # o=2i-1=7
  # k=o^2 = 7^2 = 49
  # n=(k+1)/2 = (49+1)/2=25
  # a=o = 7
  # b = n-1 = 24

  sub fibonacci_ab {
    my ($i) = @_;
    $i = 2*$i+1;   # odd integer
    my $k = $i**2; # a^2 = k = odd square
    my $n = ($k+1)/2;
    return ($i,     # a=sqrt(k)
            $n-1);  # b=n-1
  }

  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new (tree_type => 'FB');
  foreach my $i (1 .. 30) {
    my ($a,$b) = fibonacci_ab($i);
    my $c = sqrt($a*$a+$b*$b);

    # my $n = $path->tree_depth_to_n($i-1);
    # my ($pa,$pb) = $path->n_to_xy($n);
    # print "$i  $a,$b,$c   $n $pa,$pb\n";

    my $n = $path->xy_to_n($a,$b);
    my $depth = $path->tree_n_to_depth($n);
    print "$i  $a,$b,$c   $n depth=$depth\n";
  }
  exit 0;
}

{
  # P,Q by rows
  require Math::BaseCnv;
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  my $fb = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ',
                                                  tree_type => 'FB');

  my $level = 8;
  my $prev_depth = -1;
  for (my $n = $path->n_start; ; $n++) {
    my $depth = $path->tree_n_to_depth($n);
    last if $depth > 4;
    if ($depth != $prev_depth) {
      print "\n";
      $prev_depth = $depth;
    }
    my ($x,$y) = $path->n_to_xy($n);
    printf " %2d/%-2d", $x,$y;

    my ($fx,$fy) = $fb->n_to_xy($n);
    printf " %2d/%-2d", $fx,$fy;

    my $fn = $path->xy_to_n($fx,$fy);
    print "  ",n_to_treedigits_str($n);
    print "  ",n_to_treedigits_str($fn);
    print "\n";
  }
  exit 0;
}

{
  require Math::BigInt::Lite;
  my $x = Math::BigInt::Lite->new(3);
  my $y = Math::BigInt::Lite->new(4);
  Math::PlanePath::PythagoreanTree::_ab_to_pq($x,$y);
  exit 0;
}
{
  require Math::BigInt::Lite;
  my $x = Math::BigInt::Lite->new(3);
  my $low = $x & 1;
  ### $low
  exit 0;
}
{
  require Math::BigInt::Lite;
  my $x = Math::BigInt::Lite->new(3);
  my $y = Math::BigInt::Lite->new(4);
  ### $x
  ### $y
  my ($a, $b) = ($x,$y);
  ### _ab_to_pq(): "A=$a, B=$b"

  unless ($a >= 3 && $b >= 4 && ($a % 2) && !($b % 2)) {
    ### don't have A odd, B even ...
    return;
  }

  # This used to be $c=hypot($a,$b) and check $c==int($c), but libm hypot()
  # on Darwin 8.11.0 is somehow a couple of bits off being an integer, for
  # example hypot(57,176)==185 but a couple of bits out so $c!=int($c).
  # Would have thought hypot() ought to be exact on integer inputs and a
  # perfect square sum :-(.  Check for a perfect square by multiplying back
  # instead.
  #
  my $c;
  {
    my $csquared = $a*$a + $b*$b;
    $c = int(sqrt($csquared));
    ### $csquared
    ### $c
    unless ($c*$c == $csquared) {
      return;
    }
  }
  exit 0;
}

{
  require Math::BigInt::Lite;
  my $x = Math::BigInt::Lite->new(3);
  my $y = Math::BigInt::Lite->new(4);
  ### $x
  ### $y

  # my $csquared = $x*$x + $y*$y;
  # my $c = int(sqrt($csquared));
  # ### $c

  # my $mod = $x%2;
  # $mod = $y%2;
  my $eq = ($x*$x == $y*$y);
  ### $eq

  # my $x = 3;
  # my $y = 4;
  # $x = Math::BigInt::Lite->new($x);
  # $y = Math::BigInt::Lite->new($y);

  # $mod = $x%2;
  # $mod = $y%2;
  unless ($x >= 3 && $y >= 4 && ($x % 2) && !($y % 2)) {
    ### don't have A odd, B even ...
    die;
  }

  # {
  #   my $eq = ($c*$c == $csquared);
  #   ### $eq
  # }


  exit 0;
}



{
  # P,Q continued fraction quotients
  require Math::BaseCnv;
  require Math::ContinuedFraction;
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');

  my $level = 8;
  foreach my $n (1 .. 3**$level) {
    my ($x,$y) = $path->n_to_xy($n);
    my $cfrac = Math::ContinuedFraction->from_ratio($x,$y);
    my $cfrac_str = $cfrac->to_ascii;
    # my $nbits = Math::BaseCnv::cnv($n,10,3);
    my $nbits = n_to_treedigits_str($n);
    printf "%3d %7s %2d/%-2d  %s\n", $n, $nbits, $x,$y, $cfrac_str;
  }
  exit 0;

  sub n_to_treedigits_str {
    my ($n) = @_;
    return "~".join('',n_to_treedigits($n));
  }
  sub n_to_treedigits {
    my ($n) = @_;
    my ($len, $level) = round_down_pow (2*$n-1, 3);
    my @digits = digit_split_lowtohigh ($n - ($len+1)/2,  3);
    $#digits = $level-1;   # pad to $level with undefs
    foreach (@digits) { $_ ||= 0 }
    return @digits;
  }
}
{
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new (coordinates => 'PQ');
  require Math::BigInt;
  # my ($n_lo,$n_hi) = $path->rect_to_n_range (1000,0, 1500,200);
  my ($n_lo,$n_hi) = $path->rect_to_n_range (Math::BigInt->new(1000),0, 1500,200);
  ### $n_hi
  ### n_hi: "$n_hi"
  exit 0;
}

{
  require Math::PlanePath::PythagoreanTree;
#   my $path = Math::PlanePath::PythagoreanTree->new
#     (
#      # tree_type => 'FB',
#      tree_type => 'UAD',
#      coordinates => 'AB',
#     );
#   my ($x,$y) = $path->n_to_xy(1121);
# #  exit 0;
  foreach my $k (1 .. 10) {
    print 3 * 2**$k + 1,"\n";
    print 2**($k+2)+1,"\n";
  }

  sub minpos {
    my $min = $_[0];
    my $pos = 0;
    foreach my $i (1 .. $#_) {
      if ($_[$i] < $min) {
        $min = $_[$i];
        $pos = 1;
      }
    }
    return $pos;
  }

  require Math::BaseCnv;
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new
    (
     # tree_type => 'UAD',
     tree_type => 'FB',
     # coordinates => 'AB',
     coordinates => 'PQ',
    );
  my $n = 1;
  foreach my $level (1 .. 100) {
    my @x;
    my @y;
    print "level $level  base n=$n\n";
    my $base = $n;

    my ($min_x, $min_y) = $path->n_to_xy($n);
    my $min_x_n = $n;
    my $min_y_n = $n;
    foreach my $rem (0 .. 3**($level-1)-1) {
      my ($x,$y) = $path->n_to_xy($n);
      if ($x < $min_x) {
        $min_x = $x;
        $min_x_n = $n;
      }
      if ($y < $min_y) {
        $min_y = $y;
        $min_y_n = $n;
      }
      $n++;
    }
    my $min_x_rem = $min_x_n - $base;
    my $min_y_rem = $min_y_n - $base;
    my $min_x_rem_t = sprintf '%0*s', $level-1, Math::BaseCnv::cnv($min_x_rem,10,3);
    my $min_y_rem_t = sprintf '%0*s', $level-1, Math::BaseCnv::cnv($min_y_rem,10,3);
    print "  minx=$min_x at n=$min_x_n rem=$min_x_rem [$min_x_rem_t]\n";
    print "  miny=$min_y at n=$min_y_n rem=$min_y_rem [$min_y_rem_t]\n";
    local $,='..';
    print $path->rect_to_n_range(0,0, $min_x,$min_y),"\n";
  }
  exit 0;
}


{
  my $path = Math::PlanePath::PythagoreanTree->new
    (tree_type => 'UAD');
  foreach my $level (1 .. 20) {
    # my $n = 3 ** $level;
    my $n = (3 ** $level - 1) / 2;
    my ($x,$y) = $path->n_to_xy($n);
    print "$x, $y\n";
  }
  exit 0;
}

{
  # low zeros p=q+1 q=2^k
  my $p = 2;
  my $q = 1;
  ### initial
  ### $p
  ### $q

  foreach (1 .. 3) {
    ($p,$q) = (2*$p-$q, $p);
    ### $p
    ### $q
  }

  ($p,$q) = (2*$p+$q, $p);
  ### mid
  ### $p
  ### $q

  foreach (1 .. 3) {
    ($p,$q) = (2*$p-$q, $p);
    ### $p
    ### $q
  }
  exit 0;
}




{
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new;
  my (undef, $n_hi) = $path->rect_to_n_range(0,0, 1000,1000);
  ### $n_hi
  my @count;
  foreach my $n (1 .. $n_hi) {
    my ($x,$y) = $path->n_to_xy($n);
    my $z = hypot($x,$y);
    $count[$z]++;
  }
  my $total = 0;
  foreach my $i (1 .. $#count) {
    if ($count[$i]) {
      $total += $count[$i];
      my $ratio = $total/$i;
      print "$i $total   $ratio\n";
    }
  }

  exit 0;
}


{
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new;
  my $n = 1;
  foreach my $x (0 .. 10000) {
    foreach my $y (0 .. $x) {
      my $n = $path->xy_to_n($x,$y);
      next unless defined $n;
      my ($nx,$ny) = $path->n_to_xy($n);
      if ($nx != $x || $ny != $y) {
        ### $x
        ### $y
        ### $n
        ### $nx
        ### $ny
      }
    }
  }
  exit 0;
}


{
  my ($q,$p) = (21,46);
  print "$q / $p\n";
  {
    my $a = $p*$p - $q*$q;
    my $b = 2*$p*$q;
    my $c = $p*$p + $q*$q;
    print "$a $b $c\n";

    {
      require Math::BaseCnv;
      require Math::PlanePath::PythagoreanTree;
      my $path = Math::PlanePath::PythagoreanTree->new;
      my $n = 1;
      for ( ; $n < 3**11; $n++) {
        my ($x,$y) = $path->n_to_xy($n);
        if (($x == $a && $y == $b)
            || ($x == $b && $y == $a)) {
          print "n=$n\n";
          last;
        }
      }
      my $level = 1;
      $n -= 2;
      while ($n >= 3**$level) {
        $n -= 3**$level;
        $level++;
      }
      my $remt = sprintf "%0*s", $level, Math::BaseCnv::cnv($n,10,3);
      print "level $level remainder $n [$remt]\n";
    }
  }

  my $power = 1;
  my $rem = 0;
  foreach (1..8) {
    my $digit;
    if ($q & 1) {
      $p /= 2;
      if ($q > $p) {
        $q = $q - $p;
        $digit = 2;
      } else {
        $q = $p - $q;
        $digit = 1;
      }
    } else {
      $q /= 2;
      $p -= $q;
      $digit = 0;
    }
    print "$digit  $q / $p\n";
    $rem += $power * $digit;
    $power *= 3;
    last if $q == 1 && $p == 2;
  }
  print "digits $rem\n";
  exit 0;
}
{
  # my ($a, $b, $c) = (39, 80, 89);
  my ($a, $b, $c) = (36,77,85);
  if (($a ^ $c) & 1) {
    ($a,$b) = ($b,$a);
  }
  print "$a $b $c\n";

  my $p = sqrt (($a+$c)/2);
  my $q = $b/(2*$p);
  print "$p $q\n";

  $a = $p*$p - $q*$q;
  $b = 2*$p*$q;
  $c = $p*$p + $q*$q;
  print "$a $b $c\n";

  exit 0;
}



{
  require Math::Matrix;
  my $f = Math::Matrix->new ([2,0],
                             [1,1]);
  my $g = Math::Matrix->new ([-1,1],
                             [0,2]);
  my $h = Math::Matrix->new ([1,1],
                             [0,2]);
  my $fi = $f->invert;
  print $fi,"\n";
  my $gi = $g->invert;
  print $gi,"\n";
  my $hi = $h->invert;
  print $hi,"\n";
  exit 0;
}

{
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new;
  my $n = 1;
  foreach my $i (1 .. 100) {
    my ($x,$y) = $path->n_to_xy($n);
    # print 2**($i),"\n";
    # print 2*2**$i*(2**$i-1),"\n";
    my $z = hypot($x,$y);
    printf "%3d  %4d,%4d,%4d\n", $n, $x, $y, $z;
    $n += 3**$i;
  }
  exit 0;
}

{
  sub round_down_pow_3 {
    my ($n) = @_;
    my $p = 3 ** (int(log($n)/log(3)));
    return (3*$p <= $n ? 3*$p
            : $p > $n ? $p/3
            : $p);
  }

  require Math::BaseCnv;

  # base = (range-1)/2
  # range = 2*base + 1
  #
  # newbase = ((2b+1)/3 - 1) / 2
  #         = (2b+1-3)/3 / 2
  #         = (2b-2)/2/3
  #         = (b-1)/3
  #
  # deltarem = b-(b-1)/3
  #          = (3b-b+1)/3
  #          = (2b+1)/3
  #

  foreach my $n (1 .. 32) {
    my $h = 2*($n-1)+1;
    my $level = int(log($h)/log(3));
    $level--;
    my $range = 3**$level;
    my $base = ($range - 1)/2 + 1;
    my $rem = $n - $base;

    if ($rem < 0) {
      $rem += $range/3;
      $level--;
      $range /= 3;
    }
    if ($rem >= $range) {
      $rem -= $range;
      $level++;
      $range *= 3;
    }

    my $remt = Math::BaseCnv::cnv($rem,10,3);
    $remt = sprintf ("%0*s", $level, $remt);
    print "$n $h $level  $range base=$base $rem $remt\n";
  }
  exit 0;
}

{
  my $sum = 0;
  foreach my $k (0 .. 10) {
    $sum += 3**$k;
    my $f = (3**($k+1) - 1) / 2;
    print "$k $sum $f\n";
  }
  exit 0;
}


{
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new;
  my $x_limit = 500;
  my @max_n;
  foreach my $n (0 .. 500000) {
    my ($x,$y) = $path->n_to_xy($n);
    if ($x <= $x_limit) {
      $max_n[$x] = max($max_n[$x] || $n, $n);
    }
  }
  foreach my $x (0 .. $x_limit) {
    if ($max_n[$x]) {
      print "$x   $max_n[$x]\n";
    }
  }
  exit 0;
}
{
  require Math::PlanePath::PythagoreanTree;
  my $path = Math::PlanePath::PythagoreanTree->new;
  my $x_limit = 500;
  my @max_n;
  foreach my $n (0 .. 500000) {
    my ($x,$y) = $path->n_to_xy($n);
    if ($x <= $x_limit) {
      $max_n[$x] = max($max_n[$x] || $n, $n);
    }
  }
  foreach my $x (0 .. $x_limit) {
    if ($max_n[$x]) {
      print "$x   $max_n[$x]\n";
    }
  }
  exit 0;
}



{
  require Math::Matrix;
  my $u = Math::Matrix->new ([1,2,2],
                             [-2,-1,-2],
                             [2,2,3]);
  my $a = Math::Matrix->new ([1,2,2],
                             [2,1,2],
                             [2,2,3]);
  my $d = Math::Matrix->new ([-1,-2,-2],
                             [2,1,2],
                             [2,2,3]);
  my $ui = $u->invert;
  print $ui;
  exit 0;
}

{
  my (@x) = 3;
  my (@y) = 4;
  my (@z) = 5;

  for (1..3) {
    for my $i (0 .. $#x) {
      print "$x[$i], $y[$i], $z[$i]    ",sqrt($x[$i]**2+$y[$i]**2),"\n";
    }
    print "\n";

    my @new_x;
    my @new_y;
    my @new_z;
    for my $i (0 .. $#x) {
      my $x = $x[$i];
      my $y = $y[$i];
      my $z = $z[$i];
      push @new_x,   $x - 2*$y + 2*$z;
      push @new_y, 2*$x -   $y + 2*$z;
      push @new_z, 2*$x - 2*$y + 3*$z;

      push @new_x,   $x + 2*$y + 2*$z;
      push @new_y, 2*$x +   $y + 2*$z;
      push @new_z, 2*$x + 2*$y + 3*$z;

      push @new_x,  - $x + 2*$y + 2*$z;
      push @new_y, -2*$x +   $y + 2*$z;
      push @new_z, -2*$x + 2*$y + 3*$z;
    }
    @x = @new_x;
    @y = @new_y;
    @z = @new_z;
  }
  exit 0;
}
