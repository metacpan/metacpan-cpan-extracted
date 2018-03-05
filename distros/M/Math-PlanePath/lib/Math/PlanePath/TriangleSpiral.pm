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


package Math::PlanePath::TriangleSpiral;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest';
*_sqrtint = \&Math::PlanePath::_sqrtint;

# uncomment this to run the ### lines
#use Smart::Comments;


*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_even;
use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 4;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 6;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 3;
}
use constant dx_minimum => -1;
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant 1.02 _UNDOCUMENTED__dxdy_list => (2,0,    # E
                                               -1,1,   # NW
                                               -1,-1); # SW
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # SW diagonal
use constant dsumxy_maximum => 2;  # dX=+2 horiz
use constant ddiffxy_minimum => -2;  # NW diagonal
use constant ddiffxy_maximum => 2;   # dX=+2 horiz
use constant dir_maximum_dxdy => (-1,-1); # at most South-West diagonal

use constant turn_any_right => 0; # only left or straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# base at bottom right corner
#   d = [ 1,  2,  3 ]
#   n = [ 2,  11, 29 ]
#   $d = 1/2 + sqrt(2/9 * $n + -7/36)
#      = 1/2 + sqrt(8/36 * $n + -7/36)
#      = 0.5 + sqrt(8*$n + -7)/6
#      = (1 + 2*sqrt(8*$n + -7)/6) / 2
#      = (1 + sqrt(8*$n + -7)/3) / 2
#      = (3 + sqrt(8*$n - 7)) / 6
#
#   $n = (9/2*$d**2 + -9/2*$d + 2)
#      = (4.5*$d - 4.5)*$d + 2
#
# top of pyramid
#   d = [ 1,  2,  3 ]
#   n = [ 4, 16, 37 ]
#   $n = (9/2*$d**2 + -3/2*$d + 1)
# so remainder from there
#   rem = $n - (9/2*$d**2 + -3/2*$d + 1)
#       = $n - (4.5*$d*$d - 1.5*$d + 1)
#       = $n - ((4.5*$d - 1.5)*$d + 1)
#
#
sub n_to_xy {
  my ($self, $n) = @_;
  #### TriangleSpiral n_to_xy: $n

  $n = $n - $self->{'n_start'};  # starting $n==0, warn if $n==undef
  if ($n < 0) { return; }

  my $d = int ((3 + _sqrtint(8*$n+1)) / 6);
  #### $d

  $n -= (9*$d - 3)*$d/2;
  #### remainder: $n

  if ($n <= 3*$d) {
    ### sides, remainder pos/neg from top
    return (-$n,
            2*$d - abs($n));
  } else {
    ### rightwards from bottom left
    ### remainder: $n - 3*$d
    # corner is x=-3*$d
    # so -3*$d + 2*($n - 3*$d)
    #  = -3*$d + 2*$n - 6*$d
    #  = -9*$d + 2*$n
    #  = 2*$n - 9*$d
    return (2*$n - 9*$d,
            -$d);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest ($x);
  $y = round_nearest ($y);
  ### xy_to_n(): "$x,$y"

  if (($x ^ $y) & 1) {
    return undef;  # nothing on odd points
  }

  if ($y < 0 && 3*$y <= $x && $x <= -3*$y) {
    ### bottom horizontal
    # negative y, at vertical x=0
    #   [  -1, -2,   -3, -4,  -5,   -6 ]
    #   [ 8.5, 25, 50.5, 85, 128.5, 181 ]
    #   $n = (9/2*$y**2 + -3*$y + 1)
    #      = (4.5*$y*$y + -3*$y + 1)
    #      = ((4.5*$y -3)*$y + 1)
    # from which $x/2
    #
    return ((9*$y - 6)*$y/2) + $x/2 + $self->{'n_start'};

  } else {
    ### sides diagonal
    #
    # positive y, x=0 centres
    #   [ 2,  4,  6,  8 ]
    #   [ 4, 16,  37, 67 ]
    #   n = (9/8*$d**2 + -3/4*$d + 1)
    #     = (9/8*$d + -3/4)*$d + 1
    #     = (9*$d + - 6)*$d/8 + 1
    # from which -$x offset
    #
    my $d = abs($x) + $y;
    return ((9*$d - 6)*$d/8) - $x + $self->{'n_start'};
  }
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
                1 + ($y < 0 && 3*$y <= $x && $x <= -3*$y
                     ? -$y                          # bottom horizontal
                     : int ((abs($x) + $y) / 2)));  # sides
    }
  }
  return ($self->{'n_start'},
          (9*$d - 9)*$d/2 + $self->{'n_start'});
}

1;
__END__

