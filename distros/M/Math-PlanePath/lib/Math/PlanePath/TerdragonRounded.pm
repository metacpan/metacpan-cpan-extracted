# Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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


package Math::PlanePath::TerdragonRounded;
use 5.004;
use strict;
#use List::Util 'max';
*max = \&Math::PlanePath::_max;

use vars '$VERSION', '@ISA';
$VERSION = 126;
use Math::PlanePath;
@ISA = ('Math::PlanePath');
*_divrem_mutate = \&Math::PlanePath::_divrem_mutate;

use Math::PlanePath::Base::Generic
  'is_infinite',
  'round_nearest';
use Math::PlanePath::Base::Digits
  'round_up_pow';
use Math::PlanePath::TerdragonCurve;

# uncomment this to run the ### lines
# use Smart::Comments;


use constant n_start => 0;

*parameter_info_array   # arms
  = \&Math::PlanePath::TerdragonCurve::parameter_info_array;
*new = \&Math::PlanePath::TerdragonCurve::new;

{
  my @x_negative_at_n = (undef, 24, 7, 2, 2, 2, 2);
  sub x_negative_at_n {
    my ($self) = @_;
    return $x_negative_at_n[$self->{'arms'}];
  }
}
{
  my @y_negative_at_n = (undef, 316, 145, 32, 11, 4, 4);
  sub y_negative_at_n {
    my ($self) = @_;
    return $y_negative_at_n[$self->{'arms'}];
  }
}
use constant sumabsxy_minimum => 2; # X=2,Y=0
sub rsquared_minimum {
  my ($self) = @_;
  return ($self->arms_count < 2
          ? 4   # 1 arm, minimum X=2,Y=0
          : 2); # 2 or more arms, minimum X=1,Y=1
}

use constant dx_minimum => -2;
use constant dx_maximum => 2;
use constant dy_minimum => -1;
use constant dy_maximum => 1;
*_UNDOCUMENTED__dxdy_list = \&Math::PlanePath::_UNDOCUMENTED__dxdy_list_six;
use constant absdx_minimum => 1;
use constant dsumxy_minimum => -2; # diagonals
use constant dsumxy_maximum => 2;
use constant ddiffxy_minimum => -2;
use constant ddiffxy_maximum => 2;
use constant dir_maximum_dxdy => (1,-1); # South-East
use constant turn_any_straight => 0; # never straight


#------------------------------------------------------------------------------

sub n_to_xy {
  my ($self, $n) = @_;
  ### TerdragonRounded n_to_xy(): $n

  if ($n < 0) {            # negative
    return;
  }
  if (is_infinite($n)) {
    return ($n,$n);
  }

  {
    # ENHANCE-ME: the ends join and the direction can be had without a full
    # N+1 calculation
    my $int = int($n);
    ### $int
    ### $n
    if ($n != $int) {
      my ($x1,$y1) = $self->n_to_xy($int);
      my ($x2,$y2) = $self->n_to_xy($int+$self->{'arms'});
      my $frac = $n - $int;  # inherit possible BigFloat
      my $dx = $x2-$x1;
      my $dy = $y2-$y1;
      return ($frac*$dx + $x1, $frac*$dy + $y1);
    }
    $n = $int; # BigFloat int() gives BigInt, use that
  }

  my $arms_count = $self->{'arms'};
  my $arm = _divrem_mutate ($n, $arms_count);
  my $pair = _divrem_mutate ($n, 2);

  my ($x, $y) = $self->Math::PlanePath::TerdragonCurve::n_to_xy
    ((9*$n + ($pair ? 4 : 2)) * $arms_count + $arm);

  ### is: (($x+3*$y)/2).", ".(($y-$x)/2)

  return (($x+3*$y)/2, ($y-$x)/2);  # rotate -60
}

