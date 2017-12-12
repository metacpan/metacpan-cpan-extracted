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


# math-image --path=CoprimeColumns --all --scale=10
# math-image --path=CoprimeColumns --output=numbers --all

package Math::PlanePath::CoprimeColumns;
use 5.004;
use strict;

use vars '$VERSION', '@ISA', '@_x_to_n';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant default_n_start => 0;
use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant x_minimum => 1;
use constant y_minimum => 1;
               use constant diffxy_minimum => 0; # octant Y<=X so X-Y>=0
use constant gcdxy_maximum => 1;  # no common factor

use constant dx_minimum => 0;
use constant dx_maximum => 1;
use constant dir_maximum_dxdy => (1,-1); # South-East

use constant parameter_info_array =>
  [
   { name        => 'direction',
     share_key   => 'direction_updown',
     display     => 'Direction',
     type        => 'enum',
     default     => 'up',
     choices     => ['up','down'],
     choices_display => ['Down','Up'],
     description => 'Number points upwards or downwards in the columns.',
   },
   Math::PlanePath::Base::Generic::parameter_info_nstart0(),
  ];

#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  $self->{'direction'} ||= 'up';
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}


# shared with DiagonalRationals
@_x_to_n = (0,0,1);
sub _extend {
  ### _extend(): $#_x_to_n
  my $x = $#_x_to_n;
  push @_x_to_n, $_x_to_n[$x] + _totient($x);

  # if ($x > 2) {
  #   if (($x & 3) == 2) {
  #     $x >>= 1;
  #     $next_n += $_x_to_n[$x] - $_x_to_n[$x-1];
  #   } else {
  #     $next_n +=
  #   }
  # }
  ### last x: $#_x_to_n
  ### second last: $_x_to_n[$#_x_to_n-2]
  ### last: $_x_to_n[$#_x_to_n-1]
  ### diff: $_x_to_n[$#_x_to_n-1] - $_x_to_n[$#_x_to_n-2]
  ### totient of: $#_x_to_n - 2
  ### totient: _totient($#_x_to_n-2)
  ### assert: $_x_to_n[$#_x_to_n-1] - $_x_to_n[$#_x_to_n-2] == _totient($#_x_to_n-2)
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### CoprimeColumns n_to_xy(): $n

  $n = $n - $self->{'n_start'}; # to N=0 basis, and warn on undef

  # $n<-0.5 is ok for Math::BigInt circa Perl 5.12, it seems
  if (2*$n < -1) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $frac;
  {
    my $int = int($n);
    $frac = $n - $int; # -.5 <= $frac < 1
    $n = $int;  # BigFloat int() gives BigInt, use that

    if (2*$frac >= 1) {
      $frac--;
      $n += 1;
      # now -.5 <= $frac < .5
    }
    ### $n
    ### $frac
    ### assert: 2*$frac >= -1
    ### assert: 2*$frac < 1
  }

  my $x = 1;
  for (;;) {
    while ($x > $#_x_to_n) {
      _extend();
    }
    if ($_x_to_n[$x] > $n) {
      $x--;
      last;
    }
    $x++;
  }
  $n -= $_x_to_n[$x];
  ### $x
  ### n base: $_x_to_n[$x]
  ### n next: $_x_to_n[$x+1]
  ### remainder: $n

  my $y = 1;
  for (;;) {
    if (_coprime($x,$y)) {
      if (--$n < 0) {
        last;
      }
    }
    if (++$y >= $x) {
      ### oops, not enough in this column ...
      return;
    }
  }

  $y += $frac;
  if ($x >= 2 && $self->{'direction'} eq 'down') {
    $y = $x - $y;
  }
  return ($x, $y);
}

