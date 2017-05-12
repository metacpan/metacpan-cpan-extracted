#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2014, 2015 Kevin Ryde

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
use List::Util 'min','max';
use Math::PlanePath::HilbertCurve;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh';

use Smart::Comments;

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
  # HilbertSides number of overlaps

  # singles 0,3,13,53,209,829,3297,13149,52513
  #
  # doubles 0,0,1,5,23,97,399,1617,6511
  # A109765  gf x/( (1-4*x)*(1-2*x)*(1+x) )

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
  # HilbertSides axis N

  my @table = ([ 0,1,9,9, 9,9,9,9, 9,9,9,9, 9,9,2,0 ],
               [ 1,9,9,2, 0,1,9,9, 9,9,9,9, 9,9,9,9 ],
               [ 9,9,9,9, 9,9,9,9, 9,9,2,0, 1,9,9,2 ]);
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
  
  # Straight
  # 0,1,0, 0,0,1,0, 1,0,1,0,0,0,1,0, 0,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,
  # vector(25,n,valuation(n,2)%2)  /* even,odd trailing 0 bits */

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
  # HilbertSides X+Y = HilbertCurve X+Y

  #   3 |  5----6---7,9--10---11
  #     |  |         |         |
  #   2 |  4----3    8   13---12        24---23
  #     |       |         |                   |
  #   1 |       2        14   17---18---19   22
  #     |       |         |    |         |    |
  # Y=0 |  0----1        15---16        20---21

  #   3 |  5----6    9---10
  #     |  |    |    |    |
  #   2 |  4    7----8   11             24
  #     |  |              |              |
  #   1 |  3----2   13---12   17---18   23---22
  #     |       |    |         |    |         |
  # Y=0 |  0----1   14---15---16   19---20---21
  #     +----------------------------------


  require Math::PlanePath::HilbertSides;
  my $curve = Math::PlanePath::HilbertCurve->new;
  my $sides = Math::PlanePath::HilbertSides->new;
  foreach my $n (0 .. 10000) {
    my ($cx,$cy) = $curve->n_to_xy($n);
    my ($sx,$sy) = $sides->n_to_xy($n);
    my $cdiff = $cx-$cy;
    my $sdiff = $sx-$sy;
    $cdiff == $sdiff or die;
  }
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
{
  require Math::NumSeq::PlanePathCoord;
  require Math::PlanePath::AR2W2Curve;
  foreach my $start_shape (@{Math::PlanePath::AR2W2Curve
      ->parameter_info_hash->{'start_shape'}->{'choices'}}) {

    my $hseq = Math::NumSeq::PlanePathCoord->new (planepath => 'HilbertCurve',
                                                  coordinate_type => 'RSquared');
    my $aseq = Math::NumSeq::PlanePathCoord->new
      (planepath => "AR2W2Curve,start_shape=$start_shape",
       coordinate_type => 'RSquared');
    foreach my $i ($hseq->i_start .. 10000) {
      if ($hseq->ith($i) != $aseq->ith($i)) {
        print "$start_shape different at $i\n";
        last;
      }
    }
  }
  exit 0;
}

{
  require Math::PlanePath::ZOrderCurve;
  my $hilbert  = Math::PlanePath::HilbertCurve->new;
  my $zorder   = Math::PlanePath::ZOrderCurve->new;
  sub zorder_perm {
    my ($n) = @_;
    my ($x, $y) = $zorder->n_to_xy ($n);
    return $hilbert->xy_to_n ($x, $y);
  }
  sub cycle_length {
    my ($n) = @_;
    my %seen;
    my $count = 1;
    my $p = $n;
    for (;;) {
      $p = zorder_perm($p);
      if ($p == $n) {
        last;
      }
      $count++;
    }
    return $count;
  }
  foreach my $n (0 .. 128) {
    my $perm = zorder_perm($n);
    my $len = cycle_length($n);
    print "$n $perm   $len\n";
  }
  exit 0;
}



