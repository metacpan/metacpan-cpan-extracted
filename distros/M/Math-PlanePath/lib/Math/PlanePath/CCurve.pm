# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Math::PlanePath::CCurve;
use 5.004;
use strict;
use List::Util 'min','max','sum';

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'round_down_pow',
  'bit_split_lowtohigh',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
*_divrem = \&Math::PlanePath::_divrem;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::KochCurve;
*_digit_join_hightolow = \&Math::PlanePath::KochCurve::_digit_join_hightolow;

# uncomment this to run the ### lines
# use Smart::Comments;


# Not sure about this yet ... 2 or 4?  With mirror images too 8 arms would
# fill the plane everywhere 4-visited points double-traversed segments.
# use constant parameter_info_array => [ { name      => 'arms',
#                                          share_key => 'arms_2',
#                                          display   => 'Arms',
#                                          type      => 'integer',
#                                          minimum   => 1,
#                                          maximum   => 2,
#                                          default   => 1,
#                                          width     => 1,
#                                          description => 'Arms',
#                                        } ];

use constant n_start => 0;
use constant x_negative_at_n => 6;
use constant y_negative_at_n => 22;
use constant _UNDOCUMENTED__dxdy_list_at_n => 7;


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{'arms'} = max(1, min(2, $self->{'arms'} || 1));
  return $self;
}


sub n_to_xy {
  my ($self, $n) = @_;
  ### CCurve n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $zero = ($n * 0);  # inherit bignum 0
  my $x = $zero;
  my $y = $zero;
  {
    my $int = int($n);
    $x = $n - $int;  # inherit possible BigFloat
    $n = $int;        # BigFloat int() gives BigInt, use that
  }

  # initial rotation from arm number $n mod $arms
  my $rot = _divrem_mutate ($n, $self->{'arms'});

  my $len = $zero+1;
  foreach my $digit (digit_split_lowtohigh($n,4)) {
    ### $digit

    if ($digit == 0) {
      ($x,$y) = ($y,-$x);    # rotate -90
    } elsif ($digit == 1) {
      $y -= $len;            # at Y=-len
    } elsif ($digit == 2) {
      $x += $len;            # at X=len,Y=-len
      $y -= $len;
    } else {
      ### assert: $digit == 3
      ($x,$y) = (2*$len - $y,  # at X=2len,Y=-len and rotate +90
                 $x-$len);
    }
    $rot++; # to keep initial direction
    $len *= 2;
  }

  if ($rot & 2) {
    $x = -$x;
    $y = -$y;
  }
  if ($rot & 1) {
    ($x,$y) = (-$y,$x);
  }

  ### final: "$x,$y"
  return ($x,$y);
}

# point N=2^(2k) at XorY=+/-2^k  radius 2^k
#       N=2^(2k-1) at X=Y=+/-2^(k-1) radius sqrt(2)*2^(k-1)
# radius = sqrt(2^level)
# R(l)-R(l-1) = sqrt(2^level) - sqrt(2^(level-1))
#             = sqrt(2^level) * (1 - 1/sqrt(2))
# about 0.29289

# len=1 extent of lower level 0
# len=4 extent of lower level 2
# len=8 extent of lower level 4+1 = 5
# len=16 extent of lower level 8+3
# len/2 + len/4-1

my @digit_to_rot = (-1, 1, 0, 1);
my @dir4_to_dsdd = ([1,-1],[1,1],[-1,1],[-1,-1]);

sub xy_to_n {
  return scalar((shift->xy_to_n_list(@_))[0]);
}
sub xy_to_n_list {
  my ($self, $x, $y) = @_;
  ### CCurve xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);
  my $zero = $x*0*$y;

  ($x,$y) = ($x + $y, $y - $x);  # sum and diff
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }

  my @n_list;
  foreach my $dsdd (@dir4_to_dsdd) {
    my ($ds,$dd) = @$dsdd;
    ### attempt: "ds=$ds  dd=$dd"
    my $s = $x;  # sum X+Y
    my $d = $y;  # diff Y-X
    my @nbits;

    until ($s >= -1 && $s <= 1 && $d >= -1 && $d <= 1) {
      ### at: "s=$s, d=$d   nbits=".join('',reverse @nbits)
      my $bit = $s % 2;
      push @nbits, $bit;
      if ($bit) {
        $s -= $ds;
        $d -= $dd;
        ($ds,$dd) = ($dd,-$ds); # rotate -90
      }

      # divide 1/(1+i) = (1-i)/(1^2 - i^2)
      #                = (1-i)/2
      # so multiply (s + i*d) * (1-i)/2
      #   s = (s + d)/2
      #   d = (d - s)/2
      #
      ### assert: (($s+$d)%2)==0

      # this form avoids overflow near DBL_MAX
      my $odd = $s % 2;
      $s -= $odd;
      $d -= $odd;
      $s /= 2;
      $d /= 2;
      ($s,$d) = ($s+$d+$odd, $d-$s);
    }

    # five final positions
    #      .   0,1   .       ds,dd
    #           |
    #    -1,0--0,0--1,0
    #           |
    #      .   0,-1  .
    #
    ### end: "s=$s d=$d  ds=$ds dd=$dd"

    # last step must be East dx=1,dy=0
    unless ($ds == 1 && $dd == -1) { next; }

    if ($s == $ds && $d == $dd) {
      push @nbits, 1;
    } elsif ($s != 0 || $d != 0) {
      next;
    }
    # ended s=0,d=0 or s=ds,d=dd, found an N
    push @n_list, digit_join_lowtohigh(\@nbits, 2, $zero);
    ### found N: "$n_list[-1]"
  }
  ### @n_list
  return sort {$a<=>$b} @n_list;
}

# f = (1 - 1/sqrt(2) = .292
# 1/f = 3.41
# N = 2^level
# Rend = sqrt(2)^level
# Rmin = Rend / 2  maybe
# Rmin^2 = (2^level)/4
# N = 4 * Rmin^2
#
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  my ($len,$level) = _rect_to_k ($x1,$y1, $x2,$y2);
  if (is_infinite($level)) {
    return (0, $level);
  }
  return (0, 4*$len*$len*$self->{'arms'} - 1);
}

# N=16 is Y=4 away   k=2
# N=64 is Y=-8+1=-7 away  k=3
# N=256=4^4 is X=2^4=16-3=-7 away  k=4
# dist = 2^k - (2^(k-2)-1)
#      = 2^k - 2^(k-2) + 1
#      = 4*2^(k-2) - 2^(k-2) + 1
#      = 3*2^(k-2) + 1
#   k=2 3*2^(2-2)+1=4   len=4^2=16
#   k=3 3*2^(3-2)+1=7   len=4^3=64
#   k=4 3*2^(4-2)+1=13
# 2^(k-2) = (dist-1)/3
# 2^k = (dist-1)*4/3
#
# up = 3*2^(k-2+1) + 1
# 2^(k+1) = (dist-1)*4/3
# 2^k = (dist-1)*2/3
#
# left = 3*2^(k-2+1) + 1
# 2^(k+1) = (dist-1)*4/3
# 2^k = (dist-1)*2/3
#
# down = 3*2^(k-2+1) + 1
# 2^(k+1) = (dist-1)*4/3
# 2^k = (dist-1)*2/3
#
# m=2 4*(2-1)/3=4/3=1
# m=4 4*(4-1)/3=4
sub _rect_to_k {
  my ($x1,$y1, $x2,$y2) = @_;
  ### _rect_to_k(): $x1,$y1

  {
    my $m = max(abs($x1),abs($y1),abs($x2),abs($y2));
    if ($m < 2) {
      return (2, 1);
    }
    if ($m < 4) {
      return (4, 2);
    }
    ### round_down: 4*($m-1)/3
    my ($len, $k) = round_down_pow (4*($m-1)/3, 2);
    return ($len, $k);
  }

  my $len;
  my $k = 0;

  my $offset = -1;
  foreach my $m ($x2, $y2, -$x1, -$y1) {
    $offset++;
    ### $offset
    ### $m
    next if $m < 0;

    my ($len1, $k1);
    # if ($m < 2) {
    #   $len1 = 1;
    #   $k1 = 0;
    # } else {
    # }

    ($len1, $k1) = round_down_pow (($m-1)/3, 2);
    next if $k1 < $offset;
    my $sub = ($offset-$k1) % 4;
    $k1 -= $sub;  # round down to k1 == offset mod 4

    if ($k1 > $k) {
      $k = $k1;
      $len = $len1 / 2**$sub;
    }
  }

  ### result: "k=$k  len=$len"
  return ($len, 2*$k);
}