sub xy_to_n {
  my ($self, $x, $y) = @_;
  ### TerdragonRounded xy_to_n(): "$x, $y"

  $x = round_nearest($x);
  $y = round_nearest($y);

  {
    my $sum = 3*$y + $x;
    if (is_infinite($sum)) { return $sum; }
    $sum %= 6;
    unless ($sum == 2 || $sum == 4) { return undef; }
  }

  ($x,$y) = (($x-3*$y)/2,   # rotate +60
             ($x+$y)/2);
  ### rotated: "$x,$y"

  my @n_list = $self->Math::PlanePath::TerdragonCurve::xy_to_n_list ($x, $y);
  ### @n_list

  my $arms_count = $self->{'arms'};
  foreach my $n (@n_list) {
    my $arm = _divrem_mutate ($n, $arms_count);
    ### $arm
    ### remainder: $n

    my $mod = $n % 9;
    if ($mod == 2) {
      return (2*int(($n-2)/9))*$arms_count + $arm;
    }
    if ($mod == 4) {
      return (2*int(($n-4)/9) + 1)*$arms_count + $arm;
    }
  }
  return undef;
}

# arms==6 is all "hex_centred" points X+3Y mod 6 == 2 or 4
sub xy_is_visited {
  my ($self, $x, $y) = @_;
  if ($self->{'arms'} == 6) {
    my $mod = (3*$y + $x) % 6;
    return ($mod == 2 || $mod == 4);
  }
  return defined($self->xy_to_n($x,$y));
}

# not exact
sub rect_to_n_range {
  my ($self, $x1,$y1, $x2,$y2) = @_;

  # my $xmax = int(max(abs($x1),abs($x2))) + 1;
  # my $ymax = int(max(abs($y1),abs($y2))) + 1;
  # return (0,
  #         ($xmax*$xmax + 3*$ymax*$ymax)
  #         * 1
  #         * $self->{'arms'});

  $x1 = round_nearest ($x1);
  $y1 = round_nearest ($y1);
  $x2 = round_nearest ($x2);
  $y2 = round_nearest ($y2);

  ($x1,$x2) = ($x2,$x1) if $x1 > $x2;
  ($y1,$y2) = ($y2,$y1) if $y1 > $y2;

  # FIXME: How much wider ?
  # Might matter when TerdragonCurve becomes exact.
  $x1 = int($x1/3) - 2;
  $y1 = int($y1/3) - 2;
  $x2 = int($x2/3) + 2;
  $y2 = int($y2/3) + 2;

  my ($n_lo, $n_hi) = $self->Math::PlanePath::TerdragonCurve::rect_to_n_range
    ($x1,$y1, $x2,$y2);
  if ($n_hi >= $n_hi) {
    $n_lo *= 2;
    $n_hi = 2*$n_hi + 1;
  }
  return ($n_lo, $n_hi);
}


#-----------------------------------------------------------------------------
# level_to_n_range()

# like TerdragonMidpoint but 2* points on each arm, numbered starting 0
#
sub level_to_n_range {
  my ($self, $level) = @_;
  return (0, (2*$self->{'arms'}) * 3**$level - 1);
}
sub n_to_level {
  my ($self, $n) = @_;
  if ($n < 0) { return undef; }
  if (is_infinite($n)) { return $n; }
  $n = round_nearest($n);
  _divrem_mutate ($n, 2 * $self->{'arms'});
  my ($pow, $exp) = round_up_pow ($n+1, 3);
  return $exp;
}

#-----------------------------------------------------------------------------
1;
__END__

=for stopwords Guiseppe Terdragon terdragon eg Sur une courbe qui remplit toute aire Mathematische Annalen Ryde OEIS ie Math-PlanePath versa Online Radix radix Jorg Arndt Hexdragon hexdragon

=head1 NAME

Math::PlanePath::TerdragonRounded -- triangular dragon curve, with rounded corners

=head1 SYNOPSIS

 use Math::PlanePath::TerdragonRounded;
 my $path = Math::PlanePath::TerdragonRounded->new;
 my ($x, $y) = $path->n_to_xy (123);

 # or another radix digits ...
 my $path5 = Math::PlanePath::TerdragonRounded->new (radix => 5);

=head1 DESCRIPTION

This is a version of the terdragon curve with rounded-off corners,

=cut

# math-image --path=TerdragonRounded --all --output=numbers_dash --size=132x70

