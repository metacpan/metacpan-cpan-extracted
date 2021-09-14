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

Game::TextMapper::Smale - generate fantasy wilderness maps

=head1 SYNOPSIS

    my $text = Game::TextMapper::Smale->new
        ->generate_map($width, $height, $bw);

=head1 DESCRIPTION

This generates a wilderness map based on the algorithm by Erin D. Smale. See the
blog posts at L<http://www.welshpiper.com/hex-based-campaign-design-part-1/> and
L<http://www.welshpiper.com/hex-based-campaign-design-part-2/> for more
information.

=head1 METHODS

Note that this module acts as a class with the C<generate_map> method, but none
of the other subroutines defined are actual methods. They don't take a C<$self>
argument.

=cut

package Game::TextMapper::Smale;
use Game::TextMapper::Log;
use Game::TextMapper::Point;
use Modern::Perl '2018';
use Mojo::Base -base;

my $log = Game::TextMapper::Log->get;

my %world = ();

#         ATLAS HEX PRIMARY TERRAIN TYPE
#         Water   Swamp   Desert  Plains  Forest  Hills   Mountains
# Water   P       W       W       W       W       W       -
# Swamp   W       P       -       W       W       -       -
# Desert  W       -       P       W       -       W       W
# Plains  S [1]   S       T       P [4]   S       T       -
# Forest  T [2]   T       -       S       P [5]   W [8]   T [11]
# Hills   W       -       S [3]   T       T [6]   P [9]   S
# Mountns -       -       W       -       W [7]   S [10]  P [12]
#
#  1. Treat as coastal (beach or scrub) if adjacent to water
#  2. 66% light forest
#  3. 33% rocky desert or high sand dunes
#  4. Treat as farmland in settled hexes
#  5. 33% heavy forest
#  6. 66% forested hills
#  7. 66% forested mountains
#  8. 33% forested hills
#  9. 20% canyon or fissure (not implemented)
# 10. 40% chance of a pass (not implemented)
# 11. 33% forested mountains
# 12. 20% chance of a dominating peak; 10% chance of a mountain pass (not
#     implemented); 5% volcano (not implemented)
#
# Notes
# water:    water
# sand:     sand or dust
# swamp:    dark-grey swamp (near trees) or dark-grey marshes (no trees)
# plains:   light-green grass, bush or bushes near water or forest
# forest:   green trees (light), green forest, dark-green forest (heavy);
#           use firs and fir-forest near hills or mountains
# hill:     light-grey hill, dust hill if sand dunes
# mountain: grey mountain, grey mountains (peak)

# later, grass land near a settlement might get the colors soil or dark-soil!

my %primary = ("water" =>  ["water"],
	       "swamp" =>  ["dark-grey swamp"],
	       "desert" => ["dust desert"],
	       "plains" => ["light-green grass"],
	       "forest" => ["green forest",
			    "green forest",
			    "dark-green fir-forest"],
	       "hill" =>   ["light-grey hill"],
	       "mountain" => ["grey mountain",
			      "grey mountain",
			      "grey mountain",
			      "grey mountain",
			      "grey mountains"]);

my %secondary = ("water" =>  ["light-green grass",
			      "light-green bush",
			      "light-green bushes"],
		 "swamp" =>  ["light-green grass"],
		 "desert" =>   ["light-grey hill",
				"light-grey hill",
				"dust hill"],
		 "plains" =>  ["green forest"],
		 "forest" => ["light-green grass",
			      "light-green bush"],
		 "hill" =>   ["grey mountain"],
		 "mountain" => ["light-grey hill"]);

my %tertiary = ("water" => ["green forest",
			    "green trees",
			    "green trees"],
		"swamp" => ["green forest"],
		"desert" => ["light-green grass"],
		"plains" => ["light-grey hill"],
		"forest" => ["light-grey forest-hill",
			     "light-grey forest-hill",
			     "light-grey hill"],
		"hill" => ["light-green grass"],
		"mountain" => ["green fir-forest",
			       "green forest",
			       "green forest-mountains"]);

