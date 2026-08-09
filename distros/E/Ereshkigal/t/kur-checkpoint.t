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

sub slurp {
	my ($path) = @_;
	local $/ = undef;
	open( my $fh, '<', $path ) || die($!);
	my $raw = <$fh>;
	close($fh);
	return $raw;
}

# hide the Error::Helper warn noise
local *STDERR;
open( STDERR, '>', \my $stderr_capture );

#
# checkpoint opt validation and resolution
#

throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'checkpoint' => 'abc' ) } qr/checkpoint/,
	'dies on a non-int checkpoint';
throws_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'checkpoint' => -5 ) } qr/checkpoint/,
	'dies on a negative checkpoint';

my $kur = Ereshkigal::Kur->new( %common, 'name' => 'testy' );
is( $kur->{checkpoint}, 60, 'checkpoint defaults to 60' );

$kur = Ereshkigal::Kur->new( %common, 'name' => 'testy', 'checkpoint' => 5, 'ban_time' => 100 );
is( $kur->{checkpoint}, 5, 'checkpoint merged' );
$kur->{started} = time;

lives_ok { Ereshkigal::Kur->new( %common, 'name' => 'testy', 'checkpoint' => 0 ) } '0 accepted';

is( $kur->state_path, $dir . '/cache/kur.testy.csv', 'state_path is the CSV under the cache dir' );

#
# CSV shape and mutation checkpointing
#

ok( !defined( $kur->{last_checkpoint} ) || !$kur->{last_checkpoint}, 'no checkpoint yet with out a state file' );

my $before = time;
$kur->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'] } } );
ok( -f $kur->state_path,                'ban created the state CSV' );
ok( !-e $kur->state_path . '.tmp',      'no temp file left behind' );
ok( $kur->{last_checkpoint} >= $before, 'last_checkpoint bumped by the mutation' );

my $raw = slurp( $kur->state_path );
like( $raw, qr/^ip,time,ban_time_left\n/, 'the header row is present' );

$kur->_cmd_ban( { 'args' => { 'ips' => ['9.9.9.9'], 'ban_time' => 0 } } );
my $rows = read_ban_csv( $kur->state_path );
is( $rows->{'9.9.9.9'}{left}, 0, 'permanent ban written with 0 left' );
ok( $rows->{'1.2.3.4'}{left} > 0        && $rows->{'1.2.3.4'}{left} <= 100,  'timed ban written with it\'s time left' );
ok( $rows->{'1.2.3.4'}{time} >= $before && $rows->{'1.2.3.4'}{time} <= time, 'the time column is the write time' );

# clamped so a ban expiring with in the same second can't collide with the
# permanent encoding of 0
$kur->{bans}{'1.2.3.4'}{expires} = time;
$kur->_checkpoint;
$rows = read_ban_csv( $kur->state_path );
is( $rows->{'1.2.3.4'}{left}, 1, 'nearly expired ban clamped to 1 rather than 0' );

#
# the checkpoint command handler
#

my $result = $kur->_cmd_checkpoint;
is( $result->{checkpointed}, 1, '_cmd_checkpoint reports checkpointed' );
is( $result->{bans},         2, '_cmd_checkpoint reports the ban count' );

#
# periodic rewrite bookkeeping via the tick path
#

$kur->{bans}            = { '2.2.2.2' => { 'banned_at' => time, 'expires' => time + 1000 } };
$kur->{last_checkpoint} = time - 100;
my $old_raw = slurp( $kur->state_path );
$kur->_tick;
isnt( slurp( $kur->state_path ), $old_raw, 'tick rewrites the CSV once the checkpoint interval has passed' );
ok( $kur->{last_checkpoint} >= time - 2, 'tick updated last_checkpoint' );

$kur->{last_checkpoint} = time;
$old_raw = slurp( $kur->state_path );
$kur->_tick;
is( slurp( $kur->state_path ), $old_raw, 'tick leaves the CSV alone inside the checkpoint interval' );

