#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Fugu::Imsg - imsg(3) messages over a socketpair.
#
# Protocol::Imsg owns the frame, and t/protocol/imsg.t proves it over
# bytes. This file proves the socket: the write loop, the SIGPIPE
# guard, the poll, the read loop, EOF, and the close. The file builds
# one frame with the codec, for the case that has to arrive in two
# writes.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Protocol::Imsg;
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Time::HiRes qw(time);

use_ok('Fugu::Imsg');

# pair(): two Fugu::Imsg objects over a fresh socketpair
sub pair ()
{
	socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
	    or die "socketpair: $!";
	return (
		Fugu::Imsg->new( fh => $a ),
		Fugu::Imsg->new( fh => $b ),
	);
}

# receiver(): one Fugu::Imsg object and the raw peer handle, for a test
# that writes bytes the transport would never produce
sub receiver ()
{
	socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
	    or die "socketpair: $!";
	return ( $a, Fugu::Imsg->new( fh => $b ) );
}

subtest 'round-trip over a socketpair' => sub {
	my ( $tx, $rx ) = pair();

	ok( $tx->send( type => 8, data => 'payload' ), 'send succeeds' );
	my $msg = $rx->recv( timeout => 5 );
	ok( defined $msg, 'recv returns a message' );
	is( $msg->{type}, 8,         'type round-trips' );
	is( $msg->{data}, 'payload', 'payload round-trips' );

	ok( $tx->send( type => 11 ), 'empty payload sends' );
	$msg = $rx->recv( timeout => 5 );
	is( $msg->{type}, 11, 'empty-payload type round-trips' );
	is( $msg->{data}, '', 'empty payload round-trips' );
};

# The bound itself belongs to the codec. What belongs here is the
# 16368-byte round trip: the write loop and the read loop both have to
# carry a message that fills the frame.
subtest 'the largest payload survives the socket' => sub {
	my ( $tx, $rx ) = pair();

	my $max = Fugu::Imsg::MAX_PAYLOAD();
	is( $max, Protocol::Imsg::MAX_PAYLOAD(),
		'the transport re-exports the bound of the codec' );

	ok( !defined $tx->send( type => 1, data => 'x' x ( $max + 1 ) ),
		'a payload over the bound returns undef' );
	ok( $tx->send( type => 1, data => 'x' x $max ),
		'a payload at the bound is accepted' );
	my $msg = $rx->recv( timeout => 5 );
	is( length( $msg->{data} ), $max, 'the maximum payload round-trips' );
};

subtest 'truncated header then EOF returns undef' => sub {
	my ( $peer, $rx ) = receiver();

	syswrite $peer, "\x08\x00\x00\x00\x10\x00\x00\x00";    # 8 of 16 bytes
	close $peer;
	ok( !defined $rx->recv( timeout => 5 ),
		'EOF mid-header yields undef, not a hang or a die' );
	ok( $rx->is_dead, 'and the connection is dead' );
};

subtest 'two messages in one read' => sub {
	my ( $tx, $rx ) = pair();

	ok( $tx->send( type => 15, data => 'first' ),  'first sent' );
	ok( $tx->send( type => 16, data => 'second' ), 'second sent' );

	my $m1 = $rx->recv( timeout => 5 );
	my $m2 = $rx->recv( timeout => 5 );
	is( $m1->{type}, 15,       'first message type' );
	is( $m1->{data}, 'first',  'first message payload' );
	is( $m2->{type}, 16,       'second message type' );
	is( $m2->{data}, 'second', 'second message payload' );
};

subtest 'write after peer close returns undef, does not die' => sub {
	my ( $tx, $rx ) = pair();
	close $rx->{fh};

	my $lived = eval {

		# The first write can land in the socket buffer. A
		# second write always raises EPIPE.
		$tx->send( type => 1, data => 'x' );
		my $r = $tx->send( type => 1, data => 'x' );
		ok( !defined $r, 'send to a closed peer returns undef' );
		1;
	};
	ok( $lived, 'no SIGPIPE death and no exception' ) or diag $@;
};

