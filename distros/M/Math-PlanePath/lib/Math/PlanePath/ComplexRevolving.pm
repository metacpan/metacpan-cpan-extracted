# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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



package Math::PlanePath::ComplexRevolving;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow',
  'bit_split_lowtohigh',
  'digit_join_lowtohigh';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant n_start => 0;
use constant xy_is_visited => 1;
use constant x_negative_at_n => 5;
use constant y_negative_at_n => 7;
# use constant dir_maximum_dxdy => (0,0);  # supremum, almost full way
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------
# b=i+1
# X+iY = b^e0 + i*b^e1 + ... + i^t * b^et
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### ComplexRevolving n_to_xy(): $n

  if ($n < 0) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  {
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+1);
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int;       # BigFloat int() gives BigInt, use that
  }

  my $x = my $y = ($n * 0);  # inherit bignum 0

  if (my @digits = bit_split_lowtohigh($n)) {
    my $bx = $x + 1;    # inherit bignum 1
    my $by = $x;       # 0
    for (;;) {
      if (shift @digits) { # low to high
        $x += $bx;
        $y += $by;
        ($bx,$by) = (-$by,$bx);  # (bx+by*i)*i = bx*i - by,  is rotate +90
      }
      @digits || last;

      # (bx+by*i) * (i+1)
      #   = bx*i+bx + -by + by*i
      #   = (bx-by) + i*(bx+by)
      ($bx,$by) = ($bx - $by,
                   $bx + $by);
    }
  }

  ### final: "$x,$y"
  return ($x,$y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### ComplexRevolving xy_to_n(): "$x, $y"

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  foreach my $overflow ($x+$y, $x-$y) {
    if (is_infinite($overflow)) { return $overflow; }
  }

  my $zero = $x * 0 * $y;  # inherit bignum 0

  my @n;
  while ($x || $y) {
    ### at: "$x,$y  power=$power  n=$n"

    # (a+bi)*(i+1) = (a-b)+(a+b)i
    #
    if (($x % 2) == ($y % 2)) {  # x+y even
      push @n, 0;
    } else {
      ### not multiple of 1+i, take e0=0 for b^e0=1
      # [(x+iy)-1]/i
      #   = [(x-1)+yi]/i
      #   = y + (x-1)/i
      #   = y + (1-x)*i    # rotate -90

      push @n, 1;
      ($x,$y) = ($y, 1-$x);

      ### sub and div to: "$x,$y"
    }

    # divide i+1 = mul (i-1)/(i^2 - 1^2)
    #            = mul (i-1)/-2
    # is (i*y + x) * (i-1)/-2
    #  x = (-x - y)/-2  = (x + y)/2
    #  y = (-y + x)/-2  = (y - x)/2
    #
    ### assert: (($x+$y)%2)==0
    ($x,$y) = (($x+$y)/2, ($y-$x)/2);
  }

  return digit_join_lowtohigh(\@n,2,$zero);
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ComplexRevolving rect_to_n_range(): "$x1,$y1  $x2,$y2"

  my $xm = max(abs($x1),abs($x2));
  my $ym = max(abs($y1),abs($y2));

  return (0, int (32*($xm*$xm + $ym*$ym)));
}

#------------------------------------------------------------------------------
# levels

sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, 2**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  my ($pow, $exp) = round_up_pow ($n+1, 2);
  return $exp;
}

#------------------------------------------------------------------------------
1;
__END__

=for stopwords eg Ryde Math-PlanePath ie Nstart Nlevel Seminumerical et

=head1 NAME

Math::PlanePath::ComplexRevolving -- points in revolving complex base i+1

=head1 SYNOPSIS

 use Math::PlanePath::ComplexRevolving;
 my $path = Math::PlanePath::ComplexRevolving->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

X<Knuth, Donald>This path traverses points by a complex number base i+1 with
turn factor i (+90 degrees) at each 1 bit.  This is the "revolving binary
representation" of Knuth's Seminumerical Algorithms section 4.1 exercise 28.

=cut

# math-image --path=ComplexRevolving --expression='i<64?i:0' --output=numbers --size=79x30

=pod

             54 51       38 35            5
          60 53       44 37               4
    39 46 43 58 23 30 27 42               3
       45  8 57  4 29 56 41 52            2
          31  6  3  2 15 22 19 50         1
    16    12  5  0  1 28 21    49     <- Y=0
    55 62 59 10  7 14 11 26              -1
       61 24  9 20 13 40 25 36           -2
          47       18 63       34        -3
    32          48 17          33        -4

                 ^
    -4 -3 -2 -1 X=0 1  2  3  4  5

The 1 bits in N are exponents e0 to et, in increasing order,

    N = 2^e0 + 2^e1 + ... + 2^et        e0 < e1 < ... < et

and are applied to a base b=i+1 as

    X+iY = b^e0 + i * b^e1 + i^2 * b^e2 + ... + i^t * b^et

Each 2^ek has become b^ek base b=i+1.  The i^k is an extra factor i at each
1 bit of N, causing a rotation by +90 degrees for the bits above it.  Notice
the factor is i^k not i^ek, ie. it increments only with the 1-bits of N, not
the whole exponent.

A single bit N=2^k is the simplest and is X+iY=(i+1)^k.  These
N=1,2,4,8,16,etc are at successive angles 45, 90, 135, etc degrees (the same
as in C<ComplexPlus>).  But points N=2^k+1 with two bits means X+iY=(i+1) +
i*(i+1)^k and that factor "i*" is a rotation by 90 degrees so points
N=3,5,9,17,33,etc are in the next quadrant around from their preceding
2,4,8,16,32.

As per the exercise in Knuth it's reasonably easy to show that this
calculation is a one-to-one mapping between integer N and complex integer
X+iY, so the path covers the plane and visits all points once each.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ComplexRevolving-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2**$level - 1)>.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::ComplexMinus>,
L<Math::PlanePath::ComplexPlus>,
L<Math::PlanePath::DragonCurve>

Donald Knuth, "The Art of Computer Programming", volume 2 "Seminumerical
Algorithms", section 4.1 exercise 28.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
