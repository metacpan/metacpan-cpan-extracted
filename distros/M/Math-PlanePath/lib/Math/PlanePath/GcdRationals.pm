# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


# A003989 diagonals from (1,1)
# A109004        0,1,1,2,1,2,3,1,1,3,4,1,2,1,4,5,1,1,1,1
#  gcd by diagonals (0,0)=0
#                   (1,0)=1 (0,1)=1
#                   (2,0)=2 (1,1)=1 (0,2)=2
# A050873 gcd rows n>=1, k=1..n
#            1,1,2,1,1,3,1,2,1,4,1,1,1,1,5,1,2,3,2,1,6,1,1,1,
# add        0,1,0,1,1,0,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0  A023532 0 at m(m+3)/2
# IntXY      1,0,2,0,0,3,0,1,0,4,0,0,0,0,5,0,1,2,1,0,6,
# IntXY+1    2,1,3,1,1,4,1,2,1,5,1,1,1,1,6,1,2,3,2,1,7
# diff       1,0,1,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0,0,0,1   A023531
# A178340  1,2,1,3,1,1,4,1,2,1,5,1,1,1,1,6,1,2,3,2,1,7,1,1 Bernoulli
#   T(n,m) = A003989(n-m+1,m) m>=1, except when factor cancels

# diagonals_down even/odd in wedges, and other modulo

# math-image --path=GcdRationals --expression='i<30*31/2?i:0' --text --size=40
# math-image --path=GcdRationals --output=numbers --expression='i<100?i:0'
# math-image --path=GcdRationals --all --output=numbers

# Y = v = j/g
# X = (g-1)*v + u
#   = (g-1)*j/g + i/g
#   = ((g-1)*j + i)/g

# j=5  11 ...
# j=4  7 8 9 10
# j=3  4 5 6
# j=2  2 3
# j=1  1
#
# N = (1/2 d^2 - 1/2 d + 1)
#   = (1/2*$d**2 - 1/2*$d + 1)
#   = ((1/2*$d - 1/2)*$d + 1)
# j = 1/2 + sqrt(2 * $n + -7/4)
#   = [ 1 + 2*sqrt(2 * $n + -7/4) ] /2
#   = [ 1 + sqrt(8*$n -7) ] /2
#

# Primes
# i=3*a,j=3*b
# N=3*a*(3*b-1)/2


package Math::PlanePath::GcdRationals;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
*_divrem = \&Math::PlanePath::_divrem;

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;


# uncomment this to run the ### lines
#use Smart::Comments;

use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant x_minimum => 1;
use constant y_minimum => 1;
use constant gcdxy_maximum => 1;  # no common factor

use constant parameter_info_array =>
  [ { name        => 'pairs_order',
      display     => 'Pairs Order',
      type        => 'enum',
      default     => 'rows',
      choices     => ['rows','rows_reverse','diagonals_down','diagonals_up'],
      choices_display => ['Rows',
                          'Rows Reverse',
                          'Diagonals Down',
                          'Diagonals Up'],
      description => 'Order in the i,j pairs.',
    } ];

sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'pairs_order'} eq 'diagonals_down'
          ? 1
          : 0);
}

{
  my %dir_minimum_dxdy
    = (rows           => [1,0],  # N=4 to N=5 horiz
       rows_reverse   => [1,0],  # N=1 to N=2 horiz
       diagonals_down => [0,1],  # N=1 to N=2 vertical, nothing less
       diagonals_up   => [1,0],  # N=4 to N=5 horiz
      );
  sub dir_minimum_dxdy {
    my ($self) = @_;
    return @{$dir_minimum_dxdy{$self->{'pairs_order'}}};
  }
}
{
  my %dir_maximum_dxdy
    = (rows           => [1,-1], # N=2 to N=3 SE diagonal
       rows_reverse   => [2,-1], # N=3 to N=4 dX=2,dY=-1
       diagonals_down => [1,-1], # N=5 to N=6 SE diagonal
       diagonals_up   => [2,-1], # N=9 to N=10 dX=2,dY=-1
      );
  sub dir_maximum_dxdy {
    my ($self) = @_;
    return @{$dir_maximum_dxdy{$self->{'pairs_order'}}};
  }
}

#------------------------------------------------------------------------------

# all rationals X,Y >= 1 no common factor
use Math::PlanePath::DiagonalRationals;
*xy_is_visited = Math::PlanePath::DiagonalRationals->can('xy_is_visited');

