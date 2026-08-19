#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::Mdnsd against a fake mdnsd on a local socket

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use POSIX qw(_exit);
use Socket qw(SOCK_STREAM);
use Time::HiRes qw(time);

use_ok('Fugu::Imsg');
use_ok('Fugu::Mdnsd');

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# Group reply types. These values mirror the pinned enum in
# Fugu::Mdnsd.
my %REPLY = (
	collision  => 12,
	not_found  => 13,
	double_add => 14,
	probing    => 15,
	announcing => 16,
	published  => 17,
);

# start_server($behavior):
#	Fork a fake mdnsd on a fresh socket path. The function creates
#	the listener before the fork. Thus the client can connect
#	immediately. $behavior->($conn_no, $imsg, $dump_fh) runs once
#	for each accepted connection. It returns 0 to stop the accept
#	loop. The parent asserts the received messages from the dump
#	file. The child shares the TAP stream, so the child never
#	asserts. The function returns ($path, $dump_file, $pid).
sub start_server ($behavior)
{
	my $path = "$dir/mdnsd" . $n . '.sock';
	my $dump = "$dir/dump" . $n . '.txt';
	$n++;

	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $path,
		Listen => 5,
	) or die "listen $path: $!";

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		local $SIG{ALRM} = sub { _exit(1) };
		alarm 30;
		open my $fh, '>', $dump or _exit(1);
		$fh->autoflush(1);
		my $conn_no = 0;
		while ( my $sock = $listener->accept ) {
			my $imsg = Fugu::Imsg->new( fh => $sock );
			last unless $behavior->( $conn_no++, $imsg, $fh );
		}
		_exit(0);
	}
	close $listener;

	return ( $path, $dump, $pid );
}

# dump_messages($imsg, $fh, $count):
#	Read $count messages. Log the type, the payload size, and the
#	leading NUL-terminated string of each payload.
sub dump_messages ( $imsg, $fh, $count )
{
	my @msgs;
	for ( 1 .. $count ) {
		my $msg = $imsg->recv( timeout => 10 ) or return;
		my ($str) = unpack 'Z*', $msg->{data};
		printf $fh "type=%d size=%d str=%s\n", $msg->{type},
		    length( $msg->{data} ), $str;
		push @msgs, $msg;
	}
	return \@msgs;
}

# reply($imsg, $name, @types):
#	Send group replies that carry the 256-byte padded group name.
sub reply ( $imsg, $name, @types )
{
	$imsg->send( type => $REPLY{$_}, data => pack( 'Z256', $name ) )
	    for @types;
	return;
}

# drain($imsg):
#	Block until the client closes the connection
sub drain ($imsg)
{
	1 while defined $imsg->recv( timeout => 10 );
	return;
}

my %service = (
	name  => 'Unit Bridge',
	app   => 'hap',
	proto => 'tcp',
	port  => 51827,
	txt   => 'c#=1.sf=1',
);

subtest 'connect fails cleanly when the socket is missing' => sub {
	my $mdns = Fugu::Mdnsd->new( socket_path => "$dir/absent.sock" );
	ok( !defined $mdns->connect, 'connect returns undef' );
	like( $mdns->error, qr/absent\.sock/, 'error names the socket' );
	ok( !$mdns->is_published, 'not published' );
};

subtest 'publish, TXT update over a fresh connection, withdraw' => sub {
	my ( $path, $dump, $pid ) = start_server(
		sub ( $conn_no, $imsg, $fh ) {
			my $msgs = dump_messages( $imsg, $fh, 3 ) or return 0;
			my ($name) = unpack 'Z*', $msgs->[0]{data};
			reply( $imsg, $name,
				qw(probing announcing published) );
			drain($imsg);
			return $conn_no < 1;    # accept the republish, too
		} );

	my $mdns = Fugu::Mdnsd->new( socket_path => $path );
	ok( $mdns->connect, 'connected to fake mdnsd' );
	ok( $mdns->publish_service(%service), 'publish_service succeeds' );
	ok( $mdns->is_published, 'published after PUBLISHED reply' );

	ok( $mdns->update_txt( txt => 'c#=1.sf=0' ),
		'update_txt republishes over a fresh connection' );
	ok( $mdns->is_published, 'still published after TXT update' );

	ok( $mdns->withdraw,      'withdraw closes the socket' );
	ok( !$mdns->is_published, 'no longer published' );

	waitpid $pid, 0;
	is( $? >> 8, 0, 'fake mdnsd saw both conversations' );

	open my $fh, '<', $dump or die "open $dump: $!";
	my @lines = <$fh>;
	close $fh;

	is( scalar @lines, 6, 'two full ADD/ADD_SERVICE/COMMIT sequences' );
	like( $lines[0], qr/^type=8 size=256 str=Unit Bridge$/,
		'GROUP_ADD carries the padded group name' );
	like( $lines[1], qr/^type=10 size=864 str=$/,
		'GROUP_ADD_SERVICE carries an 864-byte struct' );
	like( $lines[2], qr/^type=11 size=256 str=Unit Bridge$/,
		'GROUP_COMMIT names the same group' );
	like( $lines[3], qr/^type=8 size=256 str=Unit Bridge$/,
		'republish starts with GROUP_ADD again' );
};

