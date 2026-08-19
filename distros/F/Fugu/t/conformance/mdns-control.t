#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/MDNS-Control.md

use v5.36;
use Test::More;
use Config;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use POSIX qw(_exit);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);

use_ok('Fugu::Imsg');
use_ok('Fugu::Mdnsd');

# The layout literals below are LP64 and little-endian, as measured
# for the platforms that OpenHAP deploys to. On other platforms the
# daemon's own struct differs. There a byte-exact replay is
# meaningless.
my $lp64_le = $Config{ptrsize} == 8
    && unpack( 'S', "\x01\x00" ) == 1;

# harness(%replies): a Fugu::Mdnsd whose connection is one end of a
# socketpair. The harness queues the given replies on the peer end.
# It returns ($mdns, $peer). Tests read the sent bytes back from
# $peer.
sub harness (@reply_types)
{
	socketpair( my $a, my $b, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
	    or die "socketpair: $!";
	binmode $_ for $a, $b;

	my $mdns = Fugu::Mdnsd->new;
	$mdns->{imsg} = Fugu::Imsg->new( fh => $a );

	for my $type (@reply_types) {
		syswrite $b,
		    pack( 'L4', $type, 272, 0, 1 )
		    . pack( 'Z256', 'OpenHAP Bridge' );
	}

	return ( $mdns, $b );
}

# publish_example($mdns): the worked example's parameters
sub publish_example ($mdns)
{
	return $mdns->publish_service(
		name  => 'OpenHAP Bridge',
		app   => 'hap',
		proto => 'tcp',
		port  => 51827,
		txt   => 'c#=1.sf=1',
	);
}

# read_all($peer): drain everything that the client sent
sub read_all ($peer)
{
	my $wire = '';
	while ( sysread $peer, my $chunk, 65536 ) {
		$wire .= $chunk;
		last if length($wire) >= 272 + 880 + 272;
	}
	return $wire;
}

subtest '[MDNS-Control §2] imsg_type ordinals are positional' => sub {
	my @enum = qw(
	    IMSG_NONE IMSG_CTL_END IMSG_CTL_LOOKUP IMSG_CTL_LOOKUP_FAILURE
	    IMSG_CTL_BROWSE_ADD IMSG_CTL_BROWSE_DEL IMSG_CTL_RESOLVE
	    IMSG_CTL_RESOLVE_FAILURE IMSG_CTL_GROUP_ADD IMSG_CTL_GROUP_RESET
	    IMSG_CTL_GROUP_ADD_SERVICE IMSG_CTL_GROUP_COMMIT
	    IMSG_CTL_GROUP_ERR_COLLISION IMSG_CTL_GROUP_ERR_NOT_FOUND
	    IMSG_CTL_GROUP_ERR_DOUBLE_ADD IMSG_CTL_GROUP_PROBING
	    IMSG_CTL_GROUP_ANNOUNCING IMSG_CTL_GROUP_PUBLISHED
	);
	for my $ordinal ( 0 .. $#enum ) {
		my $value = Fugu::Mdnsd->can( $enum[$ordinal] )->();
		is( $value, $ordinal,
			"[MDNS-Control §2/$enum[$ordinal]] ordinal $ordinal"
		);
	}
};

subtest '[MDNS-Control §4] struct mdns_service against a literal' => sub {
	plan skip_all => 'layout literal is LP64 little-endian'
	    unless $lp64_le;

	my $mdns = Fugu::Mdnsd->new;
	$mdns->{service} = {
		name  => 'OpenHAP Bridge',
		app   => 'hap',
		proto => 'tcp',
		port  => 51827,
		txt   => 'c#=1.sf=1',
	};

	# The test builds the whole buffer field by field at the spec's
	# offsets. It writes a zeroed LIST_ENTRY, NUL padding of every
	# fixed field, the internal padding at 858, and INADDR_ANY. A field-by-field
	# comparison would pass even with the total size or padding
	# wrong. Thus the assertion is on the entire 864 bytes.
	my $expected = "\0" x 864;
	substr( $expected, 16,  3 )  = 'hap';
	substr( $expected, 80,  3 )  = 'tcp';
	substr( $expected, 84,  14 ) = 'OpenHAP Bridge';
	substr( $expected, 600, 2 )  = "\x73\xca";       # 51827, LE
	substr( $expected, 602, 9 )  = 'c#=1.sf=1';

	my $encoded = $mdns->_encode_service;
	is( length($encoded), 864, 'encoded size is 864 bytes' );
	ok( $encoded eq $expected, 'entire buffer matches the literal' )
	    or diag 'first difference at offset '
	    . (
		grep {
			substr( $encoded, $_, 1 ) ne
			    substr( $expected, $_, 1 )
		} 0 .. 863
	    )[0];
};

subtest '[MDNS-Control §10] the publish conversation, byte-exact' => sub {
	plan skip_all => 'wire literals are LP64 little-endian'
	    unless $lp64_le;

	my ( $mdns, $peer ) = harness( 15, 16, 17 );
	ok( publish_example($mdns), 'client reaches PUBLISHED' );

	my $wire = read_all($peer);
	is( length($wire), 272 + 880 + 272,
		'three messages: 272 + 880 + 272 bytes' );

	my $name_payload = 'OpenHAP Bridge' . ( "\0" x 242 );

	# Message 1: GROUP_ADD. The pid bytes are sender-specific
	# [MDNS-Imsg §3]. Thus the test asserts them as the test
	# process's pid. The test asserts the rest byte-for-byte against
	# the spec literal.
	my $m1 = substr( $wire, 0, 272 );
	is( substr( $m1, 0, 4 ), "\x08\x00\x00\x00", 'type = 8' );
	is( substr( $m1, 4, 4 ), "\x10\x01\x00\x00", 'len = 272' );
	is( substr( $m1, 8, 4 ), "\x00\x00\x00\x00", 'peerid = 0' );
	is( unpack( 'L', substr( $m1, 12, 4 ) ),
		$$, 'pid well-formed: the sending process' );
	is( substr( $m1, 16 ), $name_payload,
		'payload is the NUL-padded group name' );

	# Message 2: GROUP_ADD_SERVICE
	my $m2 = substr( $wire, 272, 880 );
	is( substr( $m2, 0, 4 ), "\x0a\x00\x00\x00", 'type = 10' );
	is( substr( $m2, 4, 4 ), "\x70\x03\x00\x00", 'len = 880' );
	is( substr( $m2, 16, 16 ), "\0" x 16, 'entry on the wire as zeros' );
	is( substr( $m2, 32, 3 ),  'hap',     'app without underscore' );
	is( substr( $m2, 96, 4 ),  "tcp\0",   'proto without underscore' );
	is( substr( $m2, 100, 14 ), 'OpenHAP Bridge', 'instance name' );
	is( substr( $m2, 356, 256 ), "\0" x 256,
		'empty target: mdnsd substitutes its hostname' );
	is( substr( $m2, 616, 2 ), "\x73\xca", 'port 51827' );
	is( substr( $m2, 618, 9 ), 'c#=1.sf=1', 'TXT string verbatim' );
	is( substr( $m2, 876, 4 ), "\0" x 4, 'addr INADDR_ANY' );

	# Message 3: GROUP_COMMIT differs from message 1 only in type
	my $m3 = substr( $wire, 272 + 880, 272 );
	is( substr( $m3, 0, 4 ), "\x0b\x00\x00\x00", 'type = 11' );
	is( substr( $m3, 4 ), substr( $m1, 4 ),
		'otherwise identical to GROUP_ADD' );
};

subtest '[MDNS-Control §6.1] progress replies are not terminal' => sub {

	# PROBING and ANNOUNCING alone do not finish the publish. Only
	# PUBLISHED does.
	my ( $mdns, $peer ) = harness( 15, 16 );
	ok( !defined $mdns->publish_service(
			name  => 'OpenHAP Bridge',
			app   => 'hap',
			proto => 'tcp',
			port  => 51827,
			txt   => 'sf=1',
			timeout => 0.3,
		),
		'no terminal reply: publish does not succeed'
	);
	ok( !$mdns->is_published, 'not published on progress alone' );

	( $mdns, $peer ) = harness( 15, 16, 17 );
	ok( publish_example($mdns), 'PUBLISHED after progress succeeds' );
	ok( $mdns->is_published,    'published on the terminal reply' );
};

subtest '[MDNS-Control §9] an error reply is terminal' => sub {
	my ( $mdns, $peer ) = harness(12);    # ERR_COLLISION
	ok( !defined publish_example($mdns), 'collision fails the publish' );
	like( $mdns->error, qr/collision/, 'collision reported' );
	ok( !$mdns->is_published, 'not published after an error' );
};

subtest '[MDNS-Control §7] group name equals the instance name' => sub {
	my ( $mdns, $peer ) = harness( 15, 16, 17 );
	ok( publish_example($mdns), 'published' );

	my $wire  = read_all($peer);
	my $group = substr( $wire, 16, 256 );
	my $name  = substr( $wire, 272 + 16 + 84, 256 );
	is( $group, $name,
		'GROUP_ADD payload and struct name field are identical' );

	# The API cannot express the unusable combination:
	# publish_service has no separate group parameter to disagree
	# with the name
	ok( !Fugu::Mdnsd->can('publish_group'),
		'no API takes a separate group name' );
};

subtest '[MDNS-Control §8] TXT replacement reconnects, never resets' =>
    sub {
	my $dir  = tempdir( CLEANUP => 1 );
	my $path = "$dir/mdnsd.sock";
	my $dump = "$dir/dump.txt";

	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $path,
		Listen => 5,
	) or die "listen: $!";

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		local $SIG{ALRM} = sub { _exit(1) };
		alarm 30;
		open my $fh, '>', $dump or _exit(1);
		$fh->autoflush(1);
		for my $conn ( 0, 1 ) {
			my $sock = $listener->accept or _exit(1);
			my $imsg = Fugu::Imsg->new( fh => $sock );
			for ( 1 .. 3 ) {
				my $msg = $imsg->recv( timeout => 10 )
				    or _exit(1);
				say $fh "conn=$conn type=$msg->{type}";
			}
			$imsg->send(
				type => 17,
				data => pack( 'Z256', 'OpenHAP Bridge' ) );

			# Hold until the client closes
			1 while defined $imsg->recv( timeout => 10 );
		}
		_exit(0);
	}
	close $listener;

	my $mdns = Fugu::Mdnsd->new( socket_path => $path );
	ok( $mdns->connect,          'connected' );
	ok( publish_example($mdns),  'published' );
	ok( $mdns->update_txt( txt => 'c#=1.sf=0' ), 'TXT updated' );
	$mdns->withdraw;
	waitpid $pid, 0;
	is( $? >> 8, 0, 'fake mdnsd saw two connections' );

	open my $fh, '<', $dump or die "open $dump: $!";
	chomp( my @lines = <$fh> );
	close $fh;

	is_deeply(
		\@lines,
		[
			'conn=0 type=8',  'conn=0 type=10',
			'conn=0 type=11', 'conn=1 type=8',
			'conn=1 type=10', 'conn=1 type=11',
		],
		'update is a full republish on a fresh connection'
	);
	ok( !( grep {/type=9\b/} @lines ),
		'IMSG_CTL_GROUP_RESET is never sent' );
    };