my %wildcard = ("water" => ["dark-grey swamp",
			    "dark-grey marsh",
			    "sand desert",
			    "dust desert",
			    "light-grey hill",
			    "light-grey forest-hill"],
		"swamp" => ["water"],
		"desert" => ["water",
			     "grey mountain"],
		"plains" => ["water",
			     "dark-grey swamp",
			     "dust desert"],
		"forest" => ["water",
			     "water",
			     "water",
			     "dark-grey swamp",
			     "dark-grey swamp",
			     "dark-grey marsh",
			     "grey mountain",
			     "grey forest-mountain",
			     "grey forest-mountains"],
		"hill" => ["water",
			   "water",
			   "water",
			   "sand desert",
			   "sand desert",
			   "dust desert",
			   "green forest",
			   "green forest",
			   "green forest-hill"],
		"mountain" => ["sand desert",
			       "dust desert"]);


my %reverse_lookup = (
  # primary
  "water" => "water",
  "dark-grey swamp" => "swamp",
  "dust desert" => "desert",
  "light-green grass" => "plains",
  "green forest" => "forest",
  "dark-green fir-forest" => "forest",
  "light-grey hill" => "hill",
  "grey mountain" => "mountain",
  "grey mountains" => "mountain",
  # secondary
  "light-green bush" => "plains",
  "light-green bushes" => "plains",
  "dust hill" => "hill",
  # tertiary
  "green trees" => "forest",
  "light-grey forest-hill" => "hill",
  "green fir-forest" => "forest",
  "green forest-mountains" => "forest",
  # wildcard
  "dark-grey marsh" => "swamp",
  "sand desert" => "desert",
  "grey forest-mountain" => "mountain",
  "grey forest-mountains" => "mountain",
  "green forest-hill" => "forest",
  # code
  "light-soil fields" => "plains",
  "soil fields" => "plains",
    );

my %encounters = ("settlement" => ["thorp", "thorp", "thorp", "thorp",
				   "village",
				   "town", "town",
				   "large-town",
				   "city"],
		  "fortress" => ["keep", "tower", "castle"],
		  "religious" => ["shrine", "law", "chaos"],
		  "ruin" => [],
		  "monster" => [],
		  "natural" => []);

my @needs_fields;

sub one {
  my @arr = @_;
  @arr = @{$arr[0]} if @arr == 1 and ref $arr[0] eq 'ARRAY';
  return $arr[int(rand(scalar @arr))];
}

sub member {
  my $element = shift;
  foreach (@_) {
    return 1 if $element eq $_;
  }
}

sub place_major {
  my ($x, $y, $encounter) = @_;
  my $thing = one(@{$encounters{$encounter}});
  return unless $thing;
  $log->debug("placing $thing ($encounter) at ($x,$y)");
  my $hex = one(full_hexes($x, $y));
  $x += $hex->[0];
  $y += $hex->[1];
  my $coordinates = Game::TextMapper::Point::coord($x, $y);
  my $primary = $reverse_lookup{$world{$coordinates}};
  my ($color, $terrain) = split(' ', $world{$coordinates}, 2);
  if ($encounter eq 'settlement') {
    if ($primary eq 'plains') {
      $color = one('light-soil', 'soil');
      $log->debug(" " . $world{$coordinates} . " is $primary and was changed to $color");
    }
    if ($primary ne 'plains' or member($thing, 'large-town', 'city')) {
      push(@needs_fields, [$x, $y]);
    }
  }
  # ignore $terrain for the moment and replace it with $thing
  $world{$coordinates} = "$color $thing";
}

sub populate_region {
  my ($hex, $primary) = @_;
  my $random = rand 100;
  if ($primary eq 'water' and $random < 10
      or $primary eq 'swamp' and $random < 20
      or $primary eq 'sand' and $random < 20
      or $primary eq 'grass' and $random < 60
      or $primary eq 'forest' and $random < 40
      or $primary eq 'hill' and $random < 40
      or $primary eq 'mountain' and $random < 20) {
    place_major($hex->[0], $hex->[1], one(keys %encounters));
  }
}

# Brute forcing by picking random sub hexes until we found an
# unassigned one.

