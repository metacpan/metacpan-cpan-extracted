#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/MDNS-Imsg.md
#
# The framing is Protocol::Imsg, so most sections drive the codec over
# bytes. Two predicates are not framing at all: an invalid len drops
# the connection, and EOF mid-message is an error. A codec with append
# and next_message has no concept of a connection or an EOF, so both
# keep their socketpair against Fugu::Imsg.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use_ok('Protocol::Imsg');
use_ok('Fugu::Imsg');

# pair(): a Fugu::Imsg endpoint and the raw peer handle. Thus a test
# can inject wire bytes that the transport would never produce.
sub pair ()
{
	socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
	    or die "socketpair: $!";
	binmode $_ for $a, $b;
	return ( Fugu::Imsg->new( fh => $a ), $b );
}

subtest '[MDNS-Imsg §1] header is four uint32 fields in order' => sub {
	my $hdr = Protocol::Imsg::_encode_header( 0x11223344, 0x55667788,
		0x99aabbcc, 0xddeeff00 );

	is( length($hdr), 16, 'IMSG_HEADER_SIZE is 16' );

	# Field layout, not byte order: each field is in its own 4-byte
	# slot at the measured offset. The host byte order does not
	# matter.
	is( unpack( 'L', substr( $hdr, 0, 4 ) ),
		0x11223344, 'type at offset 0' );
	is( unpack( 'L', substr( $hdr, 4, 4 ) ),
		0x55667788, 'len at offset 4' );
	is( unpack( 'L', substr( $hdr, 8, 4 ) ),
		0x99aabbcc, 'peerid at offset 8' );
	is( unpack( 'L', substr( $hdr, 12, 4 ) ),
		0xddeeff00, 'pid at offset 12' );
};

subtest '[MDNS-Imsg §2] len counts header plus payload' => sub {
	my $wire =
	    Protocol::Imsg->new->encode( type => 8, data => 'x' x 240 );

	is( length($wire), 256, 'whole message is header + payload' );
	my ( $type, $len ) = unpack 'L2', $wire;
	is( $len, 256, 'len field includes the 16-byte header' );
};

subtest '[MDNS-Imsg §2] payload bound is MAX_IMSGSIZE minus header' =>
    sub {
	my $codec = Protocol::Imsg->new;

	ok( !defined $codec->encode( type => 1, data => 'x' x 16369 ),
		'payload above 16368 bytes is refused, not truncated' );
	ok( defined $codec->encode( type => 1, data => 'x' x 16368 ),
		'payload of exactly 16368 bytes is accepted' );
    };

subtest '[MDNS-Imsg §2] receiver masks the fd mark off len' => sub {
	my $codec = Protocol::Imsg->new;

	# A message whose len carries IMSG_FD_MARK still frames
	# correctly after the receiver masks off the mark
	$codec->append(
		pack( 'L4', 7, ( 16 + 4 ) | 0x80000000, 0, 1 ) . 'data' );
	my $msg = $codec->next_message;
	ok( defined $msg, 'marked message received' );
	is( $msg->{data}, 'data', 'payload length taken from masked len' );
};

# A dropped connection is a transport predicate: the codec records a
# permanent framing failure, and Fugu::Imsg turns it into a socket that
# carries nothing more.
subtest '[MDNS-Imsg §2] invalid len drops the connection' => sub {
	my ( $imsg, $peer ) = pair();

	syswrite $peer, pack( 'L4', 1, 15, 0, 1 );    # len < header size
	ok( !defined $imsg->recv( timeout => 5 ), 'len below 16 rejected' );
	ok( !defined $imsg->recv( timeout => 0.1 ), 'connection is dead' );
	ok( $imsg->is_dead, 'and it reports so' );

	( $imsg, $peer ) = pair();
	syswrite $peer, pack( 'L4', 1, 16385, 0, 1 );    # len > MAX_IMSGSIZE
	ok( !defined $imsg->recv( timeout => 5 ),
		'len above MAX_IMSGSIZE rejected' );
	ok( $imsg->is_dead, 'and that connection is dead too' );
};

subtest '[MDNS-Imsg §3] pid is the sender, peerid zero' => sub {
	my $wire = Protocol::Imsg->new->encode( type => 11, data => 'p' );

	my ( $type, $len, $peerid, $pid ) = unpack 'L4', $wire;
	is( $peerid, 0,  'peerid sent as 0' );
	is( $pid,    $$, 'pid field carries the sending process pid' );

	# imsg substitutes the sender's pid when the caller passes 0.
	# Thus a literal 0 never reaches the wire.
	my $zero = Protocol::Imsg->new->encode( type => 11, pid => 0 );
	is( ( unpack 'L4', $zero )[3],
		$$, 'a pid of 0 becomes the sending pid' );
};

subtest '[MDNS-Imsg §4] short reads accumulate across calls' => sub {
	my $codec = Protocol::Imsg->new;

	my $wire = pack( 'L4', 15, 16 + 6, 0, 1 ) . 'abcdef';

	# Append the header split mid-field. Then append the rest.
	$codec->append( substr $wire, 0, 10 );
	ok( !defined $codec->next_message,
		'partial header is not a message yet' );
	$codec->append( substr $wire, 10 );
	my $msg = $codec->next_message;
	is( $msg->{data}, 'abcdef', 'message assembled across reads' );
};

subtest '[MDNS-Imsg §4] several messages in one read' => sub {
	my $codec = Protocol::Imsg->new;

	my $wire = ( pack( 'L4', 15, 16 + 1, 0, 1 ) . 'a' )
	    . ( pack( 'L4', 16, 16 + 1, 0, 1 ) . 'b' );
	$codec->append($wire);

	my $m1 = $codec->next_message;
	my $m2 = $codec->next_message;
	is( $m1->{type}, 15,  'first message framed' );
	is( $m2->{type}, 16,  'second message framed from the same read' );
	is( $m2->{data}, 'b', 'boundary fell exactly between messages' );
};

# EOF is a transport predicate. The codec has no concept of one: it
# waits for more bytes, and only the socket knows that none will come.
subtest '[MDNS-Imsg §4] EOF mid-message is an error' => sub {
	my ( $imsg, $peer ) = pair();

	syswrite $peer, pack( 'L4', 15, 16 + 100, 0, 1 ) . 'short';
	close $peer;
	ok( !defined $imsg->recv( timeout => 5 ),
		'truncated message yields undef on EOF' );
	ok( $imsg->is_dead, 'and the connection is dead' );
};

done_testing();
