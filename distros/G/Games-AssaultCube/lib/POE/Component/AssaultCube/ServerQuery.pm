# Declare our package
package POE::Component::AssaultCube::ServerQuery;

# import the Moose stuff
use MooseX::POE::SweetArgs;
use MooseX::StrictConstructor;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# get some utility stuff
use Games::AssaultCube::ServerQuery::Response;
use POE::Component::AssaultCube::ServerQuery::Server;
use Games::AssaultCube::Utils qw( tostr get_ac_pingport );

# We need some POE stuff
use POE::Wheel::UDP;
use POE::Filter::Stream;
use Socket qw( INADDR_ANY );
use Time::HiRes qw( time );

# TODO improve validation for everything here, ha!

has 'alias' => (
	isa		=> 'Str',
	is		=> 'ro',
	lazy		=> 1,
	default		=> sub {
		my $self = shift;
		return 'ServerQuery-' . $self->get_session_id;
	},
);

has 'wheel' => (
	isa		=> 'Maybe[POE::Wheel::UDP]',
	is		=> 'rw',
	default		=> undef,
);

has 'watchers' => (
	isa		=> 'HashRef',
	is		=> 'ro',
	default		=> sub { {} },
);

has 'servers' => (
	isa		=> 'HashRef',
	is		=> 'ro',
	default		=> sub { {} },
);

has 'throttle' => (
	isa		=> 'Num',
	is		=> 'rw',
	default		=> 0.25,
);

# add this session to the watchers
sub register {
	my( $self, $session, $event ) = @_;

	if ( ! defined $session ) {
		# take from current session ID?
		$session = $poe_kernel->get_active_session;
		if ( defined $session ) {
			if ( $session->isa( 'POE::Kernel' ) ) {
				# no session running
				return;
			}
		} else {
			return;
		}
	}

	# set the default
	$event = 'ac_ping' if ! defined $event;
	$session = $session->ID if ref $session;

#warn "$session registered as a watcher\n";

	$self->watchers->{ $session } = $event;
	return 1;
}

sub unregister {
	my( $self, $session ) = @_;

	if ( ! defined $session ) {
		# take from current session ID?
		$session = $poe_kernel->get_active_session;
		if ( defined $session ) {
			if ( $session->isa( 'POE::Kernel' ) ) {
				# no session running
				return;
			}
		} else {
			return;
		}
	}

	$session = $session->ID if ref $session;

#warn "$session unregistered as a watcher\n";

	if ( exists $self->watchers->{ $session } ) {
		delete $self->watchers->{ $session };
		return 1;
	} else {
		return;
	}
}

sub addserver {
	my $self = shift;

	# sanity
	my $server;
	if ( defined $_[0] ) {
		if ( ref $_[0] and ref( $_[0] ) eq 'POE::Component::AssaultCube::ServerQuery::Server' ) {
			$server = $_[0];
		} else {
			# convert it into an object
			eval {
				$server = POE::Component::AssaultCube::ServerQuery::Server->new( @_ );
			};
			if ( $@ ) {
				die "invalid server data: $@";
			}
			if ( ! defined $server ) {
				die "unable to parse server data";
			}
		}
	} else {
		return;
	}

	if ( exists $self->servers->{ $server->ID } ) {
		return;
	} else {
#warn "added server " . $server->ID;

		# start pinging this server
		$self->servers->{ $server->ID } = $server;
		$poe_kernel->call( $self->get_session_id, 'start_pinger_delay' );
		return $server;
	}
}

sub delserver {
	my $self = shift;

	# sanity
	my $server;
	if ( defined $_[0] ) {
		if ( ref $_[0] and ref( $_[0] ) eq 'POE::Component::AssaultCube::ServerQuery::Server' ) {
			$server = $_[0];
		} else {
			# convert it into an object
			eval {
				$server = POE::Component::AssaultCube::ServerQuery::Server->new( @_ );
			};
			if ( $@ ) {
				die "invalid server data: $@";
			}
			if ( ! defined $server ) {
				die "unable to parse server data";
			}
		}
	} else {
		return;
	}

	if ( exists $self->servers->{ $server->ID } ) {
#warn "deleted server " . $server->ID;

		delete $self->servers->{ $server->ID };
		$poe_kernel->call( $self->get_session_id, 'start_pinger_delay' );
		return 1;
	} else {
		return;
	}
}

sub STARTALL {
	my $self = shift;

#warn "in STARTALL";

	$poe_kernel->alias_set( $self->alias );

	# should we fire up the pinger?
	if ( keys %{ $self->servers } ) {
		$poe_kernel->post( $self->get_session_id, 'start_pinger_delay' );
	}

	return;
}

sub STOPALL {
	my $self = shift;

#warn "in STOPALL";

	return;
}