sub pick_unassigned {
  my ($x, $y, @region) = @_;
  my $hex = one(@region);
  my $coordinates = Game::TextMapper::Point::coord($x + $hex->[0], $y + $hex->[1]);
  while ($world{$coordinates}) {
    $hex = one(@region);
    $coordinates = Game::TextMapper::Point::coord($x + $hex->[0], $y + $hex->[1]);
  }
  return $coordinates;
}

sub pick_remaining {
  my ($x, $y, @region) = @_;
  my @coordinates = ();
  for my $hex (@region) {
    my $coordinates = Game::TextMapper::Point::coord($x + $hex->[0], $y + $hex->[1]);
    push(@coordinates, $coordinates) unless $world{$coordinates};
  }
  return @coordinates;
}

# Precomputed for speed

sub full_hexes {
  my ($x, $y) = @_;
  if ($x % 2) {
    return ([0, -2],
	    [-2, -1], [-1, -1], [0, -1], [1, -1], [2, -1],
	    [-2,  0], [-1,  0], [0,  0], [1,  0], [2,  0],
	    [-2,  1], [-1,  1], [0,  1], [1,  1], [2,  1],
	    [-1,  2], [0,  2], [1,  2]);
  } else {
    return ([-1, -2], [0, -2], [1, -2],
	    [-2, -1], [-1, -1], [0, -1], [1, -1], [2, -1],
	    [-2,  0], [-1,  0], [0,  0], [1,  0], [2,  0],
            [-2,  1], [-1,  1], [0,  1], [1,  1], [2,  1],
	    [0,  2]);
  }
}

sub half_hexes {
  my ($x, $y) = @_;
  if ($x % 2) {
    return ([-2, -2], [-1, -2], [1, -2], [2, -2],
	    [-3,  0], [3,  0],
	    [-3,  1], [3,  1],
	    [-2,  2], [2,  2],
	    [-1,  3], [1,  3]);
  } else {
    return ([-1, -3], [1, -3],
	    [-2, -2], [2, -2],
	    [-3, -1], [3, -1],
	    [-3,  0], [3,  0],
	    [-2,  2], [-1,  2], [1,  2], [2,  2]);
  }
}

sub generate_region {
  my ($x, $y, $primary) = @_;
  $world{Game::TextMapper::Point::coord($x, $y)} = one($primary{$primary});

  my @region = full_hexes($x, $y);
  my $terrain;

  for (1..9) {
    my $coordinates = pick_unassigned($x, $y, @region);
    $terrain = one($primary{$primary});
    $log->debug(" primary   $coordinates => $terrain");
    $world{$coordinates} = $terrain;
  }

  for (1..6) {
    my $coordinates = pick_unassigned($x, $y, @region);
    $terrain =  one($secondary{$primary});
    $log->debug(" secondary $coordinates => $terrain");
    $world{$coordinates} = $terrain;
  }

  for my $coordinates (pick_remaining($x, $y, @region)) {
    if (rand > 0.1) {
      $terrain = one($tertiary{$primary});
      $log->debug(" tertiary  $coordinates => $terrain");
    } else {
      $terrain = one($wildcard{$primary});
      $log->debug(" wildcard  $coordinates => $terrain");
    }
    $world{$coordinates} = $terrain;
  }

  for my $coordinates (pick_remaining($x, $y, half_hexes($x, $y))) {
    my $random = rand 6;
    if ($random < 3) {
      $terrain = one($primary{$primary});
      $log->debug("  halfhex primary   $coordinates => $terrain");
    } elsif ($random < 5) {
      $terrain = one($secondary{$primary});
      $log->debug("  halfhex secondary $coordinates => $terrain");
    } else {
      $terrain = one($tertiary{$primary});
      $log->debug("  halfhex tertiary  $coordinates => $terrain");
    }
    $world{$coordinates} = $terrain;
  }
}