subtest 'error replies are terminal' => sub {
	for my $case (qw(collision double_add)) {
		my ( $path, $dump, $pid ) = start_server(
			sub ( $, $imsg, $fh ) {
				my $msgs = dump_messages( $imsg, $fh, 3 )
				    or return 0;
				my ($name) = unpack 'Z*', $msgs->[0]{data};
				reply( $imsg, $name, $case );
				drain($imsg);
				return 0;
			} );

		my $mdns = Fugu::Mdnsd->new( socket_path => $path );
		ok( $mdns->connect, "connected ($case)" );
		ok( !defined $mdns->publish_service(%service),
			"$case reply fails the publish" );
		ok( !$mdns->is_published, "not published after $case" );
		ok( length $mdns->error,  "error recorded for $case" );
		waitpid $pid, 0;
	}
};

subtest 'EOF mid-conversation fails the publish, not the process' => sub {
	my ( $path, $dump, $pid ) = start_server(
		sub ( $, $imsg, $ ) {
			$imsg->recv( timeout => 10 );    # one message only
			return 0;                        # close everything
		} );

	my $mdns = Fugu::Mdnsd->new( socket_path => $path );
	ok( $mdns->connect, 'connected' );
	my $lived = eval { !defined $mdns->publish_service(%service) };
	ok( $lived, 'publish fails without dying on the closed socket' )
	    or diag $@;
	ok( !$mdns->is_published, 'not published after EOF' );
	waitpid $pid, 0;
};

subtest 'reply timeout is bounded and parameterised' => sub {
	my ( $path, $dump, $pid ) = start_server(
		sub ( $, $imsg, $fh ) {
			my $msgs = dump_messages( $imsg, $fh, 3 ) or return 0;
			my ($name) = unpack 'Z*', $msgs->[0]{data};
			reply( $imsg, $name, 'probing' );    # never terminal
			drain($imsg);
			return 0;
		} );

	my $mdns = Fugu::Mdnsd->new( socket_path => $path );
	ok( $mdns->connect, 'connected' );
	my $start = time;
	ok( !defined $mdns->publish_service( %service, timeout => 0.5 ),
		'publish times out without a terminal reply' );
	cmp_ok( time - $start, '<', 10, 'timeout honoured the parameter' );
	like( $mdns->error, qr/timeout/, 'timeout recorded as the error' );
	waitpid $pid, 0;
};

subtest 'over-length fields are errors, not truncations' => sub {
	my $mdns = Fugu::Mdnsd->new;

	ok( !defined $mdns->publish_service( %service, name => 'x' x 256 ),
		'256-byte instance name is rejected' );
	like( $mdns->error, qr/name too long/, 'error says why' );

	ok( !defined $mdns->publish_service( %service, app => 'x' x 64 ),
		'64-byte app is rejected' );
	ok( !defined $mdns->publish_service( %service, txt => 'x' x 256 ),
		'256-byte TXT string is rejected' );

	# The wire port field is a u16. Without a check, pack truncates
	# the value modulo 65536.
	ok( !defined $mdns->publish_service( %service, port => 70000 ),
		'port above 65535 is rejected, not truncated' );
	like( $mdns->error, qr/port out of range/, 'error says why' );
};

