use Test::More;
use strict;
use IO::String;
use JSON;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                  => 'error',
            authentication            => 'Demo',
            userDB                    => 'Same',
            loginHistoryEnabled       => 0,
            brutForceProtection       => 0,
            requireToken              => 0,
            checkUser                 => 1,
            checkUserIdRule           => '$uid ne "msmith"',
            checkUserSearchAttributes => 'employee_nbr  test1 _user test2 mail',
            checkUserDisplayPersistentInfo => 1,
            checkUserDisplayEmptyHeaders   => '$uid eq "dwho"',
            checkUserDisplayEmptyValues    => '$uid eq "dwho"',
            totp2fSelfRegistration         => 1,
            totp2fActivation               => 1,
            totp2fDigits                   => 6,
            totp2fAuthnLevel               => 8,
            impersonationRule              => 1
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

( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok( $res->[2]->[0] =~ m%<td scope="row">_user</td>%, 'Found attribute _user' )
  or explain( $res->[2]->[0], 'Attribute _user' );
ok( $res->[2]->[0] =~ m%<td scope="row">dwho</td>%, 'Found value dwho' )
  or explain( $res->[2]->[0], 'Value dwho' );
ok( $res->[2]->[0] !~ m%_2fDevices</td>%, '_2fDevices NOT Found!' )
  or explain( $res->[2]->[0], 'Value _2fDevices' );

ok( $res->[2]->[0] =~ m%<td scope="row">authMode</td>%, 'Found macro authMode' )
  or explain( $res->[2]->[0], 'Macro Key authMode' );
ok( $res->[2]->[0] =~ m%<td scope="row">real_authMode</td>%,
    'Found macro real_authMode' )
  or explain( $res->[2]->[0], 'Macro Key real_authMode' );
ok( $res->[2]->[0] =~ m%<td scope="row">TOTP</td>%, 'Found TOTP' )
  or explain( $res->[2]->[0], 'Macro Value TOTP' );
count(7);

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
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
count(2);

ok( $res->[2]->[0] =~ m%Auth-User: %, 'Found Auth-User' )
  or explain( $res->[2]->[0], 'Header Key: Auth-User' );
ok( $res->[2]->[0] =~ m%testHeader1: %, 'Found testHeader1' )
  or explain( $res->[2]->[0], 'Header Key: testHeader1' );
ok( $res->[2]->[0] =~ m%testHeader2: %, 'Found testHeader2' )
  or explain( $res->[2]->[0], 'Header Key: testHeader2' );
ok( $res->[2]->[0] =~ m%emptyHeader: %, 'Found emptyHeader' )
  or explain( $res->[2]->[0], 'Header Key: emptyHeader' );
ok( $res->[2]->[0] =~ m%: dwho<br/>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Header Value: dwho' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
ok( $res->[2]->[0] =~ m%<td scope="row">dwho</td>%, 'Found dwho' )
  or explain( $res->[2]->[0], 'Macro Value dwho' );
ok( $res->[2]->[0] =~ m%<td scope="row">array</td>%, 'Found empty macro' )
  or explain( $res->[2]->[0], 'Macro: empty' );
ok( $res->[2]->[0] =~ m%<td scope="row">real_array</td>%,
    'Found empty real_macro' )
  or explain( $res->[2]->[0], 'Macro: empty real' );
count(9);

# Request with mail
$query =~ s/user=dwho/user=dwho%40badwolf.org/;
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
ok( $res->[2]->[0] =~ m%value="dwho\@badwolf.org" trplaceholder="user"%,
    'Found trplaceholder with mail' )
  or explain( $res->[2]->[0], 'trplaceholder with mail' );
count(3);
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
$query =~ s/user=dwho%40badwolf.org/user=rtyler/;
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

# Request with forbidden URL proteced by extended function
$query =~
s#url=http%3A%2F%2Fauth.example.com%2Fcheckuser#url=http%3A%2F%2Ftest1.example.com/test-restricted_uri/rtyler#;
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

# Request with allowed URL protected by extended function
$query =~
s#url=http%3A%2F%2Ftest1.example.com%2Ftest-restricted_uri%2Frtyler#url=http%3A%2F%2Ftest1.example.com/test-restricted_uri/rtyler/#;
ok(
    $res = $client->_post(
        '/checkuser',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),

        #accept => 'text/html',
    ),
    'POST checkuser'
);
my $json;
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{URL} eq 'http://test1.example.com/test-restricted_uri/rtyler/',
    'Find well formated URL' )
  or explain( $json, "Find expected URL" );
ok( $json->{ALLOWED} eq 'allowed', 'Find "allowed"' )
  or explain( $json, 'Find "allowed"' );
ok( $json->{ALERTE} eq 'alert-info', 'Find "alert-info"' )
  or explain( $json, "Find alert-info" );
ok( $json->{ALERTE_AUTH} eq 'alert-success', 'Find "alert-success"' )
  or explain( $json, 'Find "alert-success"' );
ok( $json->{LOGIN} eq 'rtyler', 'Find "rtyler"' )
  or explain( $json, 'Find login "rtyler"' );
ok( $json->{MSG} eq 'checkUser', 'Find "checkUser"' )
  or explain( $json, 'Find message "checkUser"' );
count(8);

# Request with good VH & user
$query = 'url=hTTp%3A%2F%2FTest1.exAmple.cOm/UriTesT&user=rtyler';
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
ok( $res->[2]->[0] =~ m%<div class="card-text text-left ml-2">su</div>%,
    'Found su' )
  or explain( $res->[2]->[0], 'SSO Groups: su' );
ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $res->[2]->[0] =~ m%<td scope="row">_whatToTrace</td>%,
    'Found _whatToTrace' )
  or explain( $res->[2]->[0], 'Macro Key _whatToTrace' );
count(11);

my @c = ( $res->[2]->[0] =~ /<td scope="row">rtyler<\/td>/gs );
ok( @c == 6, ' -> Six entries found' )
  or explain( $res->[2]->[0] );
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
ok( $res->[2]->[0] =~ m%<div class="card-text text-left ml-2">su</div>%,
    'Found su' )
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
m%<div class="alert alert-warning alert"><div class="text-center"><span trspan="PE5"></span></div></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], 'PE5 - Forbidden identity' );
count(2);

# Request an unknown identity
$query =~ s/user=msmith/user=spoke/;
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
m%<div class="alert alert-warning alert"><div class="text-center"><span trspan="PE5"></span></div></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], 'PE5 - Unknown identity' );
count(2);

# Request an invalid identity
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
m%<div class="alert alert-warning alert"><div class="text-center"><span trspan="PE5"></span></div></div>%,
    ' PE5 found'
) or explain( $res->[2]->[0], 'PE5 - invalid identity' );
count(2);

$client->logout($id);
clean_sessions();

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

( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );

# Request a user without SSO session
$query =~ s/user=dwho/user=rtyler/;
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
ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found uid' )
  or explain( $res->[2]->[0], 'Attribute Value uid' );
ok( $res->[2]->[0] =~ m%<td scope="row">real_uid</td>%, 'Found real_uid' )
  or explain( $res->[2]->[0], 'Attribute Value real_uid' );
count(4);

$client->logout($id);
clean_sessions();
done_testing( count() );