sub new {
  my $self = shift->SUPER::new(@_);

  my $pairs_order = ($self->{'pairs_order'} ||= 'rows');
  (($self->{'pairs_order_n_to_xy'}
    = $self->can("_pairs_order__${pairs_order}__n_to_xy"))
   && ($self->{'pairs_order_xygr_to_n'}
       = $self->can("_pairs_order__${pairs_order}__xygr_to_n")))
    or croak "Unrecognised pairs_order: ",$pairs_order;

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### GcdRationals n_to_xy(): "$n"

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  # what to do for fractional $n?
  {
    my $int = int($n);
    if ($n != $int) {
      ### frac ...
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;
  }

  my ($x,$y) = $self->{'pairs_order_n_to_xy'}->($n);

  # if ($self->{'pairs_order'} eq 'rows'
  #     || $self->{'pairs_order'} eq 'rows_reverse') {
  #   $y = int((sqrt(8*$n-7) + 1) / 2);
  #   $x = $n - ($y - 1)*$y/2;
  #
  #   if ($self->{'pairs_order'} eq 'rows_reverse') {
  #     $x = $y - ($x-1);
  #   }
  #
  #   # require Math::PlanePath::PyramidRows;
  #   # my ($x,$y) = Math::PlanePath::PyramidRows->new(step=>1)->n_to_xy($n);
  #   # $x+=1;
  #   # $y+=1;
  #
  # } else {
  #   require Math::PlanePath::DiagonalsOctant;
  #   ($x,$y) = Math::PlanePath::DiagonalsOctant->new->n_to_xy($n);
  #   if ($self->{'pairs_order'} eq 'diagonals_up') {
  #     my $d = $x+$y;      # top 0,d measure diag down by x
  #     my $e = int($d/2);  # end e,d-e
  #     ($x,$y) = ($e-$x, $d - ($e-$x));
  #   }
  #   $x+=1;
  #   $y+=1;
  # }
  ### triangle: "$x,$y"

  my $gcd = _gcd($x,$y);
  $x /= $gcd;
  $y /= $gcd;

  ### $gcd
  ### reduced: "$x,$y"
  ### push out to x: $x + ($gcd-1)*$y

  return ($x + ($gcd-1)*$y, $y);
}

sub _pairs_order__rows__n_to_xy {
  my ($n) = @_;
  my $y = int( (_sqrtint(8*$n-7) + 1) / 2 );
  return ($n - ($y-1)*$y/2,
          $y);
}
sub _pairs_order__rows_reverse__n_to_xy {
  my ($n) = @_;
  my $y = int( (_sqrtint(8*$n-7) + 1) / 2 );
  return ($y*($y+1)/2 + 1 - $n,
          $y);
}
sub _pairs_order__diagonals_down__n_to_xy {
  my ($n) = @_;
  my $d = _sqrtint($n-1);   # eg. N=10 d=3
  $n -= $d*($d+1);          # eg. d=3 subtract 12
  if ($n > 0) {
    return ($n,
            2 - $n + 2*$d);
  } else {
    return ($n + $d,
            1 - $n + $d);
  }
}
sub _pairs_order__diagonals_up__n_to_xy {
  my ($n) = @_;
  my $d = _sqrtint($n-1);
  $n -= $d*($d+1);
  if ($n > 0) {
    return (-$n + $d + 2,
            $n + $d);
  } else {
    return (1 - $n,
            $n + 2*$d);
  }
}


# X=(g-1)*v+u
# Y=v
# u = x % y
# i = u*g
#   = (x % y)*g
#   = (x % y)*(floor(x/y)+1)
#
# Better:
#   g-1 = floor(x/y)
#   Y = j/g
#   X = ((g-1)*j + i)/g
#   j = Y*g
#   (g-1)*j + i = X*g
#   i = X*g - (g-1)*j
#     = X*g - (g-1)*Y*g
#   N = i + j*(j-1)/2
#     = X*g - (g-1)*Y*g + Y*g*(Y*g-1)/2
#     = X*g + Y*g * (-(g-1) + (Y*g-1)/2)    # but Y*g-1 may be odd
#     = X*g + Y*g * (Y*g-1 - (2g-2))/2
#     = X*g + Y*g * (Y*g-1 - 2g + 2))/2
#     = X*g + Y*g * (Y*g - 2g + 1))/2
#     = X*g + Y*g * ((Y-2)*g + 1) / 2
#     = g * [ X + Y*((Y-2)*g + 1) / 2 ]
#
#   N = X*g - (g-1)*Y*g + Y*g*(Y*g-1)/2
#     = [ 2*X*g - 2*(g-1)*Y*g + Y*g*(Y*g-1) ] / 2
#     = [ 2*X - 2*(g-1)*Y + Y*(Y*g-1) ] * g / 2
#     = [ 2*X + Y*(- 2*(g-1) + (Y*g-1)) ] * g / 2
#     = [ 2*X + Y*(-2g + 2 + Y*g - 1) ] * g / 2
#     = [ 2*X + Y*((Y-2)*g + 1) ] * g / 2
#     = X*g + [(Y-2)*g + 1]*Y*g/2
#
#  if Y and g both odd then (Y-2)*g+1 is odd+1 so even

# q=int(x/y)
# x = qy+r   qy=x-r
# r = x % y
# g-1 = q
# g = q+1
# g*y = (q+1)*y
#     = q*y + y
#     = x-r + y
#
#   N = X*g + Y*g * ((Y-2)*g + 1) / 2
#     = X*g + (X+Y-r) * ((Y-2)*g + 1) / 2
#     = X*g + (X+Y-r) * ((g*Y-2*g + 1) / 2
#     = X*g + (X+Y-r) * (((X+Y-r) - 2*g + 1) / 2
#     ... not much better

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### GcdRationals xy_to_n(): "$x,$y"

  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }
  if ($x < 1 || $y < 1 || ! _coprime($x,$y)) {
    return undef;
  }

  my ($p,$r) = _divrem ($x,$y);
  ### $x
  ### $y
  ### $p
  ### $r
  return $self->{'pairs_order_xygr_to_n'}->($x,$y,$p+1,$r);


  # my $g = int($x/$y) + 1;
  # ### g: "$g"
  # ### halve: ''.$y*(($y-2)*$g + 1)
  # return $self->{'pairs_order_xygr_to_n'}->($x,$y,$g);
}

