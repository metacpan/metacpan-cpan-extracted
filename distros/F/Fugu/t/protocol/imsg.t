#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Protocol::Imsg - the imsg(3) frame, as bytes.
#
# The codec performs no system call, so every case here is bytes in and
# bytes out. The socket half is proven in t/fugu/imsg.t, over a real
# socketpair.

use v5.36;
use Test::More;
use Errno qw(EBADMSG EMSGSIZE);
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Protocol::Imsg');

subtest 'the constants match the wire format' => sub {
	is( Protocol::Imsg::HEADER_SIZE(),  16,    'the header is 16 bytes' );
	is( Protocol::Imsg::MAX_IMSGSIZE(), 16384, 'MAX_IMSGSIZE is 16384' );
	is( Protocol::Imsg::MAX_PAYLOAD(),  16368,
		'the payload bound is the difference' );
	is( Protocol::Imsg::FD_MARK(), 0x80000000,
		'FD_MARK is the high bit of len' );
	is( length( Protocol::Imsg->new->encode( type => 1 ) ),
		16, 'an empty message is a bare header' );
};

subtest 'a round trip through the buffer' => sub {
	my $codec = Protocol::Imsg->new;

	my $bytes = $codec->encode( type => 8, data => 'payload' );
	is( length($bytes), 16 + 7, 'len counts the header and the payload' );

	$codec->append($bytes);
	my $msg = $codec->next_message;
	ok( defined $msg, 'the buffer yields a message' );
	is( $msg->{type}, 8,         'the type round-trips' );
	is( $msg->{data}, 'payload', 'and the payload' );

	ok( !defined $codec->next_message, 'and nothing is left over' );
};

subtest 'an oversized payload is refused, not truncated' => sub {
	my $codec = Protocol::Imsg->new;
	my $max   = Protocol::Imsg::MAX_PAYLOAD();

	$! = 0;
	ok( !defined $codec->encode( type => 1, data => 'x' x ( $max + 1 ) ),
		'a payload over the bound returns undef' );
	is( $! + 0, EMSGSIZE, 'and sets $! to EMSGSIZE' );

	my $bytes = $codec->encode( type => 1, data => 'x' x $max );
	ok( defined $bytes, 'a payload at the bound is accepted' );
	is( length($bytes), Protocol::Imsg::MAX_IMSGSIZE(),
		'and it fills the message exactly' );
};

subtest 'a partial frame waits for the rest' => sub {
	my $codec = Protocol::Imsg->new;
	my $bytes = $codec->encode( type => 7, data => 'abcdef' );

	$codec->append( substr $bytes, 0, 10 );
	ok( !defined $codec->next_message, 'half a header is not a message' );
	ok( !$codec->is_failed, 'and it is not a failure either' );

	$codec->append( substr $bytes, 10, 4 );
	ok( !defined $codec->next_message, 'a partial payload is not one' );

	$codec->append( substr $bytes, 14 );
	is( $codec->next_message->{data}, 'abcdef', 'the rest completes it' );
};

subtest 'two messages in one append' => sub {
	my $codec = Protocol::Imsg->new;

	$codec->append( $codec->encode( type => 15, data => 'first' )
		. $codec->encode( type => 16, data => 'second' ) );

	my $m1 = $codec->next_message;
	my $m2 = $codec->next_message;
	is( $m1->{type}, 15,       'the first type' );
	is( $m1->{data}, 'first',  'the first payload' );
	is( $m2->{type}, 16,       'the second type' );
	is( $m2->{data}, 'second', 'the second payload' );
	ok( !defined $codec->next_message, 'and the buffer is empty' );
};

subtest 'an invalid length is a permanent failure' => sub {
	my $codec = Protocol::Imsg->new;

	# A len of 4 is less than the header size, so the framing makes
	# it invalid [MDNS-Imsg §2].
	$! = 0;
	$codec->append( pack 'L4', 1, 4, 0, 0 );
	ok( !defined $codec->next_message, 'a short len yields undef' );
	is( $! + 0,           EBADMSG, 'and sets $! to EBADMSG' );
	ok( $codec->is_failed, 'and the failure is recorded' );

	# The failure is permanent: a valid frame after it must not
	# come out, because native imsg drops such a connection.
	$codec->append( Protocol::Imsg->new->encode( type => 2, data => 'x' ) );
	ok( !defined $codec->next_message, 'a later valid frame stays down' );

	# A len above MAX_IMSGSIZE fails the same way.
	my $big = Protocol::Imsg->new;
	$big->append( pack 'L4', 1, Protocol::Imsg::MAX_IMSGSIZE() + 1, 0, 0 );
	ok( !defined $big->next_message, 'a len over the bound yields undef' );
	ok( $big->is_failed,             'and it is permanent too' );
};

subtest 'reset empties the buffer and clears the failure' => sub {
	my $codec = Protocol::Imsg->new;

	$codec->append( $codec->encode( type => 4, data => 'held' ) );
	$codec->reset;
	ok( !defined $codec->next_message,
		'a frame that arrived before the reset is gone' );

	$codec->append( pack 'L4', 1, 4, 0, 0 );
	$codec->next_message;
	ok( $codec->is_failed, 'the codec is failed' );
	$codec->reset;
	ok( !$codec->is_failed, 'and the reset clears it' );

	$codec->append( $codec->encode( type => 5, data => 'again' ) );
	is( $codec->next_message->{data}, 'again',
		'so the codec works after a reset' );
};

subtest 'the header carries peerid and pid' => sub {
	my $codec = Protocol::Imsg->new;

	$codec->append( $codec->encode( type => 3, data => 'x', peerid => 4242 ) );
	my $msg = $codec->next_message;
	is( $msg->{peerid}, 4242, 'peerid round-trips' );
	is( $msg->{pid},    $$,   'and the default pid names this process' );

	# The default peerid is 0, as the protocols that do not
	# correlate expect [MDNS-Imsg §3].
	$codec->append( $codec->encode( type => 3 ) );
	is( $codec->next_message->{peerid}, 0, 'the default peerid is 0' );

	# Several outstanding requests keep their own correlation
	$codec->append( $codec->encode( type => 1, data => 'a', peerid => 1 )
		. $codec->encode( type => 1, data => 'b', peerid => 2 ) );
	is( $codec->next_message->{peerid}, 1, 'the first peerid' );
	is( $codec->next_message->{peerid}, 2, 'the second peerid' );

	# imsg substitutes the sender's pid when the caller passes 0
	# [MDNS-Imsg §3], so a pid of 0 must not reach the wire.
	$codec->append( $codec->encode( type => 1, pid => 0 ) );
	is( $codec->next_message->{pid}, $$, 'a pid of 0 becomes this pid' );

	$codec->append( $codec->encode( type => 1, pid => 4711 ) );
	is( $codec->next_message->{pid}, 4711, 'and a given pid is kept' );
};

# The codec never opens a socket, and it never writes one. A method
# that reached the system would break every embedder that treats it as
# a pure function of its bytes.
subtest 'the codec performs no system call' => sub {
	my $source = "$RealBin/../../lib/Protocol/Imsg.pm";
	open my $fh, '<', $source or die "Cannot read $source: $!";
	my $text = do { local $/; <$fh> };
	close $fh;

	for my $call (qw(syswrite sysread IO::Select CORE::close socketpair)) {
		unlike( $text, qr/\Q$call\E/, "no $call" );
	}
};

done_testing();
