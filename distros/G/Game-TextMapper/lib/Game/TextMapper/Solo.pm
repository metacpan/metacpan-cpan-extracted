# Copyright (C) 2024  Alex Schroeder <alex@gnu.org>
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

Game::TextMapper::Solo - generate a map generated step by step

=head1 SYNOPSIS

    use Modern::Perl;
    use Game::TextMapper::Solo;
    my $map = Game::TextMapper::Solo->new->generate_map();
    print $map;

=head1 DESCRIPTION

This starts the map and generates all the details directly, for each step,
without knowledge of the rest of the map. The tricky part is to generate
features such that no terrible geographical problems arise.

=cut

package Game::TextMapper::Solo;
use Game::TextMapper::Log;
use Modern::Perl '2018';
use List::Util qw(shuffle all any none);
use Mojo::Base -base;

my $log = Game::TextMapper::Log->get;

=head1 ATTRIBUTES

=head2 rows

The height of the map, defaults to 15.

    use Modern::Perl;
    use Game::TextMapper::Solo;
    my $map = Game::TextMapper::Solo->new(rows => 20)
        ->generate_map;
    print $map;

=head2 cols

The width of the map, defaults to 30.

    use Modern::Perl;
    use Game::TextMapper::Solo;
    my $map = Game::TextMapper::Solo->new(cols => 40)
        ->generate_map;
    print $map;

=cut

has 'rows' => 15;
has 'cols' => 30;
has 'altitudes' => sub{[]}; # these are the altitudes of each hex, a number between 0 (deep ocean) and 10 (ice)
has 'tiles' => sub{[]}; # these are the tiles on the map, an array of arrays of strings
has 'flows' => sub{[]}; # these are the water flow directions on the map, an array of coordinates
has 'rivers' => sub{[]}; # for rendering, the flows are turned into rivers, an array of arrays of coordinates
has 'trails' => sub{[]};
has 'loglevel';

my @tiles = qw(plain rough swamp desert forest hills green-hills forest-hill mountains mountain volcano ice water coastal ocean);
my @no_sources = qw(desert volcano water coastal ocean);
my @settlements = qw(house ruin tower ruined-tower castle ruined-castle);
my @ruins = qw(ruin ruined-tower ruined-castle);

=head1 METHODS

=head2 generate_map

This method takes no arguments. Set the properties of the map using the
attributes.

=cut

sub generate_map {
  my ($self) = @_;
  $log->level($self->loglevel) if $self->loglevel;
  $self->random_walk();
  # my $walks = $self->random_walk();
  # debug random walks
  # my @walks = @$walks;
  # @walks = @walks[0 .. 10];
  # $self->trails(\@walks);
  $self->add_rivers();
  return $self->to_text();
}

sub random_walk {
  my ($self) = @_;
  my %seen;
  my $tile_count = 0;
  my $path_length = 1;
  my $max_tiles = $self->rows * $self->cols;
  my $start = int($self->rows / 2) * $self->cols + int($self->cols / 2);
  $self->altitudes->[$start] = 5;
  my @neighbours = $self->neighbours($start);
  # initial river setup: roll a d6 four destination
  $self->flows->[$start] = $neighbours[int(rand(6))];
  # roll a d6 for source, skip if same as destination
  my $source = $neighbours[int(rand(6))];
  $self->flows->[$source] = $start unless $source == $self->flows->[$start];
  # initial setup: roll for starting region with a village
  $seen{$start} = 1;
  $self->random_tile($start, $start, 'house');
  push(@{$self->tiles->[$start]}, qq("$tile_count/$start")) if $log->level eq 'debug';
  $tile_count++;
  # roll for the immediate neighbours
  for my $to (@neighbours) {
    $seen{$to} = 1;
    $self->random_tile($start, $to);
    push(@{$self->tiles->[$to]}, qq("$tile_count/$to")) if $log->level eq 'debug';
    $tile_count++;
  }
  # remember those walks for debugging (assign to trails, for example)
  my $walks = [];
  # while there are still undiscovered hexes
  while ($tile_count < $max_tiles) {
    # create an expedition of length l
    my $from = $start;
    my $to = $start;
    my $walk = [];
    for (my $i = 0; $i < $path_length; $i++) {
      push(@$walk, $to);
      if (not $seen{$to}) {
        $seen{$to} = 1;
        $self->random_tile($from, $to);
        push(@{$self->tiles->[$to]}, qq("$tile_count/$to")) if $log->level eq 'debug';
        $tile_count++;
      }
      $from = $to;
      $to = $self->neighbour($from, \%seen);
    }
    $path_length++;
    push(@$walks, $walk);
    # last if @$walks > 10;
  }
  return $walks;
}

