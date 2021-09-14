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

=head1 DESCRIPTION

Map generators that work for both hex maps and square maps use this role and
either the Hex or Square role to provide basic functionality for their regions,
such as the number of neighbours they have (six or four).

=head1 SEE ALSO

L<Game::TextMapper::Schroeder::Hex>
L<Game::TextMapper::Schroeder::Square>

=cut

package Game::TextMapper::Schroeder::Base;
use Game::TextMapper::Point;
use Modern::Perl '2018';
use Mojo::Base -role;

# We're assuming that $width and $height have two digits (10 <= n <= 99).

has width => 30;
has height => 10;

sub xy {
  my $self = shift;
  my $coordinates = shift;
  return (substr($coordinates, 0, 2), substr($coordinates, 2));
}

sub coordinates {
  my ($x, $y) = @_;
  return Game::TextMapper::Point::coord($x, $y);
}

sub legal {
  my $self = shift;
  my ($x, $y) = @_;
  ($x, $y) = $self->xy($x) if not defined $y;
  return @_ if $x > 0 and $x <= $self->width and $y > 0 and $y <= $self->height;
}


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

sub flat {
  my $self = shift;
  # initialize the altitude map; this is required so that we have a list of
  # legal hex coordinates somewhere
  my ($altitude) = @_;
  for my $y (1 .. $self->height) {
    for my $x (1 .. $self->width) {
      my $coordinates = coordinates($x, $y);
      $altitude->{$coordinates} = 0;
    }
  }
}

sub direction {
  my $self = shift;
  my ($from, $to) = @_;
  for my $i ($self->neighbors()) {
    return $i if $to eq coordinates($self->neighbor($from, $i));
  }
}

1;
