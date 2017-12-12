# Copyright 2014, 2015, 2016, 2017 Kevin Ryde

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


# much overlap


package Math::PlanePath::Z2DragonCurve;
use 5.004;
use strict;
use List::Util 'min'; # 'max'
*max = \&Math::PlanePath::_max;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'xy_is_even';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh';

use vars '$VERSION', '@ISA';
$VERSION = 125;
@ISA = ('Math::PlanePath');

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

#------------------------------------------------------------------------------
#
#        .
#        h
#        .
#        .........
#                .
#            ....g...
#            .   .
#        .   .   .
#        .   .
#     .. f..10---d--11
#        .   |
#        7...|....
#        |   |   .
#    8---c---9   e
#        |       .
#        6-------5                 3
#                |
#            2---b---3             2
#            |   |
#            |   4                 1
#            |
#    0---a---1                     0
# 
#    0   1   2   3   4       

#           10---*--11
#            |
#        7   |
#        |   |
#    8---*---9
#        |
#        6-------5
#           \ /  |  \
#            2--/*---3
#           /|\  |/   \
#            |   4
#   \     / \|/ /
#    0---*---1
#     \ /   / \

sub n_to_xy {
  my ($self, $n) = @_;
  ### Z2DragonCurve n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $zero = ($n * 0);  # inherit bignum 0

  {
    # high to low

    my $x = 0;
    my $y = 0;
    my $dx = 1;
    my $dy = 0;
    # return if $n >=9;

    my $lowdigit = _divrem_mutate($n, 4);
    my @digits = digit_split_lowtohigh($n,3);

    foreach my $digit (reverse(@digits), $lowdigit) {
      ### at: "$x,$y  digit=$digit"
      ($x,$y) = ($x-$y,$x+$y); # rotate +45
      $x += 1;
      ### rotate to: "$x,$y"

      if ($digit == 0) {
        $x -= $dx;
        $y -= $dy;

      } elsif ($digit == 1) {
        $x += $dx;
        $y += $dy;
        ($dx,$dy) = (-$dy,$dx); # rotate +90

      } elsif ($digit == 2) {
        $x += $dx - 2*$dy;   # across then at +90
        $y += $dy + 2*$dx;

      } elsif ($digit == 3) {
        $x += 3*$dx - 2*$dy;   # across then at +90, for $lowdigit
        $y += 3*$dy + 2*$dx;
      }
    }

    ### return: "$x,$y"
    return ($x,$y);
  }
  {
    # low to high

    my $x = 0;
    my $y = 0;
    my $dx = 1 + $zero;
    my $dy = $zero;
    return if $n >=16;
    my $lowdigit = _divrem_mutate($n, 3);
    if ($lowdigit == 0) {

    } elsif ($lowdigit == 1) {
      $x = 2;

    } elsif ($lowdigit == 2) {
      $x = 2;
      $y = 2;

    } elsif ($lowdigit == 3) {
      $x = 4;
      $y = 2;
    }

    foreach my $digit (digit_split_lowtohigh($n,3)) {
      # $dx *= 2;
      # $dy *= 2;
      ($dx,$dy) = ($dx+$dy,$dy-$dx); # rotate 45
      # ($dx,$dy) = (-$dy,$dx); # rotate +90

      if ($digit == 0) {

      } elsif ($digit == 1) {
        ($x,$y) = (-$y,$x); # rotate +90
        $x += 3/2*$dx;
        $y += 3/2*$dy;
        ($dx,$dy) = (-$dy,$dx); # rotate +90
        $x += 1/2*$dx;
        $y += 1/2*$dy;

      } elsif ($digit == 2) {
        $x -= 4/2*$dy;
        $y += 4/2*$dx;
      }
    }

    return ($x,$y);
  }
}


sub xy_to_n {
  my ($self, $x, $y) = @_;
  return undef;
}


# minimum  -- no, not quite right
#
#                *----------*
#                 \
#                  \   *
#               *   \
#                    \
#          *----------*
#
# width = side/2
# minimum = side*sqrt(3)/2 - width
#         = side*(sqrt(3)/2 - 1)
#
# minimum 4/9 * 2.9^level roughly
# h = 4/9 * 2.9^level
# 2.9^level = h*9/4
# level = log(h*9/4)/log(2.9)
# 3^level = 3^(log(h*9/4)/log(2.9))
#         = h*9/4, but big bigger for log
#
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### Z2DragonCurve rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0,
          ($xmax*$xmax + $ymax*$ymax + 1));
}

1;
__END__
