package Ereshkigal::Client;

use 5.006;
use strict;
use warnings;
use Errno            ();
use IO::Select       ();
use IO::Socket::UNIX ();
use File::Temp       ();
use JSON::MaybeXS    qw( encode_json decode_json );

=head1 NAME

Ereshkigal::Client - Small blocking JSON over unix socket client for Ereshkigal.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ereshkigal::Client;

    my $client = Ereshkigal::Client->new( socket => '/var/run/ereshkigal/socket' );

    # returns the raw response hash, {status=>..., ...}
    my $response = $client->call( 'status' );

    # dies unless status is ok, returning the result
    my $result = $client->call_ok( 'ban', { ips => ['1.2.3.4'] } );

=head1 DESCRIPTION

Connects to a unix socket speaking the newline delimited JSON protocol of
L<POE::Component::Server::JSONUnix>, sends a single request, and reads back
the response. Used by the C<ereshkigal> CLI for talking to the manager and by
the manager for talking to kur instances.

=head1 METHODS

=head2 new

Initiates the object. Will die on errors.

    - socket :: Path of the unix socket to connect to. Must be specified.
        Default :: undef

    - timeout :: Timeout in seconds for a call. 0 means no timeout.
        Default :: 30

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{socket} ) ) {
		die('No socket specified');
	}

	# fractional seconds would silently truncate going through alarm
	if ( defined( $opts{timeout} ) && $opts{timeout} !~ /^\d+$/ ) {
		die('timeout must be a non-negative integer');
	}

	my $self = {
		socket  => $opts{socket},
		timeout => defined( $opts{timeout} ) ? $opts{timeout} : 30,
	};
	bless $self;

	return $self;
} ## end sub new

=head2 call

Sends a single request and returns the decoded response hash. Will die on
connect failure, timeout, or an undecodable response.

    my $response = $client->call( $command, $args );

C<$args>, if defined, is sent as the args value of the request.

If the server answers with the L<POE::Component::Server::JSONUnix>
authentication required error, the unix ownership challenge is completed
transparently on the same connection and the request is resent, so no
special handling is needed for talking to a manager with enable_auth on.
The timeout wraps the whole exchange.

=cut

sub call {
	my ( $self, $command, $args ) = @_;

	if ( !defined($command) ) {
		die('No command specified');
	}

	my $response;
	eval {
		# a write to a peer that died would otherwise raise SIGPIPE and kill
		# the whole process... ignored, the write fails with EPIPE and that
		# surfaces through the normal error paths
		local $SIG{PIPE} = 'IGNORE';
		local $SIG{ALRM} = sub { die( 'timed out after ' . $self->{timeout} . " seconds\n" ); };
		alarm( $self->{timeout} );

		my $sock = IO::Socket::UNIX->new(
			'Type' => IO::Socket::UNIX::SOCK_STREAM(),
			'Peer' => $self->{socket},
		) || die( 'Failed to connect to "' . $self->{socket} . '"... ' . $! . "\n" );

		my $request = { 'command' => $command };
		if ( defined($args) ) {
			$request->{args} = $args;
		}

		$response = $self->_send_request( $sock, $request );

		# auth state is per connection, so complete the ownership challenge
		# on this same connection and resend
		#
		# matched against the error prose as the JSONUnix auth_required gate
		# answers with no code field... only its permission policy denials
		# and Ereshkigal's own _authorize carry a machine readable code, and
		# neither of those is the response being caught here
		if (   defined( $response->{status} )
			&& $response->{status} eq 'error'
			&& defined( $response->{error} )
			&& $response->{error} =~ /^authentication required/ )
		{
			$self->_authenticate($sock);
			$response = $self->_send_request( $sock, $request );
		}

		close($sock);
		alarm(0);
	};
	my $call_error = $@;
	alarm(0);
	if ($call_error) {
		die($call_error);
	}

	return $response;
} ## end sub call

