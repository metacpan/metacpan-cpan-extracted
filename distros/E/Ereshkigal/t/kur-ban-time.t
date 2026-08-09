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

my %common = (
	'backend'        => 'dummy',
	'ports'          => ['22'],
	'protocols'      => ['tcp'],
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);

# hide the Error::Helper warn noise
local *STDERR;
open( STDERR, '>', \my $stderr_capture );

#
# validation and resolution of the instance default
#

throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'ban_time' => 'abc' ) } qr/ban_time/,
	'dies on a non-int ban_time';
throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'ban_time' => -5 ) } qr/ban_time/,
	'dies on a negative ban_time';

my $kur = Ereshkigal::Kur->new( %common, 'name' => 'testy' );
is( $kur->{ban_time}, 600, 'ban_time defaults to 600' );

$kur = Ereshkigal::Kur->new( %common, 'name' => 'testy', 'ban_time' => 100 );
is( $kur->{ban_time}, 100, 'ban_time merged' );
$kur->{started} = time;

#
# ban records the expiry book
#

my $before = time;
my $result = $kur->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'] } } );
is( $result->{ips}{'1.2.3.4'}{status}, 'ok', 'ban ok' );
my $entry = $kur->{bans}{'1.2.3.4'};
ok( defined($entry), 'ban tracked' );
ok( $entry->{expires} >= $before + 100 && $entry->{expires} <= time + 100, 'instance default ban_time applied' );
ok( $entry->{banned_at} >= $before && $entry->{banned_at} <= time, 'banned_at recorded' );

$before = time;
$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['5.6.7.8'], 'ban_time' => 30 } } );
$entry  = $kur->{bans}{'5.6.7.8'};
ok( $entry->{expires} >= $before + 30 && $entry->{expires} <= time + 30, 'request ban_time overrides the default' );

$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['9.9.9.9'], 'ban_time' => 0 } } );
is( $kur->{bans}{'9.9.9.9'}{expires}, 0, 'ban_time 0 records a permanent ban' );

throws_ok { $kur->_cmd_ban( { 'args' => { 'ips' => ['1.1.1.1'], 'ban_time' => 'abc' } } ) } qr/ban_time/,
	'dies on a non-int args.ban_time';
throws_ok { $kur->_cmd_ban( { 'args' => { 'ips' => ['1.1.1.1'], 'ban_time' => -1 } } ) } qr/ban_time/,
	'dies on a negative args.ban_time';

#
# re-banning a banned IP refreshes it's timer with out being an error
#

my $bans_before = $kur->{stats}{bans};
$before = time;
$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'], 'ban_time' => 500 } } );
is( $result->{ips}{'1.2.3.4'}{status},    'ok', 'refresh is ok' );
is( $result->{ips}{'1.2.3.4'}{refreshed}, 1,    'refresh reported' );
$entry = $kur->{bans}{'1.2.3.4'};
ok( $entry->{expires} >= $before + 500 && $entry->{expires} <= time + 500, 'timer refreshed' );
is( $kur->{stats}{bans}, $bans_before, 'refresh does not bump the ban stat' );

#
# banned and status carry the timing info
#

$result = $kur->_cmd_banned;
is_deeply( [ sort( @{ $result->{banned} } ) ], [ '1.2.3.4', '5.6.7.8', '9.9.9.9' ], 'banned list' );
is( $result->{expires}{'9.9.9.9'}, 0, 'permanent ban in the expires map' );
ok( $result->{expires}{'5.6.7.8'} > time, 'timed ban in the expires map' );

$result = $kur->_cmd_status;
is( $result->{ban_time},       100, 'status ban_time' );
is( $result->{bans_timed},     2,   'status bans_timed' );
is( $result->{bans_permanent}, 1,   'status bans_permanent' );
is( $result->{next_expiry}, $kur->{bans}{'5.6.7.8'}{expires}, 'status next_expiry is the soonest' );

#
# persistence on mutation
#

my $saved = read_ban_csv( $kur->state_path );
is_deeply( [ sort( keys( %{$saved} ) ) ], [ sort( keys( %{ $kur->{bans} } ) ) ],
	'state CSV covers the ban book' );
is( $saved->{'9.9.9.9'}{left}, 0, 'permanent ban persisted with 0 left' );
ok( $saved->{'5.6.7.8'}{left} > 0, 'timed ban persisted with time left' );

$kur->_cmd_unban( { 'args' => { 'ip' => '5.6.7.8' } } );
ok( !defined( $kur->{bans}{'5.6.7.8'} ), 'unban deletes the tracking entry' );
$saved = read_ban_csv( $kur->state_path );
ok( !defined( $saved->{'5.6.7.8'} ), 'unban persisted' );

#
# the sweep
#

$kur->{bans}{'1.2.3.4'}{expires} = time - 10;
$kur->_sweep_bans;
ok( !defined( $kur->{bans}{'1.2.3.4'} ), 'expired entry swept' );
is( ( grep { $_ eq '1.2.3.4' } @{ $kur->_cmd_banned->{banned} } ), 0, 'expired IP unbanned from the backend' );
is( $kur->{stats}{expired}, 1, 'expired counted in stats' );
ok( defined( $kur->{bans}{'9.9.9.9'} ), 'permanent ban left alone by the sweep' );
$saved = read_ban_csv( $kur->state_path );
ok( !defined( $saved->{'1.2.3.4'} ), 'sweep persisted' );

#
# flush clears the book
#

$kur->_cmd_ban( { 'args' => { 'ips' => ['3.3.3.3'] } } );
$kur->_cmd_flush;
is_deeply( $kur->{bans}, {}, 'flush clears the ban book' );
$saved = read_ban_csv( $kur->state_path );
is_deeply( $saved, {}, 'flush persisted' );

#
# persistence across a restart... a fresh kur over the same dirs reloads
# the state CSV, dropping and unbanning whatever expired while down... the
# expired row is hand written with a backdated time as a checkpoint can
# never write an already expired row
#

my $now = time;
open( my $csv_fh, '>', $kur->state_path ) || die($!);
print $csv_fh "ip,time,ban_time_left\n"
	. '10.0.0.1,' . $now . ',1000' . "\n"
	. '10.0.0.2,' . ( $now - 100 ) . ',5' . "\n"
	. '10.0.0.3,' . $now . ',0' . "\n";
close($csv_fh);

my $kur2 = Ereshkigal::Kur->new( %common, 'name' => 'testy', 'ban_time' => 100 );
$kur2->{started} = time;
ok( defined( $kur2->{bans}{'10.0.0.1'} ),  'unexpired timed ban reloaded' );
ok( defined( $kur2->{bans}{'10.0.0.3'} ),  'permanent ban reloaded' );
ok( !defined( $kur2->{bans}{'10.0.0.2'} ), 'expired while down ban dropped' );
is( $kur2->{stats}{expired}, 1, 'expired while down counted' );
is( $kur2->{bans}{'10.0.0.1'}{expires}, $now + 1000, 'expiry reconstructed from time plus time left' );
is( $kur2->{bans}{'10.0.0.3'}{expires}, 0,           'permanent stays permanent' );
is_deeply(
	[ sort( @{ $kur2->_cmd_banned->{banned} } ) ],
	[ '10.0.0.1', '10.0.0.3' ],
	're-banned into the fresh backend'
);
$saved = read_ban_csv( $kur2->state_path );
ok( !defined( $saved->{'10.0.0.2'} ), 'state CSV rewritten with out the expired entry after load' );

done_testing;
