#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use EreshkigalTest   qw( test_dir socket_path_ok mock_server );
use IO::Socket::UNIX ();

use Ereshkigal::Client;

my $dir = test_dir();
if ( !socket_path_ok($dir) ) {
	plan skip_all => 'temp dir path too long for a unix socket... set TMPDIR to something shorter';
}

my $socket = $dir . '/mock.sock';
mock_server(
	$socket,
	{
		'ping' => { 'status' => 'ok', 'result' => { 'pong' => 1 } },
		'echo' => sub {
			my ($request) = @_;
			return { 'status' => 'ok', 'result' => { 'args' => $request->{args} } };
		},
		'bad'      => { 'status' => 'error', 'error' => 'nope' },
		'garbage'  => 'this is not json',
		'arrayish' => sub { return [ 1, 2, 3 ]; },
		'sleepy'   => { '__no_reply__' => 1 },
	}
);

#
# new
#

throws_ok { Ereshkigal::Client->new } qr/No socket specified/, 'new dies with out a socket';

my $client = Ereshkigal::Client->new( 'socket' => $socket );
is( $client->{timeout},                                                        30, 'timeout defaults to 30' );
is( Ereshkigal::Client->new( 'socket' => $socket, 'timeout' => 5 )->{timeout}, 5,  'timeout override honored' );

#
# call / call_ok
#

my $response = $client->call('ping');
is( $response->{status},       'ok', 'call returns the response hash' );
is( $response->{result}{pong}, 1,    'call result decoded' );

$response = $client->call( 'echo', { 'foo' => 'bar' } );
is_deeply( $response->{result}{args}, { 'foo' => 'bar' }, 'args sent through verbatim' );

is_deeply( $client->call_ok('ping'), { 'pong' => 1 }, 'call_ok returns just the result' );

eval { $client->call_ok('bad'); };
is( $@, "nope\n", 'call_ok dies with the error text and a trailing newline' );

$response = $client->call('nosuchcommand');
is( $response->{status}, 'error', 'an error response comes back as a plain hash from call' );

#
# failure modes
#

throws_ok { Ereshkigal::Client->new( 'socket' => $dir . '/nothere.sock' )->call('ping') }
qr/Failed to connect/, 'connect to a nonexistent socket dies';

throws_ok { $client->call('garbage') } qr/./, 'undecodable response dies';

throws_ok { $client->call('arrayish') } qr/not a JSON object/, 'non-object JSON response dies';

throws_ok { $client->call(undef) } qr/No command specified/, 'undef command dies';

#
# the transparent auth challenge retry
#

my $auth_socket = $dir . '/auth.sock';
my $cookie_dir  = $dir . '/cookies';
mkdir($cookie_dir) || die($!);
my $cookie = 'deadbeefcafe1234';
mock_server(
	$auth_socket,
	{
		'auth_start' => sub {
			return { 'status' => 'ok', 'result' => { 'cookie' => $cookie, 'temp_dir' => $cookie_dir } };
		},
		'auth_verify' => sub {
			my ( $request, $state ) = @_;
			my $path = $request->{args}{path};
			if ( !defined($path) || !-f $path ) {
				return { 'status' => 'error', 'error' => 'no such cookie file' };
			}
			open( my $fh, '<', $path ) || die($!);
			my $got = <$fh>;
			close($fh);
			if ( $got ne $cookie ) {
				return { 'status' => 'error', 'error' => 'cookie mismatch' };
			}
			$state->{authed} = 1;
			return { 'status' => 'ok', 'result' => { 'uid' => $>, 'username' => 'testuser' } };
		},
		'secured' => sub {
			my ( $request, $state ) = @_;
			if ( !$state->{authed} ) {
				return {
					'status' => 'error',
					'error'  => 'authentication required: call auth_start then auth_verify first'
				};
			}
			return { 'status' => 'ok', 'result' => { 'secret' => 42 } };
		},
	}
);

my $auth_client = Ereshkigal::Client->new( 'socket' => $auth_socket );
is_deeply(
	$auth_client->call_ok('secured'),
	{ 'secret' => 42 },
	'the challenge is completed transparently and the command resent'
);
opendir( my $cookie_dh, $cookie_dir ) || die($!);
my @leftover = grep { $_ ne '.' && $_ ne '..' } readdir($cookie_dh);
closedir($cookie_dh);
is_deeply( \@leftover, [], 'the cookie file was cleaned up' );