=for stopwords Ryde Math-PlanePath hendecagonal 11-gonal (s+2)-gonal OEIS hendecagonals

=head1 NAME

Math::PlanePath::TriangleSpiral -- integer points drawn around an equilateral triangle

=head1 SYNOPSIS

 use Math::PlanePath::TriangleSpiral;
 my $path = Math::PlanePath::TriangleSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path makes a spiral shaped as an equilateral triangle (each side the
same length).

                      16                                 4
                     /  \   
                   17    15                              3
                  /        \  
                18     4    14    ...                    2
               /     /  \     \     \
             19     5     3    13    32                  1
            /     /        \     \     \
          20     6     1-----2    12    31          <- Y=0
         /     /                    \     \
       21     7-----8-----9----10----11    30           -1
      /                                      \
    22----23----24----25----26----27----28----29        -2
                       
                       ^
    -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8

Cells are spread horizontally to fit on a square grid as per
L<Math::PlanePath/Triangular Lattice>.  The horizontal gaps are 2, so for
instance n=1 is at x=0,y=0 then n=2 is at x=2,y=0.  The diagonals are 1
across and 1 up or down, so n=3 is at x=1,y=1.  Each alternate row is offset
from the one above or below.

This grid is the same as the C<HexSpiral> and the path is like that spiral
except instead of a flat top and SE,SW sides it extends to triangular peaks.
The result is a longer loop and each successive loop is step=9 longer than
the previous (whereas the C<HexSpiral> is step=6 more).

X<Triangular numbers>The triangular numbers 1, 3, 6, 10, 15, 21, 28, 36 etc,
k*(k+1)/2, fall one before the successive corners of the triangle, so when
plotted make three lines going vertically and angled down left and right.

The 11-gonal "hendecagonal" numbers 11, 30, 58, etc, k*(9k-7)/2 fall on a
straight line horizontally to the right.  (As per the general rule that a
step "s" lines up the (s+2)-gonal numbers.)

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start with the same shape etc.  For example
to start at 0,

=cut

# math-image --path=TriangleSpiral,n_start=0 --expression='i<=31?i:0' --output=numbers_dash

=pod

    n_start => 0      15   
                     /  \  
                   16    14
                  /        \     
                17     3    13   
               /     /  \     \  
             18     4     2    12   ...  
            /     /        \     \     \ 
          19     5     0-----1    11    30 
         /     /                    \     \ 
       20     6-----7-----8-----9----10    29 
      /                                      \ 
    21----22----23----24----25----26----27----28 

With this adjustment the X axis N=0,1,11,30,etc is the hendecagonal numbers
(9k-7)*k/2.  And N=0,8,25,etc diagonally South-East is the hendecagonals of
the second kind which is (9k-7)*k/2 for k negative.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::TriangleSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::TriangleSpiral-E<gt>new (n_start =E<gt> $n)>

Create and return a new triangle spiral object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n < 1> the return is an empty list, it being considered the path
starts at 1.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are
each rounded to the nearest integer, which has the effect of treating each
C<$n> in the path as a square of side 1.

Only every second square in the plane has an N.  If C<$x,$y> is a
position without an N then the return is C<undef>.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A117625> (etc)

=back

    n_start=1 (default)
      A010054     turn 1=left,0=straight, extra initial 1

      A117625     N on X axis
      A081272     N on Y axis
      A006137     N on X negative axis
      A064226     N on X=Y leading diagonal, but without initial value=1
      A064225     N on X=Y negative South-West diagonal
      A081267     N on X=-Y negative South-East diagonal
      A081589     N on ENE slope dX=3,dY=1
      A038764     N on WSW slope dX=-3,dY=-1
      A060544     N on ESE slope dX=3,dY=-1 diagonal

      A063177     total sum previous row or diagonal

    n_start=0
      A051682     N on X axis (11-gonal numbers)
      A062741     N on Y axis
      A062708     N on X=Y leading diagonal
      A081268     N on X=Y+2 diagonal (right of leading diagonal)
      A062728     N on South-East diagonal (11-gonal second kind)
      A062725     N on South-West diagonal
      A081275     N on ENE slope from X=2,Y=0 then dX=+3,dY=+1
      A081266     N on WSW slope dX=-3,dY=-1
      A081271     N on X=2 vertical

    n_start=-1
      A023531     turn 1=left,0=straight, being 1 at N=k*(k+3)/2
      A023532     turn 1=straight,0=left

A023531 is C<n_start=-1> to match its "offset=0" for the first turn, being
the second point of the path.  A010054 which is 1 at triangular numbers
k*(k+1)/2 is the same except for an extra initial 1.

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::TriangleSpiralSkewed>,
L<Math::PlanePath::HexSpiral>

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
