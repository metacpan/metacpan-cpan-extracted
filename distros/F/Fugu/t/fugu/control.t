#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::Control and Fugu::Control::Client over a
# temporary socket. A forked server serves one connection at a time,
# so the tests need no event loop.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);
use IO::Socket::UNIX;
use POSIX       qw(_exit);
use Socket      qw(SOCK_STREAM);
use Time::HiRes qw(sleep);

use_ok('Fugu::Control');
use_ok('Fugu::EventLoop');
use_ok('Fugu::Imsg');

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# start_server($setup): fork a server that serves connections over a
#	real event loop until the parent kills it. $setup->($control)
#	registers the commands. The function returns ($path, $pid).
sub start_server ($setup)
{
	my $path = sprintf '%s/control%d.sock', $dir, $n++;

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		local $SIG{ALRM} = sub { _exit(1) };
		alarm 30;

		my $loop    = Fugu::EventLoop->new;
		my $control = Fugu::Control->new( path => $path );
		$setup->($control);
		$control->listen( loop => $loop ) or _exit(1);
		$loop->run;
		_exit(0);
	}

	# Wait until the child has bound the socket
	for ( 1 .. 100 ) {
		last if -S $path;
		sleep 0.05;
	}
	die 'the server never bound its socket' unless -S $path;

	return ( $path, $pid );
}

# stop_server($pid, $path)
sub stop_server ( $pid, $path )
{
	kill 'TERM', $pid;
	waitpid $pid, 0;
	unlink $path;

	return;
}

