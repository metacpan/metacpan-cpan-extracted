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

Game::TextMapper::Alpine - generate an alpine landscape

=head1 DESCRIPTION

This fills the map with some mountains and then traces the water flow down to
the sea and off the map. With water, forests grow; but if the area remains at
the same altitude, swamps form.

Settlements are placed at random in the habitable zones, but far enough from
each other, and connected by trails.

In order to support hex and square maps, this class uses roles to implement
coordinates, neighbours, and all that. This is why you need to specify the role
before creating an instance of this class:

    return Game::TextMapper::Schroeder::Alpine
	->with_roles('Game::TextMapper::Schroeder::Hex')->new()
	->generate_map(@params);

=head1 SEE ALSO

L<Game::TextMapper::Schroeder::Base>
L<Game::TextMapper::Schroeder::Hex>
L<Game::TextMapper::Schroeder::Square>

=cut

package Game::TextMapper::Schroeder::Alpine;
use Game::TextMapper::Log;
use Modern::Perl '2018';
use Mojo::Base -base;
use Role::Tiny::With;
with 'Game::TextMapper::Schroeder::Base';
use List::Util 'shuffle';

my $log = Game::TextMapper::Log->get;

has 'steepness';
has 'peaks';
has 'peak';
has 'bumps';
has 'bump';
has 'bottom';
has 'arid';
has 'wind';

sub place_peak {
  my $self = shift;
  my $altitude = shift;
  my $count = shift;
  my $current_altitude = shift;
  my @queue;
  # place some peaks and put them in a queue
  for (1 .. $count) {
    # try to find an empty hex
    for (1 .. 6) {
      my $x = int(rand($self->width)) + 1;
      my $y = int(rand($self->height)) + 1;
      my $coordinates = coordinates($x, $y);
      next if $altitude->{$coordinates};
      $altitude->{$coordinates} = $current_altitude;
      $log->debug("placed $current_altitude at $coordinates");
      push(@queue, $coordinates);
      last;
    }
  }
  return @queue;
}

sub grow_mountains {
  my $self = shift;
  my $altitude = shift;
  my @queue = @_;
  # go through the queue and add adjacent lower altitude hexes, if possible; the
  # hexes added are to the end of the queue
  while (@queue) {
    my $coordinates = shift @queue;
    my $current_altitude = $altitude->{$coordinates};
    next unless $current_altitude > 0;
    # pick some random neighbors based on variable steepness
    my $n = $self->steepness;
    # round up based on fraction
    $n += 1 if rand() < $n - int($n);
    $n = int($n);
    next if $n < 1;
    for (1 .. $n) {
      # try to find an empty neighbor; abort after six attempts
      for (1 .. 6) {
	my ($x, $y) = $self->neighbor($coordinates, $self->random_neighbor());
	next unless $self->legal($x, $y);
	my $other = coordinates($x, $y);
	# if this is taken, look further
	if ($altitude->{$other}) {
	  ($x, $y) = $self->neighbor2($coordinates, $self->random_neighbor2());
	  next unless $self->legal($x, $y);
	  $other = coordinates($x, $y);
	  # if this is also taken, try again
	  next if $altitude->{$other};
	}
	# if we found an empty neighbor, set its altitude
	$altitude->{$other} = $current_altitude > 0 ? $current_altitude - 1 : 0;
	push(@queue, $other);
	last;
      }
    }
  }
}

sub fix_altitude {
  my $self = shift;
  my $altitude = shift;
  # go through all the hexes
  for my $coordinates (sort keys %$altitude) {
    # find hexes that we missed and give them the height of a random neighbor
    if (not defined $altitude->{$coordinates}) {
      # warn "identified a hex that was skipped: $coordinates\n";
      # try to find a suitable neighbor
      for (1 .. 6) {
	my ($x, $y) = $self->neighbor($coordinates, $self->random_neighbor());
	next unless $self->legal($x, $y);
	my $other = coordinates($x, $y);
	next unless defined $altitude->{$other};
	$altitude->{$coordinates} = $altitude->{$other};
	last;
      }
      # if we didn't find one in the last six attempts, just make it hole in the ground
      if (not defined $altitude->{$coordinates}) {
	$altitude->{$coordinates} = 0;
      }
    }
  }
}

