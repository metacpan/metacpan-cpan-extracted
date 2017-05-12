package Mail::Karmasphere::Client;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS
				%QUEUE @QUEUE $QUEUE);
use Exporter;
use Data::Dumper;
use Convert::Bencode qw(bencode bdecode);
use IO::Socket::INET;
use Time::HiRes;
use IO::Select;
use Socket;
use constant {
	IDT_IP4_ADDRESS		=> "ip4",
	IDT_IP6_ADDRESS		=> "ip6",
	IDT_DOMAIN_NAME		=> "domain",
	IDT_EMAIL_ADDRESS	=> "email",

	IDT_IP4				=> "ip4",
	IDT_IP6				=> "ip6",
	IDT_DOMAIN			=> "domain",
	IDT_EMAIL			=> "email",
	IDT_URL				=> "url",
};
use constant {
	AUTHENTIC					=> "a",
	SMTP_CLIENT_IP				=> "smtp.client-ip",
	SMTP_ENV_HELO				=> "smtp.env.helo",
	SMTP_ENV_MAIL_FROM			=> "smtp.env.mail-from",
	SMTP_ENV_RCPT_TO			=> "smtp.env.rcpt-to",
	SMTP_HEADER_FROM_ADDRESS	=> "smtp.header.from.address",

	FL_FACTS		=> 1,
	FL_DATA			=> 2,
	FL_TRACE		=> 4,
	FL_MODELTRACE	=> 8,
};
use constant {
	PROTO_TCP		=> 0+getprotobyname('tcp'),
	PROTO_UDP		=> 0+getprotobyname('udp'),
};

BEGIN {
	@ISA = qw(Exporter);
	$VERSION = "2.18";
	@EXPORT_OK = qw(
					IDT_IP4_ADDRESS IDT_IP6_ADDRESS
					IDT_DOMAIN_NAME IDT_EMAIL_ADDRESS

					IDT_IP4 IDT_IP6
					IDT_DOMAIN IDT_EMAIL
					IDT_URL

					AUTHENTIC
					SMTP_CLIENT_IP
					SMTP_ENV_HELO SMTP_ENV_MAIL_FROM SMTP_ENV_RCPT_TO
					SMTP_HEADER_FROM_ADDRESS

					FL_FACTS
					FL_DATA
					FL_TRACE
					FL_MODELTRACE
				);
	%EXPORT_TAGS = (
		'all' => \@EXPORT_OK,
		'ALL' => \@EXPORT_OK,
	);
	%QUEUE = ();
	@QUEUE = ();
	$QUEUE = 100;
}

# We can't use these until we set up the above variables.
use Mail::Karmasphere::Query;
use Mail::Karmasphere::Response;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	if ($self->{Debug} and ref($self->{Debug}) ne 'CODE') {
		$self->{Debug} = sub { print STDERR Dumper(@_); };
	}
	$self->{Debug}->('new', $self) if $self->{Debug};

	unless ($self->{Socket}) {
		$self->{Proto} = 'udp'
						unless defined $self->{Proto};
		$self->{PeerAddr} = $self->{PeerHost}
						unless defined $self->{PeerAddr};
		$self->{PeerAddr} = 'query.karmasphere.com'
						unless defined $self->{PeerAddr};
		$self->{PeerPort} = 8666
						unless $self->{Port};
		_connect($self);
	}

	return bless $self, $class;
}

sub _connect {
	my $self = shift;
	$self->{Debug}->('connect') if $self->{Debug};
	$self->{Socket} = new IO::Socket::INET(
		Proto			=> $self->{Proto},
		PeerAddr		=> $self->{PeerAddr},
		PeerPort		=> $self->{PeerPort},
		ReuseAddr		=> 1,
	);
	unless (defined $self->{Socket}) {
		delete $self->{Socket};
		my @args = map { "$_=" . $self->{$_} } keys %$self;
		die "Failed to create socket: $! (@args)";
	}
}

sub query {
	my $self = shift;
	return $self->ask(new Mail::Karmasphere::Query(@_));
}

sub _previous_socket {
	my $self = shift;
	return undef unless exists $self->{PreviousTime};
	if ($self->{PreviousTime} + 10 > time()) {
		$self->{Debug}->('previous') if $self->{Debug};
		return $self->{PreviousSocket}
	}
	delete $self->{PreviousSocket};
	delete $self->{PreviousTime};
	return undef;
}

sub _is_tcp {
	my ($self, $socket) = @_;
	return $socket->protocol == PROTO_TCP;
}

