#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use EreshkigalTest qw( test_dir read_ban_csv );

use Ereshkigal::Kur;

my $dir = test_dir();

# hide the Error::Helper warn noise from the error path tests
local *STDERR;
open( STDERR, '>', \my $stderr_capture );

#
# a CIDR enabled instance on a CIDR capable backend
#

my $kur = Ereshkigal::Kur->new(
	'name'           => 'cidry',
	'backend'        => 'dummy',
	'ports'          => ['22'],
	'protocols'      => ['tcp'],
	'enable_cidr'    => 1,
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$kur->{started} = time;

is( $kur->{enable_cidr},    1, 'enable_cidr merged in' );
is( $kur->{cidr_supported}, 1, 'dummy backend reports CIDR support' );
is( $kur->_cidr_available,  1, 'CIDR is available on an enabled capable instance' );

#
# cidr_ban
#

my $result = $kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => [ '1.2.3.0/24', '10.0.0.0/8' ] } } );
is( $result->{cidrs}{'1.2.3.0/24'}{status}, 'ok', 'ban of 1.2.3.0/24 ok' );
is( $result->{cidrs}{'10.0.0.0/8'}{status}, 'ok', 'ban of 10.0.0.0/8 ok' );
is( $kur->{stats}{cidr_bans},               2,    'stats cidr_bans is 2' );

$result = $kur->_cmd_banned;
is_deeply(
	[ sort( @{ $result->{banned_cidr} } ) ],
	[ '1.2.3.0/24', '10.0.0.0/8' ],
	'banned lists both CIDRs under banned_cidr'
);
is_deeply( $result->{banned}, [], 'single IP banned list untouched by CIDR bans' );

# host bits are masked off, so a host address bans its network and a re-ban of
# the same network under a different host address just refreshes it
$result = $kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.4/24'] } } );
is( $result->{cidrs}{'1.2.3.0/24'}{refreshed}, 1, 'host address folds onto its network and refreshes' );
is( $kur->{stats}{cidr_bans},                  2, 'stats cidr_bans unchanged for the refresh' );

# invalid CIDRs error per item with out killing the valid ones in the request
$result = $kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => [ 'not-a-cidr', '172.16.0.0/12' ] } } );
is( $result->{cidrs}{'not-a-cidr'}{status}, 'error', 'invalid CIDR errors' );
like( $result->{cidrs}{'not-a-cidr'}{error}, qr/does not appear to be an IPv4 or IPv6 CIDR/, 'invalid CIDR message' );
is( $result->{cidrs}{'172.16.0.0/12'}{status}, 'ok', 'valid CIDR in the same request still banned' );

# a bare IP is not a CIDR
$result = $kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.4'] } } );
is( $result->{cidrs}{'1.2.3.4'}{status}, 'error', 'bare IP with no prefix refused' );

throws_ok { $kur->_cmd_cidr_ban( {} ) } qr/args\.cidrs/, 'dies with out args';
throws_ok { $kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => [] } } ) } qr/args\.cidrs/, 'dies on empty cidrs';
throws_ok { $kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => 'x' } } ) } qr/args\.cidrs/, 'dies on non-array cidrs';

#
# cidr_unban
#

$result = $kur->_cmd_cidr_unban( { 'args' => { 'cidr' => '1.2.3.0/24' } } );
is( $result->{was_banned},      1,            'unban of a present CIDR reports was_banned 1' );
is( $result->{cidr},            '1.2.3.0/24', 'unban reports the CIDR back' );
is( $kur->{stats}{cidr_unbans}, 1,            'stats cidr_unbans is 1' );

# unban via a host address inside the network finds the network ban
$result = $kur->_cmd_cidr_unban( { 'args' => { 'cidr' => '10.9.8.7/8' } } );
is( $result->{was_banned}, 1,            'unban via a host address inside the network finds it' );
is( $result->{cidr},       '10.0.0.0/8', 'unban reports the masked network back' );

$result = $kur->_cmd_cidr_unban( { 'args' => { 'cidr' => '1.2.3.0/24' } } );
is( $result->{was_banned}, 0, 'unban of an absent CIDR reports was_banned 0' );

