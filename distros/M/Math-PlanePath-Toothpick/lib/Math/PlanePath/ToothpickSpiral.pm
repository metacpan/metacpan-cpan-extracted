# Copyright 2013, 2014, 2015 Kevin Ryde

# This file is part of Math-PlanePath-Toothpick.
#
# Math-PlanePath-Toothpick is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Math-PlanePath-Toothpick is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath-Toothpick.  If not, see <http://www.gnu.org/licenses/>.


package Math::PlanePath::ToothpickSpiral;
use 5.004;
use strict;
use Carp 'croak';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 18;
use Math::PlanePath;
use Math::PlanePath::Base::NSEW;
@ISA = ('Math::PlanePath::Base::NSEW',
        'Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';

# uncomment this to run the ### lines
# use Smart::Comments;


use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

use constant xy_is_visited => 1;
sub x_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 2;
}
sub y_negative_at_n {
  my ($self) = @_;
  return $self->n_start + 5;
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + 5;
}

use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

#          51-50
#           |  |
#             49-48
#                 |
#          19-18 47-46
#           |  |     |
#       21-20 17-16 45-44
#        |        |     |
#    23-22  3--2 15-14 43-42
#     |     |  |     |     |
# 25-24  5--4  1 12-13 40-41
#  |     |        |     |
# 26-27  6--7 10-11 38-39
#     |     |  |     |
#    28-29  8--9 36-37
#        |        |
#       30-31 34-35
#           |  |
#          32-33

# side 2, 6, 10
#      3, 7
#      3, 7
#
# 1,13,41
# N = (8 d^2 + 4 d + 1)
#   = (8*$d**2 + 4*$d + 1)
#   = ((8*$d + 4)*$d + 1)
# d = -1/4 + sqrt(1/8 * $n + -1/16)
#   = (-1 + sqrt(2*$n -1)) / 4

sub n_to_xy {
  my ($self, $n) = @_;
  ### ToothpickSpiral n_to_xy(): $n

  $n = $n - ($self->{'n_start'}-1);  # to N=1 basis
  if ($n < 1) { return; }
  if (is_infinite($n)) { return ($n,$n); }

  my $y = int($n);
  $n -= $y;         # $n = fraction part

  my $d = int((sqrt(2*$y-1) - 1) / 4);
  $d *= 2;          # counting rings 0,2,4,6,etc
  $y -= (2*$d+2)*$d + 1;

  ### $d
  ### int offset into ring: $y

  ($y, my $odd) = _divrem($y, 2);
  my $x = $d - $y;
  if ($odd) {
    $x = -$n + $x;
    $y += 1;
  } else {
    $y = $n + $y;
  }
  # at this point $x,$y is a stairstep up towards the North-West starting
  # from the X axis X=2*d,Y=0

  $d += 1;          # now counting rings 1,3,5,7,etc
  if ($y <= 2*$d) {
    return ($x, -abs($y-$d) + $d);
  } else {
    return (-$x - 2*$d - 2, abs($y-3*$d-1) -$d - 1);
  }
  return ($x,$y);

}

# return ($quotient, $remainder)
sub _divrem {
  my ($n, $d) = @_;
  if (ref $n && $n->isa('Math::BigInt')) {
    my ($quot,$rem) = $n->copy->bdiv($d);
    if (! ref $d || $d < 1_000_000) {
      $rem = $rem->numify;  # plain remainder if fits
    }
    return ($quot, $rem);
  }
  my $rem = $n % $d;
  return (int(($n-$rem)/$d), # exact division stays in UV
          $rem);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  # use Smart::Comments;
  ### ToothpickSpiral xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  if ($y > 0 && $x >= 0) {      # first quadrant
    my $d = $x + $y;
    my $odd = ($d % 2);
    $d -= $odd;
    return (2*$d+2)*$d + 2*$y - $odd + $self->{'n_start'};
  }
  if ($y >= 0 && $x < 0) {      # second quadrant
    my $d = $y - $x;
    my $odd = ($d % 2);
    $d += $odd;
    return (2*$d-4)*$d - 2*$x + $odd + $self->{'n_start'};
  }
  if ($x < 0) {                 # third quadrant
    my $d = $x + $y;
    my $odd = ($d % 2);
    $d -= 1-$odd;
    return (2*$d+4)*$d + 2 + 2*$x + $odd + $self->{'n_start'};
  }

  # fourth quadrant
  my $d = $x - $y;
  my $odd = ($d % 2);
  $d -= 1-$odd;
  return (2*$d+4)*$d + 2 + 2*$x + $odd + $self->{'n_start'};
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### ToothpickSpiral rect_to_n_range(): "$x1,$y1  $x2,$y2"

  $x1 = abs(round_nearest($x1));
  $y1 = abs(round_nearest($y1));
  $x2 = abs(round_nearest($x2));
  $y2 = abs(round_nearest($y2));

  my $x = max($x1,$x2);
  my $y = max($y1,$y2) + 1;
  return ($self->n_start, $self->xy_to_n($x,$y));
}

