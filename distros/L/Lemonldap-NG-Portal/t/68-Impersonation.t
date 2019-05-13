use Test::More;
use strict;
use IO::String;

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
            portalMainLogo                 => 'common/logos/logo_llng_old.png',
            requireToken                   => 0,
            checkUser                      => 1,
            impersonationRule              => '$uid ne "msmith"',
            impersonationIdRule            => '$uid ne "msmith"',
            impersonationPrefix            => 'testPrefix_',
            securedCookie                  => 1,
            https                          => 0,
            checkUserDisplayPersistentInfo => 0,
            checkUserDisplayEmptyValues    => 0,
            impersonationMergeSSOgroups    => 0,
            macros                         => {
                test_impersonation => '"$testPrefix__user/$_user"',
                _whatToTrace =>
                  '$_auth eq "SAML" ? "$_user@$_idpConfKey" : $_user',
            },
        }
    }
);

## Try to impersonate with a bad spoofed user
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;
$query =~ s/spoofId=/spoofId=dwho*/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
ok( $res->[2]->[0] =~ m%<span trmsg="40"></span>%, ' PE40 found' )
  or explain( $res->[2]->[0], "PE40 - Bad formed user" );
count(2);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

## Try to impersonate with a forbidden identity
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=rtyler/;
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
ok(
    $res->[2]->[0] =~
m%<div class="message message-negative alert"><span trmsg="5"></span></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], "PE5 - Forbidden identity" );
count(2);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

## An unauthorized user try to impersonate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=msmith/;
$query =~ s/password=/password=msmith/;
$query =~ s/spoofId=/spoofId=rtyler/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
ok(
    $res->[2]->[0] =~
m%<div class="message message-negative alert"><span trmsg="93"></span></div>%,
    ' PE93 found'
) or explain( $res->[2]->[0], "PE93 - Impersonation service not allowed" );
count(2);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

## An unauthorized user to impersonate tries to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=msmith/;
$query =~ s/password=/password=msmith/;
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

ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST checkuser'
);
count(1);

ok( $res->[2]->[0] =~ m%<td class="align-middle">test_impersonation</td>%,
    'Found macro test_impersonation' )
  or explain( $res->[2]->[0], 'test_impersonation' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">msmith/msmith</td>%,
    'Found msmith/msmith' )
  or explain( $res->[2]->[0], 'Found msmith/msmith' );
count(2);

$client->logout($id);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

$query =~ s/user=/user=rtyler/;
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
count(1);

$id = expectCookie($res);
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

$query =~ s/url=/url=test1.example.com/;

ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST checkuser'
);
count(1);

( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok(
    $res->[2]->[0] =~
m%<div class="alert alert-success"><b><span trspan="allowed"></span></b></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );

ok( $res->[2]->[0] !~ m%<span trspan="groups_sso">%,
    'trspan="groups_sso" NOT found' )
  or explain( $res->[2]->[0], 'trspan="groups_sso"' );

ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<td class="text-left">_userDB</td>%, 'Found _userDB' )
  or explain( $res->[2]->[0], '_userDB' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">Auth-User</td>%,
    'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">dwho</td>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Header Value: dwho' );

ok( $res->[2]->[0] =~ m%<td class="align-middle">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td class="text-left">testPrefix_groups</td>%,
    'Found testPrefix_groups' )
  or explain( $res->[2]->[0], 'testPrefix_groups' );
ok( $res->[2]->[0] =~ m%<td class="text-left">su</td>%, 'Found su' )
  or explain( $res->[2]->[0], 'su' );
ok( $res->[2]->[0] =~ m%<td class="text-left">testPrefix_uid</td>%,
    'Found testPrefix_uid' )
  or explain( $res->[2]->[0], 'testPrefix_groups' );
ok( $res->[2]->[0] =~ m%<td class="text-left">rtyler</td>%, 'Found rtyler' )
  or explain( $res->[2]->[0], 'su' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">test_impersonation</td>%,
    'Found macro test_impersonation' )
  or explain( $res->[2]->[0], 'test_impersonation' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">rtyler/dwho</td>%,
    'Found rtyler/dwo' )
  or explain( $res->[2]->[0], 'Found rtyler/dwo' );
count(16);

my @attributes = map /<td class="text-left">(.+)?<\/td>/g, $res->[2]->[0];
ok( scalar @attributes == 58, 'Found 58 attributes' )
  or print STDERR "Missing attributes -> " . scalar @attributes;
ok( $attributes[0] eq '_auth', '_auth' ) or print STDERR Dumper( \@attributes );
ok( $attributes[1] eq 'Demo',  'Demo' )  or print STDERR Dumper( \@attributes );
ok( $attributes[26] eq 'uid',  'uid' )   or print STDERR Dumper( \@attributes );
ok( $attributes[28] eq 'testPrefix__auth', 'testPrefix__auth' )
  or print STDERR Dumper( \@attributes );
ok( $attributes[56] eq 'testPrefix_uid', 'testPrefix_uid' )
  or print STDERR Dumper( \@attributes );
ok( $attributes[57] eq 'rtyler', 'rtyler' )
  or print STDERR Dumper( \@attributes );
count(7);

$client->logout($id);
clean_sessions();

done_testing( count() );
