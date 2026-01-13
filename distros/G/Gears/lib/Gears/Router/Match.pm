package Gears::Router::Match;
$Gears::Router::Match::VERSION = '0.100';
use v5.40;
use Mooish::Base -standard;

use Devel::StrictMode;

has param 'location' => (
	(STRICT ? (isa => InstanceOf ['Gears::Router::Location']) : ()),
);

has param 'matched' => (
	(STRICT ? (isa => ArrayRef) : ()),
);

__END__

=head1 NAME

Gears::Router::Match - Match result object

=head1 SYNOPSIS

	use Gears::Router::Match;

	my $match = Gears::Router::Match->new(
		location => $location,
		matched => ['value1', 'value2'],
	);

	my $loc = $match->location;
	my $data = $match->matched;

=head1 DESCRIPTION

Gears::Router::Match represents a successful match result when a path matches a
location pattern. It contains the location that was matched and the data
extracted from the path according to the location's pattern.

=head1 INTERFACE

=head2 Attributes

=head3 location

The L<Gears::Router::Location> object that was matched.

I<Required in constructor>

=head3 matched

An array reference containing the values extracted from the matched path. The
order and meaning of these values depend on the pattern tokens defined in the
location's L<Gears::Router::Pattern> object.

I<Required in constructor>

=head2 Methods

=head3 new

	$object = $class->new(%args)

A standard Mooish constructor. Consult L</Attributes> section to learn what
keys can key passed in C<%args>.

