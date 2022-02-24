use Test::More;
use strict;
use IO::String;
use JSON qw(to_json from_json);

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => 'error',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            loginHistoryEnabled             => 0,
            brutForceProtection             => 0,
            checkUser                       => 1,
            checkUserIdRule                 => '$uid ne "rtyler"',
            checkUserUnrestrictedUsersRule  => '$uid eq "msmith"',
            tokenUseGlobalStorage           => 0,
            checkUserDisplayPersistentInfo  => 0,
            checkUserDisplayComputedSession => 1,
            checkUserDisplayEmptyValues     => 0,
            checkUserDisplayEmptyHeaders    => 1,
            impersonationMergeSSOgroups     => 0,
            checkUserHiddenHeaders          => {
                'test1.example.com' => 'Auth-User emptyHeader',
                'test2.example.com' => '',
                '*.example.llng'    => '',
            }
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
ok( $res->{MSG} eq 'checkUserComputedSession', 'Computed session' )
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

# Try checkUser with a forbidden identity existing in DB
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
$query =~ s/url=/url=test1/;
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
ok( $res->{MSG} eq 'checkUserComputedSession', 'Computed session' )
  or print STDERR Dumper($res);
count(2);

# Headers are not masked
my @auth_user = map { $_->{key} eq 'Auth-User' ? $_ : () } @{ $res->{HEADERS} };
my @empty = map { $_->{key} eq 'emptyHeader' ? $_ : () } @{ $res->{HEADERS} };
ok( $auth_user[0]->{value} eq 'rtyler', 'Auth-User is not masked' )
  or explain( $res->{HEADERS}, 'Auth-User header value' );
ok( $empty[0]->{value} eq '', 'emptyHeader is not masked' )
  or explain( $res->{HEADERS}, 'emptyHeader header value' );
count(2);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

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

$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckUser form
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

# Headers are masked
$query =~ s/url=/url=test1/;
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

@auth_user = map { $_->{key} eq 'Auth-User'   ? $_ : () } @{ $res->{HEADERS} };
@empty     = map { $_->{key} eq 'emptyHeader' ? $_ : () } @{ $res->{HEADERS} };
my @test = map { $_->{key} eq 'testHeader1' ? $_ : () } @{ $res->{HEADERS} };
ok( $auth_user[0]->{value} eq '******', 'Auth-User is masked' )
  or explain( $res->{HEADERS}, 'Auth-User header value' );
ok( $empty[0]->{value} eq '', 'emptyHeader is not masked' )
  or explain( $res->{HEADERS}, 'emptyHeader header value' );
ok( $test[0]->{value} eq 'testHeader_value', 'testHeader1 is not masked' )
  or explain( $res->{HEADERS}, 'testHeader1 header value' );
count(4);

$query =~ s/url=test1/url=test2/;
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

@auth_user = map { $_->{key} eq 'Auth-User'   ? $_ : () } @{ $res->{HEADERS} };
@empty     = map { $_->{key} eq 'emptyHeader' ? $_ : () } @{ $res->{HEADERS} };
ok( $auth_user[0]->{value} eq '******', 'Auth-User is masked' )
  or explain( $res->{HEADERS}, 'Auth-User header value' );
count(2);

$query =~ s/url=test2/url=*.example.llng/;
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

@auth_user = map { $_->{key} eq 'Auth-User'   ? $_ : () } @{ $res->{HEADERS} };
@test      = map { $_->{key} eq 'testHeader1' ? $_ : () } @{ $res->{HEADERS} };
ok( $auth_user[0]->{value} eq '******', 'Auth-User is masked' )
  or explain( $res->{HEADERS}, 'Auth-User header value' );
ok( $test[0]->{value} eq '******', 'testHeader1 is masked' )
  or explain( $res->{HEADERS}, 'testHeader1 header value' );
count(3);

$client->logout($id);

clean_sessions();
done_testing( count() );
