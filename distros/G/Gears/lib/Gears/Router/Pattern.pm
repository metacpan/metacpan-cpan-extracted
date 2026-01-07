package Gears::Router::Pattern;
$Gears::Router::Pattern::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

has param 'location' => (
	isa => InstanceOf ['Gears::Router::Location'],
	weak_ref => 1,
	handles => [qw(pattern is_bridge)],
);

# must be reimplemented
sub compare ($self, $request_path)
{
	...;
}

# must be reimplemented
sub build ($self, @more_args)
{
	...;
}

__END__

=head1 NAME

Gears::Router::Pattern - Base pattern matching and building

=head1 SYNOPSIS

	use Gears::Router::Pattern;

	my $pattern = Gears::Router::Pattern->new(
		location => $location,
	);

	# Compare a path against the pattern
	my $match_data = $pattern->compare('/user/123');

	# Build a URL from the pattern
	my $url = $pattern->build(id => 123);

=head1 DESCRIPTION

Gears::Router::Pattern is the base class for pattern matching and URL building.
It holds a reference to a location and delegates the pattern string and bridge
status to it. Subclasses implement the actual matching and building logic.

This class is abstract, it requires subclassing. Take a look at
L<Gears::Router::Pattern::Match> for the simplest example of a subclass.

=head1 INTERFACE

=head2 Attributes

=head3 location

A weak reference to the L<Gears::Router::Location> object that owns this
pattern.

I<Required in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

=head3 compare

	$match_data = $pattern->compare($request_path)

Compares the given request path string against this pattern. Returns an array
reference with matched data if successful, or undef if the path doesn't match.
This method must be implemented by subclasses.

=head3 build

	$url = $pattern->build(%params)

Builds a URL string from this pattern by substituting placeholders with the
provided parameters. This method must be implemented by subclasses.

=head3 pattern

	$str = $pattern->pattern()

Returns the pattern string from the associated location. This method is
delegated to the location attribute.

=head3 is_bridge

	$bool = $pattern->is_bridge()

Returns true if the associated location has child locations. This method is
delegated to the location attribute.