sub altitude {
  my $self = shift;
  my ($world, $altitude) = @_;
  my @queue = $self->place_peak($altitude, $self->peaks, $self->peak);
  $self->grow_mountains($altitude, @queue);
  $self->fix_altitude($altitude);
  # note height for debugging purposes
  for my $coordinates (sort keys %$altitude) {
    $world->{$coordinates} = "height$altitude->{$coordinates}";
  }
}

sub bumpiness {
  my ($self, $world, $altitude) = @_;
  for (1 .. $self->bumps) {
    for my $delta (-$self->bump, $self->bump) {
      # six attempts to try and find a good hex
      for (1 .. 6) {
	my $x = int(rand($self->width)) + 1;
	my $y = int(rand($self->height)) + 1;
	my $coordinates = coordinates($x, $y);
	my $current_altitude = $altitude->{$coordinates} + $delta;
	next if $current_altitude > 10 or $current_altitude < 0;
	# bump it up or down
	$altitude->{$coordinates} = $current_altitude;
	$world->{$coordinates} = "height$altitude->{$coordinates} zone";
	$log->debug("bumped altitude of $coordinates by $delta to $current_altitude");
	# if the bump was +2 or -2, bump the neighbours by +1 or -1
	if ($delta < -1 or $delta > 1) {
	  my $delta = $delta - $delta / abs($delta);
	  for my $i ($self->neighbors()) {
	    my ($x, $y) = $self->neighbor($coordinates, $i);
	    next unless $self->legal($x, $y);
	    my $other = coordinates($x, $y);
	    $current_altitude = $altitude->{$other} + $delta;
	    next if $current_altitude > 10 or $current_altitude < 0;
	    $altitude->{$other} = $current_altitude;
	    $world->{$other} = "height$altitude->{$other} zone";
	    $log->debug("$i bumped altitude of $other by $delta to $current_altitude");
	  }
	}
	# if we have found a good hex, don't go through all the other attempts
	last;
      }
    }
  }
}

sub water {
  my $self = shift;
  my ($world, $altitude, $water) = @_;
  # reset in case we run this twice
  # go through all the hexes
  for my $coordinates (sort keys %$altitude) {
    next if $altitude->{$coordinates} <= $self->bottom;
    # note preferred water flow by identifying lower lying neighbors
    my ($lowest, $direction);
    # look at neighbors in random order
  NEIGHBOR:
    for my $i (shuffle $self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      my $legal = $self->legal($x, $y);
      my $other = coordinates($x, $y);
      next if $legal and $altitude->{$other} > $altitude->{$coordinates};
      # don't point head on to another arrow
      next if $legal and $water->{$other} and $water->{$other} == ($i-3) % 6;
      # don't point into loops
      my %loop = ($coordinates => 1, $other => 1);
      my $next = $other;
      $log->debug("Loop detection starting with $coordinates and $other");
      while ($next) {
	# no water flow known is also good;
	$log->debug("water for $next: " . ($water->{$next} || "none"));
	last unless defined $water->{$next};
	($x, $y) = $self->neighbor($next, $water->{$next});
	# leaving the map is good
	$log->debug("legal for $next: " . $self->legal($x, $y));
	last unless $self->legal($x, $y);
	$next = coordinates($x, $y);
	# skip this neighbor if this is a loop
	$log->debug("is $next in a loop? " . ($loop{$next} || "no"));
	next NEIGHBOR if $loop{$next};
	$loop{$next} = 1;
      }
      if (not defined $direction
	  or not $legal and $altitude->{$coordinates} < $lowest
	  or $legal and $altitude->{$other} < $lowest) {
	$lowest = $legal ? $altitude->{$other} : $altitude->{$coordinates};
	$direction = $i;
	$log->debug("Set lowest to $lowest ($direction)");
      }
    }
    if (defined $direction) {
      $water->{$coordinates} = $direction;
      $world->{$coordinates} =~ s/arrow\d/arrow$water->{$coordinates}/
	  or $world->{$coordinates} .= " arrow$water->{$coordinates}";
    }
  }
}