my @dir4_to_dx = (1,0,-1,0);
my @dir4_to_dy = (0,1,0,-1);

sub n_to_dxdy {
  my ($self, $n) = @_;
  ### n_to_dxdy(): $n

  my $int = int($n);
  $n -= $int;  # $n fraction part

  my @digits = bit_split_lowtohigh($int);
  my $dir = (sum(@digits)||0) & 3;  # count of 1-bits
  my $dx = $dir4_to_dx[$dir];
  my $dy = $dir4_to_dy[$dir];

  if ($n) {
    # apply fraction part $n

    # count low 1-bits is right turn of N+1, apply as dir-(turn-1) so decr $dir
    while (shift @digits) {
      $dir--;
    }

    # this with turn=count-1 turn which is dir++ worked into swap and negate
    # of dir4_to_dy parts
    $dir &= 3;
    $dx -= $n*($dir4_to_dy[$dir] + $dx);  # with rot-90 instead of $dir+1
    $dy += $n*($dir4_to_dx[$dir] - $dy);

    # this the equivalent with explicit dir++ for turn=count-1
    # $dir++;
    # $dir &= 3;
    # $dx += $n*($dir4_to_dx[$dir] - $dx);
    # $dy += $n*($dir4_to_dy[$dir] - $dy);
  }

  ### result: "$dx, $dy"
  return ($dx,$dy);
}

#------------------------------------------------------------------------------
# k even
#         S[h]
#       ---------
#      /          \  Z[h-1]
#     /            \
#    |              |  S[h-1]
#     \            / Z[h-2]
#      --        --
# Hb[k] = S[h] + 2*S[h-1] + S[h] + 2*(Z[h-1]/2 - Z[h-2]/2)
#          + sqrt(2)*(2*Z[h-1]/2 + 2*Z[h-2]/2)
#       = 2*S[h] + 2*S[h-1] + Z[h-1]-Z[h-2]   + sqrt(2) * (Z[h-1] + Z[h-2])
#       = 2*2^h + 2*2^(h-1) + 2*2^(h-1)-2 - (2*2^(h-2)-2)   + sqrt(2) * (2*2^(h-1)-2 + 2*2^(h-2)-2)
#       = 3*2^h             + 2*2^(h-1)-2 - 2*2^(h-2) + 2   + sqrt(2) * (3*2^(h-1) - 4)
#       = 3*2^h             +   2^(h-1)                     + sqrt(2) * (3*2^(h-1) - 4)
#       = 7*2^(h-1) + sqrt(2) * (3*2^(h-1) - 4)
#       = 7*sqrt(2)^(2h-2) + sqrt(2) * (3*sqrt(2)^(2h-2) - 4)
#       = 7*sqrt(2)^(k-2) + sqrt(2) * (3*sqrt(2)^(k-2) - 4)
#       = 7*sqrt(2)^(k-2) + sqrt(2)*3*sqrt(2)^(k-2) - 4*sqrt(2)
#       = 7*sqrt(2)^(k-2) + 3*sqrt(2)*sqrt(2)^(k-2) - 4*sqrt(2)
#       = (7 + 3*sqrt(2))*sqrt(2)^(k-2) - 4*sqrt(2)
#
#             S[2]=4
#       11--10--7,9--6---5  Z[1]=2         k=4 h=2
#        |       |       |
#   13--12       8       4---3             4 + 2*2 + 4+(2-0) = 14
#    |                       |  S[1]=2     (2+0) = 2
#   14                       2
#    |                       |
#   15---16              0---1  Z[0] = 0
#

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
# Hb[k] = 2*S[h] + 2*S[h-1]  + sqrt(2)*( Z[h]/2 + Z[h-1] + Z[h]/2 + S[h]-S[h-1] )
#       = 2*S[h] + 2*S[h-1]  + sqrt(2)*( Z[h]   + Z[h-1]          + S[h]-S[h-1] )
#       = 2*2^h  + 2*2^(h-1) + sqrt(2)*( 2*2^h-2 + 2*2^(h-1)-2 + 2^h - 2^(h-1) )
#       = 3*2^h              + sqrt(2)*( 3*2^h                 + 2^(h-1)       - 4 )
#       = 3*2^h + sqrt(2)*( 7*2^(h-1) - 4 )

sub _UNDOCUMENTED_level_to_hull_boundary {
  my ($self, $level) = @_;
  my ($a, $b) = $self->_UNDOCUMENTED_level_to_hull_boundary_sqrt2($level)
    or return undef;
  return $a + $b*sqrt(2);
}
sub _UNDOCUMENTED_level_to_hull_boundary_sqrt2 {
  my ($self, $level) = @_;
  if ($level <= 2) {
    if ($level < 0) { return; }
    if ($level == 2) { return (6,0); }
    return (2, ($level == 0 ? 0 : 1));
  }

  my ($h, $rem) = _divrem($level, 2);
  my $pow = 2**($h-1);

  if ($rem) {
    return (6*$pow, 7*$pow-4);

    # return (2*S_formula($h) + 2*S_formula($h-1),
    #         Z_formula($h)/2 + Z_formula($h-1)
    #         + Z_formula($h)/2 + (S_formula($h)-S_formula($h-1)) );

  } else {
    return (7*$pow, 3*$pow-4);

    # return (S_formula($h) + 2*S_formula($h-1) + S_formula($h)+(Z_formula($h-1)-Z_formula($h-2)),
    #         (Z_formula($h-1) + Z_formula($h-2)));
  }
}

#------------------------------------------------------------------------------
{
  my @_UNDOCUMENTED_level_to_hull_area = (0, 1/2, 2);

  sub _UNDOCUMENTED_level_to_hull_area {
    my ($self, $level) = @_;

    if ($level < 3) {
      if ($level < 0) { return undef; }
      return $_UNDOCUMENTED_level_to_hull_area[$level];
    }
    my ($h, $rem) = _divrem($level, 2);
    return 35*2**($level-4) - ($rem ? 13 : 10)*2**($h-1) + 2;

    #   if ($rem) {
    #     return 35*2**($level-4) - 13*$pow + 2;
    #
    #     my $width = S_formula($h) + Z_formula($h)/2 + Z_formula($h-1)/2;
    #     my $ul = Z_formula($h-1)/2;
    #     my $ur = Z_formula($h)/2;
    #     my $bl = $width - Z_formula($h-1)/2 - S_formula($h-1);
    #     my $br = Z_formula($h-1)/2;
    #     return $width**2 - $ul**2/2 - $ur**2/2 - $bl**2/2 - $br**2/2;
    #
    #   } else {
    #     return 35*2**($level-4) - 10*$pow + 2;
    #     return 0;
    #     return 35*2**($level-4) - 5*2**$h + 2;
    #
    #     # my $width = S_formula($h) + Z_formula($h-1);
    #     # my $upper = Z_formula($h-1)/2;
    #     # my $lower = Z_formula($h-2)/2;
    #     # my $height = S_formula($h-1) + $upper + $lower;
    #     # return $width; # * $height - $upper*$upper - $lower*$lower;
    #   }
    # }
  }
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 2**$level);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n, 2);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath ie OEIS dX,dY dX combinatorial Ramus th zig zags stairstep Duvall Keesling vy Preprint

=head1 NAME

Math::PlanePath::CCurve -- Levy C curve

=head1 SYNOPSIS

 use Math::PlanePath::CCurve;
 my $path = Math::PlanePath::CCurve->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This is an integer version of the "C" curve by LE<233>vy.

=over

"Les Courbes Planes ou Gauches et les Surfaces ComposE<233>e de Parties
Semblables au Tout", Journal de l'E<201>cole Polytechnique, July 1938 pages
227-247 and October 1938 pages 249-292

L<http://gallica.bnf.fr/ark:/12148/bpt6k57344323/f53.image>
L<http://gallica.bnf.fr/ark:/12148/bpt6k57344820>

=back