sub _pairs_order__rows__xygr_to_n {
  my ($x,$y,$g,$r) = @_;
  ### j: $x+$y-$r
  ### i: $g*$r
  $x += $y;
  $x -= $r;  # j=X+Y-r
  return $x*($x-1)/2 + $g*$r;   # i=g*r
}

# i = X*g - (g-1)*g*Y
#   = X*g - (g-1)*(X+Y-r)
#   = X*g - g*(X+Y-r) + *(X+Y-r)
#   = X*g - g*X - g*Y + g*r + (X+Y-r)
#   = X*g - g*X - (X+Y-r) + g*r + (X+Y-r)
#   = g*r
#
# N = j-i+1 + j*(j-1)/2
#   = [2j-2i + 2 + $j*($j-1)] / 2
#   = [-2i + 2 + 2j+ j*(j-1)] / 2
#   = [-2i + 2 + j*(j-1+2)] / 2
#   = [-2i + 2 + j*(j+1)] / 2
#   = 1-i + j*(j+1)/2
#
sub _pairs_order__rows_reverse__xygr_to_n {
  my ($x,$y,$g,$r) = @_;
  $y += $x;
  $y -= $r;    # j = X+Y-r
  if ($r == 0) {
    # Case r=0 which is Y=1 becomes i=0 and that doesn't reverse to the
    # correct place by j-i+1.  Can either set $r=1,$g+=1 or leave $r==0
    # alone and adjust $y.
    $y -= 2;
  }
  return $y*($y+1)/2 - $r*$g + 1;
}

# d = (i-1)+(j-1)+1
#   = i+j-1
#   = rg + X+Y-r - 1
#   = X+Y + r*(g-1) - 1
# if r==0 Y==1 then r=1 g=X-1
# i = r*g = X-1
# j = X+Y-r = X+1-1 = X-1
# d = i+j-1
#   = 2X-2
# N = (d*d - (d%2))/4 + X-1
#   = ((2X-2)*(2X-2) - 0)/4 + X-1
#   = (X-1)^2 + X-1
#
sub _pairs_order__diagonals_down__xygr_to_n {
  my ($x,$y,$g,$r) = @_;

  $y += $x + $r*($g-1) - 1;   # d=X+Y + r*(g-1) - 1
  if ($r == 0) {
    $y *= 2;   # d=2*g-2
  }
  return ($y*$y - ($y % 2))/4 + $r*$g;
}
sub _pairs_order__diagonals_up__xygr_to_n {
  my ($x,$y,$g,$r) = @_;

  $y += $x + $r*($g-1);   # d=X+Y + r*(g-1)
  if ($r == 0) {
    $y = 2*$x - 1;
  }
  return ($y*$y - ($y % 2))/4 - $r*$g + 1;
}


# increase in rows, so right column
# in column increase within g wedge, then drop
#
# int(x2/y2) is slope of top of the wedge containing x2,y2
# g = int(x2/y2)+1 is the slope of the bottom of that wedge
# yw = floor(x2 / g) is the Y of that bottom
# N at x2,yw,g+1 is the top of the wedge underneath, bigger g smaller y
# or x2,y2,g is the top-right corner
#
# Eg.
# x=19 y=2 to 4
# g=int(19/4)+1=5
# yw=int(19/5)=3
# N(19,3,6)=
#
# at X=Y+1 g=2
# nhi = (y*((y-2)*g + 1) / 2 + x)*g
#     = (y*((y-2)*2 + 1) / 2 + y+1)*2
#     = (y*(2y-4 + 1) / 2 + y+1)*2
#     = (y*(2y-3) / 2 + y+1)*2
#     = y*(2y-3)  + 2y+2
#     = 2y^2 - 3y + 2y + 2
#     = 2y^2 - y + 2
#     = y*(2y-1) + 2

# 11  12  13  14      47  49  51  53     108 111 114 117     194 198 202 206
#  7       9      30      34      69      75     124     132     195     205
#  4   5      17  19      39  42      70  74     110 115     159 165     217
#  2       8      18      32      50      72      98     128     162     200
#  1   3   6  10  15  21  28  36  45  55  66  78  91 105 120 136 153 171 190