subtest '[MDNS-Control §5] TXT travels as one verbatim string' => sub {
	plan skip_all => 'layout literal is LP64 little-endian'
	    unless $lp64_le;

	# Several key=value pairs joined with '.' are a single wire
	# field. The code does not escape or re-encode anything.
	my $mdns = Fugu::Mdnsd->new;
	$mdns->{service} = {
		name  => 'x',
		app   => 'hap',
		proto => 'tcp',
		port  => 1,
		txt   => 'id=AA:BB.md=a=b.sf=1',
	};
	my $txt     = 'id=AA:BB.md=a=b.sf=1';
	my $encoded = $mdns->_encode_service;
	is( substr( $encoded, 602, length $txt ),
		$txt, 'dots and equals pass through unmodified' );
	is( substr( $encoded, 602 + length $txt, 256 - length $txt ),
		"\0" x ( 256 - length $txt ),
		'remainder of the field is NUL padding' );
};

subtest '[MDNS-Control §3.1] group names bound at 255 usable bytes' =>
    sub {
	my $mdns = Fugu::Mdnsd->new;
	ok( !defined $mdns->publish_service(
			name  => 'n' x 256,
			app   => 'hap',
			proto => 'tcp',
			port  => 1,
			txt   => '',
		),
		'a 256-byte name cannot be sent'
	);
	like( $mdns->error, qr/too long/, 'rejected as over-length' );
    };

done_testing();
