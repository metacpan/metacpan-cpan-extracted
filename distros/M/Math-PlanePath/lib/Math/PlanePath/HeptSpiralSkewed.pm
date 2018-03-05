# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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


package Math::PlanePath::HeptSpiralSkewed;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

use constant xy_is_visited => 1;
sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 3;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 5;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 8;
}
use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E    four plus NW
                           0,1,   # N
                           -1,1,  # NW
                           -1,0,  # W
                           0,-1); # S
use constant dsumxy_minimum => -1; # W,S straight
use constant dsumxy_maximum => 1;  # N,E straight
use constant ddiffxy_minimum => -2; # NW diagonal
use constant ddiffxy_maximum => 1;
use constant dir_maximum_dxdy => (0,-1); # South

use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# base South-West diagonal
#   d = [  1,  2,  3,  4 ]
#   n = [  0,  5, 17, 36 ]
# N = (7/2 d^2 - 11/2 d + 2)
#   = (7/2*$d**2 - 11/2*$d + 2)
#   = ((7/2*$d - 11/2)*$d + 2)
# d = 11/14 + sqrt(2/7 * $n + 9/196)
#   = (11 + 14*sqrt(2/7 * $n + 9/196))/14
#   = (sqrt(56*$n + 9) + 11)/14
#
# split North Y axis
#   d = [  1,  2,  3 ]
#   n = [  2, 11, 27 ]
# N = (7*$d-3)*$d/2

sub n_to_xy {
  my ($self, $n) = @_;
  #### HeptSpiralSkewed n_to_xy: $n

  $n = $n - $self->{'n_start'};   # adjust to N=0 at origin X=0,Y=0
  if ($n < 0) { return; }

  my $d = int((_sqrtint(56*$n+9) + 11) / 14);
  ### $d
  ### d frac: (_sqrtint(56*$n+9) + 11) / 14

  $n -= (7*$d-3)*$d/2;
  ### remainder: $n

  if ($n < 0) {  # split at Y axis
    if ($n >= -$d) {
      #### right diagonal ...
      return (-$n,
              $n + $d);
    }
    $n += $d;
    if ($n < 1-$d) {
      ### bottom horizontal ...
      return ($n + 2*$d-1, 1-$d);
    }
    ### right vertical ...
    return ($d, $n);
  }
  if ($n <= $d) {
    ### top horizontal ...
    return (-$n, $d);
  }
  #### left vertical ...
  return (-$d,
          -$n + 2*$d);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x >= 0 && $y >= 0) {
    ### slope
    # relative to the y=0 base same as above
    #   d = [ 1,  2,  3,  4 ]
    #   n = [ 2, 10, 25, 47 ]
    #   n = (7/2*$d**2 + -5/2*$d + 1)
    #     = (3.5*$d - 2.5)*$d + 1
    #
    my $d = $x + $y;
    return (7*$d - 5)*$d/2 + $y + $self->{'n_start'};
  }

  my $d = max(abs($x),abs($y));
  my $n = (7*$d - 5)*$d/2;
  if ($y == $d) {
    ### top horizontal
    return $n+$d - $x + $self->{'n_start'};
  }
  if ($y == -$d) {
    ### bottom horizontal
    return $n + 5*$d + $x + $self->{'n_start'};
  }
  if ($x == $d) {
    ### right vertical
    return $n + $y + $self->{'n_start'};
  }
  # ($x == - $d)
  ### left vertical
  return $n + 3*$d - $y + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);
  my $d = 0;
  foreach my $x ($x1, $x2) {
    foreach my $y ($y1, $y2) {
      $d = max ($d,
                1 + ($x > 0 && $y > 0
                     ? $x+$y                    # slope
                     : max(abs($x),abs($y))));  # square corners
    }
  }
  # ENHANCE-ME: find actual minimum if rect doesn't cover 0,0
  return ($self->{'n_start'},
          $self->{'n_start'} + (7*$d - 5)*$d/2);
}

1;
__END__

=for stopwords PlanePath Ryde Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::HeptSpiralSkewed -- integer points around a skewed seven sided spiral

=head1 SYNOPSIS

 use Math::PlanePath::HeptSpiralSkewed;
 my $path = Math::PlanePath::HeptSpiralSkewed->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a seven-sided spiral by cutting one corner of a square

=cut

# math-image --path=HeptSpiralSkewed --expression='i<=44?i:0' --output=numbers_dash --size=60x18

=pod

    31-30-29-28                       3
     |         \
    32 14-13-12 27                    2
     |  |      \  \
    33 15  4--3 11 26                 1
     |  |  |   \  \  \
    34 16  5  1--2 10 25         <- Y=0
     |  |  |        |  |
    35 17  6--7--8--9 24             -1
     |  |              |
    36 18-19-20-21-22-23             -2
     |
    37-38-39-40-41-...               -3

              ^
    -3 -2 -1 X=0 1  2  3

The path is as if around a heptagon, with the left and bottom here as two
sides of the heptagon straightened out, and the flat top here skewed across
to fit a square grid.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=HeptSpiralSkewed,n_start=0 --expression='i<=40?i:0' --output=numbers --size=60x11

=pod

    30 29 28 27              n_start => 0
    31 13 12 11 26
    32 14  3  2 10 25
    33 15  4  0  1  9 24
    34 16  5  6  7  8 23
    35 17 18 19 20 21 22
    36 37 38 39 40 ...

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::HeptSpiralSkewed-E<gt>new ()>

=item C<$path = Math::PlanePath::HeptSpiralSkewed-E<gt>new (n_start =E<gt> $n)>

Create and return a new path object.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each N
in the path as centred in a square of side 1, so the entire plane is
covered.

=back

=head1 FORMULAS

=head2 N to X,Y

It's convenient to work in terms of Nstart=0 and to take each loop as
beginning on the South-West diagonal,

=cut

# math-image --path=HeptSpiralSkewed,n_start=0 --expression='i<=37?i:0' --output=numbers_dash --size=25x16

=pod

              top length = d

              30-29-28-27
               |         \
              31          26    diagonal length = d
   left        |            \
   length     32             25
    = 2*d      |               \
              33        0       24
               |                 |    right
              34     .          23    length = d-1
               |                 |
              35 17-18-19-20-21-22
               |
               .    bottom length = 2*d-1

The SW diagonal is N=0,5,17,36,etc which is

    N = (7d-11)*d/2 + 2           # starting d=1 first loop

This can be inverted to get d from N

    d = floor( (sqrt(56*N+9)+11)/14 )

The side lengths are as shown above.  The first loop is d=1 and for it the
"right" vertical length is zero, so no such side on that first loop 0 E<lt>=
N < 5.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A192136> (etc)

=back

    n_start=1
      A140065    N on Y axis

    n_start=0
      A001106    N on X axis, 9-gonal numbers
      A218471    N on Y axis
      A022265    N on X negative axis
      A179986    N on Y negative axis, second 9-gonals
      A195023    N on X=Y diagonal
      A022264    N on North-West diagonal
      A186029    N on South-West diagonal
      A024966    N on South-East diagonal

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>,
L<Math::PlanePath::PentSpiralSkewed>,
L<Math::PlanePath::HexSpiralSkewed>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