1;
__END__

=for stopwords eg Ryde Math-PlanePath Legendre's

=head1 NAME

Math::PlanePath::ToothpickSpiral -- integer points in stair-step diagonal stripes

=head1 SYNOPSIS

 use Math::PlanePath::ToothpickSpiral;
 my $path = Math::PlanePath::ToothpickSpiral->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is length=2 toothpicks placed in an anti-clockwise spiral.
A single new toothpick is added at an end of the preceding.  Each is as
close to the origin as possible without toothpicks overlapping.  Ends may
touch, but no overlapping.

             |
             3---2---
         |   |   |
         5---4-- 1  ...
         |   |   |   |
      ---6---7 -10--11
             |   |   |
           --8---9
                 |

The result is a stair-step diamond spiral starting vertically.  As per the
other toothpick paths the vertical toothpicks are "even" points X=Ymod2 and
horizontal toothpicks "odd" points X!=Ymod2.

=cut

# math-image --path=ToothpickSpiral --expression='i<=45?i:0' --output=numbers_dash --size=80x25

=pod

             19-18    ...              3
              |  |     |
          21-20 17-16 45-44            2
           |        |     |
       23-22  3--2 15-14 43-42         1
        |     |  |     |     |
    25-24  5--4  1 12-13 40-41    <- Y=0
     |     |        |     |
    26-27  6--7 10-11 38-39           -1
        |     |  |     |
       28-29  8--9 36-37              -2
           |        |
          30-31 34-35                 -3
              |  |
             32-33                    -4

                 ^
    -4 -3 -2 -1 X=0 1  2  3  4


X<Hexagonal numbers>N=1,15,45,etc on the X=Y leading diagonal and
N=6,28,66,etc on the X=Y-1 South-West diagonal are the hexagonal numbers
k*(2k-1).  The odd hexagonals are to the North-East and the even hexagonals
to the South-West.

The hexagonal numbers of the "second kind" which are k*(2k-1) for k
negative.  They fall similarly on the X=-Y-1 North-West and X=-Y South-East
diagonals.

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different numbering of the same shape.  For example to
start at 0,

=cut

# math-image --path=ToothpickSpiral,n_start=0 --expression='i<=45?i:0' --output=numbers_dash --size=80x25

=pod

              18-17          n_start => 0 
              |  |    
          20-19 16-15 
           |        |    
       22-21  2--1 14-13 
        |     |  |     | 
    24-23  4--3  0 11-12 
     |     |        |
    25-26  5--6  9-10
        |     |  | 
       27-28  7--8 
           |
          ...

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::ToothpickSpiral-E<gt>new ()>

=item C<$path = Math::PlanePath::ToothpickSpiral-E<gt>new (n_start =E<gt> $n)>

Create and return a new staircase path object.

=back

Entries in Sloane's Online Encyclopedia of Integer Sequences related to
this path include

=over

L<http://oeis.org/A059285> (etc)

=back

    n_start=1 (the default)
      A014634     N on diagonal X=Y, odd hexagonals
      A033567     N on diagonal North-West
      A185438     N on diagonal South-West
      A188135     N on diagonal South-East
    
    n_start=0
       A033587    N on diagonal X=Y
       A014635    N on diagonal South-West, even hexagonals
       A033585    N on diagonal South-East


=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Staircase>,
L<Math::PlanePath::DiamondSpiral>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2013, 2014, 2015 Kevin Ryde

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
