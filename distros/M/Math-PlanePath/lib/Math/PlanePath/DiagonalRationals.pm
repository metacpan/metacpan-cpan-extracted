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


# Maybe:
# including_zero=>1 to have 0/1 for A038567


package Math::PlanePath::DiagonalRationals;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_rect_for_first_quadrant = \&Math::PlanePath::_rect_for_first_quadrant;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

use Math::PlanePath::CoprimeColumns;
*_extend = \&Math::PlanePath::CoprimeColumns::_extend;
*_coprime = \&Math::PlanePath::CoprimeColumns::_coprime;
use vars '@_x_to_n';
*_x_to_n = \@Math::PlanePath::CoprimeColumns::_x_to_n;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ { name        => 'direction',
      share_key   => 'direction_downup',
      display     => 'Direction',
      type        => 'enum',
      default     => 'down',
      choices     => ['down','up'],
      choices_display => ['Down','Up'],
      description => 'Number points downwards or upwards along the diagonals.',
    },
    Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant default_n_start => 1;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;
use constant x_minimum => 1;
use constant y_minimum => 1;
use constant gcdxy_maximum => 1;  # no common factor

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down' ? 0 : 1);
}
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down' ? 1 : 0);
}
use constant dsumxy_minimum => 0;
use constant dsumxy_maximum => 1;  # to next diagonal stripe

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? (0,1)   # North
          : (1,0)); # East
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return ($self->{'direction'} eq 'down'
          ? (1,-1)    # South-East
          : (2,-1));  # ESE at N=3 down to X axis
}

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);

  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  my $direction = ($self->{'direction'} ||= 'down');
  if (! ($direction eq 'up' || $direction eq 'down')) {
    croak "Unrecognised direction option: ", $direction;
  }

  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### DiagonalRationals n_to_xy(): $n

  if (2*($n - $self->{'n_start'}) < -1) {
    ### before n_start ...
    return;
  }
  my ($x,$y) = $self->Math::PlanePath::CoprimeColumns::n_to_xy($n+1)
    or return;
  ### CoprimeColumns returned: "x=$x y=$y"

  $x -= $y;
  ### shear to: "x=$x y=$y"

  return ($x,$y);
}

# Note: shared by FactorRationals
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 1
      || $y < 1
      || ! _coprime($x,$y)) {
    return 0;
  }
  return 1;
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### DiagonalRationals xy_to_n(): "$x,$y"

  my $n = Math::PlanePath::CoprimeColumns::xy_to_n($self,$x+$y,$y);

  # not the N=0 at Xcol=1,Ycol=1 which is Xdiag=1,Ydiag=0
  if (defined $n && $n > $self->{'n_start'}) {
    return $n-1;
  } else {
    return undef;
  }
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### DiagonalRationals rect_to_n_range(): "$x1,$y1 $x2,$y2"

  $x1 = round_nearest($x1);
  $y1 = round_nearest($y1);
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);
  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  if ($x2 < 1 || $y2 < 1) {
    ### outside quadrant ...
    return (1, 0);
  }

  ### rect: "$x1,$y1  $x2,$y2"

  my $d2 = $x2 + $y2 + 1;
  if (is_infinite($d2)) {
    return (1, $d2);
  }
  while ($#_x_to_n < $d2) {
    _extend();
  }
  my $d1 = max (2, $x1 + $y1);
  ### $d1
  ### $d2

  return ($_x_to_n[$d1] - 1 + $self->{'n_start'},
          $_x_to_n[$d2] + $self->{'n_start'});
}

1;
__END__

=for stopwords Ryde Math-PlanePath coprime coprimes coprimeness totient totients Euler's onwards OEIS

=head1 NAME

Math::PlanePath::DiagonalRationals -- rationals X/Y by diagonals

=head1 SYNOPSIS

 use Math::PlanePath::DiagonalRationals;
 my $path = Math::PlanePath::DiagonalRationals->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path enumerates positive rationals X/Y with no common factor, going in
diagonal order from Y down to X.

    17  |    96...
    16  |    80
    15  |    72 81
    14  |    64    82
    13  |    58 65 73 83 97
    12  |    46          84
    11  |    42 47 59 66 74 85 98
    10  |    32    48          86
     9  |    28 33    49 60    75 87
     8  |    22    34    50    67    88
     7  |    18 23 29 35 43 51    68 76 89 99
     6  |    12          36    52          90
     5  |    10 13 19 24    37 44 53 61    77 91
     4  |     6    14    25    38    54    69    92
     3  |     4  7    15 20    30 39    55 62    78 93
     2  |     2     8    16    26    40    56    70    94
     1  |     1  3  5  9 11 17 21 27 31 41 45 57 63 71 79 95
    Y=0 |
        +---------------------------------------------------
         X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16

The order is the same as the C<Diagonals> path, but only those X,Y with no
common factor are numbered.

    1/1,                      N = 1
    1/2, 1/2,                 N = 2 .. 3
    1/3, 1/3,                 N = 4 .. 5
    1/4, 2/3, 3/2, 4/1,       N = 6 .. 9
    1/5, 5/1,                 N = 10 .. 11

