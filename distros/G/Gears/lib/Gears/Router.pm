package Gears::Router;
$Gears::Router::VERSION = '0.101';
use v5.40;
use Mooish::Base -standard;

use Gears::Router::Match;

with qw(Gears::Router::Proto);

# we are the router
has extended 'router' => (
	init_arg => undef,
	default => sub ($self) { $self },
);

# base route is an empty string
sub pattern ($self)
{
	return '';
}

# builds a new location - see Gears::Router::Proto
# - must create a new subclass of Gears::Router::Location, where %args are
#   constructor arguments
# - must be reimplemented
sub _build_location ($self, %args)
{
	...;
}

# builds a new match
# can be reimplemented
sub _build_match ($self, %args)
{
	return Gears::Router::Match->new(%args);
}

sub _match_level ($self, $locations, @args)
{
	my @matched;
	foreach my $loc ($locations->@*) {
		next unless my $match_data = $loc->compare(@args);
		my $match = $self->_build_match(
			location => $loc,
			matched => $match_data,
		);

		my $children = $loc->locations;
		if ($children->@* > 0) {
			push @matched, [$match, $self->_match_level($children, @args)];
		}
		else {
			push @matched, $match;
		}
	}

	return @matched;
}

sub _match ($self, @args)
{
	return [$self->_match_level($self->locations, @args)];
}

sub match
{
	goto \&_match;
}

sub flat_match ($self, @args)
{
	my $matches = $self->_match(@args);
	return $self->flatten($matches);
}

sub flatten ($self, $matches)
{
	my @flat_matches;
	foreach my $match ($matches->@*) {
		if (ref $match eq 'ARRAY') {
			push @flat_matches, $self->flatten($match);
		}
		else {
			push @flat_matches, $match;
		}
	}

	return @flat_matches;
}

sub clear ($self)
{
	$self->locations->@* = ();
	return $self;
}

__END__

=head1 NAME

Gears::Router - Pattern matching system

=head1 SYNOPSIS

	use My::Gears::Router;

	my $router = My::Gears::Router->new;

	# Add locations with patterns
	$router->add('/user/:id', { code => sub { ... } });
	$router->add('/blog/*path', { code => sub { ... } });

	# Match against a path
	my @matches = $router->match('/user/123');

	# Flat match returns all matches in a flat list
	my @flat = $router->flat_match('/blog/2025/01/post');

	# Clear all locations
	$router->clear;

=head1 DESCRIPTION

Gears::Router is the main routing component that manages URL pattern matching.
It serves as the root of a routing tree structure and maintains a collection of
locations (patterns) that can be matched against incoming paths.

The router supports hierarchical matching where locations can have child
locations (bridges), allowing for nested route structures. Bridges are matched
even if there are no matching routes underneath them, and routes are always
matched in the order of declaration and nesting.

=head1 EXTENDING

This router is abstract and very basic by design. A subclass of it must be
created, and it must implement the C<_build_location> method. Some example
location implementations are included in the C<Gears::Router::Location::>
namespace.

Take a look at L<Gears::Router::Location::SigilMatch>, which implements a
similar placeholders system to L<Kelp>. You may want to create a subclass of it
as well, so that the location contains any useful data. Locations included
with Gears do not make any assumptions about what kind of data you want to hold
in them.

Here is how a minimal working router subclass could be implemented:

	package My::Gears::Router;

	use v5.40;
	use Mooish::Base -standard;
	use My::Gears::Router::Location;

	extends 'Gears::Router';

	# "%args" will contain everything that was passed to a "add" call as the
	# second argument, but may contain additional keys which are needed for
	# internal bookkeeping:
	#
	# $router->add($pattern => { %args })

	sub _build_location ($self, %args)
	{
		return My::Gears::Router::Location->new(%args);
	}

Here is how a minimal location subclass could be implemented, extending
L<Gears::Router::Location::SigilMatch> and adding a mandatory code reference to
it:

	package My::Gears::Router::Location;

	use v5.40;
	use Mooish::Base -standard;

	extends 'Gears::Router::Location::SigilMatch';

	# - "param" marks mandatory constructor argument
	# - use "option" instead to mark optional ones
	# - "CodeRef" is a Type::Tiny type (optional)

	has param 'code' => (
		isa => CodeRef,
	);

The router implementation above can be used as shown in L</SYNOPSIS>.

=head1 INTERFACE

=head2 Attributes

=head3 locations

An array reference of L<Gears::Router::Location> objects representing the
registered route patterns.

I<Not available in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 pattern

	$str = $router->pattern()

Returns the pattern string for this router. Since this is the root router, it
always returns an empty string.

=head3 add

	$location = $router->add($pattern, $data = {})

Adds a new location with the specified pattern to the router. The C<$pattern>
is a string that may contain placeholders, but the exact behavior depends on
the used L<Gears::Router::Location> implementation. The optional C<$data> hash
reference contains additional metadata for the location.

Returns the newly created L<Gears::Router::Location> object. Since locations
share some common interface with the router, L</add> can be called again on the
resulted location. It is a preferred way of structuring routes in the
application.

=head3 match

	@matches = $router->match($path)

Matches the given path string against all registered locations. Returns a
nested array structure where matches that have child locations (bridges) are
represented as array references containing the parent match as the first
element, and its children's matches as subsequent elements. Each match is a
L<Gears::Router::Match> object.

Since Gears make no assumptions about the intended use of the router, matching
does not stop at first non-bridge hit. This means the matching performance is
stable at I<O(n)>, n being the number of routes. That additional cost may be
alleviated by organizing routes under bridges. If the bridge does not match,
its children will not be checked at all, so the application is rewarded for
having a well-organized routing tree. If required, rewriting matching to stop
at first hit should be easy enough.

=head3 flat_match

	@matches = $router->flat_match($path)

Similar to L</match>, but returns all matches in a flat list instead of a
nested structure. Matches should be processed from index C<0> up. With this
structure, there is no way to tell which matches were part of which bridges
without inspecting the router locations manually.

This is useful when you want to process all matching locations without dealing
with the hierarchical structure. Alternatively, L</flatten> can be called on the
result of L</match> to obtain the same result.

=head3 flatten

	@flat_matches = $router->flatten($matches)

Takes a nested array structure of matches (as returned by L</match>) and
flattens it into a single-level list. This is used internally by L</flat_match>.

=head3 clear

	$router = $router->clear()

Clears the router - this includes removing all registered locations from the
router. Returns the router object for method chaining.