sub random_tile {
  my ($self, $from, $to, $settlement) = @_;
  my $roll = roll_2d6();
  my $altitude = $self->adjust_altitude($roll, $from, $to);
  # coastal water always has flow
  $self->add_flow($to, ($roll >= 5 and $roll <= 8 or $altitude == 1));
  my $wet = defined $self->flows->[$to];
  my $tile;
  if    ($altitude == 0) { $tile = 'ocean' }
  elsif ($altitude == 1) { $tile = 'coastal' }
  elsif ($altitude == 2) { $tile = $wet ? 'swamp' : 'desert' }
  elsif ($altitude == 3) { $tile = $wet ? 'swamp' : 'plain' }
  elsif ($altitude == 4) { $tile = $wet ? 'forest' : 'plain' }
  elsif ($altitude == 5) { $tile = $wet ? 'forest' : 'plain' }
  elsif ($altitude == 6) { $tile = $wet ? 'forest-hill' : 'rough' }
  elsif ($altitude == 7) { $tile = $wet ? 'green-hills' : 'hills' }
  elsif ($altitude == 8) { $tile = 'mountains' }
  elsif ($altitude == 9) { $tile = special() ? 'volcano' : 'mountain' }
  else                   { $tile = 'ice' }
  push(@{$self->tiles->[$to]}, $tile);
  if ($settlement) {
    push(@{$self->tiles->[$to]}, $settlement);
  } elsif ($roll == 7) {
    if ($tile eq 'forest' or $tile eq 'forest-hill') {
      push(@{$self->tiles->[$to]}, $settlements[int(rand($#settlements + 1))]);
    } elsif ($tile eq 'desert' or $tile eq 'swamp' or $tile eq 'green-hills') {
      push(@{$self->tiles->[$to]}, $ruins[int(rand($#ruins + 1))]);
    }
  }
  push(@{$self->tiles->[$to]}, qq("+$altitude")) if $log->level eq 'debug';
}

sub adjust_altitude {
  my ($self, $roll, $from, $to) = @_;
  my @neighbours = $self->neighbours($to);
  # ocean stays ocean
  if (all { defined $self->altitudes->[$_] and $self->altitudes->[$_] <= 1 } @neighbours) {
    return $self->altitudes->[$to] = 0;
  }
  my $altitude = $self->altitudes->[$from];
  my $max = 10;
  # if we're following a river, the altitude rarely goes up; neighbouring hexes
  # also limit the heigh changes
  for (@neighbours) {
    if (defined $self->flows->[$_]
        and $self->flows->[$_] == $to
        and defined $self->altitudes->[$_]
        and $self->altitudes->[$_] < $max) {
      $max = $self->altitudes->[$_];
    }
  }
  my $delta = 0;
  if    ($roll ==  2) { $delta = -2 }
  elsif ($roll ==  3) { $delta = -1 }
  elsif ($roll == 10) { $delta = +1 }
  elsif ($roll == 11) { $delta = +1 }
  elsif ($roll == 12) { $delta = +2 }
  $altitude += $delta;
  $altitude = $max if $altitude > $max;
  $altitude = 0 if $altitude < 0;
  $altitude = 1 if $altitude == 0 and any { defined $self->altitudes->[$_] and $self->altitudes->[$_] > 1  } @neighbours;
  return $self->altitudes->[$to] = $altitude;
}

sub add_flow {
  my ($self, $to, $source) = @_;
  my @neighbours = $self->neighbours($to);
  # don't do anything if there's already water flow
  return if defined $self->flows->[$to];
  # don't do anything if this is ocean
  return if defined $self->altitudes->[$to] and $self->altitudes->[$to] == 0;
  # if this hex can be a source or water from a neighbour flows into it
  if ($source and not $self->tiles->[$to] and $self->altitudes->[$to] >= 1 and $self->altitudes->[$to] <= 8
      or any { defined $self->flows->[$_] and $self->flows->[$_] == $to } @neighbours) {
    # prefer a lower neighbour (or an undefined one), but "lower" works only for
    # known hexes so there must already be water flow, there, and that water
    # flow must not be circular
    my @candidates = grep {
      not defined $self->altitudes->[$_]
          or $self->altitudes->[$_] < $self->altitudes->[$to]
          and $self->flowable($to, $_)
    } @neighbours;
    if (@candidates) {
      $self->flows->[$to] = $candidates[0];
      return;
    }
    # or if this hex is at the edge, prefer flowing off the edge of the map
    if (@neighbours < 6) {
      $self->flows->[$to] = -1;
      return;
    }
    # or prefer of equal altitude but again this works only for known hexes so
    # there must already be water flow, there, and that water flow must not be
    # circular
    @candidates = grep {
      $self->altitudes->[$_] == $self->altitudes->[$to]
          and $self->flowable($to, $_)
    } @neighbours;
    if (@candidates) {
      $self->flows->[$to] = $candidates[0];
      return;
    }
    # or it's magic!!
    @candidates = grep { $self->flowable($to, $_) } @neighbours;
    if (@candidates) {
      $log->info("Awkward transition at " . $self->xy($to));
      $self->flows->[$to] = $candidates[0];
      return;
    }
    # Or it's a dead end… and entrance into the underworld, obviously
    if ($self->altitudes->[$to] > 1) {
      push(@{$self->tiles->[$to]}, 'cave');
    }
  }
}

# A river can from A to B if B is undefined or if B has flow that doesn't return
# to A.
sub flowable {
  my ($self, $from, $to) = @_;
  my $flow = 0;
  while (defined $self->flows->[$to] and $self->flows->[$to] >= 0) {
    $to = $self->flows->[$to];
    return 0 if $to == $from;
    $flow = 1;
  }
  return $flow;
}

sub add_rivers {
  my ($self) = @_;
  my %seen;
  for my $coordinate (0 .. $self->rows * $self->cols - 1) {
    next unless defined $self->flows->[$coordinate];
    next if $self->altitudes->[$coordinate] <= 1; # do not show rivers starting here
    next if $seen{$coordinate};
    $seen{$coordinate} = 1;
    if (none {
      defined $self->flows->[$_]
          and $self->flows->[$_] == $coordinate
        } $self->neighbours($coordinate)) {
      my $river = [];
      while (defined $coordinate) {
        push(@$river, $coordinate);
        last if $coordinate == -1;
        $seen{$coordinate} = 1;
        $coordinate = $self->flows->[$coordinate];
      }
      push(@{$self->rivers}, $river);
    }
  }
}

sub special {
  return rand() < 1/6;
}

sub roll_2d6 {
  return 2 + int(rand(6)) + int(rand(6));
}

sub neighbour {
  my ($self, $coordinate, $seen) = @_;
  my @neighbours = $self->neighbours($coordinate);
  # If a seen hash reference is provided, prefer new hexes
  if ($seen) {
    my @candidates = grep {!($seen->{$_})} @neighbours;
    return $candidates[0] if @candidates;
  }
  return $neighbours[0];
}

# Returns the coordinates of neighbour regions, in random order, but only if on
# the map.
sub neighbours {
  my ($self, $coordinate) = @_;
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
  return map { $coordinate + $_ } shuffle grep {$_} @offsets;
}

# Return the direction of a neighbour given its coordinates. 0 is up (north), 1
# is north-east, 2 is south-east, 3 is south, 4 is south-west, 5 is north-west.
sub direction {
  my ($self, $from, $to) = @_;
  my @offsets;
  if ($from % 2) {
    @offsets = (-$self->cols, +1, $self->cols +1, $self->cols, $self->cols -1, -1);
  } else {
    @offsets = (-$self->cols, -$self->cols +1, +1, $self->cols, -1, -$self->cols -1);
  }
  for (my $i = 0; $i < 6; $i++) {
    return $i if $from + $offsets[$i] == $to;
  }
}

sub to_text {
  my ($self) = @_;
  my $text = "";
  for my $i (0 .. $self->rows * $self->cols - 1) {
    next unless $self->tiles->[$i];
    my @tiles = @{$self->tiles->[$i]};
    push(@tiles, "arrow" . $self->direction($i, $self->flows->[$i])) if defined $self->flows->[$i] and $log->level eq 'debug';
    $text .= $self->xy($i) . " @tiles\n";
  }
  for my $river (@{$self->rivers}) {
    $text .= $self->xy(@$river) . " river\n" if ref($river) and @$river > 1;
  }
  for my $trail (@{$self->trails}) {
    $text .= $self->xy(@$trail) . " trails\n" if ref($trail) and @$trail > 1;
    # More emphasis
    # $text .= $self->xy(@$trail) . " border\n" if ref($trail) and @$trail > 1;
  }
  # add arrows for the flow
  $text .= join("\n",
                qq{<marker id="arrow" markerWidth="6" markerHeight="6" refX="0" refY="3" orient="auto"><path d="M0,0 V6 L5,3 Z" style="fill: black;" /></marker>},
                map {
                  my $angle = 60 * $_;
                  qq{<path id="arrow$_" transform="rotate($angle)" d="M0,40 V-40" style="stroke: black; stroke-width: 3px; fill: none; marker-end: url(#arrow);"/>};
                } (0 .. 5));
  $text .= "\ninclude bright.txt\n";
  return $text;
}

sub xy {
  my ($self, @coordinates) = @_;
  for (my $i = 0; $i < @coordinates; $i++) {
    if ($coordinates[$i] == -1) {
      $coordinates[$i] = $self->edge($coordinates[$i - 1]);
    } else {
      $coordinates[$i] = sprintf("%02d%02d", $coordinates[$i] % $self->cols + 1, int($coordinates[$i] / $self->cols) + 1);
    }
  }
  return join("-", @coordinates);
}

sub edge {
  my ($self, $coordinate) = @_;
  my ($x, $y) = $coordinate =~ /(..)(..)/;
  if ($x == 1) {
    return "00" . $y;
  } elsif ($x == $self->cols) {
    return sprintf("%02d", $self->cols+1) . $y;
  } elsif ($y == 1) {
    return $x . "00";
  } elsif ($y == $self->rows) {
    return $x . sprintf("%02d", $self->rows+1);
  }

}

1;
