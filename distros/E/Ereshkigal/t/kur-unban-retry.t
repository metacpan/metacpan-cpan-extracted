#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use EreshkigalTest qw( test_dir );

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

# wrap _backend_do so unban failures can be forced and the methods that
# actually reach the backend recorded
my $fail_unban = 0;
my @backend_calls;
my $orig_backend_do = \&Ereshkigal::Kur::_backend_do;
{
	no warnings 'redefine';
	*Ereshkigal::Kur::_backend_do = sub {
		my ( $self, $method, @args ) = @_;
		push( @backend_calls, $method );
		if ( $fail_unban && ( $method eq 'unban' || $method eq 'unban_cidr' ) ) {
			die("unban forced to fail\n");
		}
		return $orig_backend_do->( $self, $method, @args );
	};
}

my $kur = Ereshkigal::Kur->new( %common, 'name' => 'testy', 'enable_cidr' => 1 );
$kur->{started} = time;

#
# a failed unban at expiry lands in the retry HoH and the ban still expires
#

$kur->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'] } } );
$kur->{bans}{'1.2.3.4'}{expires} = time - 5;

$fail_unban = 1;
my $before = time;
$kur->_sweep_bans;

ok( !defined( $kur->{bans}{'1.2.3.4'} ), 'expired ban dropped from the book despite the unban failing' );
my $retry = $kur->{unban_retries}{'1.2.3.4'};
ok( defined($retry), 'failed unban tracked for retry' );
is( $retry->{times_tried}, 1, 'first try counted' );
ok( $retry->{first_tried} >= $before && $retry->{first_tried} <= time, 'first_tried recorded' );
is( $retry->{last_tried}, $retry->{first_tried}, 'last_tried matches first_tried on the first failure' );
ok( $retry->{next_try} > $retry->{last_tried}, 'next_try scheduled in the future' );
is( $retry->{delay}, 2, 'backoff doubled for the next failure' );

#
# a due retry that fails again backs off further
#

$retry->{next_try} = time - 1;
$before = time;
$kur->_sweep_bans;

is( $retry->{times_tried}, 2, 'second try counted' );
ok( $retry->{last_tried} >= $before && $retry->{last_tried} <= time, 'last_tried updated' );
ok( $retry->{next_try} >= $before + 2,                               'next_try honors the previous delay' );
is( $retry->{delay}, 4, 'backoff doubled again' );

#
# the backoff caps at 60
#

$retry->{next_try} = time - 1;
$retry->{delay}    = 40;
$kur->_sweep_bans;
is( $retry->{delay}, 60, 'backoff capped at 60' );
$retry->{next_try} = time - 1;
$kur->_sweep_bans;
is( $retry->{delay}, 60, 'backoff stays at the cap' );

#
# a due retry that succeeds clears the entry
#

$retry->{next_try} = time - 1;
$fail_unban = 0;
$kur->_sweep_bans;
ok( !defined( $kur->{unban_retries}{'1.2.3.4'} ), 'successful retry cleared' );

#
# re-banning something pending a retry cancels the retry with out asking the
# backend to re-add what it already carries
#

$kur->_cmd_ban( { 'args' => { 'ips' => ['5.6.7.8'] } } );
$kur->{bans}{'5.6.7.8'}{expires} = time - 5;
$fail_unban = 1;
$kur->_sweep_bans;
ok( defined( $kur->{unban_retries}{'5.6.7.8'} ), 'retry pending for the re-ban check' );

@backend_calls = ();
my $result = $kur->_cmd_ban( { 'args' => { 'ips' => ['5.6.7.8'] } } );
is( $result->{ips}{'5.6.7.8'}{status}, 'ok', 're-ban of a pending retry is ok' );
ok( !defined( $kur->{unban_retries}{'5.6.7.8'} ), 're-ban cancelled the pending retry' );
ok( defined( $kur->{bans}{'5.6.7.8'} ),           're-ban booked' );
ok( !grep { $_ eq 'ban' } @backend_calls,         'backend not asked to re-add what it already carries' );

#
# a hand unban while the backend is still refusing leaves the retry pending,
# as it fails against that same backend... it only clears once the backend
# takes it, which is what the retry loop is for
#

$kur->_cmd_ban( { 'args' => { 'ips' => ['4.4.4.4'] } } );
$kur->{bans}{'4.4.4.4'}{expires} = time - 5;
$fail_unban = 1;
$kur->_sweep_bans;
my $pending = $kur->{unban_retries}{'4.4.4.4'};
ok( defined($pending), 'retry pending for the hand unban check' );

my $tries_before = $pending->{times_tried};
eval { $kur->_cmd_unban( { 'args' => { 'ip' => '4.4.4.4' } } ) };
ok( $@, 'a hand unban fails while the backend is refusing' );
is( $kur->{unban_retries}{'4.4.4.4'}, $pending,      'the failed hand unban left the retry pending' );
is( $pending->{times_tried},          $tries_before, 'a failed hand unban does not disturb the retry book keeping' );

