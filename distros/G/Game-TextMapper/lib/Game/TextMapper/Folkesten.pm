# Copyright (C) 2023  Alex Schroeder <alex@gnu.org>
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

Game::TextMapper::Folkesten - generate fantasy wilderness maps

=head1 SYNOPSIS

    my $text = Game::TextMapper::Folkesten->new
        ->generate_map();

=head1 DESCRIPTION

This generates a wilderness map based on the algorithm by Andreas Folkesten. See the
blog posts at L<http://arch-brick.blogspot.com/2023/08/hexmap-terrain-generator.html>.

=head1 METHODS

Note that this module acts as a class with the C<generate_map> method, but none
of the other subroutines defined are actual methods. They don't take a C<$self>
argument.

=cut

package Game::TextMapper::Folkesten;
use Game::TextMapper::Log;
use Game::TextMapper::Point;
use Modern::Perl '2018';
use Mojo::Base -base;
use List::Util qw(shuffle any first);

has 'world' => sub { {} };
has 'dry' => sub { {} };
has 'wet' => sub { {} };
has 'width' => 10;
has 'height' => 10;
has 'rivers' => sub { [] };
has 'canyons' => sub { [] };
has 'altitude' => sub {
  {
    'mountain' => 3,
    'forest-hill' => 2,
    'green-hills' => 2,
    'hills' => 2,
    'plain' => 1,
    'water' => 0,
    'ocean' => 0,
  }
};

*coord = \&Game::TextMapper::Point::coord;

my $log = Game::TextMapper::Log->get;

=head2 neighbors

The list of directions for neighbours one step away (0 to 5).

=cut

sub neighbors { 0 .. 5 }

=head2 random_neighbor

A random direction for a neighbour one step away (a random integer from 0 to 5).

=cut

sub random_neighbor { int(rand(6)) }

=head2 neighbor($hex, $i)

    say join(",", $map->neighbor("0203", 1));
    # 2,2

Returns the coordinates of a neighbor in a particular direction (0 to 5), one
step away.

C<$hex> is an array reference of coordinates or a string that can be turned into
one using the C<xy> method.

C<$i> is a direction (0 to 5).

=cut

sub neighbor {
  my $self = shift;
  # $hex is [x,y] or "0x0y" and $i is a number 0 .. 5
  my ($hex, $i) = @_;
  die join(":", caller) . ": undefined direction for $hex\n" unless defined $i;
  $hex = [$self->xy($hex)] unless ref $hex;
  my $delta_hex = [
    # x is even
    [[-1,  0], [ 0, -1], [+1,  0], [+1, +1], [ 0, +1], [-1, +1]],
    # x is odd
    [[-1, -1], [ 0, -1], [+1, -1], [+1,  0], [ 0, +1], [-1,  0]]];
  return ($hex->[0] + $delta_hex->[$hex->[0] % 2]->[$i]->[0],
	  $hex->[1] + $delta_hex->[$hex->[0] % 2]->[$i]->[1]);
}

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

=head2 neighbors($hex)

    say join(" ", $map->neighbors("0203"));
    # 0202 0303 0304 0204 0104 0103 0102

Returns the list of legal neighbours, one step away. This could be just two
neighbours (e.g. around 0101).

C<$hex> is an array reference of coordinates or a string that can be turned into
one using the C<xy> method.

=cut

sub all_neighbors {
  my $self = shift;
  my $hex = shift;
  return grep { $self->legal($_) } map { coord($self->neighbor($hex, $_)) } $self->neighbors;
}

=head2 generate_plains

All hexes are plains.

=cut

sub generate_plains {
  my $self = shift;
  for my $x (1 .. $self->width) {
    for my $y (1 .. $self->height) {
      $self->world->{coord($x,$y)} = 'plain';
    }
  }
}

=head2 generate_ocean

1d6-2 edges of the map are ocean. Randomly determine which ones. Every hex on
these edges is ocean. Every hex bordering an ocean hex has a 50% chance to be
ocean. Every hex bordering one of these secondary ocean hexes has a 33% chance
to be ocean, unless it has already been rolled for.

=cut

