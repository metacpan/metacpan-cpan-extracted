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
            checkUserHiddenAttributes      => '_loginHistory hGroups',
            macros                         => {
                test_impersonation => '"$testPrefix__user/$_user"',
                _whatToTrace       =>
                  '$_auth eq "SAML" ? "$_user@$_idpConfKey" : $_user',
                mail => 'uc $mail'
            }
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
ok( $res->[2]->[0] =~ m%<span trmsg="40">%, ' PE40 found' )
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
ok( $res->[2]->[0] =~ m%<span trmsg="5">%, ' PE5 found' )
  or explain( $res->[2]->[0], "PE5 - Forbidden identity" );
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
ok( $res->[2]->[0] =~ m%<span trmsg="93">%, ' PE93 found' )
  or explain( $res->[2]->[0], "PE93 - Impersonation service not allowed" );
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

# Get Menu
# ------------------------
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
count(1);
expectOK($res);
ok(
    $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> msmith%,
    'Connected as msmith'
) or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'msmith' );
count(1);

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

ok( $res->[2]->[0] =~ m%<td scope="row">test_impersonation</td>%,
    'Found macro test_impersonation' )
  or explain( $res->[2]->[0], 'test_impersonation' );
ok( $res->[2]->[0] =~ m%<td scope="row">msmith/msmith</td>%,
    'Found msmith/msmith' )
  or explain( $res->[2]->[0], 'Found msmith/msmith' );
my $nbr = $res->[2]->[0] =~ s%MSMITH\@BADWOLF\.ORG%%g;
ok( $nbr == 2, 'Found two MSMITH@BADWOLF.ORG' )
  or explain( $res->[2]->[0], 'Found two MSMITH@BADWOLF.ORG' );
count(3);

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

# Get Menu
# ------------------------
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Get Menu',
);
count(1);
expectOK($res);
ok( $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> dwho%,
    'Connected as dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'dwho' );
count(1);

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
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );

ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<td scope="row">_userDB</td>%, 'Found _userDB' )
  or explain( $res->[2]->[0], '_userDB' );
ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%: dwho<br/>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Header Value: dwho' );

ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td scope="row">testPrefix_groups</td>%,
    'Found testPrefix_groups' )
  or explain( $res->[2]->[0], 'testPrefix_groups' );
ok( $res->[2]->[0] =~ m%<td scope="row">[^<]*su; su_test; test_su</td>%,
    'Found "su; su_test; test_su"' )
  or explain( $res->[2]->[0], 'su' );
ok( $res->[2]->[0] =~ m%<td scope="row">testPrefix_uid</td>%,
    'Found testPrefix_uid' )
  or explain( $res->[2]->[0], 'testPrefix_groups' );
ok( $res->[2]->[0] =~ m%<td scope="row">rtyler</td>%, 'Found rtyler' )
  or explain( $res->[2]->[0], 'su' );
ok( $res->[2]->[0] =~ m%<td scope="row">test_impersonation</td>%,
    'Found macro test_impersonation' )
  or explain( $res->[2]->[0], 'test_impersonation' );
ok( $res->[2]->[0] =~ m%<td scope="row">rtyler/dwho</td>%, 'Found rtyler/dwo' )
  or explain( $res->[2]->[0], 'Found rtyler/dwo' );
ok( $res->[2]->[0] =~ m%<td scope="row">_session_id</td>%, 'Found _session_id' )
  or explain( $res->[2]->[0], 'Found _session_id' );
ok( $res->[2]->[0] =~ m%<td scope="row">_session_kind</td>%,
    'Found _session_id' )
  or explain( $res->[2]->[0], 'Found _session_kind' );
count(17);

my %attributes = map /<td scope="row">(.+)?<\/td>/g, $res->[2]->[0];
ok( keys %attributes == 34, 'Found 34 attributes' )
  or print STDERR ( keys %attributes < 34 )
  ? "Missing attributes -> " . scalar keys(%attributes) . "\n"
  : "Too much attributes -> " . scalar keys(%attributes) . "\n";
ok( $attributes{'_auth'} eq 'Demo', '_auth' )
  or print STDERR Dumper( \%attributes );
ok( $attributes{'uid'}, 'uid' ) or print STDERR Dumper( \%attributes );
ok( $attributes{'testPrefix__auth'}, 'testPrefix__auth' )
  or print STDERR Dumper( \%attributes );
ok( $attributes{'testPrefix_uid'} eq 'rtyler', 'testPrefix_uid' )
  or print STDERR Dumper( \%attributes );
count(5);

$client->logout($id);
clean_sessions();

done_testing( count() );
