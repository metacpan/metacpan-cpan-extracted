#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::Socket::UNIX ();
use lib 't/lib';
use EreshkigalTest qw( test_dir socket_path_ok wait_for_socket wait_for_gone wait_for_exit spawn_manager write_config );

use Ereshkigal;
use Ereshkigal::Client;

# a stand in for the POE::Component::Server::JSONUnix context object
package EreshkigalTest::FakeCtx;

sub new {
	my ( $class, %args ) = @_;
	return bless( {%args}, $class );
}
sub uid      { return $_[0]{uid}; }
sub username { return $_[0]{username}; }

# a stand in for the real context's NSS backed in_group... resolves the
# uid's primary group and any group member lists, which is enough to
# exercise _authorize's group handling with real users and groups
sub in_group {
	my ( $self, $group ) = @_;
	return 0 unless defined($group);

	my $primary_gid = ( getpwuid( $self->{uid} ) )[3];
	if ( defined($primary_gid) ) {
		my $primary_group = getgrgid($primary_gid);
		return 1 if defined($primary_group) && $primary_group eq $group;
	}

	my $members = ( getgrnam($group) )[3];
	if ( defined($members) ) {
		foreach my $member ( split( /\s+/, $members ) ) {
			return 1 if $member eq $self->{username};
		}
	}

	return 0;
} ## end sub in_group

package main;

sub ctx {
	return EreshkigalTest::FakeCtx->new(@_);
}

# _authorize signals a refusal by dying with a { error, code } hash ref,
# that hash ref being what carries the machine-readable code through to the
# JSONUnix error response... assert against both the message and the code
sub denied_ok {
	my ( $coderef, $regex, $desc ) = @_;
	my $lived = eval { $coderef->(); 1 };
	# capture the exception before subtest's own internals clobber $@
	my $err = $@;
	return subtest $desc => sub {
		plan tests => 3;
		ok( !$lived, 'refused' );
		like( ( ref($err) eq 'HASH' ? $err->{error} : $err ), $regex, 'error message' );
		is( ( ref($err) eq 'HASH'   ? $err->{code}  : undef ), 'permission_denied', 'permission_denied code' );
	};
} ## end sub denied_ok

my $dir = test_dir();

