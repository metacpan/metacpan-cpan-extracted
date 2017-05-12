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


package Math::PlanePath::MPeaks;
use 5.004;
use strict;
use List::Util 'min';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 124;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_sqrtint = \&Math::PlanePath::_sqrtint;

use Math::PlanePath::Base::Generic
  'round_nearest';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;
*xy_is_visited = \&Math::PlanePath::Base::Generic::xy_is_visited_quad12;

sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start;
}
# dX jumps back unbounded negative, but forward only +1
use constant dx_maximum => 1;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
use constant dsumxy_maximum => 2; # NE diagonal
use constant ddiffxy_maximum => 2; # SE diagonal
use constant dir_minimum_dxdy => (1,1);  # North-East
use constant dir_maximum_dxdy => (1,-1); # South-East

use constant parameter_info_array =>
  [
   Math::PlanePath::Base::Generic::parameter_info_nstart1(),
  ];


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new(@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

# starting each left side at 0.5 before
# [ 1,2,3 ],
# [ 1-0.5, 6-0.5, 17-0.5 ]
# N = (3 d^2 - 4 d + 3/2)
#   = (3*$d**2 - 4*$d + 3/2)
#   = ((3*$d - 4)*$d + 3/2)
# d = 2/3 + sqrt(1/3 * $n + -1/18)
#   = (2 + 3*sqrt(1/3 * $n - 1/18))/3
#   = (2 + sqrt(3 * $n - 1/2))/3
#   = (4 + 2*sqrt(3 * $n - 1/2))/6
#   = (4 + sqrt(12*$n - 2))/6
# at n=1/2 d=(4+sqrt(12/2-2))/6 = (4+sqrt(4))/6  = 1
#
# base at Y=0
# [ 1, 6, 17 ]
# N = (3 d^2 - 4 d + 2)
#   = (3*$d**2 - 4*$d + 2)
#   = ((3*$d - 4)*$d + 2)
#
# centre
# [ 3,11,25 ]
# N = (3 d^2 - d + 1)
#   = (3*$d**2 - $d + 1)
#   = ((3*$d - 1)*$d + 1)
#
sub n_to_xy {
  my ($self, $n) = @_;
  ### MPeaks n_to_xy(): $n

  # adjust to N=0 at start X=-1,Y=0
  $n = $n - $self->{'n_start'};

  my $d;
  {
    my $r = 12*$n + 10;
    if ($r < 4) {
      return;    # N < -0.5, so before start of path
    }
    $d = int( (_sqrtint($r) + 4)/6 );
  }
  $n -= (3*$d - 1)*$d;   # to $n==0 at centre
  ### $d
  ### remainder: $n

  if ($n >= $d) {
    ### right vertical ...
    # N-d is top of right peak
    # N-(3d-1) = N-3d+1 is right Y=0
    # Y=-(N-2d+1)= -N+3d-1
    return ($d,
            -$n + 3*$d - 1);
  }
  if ($n <= (my $neg_d = -$d)) {
    ### left vertical ...
    # N+(3d-1) is left Y=0
    # Y=N+3d-1
    return ($neg_d,
            $n + 3*$d - 1);
  }
  ### centre diagonals ...
  return ($n,
          abs($n) + $d-1);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### MPeaks xy_to_n(): $x, $y

  $y = round_nearest ($y);
  if ($y < 0) {
    return undef;
  }
  $x = round_nearest ($x);

  {
    my $two_x = 2*$x;
    if ($two_x > $y) {
      ### right vertical ...
      # right end [ 5,16,33 ]
      # N = (3 x^2 + 2 x)
      return (3*$x+2)*$x - $y + $self->{'n_start'} - 1;
    }
    if ($two_x < -$y) {
      ### left vertical ...
      # Nleftend = (3 d^2 - 4 d + 2)
      #          = (3x+4)x + 2
      return (3*$x+4)*$x + 1 + $y + $self->{'n_start'};
    }
  }

  ### centre diagonals ...
  # d=Y+abs(x) with d=0 first (not d=1 as above),  N=(3 d^2 + 5 d + 3)
  my $d = $y - abs($x);
  ### $d
  return (3*$d+5)*$d + 2 + $x + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);

  if ($y1 > $y2) { ($y1,$y2) = ($y2,$y1); } # swap to y1<=y2
  if ($y2 < 0) {
    return (1, 0); # rect all negative, no N
  }
  if ($y1 < 0) { $y1 *= 0; }   # "*=" to preserve bigint y1

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x1 > $x2) { ($x1,$x2) = ($x2,$x1); } # swap to x1<=x2

  my $zero = $x1 * 0 * $x2;

  # columns X<0 are increasing with increasing Y
  # columns X>0 increase below Y=2*X
  #
  return ($self->{'n_start'},
          max (
               # left column
               $self->xy_to_n($x1,
                              ($y2 >= 2*$x1 ? $y2 : $y1)),

               # right column
               $self->xy_to_n($x2,
                              ($y2 >= 2*$x2 ? $y2 : $y1)),

               # top row centre X=0, if it's covered by x1,x2
               ($x1 < 0 && $x2 > 0
                ? $self->xy_to_n($zero,$y2)
                : ())));
}

