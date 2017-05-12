# Declare our package
package Games::AssaultCube::Log::Line::DemoStop;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::GameMode';

# TODO improve validation for everything here, ha!

has 'datetime' => (
	isa		=> 'DateTime',
	is		=> 'ro',
	required	=> 1,
);

has 'map' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'size' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "Stopped recording demo: " . $self->size . " bytes, map " . $self->map . ", gamemode " . $self->gamemode_fullname . " at " . $self->datetime->datetime;
	},
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CTF TDM gamemode datetime

=head1 NAME

Games::AssaultCube::Log::Line::DemoStop - Describes the DemoStop event in a log line

=head1 ABSTRACT

Describes the DemoStop event in a log line

=head1 DESCRIPTION

This module holds the "DemoStop" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted when the AC server stops recording a demo.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 datetime

The DateTime object representing the time when the server stopped recording the demo

=head3 gamemode

The numeric AssaultCube gamemode ( look at L<Games::AssaultCube::Utils> for more info )

P.S. It's better to use the gamemode_fullname or gamemode_name accessors

=head3 gamemode_name

The gamemode name ( CTF, TDM, etc )

=head3 gamemode_fullname

The full gamemode name ( "capture the flag", "team one shot one kill", etc )

=head3 map

The map name

=head3 size

The size of the demo ( in bytes )

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
