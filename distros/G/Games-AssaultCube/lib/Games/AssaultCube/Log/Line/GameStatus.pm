# Declare our package
package Games::AssaultCube::Log::Line::GameStatus;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::MasterMode',
	'Games::AssaultCube::Log::Line::Base::GameMode';

# TODO improve validation for everything here, ha!

has 'map' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'minutes' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'finished' => (
	isa		=> 'Bool',
	is		=> 'ro',
	required	=> 1,
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return "GameStatus: map " . $self->map . " with " . $self->minutes . " minutes left in gamemode " . $self->gamemode_fullname;
	},
);

# TODO Moose can't export multiple roles into this class unless it defines BUILD...
# Error:  'Games::AssaultCube::Log::Line::Base::Mastermode|Games::AssaultCube::Log::Line::Base::Gamemode' requires the method 'BUILD' to be implemented by 'Games::AssaultCube::Log::Line::GameStatus' at /usr/local/share/perl/5.10.0/Moose/Meta/Role/Application.pm line 59
sub BUILD {
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CTF NUM TDM gamemode mastermode
=head1 NAME

Games::AssaultCube::Log::Line::GameStatus - Describes the GameStatus event in a log line

=head1 ABSTRACT

Describes the GameStatus event in a log line

=head1 DESCRIPTION

This module holds the "GameStatus" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted once in a while as the AC server goes through the game.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 gamemode

The numeric AssaultCube gamemode ( look at L<Games::AssaultCube::Utils> for more info )

P.S. It's better to use the gamemode_fullname or gamemode_name accessors

=head3 gamemode_name

The gamemode name ( CTF, TDM, etc )

=head3 gamemode_fullname

The full gamemode name ( "capture the flag", "team one shot one kill", etc )

=head3 map

The map name ( sometimes it's a zero-length string... )

=head3 minutes

The number of minutes remaining in the game

=head3 mastermode

The numeric AssaultCube mastermode of the server

	0 = OPEN
	1 = PRIVATE ( passworded )
	2 = NUM ( full )

=head3 mastermode_name

The name of the mastermode on the server ( OPEN, PRIVATE, NUM )

=head3 finished

A boolean indicating if the game is finished or not

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