subtest 'a command answers' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
			$control->register(
				echo => sub ($args) { { got => $args->{say} } } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	is_deeply( $client->request('ping'), { pong => 1 }, 'a reply decodes' );
	is( $client->error, undef, 'and no error is recorded' );

	is_deeply(
		$client->request( echo => { say => 'hello' } ),
		{ got => 'hello' },
		'the arguments reach the handler'
	);

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'the constructor contracts hold' => sub {
	my $control = Fugu::Control->new( path => "$dir/unused.sock" );
	is( $control->path, "$dir/unused.sock", 'the server knows its path' );

	ok( !eval { $control->register( c => 'not code' ); 1 },
		'a handler must be code' );
	ok( !eval { Fugu::Control->new; 1 }, 'a server needs a path' );
	ok( !eval { Fugu::Control::Client->new; 1 },
		'and so does a client' );
	ok( !eval { $control->listen; 1 }, 'and listen needs a loop' );
};

subtest 'an unknown command is refused, not fatal' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	is( $client->request('nonsense'), undef, 'the reply is undef' );
	like( $client->error, qr/unknown command: nonsense/,
		'and the reason names the command' );
	ok( !$client->socket_absent, 'the socket was there, so it was a refusal' );

	# The connection survives a refusal
	is_deeply( $client->request('ping'), { pong => 1 },
		'the next command still works' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a handler that dies gives an error reply' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( boom => sub ($) { die "no\n" } );
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	is( $client->request('boom'), undef, 'the reply is undef' );
	like( $client->error, qr/command failed: boom/,
		'and the reason says which command' );

	# The server is still there. A daemon must not fall over
	# because one handler had a bad day.
	is_deeply( $client->request('ping'), { pong => 1 },
		'the server kept serving' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a reply larger than one frame spans frames' => sub {
	# One imsg frame carries about 16 KB. A device list can be
	# bigger than that, so this is the real case, not a corner.
	my $big = 'x' x ( 4 * Fugu::Imsg::MAX_PAYLOAD() );

	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( big => sub ($) { { data => $big } } );
			$control->register(
				list => sub ($) {
					return [ map { { id => $_, pad => 'y' x 200 } }
						    1 .. 200 ];
				} );
		} );

	my $client = Fugu::Control::Client->new( path => $path );

	my $reply = $client->request('big');
	ok( defined $reply, 'the big reply arrived' )
	    or diag( $client->error // 'no error recorded' );
	is( length( $reply->{data} ), length($big), 'and it is whole' );
	is( $reply->{data}, $big, 'byte for byte' );

	my $list = $client->request('list');
	is( ref $list,     'ARRAY', 'an array reply survives too' );
	is( scalar @$list, 200,     'with every entry' );
	is( $list->[199]{id}, 200, 'and the last one is intact' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a malformed request is refused' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	# Speak the transport by hand, so the test can send what the
	# client would never send
	my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $path,
	) or die "connect: $!";
	my $imsg = Fugu::Imsg->new( fh => $sock );

	# reply($data, $type): send one raw frame and read the answer
	my $seq = 100;
	my $reply = sub ( $data, $type = Fugu::Control::TYPE_REQUEST() ) {
		my $id = $seq++;
		$imsg->send( type => $type, peerid => $id, data => $data )
		    or return;
		my $frame = $imsg->recv( timeout => 5 ) or return;
		return $frame;
	};

	my $frame = $reply->('this is not json');
	is( $frame->{type}, Fugu::Control::TYPE_ERROR(),
		'a payload that is not JSON gives an error frame' );
	like( $frame->{data}, qr/not a JSON object/, 'and says so' );

	$frame = $reply->('[1,2,3]');
	like( $frame->{data}, qr/not a JSON object/,
		'a JSON array is not a request either' );

	$frame = $reply->('{"args":{}}');
	like( $frame->{data}, qr/names no command/, 'a request needs a command' );

	$frame = $reply->( '{"command":"ping"}', 99 );
	like( $frame->{data}, qr/not a control request/,
		'a frame of the wrong type is refused' );

	# The peerid comes back, so a client can tell which request an
	# error answers
	is( $frame->{peerid}, $seq - 1, 'the error carries the peerid' );

	# After all of that, the server still answers
	$imsg->send(
		type   => Fugu::Control::TYPE_REQUEST(),
		peerid => 7,
		data   => '{"command":"ping"}',
	);
	my $good = $imsg->recv( timeout => 5 );
	is( $good->{type}, Fugu::Control::TYPE_REPLY(),
		'a good request after bad ones still works' );

	$imsg->close;
	stop_server( $pid, $path );
};

subtest 'an oversized frame does not reach a handler' => sub {
	my $called = 0;
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM,
		Peer => $path,
	) or die "connect: $!";
	my $imsg = Fugu::Imsg->new( fh => $sock );

	# The framing refuses the payload before it reaches the wire
	is( $imsg->send( type => 1, data => 'x' x 65536 ),
		undef, 'an oversized payload is not sent' );
	ok( !$imsg->is_dead, 'and the refusal does not kill the connection' );

	# A hand-built header that claims more than the format allows
	# poisons the reader, which is the framing contract. The server
	# drops that connection and stays up.
	syswrite $sock, pack( 'L4', 1, 0x7fffffff, 1, $$ );
	sleep 0.5;
	$imsg->close;

	my $client = Fugu::Control::Client->new( path => $path );
	is_deeply( $client->request('ping'), { pong => 1 },
		'the server survived the bad frame' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'an absent socket is not a refusal' => sub {
	my $client =
	    Fugu::Control::Client->new( path => "$dir/never-made.sock" );

	is( $client->request('ping'), undef, 'the request fails' );
	ok( $client->socket_absent, 'and the client says the daemon is absent' );
	like( $client->error, qr/never-made\.sock/, 'the reason names the path' );
};

# A socket inside a directory the caller may not search looks absent
# to a test for the file. It is not: the daemon is there and running.
# An operator told "not running" about a running daemon looks in the
# wrong place.
subtest 'a socket behind a closed directory is a permission problem' => sub {
	plan skip_all => 'the test runs as root, which searches any directory'
	    if $> == 0;

	my $closed = "$dir/closed";
	mkdir $closed or die "mkdir: $!";
	my $path = "$closed/control.sock";

	my $control = Fugu::Control->new( path => $path );
	$control->register( ping => sub ($) { { pong => 1 } } );
	ok( $control->listen( loop => Fugu::EventLoop->new ),
		'the server bound inside the directory' );

	chmod 0000, $closed or die "chmod: $!";

	my $client = Fugu::Control::Client->new( path => $path );
	is( $client->request('ping'), undef, 'the request fails' );
	ok( !$client->socket_absent,
		'and the client does not call the daemon absent' );
	like( $client->error, qr/Permission denied/,
		'the reason is the permission' );

	chmod 0700, $closed;
	$control->shutdown;
	rmdir $closed;
};

subtest 'a listen refuses to take a live socket' => sub {
	my ( $path, $pid ) = start_server(
		sub ($control) {
			$control->register( ping => sub ($) { { pong => 1 } } );
		} );

	my $second = Fugu::Control->new( path => $path );
	is( $second->listen( loop => Fugu::EventLoop->new ),
		undef, 'a second server does not bind' );
	like( $second->error, qr/Another process serves/,
		'and it says why' );

	# The first server is untouched
	my $client = Fugu::Control::Client->new( path => $path );
	is_deeply( $client->request('ping'), { pong => 1 },
		'the first server still answers' );

	$client->disconnect;
	stop_server( $pid, $path );
};

subtest 'a stale socket is replaced' => sub {
	my $path = "$dir/stale.sock";

	# A socket file that nothing is behind, as a crashed daemon
	# leaves. bind(2) fails on an existing name, and a daemon that
	# will not start after a crash needs a hand at every reboot.
	my $dead = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $path,
		Listen => 1,
	) or die "bind: $!";
	close $dead;
	ok( -e $path, 'the stale socket is on disk' );

	my $control = Fugu::Control->new( path => $path );
	ok( $control->listen( loop => Fugu::EventLoop->new ),
		'the server takes the name' )
	    or diag( $control->error // 'no error recorded' );

	$control->shutdown;
	ok( !-e $path, 'and shutdown removes the socket' );
};

subtest 'the socket is 0600 from birth' => sub {
	my $path = "$dir/mode.sock";

	my $control = Fugu::Control->new( path => $path );
	ok( $control->listen( loop => Fugu::EventLoop->new ),
		'the server bound' );

	my $mode = ( stat $path )[2] & 07777;
	is( $mode, 0600, 'no other user can connect' );

	$control->shutdown;
};

done_testing();
