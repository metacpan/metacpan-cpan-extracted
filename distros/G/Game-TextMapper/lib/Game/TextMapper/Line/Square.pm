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

Game::TextMapper::Line::Square - a line implementation for square maps

=head1 DESCRIPTION

The line connects two points on a square map. This class knows how to compute
all the regions between these two points, how to compute the next region along
the line, and how to output SVG.

=head1 SEE ALSO

L<Game::TextMapper::Point>
L<Game::TextMapper::Line::Line>
L<Game::TextMapper::Line::Hex>

=cut

package Game::TextMapper::Line::Square;

use Game::TextMapper::Constants qw($dx $dy);
use Game::TextMapper::Point;

use Modern::Perl '2018';
use Mojo::Base 'Game::TextMapper::Line';

sub pixels {
  my ($self, $point) = @_;
  my ($x, $y) = ($point->x * $dy, ($point->y + $self->offset->[$point->z]) * $dy);
  return ($x, $y) if wantarray;
  return sprintf("%d,%d", $x, $y);
}

sub one_step {
  my ($self, $from, $to) = @_;
  my ($min, $best);
  my $dx = $to->x - $from->x;
  my $dy = $to->y - $from->y;
  if (abs($dx) >= abs($dy)) {
    my $x = $from->x + ($dx > 0 ? 1 : -1);
    return Game::TextMapper::Point->new(x => $x, y => $from->y, z => $from->z);
  } else {
    my $y = $from->y + ($dy > 0 ? 1 : -1);
    return Game::TextMapper::Point->new(x => $from->x, y => $y, z => $from->z);
  }
}

1;