# A dead connection and an oversized payload are different faults, and
# Fugu::Control::Client::request prints this $! to the operator. Thus
# the dead check must come before the encode: reversed, "the daemon
# closed the connection" reads as "Message too long".
subtest 'the errno tells the two send failures apart' => sub {
	my ( $tx, $rx ) = pair();

	$! = 0;
	ok( !defined $tx->send( type => 1, data => 'x' x 20000 ),
		'an oversized payload on a live connection fails' );
	is( "$!", 'Message too long', 'and $! names the payload' );

	$tx->close;
	$! = 0;
	ok( !defined $tx->send( type => 1, data => 'x' x 20000 ),
		'the same payload on a dead connection fails' );
	is( "$!", 'Broken pipe', 'and $! names the connection' );
};

subtest 'recv timeout returns undef without data' => sub {
	my ( $tx, $rx ) = pair();

	my $start = time;
	ok( !defined $rx->recv( timeout => 0.2 ), 'timeout yields undef' );
	cmp_ok( time - $start, '<', 5, 'returned well before forever' );
	ok( !$rx->is_dead, 'a timeout does not kill the connection' );
};

# An event loop already knows the socket is readable. It must not sit
# in recv, and it must not lose what arrived.
subtest 'a zero timeout takes what arrived and returns' => sub {
	my ( $tx, $rx ) = pair();

	my $start = time;
	ok( !defined $rx->recv( timeout => 0 ), 'an empty socket yields undef' );
	cmp_ok( time - $start, '<', 1, 'and it did not wait' );
	ok( !$rx->is_dead, 'the connection is still usable' );

	$tx->send( type => 9, data => 'now' );
	my $msg = $rx->recv( timeout => 0 );
	ok( defined $msg, 'a whole message is taken' );
	is( $msg->{data}, 'now', 'and it is the one that was sent' );

	# A message that arrives in two writes must survive the read
	# that saw only the first half
	my $whole = Protocol::Imsg->new->encode( type => 7, data => 'abcdef' );
	syswrite $tx->{fh}, substr( $whole, 0, 10 );
	ok( !defined $rx->recv( timeout => 0 ), 'half a header is not a message' );
	ok( !$rx->is_dead, 'and it does not poison the connection' );

	syswrite $tx->{fh}, substr( $whole, 10 );
	is( $rx->recv( timeout => 0 )->{data},
		'abcdef', 'the rest completes it' );
};

# The codec records the framing failure; the transport must turn it
# into a dead connection. Without the propagation, Fugu::Control spins
# on a readable but unusable socket forever.
subtest 'a framing failure kills the connection' => sub {
	my ( $peer, $rx ) = receiver();

	# A len of 4 is less than the header size. The framing makes it
	# invalid [MDNS-Imsg §2].
	syswrite $peer, pack( 'L4', 1, 4, 0, 0 );
	ok( !defined $rx->recv( timeout => 5 ), 'invalid len yields undef' );
	ok( $rx->is_dead, 'and the transport is dead' );

	# The second recv must return at once and must not block on a
	# socket that is still open and still readable.
	my $start = time;
	ok( !defined $rx->recv( timeout => 5 ),
		'the connection stays dead afterwards' );
	cmp_ok( time - $start, '<', 1, 'and the second recv does not block' );
};

subtest 'close ends the connection for both sides' => sub {
	my ( $tx, $rx ) = pair();

	ok( !$tx->is_dead, 'a fresh object is not dead' );
	ok( $tx->close,    'close returns 1' );
	ok( $tx->is_dead,  'and the object is dead' );
	ok( $tx->close,    'a second close is a success' );

	ok( !defined $tx->send( type => 1 ), 'send after close fails' );

	# The peer sees the end of the stream
	ok( !defined $rx->recv( timeout => 5 ), 'the peer reads EOF' );
	ok( $rx->is_dead, 'and the peer connection is dead' );
};

# recv extracts before it checks the dead flag. Thus a buffer that
# still holds a whole frame at the close would hand it out afterwards.
# Two messages in one read leave exactly that state: recv returns the
# first, and the second waits in the codec.
subtest 'close drops a frame that arrived before it' => sub {
	my ( $tx, $rx ) = pair();

	$tx->send( type => 15, data => 'first' );
	$tx->send( type => 16, data => 'second' );

	is( $rx->recv( timeout => 5 )->{data},
		'first', 'the first message comes out' );

	$rx->close;
	ok( !defined $rx->recv( timeout => 0 ),
		'and the second does not, after the close' );
};

done_testing();
