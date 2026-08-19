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

package Fugu::Imsg;
our $VERSION = '0.1.2';

use Errno qw(EPIPE);
use IO::Select;
use Protocol::Imsg;
use Time::HiRes qw(time);

# Fugu::Imsg - imsg(3) messages over a connected stream socket.
#
# Protocol::Imsg owns the frame. This module owns the socket: the write
# loop, the SIGPIPE guard, the poll, and the read loop. It never opens
# or names a socket itself, and it never logs. The callers decide what
# an error means.
#
# The constant below is re-exported and not redefined. Fugu::Control
# reads Fugu::Imsg::MAX_PAYLOAD as a bareword, so the constant leaving
# this module would be a compile-time abort, not a runtime error.
use constant MAX_PAYLOAD => Protocol::Imsg::MAX_PAYLOAD;

# Fugu::Imsg->new(%args):
#	fh => $fh	connected stream socket (required)
#	Make a transport over an already-connected handle.
sub new ( $class, %args )
{
	my $fh = $args{fh} or die 'fh parameter required';
	binmode $fh;

	return bless {
		fh    => $fh,
		codec => Protocol::Imsg->new,
		dead  => 0,
	}, $class;
}

# $self->send(%args):
#	type   => $n	message type (required)
#	data   => $bytes payload (default empty)
#	peerid => $n	caller-chosen correlation value (default 0)
#	Frame and write one message. The method returns 1 on success.
#	It returns undef, with $! set, on a dead connection, an
#	oversized payload, or a write error. A peer that closed the
#	socket shows as EPIPE, not as a fatal SIGPIPE.
#
#	The dead check comes first, and the encode second. A caller
#	prints this $! to the operator, and the two conditions have
#	different causes: EPIPE says the peer closed the connection,
#	EMSGSIZE says the payload was too long.
sub send ( $self, %args )
{
	if ( $self->{dead} ) {
		$! = EPIPE;
		return;
	}

	# The codec sets $! to EMSGSIZE for an oversized payload.
	my $msg = $self->{codec}->encode(%args) // return;

	local $SIG{PIPE} = 'IGNORE';
	my $off = 0;
	while ( $off < length($msg) ) {
		my $n =
		    syswrite( $self->{fh}, $msg, length($msg) - $off, $off );
		if ( !defined $n ) {
			next if $!{EINTR};
			$self->{dead} = 1;
			return;
		}
		$off += $n;
	}

	return 1;
}

# $self->recv(%args):
#	timeout => $seconds	how long to wait (undef blocks forever)
#	Return one whole message as a hashref with type, peerid, pid
#	and data. The method accumulates short reads across calls. It
#	returns undef on timeout, clean EOF, or an unrecoverable
#	framing error. For a framing error the codec sets $! to EBADMSG,
#	and this method marks the connection dead per
#	spec/MDNS-Imsg.md §4.
#
#	A timeout of 0 takes what already arrived and returns. This is
#	the form for an event loop, which knows the socket is readable
#	and must not sit in this call. A partial message stays in the
#	buffer for the next call.
sub recv ( $self, %args )
{
	my $timeout  = $args{timeout};
	my $deadline = defined $timeout ? time + $timeout : undef;
	my $polled   = 0;

	while (1) {
		if ( my $msg = $self->{codec}->next_message ) {
			return $msg;
		}

		# A framing failure is permanent for the connection.
		if ( $self->{codec}->is_failed ) {
			$self->{dead} = 1;
			return;
		}
		return if $self->{dead};

		if ( defined $deadline ) {
			my $remaining = $deadline - time;

			# A zero timeout still gets one poll. The
			# caller asked for what already arrived, not
			# for nothing at all, and by the time the
			# deadline is computed it has already passed.
			$remaining = 0 if $remaining < 0 && !$polled;
			return         if $remaining < 0;

			# can_read(0) polls and does not wait
			my @ready =
			    IO::Select->new( $self->{fh} )
			    ->can_read($remaining);
			$polled++;
			return unless @ready;
		}

		my $n = sysread( $self->{fh}, my $chunk, 65536 );
		if ( !defined $n ) {
			next if $!{EINTR};
			$self->{dead} = 1;
			return;
		}
		if ( $n == 0 ) {

			# A clean EOF occurs only on a message boundary.
			# An EOF with buffered bytes is a truncated
			# message either way.
			$self->{dead} = 1;
			return;
		}
		$self->{codec}->append($chunk);
	}
}

# $self->close:
#	Close the socket and mark the connection dead. The method is
#	idempotent and returns 1. A caller that owns the socket closes
#	it here, and never by reaching into the object.
#
#	The reset matters: recv extracts before it checks the dead
#	flag, so a buffer that still held a frame would hand it out
#	after the close.
sub close ($self)
{
	if ( $self->{fh} ) {
		CORE::close $self->{fh};
		$self->{fh} = undef;
	}
	$self->{dead} = 1;
	$self->{codec}->reset;

	return 1;
}

# $self->is_dead:
#	Report if the connection can no longer carry a message. A
#	close, an EOF, a write error, or a framing error all lead
#	here.
sub is_dead ($self)
{
	return $self->{dead} ? 1 : 0;
}

1;
