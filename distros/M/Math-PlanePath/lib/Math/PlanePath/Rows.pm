# Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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


package Math::PlanePath::Rows;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 129;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest',
  'floor';

# uncomment this to run the ### lines
#use Smart::Comments;


use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

sub x_maximum {
  my ($self) = @_;
  return $self->{'width'} - 1;
}

sub dx_minimum {
  my ($self) = @_;
  return - ($self->{'width'}-1);
}
sub dx_maximum {
  my ($self) = @_;
  return ($self->{'width'} <= 1
          ? 0   # single column only
          : 1);
}

sub dy_minimum {
  my ($self) = @_;
  return ($self->{'width'} <= 1
          ? 1   # single column only
          : 0);
}
use constant dy_maximum => 1;
sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return (($self->{'width'} >= 2 ? (1,0)  # E too
           : ()),
          1-$self->{'width'}, 1);
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + $self->{'width'} - 1;
}

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'width'} <= 1 ? 0 : 1);
}
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'width'} <= 1
          ? 1   # single column only
          : 0);
}

sub dsumxy_minimum {
  my ($self) = @_;
  return 2 - $self->{'width'}; # dX=-(width-1) dY=+1
}
use constant dsumxy_maximum => 1;
sub ddiffxy_minimum {
  my ($self) = @_;
  # dX=-(width-1) dY=+1 gives dDiffXY=-width+1-1=-width
  return - $self->{'width'};
}
sub ddiffxy_maximum {
  my ($self) = @_;
  return ($self->{'width'} == 1
          ? -1  # constant dY=-1
          : 1); # straight E
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'width'} == 1
          ? (0,1)   # width=1 North only
          : (1,0)); # width>1 East
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return (1-$self->{'width'}, 1);
}

sub turn_any_left {
  my ($self) = @_;
  return ($self->{'width'} > 1);  # width==1 only straight ahead
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return ($self->{'width'} == 1 ? undef
          : $self->n_start + $self->{'width'} - 1);
}

*turn_any_right = \&turn_any_left;
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return ($self->{'width'} == 1 ? undef
          : $self->n_start + $self->{'width'});
}

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'width'} != 2);  # width=2 never straight
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! exists $self->{'width'}) {
    $self->{'width'} = 1;
  }
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  ### width: $self->{'width'}
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;
  ### Rows n_to_xy(): "$n"

  # no division by width=0, and width<0 not meaningful for now
  my $width;
  if (($width = $self->{'width'}) <= 0) {
    ### no points for width<=0
    return;
  }

  $n = $n - $self->{'n_start'};  # zero based

  my $int = int($n);  # BigFloat int() gives BigInt, use that
  $n -= $int;         # fraction part, preserve any BigFloat

  if (2*$n >= 1) {  # if $n >= 0.5, but BigInt friendly
    $n -= 1;
    $int += 1;
  }
  ### $n
  ### $int
  ### assert: $n >= -0.5
  ### assert: $n < 0.5

  my $y = int ($int / $width);
  $int -= $y*$width;
  if ($int < 0) {    # ensure round down when $int negative
    $int += $width;
    $y -= 1;
  }
  ### floor y: $y
  ### remainder: $int

  return ($n + $int,
          $y);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $x = round_nearest ($x);
  if ($x < 0 || $x >= $self->{'width'}) {
    return undef;  # outside the column
  }
  $y = round_nearest ($y);
  return $x + $y * $self->{'width'} + $self->{'n_start'};
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  ### rect_to_n_range: "$x1,$y1  $x2,$y2"
  my $width = $self->{'width'};

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x2 < $x1) { ($x1,$x2) = ($x2,$x1) } # swap to x1<x2

  ### x range: "$x1 to $x2"
  ### assert: $x1<=$x2
  if ($width <= 0 || $x1 >= $width || $x2 < 0) {
    ### completely outside 0 to width, or width<=0
    return (1,0);
  }

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y2 < $y1) { ($y1,$y2) = ($y2,$y1) } # swap to y1<y2
  ### assert: $y1<=$y2

  if ($x1 < 0) { $x1 *= 0; }                          # preserve bignum
  if ($x2 >= $width) { $x2 = ($x2 * 0) + $width-1; }  # preserve bignum

  ### rect exact on: "$x1,$y1  $x2,$y2"

  # exact range bottom left to top right
  return ($x1 + $y1 * $width + $self->{'n_start'},
          $x2 + $y2 * $width + $self->{'n_start'});
}

1;
__END__

=for stopwords Math-PlanePath Ryde

=head1 NAME

Math::PlanePath::Rows -- points in fixed-width rows

=head1 SYNOPSIS

 use Math::PlanePath::Rows;
 my $path = Math::PlanePath::Rows->new (width => 20);
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is rows of a given fixed width.  For example width=7 is

    width => 7

      3  |  22  23  24 ...
      2  |  15  16  17  18  19  20  21
      1  |   8   9  10  11  12  13  14
    Y=0  |   1   2   3   4   5   6   7
          -------------------------------
           X=0   1   2   3   4   5   6

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, with the same shape.  For example to
start at 0,

=cut

# math-image --path=Rows,n_start=0,width=7 --all --output=numbers

=pod

    n_start => 0, width => 7

      3  |  21  22  23  24 ...
      2  |  14  15  16  17  18  19  20
      1  |   7   8   9  10  11  12  13
    Y=0  |   0   1   2   3   4   5   6
          -------------------------------
           X=0   1   2   3   4   5   6

The only effect is to push the N values around by a constant amount.  It
might help match coordinates with something else zero-based.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::Rows-E<gt>new (width =E<gt> $w)>

=item C<$path = Math::PlanePath::Rows-E<gt>new (width =E<gt> $w, n_start =E<gt> $n)>

Create and return a new path object.  A C<width> parameter must be supplied.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> in the path.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.

C<$x> and C<$y> are rounded to the nearest integers, which has the effect of
treating each point in the path as a square of side 1, so a column -0.5 <= x
< width+0.5 and y>=-0.5 is covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 SEE ALSO

L<Math::PlanePath>, L<Math::PlanePath::Columns>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019, 2020 Kevin Ryde

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
