use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => 'error',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            loginHistoryEnabled             => 0,
            brutForceProtection             => 0,
            portalMainLogo                  => 'common/logos/logo_llng_old.png',
            requireToken                    => 0,
            checkUser                       => 1,
            checkUserSearchAttributes       => 'employee_nbr,  test1 mail ',
            impersonationRule               => 1,
            checkUserDisplayComputedSession => 1,
            checkUserDisplayPersistentInfo  => 0,
            checkUserDisplayEmptyValues     => 0,
            impersonationMergeSSOgroups     => 0,
            userControl                     => '^[\w\.\-/\s]+$',
            whatToTrace                     => '_whatToTrace',
            macros                          => {
                authLevel     => '"Macro_$authenticationLevel"',
                realAuthLevel => '"realMacro_$real_authenticationLevel"',
                _whatToTrace  =>
                  '$real__user ? "$_user / $real__user" : "$_user / $_user"',
            },
            groups => {
                authGroup     => '$authenticationLevel == 1',
                realAuthGroup => '$real_authenticationLevel == 1',
            },
            vhostOptions => {
                'test2.example.com' => {
                    vhostHttps => 1
                }
            },
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
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
ok( $res->[2]->[0] =~ m%<span trspan="connectedAs">Connected as</span> dwho%,
    'Connected as dwho' )
  or print STDERR Dumper( $res->[2]->[0] );
expectAuthenticatedAs( $res, 'dwho / rtyler' );
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
ok(
    $res->[2]->[0] =~
m%<input id="userfield" name="user" type="text" class="form-control" value="dwho / rtyler" trplaceholder="user"%,
    'Found trplaceholder = "dwho / rtyler"'
) or explain( $res->[2]->[0], 'trplaceholder = "dwho / rtyler"' );
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
ok(
    $res->[2]->[0] =~
m%<input id="urlfield" name="url" type="text" class="form-control" value="http://test1.example.com" trplaceholder="URL / DNS" aria-required="true" autocomplete="url" />%,
    'Found HTTP url'
) or explain( $res->[2]->[0], 'HTTP url' );
ok(
    $res->[2]->[0] =~
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );
ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%<td scope="row">_userDB</td>%, 'Found _userDB' )
  or explain( $res->[2]->[0], '_userDB' );
ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%: dwho<br/>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Header Value: dwho' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $res->[2]->[0] =~ m%<td scope="row">Macro_1</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( my $nbr = ( $res->[2]->[0] =~ s%<td scope="row">Macro_1</td>%%g ),
    'Found two macros' )
  or explain( $res->[2]->[0], 'Macros not well computed' );
count(11);

ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckUser form',
);
count(1);

$query =~ s/user=dwho%20%2F%20rtyler/user=dwho/;
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
ok( $res->[2]->[0] =~ m%<span trspan="checkUserComputedSession">%,
    'Found trspan="checkUserComputeSession"' )
  or explain( $res->[2]->[0], 'trspan="checkUserComputedSession"' );
ok(
    $res->[2]->[0] =~
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<td scope="row">Macro_1</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $nbr = ( $res->[2]->[0] =~ s%<td scope="row">Macro_1</td>%%g ),
    'Found two well computed macros' )
  or explain( $res->[2]->[0], 'Macros not well computed' );
ok(
    $res->[2]->[0] =~ m%<div class="card-text text-left ml-2">authGroup</div>%,
    'Found group "authGroup"'
) or explain( $res->[2]->[0], 'Group "authgroup"' );
ok(
    $res->[2]->[0] =~
      m%<div class="card-text text-left ml-2">realAuthGroup</div>%,
    'Found group "realAuthGroup"'
) or explain( $res->[2]->[0], 'Found group "realAuthGroup"' );
count(7);

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

$query =~ s/url=/url=test2.example.com/;

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
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok(
    $res->[2]->[0] =~
m%<input id="urlfield" name="url" type="text" class="form-control" value="https://test2.example.com" trplaceholder="URL / DNS" aria-required="true" autocomplete="url" />%,
    'Found HTTPS url'
) or explain( $res->[2]->[0], 'HTTP url' );
count(2);

$client->logout($id);
clean_sessions();

done_testing( count() );