# a server rejecting the challenge surfaces as a die rather than a retry loop
my $bad_socket = $dir . '/bad-auth.sock';
mock_server(
	$bad_socket,
	{
		'auth_start' => sub {
			return { 'status' => 'ok', 'result' => { 'cookie' => 'right', 'temp_dir' => $cookie_dir } };
		},
		'auth_verify' => sub {
			return { 'status' => 'error', 'error' => 'cookie mismatch' };
		},
		'secured' => sub {
			return {
				'status' => 'error',
				'error'  => 'authentication required: call auth_start then auth_verify first'
			};
		},
	}
);
throws_ok { Ereshkigal::Client->new( 'socket' => $bad_socket )->call('secured') }
qr/auth_verify failed.*cookie mismatch/, 'a rejected challenge dies';
opendir( $cookie_dh, $cookie_dir ) || die($!);
@leftover = grep { $_ ne '.' && $_ ne '..' } readdir($cookie_dh);
closedir($cookie_dh);
is_deeply( \@leftover, [], 'the cookie file was cleaned up after the rejection too' );

#
# call_many
#

throws_ok { Ereshkigal::Client->call_many( 'command' => 'ping' ) } qr/sockets must be a hash/,
	'call_many dies with out sockets';
throws_ok { Ereshkigal::Client->call_many( 'sockets' => {} ) } qr/No command specified/,
	'call_many dies with out a command';

is_deeply( Ereshkigal::Client->call_many( 'sockets' => {}, 'command' => 'ping' ),
	{}, 'an empty sockets hash returns an empty hash' );

my $cm_a_socket = $dir . '/cm-a.sock';
my $cm_b_socket = $dir . '/cm-b.sock';
mock_server(
	$cm_a_socket,
	{
		'ping'  => { 'status' => 'ok', 'result' => { 'pong' => 'a' } },
		'mixed' => { 'status' => 'ok', 'result' => { 'fine' => 1 } },
		'echo'  => sub {
			my ($request) = @_;
			return {
				'status' => 'ok',
				'result' => { 'args' => $request->{args}, 'has_args' => exists( $request->{args} ) ? 1 : 0 }
			};
		},
		'garbage'   => 'this is not json',
		'slowcheck' => { 'status' => 'ok', 'result' => { 'quick' => 1 } },
	}
);
mock_server(
	$cm_b_socket,
	{
		'ping'  => { 'status' => 'ok',    'result' => { 'pong' => 'b' } },
		'mixed' => { 'status' => 'error', 'error'  => 'nope b' },
	}
);

my $per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'a' => $cm_a_socket, 'b' => $cm_b_socket },
	'command' => 'ping',
);
is_deeply(
	$per_name,
	{ 'a' => { 'result' => { 'pong' => 'a' } }, 'b' => { 'result' => { 'pong' => 'b' } } },
	'call_many returns per name results'
);

$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'a' => $cm_a_socket, 'b' => $cm_b_socket },
	'command' => 'mixed',
);
is_deeply( $per_name->{a}, { 'result' => { 'fine' => 1 } }, 'an error on one socket does not disturb the others' );
is_deeply( $per_name->{b}, { 'error'  => 'nope b' },        'an error status response lands as that name\'s error' );

$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'a' => $cm_a_socket, 'ghost' => $dir . '/nothere.sock' },
	'command' => 'ping',
);
is_deeply( $per_name->{a}, { 'result' => { 'pong' => 'a' } }, 'the live socket still answered' );
like( $per_name->{ghost}{error}, qr/Failed to connect/, 'a nonexistent socket is a connect error for just that name' );

$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'a' => $cm_a_socket, 'b' => $cm_b_socket },
	'command' => 'garbage',
);
like( $per_name->{a}{error}, qr/Undecodable response/, 'an undecodable response is an error for that name' );
is( $per_name->{b}{error}, 'unknown command: garbage', 'the other socket still got it\'s answer' );

