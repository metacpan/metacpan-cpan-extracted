# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::Control;
our $VERSION = '0.4.0';

use IO::Socket::UNIX;
use JSON::PP ();
use Socket   qw(SOCK_STREAM SOL_SOCKET);

use Fugu::Imsg;
use Fugu::Log;

# Fugu::Control - a control socket for a running daemon.
#
# A tool that reports on a daemon has two ways to get its answer. It
# can guess from files on disk, or it can ask the daemon. The first
# way reads what the daemon wrote at some earlier time, and it is
# wrong whenever the two disagree. This module is the second way.
#
# The server registers with a Fugu::EventLoop and answers commands
# from process state. The client connects, sends one request, and
# reads the reply. The payload is JSON, and the transport is the
# imsg(3) framing of Fugu::Imsg.
#
# The socket carries no secret. That is a rule for the caller, which
# writes the command handlers, and this module cannot enforce it. A
# daemon whose configuration holds a setup code and a broker password
# must not answer a command that echoes them back.
#
# Everything that arrives on the socket is untrusted. An unknown
# command, a payload that is not JSON, and a frame over the limit all
# give an error reply. None of them ends the daemon.

# The message types. A reply that does not fit one imsg frame is sent
# as several TYPE_REPLY_PART frames and one TYPE_REPLY, so a reader
# knows when it holds the whole answer without counting.
use constant {
	TYPE_REQUEST    => 1,
	TYPE_REPLY      => 2,
	TYPE_REPLY_PART => 3,
	TYPE_ERROR      => 4,
};

# The bound on one whole reply, across every frame. A control reply
# is a status line or a device list, and a megabyte is far above
# either. The bound exists so a client cannot be made to hold an
# unbounded string by a server that never stops sending.
use constant MAX_REPLY => 1048576;

# How long a client waits for one frame.
use constant DEFAULT_TIMEOUT => 5;

# The platform predicate of peer. Only OpenBSD reports the peer
# credentials in the struct sockpeercred order: the user id, then the
# group id, then the process id. The Linux struct ucred holds the
# process id first, and one module must not carry two field orders.
# The base perl of OpenBSD exports Socket::SO_PEERCRED (0x1022), so
# no compiled module is necessary.
use constant PEER_SUPPORTED => $^O eq 'openbsd';

my $JSON = JSON::PP->new->utf8->canonical;

# Fugu::Control->new(%args):
#	path => $socket		the UNIX socket to serve (required)
#	log  => $logger		default Fugu::Log->default
#
#	Make a server. The method opens nothing. Call listen.
sub new ( $class, %args )
{
	my $path = $args{path};
	die 'path parameter required'
	    unless defined $path && length $path;

	return bless {
		path     => $path,
		log      => $args{log},
		commands => {},
		listener => undef,
		clients  => {},
		peers    => {},
		error    => undef,
	}, $class;
}

# $self->register($command, $code):
#	Add a command. The code gets the decoded arguments hashref and
#	returns the reply, which must encode as JSON.
#
#	A handler that dies gives the caller an error reply. A daemon
#	must not fall over because one handler had a bad day.
sub register ( $self, $command, $code )
{
	die 'command handler must be a code reference'
	    unless ref $code eq 'CODE';

	$self->{commands}{$command} = $code;

	return $self;
}

# $self->path: the socket path.
sub path ($self)
{
	return $self->{path};
}

# $self->error: the most recent failure.
sub error ($self)
{
	return $self->{error};
}