sub xy_is_visited {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 1
      || $y < 1
      || $y >= $x+($x==1)   # Y<X except X=Y=1 included
      || ! _coprime($x,$y)) {
    return 0;
  }
  return 1;
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### CoprimeColumns xy_to_n(): "$x,$y"
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if (is_infinite($x)) { return $x; }
  if (is_infinite($y)) { return $y; }
  if ($x < 1
      || $y < 1
      || $y >= $x+($x==1)   # Y<X except X=Y=1 included
      || ! _coprime($x,$y)) {
    return undef;
  }

  if ($x >= 2 && $self->{'direction'} eq 'down') {
    $y = $x - $y;
  }

  while ($#_x_to_n < $x) {
    _extend();
  }
  my $n = $_x_to_n[$x];
  ### base n: $n
  if ($y != 1) {
    foreach my $i (1 .. $y-1) {
      if (_coprime($x,$i)) {
        $n += 1;
      }
    }
  }
  return $n + $self->{'n_start'};
}

# Asymptotically
#     phisum(x) ~ 1/(2*zeta(2)) * x^2 + O(x ln x)
#               = 3/pi^2 * x^2 + O(x ln x)
# or by Walfisz
#     phisum(x) ~ 3/pi^2 * x^2 + O(x * (ln x)^(2/3) * (ln ln x)^4/3)
#
# but want an upper bound, so that for a given X at least enough N is
# covered ...
#
# Note: DiagonalRationals depends on this working only to column resolution.
# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### CoprimeColumns rect_to_n_range(): "$x1,$y1 $x2,$y2"

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;
  $x2 = round_nearest($x2);
  $y2 = round_nearest($y2);
  ### rounded ...
  ### $x2
  ### $y2

  if ($x2 < 1 || $y2 < 1
      # bottom right corner above X=Y diagonal, except X=1,Y=1 included
      || ($y1 >= $x2 + ($x2 == 1))) {
    ### outside ...
    return (1, 0);
  }
  if (is_infinite($x2)) {
    return ($self->{'n_start'}, $x2);
  }

  while ($#_x_to_n <= $x2) {
    _extend();
  }

  ### rect use xy_to_n at: "x=".($x2+1)." y=1"
  if ($x1 < 0) { $x1 = 0; }
  return ($_x_to_n[$x1]  + $self->{'n_start'},
          $_x_to_n[$x2+1] - 1 + $self->{'n_start'});

  # asympototically ?
  # return ($self->{'n_start'}, $self->{'n_start'} + .304*$x2*$x2 + 20);
}

# A000010
sub _totient {
  my ($x) = @_;
  my $count = (1                            # y=1 always
               + ($x > 2 && ($x&1))         # y=2 if $x odd
               + ($x > 3 && ($x % 3) != 0)  # y=3
               + ($x > 4 && ($x&1))         # y=4 if $x odd
              );
  for (my $y = 5; $y < $x; $y++) {
    $count += _coprime($x,$y);
  }
  return $count;
}

# code here only uses X>=Y but allow for any X,Y>=0 for elsewhere
sub _coprime {
  my ($x, $y) = @_;
  #### _coprime(): "$x,$y"

  if ($y > $x) {
    if ($x <= 1) {
      ### result yes ...
      return 1;
    }
    $y %= $x;
  }

  for (;;) {
    if ($y <= 1) {
      ### result: ($y == 1)
      return ($y == 1);
    }
    ($x,$y) = ($y, $x % $y);
  }
}

1;
__END__

=for stopwords Ryde coprime coprimes coprimeness totient totients Math-PlanePath Euler's onwards OEIS ie GCD

=head1 NAME

Math::PlanePath::CoprimeColumns -- coprime X,Y by columns

=head1 SYNOPSIS

 use Math::PlanePath::CoprimeColumns;
 my $path = Math::PlanePath::CoprimeColumns->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path visits points X,Y which are coprime, ie. no common factor so
gcd(X,Y)=1, in columns from Y=0 to YE<lt>=X.

    13 |                                          63
    12 |                                       57
    11 |                                    45 56 62
    10 |                                 41    55
     9 |                              31 40    54 61
     8 |                           27    39    53
     7 |                        21 26 30 38 44 52
     6 |                     17          37    51
     5 |                  11 16 20 25    36 43 50 60
     4 |                9    15    24    35    49
     3 |             5  8    14 19    29 34    48 59
     2 |          3     7    13    23    33    47
     1 |    0  1  2  4  6 10 12 18 22 28 32 42 46 58
    Y=0|
       +---------------------------------------------
       X=0  1  2  3  4  5  6  7  8  9 10 11 12 13 14

