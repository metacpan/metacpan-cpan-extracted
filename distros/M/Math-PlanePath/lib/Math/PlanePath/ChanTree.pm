# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


# digit_direction LtoH
# digit_order     HtoL
# reduced = bool
# points = even, all_mul, all_div

# points=all wrong
#
# Chan corollary 3 taking frac(2n)   = b(2n)   /   b(2n+1)
#                         frac(2n+1) = b(2n+1) / 2*b(2n+2)
# at N odd multiply 2 into denominator,
# which is divide out 2 from numerator since b(2n+1) odd terms are even
#

package Math::PlanePath::ChanTree;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_down_pow',
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
*_divrem = \&Math::PlanePath::_divrem;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::CoprimeColumns;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;

use Math::PlanePath::GcdRationals;
*_gcd = \&Math::PlanePath::GcdRationals::_gcd;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ { name            => 'k',
      display         => 'k',
      type            => 'integer',
      default         => 3,
      minimum         => 2,
    },

    # Not sure about these yet.
    # { name            => 'reduced',
    #   display         => 'Reduced',
    #   type            => 'boolean',
    #   default         => 0,
    # },
    # { name            => 'points',
    #   share_key       => 'points_ea',
    #   display         => 'Points',
    #   type            => 'enum',
    #   default         => 'even',
    #   choices         => ['even','all_mul','all_div'],
    #   choices_display => ['Even','All Mul','All Div'],
    #   when_name       => 'k',
    #   when_condition  => 'odd',
    # },
    # { name            => 'digit_order',
    #   display         => 'Digit Direction',
    #   type            => 'enum',
    #   default         => 'HtoL',
    #   choices         => ['HtoL','LtoH'],
    #   choices_display => ['High to Low','Low to High'],
    # },

    Math::PlanePath::Base::Generic::parameter_info_nstart0(),
  ];

use constant class_x_negative => 0;
use constant class_y_negative => 0;

use constant x_minimum => 1;
use constant y_minimum => 1;

sub sumxy_minimum {
  my ($self) = @_;
  return ($self->{'reduced'} || $self->{'k'} == 2
          ? 2    # X=1,Y=1 if reduced or k=2
          : 3);  # X=1,Y=2
}
sub absdiffxy_minimum {
  my ($self) = @_;
  return ($self->{'k'} & 1
          ? 1    # k odd, X!=Y since one odd one even
          : 0);  # k even, has X=Y in top row
}
sub rsquared_minimum {
  my ($self) = @_;
  return ($self->{'k'} == 2
          || ($self->{'reduced'} && ($self->{'k'} & 1) == 0)
          ? 2    # X=1,Y=1 reduced k even, including k=2 top 1/1
          : 5);  # X=1,Y=2
}
sub gcdxy_maximum {
  my ($self) = @_;
  return ($self->{'k'} == 2       # k=2, RationalsTree CW above
          || $self->{'reduced'}
          ? 1
          : undef);  # other, unlimited
}

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'k'} & 1
          ? 1    # k odd
          : 0);  # k even, dX=0,dY=-1 at N=k/2 middle of roots
}
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'k'} == 2 || ($self->{'k'} & 1)
          ? 1    # k=2 or k odd
          : 0);  # k even, dX=1,dY=0 at N=k/2-1 middle of roots
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'k'} == 2
          ? (0,1)   # k=2, per RationalsTree CW

          # otherwise East
          # k even exact  dX=1,dY=0 middle of roots
          # k odd infimum dX=big,dY=-1 eg k=5 N="2222220"
          : (1,0));
}

sub tree_num_children_list {
  my ($self) = @_;
  return ($self->{'k'});   # complete tree, always k children
}
use constant tree_n_to_subheight => undef; # complete trees, all infinite

sub turn_any_left {
  my ($self) = @_;
  return ($self->{'k'} <= 3 || $self->{'reduced'});
}
sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'k'} >= 7);
}

# left reduced=1,k=5,7,9,11 at N=51,149,327,609,...
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  if ($self->{'k'} == 5 && $self->{'reduced'}) { return 51; }
  if ($self->{'k'} == 7 && $self->{'reduced'}) { return 149; }
  return undef;
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);

  $self->{'digit_order'} ||= 'HtoL'; # default

  my $k = ($self->{'k'} ||= 3);  # default
  $self->{'half_k'} = int($k / 2);

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = 0;      # default
  }

  $self->{'points'} ||= 'even';
  return $self;
}

# rows
# level=0   k-1
# level=1   k * (k-1)
# level=2   k^2 * (k-1)
# total (k-1)*(1+k+k^2+...+k^level)
#     = (k-1)*(k^(level+1) - 1)/(k-1)
#     = k^(level+1) - 1
#
# middle odd
# k(r+s)/2-r-2s / k(r+s)/2-s
# (k-1)(r+s)/2+r / (k-1)(r+s)/2+s
# k(r+s)/2-r-2s / k(r+s)/2-s
#
#   k=5
#   5(r+2)/2 -r-2s / 5(r+s)/2-s
#
# (1 + 2*x + 3*x^2 + 2*x^3 + x^4 + 2*x^5 + 3*x^6 + 2*x^7 + x^8)
# * (1 + 2*x^5 + 3*x^10 + 2*x^15 + x^20 + 2*x^25 + 3*x^30 + 2*x^35 + x^40)
# * (1 + 2*x^(25*1) + 3*x^(25*2) + 2*x^(25*3) + x^(25*4) + 2*x^(25*5) + 3*x^(25*6) + 2*x^(25*7) + x^(25*8))
#
# 1 2 3 2
# 1 4 7 8 5 2 7 12 13 8 3 8

