# Declare our package
package Games::AssaultCube::Log::Line::MapError;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::GameMode';

# TODO improve validation for everything here, ha!

has 'map' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'error' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Error loading map " . $self->map . ": " . $self->error;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CTF TDM gamemode
=head1 NAME

Games::AssaultCube::Log::Line::MapError - Describes the MapError event in a log line

=head1 ABSTRACT

Describes the MapError event in a log line

=head1 DESCRIPTION

This module holds the "MapError" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server has an error with a map.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 map

The map name with the error

=head3 gamemode

The numeric AssaultCube gamemode ( look at L<Games::AssaultCube::Utils> for more info )

P.S. It's better to use the gamemode_fullname or gamemode_name accessors

=head3 gamemode_name

The gamemode name ( CTF, TDM, etc )

=head3 gamemode_fullname

The full gamemode name ( "capture the flag", "team one shot one kill", etc )

=head3 error

The map error string

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
