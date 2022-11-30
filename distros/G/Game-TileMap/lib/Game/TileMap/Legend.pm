package Game::TileMap::Legend;
$Game::TileMap::Legend::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use Moo;
use Mooish::AttributeBuilder -standard;
use Carp qw(croak);

use constant TERRAIN_CLASS => 'terrain';
use constant WALL_OBJECT => '';
use constant VOID_OBJECT => '0';

has field 'classes' => (
	default => sub { {} },

	# isa => HashRef [ ArrayRef [Str]],
);

has param 'characters_per_tile' => (
	default => sub { 1 },

	# isa => PositiveInt,
);

has field '_object_map' => (
	lazy => 1,

	# isa => HashRef [Str],
);

has field 'objects' => (
	default => sub { {} },

	# isa => HashRef [Any],
);

sub _build_object_map
{
	my $self = shift;
	my %classes = %{$self->classes};
	my %objects = %{$self->objects};
	my %map_reverse;

	foreach my $class (keys %classes) {
		my @objects = map { $objects{$_} } @{$classes{$class}};
		foreach my $obj (@objects) {
			$map_reverse{$obj} = $class;
		}
	}

	return \%map_reverse;
}

sub get_class_of_object
{
	my ($self, $obj) = @_;

	return $self->_object_map->{$obj}
		// croak "no such object '$obj' in map legend";
}

sub add_wall
{
	my ($self, $marker) = @_;

	return $self->add_terrain($marker, WALL_OBJECT);
}

sub add_void
{
	my ($self, $marker) = @_;

	return $self->add_terrain($marker, VOID_OBJECT);
}

sub add_terrain
{
	my ($self, $marker, $object) = @_;

	return $self->add_object(TERRAIN_CLASS, $marker, $object);
}

sub add_object
{
	my ($self, $class, $marker, $object) = @_;

	croak "marker '$marker' is already used"
		if exists $self->objects->{$marker};

	croak "marker '$marker' has wrong length"
		unless length $marker == $self->characters_per_tile;

	push @{$self->classes->{$class}}, $marker;
	$self->objects->{$marker} = $object;

	return $self;
}

1;

__END__

=head1 NAME

Game::TileMap::Legend - Map contents description

=head1 DESCRIPTION

All object classes must be string.

All map markers are strings with length equal to L</characters_per_tile>. Don't
use whitespace - map strings are trimmed before parsing.

All objects can be anything, but not C<undef>. String probably works best.

=head2 Attributes

=head3 characters_per_tile

The number of characters (horizontal only) than are used to define one tile.

Optional in the constructor. Default: C<1>

=head2 Methods

=head3 new

Moose-flavored constructor. See L</Attributes> for a list of possible arguments.

Note: it may be easier to call L<Game::TileMap/new_legend>.

=head3 add_wall

	$legend = $legend->add_wall($marker);

Defines a marker used to store a wall. You are required to set this.

Walls are considered not a part of the map.

=head3 add_void

	$legend = $legend->add_void($marker);

Defines a marker used to store a void. You are required to set this.

Voids are considered a part of the map, but they are not accessible. Think of them as chasms.

=head3 add_terrain

	$legend = $legend->add_terrain($marker => $object);

Same as C<< add_object('terrain', $marker => $object) >>.

=head3 add_object

	$legend = $legend->add_object('class', $marker => $object);

Adds a new object with a given class and marker.

=head3 get_class_of_object

	my $class = $legend->get_class_of_object($object);

Returns the object class for a given object defined in the legend.