# x^48 + 2*x^47 + 3*x^46 + 2*x^45 + x^44 + 4*x^43 + 7*x^42 + 8*x^41 + 5*x^40 + 2*x^39 + 7*x^38 + 12*x^37 + 13*x^36 + 8*x^35 + 3*x^34 + 8*x^33 + 13*x^32 + 12*x^31 + 7*x^30 + 2*x^29 + 5*x^28 + 8*x^27 + 7*x^26 + 4*x^25 + x^24 + 4*x^23 + 7*x^22 + 8*x^21 + 5*x^20 + 2*x^19 + 7*x^18 + 12*x^17 + 13*x^16 + 8*x^15 + 3*x^14 + 8*x^13 + 13*x^12 + 12*x^11 + 7*x^10 + 2*x^9 + 5*x^8 + 8*x^7 + 7*x^6 + 4*x^5 + x^4 + 2*x^3 + 3*x^2 + 2*x + 1


sub n_to_xy {
  my ($self, $n) = @_;
  ### ChanTree n_to_xy(): "$n   k=$self->{'k'} reduced=".($self->{'reduced'}||0)

  if ($n < $self->{'n_start'}) { return; }

  $n -= $self->{'n_start'}-1;
  ### 1-based N: $n
  if (is_infinite($n)) { return ($n,$n); }

  {
    my $int = int($n);
    if ($n != $int) {
      my $frac = $n - $int;  # inherit possible BigFloat/BigRat
      $int += $self->{'n_start'}-1;  # back to n_start() based
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
  }

  my $k = $self->{'k'};
  my $half_k = int($self->{'k'} / 2);
  my $half_ceil = int(($self->{'k'}+1) / 2);
  my @digits = digit_split_lowtohigh ($n, $k);
  ### @digits

  # top 1/2, 2/3, ..., (k/2-1)/(k/2), (k/2)/(k/2) ... 3/2, 2/1
  my $x = (pop @digits) + ($n*0);  # inherit bignum zero
  my $y = $x+1;
  if ($x > $half_k) {
    $x = $k+1 - $x;
  }
  if ($y > $half_k) {
    $y = $k+1 - $y;
  }
  ### top: "x=$x y=$y"


  # 1/2       2/3 3/4 ...
  # 1/4 4/7 7/10 10/13 ...

  # descend
  #
  # middle even
  # (k/2-1)(r+s)-s / (k/2)(r+s)-s
  # (k/2)(r+s)-s / (k/2)(r+s)
  # (k/2)(r+s) / (k/2)(r+s)-r
  # (k/2)(r+s)-r / (k/2-1)(r+s)-r
  #
  # k=4          r/s=1/2
  # r/2r+s         1/4
  # 2r+s/2r+2s     4/6
  # 2r+2s/r+2s     6/5
  # r+2s/s         5/1
  #
  # even eg k=4    half_k==2 half_ceil==2
  #    x + 0*(x+y) / x + 1*(x+y)     0    1x+0y / 2x+1y    <1/2
  #    x + 1*(x+y) /     2*(x+y)     1    2x+1y / 2x+2y    <2/3
  #    2*(x+y)     / 1*(x+y) + y     2    2x+2y / 1x+2y    >3/2
  #    1*(x+y) + y / 0*(x+y) + y     3    1x+2y / 0x+1y    >2/1
  #
  # even eg k=6    half_k==3 half_ceil==3
  #    x + 0*(x+y) / x + 1*(x+y)     0    1x+0y / 2x+1y
  #    x + 1*(x+y) / x + 2*(x+y)     1    2x+1y / 3x+2y
  #    x + 2*(x+y) / 3(x+y)          2    3x+2y / 3x+3y
  #        3*(x+y) / 2*(x+y) + y     3    3x+3y / 2x+3y
  #    2*(x+y) + y / 1*(x+y) + y     4    2x+3y / 1x+2y
  #    1*(x+y) + y / 0*(x+y) + y     5    1x+2y / 0x+1y
  #
  # odd eg k=3   half_k==1 half_ceil==2
  #    x + 0*(x+y) / x + 1*(x+y)     0    1x+0y / 2x+1y    <1/2
  #    x + 1*(x+y) / 1*(x+y) + y     1    2x+1y / 1x+2y
  #    1*(x+y) + y / 0*(x+y) + y     2    1x+2y / 0x+1y    >2/1
  #
  # odd eg k=5   half_k==2 half_ceil==3
  #    x + 0*(x+y) / x + 1*(x+y)     0    1x+0y / 2x+1y    <1/2
  #    x + 1*(x+y) / x + 2*(x+y)     1    2x+1y / 3x+2y    <2/3
  #    x + 2*(x+y) / 2*(x+y) + y     2    3x+2y / 2x+3y
  #    2*(x+y) + y / 1*(x+y) + y     3    2x+3y / 1x+2y    >3/2
  #    1*(x+y) + y / 0*(x+y) + y     4    1x+2y / 0x+1y    >2/1

  if ($self->{'digit_order'} eq 'HtoL') {
    @digits = reverse @digits;   # high to low is the default
  }
  foreach my $digit (@digits) {
    # c1 = 1,2,3,3,2,1 or 1,2,3,2,1
    my $c0 = ($digit <= $half_ceil ? $digit : $k-$digit+1);
    my $c1 = ($digit < $half_ceil ? $digit+1 : $k-$digit);
    my $c2 = ($digit < $half_ceil-1 ? $digit+2 : $k-$digit-1);
    ### at: "x=$x y=$y  next digit=$digit  $c1,$c0  $c2,$c1"

    ($x,$y) = ($x*$c1 + $y*$c0,
               $x*$c2 + $y*$c1);
  }
  ### loop: "x=$x y=$y"

  if (($k & 1) && ($n % 2) == 0) {   # odd N=2n+1 when 1 based
    if ($self->{'points'} eq 'all_div') {
      $x /= 2;
      ### all_div divide X to: "x=$x y=$y"
    } elsif ($self->{'points'} eq 'all_mul') {
      if ($self->{'reduced'} && ($x % 2) == 0) {
        $x /= 2;
        ### all_mul reduced divide X to: "x=$x y=$y"
      } else {
        $y *= 2;
        ### all_mul multiply Y to: "x=$x y=$y"
      }
    }
  }

  if ($self->{'reduced'}) {
    ### unreduced: "x=$x y=$y"
    if ($k & 1) {
      # k odd, gcd(x,y)=k^m for some m, divide out factors of k as possible
      foreach (0 .. scalar(@digits)) {
        last if ($x % $k) || ($y % $k);
        $x /= $k;
        $y /= $k;
      }
    } else {
      # k even, gcd(x,y) divides (k/2)^m for some m, but gcd isn't
      # necessarily equal to such a power, only a divisor of it, so must do
      # full gcd calculation
      my $g = _gcd($x,$y);
      $x /= $g;
      $y /= $g;
    }
  }

  ### n_to_xy() return: "x=$x  y=$y"
  return ($x,$y);
}

# (3*pow+1)/2 - (pow+1)/2
#     = (3*pow + 1 - pow - 1)/2
#     = (2*pow)/2
#     = pow
#
sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### Chan xy_to_n(): "x=$x y=$y   k=$self->{'k'}"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if (is_infinite($x)) {
    return $x;  # infinity
  }
  if (is_infinite($y)) {
    return $y;  # infinity
  }
  my $orig_x = $x;
  my $orig_y = $y;

  my $k = $self->{'k'};
  my $zero = ($x * 0 * $y);  # inherit bignum
  my $half_k = $self->{'half_k'};
  my $half_ceil = int(($self->{'k'}+1) / 2);

  if ($k & 1) {
    if ($self->{'points'} eq 'all_div'
        || ($self->{'points'} eq 'all_mul' && ($self->{'reduced'}))) {
      my $n = do {
        local $self->{'points'} = 'even';
        $self->xy_to_n(2*$x,$y)
      };
      if (defined $n) {
        my ($nx,$ny) = $self->n_to_xy($n);
        if ($nx == $x && $ny == $y) {
          return $n;
        }
      }
    }
    if ($self->{'points'} eq 'all_mul' && ($y % 2) == 0) {
      my $n = do {
        local $self->{'points'} = 'even';
        $self->xy_to_n($x,$y/2)
      };
      if (defined $n) {
        my ($nx,$ny) = $self->n_to_xy($n);
        if ($nx == $x && $ny == $y) {
          return $n;
        }
      }
    }

    # k odd cannot have X,Y both odd
    if (($x % 2) && ($y % 2)) {
      return undef;
    }
  }

  if (ref $x && ref $y && $x < 0xFF_FFFF && $y < 0xFF_FFFF) {
    # numize BigInt for speed
    $x = "$x";
    $y = "$y";
  }

  if ($self->{'reduced'}) {
    ### unreduced: "x=$x y=$y"
    unless (_coprime($x,$y)) {
      return undef;
    }
  }

  # left t'th child (t-1)/t < x/y < t/(t+1)       x/y<1  t=1,2,3,...
  #   x/y < (t-1)/t
  #   xt < (t-1)y
  #   xt < ty-y
  #   y < (y-x)t
  #   t > y/(y-x)
  #
  #   lx = x + (t-1)*(x+y) = t*x + (t-1)y         # t=1 upwards
  #   ly = x + t*(x+y)     = (t+1)x + ty
  #   t*lx - (t-1)*ly
  #      = t*t*x - (t-1)(t+1)x
  #      = (t^2 - (t^2 - 1))x
  #      = x
  #   x = t*lx - (t-1)*ly
  #
  #   lx = x + (t-1)*(x+y)
  #   ly = x + t*(x+y)
  #   ly-lx = x+y
  #   y = ly-lx - x
  #     = ly-lx - (t*lx - (t-1)*ly)
  #     = ly-lx - t*lx + (t-1)*ly
  #     = (-1-t)*lx + (1 + t-1)*ly
  #     = t*ly - (t+1)*lx
  #
  # right t'th child is (t+1)/t < x/y < t/(t-1)       x/y > 1
  #   (t+1)*y < t*x
  #   ty+y < tx
  #   t(x-y) > y
  #   t > y/(x-y)
  #
  #   lx = y + t*(x+y)       = t*x + (t+1)y
  #   ly = y + (t-1)*(x+y)   = (t-1)x + ty
  #   t*lx - (t+1)*ly
  #      = t*t*x - (t+1)(t-1)x
  #      = (t^2 - (t^2 - 1))x
  #      = x
  #   x = t*lx - (t+1)*ly
  #
  #   lx-ly = x+y
  #   y = lx-ly - x
  #     = lx - ly - t*lx + (t+1)*ly
  #     = (1-t)*lx + t*ly
  #     = t*ly - (t-1)*lx
  #
  # middle odd
  #   lx = x + t*(x+y)   = (t+1)x + ty
  #   ly = y + t*(x+y)   = tx + (t+1)y
  #   (t+1)*lx - t*ly
  #     = (t+1)*(t+1)*x - t*t*x
  #     = (2t+1)*x
  #   x = ((t+1)*lx - t*ly) / k          with 2t+1=k
  #   lx-ly = x-y
  #   y = ly - lx + x
  #     = x-diff
  #   ky = kx-k*diff
  #
  #   (t+1)*ly - t*lx
  #     = (t+1)*(t+1)*y - t*t*y
  #     = (2t+1)*y
  #
  # eg. k=11 x=6 y=5 t=5 -> child_x=6+5*(6+5)=61 child_y=5+5*(6+5)=60
  #     N=71 digits=5,6 top=6,5 -> 61,60
  #     low diff=11-10=1  k*ly-k*lx + x
  #
  # middle even first, t=k/2
  #   lx = tx + (t-1)y      # eg. x + 2*(x+y) / 3(x+y)  =  3x+2y / 3x+3y
  #   ly = tx + ty
  #   y = ly-lx
  #   t*x = ly - t*y
  #   x = ly/t - y
  #   eg k=4 lx=6,ly=10 t=2  y=10-6=4  x=10/2-4=1
  # middle even second, t=k/2
  #   lx = tx + ty          # eg. 3*(x+y) / 2*(x+y) + y  =  3x+3y / 2x+3y
  #   ly = (t-1)x + ty
  #   x = lx-ly
  #   t*y = lx - t*x
  #   y = lx/t - x

  my @digits;
  for (;;) {
    ### at: "x=$x, y=$y"
    ### assert: $x==int($x)
    ### assert: $y==int($y)

    if ($x < 1 || $y < 1) {
      ### X,Y negative, no such point ...
      return undef;
    }

    if ($x == $y) {
      if ($x == $half_k) {
        ### X=Y=half_k, done: $half_k
        push @digits, $x;
        last;
      } elsif ($x == 1 && $self->{'reduced'}) {
        ### X=Y=1 reduced, is top middle ...
        push @digits, $half_k;
        last;
      } else {
        ### X=Y, no such point ...
        return undef;
      }
    }

    my $diff = $x - $y;
    if ($diff < 0) {
      ### X<Y, left of row ...

      if ($diff == -1 && $x < $half_ceil) {
        ### end at diff=-1 ...
        push @digits, $x;
        last;
      }

      my ($t) = _divrem ($y, -$diff);   # y/(y-x)
      ### $t
      if ($t < $half_ceil) {
        # eg. k=4 t=1,  k=5 t=1,2  k=6 t=1,2  k=7 t=1,2,3
        ($x,$y) = ($t*$x - ($t-1)*$y,
                   $t*$y - ($t+1)*$x);
        push @digits, $t-1;

      } else {
        if ($k & 1) {
          ### left middle odd, t=half_k ...
          # x = ((t+1)*lx - t*ly) / k with 2t+1=k  t=(k-1)/2
          my $next_x = $half_ceil * $x - $half_k * $y;
          ### $next_x
          if ($next_x % $k) {
            unless ($self->{'reduced'}) {
              ### no divide k, no such point ...
              return undef;
            }
            $diff *= $k;
            ### no divide k, diff increased to: $diff
          } else {
            ### divide k ...
            $next_x /= $k;    # X = ((t+1)X - tY) / k
          }
          $x = $next_x;
          $y = $next_x - $diff;
        } else {
          ### left middle even, t=half_k ...
          my $next_y = $y - $x;
          ### $next_y
          if ($y % $half_k) {
            ### y not a multiple of half_k ...
            unless ($self->{'reduced'}) {
              return undef;
            }
            my $g = _gcd($y,$half_k);
            $y /= $g;
            $next_y *= $half_k / $g;
            ($x,$y) = ($y - $next_y,  # x = ly/t - y
                       $next_y);      # y = ly - lx
          } else {
            ### divide half_k ...
            ($x,$y) = ($y/$half_k - $next_y,  # x = ly/t - y
                       $next_y);              # y = ly - lx
          }
        }
        push @digits, $half_ceil-1;
      }

    } else {
      ### X>Y, right of row ...
      if ($diff == 1 && $y < $half_ceil) {
        ### end at diff=1 ...
        push @digits, $k+1-$x;
        last;
      }

      my ($t) = _divrem ($x, $diff);
      ### $t
      if ($t < $half_ceil) {
        ($x,$y) = ($t*$x - ($t+1)*$y,
                   $t*$y - ($t-1)*$x);
        push @digits, $k-$t;

      } else {
        if ($k & 1) {
          ### right middle odd ...
          # x = ((t+1)*lx - t*ly) / k with 2t+1=k  t=(k-1)/2
          my $next_x = $half_ceil * $x - $half_k * $y;
          ### $next_x
          if ($next_x % $k) {
            unless ($self->{'reduced'}) {
              ### no divide k, no such point ...
              return undef;
            }
            $diff *= $k;
            ### no divide k, diff increased to: $diff
          } else {
            ### divide k ...
            $next_x /= $k;    # X = ((t+1)X - tY) / k
          }
          $x = $next_x;
          $y = $next_x - $diff;
          push @digits, $half_k;
        } else {
          ### right middle even ...

          my $next_x = $x - $y;
          if ($x % $half_k) {
            ### x not a multiple of half_k ...
            unless ($self->{'reduced'}) {
              return undef;
            }
            # multiply lx,ly by half_k/gcd so lx is a multiple of half_k
            my $g = _gcd($x,$half_k);
            $x /= $g;
            $next_x *= $half_k / $g;
            ($x,$y) = ($next_x,         # x = lx-ly
                       $x - $next_x);   # y = lx/t - x
          } else {
            ### divide half_k ...
            ($x,$y) = ($next_x,                 # x = lx-ly
                       $x/$half_k - $next_x);   # y = lx/t - x
          }
          push @digits, $half_k;
        }
      }
    }
  }

  ### @digits
  if ($self->{'digit_order'} ne 'HtoL') {
    my $high = pop @digits;
    @digits = (reverse(@digits), $high);
    ### reverse digits to: @digits
  }
  my $n = digit_join_lowtohigh (\@digits, $k, $zero) + $self->{'n_start'}-1;
  ### $n

  # if (! $self->{'reduced'})
  {
    my ($nx,$ny) = $self->n_to_xy($n);
    ### reversed to: "$nx, $ny  cf orig $orig_x, $orig_y"
    if ($nx != $orig_x || $ny != $orig_y) {
      return undef;
    }
  }

  ### xy_to_n result: "n=$n"
  return $n;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ChanTree rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < 1 || $y2 < 1) {
    return (1,0);
  }

  my $zero = ($x1 * 0 * $y1 * $x2 * $y2);  # inherit bignum
  if ($self->{'points'} eq 'all_div') {
    $x2 *= 2;
  }

  my $max = max($x2,$y2);
  my $level = ($self->{'reduced'} || $self->{'k'} == 2   # k=2 is reduced
               ? $max + 1
               : int($max/2));

  return ($self->{'n_start'},
          $self->{'n_start'}-2 + ($self->{'k'}+$zero)**$level);
}

