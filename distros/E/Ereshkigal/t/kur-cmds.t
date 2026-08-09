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

my $kur = Ereshkigal::Kur->new(
	'name'           => 'testy',
	'backend'        => 'dummy',
	'ports'          => ['22'],
	'protocols'      => ['tcp'],
	'run_base_dir'   => $dir . '/run',
	'cache_base_dir' => $dir . '/cache',
);
$kur->{started} = time;

# hide the Error::Helper warn noise from the error path tests
local *STDERR;
open( STDERR, '>', \my $stderr_capture );

#
# ban
#

my $result = $kur->_cmd_ban( { 'args' => { 'ips' => [ '1.2.3.4', '5.6.7.8' ] } } );
is( $result->{ips}{'1.2.3.4'}{status}, 'ok', 'ban of 1.2.3.4 ok' );
is( $result->{ips}{'5.6.7.8'}{status}, 'ok', 'ban of 5.6.7.8 ok' );
is( $kur->{stats}{bans},               2,    'stats bans is 2' );

$result = $kur->_cmd_banned;
is_deeply( [ sort( @{ $result->{banned} } ) ], [ '1.2.3.4', '5.6.7.8' ], 'banned lists both IPs' );

# invalid IPs error per IP with out killing the valid ones in the same request
$result = $kur->_cmd_ban( { 'args' => { 'ips' => [ 'not-an-ip', '9.9.9.9' ] } } );
is( $result->{ips}{'not-an-ip'}{status}, 'error', 'invalid IP errors' );
like( $result->{ips}{'not-an-ip'}{error}, qr/does not appear to be an IPv4 or IPv6 IP/, 'invalid IP error message' );
is( $result->{ips}{'9.9.9.9'}{status}, 'ok', 'valid IP in the same request still banned' );
is( $kur->{stats}{errors},             1,    'stats errors bumped' );
is( $kur->{stats}{bans},               3,    'stats bans now 3' );

throws_ok { $kur->_cmd_ban( {} ) } qr/args\.ips/, 'dies with out args';
throws_ok { $kur->_cmd_ban( { 'args' => { 'ips' => [] } } ) } qr/args\.ips/, 'dies on empty ips';
throws_ok { $kur->_cmd_ban( { 'args' => { 'ips' => 'x' } } ) } qr/args\.ips/, 'dies on non-array ips';

#
# unban
#

$result = $kur->_cmd_unban( { 'args' => { 'ip' => '1.2.3.4' } } );
is( $result->{was_banned}, 1,         'unban of a present IP reports was_banned 1' );
is( $result->{ip},         '1.2.3.4', 'unban reports the IP back' );
is( $kur->{stats}{unbans}, 1,         'stats unbans is 1' );

$result = $kur->_cmd_banned;
is( ( grep { $_ eq '1.2.3.4' } @{ $result->{banned} } ), 0, 'unbanned IP gone from the banned list' );

$result = $kur->_cmd_unban( { 'args' => { 'ip' => '1.2.3.4' } } );
is( $result->{was_banned}, 0, 'unban of an absent IP reports was_banned 0' );
is( $kur->{stats}{unbans}, 1, 'stats unbans unchanged for an absent IP' );

throws_ok { $kur->_cmd_unban( {} ) } qr/args\.ip/, 'dies with out args';
throws_ok { $kur->_cmd_unban( { 'args' => { 'ip' => ['1.2.3.4'] } } ) } qr/args\.ip/, 'dies on a ref for ip';

#
# IPv6 normalization... long form, short form, and case variants of the
# same IP must all land on the same ban entry
#

$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['2001:0DB8:0000:0000:0000:0000:0000:0001'] } } );
is( $result->{ips}{'2001:db8::1'}{status}, 'ok', 'long form IPv6 banned under its short form' );
is( $kur->{stats}{bans},                   4,    'stats bans bumped for the IPv6 ban' );

$result = $kur->_cmd_banned;
is( ( grep { $_ eq '2001:db8::1' } @{ $result->{banned} } ), 1, 'banned lists the IPv6 IP in short form' );