sub _send_real {
	my ($self, $data) = @_;

	my $socket = $self->{Socket};

	if ($socket->protocol == PROTO_UDP) {
		if (length $data > 1024) {	# Server's UDP_MAX
			$self->{Debug}->('fallback') if $self->{Debug};
			$self->{PreviousSocket} = $self->{Socket};
			$self->{PreviousTime} = time();
			$self->{Proto} = 'tcp';
			# XXX This loses the old socket and any queries
			# sent thereon.
			$self->_connect();
			$socket = $self->{Socket};
		}
	}
	# This can NOT be an else as we clobber the variable above.
	if ($socket->protocol == PROTO_TCP) {
		$self->{Debug}->('tcp prefix') if $self->{Debug};
		$data = pack("N", length($data)) . $data;
		$self->{Debug}->('send_real', $data) if $self->{Debug};
	}
	$socket->send($data)
					or die "Failed to send to socket: $!";
}

sub send {
	my ($self, $query) = @_;

	die "Not blessed reference: $query"
			unless ref($query) =~ /[a-z]/;
	die "Not a query: $query"
			unless $query->isa('Mail::Karmasphere::Query');

	$self->{Debug}->('send_query', $query) if $self->{Debug};

	my $id = $query->id;

	my $packet = {
		_	=> $id,
	};
	$packet->{i} = $query->identities if $query->has_identities;
	$packet->{s} = $query->composites if $query->has_composites;
	$packet->{f} = $query->feeds if $query->has_feeds;
	$packet->{c} = $query->combiners if $query->has_combiners;
	$packet->{fl} = $query->flags if $query->has_flags;
	if (defined $self->{Principal}) {
		my $creds = defined $self->{Credentials} ?$self->{Credentials} : '';
		$packet->{a} = [ $self->{Principal}, $creds ];
	}
	$self->{Debug}->('send_packet', $packet) if $self->{Debug};

	my $data = bencode($packet);
	$self->{Debug}->('send_data', $data) if $self->{Debug};

	$self->_send_real($data);

	return $id;
}

sub _recv_real {
	my ($self, $socket) = @_;

	my $data;
	if ($socket->protocol == PROTO_TCP) {
		$socket->read($data, 4)
					or die "Failed to receive length from socket: $!";
		my $length = unpack("N", $data);
		$data = '';
		while ($length > 0) {
			my $block;
			my $bytes = $socket->read($block, $length)
						or die "Failed to receive data from socket: $!";
			$data .= $block;
			$length -= $bytes;
		}
		$self->{Debug}->('recv_data', $data) if $self->{Debug};
	}
	else {
		$socket->recv($data, 8192)
					or die "Failed to receive from socket: $!";
		$self->{Debug}->('recv_data', $data) if $self->{Debug};
	}
	my $packet = bdecode($data);
	die $packet unless ref($packet) eq 'HASH';

	my $response = new Mail::Karmasphere::Response($packet);
	$self->{Debug}->('recv_response', $response) if $self->{Debug};
	return $response;
}

sub recv {
	my ($self, $query, $timeout) = @_;

	my $id = ref($query) ? $query->id : $query;
	if (defined($id)) {
		if ($QUEUE{$id}) {
			$self->{Debug}->('recv_find', $id, $QUEUE{$id})
							if $self->{Debug};
			@QUEUE = grep { $_ ne $id } @QUEUE;
			return delete $QUEUE{$id};
		}
	}
	else {
		if (@QUEUE) {
			$id = shift @QUEUE;
			return delete $QUEUE{$id};
		}
	}

	$timeout = 10 unless defined $timeout;
	my $finish = time() + $timeout;
	my $select = new IO::Select();
	$select->add($self->{Socket});
	my $prev = $self->_previous_socket;
	$select->add($prev) if $prev;
	while ($timeout > 0) {
		my @ready = $select->can_read($timeout);

		if (@ready) {
			my $response = $self->_recv_real($ready[0]);
			$response->{query} = $query if ref $query;
			return $response unless defined $id;
			return $response if $response->id eq $id;

			my $rid = $response->id;
			push(@QUEUE, $rid);
			$QUEUE{$rid} = $response;
			if (@QUEUE > $QUEUE) {
				my $oid = shift @QUEUE;
				delete $QUEUE{$oid};
			}
		}

		$timeout = $finish - time();
	}

	print STDERR "Failed to receive from socket: $!\n";
	return undef;
}

sub ask {
	my ($self, $query, $timeout) = @_;
	$timeout = 5 unless defined $timeout;
	for (0..2) {
		my $id = $self->send($query);
		my $response = $self->recv($query, $timeout);
		# $response->{query} = $query;
		return $response if $response;
		$timeout += $timeout;
	}
	return undef;
}

=head1 NAME

Mail::Karmasphere::Client - Client for Karmasphere Reputation Server

