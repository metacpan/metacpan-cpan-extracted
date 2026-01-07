package Gears::Router::Location::SigilMatch;
$Gears::Router::Location::SigilMatch::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::Router::Pattern::SigilMatch;

extends 'Gears::Router::Location';

has param 'checks' => (
	isa => HashRef,
	default => sub { {} },
);

has param 'defaults' => (
	isa => HashRef,
	default => sub { {} },
);

sub _build_pattern_obj ($self)
{
	return Gears::Router::Pattern::SigilMatch->new(
		location => $self,
	);
}

__END__

=head1 NAME

Gears::Router::Location::SigilMatch - Location with sigil-based pattern matching

=head1 SYNOPSIS

	use Gears::Router::Location::SigilMatch;

	my $location = Gears::Router::Location::SigilMatch->new(
		pattern => '/user/:id/post/?slug',
		router => $router,
		checks => { id => '\d+' },
		defaults => { slug => 'index' },
	);

	# Match with all parameters
	my $match = $location->compare('/user/123/post/my-post');

	# Match with optional parameter omitted
	my $match2 = $location->compare('/user/123/post');

	# Build URL with parameters
	my $url = $location->build(id => 456, slug => 'another-post');

=head1 DESCRIPTION

Gears::Router::Location::SigilMatch is a location implementation that supports
pattern matching with placeholders using sigils. It extends the basic location
with support for parameter validation and default values. It is pretty much
feature-equal to L<Kelp::Routes> (in terms of pattern matching).

It supports following sigils:

=over

=item * C<:name> - Required placeholder

Matches any characters except slash.

=item * C<?name> - Optional placeholder

Matches any characters except slash. If it follows a slash (with no curly
braces), the slash is made optional as well.

=item * C<*name> - Wildcard placeholder

Matches any characters including slashes.

=item * C<E<gt>name> - Slurpy placeholder

Optional wildcard that matches everything including slashes. If it follows a
slash (with no curly braces), the slash is made optional as well.

=back

Each placeholder is required to be given a name. Placeholders can be enclosed
in curly braces (like C<{:name}>) to separate them from surrounding text.

=head1 INTERFACE

Inherits interface from L<Gears::Router::Location>. Uses
L<Gears::Router::Pattern::SigilMatch> for pattern matching.

=head2 Attributes

=head3 checks

A hash reference mapping placeholder names to regular expressions (as strings
or compiled regexes) that validate the matched values. If a value doesn't match
its check, the pattern won't match during comparison or will throw an exception
during building.

Each check should be a partial regular expression, since it will be included in
a larger one. It should not use beginning / end of string anchors.

I<Available in constructor>

=head3 defaults

A hash reference mapping optional placeholder names to default values. These
defaults are used when optional placeholders are not provided during matching
or building.

I<Available in constructor>

