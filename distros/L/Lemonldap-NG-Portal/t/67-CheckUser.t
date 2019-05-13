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
            checkUser                      => 1,
            requireToken                   => 0,
            checkUserIdRule                => '$uid ne "msmith"',
            checkUserDisplayPersistentInfo => 1,
            checkUserDisplayEmptyValues    => 1,
        }
    }
);

## Try to authenticate
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Try to access /checkuser'
);
count(1);

ok( $res->[2]->[0] =~ m%An error occurs, you're going to be redirected to%,
    'Found redirection page' )
  or explain( $res->[2]->[0],
    "An error occurs, you're going to be redirected to" );
count(1);
$client->logout($id);

## Try to authenticate
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckUser form -> granted
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

# Request with bad VH
my ( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
count(1);

ok( $res->[2]->[0] =~ m%<td class="text-left">_user</td>%,
    'Found attribute _user' )
  or explain( $res->[2]->[0], 'Attribute _user' );
ok( $res->[2]->[0] =~ m%<td class="text-left">dwho</td>%, 'Found value dwho' )
  or explain( $res->[2]->[0], 'Value dwho' );
count(2);

$query =~ s/user=dwho/user=rtyler/;
$query =~ s/url=/url=http%3A%2F%2Ftry.example.com/;
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
ok( $res->[2]->[0] =~ m%<span trspan="VHnotFound">%,
    'Found trspan="VHnotFound"' )
  or explain( $res->[2]->[0], 'trspan="VHnotFound"' );
count(1);

# Request with good VH & user
$query =~
s#url=http%3A%2F%2Ftry.example.com#url=hTTp%3A%2F%2FTest1.exAmple.cOm/UriTesT#;

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
ok( $res->[2]->[0] =~ m%value="http://test1.example.com/UriTesT"%,
    'Found well formatted url' )
  or explain( $res->[2]->[0], 'Well formatted url' );
count(2);

ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok(
    $res->[2]->[0] =~
m%<div class="alert alert-success"><b><span trspan="allowed"></span></b></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );
ok( $res->[2]->[0] =~ m%<span trspan="groups_sso">%,
    'Found trspan="groups_sso"' )
  or explain( $res->[2]->[0], 'trspan="groups_sso"' );
ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">Auth-User</td>%,
    'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">rtyler</td>%, 'Found rtyler' )
  or explain( $res->[2]->[0], 'Header Value: rtyler' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">su</td>%, 'Found su' )
  or explain( $res->[2]->[0], 'SSO Groups: su' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td class="text-left">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
count(11);

# Request with short VH url & user
$query =~
  s#url=http%3A%2F%2Ftest1.example.com%2FUriTesT#url=http%3A%2F%2Ftest1:1234#;

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
ok( $res->[2]->[0] =~ m%value="http://test1.example.com:1234"%,
    'Found well formatted url' )
  or explain( $res->[2]->[0], 'Well formatted url' );
count(2);

ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok(
    $res->[2]->[0] =~
m%<div class="alert alert-success"><b><span trspan="allowed"></span></b></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );
ok( $res->[2]->[0] =~ m%<span trspan="groups_sso">%,
    'Found trspan="groups_sso"' )
  or explain( $res->[2]->[0], 'trspan="groups_sso"' );
ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">Auth-User</td>%,
    'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">rtyler</td>%, 'Found rtyler' )
  or explain( $res->[2]->[0], 'Header Value: rtyler' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">su</td>%, 'Found su' )
  or explain( $res->[2]->[0], 'SSO Groups: su' );
ok( $res->[2]->[0] =~ m%<td class="align-middle">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td class="text-left">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
count(11);

# Request a forbidden identity
$query =~ s/user=rtyler/user=msmith/;
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
ok(
    $res->[2]->[0] =~
m%<div class="message message-positive alert"><span trspan="PE5"></span></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], 'PE5 - Forbidden identity' );
count(2);

# Request an unknown identity
$query =~ s/user=msmith/user=davros/;
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
ok(
    $res->[2]->[0] =~
m%<div class="message message-positive alert"><span trspan="PE5"></span></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], 'PE5 - Unknown identity' );
count(2);

# Request an unvalid identity
$query =~ s/user=dwho/user=%*'/;
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
ok(
    $res->[2]->[0] =~
m%<div class="message message-positive alert"><span trspan="PE5"></span></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], 'PE5 - Unvalid identity' );
count(2);

$client->logout($id);
clean_sessions();

done_testing( count() );
