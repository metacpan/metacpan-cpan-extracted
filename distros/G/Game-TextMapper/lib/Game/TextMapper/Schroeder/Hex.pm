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

=head1 DESCRIPTION

This role provides basic functionality for map generation with hex maps: the
number of neighbours within one or two regions distance, how to pick a random
neighbour direction, how to compute the coordinates of these neighbours, how to
draw arrows towards these neighbours.

=head1 SEE ALSO

L<Game::TextMapper::Schroeder::Base>
L<Game::TextMapper::Schroeder::Square>

=cut

package Game::TextMapper::Schroeder::Hex;
use Modern::Perl '2018';
use Mojo::Base -role;

sub neighbors { 0 .. 5 }

sub neighbors2 { 0 .. 11 }

sub random_neighbor { int(rand(6)) }

sub random_neighbor2 { int(rand(12)) }

my $delta_hex = [
  # x is even
  [[-1,  0], [ 0, -1], [+1,  0], [+1, +1], [ 0, +1], [-1, +1]],
  # x is odd
  [[-1, -1], [ 0, -1], [+1, -1], [+1,  0], [ 0, +1], [-1,  0]]];

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

sub neighbor2 {
  my $self = shift;
  # $hex is [x,y] or "0x0y" and $i is a number 0 .. 11
  my ($hex, $i) = @_;
  die join(":", caller) . ": undefined direction for $hex\n" unless defined $i;
  $hex = [$self->xy($hex)] unless ref $hex;
  return ($hex->[0] + $delta_hex2->[$hex->[0] % 2]->[$i]->[0],
	  $hex->[1] + $delta_hex2->[$hex->[0] % 2]->[$i]->[1]);
}

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

sub arrows {
  my $self = shift;
  return
      qq{<marker id="arrow" markerWidth="6" markerHeight="6" refX="6" refY="3" orient="auto"><path d="M6,0 V6 L0,3 Z" style="fill: black;" /></marker>},
      map {
	my $angle = 60 * $_;
	qq{<path id="arrow$_" transform="rotate($angle)" d="M-11.5,-5.8 L11.5,5.8" style="stroke: black; stroke-width: 3px; fill: none; marker-start: url(#arrow);"/>},
  } ($self->neighbors());
}

1;