Since gcd(X,0)=0 the X axis itself is never visited, and since gcd(K,K)=K
the leading diagonal X=Y is not visited except X=1,Y=1.

The number of coprime pairs in each column is Euler's totient function
phi(X).  Starting N=0 at X=1,Y=1 means N=0,1,2,4,6,10,etc horizontally along
row Y=1 are the cumulative totients

                          i=K
    cumulative totient = sum   phi(i)
                          i=1

Anything making a straight line etc in the path will probably be related to
totient sums in some way.

The pattern of coprimes or not within a column is the same going up as going
down, since X,X-Y has the same coprimeness as X,Y.  This means coprimes
occur in pairs from X=3 onwards.  When X is even the middle point Y=X/2 is
not coprime since it has common factor 2 from X=4 onwards.  So there's an
even number of points in each column from X=2 onwards and those cumulative
totient totals horizontally along X=1 are therefore always even likewise.

=head2 Direction Down

Option C<direction =E<gt> 'down'> reverses the order within each column to
go downwards to the X axis.

=cut

# math-image --path=CoprimeColumns,direction=down --all --output=numbers --size=50x10

=pod

    direction => "down"

     8 |                           22
     7 |                        18 23        numbering
     6 |                     12              downwards
     5 |                  10 13 19 24            |
     4 |                6    14    25            |
     3 |             4  7    15 20               v
     2 |          2     8    16    26
     1 |    0  1  3  5  9 11 17 21 27
    Y=0|
       +-----------------------------
       X=0  1  2  3  4  5  6  7  8  9

=head2 N Start

The default is to number points starting N=0 as shown above.  An optional
C<n_start> can give a different start with the same shape,  For example
to start at 1,

=cut

# math-image --path=CoprimeColumns,n_start=1 --all --output=numbers --size=50x16

=pod

    n_start => 1

     8 |                           28
     7 |                        22 27
     6 |                     18
     5 |                  12 17 21 26
     4 |               10    16    25
     3 |             6  9    15 20
     2 |          4     8    14    24
     1 |    1  2  3  5  7 11 13 19 23
    Y=0|
       +------------------------------
       X=0  1  2  3  4  5  6  7  8  9

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::CoprimeColumns-E<gt>new ()>

=item C<$path = Math::PlanePath::CoprimeColumns-E<gt>new (direction =E<gt> $str, n_start =E<gt> $n)>

Create and return a new path object.  C<direction> (a string) can be

    "up"       (the default)
    "down"

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

=item C<$bool = $path-E<gt>xy_is_visited ($x,$y)>

Return true if C<$x,$y> is visited.  This means C<$x> and C<$y> have no
common factor.  This is tested with a GCD and is much faster than the full
C<xy_to_n()>.

=back

=head1 BUGS

The current implementation is fairly slack and is slow on medium to large N.
A table of cumulative totients is built and retained up to the highest X
column number used.

=head1 OEIS

This pattern is in Sloane's Online Encyclopedia of Integer Sequences in a
couple of forms,

=over

L<http://oeis.org/A002088> (etc)

=back

    n_start=0 (the default)
      A038567    X coordinate, reduced fractions denominator
      A020653    X-Y diff, fractions denominator by diagonals
                   skipping N=0 initial 1/1

      A002088    N on X axis, cumulative totient
      A127368    by columns Y coordinate if coprime, 0 if not
      A054521    by columns 1 if coprime, 0 if not

      A054427    permutation columns N -> RationalsTree SB N X/Y<1
      A054428      inverse, SB X/Y<1 -> columns
      A121998    Y of skipped X,Y among 2<=Y<=X, those not coprime
      A179594    X column position of KxK square unvisited

    n_start=1
      A038566    Y coordinate, reduced fractions numerator

      A002088    N on X=Y+1 diagonal, cumulative totient

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::DiagonalRationals>,
L<Math::PlanePath::RationalsTree>,
L<Math::PlanePath::PythagoreanTree>,
L<Math::PlanePath::DivisibleColumns>

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
