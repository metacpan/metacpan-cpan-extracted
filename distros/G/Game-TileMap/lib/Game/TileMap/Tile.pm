package Game::TileMap::Tile;
$Game::TileMap::Tile::VERSION = '1.000';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Carp qw(croak);

has param ['x', 'y'] => (

	# isa => PositiveInt,
);

has param 'contents' => (
	writer => 1,

	# isa => Any,
);

has field 'is_wall' => (
	writer => -hidden,

	# isa => Bool,
);

has field 'is_void' => (
	writer => -hidden,

	# isa => Bool,
);

has field 'type' => (
	writer => -hidden,

	# isa => Any,
);

sub BUILD
{
	my ($self, $args) = @_;

	my $legend = $args->{legend};
	croak "argument legend is required for Game::TileMap::Tile"
		unless $legend;

	$self->_set_type($self->contents);
	$self->_set_is_void($legend->voids->{$self->type});
	$self->_set_is_wall($legend->walls->{$self->type});
}

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

=head3 is_wall

Is this tile a wall?

=head3 is_void

Is this tile a void?

=head3 type

Type of the tile, as defined in the legend (as C<$object>)

=head2 Methods

=head3 new

Moose-flavored constructor. See L</Attributes> for a list of possible arguments.

In addition, the constructor B<requires> the argument C<legend> - map legend, but
it is only required during building of the object (not stored).

=head3 set_contents

Sets new L</contents> for this tile. Useful if you want to specify this tile
without changing the legend (which may be used across many maps). You can set
contents to be anything, since L</type> is what is used to perform any checks.

