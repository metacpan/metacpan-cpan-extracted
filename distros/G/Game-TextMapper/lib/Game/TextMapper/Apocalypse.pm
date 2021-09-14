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

Game::TextMapper::Apocalypse - generate postapocalyptic landscape

=head1 DESCRIPTION

This fills the map with random seed regions which then grow to fill the map.

Settlements are placed at random.

Every mountain region is the source of a river. Rivers flow through regions that
are not themselves mountains or a deserts. Rivers end in swamps.

=head1 METHODS

=cut

package Game::TextMapper::Apocalypse;
use Game::TextMapper::Log;
use Modern::Perl '2018';
use List::Util qw(shuffle any none);
use Mojo::Base -base;

my $log = Game::TextMapper::Log->get;

has 'rows' => 10;
has 'cols' => 20;
has 'region_size' => 5;
has 'settlement_chance' => 0.1;

my @tiles = qw(forest desert mountain jungle swamp grass);
my @settlements = qw(ruin fort cave);

=head2 generate_map

This method takes no arguments. Maps are always 20×10; region always 5 hexes and
there is a 10% chance for settlements.

=cut

sub generate_map {
  my $self = shift;
  my @coordinates = shuffle(0 .. $self->rows * $self->cols - 1);
  my $seeds = $self->rows * $self->cols / $self->region_size;
  my $tiles = [];
  $tiles->[$_] = [$tiles[int(rand(@tiles))]] for splice(@coordinates, 0, $seeds);
  $tiles->[$_] = [$self->close_to($_, $tiles)] for @coordinates;
  # warn "$_\n" for $self->neighbours(0);
  # push(@{$tiles->[$_]}, "red") for map { $self->neighbours($_) } 70, 75;
  # push(@{$tiles->[$_]}, "red") for map { $self->neighbours($_) } 3, 8, 60, 120;
  # push(@{$tiles->[$_]}, "red") for map { $self->neighbours($_) } 187, 194, 39, 139;
  # push(@{$tiles->[$_]}, "red") for map { $self->neighbours($_) } 0, 19, 180, 199;
  # push(@{$tiles->[$_]}, "red") for map { $self->neighbours($_) } 161;
  for my $tile (@$tiles) {
    push(@$tile, $settlements[int(rand(@settlements))]) if rand() < $self->settlement_chance;
  }
  my $rivers = $self->rivers($tiles);
  return $self->to_text($tiles, $rivers);
}

sub neighbours {
  my $self = shift;
  my $coordinate = shift;
  my @offsets;
  if ($coordinate % 2) {
    @offsets = (-1, +1, $self->cols, -$self->cols, $self->cols -1, $self->cols +1);
    $offsets[3] = undef if $coordinate < $self->cols; # top edge
    $offsets[2] = $offsets[4] = $offsets[5] = undef if $coordinate >= ($self->rows - 1) * $self->cols; # bottom edge
    $offsets[0] = $offsets[4] = undef if $coordinate % $self->cols == 0; # left edge
    $offsets[1] = $offsets[5] = undef if $coordinate % $self->cols == $self->cols - 1; # right edge
  } else {
    @offsets = (-1, +1, $self->cols, -$self->cols, -$self->cols -1, -$self->cols +1);
    $offsets[3] = $offsets[4] = $offsets[5] = undef if $coordinate < $self->cols; # top edge
    $offsets[2] = undef if $coordinate >= ($self->rows - 1) * $self->cols; # bottom edge
    $offsets[0] = $offsets[4] = undef if $coordinate % $self->cols == 0; # left edge
    $offsets[1] = $offsets[5] = undef if $coordinate % $self->cols == $self->cols - 1; # right edge
  }
  # die "@offsets" if any { $coordinate + $_ < 0 or $coordinate + $_ >= $self->cols * $self->rows } @offsets;
  return map { $coordinate + $_ } shuffle grep {$_} @offsets;
}