# 206=20*19/2+16  i=16,j=20 gcd=4
# 19,5 is slope=floor(19/5)=3 so g=4
#
# 205=20*19/2+15  i=15,j=20 gcd=5
# 19,4 is slope=floor(19/4)=4 so g=5
#
# 217=21*20/2 + 7, i=21,j=7  gcd=7
# 19,3 is slope=floor(19/3)=6 so g=7

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  ### $x2
  ### $y2

  if ($x2 < 1 || $y2 < 1) {
    return (1, 0);  # outside quadrant
  }

  if ($x1 < 1) { $x1 = 1; }
  if ($y1 < 1) { $y1 = 1; }

  if ($self->{'pairs_order'} =~ /^diagonals/) {
    my $d = $x2 + max($x2,$y2);
    return (1, int($d*($d+($d%2)) / 4));  # N end of diagonal d
  }

  my $nhi;
  {
    my $c = max($x2,$y2);
    $nhi = _pairs_order__rows__xygr_to_n($c,$c,2,0);

    # my $rev = ($self->{'pairs_order'} eq 'rows_reverse');
    # my $slope = int($x2/$y2);
    # my $g = $slope + 1;
    #
    # # within top row
    # {
    #   my $x;
    #   if ($rev) {
    #     if ($slope > 0) {
    #       $x = max ($x1, $y2*$slope);  # left-most within this wedge
    #     } else {
    #       $x = $x1;  # top-left corner
    #     }
    #   } else {
    #     # pairs_order=rows
    #     $x = $x2;  # top-right corner
    #   }
    #   $nhi = $self->{'pairs_order_xygr_to_n'}->($x, $y2, $g, 0);
    #
    #   ### $slope
    #   ### $g
    #   ### x for hi: $x
    #   ### nhi for x,y2: $nhi
    # }
    #
    # # within x2 column, top of wedge below
    # #
    # my $yw = int(($x2+$g-1) / $g); # rounded up
    # if ($yw >= $y1) {
    #   $nhi = max ($nhi, $self->{'pairs_order_xygr_to_n'}->($x2,$yw,$g+1,0));
    #
    #   ### $yw
    #   ### nhi_wedge: $self->{'pairs_order_xygr_to_n'}->($x2,$yw,$g+1,0)
    # }
    #   my $yw = int($x2 / $g) - ($g==1);  # below X=Y diagonal when g==1
    #   if ($yw >= $y1) {
    #     $g = int($x2/$yw) + 1;  # perhaps went across more than one wedge
    #     $nhi = max ($nhi,
    #                 ($yw*(($yw-2)*($g+1) + 1) / 2 + $x2)*($g+1));
    #     ### $yw
    #     ### nhi_wedge: ($yw*(($yw-2)*($g+1) + 1) / 2 + $x2)*($g+1)
    #   }
  }

  my $nlo;
  {
    $nlo = _pairs_order__rows__xygr_to_n(1,$x1, 1, $x1-1);

    # my $g = int($x1/$y1) + 1;
    # $nlo = $self->{'pairs_order_xygr_to_n'}->($x1,$y1,$g,0);
    #
    # ### glo: $g
    # ### $nlo
    #
    # if ($g > 1) {
    #   my $yw = max (int($x1 / $g),
    #                 1);
    #   ### $yw
    #   if ($yw <= $y2) {
    #     $g = int($x1/$yw); # no +1, and perhaps up across more than one wedge
    #     $nlo = min ($nlo, $self->{'pairs_order_xygr_to_n'}->($x1,$yw,$g,0));
    #     ### glo_wedge: $g
    #     ### nlo_wedge: $self->{'pairs_order_xygr_to_n'}->($x1,$yw,$g,0)
    #   }
    # }
    # if ($nlo < 1) {
    #   $nlo = 1;
    # }
  }

  ### $nhi
  ### $nlo
  return ($nlo, $nhi);
}

sub _gcd {
  my ($x, $y) = @_;
  #### _gcd(): "$x,$y"

  # bgcd() available in even the earliest Math::BigInt
  if ((ref $x && $x->isa('Math::BigInt'))
      || (ref $y && $y->isa('Math::BigInt'))) {
    return Math::BigInt::bgcd($x,$y);
  }

  $x = abs(int($x));
  $y = abs(int($y));
  unless ($x > 0) {
    return $y;  # gcd(0,y)=y for y>=0, giving gcd(0,0)=0
  }
  if ($y > $x) {
    $y %= $x;
  }
  for (;;) {
    ### assert: $x >= 1

    if ($y <= 1) {
      return ($y == 0
              ? $x   # gcd(x,0)=x
              : 1);  # gcd(x,1)=1
    }
    ($x,$y) = ($y, $x % $y);
  }
}



