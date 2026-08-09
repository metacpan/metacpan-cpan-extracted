#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use EreshkigalTest qw( test_dir socket_path_ok wait_for_socket wait_for_gone wait_for_exit spawn_kur read_ban_csv );
use IO::Socket::UNIX ();

use Ereshkigal::Client;

if ( $^O eq 'MSWin32' ) {
	plan skip_all => 'unix sockets and fork required';
}

my $dir = test_dir();
if ( !socket_path_ok($dir) ) {
	plan skip_all => 'temp dir path too long for a unix socket... set TMPDIR to something shorter';
}

my %spawn_opts = (
	'name'  => 'testy',
	'run'   => $dir . '/run',
	'cache' => $dir . '/cache',
	'args'  => [ '--ports', '22', '--protocols', 'tcp' ],
);

my $socket = $dir . '/run/kur/testy.sock';
my $pid    = spawn_kur(%spawn_opts);

ok( wait_for_socket($socket), 'kur socket came up' ) || BAIL_OUT('kur never came up');

is( ( stat($socket) )[2] & 07777, 0600, 'kur socket mode is 0600' );

open( my $pid_fh, '<', $dir . '/run/kur/testy.pid' ) || die($!);
my $pid_file_content = <$pid_fh>;
close($pid_fh);
is( $pid_file_content, $pid, 'pid file holds the pid' );

my $client = Ereshkigal::Client->new( 'socket' => $socket, 'timeout' => 10 );

#
# JSONUnix sanity via the built-in ping
#

is( $client->call_ok('ping')->{pong}, 1, 'ping answers' );

#
# the full ban round trip through the real server
#

my $result = $client->call_ok( 'ban', { 'ips' => [ '1.2.3.4', '5.6.7.8' ] } );
is( $result->{ips}{'1.2.3.4'}{status}, 'ok', 'ban ok' );

$result = $client->call_ok('banned');
is_deeply( [ sort( @{ $result->{banned} } ) ], [ '1.2.3.4', '5.6.7.8' ], 'banned lists both' );

$result = $client->call_ok( 'unban', { 'ip' => '1.2.3.4' } );
is( $result->{was_banned}, 1, 'unban of a present IP' );
$result = $client->call_ok( 'unban', { 'ip' => '1.2.3.4' } );
is( $result->{was_banned}, 0, 'unban of an absent IP' );

$result = $client->call_ok('status');
is( $result->{name},         'testy', 'status name' );
is( $result->{banned_count}, 1,       'status banned_count' );
is( $result->{stats}{bans},  2,       'status stats' );

$result = $client->call_ok('flush');
is( $result->{flushed}, 1, 'flush' );
is_deeply( $client->call_ok('banned')->{banned}, [], 'banned empty after flush' );

$result = $client->call_ok('re_init');
is( $result->{re_init}, 1, 're_init' );

#
# the state CSV and the checkpoint command
#

my $state_csv = $dir . '/cache/kur.testy.csv';
ok( -f $state_csv, 'the state CSV exists' );

$result = $client->call_ok( 'ban', { 'ips' => ['6.6.6.6'] } );
$result = $client->call_ok('checkpoint');
is( $result->{checkpointed}, 1, 'checkpoint command works' );
is( $result->{bans},         1, 'checkpoint reports the ban count' );
$result = $client->call_ok('status');
ok( $result->{last_checkpoint} > 0, 'status reports last_checkpoint' );
$result = $client->call_ok( 'unban', { 'ip' => '6.6.6.6' } );

#
# ban time... a 1 second ban expires via the sweeper, a 0 one does not
#

$result = $client->call_ok( 'ban', { 'ips' => ['7.7.7.7'], 'ban_time' => 1 } );
is( $result->{ips}{'7.7.7.7'}{status}, 'ok', 'timed ban ok' );
$result = $client->call_ok( 'ban', { 'ips' => ['8.8.8.8'], 'ban_time' => 0 } );
is( $result->{ips}{'8.8.8.8'}{status}, 'ok', 'permanent ban ok' );