my $disabled = Ereshkigal::Kur->new( %common, 'name' => 'testy-b', 'checkpoint' => 0 );
$disabled->{started} = time;
$disabled->_cmd_ban( { 'args' => { 'ips' => ['3.3.3.3'] } } );
$disabled->{last_checkpoint} = 0;
$old_raw = slurp( $disabled->state_path );
$disabled->_tick;
is( slurp( $disabled->state_path ), $old_raw, 'checkpoint 0 disables the periodic rewrite' );
is( $disabled->{last_checkpoint},   0,        'and last_checkpoint stays put' );

#
# loading... the row time is compared against now to decide restoration
#

my $now = time;
open( my $csv_fh, '>', $dir . '/cache/kur.loader.csv' ) || die($!);
print $csv_fh "ip,time,ban_time_left\n" . '10.0.0.1,' . $now . ',500' . "\n"    # timed, alive
	. '10.0.0.2,' . ( $now - 60 ) . ',10' . "\n"                                # expired while down
	. '10.0.0.3,' . $now . ',0' . "\n"                                          # permanent
	. "not,enough\n"                                                            # malformed... field count
	. '10.0.0.4,junk,50' . "\n"                                                 # malformed... time
	. '10.0.0.5,' . $now . ',junk' . "\n"                                       # malformed... left
	. '010.0.0.7,' . $now . ',500' . "\n"                                       # will not normalize... leading zero octet
	. 'notanip,' . $now . ',500' . "\n"                                         # will not normalize... not an IP at all
	. "\n"                                                                      # blank
	. '10.0.0.6,' . $now . ',500' . "\n";                                       # good row after the junk
close($csv_fh);

my $loader = Ereshkigal::Kur->new( %common, 'name' => 'loader' );
$loader->{started} = time;
ok( defined( $loader->{bans}{'10.0.0.1'} ), 'live timed row restored' );
is( $loader->{bans}{'10.0.0.1'}{expires},   $now + 500, 'expiry reconstructed as time plus left' );
is( $loader->{bans}{'10.0.0.1'}{banned_at}, $now,       'the row time stands in for banned_at' );
ok( !defined( $loader->{bans}{'10.0.0.2'} ), 'expired while down row not restored' );
is( $loader->{stats}{expired},            1, 'and counted as expired' );
is( $loader->{bans}{'10.0.0.3'}{expires}, 0, 'permanent row stays permanent' );
ok( defined( $loader->{bans}{'10.0.0.6'} ), 'good row after malformed ones still loads' );

foreach my $bad ( '10.0.0.4', '10.0.0.5', 'not' ) {
	ok( !defined( $loader->{bans}{$bad} ), 'malformed row "' . $bad . '" skipped' );
}

# a row that will not normalize is skipped rather than booked raw... booking
# it raw would leave a ban the unban path could never name, as it normalizes
# whatever it is asked to remove
foreach my $bad ( '010.0.0.7', 'notanip' ) {
	ok( !defined( $loader->{bans}{$bad} ), 'un-normalizable row "' . $bad . '" not booked raw' );
}
is( $loader->{bans}{'10.0.0.7'}, undef, 'nor booked under a normalized form it never had' );
is_deeply(
	[ sort( @{ $loader->_cmd_banned->{banned} } ) ],
	[ '10.0.0.1', '10.0.0.3', '10.0.0.6' ],
	'restored rows re-banned into the fresh backend'
);

# after loading an updated CSV is written back out
$rows = read_ban_csv( $dir . '/cache/kur.loader.csv' );
is_deeply(
	[ sort( keys( %{$rows} ) ) ],
	[ '10.0.0.1', '10.0.0.3', '10.0.0.6' ],
	'the CSV was rewritten after load with just what got restored'
);

#
# status carries the checkpoint info
#

$result = $loader->_cmd_status;
is( $result->{checkpoint}, 60, 'status checkpoint' );
ok( $result->{last_checkpoint} > 0, 'status last_checkpoint' );

done_testing;