# # old code, rows only ...
# sub rect_to_n_range {
#   my ($self, $x1,$y1, $x2,$y2) = @_;
#   ### rect_to_n_range(): "$x1,$y1  $x2,$y2"
#
#   $x1 = round_nearest ($x1);
#   $y1 = round_nearest ($y1);
#   $x2 = round_nearest ($x2);
#   $y2 = round_nearest ($y2);
#
#   ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
#   ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
#   ### $x2
#   ### $y2
#
#   if ($x2 < 1 || $y2 < 1) {
#     return (1, 0);  # outside quadrant
#   }
#
#   if ($x1 < 1) { $x1 = 1; }
#   if ($y1 < 1) { $y1 = 1; }
#
#   my $g = int($x2/$y2) + 1;
#   my $nhi = ($y2*(($y2-2)*$g + 1) / 2 + $x2)*$g;
#   ### ghi: $g
#   ### $nhi
#
#   my $yw = int($x2 / $g) - ($g==1);  # below X=Y diagonal when g==1
#   if ($yw >= $y1) {
#     $g = int($x2/$yw) + 1;  # perhaps went across more than one wedge
#     $nhi = max ($nhi,
#                 ($yw*(($yw-2)*($g+1) + 1) / 2 + $x2)*($g+1));
#     ### $yw
#     ### nhi_wedge: ($yw*(($yw-2)*($g+1) + 1) / 2 + $x2)*($g+1)
#   }
#
#   $g = int($x1/$y1) + 1;
#   my $nlo = ($y1*(($y1-2)*$g + 1) / 2 + $x1)*$g;
#
#   ### glo: $g
#   ### $nlo
#
#   if ($g > 1) {
#     $yw = max (int($x1 / $g),
#                1);
#     ### $yw
#     if ($yw <= $y2) {
#       $g = int($x1/$yw); # no +1, and perhaps up across more than one wedge
#       $nlo = min ($nlo,
#                   ($yw*(($yw-2)*$g + 1) / 2 + $x1)*$g);
#       ### glo_wedge: $g
#       ### nlo_wedge: ($yw*(($yw-2)*$g + 1) / 2 + $x1)*$g
#     }
#   }
#
#   return ($nlo, $nhi);
# }


1;
__END__

=for stopwords eg Ryde OEIS ie Math-PlanePath GCD gcd gcds gcd/2 gcd-1 j/gcd Fortnow coprime triangulars numberings pronics incrementing

=head1 NAME

Math::PlanePath::GcdRationals -- rationals by triangular GCD

=head1 SYNOPSIS

 use Math::PlanePath::GcdRationals;
 my $path = Math::PlanePath::GcdRationals->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Fortnow, Lance>This path enumerates X/Y rationals using a method by Lance
Fortnow taking a greatest common divisor out of a triangular position.

=over

L<http://blog.computationalcomplexity.org/2004/03/counting-rationals-quickly.html>

=back

The attraction of this approach is that it's both efficient to calculate and
visits blocks of X/Y rationals using a modest range of N values, roughly a
square N=2*max(num,den)^2 in the default rows style.

    13  |      79  80  81  82  83  84  85  86  87  88  89  90
    12  |      67              71      73              77     278
    11  |      56  57  58  59  60  61  62  63  64  65     233 235
    10  |      46      48              52      54     192     196
     9  |      37  38      40  41      43  44     155 157     161
     8  |      29      31      33      35     122     126     130
     7  |      22  23  24  25  26  27      93  95  97  99 101 103
     6  |      16              20      68              76     156
     5  |      11  12  13  14      47  49  51  53     108 111 114
     4  |       7       9      30      34      69      75     124
     3  |       4   5      17  19      39  42      70  74     110
     2  |       2       8      18      32      50      72      98
     1  |       1   3   6  10  15  21  28  36  45  55  66  78  91
    Y=0 |
         --------------------------------------------------------
          X=0   1   2   3   4   5   6   7   8   9  10  11  12  13

The mapping from N to rational is

    N = i + j*(j-1)/2     for upper triangle 1 <= i <= j
    gcd = GCD(i,j)
    rational = i/j + gcd-1

which means X=numerator Y=denominator are

    X = (i + j*(gcd-1))/gcd  = j + (i-j)/gcd
    Y = j/gcd

The i,j position is a numbering of points above the X=Y diagonal by rows in
the style of L<Math::PlanePath::PyramidRows> with step=1, but starting from
i=1,j=1.

    j=4  |  7  8  9 10
    j=3  |  4  5  6
    j=2  |  2  3
    j=1  |  1
         +-------------
          i=1  2  3  4

If GCD(i,j)=1 then X/Y is simply X=i,Y=j unchanged.  This means fractions
S<X/Y E<lt> 1> are numbered by rows with increasing numerator, but skipping
positions where i,j have a common factor.

The skipped positions where i,j have a common factor become rationals
S<X/YE<gt>1>, ie. below the X=Y diagonal.  The integer part is GCD(i,j)-1 so
S<rational = gcd-1 + i/j>.  For example

    N=51 is at i=6,j=10 by rows
    common factor gcd(6,10)=2
    so rational R = 2-1 + 6/10 = 1+3/5 = 8/5
    ie. X=8,Y=5