$fail_unban = 0;
$kur->_cmd_unban( { 'args' => { 'ip' => '4.4.4.4' } } );
ok( !defined( $kur->{unban_retries}{'4.4.4.4'} ), 'a hand unban clears the retry once the backend takes it' );

#
# the CIDR family retries the same way
#

$kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['10.0.0.0/24'] } } );
$kur->{cidr_bans}{'10.0.0.0/24'}{expires} = time - 5;
$fail_unban = 1;
$kur->_sweep_bans;
ok( defined( $kur->{cidr_unban_retries}{'10.0.0.0/24'} ), 'failed CIDR unban tracked for retry' );
$kur->{cidr_unban_retries}{'10.0.0.0/24'}{next_try} = time - 1;
$fail_unban = 0;
$kur->_sweep_bans;
ok( !defined( $kur->{cidr_unban_retries}{'10.0.0.0/24'} ), 'successful CIDR retry cleared' );

#
# flush drops pending retries
#

$kur->_cmd_ban( { 'args' => { 'ips' => ['9.9.9.9'] } } );
$kur->{bans}{'9.9.9.9'}{expires} = time - 5;
$fail_unban = 1;
$kur->_sweep_bans;
ok( defined( $kur->{unban_retries}{'9.9.9.9'} ), 'retry pending for the flush check' );
$fail_unban = 0;
$kur->_cmd_flush;
ok( !defined( $kur->{unban_retries}{'9.9.9.9'} ), 'flush cleared the pending retry' );

#
# the retry tablet... an owed unban survives a restart with it's counts and
# backoff intact, as the firewall is owed it just as much after one
#

my $tablet_kur = Ereshkigal::Kur->new( %common, 'name' => 'tablety', 'enable_cidr' => 1 );
$tablet_kur->{started} = time;

is( $tablet_kur->retry_state_path,      $dir . '/cache/kur.tablety.retry.csv',      'retry_state_path' );
is( $tablet_kur->cidr_retry_state_path, $dir . '/cache/kur.tablety.cidr.retry.csv', 'cidr_retry_state_path' );
ok( !-e $tablet_kur->retry_state_path, 'nothing owed means no tablet on disk' );

$tablet_kur->_cmd_ban( { 'args' => { 'ips' => ['7.7.7.7'] } } );
$tablet_kur->{bans}{'7.7.7.7'}{expires} = time - 5;
$tablet_kur->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['172.16.0.0/12'] } } );
$tablet_kur->{cidr_bans}{'172.16.0.0/12'}{expires} = time - 5;
$fail_unban = 1;
$tablet_kur->_sweep_bans;

ok( -f $tablet_kur->retry_state_path,           'an owed unban wrote the retry tablet' );
ok( -f $tablet_kur->cidr_retry_state_path,      'and the CIDR one for the CIDR side' );
ok( !-e $tablet_kur->retry_state_path . '.tmp', 'no temp file left behind' );

# age the entry so the restore has something distinctive to carry over
my $owed = $tablet_kur->{unban_retries}{'7.7.7.7'};
$owed->{first_tried} = time - 900;
$owed->{times_tried} = 9;
$owed->{delay}       = 60;
$tablet_kur->_checkpoint_retries;

open( my $tablet_fh, '<', $tablet_kur->retry_state_path ) || die($!);
my @tablet_lines = <$tablet_fh>;
close($tablet_fh);
like( $tablet_lines[0], qr/^ip,first_tried,last_tried,times_tried,next_try,delay\n/, 'the retry header row' );
like( $tablet_lines[1], qr/^7\.7\.7\.7,/,                                            'the owed entry is a row' );

my $restored = Ereshkigal::Kur->new( %common, 'name' => 'tablety', 'enable_cidr' => 1 );
$restored->{started} = time;
my $back = $restored->{unban_retries}{'7.7.7.7'};
ok( defined($back), 'the owed unban came back' );
is( $back->{times_tried}, 9,                    'times_tried carried over' );
is( $back->{delay},       60,                   'the backoff carried over rather than starting fresh' );
is( $back->{first_tried}, $owed->{first_tried}, 'first_tried carried over' );
ok( defined( $restored->{cidr_unban_retries}{'172.16.0.0/12'} ), 'the CIDR side came back too' );

# a due one still owed is retried after the restart like any other
$restored->{unban_retries}{'7.7.7.7'}{next_try} = time - 1;
$fail_unban = 0;
$restored->_sweep_bans;
ok( !defined( $restored->{unban_retries}{'7.7.7.7'} ), 'the restored retry landed' );
ok( !-e $restored->retry_state_path,                   'and the tablet was removed once nothing was owed' );

