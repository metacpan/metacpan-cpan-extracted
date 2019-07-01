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
            totp2fSelfRegistration         => 1,
            totp2fActivation               => 1,
            totp2fDigits                   => 6,

            #hiddenAttributes               => 'test',
        }
    }
);

ok( $res = $client->_get( '/checkuser', accept => 'text/html' ),
    'Test unauth redirection' );
expectRedirection( $res,
    'http://auth.example.com/?url=aHR0cDovL2F1dGguZXhhbXBsZS5jb20vY2hlY2t1c2Vy'
);
count(1);

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
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27,
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

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

# TOTP form
ok(
    $res = $client->_get(
        '/2fregisters',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'Form registration'
);
expectRedirection( $res, qr#/2fregisters/totp$# );
ok(
    $res = $client->_get(
        '/2fregisters/totp',
        cookie => "lemonldap=$id",
        accept => 'text/html',
    ),
    'Form registration'
);
ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

# JS query
ok(
    $res = $client->_post(
        '/2fregisters/totp/getkey', IO::String->new(''),
        cookie => "lemonldap=$id",
        length => 0,
    ),
    'Get new key'
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
my ( $key, $token );
ok( $key   = $res->{secret}, 'Found secret' );
ok( $token = $res->{token},  'Found token' );
$key = Convert::Base32::decode_base32($key);

# Post code
my $code;
ok( $code = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 ),
    'Code' );
ok( $code =~ /^\d{6}$/, 'Code contains 6 digits' );
my $s = "code=$code&token=$token";
ok(
    $res = $client->_post(
        '/2fregisters/totp/verify',
        IO::String->new($s),
        length => length($s),
        cookie => "lemonldap=$id",
    ),
    'Post code'
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
ok( $res->{result} == 1, 'Key is registered' );
count(12);

# Try to sign-in
$client->logout($id);
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html',
    ),
    'Auth query'
);
my ( $host, $url, $query ) = expectForm( $res, undef, '/totp2fcheck', 'token' );

# Generate TOTP with LLNG

my $totp = Lemonldap::NG::Common::TOTP::_code( undef, $key, 0, 30, 6 );

$query =~ s/code=/code=$code/;
ok(
    $res = $client->_post(
        '/totp2fcheck',
        IO::String->new($query),
        length => length($query),
    ),
    'Post code'
);
$id = expectCookie($res);

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
count(3);

my ( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok( $res->[2]->[0] =~ m%<td scope="row">_user</td>%, 'Found attribute _user' )
  or explain( $res->[2]->[0], 'Attribute _user' );
ok( $res->[2]->[0] =~ m%<td scope="row">dwho</td>%, 'Found value dwho' )
  or explain( $res->[2]->[0], 'Value dwho' );
ok( $res->[2]->[0] !~ m%_2fDevices</td>%, '_2fDevices NOT Found!' )
  or explain( $res->[2]->[0], 'Value _2fDevices' );
count(4);

$query =~ s/url=/url=http%3A%2F%2Ftest1.example.com/;
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

count(2);
ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%: dwho<br/>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Header Value: dwho' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td scope="row">dwho</td>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Macro Value dwho' );
count(3);

# Request with bad VH
$query =~ s/user=dwho/user=rtyler/;
$query =~
  s/url=http%3A%2F%2Ftest1.example.com/url=http%3A%2F%2Ftry.example.com/;
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

# Request with forbidden URL
$query =~
s#url=http%3A%2F%2Ftry.example.com#url=http%3A%2F%2Fauth.example.com/checkuser#;
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
m%<div class="alert alert-danger"><div class="text-center"><b><span trspan="forbidden"></span></b></div></div>%,
    'Found trspan="forbidden"'
) or explain( $res->[2]->[0], 'trspan="forbidden"' );
count(2);

# Request with good VH & user
$query =~
s#url=http%3A%2F%2Fauth.example.com%2Fcheckuser#url=hTTp%3A%2F%2FTest1.exAmple.cOm/UriTesT#;
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
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );
ok( $res->[2]->[0] =~ m%<span trspan="groups_sso">%,
    'Found trspan="groups_sso"' )
  or explain( $res->[2]->[0], 'trspan="groups_sso"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%: rtyler<br/>%, 'Found rtyler' )
  or explain( $res->[2]->[0], 'Header Value: rtyler' );
ok( $res->[2]->[0] =~ m%<div class="col">su</div>%, 'Found su' )
  or explain( $res->[2]->[0], 'SSO Groups: su' );
ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
count(11);

my @c = ( $res->[2]->[0] =~ /<td scope="row">rtyler<\/td>/gs );
ok( @c == 3, ' -> Three entries found' );
count(1);

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
m%<div class="alert alert-success"><div class="text-center"><b><span trspan="allowed"></span></b></div></div>%,
    'Found trspan="allowed"'
) or explain( $res->[2]->[0], 'trspan="allowed"' );
ok( $res->[2]->[0] =~ m%<span trspan="headers">%, 'Found trspan="headers"' )
  or explain( $res->[2]->[0], 'trspan="headers"' );
ok( $res->[2]->[0] =~ m%<span trspan="groups_sso">%,
    'Found trspan="groups_sso"' )
  or explain( $res->[2]->[0], 'trspan="groups_sso"' );
ok( $res->[2]->[0] =~ m%<span trspan="attributes">%,
    'Found trspan="attributes"' )
  or explain( $res->[2]->[0], 'trspan="attributes"' );
ok( $res->[2]->[0] =~ m%<span trspan="macros">%, 'Found trspan="macros"' )
  or explain( $res->[2]->[0], 'trspan="macros"' );
ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%: rtyler<br/>%, 'Found rtyler' )
  or explain( $res->[2]->[0], 'Header Value: rtyler' );
ok( $res->[2]->[0] =~ m%<div class="col">su</div>%, 'Found su' )
  or explain( $res->[2]->[0], 'SSO Groups: su' );
ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
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
$query =~ s/user=msmith/user=dalek/;
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