N=1,2,4,6,10,etc at the start of each diagonal (in the column at X=1) is the
cumulative totient,

    totient(i) = count numbers having no common factor with i

                             i=K
    cumulative_totient(K) =  sum   totient(i)
                             i=1

=head2 Direction Up

Option C<direction =E<gt> 'up'> reverses the order within each diagonal to
count upward from the X axis.

=cut

# math-image --path=DiagonalRationals,direction=up --all --output=numbers --size=50x10

=pod

    direction => "up"

     8 |   27
     7 |   21 26
     6 |   17
     5 |   11 16 20 25
     4 |    9    15    24
     3 |    5  8    14 19
     2 |    3     7    13    23
     1 |    1  2  4  6 10 12 18 22
    Y=0|
       +---------------------------
       X=0  1  2  3  4  5  6  7  8

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape,  For example
to start at 0,

=cut

# math-image --path=DiagonalRationals,n_start=0 --all --output=numbers --size=50x10

=pod

    n_start => 0

     8 |   21
     7 |   17 22
     6 |   11
     5 |    9 12 18 23
     4 |    5    13    24
     3 |    3  6    14 19
     2 |    1     7    15    25
     1 |    0  2  4  8 10 16 20 26
    Y=0|
       +---------------------------
       X=0  1  2  3  4  5  6  7  8

=head2 Coprime Columns

The diagonals are the same as the columns in C<CoprimeColumns>.  For example
the diagonal N=18 to N=21 from X=0,Y=8 down to X=8,Y=0 is the same as the
C<CoprimeColumns> vertical at X=8.  In general the correspondence is

   Xdiag = Ycol
   Ydiag = Xcol - Ycol

   Xcol = Xdiag + Ydiag
   Ycol = Xdiag

C<CoprimeColumns> has an extra N=0 at X=1,Y=1 which is not present in
C<DiagonalRationals>.  (It would be Xdiag=1,Ydiag=0 which is 1/0.)

The points numbered or skipped in a column up to X=Y is the same as the
points numbered or skipped on a diagonal, simply because X,Y no common
factor is the same as Y,X+Y no common factor.

Taking the C<CoprimeColumns> as enumerating fractions F = Ycol/Xcol with
S<0 E<lt> F E<lt> 1> the corresponding diagonal rational
S<0 E<lt> R E<lt> infinity> is

           1         F
    R = -------  =  ---
        1/F - 1     1-F

           1         R
    F = -------  =  ---
        1/R + 1     1+R

which is a one-to-one mapping between the fractions S<F E<lt> 1> and all
rationals.

=cut

# R = 1 / (1/F - 1)
# F = Ycol/Xcol
# R = 1 / (Xcol/Ycol - 1)
#   = 1 / (Xcol-Ycol)/Ycol
#   = Ycol / (Xcol-Ycol)
#
# R = 1 / (1/F - 1)
#   = 1 / (1-F)/F
#   = F/(1-F)
#
# 1/R = 1/F - 1
# 1/R + 1 = 1/F
# F = 1 / (1/R + 1)
#   = 1 / (1+R)/R
#   = R/(1+R)
#
# F = 1 / (1/R + 1)
# R = Xdiag/Ydiag
# F = 1 / (Ydiag/Xdiag + 1)
#   = 1 / (Ydiag+Xdiag)/Xdiag
#   = Xdiag/(Ydiag+Xdiag)
#   = Ycol/Xcol
# Xcol = Ydiag+Xdiag
# Ycol = Xdiag
#
# R = 1 / (1/F - 1)
#   = 1 / ((1+R)/R - 1)
#   = 1 / ((1+R-R)/R)
#   = 1 / (1/R)
#   = R

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DiagonalRationals-E<gt>new ()>

=item C<$path = Math::PlanePath::DiagonalRationals-E<gt>new (direction =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.  C<direction> (a string) can be

    "down"     (the default)
    "up"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 1 and if C<$n E<lt> 1> then the return is an empty list.

=back

=head1 BUGS

The current implementation is fairly slack and is slow on medium to large N.
A table of cumulative totients is built and retained for the diagonal d=X+Y.

=head1 OEIS

This enumeration of rationals is in Sloane's Online Encyclopedia of Integer
Sequences in the following forms

=over

L<http://oeis.org/A020652> (etc)

=back

    direction=down, n_start=1  (the defaults)
      A020652   X, numerator
      A020653   Y, denominator
      A038567   X+Y sum, starting from X=1,Y=1
      A054431   by diagonals 1=coprime, 0=not
                  (excluding X=0 row and Y=0 column)

      A054430   permutation N at Y/X
                  reverse runs of totient(k) many integers

      A054424   permutation DiagonalRationals -> RationalsTree SB
      A054425     padded with 0s at non-coprimes
      A054426     inverse SB -> DiagonalRationals
      A060837   permutation DiagonalRationals -> FactorRationals

    direction=down, n_start=0
      A157806   abs(X-Y) difference

direction=up swaps X,Y.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::CoprimeColumns>,
L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::PythagoreanTree>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