It spirals anti-clockwise, variously crossing and overlapping itself.  The
construction is straightforward but various measurements like how many
distinct points are quite complicated.

                          11-----10-----9,7-----6------5               3
                           |             |             |
                   13-----12             8             4------3        2
                    |                                         |
            19---14,18----17                                  2        1
             |      |      |                                  |
     21-----20     15-----16                           0------1   <- Y=0
      |
     22                                                               -1
      |
    25,23---24                                                        -2
      |
     26     35-----34-----33                                          -3
      |      |             |
    27,37--28,36          32                                          -4
      |      |             |
     38     29-----30-----31                                          -5
      |
    39,41---40                                                        -6
      |
     42                                              ...              -7
      |                                                |
     43-----44     49-----48                          64-----63       -8
             |      |      |                                  |
            45---46,50----47                                 62       -9
                    |                                         |
                   51-----52            56            60-----61      -10
                           |             |             |
                          53-----54----55,57---58-----59             -11

                                                       ^
     -7     -6     -5     -4     -3     -2     -1     X=0     1

The initial segment N=0 to N=1 is repeated with a turn +90 degrees left to
give N=1 to N=2.  Then N=0to2 is repeated likewise turned +90 degrees and
placed at N=2 to make N=2to4.  And so on doubling each time.

                                  4----3
                                       |      N=0to2
                       2               2      repeated
                       |               |      as N=2to4
    0----1        0----1          0----1      with turn +90

The 90 degree rotation is the same at each repetition, so the segment at
N=2^k is always the initial N=0to1 turned +90 degrees.  This means at
N=1,2,4,8,16,etc the direction is always upwards.

The X,Y position can be written in complex numbers as a recurrence

    with N = 2^k + r      high bit 2^k, rest r<2^k

    C(N) = C(2^k)  + i*C(r)
         = (1+i)^k + i*C(r)

The effect is a change from base 2 to base 1+i but with a further power of i
on each term.  Suppose the 1-bits in N are at positions k0, k1, k2, etc
(high to low), then

    C(N) = b^k0 * i^0      N= 2^k0 + 2^(k1) + 2^(k2) + ... in binary
         + b^k1 * i^1      k0 > k1 > k2 > ...
         + b^k2 * i^2      base b=1+i
         + b^k3 * i^3
         + ...

Notice the i power is not the bit position k, but rather how many 1-bits are
above the position.

=head2 Level Ranges 4^k

The X,Y extents of the path through to Nlevel=2^k can be expressed as a
width and height measured relative to the endpoints.

       *------------------*       <-+
       |                  |         |
    *--*                  *--*      | height h[k]
    |                        |      |
    *   N=4^k         N=0    *    <-+
    |     |            |     |      | below l[k]
    *--*--*            *--*--*    <-+

    ^-----^            ^-----^
     width     2^k      width
      w[k]               w[k]           Extents to N=4^k

    <------------------------>
    total width = 2^k + 2*w[k]

N=4^k is on either the X or Y axis and for the extents here it's taken
rotated as necessary to be horizontal.  k=2 N=4^2=16 shown above is already
horizontal.  The next level k=3 N=64=4^3 would be rotated -90 degrees to be
horizontal.

The width w[k] is measured from the N=0 and N=4^k endpoints.  It doesn't
include the 2^k length between those endpoints.  The two ends are symmetric
so the extent is the same at each end.

    h[k] = 2^k - 1                     0,1,3,7,15,31,etc

    w[k] = /  0            for k=0
           \  2^(k-1) - 1  for k>=1    0,0,1,3,7,15,etc

    l[k] = /  0            for k<=1
           \  2^(k-2) - 1  for k>=2    0,0,0,1,3,7,etc

The initial N=0 to N=64 shown above is k=3.  h[3]=7 is the X=-7 horizontal.
l[3]=1 is the X=1 horizontal.  w[3]=3 is the vertical Y=3, and also Y=-11
which is 3 below the endpoint N=64 at Y=8.

Expressed as a fraction of the 2^k distance between the endpoints the
extents approach total 2 wide by 1.25 high,

       *------------------*       <-+
       |                  |         |  1
    *--*                  *--*      |         total
    |                        |      |         height
    *   N=4^k         N=0    *    <-+         -> 1+1/4
    |     |            |     |      |  1/4
    *--*--*            *--*--*    <-+

    ^-----^            ^-----^
      1/2        1       1/2     total width -> 2

The extent formulas can be found by considering the self-similar blocks.
The initial k=0 is a single line segment and all its extents are 0.

                          h[0] = 0
          N=1 ----- N=0
                          l[0] = 0
                    w[0] = 0

Thereafter the replication overlap as

       +-------+---+-------+
       |       |   |       |
    +------+   |   |   +------+
    |  | D |   | C |   | B |  |        <-+
    |  +-------+---+-------+  |          | 2^(k-1)
    |      |           |      |          | previous
    |      |           |      |          | level ends
    |    E |           | A    |        <-+
    +------+           +------+

         ^---------------^
        2^k this level ends

    w[k] =           max (h[k-1], w[k-1])  # right of A,B
    h[k] = 2^(k-1) + max (h[k-1], w[k-1])  # above B,C,D
    l[k] = max w[k-1], l[k-1]-2^(k-1)      # below A,E

Since h[k]=2^(k-1)+w[k] have S<h[k] E<gt> w[k]> for kE<gt>=1 and with the
initial h[0]=w[k]=0 have h[k]E<gt>=w[k] always.  So the max of those two
is h.

    h[k] = 2^(k-1) + h[k-1]  giving h[k] = 2^k-1     for k>=1
    w[k] = h[k-1]            giving w[k] = 2^(k-1)-1 for k>=1

The max for l[k] is always w[k-1] as l[k] is never big enough that the parts
B-C and C-D can extend down past their 2^(k-1) vertical position.
(l[0]=w[0]=0 and thereafter by induction l[k]E<lt>=w[k].)

    l[k] = w[k-1]   giving l[k] = 2^(k-2)-1 for k>=2

=head2 Repeated Points

The curve crosses itself and can repeat X,Y positions up to 4 times.  The
first double, triple and quadruple points are at

    visits      X,Y         N
    ------    -------    ----------------------
       2       -2,  3       7,    9
       3       18, -7     189,  279,  281
       4      -32, 55    1727, 1813, 2283, 2369

=cut

# binary
#     2        -10,     11        111,      1001
#                                  3          2
#     3      10010,   -111   10111101, 100010111, 100011001
#                                 6         5         4
#     4    -100000, 110111   11010111111,  11100010101,
#                           100011101011, 100101000001
#                                9, 6, 7, 4

=pod

Each line segment between integer points is traversed at most 2 times, once
forward and once backward.  There's 4 lines reaching each integer point and
this line traversal means the points are visited at most 4 times.

As per L</Direction> below the direction of the curve is given by the count
of 1-bits in N.  Since no line is repeated each of the N values at a given
X,Y have a different count-1-bits mod 4.  For example N=7 is 3 1-bits and
N=9 is 2 1-bits.  The full counts need not be consecutive, as for example
N=1727 is 9 1-bits and N=2369 is 4 1-bits.

The maximum of 2 line segment traversals can be seen from the way the curve
replicates.  Suppose the entire plane had all line segments traversed
forward and backward.

      v |         v |
    --   <--------   <-
     [0,1]       [1,1]           [X,Y] = integer points
    ->   -------->   --          each edge traversed
      | ^         | ^            forward and backward
      | |         | |
      | |         | |
      v |         v |
    --   <--------   <--
     [0,0]       [1,0]
    ->   -------->   --
      | ^         | ^

Then when each line segment expands on the right the result is the same
pattern of traversals -- viewed rotated by 45-degrees and scaled by factor
sqrt(2).

     \ v / v        \ v  / v
      [0,1]           [1,1]
     / / ^ \         ^ / ^ \
    / /   \ \       / /   \ \
           \ \     / /
            \ v   / v
             [1/2,1/2]
            ^ /   ^ \
           / /     \ \
    \ \   / /       \ \   / /
     \ v / v         \ v / v
      [0,0]            1,0
     ^ / ^ \         ^ / ^ \

The curve is a subset of this pattern.  It begins as a single line segment
which has this pattern and thereafter the pattern preserves itself.  Hence
at most 2 segment traversals in the curve.

=head2 Tiling

