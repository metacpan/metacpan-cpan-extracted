package Game::TileMap::Tile;
$Game::TileMap::Tile::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;

has param ['x', 'y'] => (

	# isa => PositiveInt,
);

has param 'contents' => (
	writer => 1,

	# isa => Any,
);

has field 'type' => (
	default => sub { shift->contents },

	# isa => Any,
);

1;

__END__

=head1 NAME

Game::TileMap::Tile - Map tile representation

=head1 DESCRIPTION

This is a simple struct-like object that holds data about one tile on a map.

=head2 Attributes

=head3 x

Horizontal position of this tile on a map.

=head3 y

Vertical position of this tile on a map.

=head3 contents

Contents of the tile. By default, same as L</type>, but you can change it with L</set_contents>.

=head3 type

Type of the tile, as defined in the legend (as C<$object>)

=head2 Methods

=head3 new

Moose-flavored constructor. See L</Attributes> for a list of possible arguments.

=head3 set_contents

Sets new L</contents> for this tile. Useful if you want to specify this tile
without changing the legend (which may be used across many maps). You can set
contents to be anything, since L</type> is what is used to perform any checks.

