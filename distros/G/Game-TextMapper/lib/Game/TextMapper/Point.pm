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

Game::TextMapper::Point - a point on the map

=head1 DESCRIPTION

This is a simple class to hold points. Points have coordinates and know how to
print them.

=cut

package Game::TextMapper::Point;
use Modern::Perl '2018';
use Mojo::Base -base;

=head2 Attributes

C<x>, C<y>, C<z> are coordinates.

C<type>, C<label>, C<size> are used to draw the SVG. These are used by the
actual implementations, L<Game::TextMapper::Point::Hex> and
L<Game::TextMapper::Point::Square>.

C<map> is a reference to L<Game::TextMapper::Mapper> from which to get
C<text_attributes> (for the coordinates), and both C<label_attributes> and
C<glow_attributes> (for the label).

=cut

has 'x';
has 'y';
has 'z';
has 'type';
has 'label';
has 'size';
has 'map';

=head2 Methods

=head3 str

Returns "(1,2,3)" or "(1,2)" depending on whether the z coordinate is defined or
not; use this for log output.

=cut

sub str {
  my $self = shift;
  if (defined $self->z) {
    return '(' . $self->x . ',' . $self->y . ',' . $self->z . ')';
  } else {
    return '(' . $self->x . ',' . $self->y . ')';
  }
}

=head3 equal($other)

True if all three coordinates match.

=cut

sub equal {
  my ($self, $other) = @_;
  return $self->x == $other->x && $self->y == $other->y && $self->z == $other->z;
}

=head3 cmp($other)

Return -1, 0, or 1 depending on the three coordinates.

=cut

sub cmp {
  my ($a, $b) = @_;
  return $a->x <=> $b->x || $a->y <=> $b->y || $a->z <=> $b->z;
}

=head3 coordinates

Return "1,1,1" or "1,1" for coordinates in scalar context, depending on whether
the z coordinate is defined or not, or it returns the three coordinates in list
context.

=cut

sub coordinates {
  my ($self) = @_;
  return $self->x, $self->y, $self->z if wantarray;
  return $self->x . "," . $self->y . "," . $self->z if defined $self->z;
  return $self->x . "," . $self->y;
}

=head3 coord($x, $y, $separator)

Return "0101" or "-01-01" for coordinates. Often this what we want in text.

=cut

sub coord {
  my ($x, $y, $separator) = @_;
  $separator //= "";
  # print (1,1) as 0101; print (-1,-1) as -01-01
  return sprintf("%0*d$separator%0*d",
		 ($x < 0 ? 3 : 2), $x,
		 ($y < 0 ? 3 : 2), $y);
}

=head2 Abstract methods

These methods must be implemented by derived classes. The $offset argument is an
array with the offsets to add to the C<y> based on C<z> coordinate. The idea is
that if we have two dungeon levels, for example, and we want to generate a
single SVG document, then the first level is at the top of the page, as usual,
and the next level is further down on the page: all the C<y> coordinates were
increased by the offset.

=head3 svg_region($attributes, $offset)

This returns an SVG fragment, a string with a C<polygon> or C<rect> element, for
example.

This is used for the group containing the regions in the resulting SVG.

=head3 svg($offset)

This returns an SVG fragment, a string with a C<use> element.

This is used for the group containing the background colours in the resulting
SVG.

=head3 svg_coordinates($offset)

This returns an SVG fragment, a string with a C<text> element.

This is used for the group containing the coordinates in the resulting SVG.

=head3 svg_label($url, $offset)

This returns an SVG fragment, a string with a C<g> element containing two
C<text> elements, and possibly an C<a> element: the "glow", the label itself,
and possibly a link to the URL.

This is used for C<g#labels> (the group containing the labels) in the resulting
SVG.

=head1 SEE ALSO

L<Game::TextMapper::Mapper> uses this class. Internally, it calls C<make_region>
which is implemented by either L<Game::TextMapper::Mapper::Hex> or
L<Game::TextMapper::Mapper::Square>. Depending on the implementation,
L<Game::TextMapper::Point::Hex> or L<Game::TextMapper::Point::Square> are used
to implement this class.

=cut

1;