The segment traversal argument above can also be made by taking the line
segments as triangles which are a quarter of a unit square with peak
pointing to the right of the traversal direction.

       to  *
           ^\
           | \
           |  \ triangle peak
           |  /
           | /
           |/       quarter of a unit square
      from *

These triangles in the two directions tile the plane.  On expansion each
splits into 2 halves in new positions.  Those parts don't overlap and the
plane is still tiled.  See for example

=over

Larry Riddle
L<http://ecademy.agnesscott.edu/~lriddle/ifs/levy/levy.htm>
L<http://ecademy.agnesscott.edu/~lriddle/ifs/levy/tiling.htm>

=back

For the integer version of the curve this kind of tiling can be used to
combine copies of the curve so that each every point is visited precisely 4
times.  The h[k], w[k] and l[k] extents above are less than the 2^k endpoint
length, so a square of side 2^k can be fully tiled with copies of the curve
at each corner,

             | ^         | ^
             | |         | |               24 copies of the curve
             | |         | |               to visit all points of the
             v |         v |               inside square ABCD
    <-------    <--------   <--------      precisely 4 times each
              A           B
    -------->   -------->   -------->      each part points
             | ^         | ^               N=0 to N=4^k-1
             | |         | |               rotated and shifted
             | |         | |               suitably
             v |         v |
    <--------   <--------   <--------
              C           D
    --------    -------->   -------->
             | ^         | ^
             | |         | |
             | |         | |
             v |         v |

The four innermost copies of the curve cover most of the inside square, but
the other copies surrounding them loop into the square and fill in the
remainder to make 4 visits at every point.

=cut

# If doing this tiling note that only points N=0 to N=4^k-1 are used.  If
# N=4^k was included then it would duplicate the N=0 at the "*" endpoints,
# resulting in 8 visits there rather than the intended 4.

=pod

It's interesting to note that a set of 8 curves at the origin only covers
the axes with 4-fold visits,

             | ^              8 arms at the origin
             | |              cover only X,Y axes
             v |              with 4-visits
    <--------   <--------
             0,0              away from the axes
    --------    -------->     some points < 4 visits
             | ^
             | |
             v |

This means that if the path had some sort of "arms" of multiple curves
extending from the origin then it would visit all points on the axes X=0 Y=0
a full 4 times, but off the axes there would be points without full 4
visits.

See F<examples/c-curve-wx.pl> for a wxWidgets program drawing various forms
and tilings of the curve.

=cut

# The S<"_ _ _"> line shown which is part of the 24-pattern above but omitted
# here.  This line is at Y=2^k.  The extents described above mean that it
# extends down to Y=2^k - h[k] = 2^k-(2^k-1)=1, so it visits some points in
# row Y=1 and higher.  Omitting the curve means there are YE<gt>=1 not visited
# 4 times.  Similarly YE<lt>=-1 and XE<lt>-1 and XE<gt>=+1.

=pod

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::CCurve-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y> then return C<undef>.  If C<$x,$y> is visited more than once then
return the smallest C<$n> which visits it.

=item C<@n_list = $path-E<gt>xy_to_n_list ($x,$y)>

Return a list of N point numbers at coordinates C<$x,$y>.  If there's
nothing at C<$x,$y> then return an empty list.

A given C<$x,$y> is visited at most 4 times so the returned list is at most
4 values.

=item C<$n = $path-E<gt>n_start()>

Return 0, the first N in the path.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2**$level)>.

=back

=head1 FORMULAS

Some formulas and results can also be found in the author's mathematical
write-up

=over

L<http://user42.tuxfamily.org/c-curve/index.html>

=back

=head2 Direction

The direction or net turn of the curve is the count of 1 bits in N,

    direction = count_1_bits(N) * 90degrees

For example N=11 is binary 1011 has three 1 bits, so direction 3*90=270
degrees, ie. to the south.

This bit count is because at each power-of-2 position the curve is a copy of
the lower bits but turned +90 degrees, so +90 for each 1-bit.

For powers-of-2 N=2,4,8,16, etc, there's only a single 1-bit so the
direction is always +90 degrees there, ie. always upwards.

=head2 Turn

At each point N the curve can turn in any direction: left, right, straight,
or 180 degrees back.  The turn is given by the number of low 0-bits of N,

    turn right = (count_low_0_bits(N) - 1) * 90degrees

For example N=8 is binary 0b100 which is 2 low 0-bits for turn=(2-1)*90=90
degrees to the right.

When N is odd there's no low zero bits and the turn is always (0-1)*90=-90
to the right, so every second turn is 90 degrees to the left.

=head2 Next Turn

The turn at the point following N, ie. at N+1, can be calculated by counting
the low 1-bits of N,

    next turn right = (count_low_1_bits(N) - 1) * 90degrees

For example N=11 is binary 0b1011 which is 2 low one bits for
nextturn=(2-1)*90=90 degrees to the right at the following point, ie. at
N=12.

This works simply because low 1-bits like ..0111 increment to low 0-bits
..1000 to become N+1.  The low 1-bits at N are thus the low 0-bits at N+1.

=head2 N to dX,dY

C<n_to_dxdy()> is implemented using the direction described above.  For
integer N the count mod 4 gives the direction for dX,dY.

    dir = count_1_bits(N) mod 4
    dx = dir_to_dx[dir]    # table 0 to 3
    dy = dir_to_dy[dir]

For fractional N the direction at int(N)+1 can be obtained from the
direction at int(N) and the turn at int(N)+1, which is the low 1-bits of N
per L</Next Turn> above.  Those two directions can then be combined as
described in L<Math::PlanePath/N to dX,dY -- Fractional>.

    # apply turn to make direction at Nint+1
    turn = count_low_1_bits(N) - 1      # N integer part
    dir = (dir - turn) mod 4            # direction at N+1

    # adjust dx,dy by fractional amount in this direction
    dx += Nfrac * (dir_to_dx[dir] - dx)
    dy += Nfrac * (dir_to_dy[dir] - dy)

A small optimization can be made by working the "-1" of the turn formula
into a +90 degree rotation of the C<dir_to_dx[]> and C<dir_to_dy[]> parts by
swap and sign change,

    turn_plus_1 = count_low_1_bits(N)     # on N integer part
    dir = (dir - turn_plus_1) mod 4       # direction-1 at N+1

    # adjustment including extra +90 degrees on dir
    dx -= $n*(dir_to_dy[dir] + dx)
    dy += $n*(dir_to_dx[dir] - dy)

=head2 X,Y to N

The N values at a given X,Y can be found by taking terms low to high from
the complex number formula (the same as given above)

    X+iY = b^k            N = 2^k + 2^(k1) + 2^(k2) + ... in binary
         + b^k1 * i       base b=1+i
         + b^k2 * i^2
         + ...

If the lowest term is b^0 then X+iY has X+Y odd.  If the lowest term is not
b^0 but instead some power b^n then X+iY has X+Y even.  This is because a
multiple of b=1+i,

    X+iY = (x+iy)*(1+i)
         = (x-y) + (x+y)i
    so X=x-y Y=x+y
    sum X+Y = 2x is even if X+iY a multiple of 1+i

So the lowest bit of N is found by

    bit = (X+Y) mod 2

If bit=1 then a power i^p is to be subtracted from X+iY.  p is how many
1-bits are above that point, and this is not yet known.  It represents a
direction to move X,Y to put it on an even position.  It's also the
direction of the step N-2^l to N, where 2^l is the lowest 1-bit of N.

The reduction should be attempted with p commencing as each of the four
possible directions N,S,E,W.  Some or all will lead to an N.  For quadrupled
points (such as X=-32, Y=55 described above) all four will lead to an N.

    for p 0 to 3
      dX,dY = i^p   # directions [1,0]  [0,1]  [-1,0]  [0,-1]

      loop until X,Y = [0,0] or [1,0] or [-1,0] or [0,1] or [0,-1]
      {
        bit = X+Y mod 2       # bits of N from low to high
        if bit == 1 {
          X -= dX             # move to "even" X+Y == 0 mod 2
          Y -= dY
          (dX,dY) = (dY,-dX)       # rotate -90 as for p-1
        }
        X,Y = (X+Y)/2, (Y-X)/2   # divide (X+iY)/(1+i)
      }

      if not (dX=1 and dY=0)
        wrong final direction, try next p
      if X=dX and Y=dY
        further high 1-bit for N
        found an N
      if X=0 and Y=0
        found an N