sub mountains {
  my $self = shift;
  my ($world, $altitude) = @_;
  # place the types
  for my $coordinates (keys %$altitude) {
    if ($altitude->{$coordinates} >= 10) {
      $world->{$coordinates} = "white mountains";
    } elsif ($altitude->{$coordinates} >= 9) {
      $world->{$coordinates} = "white mountain";
    } elsif ($altitude->{$coordinates} >= 8) {
      $world->{$coordinates} = "light-grey mountain";
    }
  }
}

sub ocean {
  my $self = shift;
  my ($world, $altitude) = @_;
  for my $coordinates (sort keys %$altitude) {
    if ($altitude->{$coordinates} <= $self->bottom) {
      my $ocean = 1;
      for my $i ($self->neighbors()) {
	my ($x, $y) = $self->neighbor($coordinates, $i);
	next unless $self->legal($x, $y);
	my $other = coordinates($x, $y);
	next if $altitude->{$other} <= $self->bottom;
	$ocean = 0;
      }
      $world->{$coordinates} = $ocean ? "ocean" : "water";
    }
  }
}

sub lakes {
  my $self = shift;
  my ($world, $altitude, $water) = @_;
  # any areas without water flow are lakes
  for my $coordinates (sort keys %$altitude) {
    if (not defined $water->{$coordinates}
	and $world->{$coordinates} ne "ocean") {
      $world->{$coordinates} = "water";
    }
  }
}

sub swamps {
  # any area with water flowing to a neighbor at the same altitude is a swamp
  my ($self, $world, $altitude, $water, $flow, $dry) = @_;
  for my $coordinates (keys %$altitude) {
    # don't turn lakes into swamps and skip bogs
    next if $world->{$coordinates} =~ /ocean|water|swamp|grass/;
    # swamps require a river
    next unless $flow->{$coordinates};
    # no swamps when there is a canyon
    next if $dry->{$coordinates};
    # look at the neighbor the water would flow to
    my ($x, $y) = $self->neighbor($coordinates, $water->{$coordinates});
    # skip if water flows off the map
    next unless $self->legal($x, $y);
    my $other = coordinates($x, $y);
    # skip if water flows downhill
    next if $altitude->{$coordinates} > $altitude->{$other};
    # if there was no lower neighbor, this is a swamp
    if ($altitude->{$coordinates} >= 6) {
      $world->{$coordinates} =~ s/height\d+/grey swamp/;
    } else {
      $world->{$coordinates} =~ s/height\d+/dark-grey swamp/;
    }
  }
}

sub flood {
  my $self = shift;
  my ($world, $altitude, $water) = @_;
  # backtracking information: $from = $flow{$to}
  my %flow;
  # allow easy skipping
  my %seen;
  # start with a list of hexes to look at; as always, keys is a source of
  # randomness that's independent of srand which is why we shuffle sort
  my @lakes = shuffle sort grep { not defined $water->{$_} } keys %$world;
  return unless @lakes;
  my $start = shift(@lakes);
  my @candidates = ($start);
  while (@candidates) {
    # Prefer candidates outside the map with altitude 0; reshuffle because
    # candidates at the same height are all equal and early or late discoveries
    # should not matter (not shuffling means it matters whether candidates are
    # pushed or unshifted because this is a stable sort)
    @candidates = sort {
      ($altitude->{$a}||0) <=> ($altitude->{$b}||0)
    } shuffle @candidates;
    $log->debug("Candidates @candidates");
    my $coordinates;
    do {
      $coordinates = shift(@candidates);
    } until not $coordinates or not $seen{$coordinates};
    last unless $coordinates;
    $seen{$coordinates} = 1;
    $log->debug("Looking at $coordinates");
    if ($self->legal($coordinates) and $world->{$coordinates} ne "ocean") {
      # if we're still on the map, check all the unknown neighbors
      my $from = $coordinates;
      for my $i ($self->neighbors()) {
	my $to = coordinates($self->neighbor($from, $i));
	next if $seen{$to};
	$log->debug("Adding $to to our candidates");
	$flow{$to} = $from;
	# adding to the front as we keep pushing forward (I hope)
	push(@candidates, $to);
      }
      next;
    }
    $log->debug("We left the map at $coordinates");
    my $to = $coordinates;
    my $from = $flow{$to};
    while ($from) {
      my $i = $self->direction($from, $to);
      if (not defined $water->{$from}
	  or $water->{$from} != $i) {
	$log->debug("Arrow for $from now points to $to");
	$water->{$from} = $i;
	$world->{$from} =~ s/arrow\d/arrow$i/
	    or $world->{$from} .= " arrow$i";
      } else {
	$log->debug("Arrow for $from already points $to");
      }
      $to = $from;
      $from = $flow{$to};
    }
    # pick the next lake
    do {
      $start = shift(@lakes);
      $log->debug("Next lake is $start") if $start;
    } until not $start or not defined $water->{$start};
    last unless $start;
    %seen = %flow = ();
    @candidates = ($start);
  }
}