sub generate_ocean {
  my $self = shift;
  my $edges = int(rand(6))-2;
  return if $edges < 0;
  my @edges = shuffle(qw(north east south west));
  for my $edge (@edges[0..$edges]) {
    if ($edge eq 'west') {
      for my $y (1 .. $self->height) {
        $self->world->{coord(1,$y)} = 'ocean';
      }
    } elsif ($edge eq 'east') {
      for my $y (1 .. $self->height) {
        $self->world->{coord($self->width,$y)} = 'ocean';
      }
    } elsif ($edge eq 'north') {
      for my $x (1 .. $self->width) {
        $self->world->{coord($x,1)} = 'ocean';
      }
    } elsif ($edge eq 'south') {
      for my $x (1 .. $self->width) {
        $self->world->{coord($x,$self->height)} = 'ocean';
      }
    }
  }
  my @secondary;
  for my $hex (grep { $self->world->{$_} eq 'ocean' } sort keys %{$self->world}) {
      for my $other ($self->all_neighbors($hex)) {
        if ($self->world->{$other} ne 'ocean' and rand() < 1/3) {
          push(@secondary, $other);
          $self->world->{$other} = 'ocean';
        }
    }
  }
  my %seen;
  for my $hex (@secondary) {
    for my $other ($self->all_neighbors($hex)) {
      next if $seen{$other};
      $seen{$other} = 1;
      if ($self->world->{$other} ne 'ocean' and rand() < 0.5) {
        $self->world->{$other} = 'ocean';
      }
    }
  }
  for my $hex (grep { $self->world->{$_} eq 'ocean' } sort keys %{$self->world}) {
    if (any { $self->world->{$_} ne 'ocean' and  $self->world->{$_} ne 'water' } $self->all_neighbors($hex)) {
      $self->world->{$hex} = 'water';
    }
  }
}

=head2 generate_mountains

Place 1d6 mountain hexes. Roll two d10s for each to determine its coordinates.
If you end up in an ocean hex or a previous mountain hex, roll again. Every
plains hex adjacent to a mountain hex has a 4 in 6 chance to be mountains as
well; otherwise, it is hills. Repeat, but now with a 2 in 6 chance. Every plains
hex adjacent to a hill hex has a 3 in 6 chance to be hills.

=cut

sub generate_mountains {
  my $self = shift;
  my $m = int(rand(6))+1;
  my $n = 0;
  my @mountains;
  while ($n < $m) {
    my $x = int(rand($self->width))+1;
    my $y = int(rand($self->height))+1;
    my $coord = coord($x, $y);
    if ($self->world->{$coord} eq 'plain') {
      push(@mountains, $coord);
      $self->world->{$coord} = 'mountain';
      $n++;
    }
  }
  for my $chance (2/3, 1/3, 0) {
    for my $hex (grep { $self->world->{$_} eq 'mountain' } sort keys %{$self->world}) {
      for my $other ($self->all_neighbors($hex)) {
        if ($self->world->{$other} eq 'plain') {
          if ($chance and rand() < $chance) {
            $self->world->{$other} = 'mountain';
          } else {
            $self->world->{$other} = 'hills';
          }
        }
      }
    }
  }
  for my $hex (grep { $self->world->{$_} eq 'hills' } sort keys %{$self->world}) {
    for my $other ($self->all_neighbors($hex)) {
      if ($self->world->{$other} eq 'plain') {
        $self->world->{$other} = 'hills';
      }
    }
  }
}

=head2 rivers

The original instructions are: "Roll 1d6 to determine how many major rivers
there are: 1 none, 2-4 one, 5 two, 6 two rivers joining into one. Each river has
a 3 in 6 chance to be flowing out of a mountain or hill hex; otherwise, it
enters from the edge of the map (if there is a land edge). If there is an ocean
on the map, the rivers will flow into it."

Instead of doing that, let's try this: "A river starts in ever mountain and
every hill, flowing downwards if possible: from mountains to hills, from hills
to plains and from plains into the ocean or off the map. Pick the lowest lying
neighbour. We can mark these as canyons, later. When a river meets another
river, then merge them (same tail) or subsume them (if meerging with the
beginning of an existing river)."

=cut