sub make_wheel {
	my $self = shift;

	# sanity
	return if defined $self->wheel;

#warn "creating POE::Wheel::UDP";

	$self->wheel( POE::Wheel::UDP->new(
		LocalAddr => '0.0.0.0',
		LocalPort => INADDR_ANY,
		InputEvent => 'wheel_input',
		Filter => POE::Filter::Stream->new,
	) );

	# be evil but we need to do this...
	binmode $self->wheel->{sock}, ":utf8" or die "Unable to set binmode: $!";

	return;
}

event start_pinger_delay => sub {
	my $self = shift;

	$poe_kernel->delay( 'start_pinger' => 0.1 );
	return;
};

event start_pinger => sub {
	my $self = shift;

	# okay, get the next server timeout
	my( $server, $nexttime ) = $self->get_next_server;
	if ( defined $server ) {
		# do we have a wheel?
		if ( ! defined $self->wheel ) {
			$self->make_wheel;
			$poe_kernel->delay( 'start_pinger' => 1 );
			return;
		}

		if ( $nexttime != 0 and $nexttime < $self->throttle ) {
			$nexttime = $self->throttle;

#warn "THROTTLE HIT!";

		}
		$nexttime = 0 if $nexttime < 0;

#warn "server(" . $server->ID . ") selected with $nexttime";

		if ( $nexttime == 0 or $self->throttle == 0 ) {
			$self->ping_server( $server );

			# ping the next available server
			$poe_kernel->delay( 'start_pinger' => 0 );
		} else {
#warn "sleeping for $nexttime secs";
			$poe_kernel->delay( 'start_pinger' => $nexttime );
		}
	} else {
		# no server, wait until we add a server
		$poe_kernel->alarm_remove_all;
		$self->wheel( undef );

#warn "no server, waiting until addserver";

	}

	return;
};

sub get_next_server {
	my $self = shift;

	# shortcut
	if ( keys %{ $self->servers } == 0 ) {
		return;
	}

	# okay, we order servers by last_pingtime and in respect to their pingfreq
	my @servers = sort { $a->[1] <=> $b->[1] }
		map { [ $_, $_->nextping() ] } values %{ $self->servers };

#use Data::Dumper;
#print Dumper( \@servers );

	# return the first server
	return( $servers[0]->[0], $servers[0]->[1] );
}

sub ping_server {
	my( $self, $server ) = @_;

	# actually ping it!
	my $datagram;
	if ( $server->get_players ) {
		$datagram = tostr('1') . tostr('1');
	} else {
		$datagram = tostr('1') . tostr('0');
	}

#warn "pinging " . $server->ID;

	# send it!
	eval {
		$self->wheel->put( {
			payload	=> [ $datagram ],
			addr	=> $server->server,
			port	=> get_ac_pingport( $server->port ),
		} );
	};

	# set the lastpingtime
	$server->last_pingtime( time() );

	return;
}

event 'wheel_input' => sub {
	my( $self, $input, $wheel_id ) = @_;

	return if ! length $input;

	# make the server ID
	# TODO we hardcode the "$port - 1" behavior...
	$input->{ID} = $input->{addr} . ':' . ( $input->{port} - 1 );

	# do we know this server?
	if ( exists $self->servers->{ $input->{ID} } ) {
		# yay, got a ping back!
		$self->process_ping( $input );
	} else {
		# hm, unknown ping...
		warn "unknown DATA from $input->{ID}";
	}

	return;
};

sub shutdown {
	my $self = shift;
	$poe_kernel->post( $self->get_session_id, 'do_shutdown' );

	return;
}

event 'do_shutdown' => sub {
	my $self = shift;

	# cleanup
	$poe_kernel->alias_remove( $self->alias );
	$self->wheel( undef );
	$poe_kernel->alarm_remove_all;

	return;
};

sub process_ping {
	my( $self, $input ) = @_;

#use Data::Dumper;
#warn "got ping reply: " . Dumper( $input );
#
#use Data::HexDump;
#print HexDump( $input->{payload}->[0] );

	# okay, convert it into a response object
	my $response;
	eval {
		$response = Games::AssaultCube::ServerQuery::Response->new( $self, $input );
	};
	if ( $@ ) {
		warn "unable to parse DATA from $input->{ID}: $@";
	};

	# pass it on to the watchers
	foreach my $w ( keys %{ $self->watchers } ) {
#warn "informing watcher $w of ping";

		$poe_kernel->post( $w, $self->watchers->{ $w }, $self->servers->{ $input->{ID} }, $response );
	}

	return;
}

sub clearservers {
	my $self = shift;

	# get rid of all servers and reset the timer
	%{ $self->servers } = ();
	$poe_kernel->call( $self->get_session_id, 'start_pinger_delay' );

	return;
}

