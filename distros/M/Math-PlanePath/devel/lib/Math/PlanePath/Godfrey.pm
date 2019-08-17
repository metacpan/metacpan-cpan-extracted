# Copyright 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


# Edwin L. Godfrey, "Enumeration of the Rational Points Between 0 and 1",
# National Mathematics Magazine, volume 12, number 4, January 1938, pages
# 163-166.  http://www.jstor.org/stable/3028080


# cf
# A126572 Array read by antidiagonals: a(n,m) = the m-th integer from among those positive integers coprime to n.

# 1/1  1/2  1/3  1/4   1/5   1/6   1/7  ...
# 2/1  2/3  2/5  2/7   2/9   2/11  2/13 ...
# 3/1  3/2  3/4  3/5   3/7   3/8   3/10 ...
# 4/1  4/3  4/5  4/7   4/9   4/11  4/13 ...
# 5/1  5/2  5/3  5/4   5/6   5/7   5/8 ...
# 6/1  6/5  6/7  6/11  6/13  6/17  6/19  ...
# 7/1  7/2  7/3  7/4   7/5   7/6   7/8 ...

#      1/2  1/3  1/4  1/5  1/6   1/7
#      2/3  2/5  2/7  2/9  2/11  2/13
#           3/4  3/5  3/7  3/8   3/10  3/11
#           4/5  4/7  4/9  4/11  4/13  4/15

package Math::PlanePath::Godfrey;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 127;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem = \&Math::PlanePath::_divrem;
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::CoprimeColumns;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant x_minimum => 1;
use constant y_minimum => 2;
use constant diffxy_maximum => -1; # upper octant X<=Y-1 so X-Y<=-1
use constant gcdxy_maximum => 1;  # no common factor


#------------------------------------------------------------------------------

sub n_to_xy {
  my ($self, $n) = @_;
  ### Godfrey n_to_xy(): $n

  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $d = int((_sqrtint(8*$n-7) + 1) / 2);
  ### $d
  ### base: ($d-1)*$d/2
  $n -= ($d-1)*$d/2;
  my $y = $n;
  my $q = $d - $y;
  # ### assert: $n >= 0
  # ### assert: $y >= 1

  my $tot = Math::PlanePath::CoprimeColumns::_totient($y);
  my ($f, $count) = _divrem ($q, $tot);

  ### $y
  ### $q
  ### $tot

  my $x = 1;
  if ($count) {
    for (;;) {
      $x++;
      if (Math::PlanePath::CoprimeColumns::_coprime($x,$y)) {
        --$count or last;
      }
    }
  }

  # final den: $x + ($f+1)*$y)
  return ($y, $x + ($f+1)*$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### Godfrey xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x < 1 || $y < 1) {
    return undef;
  }
  if (is_infinite($x)) {
    return $x;
  }

  my ($f, $r) = _divrem ($y, $x);
  ### $f
  ### $r

  my $w = ($f-1) * Math::PlanePath::CoprimeColumns::_totient($x);
  ### w from totient: $w

  foreach my $i (1 .. $r) {
    if (Math::PlanePath::CoprimeColumns::_coprime($i,$x)) {
      ### coprime: "$i, x=$x, increment"
      $w++;
    }
  }

  my $d = $x + $w - 1;
  ### $x
  ### $w
  ### $d
  ### return: $d*($d-1)/2 + $x
  return $d*($d-1)/2 + $x;
}

sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### Godfrey rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  if ($x2 < 1 || $y2 < 1) { return (1,0); }

  return (1, $self->xy_to_n($x2,$y2));
}

1;
__END__

=cut

# math-image  --path=Godfrey --output=numbers --all --size=60x14

=pod