# a row that will not parse or normalize is skipped rather than restored
open( my $bad_fh, '>', $dir . '/cache/kur.badtablet.retry.csv' ) || die($!);
print $bad_fh "ip,first_tried,last_tried,times_tried,next_try,delay\n" . '8.8.8.8,1,2,3,4,5' . "\n"    # good
	. "short,1,2,3\n"                                                                                  # malformed... field count
	. '9.9.9.9,1,2,junk,4,5' . "\n"                                                                    # malformed... non numeric
	. '010.0.0.1,1,2,3,4,5' . "\n"                                                                     # will not normalize
	. '1.1.1.1,1,2,3,4,0' . "\n";                                                                      # a 0 delay would peg the backoff
close($bad_fh);
my $bad_tablet = Ereshkigal::Kur->new( %common, 'name' => 'badtablet' );
$bad_tablet->{started} = time;
ok( defined( $bad_tablet->{unban_retries}{'8.8.8.8'} ), 'the good row restored' );

foreach my $bad ( 'short', '9.9.9.9', '010.0.0.1', '10.0.0.1' ) {
	ok( !defined( $bad_tablet->{unban_retries}{$bad} ), 'bad retry row "' . $bad . '" skipped' );
}
is( $bad_tablet->{unban_retries}{'1.1.1.1'}{delay}, 2, 'a 0 delay is floored rather than pegging the backoff' );

# only the backoff's own doubling is clamped, so a restored delay has to be
# brought inside the cap here or one bad row puts the next attempt days out
open( my $wild_fh, '>', $dir . '/cache/kur.wildtablet.retry.csv' ) || die($!);
print $wild_fh "ip,first_tried,last_tried,times_tried,next_try,delay\n"
	. '8.8.4.4,1,2,3,4,999999' . "\n"
	. '8.8.8.8,1,2,3,4,60' . "\n"
	. '4.4.4.4,1,2,3,4,30' . "\n";
close($wild_fh);
my $wild_tablet = Ereshkigal::Kur->new( %common, 'name' => 'wildtablet' );
$wild_tablet->{started} = time;
is( $wild_tablet->{unban_retries}{'8.8.4.4'}{delay}, 60, 'a delay past the cap is brought back to it' );
is( $wild_tablet->{unban_retries}{'8.8.8.8'}{delay}, 60, 'a delay at the cap is left alone' );
is( $wild_tablet->{unban_retries}{'4.4.4.4'}{delay}, 30, 'a delay under the cap is left alone' );

#
# status and banned surface what is owed
#

my $shown = Ereshkigal::Kur->new( %common, 'name' => 'showy', 'enable_cidr' => 1 );
$shown->{started} = time;

my $status = $shown->_cmd_status;
is( $status->{unban_retries},        0, 'status reports nothing owed' );
is( $status->{unban_retries_oldest}, 0, 'and no oldest' );
is( $status->{cidr_unban_retries},   0, 'nor on the CIDR side' );
is_deeply( $shown->_cmd_banned->{unban_retries}, {}, 'banned carries an empty retry hash' );

$shown->_cmd_ban( { 'args' => { 'ips' => [ '5.5.5.5', '6.6.6.6' ] } } );
$shown->{bans}{$_}{expires} = time - 5 foreach ( '5.5.5.5', '6.6.6.6' );
$fail_unban = 1;
my $swept_at = time;
$shown->_sweep_bans;
$shown->{unban_retries}{'5.5.5.5'}{first_tried} = $swept_at - 600;

$status = $shown->_cmd_status;
is( $status->{unban_retries},        2,               'status counts what is owed' );
is( $status->{unban_retries_oldest}, $swept_at - 600, 'status reports the longest owed' );

my $listed = $shown->_cmd_banned->{unban_retries};
is_deeply( [ sort( keys( %{$listed} ) ) ], [ '5.5.5.5', '6.6.6.6' ], 'banned lists every owed unban' );
is( $listed->{'6.6.6.6'}{times_tried}, 1, 'banned carries times_tried' );
ok( defined( $listed->{'6.6.6.6'}{next_try} ) && defined( $listed->{'6.6.6.6'}{last_tried} ),
	'banned carries the times' );
# the firewall really does still carry it, that being why the unban is owed,
# so it stays in the banned list... the book is what it left, not the firewall
is_deeply(
	[ sort( @{ $shown->_cmd_banned->{banned} } ) ],
	[ '5.5.5.5', '6.6.6.6' ],
	'an owed unban is still listed as banned, the firewall not having let go of it'
);
is_deeply( $shown->{bans}, {}, 'while the ban book has released it' );

#
# clear_retries
#

