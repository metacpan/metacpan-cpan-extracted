#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';
use EreshkigalTest qw( test_dir );

use Ereshkigal;

my $dir = test_dir();

my $config_count = 0;

sub write_cfg {
	my ($content) = @_;
	$config_count++;
	my $path = $dir . '/cfg' . $config_count . '.toml';
	open( my $fh, '>', $path ) || die($!);
	print $fh $content;
	close($fh);
	return $path;
}

# hide the Error::Helper warn noise
local *STDERR;
open( STDERR, '>', \my $stderr_capture );

#
# config error paths
#

throws_ok { Ereshkigal->new( 'config' => $dir . '/nothere.toml' ) } qr/Failed to open the config/,
	'dies on a missing config file';

throws_ok { Ereshkigal->new( 'config' => write_cfg('kur = [broken') ) } qr/Failed to parse the config/,
	'dies on invalid TOML';

throws_ok { Ereshkigal->new( 'config' => write_cfg('kur = "a string"') ) } qr/defined but not a hash/,
	'dies when kur is not a hash';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.sshd]\nports = [ "22" ]\n)) )
}
qr/lacks a backend/, 'dies when a kur def lacks a backend';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur."bad.name"]\nbackend = "dummy"\n)) )
}
qr/does not match/, 'dies on an invalid kur name';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq(socket_group = "nosuchgroupzzz"\n)) )
}
qr/Failed to resolve the socket group/, 'dies on an unknown socket_group';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq(ban_time = "abc"\n)) )
}
qr/ban_time/, 'dies on a non-int top level ban_time';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.sshd]\nbackend  = "dummy"\nban_time = "abc"\n)) )
}
qr/ban_time for the kur/, 'dies on a non-int kur ban_time';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq(checkpoint = "abc"\n)) )
}
qr/checkpoint/, 'dies on a non-int top level checkpoint';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.sshd]\nbackend    = "dummy"\ncheckpoint = "abc"\n)) )
}
qr/checkpoint for the kur/, 'dies on a non-int kur checkpoint';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq(authed_users = "zane"\n)) )
}
qr/authed_users is not an array/, 'dies on a non-array top level authed_users';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq(authed_groups = "wheel"\n)) )
}
qr/authed_groups is not an array/, 'dies on a non-array top level authed_groups';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.sshd]\nbackend      = "dummy"\nauthed_users = "zane"\n)) )
}
qr/authed_users for the kur/, 'dies on a non-array kur authed_users';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.sshd]\nbackend       = "dummy"\nauthed_groups = "wheel"\n)) )
}
qr/authed_groups for the kur/, 'dies on a non-array kur authed_groups';

#
# defaults
#

# run_base_dir has to be set as new creates the run dirs, which will not
# work for the default of /var/run/ereshkigal when unprivileged
my $minimal = write_cfg( 'run_base_dir = "' . $dir . '/defrun"' . "\n" . qq([kur.sshd]\nbackend = "dummy"\n) );
my $ereshkigal;
lives_ok { $ereshkigal = Ereshkigal->new( 'config' => $minimal ) } 'new lives on a minimal config';
is( $ereshkigal->{socket_mode}, 0660,  'socket_mode defaults to 0660' );
is( $ereshkigal->{timeout},     30,    'timeout defaults to 30' );
is( $ereshkigal->{kur_bin},     'kur', 'kur_bin defaults to kur' );
is( $ereshkigal->{ban_time},    600,   'ban_time defaults to 600' );
is( $ereshkigal->{checkpoint},  60,    'checkpoint defaults to 60' );
ok( !$ereshkigal->{enable_auth},      'enable_auth defaults to off' );
ok( !$ereshkigal->{enable_cidr},      'enable_cidr defaults to off' );
ok( !$ereshkigal->{cidr_silent_drop}, 'cidr_silent_drop defaults to off' );
is_deeply( $ereshkigal->{authed_users},  [], 'authed_users defaults to empty' );
is_deeply( $ereshkigal->{authed_groups}, [], 'authed_groups defaults to empty' );
is( $ereshkigal->{socket_gid}, ( getpwnam('root') )[3], 'socket_gid defaults to the default group of root' );
ok( -d $dir . '/defrun/kur', 'new created the run dirs' );

