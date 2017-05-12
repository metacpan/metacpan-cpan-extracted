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

package Math::PlanePath::DiagonalsAlternating;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
# use Smart::Comments;

use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

use constant class_x_negative => 0;
use constant class_y_negative => 0;

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant 1.02 _UNDOCUMENTED__dxdy_list => (1,0,   # E   at N=3 in default n_start=1
                                               0,1,   # N   at N=1
                                               -1,1,  # NW  at N=4
                                               1,-1,  # SE  at N=2
                                              );
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 3;
}
use constant dsumxy_minimum => 0; # advancing diagonals
use constant dsumxy_maximum => 1;
use constant ddiffxy_minimum => -2; # NW diagonal
use constant ddiffxy_maximum => 2;  # SE diagonal
use constant dir_maximum_dxdy => (1,-1); # South-East


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  $self->{'x_start'} ||= 0;
  $self->{'y_start'} ||= 0;
  return $self;
}


#   \
# 15 26
#  |\  \
# 14 16 25
#      \  \
#  .  . 17 24
#         \  \
#  .  .  . 18 23
#            \  \
#  .  .  .  . 19 22
#               \  \
#  .  .  .  .  . 20-21

# Basis N=0
#   d = [  0, 1,  2,  3 ]
#   n = [  0, 5, 14, 27 ]
# N = (2 d^2 + 3 d)
#   = (2*$d**2 + 3*$d)
#   = ((2*$d + 3)*$d)
# d = -3/4 + sqrt(1/2 * $n + 9/16)
#   = (sqrt(8*$n + 9) - 3) / 4
#
# Midpoint
#   d = [ 0, 1,  2, 3 ]
#   n = [ 2, 9, 20, 35 ]
# N = (2 d^2 + 5 d + 2)
#   = (2*$d**2 + 5*$d + 2)
#   = ((2*$d + 5)*$d + 2)

sub n_to_xy {
  my ($self, $n) = @_;
  ### DiagonalsAlternating n_to_xy(): "$n   ".(ref $n || '')

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};
  if ($n < 0) { return; }

  my $d = int( (_sqrtint(8*int($n)+9) - 3)/4 );
  $n -= (2*$d + 5)*$d + 3;
  ### remainder: $n

  my ($x,$y);
  if ($n >= -1) {
    if ($n < 0) {
      ### horizontal X axis ...
      $x = $n + 2*$d+2;
      $y = 0;
    } else {
      ### diagonal upwards ...
      $x = -$n + 2*$d+2;
      $y = $n;
    }
  } else {
    $n += 2*$d+2;      # -1 <= $n < ...
    ### added n: $n
    ### assert: ! ($n < -1)

    if ($n < 0) {
      ### vertical Y axis ...
      $x = 0;
      $y = $n + 2*$d+1;
    } else {
      ### diagonal downwards ...
      $x = $n;
      $y = -$n + 2*$d+1;
    }
  }

  return ($x + $self->{'x_start'},
          $y + $self->{'y_start'});
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### xy_to_n(): $x, $y

  $x = $x - $self->{'x_start'};   # "-" operator to provoke warning if x==undef
  $y = $y - $self->{'y_start'};
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  if ($x < 0 || $y < 0) {
    return undef;  # outside first quadrant
  }

  my $d = $x + $y;

  # odd, downwards ...
  # d= [ 1,3,5 ]
  # N= [ 2,7,16 ]
  # N = ((1/2*$d + 1/2)*$d + 1)
  #
  # even, upwards
  # d= [ 0,2,4 ]
  # N= [ 1,4,11 ]
  # N = ((1/2*$d + 1/2)*$d + 1)
  #   = ($d + 1)*$d/2 + 1

  my $n = ($d + 1)*$d/2 + $self->{'n_start'};
  if ($d % 2) {
    return $n + $x;
  } else {
    return $n + $y;
  }
}

use Math::PlanePath::Diagonals;
*rect_to_n_range = \&Math::PlanePath::Diagonals::rect_to_n_range;

1;
__END__

=for stopwords PlanePath Ryde Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::DiagonalsAlternating -- points in diagonal stripes of alternating directions

=head1 SYNOPSIS

 use Math::PlanePath::DiagonalsAlternating;
 my $path = Math::PlanePath::DiagonalsAlternating->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path follows successive diagonals going from the Y axis down to the X
axis and then back again,

=cut

# math-image --path=DiagonalsAlternating --expression='i<=31?i:0' --output=numbers

=pod

      7  |  29 
      6  |  28  30
      5  |  16  27  31
      4  |  15  17  26  ...
      3  |   7  14  18  25 
      2  |   6   8  13  19  24 
      1  |   2   5   9  12  20  23
    Y=0  |   1   3   4  10  11  21  22
         +----------------------------
           X=0   1   2   3   4   5   6

X<Triangular numbers>The triangular numbers 1,3,6,10,etc k*(k+1)/2 are the
start of each run up or down alternately on the X axis and Y axis.
X<Hexagonal numbers>N=1,6,15,28,etc on the Y axis (Y even) are the hexagonal
numbers j*(2j-1).  N=3,10,21,36,etc on the X axis (X odd) are the hexagonal
numbers of the second kind j*(2j+1).

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=DiagonalsAlternating,n_start=0 --expression='i<=14?i:0' --output=numbers --size=35x5

=pod

    n_start => 0            

      4  |  14
      3  |   6 13
      2  |   5  7 12
      1  |   1  4  8 11
    Y=0  |   0  2  3  9 10
         +----------------- 
           X=0  1  2  3  4  

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::DiagonalsAlternating-E<gt>new ()>

=item C<$path = Math::PlanePath::DiagonalsAlternating-E<gt>new (n_start =E<gt> $n)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n E<lt> 1> the return is an empty list, it being considered the path
begins at 1.

=back

=head1 FORMULAS

=head2 Rectangle to N Range

Within each row increasing X is increasing N, and in each column increasing
Y is increasing N.  So in a rectangle the lower left corner is the minimum N
and the upper right is the maximum N.

    |               N max
    |     ----------+
    |    |  ^       |
    |    |  |       |
    |    |   ---->  |
    |    +----------
    |   N min
    +-------------------

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A131179> (etc)

=back

    n_start=1
      A131179    N on X axis (extra initial 0)
      A128918    N on Y axis (extra initial 1)
      A001844    N on X=Y diagonal
      A038722    permutation N at transpose Y,X

    n_start=0
      A003056    X+Y
      A004247    X*Y
      A049581    abs(X-Y)
      A048147    X^2+Y^2
      A004198    X bit-and Y
      A003986    X bit-or Y
      A003987    X bit-xor Y
      A004197    min(X,Y)
      A003984    max(X,Y)
      A101080    HammingDist(X,Y)
      A023531    dSum = dX+dY, being 1 at N=triangular+1 (and 0)
      A046092    N on X=Y diagonal
      A061579    permutation N at transpose Y,X

      A056011    permutation N at points by Diagonals,direction=up order
      A056023    permutation N at points by Diagonals,direction=down
         runs alternately up and down, both are self-inverse

The coordinates such as A003056 X+Y are the same here as in the Diagonals
path.  C<DiagonalsAlternating> transposes X,Y -E<gt> Y,X in every second
diagonal but forms such as X+Y are unchanged by swapping to Y+X.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Diagonals>,
L<Math::PlanePath::DiagonalsOctant>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
