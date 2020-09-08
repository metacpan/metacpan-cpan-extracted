use Test::More;
use strict;
use IO::String;
use JSON qw(to_json from_json);

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                       => 'error',
            authentication                 => 'Demo',
            userDB                         => 'Same',
            loginHistoryEnabled            => 0,
            brutForceProtection            => 0,
            checkUser                      => 1,
            checkUserIdRule                => '$uid ne "rtyler"',
            checkUserUnrestrictedUsersRule => '$uid eq "msmith"',
            tokenUseGlobalStorage          => 0,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            impersonationMergeSSOgroups    => 0,
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(1);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
count(1);

# Try checkUser with an allowed identity
$query =~ s/user=dwho/user=msmith/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUserComputeSession', 'Computed session' )
  or print STDERR Dumper($res);
count(2);

# Try checkUser with a forbidden identity
$query =~ s/user=msmith/user=rtyler/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'PE5', 'BADCREDENTIALS' )
  or print STDERR Dumper($res);
count(2);

# Try to authenticate with rtyler
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id2 = expectCookie($res);

# Try chckUser with a forbidden identity existing in DB
$query =~ s/user=msmith/user=rtyler/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'PE5', 'BADCREDENTIALS' )
  or print STDERR Dumper($res);
count(2);

# Try to authenticate with msmith
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=msmith&password=msmith'),
        length => 27
    ),
    'Auth query'
);
count(1);
expectOK($res);
$id = expectCookie($res);

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(1);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
count(1);

# Try checkUser with an allowed identity
$query =~ s/user=msmith/user=dwho/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUser', 'SSO session' )
  or print STDERR Dumper($res);
count(2);

# Try checkUser with a forbidden identity existing in DB
$query =~ s/user=dwho/user=rtyler/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUser', 'SSO session' )
  or print STDERR Dumper($res);
count(2);

$client->logout($id2);

# Try checkUser with a forbidden identity
$query =~ s/user=dwho/user=rtyler/;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
    ),
    'POST checkuser'
);
count(1);

ok( $res = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $res->{MSG} eq 'checkUserComputeSession', 'Computed session' )
  or print STDERR Dumper($res);
count(2);

$client->logout($id);
clean_sessions();
done_testing( count() );
