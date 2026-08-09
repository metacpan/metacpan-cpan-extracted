#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;
use JSON::MaybeXS qw( decode_json );
use lib 't/lib';
use EreshkigalTest qw( test_dir socket_path_ok mock_server );

use Ereshkigal::App;

my $dir = test_dir();

# checks an invocation fails with a message matching the regex
sub usage_error_ok {
	my ( $argv, $regex, $test_name ) = @_;

	my $result = test_app( 'Ereshkigal::App' => $argv );
	isnt( $result->exit_code, 0, $test_name . '... nonzero exit' );
	my $combined = join( '', defined( $result->error ) ? $result->error : '', $result->stderr, $result->stdout );
	like( $combined, $regex, $test_name . '... message' );

	return;
} ## end sub usage_error_ok

#
# usage errors, no server needed
#

usage_error_ok( [ 'start',  'extra' ], qr/does not take any args/, 'start with stray args' );
usage_error_ok( [ 'stop',   'extra' ], qr/does not take any args/, 'stop with stray args' );
usage_error_ok( [ 'banned', 'extra' ], qr/does not take any args/, 'banned with stray args' );

usage_error_ok( [ 'status', 'a',     'b' ],    qr/at most one/,              'status with two args' );
usage_error_ok( [ 'status', '--all', 'sshd' ], qr/may not be used together/, 'status --all with a kur name' );

usage_error_ok( ['ban'], qr/at least one IP/, 'ban with no IPs' );

usage_error_ok( ['unban'], qr/either --all or a single IP/, 'unban with no args' );
usage_error_ok( [ 'unban', '--all',   '1.2.3.4' ], qr/may not be used together/,    'unban --all with an IP' );
usage_error_ok( [ 'unban', '1.2.3.4', '5.6.7.8' ], qr/either --all or a single IP/, 'unban with two IPs' );

usage_error_ok( ['cidr-ban'], qr/at least one CIDR/, 'cidr-ban with no CIDRs' );

usage_error_ok( ['cidr-unban'],                               qr/a single CIDR/, 'cidr-unban with no args' );
usage_error_ok( [ 'cidr-unban', '1.2.3.0/24', '10.0.0.0/8' ], qr/a single CIDR/, 'cidr-unban with two CIDRs' );

usage_error_ok( ['add'],             qr/single kur instance name/, 'add with no name' );
usage_error_ok( [ 'add', 'a', 'b' ], qr/single kur instance name/, 'add with two names' );
usage_error_ok(
	[ 'add', 'sshd' ],
	qr/either --backend or --fan-out must be specified/,
	'add with out --backend or --fan-out'
);
usage_error_ok(
	[ 'add', 'gate', '--backend', 'dummy', '--fan-out', 'sshd' ],
	qr/may not be used together/,
	'add with both --backend and --fan-out'
);
usage_error_ok(
	[ 'add', 'sshd', '--backend', 'dummy', '--option', 'bad-format' ],
	qr/not in the form key=value/,
	'add with a malformed --option'
);

usage_error_ok( ['remove'], qr/single kur instance name/, 'remove with no name' );

usage_error_ok( [ 'checkpoint', 'a', 'b' ], qr/at most one/, 'checkpoint with two args' );

usage_error_ok( [ 're-init', 'a', 'b' ], qr/at most one/, 're-init with two args' );

usage_error_ok( [ 'clear-retries', 'a', 'b' ], qr/at most one/, 'clear-retries with two args' );
usage_error_ok(
	[ 'clear-retries', '--ip', '1.2.3.4', '--cidr', '1.2.3.0/24' ],
	qr/may not be used together/,
	'clear-retries with both --ip and --cidr'
);

usage_error_ok( ['bogus'], qr/bogus/i, 'unknown subcommand' );

#
# --help works on every command, exits 0, and answers before validate_args
# gets to complain about missing args... it also has to agree with what the
# built in help command renders
#

foreach my $command (
	'status',        'banned', 'ban',    'unban',      'cidr-ban', 'cidr-unban',
	'clear-retries', 'add',    'remove', 'checkpoint', 'start',    'stop',
	're-init'
	)
{
	foreach my $flag ( '--help', '-h' ) {
		my $result = test_app( 'Ereshkigal::App' => [ $command, $flag ] );
		is( $result->exit_code, 0, $command . ' ' . $flag . ' exits 0' );
		like( $result->stdout, qr/\Q$command\E/,            $command . ' ' . $flag . ' names the command' );
		like( $result->stdout, qr/show this help and exit/, $command . ' ' . $flag . ' lists the help option' );
	}

	# the description is the point of the exercise... every command has to
	# carry more than a single terse line
	my $help = test_app( 'Ereshkigal::App' => [ 'help', $command ] );
	my @body = grep { /\S/ } split( /\n/, $help->stdout );
	cmp_ok( scalar(@body), '>=', 6, $command . ' help says more than a line or two' );

	my $flagged = test_app( 'Ereshkigal::App' => [ $command, '--help' ] );
	is( $flagged->stdout, $help->stdout, $command . ' --help agrees with help ' . $command );
} ## end foreach my $command ( 'status', 'banned', 'ban'...)

