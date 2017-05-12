# Declare our package
package Games::AssaultCube::ServerQuery;

# import the Moose stuff
use Moose;
use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# get some utility stuff
use Games::AssaultCube::Utils qw( default_port tostr get_ac_pingport );
use Games::AssaultCube::ServerQuery::Response;
use IO::Socket::INET;

# TODO make validation so we accept either hostname or IPv4/6...
has 'server' => (
	isa		=> 'Str',
	is		=> 'ro',
	required	=> 1,
);

# <mst> Apocalypse: { my $port_spec = subtype as Int => where { ... }; has 'attr' => (isa => $port_spec, ...); }
{
	my $port_type = subtype as 'Int' => where {
		if ( $_ <= 0 or $_ > 65535 ) {
			return 0;
		} else {
			return 1;
		}
	};

	has 'port' => (
		isa		=> $port_type,
	#	isa		=> 'Int',
		is		=> 'rw',
		default		=> default_port(),
	);
}

has 'timeout' => (
	isa		=> 'Int',
	is		=> 'rw',
	default 	=> 30,
);

has 'get_players' => (
	isa		=> 'Bool',
	is		=> 'rw',
	default		=> 0,
);

sub BUILDARGS {
	my $class = shift;

	if ( @_ == 1 && ! ref $_[0] ) {
		# set the server as the first argument
		return { server => $_[0] };
	} elsif ( @_ == 2 && ! ref $_[0] ) {
		# server/port argument
		return { server => $_[0], port => $_[1] };
	} else {
		# normal hash/hashref way
		return $class->SUPER::BUILDARGS(@_);
	}
}

sub run {
	my $self = shift;

	# Ok, get our socket and send off the PING!
	my $sock = IO::Socket::INET->new(
		Proto		=> 'udp',
		PeerPort	=> get_ac_pingport( $self->port ),
		PeerAddr	=> $self->server,
	) or die "Could not create socket: $!";
	binmode $sock, ":utf8" or die "Unable to set binmode: $!";

	# generate the PING packet
	# TODO support the EXT_XYZ options
	my $pingpacket;
	if ( $self->get_players ) {
		$pingpacket = tostr('1') . tostr('1');
	} else {
		$pingpacket = tostr('1') . tostr('0');
	}

	# send it!
	$sock->send( $pingpacket ) or die "Unable to send: $!";

	# set the alarm, and wait for the response
	my( $datagram, $result );
	eval {
		# perldoc -f alarm says I need to put \n in the die... weird!
		local $SIG{ALRM} = sub { die "alarm\n" };
		alarm $self->timeout;
		$result = $sock->recv( $datagram, 1024 ) or die "Unable to recv: $!";
		alarm 0;
	};
	if ( $@ ) {
		if ( $@ =~ /^alarm/ ) {
			die "Unable to query server: Timed out";
		} else {
			die "Unable to query server: $@";
		}
	} else {
		if ( defined $result and defined $datagram and length( $datagram ) > 0 ) {
			return Games::AssaultCube::ServerQuery::Response->new( $self, $datagram );
		} else {
			return;
		}
	}
}

# from Moose::Manual::BestPractices
no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=for stopwords PxL playerlist PHP hostname ip

=head1 NAME

Games::AssaultCube::ServerQuery - Queries a running AssaultCube server for information

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

This module queries a running AssaultCube server for information.

=head1 DESCRIPTION

This module queries a running AssaultCube server for information. This has been tested extensively on
AssaultCube-1.0.2 servers, so beware if you try older/newer ones! Also, not all servers return all data, so
be sure to check for it in your code...

=head2 Constructor

This module uses Moose, so you can pass either a hash, hashref, or a server/port to the constructor. Passing
a string means we're passing in a server hostname/ip. If you want to specify more options, please use the
hash/hashref method.

The attributes are:

=head3 server

The server hostname or ip.

=head3 port

The server port. Defaults to 28763.

WARNING: AssaultCube uses $port+1 for the query port. Please do not do pass $port+1 to the constructor,
we do it internally. Maybe in the future AC will use $port+2 or another system, so let us deal with it :)

=head3 get_players

Should we also retrieve the playerlist? This is a boolean which defaults to false.

=head3 timeout

The timeout waiting for the server response in seconds. Defaults to 30.

WARNING: We use alarm() internally to do the timeout. If you used it somewhere else, it will cause conflicts
and potentially render it useless. Please inform me if there's conflicts in your script and we can try to
work around it.

=head2 Methods

Currently, there is only one method: run(). You call this and get the response object back. For more
information please look at the L<Games::AssaultCube::ServerQuery::Response> class. You can call run() as
many times as you want, no need to re-instantiate the object for each query.

WARNING: run() will die() if errors happen. For sanity, you should wrap it in an eval.

=head2 Attributes

You can modify some attributes before calling run() on the object. They are:

=head3 port

Same as the constructor

=head3 timeout

Same as the constructor

=head3 get_players

Same as the constructor

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

Props goes to Getty and the BS clan for the support!

This project is sponsored by L<http://cubestats.net>

Also, thanks goes out to PxL for the initial PHP implementation which helped in unraveling the AssaultCube
mess.

We also couldn't have done it without staring at the AssaultCube C++ code for hours, ha!

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
