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

Game::TextMapper::Gridmapper - generate dungeon maps

=head1 DESCRIPTION

This generates dungeon maps. At its core, this uses a 3×3 layout, 9 sections
total. 5 or 7 of these 9 sections get a room. The connections for the rooms (the
"shape") is picked at random from a fixed list of configurations (plus flipped
and rotated variants). The first room contains the stairs.

To generate bigger dungeons, more of these 3×3 layouts are added to the first.
As the number of rooms is dynamic, the algorithm figures out how to best use a
number of layouts containing 5 or 7 rooms to get to that number, and then simply
drops the extra rooms.

=head1 METHODS

=cut

package Game::TextMapper::Gridmapper;
use Game::TextMapper::Log;
use Game::TextMapper::Constants qw($dx $dy);
use Modern::Perl '2018';
use List::Util qw'shuffle none any min max all';
use List::MoreUtils qw'pairwise';
use Mojo::Util qw(url_escape);
use Mojo::Base -base;

my $log = Game::TextMapper::Log->get;

# This is the meta grid for the geomorphs. Normally this is (3,3) for simple
# dungeons. We need to recompute these when smashing geomorphs together.
has 'dungeon_dimensions';
has 'dungeon_geomorph_size';

# This is the grid for a particular geomorph. This is space for actual tiles.
has 'room_dimensions';

# Rows and columns, for the tiles. Add two tiles for the edges, so the first
# two rows and the last two rows, and the first two columns and the last two
# columns should be empty. This is the empty space where stairs can be added.
# (0,0) starts at the top left and goes rows before columns, like text. Max
# tiles is the maximum number of tiles. We need to recompute these values when
# smashing two geomorphs together.
has 'row';
has 'col';
has 'max_tiles';

sub init {
  my $self = shift;
  $self->dungeon_geomorph_size(3);   # this stays the same
  $self->dungeon_dimensions([3, 3]); # this will change
  $self->room_dimensions([5, 5]);
  $self->recompute();
}

sub recompute {
  my $self = shift;
  $self->row($self->dungeon_dimensions->[0]
	     * $self->room_dimensions->[0]
	     + 4);
  $self->col($self->dungeon_dimensions->[1]
	     * $self->room_dimensions->[1]
	     + 4);
  $self->max_tiles($self->row * $self->col - 1);
}

=head2 generate_map($pillars, $n, $caves)

If C<$pillars> is true, then rooms with pillars are generated. This is usually a
good idea. It's harder to pull off from I<Hex Describe> because the description
of the dungeon should mention the pillars but there's now way to do that.
Perhaps, if C<$pillars> were to be a reference of room numbers with pillars, it
might work; right now, however, it's simply a boolean value.

C<$n> is number of rooms.

If C<$caves> is true, then the entire map uses cave walls instead of regular
walls.

=cut

sub generate_map {
  my $self = shift;
  my $pillars = shift;
  my $n = shift;
  my $caves = shift;
  $self->init;
  my $rooms = [map { $self->generate_room($_, $pillars, $caves) } (1 .. $n)];
  my ($shape, $stairs) = $self->shape(scalar(@$rooms));
  my $tiles = $self->add_rooms($rooms, $shape);
  $tiles = $self->add_corridors($tiles, $shape);
  $tiles = $self->add_doors($tiles) unless $caves;
  $tiles = $self->add_stair($tiles, $stairs) unless $caves;
  $tiles = $self->add_small_stair($tiles, $stairs) if $caves;
  $tiles = $self->fix_corners($tiles);
  $tiles = $self->fix_pillars($tiles) if $pillars;
  $tiles = $self->to_rocks($tiles) if $caves;
  return $self->to_text($tiles);
}

sub generate_room {
  my $self = shift;
  my $num = shift;
  my $pillars = shift;
  my $caves = shift;
  my $r = rand();
  if ($r < 0.9) {
    return $self->generate_random_room($num);
  } elsif ($r < 0.95 and $pillars or $caves) {
    return $self->generate_pillar_room($num);
  } else {
    return $self->generate_fancy_corner_room($num);
  }
}

sub generate_random_room {
  my $self = shift;
  my $num = shift;
  # generate the tiles necessary for a single geomorph
  my @tiles;
  my @dimensions = (2 + int(rand(3)), 2 + int(rand(3)));
  my @start = pairwise { int(rand($b - $a)) } @dimensions, @{$self->room_dimensions};
  # $log->debug("New room starting at (@start) for dimensions (@dimensions)");
  for my $x ($start[0] .. $start[0] + $dimensions[0] - 1) {
    for my $y ($start[1] .. $start[1] + $dimensions[1] - 1) {
      $tiles[$x + $y * $self->room_dimensions->[0]] = ["empty"];
    }
  }
  my $x = $start[0] + int($dimensions[0]/2);
  my $y = $start[1] + int($dimensions[1]/2);
  push(@{$tiles[$x + $y * $self->room_dimensions->[0]]}, "\"$num\"");
  return \@tiles;
}

sub generate_fancy_corner_room {
  my $self = shift;
  my $num = shift;
  my @tiles;
  my @dimensions = (3 + int(rand(2)), 3 + int(rand(2)));
  my @start = pairwise { int(rand($b - $a)) } @dimensions, @{$self->room_dimensions};
  # $log->debug("New room starting at (@start) for dimensions (@dimensions)");
  for my $x ($start[0] .. $start[0] + $dimensions[0] - 1) {
    for my $y ($start[1] .. $start[1] + $dimensions[1] - 1) {
      push(@{$tiles[$x + $y * $self->room_dimensions->[0]]}, "empty");
      # $log->debug("$x $y @{$tiles[$x + $y * $self->room_dimensions->[0]]}");
    }
  }
  my $type = rand() < 0.5 ? "arc" : "diagonal";
  $tiles[$start[0] + $start[1] * $self->room_dimensions->[0]] = ["$type-se"];
  $tiles[$start[0] + $dimensions[0] + $start[1] * $self->room_dimensions->[0] -1] = ["$type-sw"];
  $tiles[$start[0] + ($start[1] + $dimensions[1] - 1) * $self->room_dimensions->[0]] = ["$type-ne"];
  $tiles[$start[0] + $dimensions[0] + ($start[1] + $dimensions[1] - 1) * $self->room_dimensions->[0] - 1] = ["$type-nw"];
  my $x = $start[0] + int($dimensions[0]/2);
  my $y = $start[1] + int($dimensions[1]/2);
  push(@{$tiles[$x + $y * $self->room_dimensions->[0]]}, "\"$num\"");
  return \@tiles;
}