# from Moose::Manual::BestPractices
no MooseX::POE;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords addserver clearservers delserver serverlist

=head1 NAME

POE::Component::AssaultCube::ServerQuery - Queries a running AssaultCube server for information

=head1 SYNOPSIS

	use POE qw( Component::AssaultCube::ServerQuery );

	sub _start {
		$_[HEAP]->{query} = POE::Component::AssaultCube::ServerQuery->new;
		$_[HEAP]->{query}->register( $_[SESSION], 'got_ping_data' );
		$_[HEAP]->{query}->addserver( '123.123.123.123' );
	}

	sub got_ping_data {
		my( $server, $response ) = @_[ARG0, ARG1];
		if ( defined $response ) {
			print "response from(" . $server->ID . "): " $response->desc_nocolor .
				" - " . $response->players . " players running\n";
		} else {
			print "server " . $server->ID . " is not responding\n";
		}
	}

=head1 ABSTRACT

This module queries a running AssaultCube server for information.

=head1 DESCRIPTION

This module is a wrapper around the L<Games::AssaultCube::ServerQuery> logic and encapsulates the
raw POE details. Furthermore, this module can ping many servers in parallel.

This module gives you full control of throttling, and per-server ping frequency ( how often to ping
the server ) plus a nice object front-end!

Normal usage of this component is to create an object, then add your serverlist to the object. Then
you would have to register your session to receive responses. During run-time you can add/remove servers
from the list, and finally shutdown the object/session.

NOTE: While you can create several ServerQuery objects and use them, it is more optimal to create only
one object and put all servers there. ( This theory is unbenchmarked, ha! )

This module does not enforce timeouts per server, it gives you a "raw" feed of pings every $frequency
seconds. It is up to the application logic to see if a ping failed or not. This is trivial with the
appropriate use of timers :) However, patches welcome if you want the server to have individual timeouts.
It will not change the logic in the application event "ac_ping" because it already checks for a defined
value.

This module sets an alias to be "long-lived" and creates/destroys the L<POE::Wheel::UDP> object only
when necessary.

=head2 Constructor

This module uses Moose, so you can pass either a hash or hashref to the constructor.

The attributes are:

=head3 throttle

A number in seconds ( can be floating-point )

How long we should wait before sending the next ping. Useful for flood-control!

Default: 0.25

NOTE: You can set it to 0 to disable this feature

=head3 alias

The POE session alias we will use

Default: 'ServerQuery-' . $_[SESSION]->ID

=head2 Methods

Once instantiated, you can do various operations on the object.

=head3 addserver

Adds a server to be monitored to the list. Arguments are passed on to the
L<POE::Component::AssaultCube::ServerQuery::Server> constructor. Returns the server
object or undef if it was already in the list. Will die if it encounters errors.

	$query->addserver( "123.123.123.123" );
	$query->addserver( "123.123.123.123", 12345 );
	$query->addserver({ server => "123.123.123.123", port => 12345, frequency => 60 });

Adding a server automatically sends a ping, then waits for $frequency seconds before sending the next
one.

=head3 delserver

Deletes a server from the monitoring list. You can either pass in a
L<POE::Component::AssaultCube::ServerQuery::Server> object ref or the arguments will be converted
internally into the object. From there we will see if the server is in the list, returns 1 if it is;
returns undef otherwise.

=head3 register

Adds a "watcher" session that will receive ping replies. Accepts a session ID/alias/reference, and the
event name.

The session defaults to the running POE session, if there is one

The event name defaults to "ac_ping"

=head3 unregister

Removes a "watcher" session from the list. Accepts a session ID/alias/reference.

=head3 shutdown

Initiates shutdown procedures and destroys the associated session

=head3 clearservers

Removes all servers from the list and ceases pinging servers

=head2 POE events

You can post events to this component too. You can get the session id:

	$poe_kernel->post( $query->get_session_id, ... );

=head3 do_shutdown

Initiates shutdown procedures and destroys the associated session

=head2 PING data

You receive the ping replies via the session/event you registered. There is no "filtering" capability
and you get replies for all servers.

The event handler gets 2 arguments: the server object, and the response. The server object is the
L<POE::Component::AssaultCube::ServerQuery::Server> module. The response can either be
undef or a L<Games::AssaultCube::ServerQuery::Response> object.

Here's a sample ping handler:

	sub got_ping_data {
		my( $server, $response ) = @_[ARG0, ARG1];
		if ( defined $response ) {
			print "response from(" . $server->ID . "): " $response->desc_nocolor .
				" - " . $response->players . " players running\n";
		} else {
			print "server " . $server->ID . " is not responding\n";
		}
	}

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