subtest 'republish on a held connection is refused' => sub {

	# mdnsd ignores the duplicate GROUP_ADD and drops the
	# ADD_SERVICE. It answers the COMMIT with a success-looking
	# sequence for the old records. Thus publish_service must refuse
	# calls while a service is published. Replacement goes through
	# update_txt.
	my ( $path, $dump, $pid ) = start_server(
		sub ( $, $imsg, $fh ) {
			my $msgs = dump_messages( $imsg, $fh, 3 ) or return 0;
			my ($name) = unpack 'Z*', $msgs->[0]{data};
			reply( $imsg, $name, 'published' );
			drain($imsg);
			return 0;
		} );

	my $mdns = Fugu::Mdnsd->new( socket_path => $path );
	ok( $mdns->connect,                   'connected' );
	ok( $mdns->publish_service(%service), 'published once' );
	ok( !defined $mdns->publish_service(%service),
		'second publish on the live handle is refused' );
	like( $mdns->error, qr/already published/, 'error says why' );
	ok( $mdns->is_published, 'the original advertisement stands' );

	$mdns->withdraw;
	waitpid $pid, 0;
};

subtest 'update_txt is a no-op while unpublished' => sub {
	my $mdns = Fugu::Mdnsd->new;
	ok( $mdns->update_txt( txt => 'sf=0' ),
		'unpublished update_txt returns success' );
	ok( !$mdns->is_published, 'still unpublished' );
};

subtest 'publish connects on demand' => sub {
	my ( $path, $dump, $pid ) = start_server(
		sub ( $conn_no, $imsg, $fh ) {
			my $msgs = dump_messages( $imsg, $fh, 3 ) or return 0;
			my ($name) = unpack 'Z*', $msgs->[0]{data};
			reply( $imsg, $name, 'published' );
			drain($imsg);
			return 0;
		} );

	my $mdns = Fugu::Mdnsd->new( socket_path => $path );
	ok( !$mdns->is_published, 'not connected yet' );
	ok( $mdns->publish(%service), 'publish connects and publishes' );
	ok( $mdns->is_published,      'the service is advertised' );

	$mdns->withdraw;
	waitpid $pid, 0;
};

subtest 'publish reports a missing mdnsd through error' => sub {
	my $mdns = Fugu::Mdnsd->new( socket_path => "$dir/absent2.sock" );
	ok( !defined $mdns->publish(%service), 'publish returns undef' );
	like( $mdns->error, qr/absent2\.sock/, 'error names the socket' );
	ok( !$mdns->is_published, 'nothing is advertised' );
};

subtest 'the object going away withdraws the service' => sub {
	my ( $path, $dump, $pid ) = start_server(
		sub ( $conn_no, $imsg, $fh ) {
			my $msgs = dump_messages( $imsg, $fh, 3 ) or return 0;
			my ($name) = unpack 'Z*', $msgs->[0]{data};
			reply( $imsg, $name, 'published' );

			# The socket closing is the withdrawal. The
			# child ends when the client goes away.
			drain($imsg);
			return 0;
		} );

	{
		my $mdns = Fugu::Mdnsd->new( socket_path => $path );
		ok( $mdns->publish(%service), 'published inside the scope' );
	}

	# The destructor closed the socket, so the fake mdnsd sees the
	# end of the stream and its accept loop ends.
	is( waitpid( $pid, 0 ), $pid,
		'the server saw the connection close on destruction' );
};

subtest 'format_txt formats TXT records for mdnsd [MDNS-Control §5]' =>
    sub {
	is( Fugu::Mdnsd::format_txt( b => 2, a => 1, c => 3 ),
		'a=1.b=2.c=3',
		'key=value pairs joined with dots in sorted key order' );
	is( Fugu::Mdnsd::format_txt(), '', 'no records give no string' );
	is( Fugu::Mdnsd::format_txt( 'c#' => 1, sf => 0 ),
		'c#=1.sf=0', 'HAP-style keys pass through unchanged' );
};

subtest 'new proves the struct template' => sub {
	# The size is a measured fact about the platform. A template
	# that no longer encodes it means every publish would send a
	# malformed record, so new must refuse to build the object.
	ok( eval { Fugu::Mdnsd->new; 1 }, 'new accepts the shipped template' )
	    or diag($@);
	is( length( pack( Fugu::Mdnsd::SERVICE_TEMPLATE(), '', '', '', 0, 0, 0, '' ) ),
		Fugu::Mdnsd::SERVICE_LEN(),
		'the template encodes the documented size' );
};

done_testing();