# the dangerous ones say so
foreach
	my $pair ( [ 'clear-retries', qr/BEWARE/ ], [ 'unban', qr/no confirmation/ ], [ 'stop', qr/stops being enforced/ ] )
{
	my $result = test_app( 'Ereshkigal::App' => [ $pair->[0], '--help' ] );
	like( $result->stdout, $pair->[1], $pair->[0] . ' help warns about what it does' );
}

# -s reaches the client for every client command
foreach my $command ( 'stop', 'status', 'banned' ) {
	usage_error_ok( [ '-s', $dir . '/nothere.sock', $command ], qr/Failed to connect/, $command . ' honors -s' );
}
usage_error_ok( [ '-s', $dir . '/nothere.sock', 'ban',   '1.2.3.4' ], qr/Failed to connect/, 'ban honors -s' );
usage_error_ok( [ '-s', $dir . '/nothere.sock', 'unban', '--all' ],   qr/Failed to connect/, 'unban honors -s' );
usage_error_ok(
	[ '-s', $dir . '/nothere.sock', 'cidr-ban', '1.2.3.0/24' ],
	qr/Failed to connect/,
	'cidr-ban honors -s'
);
usage_error_ok(
	[ '-s', $dir . '/nothere.sock', 'cidr-unban', '1.2.3.0/24' ],
	qr/Failed to connect/,
	'cidr-unban honors -s'
);
usage_error_ok( [ '-s', $dir . '/nothere.sock', 'remove', 'sshd' ], qr/Failed to connect/, 'remove honors -s' );
usage_error_ok( [ '-s', $dir . '/nothere.sock', 'checkpoint' ], qr/Failed to connect/, 'checkpoint honors -s' );
usage_error_ok(
	[ '-s', $dir . '/nothere.sock', 'add', 'sshd', '--backend', 'dummy' ],
	qr/Failed to connect/,
	'add honors -s'
);

#
# happy paths against a mock manager
#

