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

# global enable_cidr on, with per kur overrides exercising the whole matrix...
# sshd inherits the global on, smtp turns it off and errors, drop turns it off
# but silently drops. every backend is the dummy, which supports CIDR, so what
# is being proven here is the config threading and the manager routing.
my $config = write_config(
	$dir,
	'settings_toml' => "enable_cidr      = true\ncidr_silent_drop = false\n",
	'kurs_toml'     => '[kur.sshd]
backend   = "dummy"
ports     = [ "22" ]
protocols = [ "tcp" ]

[kur.smtp]
backend     = "dummy"
ports       = [ "25" ]
protocols   = [ "tcp" ]
enable_cidr = false

[kur.drop]
backend          = "dummy"
enable_cidr      = false
cidr_silent_drop = true
',
);
my $manager_pid = spawn_manager($config);

my $manager_socket = $dir . '/run/socket';
ok( wait_for_socket($manager_socket),               'manager socket came up' ) || BAIL_OUT('manager never came up');
ok( wait_for_socket( $dir . '/run/kur/sshd.sock' ), 'sshd kur socket came up' );
ok( wait_for_socket( $dir . '/run/kur/smtp.sock' ), 'smtp kur socket came up' );
ok( wait_for_socket( $dir . '/run/kur/drop.sock' ), 'drop kur socket came up' );

my $client = Ereshkigal::Client->new( 'socket' => $manager_socket, 'timeout' => 15 );

#
# the global setting and per kur overrides threaded through to the kurs, proven
# via each kur's own status
#

is( $client->call_ok( 'status_kur', { 'name' => 'sshd' } )->{status}{cidr_enabled},
	1, 'global enable_cidr inherited by sshd' );
is( $client->call_ok( 'status_kur', { 'name' => 'smtp' } )->{status}{cidr_enabled},
	0, 'per kur enable_cidr override off on smtp' );
is( $client->call_ok( 'status_kur', { 'name' => 'drop' } )->{status}{cidr_enabled},
	0, 'per kur enable_cidr override off on drop' );

#
# targeted cidr_ban on an enabled kur
#

my $result = $client->call_ok( 'cidr_ban', { 'cidrs' => ['1.2.3.0/24'], 'kur' => 'sshd' } );
is( $result->{kurs}{sshd}{cidrs}{'1.2.3.0/24'}{status}, 'ok', 'targeted cidr_ban applied on sshd' );
ok( !defined( $result->{kurs}{smtp} ), 'targeted cidr_ban did not touch smtp' );

# host bits are masked off at the manager before the fan out
$result = $client->call_ok( 'cidr_ban', { 'cidrs' => ['10.9.8.7/8'], 'kur' => 'sshd' } );
is( $result->{kurs}{sshd}{cidrs}{'10.0.0.0/8'}{status}, 'ok', 'host address masked to its network before fan out' );

#
# banned carries the CIDR bans under banned_cidr
#

$result = $client->call_ok('banned');
is_deeply(
	[ sort( @{ $result->{kurs}{sshd}{banned_cidr} } ) ],
	[ '1.2.3.0/24', '10.0.0.0/8' ],
	'banned reports the CIDR bans for sshd'
);
is_deeply( $result->{kurs}{smtp}{banned_cidr}, [], 'smtp carries no CIDR bans' );

#
# an untargeted cidr_ban fans to every real kur, each answering per its own CIDR
# disposition... enabled bans, disabled errors, disabled with silent drop drops
#

$result = $client->call_ok( 'cidr_ban', { 'cidrs' => ['172.16.0.0/12'] } );
is( $result->{kurs}{sshd}{cidrs}{'172.16.0.0/12'}{status}, 'ok', 'fan out cidr_ban applied on the enabled sshd' );
like( $result->{kurs}{smtp}{error}, qr/not enabled/, 'fan out cidr_ban errors on the disabled smtp' );
is( $result->{kurs}{drop}{dropped}, 1, 'fan out cidr_ban silently dropped on the disabled drop kur' );

#
# the manager pre-flights CIDRs, rejecting garbage before the fan out
#

$result = $client->call_ok( 'cidr_ban', { 'cidrs' => [ 'not-a-cidr', '192.168.0.0/16' ], 'kur' => 'sshd' } );
is( $result->{rejected}{'not-a-cidr'}{status}, 'error', 'invalid CIDR rejected by the manager' );
like( $result->{rejected}{'not-a-cidr'}{error}, qr/does not appear to be an IPv4 or IPv6 CIDR/, 'rejected message' );
is( $result->{kurs}{sshd}{cidrs}{'192.168.0.0/16'}{status}, 'ok', 'valid CIDR in the same request applied' );

my $response = $client->call( 'cidr_ban', { 'cidrs' => ['not-a-cidr'] } );
is( $response->{status}, 'error', 'cidr_ban with nothing but invalid CIDRs errors' );

$response = $client->call( 'cidr_ban', { 'cidrs' => ['1.2.3.0/24'], 'kur' => 'nope' } );
is( $response->{status}, 'error', 'cidr_ban to an unknown kur errors' );
like( $response->{error}, qr/No such kur instance/, 'unknown kur message' );

#
# cidr_unban fans to every real kur, again each per its disposition
#

$result = $client->call_ok( 'cidr_unban', { 'cidr' => '1.2.3.0/24' } );
is( $result->{kurs}{sshd}{was_banned}, 1, 'cidr_unban removed it from sshd' );
like( $result->{kurs}{smtp}{error}, qr/not enabled/, 'cidr_unban errors on the disabled smtp' );
is( $result->{kurs}{drop}{dropped}, 1, 'cidr_unban silently dropped on the drop kur' );

# unban via a host address inside the network finds the masked network ban
$result = $client->call_ok( 'cidr_unban', { 'cidr' => '10.1.2.3/8' } );
is( $result->{kurs}{sshd}{was_banned}, 1, 'cidr_unban via a host address finds the network ban' );

$response = $client->call( 'cidr_unban', { 'cidr' => 'not-a-cidr' } );
is( $response->{status}, 'error', 'cidr_unban of an invalid CIDR errors' );

$response = $client->call('cidr_unban');
is( $response->{status}, 'error', 'cidr_unban with out args errors' );

#
# unban --all flushes CIDR bans alongside single IP bans
#

$client->call_ok( 'cidr_ban', { 'cidrs' => ['203.0.113.0/24'], 'kur' => 'sshd' } );
$client->call_ok( 'ban',      { 'ips'   => ['5.5.5.5'],        'kur' => 'sshd' } );
$result = $client->call_ok( 'unban', { 'all' => 1 } );
is( $result->{kurs}{sshd}{flushed}, 1, 'unban all flushed sshd' );
$result = $client->call_ok('banned');
is_deeply( $result->{kurs}{sshd}{banned},      [], 'sshd single IP bans empty after unban all' );
is_deeply( $result->{kurs}{sshd}{banned_cidr}, [], 'sshd CIDR bans empty after unban all' );

#
# stop
#

$result = $client->call_ok('stop');
is( $result->{stopping}, 1, 'stop response' );
ok( wait_for_gone($manager_socket), 'manager socket gone' );
is( wait_for_exit( $manager_pid, 20 ), 0, 'manager exited 0' );

done_testing;
