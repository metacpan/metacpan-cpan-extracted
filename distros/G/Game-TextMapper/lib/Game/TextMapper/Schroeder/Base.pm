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

Game::TextMapper::Schroeder::Base - a base role for map generators

=head1 SYNOPSIS

    # create a map
    package World;
    use Modern::Perl;
    use Game::TextMapper::Schroeder::Base;
    use Mojo::Base -base;
    use Role::Tiny::With;
    with 'Game::TextMapper::Schroeder::Base';
    # use it
    package main;
    my $map = World->new(height => 10, width => 10);

=head1 DESCRIPTION

Map generators that work for both hex maps and square maps use this role and
either the Hex or Square role to provide basic functionality for their regions,
such as the number of neighbours they have (six or four).

=cut

package Game::TextMapper::Schroeder::Base;
use Game::TextMapper::Point;
use Modern::Perl '2018';
use Mojo::Base -role;

# We're assuming that $width and $height have two digits (10 <= n <= 99).

has width => 30;
has height => 10;

sub coordinates {
  my ($x, $y) = @_;
  return Game::TextMapper::Point::coord($x, $y);
}

=head1 METHODS

=head2 xy($coordinates)

C<$coordinates> is a string with four digites and interpreted as coordinates and
returned, e.g. returns (2, 3) for "0203".

=cut

sub xy {
  my $self = shift;
  my $coordinates = shift;
  return (substr($coordinates, 0, 2), substr($coordinates, 2));
}

=head2 legal($x, $y) or $legal($coordinates)

    say "legal" if $map->legal(10,10);

Turn $coordinates into ($x, $y), assuming each to be two digits, i.e. "0203"
turns into (2, 3).

Return ($x, $y) if the coordinates are legal, i.e. on the map.

=cut

sub legal {
  my $self = shift;
  my ($x, $y) = @_;
  ($x, $y) = $self->xy($x) if not defined $y;
  return @_ if $x > 0 and $x <= $self->width and $y > 0 and $y <= $self->height;
}

=head2 remove_closer_than($limit, @coordinates)

Each element of @coordinates is a string with four digites and interpreted as
coordinates, e.g. "0203" is treated as (2, 3). Returns a list where each element
is no closer than $limit to any existing element.

This depends on L<Game::TextMapper::Schroeder::Base> being used as a role by a
class that implements C<distance>.

=cut

sub remove_closer_than {
  my $self = shift;
  my ($limit, @hexes) = @_;
  my @filtered;
 HEX:
  for my $hex (@hexes) {
    my ($x1, $y1) = $self->xy($hex);
    # check distances with all the hexes already in the list
    for my $existing (@filtered) {
      my ($x2, $y2) = $self->xy($existing);
      my $distance = $self->distance($x1, $y1, $x2, $y2);
      # warn "Distance between $x1$y1 and $x2$y2 is $distance\n";
      next HEX if $distance < $limit;
    }
    # if this hex wasn't skipped, it goes on to the list
    push(@filtered, $hex);
  }
  return @filtered;
}

=head2 flat($altitude)

    my $altitude = {};
    $map->flat($altitude);
    say $altitude->{"0203"};

Initialize the altitude map; this is required so that we have a list of legal
hex coordinates somewhere.

=cut

sub flat {
  my $self = shift;
  my ($altitude) = @_;
  for my $y (1 .. $self->height) {
    for my $x (1 .. $self->width) {
      my $coordinates = coordinates($x, $y);
      $altitude->{$coordinates} = 0;
    }
  }
}

=head2 direction($from, $to)

Return the direction (an integer) to step from C<$from> to reach C<$to>.

This depends on L<Game::TextMapper::Schroeder::Base> being used as a role by a
class that implements C<neighbors> and C<neighbor>.

=cut

sub direction {
  my $self = shift;
  my ($from, $to) = @_;
  for my $i ($self->neighbors()) {
    return $i if $to eq coordinates($self->neighbor($from, $i));
  }
}

=head1 SEE ALSO

L<Game::TextMapper::Schroeder::Hex> and L<Game::TextMapper::Schroeder::Square>
both use this class to provide common functionality.

=cut

1;
