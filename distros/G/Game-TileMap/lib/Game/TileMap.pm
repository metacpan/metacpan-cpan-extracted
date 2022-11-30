package Game::TileMap;
$Game::TileMap::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Storable qw(dclone);
use Carp qw(croak);

use Game::TileMap::Legend;
use Game::TileMap::Tile;
use Game::TileMap::_Utils;

has param 'legend' => (

	# isa => InstanceOf ['Game::TileMap::Legend'],
);

has field 'coordinates' => (
	writer => -hidden,

	# isa => ArrayRef [ArrayRef [Any]],
);

has field 'size_x' => (
	writer => -hidden,

	# isa => PositiveInt,
);

has field 'size_y' => (
	writer => -hidden,

	# isa => PositiveInt,
);

has field '_guide' => (
	writer => 1,

	# isa => HashRef [ArrayRef [Tuple [Any, PositiveInt, PositiveInt]]],
);

with qw(
	Game::TileMap::Role::Checks
	Game::TileMap::Role::Helpers
);

sub new_legend
{
	my $self = shift;

	return Game::TileMap::Legend->new(@_);
}

sub BUILD
{
	my ($self, $args) = @_;

	if ($args->{map}) {
		$self->from_string($args->{map})
			if !ref $args->{map};

		$self->from_array($args->{map})
			if ref $args->{map} eq 'ARRAY';
	}
}