# No, because N decreases in right hand columns
# return (1,
#         max ($self->xy_to_n($x1,$y2),
#              $self->xy_to_n($x2,$y2),
#              # and at X=0 if it's covered by x1,x2
#              ($x1 < 0 && $x2 > 0 ? $self->xy_to_n($zero,$y2) : ()));

# my @n;
# if ($y1 <= 2*$x2) {
#   # right vertical
#   push @n, (3*$x2+2)*$x2 - $y1;
# }
# if (($x1 > 0) != ($x2 > 0)) {
#   # centre vertical
#   return (3*$y2+5)*$y2 + 3;
# }

1;
__END__

=for stopwords Ryde Math-PlanePath ie OEIS

=head1 NAME

Math::PlanePath::MPeaks -- points in expanding M shape

=head1 SYNOPSIS

 use Math::PlanePath::MPeaks;
 my $path = Math::PlanePath::MPeaks->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path puts points in layers of an "M" shape

=cut

# math-image --path=MPeaks --expression='i<=56?i:0' --output=numbers --size=50x10

=pod

         41                              49         7
         40  42                      48  50         6
         39  22  43              47  28  51         5
         38  21  23  44      46  27  29  52         4
         37  20   9  24  45  26  13  30  53         3
         36  19   8  10  25  12  14  31  54         2
         35  18   7   2  11   4  15  32  55         1
         34  17   6   1   3   5  16  33  56     <- Y=0

                          ^
         -4  -3  -2  -1  X=0  1   2   3   4

N=1 to N=5 is the first "M" shape, then N=6 to N=16 on top of that, etc.
The centre goes half way down.  Reckoning the N=1 to N=5 as layer d=1 then

    Xleft = -d
    Xright = d
    Ypeak = 2*d - 1
    Ycentre = d - 1

Each "M" is 6 points longer than the preceding.  The verticals are each 2
longer, and the centre diagonals each 1 longer.  This step 6 is similar to
the C<HexSpiral>.

The octagonal numbers N=1,8,21,40,65,etc k*(3k-2) are a straight line
of slope 2 going up to the left.  The octagonal numbers of the second
kind N=5,16,33,56,etc k*(3k+2) are along the X axis to the right.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, in the same pattern.  For example to
start at 0,

=cut

# math-image --path=MPeaks,n_start=0 --expression='i<=55?i:0' --output=numbers --size=50x10

=pod

    n_start => 0

    40                              48
    39  41                      47  49
    38  21  42              46  27  50
    37  20  22  43      45  26  28  51
    36  19   8  23  44  25  12  29  52
    35  18   7   9  24  11  13  30  53
    34  17   6   1  10   3  14  31  54
    33  16   5   0   2   4  15  32  55

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::MPeaks-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.

For C<$n < 0.5> the return is an empty list, it being considered there are
no negative points.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.  C<$x> and C<$y> are each
rounded to the nearest integer which has the effect of treating points as a
squares of side 1, so the half-plane y>=-0.5 is entirely covered.

=back

=head1 OEIS

Entries in Sloane's Online Encyclopedia of Integer Sequences related to this
path include

=over

L<http://oeis.org/A045944> (etc)

=back

    n_start=1 (the default)
      A045944    N on X axis >= 1, extra initial 0
                   being octagonal numbers second kind
      A056106    N on Y axis, extra initial 1
      A056109    N on X negative axis <= -1

    n_start=0
      A049450    N on Y axis, extra initial 0, 2*pentagonal

    n_start=2
      A027599    N on Y axis, extra initial 6,2

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::PyramidSides>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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


# Local variables:
# compile-command: "math-image --path=MPeaks --lines --scale=20"
# End:
#
# math-image --path=MPeaks --all --output=numbers