#
# settings merge and kur parsing
#

my $group = getgrgid( ( split( /\s+/, $( ) )[0] );

my $full
	= write_cfg( 'run_base_dir   = "'
		. $dir . '/run"' . "\n"
		. 'cache_base_dir = "'
		. $dir
		. '/cache"' . "\n"
		. 'socket_group   = "'
		. $group . '"' . "\n"
		. 'socket_mode    = "0640"' . "\n"
		. 'kur_bin        = "/somewhere/kur"' . "\n"
		. 'timeout        = 5' . "\n"
		. 'ban_time       = 120' . "\n"
		. 'checkpoint     = 90' . "\n"
		. 'enable_cidr    = true' . "\n"
		. 'enable_auth    = true' . "\n"
		. 'auth_temp_dir  = "/tmp"' . "\n"
		. 'authed_users   = [ "zane" ]' . "\n"
		. 'authed_groups  = [ "'
		. $group . '" ]' . "\n\n"
		. '[kur.sshd]' . "\n"
		. 'backend   = "dummy"' . "\n"
		. 'ports     = [ "22", "80" ]' . "\n"
		. 'protocols = [ "tcp" ]' . "\n"
		. 'prefix    = "foo"' . "\n"
		. 'self_heal = 1' . "\n\n"
		. '[kur.sshd.options]' . "\n"
		. 'b = "2"' . "\n"
		. 'a = "1"' . "\n\n"
		. '[kur.smtp]' . "\n"
		. 'backend          = "dummy"' . "\n"
		. 'ban_time         = 30' . "\n"
		. 'checkpoint       = 15' . "\n"
		. 'enable_cidr      = false' . "\n"
		. 'cidr_silent_drop = true' . "\n"
		. 'ports            = [ "25" ]'
		. "\n" );

lives_ok { $ereshkigal = Ereshkigal->new( 'config' => $full ) } 'new lives on a full config';
is( $ereshkigal->{run_base_dir},   $dir . '/run',    'run_base_dir merged' );
is( $ereshkigal->{cache_base_dir}, $dir . '/cache',  'cache_base_dir merged' );
is( $ereshkigal->{kur_bin},        '/somewhere/kur', 'kur_bin merged' );
is( $ereshkigal->{timeout},        5,                'timeout merged' );
is( $ereshkigal->{ban_time},       120,              'ban_time merged' );
is( $ereshkigal->{checkpoint},     90,               'checkpoint merged' );
ok( $ereshkigal->{enable_auth}, 'enable_auth merged' );
ok( $ereshkigal->{enable_cidr}, 'enable_cidr merged' );
is( $ereshkigal->{auth_temp_dir}, '/tmp', 'auth_temp_dir merged' );
is_deeply( $ereshkigal->{authed_users},  ['zane'], 'authed_users merged' );
is_deeply( $ereshkigal->{authed_groups}, [$group], 'authed_groups merged' );
is( $ereshkigal->{socket_mode}, 0640,                      'socket_mode processed via oct' );
is( $ereshkigal->{socket_gid},  ( split( /\s+/, $( ) )[0], 'socket_group resolved to our GID' );

is( scalar( keys( %{ $ereshkigal->{kurs} } ) ), 2, 'both kur instances parsed' );
foreach my $name ( 'sshd', 'smtp' ) {
	my $entry = $ereshkigal->{kurs}{$name};
	ok( defined($entry), 'kur "' . $name . '" registered' );
	is( $entry->{enabled},  1, $name . ' enabled' );
	is( $entry->{restarts}, 0, $name . ' restarts 0' );
	is( $entry->{delay},    1, $name . ' delay 1' );
}

is( $ereshkigal->socket_path,             $dir . '/run/socket',        'socket_path' );
is( $ereshkigal->pid_path,                $dir . '/run/pid',           'pid_path' );
is( $ereshkigal->kur_socket_path('sshd'), $dir . '/run/kur/sshd.sock', 'kur_socket_path' );

#
# _build_kur_cmd
#

my @cmd     = $ereshkigal->_build_kur_cmd('sshd');
my $cmd_str = join( ' ', @cmd );
is( $cmd[0], '/somewhere/kur', 'cmd starts with kur_bin' );
like( $cmd_str, qr/--foreground/,              'cmd has --foreground' );
like( $cmd_str, qr/--name sshd/,               'cmd has --name' );
like( $cmd_str, qr/--backend dummy/,           'cmd has --backend' );
like( $cmd_str, qr/--ports 22,80/,             'cmd joins ports' );
like( $cmd_str, qr/--protocols tcp/,           'cmd has protocols' );
like( $cmd_str, qr/--prefix foo/,              'cmd has prefix' );
like( $cmd_str, qr/--self-heal 1/,             'cmd has self-heal' );
like( $cmd_str, qr/--option a=1 --option b=2/, 'cmd has sorted options' );
like( $cmd_str, qr/--ban-time 120/,            'cmd has the manager wide ban_time' );
like( $cmd_str, qr/--checkpoint 90/,           'cmd has the manager wide checkpoint' );
like( $cmd_str, qr/--enable-cidr 1/,           'cmd inherits the manager wide enable_cidr' );
like( $cmd_str, qr/--cidr-silent-drop 0/,      'cmd inherits the manager wide cidr_silent_drop' );
like( $cmd_str, qr/--run \Q$dir\E\/run/,       'cmd has the run dir' );
like( $cmd_str, qr/--cache \Q$dir\E\/cache/,   'cmd has the cache dir' );

@cmd     = $ereshkigal->_build_kur_cmd('smtp');
$cmd_str = join( ' ', @cmd );
unlike( $cmd_str, qr/--prefix|--self-heal|--option|--protocols/, 'unset options not passed for smtp' );
like( $cmd_str, qr/--ban-time 30/,        'the kur ban_time overrides the manager wide one' );
like( $cmd_str, qr/--checkpoint 15/,      'the kur checkpoint overrides the manager wide one' );
like( $cmd_str, qr/--enable-cidr 0/,      'the kur enable_cidr override off is passed' );
like( $cmd_str, qr/--cidr-silent-drop 1/, 'the kur cidr_silent_drop override on is passed' );

#
# fan_out kurs
#

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.gate]\nbackend = "dummy"\nfan_out = [ "sshd" ]\n)) )
}
qr/both a backend and a fan_out/, 'dies on a kur with both a backend and a fan_out';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.gate]\nfan_out = "sshd"\n)) )
}
qr/not an array of one or more/, 'dies on a non-array fan_out';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.gate]\nfan_out = [ ]\n)) )
}
qr/not an array of one or more/, 'dies on an empty fan_out';