#------------------------------------------------------------------------------
# (N - (Nstart-1))*k + Nstart   run -1 to k-2
#   = N*k - (Nstart-1)*k + Nstart   run -1 to k-2
#   = N*k - k*Nstart + k + Nstart   run -1 to k-2
#   = (N+1)*k + (1-k)*Nstart   run -1 to k-2
# k*Nstart - k - Nstart + 1 = (k-1)*(Nstart-1)
#   = N*k - (k-1)*(Nstart-1) +1   run -1 to k-2
#   = N*k - (k-1)*(Nstart-1)    run 0 to k-1
#
sub tree_n_children {
  my ($self, $n) = @_;
  my $n_start = $self->{'n_start'};
  unless ($n >= $n_start) {
    return;
  }
  my $k = $self->{'k'};
  $n = $n*$k - ($k-1)*($n_start-1);
  return map {$n+$_} 0 .. $k-1;
}
sub tree_n_num_children {
  my ($self, $n) = @_;
  return ($n >= $self->{'n_start'} ? $self->{'k'} : undef);
}

# parent = floor((N-Nstart+1) / k) + Nstart-1
#        = floor((N-Nstart+1 + k*Nstart-k) / k)
#        = floor((N + (k-1)*(Nstart-1)) / k)
# N-(Nstart-1) >= k
# N-Nstart+1 >= k
# N-Nstart >= k-1
# N >= k-1+Nstart
# N >= k+Nstart-1
sub tree_n_parent {
  my ($self, $n) = @_;
  ### ChanTree tree_n_parent(): $n
  my $n_start = $self->{'n_start'};
  $n = $n - ($n_start-1);   # to N=1 basis, and warn if $n undef
  my $k = $self->{'k'};
  unless ($n >= $k) {
    ### root node, no parent ...
    return undef;
  }
  _divrem_mutate ($n, $k);   # delete low digit ...
  return $n + ($n_start-1);
}
sub tree_n_to_depth {
  my ($self, $n) = @_;
  ### ChanTree tree_n_to_depth(): $n
  $n = $n - $self->{'n_start'} + 1;   # N=1 basis, and warn if $n==undef
  unless ($n >= 1) {
    return undef;
  }
  my ($pow, $exp) = round_down_pow ($n, $self->{'k'});
  return $exp;     # floor(log base k (N-Nstart+1))
}
sub tree_depth_to_n {
  my ($self, $depth) = @_;
  return ($depth >= 0
          ? $self->{'k'}**$depth + ($self->{'n_start'}-1)
          : undef);
}

