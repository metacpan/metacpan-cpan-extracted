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

Game::TextMapper::Schroeder::Island - generate an island chain

=head1 DESCRIPTION

This creates an island chain in an ocean, based on the idea of a hotspot moving
across the map. All regions atop the hotspot get raised at random; all regions
outside the hotspot are eroded at random. This leaves a chain of ever smaller
islands behind.

The rest of the code, river formation and all that, is based on the Alpine
algorithm and therefore it also requires the use of roles.

    return Game::TextMapper::Schroeder::Island
	->with_roles('Game::TextMapper::Schroeder::Square')->new()
	->generate_map(@params);

=head1 SEE ALSO

L<Game::TextMapper::Schroeder::Alpine>
L<Game::TextMapper::Schroeder::Base>
L<Game::TextMapper::Schroeder::Hex>
L<Game::TextMapper::Schroeder::Square>

=cut

package Game::TextMapper::Schroeder::Island;
use Game::TextMapper::Log;
use Modern::Perl '2018';
use Mojo::Base 'Game::TextMapper::Schroeder::Alpine';
use Role::Tiny::With;
with 'Game::TextMapper::Schroeder::Base';
use List::Util qw'shuffle min max';

my $log = Game::TextMapper::Log->get;

has 'bottom' => 0;
has 'top' => 10;
has 'radius' => 5;
has 'hotspot';

sub ocean {
  my $self = shift;
  my ($world, $altitude) = @_;
  for my $coordinates (sort keys %$altitude) {
    if ($altitude->{$coordinates} <= $self->bottom) {
      my $ocean = 1;
      for my $i ($self->neighbors()) {
	my ($x, $y) = $self->neighbor($coordinates, $i);
	my $legal = $self->legal($x, $y);
	my $other = coordinates($x, $y);
	next if not $legal or $altitude->{$other} <= $self->bottom;
	$ocean = 0;
      }
      $world->{$coordinates} = $ocean ? "ocean" : "water";
    }
  }
}

sub change {
  my $self = shift;
  return if $self->hotspot->[0] > $self->width - 2 * $self->radius;
  my $world = shift;
  my $altitude = shift;
  # advance hotspot
  if (rand() < 0.2) {
    $self->hotspot->[0] += 1.5 * $self->radius;
  } else {
    $self->hotspot->[0]++;
  }
  if (rand() < 0.5) {
    if (rand() > $self->hotspot->[1] / $self->height) {
      $self->hotspot->[1]++;
    } else {
      $self->hotspot->[1]--;
    }
  }
  # figure out who goes up and who goes down, if the hotspot is active
  my %hot;
  for my $x (max(1, $self->hotspot->[0] - $self->radius) .. min($self->width, $self->hotspot->[0] + $self->radius)) {
    for my $y (max(1, $self->hotspot->[1] - $self->radius) .. min($self->height, $self->hotspot->[1] + $self->radius)) {
      if ($self->distance($x, $y, @{$self->hotspot}) <= $self->radius) {
	my $coordinates = coordinates($x, $y);
	$hot{$coordinates} = 1;
      }
    }
  }
  # change the land
  for my $coordinates (keys %$altitude) {
    my $change = 0;
    if ($hot{$coordinates}) {
      # on the hotspot the land rises
      $change = 1 if rand() < 0.2;
    } else {
      # off the hotspot the land sinks
      $change = -1 if rand() < 0.2;
    }
    next unless $change;
    # rising from the ocean atop the hotspot
    $altitude->{$coordinates} += $change;
    $altitude->{$coordinates} = $self->bottom if $altitude->{$coordinates} < $self->bottom;
    $altitude->{$coordinates} = $self->top if $altitude->{$coordinates} > $self->top;
  }
  # land with higher neighbours on the hotspot goes up
  for my $coordinates (keys %hot) {
    my $change = 0;
    for my $i ($self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      $change = 1 if $altitude->{$other} - $altitude->{$coordinates} > 1;
      last;
    }
    $altitude->{$coordinates}++ if $change;
  }
  # note height for debugging purposes
  for my $coordinates (keys %$altitude) {
    $world->{$coordinates} = "height$altitude->{$coordinates}";
  }
}