{
  require Math::BaseCnv;
  require Math::NumSeq::PlanePathDelta;
  my $seq = Math::NumSeq::PlanePathDelta->new (delta_type => 'Dir4',
                                               planepath => 'HilbertCurve');
  foreach my $n (0 .. 256) {
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    my $want = $seq->ith($n);
    my $got = dir_try($n);
    my $str = ($want == $got ? '' : '   ***');
    printf "%2d %3s  %d %d%s\n", $n, $n4, $want, $got, $str;
  }
  exit 0;


# my @next_state = (4,0,0,12, 0,4,4,8, 12,8,8,4, 8,12,12,0);
# my @digit_to_x = (0,1,1,0, 0,0,1,1, 1,0,0,1, 1,1,0,0);
# my @digit_to_y = (0,0,1,1, 0,1,1,0, 1,1,0,0, 1,0,0,1);

#     dx  dy  dir
# 0   +1   0   0,1,2     4,0,0,12    0=XYswap dir^1   3 y=-x  dir^3  low^1 or ^3
# 4    0  +1   1,0,3     0,4,4,8                      3 x=-y
# 8   -1   0   2,3,0    12,8,8,4,
# 12   0  -1   3,2,1    8,12,12,0    0=XYswap dir^1

#  [012]3333
#  [123]0000

# p = count 3s   0 if dx+dy=-1 so dx=-1 or dy=-1 SW,  1 if dx+dy=1 NE
# m = count 3s in -n    0 if dx-dy=-1 NW, 1 if dx-dy=1 SE
# 1023200 neg = 2310133+1 = 2310200  count 0s except trailing 0s


  sub dir_try {
    my ($n) = @_;
    ### dir_try(): $n



    # p = count 3s   0 if dx+dy=-1 so dx=-1 or dy=-1 SW,  1 if dx+dy=1 NE
    # m = count 3s in -n    0 if dx-dy=-1 NW, 1 if dx-dy=1 SE
    # 1023200 neg = 2310133+1 = 2310200  count 0s except trailing 0s

    $n++;
    my $p = count_3s($n) & 1;
    my $m = count_3s((-$n) & 0xFF) & 1;
    ### n  : sprintf "%8b", $n
    ### neg: sprintf "%8b", (-$n) & 0xFF
    ### $p
    ### $m
    if ($p == 0) {
      if ($m == 0) {
        return 0; # E
      } else {
        return 1; # S
      }
    } else {
      if ($m == 0) {
        return 3; # N
      } else {
        return 2; # W
      }
    }



    # my $state = 0;
    # my @digits = digits($n);
    # if (@digits & 1) {
    #   #      $state ^= 1;
    # }
    # # unshift @digits, 0;
    # ### @digits
    #
    # my $flip = 0;
    # my $dir = 0;
    # for (;;) {
    #   if (! @digits) {
    #     return $flip;
    #   }
    #   $dir = pop @digits;
    #   if ($dir == 3) {
    #     $flip ^= 1;
    #   } else {
    #     last;
    #   }
    # }
    # if ($flip) {
    #   $dir = 1-$dir;
    # }
    #
    # while (@digits) {
    #   my $digit = pop @digits;
    #   ### at: "state=$state  digit=$digit  dir=$dir"
    #
    #   if ($digit == 0) {
    #   }
    #   if ($digit == 1) {
    #     $dir = 1-$dir;
    #   }
    #   if ($digit == 2) {
    #     $dir = 1-$dir;
    #   }
    #   if ($digit == 3) {
    #     $dir = $dir+2;
    #   }
    # }
    #
    # ### $dir
    # return $dir % 4;





    # works ...
    #
    # while (@digits && $digits[-1] == 3) {
    #   $state ^= 1;
    #   pop @digits;
    # }
    # # if (@digits) {
    # #   push @digits, $digits[-1];
    # # }
    #
    # while (@digits > 1) {
    #   my $digit = shift @digits;
    #   ### at: "state=$state  digit=$digit  dir=$dir"
    #
    #   if ($digit == 0) {
    #   }
    #   if ($digit == 1) {
    #     $state ^= 1;
    #   }
    #   if ($digit == 2) {
    #     $state ^= 1;
    #   }
    #   if ($digit == 3) {
    #     $state ^= 2;
    #   }
    # }
    #
    # ### $state
    # ### $digit
    # my $dir = $digits[0] // return $state^1;
    # if ($state & 1) {
    #   $dir = 1-$dir;
    # }
    # if ($state & 2) {
    #   $dir = $dir+2;
    # }
    # ### $dir
    #
    #
    # ### $dir
    # return $dir % 4;






    # my $digit = $digits[-1];
    # if ($digit == 0) {
    #   $dir = 0;
    # }
    # if ($digit == 1) {
    #   $dir = 2;
    # }
    # if ($digit == 2) {
    #   $dir = 1;
    # }
    # if ($digit == 3) {
    #   $dir = 1;
    # }
    # if (@digits & 1) {
    #   $dir = 1-$dir;
    # }
    # my $ret = $dir;
    #
    # while (@digits) {
    #   my $digit = shift @digits;
    #   if ($digit == 0) {
    #     $dir = 1-$dir;
    #     $ret = $dir;
    #   }
    #   if ($digit == 1) {
    #     $ret = $dir;
    #   }
    #   if ($digit == 2) {
    #     $ret = $dir;
    #   }
    #   if ($digit == 3) {
    #     $dir = $dir + 2;
    #   }
    # }
    # return $ret % 4;


    # $ret = 0;
    # while (($n & 3) == 3) {
    #   $n >>= 2;
    #   $ret ^= 1;
    # }
    #
    # my $digit = ($n & 3);
    # $n >>= 2;
    # if ($digit == 0) {
    # }
    # if ($digit == 1) {
    #   $ret++;
    # }
    # if ($digit == 2) {
    #   $ret += 2;
    # }
    # if ($digit == 3) {
    # }
    #
    # while ($n) {
    #   my $digit = ($n & 3);
    #   $n >>= 2;
    #
    #   if ($digit == 0) {
    #     $ret = 1-$ret;
    #   }
    #   if ($digit == 1) {
    #     $ret = -$ret;
    #     #        $ret = 1-$ret;
    #   }
    #   if ($digit == 2) {
    #     $ret = 1-$ret;
    #   }
    #   if ($digit == 3) {
    #     $ret = $ret + 2;
    #   }
    # }
    # return $ret % 4;
    #
    #
    #
    # if (($n & 3) == 3) {
    #   while (($n & 15) == 15) {
    #     $n >>= 4;
    #   }
    #   if (($n & 3) == 3) {
    #     $ret = 1;
    #   }
    #   $n >>= 2;
    # } elsif (($n & 3) == 1) {
    #   $ret = 0;
    #   $n >>= 2;
    # } elsif (($n & 3) == 2) {
    #   $ret = 2;
    #   $n >>= 2;
    # }
    #
    # while ($n) {
    #   if (($n & 3) == 0) {
    #     $ret ^= 1;
    #   }
    #   if (($n & 3) == 3) {
    #     $ret ^= 2;
    #   }
    #   $n >>= 2;
    # }
    # return $ret;
  }

  sub digits {
    my ($n) = @_;
    my @ret;
    while ($n) {
      unshift @ret, $n & 3;
      $n >>= 2;
    } ;  #  || @ret&1
    return @ret;
  }

  sub count_3s {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += (($n & 3) == 3);
      $n >>= 2;
      $count += (($n & 3) == 3);
      $n >>= 2;
    }
    return $count;
  }
}