sub generate_rivers {
  my $self = shift;
  my %seen;
  local $" = "-";
  for my $hex (grep { $self->world->{$_} eq 'mountain' } sort keys %{$self->world}) {
    next if $seen{$hex};
    my $river = [$hex];
    $seen{$hex} = $river;
    push(@{$self->rivers}, $river);
    $self->wet->{$hex} = 1;
    $log->debug("River starting at $hex");
    while(1) {
      my @neighbours = map { coord($self->neighbor($hex, $_)) } shuffle $self->neighbors;
      my $end = first { not $self->legal($_) or $self->world->{$_} eq 'water' } @neighbours;
      if ($end) {
        $log->debug(" ends at $end");
        push(@$river, $end);
        last;
      }
      # $log->debug(" neighbours: " . join(", ", map { "$_: " . $self->world->{$_} } @neighbours));
      @neighbours = sort { $self->altitude->{$self->world->{$a}} <=> $self->altitude->{$self->world->{$b}} } @neighbours;
      my $next = shift(@neighbours);
      if ($seen{$next}) {
        my @other = @{$seen{$next}};
        $log->debug("  found river at $next: @other");
        # avoid loops
        while ($other[0] eq $river->[0]) {
          $next = shift(@neighbours);
          if ($seen{$next}) {
            @other = @{$seen{$next}};
            $log->debug("  nope, try again at $next: @other");
            # check again
          } else {
            @other = ();
            $log->debug("  nope, try again at $next (no river)");
            last;
          }
        }
        if (@other > 0) {
          if ($other[0] eq $next) {
            $log->debug(" flows into @other");
            # append the other river hexes to this river and remove the other river from the list
            push(@$river, @other);
            $self->rivers([grep { $_->[0] ne $next } @{$self->rivers}]);
          } else {
            $log->debug(" merges into @other");
            # copy the downstream hexes of the other river
            shift(@other) while $other[0] and $other[0] ne $next;
            push(@$river, @other);
          }
          last;
        }
        if (not $next) {
          # with no other neighbour found, the river goes underground!?
          $log->debug(" disappears");
          last;
        }
        # if the neighbour is not a a river and exists, fall through
      }
      $hex = $next;
      $log->debug(" flows to $hex");
      push(@$river, $hex);
      $seen{$hex} = $river;
      $self->wet->{$hex} = 1;
    }
  }
}

=head2 generate_canyons

Check all the rivers: if it flows "uphill", add a canyon

=cut

sub generate_canyons {
  my $self = shift;
  local $" = "-";
  my %seen;
  my $canyon = [];
  for my $river (@{$self->rivers}) {
    next unless @$river > 2;
    my $last = $river->[0];
    my $current_altitude = $self->altitude->{$self->world->{$last}};
    $log->debug("Looking at @$river ($current_altitude)");
    for my $hex (@$river) {
      if ($seen{$hex}) {
        if (@$canyon == 0) {
          last;
        } elsif ($seen{$hex} == 1) {
          push(@$canyon, $hex);
          push(@{$self->canyons}, $canyon);
          $canyon = [];
          $log->debug(" ending cayon at known $hex");
          $current_altitude = $self->altitude->{$self->world->{$hex}};
          next;
        } elsif ($seen{$hex} > 1) {
          push(@{$self->canyons}, $canyon);
          $canyon = [];
          $log->debug(" merging cayon at $hex");
          # FIXME
          last;
        }
      }
      $seen{$hex}++;
      if ($self->legal($hex) and $self->altitude->{$self->world->{$hex}} > $current_altitude) {
        if (@$canyon > 0) {
          push(@$canyon, $hex);
          $log->debug(" extending cayon to $hex");
        } else {
          $canyon = [$last, $hex];
          $log->debug("Starting cayon @$canyon");
        }
        $seen{$hex}++; # more than 1 means this is inside a canyon
      } elsif (@$canyon > 0) {
        push(@$canyon, $hex);
        push(@{$self->canyons}, $canyon);
        $canyon = [];
        $log->debug(" ending cayon at $hex");
        $current_altitude = $self->altitude->{$self->world->{$hex}};
      } elsif ($self->legal($hex)) {
        $current_altitude = $self->altitude->{$self->world->{$hex}};
      }
      $last = $hex;
    }
  }
}

=head2 generate_dry

The wind blows from west or east. Follow the wind in straight horizontal lines.
Once the line hits a mountain, all the following hexes are dry hills or dry
plains except if it has a river.

=cut