The "loop until" ends at one of the five points

            0,1
             |
    -1,0 -- 0,0 -- 1,0
             |
            0,-1

It's not possible to wait for X=0,Y=0 to be reached because some dX,dY
directions will step infinitely among the four non-zeros.  Only the case
X=dX,Y=dY is sure to reach 0,0.

The successive p decrements which rotate dX,dY by -90 degrees must end at p
== 0 mod 4 for highest term in the X+iY formula having i^0=1.  This means
must end dX=1,dY=0 East.  If this doesn't happen then there is no N for that
p direction.

The number of 1-bits in N is == p mod 4.  So the order the N values are
obtained follows the order the p directions are attempted.  In general the N
values will not be smallest to biggest N so a little sort is necessary if
that's desired.

It can be seen that sum X+Y is used for the bit calculation and then again
in the divide by 1+i.  It's convenient to write the whole loop in terms of
sum S=X+Y and difference D=Y-X.

    for dS = +1 or -1      # four directions
      for dD = +1 or -1    #
        S = X+Y
        D = Y-X

        loop until -1 <= S <= 1 and -1 <= D <= 1 {
          bit = S mod 2       # bits of N from low to high
          if bit == 1 {
            S -= dS              # move to "even" S+D == 0 mod 2
            D -= dD
            (dS,dD) = (dD,-dS)   # rotate -90
          }
          (S,D) = (S+D)/2, (D-S)/2   # divide (S+iD)/(1+i)
        }

        if not (dS=1 and dD=-1)
          wrong final direction, try next dS,dD direction
        if S=dS and D=dD
          further high 1-bit for N
          found an N
        if S=0 and D=0
          found an N

The effect of S=X+Y, D=Y-D is to rotate by -45 degrees and use every second
point of the plane.

    D= 2                      X=0,Y=2       .              rotate -45

    D= 1            X=0,Y=1      .       X=1,Y=2       .

    D= 0  X=0,Y=0      .      X=1,Y=1       .       X=2,Y=2

    D=-1            X=1,Y=0      .       X=2,Y=1       .

    D=-2                      X=2,Y=0       .

           S=0        S=1       S=2        S=3        S=4

The final five points described above are then in a 3x3 block at the origin.
The four in-between points S=0,D=1 etc don't occur so range tests
-1E<lt>=SE<lt>=1 and -1E<lt>=DE<lt>=1 can be used.

     S=-1,D=1      .      S=1,D=1

        .       S=0,D=0      .

     S=-1,D=-1     .      S=1,D=-1

=head2 Segments by Direction

In a level N=0 to N=2^k-1 inclusive, the number of segments in each
direction 0=East, 1=North, 2=West, 3=South are given by

           k=0        for k >= 1
           ---        ----------
    M0[k] = 1,    2^(k-2) + d(k+2)*2^(h-1)
    M1[k] = 0,    2^(k-2) + d(k+0)*2^(h-1)
    M2[k] = 0,    2^(k-2) + d(k-2)*2^(h-1)
    M3[k] = 0,    2^(k-2) + d(k-4)*2^(h-1)

    where h = floor(k/2)
    and   d(m) = 0  1  1  1  0 -1 -1 -1
                 for m == 0 to 7 mod 8

    M0[k] = 1, 1, 1, 1, 2,  6, 16, 36, 72, 136, 256, ...
    M1[k] = 0, 1, 2, 3, 4,  6, 12, 28, 64, 136, 272, ...
    M2[k] = 0, 0, 1, 3, 6, 10, 16, 28, 56, 120, 256, ...
    M3[k] = 0, 0, 0, 1, 4, 10, 20, 36, 64, 120, 240, ...

d(n) is a factor +1, -1 or 0 according to n mod 8.  Each M goes as a power
2^(k-2), so roughly 1/4 each, but a half power 2^(h-1) possibly added or
subtracted in a k mod 8 pattern.  In binary this is a 2^(k-2) high 1-bit
with another 1-bit in the middle added or subtracted.

The total is 2^k since there are a total 2^k points from N=0 to 2^k-1
inclusive.

    M0[k] + M1[k] + M2[k] + M3[k] = 2^k

It can be seen that the d(n) parts sum to 0 so the 2^(h-1) parts cancel out
leaving 4*2^(k-2) = 2^k.

    d(0) + d(2) + d(4) + d(6) = 0
    d(1) + d(3) + d(5) + d(7) = 0

=for GP-DEFINE  Mdir_vec = [0, 1, 1, 1,  0, -1, -1, -1]

=for GP-DEFINE  Mdir(n) = Mdir_vec[(n%8)+1]  /* +1 for vector start index 1 */

=for GP-DEFINE  M0half(k) = my(h=floor(k/2)); if(k==0,1, 2^(k-2) + Mdir(k+2)*2^(h-1))

=for GP-DEFINE  M1half(k) = my(h=floor(k/2)); if(k==0,0, 2^(k-2) + Mdir(k+0)*2^(h-1))

=for GP-DEFINE  M2half(k) = my(h=floor(k/2)); if(k==0,0, 2^(k-2) + Mdir(k-2)*2^(h-1))

=for GP-DEFINE  M3half(k) = my(h=floor(k/2)); if(k==0,0, 2^(k-2) + Mdir(k-4)*2^(h-1))

=for GP-DEFINE  M0samples = [ 1, 1, 1, 1, 2,  6, 16, 36, 72, 136, 256 ]

=for GP-DEFINE  M1samples = [ 0, 1, 2, 3, 4,  6, 12, 28, 64, 136, 272 ]

=for GP-DEFINE  M2samples = [ 0, 0, 1, 3, 6, 10, 16, 28, 56, 120, 256 ]

=for GP-DEFINE  M3samples = [ 0, 0, 0, 1, 4, 10, 20, 36, 64, 120, 240 ]

=for GP-Test  vector(length(M0samples),k,M0half(k-1)) == M0samples

=for GP-Test  vector(length(M1samples),k,M1half(k-1)) == M1samples

=for GP-Test  vector(length(M2samples),k,M2half(k-1)) == M2samples

=for GP-Test  vector(length(M3samples),k,M3half(k-1)) == M3samples

The counts can be calculated in two ways.  Firstly they satisfy mutual
recurrences.  Each adds the preceding rotated M.

    M0[k+1] = M0[k] + M3[k]        initially M0[0] = 1 (N=0 to N=1)
    M1[k+1] = M1[k] + M0[k]                  M1[0] = 0
    M2[k+1] = M2[k] + M1[k]                  M2[0] = 0
    M3[k+1] = M3[k] + M2[k]                  M3[0] = 0

Geometrically this can be seen from the way each level extends by a copy of
the previous level rotated +90,

    7---6---5            Easts in N=0 to 8
    |       |            =   Easts in N=0 to 4
    8       4---3          + Wests in N=0 to 4
                |             since N=4 to N=8 is
                2             the N=0 to N=4 rotated +90
                |
            0---1

For the bits in N, level k+1 introduces a new bit either 0 or 1.  In M0[k+1]
the a 0-bit is count M0[k] the same direction, and when a 1-bit is M3[k]
since one less bit mod 4.  Similarly the other counts.

Some substitutions give 3rd order recurrences

    for k >= 4
    M0[k] = 4*M0[k-1] - 6*M0[k-2] + 4*M0[k-3]    initial 1,1,1,1
    M1[k] = 4*M1[k-1] - 6*M1[k-2] + 4*M1[k-3]    initial 0,1,2,3
    M2[k] = 4*M2[k-1] - 6*M2[k-2] + 4*M2[k-3]    initial 0,0,1,3
    M3[k] = 4*M3[k-1] - 6*M3[k-2] + 4*M3[k-3]    initial 0,0,0,1

=for GP-DEFINE  M0rec(k) = if(k<4,1, 4*M0rec(k-1) - 6*M0rec(k-2) + 4*M0rec(k-3))

=for GP-DEFINE  M1rec(k) = if(k<4,k, 4*M1rec(k-1) - 6*M1rec(k-2) + 4*M1rec(k-3))

=for GP-DEFINE  M2rec(k) = if(k<2,0, if(k==2,1, if(k==3,3, 4*M2rec(k-1) - 6*M2rec(k-2) + 4*M2rec(k-3))))

