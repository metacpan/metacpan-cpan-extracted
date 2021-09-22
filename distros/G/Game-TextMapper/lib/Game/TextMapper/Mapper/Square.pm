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

Game::TextMapper::Mapper::Hex - a mapper for hex maps

=head1 DESCRIPTION

This class knows how to parse a text containing a square map description into
SVG definitions, and regions. Once the map is built, this class knows how to
generate the SVG for the entire map.

=head1 SEE ALSO

This class is derived from L<Game::TextMapper::Mapper>.

It uses L<Game::TextMapper::Point::Square> to represent points (regions) and
L<Game::TextMapper::Line::Square> to represent lines.

L<Game::TextMapper::Mapper::Hex> is a similar class for hex maps.

=cut

package Game::TextMapper::Mapper::Square;

use Game::TextMapper::Constants qw($dy);
use Game::TextMapper::Point::Square;
use Game::TextMapper::Line::Square;

use Modern::Perl '2018';
use Mojo::Base 'Game::TextMapper::Mapper';

sub make_region {
  my $self = shift;
  return Game::TextMapper::Point::Square->new(@_);
}

sub make_line {
  my $self = shift;
  return Game::TextMapper::Line::Square->new(@_);
}

sub shape {
  my $self = shift;
  my $attributes = shift;
  return sprintf('<rect %s x="%.1f" y="%.1f" width="%.1f" height="%.1f" />',
		 $attributes, -$dy/2, -$dy/2, $dy, $dy);
}

sub viewbox {
  my $self = shift;
  my ($minx, $miny, $maxx, $maxy) = @_;
  map { int($_) } (($minx - 1) * $dy, ($miny - 1) * $dy,
		   ($maxx + 1) * $dy, ($maxy + 1) * $dy);
}

1;