throws_ok {
	Ereshkigal->new( 'config' => write_cfg(qq([kur.gate]\nfan_out = [ "bad.name" ]\n)) )
}
qr/contains an invalid kur name/, 'dies on a fan_out with an invalid member name';

throws_ok {
	Ereshkigal->new(
		'config' => write_cfg( qq([kur.sshd]\nbackend = "dummy"\n\n) . qq([kur.gate]\nfan_out = [ "nosuch" ]\n) ) )
}
qr/contains an unknown kur/, 'dies on a fan_out with an unknown member';

throws_ok {
	Ereshkigal->new(
		'config' => write_cfg(
				  qq([kur.sshd]\nbackend = "dummy"\n\n)
				. qq([kur.gate]\nfan_out = [ "sshd" ]\n\n)
				. qq([kur.gate2]\nfan_out = [ "gate" ]\n)
		)
	)
}
qr/may not nest/, 'dies on a nested fan_out kur';

my $gateway_cfg
	= write_cfg( 'run_base_dir = "'
		. $dir
		. '/gwrun"' . "\n"
		. qq([kur.sshd]\nbackend = "dummy"\n\n)
		. qq([kur.smtp]\nbackend = "dummy"\n\n)
		. qq([kur.gate]\nfan_out = [ "sshd", "smtp" ]\n) );
lives_ok { $ereshkigal = Ereshkigal->new( 'config' => $gateway_cfg ) } 'new lives with a fan_out kur';
ok( defined( $ereshkigal->{kurs}{gate} ), 'the fan_out kur registered' );