sub tree_num_roots {
  my ($self) = @_;
  return $self->{'k'} - 1;
}
sub tree_root_n_list {
  my ($self) = @_;
  my $n_start = $self->{'n_start'};
  return $n_start .. $n_start + $self->{'k'} - 2;
}

sub tree_n_root {
  my ($self, $n) = @_;
  my $n_start_offset = $self->{'n_start'} - 1;
  $n = $n - $n_start_offset;   # N=1 basis, and warn if $n==undef
  return ($n >= 1
          ? _high_digit($n,$self->{'k'}) + $n_start_offset
          : undef);
}
# Return the most significant digit of $n written in base $radix.
sub _high_digit {
  my ($n, $radix) = @_;
  ### assert: ! ($n < 1)
  my ($pow) = round_down_pow ($n, $radix);
  _divrem_mutate($n,$pow);  # $n=quotient
  return $n;
}

1;
__END__

=for stopwords Ryde Math-PlanePath Heng coeffs GCD Calkin-Wilf ie Nstart OEIS k-ary generalization

=head1 NAME

Math::PlanePath::ChanTree -- tree of rationals

=head1 SYNOPSIS

 use Math::PlanePath::ChanTree;
 my $path = Math::PlanePath::ChanTree->new (k => 3, reduced => 0);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Chan, Song Heng>This path enumerates rationals X/Y in a tree as per