sub generate_pillar_room {
  my $self = shift;
  my $num = shift;
  my @tiles;
  my @dimensions = (3 + int(rand(2)), 3 + int(rand(2)));
  my @start = pairwise { int(rand($b - $a)) } @dimensions, @{$self->room_dimensions};
  # $log->debug("New room starting at (@start) for dimensions (@dimensions)");
  my $type = "|";
  for my $x ($start[0] .. $start[0] + $dimensions[0] - 1) {
    for my $y ($start[1] .. $start[1] + $dimensions[1] - 1) {
      if ($type eq "|" and ($x == $start[0] or $x == $start[0] + $dimensions[0] - 1)
	  or $type eq "-" and ($y == $start[1] or $y == $start[1] + $dimensions[1] - 1)) {
	push(@{$tiles[$x + $y * $self->room_dimensions->[0]]}, "pillar");
      } else {
	push(@{$tiles[$x + $y * $self->room_dimensions->[0]]}, "empty");
	# $log->debug("$x $y @{$tiles[$x + $y * $self->room_dimensions->[0]]}");
      }
    }
  }
  my $x = $start[0] + int($dimensions[0]/2);
  my $y = $start[1] + int($dimensions[1]/2);
  push(@{$tiles[$x + $y * $self->room_dimensions->[0]]}, "\"$num\"");
  return \@tiles;
}

sub one {
  return $_[int(rand(scalar @_))];
}

=head1 LAYOUT

One of the shapes is picked, and then flipped and rotated to generate more
shapes. This is why we can skip any shape that is a flipped and/or rotated
version of an existing shape.

=head2 5 Room Dungeons

These are inspired by L<The Nine Forms of the Five Room
Dungeon|https://gnomestew.com/the-nine-forms-of-the-five-room-dungeon/> by
Matthew J. Neagley, for Gnome Stew.

=cut

sub five_room_shape {
  my $self = shift;
  my @shapes;

=head3 The Railroad

          5        5     4--5         5--4
          |        |     |               |
          4     3--4     3       5--4    3
          |     |        |          |    |
    1--2--3  1--2     1--2    1--2--3 1--2

=cut

  push(@shapes,
       [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0]],
       [[0, 2], [1, 2], [1, 1], [2, 1], [2, 0]],
       [[0, 2], [1, 2], [1, 1], [1, 0], [2, 0]],
       [[0, 2], [1, 2], [2, 2], [2, 1], [1, 1]],
       [[0, 2], [1, 2], [1, 1], [1, 0], [0, 0]]);

=head3 Foglio's Snail

       5  4
       |  |
    1--2--3

=cut

  # Note how whenever there is a non-linear connection, there is a an extra
  # element pointing to the "parent". This is necessary for all but the
  # railroads.
  push(@shapes,
       [[0, 2], [1, 2], [2, 2], [2, 1], [1, 1, 1]]);

=head3 The Fauchard Fork

       5       5
       |       |
       3--4 4--3 5--3--4
       |       |    |
    1--2    1--2 1--2

=cut

  push(@shapes,
       [[0, 2], [1, 2], [1, 1], [2, 1], [1, 0, 2]],
       [[0, 2], [1, 2], [1, 1], [0, 1], [1, 0, 2]],
       [[0, 2], [1, 2], [1, 1], [2, 1], [0, 1, 2]]);

=head3 The Moose

               4
               |
    5     4 5  3
    |     | |  |
    1--2--3 1--2

=cut

  push(@shapes,
       [[0, 2], [1, 2], [2, 2], [2, 1], [0, 1, 0]],
       [[0, 2], [1, 2], [1, 1], [1, 0], [0, 1, 0]]);

=head3 The Paw

       5
       |
    3--2--4
       |
       1

=cut

  push(@shapes,
       [[1, 2], [1, 1], [0, 1], [2, 1, 1], [1, 0, 1]]);

=head3 The Arrow

       3
       |
       2
       |
    5--1--4

=cut

  push(@shapes,
       [[1, 2], [1, 1], [1, 0], [2, 2, 0], [0, 2, 0]]);

=head3 The Cross

       5
       |
    3--1--4
       |
       2

=cut

  push(@shapes,
       [[1, 1], [1, 2], [0, 1, 0], [2, 1, 0], [1, 0, 0]]);

=head3 The Nose Ring

       5--4  2--3--4
       |  |  |  |
    1--2--3  1--5

=cut

  push(@shapes,
       [[0, 2], [1, 2], [2, 2], [2, 1], [1, 1, 1, 3]],
       [[0, 2], [0, 1], [1, 1], [2, 1], [1, 2, 0, 2]]);

  return $self->shape_flip(one(@shapes));
}

=head2 7 Room Dungeons

High room density is a desirable property, so we can fill the 9 sections of the
3×3 base layout with more than just five rooms. The algorithm uses 7 room
shapes in addition to the five room shapes.

=cut

sub seven_room_shape {
  my $self = shift;
  my @shapes;

=head3 The Snake

    7--6--5  7--6--5     4--5 7
          |        |     |  | |
          4     3--4     3  6 6--5--4
          |     |        |  |       |
    1--2--3  1--2     1--2  7 1--2--3

=cut

  push(@shapes,
    [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [1, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 0], [1, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [1, 0], [2, 0], [2, 1], [2, 2]],
    [[0, 2], [1, 2], [2, 2], [2, 1], [1, 1] ,[0, 1], [0, 0]]);

=head3 The Fork

       7  5 7     5 7-----5
       |  | |     | |     |
       6  4 6     4 6     4
       |  | |     | |     |
    1--2--3 1--2--3 1--2--3

=cut

  # Note how whenever there is a non-linear connection, there is a an extra
  # element pointing to the "parent". This is necessary for all but the
  # railroads.

  push(@shapes,
    [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [1, 1, 1], [1, 0]],
    [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [0, 1, 0], [0, 0]],
    [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [0, 1, 0], [0, 0, 5, 4]]);

=head3 The Sidequest

    6--5       5--6 7     5 6--5       5--6 7     5
    |  |       |  | |     | |  |       |  | |     |
    7  3--4 4--3  7 6--3--4 7  3--4 4--3  7 6--3--4
       |       |       |    |  |    |  |    |  |
    1--2    1--2    1--2    1--2    1--2    1--2

=cut

  push(@shapes,
    [[0, 2], [1, 2], [1, 1], [2, 1], [1, 0, 2], [0, 0], [0, 1]],
    [[0, 2], [1, 2], [1, 1], [0, 1], [1, 0, 2], [2, 0], [2, 1]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 0], [0, 1, 2], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [1, 0, 2], [0, 0], [0, 1, 5, 0]],
    [[0, 2], [1, 2], [1, 1], [0, 1, 2, 0], [1, 0, 2], [2, 0], [2, 1]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 0], [0, 1, 2, 0], [0, 0]]);