=for GP-DEFINE  M3rec(k) = if(k<3,0, if(k==3,1, 4*M3rec(k-1) - 6*M3rec(k-2) + 4*M3rec(k-3)))

=for GP-Test  vector(20,k,M0rec(k-1)) == vector(20,k,M0half(k-1))

=for GP-Test  vector(20,k,M1rec(k-1)) == vector(20,k,M1half(k-1))

=for GP-Test  vector(20,k,M2rec(k-1)) == vector(20,k,M2half(k-1))

=for GP-Test  vector(20,k,M3rec(k-1)) == vector(20,k,M3half(k-1))

The characteristic polynomial  of these recurrences is

    x^3 - 4x^2 + 6x - 4
    = (x-2) * (x - (1-i)) * (x - (1+i))

=for GP-Test  x^3 - 4*x^2 + 6*x - 4 == (x-2)*(x^2 - 2*x + 2)

=for GP-Test  x^3 - 4*x^2 + 6*x - 4 == (x-2) * (x + (I-1)) * (x - (I+1))

So explicit formulas can be written in powers of the roots 2, 1-i and 1+i,

    M0[k] = ( 2^k +   (1-i)^k +   (1+i)^k )/4      for k>=1
    M1[k] = ( 2^k + i*(1-i)^k - i*(1+i)^k )/4
    M2[k] = ( 2^k -   (1-i)^k -   (1+i)^k )/4
    M3[k] = ( 2^k - i*(1-i)^k + i*(1+i)^k )/4

=for GP-DEFINE  M0pow(k) = if(k==0,1, (1/4)*(2^k +   (1-I)^k +   (1+I)^k))

=for GP-DEFINE  M1pow(k) = if(k==0,0, (1/4)*(2^k + I*(1-I)^k - I*(1+I)^k))

=for GP-DEFINE  M2pow(k) = if(k==0,0, (1/4)*(2^k -   (1-I)^k -   (1+I)^k))

=for GP-DEFINE  M3pow(k) = if(k==0,0, (1/4)*(2^k - I*(1-I)^k + I*(1+I)^k))

=for GP-Test  vector(50,k,M0pow(k-1)) == vector(50,k,M0half(k-1))

=for GP-Test  vector(50,k,M1pow(k-1)) == vector(50,k,M1half(k-1))

=for GP-Test  vector(50,k,M2pow(k-1)) == vector(50,k,M2half(k-1))

=for GP-Test  vector(50,k,M3pow(k-1)) == vector(50,k,M3half(k-1))

The complex numbers 1-i and 1+i are 45 degree lines clockwise and
anti-clockwise respectively.  The powers turn them in opposite directions so
the imaginary parts always cancel out.  The remaining real parts can be had
by a half power h=floor(k/2) which is the magnitude abs(1-i)=sqrt(2)
projected onto the real axis.  The sign selector d(n) above is whether the
positive or negative part of the real axis, or zero when at the origin.

The second way to calculate is the combinatorial interpretation that per
L</Direction> above the direction is count_1_bits(N) mod 4 so East segments
are all N values with count_1_bits(N) == 0 mod 4, ie. N with 0, 4, 8, etc
many 1-bits.  The number of ways to have those bit counts within total k
bits is k choose 0, 4, 8 etc.

    M0[k] = /k\ + /k\ + ... + / k\      m = floor(k/4)
            \0/   \4/         \4m/

    M1[k] = /k\ + /k\ + ... + / k  \    m = floor((k-1)/4)
            \1/   \5/         \4m+1/

    M2[k] = /k\ + /k\ + ... + / k  \    m = floor((k-2)/4)
            \2/   \6/         \4m+2/

    M3[k] = /k\ + /k\ + ... + / k  \    m = floor((k-3)/4)
            \3/   \7/         \4m+3/

=for GP-DEFINE  M0sum(k) = sum(i=0,floor(k/4), binomial(k, 4*i))

=for GP-DEFINE  M1sum(k) = sum(i=0,floor(k/4), binomial(k, 4*i+1))

=for GP-DEFINE  M2sum(k) = sum(i=0,floor(k/4), binomial(k, 4*i+2))

=for GP-DEFINE  M3sum(k) = sum(i=0,floor(k/4), binomial(k, 4*i+3))

=for GP-Test  vector(length(M0samples),k,M0sum(k-1)) == M0samples

=for GP-Test  vector(length(M1samples),k,M1sum(k-1)) == M1samples

=for GP-Test  vector(length(M2samples),k,M2sum(k-1)) == M2samples

=for GP-Test  vector(length(M3samples),k,M3sum(k-1)) == M3samples

The power forms above are cases of the identity by Ramus for sums of
binomial coefficients in arithmetic progression like this.  (See Knuth
volume 1 section 1.2.6 exercise 30 for a form with cosines resulting from
w=i+1 as 8th roots of unity.)

The total M0+M1+M2+M3=2^k is the total binomials across a row of Pascal's
triangle.

    /k\ + /k\ + ... + /k\ = 2^k
    \0/   \1/         \k/

It's interesting to note the M counts here are the same in the dragon curve
(L<Math::PlanePath::DragonCurve>).  The shapes of the curves are different
since the segments are in a different order, but the total puts points N=2^k
at the same X,Y position.

=cut

# cf.
# J. Konvalina, Y.-H. Liu, Arithmetic progression sums of binomial
# coefficients, Appl. Math. Lett., 10(4), 11-13 (1997).

# ((1+I)^k + (1-I)^k)/2^floor(k/2) = [2, 2, 0, -2,  -2, -2, 0, 2, ]
# M3[k] = M0[k+1] - M0[k]
#       = 2^(k+1) - 2^k   (1-i)^(k+1) - (1-i)^k   (1+i)^(k+1) - (1+i)^k
#       = 2^k   (1-i - 1)*(1+i)^k   (1+i - 1)*(1+i)^k
#       = 2^k   (-i)*(1+i)^k   (i)*(1+i)^k
# M2[k] = M3[k+1] - M3[k]
#       = 2^k   (-i)*(-i)*(1+i)^k   (i)*(i)*(1+i)^k
#       = 2^k  - (1+i)^k   - (1+i)^k
# M2[k] = M3[k+1] - M3[k]
#       = 2^k   (-i)*(-i)*(-i)*(1+i)^k   (i)*(i)*(i)*(1+i)^k
#       = 2^k  + i*(1+i)^k   - i*(1+i)^k
# S[k] = a*2^k + (c+di)*(1-i)^k + (e+fi)*(1+i)^k
# a*2^0 + (c+di)*(1-i)^0 + (e+fi)*(1+i)^0 = 1
# a     + (c+di)         + (e+fi)         = 1
#    a  + c     + e     = 1
#           + d     + f = 0
# a*2^1 + (c+di)*(1-i)^1 + (e+fi)*(1+i)^1 = 1
# a*2   + (c+di)*(1-i)   + (e+fi)*(1+i)   = 1
#   2a      + d     - f = 1
#       - c     + e     = 0
# a*2^2 + (c+di)*(1-i)^2 + (e+fi)*(1+i)^2 = 1
# a*4   + (c+di)*-2i     + (e+fi)*2i      = 1
#   4a      + 2d      - 2f = 1
#   4b  - 2c     + 2e      = 0
  # matsolve([1,1,1; 2,1,1; 4,2,-2]; [1,1,1])
# a*2 + b*(1-i) + c*(1+i) = 1
#            2a + (1-i)b + (1+i)c = 1
# a*4 + b*-2i + c*2i = 1                  4a +   -2ib +    2ic = 1
# b=c a=1/4 b=c=3/8

=pod

=head2 Right Boundary

The length of the right-side boundary of the curve, which is the outside of
the "C", from N=0 to N=2^k is

    R[k] = /  7*2^h - 2k - 6     if k even
           \ 10*2^h - 2k - 6     if k odd
           where h = floor(k/2)
         = 1, 2, 4, 8, 14, 24, 38, 60, 90, 136, 198, 292, 418, ...

    R[k] =   (7/2 + 5/2 * sqrt(2)) * ( sqrt(2))^k
           + (7/2 - 5/2 * sqrt(2)) * (-sqrt(2))^k
           - 2*k - 6

    R[k] = 2*R[k-1] + R[k-2] - 4*R[k-3] + 2*R[k-4]