=over

Song Heng Chan, "Analogs of the Stern Sequence", Integers 2011,
L<http://www.integers-ejcnt.org/l26/l26.pdf>

=back

The default k=3 visits X,Y with one odd, one even, and perhaps a common
factor 3^m.

=cut

# math-image --path=ChanTree --all --output=numbers_xy --size=62x15

=pod

     14 |    728              20                              12
     13 |         53      11      77      27
     12 |    242              14              18
     11 |
     10 |     80
      9 |         17      23       9                      15
      8 |     26                                              78
      7 |
      6 |      8                              24              28
      5 |          5       3                              19
      4 |      2               6              10              22
      3 |
      2 |      0               4              16              52
      1 |          1       7      25      79     241     727
    Y=0 |
        +--------------------------------------------------------
         X=0   1   2   3   4   5   6   7   8   9  10  11  12  13

There are 2 tree roots (so technically it's a "forest") and each node has 3
children.  The points are numbered by rows starting from N=0.  This
numbering corresponds to powers in a polynomial product generating function.

    N=0 to 1               1/2                    2/1
                         /  |  \                /  |  \
    N=2 to 7          1/4  4/5   5/2         2/5  5/4  4/1
                     / | \  ...   ...      ...   ...  / | \
    N=8 to 25     1/6 6/9 9/4  ...            ...  5/9 9/6 6/1

    N=26 ...        

The children of each node are

                    X/Y
       ------------/ | \-----------
      |              |             |
    X/(2X+Y)   (2X+Y)/(X+2Y)   (X+2Y)/Y

Which as X,Y coordinates means vertical, 45-degree diagonal, and horizontal.

    X,Y+2X      X+(X+Y),Y+(X+Y)
      |       /
      |     /
      |   /
      | /
     X,Y------- X+2Y,Y

The slowest growth is on the far left of the tree 1/2, 1/4, 1/6, 1/8, etc
advancing by just 2 at each level.  Similarly on the far right 2/1, 4/1,
6/1, etc.  This means that to cover such an X or Y requires a power-of-3,
N=3^(max(X,Y)/2).

=head2 GCD

Chan shows that these top nodes and children visit all rationals X/Y with
X,Y one odd, one even.  But the X,Y are not in least terms, they may have a
power-of-3 common factor GCD(X,Y)=3^m for some m.

The GCD is unchanged in the first and third children.  The middle child GCD
might gain an extra factor 3.  This means the power is at most the number of
middle legs taken, which is the count of ternary 1-digits of its position
across the row.

    GCD(X,Y) = 3^m
    m <= count ternary 1-digits of N+1, excluding high digit

As per L</N Start> below, N+1 in ternary has high digit 1 or 2 which
indicates the tree root.  Ignoring that high digit gives an offset into the
row of that tree and the digits are 0,1,2 for left,middle,right.

For example the first GCD is at N=9 with X=6,Y=9 common factor GCD=3.
N+1=10="101" ternary, which without the high digit is "01" which has a
single "1" so GCD <= 3^1.  The mirror image of this point is X=9,Y=6 at N=24
and there N+1=24+1=25="221" ternary which without the high digit is "21"
with a single 1-digit likewise.

For various points the power m is equal to the count of 1-digits.

=head2 k Parameter

Parameter C<k =E<gt> $integer> controls the number of children and top
nodes.  There are k-1 top nodes and each node has k children.  The top nodes
are

    k odd, k-1 many tops, with h=ceil(k/2)
    1/2  2/3  3/4  ... (h-1)/h       h/(h-1) ...  4/3  3/2  2/1

    k even, k-1 many tops, with h=k/2
    1/2  2/3  3/4  ... (h-1)/h  h/h  h/(h-1) ...  4/3  3/2  2/1

Notice the list for k odd or k even is the same except that for k even
there's an extra middle term h/h.  The first few tops are as follows.  The
list in each row is spread to show how successive bigger h adds terms in the
middle.

     k                 X/Y top nodes
    ---    ---------------------------------
    k=2                   1/1

    k=3              1/2       2/1
    k=4              1/2  2/2  2/1

    k=5         1/2  2/3       3/2  2/1
    k=6         1/2  2/3  3/3  3/2  2/1

    k=7    1/2  2/3  3/4       4/3  3/2  2/1
    k=8    1/2  2/3  3/4  4/4  4/3  3/2  2/1

As X,Y coordinates these tops are a run up along X=Y-1 and back down along
X=Y+1, with a middle X=Y point if k even.  For example,

=cut

# math-image --path=ChanTree,k=13 --output=numbers --expression='i<12?i:0'
# math-image --path=ChanTree,k=14 --output=numbers --expression='i<13?i:0'

=pod

      7 |                         5         k=13 top nodes N=0 to N=11
      6 |                     4       6        total 12 top nodes
      5 |                 3       7
      4 |             2       8
      3 |         1       9
      2 |     0      10
      1 |        11
    Y=0 |
        +------------------------------
        X=0   1   2   3   4   5   6   7

                                            k=14 top nodes N=0 to N=12
      7 |                         5   6        total 13 top nodes
      6 |                     4       7
      5 |                 3       8         N=6 is the 7/7 middle term
      4 |             2       9
      3 |         1      10
      2 |     0      11
      1 |        12
    Y=0 |
        +------------------------------
        X=0   1   2   3   4   5   6   7

Each node has k children.  The formulas for the children can be seen from
sample cases k=5 and k=6.  A node X/Y descends to

    k=5                     k=6

    1X+0Y / 2X+1Y           1X+0Y / 2X+1Y
    2X+1Y / 3X+2Y           2X+1Y / 3X+2Y
    3X+2Y / 2X+3Y           3X+2Y / 3X+3Y
    2X+3Y / 1X+2Y           3X+3Y / 2X+3Y
    1X+2Y / 0X+1Y           2X+3Y / 1X+2Y
                            1X+2Y / 0X+1Y

The coefficients of X and Y run up to h=ceil(k/2) starting from either 0, 1
or 2 and ending 2, 1 or 0.  When k is even there's two h coeffs in the
middle.  When k is odd there's just one.  The resulting tree for example
with k=4 is

    k=4
          1/2              2/2               2/1
       /       \        /        \        /       \
    1/4 4/6 6/5 5/2  2/6 6/8 8/6 6/2   2/5 5/6 6/4 4/1

Chan shows that this combination of top nodes and children visits

    if k odd:    rationals X/Y with X,Y one odd, one even
                  possible GCD(X,Y)=k^m for some integer m

    if k even:   all rationals X/Y
                  possible GCD(X,Y) a divisor of (k/2)^m

When k odd, GCD(X,Y) is a power of k, so for example as described above k=3
gives GCD=3^m.  When k even GCD(X,Y) is a divisor of (k/2)^m but not
necessarily a full such power.  For example with k=12 the first such
non-power GCD is at N=17 where X=16,Y=18 has GCD(16,18)=2 which is only a
divisor of k/2=6, not a power of 6.

=head2 N Start

The C<n_start =E<gt> $n> option can select a different initial N.  The tree
structure is unchanged, just the numbering shifted.  As noted above the
default Nstart=0 corresponds to powers in a generating function.

C<n_start=E<gt>1> makes the numbering correspond to digits of N written in
base-k.  For example k=10 corresponds to N written in decimal,

    N=1 to 9                1/2    ...  ...    2/1

    N=10 to 99          1/4 4/7  ...      ...  7/4 4/1

    N=100 to 999    1/6 6/11   ...          ...   11/6 6/1

In general C<n_start=E<gt>1> makes the tree

    N written in base-k digits
     depth = numdigits(N)-1
     NdepthStart = k^depth
                 = 100..000 base-k, high 1 in high digit position of N
     N-NdepthStart = position across whole row of all top trees

And the high digit of N selects which top-level tree the given N is under,
so

    N written in base-k digits
     top tree = high digit of N
                (1 to k, selecting the k-1 many top nodes)
     Nrem = digits of N after the highest
          = position across row within the high-digit tree
     depth = numdigits(Nrem)       # top node depth=0
           = numdigits(N)-1

=head2 Diatomic Sequence

Chan shows that each denominator Y becomes the numerator X in the next
point.  The last Y of a row becomes the first X of the next row.  This is a
generalization of Stern's diatomic sequence and of the Calkin-Wilf tree of
rationals.  (See L<Math::NumSeq::SternDiatomic> and
L<Math::PlanePath::RationalsTree/Calkin-Wilf Tree>.)

The case k=2 is precisely the Calkin-Wilf tree.  There's just one top node
1/1, being the even k "middle" form h/h with h=k/2=1 as described above.
Then there's two children of each node (the "middle" pair of the even k
case),

    k=2, Calkin-Wilf tree

                     X/Y
                   /     \
    (1X+0Y)/(1X+1Y)       (1X+1Y)/(0X+1Y)
       = X/(X+Y)             = (X+Y)/Y

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ChanTree-E<gt>new ()>

