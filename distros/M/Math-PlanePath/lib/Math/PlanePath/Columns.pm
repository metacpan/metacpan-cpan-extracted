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


package Math::PlanePath::Columns;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 125;
use Math::PlanePath;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'round_nearest',
  'floor';

# uncomment this to run the ### lines
#use Devel::Comments;

use constant class_x_negative => 0;
use constant class_y_negative => 0;
use constant n_frac_discontinuity => .5;

use constant parameter_info_array =>
  [ Math::PlanePath::Base::Generic::parameter_info_nstart1() ];

sub y_maximum {
  my ($self) = @_;
  return $self->{'height'} - 1;
}

sub diffxy_minimum {
  my ($self) = @_;
  if ($self->{'height'} == 0) {
    return 0;                       # at X=0,Y=0
  } else {
    return 1 - $self->{'height'};   # at X=0,Y=height-1
  }
}

sub dx_minimum {
  my ($self) = @_;
  return ($self->{'height'} <= 1
          ? 1   # single row only
          : 0);
}
use constant dx_maximum => 1;
sub _UNDOCUMENTED__dxdy_list {
  my ($self) = @_;
  return (($self->{'height'} >= 2 ? (0,1) # N too
           : ()),
          1, 1-$self->{'height'});
}
sub _UNDOCUMENTED__dxdy_list_at_n {
  my ($self) = @_;
  return $self->n_start + $self->{'height'} - 1;
}

sub dy_minimum {
  my ($self) = @_;
  return - ($self->{'height'}-1);
}
sub dy_maximum {
  my ($self) = @_;
  return ($self->{'height'} <= 1
          ? 0   # single row only
          : 1);
}

sub absdx_minimum {
  my ($self) = @_;
  return ($self->{'height'} <= 1
          ? 1   # single row only
          : 0);
}
sub absdy_minimum {
  my ($self) = @_;
  return ($self->{'height'} <= 1 ? 0 : 1);
}

sub dsumxy_minimum {
  my ($self) = @_;
  return 2 - $self->{'height'}; # dX=+1 dY=-(height-1)
}
use constant dsumxy_maximum => 1;

sub ddiffxy_minimum {
  my ($self) = @_;
  return ($self->{'height'} == 1
          ? 1    # constant dX=1,dY=0
          : -1); # straight N
}
sub ddiffxy_maximum {
  my ($self) = @_;
  return $self->{'height'}; # dX=+1 dY=-(height-1)
}

sub dir_minimum_dxdy {
  my ($self) = @_;
  return ($self->{'height'} == 1
          ? (1,0)   # height=1 East only
          : (0,1)); # height>1 North
}
sub dir_maximum_dxdy {
  my ($self) = @_;
  return (1, $self->dy_minimum);
}

sub turn_any_left {
  my ($self) = @_;
  return ($self->{'height'} != 1);  # height=1 only straight ahead
}
sub _UNDOCUMENTED__turn_any_left_at_n {
  my ($self) = @_;
  return ($self->{'height'} == 1 ? undef
          : $self->n_start + $self->{'height'});
}

*turn_any_right = \&turn_any_left;
sub _UNDOCUMENTED__turn_any_right_at_n {
  my ($self) = @_;
  return ($self->{'height'} == 1 ? undef
          : $self->n_start + $self->{'height'} - 1);
}

sub turn_any_straight {
  my ($self) = @_;
  return ($self->{'height'} != 2);  # height=2 never straight
}


#------------------------------------------------------------------------------

sub new {
  my $self = shift->SUPER::new (@_);
  if (! exists $self->{'height'}) {
    $self->{'height'} = 1;
  }
  if (! defined $self->{'n_start'}) {
    $self->{'n_start'} = $self->default_n_start;
  }
  return $self;
}