$result = $client->call_ok('banned');
ok( $result->{expires}{'7.7.7.7'} > 0, 'timed ban has an expiry' );
is( $result->{expires}{'8.8.8.8'}, 0, 'permanent ban has no expiry' );

my $ban_expired = 0;
my $waited      = 0;
while ( $waited < 10 ) {
	$result = $client->call_ok('banned');
	if ( !grep { $_ eq '7.7.7.7' } @{ $result->{banned} } ) {
		$ban_expired = 1;
		last;
	}
	select( undef, undef, undef, 0.5 );
	$waited += 0.5;
}
ok( $ban_expired, 'timed ban expired' );
ok( ( grep { $_ eq '8.8.8.8' } @{ $result->{banned} } ), 'permanent ban still present' );
$result = $client->call_ok('status');
is( $result->{stats}{expired}, 1, 'expired counted in stats' );

#
# bad input does not kill the server
#

my $response = $client->call('nosuchcommand');
is( $response->{status}, 'error', 'unknown command errors' );
like( $response->{error}, qr/unknown command/, 'unknown command error message' );

my $raw = IO::Socket::UNIX->new(
	'Type' => IO::Socket::UNIX::SOCK_STREAM(),
	'Peer' => $socket,
) || die($!);
print $raw "this is not json\n";
my $raw_line = <$raw>;
close($raw);
like( $raw_line, qr/invalid JSON/, 'malformed JSON gets an error response' );

is( $client->call_ok('ping')->{pong}, 1, 'server still alive after the bad input' );

#
# a second kur with the same name refuses to clobber the live socket
#

my $second_pid  = spawn_kur( %spawn_opts, 'quiet' => 1 );
my $second_exit = wait_for_exit($second_pid);
ok( defined($second_exit) && $second_exit != 0, 'second kur with the same name exits nonzero' );

is( $client->call_ok('ping')->{pong}, 1, 'first kur survived the second one' );

#
# timed bans survive a kill and respawn via the persisted state
#

$result = $client->call_ok( 'ban', { 'ips' => ['9.9.9.1'], 'ban_time' => 3600 } );
is( $result->{ips}{'9.9.9.1'}{status}, 'ok', 'long timed ban ok' );

kill( 'KILL', $pid );
wait_for_exit($pid);
$pid = spawn_kur(%spawn_opts);

# the SIGKILLed kur left a stale socket file behind, so poll till the
# respawned one actually answers
my $alive = 0;
$waited = 0;
while ( $waited < 10 ) {
	my $pong = eval { $client->call_ok('ping'); };
	if ( defined($pong) && $pong->{pong} ) {
		$alive = 1;
		last;
	}
	select( undef, undef, undef, 0.5 );
	$waited += 0.5;
}
ok( $alive, 'kur back up after being killed' );

$result = $client->call_ok('banned');
ok( ( grep { $_ eq '9.9.9.1' } @{ $result->{banned} } ), 'timed ban still banned after the restart' );
ok( $result->{expires}{'9.9.9.1'} > time, 'and still tracked with it\'s expiry' );
ok( ( grep { $_ eq '8.8.8.8' } @{ $result->{banned} } ), 'permanent ban still banned after the restart' );

#
# stop
#

my $stop_time = time;
$result = $client->call_ok('stop');
is( $result->{stopping}, 1, 'stop response' );
ok( wait_for_gone($socket),                       'socket removed after stop' );
ok( wait_for_gone( $dir . '/run/kur/testy.pid' ), 'pid file removed after stop' );
is( wait_for_exit($pid), 0, 'kur exited 0' );

# stop checkpoints right before teardown
my $rows = read_ban_csv($state_csv);
ok( $rows->{'8.8.8.8'}{time} >= $stop_time, 'stop left a freshly written state CSV behind' );

done_testing;
