package Gears::Router::Location::Match;
$Gears::Router::Location::Match::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Gears::Router::Pattern::Match;

extends 'Gears::Router::Location';

sub _build_pattern_obj ($self)
{
	return Gears::Router::Pattern::Match->new(
		location => $self,
	);
}

__END__

=head1 NAME

Gears::Router::Location::Match - Most basic location implementation

=head1 SYNOPSIS

	use Gears::Router::Location::Match;

	my $location = Gears::Router::Location::Match->new(
		pattern => '/exact/path',
		router => $router,
	);

	# This will match
	my $match = $location->compare('/exact/path');

	# This will not match
	my $no_match = $location->compare('/exact/path/extra');

=head1 DESCRIPTION

Gears::Router::Location::Match is a location implementation that performs exact
string matching. If the location is a bridge, it matches when the request path
starts with the pattern. If it's not a bridge, it only matches when the path
equals the pattern exactly.

This is the simplest location type that doesn't support any placeholders or
wildcards. While it may not be useful for any real work, it can be used to
reduce the number of moving parts when testing other parts of the router.

=head1 INTERFACE

Inherits interface from L<Gears::Router::Location>. Uses
L<Gears::Router::Pattern::Match> for pattern matching.

