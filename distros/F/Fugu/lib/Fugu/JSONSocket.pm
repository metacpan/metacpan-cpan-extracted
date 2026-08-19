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

package Fugu::JSONSocket;
our $VERSION = '0.1.2';

use IO::Select;
use IO::Socket::UNIX;
use JSON::PP;
use Socket      qw(SOCK_STREAM);
use Time::HiRes qw(time);

# Fugu::JSONSocket - a newline-delimited JSON client over a UNIX
# socket.
#
# One JSON object for each line, in both directions. QEMU speaks this
# on its machine-protocol and guest-agent sockets, and so does every
# other program that wanted a protocol without inventing a framing.
#
# The codec is JSON::PP, which is core Perl. Thus the module keeps the
# Fugu load contract, and a program that only talks to a local
# socket needs nothing installed.
#
# Every read has a wall-clock deadline. The Timeout of IO::Socket
# governs its own connect and accept only, so a bare readline blocks
# for ever against a peer that stopped answering on an open socket.
# Bytes after a newline stay buffered, so a reply that shares a
# segment with the next one is not lost.

use constant {
	CONNECT_TIMEOUT => 5,
	READ_TIMEOUT    => 10,
	READ_CHUNK      => 4096,
};

# Fugu::JSONSocket->new(%args):
#	path     => $socket	the UNIX socket (required)
#	timeout  => $seconds	deadline for one read (default 10)
#	greeting => 0|1		read one line at connect (default 0)
#
#	A protocol that announces itself before it takes a command
#	sets greeting. Then connect reads that line and request returns
#	it through ->greeting.
sub new ( $class, %args )
{
	my $path = $args{path};
	die 'path parameter required'
	    unless defined $path && length $path;

	return bless {
		path     => $path,
		timeout  => $args{timeout}  // READ_TIMEOUT,
		greeting => $args{greeting} // 0,
		sock     => undef,
		buffer   => '',
		banner   => undef,
		error    => undef,
	}, $class;
}

# $self->path:
#	Return the socket path.
sub path ($self)
{
	return $self->{path};
}

# $self->error: the most recent failure.
sub error ($self)
{
	return $self->{error};
}

# $self->greeting:
#	Return the decoded greeting, for a connection that asked for
#	one. It is undef otherwise.
sub greeting ($self)
{
	return $self->{banner};
}

# $self->is_connected:
#	Report if the socket is open.
sub is_connected ($self)
{
	return $self->{sock} ? 1 : 0;
}

# $self->exists:
#	Report if the socket file is there. A peer that has not started
#	is not an error, so a caller tests before it connects.
sub exists ($self)
{
	return -S $self->{path} ? 1 : 0;
}

# $self->connect:
#	Open the socket, and read the greeting when the caller asked
#	for one. The method returns 1 on success, and undef with the
#	reason in ->error. A second call on an open connection is a
#	success that does nothing.
sub connect ($self)
{
	return 1 if $self->{sock};

	$self->{error} = undef;

	my $sock = IO::Socket::UNIX->new(
		Type    => SOCK_STREAM,
		Peer    => $self->{path},
		Timeout => CONNECT_TIMEOUT,
	    )
	    or do {
		$self->{error} = "connect $self->{path}: $!";
		return;
	    };

	$self->{sock}   = $sock;
	$self->{buffer} = '';
	$self->{banner} = undef;

	if ( $self->{greeting} ) {
		my $banner = $self->read_message;
		unless ( defined $banner ) {
			$self->disconnect;
			return;
		}
		$self->{banner} = $banner;
	}

	return 1;
}

# $self->disconnect:
#	Close the socket and drop the buffer. The method is idempotent
#	and returns the object.
sub disconnect ($self)
{
	if ( $self->{sock} ) {
		close $self->{sock};
		$self->{sock} = undef;
	}
	$self->{buffer} = '';
	$self->{banner} = undef;

	return $self;
}

# $self->request($hashref):
#	Encode, send, and read one reply. The method returns the
#	decoded reply, or undef with the reason in ->error.
sub request ( $self, $message )
{
	$self->send_message($message) or return;

	return $self->read_message;
}

# $self->send_message($hashref):
#	Encode and write one message with its newline. The method
#	returns 1, or undef with the reason in ->error.
sub send_message ( $self, $message )
{
	$self->{error} = undef;

	my $sock = $self->{sock};
	unless ($sock) {
		$self->{error} = 'not connected';
		return;
	}

	my $json = eval { JSON::PP->new->utf8->encode($message) };
	unless ( defined $json ) {
		$self->{error} = 'cannot encode the message';
		return;
	}
	$json .= "\n";

	local $SIG{PIPE} = 'IGNORE';
	my $offset = 0;
	while ( $offset < length $json ) {
		my $n = syswrite $sock, $json, length($json) - $offset, $offset;
		unless ( defined $n ) {
			next if $!{EINTR};
			$self->{error} = "write $self->{path}: $!";
			$self->disconnect;
			return;
		}
		$offset += $n;
	}

	return 1;
}

# $self->read_message:
#	Read one line and decode it. The method returns the decoded
#	value, or undef with the reason in ->error.
sub read_message ($self)
{
	my $line = $self->read_line;
	return unless defined $line && length $line;

	my $value = eval { JSON::PP->new->utf8->decode($line) };
	unless ( defined $value ) {
		$self->{error} = "invalid JSON from $self->{path}";
		return;
	}

	return $value;
}

# $self->read_line:
#	Read one line without its terminator. The method returns undef
#	on a timeout, an end of file, or a read error, with the reason
#	in ->error.
sub read_line ($self)
{
	$self->{error} = undef;

	my $sock = $self->{sock};
	unless ($sock) {
		$self->{error} = 'not connected';
		return;
	}

	my $deadline = time + $self->{timeout};
	my $select   = IO::Select->new($sock);

	while (1) {
		my $nl = index $self->{buffer}, "\n";
		if ( $nl >= 0 ) {
			my $line = substr $self->{buffer}, 0, $nl;
			substr $self->{buffer}, 0, $nl + 1, '';
			return $line;
		}

		my $left = $deadline - time;
		if ( $left <= 0 || !$select->can_read($left) ) {
			$self->{error} = "timeout reading $self->{path}";
			return;
		}

		my $n = sysread $sock, my $chunk, READ_CHUNK;
		if ( !defined $n ) {
			next if $!{EINTR};
			$self->{error} = "read $self->{path}: $!";
			$self->disconnect;
			return;
		}
		if ( $n == 0 ) {
			$self->{error} = "$self->{path} closed the connection";
			$self->disconnect;
			return;
		}

		$self->{buffer} .= $chunk;
	}
}

1;