is_deeply( [ $ereshkigal->_real_kur_names ],             [ 'smtp', 'sshd' ], 'fan_out kurs are not real kurs' );
is_deeply( [ $ereshkigal->_expand_kur_targets('gate') ], [ 'sshd', 'smtp' ], 'a fan_out kur expands to it\'s members' );
is_deeply( [ $ereshkigal->_expand_kur_targets('sshd') ], ['sshd'], 'a plain kur expands to it\'s self' );

# removal of a fan_out member is refused so a gate can not be left with a
# dangling member, matching what config load refuses
throws_ok { $ereshkigal->_cmd_remove_kur( { 'args' => { 'name' => 'sshd' } } ) }
qr/is a fan_out member of "gate"/, 'removing a fan_out member is refused';

my $summary = $ereshkigal->_kur_summary;
is_deeply(
	$summary->{gate},
	{ 'fan_out' => [ 'sshd', 'smtp' ], 'running' => 0, 'enabled' => 1 },
	'the summary row for a fan_out kur carries it\'s members'
);

# nothing was spawned, so a ban targeted at the gateway answers not running
# per member... proving the expansion with out a server
is_deeply(
	$ereshkigal->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'], 'kur' => 'gate' } }, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } } },
	'a ban targeted at a fan_out kur expands to it\'s members'
);

ok( !defined( $ereshkigal->_cmd_banned->{kurs}{gate} ), 'banned has no row for the fan_out kur' );

my $gate_status = $ereshkigal->_cmd_status_kur( { 'args' => { 'name' => 'gate' } }, undef );
is_deeply( $gate_status->{fan_out}, [ 'sshd', 'smtp' ], 'status_kur of a fan_out kur lists it\'s members' );
ok( defined( $gate_status->{kurs}{sshd} ), 'status_kur of a fan_out kur carries per member results' );

#
# _fan_out
#

# nothing was ever spawned, so every kur lacks a pid and must be answered
# with not running with out a connect ever being attempted... were one
# attempted the error would read Failed to connect instead
my $fanned = $ereshkigal->_fan_out( [ 'sshd', 'smtp' ], 'ping' );
is_deeply(
	$fanned,
	{ 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } },
	'_fan_out answers not running kurs with out connecting'
);

$fanned = $ereshkigal->_fan_out( ['nosuch'], 'ping' );
is_deeply( $fanned, { 'nosuch' => { 'error' => 'not running' } }, '_fan_out treats an unknown kur as not running' );

#
# a running kur whose socket can not be reached reports under the same error
# key status_all uses, rather than nesting the failure inside status
#

# a pid makes it look running, so the fan out attempts a connect and fails
# against the socket that was never created
$ereshkigal->{kurs}{sshd}{pid} = $$;

my $wedged = $ereshkigal->_cmd_status_kur( { 'args' => { 'name' => 'sshd' } }, undef );
is( $wedged->{running}, 1, 'status_kur of a wedged kur still reports running' );
like( $wedged->{error}, qr/Failed to connect/, 'status_kur reports the failure under error' );
ok( !defined( $wedged->{status} ), 'status_kur leaves status unset when the kur could not be reached' );

my $all = $ereshkigal->_cmd_status_all;
like( $all->{kurs}{sshd}{error}, qr/Failed to connect/, 'status_all reports the same failure under error' );
ok( !defined( $all->{kurs}{sshd}{status} ), 'status_all leaves status unset too' );

$ereshkigal->{kurs}{sshd}{pid} = undef;

#
# clear_retries fans out like checkpoint, validating and canonicalizing what
# it is given before any of it goes out
#

throws_ok { $ereshkigal->_cmd_clear_retries( { 'args' => { 'ip' => 'notanip' } }, undef ) }
qr/does not appear to be an IPv4 or IPv6 IP/, 'clear_retries refuses an invalid ip';
throws_ok { $ereshkigal->_cmd_clear_retries( { 'args' => { 'cidr' => 'notacidr' } }, undef ) }
qr/does not appear to be an IPv4 or IPv6 CIDR/, 'clear_retries refuses an invalid cidr';
throws_ok {
	$ereshkigal->_cmd_clear_retries( { 'args' => { 'ip' => '1.2.3.4', 'cidr' => '1.2.3.0/24' } }, undef )
}
qr/only one of/, 'clear_retries refuses both an ip and a cidr';
throws_ok { $ereshkigal->_cmd_clear_retries( { 'args' => { 'kur' => 'nosuch' } }, undef ) }
qr/No such kur instance/, 'clear_retries refuses an unknown kur';

