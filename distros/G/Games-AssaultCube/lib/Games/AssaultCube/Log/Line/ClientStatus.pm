# Declare our package
package Games::AssaultCube::Log::Line::ClientStatus;

# import the Moose stuff
use Moose;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

extends 'Games::AssaultCube::Log::Line::Base';

with	'Games::AssaultCube::Log::Line::Base::TeamInfo',
	'Games::AssaultCube::Log::Line::Base::RoleInfo',
	'Games::AssaultCube::Log::Line::Base::NickIP';

# TODO improve validation for everything here, ha!

has 'cn' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'frags' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'deaths' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'flags' => (
	isa		=> 'Int',
	is		=> 'ro',
);

has 'tostr' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;

		# we want nicely-formatted output
		return sprintf( "Client status of %25s (%4s): %3d frags, %3d deaths%s", $self->nick, $self->team_name, $self->frags, $self->deaths, ( defined $self->flags ? sprintf( ", %d flags", $self->flags ) : "" ) );
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

=for stopwords CLA RVSF ADMIN cn frags gamemode ip

=head1 NAME

Games::AssaultCube::Log::Line::ClientStatus - Describes the ClientStatus event in a log line

=head1 ABSTRACT

Describes the ClientStatus event in a log line

=head1 DESCRIPTION

This module holds the "ClientStatus" event data from a log line. Normally, you would not use this class directly
but via the L<Games::AssaultCube::Log::Line> class.

This line is emitted once in a while as the AC server goes through the game.

=head2 Attributes

Those attributes hold information about the event. As this class extends the L<Games::AssaultCube::Log::Line::Base>
class, you can also use it's attributes too.

=head3 cn

The client connection id

=head3 nick

The nick of the client

=head3 team

The id of the client's team

	0 = CLA
	1 = RVSF
	2 = NONE

=head3 team_name

The team name of the client ( CLA, RVSF, NONE )

=head3 frags

The number of frags this client has done

=head3 deaths

The number of deaths this client has done

=head3 flags

The number of flags taken ( not always defined - depends on gamemode )

=head3 role

The id of the client's role

	0 = DEAFULT
	1 = ADMIN

=head3 role_name

The role name of the client ( DEFAULT, ADMIN )

=head3 ip

The ip of the client

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
