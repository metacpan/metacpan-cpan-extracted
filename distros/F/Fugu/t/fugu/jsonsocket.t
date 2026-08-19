#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for Fugu::JSONSocket against a fake peer on a local
# socket.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp  qw(tempdir);
use IO::Socket::UNIX;
use JSON::PP;
use POSIX       qw(_exit);
use Socket      qw(SOCK_STREAM);
use Time::HiRes qw(time sleep);

use_ok('Fugu::JSONSocket');

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# start_peer($behavior):
#	Fork a peer on a fresh socket path. The listener exists before
#	the fork, so the client can connect at once.
#	$behavior->($socket) runs once for the accepted connection.
#	The function returns ($path, $pid).
sub start_peer ($behavior)
{
	my $path = sprintf '%s/peer%d.sock', $dir, $n++;

	my $listener = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $path,
		Listen => 5,
	) or die "listen $path: $!";

	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		local $SIG{ALRM} = sub { _exit(1) };
		alarm 30;
		my $sock = $listener->accept;
		$behavior->($sock) if $sock;
		_exit(0);
	}
	close $listener;

	return ( $path, $pid );
}

# read_line($sock): one line from the peer side, without the newline
sub read_line ($sock)
{
	my $line = <$sock>;
	return unless defined $line;
	chomp $line;
	return $line;
}

subtest 'request and reply' => sub {
	my ( $path, $pid ) = start_peer(
		sub ($sock) {
			while ( defined( my $line = read_line($sock) ) ) {
				my $request = decode_json($line);
				print {$sock} encode_json(
					{ echo => $request->{execute} } ), "\n";
			}
			return;
		} );

	my $client = Fugu::JSONSocket->new( path => $path );
	ok( !$client->is_connected, 'not connected yet' );
	ok( $client->exists,        'the socket file is there' );
	ok( $client->connect,       'connect succeeds' );
	ok( $client->is_connected,  'and the client says so' );
	ok( $client->connect,       'a second connect is a no-op success' );

	is_deeply(
		$client->request( { execute => 'query-status' } ),
		{ echo => 'query-status' },
		'the reply decodes'
	);
	is_deeply(
		$client->request( { execute => 'ping' } ),
		{ echo => 'ping' },
		'a second request on the same connection'
	);

	$client->disconnect;
	ok( !$client->is_connected, 'disconnect closes it' );
	waitpid $pid, 0;
};

subtest 'a greeting is read at connect when asked' => sub {
	my ( $path, $pid ) = start_peer(
		sub ($sock) {
			print {$sock} encode_json( { QMP => { version => 1 } } ),
			    "\n";
			while ( defined( my $line = read_line($sock) ) ) {
				print {$sock} encode_json( { return => {} } ), "\n";
			}
			return;
		} );

	my $client =
	    Fugu::JSONSocket->new( path => $path, greeting => 1 );
	ok( $client->connect, 'connect reads the greeting' );
	is_deeply(
		$client->greeting,
		{ QMP => { version => 1 } },
		'and it is available'
	);

	# The greeting is not mistaken for the reply to the first
	# command
	is_deeply( $client->request( { execute => 'x' } ),
		{ return => {} }, 'the first reply is the command reply' );

	$client->disconnect;
	waitpid $pid, 0;
};

subtest 'a protocol with no greeting skips it' => sub {
	my ( $path, $pid ) = start_peer(
		sub ($sock) {
			while ( defined( my $line = read_line($sock) ) ) {
				print {$sock} encode_json( { return => 'ok' } ),
				    "\n";
			}
			return;
		} );

	my $client = Fugu::JSONSocket->new( path => $path );
	ok( $client->connect, 'connect does not wait for a greeting' );
	is( $client->greeting, undef, 'and there is none' );
	is_deeply( $client->request( { execute => 'ping' } ),
		{ return => 'ok' }, 'the first reply belongs to the command' );

	$client->disconnect;
	waitpid $pid, 0;
};