# Sends one request over an already connected socket and reads back the one
# line answer to it, which is the whole of the newline delimited JSON
# protocol POE::Component::Server::JSONUnix speaks. Used by call for both the
# initial request and the resend after an auth challenge, and by _authenticate
# for the challenge itself, so it deliberately does no connecting, no timing
# out, and no auth handling of its own... the caller owns all three.
#
# The request is JSON encoded, a newline appended, and written to the socket;
# the answer is read to the first newline and JSON decoded.
#
# Args, both required and positional...
#
#     $sock    :: An open IO::Socket::UNIX already connected to the server.
#                 Left open on return, as the auth challenge and the resend
#                 that follows it have to happen on this same connection.
#     $request :: A hash ref of the request to send, which the server expects
#                 to carry a 'command' key naming the command and, optionally,
#                 a 'args' key holding that command's arguments hash ref. It
#                 is encoded as given, so anything JSON::MaybeXS cannot
#                 encode dies here.
#
# Returns the decoded response as a hash ref. The server's own shape is
# { status => 'ok', result => ... } on success and
# { status => 'error', error => '...' } on failure, but no checking of that
# is done here... an error response comes back as a plain hash ref just like a
# successful one, for the caller to judge. call_ok is what turns an error
# status into a die.
#
# Dies, with a trailing newline so the message reads cleanly when it reaches
# a user, if the socket gives EOF rather than a line, if the line will not
# JSON decode, or if it decodes to anything other than a hash ref.
#
#     my $response = $self->_send_request( $sock, { 'command' => 'status' } );
#     # $response is { status => 'ok', result => { pid => 42, ... } }
#
#     my $response = $self->_send_request(
#         $sock,
#         { 'command' => 'ban', 'args' => { 'ips' => ['1.2.3.4'] } }
#     );
sub _send_request {
	my ( $self, $sock, $request ) = @_;

	print $sock encode_json($request) . "\n";

	my $line = <$sock>;
	if ( !defined($line) ) {
		die( 'No response read from "' . $self->{socket} . '"' . "\n" );
	}

	my $response = decode_json($line);
	if ( ref($response) ne 'HASH' ) {
		die( 'Response is not a JSON object' . "\n" );
	}

	return $response;
} ## end sub _send_request

# Completes the POE::Component::Server::JSONUnix unix ownership challenge on
# an already connected socket, which is how a manager with enable_auth on
# learns who is talking to it. Called by call when a request comes back
# refused with the authentication required error, after which that request is
# resent on the same connection.
#
# The challenge runs in two commands. auth_start hands back a random cookie
# and a temp dir the server can see; the cookie is written to a fresh file in
# that dir, which by being owned by this process is the actual proof of
# identity; auth_verify is then pointed at that file, and the server stats it
# to learn the uid and username. The cookie file is removed either way, the
# server doing it on success and this doing it otherwise, so a rejected
# challenge leaves nothing behind.
#
# Args, required and positional...
#
#     $sock :: An open IO::Socket::UNIX already connected to the server. Auth
#              state is per connection, so this must be the same socket the
#              refused request went over and the one the resend will go over.
#              Left open on return.
#
# Returns nothing meaningful, an empty return. Success is the absence of a
# die... on return the connection is authenticated and the caller may resend.
#
# Dies, with a trailing newline, if auth_start answers anything but ok or
# without both a cookie and a temp_dir, if the cookie file cannot be
# written (a full or unwritable temp dir surfaces here rather than as a
# confusing auth_verify failure later), or if auth_verify answers anything
# but ok, which is what a genuine refusal looks like.
#
#     eval { $self->_authenticate($sock); };
#     if ($@) { die( 'could not authenticate... ' . $@ ); }
#     my $response = $self->_send_request( $sock, $request );
sub _authenticate {
	my ( $self, $sock ) = @_;

	my $start = $self->_send_request( $sock, { 'command' => 'auth_start' } );
	if ( !defined( $start->{status} ) || $start->{status} ne 'ok' ) {
		die( 'auth_start failed... ' . ( defined( $start->{error} ) ? $start->{error} : 'unknown error' ) . "\n" );
	}
	my $cookie   = $start->{result}{cookie};
	my $temp_dir = $start->{result}{temp_dir};
	if ( !defined($cookie) || !defined($temp_dir) ) {
		die( 'auth_start did not return a cookie and temp_dir' . "\n" );
	}

	my ( $cookie_fh, $cookie_file )
		= File::Temp::tempfile( 'ereshkigal-auth-XXXXXXXX', 'DIR' => $temp_dir, 'UNLINK' => 0 );
	# checked so a full filesystem or unwritable temp_dir surfaces here as
	# the actual cause rather than as a confusing auth_verify failure
	if ( !print( $cookie_fh $cookie ) || !close($cookie_fh) ) {
		my $write_error = $!;
		unlink($cookie_file);
		die( 'Failed to write the auth cookie to "' . $cookie_file . '"... ' . $write_error . "\n" );
	}

	my $verify;
	eval {
		$verify
			= $self->_send_request( $sock, { 'command' => 'auth_verify', 'args' => { 'path' => $cookie_file } } );
	};
	my $verify_error = $@;
	# the server removes it on success, but make sure it is gone either way
	unlink($cookie_file) if -e $cookie_file;
	if ($verify_error) {
		die($verify_error);
	}
	if ( !defined( $verify->{status} ) || $verify->{status} ne 'ok' ) {
		die( 'auth_verify failed... ' . ( defined( $verify->{error} ) ? $verify->{error} : 'unknown error' ) . "\n" );
	}

	return;
} ## end sub _authenticate

