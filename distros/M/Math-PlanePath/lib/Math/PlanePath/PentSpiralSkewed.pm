# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


package Math::PlanePath::PentSpiralSkewed;
use 5.004;
use strict;
#use List::Util 'min','max';
*min = \&Math::PlanePath::_min;
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
*_sqrtint = \&Math::PlanePath::_sqrtint;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


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
  return $self->n_start + 4;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 6;
}

use constant dx_minimum => -1;
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant _UNDOCUMENTED__dxdy_list => (1,0,   # E
                           0,1,   # N
                           -1,1,  # NW
                           -1,-1, # SW
                           1,-1,  # SE
                          );
use constant dsumxy_minimum => -2; # SW diagonal
use constant dsumxy_maximum => 1;
use constant ddiffxy_minimum => -2; # NW diagonal
use constant ddiffxy_maximum => 2;  # SE diagonal
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  #### n_to_xy: $n

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};
  if ($n < 0) { return; }

  my $d = int( (_sqrtint(40*$n+9)+7) / 10);
  $n -= (5*$d-1)*$d/2;

  if ($n < -$d) {
    $n += 2*$d;
    if ($n < 1) {
      # bottom horizontal
      return ($n+$d-1, -$d+1);
    } else {
      # lower right vertical ...
      return ($d, $n-$d);
    }
  } else {
    if ($n <= $d) {
      ### top diagonals left and right ...
      return (-$n,
              -abs($n) + $d);
    } else {
      ### lower left diagonal ...
      return ($n - 2*$d,
              -$n + $d);
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  if ($x > 0 && $y < 0) {
    # vertical downwards at x=0
    #   d = [ 1, 2, 3 ]
    #   n = [ 5, 14, 28 ]
    #   n = (5/2*$d**2 + 3/2*$d + 1)
    # so
    my $d = max($x-1, -$y);
    ### lower right square part
    ### $d
    return ((5*$d + 3)*$d/2
            + $x
            + ($x > $d ? $y+$d : 0)
            + $self->{'n_start'});
  }

  # vertical at x=0
  #   d = [ 1, 2, 3 ]
  #   n = [ 3, 10, 22 ]
  #   n = (5/2*$d**2 + -1/2*$d + 1)
  #
  my $d = abs($x)+abs($y);
  return ((5*$d - 1)*$d/2
          - $x
          + ($y < 0 ? 2*($d+$x) : 0)
          + $self->{'n_start'});
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### PentSpiralSkewed rect_to_n_range(): $x1,$y1, $x2,$y2

  my $d = 0;
  foreach my $x ($x1, $x2) {
    $x = round_nearest ($x);
    foreach my $y ($y1, $y2) {
      $y = round_nearest ($y);

      my $this_d = 1 + ($x > 0 && $y < 0
                        ? max($x,-$y)
                        : abs($x)+abs($y));
      ### $x
      ### $y
      ### $this_d
      $d = max($d, $this_d);
    }
  }
  ### $d
  return ($self->{'n_start'},
          $self->{'n_start'} + 5*$d*($d-1)/2 + 2);
}

1;
__END__

=for stopwords Ryde Math-PlanePath OEIS

=head1 NAME

Math::PlanePath::PentSpiralSkewed -- integer points in a pentagonal shape

=head1 SYNOPSIS

 use Math::PlanePath::PentSpiralSkewed;
 my $path = Math::PlanePath::PentSpiralSkewed->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a pentagonal (five-sided) spiral with points skewed so as to
fit a square grid and fully cover the plane.

          10 ...             2
         /  \  \
       11  3  9 20           1
      /  /  \  \  \
    12  4  1--2  8 19    <- Y=0
      \  \       |  |
       13  5--6--7 18       -1
         \          |
          14-15-16-17       -2

     ^  ^  ^  ^  ^  ^
    -2 -1 X=0 1  2  3 ...

The pattern is similar to the C<SquareSpiral> but cuts three corners which
makes each cycle is faster.  Each cycle is just 5 steps longer than the
previous (where it's 8 for a C<SquareSpiral>).

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=PentSpiralSkewed,n_start=0 --expression='i<=57?i:0' --output=numbers --size=60x11

=pod

                38             n_start => 0
             39 21 37  ...
          40 22  9 20 36 57
       41 23 10  2  8 19 35 56
    42 24 11  3  0  1  7 18 34 55
       43 25 12  4  5  6 17 33 54
          44 26 13 14 15 16 32 53
             45 27 28 29 30 31 52
                46 47 48 49 50 51

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::PentSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::PentSpiral-E<gt>new (n_start =E<gt> $n)>

Create and return a new path object.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point in the path as a square of side 1.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A192136> (etc)

=back

    n_start=1 (the default)
      A192136    N on X axis, (5*n^2 - 3*n + 2)/2
      A140066    N on Y axis
      A116668    N on X negative axis, (5n^2 + n + 2)/2
      A134238    N on Y negative axis
      A158187    N on North-West diagonal, 10*n^2 + 1
      A005891    N on South-East diagonal, centred pentagonals

    n_start=0
      A000566    N on X axis, heptagonal numbers
      A005476    N on Y axis
      A005475    N on X negative axis
      A147875    N on Y negative axis, second heptagonals
      A033583    N on North-West diagonal, 10*n^2
      A028895    N on South-East diagonal, 5*triangular

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::SquareSpiral>,
L<Math::PlanePath::DiamondSpiral>,
L<Math::PlanePath::HexSpiralSkewed>

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