# A reply can share a segment with the one after it. A reader that
# threw away the remainder would lose the second reply.
subtest 'buffered remainder' => sub {
	my ( $path, $pid ) = start_peer(
		sub ($sock) {
			read_line($sock);

			# Both replies in one write
			print {$sock} encode_json( { n => 1 } ) . "\n"
			    . encode_json( { n => 2 } ) . "\n";
			sleep 1;
			return;
		} );

	my $client = Fugu::JSONSocket->new( path => $path );
	$client->connect;

	is_deeply( $client->request( { execute => 'both' } ),
		{ n => 1 }, 'the first reply' );
	is_deeply( $client->read_message, { n => 2 },
		'and the second, from the buffer' );

	$client->disconnect;
	waitpid $pid, 0;
};

subtest 'a read has a wall-clock deadline' => sub {
	my ( $path, $pid ) = start_peer(
		sub ($sock) {

			# Read the request and never answer
			read_line($sock);
			sleep 10;
			return;
		} );

	my $client = Fugu::JSONSocket->new( path => $path, timeout => 1 );
	$client->connect;

	my $start = time;
	is( $client->request( { execute => 'silence' } ),
		undef, 'a peer that stops answering does not hang the caller' );
	my $elapsed = time - $start;

	ok( $elapsed < 8, 'the read returned near the deadline' )
	    or diag("took ${elapsed}s");
	like( $client->error, qr/timeout/, 'and the reason is the timeout' );

	$client->disconnect;
	kill 'TERM', $pid;
	waitpid $pid, 0;
};

subtest 'an end of file is reported, not a hang' => sub {

	# The peer holds the listener while it drops the connection, so
	# the client always gets as far as a connected socket
	my ( $path, $pid ) = start_peer(
		sub ($sock) {
			close $sock;
			sleep 2;
			return;
		} );

	my $client = Fugu::JSONSocket->new( path => $path, timeout => 5 );
	ok( $client->connect, 'the client connected' );

	is( $client->request( { execute => 'x' } ),
		undef, 'a closed peer gives undef' );

	# The write can fail with EPIPE, or it can land in the socket
	# buffer and the read then sees the end of the stream. Both are
	# the peer going away, and either wording is correct.
	like( $client->error, qr/closed the connection|write/,
		'and the reason names the close' )
	    or diag( 'error was: ' . ( $client->error // 'undef' ) );
	ok( !$client->is_connected, 'the client dropped the socket' );

	kill 'TERM', $pid;
	waitpid $pid, 0;
};

subtest 'invalid JSON is an error, not a die' => sub {
	my ( $path, $pid ) = start_peer(
		sub ($sock) {
			read_line($sock);
			print {$sock} "{not json\n";
			sleep 1;
			return;
		} );

	my $client = Fugu::JSONSocket->new( path => $path, timeout => 5 );
	$client->connect;

	is( $client->request( { execute => 'x' } ), undef, 'the reply is undef' );
	like( $client->error, qr/invalid JSON/, 'and the reason says why' );

	$client->disconnect;
	waitpid $pid, 0;
};

subtest 'a missing socket fails cleanly' => sub {
	my $client =
	    Fugu::JSONSocket->new( path => "$dir/never-created.sock" );

	ok( !$client->exists, 'the socket file is absent' );
	is( $client->connect, undef, 'connect returns undef' );
	like( $client->error, qr/never-created\.sock/, 'and names the socket' );

	is( $client->request( { execute => 'x' } ),
		undef, 'a request without a connection is undef' );
	like( $client->error, qr/not connected/, 'and says so' );
};

subtest 'a missing path is a programming error' => sub {
	ok( !eval { Fugu::JSONSocket->new; 1 }, 'new needs a path' );
	ok( !eval { Fugu::JSONSocket->new( path => '' ); 1 },
		'and a real one' );
};

done_testing();