throws_ok { $kur->_cmd_cidr_unban( {} ) } qr/args\.cidr/, 'dies with out args';
throws_ok { $kur->_cmd_cidr_unban( { 'args' => { 'cidr' => ['1.2.3.0/24'] } } ) } qr/args\.cidr/, 'dies on a ref';
throws_ok { $kur->_cmd_cidr_unban( { 'args' => { 'cidr' => 'not-a-cidr' } } ) }
qr/does not appear to be an IPv4 or IPv6 CIDR/, 'unban of an invalid CIDR dies';

#
# status reflects the CIDR state
#

$kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => [ '192.168.0.0/16', '203.0.113.0/24' ], 'ban_time' => 0 } } );
$result = $kur->_cmd_status;
is( $result->{cidr_enabled},        1, 'status cidr_enabled' );
is( $result->{cidr_supported},      1, 'status cidr_supported' );
is( $result->{cidr_banned_count},   3, 'status cidr_banned_count counts current CIDR bans' );
is( $result->{cidr_bans_permanent}, 2, 'status cidr_bans_permanent for the ban_time 0 bans' );

#
# flush clears CIDR bans alongside single IP bans
#

$kur->_cmd_ban( { 'args' => { 'ips' => ['4.4.4.4'] } } );
$result = $kur->_cmd_flush;
is( $result->{flushed}, 1, 'flush response' );
$result = $kur->_cmd_banned;
is_deeply( $result->{banned},      [], 'single IP bans empty after flush' );
is_deeply( $result->{banned_cidr}, [], 'CIDR bans empty after flush' );

#
# an instance with CIDR left disabled, the default... commands are refused
#

my $off = Ereshkigal::Kur->new(
	'name'           => 'cidr-off',
	'backend'        => 'dummy',
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$off->{started} = time;

is( $off->{enable_cidr},   0, 'enable_cidr defaults off' );
is( $off->_cidr_available, 0, 'CIDR not available when disabled' );

# the toggles are folded from whatever the config carried... the false-ish
# strings and an empty string, which a templater may well emit, all mean off,
# while anything else is on
foreach my $false ( '', '0', 'false', 'FALSE', 'no', 'off' ) {
	my $folded = Ereshkigal::Kur->new(
		'name'           => 'fold',
		'backend'        => 'dummy',
		'run_base_dir'   => $dir . '/run',
		'cache_base_dir' => $dir . '/cache',
		'enable_cidr'    => $false,
	);
	is( $folded->{enable_cidr}, 0, 'enable_cidr "' . $false . '" folds to off' );
} ## end foreach my $false ( '', '0', 'false', 'FALSE', ...)

foreach my $true ( '1', 'true', 'yes', 'on' ) {
	my $folded = Ereshkigal::Kur->new(
		'name'           => 'fold',
		'backend'        => 'dummy',
		'run_base_dir'   => $dir . '/run',
		'cache_base_dir' => $dir . '/cache',
		'enable_cidr'    => $true,
	);
	is( $folded->{enable_cidr}, 1, 'enable_cidr "' . $true . '" folds to on' );
} ## end foreach my $true ( '1', 'true', 'yes', 'on' )

throws_ok { $off->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.0/24'] } } ) } qr/not enabled/,
	'cidr_ban refused when disabled';
throws_ok { $off->_cmd_cidr_unban( { 'args' => { 'cidr' => '1.2.3.0/24' } } ) } qr/not enabled/,
	'cidr_unban refused when disabled';
is( $off->_cmd_status->{cidr_enabled}, 0, 'status reports CIDR disabled' );

#
# a disabled instance with cidr_silent_drop set drops rather than erroring, so
# it can sit behind a fan out with CIDR capable peers with out spoiling it
#

my $drop = Ereshkigal::Kur->new(
	'name'             => 'cidr-drop',
	'backend'          => 'dummy',
	'cidr_silent_drop' => 1,
	'run_base_dir'     => $dir . '/run',
	'cache_base_dir'   => $dir . '/cache',
);
$drop->{started} = time;

$result = $drop->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.0/24'] } } );
is( $result->{dropped}, 1, 'cidr_ban silently dropped when disabled and cidr_silent_drop set' );
like( $result->{reason}, qr/not enabled/, 'drop reason names the disabled state' );
$result = $drop->_cmd_cidr_unban( { 'args' => { 'cidr' => '1.2.3.0/24' } } );
is( $result->{dropped}, 1, 'cidr_unban silently dropped when disabled and cidr_silent_drop set' );
# nothing reached the backend
is_deeply( $drop->_cmd_banned->{banned_cidr}, [], 'a dropped cidr_ban never touches the backend' );

#
# a CIDR incapable backend refuses even when enable_cidr is set... simulated by
# forcing the capability flag off, since the real incapable backends can not be
# inited in a test environment
#

my $incapable = Ereshkigal::Kur->new(
	'name'           => 'cidr-incapable',
	'backend'        => 'dummy',
	'enable_cidr'    => 1,
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$incapable->{started}        = time;
$incapable->{cidr_supported} = 0;

is( $incapable->_cidr_available, 0, 'CIDR not available when the backend can not do it' );
throws_ok { $incapable->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.0/24'] } } ) }
qr/does not support CIDR bans/, 'cidr_ban refused on a CIDR incapable backend';

# with silent drop on, the same incapable instance drops instead
$incapable->{cidr_silent_drop} = 1;
$result = $incapable->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.0/24'] } } );
is( $result->{dropped}, 1, 'cidr_ban dropped on a CIDR incapable backend with silent drop' );
like( $result->{reason}, qr/does not support CIDR bans/, 'drop reason names the incapable backend' );

#
# persistence... CIDR bans go to their own sibling CSV and survive a restart
#

is( $kur->cidr_state_path, $dir . '/cache/kur.cidry.cidr.csv', 'cidr_state_path is the sibling CSV' );

my $persist = Ereshkigal::Kur->new(
	'name'           => 'cidr-persist',
	'backend'        => 'dummy',
	'enable_cidr'    => 1,
	'ban_time'       => 1000,
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$persist->{started} = time;
$persist->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['1.2.3.0/24'] } } );                     # timed
$persist->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['10.0.0.0/8'], 'ban_time' => 0 } } );    # permanent