{
  my $path = Math::PlanePath::HilbertCurve->new;
  my @range = $path->rect_to_n_range (1,2, 2,4);
  ### @range
  exit 0;
}

{
  my $path = Math::PlanePath::HilbertCurve->new;

  sub want {
    my ($n) = @_;
    my ($x1,$y1) = $path->n_to_xy($n);
    my ($x2,$y2) = $path->n_to_xy($n+1);
    return ($x2-$x1, $y2-$y1);
  }

  sub try {
    my ($n) = @_;
    ### try(): $n

    while (($n & 15) == 15) {
      $n >>= 4;
    }

    my $pos = 0;
    my $mask = 16;
    while ($n >= $mask) {
      $pos += 4;
      $mask <<= 4;
    }
    ### $pos

    my $dx = 1;
    my $dy = 0;
    ### d initial: "$dx,$dy"

    while ($pos >= 0) {
      my $bits = ($n >> $pos) & 15;
      ### $bits

      if ($bits == 1
          || $bits == 2
          || $bits == 3
          || $bits == 4
          || $bits == 8
         ) {
        ($dx,$dy) = ($dy,$dx);
        ### d swap to: "$dx,$dy"

      } elsif ($bits == 2
               || $bits == 12
              ) {
        $dx = -$dx;
        $dy = -$dy;
        ### d invert: "$dx,$dy"

      } elsif ($bits == 2
               || $bits == 10
               || $bits == 11
               || $bits == 13
              ) {
        ($dx,$dy) = ($dy,$dx);
        $dx = -$dx;
        $dy = -$dy;
        ### d swap and invert: "$dx,$dy"

      } elsif ($bits == 0
               || $bits == 5
              ) {
        ### d unchanged

      }

      $pos -= 4;
    }

    return ($dx,$dy);
  }

  sub Wtry {
    my ($n) = @_;
    ### try(): $n

    my $pos = 0;
    my $mask = 16;
    while ($n >= $mask) {
      $pos += 4;
      $mask <<= 4;
    }
    ### $pos

    my $dx = 1;
    my $dy = 0;
    ### d initial: "$dx,$dy"

    while ($pos >= 0) {
      my $bits = ($n >> $pos) & 15;
      ### $bits

      if ($bits == 1
          || $bits == 3
          || $bits == 4
          || $bits == 8
         ) {
        ($dx,$dy) = ($dy,$dx);
        ### d swap to: "$dx,$dy"

      } elsif ($bits == 2
               || $bits == 12
              ) {
        $dx = -$dx;
        $dy = -$dy;
        ### d invert: "$dx,$dy"

      } elsif ($bits == 2
               || $bits == 6
               || $bits == 10
               || $bits == 11
               || $bits == 13
              ) {
        ($dx,$dy) = ($dy,$dx);
        $dx = -$dx;
        $dy = -$dy;
        ### d swap and invert: "$dx,$dy"

      } elsif ($bits == 0
               || $bits == 5
              ) {
        ### d unchanged

      }

      $pos -= 4;
    }

    return ($dx,$dy);
  }

  sub ZZtry {
    my ($n) = @_;
    my $dx = 0;
    my $dy = 1;
    do {
      my $bits = $n & 3;

      if ($bits == 0) {
        ($dx,$dy) = ($dy,$dx);
        ### d swap: "$dx,$dy"
      } elsif ($bits == 1) {
        # ($dx,$dy) = ($dy,$dx);
        # ### d swap: "$dx,$dy"
      } elsif ($bits == 2) {
        ($dx,$dy) = ($dy,$dx);
        ### d swap: "$dx,$dy"
        $dx = -$dx;
        $dy = -$dy;
        ### d invert: "$dx,$dy"
      } elsif ($bits == 3) {
        ### d unchanged
      }

      my $prevbits = $bits;
      $n >>= 2;
      return ($dx,$dy) if ! $n;
      $bits = $n & 3;

      if ($bits == 0) {
        ### d unchanged
      } elsif ($bits == 1) {
        ($dx,$dy) = ($dy,$dx);
        ### d swap: "$dx,$dy"
      } elsif ($bits == 2) {
        if ($prevbits >= 2) {
        }
        # $dx = -$dx;
        # $dy = -$dy;
        ($dx,$dy) = ($dy,$dx);
        ### d swap: "$dx,$dy"
      } elsif ($bits == 3) {
        ($dx,$dy) = ($dy,$dx);
        ### d invert and swap: "$dx,$dy"
      }
      $n >>= 2;
    } while ($n);
    return ($dx,$dy);
  }

  my @n_to_next_i = (4,   0,  0,  8,  # i=0
                     0,   4,  4, 12,  # i=4
                     12,  8,  8,  0,  # i=8
                     8,  12, 12,  4,  # i=12
                    );
  my @n_to_x = (0, 1, 1, 0,   # i=0
                0, 0, 1, 1,   # i=4
                1, 1, 0, 0,   # i=8
                1, 0, 0, 1,   # i=12
               );
  my @n_to_y = (0, 0, 1, 1,   # i=0
                0, 1, 1, 0,   # i=4
                1, 0, 0, 1,   # i=8
                1, 1, 0, 0,   # i=12
               );

  my @i_to_dx = (1, 0, -1, 3, 0, 1,  0, 7,-1, 1, 10, 0,-1, 0,1,15);
  my @i_to_dy = (0, 1,  0, 3, 1, 0, -1, 7, 0, 0, 10, 1, 0,-1,0,15);

  # unswapped
  # my @i_to_dx = (1, 0, -1, 3, 0, 1,  0, 7,-1, 1, 10, 0,-1, 0,1,15);
  # my @i_to_dy = (0, 1,  0, 3, 1, 0, -1, 7, 0, 0, 10, 1, 0,-1,0,15);
  # my @i_to_dx = (0 .. 15);
  # my @i_to_dy = (0 .. 15);
  sub Xtry {
    my ($n) = @_;
    ### HilbertCurve n_to_xy(): $n
    ### hex: sprintf "%#X", $n
    return if $n < 0;

    my $x = my $y = ($n * 0); # inherit
    my $pos = 0;
    {
      my $pow = $x + 4;        # inherit
      while ($n >= $pow) {
        $pow <<= 2;
        $pos += 2;
      }
    }
    ### $pos

    my $dx = 9;
    my $dy = 9;
    my $i = ($pos & 2) << 1;
    my $t;
    while ($pos >= 0) {
      my $nbits = (($n >> $pos) & 3);
      $t = $i + $nbits;
      $x = ($x << 1) | $n_to_x[$t];
      $y = ($y << 1) | $n_to_y[$t];
      ### $pos
      ### $i
      ### bits: ($n >> $pos) & 3
      ### $t
      ### n_to_x: $n_to_x[$t]
      ### n_to_y: $n_to_y[$t]
      ### next_i: $n_to_next_i[$t]
      ### x: sprintf "%#X", $x
      ### y: sprintf "%#X", $y
      # if ($nbits == 0) {
      # } els
      if ($nbits == 3) {
        if ($pos & 2) {
          ($dx,$dy) = ($dy,$dx);
        }
      } else {
        ($dx,$dy) = ($i_to_dx[$t], $i_to_dy[$t]);
      }
      $i = $n_to_next_i[$t];
      $pos -= 2;
    }

    print "final i $i\n";
    return ($dx,$dy);
  }

  sub base4 {
    my ($n) = @_;
    my $ret = '';
    do {
      $ret .= ($n & 3);
    } while ($n >>= 2);
    return reverse $ret;
  }

  foreach my $n (0 .. 256) {
    my $n4 = base4($n);
    my ($wdx,$wdy) = want($n);
    my ($tdx,$tdy) = try($n);
    my $diff = ($wdx!=$tdx || $wdy!=$tdy ? " ***" : "");
    print "$n $n4  $wdx,$wdy  $tdx,$tdy $diff\n";
  }
  exit 0;



  # p=dx+dy    +/-1
  # m=dx-dy    +/-1
  #
  # p = count 3s in N, odd/even
  # m = count 3s in -N, odd/even
  #
  # p==m is dx
  # p!=m then p is dy
}