sub rivers {
  my ($self, $world, $altitude, $water, $flow, $rivers) = @_;
  # $flow are the sources points of rivers, or 1 if a river flows through them
  my @growing = map {
    $world->{$_} = "light-grey forest-hill" unless $world->{$_} =~ /mountain|swamp|grass|water|ocean/;
    $flow->{$_} = [$_]
  } sort grep {
    # these are the potential starting places: up in the mountains below the
    # ice, or lakes
    ($altitude->{$_} == 7 or $altitude->{$_} == 8
     or $world->{$_} =~ /water/ and $altitude->{$_} > $self->bottom)
    and not $flow->{$_}
    and $world->{$_} !~ /dry/;
  } keys %$altitude;
  $self->grow_rivers(\@growing, $water, $flow, $rivers);
}

sub grow_rivers {
  my ($self, $growing, $water, $flow, $rivers) = @_;
  while (@$growing) {
    # warn "Rivers: " . @growing . "\n";
    # pick a random growing river and grow it
    my $n = int(rand(scalar @$growing));
    my $river = $growing->[$n];
    # warn "Picking @$river\n";
    my $coordinates = $river->[-1];
    my $end = 1;
    if (defined $water->{$coordinates}) {
      my $other = coordinates($self->neighbor($coordinates, $water->{$coordinates}));
      die "Adding $other leads to an infinite loop in river @$river\n" if grep /$other/, @$river;
      # if we flowed into a hex with a river
      if (ref $flow->{$other}) {
	# warn "Prepending @$river to @{$flow->{$other}}\n";
	# prepend the current river to the other river
	unshift(@{$flow->{$other}}, @$river);
	# move the source marker
	$flow->{$river->[0]} = $flow->{$other};
	$flow->{$other} = 1;
	# and remove the current river from the growing list
	splice(@$growing, $n, 1);
	# warn "Flow at $river->[0]: @{$flow->{$river->[0]}}\n";
	# warn "Flow at $other: $flow->{$other}\n";
      } else {
	$flow->{$coordinates} = 1;
	push(@$river, $other);
      }
    } else {
      # stop growing this river
      # warn "Stopped river: @$river\n" if grep(/0914/, @$river);
      push(@$rivers, splice(@$growing, $n, 1));
    }
  }
}

sub canyons {
  my $self = shift;
  my ($world, $altitude, $rivers, $canyons, $dry) = @_;
  # using a reference to an array so that we can leave pointers in the %seen hash
  my $canyon = [];
  # remember which canyon flows through which hex
  my %seen;
  for my $river (@$rivers) {
    my $last = $river->[0];
    my $current_altitude = $altitude->{$last};
    $log->debug("Looking at @$river ($current_altitude)");
    for my $coordinates (@$river) {
      $log->debug("Looking at $coordinates");
      if ($seen{$coordinates}) {
	# the rest of this river was already looked at, so there is no need to
	# do the rest of this river; if we're in a canyon, prepend it to the one
	# we just found before ending
	if (@$canyon) {
	  my @other = @{$seen{$coordinates}};
	  if ($other[0] eq $canyon->[-1]) {
	    $log->debug("Canyon @$canyon of river @$river merging with @other at $coordinates");
	    unshift(@{$seen{$coordinates}}, @$canyon[0 .. @$canyon - 2]);
	  } else {
	    $log->debug("Canyon @$canyon of river @$river stumbled upon existing canyon @other at $coordinates");
	    while (@other) {
	      my $other = shift(@other);
	      next if $other ne $coordinates;
	      push(@$canyon, $other, @other);
	      last;
	    }
	    $log->debug("Canyon @$canyon");
	    push(@$canyons, $canyon);
	  }
	  $canyon = [];
	}
	$log->debug("We've seen the rest: @{$seen{$coordinates}}");
	last;
      }
      # no canyons through water!
      if ($altitude->{$coordinates} and $current_altitude < $altitude->{$coordinates}
	  and $world->{$coordinates} !~ /water|ocean/) {
	# river is digging a canyon; if this not the start of the river and it
	# is the start of a canyon, prepend the last step
	push(@$canyon, $last) unless @$canyon;
	push(@$canyon, $coordinates);
	$world->{$coordinates} .= " zone" unless $dry->{$coordinates};
	$dry->{$coordinates} = 1;
	$log->debug("Growing canyon @$canyon");
	$seen{$coordinates} = $canyon;
      } else {
	# if we just left a canyon, append the current step
	if (@$canyon) {
	  push(@$canyon, $coordinates);
	  push(@$canyons, $canyon);
	  $log->debug("Looking at river @$river");
	  $log->debug("Canyon @$canyon");
	  $canyon = [];
	  last;
	}
	# not digging a canyon
	$last = $coordinates;
	$current_altitude = $altitude->{$coordinates};
      }
    }
  }
}