=for GP-DEFINE Rsamples = [1, 2, 4, 8, 14, 24, 38, 60, 90, 136, 198, 292, 418]

=for GP-DEFINE Rcases(k)=if(k%2,10,7)*2^floor(k/2) - 2*k - 6

=for GP-Test vector(length(Rsamples), k, Rcases(k-1)) == Rsamples

=for GP-DEFINE Rrec(k)=if(k<4,Rsamples[k+1], 2*Rrec(k-1) + Rrec(k-2) - 4*Rrec(k-3) + 2*Rrec(k-4))

=for GP-Test vector(length(Rsamples), k, Rrec(k-1)) == Rsamples

=for GP-DEFINE nearint(x)=if(abs(x-round(x)) < 0.000001, round(x), x)

=for GP-DEFINE Rpow(k)=nearint( (7/2 + 5/2 * sqrt(2))*( sqrt(2))^k + (7/2 - 5/2 * sqrt(2))*(-sqrt(2))^k ) - 2*k - 6

=for GP-Test vector(length(Rsamples), k, Rpow(k-1)) == Rsamples

=cut

# R[2k] =   (7/2 + 5/2 * sqrt(2))*( sqrt(2))^(2k)
#         + (7/2 - 5/2 * sqrt(2))*(-sqrt(2))^(2k)
#       =   (7/2 + 5/2 * sqrt(2))*2^k
#         + (7/2 - 5/2 * sqrt(2))*2^k
#       =   2*7/2*2^k
#       =   7*2^k
#
# R[2k+1] =   (7/2 + 5/2 * sqrt(2))*( sqrt(2))^(2k)
#           + (7/2 - 5/2 * sqrt(2))*(-sqrt(2))^(2k)
#         =   (7/2 + 5/2 * sqrt(2))*2^k*sqrt(2)
#           + (7/2 - 5/2 * sqrt(2))*2^k*-sqrt(2)
#         =   (7/2*sqrt(2)  + 5/2 * sqrt(2)*sqrt(2))*2^k
#           + (7/2*-sqrt(2) - 5/2 * sqrt(2)*-sqrt(2))*2^k
#         =   (7/2*sqrt(2)  + 5/2 * 2)*2^k
#           + (7/2*-sqrt(2) + 5/2 * 2)*2^k
#         =   (5/2 * 2)*2^k * 2
#         =   10*2^k

=pod

The length doubles until R[4]=14 which is points N=0 to N=2^4=16.  At k=4
the points N=7,8,9 have turned inward and closed off some of the outside of
the curve so the boundary less than 2x.

        11--10--9,7--6--5        right boundary
         |       |      |        around "outside"
    13--12       8      4--3     N=0 to N=2^4=16
     |                     |
    14                     2        R[4]=14
     |                     |
    15--16              0--1


The floor(k/2) and odd/even cases are eliminated by the +/-sqrt(2) powering
shown.  Those powers are also per the characteristic equation of the
recurrence,

    x^4 - 2*X^3 - x^2 + 4*x - 2
      = (x - 1)^2 * (x + sqrt(2)) * (x - sqrt(2))
    roots 1, sqrt(2), -sqrt(2)

The right boundary comprises runs of straight lines and zig-zags.  When it
expands the straight lines become zig-zags and the zig-zags become straight
lines.  The straight lines all point "forward", which is anti-clockwise.

                                      c     *     a
                                     / ^   / ^   / ^
                            =>      v   \ v   \ v   \
    D<----C<----B<----A            D     C     B     A
    |                 ^           /                   ^
    v                 |          v                     \
       straight S=3                zig-zag Z[k+1] = 2S[k]-2 = 4

The count Z here is both sides of each "V" shape from points "a" through to
"c".  So Z counts the boundary length (rather than the number of "V"s).
Each S becomes an upward peak.  The first and last side of those peaks
become part of the following "straight" section (at A and D), hence
Z[k+1]=2*S[k]-2.

The zigzags all point "forward" too.  When they expand they close off the V
shape and become 2 straight lines for each V, which means 1 straight line
for each Z side.  The segment immediately before and after contribute a
segment to the resulting straight run too, hence S[k+1]=Z[k]+2.

         C     B     A               *<---C<---*<---B<---*<---A<---*
        / ^   / ^   / ^              |         |         |         |
       v   \ v   \ v   \      =>     |         |         |         |
      *     *     *     *         <--*         *         *         *<--
     /                   ^
    v                     \
      zig-zag Z=4 segments             straight S[k+1] = Z[k]+2 = 6

The initial N=0 to N=1 is a single straight segment S[0]=1 and from there
the runs grow.  N=1 to N=3 is a straight section S[1]=2.  Z[0]=0 represents
an empty zigzag at N=1.  Z[1] is the first non-empty at N=3 to N=5.

     h   S[h]     Z[h]       Z[h]   = 2*S[h]-2
    --   ----     ----       S[h+1] = Z[h]+2
     0     1        0
     1     2        2        S[h+1] = 2*S[h]-2+2 = 2*S[h]
     2     4        6        so
     3     8       14        S[h] = 2^h
     4    16       30        Z[h] = 2*2^h-2
     5    32       62
     5    64      126

The curve N=0 to N=2^k is symmetric at each end and is made up of runs S[0],
Z[0], S[1], Z[1], etc, of straight and zigzag alternately at each end.  When
k is even there's a single copy of a middle S[k/2].  When k is odd there's a
single middle Z[(k-1)/2] (with an S[(k-1)/2] before and after).  So

                / i=h-1          \           # where h = floor(k/2)
    R[k] = 2 * | sum   S[i]+Z[i]  |
                \ i=0            /
           + S[h]
           + / S[h]+Z[h]  if k odd
             \ 0          if k even

         =  2*(  1+2+4+...+2^(h-1)           # S[0] to S[h-1]
               + 2+4+8+...+2^h  -  2*h)      # Z[0] to Z[h-1]
           + 2^h                             # S[h]
           + if k odd (2^h + 2*2^h - 2)      # possible S[h]+Z[h]

         = 2*(2^h-1 + 2*2^h-2 - 2h) + 2^h + (k odd 3*2^h - 2)
         = 7*2^h - 4h-6 + (if k odd then + 3*2^h - 2)
         = 7*2^h - 2k-6 + (if k odd then + 3*2^h)

=head2 Convex Hull Boundary

A convex hull is the smallest convex polygon which contains a given set of
points.  For the C curve the boundary length of the convex hull for points
N=0 to N=2^k inclusive is

    hull boundary[k]
        / 2                                    if k=0
        | 2+sqrt(2)                            if k=1
      = | 6                                    if k=2
        | 6*2^(h-1) + (7*2^(h-1) - 4)*sqrt(2)  if k odd  >=3
        \ 7*2^(h-1) + (3*2^(h-1) - 4)*sqrt(2)  if k even >=4
    where h = floor(k/2)

      k              hull boundary
     ---      ----------------------------
      0        2 +  0 * sqrt(2)  =    2
      1        2 +  1 * sqrt(2)  =    3.41
      2        6 +  0 * sqrt(2)  =    6
      3        6 +  3 * sqrt(2)  =   10.24
      4       14 +  2 * sqrt(2)  =   16.82
      5       12 + 10 * sqrt(2)  =   26.14
      6       28 +  8 * sqrt(2)  =   39.31
      7       24 + 24 * sqrt(2)  =   57.94
      8       56 + 20 * sqrt(2)  =   84.28
      9       48 + 52 * sqrt(2)  =  121.53

The integer part is the straight sides of the hull and the sqrt(2) part is
the diagonal sides of the hull.