ok( -f $persist->cidr_state_path, 'cidr ban wrote the sibling CSV' );
my $rows = read_ban_csv( $persist->cidr_state_path );
is( $rows->{'10.0.0.0/8'}{left}, 0, 'permanent CIDR ban written with 0 left' );
ok( $rows->{'1.2.3.0/24'}{left} > 0 && $rows->{'1.2.3.0/24'}{left} <= 1000, 'timed CIDR ban written with time left' );

# the single IP CSV for this instance is untouched by CIDR only activity
ok( !-f $persist->state_path || !%{ read_ban_csv( $persist->state_path ) }, 'single IP CSV carries no CIDR rows' );

# a fresh, still enabled instance of the same name restores them
my $reload = Ereshkigal::Kur->new(
	'name'           => 'cidr-persist',
	'backend'        => 'dummy',
	'enable_cidr'    => 1,
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$reload->{started} = time;
is_deeply(
	[ sort( @{ $reload->_cmd_banned->{banned_cidr} } ) ],
	[ '1.2.3.0/24', '10.0.0.0/8' ],
	'CIDR bans restored into the fresh backend on restart'
);
is( $reload->{cidr_bans}{'10.0.0.0/8'}{expires}, 0, 'permanent CIDR ban stays permanent across restart' );

# a restart with CIDR disabled leaves the persisted file intact rather than
# handing it to a backend or wiping it
my $reload_off = Ereshkigal::Kur->new(
	'name'           => 'cidr-persist',
	'backend'        => 'dummy',
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$reload_off->{started} = time;
is_deeply( $reload_off->{cidr_bans}, {}, 'disabled restart does not load CIDR bans into tracking' );
$rows = read_ban_csv( $persist->cidr_state_path );
is_deeply(
	[ sort( keys( %{$rows} ) ) ],
	[ '1.2.3.0/24', '10.0.0.0/8' ],
	'and leaves the persisted CIDR CSV intact for a later re-enable'
);

done_testing;