my $username      = getpwuid($>);
my $primary_group = getgrgid( ( split( /\s+/, $( ) )[0] );

#
# the authorization decision as plain methods, no sockets or POE
#

open( my $cfg_fh, '>', $dir . '/auth.toml' ) || die($!);
print $cfg_fh 'run_base_dir   = "'
	. $dir . '/run"' . "\n"
	. 'cache_base_dir = "'
	. $dir
	. '/cache"' . "\n"
	. 'enable_auth    = true' . "\n"
	. 'authed_users   = [ "globaluser" ]' . "\n\n"
	. '[kur.sshd]' . "\n"
	. 'backend      = "dummy"' . "\n"
	. 'authed_users = [ "scopeduser" ]' . "\n\n"
	. '[kur.smtp]' . "\n"
	. 'backend = "dummy"' . "\n\n"
	. '[kur.gate]' . "\n"
	. 'fan_out      = [ "sshd", "smtp" ]' . "\n"
	. 'authed_users = [ "gateuser" ]' . "\n";
close($cfg_fh);

my $ereshkigal = Ereshkigal->new( 'config' => $dir . '/auth.toml' );

# uid 0 is always authorized
lives_ok { $ereshkigal->_authorize( ctx( 'uid' => 0, 'username' => 'root' ) ) } 'uid 0 manager level';
lives_ok { $ereshkigal->_authorize( ctx( 'uid' => 0, 'username' => 'root' ), 'sshd', 'smtp' ) } 'uid 0 any kur';

# a global user is authorized for everything
my $global = ctx( 'uid' => 12345, 'username' => 'globaluser' );
lives_ok { $ereshkigal->_authorize($global) } 'global user manager level';
lives_ok { $ereshkigal->_authorize( $global, 'sshd' ) } 'global user single kur';
lives_ok { $ereshkigal->_authorize( $global, 'sshd', 'smtp' ) } 'global user all kurs';

# a kur scoped user is authorized for just that kur
my $scoped = ctx( 'uid' => 12346, 'username' => 'scopeduser' );
lives_ok { $ereshkigal->_authorize( $scoped, 'sshd' ) } 'scoped user their kur';
denied_ok(
	sub { $ereshkigal->_authorize( $scoped, 'smtp' ) },
	qr/not authorized for the kur "smtp"/,
	'scoped user other kur denied'
);
denied_ok(
	sub { $ereshkigal->_authorize($scoped) },
	qr/not authorized for manager level/,
	'scoped user manager level denied'
);
denied_ok(
	sub { $ereshkigal->_authorize( $scoped, 'sshd', 'smtp' ) },
	qr/not authorized for the kur "smtp"/,
	'scoped user denied when any touched kur is not theirs'
);

# a nobody is denied everywhere
my $nobody = ctx( 'uid' => 12347, 'username' => 'nobodyuser' );
denied_ok( sub { $ereshkigal->_authorize($nobody) }, qr/not authorized/, 'unknown user manager level denied' );
denied_ok( sub { $ereshkigal->_authorize( $nobody, 'sshd' ) }, qr/not authorized/, 'unknown user kur denied' );

# a gateway scoped user... authorization for a command targeted at a
# fan_out kur is checked against the gateway's own lists, not it's
# members', that being what makes one usable as a single point of contact
my $gateuser = ctx( 'uid' => 12348, 'username' => 'gateuser' );
lives_ok { $ereshkigal->_authorize( $gateuser, 'gate' ) } 'gateway user their gateway';
denied_ok(
	sub { $ereshkigal->_authorize( $gateuser, 'sshd' ) },
	qr/not authorized/,
	'gateway user denied the members directly'
);
denied_ok( sub { $ereshkigal->_authorize($gateuser) }, qr/not authorized/, 'gateway user denied manager level' );

SKIP: {
	# these exercise the current user's real group membership, so uid 0 short
	# circuiting to always authorized makes every assertion meaningless
	skip 'group membership auth is meaningless when running as root', 6 if $> == 0;

	# group via the user's own primary group
	$ereshkigal->{authed_users}  = [];
	$ereshkigal->{authed_groups} = [$primary_group];
	my $me = ctx( 'uid' => $>, 'username' => $username );
	lives_ok { $ereshkigal->_authorize($me) } 'authorized via primary group membership';
	lives_ok { $ereshkigal->_authorize( $me, 'sshd', 'smtp' ) } 'primary group covers kurs too';

	# unknown groups just never match rather than erroring
	$ereshkigal->{authed_groups} = ['nosuchgroupzzz'];
	denied_ok( sub { $ereshkigal->_authorize($me) }, qr/not authorized/, 'unknown group never matches' );

	# group via a member list
	my $member_group;
	setgrent();
	while ( my ( $group_name, undef, undef, $members ) = getgrent() ) {
		if ( defined($members) && grep { $_ eq $username } split( /\s+/, $members ) ) {
			$member_group = $group_name;
			last;
		}
	}
	endgrent();
SKIP: {
		skip 'current user is not in any group member list', 1 if !defined($member_group);
		$ereshkigal->{authed_groups} = [$member_group];
		lives_ok { $ereshkigal->_authorize($me) } 'authorized via a group member list';
	}

	# per kur groups expand the global ones
	$ereshkigal->{authed_groups} = [];
	$ereshkigal->{kurs}{sshd}{opts}{authed_groups} = [$primary_group];
	lives_ok { $ereshkigal->_authorize( $me, 'sshd' ) } 'kur level group grants that kur';
	denied_ok( sub { $ereshkigal->_authorize( $me, 'smtp' ) }, qr/not authorized/, 'but not the other kur' );
} ## end SKIP:

# an untargeted command on a manager carrying no real kurs is authorized
# before the emptiness is reported, so a refusal does not leak whether the
# manager has anything defined... the empty list makes it the manager level
# check, matching every other untargeted command
open( my $bare_fh, '>', $dir . '/bare.toml' ) || die($!);
print $bare_fh 'run_base_dir   = "'
	. $dir . '/run"' . "\n"
	. 'cache_base_dir = "'
	. $dir
	. '/cache"' . "\n"
	. 'enable_auth    = true' . "\n"
	. 'authed_users   = [ "globaluser" ]' . "\n";
close($bare_fh);

my $bare = Ereshkigal->new( 'config' => $dir . '/bare.toml' );
foreach my $command ( 'ban', 'cidr_ban' ) {
	my $method = '_cmd_' . $command;
	my $args   = $command eq 'ban' ? { 'ips' => ['1.2.3.4'] } : { 'cidrs' => ['1.2.3.0/24'] };
	denied_ok(
		sub { $bare->$method( { 'args' => $args }, $nobody ) },
		qr/not authorized/,
		'untargeted ' . $command . ' with no kurs refuses before reporting emptiness'
	);
}

# and an authorized caller still gets told there is nothing to ban on
throws_ok { $bare->_cmd_ban( { 'args' => { 'ips' => ['1.2.3.4'] } }, $global ) } qr/No kur instances/,
	'an authorized caller still gets the no kur instances error';

# clear_retries authorizes the same way the rest do... the scoped user for a
# kur that is theirs, refused for one that is not and at manager level
lives_ok { $ereshkigal->_cmd_clear_retries( { 'args' => { 'kur' => 'sshd' } }, $scoped ) }
'clear_retries allowed for a scoped user on their own kur';
denied_ok(
	sub { $ereshkigal->_cmd_clear_retries( { 'args' => { 'kur' => 'smtp' } }, $scoped ) },
	qr/not authorized/,
	'clear_retries denied for a scoped user on another kur'
);
denied_ok(
	sub { $ereshkigal->_cmd_clear_retries( {}, $scoped ) },
	qr/not authorized/,
	'untargeted clear_retries denied for a scoped user'
);
lives_ok { $ereshkigal->_cmd_clear_retries( { 'args' => { 'kur' => 'gate' } }, $gateuser ) }
'clear_retries at a gateway is the gateway grant, not it\'s members\'';

# and re_init, which rebuilds firewall state, authorizes the same way
lives_ok { $ereshkigal->_cmd_re_init( { 'args' => { 'kur' => 'sshd' } }, $scoped ) }
're_init allowed for a scoped user on their own kur';
denied_ok(
	sub { $ereshkigal->_cmd_re_init( { 'args' => { 'kur' => 'smtp' } }, $scoped ) },
	qr/not authorized/,
	're_init denied for a scoped user on another kur'
);
denied_ok(
	sub { $ereshkigal->_cmd_re_init( {}, $scoped ) },
	qr/not authorized/,
	'untargeted re_init denied for a scoped user'
);

# with enable_auth off everything is authorized regardless of lists
$ereshkigal->{enable_auth} = 0;
lives_ok { $ereshkigal->_authorize($nobody) } 'enable_auth off manager level';
lives_ok { $ereshkigal->_authorize( $nobody, 'sshd', 'smtp' ) } 'enable_auth off kurs';

#
# functional... a manager with enable_auth on
#

SKIP: {
	skip 'unix sockets and fork required',             29 if $^O eq 'MSWin32';
	skip 'temp dir path too long for a unix socket',   29 if !socket_path_ok($dir);
	skip 'perms are meaningless when running as root', 29 if $> == 0;

	#
	# scenario one... the current user in the global lists via their group
	#

	my $global_dir = test_dir();
	skip 'temp dir path too long for a unix socket', 29 if !socket_path_ok($global_dir);
	my $config = write_config( $global_dir,
		'settings_toml' => qq(enable_auth   = true\nauthed_groups = [ "$primary_group" ]\n) );
	my $manager_pid    = spawn_manager($config);
	my $manager_socket = $global_dir . '/run/socket';
	ok( wait_for_socket($manager_socket), 'auth manager came up' ) || BAIL_OUT('auth manager never came up');
	ok( wait_for_socket( $global_dir . '/run/kur/sshd.sock' ), 'sshd kur came up' );

	# a raw un-authed request is gated
	my $raw = IO::Socket::UNIX->new(
		'Type' => IO::Socket::UNIX::SOCK_STREAM(),
		'Peer' => $manager_socket,
	) || die($!);
	print $raw '{"command":"status"}' . "\n";
	my $raw_line = <$raw>;
	close($raw);
	like( $raw_line, qr/authentication required/, 'un-authed requests are gated' );

	# the client completes the challenge transparently
	my $client = Ereshkigal::Client->new( 'socket' => $manager_socket, 'timeout' => 15 );
	my $status = $client->call_ok('status');
	is( $status->{enable_auth},         1, 'status reports enable_auth' );
	is( $status->{kurs}{sshd}{running}, 1, 'status works through the transparent challenge' );

	my $result = $client->call_ok( 'ban', { 'ips' => ['1.2.3.4'] } );
	is( $result->{kurs}{sshd}{ips}{'1.2.3.4'}{status}, 'ok', 'fan-out ban works for a global user' );

	# kur sockets stay challenge free
	my $kur_client = Ereshkigal::Client->new( 'socket' => $global_dir . '/run/kur/sshd.sock', 'timeout' => 15 );
	is( $kur_client->call_ok('ping')->{pong}, 1, 'kur sockets answer with out any challenge' );

	$result = $client->call_ok('stop');
	is( $result->{stopping}, 1, 'stop works for a global user' );
	ok( wait_for_gone($manager_socket), 'auth manager socket gone' );
	is( wait_for_exit( $manager_pid, 20 ), 0, 'auth manager exited 0' );

	#
	# scenario two... the current user only in kur.sshd's lists
	#

	my $scoped_dir = test_dir();
	skip 'temp dir path too long for a unix socket', 18 if !socket_path_ok($scoped_dir);
	$config = write_config(
		$scoped_dir,
		'settings_toml' => qq(enable_auth = true\n),
		'kurs_toml'     => qq([kur.sshd]
backend      = "dummy"
ports        = [ "22" ]
protocols    = [ "tcp" ]
authed_users = [ "$username" ]

[kur.smtp]
backend   = "dummy"
ports     = [ "25" ]
protocols = [ "tcp" ]

[kur.gate]
fan_out      = [ "sshd", "smtp" ]
authed_users = [ "$username" ]
),
	);
	$manager_pid    = spawn_manager($config);
	$manager_socket = $scoped_dir . '/run/socket';
	ok( wait_for_socket($manager_socket), 'scoped manager came up' ) || BAIL_OUT('scoped manager never came up');
	ok( wait_for_socket( $scoped_dir . '/run/kur/sshd.sock' ), 'scoped sshd came up' );
	ok( wait_for_socket( $scoped_dir . '/run/kur/smtp.sock' ), 'scoped smtp came up' );

	$client = Ereshkigal::Client->new( 'socket' => $manager_socket, 'timeout' => 15 );

	$result = $client->call_ok( 'status_kur', { 'name' => 'sshd' } );
	is( $result->{running}, 1, 'scoped user may status_kur their kur' );

	$result = $client->call_ok( 'ban', { 'ips' => ['1.2.3.4'], 'kur' => 'sshd' } );
	is( $result->{kurs}{sshd}{ips}{'1.2.3.4'}{status}, 'ok', 'scoped user may ban on their kur' );

	$result = $client->call_ok( 'checkpoint', { 'kur' => 'sshd' } );
	is( $result->{kurs}{sshd}{checkpointed}, 1, 'scoped user may checkpoint their kur' );

	# the gateway grant... the user is NOT in smtp's lists, but being in the
	# gate's lists is what authorizes a command targeted at the gate, so the
	# fanned ban lands on both members
	$result = $client->call_ok( 'ban', { 'ips' => ['4.5.6.7'], 'kur' => 'gate' } );
	is( $result->{kurs}{sshd}{ips}{'4.5.6.7'}{status}, 'ok', 'gateway ban lands on sshd' );
	is( $result->{kurs}{smtp}{ips}{'4.5.6.7'}{status}, 'ok', 'gateway grant covers members the user is not listed on' );

	my $denied = qr/not authorized/;
	throws_ok { $client->call_ok('status') } $denied,     'scoped user denied status';
	throws_ok { $client->call_ok('status_all') } $denied, 'scoped user denied status_all';
	throws_ok { $client->call_ok( 'status_kur', { 'name' => 'smtp' } ) } $denied,
		'scoped user denied status_kur of the other kur';
	throws_ok { $client->call_ok( 'ban', { 'ips' => ['5.6.7.8'] } ) } $denied, 'scoped user denied fan-out ban';
	throws_ok { $client->call_ok( 'unban', { 'ip' => '1.2.3.4' } ) } $denied, 'scoped user denied unban';
	throws_ok { $client->call_ok('banned') } $denied,     'scoped user denied banned';
	throws_ok { $client->call_ok('checkpoint') } $denied, 'scoped user denied fan-out checkpoint';
	throws_ok { $client->call_ok( 'add_kur', { 'name' => 'dns', 'opts' => { 'backend' => 'dummy' } } ) } $denied,
		'scoped user denied add_kur';
	throws_ok { $client->call_ok( 'remove_kur', { 'name' => 'smtp' } ) } $denied, 'scoped user denied remove_kur';
	throws_ok { $client->call_ok('stop') } $denied, 'scoped user denied stop';

	# no authorized stop is possible for this user, so TERM the manager and
	# then stop the orphaned kurs directly via their challenge free sockets
	kill( 'TERM', $manager_pid );
	is( wait_for_exit( $manager_pid, 20 ), 0, 'scoped manager exited on TERM' );
	foreach my $name ( 'sshd', 'smtp' ) {
		eval {
			Ereshkigal::Client->new( 'socket' => $scoped_dir . '/run/kur/' . $name . '.sock', 'timeout' => 15 )
				->call_ok('stop');
		};
		ok( wait_for_gone( $scoped_dir . '/run/kur/' . $name . '.sock' ), 'orphaned ' . $name . ' kur stopped' );
	}
} ## end SKIP:

done_testing;