=head1 SYNOPSIS

 use Mail::Karmasphere::Client qw(:all);
 
 my $client = new Mail::Karmasphere::Client(
    PeerAddr	=> 'query.karmasphere.com',
    PeerPort	=> 8666,
    Principal   => "my_assigned_query_username",
    Credentials => "my_assigned_query_password",
    # see http://my.karmasphere.com/devzone/client/configuration#credentials
    # quickstart:  use temporary credentials for "generic perl".
    # recommended: use permanent credentials -- register for an account.
   );
 
 my $query = new Mail::Karmasphere::Query();
 $query->identity('127.0.0.2', IDT_IP4);
 $query->composite('karmasphere.email-sender');
 my $response = $client->ask($query, 6);
 print $response->as_string;
 
 my $id = $client->send($query);
 my $response = $client->recv($query, 12);
 my $response = $client->recv($id, 12);
 
 my $response = $client->query(
 	Identities	=> [ ... ]
 	Composite	=> 'karmasphere.email-sender',
 		);

=head1 DESCRIPTION

The Perl Karma Client API consists of three objects: The Query, the
Response, and the Client. The user constructs a Query and passes it
to a Client, which returns a Response.

=head1 CONSTRUCTOR

The class method new(...) constructs a new Client object. All arguments
are optional. The following parameters are recognised as arguments
to new():

=over 4 

=item PeerAddr

The IP address or hostname to contact. See L<IO::Socket::INET>. The
default is 'query.karmasphere.com'.

=item PeerPort

The TCP or UDP to contact. See L<IO::Socket::INET>. The default
is 8666.

=item Proto

Either 'udp' or 'tcp'. The default is 'udp' because it is faster.

=item Principal

=item Credentials

A username and password are required to authenticate client
connections.  They are assigned by Karmasphere.  See
http://my.karmasphere.com/devzone/client/configuration#credentials

"Principal" corresponds to "username", and "Credentials"
corresponds to "password".  Note that these are not the same
username and password you use to sign in to the website.

=item Debug

Either a true value for debugging to stderr, or a custom debug handler.
The custom handler will be called with N arguments, the first of which
is a string 'debug context'. The custom handler may choose to ignore
messages from certain contexts.

=back

=head1 METHODS

=over 4

=item $response = $client->ask($query, $timeout)

Returns a L<Mail::Karmasphere::Response> to a
L<Mail::Karmasphere::Query>. The core of this method is equivalent to

	$client->recv($client->send($query), $timeout)

The method retries up to 3 times, doubling the timeout each time. If
the application requires more control over retries or backoff, it
should use send() and recv() individually. $timeout is optional.

=item $id = $client->send($query)

Sends a L<Mail::Karmasphere::Query> to the server, and returns the
id of the query, which may be passed to recv().  Note that any query
longer than 64KB will be rejected by the server with a message advising
that the maximum message length has been exceeded.

=item $response = $client->recv($id, $timeout)

Returns a L<Mail::Karmasphere::Response> to the query with id $id,
assuming that the query has already been sent using send(). If no
matching response is read before the timeout, undef is returned.

=item $response = $client->query(...)

A convenience method, equivalent to

	$client->ask(new Mail::Karmasphere::Query(...));

See L<Mail::Karmasphere::Query> for more details.

=back

=head1 EXPORTS

=over 4

=item IDT_IP4 IDT_IP6 IDT_DOMAIN IDT_EMAIL IDT_URL

Identity type constants.

=item AUTHENTIC SMTP_CLIENT_IP SMTP_ENV_HELO SMTP_ENV_MAIL_FROM SMTP_ENV_RCPT_TO SMTP_HEADER_FROM_ADDRESS

Identity tags, indicating the context of an identity to the server.

=item FL_FACTS

A flag indicating that all facts must be returned explicitly in the
Response.

=back

=head1 NOTES ON THE IMPLEMENTATION

The server will discard any packet in TCP mode which exceeds
64K. Although the packet length field is 4 bytes, it is relatively
common to get non-Karmasphere clients connecting to the port.
Therefore the server checks that the top two bytes are \0 before
accepting the packet. This saves everybody a headache.

Some flags, notably those which generate large response packets,
are totally ignored for UDP queries, even in the case that they would
not generate a large response. This also saves many headaches.

=head1 BUGS

UDP retries are not yet implemented.

=head1 SEE ALSO

L<Mail::Karmasphere::Query>,
L<Mail::Karmasphere::Response>,
http://www.karmasphere.com/,
http://my.karmasphere.com/devzone/client/configuration,
L<Mail::SpamAssassin::Plugin::Karmasphere>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Shevek, Karmasphere. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