#
# a bad ban_time is bounced once at the manager rather than by every kur...
# the kur still validates it, but a caller should not get N copies of the
# same error back for one bad value
#

foreach my $bad ( 'abc', -1, '1.5', ['30'] ) {
	my $shown = ref($bad) ? 'a ref' : $bad;
	throws_ok {
		$ereshkigal->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'], 'ban_time' => $bad } }, undef )
	}
	qr/args\.ban_time must be a non-negative int of seconds/, 'ban_time "' . $shown . '" bounced at the manager';
}

# and a good one still reaches the kurs, which are simply not running here
is_deeply(
	$ereshkigal->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'], 'ban_time' => 30 } }, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } } },
	'a valid ban_time is not bounced'
);

#
# re_init fans out the same way
#

throws_ok { $ereshkigal->_cmd_re_init( { 'args' => { 'kur' => 'nosuch' } }, undef ) }
qr/No such kur instance/, 're_init refuses an unknown kur';
is_deeply(
	$ereshkigal->_cmd_re_init( {}, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } } },
	're_init with no name goes to every real kur'
);
is_deeply(
	$ereshkigal->_cmd_re_init( { 'args' => { 'kur' => 'gate' } }, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } } },
	're_init targeted at a fan_out kur expands to it\'s members'
);
is_deeply(
	$ereshkigal->_cmd_re_init( { 'args' => { 'kur' => 'sshd' } }, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' } } },
	're_init targeted at one kur goes to just it'
);

# nothing is running, so every target answers not running... which is enough
# to prove the expansion and that each name is reached
is_deeply(
	$ereshkigal->_cmd_clear_retries( {}, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } } },
	'clear_retries with nothing named goes to every real kur'
);
is_deeply(
	$ereshkigal->_cmd_clear_retries( { 'args' => { 'kur' => 'gate' } }, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' }, 'smtp' => { 'error' => 'not running' } } },
	'clear_retries targeted at a fan_out kur expands to it\'s members'
);
is_deeply(
	$ereshkigal->_cmd_clear_retries( { 'args' => { 'kur' => 'sshd', 'ip' => '1.2.3.4' } }, undef ),
	{ 'kurs' => { 'sshd' => { 'error' => 'not running' } } },
	'clear_retries targeted at one kur goes to just it'
);

#
# the interfaces option and options validation
#

$ereshkigal = Ereshkigal->new(
	'config' => write_cfg(
			  'run_base_dir = "'
			. $dir
			. '/ifrun"' . "\n"
			. qq([kur.edge]\nbackend = "dummy"\n\n)
			. qq([kur.edge.options]\ninterfaces = [ "eth0", "eth1" ]\nmode = "src"\n\n)
			. qq([kur.lone]\nbackend = "dummy"\n\n)
			. qq([kur.lone.options]\ninterfaces = "eth0"\n)
	)
);
@cmd     = $ereshkigal->_build_kur_cmd('edge');
$cmd_str = join( ' ', @cmd );
like( $cmd_str, qr/--interfaces eth0,eth1/, 'an array interfaces option rides --interfaces' );
like( $cmd_str, qr/--option mode=src/,      'scalar options still ride --option' );
unlike( $cmd_str, qr/--option interfaces/, 'interfaces does not also ride --option' );

@cmd     = $ereshkigal->_build_kur_cmd('lone');
$cmd_str = join( ' ', @cmd );
like( $cmd_str, qr/--interfaces eth0/, 'a scalar interfaces option rides --interfaces too' );

throws_ok {
	Ereshkigal->new(
		'config' => write_cfg(
				  'run_base_dir = "'
				. $dir
				. '/ifrun"' . "\n"
				. qq([kur.edge]\nbackend = "dummy"\n\n[kur.edge.options]\nbad = [ "a" ]\n)
		)
	)
} ## end throws_ok
qr/non-scalar value for the option "bad"/, 'dies on an array valued option other than interfaces';

done_testing;