sub wet {
  my $self = shift;
  # a hex is wet if there is a river, a swamp or a forest within 2 hexes
  my ($coordinates, $world, $flow) = @_;
  for my $i ($self->neighbors()) {
    my ($x, $y) = $self->neighbor($coordinates, $i);
    my $other = coordinates($x, $y);
    return 0 if $flow->{$other};
  }
  for my $i ($self->neighbors2()) {
    my ($x, $y) = $self->neighbor2($coordinates, $i);
    my $other = coordinates($x, $y);
    return 0 if $flow->{$other};
  }
  return 1;
}

sub grow_forest {
  my ($self, $coordinates, $world, $altitude, $dry) = @_;
  my @candidates;
  push(@candidates, $coordinates) if $world->{$coordinates} !~ /mountain|hill|water|ocean|swamp|grass/;
  my $n = $self->arid;
  # fractions are allowed
  $n += 1 if rand() < $self->arid - int($self->arid);
  $n = int($n);
  $log->debug("Arid: $n");
  if ($n >= 1) {
    for my $i ($self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      next if $dry->{$other};
      next if $altitude->{$coordinates} < $altitude->{$other}; # distance of one unless higher
      push(@candidates, $other) if $world->{$other} !~ /mountain|hill|water|ocean|swamp|grass/;
    }
  }
  if ($n >= 2) {
    for my $i ($self->neighbors2()) {
      my ($x, $y) = $self->neighbor2($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      next if $altitude->{$coordinates} <= $altitude->{$other}; # distance of two only if lower
      my $ok = 0;
      for my $m ($self->neighbors()) {
	my ($mx, $my) = $self->neighbor($coordinates, $m);
	next unless $self->legal($mx, $my);
	my $midway = coordinates($mx, $my);
	next if $dry->{$midway};
	next if $self->distance($midway, $other) != 1;
	next if $altitude->{$coordinates} < $altitude->{$midway};
	next if $altitude->{$midway} < $altitude->{$other};
	$ok = 1;
	last;
      }
      next unless $ok;
      push(@candidates, $other) if $world->{$other} !~ /mountain|hill|water|ocean|swamp|grass/;
    }
  }
  $log->debug("forest growth: $coordinates: @candidates");
  for $coordinates (@candidates) {
    if ($altitude->{$coordinates} >= 7) {
      $world->{$coordinates} = "light-green fir-forest";
    } elsif ($altitude->{$coordinates} >= 6) {
      $world->{$coordinates} = "green fir-forest";
    } elsif ($altitude->{$coordinates} >= 4) {
      $world->{$coordinates} = "green forest";
    } else {
      $world->{$coordinates} = "dark-green forest";
    }
  }
}

sub forests {
  my ($self, $world, $altitude, $flow, $dry) = @_;
  # Empty hexes with a river flowing through them (and nearby hexes) are forest
  # filled valleys.
  for my $coordinates (keys %$flow) {
    next if $dry->{$coordinates};
    $self->grow_forest($coordinates, $world, $altitude, $dry);
  }
}

sub winds {
  my $self = shift;
  my ($world, $altitude, $water, $flow) = @_;
  my $wind = $self->wind // $self->random_neighbor;
  $world->{"0101"} .= " wind" . $self->reverse($wind);
  for my $coordinates (keys %$altitude) {
    # limit ourselves to altitude 7 and 8
    next if $altitude->{$coordinates} < 7 or $altitude->{$coordinates} > 8;
    # look at the neighbor the water would flow to
    my ($x, $y) = $self->neighbor($coordinates, $wind);
    # skip if off the map
    next unless $self->legal($x, $y);
    my $other = coordinates($x, $y);
    # skip if the other hex is lower
    next if $altitude->{$coordinates} > $altitude->{$other};
    # if the other hex was higher, this land is dry
    $log->debug("$coordinates is dry because of $other");
    $world->{$coordinates} .= " dry zone"; # use label for debugging
  }
}

sub bogs {
  my $self = shift;
  my ($world, $altitude, $water) = @_;
  for my $coordinates (keys %$altitude) {
    # limit ourselves to altitude 7
    next if $altitude->{$coordinates} != 7;
    # don't turn lakes into bogs
    next if $world->{$coordinates} =~ /water|ocean/;
    # look at the neighbor the water would flow to
    my ($x, $y) = $self->neighbor($coordinates, $water->{$coordinates});
    # skip if water flows off the map
    next unless $self->legal($x, $y);
    my $other = coordinates($x, $y);
    # skip if water flows downhill
    next if $altitude->{$coordinates} > $altitude->{$other};
    # if there was no lower neighbor, this is a bog
    $world->{$coordinates} =~ s/height\d+/grey swamp/;
  }
}

sub dry {
  my ($self, $world, $altitude) = @_;
  my @dry;
  for my $coordinates (shuffle sort keys %$world) {
    if ($world->{$coordinates} !~ /mountain|hill|water|ocean|swamp|grass|forest|firs|trees/) {
      if ($altitude->{$coordinates} >= 7) {
	$world->{$coordinates} = "light-grey grass";
      } else {
	$world->{$coordinates} = "light-green bushes";
	push(@dry, $coordinates);
      }
    }
  }
  return unless @dry;
  # dry some of them up
  my @seeds = @dry[0..@dry/4];
  for my $coordinates (@seeds) {
    $self->drier($world, $coordinates);
    for my $i ($self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      $self->drier($world, $other);
    }
  }
}

sub drier {
  my ($self, $world, $coordinates) = @_;
  $world->{$coordinates} =~ s/light-green bushes/light-green grass/
      or $world->{$coordinates} =~ s/light-green grass/dust grass/
      or $world->{$coordinates} =~ s/dust grass/dust hill/
      or $world->{$coordinates} =~ s/dust hill/dust desert/;
}

sub settlements {
  my $self = shift;
  my ($world, $flow) = @_;
  my @settlements;
  my $max = $self->height * $self->width;
  # do not match forest-hill
  my @candidates = shuffle sort grep { $world->{$_} =~ /\b(fir-forest|forest(?!-hill))\b/ } keys %$world;
  @candidates = $self->remove_closer_than(2, @candidates);
  @candidates = @candidates[0 .. int($max/10 - 1)] if @candidates > $max/10;
  push(@settlements, @candidates);
  for my $coordinates (@candidates) {
    $world->{$coordinates} =~ s/fir-forest/firs thorp/
	or $world->{$coordinates} =~ s/forest(?!-hill)/trees thorp/;
  }
  @candidates = shuffle sort grep { $world->{$_} =~ /(?<!fir-)forest(?!-hill)/ and $flow->{$_}} keys %$world;
  @candidates = $self->remove_closer_than(5, @candidates);
  @candidates = @candidates[0 .. int($max/20 - 1)] if @candidates > $max/20;
  push(@settlements, @candidates);
  for my $coordinates (@candidates) {
    $world->{$coordinates} =~ s/forest/trees village/;
  }
  @candidates = shuffle sort grep { $world->{$_} =~ /(?<!fir-)forest(?!-hill)/ and $flow->{$_} } keys %$world;
  @candidates = $self->remove_closer_than(10, @candidates);
  @candidates = @candidates[0 .. int($max/40 - 1)] if @candidates > $max/40;
  push(@settlements, @candidates);
  for my $coordinates (@candidates) {
    $world->{$coordinates} =~ s/forest/trees town/;
  }
  @candidates = shuffle sort grep { $world->{$_} =~ /white mountain\b/ } keys %$world;
  @candidates = $self->remove_closer_than(10, @candidates);
  @candidates = @candidates[0 .. int($max/40 - 1)] if @candidates > $max/40;
  push(@settlements, @candidates);
  for my $coordinates (@candidates) {
    $world->{$coordinates} =~ s/white mountain\b/white mountain law/;
  }
  @candidates = shuffle sort grep { $world->{$_} =~ /swamp/ } keys %$world;
  @candidates = $self->remove_closer_than(10, @candidates);
  @candidates = @candidates[0 .. int($max/40 - 1)] if @candidates > $max/40;
  push(@settlements, @candidates);
  for my $coordinates (@candidates) {
    $world->{$coordinates} =~ s/swamp/swamp2 chaos/;
  }
  for my $coordinates (@settlements) {
    for my $i ($self->neighbors()) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      my $other = coordinates($x, $y);
      next unless $world->{$other} and $world->{$other} =~ /water|ocean/;
      # bump ports one size category up
      $world->{$coordinates} =~ s/large-town/city port/;
      $world->{$coordinates} =~ s/town/large-town port/;
      $world->{$coordinates} =~ s/village/town port/;
      # no bumps for thorps
      last;
    }
  }
  for my $coordinates (@settlements) {
    # thorps and villages don't cut enough wood; make sure to get both "green" and "dark-green"
    $world->{$coordinates} =~ s/\S*green trees/light-soil/ if $world->{$coordinates} =~ /large-town|city/;
    $world->{$coordinates} =~ s/\S*green trees/soil/ if $world->{$coordinates} =~ / town/;
  }
  return @settlements;
}

