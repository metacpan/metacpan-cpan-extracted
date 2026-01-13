package Gears::Router::Pattern::Match;
$Gears::Router::Pattern::Match::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

extends 'Gears::Router::Pattern';

sub compare ($self, $request_path)
{
	my $pattern = $self->pattern;

	if ($self->is_bridge) {
		return undef
			unless scalar $request_path =~ m/^\Q$pattern\E/;
	}
	else {
		return undef
			unless $request_path eq $pattern;
	}

	# this pattern does not really match anything other than the pattern itself
	# - return empty (but defined) list of matches
	return [];
}

sub build ($self, @more_args)
{
	return $self->pattern;
}

__END__

=head1 NAME

Gears::Router::Pattern::Match - Most basic pattern implementation

=head1 SYNOPSIS

	use Gears::Router::Pattern::Match;

	my $pattern = Gears::Router::Pattern::Match->new(
		location => $location,
	);

	# Exact match for non-bridge, prefix match for bridge
	my $match_data = $pattern->compare('/exact/path');

	# Building always returns the pattern itself
	my $url = $pattern->build();

=head1 DESCRIPTION

Gears::Router::Pattern::Match provides exact string pattern matching. If the
associated location is a bridge, it matches when the request path starts with
the pattern. If it's not a bridge, it only matches when the path equals the
pattern exactly.

This is the simplest location type that doesn't support any placeholders or
wildcards. While it may not be useful for any real work, it can be used to
reduce the number of moving parts when testing other parts of the router. It
always returns an empty array reference for matched data and the pattern itself
when building.

=head1 INTERFACE

Inherits interface from L<Gears::Router::Pattern>.

=head2 Methods

=head3 compare

	$match_data = $pattern->compare($request_path)

Compares the request path against the pattern. For bridges, returns an empty
array reference if the path starts with the pattern. For non-bridges, returns
an empty array reference only if the path exactly equals the pattern. Returns
C<undef> if there's no match.

=head3 build

	$url = $pattern->build(%params)

Returns the pattern string. Parameters are ignored since this pattern type has
no placeholders.

