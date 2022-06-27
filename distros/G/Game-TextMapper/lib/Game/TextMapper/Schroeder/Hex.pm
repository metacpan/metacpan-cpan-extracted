# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::TextMapper::Schroeder::Hex - a role for hex map generators

=head1 SYNOPSIS

    # create a map
    package World;
    use Modern::Perl;
    use Mojo::Base -base;
    use Role::Tiny::With;
    with 'Game::TextMapper::Schroeder::Base';
    with 'Game::TextMapper::Schroeder::Hex';
    # use it
    package main;
    my $map = World->new(height => 10, width => 10);

=head1 DESCRIPTION

This role provides basic functionality for map generation with hex maps: the
number of neighbours within one or two regions distance, how to pick a random
neighbour direction, how to compute the coordinates of these neighbours, how to
draw arrows towards these neighbours.

This inherits attributes and methods from L<Game::TextMapper::Schroeder::Base>,
such as C<width> and C<height>.

=cut

package Game::TextMapper::Schroeder::Hex;
use Modern::Perl '2018';
use Mojo::Base -role;
use POSIX qw(ceil);

=head1 METHODS

=head2 reverse

Reverses a direction.

=cut

sub reverse {
  my ($self, $i) = @_;
  return ($i + 3) % 6;
}

=head2 neighbors

The list of directions for neighbours one step away (0 to 5).

=cut

sub neighbors { 0 .. 5 }

=head2 neighbors2

The list of directions for neighbours two steps away (0 to 11).

=cut

sub neighbors2 { 0 .. 11 }

=head2 random_neighbor

A random direction for a neighbour one step away (a random integer from 0 to 5).

=cut

sub random_neighbor { int(rand(6)) }

=head2 random_neighbor2

A random direction for a neighbour two steps away (a random integer from 0 to
11).

=cut

sub random_neighbor2 { int(rand(12)) }

my $delta_hex = [
  # x is even
  [[-1,  0], [ 0, -1], [+1,  0], [+1, +1], [ 0, +1], [-1, +1]],
  # x is odd
  [[-1, -1], [ 0, -1], [+1, -1], [+1,  0], [ 0, +1], [-1,  0]]];

=head2 neighbor($hex, $i)

    say join(",", $map->neighbor("0203", 1));
    # 2,2

Returns the coordinates of a neighbor in a particular direction (0 to 5), one
step away.

C<$hex> is an array reference of coordinates or a string that can be turned into
one using the C<xy> method from L<Game::TextMapper::Schroeder::Base>.

C<$i> is a direction (0 to 5).

=cut

sub neighbor {
  my $self = shift;
  # $hex is [x,y] or "0x0y" and $i is a number 0 .. 5
  my ($hex, $i) = @_;
  die join(":", caller) . ": undefined direction for $hex\n" unless defined $i;
  $hex = [$self->xy($hex)] unless ref $hex;
  return ($hex->[0] + $delta_hex->[$hex->[0] % 2]->[$i]->[0],
	  $hex->[1] + $delta_hex->[$hex->[0] % 2]->[$i]->[1]);
}

my $delta_hex2 = [
  # x is even
  [[-2, +1], [-2,  0], [-2, -1], [-1, -1], [ 0, -2], [+1, -1],
   [+2, -1], [+2,  0], [+2, +1], [+1, +2], [ 0, +2], [-1, +2]],
  # x is odd
  [[-2, +1], [-2,  0], [-2, -1], [-1, -2], [ 0, -2], [+1, -2],
   [+2, -1], [+2,  0], [+2, +1], [+1, +1], [ 0, +2], [-1, +1]]];

=head2 neighbor2($hex, $i)

    say join(",", $map->neighbor2("0203", 1));
    # 0, 3

Returns the coordinates of a neighbor in a particular direction (0 to 11), two
steps away.

C<$hex> is an array reference of coordinates or a string that can be turned into
one using the C<xy> method from L<Game::TextMapper::Schroeder::Base>.

C<$i> is a direction (0 to 5).

=cut

sub neighbor2 {
  my $self = shift;
  # $hex is [x,y] or "0x0y" and $i is a number 0 .. 11
  my ($hex, $i) = @_;
  die join(":", caller) . ": undefined direction for $hex\n" unless defined $i;
  $hex = [$self->xy($hex)] unless ref $hex;
  return ($hex->[0] + $delta_hex2->[$hex->[0] % 2]->[$i]->[0],
	  $hex->[1] + $delta_hex2->[$hex->[0] % 2]->[$i]->[1]);
}

=head2 distance($x1, $y1, $x2, $y2) or distance($coords1, $coords2)

    say $map->distance("0203", "0003");
    # 2

Returns the distance between two coordinates.

=cut

sub distance {
  my $self = shift;
  my ($x1, $y1, $x2, $y2) = @_;
  if (@_ == 2) {
    ($x1, $y1, $x2, $y2) = map { $self->xy($_) } @_;
  }
  # transform the coordinate system into a decent system with one axis tilted by
  # 60°
  $y1 = $y1 - POSIX::ceil($x1/2);
  $y2 = $y2 - POSIX::ceil($x2/2);
  if ($x1 > $x2) {
    # only consider moves from left to right and transpose start and
    # end point to make it so
    my ($t1, $t2) = ($x1, $y1);
    ($x1, $y1) = ($x2, $y2);
    ($x2, $y2) = ($t1, $t2);
  }
  if ($y2>=$y1) {
    # if it the move has a downwards component add Δx and Δy
    return $x2-$x1 + $y2-$y1;
  } else {
    # else just take the larger of Δx and Δy
    return $x2-$x1 > $y1-$y2 ? $x2-$x1 : $y1-$y2;
  }
}

=head2 arrows

A helper that returns the SVG fragments for arrows in six directions, to be used
in a C<defs> element.

=cut

sub arrows {
  my $self = shift;
  return
      qq{<marker id="arrow" markerWidth="6" markerHeight="6" refX="6" refY="3" orient="auto"><path d="M6,0 V6 L0,3 Z" style="fill: black;" /></marker>},
      qq{<marker id="wind" markerWidth="6" markerHeight="6" refX="6" refY="3" orient="auto"><path d="M6,0 V6 L0,3 Z" style="fill: purple;" /></marker>},
      map {
	my $angle = 60 * $_;
	qq{<path id="arrow$_" transform="rotate($angle)" d="M-11.5,-5.8 L11.5,5.8" style="stroke: black; stroke-width: 3px; fill: none; marker-start: url(#arrow);"/>},
	qq{<path id="wind$_" transform="translate(40,40) rotate($angle)" d="M-11.5,-5.8 L11.5,5.8" style="stroke: purple; stroke-width: 3px; fill: none; marker-start: url(#wind);"/>},
  } ($self->neighbors());
}

=head1 SEE ALSO

L<Game::TextMapper::Schroeder::Base>
L<Game::TextMapper::Schroeder::Square>

=cut

1;