sub trails {
  my $self = shift;
  my ($altitude, $settlements) = @_;
  # look for a neighbor that is as low as possible and nearby
  my %trails;
  my @from = shuffle @$settlements;
  my @to = shuffle @$settlements;
  for my $from (@from) {
    my ($best, $best_distance, $best_altitude);
    for my $to (@to) {
      next if $from eq $to;
      my $distance = $self->distance($from, $to);
      $log->debug("Considering $from-$to: distance $distance, altitude " . $altitude->{$to});
      if ($distance <= 3
	  and (not $best_distance or $distance <= $best_distance)
	  and (not $best or $altitude->{$to} < $best_altitude)) {
	$best = $to;
	$best_altitude = $altitude->{$best};
	$best_distance = $distance;
      }
    }
    next if not $best;
    # skip if it already exists in the other direction
    next if $trails{"$best-$from"};
    $trails{"$from-$best"} = 1;
    $log->debug("Trail $from-$best");
  }
  return keys %trails;
}

sub cliffs {
  my $self = shift;
  my ($world, $altitude) = @_;
  my @neighbors = $self->neighbors();
  # hexes with altitude difference bigger than 1 have cliffs
  for my $coordinates (keys %$world) {
    next if $altitude->{$coordinates} <= $self->bottom;
    for my $i (@neighbors) {
      my ($x, $y) = $self->neighbor($coordinates, $i);
      next unless $self->legal($x, $y);
      my $other = coordinates($x, $y);
      if ($altitude->{$coordinates} - $altitude->{$other} >= 2) {
	if (@neighbors == 6) {
	  $world->{$coordinates} .= " cliff$i";
	} else { # square
	  $world->{$coordinates} .= " cliffs$i";
	}
      }
    }
  }
}

