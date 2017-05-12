# mostly works, but any good ?




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


# math-image --path=QuintetSide --lines --scale=10
# math-image --path=QuintetSide --output=numbers


package Math::PlanePath::QuintetSide;
use 5.004;
use strict;
use POSIX 'ceil';
use Math::Libm 'hypot';
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA', '@_xend','@_yend';
$VERSION = 124;
use Math::PlanePath 37;
@ISA = ('Math::PlanePath');

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh';

use Math::PlanePath::SacksSpiral;

# uncomment this to run the ### lines
#use Devel::Comments;

use constant n_start => 0;

sub n_to_xy {
  my ($self, $n) = @_;
  ### QuintetSide n_to_xy(): $n
  if ($n < 0) {
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  my $x;
  my $y = 0;
  { my $int = int($n);
    $x = $n - $int;
    $n = $int;
  }
  my $xend = 1;
  my $yend = 0;

  foreach my $digit (digit_split_lowtohigh($n,3)) {
    my $xend_offset = $xend - $yend;   # end + end rotated +90
    my $yend_offset = $yend + $xend;   #  being the digit 2 position

    ### at: "$x,$y"
    ### $digit
    ### $xend
    ### $yend
    ### $xend_offset
    ### $yend_offset

    if ($digit == 1) {
      ($x,$y) = (-$y + $xend,   # rotate +90
                 $x  + $yend);
    } elsif ($digit == 2) {
      $x += $xend_offset;       # digit 2 offset position
      $y += $yend_offset;
    }
    $xend += $xend_offset;   # 2*end + end rotated +90
    $yend += $yend_offset;
  }

  ### final: "$x,$y"
  return ($x, $y);
}

@_xend = (1);
@_yend = (0);
sub _ends_for_level {
  my ($level) = @_;
  ### $#_xend
  if ($#_xend < $level) {
    my $x = $_xend[-1];
    my $y = $_yend[-1];
    do {
      ($x,$y) = (2*$x - $y,     # 2*$x + rotate +90
                 2*$y + $x);    # 2*$y + rotate +90
      ### _ends_for_level() push: scalar(@_xend)."  $x,$y"
      # ### assert: "$x,$y" eq join(','__PACKAGE__->n_to_xy(scalar(@xend) ** 3))
      push @_xend, $x;
      push @_yend, $y;
    } while ($#_xend < $level);
  }
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  $x = round_nearest($x);
  $y = round_nearest($y);
  ### QuintetSide xy_to_n(): "$x, $y"

  my $r = hypot($x,$y);
  my $level = ceil(log($r+1)/log(sqrt(5)));
  if (is_infinite($level)) {
    return $level;
  }
  return _xy_to_n_in_level($x,$y,$level);
}


sub _xy_to_n_in_level {
  my ($x, $y, $level) = @_;

  _ends_for_level($level);
  my @pending_n = (0);
  my @pending_x = ($x);
  my @pending_y = ($y);
  my @pending_level = ($level);

  while (@pending_n) {
    my $n = pop @pending_n;
    $x = pop @pending_x;
    $y = pop @pending_y;
    $level = pop @pending_level;
    ### consider: "$x,$y  n=$n level=$level"

    if ($level == 0) {
      if ($x == 0 && $y == 0) {
        return $n;
      }
      next;
    }
    my $xend = $_xend[$level-1];
    my $yend = $_yend[$level-1];
    if (hypot($x,$y) * (.9/sqrt(5)) > hypot($xend,$yend)) {
      ### radius out of range: hypot($x,$y)." cf end ".hypot($xend,$yend)
      next;
    }

    $level--;
    $n *= 3;

    ### descend: "end=$xend,$yend"

    # digit 0
    push @pending_n, $n;
    push @pending_x, $x;
    push @pending_y, $y;
    push @pending_level, $level;
    ### push: "$x,$y  digit=0"

    # digit 1
    $x -= $xend;
    $y -= $yend;
    ($x,$y) = ($y, -$x);   # rotate -90
    push @pending_n, $n + 1;
    push @pending_x, $x;
    push @pending_y, $y;
    push @pending_level, $level;
    ### push: "$x,$y  digit=1"

    # digit 2
    $x -= $xend;
    $y -= $yend;
    ($x,$y) = (-$y, $x);   # rotate +90
    push @pending_n, $n + 2;
    push @pending_x, $x;
    push @pending_y, $y;
    push @pending_level, $level;
    ### push: "$x,$y  digit=2"
  }

  return undef;
}

# radius = sqrt(5) ^ level
# log(radius) = level * log(sqrt(5))
# level = log(radius) * 1/log(sqrt(5))
#
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;
  $y1 *= sqrt(3);
  $y2 *= sqrt(3);
  my ($r_lo, $r_hi) = Math::PlanePath::SacksSpiral::_rect_to_radius_range
    ($x1,$y1, $x2,$y2);
  my $level = ceil (log($r_hi+.1) * (1/log(sqrt(5))));
  if ($level < 1) { $level = 1; }
  return (0, 3**$level - 1);
}

1;
__END__

=for stopwords eg Ryde

=head1 NAME

Math::PlanePath::QuintetSide -- one side of the quintet tiling

=head1 SYNOPSIS

 use Math::PlanePath::QuintetSide;
 my $path = Math::PlanePath::QuintetSide->new;
 my ($x, $y) = $path->n_to_xy (123);

=head1 DESCRIPTION

This path is ...

                      ...
                       |
                26----27
                 |
          24----25
           |
          23----22
                 |
          20----21
           |
    18----19
     |
    17----16
           |
          15----14
                 |
                13----12                  6
                       |
                      11----10            5
                             |
                       8---- 9            4
                       |
                 6---- 7                  3
                 |
                 5---- 4                  2
                       |
                 2---- 3                  1
                 |
           0---- 1                    <- Y=0

           ^    
          X=0    1     2     3

It slowly spirals around counter clockwise, with a lot of wiggling in
between.  The N=3^level point is at

    N = 3^level
    angle = level * atan(1/2)
          = level * 26.56 degrees
    radius = sqrt(5) ^ level

A full revolution for example takes roughly level=14 which is about
N=4,780,000.

Both ends of such levels are in fact sub-spirals, like an "S" shape.

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::QuintetSide-E<gt>new ()>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional C<$n> gives a point on the straight line between surrounding
integer N.

=back

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::KochCurve>

L<Math::Fractal::Curve>

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