If j is prime then gcd(i,j)=1 and so X=i,Y=j.  This means that in rows with
prime Y are numbered by consecutive N across to the X=Y diagonal.  For
example in row Y=7 above N=22 to N=27.

=head2 Triangular Numbers

X<Triangular numbers>N=1,3,6,10,etc along the bottom Y=1 row is the
triangular numbers N=k*(k-1)/2.  Such an N is at i=k,j=k and has gcd(i,j)=k
which divides out to Y=1.

    N=k*(k-1)/2  i=k,j=k

    Y = j/gcd
      = 1       on the bottom row

    X = (i + j*(gcd-1)) / gcd
      = (k + k*(k-1)) / k
      = k-1     successive points on that bottom row

N=1,2,4,7,11,etc in the column at X=1 immediately follows each of those
bottom row triangulars, ie. N+1.

    N in X=1 column = Y*(Y-1)/2 + 1

=head2 Primes

If N is prime then it's above the sloping line X=2*Y.  If N is composite
then it might be above or below, but the primes are always above.  Here's
the table with dots "..." marking the X=2*Y line.

           primes and composites above
        |
     6  |      16              20      68
        |                                             .... X=2*Y
     5  |      11  12  13  14      47  49  51  53 ....
        |                                     ....
     4  |       7       9      30      34 .... 69
        |                             ....
     3  |       4   5      17  19 .... 39  42      70   only
        |                     ....                      composite
     2  |       2       8 .... 18      32      50       below
        |             ....
     1  |       1 ..3.  6  10  15  21  28  36  45  55
        |     ....
    Y=0 | ....
         ---------------------------------------------
          X=0   1   2   3   4   5   6   7   8   9  10

Values below X=2*Y such as 39 and 42 are always composite.  Values above
such as 19 and 30 are either prime or composite.  Only X=2,Y=1 is exactly on
the line, which is prime N=3 as it happens.  The rest of the line X=2*k,Y=k
is not visited since common factor k would mean X/Y is not a rational in
least terms.

This pattern of primes and composites occurs because N is a multiple of
gcd(i,j) when that gcd is odd, or a multiple of gcd/2 when that gcd is even.

    N = i + j*(j-1)/2
    gcd = gcd(i,j)

    N = gcd   * (i/gcd + j/gcd * (j-1)/2)  when gcd odd
        gcd/2 * (2i/gcd + j/gcd * (j-1))   when gcd even

If gcd odd then either j/gcd or j-1 is even, to take the "/2" divisor.  If
gcd even then only gcd/2 can come out as a factor since taking out the full
gcd might leave both j/gcd and j-1 odd and so the "/2" not an integer.  That
happens for example to N=70

    N = 70
    i = 4, j = 12     for 4 + 12*11/2 = 70 = N
    gcd(i,j) = 4
    but N is not a multiple of 4, only of 4/2=2

Of course knowing gcd or gcd/2 is a factor of N is only useful when that
factor is 2 or more, so

    odd gcd >= 2                means gcd >= 3
    even gcd with gcd/2 >= 2    means gcd >= 4

    so N composite when gcd(i,j) >= 3

If gcdE<lt>3 then the "factor" coming out is only 1 and says nothing about
whether N is prime or composite.  There are both prime and composite N with
gcdE<lt>3, as can be seen among the values above the X=2*Y line in the table
above.

=head2 Rows Reverse

Option C<pairs_order =E<gt> "rows_reverse"> reverses the order of points
within the rows of i,j pairs,

    j=4 | 10  9  8  7
    j=3 |  6  5  4
    j=2 |  3  2
    j=1 |  1
        +------------
         i=1  2  3  4

The X,Y numbering becomes

=cut

# math-image --path=GcdRationals,pairs_order=rows_reverse --all --output=numbers

=pod

    pairs_order => "rows_reverse"

    11  |      66  65  64  63  62  61  60  59  58  57
    10  |      55      53              49      47     209
     9  |      45  44      42  41      39  38     170 168
     8  |      36      34      32      30     135     131
     7  |      28  27  26  25  24  23     104 102 100  98
     6  |      21              17      77              69
     5  |      15  14  13  12      54  52  50  48     118
     4  |      10       8      35      31      76      70
     3  |       6   5      20  18      43  40      75  71
     2  |       3       9      19      33      51      73
     1  |       1   2   4   7  11  16  22  29  37  46  56
    Y=0 |
         ------------------------------------------------
          X=0   1   2   3   4   5   6   7   8   9  10  11

The triangular numbers, per L</Triangular Numbers> above, are now in the X=1
column, ie. at the left rather than at the Y=1 bottom row.  That bottom row
is now the next after each triangular, ie. T(X)+1.

=head2 Diagonals