$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['2001:db8:0:0::1'] } } );
is( $result->{ips}{'2001:db8::1'}{refreshed}, 1, 'differently spelled rebans just refresh the existing ban' );
is( $kur->{stats}{bans},                      4, 'stats bans unchanged for the refresh' );

$result = $kur->_cmd_unban( { 'args' => { 'ip' => '2001:0db8::0001' } } );
is( $result->{was_banned}, 1,             'unban via a variant spelling finds the ban' );
is( $result->{ip},         '2001:db8::1', 'unban reports the IP back in short form' );

$result = $kur->_cmd_banned;
is( ( grep { $_ eq '2001:db8::1' } @{ $result->{banned} } ), 0, 'IPv6 IP gone from the banned list' );

# leading zero octet IPv4 is ambiguous, octal vs decimal wise, so it is
# refused here rather than reaching the backend, which would accept it
$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['010.0.0.1'] } } );
is( $result->{ips}{'010.0.0.1'}{status}, 'error', 'leading zero octet IPv4 refused' );

throws_ok { $kur->_cmd_unban( { 'args' => { 'ip' => 'not-an-ip' } } ) } qr/does not appear to be an IPv4 or IPv6 IP/,
	'unban of an invalid IP dies';

#
# status
#

$result = $kur->_cmd_status;
is( $result->{name},    'testy', 'status name' );
is( $result->{backend}, 'dummy', 'status backend' );
is( $result->{pid},     $$,      'status pid' );
ok( $result->{uptime} >= 0, 'status uptime' );
is( $result->{banned_count}, 2, 'status banned_count tracks bans/unbans' );
is_deeply( $result->{stats},     $kur->{stats}, 'status stats' );
is_deeply( $result->{ports},     ['22'],        'status ports' );
is_deeply( $result->{protocols}, ['tcp'],       'status protocols' );

#
# flush
#

$result = $kur->_cmd_flush;
is( $result->{flushed}, 1, 'flush response' );
$result = $kur->_cmd_banned;
is_deeply( $result->{banned}, [], 'banned empty after flush' );
$result = $kur->_cmd_ban( { 'args' => { 'ips' => ['3.3.3.3'] } } );
is( $result->{ips}{'3.3.3.3'}{status}, 'ok', 'bans still work after flush' );

#
# re_init
#

$result = $kur->_cmd_re_init;
is( $result->{re_init}, 1, 're_init response' );
$result = $kur->_cmd_banned;
is_deeply( $result->{banned}, ['3.3.3.3'], 'previously banned IPs still listed after re_init' );

#
# _backend_do error propagation... Error::Helper may just warn instead of
# dieing, so _backend_do has to check the error state its self
#

throws_ok { $kur->_backend_do('ban') } qr/Nothing specified for the value ban/,
	'_backend_do dies on a backend error even when the backend just warns';

#
# unban of a non-canonical spelling the backend book carries... the state
# restore path can seed the book with spellings the backend accepts but
# normalization refuses, and those have to still be findable via the
# canonical form
#

$kur->{backend_obj}->ban( 'ban' => '2001:DB8:0:0:0:0:0:99' );
$kur->{bans}{'2001:db8::99'} = { 'banned_at' => time, 'expires' => 0 };
$result = $kur->_cmd_unban( { 'args' => { 'ip' => '2001:db8::99' } } );
is( $result->{was_banned}, 1, 'non-canonical backend book entry found via the canonical form' );
is( ( grep { $_ =~ /99/ } @{ $kur->_cmd_banned->{banned} } ), 0, 'and the backend book entry is gone' );

#
# stopping refuses backend-mutating commands
#

$kur->{stopping} = 1;
throws_ok { $kur->_cmd_ban( { 'args' => { 'ips' => ['4.4.4.4'] } } ) } qr/stopping/, 'ban refused while stopping';
throws_ok { $kur->_cmd_unban( { 'args' => { 'ip' => '3.3.3.3' } } ) } qr/stopping/, 'unban refused while stopping';
throws_ok { $kur->_cmd_flush } qr/stopping/, 'flush refused while stopping';
throws_ok { $kur->_cmd_re_init } qr/stopping/, 're_init refused while stopping';
$kur->{stopping} = 0;

done_testing;
