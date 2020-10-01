# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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


package Math::PlanePath::PentSpiral;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 128;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant parameter_info_array =>
  [
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];

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

use constant dx_minimum => -2;
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant 1.02 _UNDOCUMENTED__dxdy_list => (2,0,   # E by 2
                                               1,1,   # NE
                                               -2,1,  # WNW
                                               -2,-1, # WSW
                                               1,-1,  # SE
                                              );
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -3; # SW -2,-1
use constant dsumxy_maximum => 2;  # dX=+2 and NE diag
use constant ddiffxy_minimum => -3; # NW dX=-2,dY=+1
use constant ddiffxy_maximum => 2;
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

# base South-West diagonal
#   d = [  1,  2,  3,  4 ]
#   n = [  0,  4, 13, 27 ]
# N = (5/2 d^2 - 7/2 d + 1)
#   = (5/2*$d**2 - 7/2*$d + 1)
#   = ((5/2*$d - 7/2)*$d + 1)
# d = 7/10 + sqrt(2/5 * $n + 9/100)
#   = (sqrt(40*$n + 9) + 7) / 10
#
# split Y axis
#   d = [  1,  2,  3 ]
#   n = [  2,  9, 21 ]
# N = ((5/2*$d - 1/2)*$d)

sub n_to_xy {
  my ($self, $n) = @_;
  #### n_to_xy: $n

  # adjust to N=0 at origin X=0,Y=0
  $n = $n - $self->{'n_start'};
  if ($n < 0) { return; }

  my $d = int( (_sqrtint(40*$n+9)+7)/10 );
  $n -= (5*$d-1)*$d/2;

  if ($n < -$d) {
    $n += 2*$d;
    if ($n < 1) {
      # bottom horizontal
      return (2*$n+$d-1, -$d+1);
    } else {
      # lower right diagonal ...
      return ($n+$d, $n-$d);
    }
  } else {
    if ($n <= $d) {
      ### top 2,1 slope left and right diagonals ...
      return (-2*$n,
              -abs($n) + $d);
    } else {
      ### lower left diagonal ...
      return ($n - 3*$d,
              -$n + $d);
    }
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  $y = round_nearest ($y);

  # nothing on odd points
  # when y>=0 any odd x is not covered
  # when y<0 the uncovered alternates, x even on y=-1, x odd on y=-2, x even
  # y=-3 etc
  if (($x%2) ^ ($y < 0 ? $y%2 : 0)) {
    return undef;
  }

  if ($y >= 0) {
    ### top left and right slopes
    # vertical at x=0
    #   d = [ 1, 2, 3 ]
    #   n = [ 3, 10, 22 ]
    #   n = (5/2*$d**2 + -1/2*$d + 1)
    #
    ### assert: ($x%2)==0
    $x /= 2;
    my $d = abs($x) + $y;
    return (5*$d - 1)*$d/2 - $x + $self->{'n_start'};
  }

  if ($x < $y) {
    ### lower left slope
    # horizontal leftwards at y=0
    #   d = [ 1,  2,  3 ]
    #   n = [ 4, 12, 25 ]
    #   n = (5/2*$d**2 + 1/2*$d + 1)
    #     = (2.5*$d + 0.5)*$d + 1
    my $d = -($x+$y)/2;
    return (5*$d + 1)*$d/2 - $y + $self->{'n_start'};
  }

  if ($x > -$y) {
    ### lower right slope
    # horizontal rightwards at y=0
    #   d = [ 1, 2, 3, ]
    #   n = [ 2, 8, 19,]
    #   n = (5/2*$d**2 + -3/2*$d + 1)
    #     = (2.5*$d - 1.5)*$d + 1
    my $d = ($x-$y)/2;
    return (5*$d - 3)*$d/2 + $y + $self->{'n_start'};
  }

  ### bottom horizontal
  # vertical downwards at x=0 is
  #   y = [  -1, -2,   -3 ]
  #   n = [ 5.5, 15, 29.5 ]
  #   n = (5/2*$y**2 + -2*$y + 1)
  #     = (2.5*$y - 2)*$y + 1
  # so
  #   N = (2.5*$y - 2)*$y + 1  +  $x/2
  #     = ((5*$y - 4)*$y + $x)/2 + 1
  #
  return ((5*$y-4)*$y + $x)/2 + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### PentSpiral rect_to_n_range(): $x1,$y1, $x2,$y2

  my $d = 0;
  foreach my $x ($x1, $x2) {
    $x = round_nearest ($x);
    foreach my $y ($y1, $y2) {
      $y = round_nearest ($y);

      my $this_d = 1 + ($y >= 0     ? abs($x) + $y
                        : $x < $y   ? -($x+$y)/2
                        : $x > -$y  ? ($x-$y)/2
                        : -$y);
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

Math::PlanePath::PentSpiral -- integer points in a pentagonal shape

=head1 SYNOPSIS

 use Math::PlanePath::PentSpiral;
 my $path = Math::PlanePath::PentSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a pentagonal (five-sided) spiral with points spread out to
fit on a square grid.

                      22                              3

                23    10    21                        2

          24    11     3     9    20                  1

    25    12     4     1     2     8    19       <- Y=0

       26    13     5     6     7    18    ...       -1

          27    14    15    16    17    33           -2

             28    29    30    31    32              -2


     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7

Each horizontal gap is 2, so for instance n=1 is at x=0,y=0 then n=2 is at
x=2,y=0.  The lower diagonals are 1 across and 1 down, so n=17 is at
x=4,y=-2 and n=18 is x=5,y=-1.  But the upper angles go 2 across and 1 up,
so n=20 is x=4,y=1 then n=21 is x=2,y=2.

The effect is to make the sides equal length, except for a kink at the lower
right corner.  Only every second square in the plane is used.  In the top
half (y>=0) those points line up, in the lower half (y<0) they're offset on
alternate rows.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=PentSpiral,n_start=0 --expression='i<=57?i:0' --output=numbers --size=120x11

=pod

    n_start => 0            38

                      39    21    37
                                           ...
                40    22     9    20    36    57

          41    23    10     2     8    19    35    56

    42    24    11     3     0     1     7    18    34    55

       43    25    12     4     5     6    17    33    54

          44    26    13    14    15    16    32    53

             45    27    28    29    30    31    52

                46    47    48    49    50    51

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::PentSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::PentSpiral-E<gt>new (n_start =E<gt> $n)>

Create and return a new pentagon spiral object.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
point in the path as a square of side 1.

=back

=head1 FORMULAS

=head2 N to X,Y

It's convenient to work in terms of Nstart=0 and to take each loop as
beginning on the South-West diagonal,

                      21                loop d=3
                   --    --
                22          20
             --                --
          23                      19
       --                            --
    24                 0                18
      \                                /
       25          .                 17
         \                          /
          26    13----14----15----16
            \
             .

The SW diagonal is N=0,4,13,27,46,etc which is

    N = (5d-7)*d/2 + 1           # starting d=1 first loop

This can be inverted to get d from N

    d = floor( (sqrt(40*N + 9) + 7) / 10 )

Each side is length d, except the lower right diagonal slope which is d-1.
For the very first loop that lower right is length 0.

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A140066> (etc)

=back

    n_start=1 (the default)
      A192136    N on X axis, (5*n^2 - 3*n + 2)/2
      A140066    N on Y axis
      A116668    N on X negative axis
      A005891    N on South-East diagonal, centred pentagonals
      A134238    N on South-West diagonal

    n_start=0
      A000566    N on X axis, heptagonal numbers
      A005476    N on Y axis
      A028895    N on South-East diagonal

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PentSpiralSkewed>,
L<Math::PlanePath::HexSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019 Kevin Ryde

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