sub seed_region {
  my ($seeds, $terrain) = @_;
  my $terrain_above;
  for my $hex (@$seeds) {
    $log->debug("seed_region (" . $hex->[0] . "," . $hex->[1] . ") with $terrain");
    generate_region($hex->[0], $hex->[1], $terrain);
    populate_region($hex, $terrain);
    my $random = rand 12;
    # pick next terrain based on the previous one (to the left); or the one
    # above if in the first column
    my $next;
    $terrain = $terrain_above if $hex->[0] == 1 and $terrain_above;
    if ($random < 6) {
      $next = one($primary{$terrain});
      $log->debug("picked primary $next");
    } elsif ($random < 9) {
      $next = one($secondary{$terrain});
      $log->debug("picked secondary $next");
    } elsif ($random < 11) {
      $next = one($tertiary{$terrain});
      $log->debug("picked tertiary $next");
    } else {
      $next = one($wildcard{$terrain});
      $log->debug("picked wildcard $next");
    }
    $terrain_above = $terrain if $hex->[0] == 1;
    die "Terrain lacks reverse_lookup: $next\n" unless $reverse_lookup{$next};
    $terrain = $reverse_lookup{$next};
  }
}

sub agriculture {
  for my $hex (@needs_fields) {
    $log->debug("looking to plant fields near " . Game::TextMapper::Point::coord($hex->[0], $hex->[1]));
    my $delta = [[[-1,  0], [ 0, -1], [+1,  0], [+1, +1], [ 0, +1], [-1, +1]],  # x is even
		 [[-1, -1], [ 0, -1], [+1, -1], [+1,  0], [ 0, +1], [-1,  0]]]; # x is odd
    my @plains;
    for my $i (0 .. 5) {
      my ($x, $y) = ($hex->[0] + $delta->[$hex->[0] % 2]->[$i]->[0],
		     $hex->[1] + $delta->[$hex->[0] % 2]->[$i]->[1]);
      my $coordinates = Game::TextMapper::Point::coord($x, $y);
      if ($world{$coordinates}) {
	my ($color, $terrain) = split(' ', $world{$coordinates}, 2);
	$log->debug("  $coordinates is " . $world{$coordinates} . " ie. " . $reverse_lookup{$world{$coordinates}});
	if ($reverse_lookup{$world{$coordinates}} eq 'plains') {
	  $log->debug("   $coordinates is a candidate");
	  push(@plains, $coordinates);
	}
      }
    }
    next unless @plains;
    my $target = one(@plains);
    $world{$target} = one('light-soil fields', 'soil fields');
    $log->debug(" $target planted with " . $world{$target});
  }
}

=head2 generate_map WIDTH, HEIGHT, BW

WIDTH and HEIGHT default to 20×10.

BW stands for "black & white", i.e. a true value skips background colours.

=cut

sub generate_map {
  my ($self, $width, $height, $bw) = @_;
  $width = 20 if not defined $width or $width < 1 or $width > 100;
  $height = 10 if not defined $height or $height < 1 or $height > 100;

  my $seeds;
  for (my $y = 1; $y < $height + 3; $y += 5) {
    for (my $x = 1; $x < $width + 3; $x += 5) {
      # [1,1] [6,3], [11,1], [16,3]
      my $y0 = $y + int(($x % 10) / 3);
      push(@$seeds, [$x, $y0]);
    }
  }

  %world = (); # reinitialize!

  my @seed_terrain = keys %primary;
  seed_region($seeds, one(@seed_terrain));
  agriculture();

  # delete extra hexes we generated to fill the gaps
  for my $coordinates (keys %world) {
    $coordinates =~ /(-?\d\d)(-?\d\d)/;
    delete $world{$coordinates} if $1 < 1 or $2 < 1;
    delete $world{$coordinates} if $1 > $width or $2 > $height;
  }
  if ($bw) {
    for my $coordinates (keys %world) {
      my ($color, $rest) = split(' ', $world{$coordinates}, 2);
      if ($rest) {
	$world{$coordinates} = $rest;
      } else {
	delete $world{$coordinates};
      }
    }
  }

  return join("\n", map { $_ . " " . $world{$_} } sort keys %world) . "\n"
    . "include gnomeyland.txt\n";
}

=head1 SEE ALSO

Erin D. Smale described this algorithm in two famous blog posts:
L<http://www.welshpiper.com/hex-based-campaign-design-part-1/> and
L<http://www.welshpiper.com/hex-based-campaign-design-part-2/>.

The map itself uses the I<Gnomeyland> icons by Gregory B. MacKenzie. These are
licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
To view a copy of this license, visit
L<http://creativecommons.org/licenses/by-sa/3.0/>.

=cut

1;
