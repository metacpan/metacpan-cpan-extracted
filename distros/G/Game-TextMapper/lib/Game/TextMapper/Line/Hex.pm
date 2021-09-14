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

Game::TextMapper::Line::Hex - a line implementation for hex maps

=head1 DESCRIPTION

The line connects two points on a hex map. This class knows how to compute all
the regions between these two points, how to compute the next region along the
line, and how to output SVG.

=head1 SEE ALSO

L<Game::TextMapper::Point>
L<Game::TextMapper::Line::Line>
L<Game::TextMapper::Line::Square>

=cut

package Game::TextMapper::Line::Hex;

use Game::TextMapper::Constants qw($dx $dy);
use Game::TextMapper::Point;

use Modern::Perl '2018';
use Mojo::Base 'Game::TextMapper::Line';

sub pixels {
  my ($self, $point) = @_;
  my ($x, $y) = ($point->x * $dx * 3/2, ($point->y + $self->offset->[$point->z]) * $dy - $point->x % 2 * $dy/2);
  return ($x, $y) if wantarray;
  return sprintf("%.1f,%.1f", $x, $y);
}

# Brute forcing the "next" step by trying all the neighbors. The
# connection data to connect to neighboring hexes.
#
# Example Map             Index for the array
#
#      0201                      2
#  0102    0302               1     3
#      0202    0402
#  0103    0303               6     4
#      0203    0403              5
#  0104    0304
#
#  Note that the arithmetic changes when x is odd.

sub one_step {
  my ($self, $from, $to) = @_;
  my $delta = [[[-1,  0], [ 0, -1], [+1,  0], [+1, +1], [ 0, +1], [-1, +1]],  # x is even
	       [[-1, -1], [ 0, -1], [+1, -1], [+1,  0], [ 0, +1], [-1,  0]]]; # x is odd
  my ($min, $best);
  for my $i (0 .. 5) {
    # make a new guess
    my ($x, $y) = ($from->x + $delta->[$from->x % 2]->[$i]->[0],
		   $from->y + $delta->[$from->x % 2]->[$i]->[1]);
    my $d = ($to->x - $x) * ($to->x - $x)
          + ($to->y - $y) * ($to->y - $y);
    if (!defined($min) || $d < $min) {
      $min = $d;
      $best = Game::TextMapper::Point->new(x => $x, y => $y, z => $from->z);
    }
  }
  return $best;
}

1;
