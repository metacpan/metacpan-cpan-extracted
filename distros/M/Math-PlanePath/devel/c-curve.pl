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
use List::Util 'min','max','sum';
use Scalar::Util 'blessed';
use Math::BaseCnv;
use List::Pairwise;
use lib 'xt';
use Math::PlanePath::Base::Digits
  'digit_join_lowtohigh';
use Math::BigInt try => 'GMP';
use Math::BigRat;
use Math::Geometry::Planar ();
use Module::Load;
use POSIX 'ceil';

use MyOEIS;
use Math::PlanePath::CCurve;
my $path = Math::PlanePath::CCurve->new;
*_divrem = \&Math::PlanePath::_divrem;
our $seg_len;

# uncomment this to run the ### lines
# use Smart::Comments;



# The total points along the horizontal, including the endpoints, is
#
#     H[k] = a[k] + 1 + e[k] + 1 + a[k]
#          = 2*d[k-3] + 2*d[k-7] + 2

# The pairs of terms are the Jocobsthal sequence
#
#     j[k+1] = j[k] + d[k-1] + j[k-2] + 2*j[k-3]



{
  # right boundary N

  my $path = Math::PlanePath::CCurve->new;
  my %non_values;
  my %n_values;
  my @n_values;
  my @values;
  foreach my $k (8) {
    print "k=$k\n";
    my $n_limit = 2**$k;
    foreach my $n (0 .. $n_limit-1) {
      $non_values{$n} = 1;
    }
    my $points = MyOEIS::path_boundary_points ($path, $n_limit,
                                               side => 'right');
    for (my $i = 0; $i+1 <= $#$points; $i++) {
      my ($x,$y) = @{$points->[$i]};
      my ($x2,$y2) = @{$points->[$i+1]};
      # my @n_list = $path->xy_to_n_list($x,$y);
      my @n_list = path_xyxy_to_n($path, $x,$y, $x2,$y2);
      foreach my $n (@n_list) {
        delete $non_values{$n};
        if ($n <= $n_limit) { $n_values{$n} = 1; }
        my $n2 = Math::BaseCnv::cnv($n,10,2);
        my $pred = 1; # $path->_UNDOCUMENTED__n_segment_is_right_boundary($n);
        my $diff = $pred ? '' : '  ***';
        if ($k <= 8) { printf "%3d  %*s%s\n", $n, $k, $n2, $diff; }
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

    # if ($k <= 4) {
    #   foreach my $n (@non_values) {
    #     my $pred = $path->_UNDOCUMENTED__n_segment_is_right_boundary($n);
    #     my $diff = $pred ? '  ***' : '';
    #     my $n2 = Math::BaseCnv::cnv($n,10,3);
    #     print "non $n  $n2$diff\n";
    #   }
    # }
    # @values = @non_values;

    # print "func ";
    # foreach my $i (0 .. $count-1) {
    #   my $n = $path->_UNDOCUMENTED__right_boundary_i_to_n($i);
    #   my $n2 = Math::BaseCnv::cnv($n,10,3);
    #   print "$n2,";
    # }
    # print "\n";

    print "vals ";
    foreach my $i (0 .. $count-1) {
      my $n = $values[$i];
      my $n2 = Math::BaseCnv::cnv($n,10,2);
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

=head2 Two Curves

Two curves can be placed back-to-back, as if starting from a line segment
traversed in both directions.

                     <---------         back-to-back
                     --------->          lines

For example to N=16,

           11-----10-----9,7-----6------5     k=4       3
            |             |             |
    13-----12             8             4------3        2
     |                                         |
    14                                         2        1
     |                                         |
    15-----16                           0------1   <- Y=0
     1------0                           16----15   <- Y=0
     |                                         |
     2                                        14       -1
     |                                         |
     3------4             8            12-----13       -2
            |             |             |
            5------6-----7,9----10-----11              -3

The boundary and area of this shape are

    Btwo[k] = /  2                        if k=0
              |  8*2^h - 8                if k even >= 2
              \ 12*2^h - 8                if k odd
            = 2, 4, 8, 16, 24, 40, 56, 88, 120, 184, 248, 376, 504, 760, 1016, 1528, 2040, ...

    Atwo[k] = / 0                         if k=0
              | (7/2)*2^k -  7*2^h + 4    if k even >= 2
              \ (7/2)*2^k - 10*2^h + 4    if k odd
            = 0, 1, 4, 12, 32, 76, 172, 372, 788, 1636, 3364, 6852, 13892, 28036, 56452, 113412, 227588

=for Test-Pari-DEFINE  S(h) = 2^h

=for Test-Pari-DEFINE  Z(h) = 2*2^h-2

=for Test-Pari-DEFINE  Btwo_samples = [ 2, 4, 8, 16, 24, 40, 56, 88, 120, 184, 248, 376, 504, 760, 1016, 1528, 2040 ]

=for Test-Pari-DEFINE  Btwo(k) = my(h=floor(k/2)); if(k==0, 2, if(k%2, 12*2^h-8, 8*2^h-8))

=for Test-Pari-DEFINE  Btwo_from_SZ(k) = my(h=floor(k/2)); if(k==0, 2, if(k%2, 4*S(h)+4*Z(h), 4*S(h)+4*Z(h-1)))

=for GP-Test  vector(length(Btwo_samples), k, Btwo(k-1)) == Btwo_samples

=for GP-Test  vector(50, k, Btwo(k-1)) == vector(50, k, Btwo_from_SZ(k-1))

The straight and zigzag parts are the two middle sides of the right and
convex hull shapes shown above.  So the boundary

    Btwo[k] = 4*S[h] + 4*Z[h-1]                for k even >= 2
            = 4*(2^h) + 4*(2*2^(h-1) - 2)
            = 8*2^h - 8

    Btwo[k] = 4*S[h] + 4*Z[h]                  for k odd
            = 4*(2^h) + 4*(2*2^h - 2)
            = 12*2^h - 8

The area can be calculated from the enclosing square S[h]+Z[h-1] from which
subtract the four zigzag triangles at the corners.

    Atwo[k] = 4*(S[h]+Z[h-1])^2 + 4*Z[h-1]/2*(Z[h-1]/2 + 1)/2
     for k even >= 2

    Atwo[k] = 4*(S[h]+Z[h])^2   + 4*Z[h]/2  *(Z[h]/2   + 1)/2
     for k odd

=for Test-Pari-DEFINE  Atwo_samples = [ 0, 1, 4, 12, 32, 76, 172, 372, 788, 1636, 3364, 6852, 13892, 28036, 56452, 113412, 227588 ]

=for Test-Pari-DEFINE  Atwo(k) = my(h=floor(k/2)); if(k==0, 0, if(k%2, (7/2)*2^k - 10*2^h + 4, (7/2)*2^k - 7*2^h + 4))

=for Test-Pari-DEFINE  Atwo_from_SZ_even(h) = (S(h)+Z(h-1))^2 - 4*Z(h-1)/2*(Z(h-1)/2 + 1)/2

=for Test-Pari-DEFINE  Atwo_from_SZ_odd(h) = (S(h)+Z(h))^2 - 4*Z(h)/2*(Z(h)/2 + 1)/2

=for Test-Pari-DEFINE  Atwo_from_SZ(k) = my(h=floor(k/2)); if(k==0, 0, if(k%2, Atwo_from_SZ_odd(h), Atwo_from_SZ_even(h)))

=for GP-Test  vector(length(Atwo_samples), k, Atwo(k-1)) == Atwo_samples

=for GP-Test  vector(50, k, Atwo(k-1)) == vector(50, k, Atwo_from_SZ(k-1))

=cut

# area
# = (2^h + 2*2^(h-1)-2)^2 - 4*(2*2^(h-1) - 2)/2*((2*2^(h-1) - 2)/2 + 1)/2
# = (2^h + 2^h-2)^2 - 4*(2^h - 2)/2*((2^h - 2)/2 + 1)/2
# = (x + x-2)^2 - 4*(x - 2)/2*((x - 2)/2 + 1)/2
# = 7/2*x^2 - 7*x + 4
# = (7/2)*2^k - 7*2^h + 4
# odd
# = (2^h + 2*2^h-2)^2 - 4*(2*2^h - 2)/2*((2*2^h - 2)/2 + 1)/2
# = (x + 2*x-2)^2 - 4*(2*x - 2)/2*((2*x - 2)/2 + 1)/2
# = 7*x^2 - 10*x + 4
# = (7/2)*2^k - 10*2^h + 4

  # 2 back-to-back boundary     N=0 to 2^k each
  #
  # h=0 n=4^h=1  boundary=2
  # h=2 n=4^h=16 boundary=6*4=24  area=36-4=32

  #              2^h/4        zig (2^h/4 - 2)*2
  #        *--------------*
  #        |              |
  #     *--*              *--*
  #     |                    |  side 2^h/4 same by symmetry
  #     +                    +
  #
  # total
  #
  # A159741 8*(2^n-1)      whole
  # A028399 2^n - 4        half  cf A173033
  # A000918 2^n - 2        quarter

  #        7------6------5     k=3       3     straight
  #        |             |                     = 2^h
  # 7-----8,8            4------3        2
  # |                           |              zig
  # 6                           2        1     = 2*2^h-2
  # |                           |
  # 5------4            0,0-----1   <- Y=0
  #        |             |
  #        3------2------1
  # h=0 n=2*4^h=2   boundary=4
  # h=1 n=2*4^h=8   boundary=16   area=12
  # h=2 n=2*4^h=32  boundary=40
  # h=3 n=2*4^h=128 boundary=88
  # total 4*(2^h) + 4*(2*2^h - 2)
  #     = 3*2^h-8
  # A182461             whole except 4    a(n) = a(n-1)*2+8 16,40,88,
  # A131128 3*2^n - 4   half
  # A033484 3*2^n - 2   quarter
  # A153893 3*2^n - 1   eighth  h>=1

  require MyOEIS;
  my @values;
  foreach my $k (0 .. 16) {
    my $n_end = 2**$k;
    my $h = int($k/2);
    my ($n1, $n2) = ($k % 2 ? diagonal_4k_axis_n_ends($h) : width_4k_axis_n_ends($h));
    my ($x1,$y1) = $path->n_to_xy ($n1);
    my ($x2,$y2) = $path->n_to_xy ($n2);
    my $points = MyOEIS::path_boundary_points_ft($path, $n_end,
                                                 $x1,$y1, $x2,$y2,
                                                 side => 'right',
                                                 dir => $h,
                                                );
    if (@$points < 30) {
      print "k=$k from N=$n1 $x1,$y1 to N=$n2 $x2,$y2\n";
      print "  ",points_str($points),"\n";
    }
    my $boundary = 2 * (scalar(@$points) - 1);

    my $area;
    if (@$points > 2) {
      my $planar = Math::Geometry::Planar->new;
      $planar->points($points);
      $area = 2 * $planar->area;
    } else {
      $area = 0;
    }

    # push @values, $boundary;
    push @values, $area;
    print "$h B=$boundary A=$area   n=$n1 xy=$x1,$y1 to n=$n2 xy=$x2,$y2  limit $n_end\n";
  }
  print join(',',@values),"\n";
  shift @values;
  shift @values;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub points_str {
    my ($points) = @_;
    ### points_str(): $points
    my $count = scalar(@$points);
    return  "count=$count  ".join(' ',map{join(',',@$_)}@$points)
  }
}

{
  my @sdir = (2,2,0,-2, -2,-2,0,2);
  sub s0_by_formula {
    my ($k) = @_;
    {
      my $h = int($k/2);
      return 2**$k/4 + $sdir[$k%8]*2**$h/4;
    }
    {
      # (1/4)*(2^k +   (1-I)^k +   (1+I)^k))
      require Math::Complex;
      return (2**$k / 2
              + (Math::Complex->new(1,-1)**$k * Math::Complex->new(1,-1)
                 + Math::Complex->new(1,1) **$k * Math::Complex->new(1,1)) / 4);
    }
  }
  my @s1dir = (0,2,2,2, 0,-2,-2,-2);
  sub s1_by_formula {
    my ($k) = @_;
    my $h = int($k/2);
    return 2**$k/4 + $sdir[($k-2)%8]*2**$h/4;
  }
  my @s2dir = (0,2,2,2, 0,-2,-2,-2);
  sub s2_by_formula {
    my ($k) = @_;
    my $h = int($k/2);
    return 2**$k/4 + $sdir[($k-4)%8]*2**$h/4;
  }
  sub s3_by_formula {
    my ($k) = @_;
    my $h = int($k/2);
    return 2**$k/4 + $sdir[($k-6)%8]*2**$h/4;
  }
#  print "  1,  1,  1,  1,  2,  6, 16, 36, 72,136,256,496,992,2016,4096,8256,16512,32896,65536,\n";  # M0
#  print "  0,  1,  2,  3,  4,  6, 12, 28, 64,136,272,528,1024,2016,4032,8128,16384,32896,65792,\n"; # M1
#  print "  0,  0,  1,  3,  6, 10, 16, 28, 56,120,256,528,1056,2080,4096,8128,16256,32640,65536,\n"; # M2
  print "  0,  0,  0,  1,  4, 10, 20, 36, 64,120,240,496,1024,2080,4160,8256,16384,32640,65280,\n"; # M3
  foreach my $k (0 .. 17) {
    printf "%3d,", s3_by_formula($k);
  }
  exit 0;
}










{
  # triangle area parts by individual recurrence
  # e[k+8] = e[k+7] + 2*e[k+6] - e[k+4] + e[k+3] + 2*e[k+1] + 4*e[k]
  # 1,0,0,0,0,0,0,2,6,10,22,40,80,156,308,622,1242,2494,4994,9988,19988,39952,79904,159786

  my @e = (1,0,0,0,0,0,0,2);
  foreach my $k (0 .. 15) {
    push @e, $e[-1] + 2*$e[-2] - $e[-4] + $e[-5] + 2*$e[-7] + 4*$e[-8];
  }
  print join(",",@e),"\n";
  exit 0;
}
{
  # area parts by a-z recurrence
  #
  # a 0,0,0,2,4,8,16,30,60,116,232,466,932,1872,3744,7494
  # c 0,1,1,1,1,2,4,8,18,39,79,159,315,628,1250,2494
  # e 1,0,0,0,0,0,0,2,6,10,22,40,80,156,308,622
  # g 0,0,0,0,0,0,0,2,2,6,10,20,40,76,156,310

  # b 0,0,1,1,3,5,10,20,38,78,155,311,625,1247,2500,4994
  # d 0,0,0,1,1,3,5,10,20,38,78,155,311,625,1247,2500
  # f 0,0,0,0,1,1,3,5,10,20,38,78,155,311,625,1247
  # h 0,0,0,0,0,1,1,3,5,10,20,38,78,155,311,625
  # i 0,0,0,0,0,0,1,1,3,5,10,20,38,78,155,311
  #
  # [4]
  # [2]
  # [0]
  # [1]
  # [-1]
  # [0]
  # [2]
  # [1]
  # x^8 - (4*x^7 + 2*x^6 + 0*x^5 + 1*x^4 + -1*x^3 + 0*x^2 + 2*x + 1)
  #
  # 2,6,10,22,40,80,156,308,622,1242,2494,4994,9988,19988,39952,79904,159786,319550,639122,1278222,2556512,5113048,10226116,20452300,40904486
  #
  # 4*2 + 2*6 + 0*10 + 22 - 40 + 0*80 + 2*156 + 308
  # a*x^2*g(x) + b*x*g(x) - g(x) = initial
  # (-2 - 4*x)/(-1 + 1*x + 2*x^2 + 0*x^3 - x^4 + x^5 + 0*x^6 + 2*x^7 + 4*x^8)
  #
  #
  my (@a,@b,@c,@d,@e,@f,@g,@h,@i);
  my $a = 0;
  my $b = 0;
  my $c = 0;
  my $d = 0;
  my $e = 1;
  my $f = 0;
  my $g = 0;
  my $h = 0;
  my $i = 0;
  my @values;
  foreach my $k (0 .. 15) {
    print "$a $b $c $d $e $f $g $h $i\n";
    push @a, $a;
    push @b, $b;
    push @c, $c;
    push @d, $d;
    push @e, $e;
    push @f, $f;
    push @g, $g;
    push @h, $h;
    push @i, $i;
    if ($k % 2) {
      push @values, $b;
    } else {
      push @values, $b;
    }

    (    $a,        $b,    $c,          $d, $e,        $f, $g,   $h, $i)
      = (2*$d+2*$b, $a+$c, $c+$e+$f+$h, $b, 2*$g+2*$i, $d, 2*$i, $f, $h);

    $k < 2 || $e == 4*$i[-1 -1] + 2*$i[0 -1] or die;
    $k < 6 || $e == 4*$b[-5 -1] + 2*$b[-4 -1] or die;
    $k < 2 || $a == 2*$b[-1 -1] + 2*$b[0 -1] or die;
    $k < 2 || $f == $b[-1 -1] or die;
    $k < 3 || $h == $b[-2 -1] or die;
    $k < 7 || $c == ($c[0 -1] + 4*$b[-6 -1] + 2*$b[-5 -1]
                     + $b[-2 -1] + $b[-3 -1]) or die;
    $k < 8 || $b == $b[-1] + 2*$b[-2] + 0 - $b[-4] + $b[-5] + 0 + 2*$b[-7] + 4*$b[-8] or die;
  }
  shift @values;
  while (@values && $values[0] == 0) {
    shift @values;
  }
  shift @values;
  shift @values;
  print join(",",@values),"\n";
  Math::OEIS::Grep->search(array => \@values);

  print "a ",join(',',@a),"\n";
  print "b ",join(',',@b),"\n";
  print "c ",join(',',@c),"\n";
  print "d ",join(',',@d),"\n";
  print "e ",join(',',@e),"\n";
  print "f ",join(',',@f),"\n";
  print "g ",join(',',@g),"\n";
  print "h ",join(',',@h),"\n";
  print "i ",join(',',@i),"\n";

  my $t = $a + 2*$b + 2*$c + 2*$d + $e + 2*$f + $g + 2*$h + 2*$i;
  # $a+$b+$c+$d+$e+$f+$g+$h+$i;
  $a /= $t;
  $b /= $t;
  $c /= $t;
  $d /= $t;
  $e /= $t;
  $f /= $t;
  $g /= $t;
  $h /= $t;
  $i /= $t;
  printf  "%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f\n",
    $a, $b, $c, $d, $e, $f, $g, $h, $i;
  printf  "%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f\n",
    $a/$i, $b/$i, $c/$i, $d/$i, $e/$i, $f/$i, $g/$i, $h/$i, $i/$i;
  printf  "sum %f  %.5f\n", $t,
    $a + 2*$b + 2*$c + 2*$d + $e + 2*$f + $g + 2*$h + 2*$i;

  printf  "above %.5f\n", $a+2*$b+2*$c+2*$d+$e;
  printf  "below %.5f\n", 2*$f+$g+2*$h+2*$i;
  printf  "peak above %.5f\n", $a+2*$b+2*$c;
  printf  "peak below %.5f\n", +2*$d + $e + 2*$f+$g+2*$h+2*$i;


  @values = ();
  $seg_len = 1;
  $|=1;
  foreach my $k (0 .. 10) {
    my @count = ((0) x 21);
    my $n_end = 4**$k;
    my $x = 0;
    my $y = 0;
    foreach my $n (0 .. $n_end-1) {
      my ($dx,$dy) = $path->n_to_dxdy($n);
      {
        my ($x,$y) = div_90($x,$y, $k);
        my ($dx,$dy) = div_90($dx,$dy, $k);

        ($x,$y) = (-$x,-$y); # rotate 180
        ($dx,$dy) = (-$dx,-$dy); # rotate 180
        # $x -= 1;
        if ($k < 2) { print "$x,$y  $dx,$dy\n"; }
        my $part = seg_to_part($x,$y,$dx,$dy);
        $count[$part]++;
      }
      $x += $dx;
      $y += $dy;
    }
    if ($k < 0) {
      print "end $x,$y\n";
      ($x,$y) = div_90($x,$y, $k);
      ($x,$y) = (-$x,-$y); # rotate 180
      print "end rot $x,$y\n";

      printcounts(\@count);
      print "\n";
    }
    my $value = $count[1];
    push @values, $value;
    print "$value,";
  }
  print "\n";

  print join(",",@values),"\n";
  Math::OEIS::Grep->search(array => \@values);

  exit 0;

  sub div_90 {
    my ($x,$y, $n) = @_;
    foreach (1 .. $n) {
      ($x,$y) = ($y,-$x);  # rotate -90
      $x /= 2;
      $y /= 2;
    }
    return ($x,$y);
  }
}


{
  # points count on axes

  # x axis k even  A052953 Expansion of 2*(1-x-x^2)/((x-1)(2x-1)(1+x)).
  #                A128209 Jacobsthal numbers(A001045) + 1.
  #                A001045   a(n) = a(n-1)+2*a(n-2)   x/(1-x-2*x^2)  (1-2x)(1+x)
  # A001045 Jacobsthal x/(1-x-2*x^2)  near 2^n/3
  # axis a

  my @values;
  $seg_len = 1;
  $|=1;
  foreach my $k (0 .. 18) {
    my $n_end = 2**$k;
    my $xaxis = 0;
    my $yaxis = 0;
    my $xpos = 0;
    my $ypos = 0;
    my $xneg = 0;
    my $yneg = 0;
    foreach my $n (0 .. $n_end) {
      my ($x,$y) = $path->n_to_xy($n);
      # foreach (1 .. $k) {
      #   ($x,$y) = ($y,-$x);  # rotate -90
      # }
      if ($x == 0) { $yaxis++;}
      if ($y == 0) { $xaxis++;}
      if ($y == 0 && $x > 0) { $xpos++; }
      if ($y == 0 && $x < 0) { $xneg++; }
      if ($x == 0 && $y > 0) { $ypos++; }
      if ($x == 0 && $y < 0) { $yneg++; }
      if ($k < 2) {
        print "$n  xy=$x,$y\n";
      }
    }
    print "k=$k  $xaxis $yaxis  $xpos $xneg  $ypos $yneg\n";
    my $value = $xpos;
    push @values, $value;
    #    print "$value,";
  }
  print "\n";

  print join(",",@values),"\n";
  Math::OEIS::Grep->search(array => \@values);

  exit 0;
}

{
  # d alts gf

  # da[k+1] = d[k] + d[k-2] + d[k-3] + 2*d[k-4] + 1
  # d alts = 1,2,4,8,17,34,68,136,273,546,1092,2184,4369,8738,17476,34952
  # A083593 Expansion of 1/((1-2*x)*(1-x^4)).  (1-x)*(1+x)*(1+x^2)

  # G(x) - 2*x^4*G(x) - x^3*G(x) - x^2*G(x) - x*G(x) - 1/(1-x) = 0
  # G(x)*(1 - x - x^2 - x^3 - 2*x^4)
  # G(x) = 1/(1-x)/(1 - x - x^2 - x^3 - 2*x^4)
  # G(x) = 1/( (1-x) * (1-2*x) * (1-x^4) )
  # G(x) = 1/( (1-2*x) * (1-x)^2 * (1+x) * (1+x^2) )
  # W(x) = G(x^2) + x*G(x^2)
  # W(x) = (1 + x)/( (1-x^2)*(1+x^2)*(1-2*x^2)*(1+x^4) )

  # G(x) = A/(1-2*x) + B/(1-x) + C/(1-x)^2 + D/(1+x) + (E+F*x)/(1+x^2)
  #    (-A + -2*B + 2*D + 2*F)*x^5
  #   + (A + B + 2*C + -5*D + 2*E - 3*F)*x^4
  #   + (C + 6*D + -3*E - F)*x^3
  #   + (C + -6*D + -E + 3*F)*x^2
  #   + (A + 2*B + C + 4*D + 3*E - F)*x
  #   + (-A + -B + -C + -D - E)
  # matsolve([-1,-2,0,2,0,2; 1,1,2,-5,2,-3; 0,0,1,6,-3,-1; 0,0,1,-6,-1,3; 1,2,1,4,3,-1; -1,-1,-1,-1,-1,0],[0;0;0;0;0;1])
  # [-32/15]
  # [7/8]
  # [1/4]
  # [-1/24]
  # [1/20]
  # [-3/20]
  #
  # G(x) = 32/15/(1-2*x) - 7/8/(1-x) - 1/4/(1-x)^2 + 1/24/(1+x) + (-1/20 + 3/20*x)/(1+x^2)


  require Math::Polynomial;
  my $p = Math::Polynomial->new(1,2,4,8,17,34,68,136,273,546,1092,2184,4369,8738,17476,34952);
  my $q = Math::Polynomial->new(1,-1,-1,-1,-2);
  my $ones = Math::Polynomial->new(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  print $q*$p-$ones,"\n";
  exit 0;
}

{
  # d alts by recurrence
  # da[k+1] = d[k] + d[k-2] + d[k-3] + 2*d[k-4] + 1

  my @d = (1,2,4,8);
  foreach (1 .. 20) {
    push @d, $d[-1] + $d[-2] + $d[-3] + 2*$d[-4] + 1;
  }
  print join(',',@d),"\n";
  exit 0;
}

{
  # 8 axes directions by recurrence
  my (@a,@b,@c,@d,@e,@f,@g,@h);
  my $a = 0;
  my $b = 0;
  my $c = 0;
  my $d = 1;
  my $e = 0;
  my $f = 0;
  my $g = 0;
  my $h = 0;
  foreach my $i (0 .. 30) {
    print "$a $b $c $d $e $f $g $h\n";
    (    $a, $b, $c, $d,            $e,   $f, $g, $h)
      = ($b, $c, $d, $a+$c+$e+$g+1, 2*$f, $g, $h, $a);
    push @a,$a;
    push @b,$b;
    push @c,$c;
    push @d,$d;
    push @e,$e;
    push @f,$f;
    push @g,$g;
    push @h,$h;

    $i < 2 || $a[-1] == $b[-2] or die;
    $i < 3 || $a[-1] == $c[-3] or die;
    $i < 4 || $a[-1] == $d[-4] or die;
    $i < 2 || $e[-1] == 2*$f[-2] or die;
    $i < 3 || $e[-1] == 2*$g[-3] or die;
    $i < 4 || $e[-1] == 2*$h[-4] or die;
    $i < 5 || $e[-1] == 2*$a[-5] or die;
    $i < 6 || $e[-1] == 2*$b[-6] or die;
    $i < 7 || $e[-1] == 2*$c[-7] or die;
    $i < 8 || $e[-1] == 2*$d[-8] or die;
    $i < 2 || $d[-1] == $a[-1 -1] + $c[-1 -1] + $e[-1 -1] + $g[-1 -1] + 1 or die;
    $i < 4 || $d[-1] == $d[-4 -1] + $d[-2 -1] + $e[-1 -1] + $g[-1 -1] + 1 or die;
    $i < 8 || $d[-1] == $d[-1 -2] + $d[-3 -2] + $d[-5 -2] + 2*$d[-7 -2] + 1 or die;

    # d[k+1] = a[k]   + b[k]   + e[k]     + g[k]    + 1
    #
    # d[k+1] = d[k-2] + d[k-3] + d[k-5] + 2*d[k-7]  + 1
  }

  #        0 1 2 3 4 5 6 7  8
  # @d = (1,1,2,2,4,4,8,8,17);
  # foreach my $i (8 .. 20) {
  #   push @d, $d[$i-1] + $d[$i-3] + $d[$i-5] + 2*$d[$i-7] + 1;  # d[i+1]
  # }
  # print join(',',@d),"\n";

  my @values;
  for (my $i = 0; $i <= $#d; $i+=2) {
    push @values, $d[$i];
    # push @values, 2*$a[$i] + $e[$i] + 2;
  }
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  #   1---0     k=0
  #
  #     1       k=1  d=1
  #    / \
  #   2   0
  #
  #   3-2-1     k=2  c=1
  #   |   |          d=1
  #   4   0
  #
  #           *         *
  #           |\       /|
  #           | \     / |             a[k+1] = b
  #           | ca   ca |             b      = c
  #           |   \|/   |             c      = d
  #      *    |  --*--  |    *        d      = a+c + e+g + 1
  #       \   |   /|\   |   /         e      = 2*f
  #        c  d eg   eg d  /          f[k+1] = g
  #         \ | /     \ | c           g      = h
  #          \|/       \|/            h      = a
  # *-----b---*--f-*-f--*--b------*
  #          /|\       /|\
  #         a | g     g | a
  #        /  h  \   /  h  \
  #       /   |   \ /   |   \
  #      *    |    *    |    *
  #           |   / \   |
  #           |  /   \  |
  #           | /     \ |
  #           |/       \|
  #           *         *
  #
  # a[k+1] = b[k] = c[k-1] = d[k-2]
  # e[k+1] = 2*f[k] = 2*g[k-1] = 2*h[k-2] = 2*a[k-3] = 2*b[k-4] = 2*c[k-5] = 2*d[k-6]
  # g[k+1] = h[k] = a[k-1] = b[k-2] = c[k-3] = d[k-4]
  # d[k+1] = a[k]   + c[k]   + e[k]     + g[k]    + 1
  #        = d[k-3] + d[k-1] + 2*d[k-7] + d[k-5]  + 1
  # d[k+1] = d[k-1] + d[k-3] + d[k-5] + 2*d[k-7]  + 1
  # d=1,1,2,2,4,4,8,8,17,17,34,34,68,68,136,136,273,273,546
  # 2*1 + 2 + 4 + 8 + 1 = 17

  #         *       *
  #         |\     /|
  #         | \   / |
  #         |  \ /  |
  #     *   |   *   |   *
  #      \  |  / \  |  /
  #       b c d   d c b
  #        \|/     \|/
  # ----a---*---e---*---a-----
  #        /|\     /|\
  #       h g f   f g h
  #      /  |  \ /  |  \
  #     *   |   *   |   *
  #         |  / \  |
  #         | /   \ |
  #         |/     \|
  #         *       *

=pod

X positive
Xpos[8i+0] = e[8i+0] + a[8i+0] + 1 = 2*d[8i-7] + d[8i-3] + 1
Xpos[8i+1] = d[8i+1]
Xpos[8i+2] = c[8i+2] = d[8i+1]
Xpos[8i+3] = b[8i+3] = d[8i+1]
Xpos[8i+4] = a[8i+4] = d[8i+1]
Xpos[8i+5] = h[8i+5] = d[8i+1]
Xpos[8i+6] = g[8i+6] = d[8i+1]
Xpos[8i+7] = f[8i+7] = d[8i+1]
1,1,1,1,1,1,1,1, 7, 17,17,17,17,17,17,17, 103, 273,273

X axis
X[4i+0] = 2*a[4i+0] + e[4i+0] = 2*d[4i-3] + 2*d[4i-7]
X[4i+1] =   d[4i+1] + h[4i+1] = d[4i+1] + d[4i-3]
X[4i+2] =   c[4i+2] + g[4i+2] = d[4i+1] + d[4i-3]
X[4i+3] =   b[4i+3] + f[4i+3] = d[4i+1] + d[4i-3]
2,2,2,2, 4, 6,6,6, 12, 22,22,22, 44, 86,86,86, 172, 342,342,342, 684

=cut

  my ($len,$x,$y);
  my $xy_to_part = sub {
    if ($y == 0 && $x > 0) { return 0; } # a
    if ($x == $y && $x > 0) { return 1; } # b
    if ($x == 0 && $y > 0) { return 2; } # c
    if ($x == -$y && $y > 0) { return 3; } # d
    if ($x < 0 && $x > -$len) { return 4; } # e
    if ($x == $y && $x < 0) { return 5; } # f
    if ($x == 0 && $y < 0) { return 6; } # g
    if ($x == -$y && $y < 0) { return 7; } # h
    return 10;
  };

  my @counts;
  $seg_len = 1;
  $|=1;
  my $i = 0;
  for (my $k = 1; $k < 20; $k += 1, $i++) {
    my $n_end = 2**$k;
    $len = 2**ceil($k/2);
    my $rot = (int($k/2)+2) % 4;
    my $fortyfive = $k % 2;
    foreach my $part (0 .. 10) { $counts[$part][$i] = 0; }
    foreach my $n (0 .. $n_end) {
      ($x,$y) = $path->n_to_xy($n);
      foreach (1 .. $rot) {
        ($x,$y) = ($y,-$x);  # rotate -90
      }
      if ($fortyfive) {
        ($x,$y) = ($x+$y, $y-$x); # rotate -45
      }
      my $part = $xy_to_part->($x,$y, $len);
      $counts[$part][$i]++;
      if ($k < 3 || $n == $n_end) {
        # print "$n  xy=$x,$y  part=$part\n";
      }
    }
    print "k=$k  ",join(' ',map{$counts[$_][$i]}0 .. 7),"  len=$len\n";
  }
  print "\n";

  foreach my $part (0 .. 7) {
    my $aref = $counts[$part];
    my @values = @$aref;
    shift @values;
    while (@values && $values[0] == 0) {
      shift @values;
    }
    shift @values;
    print "part=$part  ",join(",",@values),"\n";
    if (@values) {
      Math::OEIS::Grep->search(array => \@values);
    }
  }
  exit 0;
}


{
  # single, double etc point counts

  my $n = $path->n_start;
  my %seen;
  my @counts;
  foreach my $k (0 .. 20) {
    $counts[1][$k] = 0;
    $counts[2][$k] = 0;
    $counts[3][$k] = 0;
    $counts[4][$k] = 0;
    my $n_end = 2**$k;
    while ($n < $n_end) {
      my ($x,$y) = $path->n_to_xy ($n);
      $seen{"$x,$y"}++;
      $n++;
    }
    foreach my $seen (values %seen) {
      $counts[$seen][$k]++;
    }
    print "$k $counts[1][$k] $counts[2][$k] $counts[3][$k] $counts[4][$k]\n";
  }
  foreach my $s (1 .. 4) {
    my @values = @{$counts[$s]};
    while (@values && $values[0] == 0) {
      shift @values;
    }
    shift @values;
    shift @values;
    shift @values;
    shift @values;
    print "s=$s\n";
    print join(",",@values),"\n";
    Math::OEIS::Grep->search(array => \@values);
  }
  exit 0;
}

{
  # area parts of fractal
  #    a      b(2)    c(2)    d(2)     e      f(2)    g      h(2)     i(2)
  # 0.36364 0.24242 0.12121 0.12121 0.03030 0.06061 0.01515 0.03030 0.01515
  #
  # 0.22857 0.15238 0.07619 0.07619 0.01905 0.03810 0.00952 0.01905 0.00952
  # 24   +  16   +  8  +    8+      2 +     4  +    1 +     2 +     1   = 66
  #

  exit 0;
}



{
  sub seg_to_quad {
    my ($x,$y,$dx,$dy, $a,$b,$c,$d) = @_;
    ### seg_to_quad(): "x=$x y=$y  dx=$dx dy=$dy"
    if ($x < 0) {
      ### x neg ...
      return undef;
    }
    if ($x == 0) {
      if ($dy < 0) {
        ### x=0 and leftward notch ...
        return undef;
      }
      if ($dx < 0) {
        ### x=0 and downward notch ...
        return undef;
      }
    }
    if ($y < 0) {
      ### y neg ...
      return undef;
    }
    if ($y == 0) {
      if ($dx > 0) {
        ### y=0 and downward notch ...
        return undef;
      }
      if ($dy < 0) {
        ### y=0 and leftward notch ...
        return undef;
      }
    }

    # *---------*
    # |\   a   /|
    # | \     / |
    # |  \   /  |
    # |   \ /   |
    # |b   *   d|
    # |   / \   |
    # |  /   \  |
    # | /     \ |
    # |/   c   \|
    # *---------*

    my $s = $x+$y;
    my $cd = ($x > $y || ($x == $y && ($dx > 0       # downward notch
                                       || $dy < 0    # leftward notch
                                      )));
    my $ad = ($s > $seg_len || ($s == $seg_len && ($dx > 0     # downward notch
                                           || $dy > 0  # rightward notch
                                          )));
    ### at: "cd=$cd ad=$ad"
    if ($cd) {
      if ($ad) { return $d; }
      else { return $c; }
    } else {
      if ($ad) { return $a; }
      else { return $b; }
    }
  }

  sub seg_to_part {
    my ($x,$y,$dx,$dy) = @_;
    if (defined (my $part = seg_to_quad($x,$y,$dx,$dy, 20,4,7,20))) {
      return $part;
    }
    $x += $seg_len;
    if (defined (my $part = seg_to_quad($x,$y,$dx,$dy, 0,2,6,3))) {
      return $part;
    }
    $x += $seg_len;
    if (defined (my $part = seg_to_quad($x,$y,$dx,$dy, 20,20,5,1))) {
      return $part;
    }
    $x -= 2*$seg_len;
    $y += $seg_len;
    if (defined (my $part = seg_to_quad($x,$y,$dx,$dy, 10,14,20,20))) {
      return $part;
    }
    $x += $seg_len;
    if (defined (my $part = seg_to_quad($x,$y,$dx,$dy, 9,12,20,13))) {
      return $part;
    }
    $x += $seg_len;
    if (defined (my $part = seg_to_quad($x,$y,$dx,$dy, 8,20,20,11))) {
      return $part;
    }
    return 20;
  }

  sub printcounts {
    my ($count) = @_;
    my $total = sum(@$count);
    printf "           |      %6d        |      total %d\n", $count->[0], $total;
    printf "    %6d | %6d      %6d | %6d\n", $count->[1], $count->[2], $count->[3], $count->[4];
    printf "%6d     |      %6d        |     %6d\n", $count->[5], $count->[6], $count->[7];
    print "-------------------------------------------------\n";
    printf "%6d     |      %6d        |     %6d\n", $count->[8], $count->[9], $count->[10];
    printf "    %6d | %6d      %6d | %6d     [%d]\n", $count->[11], $count->[12], $count->[13], $count->[14],
      $count->[20];;
  }
}


{
  # area as triangle spread, counted from path

# len 16384
# half 8192
#
# 61356740 40904429 20452175 20452175 40904429 20452243 5113048 20452243 10226127 2556512 10226127 5113058 2556546 2556546 5113058
# total 268435456
# sum   268435456
#            |      61356740        |
#     40904429 | 20452175      20452175 | 40904429
# 20452243     |      5113048        |     20452243
# -------------------------------------------------
# 10226127     |      2556512        |     10226127
#     5113058 | 2556546      2556546 | 5113058

  #           *---------*
  #          /|\  0|0  /|\
  #         / | \  |  / | \
  #        /  |  \ | /  |  \
  #       /  1|2  \ /  3|4  \
  #      *--- | ---*--  |  --*
  #     / \  1|2  / \  3|4  / \
  #    /   \  |  /   \  |  /   \
  #   /  |  \ | /  |  \ | /  |  \
  #  /  5|5  \|/  6|6  \|/  7|7  \
  # *---------*---------*---------*
  #  \  8|8  /|\  9|9  /|\ 10|10 /
  #   \  |  / | \  |  / | \  |  /
  #    \   /  |  \   /  |  \   /
  #     \ / 11|12 \ /13 |14 \ /
  #      *--  |  --*--  |  --*
  #       \ 11|12 / \13 |14 /
  #        \  |  /   \  |  /
  #         \ | /     \ | /
  #          \|/       \|/
  #           *         *
  #
  #             *                           *               <- Y=4
  #               2       0       0     3
  #            11-----10-----9,7-----6------5      .
  #         1   1|            0|0            |4   4
  # .   13-----12             8             4------3     .  <- Y=2
  #    1 |                                         | 4
  #     14      |      .             .      |      2
  #    5 |                                         | 7
  #     15-----16                           0------1        <- Y=0
  #         8  len=4                          10
  #

  my $k = 3*8 + 4;
  my $len = 2**($k/2);
  my $half = $len/2;
  my $n_end = 2**$k;
  my $x = 0;
  my $y = 0;
  my ($dx,$dy);
  print "len $len\n";
  print "half $half\n";

  my $path = Math::PlanePath::CCurve->new;
  {
    my ($x,$y) = $path->n_to_xy($n_end);
    $x == -$len or die "$x";
    $y == 0 or die;
  }
  my @count = ((0) x 15);
  my $mx = 0;
  my $my = 0;
  foreach my $n (0 .. $n_end-1) {
    ($dx,$dy) = $path->n_to_dxdy($n);
    $x = $mx;
    $y = $my;
    my $part = seg_to_part($x,$y,$dx,$dy);
    # print "x=$mx y=$my s=",$mx+$my," dx=$dx dy=$dy  part $part\n";
    $count[$part]++;
    $mx += $dx;
    $my += $dy;
  }
  print "\n";
  print join(' ',@count),"\n";
  print "total $n_end\n";
  printcounts(\@count);
  exit 0;
}
{
  #           *---------*                      *---------*
  #          /|\  0|0  /|\                    /|\   |   /|\
  #         / | \  |  / | \                 1/ | \2 | 3/ | \4
  #        /  |  \ | /  |  \                /  | 0\ | /0 |  \
  #       /  1|2  \ /  3|4  \              /   |   \ /   |   \
  #      *--- | ---*--  |  --*            *--- | ---*--  |  --*
  #     / \  1|2  / \  3|4  / \          / \   |   / \   |   / \
  #    /   \  |  /   \  |  /   \       5/   \5 | 6/   \6 | 7/   \7
  #   /  |  \ | /  |  \ | /  |  \      /  | 1\ | /2 | 3\ | /4 |  \
  #  /  5|5  \|/  6|6  \|/  7|7  \    /   |   \|/   |   \|/   |   \
  # *---------*---------*---------*  *---------*---------*---------*
  #  \  8|8  /|\  9|9  /|\ 10|10 /    \   |   /|\   |   /|\   |   /
  #   \  |  / | \  |  / | \  |  /      \  |11/ | \12|13/ | \14|  /
  #    \   /  |  \   /  |  \   /       8\   /8 | 9\   /9 |10\   /10
  #     \ / 11|12 \ /13 |14 \ /          \ /   |   \ /   |   \ /
  #      *--  |  --*--  |  --*            *--  |  --*--  |  --*
  #       \ 11|12 / \13 |14 /              \   |   / \   |   /
  #        \  |  /   \  |  /                \  |  /   \  |  /
  #         \ | /     \ | /                11\ | /12 13\ | /14
  #          \|/       \|/                    \|/       \|/
  #           *         *                      *         *
  #
  # 6 -> left 2bit 2,9

  # expanded            a  b c d  e   f g h   i j k    l  m  n  p
  #                     0  1 2 3  4   5 6 7   8 9 10  11 12 13 14
  my $left_bitperm  = [13, 6,3,12,9,  0,2,8,  3,6,11,  2,0,5,1];
  my $right_bitperm = [12, 9,13,2,6, 10,3,0, 14,6,2,   4,7,0,3];

  # # unexpanded
  # #            0  1 2 3  4   5 6  7  8 9 10  11 12 13 14
  # my $left  = [9, 3,6,9,12,  3,6,11, 0,2,8,   0,2,1,5];
  # my $right = [8, 13,9,6,2, 14,6, 2, 10,3,0,  7,4,3,0];

  my @mask = map {1<<$_} 0 .. $#$left_bitperm;
  my $bitperm = sub {
    my ($n, $perm) = @_;
    my $new = 0;
    foreach my $i (0 .. $#$perm) {
      if ($n & $mask[$perm->[$i]]) {
        $new |= $mask[$i];
      }
    }
    return $new;
  };
  my @left  = map {$bitperm->($_,$left_bitperm)} 0 .. 0x7FFF;
  my @right = map {$bitperm->($_,$right_bitperm)} 0 .. 0x7FFF;

  require Graph::Easy;
  my $graph = Graph::Easy->new(timeout => 9999);

  my %seen;
  # my %reverse;
  my @pending = ($mask[6]);
  @pending = @mask;
  while (@pending) {
    # last if scalar(keys %seen) > 20;
    my $n = pop @pending;
    next if $seen{$n};
    $seen{$n} = 1;
    my $l = $left[$n];
    my $r = $right[$n];
    # push @{$reverse{$l}}, "$n.L";
    # push @{$reverse{$r}}, "$n.R";
    printf "%015b -> left %015b right %015b\n", $n, $l, $r;
    push @pending, $l, $r;

    my $n_name = $n;
    my $l_name = $l;
    my $r_name = $r;
    # my $n_name = sprintf '%02X', $n;
    # my $l_name = sprintf '%02X', $l;
    # my $r_name = sprintf '%02X', $r;
    if ($n & $mask[6]) {
      if ($n != $l) { $graph->add_edge_once($n_name,$l_name); }
      if ($n != $r) { $graph->add_edge_once($n_name,$r_name); }
    }

    # if (($n & $mask[6])
    #     && ($l & $mask[6])
    #     && ($r & $mask[6])
    #    ) {
    #   # $graph->add_edge_once($n_name,$l_name);
    #   # $graph->add_edge_once($n_name,$r_name);
    # }
    # if (($n & $mask[6]) && ($r & $mask[6])) {
    # }
  }
  my @seen = sort {$a<=>$b} keys %seen;
  print "count seen ",scalar(@seen),"\n";
  foreach my $i (0 .. $#seen) {
    $seen{$seen[$i]} = $i;
  }

  {
    # always-on
    my %not_always_on;
    foreach my $n (@seen) {
      if (($n & $mask[6]) == 0) {
        $not_always_on{$n} = 1;
      }
    }
    print "count OFF ",scalar(keys %not_always_on),"\n";
    my $more = 1;
    while ($more) {
      $more = 0;
      foreach my $n (@seen) {
        unless ($not_always_on{$n}) {
          my $l = $left[$n];
          my $r = $right[$n];
          if ($not_always_on{$l} || $not_always_on{$r}) {
            $not_always_on{$n} = 1;
            $more++;
          }
        }
      }
      print "  pass $more excluded\n";
    }

    my %always_on;
    foreach my $n (@seen) {
      unless ($not_always_on{$n}) {
        $always_on{$n} = 1;
      }
    }
    print "count ON ",scalar(keys %always_on),", not always ON ",scalar(keys %not_always_on),"\n";
    foreach my $n (@seen) {
      if ($always_on{$n}) {
        printf "  ON always %15b\n", $n;
      }
    }
  }

  {
    # always-off
    my %not_always_off;
    foreach my $n (@seen) {
      if ($n & $mask[6]) {
        $not_always_off{$n} = 1;
      }
    }
    print "count ON ",scalar(keys %not_always_off),"\n";
    my $more = 1;
    while ($more) {
      $more = 0;
      foreach my $n (@seen) {
        unless ($not_always_off{$n}) {
          my $l = $left[$n];
          my $r = $right[$n];
          if ($not_always_off{$l} || $not_always_off{$r}) {
            $not_always_off{$n} = 1;
            $more++;
          }
        }
      }
      print "  pass $more excluded\n";
    }

    my %always_off;
    foreach my $n (@seen) {
      unless ($not_always_off{$n}) {
        $always_off{$n} = 1;
      }
    }
    print "count always-OFF ",scalar(keys %always_off),", not always OFF ",scalar(keys %not_always_off),"\n";
    foreach my $n (@seen) {
      if ($always_off{$n}) {
        printf "  OFF always %015b\n", $n;
      }
    }
  }

  {
    foreach my $n (@seen) {
      if ($left[$n] == 0 || $right[$n] == 0) {
        print "to zero $n -> $left[$n] $right[$n]\n";
      }
    }
  }
  {
    foreach my $n (@seen) {
      if ($left[$n] == 0x7FFF || $right[$n] == 0x7FFF) {
        print "to ones $n -> $left[$n] $right[$n]\n";
      }
    }
  }
  {
    foreach my $n (@seen) {
      if ($left[$n] == $n || $right[$n] == $n) {
        print "to self $n -> $left[$n] $right[$n]\n";
      }
    }
  }

  {
    # row reductions
    my @m;
    my $end = $#seen;

    my $printrow = sub {
      my ($r) = @_;
      print "row $r = ";
      foreach my $i (0 .. $end) {
        if ($m[$r][$i]) { print "$m[$r][$i]"; }
        print ",";
      }
      print "\n";
    };
    my $printcol = sub {
      my ($c) = @_;
      print "column $c = ";
      foreach my $i (0 .. $end) {
        if ($m[$i][$c]) { print "$m[$i][$c]"; }
        print ",";
      }
      print "\n";
    };

    foreach my $i (0 .. $end) {
      $m[$i][$i] = Math::BigRat->new(1);
      my $n = $seen[$i];
      foreach my $t ($left[$n], $right[$n]) {
        my $ti = $seen{$t} || 0;
        if ($ti != 0 && $ti != $end) {
          $m[$i][$ti] ||= 0;
          $m[$i][$ti] -= Math::BigRat->new("-1/2");
        }
      }
    }
    $m[$end][$end+1] = Math::BigRat->new(1);
    print "weights\n";
    $printcol->($end+1);

    foreach my $c (0 .. $end) {
      print "column $c\n";

      foreach my $i (0 .. $c-1) {
        if ($m[$c][$i]) {
          $printrow->($c);
          die "oops not zero $c, $i";
        }
      }

      if ($m[$c][$c] == 0) {
        $printrow->($c);
        die " is zero";
      }
      if ($m[$c][$c] != 1) {
        my $f = 1 / $m[$c][$c];
        my $count = 0;
        foreach my $i (0 .. $end+1) {
          if ($m[$c][$i]) {
            $m[$c][$i] *= $f;
            $count++;
          }
        }
        print "  mul $f  ($count terms)\n";
      }
      print "  weight ",$m[$c][$end+1]||0,"\n";

      $m[$c][$c] == 1 or die " diagonal not one ",$m[$c][$c];

      foreach my $r ($c+1 .. $end) {
        my $f = $m[$r][$c];
        if ($f) {
          my $count = 0;
          foreach my $i (0 .. $end+1) {
            my $d = ($m[$r][$i] || 0) - $f * ($m[$c][$i] || 0);
            if ($d == 0) {
              delete $m[$r][$i];
            } else {
              $m[$r][$i] = $d;
              $count++;
            }
          }
          print "  row $r sub $c * $f  ($count terms)\n";
        }
      }
    }

    print "weights\n";
    $printcol->($end+1);

    foreach my $c (reverse 0 .. $end) {
      print "column $c\n";
      $m[$c][$c] == 1 or die " diagonal not one ",$m[$c][$c];

      my $count = 0;
      foreach my $r (0 .. $c-1) {
        my $f = delete $m[$r][$c];
        if ($f) {
          $m[$r][$end+1] ||= 0;
          $m[$r][$end+1] -= $f ;
          $count++;
        }
      }
      print "  ($count terms)\n";
    }

    print "weights\n";
    $printcol->($end+1);

    foreach my $i (0 .. $end) {
      my $n = $seen[$i];
      my $w = $m[$i][$end+1] || 0;
      print "  $n => Math::BigRat->new('$w'),\n";
    }
    foreach my $n (@mask) {
      my $i = $seen{$n};
      if (defined $i) {
        print "mask $n weight $m[$i][$end+1]\n";
      }
    }
  }
  exit;

  if (0) {
    print "weight\n";
    my %weight;
    $weight{0} = 0;
    $weight{0x7FFF} = 1;

    my %weight_const;
    my %weight_n;
    my %weight_factor;

    my $more = 1;
    while ($more) {
      $more = 0;
      foreach my $n (@seen) {
        unless (defined $weight{$n}) {
          my $l = $left[$n];
          my $r = $right[$n];
          if (defined $weight{$l} && defined $weight{$r}) {
            $weight{$n} = $weight{$l} + $weight{$r};
            $more = 1;
            delete $weight_const{$n};
            delete $weight_n{$n};
            delete $weight_factor{$n};
          } elsif (defined $weight_n{$n} && $weight_n{$n} == $n) {
            # w = c + w*f
            # w = c/(1-f)
            $weight{$n} = $weight_const{$n} / (1 - $weight_factor{$n});
            $more = 1;
          } elsif (! defined $weight_n{$n} && defined $weight{$l}) {
            $weight_const{$n} = $weight{$l}/2;
            $weight_n{$n} = $r;
            $weight_factor{$n} = 1/2;
            $more = 1;
          } elsif (! defined $weight_n{$n} && defined $weight{$r}) {
            $weight_const{$n} = $weight{$r}/2;
            $weight_n{$n} = $l;
            $weight_factor{$n} = 1/2;
            $more = 1;
          } elsif (defined (my $w = $weight_n{$n})) {
            if (defined $weight{$w}) {
              $weight{$n} = $weight_const{$n} + $weight{$w}*$weight_factor{$n};
              delete $weight_const{$n};
              delete $weight_n{$n};
              delete $weight_factor{$n};
              $more = 1;
            } elsif (defined $weight_n{$w}) {
              # c + f*(c2+f2*x)
              # = c+f*c2 + f*f2*x
              $weight_const{$n} += $weight_const{$w} * $weight_factor{$n};
              $weight_n{$n} = $weight_n{$w};
              $weight_factor{$n} *= $weight_factor{$w};
              $more = 1;
            }
          }
        }
      }
      print "  pass $more, factors ",scalar(keys %weight_factor),", final ",scalar(keys %weight),"\n";
    }

    foreach my $n (sort {$a<=>$b} keys %weight_n) {
      printf "%X -> %f + %f * %X\n",
        $n, $weight_const{$n}, $weight_factor{$n}, $weight_n{$n};
    }
    # print join(' ',map{sprintf '%X', $_} sort {$a<=>$b} keys %weight),"\n";
  }

  if (0) {
    # w[0] - (w[0]/2 + w[0]/2) = 0
    # w[f] - (w[f]/2 + w[f]/2) = 0
    # w[6] = 0.5*w[2] + 0.5*w[3]
    # w[0] = 0
    # w[32767] = 1
    # w = W*w + F
    # w = (I-W)^-1 * F
    #
    open my $fh, '>', '/tmp/x.gp';
    print $fh "allocatemem(230000000)\n";
    print $fh "W=[";
    my $sep = '';
    print "before ",scalar(@seen),"\n";
    # @seen = grep {$_ != 0} @seen;
    # @seen = grep {$left[$_] || $right[$_]} @seen;
    print "reduced ",scalar(@seen),"\n";
    foreach my $n (@seen) {
      my $l = $left[$n];
      my $r = $right[$n];
      foreach my $i (@seen) {
        print $fh $sep,
          ($i==$n ? "1" : "0"),
            ($i == $l && $i != 0 && $i != 0x7FFF ? "-1/2" : ""),
              ($i == $r && $i != 0 && $i != 0x7FFF ? "-1/2" : "");
        $sep = ',';
      }
      $sep = "; \\\n";
      printf "w[%4X] - (w[%4X]/2 + w[%4X]/2) = 0\n", $n,$l,$r;
    }
    print $fh "];";

    print $fh " F=[";
    $sep = '';
    foreach my $i (@seen) {
      print $fh $sep, $i==0x7FFF ? 1 : 0;
      $sep = ';';
    }
    print $fh "];";

    # print $fh " matdet(W)\n";
    print $fh " mattranspose(matsolve(W,F))\n";
    # print $fh "W^-1 * F\n";
    $|=1; # autoflush
    system ('gp  < /tmp/x.gp');
  }

  $graph->rename_node(32767, "*");
  # {
  #   # merge on->on,on
  #
  #   my $all_successors_on = sub {
  #     my ($node) = @_;
  #     foreach my $successor ($node->successors) {
  #       if (! ($successor->label & $mask[6])) {
  #         return 0;
  #       }
  #     }
  #     return 1;
  #   };
  #     my $more = 1;
  #   my $depth = 0;
  #   while ($more) {
  #     # print $graph->as_ascii;
  #     print "depth $depth\n";
  #     $more = 0;
  #     foreach my $node ($graph->nodes) {
  #       if ($all_successors_on->($node)) {
  #
  #       my @successsors = $node->successors;
  #       if (! @successsors) {
  #         print "  del ",$node->label,"\n";
  #         $graph->del_node($node);
  #         $more = 1;
  #       }
  #     }
  #     $depth++;
  #   }
  #   my $num_nodes = $graph->nodes;
  #   print "merged to $num_nodes\n";
  # }

  {
    my $graphviz = $graph->as_graphviz();
    require File::Slurp;
    File::Slurp::write_file('/tmp/c-curve.dot', $graphviz);
  }

  #print $graph->as_ascii;

  print "type ",$graph->type,"\n";
  print "is_simple: ",$graph->is_simple ? "yes\n" : "no\n";
  print "roots: ",join(' ', map{$_->name} $graph->source_nodes), "\n";

  if (0) {
    # delete sinks

    print "count nodes ",scalar($graph->nodes),"\n";
    my $more = 1;
    my $depth = 0;
    while ($more) {
      # print $graph->as_ascii;
      print "depth $depth\n";
      $more = 0;
      foreach my $node ($graph->nodes) {
        my @successsors = $node->successors;
        if (! @successsors) {
          print "  del ",$node->label,"\n";
          $graph->del_node($node);
          $more = 1;
        }
      }
      $depth++;
    }
    my $num_nodes = $graph->nodes;
    print "remaining $num_nodes\n";
  }



  exit;

  {
    my $txt = $graph->as_txt;
    require File::Slurp;
    File::Slurp::write_file('/tmp/c-curve.txt', $txt);
  }


  exit 0;
}



{
  # convex hull
  # A007283  3*2^n

  require Math::Geometry::Planar;
  my @values;
  my @points;
  my $n = $path->n_start;
  foreach my $k (0 .. 14) {
    my $n_end = 2**$k;
    while ($n <= $n_end) {
      push @points, [ $path->n_to_xy($n) ];
      $n++;
    }
    my ($area, $boundary);
    if (@points < 3) {
      $area = 0;
      $boundary = 2;
    } else {
      my $polygon = Math::Geometry::Planar->new;
      $polygon->points([@points]);
      if (@points > 3) { $polygon = $polygon->convexhull2; }
      my $points = $polygon->points;
      $area = blessed($polygon) && $polygon->area;
      $boundary = blessed($polygon) && $polygon->perimeter;
    }
    my $bstr = to_root_sum($boundary);

    my ($a,$b) = $path->_UNDOCUMENTED_level_to_hull_boundary_sqrt2($k);
    my $len = $path->_UNDOCUMENTED_level_to_hull_boundary($k);
    my $ar = $path->_UNDOCUMENTED_level_to_hull_area($k);

    # print "$k   $boundary = $bstr   $a $b\n";
    printf "%6.3f\n", $len;
    #print "$k $area $ar\n";
    # print "$ar, ";
    if (! ($k & 1)) {
      push @values, $area;
    }
  }

  while (! is_integer($values[0])) {
    shift @values;
  }
  # shift @values;
  # shift @values;
  # shift @values;
  print join(",",@values),"\n";
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub is_integer {
    my ($n) = @_;
    return ($n == int($n));
  }

  # k even
  #         S[h]
  #       ---------
  #      /          \  Z[h-1]
  #     /            \
  #    |              |  S[h-1]
  #     \            / Z[h-2]
  #      --        --
  # width = S[h] + 2*(Z[h-1]/2)
  #       = 2^h + 2*2^(h-1)-2
  #       = 2*2^h - 2
  # height = S[h-1] + Z[h-1]/2 + Z[h-2]/2
  #        = 2^(h-1) + (2*2^(h-1)-2)/2 + (2*2^(h-2)-2)/2
  #        = 2^(h-1) + 2^(h-1)-1 + 2^(h-2)-1
  #        = 2^(h-1) + 2^(h-1) + 2^(h-2) - 2
  #        = 5*2^(h-2) - 2
  # upper corner = (Z[h-1]/2)
  #              = 2^(h-1) - 1
  # lower corner = (Z[h-2]/2)
  #              = 2^(h-2) - 1
  # area = width*height - upper^2 - lower^2
  #      = (2*2^h - 2)*(5*2^(h-2) - 2) - (2^(h-1) - 1)^2 - (2^(h-2) - 1)^2
  #      = (8*2^(h-2) - 2)*(5*2^(h-2) - 2) - (2*2^(h-2) - 1)^2 - (2^(h-2) - 1)^2
  #      = (8*p - 2)*(5*p - 2) - (2*p - 1)^2 - (p - 1)^2
  #      = 35*p^2 - 20*p + 2
  #      = 35*2^(2h-4) - 20*2^(h-2) + 2
  #      = 35*2^(k-4) - 20*2^(h-2) + 2
  #      = 35*2^(k-4) - 5*2^h + 2

  # k odd
  #            S[h]
  #            ----
  #   Z[h-1] /     \    middle Z[h]
  # S[h-1]  |       \
  #          \       \
  #                   |  S[h]
  #                   |
  #             \    /  Z[h-1]
  #               --
  #              S[h-1]
  #
  # width = S[h] + Z[h]/2 + Z[h-1]/2
  #       = 2^h + 2^h-1 + 2^(h-1)-1
  #       = 5*2^(h-1) - 2
  #       = 5/2*p - 2
  # height = Z[h]/2 + S[h] + Z[h-1]/2
  #        = width
  # UL = Z[h-1]/2 = 2^(h-1) - 1 = p/2-1
  # UR = Z[h]/2   = 2^h - 1     = p-1
  # BL = width - Z[h-1]/2 - S[h-1]
  #    = S[h] + Z[h]/2 + Z[h-1]/2 - Z[h-1]/2 - S[h-1]
  #    = Z[h]/2 + S[h] - S[h-1]
  #    = p-1 + p - p/2
  # BR = Z[h-1]/2 = 2^(h-1) - 1 = p/2-1
  # area = width*height - UL^2/2 - UR^2/2 - BL^2/2 - BR^2/2
  #      = (5/2*p - 2)^2 - (p/2-1)^2/2 - (p-1)^2/2  - (p-1 + p - p/2)^2/2 - (p/2-1)^2/2
  #      = 35/8*p^2 - 13/2*p + 2


  # x = a + b*sqrt(2)
  sub to_root_sum {
    my ($x) = @_;
    if (! defined $x) { return 'undef' }
    foreach my $b (0 .. int($x)) {
      my $a = $x - $b*sqrt(2);
      my $a_int = int($a+.5);
      if (abs($a - $a_int) < 0.00000001) {
        return "$a_int + $b*sqrt(2)";
      }
    }
    return "$x";
  }
}

{
  # total boundary vs recurrence
  #
  # B[k] = /  7*2^h - 2k - 6 + 55/4*2^h + 28h - 130     if k even
  #        \ 10*2^h - 2k - 6 + 78/4*2^h + 28h - 116     if k odd
  #
  #      = /  83/4 * 2^h + 12k - 136     if k even      k >= 6
  #        \ 118/4 * 2^h + 12k - 136     if k odd
  #
  # B[k] = 2*B[k-1] + B[k-2] - 4*B[k-3] + 2*B[k-3]

  my @want = (2,4,8,16,30,56,102,184,292,444,648,940,1336,1908,2688,3820,5368,7620,10704,15196,21352,30324);
  my $B;
  $B = sub {
    my ($k) = @_;
    if ($k < 6) { return $want[$k]; }
    my $h = int($k/2);
    if ($k % 2 == 0) {
      return  83/4 * 2**$h + 12*$k - 136;  # 83+35 = 118
    } else {
      return 118/4 * 2**$h + 12*$k - 136;
    }
  };
  $B = sub {
    my ($k) = @_;
    if ($k < 10) { return $want[$k]; }
    return ($B->($k-4) * 2
            + $B->($k-3) * -4
            + $B->($k-2) * 1
            + $B->($k-1) * 2);
  };
  # $B = sub {
  #   my ($k) = @_;
  #   return MyOEIS::path_boundary_length($path, 2**$k);
  # };
  $|=1;
  foreach my $k (0 .. $#want) {
    my $want = $want[$k];
    my $got = $B->($k);
    my $diff = $want - $got;
     print "$k  $want  $got   $diff\n";
    # print "$got,";
  }
  exit 0;
}

{
  # left boundary vs recurrence
  # L[k] = 4*L[k-1] - 5*L[k-2] + 2*L[k-3]   k >= 6
  # x^3 - 4*x^2 + 5*x - 2 = (x-1)^2 * (x-2)      so a*2^k + b*k + c
  #
  # explicit L[2*h]   = 55/4 * 2^h + 28*h - 130      # h>=3
  # explicit L[2*h+1] = 78/4 * 2^h + 28*h - 116

  # my @want = (1,4,16,64,202,450,918,1826,3614,7162,14230,28338,56526,112874,225542,450850,901438,1802586);
  my @want = (2,8,32,124,308,648,1300,2576,5100,10120,20132,);  # left 2k+1
  my $L;
  $L = sub {
    my ($k) = @_;
    if ($k < 6) { return $want[$k]; }
    return ($L->($k-3) * 2
      + $L->($k-2) * -5
        + $L->($k-1) * 4);
  };
  $L = sub {
    my ($k) = @_;
    if ($k < 3) { return $want[$k]; }
    return 78/4*2**$k + 28*$k - 116;
  };
  # $L = sub {
  #   my ($k) = @_;
  #   return MyOEIS::path_boundary_length($path, 2*4**$k, side => 'left');
  # };
  $|=1;
  foreach my $k (0 .. $#want) {
    my $want = $want[$k];
    my $got = $L->($k);
    my $diff = $want - $got;
     print "$k  $want  $got   $diff\n";
    # print "$got,";
  }
  exit 0;
}

{
  # right boundary formula vs recurrence
  # R[k] = 2*R[k-1] + R[k-2] - 4*R[k-3] + 2*R[k-4]
  #
  # R[2k]   = 4*R[2k-2] - 5*R[2k-4] + 2*R[2k-6]
  # R[2k+1] = 4*R[2k-1] - 5*R[2k-3] + 2*R[2k-5]

  my $R;
  $R = sub {
    my ($k) = @_;
    if ($k < 4) { return R_formula($k); }
    return (2*$R->($k-4)
            - 4*$R->($k-3)
            + $R->($k-2)
            + 2*$R->($k-1));
  };
  require Memoize;
  $R = Memoize::memoize($R);

  my $R2;
  $R2 = sub {
    my ($k) = @_;
    if ($k < 3) { return R_formula(2*$k); }
    return (2*$R2->($k-3)
            - 5*$R2->($k-2)
            + 4*$R2->($k-1));
  };
  require Memoize;
  $R2 = Memoize::memoize($R2);

  my $R2P1;
  $R2P1 = sub {
    my ($k) = @_;
    if ($k < 3) { return R_formula(2*$k+1); }
    return (2*$R2P1->($k-3)
            - 5*$R2P1->($k-2)
            + 4*$R2P1->($k-1));
  };
  require Memoize;
  $R2P1 = Memoize::memoize($R2P1);

  foreach my $k (0 .. 50) {
    # my $want = R_formula($k);
    # print "$k  $want  ",$R->($k),"\n";
    my $want = R_formula(2*$k);
    print "$k  $want  ",$R2->($k),"\n";
  }
  exit 0;
}



{
  # right outer boundary with sqrt(2)

  sub S_formula {
    my ($h) = @_;
    return 2**$h;
  };
  sub Z_formula {
    my ($h) = @_;
    return 2*2**$h - 2;
  };
  my $S_cum = sub {   # sum S[0] .. S[h] inclusive
    my ($h) = @_;
    return 2**($h+1) - 1;
  };
  my $Z_cum = sub {   # sum Z[0] .. Z[h] inclusive
    my ($h) = @_;
    return 2*(2**($h+1) - 1) - 2*($h+1);
  };
  my $S_inR = sub {
    my ($k) = @_;
    my ($h, $rem) = Math::PlanePath::_divrem($k,2);
    if ($rem) {
      return 2*$S_cum->($h);
    } else {
      return 2*$S_cum->($h-1) + S_formula($h);
    }
  };
  my $Z_inR = sub {
    my ($k) = @_;
    my ($h, $rem) = Math::PlanePath::_divrem($k,2);
    if ($rem) {
      return 2*$Z_cum->($h-1) + Z_formula($h);
    } else {
      return 2*$Z_cum->($h-1);
    }
  };
  my $R_bySZ = sub {
    my ($k) = @_;
    return $S_inR->($k) + $Z_inR->($k);
  };

  {
    my $total = 0;
    foreach my $h (0 .. 10) {
      $total == $S_cum->($h-1) or die;
      $total += S_formula($h);
    }
  }
  {
    my $total = 0;
    foreach my $h (0 .. 10) {
      $total == $Z_cum->($h-1) or die;
      $total += Z_formula($h);
    }
  }
  # {
  #   print $S_cum->(-1),"\n";
  #   foreach my $h (0 .. 10) {
  #     print "+ ",S_formula($h), " = ",$S_cum->($h),"\n";
  #   }
  # }
  {
    foreach my $k (0 .. 10) {
      my $s = $S_inR->($k);
      my $z = $S_inR->($k);
      my $rby = $R_bySZ->($k);
      my $rformula = R_formula($k);
      # print "$k  $s + $z = $rby   rf=$rformula\n";
      $rby == $rformula or die "$k $rby $rformula";
    }
  }

  {
    foreach my $k (0 .. 100) {
      my $s = $S_inR->($k);
      my $z = $S_inR->($k);
      my $t = sqrt(2)**$k;
      my $f = ($s + $z/sqrt(2)) / $t;
      print "$k  $s + $z    f=$f\n";
    }
    print "2+  2*sqrt(2)=",2 + 2*sqrt(2),"\n";   # k odd
    print "3+3/2*sqrt(2)=",3+1.5*sqrt(2),"\n";   # k even
  }
  exit 0;

}
{
  # right outer boundary

  sub R_formula {
    my ($k) = @_;
    my $h = int($k/2);

    return ($k & 1
            ? 10*2**$h - 2*$k - 6   # yes
            :  7*2**$h - 2*$k - 6); # yes

    if ($k & 1) {
      my $j = ($k+1)/2;
      return 5*2**$j - 4*$j - 4;  # yes
      return 10*2**$h - 4*$h - 8;  # yes
      return 2*2**$h + (2*$k-2)*(2**$h-1) - 4*($h-2)*2**$h - 8;  # yes

      {
        my $r = 0;
        foreach my $i (1 .. $h-1) {      # yes
          $r += $i * 2**$i;
        }
        return 2*2**$h + (2*$k-2)*(2**$h-1)  - 4*$r;
      }
      {
        my $r = 0;
        foreach my $i (0 .. $h-1) {
          $r += (2*$k-2 - 4*$i) * 2**$i;
        }
        return 2*2**$h + $r
      }
      {
        my $r = 0;
        my $pow = 1;
        while ($k >= 3) {
          ### t: 2*$k-2
          $r += (2*$k-2) * $pow;
          $pow *= 2;
          $k -= 2;
        }
        return $r + 2*$pow;
      }
    } else {
      my $h = $k/2;

      {
        return 7*2**$h - 4*$h - 6;  # yes
        return (2*$k-1) * 2**$h - 2*$k + 2 - 4*(($h-1-1)*2**($h-1+1) + 2);
      }
      {
        # right[k] = 2k-2 + 2*right[k-2]      termwise, yes
        my $r = 0;
        foreach my $i (0 .. $h-1) {
          $r += $i*2**$i;
        }
        return (2*$k-1) * 2**$h - 2*$k + 2 - 4*$r;
      }
      {
        # right[k] = 2k-2 + 2*right[k-2]      termwise, yes
        my $r = 0;
        my $pow = 1;
        while ($k > 0) {
          $r += (2*$k-2) * $pow;
          $pow *= 2;
          $k -= 2;
        }
        return $r + $pow;
      }
      return ($h-2) *2**$h;
    }
  };

  my ($Scum_recurrence, $Zcum_recurrence, $R_recurrence);
  $Scum_recurrence = sub {
    my ($k) = @_;
    if ($k == 0) { return 0; }
    if ($k == 1) { return 0; }
    return 2*$Scum_recurrence->($k-2) + $k-1;  # yes
    return $Zcum_recurrence->($k-1);           # yes
  };
  $Zcum_recurrence = sub {
    my ($k) = @_;
    if ($k == 0) { return 0; }
    if ($k == 1) { return 1; }
    return 2*$Zcum_recurrence->($k-2) + $k; # yes
    return 2*$Scum_recurrence->($k-1) + $k; # yes
  };
  $R_recurrence = sub {
    my ($k) = @_;
    if ($k == 0) { return 1; }
    if ($k == 1) { return 2; }
    return 2*$R_recurrence->($k-2) + 2*$k-2;
  };

  for (my $k = 0; $k < 15; $k++) {
    print R_formula($k),", ";
  }
  print "\n";

  require MyOEIS;
  my $path = Math::PlanePath::CCurve->new;
  foreach my $k (0 .. 17) {
    my $n_end = 2**$k;
    my $p = MyOEIS::path_boundary_length($path, $n_end, side => 'right');
    # my $b = $B->($k);
    my $srec = $Scum_recurrence->($k);
    my $zrec = $Zcum_recurrence->($k);
    my $rszrec = $srec + $zrec + 1;
    my $rrec = $R_recurrence->($k);
    # my $t = $T->($k);
    # my $u = $U->($k);
    # my $u2 = $U2->($k);
    # my $u_lr = $U_from_LsubR->($k);
    # my $v = $V->($k);
    my ($s, $z) = path_S_and_Z($path, $n_end);
    my $r = $s + $z + 1;
    my $rformula = R_formula($k);
    my $drformula = $r - $rformula;
    # next unless $k & 1;
    print "$k $p  $s $z $r   $srec $zrec $rszrec $rrec $rformula  small by=$drformula\n";
  }
  exit 0;

  sub path_S_and_Z {
    my ($path, $n_end) = @_;
    ### path_S_and_Z(): $n_end
    my $s = 0;
    my $z = 0;
    my $x = 1;
    my $y = 0;
    my ($dx,$dy) = (1,0);
    my ($target_x,$target_y) = $path->n_to_xy($n_end);
    until ($x == $target_x && $y == $target_y) {
      ### at: "$x, $y  $dx,$dy"
      ($dx,$dy) = ($dy,-$dx); # rotate -90
      if (path_xy_is_visited_within ($path, $x+$dx,$y+$dy, $n_end)) {
        $z++;
      } else {
        ($dx,$dy) = (-$dy,$dx); # rotate +90
        if (path_xy_is_visited_within ($path, $x+$dx,$y+$dy, $n_end)) {
          $s++;
        } else {
          ($dx,$dy) = (-$dy,$dx); # rotate +90
          $z++;
          path_xy_is_visited_within ($path, $x+$dx,$y+$dy, $n_end) or die;
        }
      }
      $x += $dx;
      $y += $dy;
    }
    return ($s, $z);
  }
  sub path_xy_is_visited_within {
    my ($path, $x,$y, $n_end) = @_;
    my @n_list = $path->xy_to_n_list($x,$y);
    foreach my $n (@n_list) {
      if ($n <= $n_end) {
        return 1;
      }
    }
    return 0;
  }
}



{
  # diagonal N endpoints search
  my @values;
  foreach my $k (0 .. 10) {
    my ($n1, $n2) = diagonal_4k_axis_n_ends($k);
    my ($x1,$y1) = $path->n_to_xy ($n1);
    my ($x2,$y2) = $path->n_to_xy ($n2);

    foreach (1 .. $k) {
      ($x1,$y1) = ($y1,-$x1); # rotate -90
      ($x2,$y2) = ($y2,-$x2); # rotate -90
    }
    push @values, $n2;
    printf "$n1 xy=$x1,$y1    $n2 xy=$x2,$y2     %b %b\n", $n1, $n2;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  sub diagonal_4k_axis_n_ends {
    my ($k) = @_;
    if ($k == 0) { return (0, 2); }
    my $start = 2*(4**($k-1)-1)/3;
    return ($start, 2*4**$k - $start);
  }
}
{
  # diagonal N endpoints search
  my @values;
  foreach my $k (0 .. 10) {
    my $n_limit = 2*4**$k;
    my $dx = 1;
    my $dy = 1;
    foreach (-1 .. $k) {
      ($dx,$dy) = (-$dy,$dx); # rotate +90
    }

    my $x = 0;
    my $y = 0;
    foreach my $i (0 .. $n_limit/2) {
      my $try_x = $i*$dx;
      my $try_y = $i*$dy;
      if (my @n_list = $path->xy_to_n_list($try_x,$try_y)) {
        if ($n_list[0] <= $n_limit) {
          $x = $try_x;
          $y = $try_y;
        }
      }
    }

    # my $x = (4**$k-1)/3;
    # my $y = $x;
    # foreach (0 .. $k) {
    #   # ($x,$y) = (-$y,$x); # rotate +90
    #   ($x,$y) = (-$x,-$y); # rotate 180
    # }
    # $x = 2**($k)-1 - $x;
    # $y = $x;
    my @n_list = $path->xy_to_n_list($x,$y);
    push @values, $n_list[0];
    my $n_list_str = join(',',@n_list);
    printf "$k $n_limit  xy=$x,$y   $n_list_str  %b\n", $n_list[0];
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;
}

{
  # axis N endpoints
  my @values;
  foreach my $k (0 .. 10) {
    my ($n1, $n2) = width_4k_axis_n_ends($k);
    my ($x1,$y1) = $path->n_to_xy ($n1);
    my ($x2,$y2) = $path->n_to_xy ($n2);

    foreach (1 .. $k) {
      ($x1,$y1) = ($y1,-$x1); # rotate -90
      ($x2,$y2) = ($y2,-$x2); # rotate -90
    }
    push @values, $n2;
    printf "$n1 xy=$x1,$y1    $n2 xy=$x2,$y2     %b %b\n", $n1, $n2;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values);
  exit 0;

  # 0,1, 5,21, 85,... binary      1, 101, 10101, ...
  # (4^(k-1)-1)/3  for k>=1
  # = (4^k-4)/12
  #
  # 1,4,15,59,235,...
  # binary 1, 100, 1111, 111011, 11101011, 1110101011
  # A199210 (11*4^n+1)/3.
  # 4^k - (4^k-4)/12
  #   = (12*4^k - 4^k + 4)/12
  #   = (11*4^k + 4)/12
  #   = (11*4^(k-1) + 1)/3
  #
  sub width_4k_axis_n_ends {
    my ($k) = @_;
    if ($k == 0) { return (0, 1); }
    my $start = (4**($k-1)-1)/3;
    return ($start, 4**$k - $start);
  }
}



{
  # X,Y extents at 4^k
  my $path = Math::PlanePath::CCurve->new;
  my $x_min = 0;
  my $y_min = 0;
  my $x_max = 0;
  my $y_max = 0;
  my $target = 2;
  my @w_max;
  my @w_min;
  my @h_max;
  my @h_min;
  my $rot = 3;
  foreach my $n (0 .. 2**16) {
    my ($x,$y) = $path->n_to_xy ($n);
    $x_min = min($x+$y,$x_min);
    $x_max = max($x+$y,$x_max);
    $y_min = min($y-$x,$y_min);
    $y_max = max($y-$x,$y_max);

    if ($n == $target) {
      my $w_min = $x_min;
      my $w_max = $x_max;
      my $h_min = $y_min;
      my $h_max = $y_max;
      foreach (1 .. $rot) {
        ($w_max,$w_min, $h_max,$h_min) = ($h_max,$h_min,  -$w_min,-$w_max);
      }
      push @w_min, $w_min;
      push @h_min, $h_min;
      push @w_max, $w_max;
      push @h_max, $y_max;

      if (1) {
        printf "xy=%9b,%9b  w -%9b to %9b   h -%9b to %9b\n",
          abs($x),abs($y), abs($w_min),$w_max, abs($h_min),$h_max;
      }
      print "xy=$x,$y  w $w_min to $w_max   h $h_min to $h_max\n";
      # print "xy=$x,$y  x $x_min to $x_max   y $y_min to $y_max\n\n";
      $target *= 4;
      $rot++;
    }
  }

  require Math::OEIS::Grep;
  # Math::OEIS::Grep->search(array => \@w_min, name => "w_min");
  # Math::OEIS::Grep->search(array => \@h_min);
  # Math::OEIS::Grep->search(array => \@w_max);
  shift @h_max;
  shift @h_max;
  Math::OEIS::Grep->search(array => \@h_max, name => "h_max");
  exit 0;
}

{
  # X,Y to N by dividing
  #
  #   *--*
  #      |
  #   *  *             0,1   1,1
  #      |
  #   *==*      -1,0   0,0   1,0
  #      |
  #   *  *             0,-1  1,-1
  #      |
  #   *--*
  #
  my $path = Math::PlanePath::CCurve->new;
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);
  my @dir4_to_ds = ( 1, 1, -1, -1); # ds = dx+dy
  my @dir4_to_dd = (-1, 1,  1, -1); # ds = dy-dx

  my $n_at = 1727;
  my ($x,$y) = $path->n_to_xy ($n_at);
  print "n=$n_at   $x,$y\n";

  my @n_list;
  my $n_list_str = '';
  foreach my $anti (0) {
    foreach my $dir (0, 1, 2, 3) {
      print "dir=$dir  anti=$anti\n";
      my $dx = $dir4_to_dx[$dir];
      my $dy = $dir4_to_dy[$dir];
      my $arm = 0;

      my ($x,$y) = ($x,$y);
      my $s = $x + $y;
      my $d = $y - $x;
      my $ds = $dir4_to_ds[$dir];
      my $dd = $dir4_to_dd[$dir];
      my @nbits;
      for (;;) {
        my $nbits = join('',reverse @nbits);
        print "$x,$y  bit=",$s%2,"   $nbits\n";

        if ($s >= -1 && $s <= 1 && $d >= -1 && $d <= 1) {
          # five final positions
          #      .   0,1   .       ds,dd
          #           |
          #    -1,0--0,0--1,0
          #           |
          #      .   0,-1  .
          #
          if ($s == $ds && $d == $dd) {
            push @nbits, 1;
            $s -= $ds;
            $d -= $dd;
          }
          if ($s==0 && $d==0) {
            my $n = digit_join_lowtohigh(\@nbits, 2, 0);
            my $nbits = join('',reverse @nbits);
            print "n=$nbits = $n\n";
            push @n_list, $n;
            $n_list_str .= "${n}[dir=$dir,anti=$anti], ";
            last;
          }

          $arm += dxdy_to_dir4($x,$y);
          print "not found, arm=$arm\n";
          last;
        }

        my $bit = $s % 2;
        push @nbits, $bit;
        if ($bit) {
          # if (($x == 0 && ($y == 1 || $y == -1))
          #     || ($y == 0 && ($x == 1 || $x == -1))) {
          #   if ($x != $dx || $y != $dy) {
          $x -= $dx;
          $y -= $dy;
          # $s -= ($dx + $dy);
          # $d -= ($dy - $dx);
          $s -= $ds;
          $d -= $dd;
          ($dx,$dy) = ($dy,-$dx); # rotate -90
          ($ds,$dd) = ($dd,-$ds); # rotate -90
          $arm++;
        }

        # undo expand on right, normal curl anti-clockwise:
        # divide i+1 = mul (i-1)/(i^2 - 1^2)
        #            = mul (i-1)/-2
        # is (i*y + x) * (i-1)/-2
        #  x = (-x - y)/-2  = (x + y)/2
        #  y = (-y + x)/-2  = (y - x)/2
        #
        # undo expand on left, curl clockwise:
        # divide 1-i = mul (1+i)/(1 - i^2)
        #            = mul (1+i)/2
        # is (i*y + x) * (i+1)/2
        #  x = (x - y)/2
        #  y = (y + x)/2
        #
        ### assert: (($x+$y)%2)==0
        ($x,$y) = ($anti ? ($d/-2, $s/2)     : ($s/2, $d/2));

        ($s,$d) = (($s + $d)/2, ($d - $s)/2);

        last if @nbits > 20;
      }
      print "\n";
    }
  }
  print "$n_list_str\n";
  print join(', ', @n_list),"\n";
  @n_list = sort {$a<=>$b} @n_list;
  print join(', ', @n_list),"\n";
  foreach my $n (@n_list) {
    my $count = count_1_bits($n) % 4;
    printf "%b  %d\n", $n, $count;
  }
  exit 0;

  sub dxdy_to_dir4 {
    my ($dx, $dy) = @_;
    if ($dx > 0) { return 0; }  # east
    if ($dx < 0) { return 2; }  # west
    if ($dy > 0) { return 1; }  # north
    if ($dy < 0) { return 3; }  # south
  }

  # S=X+Y   S = S
  # D=Y-X   Y = (S+D)/2
  #
  # S=X+Y
  # X=S-Y
  #
  # newX,newY = (X+Y)/2, (Y-X)/2
  #           = (S-Y+Y)/2, (Y-(S-Y))/2
  #           = S/2, (Y-S+Y)/2
  #           = S/2, (2Y-S)/2
  # newS = S/2 + (2Y-S)/2
  #      = Y
  # newY = (2Y-S)/2
}

{
  # arms visits

  my $k = 3;
  my $path = Math::PlanePath::CCurve->new;
  my $n_hi = 256  * 8 ** $k;
  my $len = 2 ** $k;

  my @points;
  my $plot = sub {
    my ($x,$y, $n) = @_;
    ### plot: "$x,$y"

    if ($x == 0 && $y == 0) {
      $points[$x][$y] = '8';
    }
    if ($x >= 0 && $x <= 2*$len
        && $y >= 0 && $y <= 2*$len) {
      # $points[$x][$y] .= sprintf '%d,', $n;
      $points[$x][$y] .= sprintf '*', $n;
    }
  };

  foreach my $n (0 .. $n_hi) {
    my ($x,$y) = $path->n_to_xy ($n);
    foreach (0, 1) {
      foreach (1 .. 4) {
        ($x,$y) = (-$y,$x); # rotate +90
        $plot->($x, $y, $n);
      }
      $y = -$y;
    }
  }

  foreach my $y (reverse 0 .. 2*$len) {
    printf "%2d: ", $y;
    foreach my $x (0 .. 2*$len) {
      printf ' %4s', $points[$x][$y] // '-';
    }
    print "\n";
  }
  printf "    ";
  foreach my $x (0 .. 2*$len) {
    printf ' %4s', $x;
  }
  print "\n";

  exit 0;
}

{
  # quad point visits by tiling

  #     *------*-----*
  #     |            |
  #    N=4^k        N=0
  #
  # 4 inward square, 4 outward square

  my $k = 3;
  my $path = Math::PlanePath::CCurve->new;
  my $len = 2 ** $k;
  my $rot = (2 - $k) % 4;
  ### $rot

  my @points;
  my $plot = sub {
    my ($x,$y, $n) = @_;
    ### plot: "$x,$y"

    if ($x >= 0 && $x <= 2*$len
        && $y >= 0 && $y <= 2*$len) {
      # $points[$x][$y] .= sprintf '%d,', $n;
      $points[$x][$y] .= sprintf '*', $n;
    }
  };

  foreach my $n (0 .. 4**$k-1) {
    my ($x,$y) = $path->n_to_xy ($n);
    ### at: "$x,$y n=$n"
    foreach (1 .. $rot) {
      ($x,$y) = (-$y,$x); # rotate +90
    }
    ### rotate to: "$x,$y"
    $x += $len;
    ### X shift to: "$x,$y"

    foreach my $x_offset (0, $len,  #  -$len,
                         ) {
      foreach my $y_offset (0, $len, #  -$len,
                           ) {

        ### horiz: "$x,$y"
        $plot->($x+$x_offset, $y+$y_offset, $n);
        { my ($x,$y) = (-$x,-$y); # rotate 180
          $x += $len;
          ### rotated: "$x,$y"
          $plot->($x+$x_offset,$y+$y_offset, $n);
        }

        my ($x,$y) = (-$y,$x); # rotate +90
        # ### vert: "$x,$y"
        $plot->($x+$x_offset,$y+$y_offset, $n);
        { my ($x,$y) = (-$x,-$y); # rotate 180
          $y += $len;
          # ### rotated: "$x,$y"
          $plot->($x+$x_offset,$y+$y_offset, $n);
        }
      }
    }
  }

  foreach my $y (reverse 0 .. 2*$len) {
    printf "%2d: ", $y;
    foreach my $x (0 .. 2*$len) {
      printf ' %4s', $points[$x][$y] // '-';
    }
    print "\n";
  }
  exit 0;
}

{
  # repeat points
  my $path = Math::PlanePath::CCurve->new;
  my %seen;
  my @first;
  foreach my $n (0 .. 2**16 - 1) {
    my ($x, $y) = $path->n_to_xy ($n);
    my $xy = "$x,$y";
    my $count = ++$seen{$xy};
    if (! $first[$count]) {
      $first[$count] = $xy;
      printf "count=%d first N=%d %b\n", $count, $n,$n;
    }
  }

  ### @first
  foreach my $xy (@first) {
    $xy or next;
    my ($x,$y) = split /,/, $xy;
    my @n_list = $path->xy_to_n_list($x,$y);
    print "$xy  N=",join(', ',@n_list),"\n";
  }

  my @count;
  while (my ($key,$visits) = each %seen) {
    $count[$visits]++;
    if ($visits > 4) {
      print "$key    $visits\n";
    }
  }
  ### @count


  exit 0;
}
{
  # repeat edges
  my $path = Math::PlanePath::CCurve->new;
  my ($prev_x,$prev_y) = $path->n_to_xy (0);
  my %seen;
  foreach my $n (1 .. 2**24 - 1) {
    my ($x, $y) = $path->n_to_xy ($n);
    my $min_x = min($x,$prev_x);
    my $min_y = min($y,$prev_y);
    my $max_x = max($x,$prev_x);
    my $max_y = max($y,$prev_y);
    my $xy = "$min_x,$min_y--$max_x,$max_y";
    my $count = ++$seen{$xy};
    if ($count > 2) {
      printf "count=%d third N=%d %b\n", $count, $n,$n;
    }
    $prev_x = $x;
    $prev_y = $y;
  }
  exit 0;
}
{
  # A047838     1, 3, 7, 11, 17, 23, 31, 39, 49, 59, 71, 83, 97, 111, 127, 143,
  # A080827  1, 3, 5, 9, 13, 19, 25, 33, 41, 51, 61, 73, 85, 99, 113, 129,

  require Image::Base::Text;
  my $width = 60;
  my $height = 30;
  my $w2 = int(($width+1)/2);
  my $h2 = int($height/2);
  my $image = Image::Base::Text->new (-width => $width,
                                      -height => $height);
  my $x = $w2;
  my $y = $h2;
  my $dx = 1;
  my $dy = 0;
  foreach my $i (2 .. 102) {
    $image->xy($x,$y,'*');
    if ($dx) {
      $x += $dx;
      $image->xy($x,$y,'-');
      $x += $dx;
      $image->xy($x,$y,'-');
      $x += $dx;
    } else {
      $y += $dy;
      $image->xy($x,$y,'|');
      $y += $dy;
    }
    my $value = A080827_pred($i);
    if (! $value) {
      if ($i & 1) {
        ($dx,$dy) = ($dy,-$dx);
      } else {
        ($dx,$dy) = (-$dy,$dx);
      }
    }
  }
  $image->save('/dev/stdout');
  exit 0;
}




{
  # _rect_to_level()
  require Math::PlanePath::CCurve;
  foreach my $x (0 .. 16) {
    my ($len,$level) = Math::PlanePath::CCurve::_rect_to_level(0,0,$x,0);
    $len = $len*$len-1;
    print "$x  $len $level\n";
  }
  foreach my $x (0 .. 16) {
    my ($len,$level) = Math::PlanePath::CCurve::_rect_to_level(0,0,0,$x);
    $len = $len*$len-1;
    print "$x  $len $level\n";
  }
  foreach my $x (0 .. 16) {
    my ($len,$level) = Math::PlanePath::CCurve::_rect_to_level(0,0,-$x,0);
    $len = $len*$len-1;
    print "$x  $len $level\n";
  }
  foreach my $x (0 .. 16) {
    my ($len,$level) = Math::PlanePath::CCurve::_rect_to_level(0,0,0,-$x);
    $len = $len*$len-1;
    print "$x  $len $level\n";
  }
  exit 0;
}


__END__

w[   0] = 0
w[   1] - (w[1020]/2 + w[2080]/2) = 0
w[   2] = w[1000]/2/2/2/2
w[   4] - (w[ 840]/2 + w[ 408]/2) = 0
w[   6] - (w[4840]/2 + w[ 408]/2) = 0
w[   7] - (w[5860]/2 + w[2488]/2) = 0
w[   8] - (w[ 104]/2 + w[4040]/2) = 0
w[  10] = w[2000]/2/2/2/2
w[  18] - (w[ 104]/2 + w[4840]/2) = 0
w[  19] - (w[1124]/2 + w[68C0]/2) = 0
w[  20] = w[2000]/2
w[  22] = w[6000]/2
w[  23] - (w[7020]/2 + w[2080]/2) = 0
w[  40] - (w[ 202]/2 + w[ 210]/2) = 0
w[  80] = w[1000]/2
w[  90] - (w[1800]/2) = 0
w[  91] - (w[1020]/2 + w[3880]/2) = 0
w[ 100] = w[1000]/2/2
w[ 104] - (w[ 8C0]/2 + w[ 408]/2) = 0
w[ 105] - (w[18E0]/2 + w[2488]/2) = 0
w[ 11C] - (w[ 9C4]/2 + w[4C48]/2) = 0
w[ 11D] - (w[19E4]/2 + w[6CC8]/2) = 0
w[ 120] = w[2080]/2
w[ 121] - (w[30A0]/2 + w[2080]/2) = 0
w[ 126] - (w[68C0]/2 + w[ 408]/2) = 0
w[ 127] - (w[78E0]/2 + w[2488]/2) = 0
w[ 194] - (w[ 8C0]/2 + w[1C08]/2) = 0
w[ 195] - (w[18E0]/2 + w[3C88]/2) = 0
w[ 200] - (w[2000]/2/2/2/2/2 + w[1000]/2/2/2/2/2) = 0
w[ 202] - (w[1020]/2/2/2/2 + w[1000]/2/2/2/2/2) = 0
w[ 210] - (w[2000]/2/2/2/2/2 + w[4400]/2/2) = 0
w[ 212] - (w[1020]/2/2/2/2 + w[4400]/2/2) = 0
w[ 213] - (w[5030]/2 + w[2882]/2) = 0
w[ 310] - (w[  90]/2 + w[4400]/2/2) = 0
w[ 311] - (w[10B0]/2 + w[2882]/2) = 0
w[ 316] - (w[48D0]/2 + w[ C0A]/2) = 0
w[ 317] - (w[58F0]/2 + w[2C8A]/2) = 0
w[ 400] = w[2000]/2/2
w[ 408] - (w[ 104]/2 + w[4060]/2) = 0
w[ 409] - (w[1124]/2 + w[60E0]/2) = 0
w[ 40E] - (w[4944]/2 + w[4468]/2) = 0
w[ 40F] - (w[5964]/2 + w[64E8]/2) = 0
w[ 42A] - (w[6104]/2 + w[4060]/2) = 0
w[ 42B] - (w[7124]/2 + w[60E0]/2) = 0
w[ 480] = w[1020]/2
w[ 481] - (w[1020]/2 + w[30A0]/2) = 0
w[ 498] - (w[ 104]/2 + w[5860]/2) = 0
w[ 499] - (w[1124]/2 + w[78E0]/2) = 0
w[ 50C] - (w[ 9C4]/2 + w[4468]/2) = 0
w[ 50D] - (w[19E4]/2 + w[64E8]/2) = 0
w[ 528] - (w[2184]/2 + w[4060]/2) = 0
w[ 529] - (w[31A4]/2 + w[60E0]/2) = 0
w[ 52E] - (w[69C4]/2 + w[4468]/2) = 0
w[ 52F] - (w[79E4]/2 + w[64E8]/2) = 0
w[ 584] - (w[ 8C0]/2 + w[1428]/2) = 0
w[ 585] - (w[18E0]/2 + w[34A8]/2) = 0
w[ 59C] - (w[ 9C4]/2 + w[5C68]/2) = 0
w[ 59D] - (w[19E4]/2 + w[7CE8]/2) = 0
w[ 602] - (w[1020]/2/2/2/2 + w[6000]/2/2) = 0
w[ 603] - (w[5030]/2 + w[20A2]/2) = 0
w[ 61A] - (w[4114]/2 + w[4862]/2) = 0
w[ 61B] - (w[5134]/2 + w[68E2]/2) = 0
w[ 706] - (w[48D0]/2 + w[ 42A]/2) = 0
w[ 707] - (w[58F0]/2 + w[24AA]/2) = 0
w[ 718] - (w[ 194]/2 + w[4862]/2) = 0
w[ 719] - (w[11B4]/2 + w[68E2]/2) = 0
w[ 71E] - (w[49D4]/2 + w[4C6A]/2) = 0
w[ 71F] - (w[59F4]/2 + w[6CEA]/2) = 0
w[ 800] = w[2000]/2/2/2
w[ 802] = w[4400]/2
w[ 803] - (w[5420]/2 + w[2080]/2) = 0
w[ 840] - (w[ 602]/2 + w[ 210]/2) = 0
w[ 848] - (w[ 706]/2 + w[4250]/2) = 0
w[ 849] - (w[1726]/2 + w[62D0]/2) = 0
w[ 8C0] - (w[ 602]/2 + w[1210]/2) = 0
w[ 8C1] - (w[1622]/2 + w[3290]/2) = 0
w[ 8D8] - (w[ 706]/2 + w[5A50]/2) = 0
w[ 8D9] - (w[1726]/2 + w[7AD0]/2) = 0
w[ 900] = w[1020]/2/2
w[ 901] - (w[14A0]/2 + w[2080]/2) = 0
w[ 922] = w[6480]/2
w[ 923] - (w[74A0]/2 + w[2080]/2) = 0
w[ 94C] - (w[ FC6]/2 + w[4658]/2) = 0
w[ 94D] - (w[1FE6]/2 + w[66D8]/2) = 0
w[ 9C4] - (w[ EC2]/2 + w[1618]/2) = 0
w[ 9C5] - (w[1EE2]/2 + w[3698]/2) = 0
w[ 9DC] - (w[ FC6]/2 + w[5E58]/2) = 0
w[ 9DD] - (w[1FE6]/2 + w[7ED8]/2) = 0
w[ A42] - (w[4612]/2 + w[ 212]/2) = 0
w[ A43] - (w[5632]/2 + w[2292]/2) = 0
w[ A5A] - (w[4716]/2 + w[4A52]/2) = 0
w[ A5B] - (w[5736]/2 + w[6AD2]/2) = 0
w[ B12] - (w[4490]/2 + w[4400]/2/2) = 0
w[ B13] - (w[54B0]/2 + w[2882]/2) = 0
w[ B46] - (w[4ED2]/2 + w[ 61A]/2) = 0
w[ B47] - (w[5EF2]/2 + w[269A]/2) = 0
w[ B5E] - (w[4FD6]/2 + w[4E5A]/2) = 0
w[ B5F] - (w[5FF6]/2 + w[6EDA]/2) = 0
w[ C0A] - (w[4504]/2 + w[4060]/2) = 0
w[ C0B] - (w[5524]/2 + w[60E0]/2) = 0
w[ D08] - (w[ 584]/2 + w[4060]/2) = 0
w[ D09] - (w[15A4]/2 + w[60E0]/2) = 0
w[ D2A] - (w[6584]/2 + w[4060]/2) = 0
w[ D2B] - (w[75A4]/2 + w[60E0]/2) = 0
w[ EC2] - (w[4612]/2 + w[1232]/2) = 0
w[ EC3] - (w[5632]/2 + w[32B2]/2) = 0
w[ EDA] - (w[4716]/2 + w[5A72]/2) = 0
w[ EDB] - (w[5736]/2 + w[7AF2]/2) = 0
w[ F1A] - (w[4594]/2 + w[4862]/2) = 0
w[ F1B] - (w[55B4]/2 + w[68E2]/2) = 0
w[ FC6] - (w[4ED2]/2 + w[163A]/2) = 0
w[ FC7] - (w[5EF2]/2 + w[36BA]/2) = 0
w[ FDE] - (w[4FD6]/2 + w[5E7A]/2) = 0
w[ FDF] - (w[5FF6]/2 + w[7EFA]/2) = 0
w[1000] - (w[   8]/2 + w[   1]/2) = 0
w[1004] - (w[ 848]/2 + w[ 409]/2) = 0
w[1005] - (w[1868]/2 + w[2489]/2) = 0
w[1020] - (w[2008]/2 + w[   1]/2) = 0
w[1021] - (w[3028]/2 + w[2081]/2) = 0
w[1038] - (w[210C]/2 + w[4841]/2) = 0
w[1039] - (w[312C]/2 + w[68C1]/2) = 0
w[10B0] - (w[2008]/2 + w[1801]/2) = 0
w[10B1] - (w[3028]/2 + w[3881]/2) = 0
w[1124] - (w[28C8]/2 + w[ 409]/2) = 0
w[1125] - (w[38E8]/2 + w[2489]/2) = 0
w[113C] - (w[29CC]/2 + w[4C49]/2) = 0
w[113D] - (w[39EC]/2 + w[6CC9]/2) = 0
w[11B4] - (w[28C8]/2 + w[1C09]/2) = 0
w[11B5] - (w[38E8]/2 + w[3C89]/2) = 0
w[1210] - (w[  18]/2 + w[ 803]/2) = 0
w[1211] - (w[1038]/2 + w[2883]/2) = 0
w[1232] - (w[6018]/2 + w[ 803]/2) = 0
w[1233] - (w[7038]/2 + w[2883]/2) = 0
w[1314] - (w[ 8D8]/2 + w[ C0B]/2) = 0
w[1315] - (w[18F8]/2 + w[2C8B]/2) = 0
w[1336] - (w[68D8]/2 + w[ C0B]/2) = 0
w[1337] - (w[78F8]/2 + w[2C8B]/2) = 0
w[140C] - (w[ 94C]/2 + w[4469]/2) = 0
w[140D] - (w[196C]/2 + w[64E9]/2) = 0
w[1428] - (w[210C]/2 + w[4061]/2) = 0
w[1429] - (w[312C]/2 + w[60E1]/2) = 0
w[14A0] - (w[2008]/2 + w[1021]/2) = 0
w[14A1] - (w[3028]/2 + w[30A1]/2) = 0
w[14B8] - (w[210C]/2 + w[5861]/2) = 0
w[14B9] - (w[312C]/2 + w[78E1]/2) = 0
w[152C] - (w[29CC]/2 + w[4469]/2) = 0
w[152D] - (w[39EC]/2 + w[64E9]/2) = 0
w[15A4] - (w[28C8]/2 + w[1429]/2) = 0
w[15A5] - (w[38E8]/2 + w[34A9]/2) = 0
w[15BC] - (w[29CC]/2 + w[5C69]/2) = 0
w[15BD] - (w[39EC]/2 + w[7CE9]/2) = 0
w[1618] - (w[ 11C]/2 + w[4863]/2) = 0
w[1619] - (w[113C]/2 + w[68E3]/2) = 0
w[1622] - (w[6018]/2 + w[  23]/2) = 0
w[1623] - (w[7038]/2 + w[20A3]/2) = 0
w[163A] - (w[611C]/2 + w[4863]/2) = 0
w[163B] - (w[713C]/2 + w[68E3]/2) = 0
w[171C] - (w[ 9DC]/2 + w[4C6B]/2) = 0
w[171D] - (w[19FC]/2 + w[6CEB]/2) = 0
w[1726] - (w[68D8]/2 + w[ 42B]/2) = 0
w[1727] - (w[78F8]/2 + w[24AB]/2) = 0
w[173E] - (w[69DC]/2 + w[4C6B]/2) = 0
w[173F] - (w[79FC]/2 + w[6CEB]/2) = 0
w[1800] - (w[ 408]/2 + w[   1]/2) = 0
w[1801] - (w[1428]/2 + w[2081]/2) = 0
w[1806] - (w[4C48]/2 + w[ 409]/2) = 0
w[1807] - (w[5C68]/2 + w[2489]/2) = 0
w[1868] - (w[270E]/2 + w[4251]/2) = 0
w[1869] - (w[372E]/2 + w[62D1]/2) = 0
w[18E0] - (w[260A]/2 + w[1211]/2) = 0
w[18E1] - (w[362A]/2 + w[3291]/2) = 0
w[18F8] - (w[270E]/2 + w[5A51]/2) = 0
w[18F9] - (w[372E]/2 + w[7AD1]/2) = 0
w[1920] - (w[2488]/2 + w[   1]/2) = 0
w[1921] - (w[34A8]/2 + w[2081]/2) = 0
w[1926] - (w[6CC8]/2 + w[ 409]/2) = 0
w[1927] - (w[7CE8]/2 + w[2489]/2) = 0
w[196C] - (w[2FCE]/2 + w[4659]/2) = 0
w[196D] - (w[3FEE]/2 + w[66D9]/2) = 0
w[19E4] - (w[2ECA]/2 + w[1619]/2) = 0
w[19E5] - (w[3EEA]/2 + w[3699]/2) = 0
w[19FC] - (w[2FCE]/2 + w[5E59]/2) = 0
w[19FD] - (w[3FEE]/2 + w[7ED9]/2) = 0
w[1A62] - (w[661A]/2 + w[ 213]/2) = 0
w[1A63] - (w[763A]/2 + w[2293]/2) = 0
w[1A7A] - (w[671E]/2 + w[4A53]/2) = 0
w[1A7B] - (w[773E]/2 + w[6AD3]/2) = 0
w[1B10] - (w[ 498]/2 + w[ 803]/2) = 0
w[1B11] - (w[14B8]/2 + w[2883]/2) = 0
w[1B16] - (w[4CD8]/2 + w[ C0B]/2) = 0
w[1B17] - (w[5CF8]/2 + w[2C8B]/2) = 0
w[1B32] - (w[6498]/2 + w[ 803]/2) = 0
w[1B33] - (w[74B8]/2 + w[2883]/2) = 0
w[1B66] - (w[6EDA]/2 + w[ 61B]/2) = 0
w[1B67] - (w[7EFA]/2 + w[269B]/2) = 0
w[1B7E] - (w[6FDE]/2 + w[4E5B]/2) = 0
w[1B7F] - (w[7FFE]/2 + w[6EDB]/2) = 0
w[1C08] - (w[ 50C]/2 + w[4061]/2) = 0
w[1C09] - (w[152C]/2 + w[60E1]/2) = 0
w[1C0E] - (w[4D4C]/2 + w[4469]/2) = 0
w[1C0F] - (w[5D6C]/2 + w[64E9]/2) = 0
w[1D28] - (w[258C]/2 + w[4061]/2) = 0
w[1D29] - (w[35AC]/2 + w[60E1]/2) = 0
w[1D2E] - (w[6DCC]/2 + w[4469]/2) = 0
w[1D2F] - (w[7DEC]/2 + w[64E9]/2) = 0
w[1EE2] - (w[661A]/2 + w[1233]/2) = 0
w[1EE3] - (w[763A]/2 + w[32B3]/2) = 0
w[1EFA] - (w[671E]/2 + w[5A73]/2) = 0
w[1EFB] - (w[773E]/2 + w[7AF3]/2) = 0
w[1F18] - (w[ 59C]/2 + w[4863]/2) = 0
w[1F19] - (w[15BC]/2 + w[68E3]/2) = 0
w[1F1E] - (w[4DDC]/2 + w[4C6B]/2) = 0
w[1F1F] - (w[5DFC]/2 + w[6CEB]/2) = 0
w[1F3A] - (w[659C]/2 + w[4863]/2) = 0
w[1F3B] - (w[75BC]/2 + w[68E3]/2) = 0
w[1FE6] - (w[6EDA]/2 + w[163B]/2) = 0
w[1FE7] - (w[7EFA]/2 + w[36BB]/2) = 0
w[1FFE] - (w[6FDE]/2 + w[5E7B]/2) = 0
w[1FFF] - (w[7FFE]/2 + w[7EFB]/2) = 0
w[2000] - (w[   1]/2 + w[   4]/2) = 0
w[2008] - (w[ 105]/2 + w[4044]/2) = 0
w[2009] - (w[1125]/2 + w[60C4]/2) = 0
w[2080] - (w[   1]/2 + w[1004]/2) = 0
w[2081] - (w[1021]/2 + w[3084]/2) = 0
w[2086] - (w[4841]/2 + w[140C]/2) = 0
w[2087] - (w[5861]/2 + w[348C]/2) = 0
w[20A2] - (w[6001]/2 + w[1004]/2) = 0
w[20A3] - (w[7021]/2 + w[3084]/2) = 0
w[210C] - (w[ 9C5]/2 + w[444C]/2) = 0
w[210D] - (w[19E5]/2 + w[64CC]/2) = 0
w[2184] - (w[ 8C1]/2 + w[140C]/2) = 0
w[2185] - (w[18E1]/2 + w[348C]/2) = 0
w[21A0] - (w[2081]/2 + w[1004]/2) = 0
w[21A1] - (w[30A1]/2 + w[3084]/2) = 0
w[21A6] - (w[68C1]/2 + w[140C]/2) = 0
w[21A7] - (w[78E1]/2 + w[348C]/2) = 0
w[2202] - (w[4011]/2 + w[   6]/2) = 0
w[2203] - (w[5031]/2 + w[2086]/2) = 0
w[2292] - (w[4011]/2 + w[1806]/2) = 0
w[2293] - (w[5031]/2 + w[3886]/2) = 0
w[2306] - (w[48D1]/2 + w[ 40E]/2) = 0
w[2307] - (w[58F1]/2 + w[248E]/2) = 0
w[2390] - (w[  91]/2 + w[1806]/2) = 0
w[2391] - (w[10B1]/2 + w[3886]/2) = 0
w[2396] - (w[48D1]/2 + w[1C0E]/2) = 0
w[2397] - (w[58F1]/2 + w[3C8E]/2) = 0
w[2488] - (w[ 105]/2 + w[5064]/2) = 0
w[2489] - (w[1125]/2 + w[70E4]/2) = 0
w[248E] - (w[4945]/2 + w[546C]/2) = 0
w[248F] - (w[5965]/2 + w[74EC]/2) = 0
w[24AA] - (w[6105]/2 + w[5064]/2) = 0
w[24AB] - (w[7125]/2 + w[70E4]/2) = 0
w[258C] - (w[ 9C5]/2 + w[546C]/2) = 0
w[258D] - (w[19E5]/2 + w[74EC]/2) = 0
w[25A8] - (w[2185]/2 + w[5064]/2) = 0
w[25A9] - (w[31A5]/2 + w[70E4]/2) = 0
w[25AE] - (w[69C5]/2 + w[546C]/2) = 0
w[25AF] - (w[79E5]/2 + w[74EC]/2) = 0
w[260A] - (w[4115]/2 + w[4066]/2) = 0
w[260B] - (w[5135]/2 + w[60E6]/2) = 0
w[269A] - (w[4115]/2 + w[5866]/2) = 0
w[269B] - (w[5135]/2 + w[78E6]/2) = 0
w[270E] - (w[49D5]/2 + w[446E]/2) = 0
w[270F] - (w[59F5]/2 + w[64EE]/2) = 0
w[2798] - (w[ 195]/2 + w[5866]/2) = 0
w[2799] - (w[11B5]/2 + w[78E6]/2) = 0
w[279E] - (w[49D5]/2 + w[5C6E]/2) = 0
w[279F] - (w[59F5]/2 + w[7CEE]/2) = 0
w[2882] - (w[4401]/2 + w[1004]/2) = 0
w[2883] - (w[5421]/2 + w[3084]/2) = 0
w[28C8] - (w[ 707]/2 + w[5254]/2) = 0
w[28C9] - (w[1727]/2 + w[72D4]/2) = 0
w[2980] - (w[ 481]/2 + w[1004]/2) = 0
w[2981] - (w[14A1]/2 + w[3084]/2) = 0
w[29A2] - (w[6481]/2 + w[1004]/2) = 0
w[29A3] - (w[74A1]/2 + w[3084]/2) = 0
w[29CC] - (w[ FC7]/2 + w[565C]/2) = 0
w[29CD] - (w[1FE7]/2 + w[76DC]/2) = 0
w[2A4A] - (w[4717]/2 + w[4256]/2) = 0
w[2A4B] - (w[5737]/2 + w[62D6]/2) = 0
w[2ADA] - (w[4717]/2 + w[5A56]/2) = 0
w[2ADB] - (w[5737]/2 + w[7AD6]/2) = 0
w[2B4E] - (w[4FD7]/2 + w[465E]/2) = 0
w[2B4F] - (w[5FF7]/2 + w[66DE]/2) = 0
w[2B92] - (w[4491]/2 + w[1806]/2) = 0
w[2B93] - (w[54B1]/2 + w[3886]/2) = 0
w[2BDE] - (w[4FD7]/2 + w[5E5E]/2) = 0
w[2BDF] - (w[5FF7]/2 + w[7EDE]/2) = 0
w[2C8A] - (w[4505]/2 + w[5064]/2) = 0
w[2C8B] - (w[5525]/2 + w[70E4]/2) = 0
w[2D88] - (w[ 585]/2 + w[5064]/2) = 0
w[2D89] - (w[15A5]/2 + w[70E4]/2) = 0
w[2DAA] - (w[6585]/2 + w[5064]/2) = 0
w[2DAB] - (w[75A5]/2 + w[70E4]/2) = 0
w[2ECA] - (w[4717]/2 + w[5276]/2) = 0
w[2ECB] - (w[5737]/2 + w[72F6]/2) = 0
w[2F9A] - (w[4595]/2 + w[5866]/2) = 0
w[2F9B] - (w[55B5]/2 + w[78E6]/2) = 0
w[2FCE] - (w[4FD7]/2 + w[567E]/2) = 0
w[2FCF] - (w[5FF7]/2 + w[76FE]/2) = 0
w[3028] - (w[210D]/2 + w[4045]/2) = 0
w[3029] - (w[312D]/2 + w[60C5]/2) = 0
w[3084] - (w[ 849]/2 + w[140D]/2) = 0
w[3085] - (w[1869]/2 + w[348D]/2) = 0
w[30A0] - (w[2009]/2 + w[1005]/2) = 0
w[30A1] - (w[3029]/2 + w[3085]/2) = 0
w[312C] - (w[29CD]/2 + w[444D]/2) = 0
w[312D] - (w[39ED]/2 + w[64CD]/2) = 0
w[31A4] - (w[28C9]/2 + w[140D]/2) = 0
w[31A5] - (w[38E9]/2 + w[348D]/2) = 0
w[3222] - (w[6019]/2 + w[   7]/2) = 0
w[3223] - (w[7039]/2 + w[2087]/2) = 0
w[3290] - (w[  19]/2 + w[1807]/2) = 0
w[3291] - (w[1039]/2 + w[3887]/2) = 0
w[32B2] - (w[6019]/2 + w[1807]/2) = 0
w[32B3] - (w[7039]/2 + w[3887]/2) = 0
w[3326] - (w[68D9]/2 + w[ 40F]/2) = 0
w[3327] - (w[78F9]/2 + w[248F]/2) = 0
w[3394] - (w[ 8D9]/2 + w[1C0F]/2) = 0
w[3395] - (w[18F9]/2 + w[3C8F]/2) = 0
w[33B6] - (w[68D9]/2 + w[1C0F]/2) = 0
w[33B7] - (w[78F9]/2 + w[3C8F]/2) = 0
w[348C] - (w[ 94D]/2 + w[546D]/2) = 0
w[348D] - (w[196D]/2 + w[74ED]/2) = 0
w[34A8] - (w[210D]/2 + w[5065]/2) = 0
w[34A9] - (w[312D]/2 + w[70E5]/2) = 0
w[35AC] - (w[29CD]/2 + w[546D]/2) = 0
w[35AD] - (w[39ED]/2 + w[74ED]/2) = 0
w[362A] - (w[611D]/2 + w[4067]/2) = 0
w[362B] - (w[713D]/2 + w[60E7]/2) = 0
w[3698] - (w[ 11D]/2 + w[5867]/2) = 0
w[3699] - (w[113D]/2 + w[78E7]/2) = 0
w[36BA] - (w[611D]/2 + w[5867]/2) = 0
w[36BB] - (w[713D]/2 + w[78E7]/2) = 0
w[372E] - (w[69DD]/2 + w[446F]/2) = 0
w[372F] - (w[79FD]/2 + w[64EF]/2) = 0
w[379C] - (w[ 9DD]/2 + w[5C6F]/2) = 0
w[379D] - (w[19FD]/2 + w[7CEF]/2) = 0
w[37BE] - (w[69DD]/2 + w[5C6F]/2) = 0
w[37BF] - (w[79FD]/2 + w[7CEF]/2) = 0
w[3880] - (w[ 409]/2 + w[1005]/2) = 0
w[3881] - (w[1429]/2 + w[3085]/2) = 0
w[3886] - (w[4C49]/2 + w[140D]/2) = 0
w[3887] - (w[5C69]/2 + w[348D]/2) = 0
w[38E8] - (w[270F]/2 + w[5255]/2) = 0
w[38E9] - (w[372F]/2 + w[72D5]/2) = 0
w[39A0] - (w[2489]/2 + w[1005]/2) = 0
w[39A1] - (w[34A9]/2 + w[3085]/2) = 0
w[39A6] - (w[6CC9]/2 + w[140D]/2) = 0
w[39A7] - (w[7CE9]/2 + w[348D]/2) = 0
w[39EC] - (w[2FCF]/2 + w[565D]/2) = 0
w[39ED] - ((1/2 + ((1/2 + w[6FDF]/2)/2 + 1/2)/2)/2 + (w[1B7F]/2 + 1/2)/2) = 0
w[3A6A] - (w[671F]/2 + w[4257]/2) = 0
w[3A6B] - (w[773F]/2 + w[62D7]/2) = 0
w[3AFA] - (w[671F]/2 + w[5A57]/2) = 0
w[3AFB] - (w[773F]/2 + w[7AD7]/2) = 0
w[3B6E] - (w[6FDF]/2 + w[465F]/2) = 0
w[3B6F] - (1/2 + w[66DF]/2) = 0
w[3B90] - (w[ 499]/2 + w[1807]/2) = 0
w[3B91] - (w[14B9]/2 + w[3887]/2) = 0
w[3B96] - (w[4CD9]/2 + w[1C0F]/2) = 0
w[3B97] - (w[5CF9]/2 + w[3C8F]/2) = 0
w[3BB2] - (w[6499]/2 + w[1807]/2) = 0
w[3BB3] - (w[74B9]/2 + w[3887]/2) = 0
w[3BFE] - (w[6FDF]/2 + w[5E5F]/2) = 0
w[3BFF] = (1/2 + (w[5F7F]/2 + 1/2)/2)
w[3C88] - (w[ 50D]/2 + w[5065]/2) = 0
w[3C89] - (w[152D]/2 + w[70E5]/2) = 0
w[3C8E] - (w[4D4D]/2 + w[546D]/2) = 0
w[3C8F] - (w[5D6D]/2 + w[74ED]/2) = 0
w[3DA8] - (w[258D]/2 + w[5065]/2) = 0
w[3DA9] - (w[35AD]/2 + w[70E5]/2) = 0
w[3DAE] - (w[6DCD]/2 + w[546D]/2) = 0
w[3DAF] - (w[7DED]/2 + w[74ED]/2) = 0
w[3EEA] - (w[671F]/2 + w[5277]/2) = 0
w[3EEB] - (w[773F]/2 + w[72F7]/2) = 0
w[3F98] - (w[ 59D]/2 + w[5867]/2) = 0
w[3F99] - (w[15BD]/2 + w[78E7]/2) = 0
w[3F9E] - (w[4DDD]/2 + w[5C6F]/2) = 0
w[3F9F] - (w[5DFD]/2 + w[7CEF]/2) = 0
w[3FBA] - (w[659D]/2 + w[5867]/2) = 0
w[3FBB] - (w[75BD]/2 + w[78E7]/2) = 0
w[3FEE] - (w[6FDF]/2 + w[567F]/2) = 0
w[3FEF] = (1/2 + ((1/2 + w[6FDF]/2)/2 + 1/2)/2)
w[4000] = w[1000]/2/2/2
w[4010] = w[1020]/2/2/2
w[4011] - (w[1020]/2 + w[2980]/2) = 0
w[4040] - (w[ 202]/2 + w[ 310]/2) = 0
w[4044] - (w[ A42]/2 + w[ 718]/2) = 0
w[4045] - (w[1A62]/2 + w[2798]/2) = 0
w[4060] - (w[2202]/2 + w[ 310]/2) = 0
w[4061] - (w[3222]/2 + w[2390]/2) = 0
w[4066] - (w[6A42]/2 + w[ 718]/2) = 0
w[4067] - (w[7A62]/2 + w[2798]/2) = 0
w[4114] - (w[ 8C0]/2 + w[ D08]/2) = 0
w[4115] - (w[18E0]/2 + w[2D88]/2) = 0
w[4250] - (w[ 212]/2 + w[ B12]/2) = 0
w[4251] - (w[1232]/2 + w[2B92]/2) = 0
w[4256] - (w[4A52]/2 + w[ F1A]/2) = 0
w[4257] - (w[5A72]/2 + w[2F9A]/2) = 0
w[4370] - (w[2292]/2 + w[ B12]/2) = 0
w[4371] - (w[32B2]/2 + w[2B92]/2) = 0
w[4376] - (w[6AD2]/2 + w[ F1A]/2) = 0
w[4377] - (w[7AF2]/2 + w[2F9A]/2) = 0
w[4400] = w[2080]/2/2
w[4401] - (w[1020]/2 + w[21A0]/2) = 0
w[444C] - (w[ B46]/2 + w[4778]/2) = 0
w[444D] - (w[1B66]/2 + w[67F8]/2) = 0
w[4468] - (w[2306]/2 + w[4370]/2) = 0
w[4469] - (w[3326]/2 + w[63F0]/2) = 0
w[446E] - (w[6B46]/2 + w[4778]/2) = 0
w[446F] - (w[7B66]/2 + w[67F8]/2) = 0
w[4490] = w[1920]/2
w[4491] - (w[1020]/2 + w[39A0]/2) = 0
w[4504] - (w[ 8C0]/2 + w[ 528]/2) = 0
w[4505] - (w[18E0]/2 + w[25A8]/2) = 0
w[4594] - (w[ 8C0]/2 + w[1D28]/2) = 0
w[4595] - (w[18E0]/2 + w[3DA8]/2) = 0
w[4612] - (w[1020]/2/2/2/2 + w[6480]/2/2) = 0
w[4613] - (w[5030]/2 + w[29A2]/2) = 0
w[4658] - (w[ 316]/2 + w[4B72]/2) = 0
w[4659] - (w[1336]/2 + w[6BF2]/2) = 0
w[465E] - (w[4B56]/2 + w[4F7A]/2) = 0
w[465F] - (w[5B76]/2 + w[6FFA]/2) = 0
w[4716] - (w[48D0]/2 + w[ D2A]/2) = 0
w[4717] - (w[58F0]/2 + w[2DAA]/2) = 0
w[4778] - (w[2396]/2 + w[4B72]/2) = 0
w[4779] - (w[33B6]/2 + w[6BF2]/2) = 0
w[477E] - (w[6BD6]/2 + w[4F7A]/2) = 0
w[477F] - (w[7BF6]/2 + w[6FFA]/2) = 0
w[4840] - (w[ 602]/2 + w[ 310]/2) = 0
w[4841] - (w[1622]/2 + w[2390]/2) = 0
w[4862] - (w[6602]/2 + w[ 310]/2) = 0
w[4863] - (w[7622]/2 + w[2390]/2) = 0
w[48D0] - (w[ 602]/2 + w[1B10]/2) = 0
w[48D1] - (w[1622]/2 + w[3B90]/2) = 0
w[4944] - (w[ EC2]/2 + w[ 718]/2) = 0
w[4945] - (w[1EE2]/2 + w[2798]/2) = 0
w[4966] - (w[6EC2]/2 + w[ 718]/2) = 0
w[4967] - (w[7EE2]/2 + w[2798]/2) = 0
w[49D4] - (w[ EC2]/2 + w[1F18]/2) = 0
w[49D5] - (w[1EE2]/2 + w[3F98]/2) = 0
w[4A52] - (w[4612]/2 + w[ B12]/2) = 0
w[4A53] - (w[5632]/2 + w[2B92]/2) = 0
w[4B56] - (w[4ED2]/2 + w[ F1A]/2) = 0
w[4B57] - (w[5EF2]/2 + w[2F9A]/2) = 0
w[4B72] - (w[6692]/2 + w[ B12]/2) = 0
w[4B73] - (w[76B2]/2 + w[2B92]/2) = 0
w[4C48] - (w[ 706]/2 + w[4370]/2) = 0
w[4C49] - (w[1726]/2 + w[63F0]/2) = 0
w[4C6A] - (w[6706]/2 + w[4370]/2) = 0
w[4C6B] - (w[7726]/2 + w[63F0]/2) = 0
w[4CD8] - (w[ 706]/2 + w[5B70]/2) = 0
w[4CD9] - (w[1726]/2 + w[7BF0]/2) = 0
w[4D4C] - (w[ FC6]/2 + w[4778]/2) = 0
w[4D4D] - (w[1FE6]/2 + w[67F8]/2) = 0
w[4D6E] - (w[6FC6]/2 + w[4778]/2) = 0
w[4D6F] - (w[7FE6]/2 + w[67F8]/2) = 0
w[4DDC] - (w[ FC6]/2 + w[5F78]/2) = 0
w[4DDD] - (w[1FE6]/2 + w[7FF8]/2) = 0
w[4E5A] - (w[4716]/2 + w[4B72]/2) = 0
w[4E5B] - (w[5736]/2 + w[6BF2]/2) = 0
w[4ED2] - (w[4612]/2 + w[1B32]/2) = 0
w[4ED3] - (w[5632]/2 + w[3BB2]/2) = 0
w[4F5E] - (w[4FD6]/2 + w[4F7A]/2) = 0
w[4F5F] - (w[5FF6]/2 + w[6FFA]/2) = 0
w[4F7A] - (w[6796]/2 + w[4B72]/2) = 0
w[4F7B] - (w[77B6]/2 + w[6BF2]/2) = 0
w[4FD6] - (w[4ED2]/2 + w[1F3A]/2) = 0
w[4FD7] - (w[5EF2]/2 + w[3FBA]/2) = 0
w[5030] - (w[2008]/2 + w[ 901]/2) = 0
w[5031] - (w[3028]/2 + w[2981]/2) = 0
w[5064] - (w[2A4A]/2 + w[ 719]/2) = 0
w[5065] - (w[3A6A]/2 + w[2799]/2) = 0
w[5134] - (w[28C8]/2 + w[ D09]/2) = 0
w[5135] - (w[38E8]/2 + w[2D89]/2) = 0
w[5254] - (w[ A5A]/2 + w[ F1B]/2) = 0
w[5255] - (w[1A7A]/2 + w[2F9B]/2) = 0
w[5276] - (w[6A5A]/2 + w[ F1B]/2) = 0
w[5277] - (w[7A7A]/2 + w[2F9B]/2) = 0
w[5374] - (w[2ADA]/2 + w[ F1B]/2) = 0
w[5375] - (w[3AFA]/2 + w[2F9B]/2) = 0
w[5420] - (w[2008]/2 + w[ 121]/2) = 0
w[5421] - (w[3028]/2 + w[21A1]/2) = 0
w[546C] - (w[2B4E]/2 + w[4779]/2) = 0
w[546D] - (w[3B6E]/2 + w[67F9]/2) = 0
w[54B0] - (w[2008]/2 + w[1921]/2) = 0
w[54B1] - (w[3028]/2 + w[39A1]/2) = 0
w[5524] - (w[28C8]/2 + w[ 529]/2) = 0
w[5525] - (w[38E8]/2 + w[25A9]/2) = 0
w[55B4] - (w[28C8]/2 + w[1D29]/2) = 0
w[55B5] - (w[38E8]/2 + w[3DA9]/2) = 0
w[5632] - (w[6018]/2 + w[ 923]/2) = 0
w[5633] - (w[7038]/2 + w[29A3]/2) = 0
w[565C] - (w[ B5E]/2 + w[4F7B]/2) = 0
w[565D] - (w[1B7E]/2 + w[6FFB]/2) = 0
w[567E] - (w[6B5E]/2 + w[4F7B]/2) = 0
w[567F] - (w[7B7E]/2 + w[6FFB]/2) = 0
w[5736] - (w[68D8]/2 + w[ D2B]/2) = 0
w[5737] - (w[78F8]/2 + w[2DAB]/2) = 0
w[577C] - (w[2BDE]/2 + w[4F7B]/2) = 0
w[577D] - (w[3BFE]/2 + w[6FFB]/2) = 0
w[5860] - (w[260A]/2 + w[ 311]/2) = 0
w[5861] - (w[362A]/2 + w[2391]/2) = 0
w[5866] - (w[6E4A]/2 + w[ 719]/2) = 0
w[5867] - (w[7E6A]/2 + w[2799]/2) = 0
w[58F0] - (w[260A]/2 + w[1B11]/2) = 0
w[58F1] - (w[362A]/2 + w[3B91]/2) = 0
w[5964] - (w[2ECA]/2 + w[ 719]/2) = 0
w[5965] - (w[3EEA]/2 + w[2799]/2) = 0
w[59F4] - (w[2ECA]/2 + w[1F19]/2) = 0
w[59F5] - (w[3EEA]/2 + w[3F99]/2) = 0
w[5A50] - (w[ 61A]/2 + w[ B13]/2) = 0
w[5A51] - (w[163A]/2 + w[2B93]/2) = 0
w[5A56] - (w[4E5A]/2 + w[ F1B]/2) = 0
w[5A57] - (w[5E7A]/2 + w[2F9B]/2) = 0
w[5A72] - (w[661A]/2 + w[ B13]/2) = 0
w[5A73] - (w[763A]/2 + w[2B93]/2) = 0
w[5B54] - (w[ EDA]/2 + w[ F1B]/2) = 0
w[5B55] - (w[1EFA]/2 + w[2F9B]/2) = 0
w[5B70] - (w[269A]/2 + w[ B13]/2) = 0
w[5B71] - (w[36BA]/2 + w[2B93]/2) = 0
w[5B76] - (w[6EDA]/2 + w[ F1B]/2) = 0
w[5B77] - (w[7EFA]/2 + w[2F9B]/2) = 0
w[5C68] - (w[270E]/2 + w[4371]/2) = 0
w[5C69] - (w[372E]/2 + w[63F1]/2) = 0
w[5C6E] - (w[6F4E]/2 + w[4779]/2) = 0
w[5C6F] - (w[7F6E]/2 + w[67F9]/2) = 0
w[5CF8] - (w[270E]/2 + w[5B71]/2) = 0
w[5CF9] - (w[372E]/2 + w[7BF1]/2) = 0
w[5D6C] - (w[2FCE]/2 + w[4779]/2) = 0
w[5D6D] - (w[3FEE]/2 + w[67F9]/2) = 0
w[5DFC] - (w[2FCE]/2 + w[5F79]/2) = 0
w[5DFD] - (w[3FEE]/2 + w[7FF9]/2) = 0
w[5E58] - (w[ 71E]/2 + w[4B73]/2) = 0
w[5E59] - (w[173E]/2 + w[6BF3]/2) = 0
w[5E5E] - (w[4F5E]/2 + w[4F7B]/2) = 0
w[5E5F] - (w[5F7E]/2 + w[6FFB]/2) = 0
w[5E7A] - (w[671E]/2 + w[4B73]/2) = 0
w[5E7B] - (w[773E]/2 + w[6BF3]/2) = 0
w[5EF2] - (w[661A]/2 + w[1B33]/2) = 0
w[5EF3] - (w[763A]/2 + w[3BB3]/2) = 0
w[5F5C] - (w[ FDE]/2 + w[4F7B]/2) = 0
w[5F5D] - (w[1FFE]/2 + w[6FFB]/2) = 0
w[5F78] - (w[279E]/2 + w[4B73]/2) = 0
w[5F79] - (w[37BE]/2 + w[6BF3]/2) = 0
w[5F7E] - (w[6FDE]/2 + w[4F7B]/2) = 0
w[5F7F] - (w[7FFE]/2 + w[6FFB]/2) = 0
w[5FF6] - (w[6EDA]/2 + w[1F3B]/2) = 0
w[5FF7] - (w[7EFA]/2 + w[3FBB]/2) = 0
w[6000] - (w[   1]/2 + w[ 104]/2) = 0
w[6001] - (w[1021]/2 + w[2184]/2) = 0
w[6018] - (w[ 105]/2 + w[4944]/2) = 0
w[6019] - (w[1125]/2 + w[69C4]/2) = 0
w[60C4] - (w[ A43]/2 + w[171C]/2) = 0
w[60C5] - (w[1A63]/2 + w[379C]/2) = 0
w[60E0] - (w[2203]/2 + w[1314]/2) = 0
w[60E1] - (w[3223]/2 + w[3394]/2) = 0
w[60E6] - (w[6A43]/2 + w[171C]/2) = 0
w[60E7] - (w[7A63]/2 + w[379C]/2) = 0
w[6104] - (w[ 8C1]/2 + w[ 50C]/2) = 0
w[6105] - (w[18E1]/2 + w[258C]/2) = 0
w[611C] - (w[ 9C5]/2 + w[4D4C]/2) = 0
w[611D] - (w[19E5]/2 + w[6DCC]/2) = 0
w[62D0] - (w[ 213]/2 + w[1B16]/2) = 0
w[62D1] - (w[1233]/2 + w[3B96]/2) = 0
w[62D6] - (w[4A53]/2 + w[1F1E]/2) = 0
w[62D7] - (w[5A73]/2 + w[3F9E]/2) = 0
w[63F0] - (w[2293]/2 + w[1B16]/2) = 0
w[63F1] - (w[32B3]/2 + w[3B96]/2) = 0
w[63F6] - (w[6AD3]/2 + w[1F1E]/2) = 0
w[63F7] - (w[7AF3]/2 + w[3F9E]/2) = 0
w[6480] - (w[   1]/2 + w[1124]/2) = 0
w[6481] - (w[1021]/2 + w[31A4]/2) = 0
w[6498] - (w[ 105]/2 + w[5964]/2) = 0
w[6499] - (w[1125]/2 + w[79E4]/2) = 0
w[64CC] - (w[ B47]/2 + w[577C]/2) = 0
w[64CD] - (w[1B67]/2 + w[77FC]/2) = 0
w[64E8] - (w[2307]/2 + w[5374]/2) = 0
w[64E9] - (w[3327]/2 + w[73F4]/2) = 0
w[64EE] - (w[6B47]/2 + w[577C]/2) = 0
w[64EF] - (w[7B67]/2 + w[77FC]/2) = 0
w[6584] - (w[ 8C1]/2 + w[152C]/2) = 0
w[6585] - (w[18E1]/2 + w[35AC]/2) = 0
w[659C] - (w[ 9C5]/2 + w[5D6C]/2) = 0
w[659D] - (w[19E5]/2 + w[7DEC]/2) = 0
w[6602] - (w[4011]/2 + w[ 126]/2) = 0
w[6603] - (w[5031]/2 + w[21A6]/2) = 0
w[661A] - (w[4115]/2 + w[4966]/2) = 0
w[661B] - (w[5135]/2 + w[69E6]/2) = 0
w[6692] - (w[4011]/2 + w[1926]/2) = 0
w[6693] - (w[5031]/2 + w[39A6]/2) = 0
w[66D8] - (w[ 317]/2 + w[5B76]/2) = 0
w[66D9] - (w[1337]/2 + w[7BF6]/2) = 0
w[66DE] - (w[4B57]/2 + w[5F7E]/2) = 0
w[66DF] - (w[5B77]/2 + w[7FFE]/2) = 0
w[6706] - (w[48D1]/2 + w[ 52E]/2) = 0
w[6707] - (w[58F1]/2 + w[25AE]/2) = 0
w[671E] - (w[49D5]/2 + w[4D6E]/2) = 0
w[671F] - (w[59F5]/2 + w[6DEE]/2) = 0
w[6796] - (w[48D1]/2 + w[1D2E]/2) = 0
w[6797] - (w[58F1]/2 + w[3DAE]/2) = 0
w[67F8] - (w[2397]/2 + w[5B76]/2) = 0
w[67F9] - (w[33B7]/2 + w[7BF6]/2) = 0
w[67FE] - (w[6BD7]/2 + w[5F7E]/2) = 0
w[67FF] - (w[7BF7]/2 + w[7FFE]/2) = 0
w[68C0] - (w[ 603]/2 + w[1314]/2) = 0
w[68C1] - (w[1623]/2 + w[3394]/2) = 0
w[68D8] - (w[ 707]/2 + w[5B54]/2) = 0
w[68D9] - (w[1727]/2 + w[7BD4]/2) = 0
w[68E2] - (w[6603]/2 + w[1314]/2) = 0
w[68E3] - (w[7623]/2 + w[3394]/2) = 0
w[69C4] - (w[ EC3]/2 + w[171C]/2) = 0
w[69C5] - (w[1EE3]/2 + w[379C]/2) = 0
w[69DC] - (w[ FC7]/2 + w[5F5C]/2) = 0
w[69DD] - (w[1FE7]/2 + w[7FDC]/2) = 0
w[69E6] - (w[6EC3]/2 + w[171C]/2) = 0
w[69E7] - (w[7EE3]/2 + w[379C]/2) = 0
w[6A42] - (w[4613]/2 + w[ 316]/2) = 0
w[6A43] - (w[5633]/2 + w[2396]/2) = 0
w[6A5A] - (w[4717]/2 + w[4B56]/2) = 0
w[6A5B] - (w[5737]/2 + w[6BD6]/2) = 0
w[6AD2] - (w[4613]/2 + w[1B16]/2) = 0
w[6AD3] - (w[5633]/2 + w[3B96]/2) = 0
w[6B46] - (w[4ED3]/2 + w[ 71E]/2) = 0
w[6B47] - (w[5EF3]/2 + w[279E]/2) = 0
w[6B5E] - (w[4FD7]/2 + w[4F5E]/2) = 0
w[6B5F] - (w[5FF7]/2 + w[6FDE]/2) = 0
w[6BD6] - (w[4ED3]/2 + w[1F1E]/2) = 0
w[6BD7] - (w[5EF3]/2 + w[3F9E]/2) = 0
w[6BF2] - (w[6693]/2 + w[1B16]/2) = 0
w[6BF3] - (w[76B3]/2 + w[3B96]/2) = 0
w[6CC8] - (w[ 707]/2 + w[5374]/2) = 0
w[6CC9] - (w[1727]/2 + w[73F4]/2) = 0
w[6CEA] - (w[6707]/2 + w[5374]/2) = 0
w[6CEB] - (w[7727]/2 + w[73F4]/2) = 0
w[6DCC] - (w[ FC7]/2 + w[577C]/2) = 0
w[6DCD] - (w[1FE7]/2 + w[77FC]/2) = 0
w[6DEE] - (w[6FC7]/2 + w[577C]/2) = 0
w[6DEF] - (w[7FE7]/2 + w[77FC]/2) = 0
w[6E4A] - (w[4717]/2 + w[4376]/2) = 0
w[6E4B] - (w[5737]/2 + w[63F6]/2) = 0
w[6EC2] - (w[4613]/2 + w[1336]/2) = 0
w[6EC3] - (w[5633]/2 + w[33B6]/2) = 0
w[6EDA] - (w[4717]/2 + w[5B76]/2) = 0
w[6EDB] - (w[5737]/2 + w[7BF6]/2) = 0
w[6F4E] - (w[4FD7]/2 + w[477E]/2) = 0
w[6F4F] - (w[5FF7]/2 + w[67FE]/2) = 0
w[6FC6] - (w[4ED3]/2 + w[173E]/2) = 0
w[6FC7] - (w[5EF3]/2 + w[37BE]/2) = 0
w[6FDE] - (w[4FD7]/2 + w[5F7E]/2) = 0
w[6FDF] - (w[5FF7]/2 + w[7FFE]/2) = 0
w[6FFA] - (w[6797]/2 + w[5B76]/2) = 0
w[6FFB] - (w[77B7]/2 + w[7BF6]/2) = 0
w[7020] - (w[2009]/2 + w[ 105]/2) = 0
w[7021] - (w[3029]/2 + w[2185]/2) = 0
w[7038] - (w[210D]/2 + w[4945]/2) = 0
w[7039] - (w[312D]/2 + w[69C5]/2) = 0
w[70E4] - (w[2A4B]/2 + w[171D]/2) = 0
w[70E5] - (w[3A6B]/2 + w[379D]/2) = 0
w[7124] - (w[28C9]/2 + w[ 50D]/2) = 0
w[7125] - (w[38E9]/2 + w[258D]/2) = 0
w[713C] - (w[29CD]/2 + w[4D4D]/2) = 0
w[713D] - (w[39ED]/2 + w[6DCD]/2) = 0
w[72D4] - (w[ A5B]/2 + w[1F1F]/2) = 0
w[72D5] - (w[1A7B]/2 + w[3F9F]/2) = 0
w[72F6] - (w[6A5B]/2 + w[1F1F]/2) = 0
w[72F7] - (w[7A7B]/2 + w[3F9F]/2) = 0
w[73F4] - (w[2ADB]/2 + w[1F1F]/2) = 0
w[73F5] - (w[3AFB]/2 + w[3F9F]/2) = 0
w[74A0] - (w[2009]/2 + w[1125]/2) = 0
w[74A1] - (w[3029]/2 + w[31A5]/2) = 0
w[74B8] - (w[210D]/2 + w[5965]/2) = 0
w[74B9] - (w[312D]/2 + w[79E5]/2) = 0
w[74EC] - (w[2B4F]/2 + w[577D]/2) = 0
w[74ED] - (w[3B6F]/2 + ((1/2 + (w[5F7F]/2 + 1/2)/2)/2 + 1/2)/2) = 0
w[75A4] - (w[28C9]/2 + w[152D]/2) = 0
w[75A5] - (w[38E9]/2 + w[35AD]/2) = 0
w[75BC] - (w[29CD]/2 + w[5D6D]/2) = 0
w[75BD] - (w[39ED]/2 + w[7DED]/2) = 0
w[7622] - (w[6019]/2 + w[ 127]/2) = 0
w[7623] - (w[7039]/2 + w[21A7]/2) = 0
w[763A] - (w[611D]/2 + w[4967]/2) = 0
w[763B] - (w[713D]/2 + w[69E7]/2) = 0
w[76B2] - (w[6019]/2 + w[1927]/2) = 0
w[76B3] - (w[7039]/2 + w[39A7]/2) = 0
w[76DC] - (w[ B5F]/2 + w[5F7F]/2) = 0
w[76DD] = (w[1B7F]/2 + 1/2)
w[76FE] - (w[6B5F]/2 + w[5F7F]/2) = 0
w[76FF] = ((1/2 + w[6FDF]/2)/2 + 1/2)
w[7726] - (w[68D9]/2 + w[ 52F]/2) = 0
w[7727] - (w[78F9]/2 + w[25AF]/2) = 0
w[773E] - (w[69DD]/2 + w[4D6F]/2) = 0
w[773F] - (w[79FD]/2 + w[6DEF]/2) = 0
w[77B6] - (w[68D9]/2 + w[1D2F]/2) = 0
w[77B7] - (w[78F9]/2 + w[3DAF]/2) = 0
w[77FC] - (w[2BDF]/2 + w[5F7F]/2) = 0
w[77FD] = ((1/2 + (w[5F7F]/2 + 1/2)/2)/2 + 1/2)
w[78E0] - (w[260B]/2 + w[1315]/2) = 0
w[78E1] - (w[362B]/2 + w[3395]/2) = 0
w[78E6] - (w[6E4B]/2 + w[171D]/2) = 0
w[78E7] - (w[7E6B]/2 + w[379D]/2) = 0
w[78F8] - (w[270F]/2 + w[5B55]/2) = 0
w[78F9] - (w[372F]/2 + w[7BD5]/2) = 0
w[79E4] - (w[2ECB]/2 + w[171D]/2) = 0
w[79E5] - (w[3EEB]/2 + w[379D]/2) = 0
w[79FC] - (w[2FCF]/2 + w[5F5D]/2) = 0
w[79FD] - ((1/2 + ((1/2 + w[6FDF]/2)/2 + 1/2)/2)/2 + (w[1FFF]/2 + 1/2)/2) = 0
w[7A62] - (w[661B]/2 + w[ 317]/2) = 0
w[7A63] - (w[763B]/2 + w[2397]/2) = 0
w[7A7A] - (w[671F]/2 + w[4B57]/2) = 0
w[7A7B] - (w[773F]/2 + w[6BD7]/2) = 0
w[7AD0] - (w[ 61B]/2 + w[1B17]/2) = 0
w[7AD1] - (w[163B]/2 + w[3B97]/2) = 0
w[7AD6] - (w[4E5B]/2 + w[1F1F]/2) = 0
w[7AD7] - (w[5E7B]/2 + w[3F9F]/2) = 0
w[7AF2] - (w[661B]/2 + w[1B17]/2) = 0
w[7AF3] - (w[763B]/2 + w[3B97]/2) = 0
w[7B66] - (w[6EDB]/2 + w[ 71F]/2) = 0
w[7B67] - (w[7EFB]/2 + w[279F]/2) = 0
w[7B7E] - (w[6FDF]/2 + w[4F5F]/2) = 0
w[7B7F] = (1/2 + w[6FDF]/2)
w[7BD4] - (w[ EDB]/2 + w[1F1F]/2) = 0
w[7BD5] - (w[1EFB]/2 + w[3F9F]/2) = 0
w[7BF0] - (w[269B]/2 + w[1B17]/2) = 0
w[7BF1] - (w[36BB]/2 + w[3B97]/2) = 0
w[7BF6] - (w[6EDB]/2 + w[1F1F]/2) = 0
w[7BF7] - (w[7EFB]/2 + w[3F9F]/2) = 0
w[7CE8] - (w[270F]/2 + w[5375]/2) = 0
w[7CE9] - (w[372F]/2 + w[73F5]/2) = 0
w[7CEE] - (w[6F4F]/2 + w[577D]/2) = 0
w[7CEF] - ((1/2 + w[67FF]/2)/2 + ((1/2 + (w[5F7F]/2 + 1/2)/2)/2 + 1/2)/2) = 0
w[7DEC] - (w[2FCF]/2 + w[577D]/2) = 0
w[7DED] - ((1/2 + ((1/2 + w[6FDF]/2)/2 + 1/2)/2)/2 + ((1/2 + (w[5F7F]/2 + 1/2)/2)/2 + 1/2)/2) = 0
w[7E6A] - (w[671F]/2 + w[4377]/2) = 0
w[7E6B] - (w[773F]/2 + w[63F7]/2) = 0
w[7ED8] - (w[ 71F]/2 + w[5B77]/2) = 0
w[7ED9] - (w[173F]/2 + w[7BF7]/2) = 0
w[7EDE] - (w[4F5F]/2 + w[5F7F]/2) = 0
w[7EDF] = (w[5F7F]/2 + 1/2)
w[7EE2] - (w[661B]/2 + w[1337]/2) = 0
w[7EE3] - (w[763B]/2 + w[33B7]/2) = 0
w[7EFA] - (w[671F]/2 + w[5B77]/2) = 0
w[7EFB] - (w[773F]/2 + w[7BF7]/2) = 0
w[7F6E] - (w[6FDF]/2 + w[477F]/2) = 0
w[7F6F] = (1/2 + w[67FF]/2)
w[7FDC] - (w[ FDF]/2 + w[5F7F]/2) = 0
w[7FDD] = (w[1FFF]/2 + 1/2)
w[7FE6] - (w[6EDB]/2 + w[173F]/2) = 0
w[7FE7] - (w[7EFB]/2 + w[37BF]/2) = 0
w[7FF8] - (w[279F]/2 + w[5B77]/2) = 0
w[7FF9] - (w[37BF]/2 + w[7BF7]/2) = 0
w[7FFE] - (w[6FDF]/2 + w[5F7F]/2) = 0
w[7FFF] = 1
