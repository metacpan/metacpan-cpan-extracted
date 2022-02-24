use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            authentication      => 'Demo',
            userDB              => 'Same',
            loginHistoryEnabled => 0,
            brutForceProtection => 0,
            portalMainLogo      => 'common/logos/logo_llng_old.png',
            requireToken        => 1,
            impersonationRule   => 1,
            impersonationIdRule => '$uid ne "msmith"',
            impersonationUnrestrictedUsersRule => '$uid eq "dwho"',
        }
    }
);

## Try to Impersonate an allowed identity
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId', 'token' );

$query =~ s/user=[^&]*/user=rtyler/;
$query =~ s/password=/password=rtyler/;
$query =~ s/spoofId=/spoofId=dwho/;

ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
my $id = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'dwho' );
count(2);
$client->logout($id);

## Try to Impersonate a forbidden identity
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId', 'token' );

$query =~ s/user=[^&]*/user=rtyler/;
$query =~ s/password=/password=rtyler/;
$query =~ s/spoofId=/spoofId=msmith/;

ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
ok( $res->[2]->[0] =~ m%<span trmsg="5">%, ' PE5 found' )
  or explain( $res->[2]->[0], "PE5 - Forbidden identity" );
count(2);

## Try to Impersonate a forbidden identity with an Unrestricted user
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId', 'token' );

$query =~ s/user=[^&]*/user=dwho/;
$query =~ s/password=/password=dwho/;
$query =~ s/spoofId=/spoofId=msmith/;

ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
$id = expectCookie($res);
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
expectAuthenticatedAs( $res, 'msmith' );
count(2);
$client->logout($id);

clean_sessions();

done_testing( count() );