=head2 call_many

Sends the same single request to multiple sockets concurrently. This is for
the manager fanning a command out to its kurs, which is why it is a class
method taking a whole hash of sockets rather than using a per socket object.

    my $per_name = Ereshkigal::Client->call_many(
        sockets => { sshd => '/var/run/ereshkigal/kur/sshd.sock' },
        command => 'ban',
        args    => { ips => [ '1.2.3.4' ] },
        timeout => 30,
    );

    - sockets :: A hash of name to unix socket path. Must be specified.
        Default :: undef

    - command :: The command to send to every socket. Must be specified.
        Default :: undef

    - args :: Sent as the args value of the request, if defined.
        Default :: undef

    - timeout :: Timeout in seconds for the whole fan out, bounding it as a
          whole rather than each socket individually, so the wall time is
          the slowest socket capped at one timeout instead of the sum. This
          covers the connects as well, each of which is bounded by an even
          share of what is left of it, so a socket whose listener never
          accepts cannot hang the fan out or starve the rest of it. 0
          means no timeout.
        Default :: 30

The return is a hash keyed the same as sockets, each value being either
C<{ result =E<gt> ... }> for a response with an ok status or
C<{ error =E<gt> "..." }> for anything else... connect failure, EOF, an
undecodable response, an error status response, or the deadline passing. A
failure with one socket never disturbs the others.

Unlike L</call>, no authentication challenge handling happens... kur
sockets never challenge and this is not meant for talking to the manager
socket.

=cut