=item C<$path = Math::PlanePath::ChanTree-E<gt>new (k =E<gt> $k, n_start =E<gt> $n)>

Create and return a new path object.  The defaults are k=3 and n_start=0.

=item C<$n = $path-E<gt>n_start()>

Return the first N in the path.  This is 0 by default, otherwise the
C<n_start> parameter.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  If there's nothing at
C<$x,$y> then return C<undef>.

=back

=head2 Tree Methods

X<Complete n-ary tree>Each point has k children, so the path is a complete
k-ary tree.

=over

=item C<@n_children = $path-E<gt>tree_n_children($n)>

Return the children of C<$n>, or an empty list if C<$n E<lt> n_start()>,
ie. before the start of the path.

=item C<$num = $path-E<gt>tree_n_num_children($n)>

Return k, since every node has k children.  Or return C<undef> if C<$n E<lt>
n_start()>, ie. before the start of the path.

=item C<$n_parent = $path-E<gt>tree_n_parent($n)>

Return the parent node of C<$n>, or C<undef> if C<$n> has no parent either
because it's a top node or before C<n_start()>.

=item C<$n_root = $path-E<gt>tree_n_root ($n)>

Return the N which is root node of C<$n>.

=item C<$depth = $path-E<gt>tree_n_to_depth($n)>