sub forests {
  my $self = shift;
  my ($world, $altitude) = @_;
  # higher up is forests
  for my $coordinates (keys %$altitude) {
    next unless $altitude->{$coordinates}; # skip ocean
    next if $world->{$coordinates} =~ /mountain|lake/;
    if ($altitude->{$coordinates} == 1) {
      $world->{$coordinates} = "light-grey bushes";
    } elsif ($altitude->{$coordinates} == 2) {
      $world->{$coordinates} = "light-green trees";
    } elsif ($altitude->{$coordinates} == 3) {
      $world->{$coordinates} = "green forest";
    } elsif ($altitude->{$coordinates} == 4) {
      $world->{$coordinates} = "dark-green forest";
    } elsif ($altitude->{$coordinates} > 4) {
      $world->{$coordinates} = "dark-green mountains";
    }
  }
}

sub lakes {
  my $self = shift;
  my ($world, $altitude) = @_;
  # any areas surrounded by higher land is a lake
 HEX:
  for my $coordinates (sort keys %$altitude) {
    for my $i ($self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      next HEX if $altitude->{$other} == 0;
      next HEX if $altitude->{$coordinates} > $altitude->{$other};
    }
    $world->{$coordinates} = "green lake";
  }
}

sub islands {
  my $self = shift;
  my ($world, $altitude) = @_;
  # any areas surrounded by water is an island
 HEX:
  for my $coordinates (sort keys %$altitude) {
    next if $altitude->{$coordinates} == 0;
    for my $i ($self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      next HEX if $altitude->{$other} > 0;
    }
    $world->{$coordinates} = "water mountains";
  }
}

sub generate {
  my $self = shift;
  my ($world, $altitude, $settlements, $trails, $step) = @_;
  # %flow indicates that there is actually a river in this hex
  my $flow = {};

  $self->hotspot([int($self->radius / 2), int($self->height / 3 + rand() * $self->height / 3)]);

  my @code = (sub { $self->flat($altitude) });
  for (1 .. $self->width - 2 * $self->radius) {
    push(@code, sub { $self->change($world, $altitude) });
  }
  push(@code, sub { $self->ocean($world, $altitude) });

  push(@code,
    sub { $self->lakes($world, $altitude); },
    sub { $self->islands($world, $altitude); },
    sub { $self->forests($world, $altitude); },
    sub { push(@$settlements, $self->settlements($world, $flow)); },
    sub { push(@$trails, $self->trails($altitude, $settlements)); },
      );

  # $step 0 runs all the code; note that we can't simply cache those results
  # because we need to start over with the same seed!
  my $i = 1;
  while (@code) {
    shift(@code)->();
    return if $step == $i++;
  }
}

sub generate_map {
  my $self = shift;
  # The parameters turn into class variables.
  $self->width(shift // 40);
  $self->height(shift // 15);
  $self->radius(shift // 4);
  my $seed = shift||time;
  my $url = shift;
  my $step = shift||0;

  # For documentation purposes, I want to be able to set the pseudo-random
  # number seed using srand and rely on rand to reproduce the same sequence of
  # pseudo-random numbers for the same seed. The key point to remember is that
  # the keys function will return keys in random order. So if we look over the
  # result of keys, we need to look at the code in the loop: If order is
  # important, that wont do. We need to sort the keys. If we want the keys to be
  # pseudo-shuffled, use shuffle sort keys.
  srand($seed);

  # keys for all hashes are coordinates such as "0101".
  # %world is the description with values such as "green forest".
  # %altitude is the altitude with values such as 3.
  # @settlements are are the locations of settlements such as "0101"
  # @trails are the trails connecting these with values as "0102-0202"
  # $step is how far we want map generation to go where 0 means all the way
  my ($world, $altitude, $settlements, $trails) =
      ({}, {}, [], []);
  $self->generate($world, $altitude, $settlements, $trails, $step);

  # when documenting or debugging, do this before collecting lines
  if ($step > 0) {
    # add a height label at the very end
    if ($step) {
      for my $coordinates (keys %$world) {
	$world->{$coordinates} .= ' "' . $altitude->{$coordinates} . '"';
      }
    }
  }

  local $" = "-"; # list items separated by -
  my @lines;
  push(@lines, map { $_ . " " . $world->{$_} } sort keys %$world);
  push(@lines, map { "$_ trail" } @$trails);
  push(@lines, "include gnomeyland.txt");

  # when documenting or debugging, add some more lines at the end
  if ($step > 0) {
    # visualize height
    push(@lines,
	 map {
	   my $n = int(25.5 * $_);
	   qq{height$_ attributes fill="rgb($n,$n,$n)"};
	 } (0 .. 10));
    # visualize water flow
    push(@lines, $self->arrows());
  }

  push(@lines, "# Seed: $seed");
  push(@lines, "# Documentation: " . $url) if $url;
  my $map = join("\n", @lines);
  return $map;
}

1;
