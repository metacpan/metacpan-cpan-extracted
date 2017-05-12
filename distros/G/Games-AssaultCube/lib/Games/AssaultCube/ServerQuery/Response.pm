# Declare our package
package Games::AssaultCube::ServerQuery::Response;

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# get some utility stuff
use Games::AssaultCube::Utils qw( parse_pingresponse default_port getpongflag stripcolors );

# This is a bit "weird" but very convenient, ha!
with	'Games::AssaultCube::Log::Line::Base::GameMode';

# TODO improve validation for everything here, ha!

has 'server' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'port' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'pingtime' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'query' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'protocol' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'players' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'minutes_left' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'map' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'desc' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'desc_nocolor' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return stripcolors( $self->desc );
	},
);

has 'max_players' => (
	isa		=> 'Int',
	is		=> 'ro',
	required	=> 1,
);

has 'pong' => (
	isa		=> 'Int',
	is		=> 'ro',
	default		=> 0,
);

has 'pong_name' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return getpongflag( $self->pong );
	},
);

has 'player_list' => (
	isa		=> 'ArrayRef[Str]',
	is		=> 'ro',
	default		=> sub { [] },
);

has 'is_full' => (
	isa		=> 'Bool',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		if ( $self->players == $self->max_players ) {
			return 1;
		} else {
			return 0;
		}
	},
);

has 'datagram' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

has 'tohash' => (
	isa		=> 'HashRef',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		my $data = {};

		foreach my $attr ( qw( timestamp gamemode server port pingtime protocol players minutes_left map desc max_players ) ) {
			$data->{ $attr } = $self->$attr();
		}

		# extra data
		if ( scalar @{ $self->player_list } ) {
			$data->{player_list} = [ @{ $self->player_list } ];
		} else {
			$data->{player_list} = [];
		}

		return $data;
	},
);

has 'timestamp' => (
	isa		=> 'Int',
	is		=> 'ro',
	default		=> sub {
		scalar time();
	},
);

sub BUILDARGS {
	my $class = shift;

	# Normally, we would be created by Games::AssaultCube::ServerQuery and contain 2 args
	if ( @_ == 2 && ref $_[0] ) {
		if ( ref( $_[0] ) eq 'Games::AssaultCube::ServerQuery' ) {
			# call the parse method
			return {
				server		=> $_[0]->server,
				port		=> $_[0]->port,
				datagram	=> $_[1],
				%{ parse_pingresponse( $_[1] ) },
			};
		} elsif ( ref( $_[0] ) eq 'POE::Component::AssaultCube::ServerQuery' ) {
			# parse it a bit differently
			return {
				server		=> $_[1]->{addr},
				port		=> $_[1]->{port},
				datagram	=> $_[1]->{payload}->[0],
				%{ parse_pingresponse( $_[1]->{payload}->[0] ) },
			};
		} else {
			die "unknown arguments";
		}
	} else {
		return $class->SUPER::BUILDARGS(@_);
	}
}

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords CTF TDM desc gamemode pingtime pingmode pongflag pongflags tohash pong timestamp

=head1 NAME

Games::AssaultCube::ServerQuery::Response - Holds the various data from a ServerQuery response

=head1 SYNOPSIS

	use Games::AssaultCube::ServerQuery;
	my $query = Games::AssaultCube::ServerQuery->new( 'my.server.com' );
	#my $query = Games::AssaultCube::ServerQuery->new( 'my.server.com', 12345 );
	#my $query = Games::AssaultCube::ServerQuery->new({ server => 'foo.com', port => 12345, timeout => 5 });
	my $response = $query->run;
	if ( defined $response ) {
		print "Server is running with " . $response->players . " players\n";
	} else {
		print "Server is not responding!\n";
	}

=head1 ABSTRACT

This module holds the various data from a ServerQuery response.

=head1 DESCRIPTION

This module holds the response data from an AssaultCube ServerQuery. Normally you will not use this class
directly, but via the L<Games::AssaultCube::ServerQuery> class.

=head2 Attributes

You can get the various data by fetching the attribute. Valid attributes are:

=head3 server

The server hostname/ip

=head3 port

The server port

WARNING: AssaultCube uses $port+1 for the query port. Please do not do pass $port+1 to the constructor,
we do it internally. Maybe in the future AC will use $port+2 or another system, so let us deal with it :)

=head3 pingtime

The AssaultCube-specific pingtime counter

=head3 query

The AssaultCube-specific query number we used to PING the server

=head3 protocol

The AssaultCube server protocol version

=head3 gamemode

The numeric AssaultCube gamemode ( look at L<Games::AssaultCube::Utils> for more info )

P.S. It's better to use the gamemode_fullname or gamemode_name accessors

=head3 gamemode_name

The gamemode name ( CTF, TDM, etc )

=head3 gamemode_fullname

The full gamemode name ( "capture the flag", "team one shot one kill", etc )

=head3 players

The number of players currently on the server

=head3 minutes_left

The number of minutes left on the server

=head3 map

The map that's running on the server

=head3 desc

The description of the server

=head3 desc_nocolor

The description of the server, with any AssaultCube-specific colors removed

=head3 max_players

The maximum number of players this server can accept

=head3 pong

The AssaultCube-specific pongflags number

P.S. It's better to use the pong_name accessor

=head3 pong_name

The AssaultCube-specific pongflag name

=head3 player_list

An arrayref of players on the server

P.S. Don't forget to enable get_players in the constructor to L<Games::AssaultCube::ServerQuery>, it
defaults to an empty arrayref.

=head3 is_full

Returns a boolean value whether the server is full or not

=head3 datagram

The actual packet we received from the server

=head3 tohash

A convenience accessor returning "vital" data in a hashref for easy usage

=head3 timestamp

The UNIX timestamp when this response object was generated

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