sub generate_dry {
  my $self = shift;
  my $dir = rand() < 0.5 ? -1 : 1;
  my $start = $dir == 1 ? 1 : $self->width;
  my $end = $dir == 1 ? $self->width : 1;
  for my $y (1 .. $self->height) {
    my $dry = 0;
    for (my $x = $start; $dir == 1 ? $x <= $end : $x >= $end; $x += $dir) {
      my $hex = coord($x, $y);
      if (not $dry and $self->world->{$hex} eq 'mountain') {
        $log->debug("Going " . ($dir == 1 ? 'east' : 'west') . " from $hex is dry");
        $dry = $x;
      } elsif ($dry) {
        my @hexes = ($hex);
        # $dry contains the $x of the mountain. If $x something like 0306, we
        # want to check 0405 (-1!) and 0406; if $x is something like 0607, we
        # want to check 0707 and 0708 (+1). That is to say, it depends on
        # whether the initial $x is even or odd. Also, it's always two hexes to
        # check if the difference between the two $x coordinates is odd.
        push(@hexes, coord($x, $y + ($dry % 2 ? -1 : +1))) if abs($x - $dry) % 2;
        for my $hex2 (@hexes) {
          next if $self->wet->{$hex2};
          $log->debug(" $hex2 is dry");
          $self->dry->{$hex2} = 1;
        }
      }
    }
  }
}

=head2 generate_forest

Every hex with a river has a 50% chance to be forested. Every hills or plains
hex without a river that isn’t dry or next to a dry hex has a 1 in 6 chance to
be forested; 2 in 6 if it is next to a forested river hex.

=cut

sub generate_forest {
  my $self = shift;
  my @land_hexes = grep { $self->world->{$_} ne 'water' and $self->world->{$_} ne 'ocean' } sort keys %{$self->world};
  my %forest_hexes;
  for my $hex (@land_hexes) {
    if ($self->wet->{$hex} and rand() < 0.5
        or not $self->dry->{$hex}
        and not any { $self->dry->{$_} } $self->all_neighbors($hex)
        and rand() < 1/6) {
      if ($self->world->{$hex} eq 'plain' ) {
        $self->world->{$hex} = 'forest';
        $forest_hexes{$hex} = 1;
      } elsif ($self->world->{$hex} eq 'hills' ) {
        $self->world->{$hex} = 'forest-hill';
        $forest_hexes{$hex} = 1;
      }
    }
  }
  # since this pass relies on neighbours being forested
  for my $hex (@land_hexes) {
    if (not $self->dry->{$hex}
        and any { $forest_hexes{$_} } $self->all_neighbors($hex)
        and rand() < 2/6) {
      if ($self->world->{$hex} eq 'plain' ) {
        $self->world->{$hex} = 'forest';
      } elsif ($self->world->{$hex} eq 'hills' ) {
        $self->world->{$hex} = 'forest-hill';
      }
    }
  }
}

=head2 generate_swamp

A 1 in 6 chance on every plain river hex that isn't next to a dry hex.

=cut

sub generate_swamp {
  my $self = shift;
  for my $hex (grep { $self->world->{$_} eq 'plain' and $self->wet->{$_} } sort keys %{$self->world}) {
    next if any { $self->dry->{$_} } $self->all_neighbors($hex);
    if (rand() < 1/6) {
      $self->world->{$hex} = 'swamp';
    }
  }
}

=head2 generate_islands

Every ocean hex has a 1 in 6 chance of having an island.

=cut

sub generate_islands {
  my $self = shift;
  for my $hex (grep { $self->world->{$_} eq 'water' or $self->world->{$_} eq 'ocean' } sort keys %{$self->world}) {
    if (rand() < 1/6) {
      $self->world->{$hex} .= " island";
    }
  }
}

=head2 string

Create the string output.

=cut

sub string {
  my $self = shift;
  return join("\n", map { $_ . " " . $self->world->{$_} } sort keys %{$self->world}) . "\n"
      . join("\n", map { join("-", @$_) . " river" } @{$self->rivers}) . "\n"
      . join("\n", map { join("-", @$_) . " canyon" } @{$self->canyons}) . "\n";
}

=head2 generate_map

Start with a 10 by 10 hexmap.

=cut

sub generate_map {
  my $self = shift;
  $self->generate_plains();
  $self->generate_ocean();
  $self->generate_mountains();
  $self->generate_rivers();
  $self->generate_canyons();
  $self->generate_dry();
  $self->generate_forest();
  $self->generate_swamp();
  $self->generate_islands();
  return $self->string() . "\n"
      . "include bright.txt\n";
}

=head1 SEE ALSO

Andreas Folkesten described this algorithm in the following blog post:
L<http://arch-brick.blogspot.com/2023/08/hexmap-terrain-generator.html>.

The map itself uses the I<Light> icons by Alex Schroeder. These are
dedicated to the public domain. See
L<http://creativecommons.org/licenses/by-sa/3.0/>.

=cut

1;