$shown->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['192.168.0.0/16'] } } );
$shown->{cidr_bans}{'192.168.0.0/16'}{expires} = time - 5;
$shown->_sweep_bans;
is( scalar( keys( %{ $shown->{cidr_unban_retries} } ) ), 1, 'a CIDR is owed for the clear tests' );

# a single named IP clears just it, and leaves the other family alone
$result = $shown->_cmd_clear_retries( { 'args' => { 'ip' => '5.5.5.5' } } );
is( $result->{cleared},      1, 'clearing one IP reports one cleared' );
is( $result->{cleared_ip},   1, 'under cleared_ip' );
is( $result->{cleared_cidr}, 0, 'and nothing on the CIDR side' );
ok( !defined( $shown->{unban_retries}{'5.5.5.5'} ),            'the named one is gone' );
ok( defined( $shown->{unban_retries}{'6.6.6.6'} ),             'the other IP is untouched' );
ok( defined( $shown->{cidr_unban_retries}{'192.168.0.0/16'} ), 'the CIDR side is untouched' );

# clearing one that is not owed is not an error, it just clears nothing
is( $shown->_cmd_clear_retries( { 'args' => { 'ip' => '5.5.5.5' } } )->{cleared},
	0, 'clearing an IP that is not owed clears nothing' );

# a named CIDR clears just it
$result = $shown->_cmd_clear_retries( { 'args' => { 'cidr' => '192.168.0.0/16' } } );
is( $result->{cleared_cidr}, 1, 'clearing one CIDR reports it' );
ok( !defined( $shown->{cidr_unban_retries}{'192.168.0.0/16'} ), 'the named CIDR is gone' );
ok( defined( $shown->{unban_retries}{'6.6.6.6'} ),              'and the IP side untouched' );

throws_ok { $shown->_cmd_clear_retries( { 'args' => { 'ip' => 'notanip' } } ) }
qr/does not appear to be an IPv4 or IPv6 IP/, 'an invalid ip is refused';
throws_ok { $shown->_cmd_clear_retries( { 'args' => { 'cidr' => 'notacidr' } } ) }
qr/does not appear to be an IPv4 or IPv6 CIDR/, 'an invalid cidr is refused';
throws_ok { $shown->_cmd_clear_retries( { 'args' => { 'ip' => '1.2.3.4', 'cidr' => '1.2.3.0/24' } } ) }
qr/only one of/, 'naming both an ip and a cidr is refused';

# with nothing named the lot goes, both families
$shown->_cmd_cidr_ban( { 'args' => { 'cidrs' => ['10.0.0.0/8'] } } );
$shown->{cidr_bans}{'10.0.0.0/8'}{expires} = time - 5;
$shown->_sweep_bans;
$result = $shown->_cmd_clear_retries( {} );
is( $result->{cleared}, 2, 'clearing with nothing named clears both families' );
is_deeply( $shown->{unban_retries},      {}, 'the IP side is empty' );
is_deeply( $shown->{cidr_unban_retries}, {}, 'the CIDR side is empty' );
ok( !-e $shown->retry_state_path, 'and the tablet is gone' );

#
# a clean stop pays what was owed... teardown takes the whole setup with it,
# so the debts go rather than being replayed by the next run
#

my $stopper = Ereshkigal::Kur->new( %common, 'name' => 'stopper' );
$stopper->{started} = time;
$stopper->_cmd_ban( { 'args' => { 'ips' => ['3.3.3.3'] } } );
$stopper->{bans}{'3.3.3.3'}{expires} = time - 5;
$fail_unban = 1;
$stopper->_sweep_bans;
ok( -f $stopper->retry_state_path, 'a debt is owed going into the stop' );

$fail_unban = 0;
$stopper->_stop_guts;
is_deeply( $stopper->{unban_retries}, {}, 'a clean teardown paid what was owed' );
ok( !-e $stopper->retry_state_path, 'and took the tablet with it' );

# a teardown that failed may well have left the rules there, so the debt stays
my $stuck = Ereshkigal::Kur->new( %common, 'name' => 'stuck' );
$stuck->{started} = time;
$stuck->_cmd_ban( { 'args' => { 'ips' => ['2.2.2.2'] } } );
$stuck->{bans}{'2.2.2.2'}{expires} = time - 5;
$fail_unban = 1;
$stuck->_sweep_bans;

my $fail_teardown = 1;
{
	no warnings 'redefine';
	local *Ereshkigal::Kur::_backend_do = sub {
		my ( $self, $method, @args ) = @_;
		die("teardown forced to fail\n") if ( $fail_teardown && $method eq 'teardown' );
		return $orig_backend_do->( $self, $method, @args );
	};
	ok( $stuck->_stop_guts, 'the teardown failed' );
}
ok( defined( $stuck->{unban_retries}{'2.2.2.2'} ), 'a failed teardown keeps the debt' );
ok( -f $stuck->retry_state_path,                   'and leaves the tablet in place' );

done_testing;