sub marshlands {
  my ($self, $world, $altitude, $rivers) = @_;
  my %seen;
  for my $river (@$rivers) {
    my $last = $river->[0];
    for my $coordinates (@$river) {
      last if $seen{$coordinates}; # we've been here before
      $seen{$coordinates} = 1;
      next unless exists $altitude->{$coordinates}; # rivers ending off the map
      if ($altitude->{$coordinates} <= $self->bottom) {
	if ($altitude->{$coordinates} == $self->bottom
	    and $world->{$coordinates} =~ /water|ocean/
	    and $altitude->{$coordinates} == $altitude->{$last} - 1) {
	  $world->{$coordinates} = "blue-green swamp";
	} else {
	  $world->{$coordinates} =~ s/ocean/water/;
	  delete $seen{$coordinates};
	  last;
	}
      }
      $last = $coordinates;
    }
  }
}

sub generate {
  my ($self, $world, $altitude, $water, $rivers, $settlements, $trails, $canyons, $step) = @_;
  # $flow indicates that there is actually a river in this hex
  my $flow = {};
  # $dry indicates that is a river in this hex, but it cut itself a canyon
  my $dry = {};
  my @code = (
    sub { $self->flat($altitude);
	  $self->altitude($world, $altitude); },
    sub { $self->bumpiness($world, $altitude); },
    sub { $self->mountains($world, $altitude); },
    sub { $self->ocean($world, $altitude); },
    sub { $self->water($world, $altitude, $water); },
    sub { $self->lakes($world, $altitude, $water); },
    sub { $self->flood($world, $altitude, $water); },
    sub { $self->bogs($world, $altitude, $water); },
    sub { $self->winds($world, $altitude, $water); },
    sub { $self->rivers($world, $altitude, $water, $flow, $rivers); },
    sub { $self->canyons($world, $altitude, $rivers, $canyons, $dry); },
    sub { $self->swamps($world, $altitude, $water, $flow, $dry); },
    sub { $self->forests($world, $altitude, $flow, $dry); },
    sub { $self->dry($world, $altitude); },
    sub { $self->cliffs($world, $altitude); },
    sub { push(@$settlements, $self->settlements($world, $flow)); },
    sub { push(@$trails, $self->trails($altitude, $settlements)); },
    sub { $self->marshlands($world, $altitude, $rivers); },
    # make sure you look at "alpine_document.html.ep" if you change this list!
    # make sure you look at '/alpine/document' if you add to this list!
      );

  # $step 0 runs all the code; note that we can't simply cache those results
  # because we need to start over with the same seed!
  my $i = 1;
  while (@code) {
    shift(@code)->();
    return if $step == $i++;
    $self->fixup($world, $altitude, $i);
  }
}