SKIP: {
	skip 'temp dir path too long for a unix socket', 36 if !socket_path_ok($dir);
	skip 'unix sockets and fork required',           36 if $^O eq 'MSWin32';

	my $socket = $dir . '/mock.sock';
	my $echo   = sub {
		my ($request) = @_;
		return { 'status' => 'ok', 'result' => { 'command' => $request->{command}, 'args' => $request->{args} } };
	};
	mock_server(
		$socket,
		{
			'status'        => { 'status' => 'ok', 'result' => { 'pid' => 42, 'uptime' => 1, 'kurs' => {} } },
			'status_all'    => { 'status' => 'ok', 'result' => { 'all' => 1 } },
			'status_kur'    => $echo,
			'banned'        => { 'status' => 'ok', 'result' => { 'kurs' => { 'sshd' => { 'banned' => [] } } } },
			'ban'           => $echo,
			'unban'         => $echo,
			'cidr_ban'      => $echo,
			'cidr_unban'    => $echo,
			'add_kur'       => $echo,
			'remove_kur'    => { 'status' => 'error', 'error' => 'No such kur instance, "sshd"' },
			'checkpoint'    => $echo,
			'clear_retries' => $echo,
			're_init'       => $echo,
			'stop'          => { 'status' => 'ok', 'result' => { 'stopping' => 1 } },
		}
	);

	my @s = ( '-s', $socket );

	my $result = test_app( 'Ereshkigal::App' => [ @s, 'status' ] );
	is( $result->exit_code, 0, 'status exit 0' );
	is_deeply(
		decode_json( $result->stdout ),
		{ 'pid' => 42, 'uptime' => 1, 'kurs' => {} },
		'status prints the result as JSON'
	);

	$result = test_app( 'Ereshkigal::App' => [ @s, 'status', '--all' ] );
	is_deeply( decode_json( $result->stdout ), { 'all' => 1 }, 'status --all calls status_all' );

	$result = test_app( 'Ereshkigal::App' => [ @s, 'status', 'sshd' ] );
	my $decoded = decode_json( $result->stdout );
	is( $decoded->{command},    'status_kur', 'status with a name calls status_kur' );
	is( $decoded->{args}{name}, 'sshd',       'status passes the name' );

	$result = test_app( 'Ereshkigal::App' => [ @s, 'banned' ] );
	is( $result->exit_code, 0, 'banned exit 0' );
	is_deeply(
		decode_json( $result->stdout ),
		{ 'kurs' => { 'sshd' => { 'banned' => [] } } },
		'banned prints the result'
	);

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'ban', '1.2.3.4', '5.6.7.8' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command}, 'ban', 'ban calls ban' );
	is_deeply( $decoded->{args}{ips}, [ '1.2.3.4', '5.6.7.8' ], 'ban passes the IPs' );
	ok( !defined( $decoded->{args}{kur} ), 'ban with out --kur sends no kur' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'ban', '--kur', 'sshd', '1.2.3.4' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{kur}, 'sshd', 'ban passes --kur' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'ban', '--ban-time', '30', '1.2.3.4' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{ban_time}, 30, 'ban passes --ban-time' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'ban', '1.2.3.4' ] );
	$decoded = decode_json( $result->stdout );
	ok( !defined( $decoded->{args}{ban_time} ), 'ban with out --ban-time sends no ban_time' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'unban', '1.2.3.4' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{ip}, '1.2.3.4', 'unban passes the IP' );
	ok( !$decoded->{args}{all}, 'unban with an IP does not send all' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'unban', '--all' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{all}, 1, 'unban --all sends all' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'cidr-ban', '1.2.3.0/24', '10.0.0.0/8' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command}, 'cidr_ban', 'cidr-ban calls cidr_ban' );
	is_deeply( $decoded->{args}{cidrs}, [ '1.2.3.0/24', '10.0.0.0/8' ], 'cidr-ban passes the CIDRs' );
	ok( !defined( $decoded->{args}{kur} ), 'cidr-ban with out --kur sends no kur' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'cidr-ban', '--kur', 'sshd', '--ban-time', '30', '1.2.3.0/24' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{kur},      'sshd', 'cidr-ban passes --kur' );
	is( $decoded->{args}{ban_time}, 30,     'cidr-ban passes --ban-time' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'cidr-unban', '1.2.3.0/24' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command},    'cidr_unban', 'cidr-unban calls cidr_unban' );
	is( $decoded->{args}{cidr}, '1.2.3.0/24', 'cidr-unban passes the CIDR' );

	$result = test_app(
		'Ereshkigal::App' => [
			@s,        'add',          'dns', '--backend', 'dummy', '--ports',
			'53,5353', '--protocols',  'udp', '--option',  'a=1',   '--option',
			'b=2',     '--self-heal',  '0',   '--prefix',  'foo',   '--ban-time',
			'300',     '--checkpoint', '30',
		]
	);
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command},    'add_kur', 'add calls add_kur' );
	is( $decoded->{args}{name}, 'dns',     'add passes the name' );
	is_deeply(
		$decoded->{args}{opts},
		{
			'backend'    => 'dummy',
			'ports'      => [ '53', '5353' ],
			'protocols'  => ['udp'],
			'options'    => { 'a' => '1', 'b' => '2' },
			'self_heal'  => 0,
			'prefix'     => 'foo',
			'ban_time'   => 300,
			'checkpoint' => 30,
		},
		'add passes the full def through'
	);

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'add', 'gate', '--fan-out', 'sshd,smtp' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{name}, 'gate', 'add --fan-out passes the name' );
	is_deeply( $decoded->{args}{opts}, { 'fan_out' => [ 'sshd', 'smtp' ] }, 'add --fan-out passes the member list' );

	$result = test_app( 'Ereshkigal::App' => [ @s, 'remove', 'sshd' ] );
	isnt( $result->exit_code, 0, 'an error response exits nonzero' );
	my $combined = join( '', defined( $result->error ) ? $result->error : '', $result->stderr );
	like( $combined, qr/No such kur instance/, 'the error message is shown' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'checkpoint' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command}, 'checkpoint', 'checkpoint calls checkpoint' );
	ok( !defined( $decoded->{args} ), 'checkpoint with out a name sends no args' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'checkpoint', 'sshd' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{kur}, 'sshd', 'checkpoint passes the kur name' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 're-init' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command}, 're_init', 're-init calls re_init' );
	ok( !defined( $decoded->{args} ), 're-init with out a name sends no args' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 're-init', 'sshd' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{kur}, 'sshd', 're-init passes the kur name' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'clear-retries' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{command}, 'clear_retries', 'clear-retries calls clear_retries' );
	ok( !defined( $decoded->{args} ), 'clear-retries with nothing named sends no args' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'clear-retries', 'sshd', '--ip', '1.2.3.4' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{kur}, 'sshd',    'clear-retries passes the kur name' );
	is( $decoded->{args}{ip},  '1.2.3.4', 'clear-retries passes --ip' );

	$result  = test_app( 'Ereshkigal::App' => [ @s, 'clear-retries', '--cidr', '1.2.3.0/24' ] );
	$decoded = decode_json( $result->stdout );
	is( $decoded->{args}{cidr}, '1.2.3.0/24', 'clear-retries passes --cidr' );

	$result = test_app( 'Ereshkigal::App' => [ @s, 'stop' ] );
	is( $result->exit_code, 0, 'stop exit 0' );
	is_deeply( decode_json( $result->stdout ), { 'stopping' => 1 }, 'stop prints the result' );
} ## end SKIP:

done_testing;
