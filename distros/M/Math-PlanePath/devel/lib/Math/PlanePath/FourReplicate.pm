# Copyright 2013, 2014, 2015, 2016 Kevin Ryde

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


# Working. But what is this properly called?

# strips N mod 3      (X-Y)/2 == N mod 3



package Math::PlanePath::FourReplicate;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use Math::PlanePath;
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest',
  'xy_is_even';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';

use vars '$VERSION', '@ISA';
$VERSION = 124;
@ISA = ('Math::PlanePath');

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

#------------------------------------------------------------------------------

my @digit_to_x   = (0,2,-1,-1);
my @digit_to_y   = (0,0, 1,-1);

sub n_to_xy {
  my ($self, $n) = @_;
  ### FourReplicate n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n, $n); }

  my $zero = ($n * 0);  # inherit bignum 0
  my $x = my $y = $zero;
  my $len = $zero + 1;
  foreach my $digit (digit_split_lowtohigh($n,4)) {
    $x += $len * $digit_to_x[$digit];
    $y += $len * $digit_to_y[$digit];
    $len = -2*$len;
  }

  return ($x, $y);
}


# all even points when arms==6
*xy_is_visited = \&xy_is_even;

#    -1,1
#      * . * .
#       \
#      . *-.-* 2,0
#       /
#      * . * .
#    -1,-1
#
# $x % 4
# $y % 4
#
# 3 |     2       3
# 2 | 1       0
# 1 |     3       2
# 0 | 0       1
#   +---------------
#     0   1   2   3

my @yx_to_digit = ([ 0,     undef, 1,     undef ],
                   [ undef, 3,     undef, 2     ],
                   [ 1,     undef, 0,     undef ],
                   [ undef, 2,     undef, 3     ]);

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest($x);
  $y = round_nearest($y);

  if (is_infinite($x)) {
    return $x;  # infinity
  }
  if (is_infinite($y)) {
    return $y;  # infinity
  }

  my $zero = $x*0*$y;
  my @ndigits;
  while ($x || $y) {
    ### at: "x=$x y=$y"
    my $ndigit = $yx_to_digit[$y%4]->[$x%4];
    if (! defined $ndigit) { return undef; }
    push @ndigits, $ndigit;
    $x -= $digit_to_x[$ndigit];
    $y -= $digit_to_y[$ndigit];

    ### $ndigit
    ### dxdy: "dx=$digit_to_x[$ndigit] dy=$digit_to_y[$ndigit]"

    $x /= -2;
    $y /= -2;
  }
  return digit_join_lowtohigh(\@ndigits,4,$zero);;
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### FourReplicate rect_to_n_range(): "$x1,$y1  $x2,$y2"
  my $xmax = int(max(abs($x1),abs($x2)));
  my $ymax = int(max(abs($y1),abs($y2)));
  return (0, ($xmax*$xmax + 3*$ymax*$ymax + 1) * 32);

  return (0, 4**6); #          ($xmax*$xmax + 3*$ymax*$ymax + 1));
}

1;
__END__