sub from_string
{
	my ($self, $map_str) = @_;
	my $per_tile = $self->legend->characters_per_tile;

	my @map_lines =
		reverse
		grep { /\S/ }
		map { Game::TileMap::_Utils::trim $_ }
		split "\n", $map_str
		;

	my @map;
	foreach my $line (@map_lines) {
		my @objects;
		while (length $line) {
			my $marker = substr $line, 0, $per_tile, '';
			push @objects, ($self->legend->objects->{$marker} // croak "Invalid map marker '$marker'");
		}

		push @map, \@objects;
	}

	return $self->from_array(\@map);
}

sub from_array
{
	my ($self, $map_aref) = @_;
	my @map = @{$map_aref};

	my @map_size = (scalar @{$map[0]}, scalar @map);
	my %guide;

	my @new_map;
	foreach my $line (0 .. $#map) {
		croak "invalid map size on line $line"
			if @{$map[$line]} != $map_size[0];

		for my $col (0 .. $#{$map[$line]}) {
			my $prev_obj = $map[$line][$col];
			my $obj = Game::TileMap::Tile->new(contents => $prev_obj, x => $col, y => $line);

			$new_map[$col][$line] = $obj;
			push @{$guide{$self->legend->get_class_of_object($prev_obj)}}, $obj;
		}
	}

	$self->_set_coordinates(\@new_map);
	$self->_set_size_x($map_size[0]);
	$self->_set_size_y($map_size[1]);
	$self->_set_guide(\%guide);

	return $self;
}

sub to_string
{
	return shift->to_string_and_mark;
}

sub to_string_and_mark
{
	my ($self, $mark_positions, $with) = @_;
	$with //= '@' x $self->legend->characters_per_tile;

	my @lines;
	my %markers_rev = map {
		$self->legend->objects->{$_} => $_
	} keys %{$self->legend->objects};

	my $mark = \undef;
	my $coordinates = $self->coordinates;
	if ($mark_positions) {
		$coordinates = dclone $coordinates;

		foreach my $pos (@{$mark_positions}) {
			$coordinates->[$pos->[0]][$pos->[1]] = $mark;
		}
	}

	foreach my $pos_x (0 .. $#$coordinates) {
		foreach my $pos_y (0 .. $#{$coordinates->[$pos_x]}) {
			my $obj = $coordinates->[$pos_x][$pos_y];
			$lines[$pos_y][$pos_x] = $obj eq $mark ? $with : $markers_rev{$obj->type};
		}
	}

	return join "\n",
		reverse
		map { join '', @{$_} } @lines;
}

1;

__END__

=head1 NAME

Game::TileMap - Representation of tile-based two-dimensional rectangular maps

=head1 SYNOPSIS

	use Game::TileMap;

	# first, create a map legend

	my $legend = Game::TileMap->new_legend;

	$legend
		->add_wall('#') # required
		->add_void('.') # required
		->add_terrain('_' => 'pavement')
		->add_object('monster_spawns', 'a' => 'spawn_a')
		->add_object('monster_spawns', 'b' => 'spawn_b')
		->add_object('surroundings', '=' => 'chest')
		;

	# next, create a map

	my $map_str = <<MAP;

	.__.......
	.__.......
	.__.......
	.__.......
	.__..#####
	.__..#a__=
	.__..#__b_
	._________
	.__..#####
	.__.......
	.__.......

	MAP

	my $map = Game::TileMap->new(
		legend => $legend,
		map => $map_str
	);

	# map can be queried to get some info about its contents
	my @monsters = $map->get_all_of_class('monster_spawns');
	my @chests = $map->get_all_of_type('chest');
	my $true = $map->check_within_map(0, 5);
	my $false = $map->check_can_be_accessed(0, 5);

=head1 DESCRIPTION

Game::TileMap is a module which helps you build and store simple
two-dimensional maps of tiles, where each tile contains only one element. Maps
created from this module are generally considered immutable and should only be
used to define a map, not to store its changing state.

Maps can be created out of strings or arrays of arrays and are stored as an
array of array of L<Game::TileMap::Tile>. Some helpful features are in place:

=over

=item * map markers (usually just single characters) are translated into objects specified in the legend

Map characters can't be whitespace (map lines are trimmed before processing).

Legend objects can't be falsy, but other than that they can be anything (string, object, reference).

=item * each legend object is assigned to a class, which you can query for later

If you add a class C<surroundings>:

	$legend->add_object('surroundings', '@' => 'trash bin')
	       ->add_object('surroundings', '=' => 'desk')
	       ->add_object('surroundings', 'H' => 'locker')
	       ->add_object('surroundings', 'L' => 'chair');

Then you can easily get information about locations of those tiles on a map:

	my @all_surroundings = $map->get_all_of_class('surroundings');

This array will contains blessed objects of L<Game::TileMap::Tile> class.

=item * you define how your maps look yourself

Only predefined objects are C<walls> (can't be accessed and are considered not
a part of map) and C<voids> (can't be accessed, but are a part of map). Their
predefined class is C<terrain>. You are free to introduce as many objects and
classes as needed.

=item * bottom-left corner of the stringified map is at [0;0], while top-right is at [max;max]

This lets you think of a map like you think of a coordinate frame (first quarter).

=item * map array has X coordinates in first dimension and Y coordinates in second dimension

This way you can get more familiar notation:

	$map->coordinates->[3][5]; # actual point at [3;5]

=item * supports multi-character maps

	my $legend = Game::TileMap->new_legend(characters_per_tile => 2);

	$legend
		->add_wall('##')
		->add_void('..')
		->add_terrain('__' => 'pavement')
		->add_terrain('_~' => 'mud')
		->add_terrain('_,' => 'grass')
	;

	my $map_str = <<MAP;
	_,_______~
	_,__####_~
	____####_~
	_,__####_~
	_,_______~
	MAP

=back

=head2 Attributes

=head3 legend

A reference to map legend. Required in constructor.

=head3 coordinates

The constructed map: array of array of L<Game::TileMap::Tile>.

=head3 size_x

Horizontal size of the map.

=head3 size_y

Vertical size of the map.

=head2 Methods

=head3 new_legend

Static method which returns a new instance of L<Game::TileMap::Legend>. Note
that legends are reusable.

=head3 new

Moose-flavored constructor. Possible arguments are:

=over

=item * C<< map => ArrayRef | Str >>

Optional.

Map input that will be passed to L<from_string> or L<from_array>.

=item * C<< legend => InstanceOf ['Game::TileMap::Legend'] >>

Required.

Legend of the map, which describes its contents.

=back

=head3 from_string

	my $map = Game::TileMap->new(legend => $legend);
	$map->from_string($map_str);

Creates a map from a string.

=head3 from_array

	my $map = Game::TileMap->new(legend => $legend);
	$map->from_array($map_aref);

Creates a map from an array.

=head3 to_string

Creates a string from a map.

=head3 to_string_and_mark

	print $map->to_string_and_mark([[1, 2], [1, 3]]);

	print $str = $map->to_string_and_mark([[5, 5]], 'X');

Creates a string from a map and marks given positions with a marker. The
default marker is C<'@'> (times the number of characters per tile).

Useful during debugging.

=head3 check_within_map

	my $bool = $map->check_within_map($pos_x, $pos_y);

Returns true if the given position is considered to be inside the map (not
outside of bounds and not a wall).

Note that C<$pos_x> and C<$pos_y> can be decimal (not just integers).

=head3 check_can_be_accessed

	my $bool = $map->check_can_be_accessed($pos_x, $pos_y);

Returns true if the given position is considered accessible (not outside of
bounds and not a wall or a void).

Note that C<$pos_x> and C<$pos_y> can be decimal (not just integers).

=head3 get_all_of_class

	my @arr = $map->get_all_of_class('class_name');

Returns all map objects (in form of L<Game::TileMap::Tile> instances) that are
assigned to a given class (found out by string equality check).

=head3 get_all_of_type

	my @arr = $map->get_all_of_type($object);

Returns all map objects (in form of L<Game::TileMap::Tile> instances) that are
of a given object type (found out by string equality check).

=head1 SEE ALSO

L<Game::LevelMap> is more suited for terminal games.

L<Games::Board> is more focused on creating board games.

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