Return the depth of node C<$n>, or C<undef> if there's no point C<$n>.  The
tree tops are depth=0, then their children depth=1, etc.

=item C<$n = $path-E<gt>tree_depth_to_n($depth)>

=item C<$n = $path-E<gt>tree_depth_to_n_end($depth)>

Return the first or last N at tree level C<$depth> in the path.  The top of
the tree is depth=0.

=back

=head2 Tree Descriptive Methods

=over

=item C<$num = $path-E<gt>tree_num_roots ()>

Return the number of root nodes in C<$path>, which is k-1.  For example the
default k=3 return 2 as there are two root nodes.

=item C<@n_list = $path-E<gt>tree_root_n_list ()>

Return a list of the N values which are the root nodes of C<$path>.  This is
C<n_start()> through C<n_start()+k-2> inclusive, being the first k-1 many
points.  For example in the default k=2 and Nstart=0 the return is two
values C<(0,1)>.

=item C<$num = $path-E<gt>tree_num_children_minimum()>

=item C<$num = $path-E<gt>tree_num_children_maximum()>

Return k since every node has k many children, making that both the minimum
and maximum.

=item C<$bool = $path-E<gt>tree_any_leaf()>

Return false, since there are no leaf nodes in the tree.

=back

=head1 FORMULAS