Option C<pairs_order =E<gt> "diagonals_down"> takes the i,j pairs by
diagonals down from the Y axis.  C<pairs_order =E<gt> "diagonals_up">
likewise but upwards from the X=Y centre up to the Y axis.  (These
numberings are in the style of L<Math::PlanePath::DiagonalsOctant>.)

    diagonals_down            diagonals_up

    j=7 | 13                   j=7 | 16
    j=6 | 10 14                j=6 | 12 15
    j=5 |  7 11 15             j=5 |  9 11 14
    j=4 |  5  8 12 16          j=4 |  6  8 10 13
    j=3 |  3  6  9             j=3 |  4  5  7
    j=2 |  2  4                j=2 |  2  3
    j=1 |  1                   j=1 |  1
        +------------              +------------
         i=1  2  3  4               i=1  2  3  4

The resulting path becomes

=cut

# math-image --path=GcdRationals,pairs_order=diagonals_down --all --output=numbers --size=40x10

=pod

    pairs_order => "diagonals_down"

     9  |     21 27    40 47    63 72
     8  |     17    28    41    56    74
     7  |     13 18 23 29 35 42    58 76
     6  |     10          30    44
     5  |      7 11 15 20    32 46 62 80
     4  |      5    12    22    48    52
     3  |      3  6    14 24    33 55
     2  |      2     8    19    34    54
     1  |      1  4  9 16 25 36 49 64 81
    Y=0 |
         --------------------------------
          X=0  1  2  3  4  5  6  7  8  9

X<Square numbers>The Y=1 bottom row is the perfect squares which are at i=j
in the C<DiagonalsOctant> and have gcd(i,j)=i thus becoming X=i,Y=1.

=cut

# math-image --path=GcdRationals,pairs_order=diagonals_up --all --output=numbers --size=40x10

=pod

    pairs_order => "diagonals_up"

     9  |     25 29    39 45    58 65
     8  |     20    28    38    50    80
     7  |     16 19 23 27 32 37    63 78
     6  |     12          26    48
     5  |      9 11 14 17    35 46 59 74
     4  |      6    10    24    44    54
     3  |      4  5    15 22    34 51
     2  |      2     8    18    33    52
     1  |      1  3  7 13 21 31 43 57 73
    Y=0 |
         --------------------------------
          X=0  1  2  3  4  5  6  7  8  9

X<Square numbers>X<Pronic numbers>N=1,2,4,6,9 etc in the X=1 column is the
perfect squares k*k and the pronics k*(k+1) interleaved, also called the
X<Quarter square numbers>quarter-squares.  N=2,5,10,17,etc on Y=X+1 above
the leading diagonal are the squares+1, and N=3,8,15,24,etc below on Y=X-1
below the diagonal are the squares-1.

The GCD division moves points downwards and shears them across horizontally.
The effect on diagonal lines of i,j points is as follows

      | 1
      |   1     gcd=1 slope=-1
      |     1
      |       1
      |         1
      |           1
      |             1
      |               1
      |                 1
      |                 .    gcd=2 slope=0
      |               .   2
      |             .     2     3  gcd=3 slope=1
      |           .       2   3           gcd=4 slope=2
      |         .         2 3         4
      |       .           3       4       5     gcd=5 slope=3
      |     .                 4      5
      |   .               4     5
      | .                 5
      +-------------------------------

The line of "1"s is the diagonal with gcd=1 and thus X,Y=i,j unchanged.

The line of "2"s is when gcd=2 so X=(i+j)/2,Y=j/2.  Since i+j=d is constant
within the diagonal this makes X=d fixed, ie. vertical.

Then gcd=3 becomes X=(i+2j)/3 which slopes across by +1 for each i, or gcd=4
has X=(i+3j)/4 slope +2, etc.

Of course only some of the points in an i,j diagonal have a given gcd, but
those which do are transformed this way.  The effect is that for N up to a
given diagonal row all the "*" points in the following are traversed, plus
extras in wedge shaped arms out to the side.

     | *
     | * *                 up to a given diagonal points "*"
     | * * *               all visited, plus some wedges out
     | * * * *             to the right
     | * * * * *
     | * * * * *   /
     | * * * * * /  --
     | * * * * *  --
     | * * * * *--
     +--------------

In terms of the rationals X/Y the effect is that up to N=d^2 with diagonal
d=2j the fractions enumerated are

    N=d^2
    enumerates all num/den where num <= d and num+den <= 2*d

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over

=item C<$path = Math::PlanePath::GcdRationals-E<gt>new ()>

=item C<$path = Math::PlanePath::GcdRationals-E<gt>new (pairs_order =E<gt> $str)>

Create and return a new path object.  The C<pairs_order> option can be

    "rows"               (default)
    "rows_reverse"
    "diagonals_down"
    "diagonals_up"

=back

=head1 FORMULAS

=head2 X,Y to N -- Rows

The defining formula above for X,Y can be inverted to give i,j and N.  This
calculation doesn't notice if X,Y have a common factor, so a coprime(X,Y)
test must be made separately if necessary (for C<xy_to_n()> it is).

    X/Y = g-1 + (i/g)/(j/g)