# $self->listen:
#	Bind the socket and start accepting. The method returns the
#	object on success, or undef with the reason in error.
#
#	%args:
#		loop  => $loop	the event loop (required)
#		mode  => $mode	the socket mode (default: 0600)
#		group => $name	the socket group, a name or a group id
#
#	The socket holds its mode from birth, through a umask guard. A
#	chmod after the bind toward a wider mode leaves a window in
#	which any user on the machine can connect. The directory that
#	holds the socket is the outer boundary, and the caller owns its
#	mode.
#
#	bind(2) takes no group. The group form binds under the owner
#	bits of the final mode. It chowns the path to the group, and
#	it chmods to the mode last. The order narrows first and
#	widens last: at every instant the users that can connect are a
#	subset of the final set. A daemon drops privileges first, and
#	it calls listen after. A process can chgrp its own file to a
#	group that it belongs to, so the chgrp needs no root.
#
#	A stale socket from a daemon that did not shut down cleanly is
#	removed first. bind(2) fails on an existing name, and a daemon
#	that refuses to start because its last run crashed is a daemon
#	that needs a hand at every reboot.
sub listen ( $self, %args )
{
	my $loop  = $args{loop} // die 'loop parameter required';
	my $mode  = $args{mode} // 0600;
	my $group = $args{group};

	# A mode outside the permission bits is a programming error.
	die "Invalid socket mode: $mode"
	    unless ref($mode) eq '' && $mode =~ /^\d+$/ && $mode <= 0777;

	$self->{error} = undef;

	my $gid;
	if ( defined $group ) {

		# A numeric group must exist too: a chown to a group
		# id that no group holds would report success, and the
		# socket would carry a meaningless owner.
		if ( $group =~ /^\d+$/ ) {
			$gid = defined getgrgid($group) ? $group : undef;
		}
		else {
			$gid = getgrnam($group);
		}
		unless ( defined $gid ) {
			$self->{error} = "Cannot resolve group $group";
			return;
		}
	}

	$self->_remove_stale or return;

	my $guard =
	    defined $gid ? ( 0777 & ~( $mode & 0700 ) ) : ( 0777 & ~$mode );
	my $old      = umask $guard;
	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $self->{path},
		Listen => 5,
	);
	umask $old;

	unless ($listener) {
		$self->{error} = "Cannot bind $self->{path}: $!";
		return;
	}

	if ( defined $gid ) {
		unless ( chown -1, $gid, $self->{path} ) {
			return $self->_unbind( $listener,
				"Cannot chown $self->{path} to group $gid: $!"
			);
		}
		unless ( chmod $mode, $self->{path} ) {
			return $self->_unbind( $listener,
				"Cannot chmod $self->{path}: $!" );
		}
	}

	$self->{listener} = $listener;
	$self->_log->debug( 'Control socket listening on %s', $self->{path} );

	$loop->add_fd( $listener,
		read => sub ($) { $self->accept_one($loop) } );

	return $self;
}

# $self->_unbind($listener, $reason):
#	Take a half-built socket down. A half-built socket must never
#	accept a connection, so the listener closes and the path goes.
sub _unbind ( $self, $listener, $reason )
{
	$self->{error} = $reason;

	unless ( CORE::close $listener ) {
		$self->_log->error( 'Cannot close the listener on %s: %s',
			$self->{path}, $! );
	}
	unless ( unlink $self->{path} ) {

		# A socket that stays behind reads as a stale socket at
		# the next start, and _remove_stale takes it then.
		$self->_log->error( 'Cannot remove %s: %s', $self->{path}, $! );
	}

	return;
}

# $self->accept_one($loop):
#	Take one connection and register it as a read handler on the
#	loop. The peer of an open connection cannot change, so one
#	getsockopt(2) per connection is enough, and this is the place
#	for it.
sub accept_one ( $self, $loop )
{
	my $client = $self->{listener}->accept or return;

	my ( $peer, $fault );
	if (PEER_SUPPORTED) {
		( $peer, $fault ) = _read_peer($client);

		# The read cannot fail on a healthy UNIX socket, so a
		# failure names a broken assumption. A control socket
		# that cannot name its peer must not answer.
		unless ($peer) {
			$self->_log->error(
				'Cannot read the peer credentials on %s: %s',
				$self->{path}, $fault );
			CORE::close $client;
			return;
		}
	}

	my $imsg = Fugu::Imsg->new( fh => $client );
	$self->{clients}{ fileno $client } = $imsg;
	$self->{peers}{ fileno $client }   = $peer;

	# The loop already knows the socket is readable, thus the read
	# takes what arrived and returns. A request that spans two
	# reads waits in the buffer for the next readable event.
	$loop->add_fd(
		$client,
		read => sub ($fh) {
			$self->_serve_one($imsg)
			    or $self->_drop_client( $fh, $loop );
		} );

	return;
}