=head2 N Children

For the default k=3 the children are

    3N+2, 3N+3, 3N+4        n_start=0

If C<n_start=E<gt>1> then instead

    3N, 3N+1, 3N+2                  n_start=1

For this C<n_start=1> the children are found by appending an extra ternary
digit, or base-k digit for arbitrary k.

    k*N, k*N+1, ... , k*N+(k-1)     n_start=1

In general for k and Nstart the children are

    kN - (k-1)*(Nstart-1)  + 0
      ...
    kN - (k-1)*(Nstart-1)  + k-1

=head2 N Parent

The parent node reverses the children calculation above.  The simplest case
is C<n_start=1> where it's a division to remove the lowest base-k
digit

    parent = floor(N/k)       when n_start=1

For other C<n_start> adjust before and after to an C<n_start=1> basis,

    parent = floor((N-(Nstart-1)) / k) + Nstart-1

For example in the default k=0 Nstart=1 the parent of N=3 is
floor((3-(1-1))/3)=1.

The post-adjustment can be worked into the formula with (k-1)*(Nstart-1)
similar to the children above,

    parent = floor((N + (k-1)*(Nstart-1)) / k)

But the first style is more convenient to compare to see that N is past the
top nodes and therefore has a parent.

    N-(Nstart-1) >= k      to check N is past top-nodes

=head2 N Root

As described under L</N Start> above, if Nstart=1 then the tree root is
simply the most significant base-k digit of N.  For other Nstart an
adjustment is made to N=1 style and back again.

    adjust = Nstart-1
    Nroot(N) = high_base_k_digit(N-adjust) + adjust

=head2 N to Depth

The structure of the tree means

    depth = floor(logk(N+1))    for n_start=0

For example if k=3 then all of N=8 through N=25 inclusive have
depth=floor(log3(N+1))=2.  With an C<n_start> it becomes

    depth = floor(logk(N-(Nstart-1)))

C<n_start=1> is the simplest case, being the length of N written in base-k
digits.

    depth = floor(logk(N))     for n_start=1

=head1 OEIS

This tree is in Sloane's Online Encyclopedia of Integer Sequences as

=over

L<http://oeis.org/A191379> (etc)

=back

    k=3, n_start=0  (the defaults)
      A191379   X coordinate, and Y=X(N+n)

As noted above k=2 is the Calkin-Wilf tree.  See
L<Math::PlanePath::RationalsTree/OEIS> for "CW" related sequences.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::PythagoreanTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