sub n_to_xy {
  my ($self, $n) = @_;

  # no division by zero, and negatives not meaningful for now
  my $height;
  if (($height = $self->{'height'}) <= 0) {
    ### no points for height<=0
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

  my $x = int ($int / $height);
  $int -= $x*$height;
  if ($int < 0) {    # ensure round down when $int negative
    $int += $height;
    $x -= 1;
  }
  ### floor x: $x
  ### remainder: $int

  return ($x,
          $n + $int);
}

sub xy_to_n {
  my ($self, $x, $y) = @_;

  $y = round_nearest ($y);
  if ($y < 0 || $y >= $self->{'height'}) {
    return undef;  # outside the oblong
  }
  $x = round_nearest ($x);
  return $x * $self->{'height'} + $y + $self->{'n_start'};
}

# exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  my $height = $self->{'height'};

  $y1 = round_nearest ($y1);
  $y2 = round_nearest ($y2);
  if ($y2 < $y1) { ($y1,$y2) = ($y2,$y1) } # swap to y1<y2
  ### assert: $y1<=$y2

  if ($height<=0 || $y1 >= $height || $y2 < 0) {
    ### completely outside 0 to height-1, or height<=0 ...
    return (1,0);
  }

  $x1 = round_nearest ($x1);
  $x2 = round_nearest ($x2);
  if ($x2 < $x1) { ($x1,$x2) = ($x2,$x1) } # swap to x1<x2
  ### assert: $x1<=$x2

  if ($y1 < 0) { $y1 *= 0; }                            # preserve bignum
  if ($y2 >= $height) { $y2 = ($y2*0) + $height-1; }  # preserve bignum

  # exact range bottom left to top right
  return ($x1*$height + $y1 + $self->{'n_start'},
          $x2*$height + $y2 + $self->{'n_start'});
}

1;
__END__

=for stopwords PlanePath Math-PlanePath Ryde

=head1 NAME

Math::PlanePath::Columns -- points in fixed-height columns

=head1 SYNOPSIS

 use Math::PlanePath::Columns;
 my $path = Math::PlanePath::Columns->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is columns of a given fixed height.  For example height 5 would be

         |
      4  |   5  10  15  20        <---  height==5
      3  |   4   9  14  19
      2  |   3   8  13  18
      1  |   2   7  12  17  ...
    Y=0  |   1   6  11  16  21 
          ----------------------
           X=0   1   2   3   4  ...

=head2 N Start

The default is to number points starting N=1 as shown above.  An optional
C<n_start> can give a different start, with the same shape.  For example to
start at 0,

=cut

# math-image --path=Columns,n_start=0,height=5 --all --output=numbers

=pod

    n_start => 0, height => 5

      4  |   4   9  14  19 
      3  |   3   8  13  18 
      2  |   2   7  12  17 
      1  |   1   6  11  16  ...
    Y=0  |   0   5  10  15  20
          ----------------------
           X=0   1   2   3   4  ...

The only effect is to push the N values around by a constant amount.  It
might help match coordinates with something else zero-based.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for behaviour common to all path classes.

=over 4

=item C<$path = Math::PlanePath::Columns-E<gt>new (height =E<gt> $h)>

=item C<$path = Math::PlanePath::Columns-E<gt>new (height =E<gt> $h, n_start =E<gt> $n)>

Create and return a new path object.  A C<height> parameter must be supplied.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> in the path.

=item C<$n = $path-E<gt>xy_to_n ($x,$y)>

Return the point number for coordinates C<$x,$y>.

C<$x> and C<$y> are rounded to the nearest integers, which has the effect of
treating each point in the path as a square of side 1, so a rectangle $x >=
-0.5 and -0.5 <= y < height+0.5 is covered.

=item C<($n_lo, $n_hi) = $path-E<gt>rect_to_n_range ($x1,$y1, $x2,$y2)>

The returned range is exact, meaning C<$n_lo> and C<$n_hi> are the smallest
and biggest in the rectangle.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::Rows>,
L<Math::PlanePath::CoprimeColumns>

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
