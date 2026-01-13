package Gears::Router::Location;
$Gears::Router::Location::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Gears::Router::Pattern;

has param 'pattern' => (
	isa => Str,
);

has field 'pattern_obj' => (
	isa => InstanceOf ['Gears::Router::Pattern'],
	lazy => 1,
);

with qw(
	Gears::Router::Proto
);

sub is_bridge ($self)
{
	return $self->locations->@* > 0;
}

sub compare ($self, $path)
{
	return $self->pattern_obj->compare($path);
}

sub build ($self, @more_args)
{
	return $self->pattern_obj->build(@more_args);
}

# must be reimplemented
sub _build_pattern_obj ($self)
{
	...;
}

__END__

=head1 NAME

Gears::Router::Location - A routing location with a pattern

=head1 SYNOPSIS

	my $location = Gears::Router::Location::Subclass->new(
		pattern => '/user/:id',
		router => $router,
	);

	# Add child locations
	my $child = $location->add('/profile', { name => 'profile' });

	# Check if this location has children
	if ($location->is_bridge) {
		# ...
	}

	# Compare a path against this location's pattern
	my $match_data = $location->compare('/user/123');

	# Build a URL from this location's pattern
	my $url = $location->build(id => 123);

=head1 DESCRIPTION

Gears::Router::Location represents a single routing location with a pattern.
Locations can have child locations, forming a hierarchical routing tree. Both
router and location share common interface thourgh a role, so they can be used
interchangeably to build the tree of locations. A location with child locations
is called a I<"bridge">.

Each location holds a pattern string and creates a pattern object to handle
matching and URL building operations.

This is a base, abstract class. It must be reimplemented to at least override
the C<_build_pattern_obj> method. Take a look at
L<Gears::Router::Location::Match> for the simplest example of a subclass.

=head1 INTERFACE

=head2 Attributes

=head3 pattern

The pattern string for this location, such as C</path>.

I<Required in constructor>

=head3 pattern_obj

A L<Gears::Router::Pattern> object that handles the actual pattern matching and
building operations. This is lazily built from the pattern string.

I<Not available in constructor>

=head3 router

A weak reference to the parent L<Gears::Router> object.

I<Required in constructor>

=head3 locations

An array reference of child L<Gears::Router::Location> objects.

I<Not available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 add

	$child_location = $location->add($pattern, $data = {})

Adds a new child location with the specified pattern. The child's pattern is
automatically prepended with the parent's pattern. Returns the newly created
child location object.

=head3 is_bridge

	$bool = $location->is_bridge()

Returns C<true> if this location has child locations, C<false> otherwise.

=head3 compare

	$match_data = $location->compare($path)

Compares the given path string against this location's pattern. Returns an
array reference with matched data if successful, or C<undef> if the path doesn't
match.

Note that a successful match may also return an empty array reference, but
never C<undef>.

=head3 build

	$string = $location->build(@build_data)

Builds a URI string from this location's pattern. The exact behavior is
implementation-specific.

