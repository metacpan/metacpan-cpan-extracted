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

has 'x';
has 'y';
has 'z';

sub equal {
  my ($self, $other) = @_;
  return $self->x == $other->x && $self->y == $other->y;
}

sub cmp {
  my ($a, $b) = @_;
  return $a->x <=> $b->x || $a->y <=> $b->y;
}

sub coordinates {
  my ($self) = @_;
  return $self->x, $self->y if wantarray;
  return $self->x . "," . $self->y;
}

sub coord {
  my ($x, $y, $separator) = @_;
  $separator //= "";
  # print (1,1) as 0101; print (-1,-1) as -01-01
  return sprintf("%0*d$separator%0*d",
		 ($x < 0 ? 3 : 2), $x,
		 ($y < 0 ? 3 : 2), $y);
}

1;