sub close_to {
  my $self = shift;
  my $coordinate = shift;
  my $tiles = shift;
  for ($self->neighbours($coordinate)) {
    return $tiles->[$_]->[0] if $tiles->[$_];
  }
  return $tiles[int(rand(@tiles))];
}

sub rivers {
  my $self = shift;
  my $tiles = shift;
  # the array of rivers has a cell for each coordinate: if there are no rivers,
  # it is undef; else it is a reference to the river
  my $rivers = [];
  for my $source (grep { $self->is_source($_, $tiles) } 0 .. $self->rows * $self->cols - 1) {
    $log->debug("River starting at " . $self->xy($source) . " (@{$tiles->[$source]})");
    my $river = [$source];
    $self->grow_river($source, $river, $rivers, $tiles);
  }
  return $rivers;
}

sub grow_river {
  my $self = shift;
  my $coordinate = shift;
  my $river = shift;
  my $rivers = shift;
  my $tiles = shift;
  my @destinations = shuffle grep { $self->is_destination($_, $river, $rivers, $tiles) } $self->neighbours($coordinate);
  return unless @destinations; # this is a dead end
  for my $next (@destinations) {
    push(@$river, $next);
    $log->debug(" " . $self->xy($river));
    if ($rivers->[$next]) {
      $log->debug(" merge!");
      my @other = @{$rivers->[$next]};
      while ($other[0] != $next) { shift @other };
      shift @other; # get rid of the duplicate $next
      push(@$river, @other);
      return $self->mark_river($river, $rivers);
    } elsif ($self->is_sink($next, $tiles)) {
      $log->debug("  done!");
      return $self->mark_river($river, $rivers);
    } else {
      my $result = $self->grow_river($next, $river, $rivers, $tiles);
      return $result if $result;
      $log->debug("  dead end!");
      $rivers->[$next] = 0; # prevents this from being a destination
      pop(@$river);
    }
  }
  return; # all destinations were dead ends
}

sub mark_river {
  my $self = shift;
  my $river = shift;
  my $rivers = shift;
  for my $coordinate (@$river) {
    $rivers->[$coordinate] = $river;
  }
  return $river;
}

sub is_source {
  my $self = shift;
  my $coordinate = shift;
  my $tiles = shift;
  return any { $_ eq 'mountain' } (@{$tiles->[$coordinate]});
}

sub is_destination {
  my $self = shift;
  my $coordinate = shift;
  my $river = shift;
  my $rivers = shift;
  my $tiles = shift;
  return 0 if defined $rivers->[$coordinate] and $rivers->[$coordinate] == 0;
  return 0 if grep { $_ == $coordinate } @$river;
  return none { $_ eq 'mountain' or $_ eq 'desert' } (@{$tiles->[$coordinate]});
}

sub is_sink {
  my $self = shift;
  my $coordinate = shift;
  my $tiles = shift;
  return any { $_ eq 'swamp' } (@{$tiles->[$coordinate]});
}

sub to_text {
  my $self = shift;
  my $tiles = shift;
  my $rivers = shift;
  my $text = "";
  for my $i (0 .. $self->rows * $self->cols - 1) {
    $text .= $self->xy($i) . " @{$tiles->[$i]}\n" if $tiles->[$i];
  }
  for my $river (@$rivers) {
    $text .= $self->xy($river) . " river\n" if ref($river) and @$river > 1;
  }
  $text .= "\ninclude apocalypse.txt\n";
  return $text;
}

sub xy {
  my $self = shift;
  return join("-", map { sprintf("%02d%02d", $_ % $self->cols + 1, int($_ / $self->cols) + 1) } @_) if @_ > 1;
  return sprintf("%02d%02d", $_[0] % $self->cols + 1, int($_[0] / $self->cols) + 1) unless ref($_[0]);
  return join("-", map { sprintf("%02d%02d", $_ % $self->cols + 1, int($_ / $self->cols) + 1) } @{$_[0]});
}

1;