When k is even the hull has the following shape.  The sides are as per the
right boundary above but after Z[h-2] the curl goes inwards and so parts
beyond Z[h-2] are not part of the hull.  Each Z stair-step diagonal becomes
a sqrt(2) length for the hull.  Z counts both vertical and horizontal of
each stairstep, hence sqrt(2)*Z/2 for the hull boundary.

                  S[h]
               *--------*                  *       Z=2
      Z[h-1]  /          \  Z[h-1]         | \     diagonal
             /            \                |  \    sqrt(2)*Z/2
            *              *               *----*  = sqrt(2)
    S[h-1]  |              |  S[h-1]
            |              |
            *              *
      Z[h-2] \            / Z[h-2]
              *--      --*

                S[h] + Z[h-2]-Z[h-1]

    k even
    hull boundary[k] = S[h] + 2*S[h-1] + S[h+Z[h-2]-Z[h-1]
                       + sqrt(2)*(2*Z[h-1] + 2*Z[h-2])/2

When k is odd the shape is similar but Z[h] in the middle.

                        S[h]
                       *----*
               Z[h-1] /      \  middle
                     *        \  Z[h]
             S[h-1]  |         \
                     *          *
                      \         |  S[h]
          Z[h]                  |
    + 2*(S[h]-S[h-1])           *
                         \     /  Z[h-1]
                          *---*
                          S[h-1]

    k odd
    hull boundary[k] = 2*S[h] + 2*S[h-1]
                       + sqrt(2)*(Z[h]/2 + 2*Z[h-1]/2
                                  + Z[h]/2 + S[h]-S[h-1]

=head2 Convex Hull Area

The area of the convex hull for points N=0 to N=2^k inclusive is

            / 0                                if k=0
            | 1/2                              if k=1
    HA[k] = | 2                                if k=2
            | 35*2^(k-4) - 13*2^(h-1) + 2      if k odd  >=3
            \ 35*2^(k-4) - 10*2^(h-1) + 2      if k even >=4
          where h = floor(k/2)

    = 0, 1/2, 2, 13/2, 17, 46, 102, 230, 482, 1018, 2082, 4274, ...

HA[1] and HA[3] are fractions but all others are integers.

The area can be calculated from the shapes shown for the hull boundary
above.  For k odd it can be noted the width and height are equal, then the
various corners are cut off.

=head2 Line Points

The number of points which fall on straight and diagonal lines from the
endpoints can be calculated by considering how the previous level duplicates
to make the next.

              d   d
            c  \ /  c
        b   |   +   |   b
         \  |  / \  |  /           curve endpoints
          \ | /   \ | /             "S" start
           \|/     \|/              "E" end
     a------E---e---S------a
           /|\     /|\
          / | \   / | \
         /  |  f f  |  \
        h   g       g   h

The curve is rotated to make the endpoints horizontal.  Each "a" through "h"
is the number of points which fall on the respective line.  The curve is
symmetric in left to right so the line counts are the same each side in
mirror image.

"S" start and "E" end points are not included in any of the counts.  "e" is
the count in between S and E.  The two "d" lines meet at point "+" and that
point is counted in d.  That point is where two previous level curves meet
for kE<gt>=1.  Points are visited up to 4 times (per L</Repeated Points>
above) and all those multiple visits are counted.

The following diagram shows how curve level k+1 is made from two level k
curves.  One is from S to M and another M to E.

            |\       /|            curve level k copies
            | \     / |            S to M and M to E
            | c+a c+a |            making curve k+1 S to E
            |   \|/   |
       \    |  --M--  |    /
        \   |   /|\   |   c        a[k+1] = b[k]
         c  d e+g e+g d  /         b[k+1] = c[k]
          \ | /     \ | /          c[k+1] = d[k]
           \|/       \|/           d[k+1] = a[k]+c[k] + e[k]+g[k] + 1
    b-------E--f---f--S-------b    e[k+1] = 2*f[k]
           /|\       /|\           f[k+1] = g[k]
          a | g     g | a          g[k+1] = h[k]
         /  h  \   /  h  \         h[k+1] = a[k]
        /   |   \ /   |   \
       /    |         |    \

For example the line S to M is an e[k], but also the M to E contributes a
g[k] on that same line so e+g.  Similarly c[k] and a[k] on the outer sides
of M.  Point M itself is visited too so the grand total for d[k+1] is
a+c+e+g+1.  The other lines are simpler, being just rotations except for the
middle line e[k+1] which is made of two f[k].

The successive g[k+1]=h[k]=a[k-1]=b[k-2]=c[k-3]=d[k-4] can be substituted
into the d to give a recurrence

    d[k+1] = d[k-1] + d[k-3] + d[k-5] + 2*d[k-7] + 1
           = 0,1,1,2,2,4,4,8,8,17,17,34,34,68,68,136,136,273,273,...

                               x + x^2          (common factor 1+x
    generating function  -------------------     in numerator and
                         (1-2*x^2) * (1-x^8)     denominator)

    d[2h-1] = d[2h] = floor( 8/15 * 2^h )

=for GP-DEFINE  gd(x)=(x+x^2) / ( (1-2*x^2)*(1-x^8) )

=for GP-Test  gd(x) == (x+x^2) / ( (1-x^2)*(1+x^2)*(1-2*x^2)*(1+x^4) )

=for GP-Test Vec(gd(x) - O(x^19)) == [1,1,2,2,4,4,8,8,17,17,34,34,68,68,136,136,273,273] /* sans initial 0s */

=for GP-DEFINE  vector_modulo(v,i) = v[(i% #v)+1];

=for GP-DEFINE  d_by_powers(k) = 8/15*2^ceil(k/2) - 1/15*vector_modulo([8,1,1,2,2,4,4,8],k);

=for GP-Test vector(19,k,k--; d_by_powers(k)) == [0,1,1,2,2,4,4,8,8,17,17,34,34,68,68,136,136,273,273] /* sans initial 0s */

=for GP-DEFINE  d_by_powers(k) = floor(8/15*2^ceil(k/2));

=for GP-Test vector(19,k,k--; d_by_powers(k)) == [0,1,1,2,2,4,4,8,8,17,17,34,34,68,68,136,136,273,273] /* sans initial 0s */

The recurrence begins with the single segment N=0 to N=1 and the two
endpoints are not included so initial all zeros a[0]=...=h[0]=0.

As an example, the N=0 to N=64 picture above is level k=6 and its "d" line
relative to those endpoints is the South-West diagonal down from N=0.  The
points on that line are N=32,30,40,42 giving d[6]=4.

All the measures are relative to the endpoint direction.  The points on the
fixed X or Y axis or diagonal can be found by taking the appropriate a
through h, or sum of two of them for both positive and negative of a
direction.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A179868> (etc)

=back

    A010059   abs(dX), count1bits(N)+1 mod 2
    A010060   abs(dY), count1bits(N) mod 2, being Thue-Morse

    A000120   direction, being total turn, count 1-bits
    A179868   direction 0to3, count 1-bits mod 4

    A035263   turn 0=straight or 180, 1=left or right,
                being (count low 0-bits + 1) mod 2
    A096268   next turn 1=straight or 180, 0=left or right,
                being count low 1-bits mod 2
    A007814   turn-1 to the right,
                being count low 0-bits

    A003159   N positions of left or right turn, ends even num 0 bits
    A036554   N positions of straight or 180 turn, ends odd num 0 bits

    A146559   X at N=2^k, being Re((i+1)^k)
    A009545   Y at N=2^k, being Im((i+1)^k)

    A131064   right boundary length to odd power N=2^(2k-1),
                being 5*2^n-4n-4, skip initial 1
    A027383   right boundary length differences

    A038503   number of East  segments in N=0 to N=2^k-1
    A038504   number of North segments in N=0 to N=2^k-1
    A038505   number of West  segments in N=0 to N=2^k-1
    A000749   number of South segments in N=0 to N=2^k-1

    A191689   fractal dimension of the interior boundary

A191689 is the fractal dimension which roughly speaking means what power r^k
the boundary length grows by when each segment is taken as a little triangle
(or similar).  There are various holes inside the curling spiralling curve
and they are all boundary for this purpose.

=over

P. Duvall and J. Keesling, "The Dimension of the Boundary of the
LE<233>vy Dragon", International Journal Math and Math Sci, volume 20,
number 4, 1997, pages 627-632.  (Preprint "The Hausdorff Dimension of the
Boundary of the LE<233>vy Dragon" L<http://at.yorku.ca/p/a/a/h/08.htm>.)

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DragonCurve>,
L<Math::PlanePath::AlternatePaper>,
L<Math::PlanePath::KochCurve>

L<ccurve(6x)> back-end for L<xscreensaver(1)> which displays the C curve
(and various other dragon curve and Koch curves).

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

This file is part of Math-PlanePath.

Math-PlanePath is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-PlanePath is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

=cut