=pod

    ...         44----43                                   14
      \        /        \
       46----45     .    42                                13
                        /
           .    40----41                                   12
               /
             39     .    24----23          20----19        11
               \        /        \        /        \
           .    38    25     .    22----21     .    18     10
               /        \                          /
       36----37     .    26----27     .    16----17         9
      /                          \        /
    35     .    32----31     .    28    15     .            8
      \        /        \        /        \
       34----33          30----29     .    14               7
                                          /
                             .    12----13     .            6
                                 /
                               11     .     8-----7         5
                                 \        /        \
                                  10-----9     .     6      4
                                                   /
                                      .     4-----5         3
                                          /
                                         3                  2
                                          \
                                      .     2               1
                                          /
                             .     0-----1     .       <- Y=0

     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8

The plain C<TerdragonCurve> is tripled in size and two points on each 3-long
edge are visited by the C<TerdragonRounded> here.

=head2 Arms

Multiple copies of the curve can be selected, each advancing successively.
The curve is 1/6 of the plane (like the plain terdragon) and 6 arms rotated
by 60, 120, 180, 240 and 300 degrees mesh together perfectly.

C<arms =E<gt> 6> begins as follows.  N=0,6,12,18,etc is the first arm (the
curve shown above), then N=1,7,13,19 the second copy rotated 60 degrees,
N=2,8,14,20 the third rotated 120, etc.

=cut

# math-image --path=TerdragonRounded,arms=6 --all --output=numbers_dash --size=80x30

=pod

    arms=>6              43----37          72--...
                        /        \        /
               ...    49          31    66          48----42
               /        \        /        \        /        \
             73          55    25          60----54          36
               \        /        \                          /
                67----61          19----13          24----30
                                          \        /
       38----32          14-----8           7    18          71---...
      /        \        /        \        /        \        /
    44          26----20           2     1          12    65
      \                                            /        \
       50----56           9-----3     .     0-----6          59----53
               \        /                                            \
    ...         62    15           4     5          23----29          47
      \        /        \        /        \        /        \        /
       74----68          21    10          11----17          35----41
                        /        \
                33----27          16----22          64----70
               /                          \        /        \
             39          57----63          28    58          76
               \        /        \        /        \        /
                45----51          69    34          52    ...
                                 /        \        /
                          ...--75          40----46

     ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^
    -11-10-9 -8 -7 -6 -5 -4 -3 -2 -1 X=0 1  2  3  4  5  6  7  8  9 10 11

=head1 FUNCTIONS

See L<Math::PlanePath/FUNCTIONS> for the behaviour common to all path
classes.

=over 4

=item C<$path = Math::PlanePath::TerdragonRounded-E<gt>new ()>

=item C<$path = Math::PlanePath::TerdragonRounded-E<gt>new (arms =E<gt> $count)>

Create and return a new path object.

=item C<($x,$y) = $path-E<gt>n_to_xy ($n)>

Return the X,Y coordinates of point number C<$n> on the path.  Points begin
at 0 and if C<$n E<lt> 0> then the return is an empty list.

Fractional positions give an X,Y position along a straight line between the
integer positions.

=back

=head2 Level Methods

=over

=item C<($n_lo, $n_hi) = $path-E<gt>level_to_n_range($level)>

Return C<(0, 2 * 3**$level - 1)>, or for multiple arms return C<(0, 2 *
$arms * 3**$level - 1)>.

These level ranges are like C<TerdragonMidpoint> but with 2 points on each
line segment terdragon line segment instead of 1.

=back

=head1 FORMULAS

=head2 X,Y Visited

When arms=6 all "hex centred" points of the plane are visited, being those
points with

    X+3Y mod 6 == 2 or 4        "hex_centred"

=head1 SEE ALSO

L<Math::PlanePath>,
L<Math::PlanePath::TerdragonCurve>,
L<Math::PlanePath::TerdragonMidpoint>,
L<Math::PlanePath::DragonRounded>

X<Arndt, Jorg>X<fxtbook>Jorg Arndt C<http://www.jjj.de/fxt/#fxtbook> section
1.31.4 "Terdragon and Hexdragon", where this rounded terdragon is called
hexdragon.

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-planepath/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

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