# Remove temporary markers that won't be needed in the next step
sub fixup {
  my ($self, $world, $altitude, $step, $last) = @_;
  # When documenting or debugging, water flow arrows are no longer needed when
  # the rivers are added.
  if ($step >= 10) {
    for my $coordinates (keys %$world) {
      $world->{$coordinates} =~ s/ arrow\d//;
    }
  }
  # Wind direction is only shown once.
  $world->{"0101"} =~ s/ wind\d//;
  # Remove zone markers.
  for my $coordinates (keys %$world) {
    $world->{$coordinates} =~ s/ zone//;
  }
}

sub generate_map {
  my $self = shift;

  # The parameters turn into class variables.
  $self->width(shift // 30);
  $self->height(shift // 10);
  $self->steepness(shift // 3);
  $self->peaks(shift // int($self->width * $self->height / 40));
  $self->peak(shift // 10);
  $self->bumps(shift // int($self->width * $self->height / 40));
  $self->bump(shift // 2);
  $self->bottom(shift // 0);
  $self->arid(shift // 2);
  $self->wind(shift); # or random
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

  # Keys for all hashes are coordinates such as "0101".
  # %world is the description with values such as "green forest".
  # %altitude is the altitude with values such as 3.
  # %water is the preferred direction water would take with values such as 0.
  # (north west); 0 means we need to use "if defined".
  # @rivers are the rivers with values such as ["0102", "0202"].
  # @settlements are are the locations of settlements such as "0101".
  # @trails are the trails connecting these with values as "0102-0202".
  # $step is how far we want map generation to go where 0 means all the way.
  my ($world, $altitude, $water, $rivers, $settlements, $trails, $canyons) =
      ({}, {}, {}, [], [], [], []);
  $self->generate($world, $altitude, $water, $rivers, $settlements, $trails, $canyons, $step);

  # When documenting or debugging, add altitude as a label.
  if ($step > 0) {
    for my $coordinates (keys %$world) {
      $world->{$coordinates} .= ' "' . $altitude->{$coordinates} . '"';
    }
  }

  local $" = "-"; # list items separated by -
  my @lines;
  push(@lines, map { $_ . " " . $world->{$_} } sort keys %$world);
  push(@lines, map { "$_ trail" } @$trails);
  push(@lines, map { "@$_ river" } @$rivers);
  push(@lines, map { "@$_ canyon" } @$canyons); # after rivers
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
