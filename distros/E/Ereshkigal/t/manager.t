#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use EreshkigalTest qw( test_dir socket_path_ok wait_for_socket wait_for_gone wait_for_exit spawn_manager write_config );

use Ereshkigal::Client;

if ( $^O eq 'MSWin32' ) {
	plan skip_all => 'unix sockets and fork required';
}

my $dir = test_dir();
if ( !socket_path_ok($dir) ) {
	plan skip_all => 'temp dir path too long for a unix socket... set TMPDIR to something shorter';
}

my $config      = write_config($dir);
my $manager_pid = spawn_manager($config);

my $manager_socket = $dir . '/run/socket';
ok( wait_for_socket($manager_socket),               'manager socket came up' ) || BAIL_OUT('manager never came up');
ok( wait_for_socket( $dir . '/run/kur/sshd.sock' ), 'sshd kur socket came up' );
ok( wait_for_socket( $dir . '/run/kur/smtp.sock' ), 'smtp kur socket came up' );

is( ( stat($manager_socket) )[2] & 07777, 0660,                      'manager socket mode is 0660' );
is( ( stat($manager_socket) )[5],         ( split( /\s+/, $( ) )[0], 'manager socket group is the configured one' );

my $client = Ereshkigal::Client->new( 'socket' => $manager_socket, 'timeout' => 15 );

#
# status
#

my $status = $client->call_ok('status');
is( $status->{kurs}{sshd}{running},  1, 'status shows sshd running' );
is( $status->{kurs}{smtp}{running},  1, 'status shows smtp running' );
is( $status->{kurs}{sshd}{restarts}, 0, 'sshd restarts 0' );
ok( defined( $status->{kurs}{sshd}{pid} ), 'sshd has a pid' );

#
# ban
#

my $result = $client->call_ok( 'ban', { 'ips' => ['1.2.3.4'] } );
is( $result->{kurs}{sshd}{ips}{'1.2.3.4'}{status}, 'ok', 'ban applied on sshd' );
is( $result->{kurs}{smtp}{ips}{'1.2.3.4'}{status}, 'ok', 'ban applied on smtp' );

$result = $client->call_ok( 'ban', { 'ips' => ['9.9.9.9'], 'kur' => 'sshd' } );
is( $result->{kurs}{sshd}{ips}{'9.9.9.9'}{status}, 'ok', 'targeted ban applied on sshd' );
ok( !defined( $result->{kurs}{smtp} ), 'targeted ban did not touch smtp' );

my $response = $client->call( 'ban', { 'ips' => ['1.1.1.1'], 'kur' => 'nope' } );
is( $response->{status}, 'error', 'ban to an unknown kur errors' );
like( $response->{error}, qr/No such kur instance/, 'unknown kur error message' );

$result = $client->call_ok( 'ban', { 'ips' => [ 'not-an-ip', '2.2.2.2' ] } );
is( $result->{rejected}{'not-an-ip'}{status}, 'error', 'invalid IP rejected by the manager' );
like( $result->{rejected}{'not-an-ip'}{error}, qr/does not appear to be an IPv4 or IPv6 IP/, 'rejected error message' );
ok( !defined( $result->{kurs}{sshd}{ips}{'not-an-ip'} ), 'rejected IP not fanned out to the kurs' );
is( $result->{kurs}{sshd}{ips}{'2.2.2.2'}{status}, 'ok', 'valid IP in the same request applied' );
ok( !defined( $result->{rejected}{'2.2.2.2'} ), 'valid IP not in rejected' );

$response = $client->call( 'ban', { 'ips' => [ 'not-an-ip', '010.0.0.1' ] } );
is( $response->{status}, 'error', 'ban with nothing but invalid IPs errors' );

# variant spellings normalize to one canonical form before the fan out
$result = $client->call_ok( 'ban', { 'ips' => [ '2001:0DB8:0000:0000:0000:0000:0000:0001', '2001:db8:0:0::1' ] } );
is( $result->{kurs}{sshd}{ips}{'2001:db8::1'}{status}, 'ok', 'IPv6 fanned out in canonical form' );
ok( !defined( $result->{kurs}{sshd}{ips}{'2001:0DB8:0000:0000:0000:0000:0000:0001'} ),
	'long form not fanned out as its own IP' );
$result = $client->call_ok( 'unban', { 'ip' => '2001:DB8::1' } );
is( $result->{kurs}{sshd}{was_banned}, 1, 'unban via a variant spelling finds the ban' );

$response = $client->call( 'unban', { 'ip' => 'not-an-ip' } );
is( $response->{status}, 'error', 'unban of an invalid IP errors' );

$result = $client->call_ok( 'ban', { 'ips' => ['5.5.5.5'], 'ban_time' => 3600, 'kur' => 'smtp' } );
is( $result->{kurs}{smtp}{ips}{'5.5.5.5'}{status}, 'ok', 'ban with a ban_time ok' );
$result = $client->call_ok('banned');
ok( $result->{kurs}{smtp}{expires}{'5.5.5.5'} > time, 'ban_time forwarded through the manager' );

#
# banned
#

$result = $client->call_ok('banned');
ok( ( grep { $_ eq '9.9.9.9' } @{ $result->{kurs}{sshd}{banned} } ),  '9.9.9.9 banned on sshd' );
ok( !( grep { $_ eq '9.9.9.9' } @{ $result->{kurs}{smtp}{banned} } ), '9.9.9.9 not banned on smtp' );

# the aggregation matches what the kur socket reports directly
my $sshd_client = Ereshkigal::Client->new( 'socket' => $dir . '/run/kur/sshd.sock', 'timeout' => 15 );
is_deeply(
	[ sort( @{ $sshd_client->call_ok('banned')->{banned} } ) ],
	[ sort( @{ $result->{kurs}{sshd}{banned} } ) ],
	'manager banned aggregation matches the kur socket'
);

# the manager rebuilds each row rather than passing it through, so every
# field the kur reports has to be carried over deliberately... the retry
# books are what the CLI help points people at, so they must survive
is_deeply(
	[ sort( keys( %{ $result->{kurs}{sshd} } ) ) ],
	[ sort( keys( %{ $sshd_client->call_ok('banned') } ) ) ],
	'the manager carries over every field the kur reports for banned'
);
ok( defined( $result->{kurs}{sshd}{unban_retries} ),      'banned carries unban_retries through the manager' );
ok( defined( $result->{kurs}{sshd}{cidr_unban_retries} ), 'and the CIDR retry book too' );

#
# unban
#

$result = $client->call_ok( 'unban', { 'ip' => '9.9.9.9' } );
is( $result->{kurs}{sshd}{was_banned}, 1, 'unban removed it from sshd' );
is( $result->{kurs}{smtp}{was_banned}, 0, 'unban reports it absent on smtp' );

$result = $client->call_ok( 'unban', { 'all' => 1 } );
is( $result->{kurs}{sshd}{flushed}, 1, 'unban all flushed sshd' );
is( $result->{kurs}{smtp}{flushed}, 1, 'unban all flushed smtp' );
$result = $client->call_ok('banned');
is_deeply( $result->{kurs}{sshd}{banned}, [], 'sshd empty after unban all' );
is_deeply( $result->{kurs}{smtp}{banned}, [], 'smtp empty after unban all' );

$response = $client->call('unban');
is( $response->{status}, 'error', 'unban with out args errors' );

#
# re_init against live kurs... the ban book is the authority, so what was
# banished before the rebuild is still banished after it
#

$client->call_ok( 'ban', { 'ips' => [ '7.7.7.7', '8.8.8.8' ] } );

$result = $client->call_ok('re_init');
is( $result->{kurs}{sshd}{re_init}, 1, 're_init reached sshd' );
is( $result->{kurs}{smtp}{re_init}, 1, 're_init reached smtp' );

$result = $client->call_ok('banned');
is_deeply(
	[ sort( @{ $result->{kurs}{sshd}{banned} } ) ],
	[ '7.7.7.7', '8.8.8.8' ],
	'the bans were rebuilt from the book'
);

# targeted at one kur, and at a gateway
$result = $client->call_ok( 're_init', { 'kur' => 'sshd' } );
is( $result->{kurs}{sshd}{re_init}, 1, 're_init targeted at one kur reached it' );
ok( !defined( $result->{kurs}{smtp} ), 'and left the other alone' );

$response = $client->call( 're_init', { 'kur' => 'nope' } );
is( $response->{status}, 'error', 're_init of an unknown kur errors' );

$client->call_ok( 'unban', { 'all' => 1 } );

#
# status_kur / status_all
#

$result = $client->call_ok( 'status_kur', { 'name' => 'sshd' } );
is( $result->{running},         1,       'status_kur running' );
is( $result->{status}{backend}, 'dummy', 'status_kur nested kur status' );
$response = $client->call( 'status_kur', { 'name' => 'nope' } );
is( $response->{status}, 'error', 'status_kur of an unknown kur errors' );

$result = $client->call_ok('status_all');
is( $result->{kurs}{sshd}{status}{backend}, 'dummy', 'status_all carries kur status blocks' );
is( $result->{kurs}{smtp}{status}{name},    'smtp',  'status_all smtp status block' );

#
# add_kur / remove_kur
#

$result = $client->call_ok( 'add_kur',
	{ 'name' => 'dns', 'opts' => { 'backend' => 'dummy', 'ports' => ['53'], 'protocols' => ['udp'] } } );
is( $result->{added}, 'dns', 'add_kur response' );
ok( wait_for_socket( $dir . '/run/kur/dns.sock' ), 'dns kur socket came up' );
$status = $client->call_ok('status');
is( $status->{kurs}{dns}{running}, 1, 'dns shows running' );
$result = $client->call_ok( 'ban', { 'ips' => ['4.4.4.4'], 'kur' => 'dns' } );
is( $result->{kurs}{dns}{ips}{'4.4.4.4'}{status}, 'ok', 'ban works on the added kur' );

$response = $client->call( 'add_kur', { 'name' => 'dns', 'opts' => { 'backend' => 'dummy' } } );
is( $response->{status}, 'error', 'duplicate add_kur errors' );
like( $response->{error}, qr/already exists/, 'duplicate add_kur error message' );

$response = $client->call( 'add_kur', { 'name' => 'bad.name', 'opts' => { 'backend' => 'dummy' } } );
is( $response->{status}, 'error', 'add_kur with a bad name errors' );
$response = $client->call( 'add_kur', { 'name' => 'nobackend', 'opts' => {} } );
is( $response->{status}, 'error', 'add_kur with out a backend errors' );
$status = $client->call_ok('status');
ok( !defined( $status->{kurs}{nobackend} ), 'failed add_kur not registered' );

$result = $client->call_ok( 'remove_kur', { 'name' => 'dns' } );
is( $result->{removed}, 'dns', 'remove_kur response' );
ok( wait_for_gone( $dir . '/run/kur/dns.sock' ), 'dns socket gone after remove' );
ok( wait_for_gone( $dir . '/run/kur/dns.pid' ),  'dns pid file gone after remove' );
$status = $client->call_ok('status');
ok( !defined( $status->{kurs}{dns} ), 'dns gone from status after remove' );

$response = $client->call( 'remove_kur', { 'name' => 'nope' } );
is( $response->{status}, 'error', 'remove_kur of an unknown kur errors' );

#
# fan_out kurs... a gateway with no process of it's own that expands to
# it's members when targeted
#

$result = $client->call_ok( 'add_kur', { 'name' => 'gate', 'opts' => { 'fan_out' => [ 'sshd', 'smtp' ] } } );
is( $result->{added}, 'gate', 'added a fan_out kur' );

$status = $client->call_ok('status');
is_deeply( $status->{kurs}{gate}{fan_out}, [ 'sshd', 'smtp' ], 'status shows the members' );
is( $status->{kurs}{gate}{running}, 1, 'the fan_out kur counts as running when every member is' );
ok( !-e $dir . '/run/kur/gate.sock', 'no socket for the fan_out kur' );

$result = $client->call_ok( 'ban', { 'ips' => ['7.7.7.7'], 'kur' => 'gate' } );
is( $result->{kurs}{sshd}{ips}{'7.7.7.7'}{status}, 'ok', 'gateway ban applied on sshd' );
is( $result->{kurs}{smtp}{ips}{'7.7.7.7'}{status}, 'ok', 'gateway ban applied on smtp' );
ok( !defined( $result->{kurs}{gate} ), 'the response is keyed per member, no gate row' );

$result = $client->call_ok( 'checkpoint', { 'kur' => 'gate' } );
is( $result->{kurs}{sshd}{checkpointed}, 1, 'gateway checkpoint hit sshd' );
is( $result->{kurs}{smtp}{checkpointed}, 1, 'gateway checkpoint hit smtp' );

$result = $client->call_ok( 'status_kur', { 'name' => 'gate' } );
is_deeply( $result->{fan_out}, [ 'sshd', 'smtp' ], 'status_kur of the gateway lists members' );
is( $result->{kurs}{sshd}{name}, 'sshd', 'status_kur of the gateway carries member statuses' );

$result = $client->call_ok('banned');
ok( !defined( $result->{kurs}{gate} ),                               'banned has no gate row' );
ok( ( grep { $_ eq '7.7.7.7' } @{ $result->{kurs}{sshd}{banned} } ), 'the gateway ban shows on the member rolls' );

$response = $client->call( 'add_kur', { 'name' => 'gate2', 'opts' => { 'fan_out' => ['nosuch'] } } );
is( $response->{status}, 'error', 'add_kur with an unknown member errors' );
$response = $client->call( 'add_kur', { 'name' => 'gate2', 'opts' => { 'fan_out' => ['gate'] } } );
is( $response->{status}, 'error', 'fan_out kurs may not nest' );
$response
	= $client->call( 'add_kur', { 'name' => 'gate2', 'opts' => { 'backend' => 'dummy', 'fan_out' => ['sshd'] } } );
is( $response->{status}, 'error', 'backend and fan_out are mutually exclusive' );

$result = $client->call_ok( 'remove_kur', { 'name' => 'gate' } );
is( $result->{removed}, 'gate', 'the fan_out kur removed' );
$status = $client->call_ok('status');
ok( !defined( $status->{kurs}{gate} ), 'gate gone from status after remove' );
is( $status->{kurs}{sshd}{running}, 1, 'members unaffected by removing the gateway' );

#
# checkpoint... all kurs, one kur, unknown kur
#

$result = $client->call_ok('checkpoint');
is( $result->{kurs}{sshd}{checkpointed}, 1, 'checkpoint fanned out to sshd' );
is( $result->{kurs}{smtp}{checkpointed}, 1, 'checkpoint fanned out to smtp' );
ok( -f $dir . '/cache/kur.sshd.csv', 'sshd state CSV exists' );
ok( -f $dir . '/cache/kur.smtp.csv', 'smtp state CSV exists' );

$result = $client->call_ok( 'checkpoint', { 'kur' => 'sshd' } );
is( $result->{kurs}{sshd}{checkpointed}, 1, 'targeted checkpoint hit sshd' );
ok( !defined( $result->{kurs}{smtp} ), 'targeted checkpoint did not touch smtp' );

$response = $client->call( 'checkpoint', { 'kur' => 'nope' } );
is( $response->{status}, 'error', 'checkpoint of an unknown kur errors' );

#
# fan out with a down kur... a kur who's backend can never init lives in
# restart backoff, and fan out commands must answer an error for it with out
# the live kurs being disturbed
#

$result = $client->call_ok( 'add_kur', { 'name' => 'down', 'opts' => { 'backend' => 'nosuchbackendzzz' } } );
is( $result->{added}, 'down', 'added a kur that can never start' );

$result = $client->call_ok( 'ban', { 'ips' => ['3.3.3.3'] } );
ok( defined( $result->{kurs}{down}{error} ), 'fan out ban answers an error for the down kur' );
is( $result->{kurs}{sshd}{ips}{'3.3.3.3'}{status}, 'ok', 'fan out ban still applied on sshd' );
is( $result->{kurs}{smtp}{ips}{'3.3.3.3'}{status}, 'ok', 'fan out ban still applied on smtp' );

$result = $client->call_ok('banned');
ok( defined( $result->{kurs}{down}{error} ),                         'banned answers an error for the down kur' );
ok( ( grep { $_ eq '3.3.3.3' } @{ $result->{kurs}{sshd}{banned} } ), 'banned still reports the live kurs' );

$result = $client->call_ok( 'unban', { 'ip' => '3.3.3.3' } );
ok( defined( $result->{kurs}{down}{error} ), 'unban answers an error for the down kur' );
is( $result->{kurs}{sshd}{was_banned}, 1, 'unban still removed it from sshd' );

$result = $client->call_ok( 'remove_kur', { 'name' => 'down' } );
is( $result->{removed}, 'down', 'the down kur removed again' );

#
# supervision... kill a kur and it should come back
#

open( my $pid_fh, '<', $dir . '/run/kur/sshd.pid' ) || die($!);
my $old_sshd_pid = <$pid_fh>;
close($pid_fh);
kill( 'KILL', $old_sshd_pid );

my $respawned = 0;
my $waited    = 0;
while ( $waited < 20 ) {
	$status = $client->call_ok('status');
	if (   $status->{kurs}{sshd}{restarts}
		&& $status->{kurs}{sshd}{running}
		&& $status->{kurs}{sshd}{pid} != $old_sshd_pid )
	{
		$respawned = 1;
		last;
	}
	select( undef, undef, undef, 0.5 );
	$waited += 0.5;
} ## end while ( $waited < 20 )
ok( $respawned, 'sshd respawned after being killed' );
is( $status->{kurs}{sshd}{restarts}, 1, 'restart counted' );

# can't just wait on the socket path as the SIGKILLed kur left a stale
# socket file behind, so poll till the respawned one actually answers
my $alive = 0;
$waited = 0;
while ( $waited < 20 ) {
	my $pong = eval { $sshd_client->call_ok('ping'); };
	if ( defined($pong) && $pong->{pong} ) {
		$alive = 1;
		last;
	}
	select( undef, undef, undef, 0.5 );
	$waited += 0.5;
}
ok( $alive, 'respawned sshd answers on it\'s socket' );

$result = $client->call_ok( 'ban', { 'ips' => ['6.6.6.6'], 'kur' => 'sshd' } );
is( $result->{kurs}{sshd}{ips}{'6.6.6.6'}{status}, 'ok', 'bans work on the respawned kur' );

#
# stop... this is also the regression test for wheel destruction from the
# wrong session, as the add/remove above has to not keep the manager alive
#

$result = $client->call_ok('stop');
is( $result->{stopping}, 1, 'stop response' );
ok( wait_for_gone($manager_socket),               'manager socket gone' );
ok( wait_for_gone( $dir . '/run/kur/sshd.sock' ), 'sshd socket gone' );
ok( wait_for_gone( $dir . '/run/kur/smtp.sock' ), 'smtp socket gone' );
ok( wait_for_gone( $dir . '/run/pid' ),           'manager pid file gone' );
is( wait_for_exit( $manager_pid, 20 ), 0, 'manager exited 0' );

done_testing;