$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'a' => $cm_a_socket },
	'command' => 'echo',
	'args'    => { 'foo' => 'bar' },
);
is_deeply( $per_name->{a}{result}{args}, { 'foo' => 'bar' }, 'call_many passes args through verbatim' );

$per_name = Ereshkigal::Client->call_many( 'sockets' => { 'a' => $cm_a_socket }, 'command' => 'echo' );
is( $per_name->{a}{result}{has_args}, 0, 'no args means no args key on the wire' );

# a stalled socket must not keep an answered one from returning... this is
# the concurrency assertion that matters
my $cm_stall_socket = $dir . '/cm-stall.sock';
mock_server( $cm_stall_socket, { 'slowcheck' => { '__no_reply__' => 1 }, 'ping' => { '__no_reply__' => 1 } } );
$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'ok' => $cm_a_socket, 'stall' => $cm_stall_socket },
	'command' => 'slowcheck',
	'timeout' => 1,
);
is_deeply( $per_name->{ok}, { 'result' => { 'quick' => 1 } }, 'the answering socket returned it\'s result' );
like( $per_name->{stall}{error}, qr/timed out/, 'the stalled one is a timeout error' );

# the deadline is shared... two stalled sockets take about one timeout,
# not the sum, with generous slop as the point is not-the-sum rather than
# precision timing
my $cm_stall2_socket = $dir . '/cm-stall2.sock';
mock_server( $cm_stall2_socket, { 'ping' => { '__no_reply__' => 1 } } );
my $started = time;
$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'one' => $cm_stall_socket, 'two' => $cm_stall2_socket },
	'command' => 'ping',
	'timeout' => 2,
);
my $elapsed = time - $started;
like( $per_name->{one}{error}, qr/timed out/, 'the first stalled socket timed out' );
like( $per_name->{two}{error}, qr/timed out/, 'the second stalled socket timed out' );
cmp_ok( $elapsed, '<=', 3, 'the deadline is shared... about one timeout, not the sum' );

# a listener that never accepts can not wedge the fan out... what a connect
# to one whose accept queue has filled does is platform specific, Linux
# blocking where the BSDs refuse at once, so this asserts the part that must
# hold either way... every name is answered and the whole thing stays inside
# the deadline, which is what the bounded connects buy
my $deaf_socket = $dir . '/cm-deaf.sock';
my $deaf        = IO::Socket::UNIX->new(
	'Type'   => IO::Socket::UNIX::SOCK_STREAM(),
	'Local'  => $deaf_socket,
	'Listen' => 1,
) || die($!);

# fill the accept queue... each filler is bounded too, as the one that finds
# the queue full is the one that would otherwise hang this test
my @backlog;
foreach ( 1 .. 20 ) {
	my $filler;
	eval {
		local $SIG{ALRM} = sub { die("blocked\n"); };
		alarm(1);
		$filler = IO::Socket::UNIX->new(
			'Type' => IO::Socket::UNIX::SOCK_STREAM(),
			'Peer' => $deaf_socket,
		);
		alarm(0);
		1;
	} or do {
		alarm(0);
	};
	last if !$filler;
	push( @backlog, $filler );
} ## end foreach ( 1 .. 20 )

$started  = time;
$per_name = Ereshkigal::Client->call_many(
	'sockets' => { 'deaf' => $deaf_socket, 'ok' => $cm_a_socket },
	'command' => 'slowcheck',
	'timeout' => 4,
);
$elapsed = time - $started;
cmp_ok( $elapsed, '<=', 8, 'a listener that never accepts does not hang the fan out' );
ok( defined( $per_name->{deaf} ),        'the deaf socket still got an answer' );
ok( defined( $per_name->{deaf}{error} ), 'and that answer is an error' );
is_deeply(
	$per_name->{ok},
	{ 'result' => { 'quick' => 1 } },
	'the healthy socket is not starved of it\'s share of the deadline'
);

foreach my $filler (@backlog) {
	close($filler);
}
close($deaf);
unlink($deaf_socket);

# this one last as the mock will be stuck sleeping afterwards
throws_ok { Ereshkigal::Client->new( 'socket' => $socket, 'timeout' => 1 )->call('sleepy') }
qr/timed out/, 'times out when the server never replies';

done_testing;