=head3 The Unbalanced Fork

    7     5 7  4--5 7     5 7        7  4--5 7     5 7
    |     | |  |    |     | |        |  |    |     | |
    6     4 6  3    6  3--4 6  3--4  6--3    6--3--4 6--3--4
    |     | |  |    |  |    |  |  |  |  |    |  |    |  |  |
    1--2--3 1--2    1--2    1--2  5  1--2    1--2    1--2  5

=cut

  push(@shapes,
    [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [0, 1, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [1, 0], [2, 0], [0, 1, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 0], [0, 1, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 2], [0, 1, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [1, 0], [2, 0], [0, 1, 2, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 0], [0, 1, 2, 0], [0, 0]],
    [[0, 2], [1, 2], [1, 1], [2, 1], [2, 2], [0, 1, 2, 0], [0, 0]]);

=head3 The Triplet

    4  5  7     5  7     5     4--5  7     5  7     5
    |  |  |     |  |     |     |  |  |     |  |     |
    3--2--6  3--2--6  3--2--6  3--2--6  3--2--6  3--2--6
       |     |  |     |  |  |     |     |  |     |  |  |
       1     4  1     4  1  7     1     4--1     4--1  7

=cut

  push(@shapes,
    [[1, 2], [1, 1], [0, 1], [0, 0], [1, 0, 1], [2, 1, 1], [2, 0]],
    [[1, 2], [1, 1], [0, 1], [0, 2], [1, 0, 1], [2, 1, 1], [2, 0]],
    [[1, 2], [1, 1], [0, 1], [0, 2], [1, 0, 1], [2, 1, 1], [2, 2]],
    [[1, 2], [1, 1], [0, 1], [0, 0], [1, 0, 1, 3], [2, 1, 1], [2, 0]],
    [[1, 2], [1, 1], [0, 1], [0, 2, 2, 0], [1, 0, 1], [2, 1, 1], [2, 0]],
    [[1, 2], [1, 1], [0, 1], [0, 2, 2, 0], [1, 0, 1], [2, 1, 1], [2, 2]]);

=head3 The Fake Fork

    7  3    7        7  3    7
    |  |    |        |  |    |
    6  2    6  2--3  6--2    6--2--3
    |  |    |  |     |  |    |  |
    5--1--4 5--1--4  5--1--4 5--1--4

=cut

  push(@shapes,
    [[1, 2], [1, 1], [1, 0], [2, 2, 0], [0, 2, 0], [0, 1], [0, 0]],
    [[1, 2], [1, 1], [2, 1], [2, 2, 0], [0, 2, 0], [0, 1], [0, 0]],
    [[1, 2], [1, 1], [1, 0], [2, 2, 0], [0, 2, 0], [0, 1, 4, 1], [0, 0]],
    [[1, 2], [1, 1], [2, 1], [2, 2, 0], [0, 2, 0], [0, 1, 4, 1], [0, 0]]);

=head3 The Shuriken

    5  6--7  5  6--7  5--6    5--6--7  5--6--7  5--6
    |  |     |  |     |       |  |     |  |     |
    4--1     4--1     4--1--7 4--1     4--1     4--1--7
       |        |        |       |        |     |  |
    3--2        2--3  3--2    3--2        2--3  3--2

=cut

  push(@shapes,
    [[1, 1], [1, 2], [0, 2], [0, 1, 0], [0, 0], [1, 0, 0], [2, 0]],
    [[1, 1], [1, 2], [2, 2], [0, 1, 0], [0, 0], [1, 0, 0], [2, 0]],
    [[1, 1], [1, 2], [0, 2], [0, 1, 0], [0, 0], [1, 0], [2, 1, 0]],
    [[1, 1], [1, 2], [0, 2], [0, 1, 0], [0, 0], [1, 0, 4, 0], [2, 0]],
    [[1, 1], [1, 2], [2, 2], [0, 1, 0], [0, 0], [1, 0, 4, 0], [2, 0]],
    [[1, 1], [1, 2], [0, 2], [0, 1, 2, 0], [0, 0], [1, 0], [2, 1, 0]]);

=head3 The Noose

       6--5  3--4     3--4
       |  |  |  |     |  |
       7  4  2  5     2  5--7
       |  |  |  |     |  |
    1--2--3  1--6--7  1--6

=cut

  push(@shapes,
    [[0, 2], [1, 2], [2, 2], [2, 1], [2, 0], [1, 0], [1, 1, 1, 5]],
    [[0, 2], [0, 1], [0, 0], [1, 0], [1, 1], [1, 2, 0, 4], [2, 2, 5]],
    [[0, 2], [0, 1], [0, 0], [1, 0], [1, 1], [1, 2, 0, 4], [2, 1, 4]]);

  return $self->shape_flip(one(@shapes));
}

sub shape_flip {
  my $self = shift;
  my $shape = shift;
  my $r = rand;
  # in case we are debugging
  # $r = 1;
  if ($r < 0.20) {
    # flip vertically
    $shape = [map{ $_->[1] = $self->dungeon_dimensions->[1] - 1 - $_->[1]; $_ } @$shape];
    # $log->debug("flip vertically: " . join(", ", map { "[@$_]"} @$shape));
  } elsif ($r < 0.4) {
    # flip horizontally
    $shape = [map{ $_->[0] = $self->dungeon_dimensions->[0] - 1 - $_->[0]; $_ } @$shape];
    # $log->debug("flip horizontally: " . join(", ", map { "[@$_]"} @$shape));
  } elsif ($r < 0.6) {
    # flip diagonally
    $shape = [map{ my $t = $_->[1]; $_->[1] = $_->[0]; $_->[0] = $t; $_ } @$shape];
    # $log->debug("flip diagonally: " . join(", ", map { "[@$_]"} @$shape));
  } elsif ($r < 0.8) {
    # flip diagonally
    $shape = [map{ $_->[0] = $self->dungeon_dimensions->[0] - 1 - $_->[0];
		   $_->[1] = $self->dungeon_dimensions->[1] - 1 - $_->[1];
		   $_ } @$shape];
    # $log->debug("flip both: " . join(", ", map { "[@$_]"} @$shape));
  }
  return $shape;
}

sub shape_merge {
  my $self = shift;
  my @shapes = @_;
  my $result = [];
  my $cols = POSIX::ceil(sqrt(@shapes));
  my $shift = [0, 0];
  my $rooms = 0;
  for my $shape (@shapes) {
    # $log->debug(join(" ", "Shape", map { "[@$_]" } @$shape));
    my $n = @$shape;
    # $log->debug("Number of rooms for this shape is $n");
    # $log->debug("Increasing coordinates by ($shift->[0], $shift->[1])");
    for my $room (@$shape) {
      $room->[0] += $shift->[0] * $self->dungeon_geomorph_size;
      $room->[1] += $shift->[1] * $self->dungeon_geomorph_size;
      for my $i (2 .. $#$room) {
	# $log->debug("Increasing room reference $i ($room->[$i]) by $rooms");
	$room->[$i] += $rooms;
      }
      push(@$result, $room);
    }
    $self->shape_reconnect($result, $n) if $n < @$result;
    if ($shift->[0] == $cols -1) {
      $shift = [0, $shift->[1] + 1];
    } else {
      $shift = [$shift->[0] + 1, $shift->[1]];
    }
    $rooms += $n;
  }
  # Update globals
  for my $dim (0, 1) {
    $self->dungeon_dimensions->[$dim] = max(map { $_->[$dim] } @$result) + 1;
  }
  # $log->debug("Dimensions of the dungeon are (" . join(", ", map { $self->dungeon_dimensions->[$_] } 0, 1) . ")");
  $self->recompute();
  return $result;
}

sub shape_reconnect {
  my ($self, $result, $n) = @_;
  my $rooms = @$result;
  my $first = $rooms - $n;
  # Disconnect the old room by adding an invalid self-reference to the first
  # room of the last shape added; if there are just two numbers there, it would
  # otherwise mean that the first room of the new shape connects to the last
  # room of the previous shape and that is wrong.
  # $log->debug("First of the shape is @{$result->[$first]}");
  push(@{$result->[$first]}, $first) if @{$result->[$first]} == 2;
  # New connections can be either up or left, therefore only the rooms within
  # this shape that are at the left or the upper edge need to be considered.
  my @up_candidates;
  my @left_candidates;
  my $min_up;
  my $min_left;
  for my $start ($first .. $rooms - 1) {
    my $x = $result->[$start]->[0];
    my $y = $result->[$start]->[1];
    # Check up: if we find a room in our set, this room is disqualified; if we
    # find another room, record the distance, and the destination.
    for my $end (0 .. $first - 1) {
      next if $start == $end;
      next if $result->[$end]->[0] != $x;
      my $d = $y - $result->[$end]->[1];
      next if $min_up and $d > $min_up;
      if (not $min_up or $d < $min_up) {
	# $log->debug("$d for $start → $end is smaller than $min_up: ") if defined $min_up;
	$min_up = $d;
	@up_candidates = ([$start, $end]);
      } else {
	# $log->debug("$d for $start → $end is the same as $min_up");
	push(@up_candidates, [$start, $end]);
      }
    }
    # Check left: if we find a room in our set, this room is disqualified; if we
    # find another room, record the distance, and the destination.
    for my $end (0 .. $first - 1) {
      next if $start == $end;
      next if $result->[$end]->[1] != $y;
      my $d = $x - $result->[$end]->[0];
      next if $min_left and $d > $min_left;
      if (not $min_left or $d < $min_left) {
	$min_left = $d;
	@left_candidates = ([$start, $end]);
      } else {
	push(@left_candidates, [$start, $end]);
      }
    }
  }
  # $log->debug("up candidates: " . join(", ", map { join(" → ", map { $_ < 10 ? $_ : chr(55 + $_) } @$_) } @up_candidates));
  # $log->debug("left candidates: " . join(", ", map { join(" → ", map { $_ < 10 ? $_ : chr(55 + $_) } @$_) } @left_candidates));
  for (one(@up_candidates), one(@left_candidates)) {
    next unless $_;
    # $log->debug("Connecting " . join(" → ", map { $_ < 10 ? $_ : chr(55 + $_) } @$_));
    my ($start, $end) = @$_;
    if (@{$result->[$start]} == 3 and $result->[$start]->[2] == $start) {
      # remove the fake connection if there is one
      pop(@{$result->[$start]});
    } else {
      # connecting to the previous room (otherwise the new connection replaces
      # the implicit connection to the previous room)
      push(@{$result->[$start]}, $start - 1);
    }
    # connect to the new one
    push(@{$result->[$start]}, $end);
  }
}

sub debug_shapes {
  my $self = shift;
  my $shapes = shift;
  my $map = [map { [ map { "  " } 0 .. $self->dungeon_dimensions->[0] - 1] } 0 .. $self->dungeon_dimensions->[1] - 1];
  $log->debug(join(" ", "  ", map { sprintf("%2x", $_) } 0 .. $self->dungeon_dimensions->[0] - 1));
  for my $n (0 .. $#$shapes) {
    my $shape = $shapes->[$n];
    $map->[ $shape->[1] ]->[ $shape->[0] ] = sprintf("%2x", $n);
  }
  for my $y (0 .. $self->dungeon_dimensions->[1] - 1) {
    $log->debug(join(" ", sprintf("%2x", $y), @{$map->[$y]}));
  }
}

sub shape {
  my $self = shift;
  # note which rooms get stairs (identified by label!)
  my $stairs;
  # return an array of deltas to shift rooms around
  my $num = shift;
  my $shape = [];
  # attempt to factor into 5 and 7 rooms
  my $sevens = int($num/7);
  my $rest = $num - 7 * $sevens; # $num % 7
  while ($sevens > 0 and $rest % 5) {
    $sevens--;
    $rest = $num - 7 * $sevens;
  }
  my $fives = POSIX::ceil($rest/5);
  my @sequence = shuffle((5) x $fives, (7) x $sevens);
  @sequence = (5) unless @sequence;
  $shape = $self->shape_merge(map { $_ == 5 ? $self->five_room_shape() : $self->seven_room_shape() } @sequence);
  for (my $n = 0; @sequence; $n += shift(@sequence)) {
    push(@$stairs, $n + 1);
  }
  $log->debug(join(" ", "Stairs", @$stairs));
  if (@$stairs > 2) {
    @$stairs = shuffle(@$stairs);
    my $n = POSIX::floor(log($#$stairs));
    @$stairs = @$stairs[0 .. $n];
  }
  $self->debug_shapes($shape) if $log->level eq 'debug';
  $log->debug(join(", ", map { "[@$_]"} @$shape));
  die("No appropriate dungeon shape found for $num rooms") unless @$shape;
  return $shape, $stairs;
}

sub debug_tiles {
  my $self = shift;
  my $tiles = shift;
  my $i = 0;
  $log->debug(
    join('', " " x 5,
	 map {
	   sprintf("% " . $self->room_dimensions->[0] . "d", $_ * $self->room_dimensions->[0])
	 } 1 .. $self->dungeon_dimensions->[0]));
  while ($i < @$tiles) {
    $log->debug(
      sprintf("%4d ", $i)
      . join('', map { $_ ? "X" : " " } @$tiles[$i .. $i + $self->row - 1]));
    $i += $self->row;
  }
}

sub add_rooms {
  my $self = shift;
  # Get the rooms and the deltas, draw it all on a big grid. Don't forget the
  # two-tile border around it all.
  my $rooms = shift;
  my $deltas = shift;
  my @tiles;
  pairwise {
    my $room = $a;
    my $delta = $b;
    # $log->debug("Draw room shifted by delta (@$delta)");
    # copy the room, shifted appropriately
    for my $x (0 .. $self->room_dimensions->[0] - 1) {
      for my $y (0 .. $self->room_dimensions->[0] - 1) {
	# my $v =
	$tiles[$x + $delta->[0] * $self->room_dimensions->[0] + 2
	       + ($y + $delta->[1] * $self->room_dimensions->[1] + 2)
	       * $self->row]
	    = $room->[$x + $y * $self->room_dimensions->[0]];
      }
    }
  } @$rooms, @$deltas;
  # $self->debug_tiles(\@tiles) if $log->level eq 'debug';
  return \@tiles;
}

sub add_corridors {
  my $self = shift;
  my $tiles = shift;
  my $shapes = shift;    # reference to the original
  my @shapes = @$shapes; # a copy that gets shorter
  my $from = shift(@shapes);
  my $delta;
  for my $to (@shapes) {
    if (@$to == 3
	and $to->[0] == $shapes->[$to->[2]]->[0]
	and $to->[1] == $shapes->[$to->[2]]->[1]) {
      # If the preceding shape is pointing to ourselves, then this room is
      # disconnected: don't add a corridor.
      # $log->debug("No corridor from @$from to @$to");
      $from = $to;
    } elsif (@$to == 2) {
      # The default case is that the preceding shape is our parent. A simple
      # railroad!
      # $log->debug("Regular from @$from to @$to");
      $tiles = $self->add_corridor($tiles, $from, $to, $self->get_delta($from, $to));
      $from = $to;
    } else {
      # In case the shapes are not connected in order, the parent shapes are
      # available as extra elements.
      for my $from (map { $shapes->[$_] } @$to[2 .. $#$to]) {
	# $log->debug("Branch from @$from to @$to");
	$tiles = $self->add_corridor($tiles, $from, $to, $self->get_delta($from, $to));
      }
      $from = $to;
    }
  }
  $self->debug_tiles($tiles) if $log->level eq 'debug';
  return $tiles;
}

sub get_delta {
  my $self = shift;
  my $from = shift;
  my $to = shift;
  # Direction: north is minus an entire row, south is plus an entire row, east
  # is plus one, west is minus one. Return an array reference with three
  # elements: how to get the next element and how to get the two elements to the
  # left and right.
  if ($to->[0] < $from->[0]) {
    # $log->debug("west");
    return [-1, - $self->row, $self->row];
  } elsif ($to->[0] > $from->[0]) {
    # $log->debug("east");
    return [1, - $self->row, $self->row];
  } elsif ($to->[1] < $from->[1]) {
    # $log->debug("north");
    return [- $self->row, 1, -1];
  } elsif ($to->[1] > $from->[1]) {
    # $log->debug("south");
    return [$self->row, 1, -1];
  } else {
    $log->warn("unclear direction: bogus shape?");
  }
}

sub position_in {
  my $self = shift;
  # Return a position in the big array corresponding to the midpoint in a room.
  # Don't forget the two-tile border.
  my $delta = shift;
  my $x = int($self->room_dimensions->[0]/2) + 2;
  my $y = int($self->room_dimensions->[1]/2) + 2;
  return $x + $delta->[0] * $self->room_dimensions->[0]
      + ($y + $delta->[1] * $self->room_dimensions->[1]) * $self->row;
}

sub add_corridor {
  my $self = shift;
  # In the example below, we're going east from F to T. In order to make sure
  # that we also connect rooms in (0,0)-(1,1), we start one step earlier (1,2)
  # and end one step later (8,2).
  #
  #  0123456789
  # 0
  # 1
  # 2  F    T
  # 3
  # 4
  my $tiles = shift;
  my $from = shift;
  my $to = shift;
  # $log->debug("Drawing a corridor [@$from]-[@$to]");
  # Delta has three elements: forward, left and right indexes.
  my $delta = shift;
  # Convert $from and $to to indexes into the tiles array.
  $from = $self->position_in($from) - 2 * $delta->[0];
  $to = $self->position_in($to) + 2 * $delta->[0];
  my $n = 0;
  my $contact = 0;
  my $started = 0;
  my @undo;
  # $log->debug("Drawing a corridor $from-$to");
  while (not grep { $to == ($from + $_) } @$delta) {
    $from += $delta->[0];
    # contact is if we're on a room, or to the left or right of a room (but not in front of a room)
    $contact = any { $self->something($tiles, $from, $_) } 0, $delta->[1], $delta->[2];
    if ($contact) {
      $started = 1;
      @undo = ();
    } else {
      push(@undo, $from);
    }
    $tiles->[$from] = ["empty"] if $started and not $tiles->[$from];
    last if $n++ > 20; # safety!
  }
  for (@undo) {
    $tiles->[$_] = undef;
  }
  return $tiles;
}

sub add_doors {
  my $self = shift;
  my $tiles = shift;
  # Doors can be any tile that has three or four neighbours, including
  # diagonally:
  #
  # ▓▓   ▓▓
  # ▓▓▒▓ ▓▓▒▓
  #      ▓▓
  my @types = qw(door door door door door door secret secret archway concealed);
  # first two neighbours must be clear, the next two must be set, and one of the others must be set as well
  my %test = (n => [-1, 1, -$self->row, $self->row, -$self->row + 1, -$self->row - 1],
	      e => [-$self->row, $self->row, -1, 1, $self->row + 1, -$self->row + 1],
	      s => [-1, 1, -$self->row, $self->row, $self->row + 1, $self->row - 1],
	      w => [-$self->row, $self->row, -1, 1, $self->row - 1, -$self->row - 1]);
  my @doors;
  for my $here (shuffle 1 .. scalar(@$tiles) - 1) {
    for my $dir (shuffle qw(n e s w)) {
      if ($tiles->[$here]
	  and not $self->something($tiles, $here, $test{$dir}->[0])
	  and not $self->something($tiles, $here, $test{$dir}->[1])
	  and $self->something($tiles, $here, $test{$dir}->[2])
	  and $self->something($tiles, $here, $test{$dir}->[3])
	  and ($self->something($tiles, $here, $test{$dir}->[4])
	       or $self->something($tiles, $here, $test{$dir}->[5]))
	  and not $self->doors_nearby($here, \@doors)) {
	$log->warn("$here content isn't 'empty'") unless $tiles->[$here]->[0] eq "empty";
	my $type = one(@types);
	my $variant = $dir;
	my $target = $here;
	# this makes sure doors are on top
	if ($dir eq "s") { $target += $self->row; $variant = "n"; }
	elsif ($dir eq "e") { $target += 1; $variant = "w"; }
	push(@{$tiles->[$target]}, "$type-$variant");
	push(@doors, $here);
      }
    }
  }
  return $tiles;
}

sub doors_nearby {
  my $self = shift;
  my $here = shift;
  my $doors = shift;
  for my $door (@$doors) {
    return 1 if $self->distance($door, $here) < 2;
  }
  return 0;
}

sub distance {
  my $self = shift;
  my $from = shift;
  my $to = shift;
  my $dx = $to % $self->row - $from % $self->row;
  my $dy = int($to/$self->row) - int($from/$self->row);
  return sqrt($dx * $dx + $dy * $dy);
}

sub add_stair {
  my $self = shift;
  my $tiles = shift;
  my $stairs = shift;
 STAIR:
  for my $room (@$stairs) {
    # find the middle using the label
    my $start;
    for my $i (0 .. scalar(@$tiles) - 1) {
      next unless $tiles->[$i];
      $start = $i;
      last if grep { $_ eq qq{"$room"} } @{$tiles->[$i]};
    }
    # The first test refers to a tile that must be set to "empty" (where the stair
    # will end), all others must be undefined. Note that stairs are anchored at
    # the top end, and we're placing a stair that goes *down*. So what we're
    # looking for is the point (4,1) in the image below:
    #
    #   12345
    # 1 EE<<
    # 2 EE
    #
    # Remember, +1 is east, -1 is west, -$row is north, +$row is south. The anchor
    # point we're testing is already known to be undefined.
    my %test = (n => [-2 * $self->row,
		      -$self->row - 1, -$self->row, -$self->row + 1,
		      -1, +1,
		      +$self->row - 1, +$self->row, +$self->row + 1],
		e => [+2,
		      -$self->row + 1, +1, +$self->row + 1,
		      -$self->row, +$self->row,
		      -$self->row - 1, -1, +$self->row - 1]);
    $test{s} = [map { -$_ } @{$test{n}}];
    $test{w} = [map { -$_ } @{$test{e}}];
    # First round: limit ourselves to stair positions close to the start.
    my %candidates;
    for my $here (shuffle 0 .. scalar(@$tiles) - 1) {
      next if $tiles->[$here];
      my $distance = $self->distance($here, $start);
      $candidates{$here} = $distance if $distance <= 4;
    }
    # Second round: for each candidate, test stair placement and record the
    # distance of the landing to the start and the direction of every successful
    # stair.
    my $stair;
    my $stair_dir;
    my $stair_distance = $self->max_tiles;
    for my $here (sort {$a cmp $b} keys %candidates) {
      # push(@{$tiles->[$here]}, "red");
      for my $dir (shuffle qw(n e w s)) {
	my @test = @{$test{$dir}};
	my $first = shift(@test);
	if (# the first test is an empty tile: this the stair's landing
	    $self->empty($tiles, $here, $first)
	    # and the stair is surrounded by empty space
	    and none { $self->something($tiles, $here, $_) } @test) {
	  my $distance = $self->distance($here + $first, $start);
	  if ($distance < $stair_distance) {
	    # $log->debug("Considering stair-$dir for $here ($distance)");
	    $stair = $here;
	    $stair_dir = $dir;
	    $stair_distance = $distance;
	  }
	}
      }
    }
    if (defined $stair) {
      push(@{$tiles->[$stair]}, "stair-$stair_dir");
      next STAIR;
    }
    # $log->debug("Unable to place a regular stair, trying to place a spiral staircase");
    for my $here (shuffle 0 .. scalar(@$tiles) - 1) {
      next unless $tiles->[$here];
      if (# close by
	  $self->distance($here, $start) < 3
	  # and the landing is empty (no statue, doors n or w)
	  and @{$tiles->[$here]} == 1
	  and $tiles->[$here]->[0] eq "empty"
	  # and the landing to the south has no door n
	  and not grep { /-n$/ } @{$tiles->[$here+$self->row]}
	  # and the landing to the east has no door w
	  and not grep { /-w$/ } @{$tiles->[$here+1]}) {
	$log->debug("Placed spiral stair at $here");
	$tiles->[$here]->[0] = "stair-spiral";
	next STAIR;
      }
    }
    $log->warn("Unable to place a stair!");
    next STAIR;
  }
  return $tiles;
}

sub add_small_stair {
  my $self = shift;
  my $tiles = shift;
  my $stairs = shift;
  my %delta = (n => -$self->row, e => 1, s => $self->row, w => -1);
 STAIR:
  for my $room (@$stairs) {
    # find the middle using the label
    my $start;
    for my $i (0 .. scalar(@$tiles) - 1) {
      next unless $tiles->[$i];
      $start = $i;
      last if grep { $_ eq qq{"$room"} } @{$tiles->[$i]};
    }
    for (shuffle qw(n e w s)) {
      if (grep { $_ eq "empty" } @{$tiles->[$start + $delta{$_}]}) {
	push(@{$tiles->[$start + $delta{$_}]}, "stair-spiral");
	next STAIR;
      }
    }
  }
  return $tiles;
}

sub fix_corners {
  my $self = shift;
  my $tiles = shift;
  my %look = (n => -$self->row, e => 1, s => $self->row, w => -1);
  for my $here (0 .. scalar(@$tiles) - 1) {
    for (@{$tiles->[$here]}) {
      if (/^(arc|diagonal)-(ne|nw|se|sw)$/) {
	my $dir = $2;
	# debug_neighbours($tiles, $here);
	if (substr($dir, 0, 1) eq "n" and $here + $self->row < $self->max_tiles and $tiles->[$here + $self->row] and @{$tiles->[$here + $self->row]}
	    or substr($dir, 0, 1) eq "s" and $here > $self->row and $tiles->[$here - $self->row] and @{$tiles->[$here - $self->row]}
	    or substr($dir, 1) eq "e" and $here > 0 and $tiles->[$here - 1] and @{$tiles->[$here - 1]}
	    or substr($dir, 1) eq "w" and $here < $self->max_tiles and $tiles->[$here + 1] and @{$tiles->[$here + 1]}) {
	  $_ = "empty";
	}
      }
    }
  }
  return $tiles;
}

sub fix_pillars {
  my $self = shift;
  my $tiles = shift;
  # This is: $test{n}->[0] is straight ahead (e.g. looking north), $test{n}->[1]
  # is to the left (e.g. looking north-west), $test{n}->[2] is to the right
  # (e.g. looking north-east).
  my %test = (n => [-$self->row, -$self->row - 1, -$self->row + 1],
	      e => [1, 1 - $self->row, 1 + $self->row],
	      s => [$self->row, $self->row - 1, $self->row + 1],
	      w => [-1, -1 - $self->row, -1 + $self->row]);
  for my $here (0 .. scalar(@$tiles) - 1) {
  TILE:
    for (@{$tiles->[$here]}) {
      if ($_ eq "pillar") {
	# $log->debug("$here: $_");
	# debug_neighbours($tiles, $here);
	for my $dir (qw(n e w s)) {
	  if ($self->something($tiles, $here, $test{$dir}->[0])
	      and not $self->something($tiles, $here, $test{$dir}->[1])
	      and not $self->something($tiles, $here, $test{$dir}->[2])) {
	    # $log->debug("Removing pillar $here");
	    $_ = "empty";
	    next TILE;
	  }
	}
      }
    }
  }
  return $tiles;
}

sub to_rocks {
  my $self = shift;
  my $tiles = shift;
  # These are the directions we know (where m is the center). Order is important
  # so that list comparison is made easy.
  my @dirs = qw(n e w s);
  my %delta = (n => -$self->row, e => 1, s => $self->row, w => -1);
  # these are all the various rock configurations we know about; listed are the
  # fields that must be "empty" for this to work
  my %rocks = ("rock-n" => [qw(e w s)],
	       "rock-ne" => [qw(w s)],
	       "rock-ne-alternative" => [qw(w s)],
	       "rock-e" => [qw(n w s)],
	       "rock-se" => [qw(n w)],
	       "rock-se-alternative" => [qw(n w)],
	       "rock-s" => [qw(n e w)],
	       "rock-sw" => [qw(n e)],
	       "rock-sw-alternative" => [qw(n e)],
	       "rock-w" => [qw(n e s)],
	       "rock-nw" => [qw(e s)],
	       "rock-nw-alternative" => [qw(e s)],
	       "rock-dead-end-n" => [qw(s)],
	       "rock-dead-end-e" => [qw(w)],
	       "rock-dead-end-s" => [qw(n)],
	       "rock-dead-end-w" => [qw(e)],
	       "rock-corridor-n" => [qw(n s)],
	       "rock-corridor-s" => [qw(n s)],
	       "rock-corridor-e" => [qw(e w)],
	       "rock-corridor-w" => [qw(e w)], );
  # my $first = 1;
  for my $here (0 .. scalar(@$tiles) - 1) {
  TILE:
    for (@{$tiles->[$here]}) {
      next unless grep { $_ eq "empty" } @{$tiles->[$here]};
      if (not $_) {
	$_ = "rock" if all { grep { $_ } $self->something($tiles, $here, $_) } qw(n e w s);
      } else {
	# loop through all the rock tiles and compare the patterns
      ROCK:
	for my $rock (keys %rocks) {
	  my $expected = $rocks{$rock};
	  my @actual = grep {
	    my $dir = $_;
	     $self->something($tiles, $here, $delta{$dir});
	  } @dirs;
	  if (list_equal($expected, \@actual)) {
	    $_ = $rock;
	    next TILE;
	  }
        }
      }
    }
  }
  return $tiles;
}

sub list_equal {
  my $a1 = shift;
  my $a2 = shift;
  return 0 if @$a1 ne @$a2;
  for (my $i = 0; $i <= $#$a1; $i++) {
    return unless $a1->[$i] eq $a2->[$i];
  }
  return 1;
}

sub coordinates {
  my $self = shift;
  my $here = shift;
  return sprintf("%d,%d", int($here/$self->row), $here % $self->row);
}

sub legal {
  my $self = shift;
  # is this position on the map?
  my $here = shift;
  my $delta = shift;
  return if $here + $delta < 0 or $here + $delta > $self->max_tiles;
  return if $here % $self->row == 0 and $delta == -1;
  return if $here % $self->row == $self->row and $delta == 1;
  return 1;
}

sub something {
  my $self = shift;
  # Is there something at this legal position? Off the map means there is
  # nothing at the position.
  my $tiles = shift;
  my $here = shift;
  my $delta = shift;
  return if not $self->legal($here, $delta);
  return @{$tiles->[$here + $delta]} if $tiles->[$here + $delta];
}

sub empty {
  my $self = shift;
  # Is this position legal and empty? We're looking for the "empty" tile!
  my $tiles = shift;
  my $here = shift;
  my $delta = shift;
  return if not $self->legal($here, $delta);
  return grep { $_ eq "empty" } @{$tiles->[$here + $delta]};
}

sub debug_neighbours {
  my $self = shift;
  my $tiles = shift;
  my $here = shift;
  my @n;
  if ($here > $self->row and $tiles->[$here - $self->row] and @{$tiles->[$here - $self->row]}) {
    push(@n, "n: @{$tiles->[$here - $self->row]}");
  }
  if ($here + $self->row <= $self->max_tiles and $tiles->[$here + $self->row] and @{$tiles->[$here + $self->row]}) {
    push(@n, "s: @{$tiles->[$here + $self->row]}");
  }
  if ($here > 0 and $tiles->[$here - 1] and @{$tiles->[$here - 1]}) {
    push(@n, "w: @{$tiles->[$here - 1]}");
  }
  if ($here < $self->max_tiles and $tiles->[$here + 1] and @{$tiles->[$here + 1]}) {
    push(@n, "e: @{$tiles->[$here + 1]}");
  }
  $log->debug("Neighbours of $here: @n");
  for (-$self->row-1, -$self->row, -$self->row+1, -1, +1, $self->row-1, $self->row, $self->row+1) {
    eval { $log->debug("Neighbours of $here+$_: @{$tiles->[$here + $_]}") };
  }
}

sub to_text {
  my $self = shift;
  # Don't forget the border of two tiles.
  my $tiles = shift;
  my $text = "include gridmapper.txt\n";
  for my $x (0 .. $self->row - 1) {
    for my $y (0 .. $self->col - 1) {
      my $tile = $tiles->[$x + $y * $self->row];
      if ($tile) {
	$text .= sprintf("%02d%02d @$tile\n", $x + 1, $y + 1);
      }
    }
  }
  # The following is matched in /gridmapper/random!
  my $url = $self->to_gridmapper_link($tiles);
  $text .= qq{other <text x="-20em" y="0" font-size="40pt" transform="rotate(-90)" style="stroke:blue">}
  . qq{<a xlink:href="$url">Edit in Gridmapper</a></text>\n};
  $text .= "# Gridmapper link: $url\n";
  return $text;
}

sub to_gridmapper_link {
  my $self = shift;
  my $tiles = shift;
  my $code;
  my $pen = 'up';
  for my $y (0 .. $self->col - 1) {
    for my $x (0 .. $self->row - 1) {
      my $tile = $tiles->[$x + $y * $self->row];
      if (not $tile or @$tile == 0) {
	my $next = $tiles->[$x + $y * $self->row + 1];
	if ($pen eq 'down' and $next and @$next) {
	  $code .= ' ';
	} else {
	  $pen = 'up';
	}
	next;
      }
      if ($pen eq 'up') {
	$code .= "($x,$y)";
	$pen = 'down';
      }
      my $finally = " ";
      # $log->debug("[$x,$y] @$tile");
      for (@$tile) {
	if ($_ eq "empty") { $finally = "f" }
	elsif ($_ eq "pillar") { $code .= "p" }
	elsif (/^"(\d+)"$/) { $code .= $1 }
	elsif ($_ eq "arc-se") { $code .= "a" }
	elsif ($_ eq "arc-sw") { $code .= "aa" }
	elsif ($_ eq "arc-nw") { $code .= "aaa" }
	elsif ($_ eq "arc-ne") { $code .= "aaaa" }
	elsif ($_ eq "diagonal-se") { $code .= "n" }
	elsif ($_ eq "diagonal-sw") { $code .= "nn" }
	elsif ($_ eq "diagonal-nw") { $code .= "nnn" }
	elsif ($_ eq "diagonal-ne") { $code .= "nnnn" }
	elsif ($_ eq "door-w") { $code .= "d" }
	elsif ($_ eq "door-n") { $code .= "dd" }
	elsif ($_ eq "door-e") { $code .= "ddd" }
	elsif ($_ eq "door-s") { $code .= "dddd" }
	elsif ($_ eq "secret-w") { $code .= "dv" }
	elsif ($_ eq "secret-n") { $code .= "ddv" }
	elsif ($_ eq "secret-e") { $code .= "dddv" }
	elsif ($_ eq "secret-s") { $code .= "ddddv" }
	elsif ($_ eq "concealed-w") { $code .= "dvv" }
	elsif ($_ eq "concealed-n") { $code .= "ddvv" }
	elsif ($_ eq "concealed-e") { $code .= "dddvv" }
	elsif ($_ eq "concealed-s") { $code .= "ddddvv" }
	elsif ($_ eq "archway-w") { $code .= "dvvvv" }
	elsif ($_ eq "archway-n") { $code .= "ddvvvv" }
	elsif ($_ eq "archway-e") { $code .= "dddvvvv" }
	elsif ($_ eq "archway-s") { $code .= "ddddvvvv" }
	elsif ($_ eq "stair-s") { $code .= "s" }
	elsif ($_ eq "stair-w") { $code .= "ss" }
	elsif ($_ eq "stair-n") { $code .= "sss" }
	elsif ($_ eq "stair-e") { $code .= "ssss" }
	elsif ($_ eq "stair-spiral") { $code .= "svv" }
	elsif ($_ eq "rock") { $finally = "g" }
	elsif ($_ eq "rock-n") { $finally = "g" }
	elsif ($_ eq "rock-ne") { $finally = "g" }
	elsif ($_ eq "rock-ne-alternative") { $finally = "g" }
	elsif ($_ eq "rock-e") { $finally = "g" }
	elsif ($_ eq "rock-se") { $finally = "g" }
	elsif ($_ eq "rock-se-alternative") { $finally = "g" }
	elsif ($_ eq "rock-s") { $finally = "g" }
	elsif ($_ eq "rock-sw") { $finally = "g" }
	elsif ($_ eq "rock-sw-alternative") { $finally = "g" }
	elsif ($_ eq "rock-w") { $finally = "g" }
	elsif ($_ eq "rock-nw") { $finally = "g" }
	elsif ($_ eq "rock-nw-alternative") { $finally = "g" }
	elsif ($_ eq "rock-dead-end-n") { $finally = "g" }
	elsif ($_ eq "rock-dead-end-e") { $finally = "g" }
	elsif ($_ eq "rock-dead-end-s") { $finally = "g" }
	elsif ($_ eq "rock-dead-end-w") { $finally = "g" }
	elsif ($_ eq "rock-corridor-n") { $finally = "g" }
	elsif ($_ eq "rock-corridor-s") { $finally = "g" }
	elsif ($_ eq "rock-corridor-e") { $finally = "g" }
	elsif ($_ eq "rock-corridor-w") { $finally = "g" }
	else {
	  $log->warn("Tile $_ not known for Gridmapper link");
	}
      }
      $code .= $finally;
    }
    $pen = 'up';
  }
  $log->debug("Gridmapper: $code");
  my $url = 'https://campaignwiki.org/gridmapper?' . url_escape($code);
  return $url;
}

=head1 SEE ALSO

L<Gridmapper|https://alexschroeder.ch/cgit/gridmapper/about/> is a web
application that lets you draw dungeons with strong focus on using the keyboard.

=cut

1;