sub call_many {
	my ( $blank, %opts ) = @_;

	if ( ref( $opts{sockets} ) ne 'HASH' ) {
		die('sockets must be a hash of name to socket path');
	}
	if ( !defined( $opts{command} ) ) {
		die('No command specified');
	}
	my $timeout = defined( $opts{timeout} ) ? $opts{timeout} : 30;

	# a write to a peer that died would otherwise raise SIGPIPE and kill
	# the whole process... ignored, the write fails with EPIPE and that
	# lands in that socket's error answer like any other failure
	local $SIG{PIPE} = 'IGNORE';

	my $request = { 'command' => $opts{command} };
	if ( defined( $opts{args} ) ) {
		$request->{args} = $opts{args};
	}
	my $request_line = encode_json($request) . "\n";

	my $answers = {};

	# one shared deadline over the whole fan out, the connects included... a
	# timeout of 0 means no deadline at all
	my $deadline = $timeout ? time + $timeout : undef;

	# each connection is a little state machine... writing till the request
	# line is fully sent, then reading till a newline shows up
	my %conns;
	my $writers     = IO::Select->new;
	my $readers     = IO::Select->new;
	my @names       = sort( keys( %{ $opts{sockets} } ) );
	my $left_to_try = scalar(@names);
	foreach my $name (@names) {
		# a unix stream connect to a live listener normally completes at once
		# and a dead socket refuses at once, but a listener whose accept queue
		# has filled blocks, so each connect is bounded rather than being left
		# to wedge the whole fan out... the bound is an even share of what is
		# left of the deadline, so one wedged listener cannot eat the budget
		# the rest need, and never less than a second as alarm(0) would mean
		# no alarm at all
		my $remaining;
		if ( defined($deadline) ) {
			my $budget = $deadline - time;
			if ( $budget <= 0 ) {
				$left_to_try--;
				$answers->{$name} = { 'error' => 'Timed out before connecting to "' . $opts{sockets}{$name} . '"' };
				next;
			}
			$remaining = int( $budget / $left_to_try ) || 1;
		}
		$left_to_try--;

		my $sock;
		my $connect_error;
		eval {
			local $SIG{ALRM} = sub { die("timed out\n"); };
			alarm($remaining) if defined($remaining);
			$sock = IO::Socket::UNIX->new(
				'Type' => IO::Socket::UNIX::SOCK_STREAM(),
				'Peer' => $opts{sockets}{$name},
			);
			$connect_error = $! if !$sock;
			alarm(0);
			1;
		} or do {
			alarm(0);
			$sock          = undef;
			$connect_error = 'timed out';
		};
		if ( !$sock ) {
			$answers->{$name}
				= { 'error' => 'Failed to connect to "' . $opts{sockets}{$name} . '"... ' . $connect_error };
			next;
		}
		$sock->blocking(0);
		$conns{$sock} = { 'name' => $name, 'sock' => $sock, 'sent' => 0, 'buf' => '' };
		$writers->add($sock);
	} ## end foreach my $name (@names)

	my $finish = sub {
		my ( $conn, $answer ) = @_;
		$writers->remove( $conn->{sock} );
		$readers->remove( $conn->{sock} );
		close( $conn->{sock} );
		delete( $conns{ $conn->{sock} } );
		$answers->{ $conn->{name} } = $answer;
	};

	# one select loop over all the connections against that same deadline...
	# no SIGALRM here as one alarm can't supervise N conversations, which is
	# why only the sequential connects above use one
	while (%conns) {
		my $remaining;
		if ( defined($deadline) ) {
			$remaining = $deadline - time;
			last if $remaining <= 0;
		}

		my ( $readable, $writable ) = IO::Select->select( $readers, $writers, undef, $remaining );

		foreach my $sock ( defined($writable) ? @{$writable} : () ) {
			my $conn = $conns{$sock};
			next if !defined($conn);
			my $wrote = syswrite( $sock, $request_line, length($request_line) - $conn->{sent}, $conn->{sent} );
			if ( !defined($wrote) ) {
				next if $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR};
				$finish->( $conn, { 'error' => 'Failed to write the request... ' . $! } );
				next;
			}
			$conn->{sent} += $wrote;
			if ( $conn->{sent} >= length($request_line) ) {
				$writers->remove($sock);
				$readers->add($sock);
			}
		} ## end foreach my $sock ( defined($writable) ? @{$writable...})

		foreach my $sock ( defined($readable) ? @{$readable} : () ) {
			my $conn = $conns{$sock};
			next if !defined($conn);
			my $read = sysread( $sock, my $chunk, 4096 );
			if ( !defined($read) ) {
				next if $!{EAGAIN} || $!{EWOULDBLOCK} || $!{EINTR};
				$finish->( $conn, { 'error' => 'Failed to read the response... ' . $! } );
				next;
			}
			if ( $read == 0 ) {
				$finish->( $conn, { 'error' => 'No response read from "' . $opts{sockets}{ $conn->{name} } . '"' } );
				next;
			}
			$conn->{buf} .= $chunk;
			if ( $conn->{buf} =~ /\n/ ) {
				my ($line) = split( /\n/, $conn->{buf}, 2 );
				my $response;
				eval { $response = decode_json($line); };
				if ($@) {
					$finish->( $conn, { 'error' => 'Undecodable response... ' . $@ } );
					next;
				}
				if ( ref($response) ne 'HASH' ) {
					$finish->( $conn, { 'error' => 'Response is not a JSON object' } );
					next;
				}
				# the call_ok check, applied per connection
				if ( !defined( $response->{status} ) || $response->{status} ne 'ok' ) {
					$finish->(
						$conn, { 'error' => defined( $response->{error} ) ? $response->{error} : 'unknown error' }
					);
					next;
				}
				$finish->( $conn, { 'result' => $response->{result} } );
			} ## end if ( $conn->{buf} =~ /\n/ )
		} ## end foreach my $sock ( defined($readable) ? @{$readable...})
	} ## end while (%conns)

	# whatever had not finished when the deadline passed
	foreach my $conn ( values(%conns) ) {
		close( $conn->{sock} );
		$answers->{ $conn->{name} } = { 'error' => 'timed out after ' . $timeout . ' seconds' };
	}

	return $answers;
} ## end sub call_many

=head2 call_ok

Like L</call>, but dies if the response status is not ok, and returns the
result value of the response instead of the whole response.

    my $result = $client->call_ok( $command, $args );

=cut

sub call_ok {
	my ( $self, $command, $args ) = @_;

	my $response = $self->call( $command, $args );

	if ( !defined( $response->{status} ) || $response->{status} ne 'ok' ) {
		my $error = defined( $response->{error} ) ? $response->{error} : 'unknown error';
		$error .= "\n" if $error !~ /\n$/;
		die($error);
	}

	return $response->{result};
} ## end sub call_ok

1;