# $self->shutdown:
#	Close every connection, close the listener, and remove the
#	socket. A socket left behind names a daemon that is not there.
sub shutdown ( $self, %args )
{
	my $loop = $args{loop};

	for my $key ( keys %{ $self->{clients} } ) {
		my $imsg = delete $self->{clients}{$key};
		delete $self->{peers}{$key};
		$loop->remove_fd( $imsg->{fh} ) if $loop && $imsg->{fh};
		$imsg->close;
	}

	if ( $self->{listener} ) {
		$loop->remove_fd( $self->{listener} ) if $loop;
		CORE::close $self->{listener};
		$self->{listener} = undef;
	}

	unlink $self->{path};

	return $self;
}

# $self->_serve_one($imsg):
#	Read one request and answer it. The method returns 1 when the
#	connection can carry another, and 0 when it is finished. The
#	read never blocks: the loop calls again when more arrives.
sub _serve_one ( $self, $imsg )
{
	my $message = $imsg->recv( timeout => 0 );
	unless ($message) {
		return 0 if $imsg->is_dead;

		# No whole frame arrived yet. The loop calls again.
		return 1;
	}

	my $peerid = $message->{peerid};

	if ( $message->{type} != TYPE_REQUEST ) {
		return $self->_send_error( $imsg, $peerid,
			'not a control request' );
	}

	my $request = eval { $JSON->decode( $message->{data} ) };
	unless ( ref $request eq 'HASH' ) {
		return $self->_send_error( $imsg, $peerid,
			'request is not a JSON object' );
	}

	my $command = $request->{command};
	unless ( defined $command && length $command ) {
		return $self->_send_error( $imsg, $peerid,
			'request names no command' );
	}

	my $handler = $self->{commands}{$command};
	unless ($handler) {
		return $self->_send_error( $imsg, $peerid,
			"unknown command: $command" );
	}

	# The credentials belong to the connection. peer answers only
	# while the handler runs, so the local scope ends with the
	# call.
	my $reply = do {
		local $self->{current_peer} =
		    $self->{peers}{ fileno $imsg->{fh} };
		eval { $handler->( $request->{args} // {} ) };
	};
	if ($@) {
		my $reason = $@;
		chomp $reason;
		$self->_log->error( 'Control command %s died: %s',
			$command, $reason );
		return $self->_send_error( $imsg, $peerid,
			"command failed: $command" );
	}

	return $self->_send_reply( $imsg, $peerid, $reply );
}

# $self->_send_reply($imsg, $peerid, $reply):
#	Send one reply, in as many frames as it needs. Every frame but
#	the last is a part.
sub _send_reply ( $self, $imsg, $peerid, $reply )
{
	my $body =
	    eval { $JSON->encode( { ok => JSON::PP::true, reply => $reply } ) };
	unless ( defined $body ) {
		return $self->_send_error( $imsg, $peerid,
			'reply does not encode as JSON' );
	}

	if ( length($body) > MAX_REPLY ) {
		return $self->_send_error( $imsg, $peerid, 'reply too large' );
	}

	my $chunk = Fugu::Imsg::MAX_PAYLOAD;
	while ( length($body) > $chunk ) {
		$imsg->send(
			type   => TYPE_REPLY_PART,
			peerid => $peerid,
			data   => substr( $body, 0, $chunk, '' ),
		) or return 0;
	}

	return $imsg->send(
		type   => TYPE_REPLY,
		peerid => $peerid,
		data   => $body,
	) ? 1 : 0;
}

# $self->_send_error($imsg, $peerid, $reason):
#	Send an error reply. The method returns 1: a bad request is
#	the peer's problem, and the connection stays usable.
sub _send_error ( $self, $imsg, $peerid, $reason )
{
	$self->_log->debug( 'Control error: %s', $reason );

	$imsg->send(
		type   => TYPE_ERROR,
		peerid => $peerid,
		data   => $JSON->encode(
			{ ok => JSON::PP::false, error => $reason }
		),
	) or return 0;

	return 1;
}

# Fugu::Control->peer_supported:
#	Report if the platform gives peer credentials in the struct
#	sockpeercred order. A caller or a test uses this, not a log
#	line, to tell "not supported" from "the read failed".
sub peer_supported ($)
{
	return PEER_SUPPORTED ? 1 : 0;
}

# $self->peer:
#	The credentials of the connection that the server answers now,
#	as a hash reference with uid, gid and pid. The method returns
#	undef outside a handler call, and undef where peer_supported is
#	false. It holds no policy: the group of the socket is the
#	coarse gate, and the handler is the fine gate.
sub peer ($self)
{
	return $self->{current_peer};
}

# _read_peer($client):
#	The peer credentials of one connection, as ($peer, $fault).
#	One of the two is defined. getsockopt(2) with SO_PEERCRED
#	returns a struct sockpeercred, and the length check guards the
#	unpack.
sub _read_peer ($client)
{
	# The constant probe fails closed. The base perl of OpenBSD
	# 7.8 exports Socket::SO_PEERCRED, and a real guest verified
	# the read. Socket still croaks at call time for a constant
	# that a platform does not define, and the server must log and
	# close instead.
	my $option = eval { Socket::SO_PEERCRED() };
	return ( undef, 'Socket defines no SO_PEERCRED' )
	    unless defined $option;

	my $cred = getsockopt( $client, SOL_SOCKET, $option );
	return ( undef, "getsockopt: $!" ) unless defined $cred;

	# A size other than 12 names an other struct layout, so the
	# read fails closed instead of unpacking a guess.
	return ( undef, length($cred) . ' credential bytes, not 12' )
	    unless length($cred) == 12;

	my ( $uid, $gid, $pid ) = _unpack_peer($cred);

	return ( { uid => $uid, gid => $gid, pid => $pid }, undef );
}

# _unpack_peer($cred):
#	The three fields of a struct sockpeercred: the user id, the
#	group id, and the process id. The id fields are unsigned, so a
#	uid at or above 2**31 stays positive. The process id is
#	signed, per pid_t.
sub _unpack_peer ($cred)
{
	return unpack 'L2l', $cred;
}

# $self->_drop_client($fh, $loop):
#	Forget a connection that ended.
sub _drop_client ( $self, $fh, $loop )
{
	# The handle is still open here: recv marks {dead} without
	# closing, so fileno answers and the client entry is there.
	my $imsg = delete $self->{clients}{ fileno $fh };
	delete $self->{peers}{ fileno $fh };

	$loop->remove_fd($fh);
	$imsg->close;

	return;
}

# $self->_remove_stale:
#	Remove a socket that no daemon is behind. A socket that
#	something still answers on is another daemon, and this one
#	must not take its name.
sub _remove_stale ($self)
{
	return 1 unless -e $self->{path};

	my $probe = IO::Socket::UNIX->new(
		Type    => SOCK_STREAM,
		Peer    => $self->{path},
		Timeout => 1,
	);
	if ($probe) {
		CORE::close $probe;
		$self->{error} = "Another process serves $self->{path}";
		return;
	}

	unless ( unlink $self->{path} ) {
		$self->{error} = "Cannot remove stale $self->{path}: $!";
		return;
	}

	return 1;
}

# $self->_log:
#	The logger of this server.
sub _log ($self)
{
	return $self->{log} // Fugu::Log->default;
}

package Fugu::Control::Client;
our $VERSION = '0.4.0';

use Errno qw(EACCES ENOENT);
use IO::Socket::UNIX;
use JSON::PP ();
use Socket   qw(SOCK_STREAM);

use Fugu::Imsg;

# Fugu::Control::Client - the other end of a control socket.
#
# The client separates "the daemon is not there" from "the daemon
# refused". A tool that cannot tell them apart reports the wrong
# thing to an operator half the time.

# Fugu::Control::Client->new(%args):
#	path    => $socket	the socket to reach (required)
#	timeout => $seconds	per-frame deadline, default 5
sub new ( $class, %args )
{
	my $path = $args{path};
	die 'path parameter required'
	    unless defined $path && length $path;

	return bless {
		path    => $path,
		timeout => $args{timeout} // Fugu::Control::DEFAULT_TIMEOUT,
		imsg    => undef,
		next_id => 1,
		error   => undef,
		absent  => 0,
	}, $class;
}

# $self->error: the most recent failure.
sub error ($self)
{
	return $self->{error};
}

# $self->socket_absent:
#	Report if the most recent failure was an absent socket, and
#	not a refusal. A tool says "the daemon is not running" for the
#	first and "the daemon said no" for the second.
sub socket_absent ($self)
{
	return $self->{absent};
}

# $self->connect:
#	Open the connection. The method returns the object, or undef
#	with the reason in error.
sub connect ($self)
{
	return $self if $self->{imsg} && !$self->{imsg}->is_dead;

	$self->{error}  = undef;
	$self->{absent} = 0;

	unless ( -e $self->{path} ) {

		# A socket inside a directory that the caller may not
		# search fails this test too. That is a permission
		# problem and not an absent daemon, and an operator
		# needs to be told which one it is.
		if ( $! == EACCES ) {
			$self->{error} = "Cannot reach $self->{path}: $!";
			return;
		}

		$self->{absent} = 1;
		$self->{error}  = "No control socket at $self->{path}";
		return;
	}

	my $sock = IO::Socket::UNIX->new(
		Type    => SOCK_STREAM,
		Peer    => $self->{path},
		Timeout => $self->{timeout},
	);
	unless ($sock) {
		$self->{absent} = 1 if $! == ENOENT;
		$self->{error}  = "Cannot connect to $self->{path}: $!";
		return;
	}

	$self->{imsg} = Fugu::Imsg->new( fh => $sock );

	return $self;
}

# $self->disconnect:
#	Close the connection. The method is idempotent.
sub disconnect ($self)
{
	$self->{imsg}->close if $self->{imsg};
	$self->{imsg} = undef;

	return $self;
}

# $self->request($command, $args):
#	Send one command and return the decoded reply. The method
#	returns undef with the reason in error on any failure: no
#	socket, a dead connection, a timeout, or a server that
#	refused.
sub request ( $self, $command, $args = undef )
{
	$self->connect or return;

	$self->{error} = undef;
	my $peerid = $self->{next_id}++;
	my $body   = JSON::PP->new->utf8->canonical->encode(
		{ command => $command, args => $args // {} } );

	unless (
		$self->{imsg}->send(
			type   => Fugu::Control::TYPE_REQUEST,
			peerid => $peerid,
			data   => $body,
		) )
	{
		$self->{error} = "Cannot send $command: $!";
		$self->disconnect;
		return;
	}

	return $self->_read_reply( $command, $peerid );
}

# $self->_read_reply($command, $peerid):
#	Collect the frames of one reply and decode it. A frame that
#	belongs to another request is dropped: the peerid says which
#	request a frame answers.
sub _read_reply ( $self, $command, $peerid )
{
	my $body  = '';
	my $error = undef;

	while (1) {
		my $frame = $self->{imsg}->recv( timeout => $self->{timeout} );
		unless ($frame) {
			$self->{error} =
			    $self->{imsg}->is_dead
			    ? "The daemon closed the connection during $command"
			    : "No answer to $command within $self->{timeout}s";
			$self->disconnect;
			return;
		}

		next unless $frame->{peerid} == $peerid;

		$error = 1 if $frame->{type} == Fugu::Control::TYPE_ERROR;
		$body .= $frame->{data};

		if ( length($body) > Fugu::Control::MAX_REPLY ) {
			$self->{error} = "Reply to $command is too large";
			$self->disconnect;
			return;
		}

		last
		    if $frame->{type} == Fugu::Control::TYPE_REPLY
		    || $frame->{type} == Fugu::Control::TYPE_ERROR;
	}

	my $decoded = eval { JSON::PP->new->utf8->decode($body) };
	unless ( ref $decoded eq 'HASH' ) {
		$self->{error} = "The answer to $command is not JSON";
		return;
	}

	if ( $error || !$decoded->{ok} ) {
		$self->{error} = $decoded->{error}
		    // "The daemon refused $command";
		return;
	}

	return $decoded->{reply};
}

1;