The g-1 integer part is recovered by a division X divide Y,

    X = quot*Y + rem   division by Y rounded towards 0
      where 0 <= rem < Y
      unless Y=1 in which case use quot=X-1, rem=1
    g-1 = quot
    g = quot+1

The Y=1 special case can instead be left as the usual kind of division
quot=X,rem=0, so 0E<lt>=remE<lt>Y.  This will give i=0 which is outside the
intended 1E<lt>=iE<lt>=j range, but j is 1 bigger and the combination still
gives the correct N.  It's as if the i=g,j=g point at the end of a row is
moved to i=0,j=g+1 just before the start of the next row.  If only N is of
interest not the i,j then it can be left rem=0.

Equating the denominators in the X/Y formula above gives j by

    Y = j/g          the definition above

    j = g*Y
      = (quot+1)*Y
    j = X+Y-rem      per the division X=quot*Y+rem

And equating the numerators gives i by

    X = (g-1)*Y + i/g     the definition above

    i = X*g - (g-1)*Y*g
      = X*g - quot*Y*g
      = X*g - (X-rem)*g     per the division X=quot*Y+rem
    i = rem*g
    i = rem*(quot+1)

Then N from i,j by the definition above

    N = i + j*(j-1)/2

For example X=11,Y=4 divides X/Y as 11=4*2+3 for quot=2,rem=3 so i=3*(2+1)=9
j=11+4-3=12 and so N=9+12*11/2=75 (as shown in the first table above).

It's possible to use only the quotient p, not the remainder rem, by taking
j=(quot+1)*Y instead of j=X+Y-rem, but usually a division operation gives
the remainder at no extra cost, or a cost small enough that it's worth
swapping a multiply for an add or two.

The gcd g can be recovered by rounding up in the division, instead of
rounding down and then incrementing with g=quot+1.

   g = ceil(X/Y)
     = cquot for division X=cquot*Y - crem

But division in most programming languages is towards 0 or towards
-infinity, not upwards towards +infinity.

=head2 X,Y to N -- Rows Reverse

For pairs_order="rows_reverse", the horizontal i is reversed to j-i+1.  This
can be worked into the triangular part of the N formula as

    Nrrev = (j-i+1) + j*(j-1)/2        for 1<=i<=j
          = j*(j+1)/2 - i + 1

The Y=1 case described above cannot be left to go through with rem=0 giving
i=0 and j+1 since the reversal j-i+1 is then not correct.  Either use rem=1
as described, or if not then compensate at the end,

    if r=0 then j -= 2            adjust
    Nrrev = j*(j+1)/2 - i + 1     same Nrrev as above

For example X=5,Y=1 is quot=5,rem=0 gives i=0*(5+1)=0 j=5+1-0=6.  Without
adjustment it would be Nrrev=6*7/2-0+1=22 which is wrong.  But adjusting
j-=2 so that j=6-2=4 gives the desired Nrrev=4*5/2-0+1=11 (per the table in
L</Rows Reverse> above).

=cut

# No, not quite
#
# =head2 Rectangle N Range -- Rows
#
# An over-estimate of the N range can be calculated just from the X,Y to N
# formula above.
#
# Within a row N increases with increasing X, so for a rectangle the minimum
# is in the left column and the maximum in the right column.
#
# Within a column N values increase until reaching the end of a "g" wedge,
# then drop down a bit.  So the maximum is either the top-right corner of the
# rectangle, or the top of the next lower wedge, ie. smaller Y but bigger g.
# Conversely the minimum is either the bottom right of the rectangle, or the
# bottom of the next higher wedge, ie. smaller g but bigger Y.  (Is that
# right?)
#
# This is an over-estimate because it ignores which X,Y points are coprime and
# thus actually should have N values.
#
# =head2 Rectangle N Range -- Rows Reverse
#
# When row pairs are taken in reverse order increasing X is not increasing N,
# but rather the maximum N of a row is at the left end of the wedge.

=pod

=head1 OEIS

This enumeration of rationals is in Sloane's Online Encyclopedia of Integer
Sequences in the following forms

=over

L<http://oeis.org/A054531> (etc)

=back

    pairs_order="rows" (the default)
      A226314   X coordinate
      A054531   Y coordinate, being N/GCD(i,j)
      A000124   N in X=1 column, triangular+1
      A050873   ceil(X/Y), gcd by rows
      A050873-A023532  floor(X/Y)
                gcd by rows and subtract 1 unless i=j

    pairs_order="diagonals_down"
      A033638   N in X=1 column, quartersquares+1 and pronic+1
      A000290   N in Y=1 row, perfect squares

    pairs_order="diagonals_up"
      A002620   N in X=1 column, squares and pronics
      A002061   N in Y=1 row, central polygonals (extra initial 1)
      A002522   N at Y=X+1 above leading diagonal, squares+1

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DiagonalRationals>,
L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::CoprimeColumns>,
L<Math::PlanePath::DiagonalsOctant>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
