use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';

# Initialization
my $op = LLNG::Manager::Test->new( {
        ini => {
            logLevel                        => $debug,
            domain                          => 'idp.com',
            portal                          => 'http://auth.op.com',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            issuerDBOpenIDConnectActivation => 1,
            issuerDBOpenIDConnectRule       => '$uid eq "french"',
            oidcRPMetaDataExportedVars      => {
                rp => {
                    email       => "mail",
                    family_name => "cn",
                    name        => "cn"
                }
            },
            oidcServiceMetaDataAuthorizeURI       => "authorize",
            oidcServiceMetaDataCheckSessionURI    => "checksession.html",
            oidcServiceMetaDataJWKSURI            => "jwks",
            oidcServiceMetaDataEndSessionURI      => "logout",
            oidcServiceMetaDataRegistrationURI    => "register",
            oidcServiceMetaDataTokenURI           => "token",
            oidcServiceMetaDataUserInfoURI        => "userinfo",
            oidcServiceAllowHybridFlow            => 1,
            oidcServiceAllowImplicitFlow          => 1,
            oidcServiceAllowDynamicRegistration   => 1,
            oidcServiceAllowAuthorizationCodeFlow => 1,
            oidcRPMetaDataOptions                 => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims         => 1,
                }
            },
            oidcOPMetaDataOptions           => {},
            oidcOPMetaDataJSON              => {},
            oidcOPMetaDataJWKS              => {},
            oidcServiceMetaDataAuthnContext => {
                'loa-4' => 4,
                'loa-1' => 1,
                'loa-5' => 5,
                'loa-2' => 2,
                'loa-3' => 3
            },
            oidcServicePrivateKeySig => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAs2jsmIoFuWzMkilJaA8//5/T30cnuzX9GImXUrFR2k9EKTMt
GMHCdKlWOl3BV+BTAU9TLz7Jzd/iJ5GJ6B8TrH1PHFmHpy8/qE/S5OhinIpIi7eb
ABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH1caJ8lmiERFj7IvNKqEhzAk0pyDr
8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdykX5rx0h5SslG3jVWYhZ/SOb2aIzO
r0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO8093X5VVk9vaPRg0zxJQ0Do0YLyzkR
isSAIFb0tdKuDnjRGK6y/N2j6At2HjkxntbtGQIDAQABAoIBADYq6LxJd977LWy3
0HT9nboFPIf+SM2qSEc/S5Po+6ipJBA4ZlZCMf7dHa6znet1TDpqA9iQ4YcqIHMH
6xZNQ7hhgSAzG9TrXBHqP+djDlrrGWotvjuy0IfS9ixFnnLWjrtAH9afRWLuG+a/
NHNC1M6DiiTE0TzL/lpt/zzut3CNmWzH+t19X6UsxUg95AzooEeewEYkv25eumWD
mfQZfCtSlIw1sp/QwxeJa/6LJw7KcPZ1wXUm1BN0b9eiKt9Cmni1MS7elgpZlgGt
xtfGTZtNLQ7bgDiM8MHzUfPBhbceNSIx2BeCuOCs/7eaqgpyYHBbAbuBQex2H61l
Lcc3Tz0CgYEA4Kx/avpCPxnvsJ+nHVQm5d/WERuDxk4vH1DNuCYBvXTdVCGADf6a
F5No1JcTH3nPTyPWazOyGdT9LcsEJicLyD8vCM6hBFstG4XjqcAuqG/9DRsElpHQ
yi1zc5DNP7Vxmiz9wII0Mjy0abYKtxnXh9YK4a9g6wrcTpvShhIcIb8CgYEAzGzG
lorVCfX9jXULIznnR/uuP5aSnTEsn0xJeqTlbW0RFWLdj8aIL1peirh1X89HroB9
GeTNqEJXD+3CVL2cx+BRggMDUmEz4hR59meZCDGUyT5fex4LIsceb/ESUl2jo6Sw
HXwWbN67rQ55N4oiOcOppsGxzOHkl5HdExKidycCgYEAr5Qev2tz+fw65LzfzHvH
Kj4S/KuT/5V6He731cFd+sEpdmX3vPgLVAFPG1Q1DZQT/rTzDDQKK0XX1cGiLG63
NnaqOye/jbfzOF8Z277kt51NFMDYhRLPKDD82IOA4xjY/rPKWndmcxwdob8yAIWh
efY76sMz6ntCT+xWSZA9i+ECgYBWMZM2TIlxLsBfEbfFfZewOUWKWEGvd9l5vV/K
D5cRIYivfMUw5yPq2267jPUolayCvniBH4E7beVpuPVUZ7KgcEvNxtlytbt7muil
5Z6X3tf+VodJ0Swe2NhTmNEB26uwxzLe68BE3VFCsbSYn2y48HAq+MawPZr18bHG
ZfgMxwKBgHHRg6HYqF5Pegzk1746uH2G+OoCovk5ylGGYzcH2ghWTK4agCHfBcDt
EYqYAev/l82wi+OZ5O8U+qjFUpT1CVeUJdDs0o5u19v0UJjunU1cwh9jsxBZAWLy
PAGd6SWf4S3uQCTw6dLeMna25YIlPh5qPA6I/pAahe8e3nSu2ckl
-----END RSA PRIVATE KEY-----
",
            oidcServicePublicKeySig => "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAs2jsmIoFuWzMkilJaA8/
/5/T30cnuzX9GImXUrFR2k9EKTMtGMHCdKlWOl3BV+BTAU9TLz7Jzd/iJ5GJ6B8T
rH1PHFmHpy8/qE/S5OhinIpIi7ebABqnoVcwDdCa8ugzq8k8SWxhRNXfVIlwz4NH
1caJ8lmiERFj7IvNKqEhzAk0pyDr8hubveTC39xREujKlsqutpPAFPJ3f2ybVsdy
kX5rx0h5SslG3jVWYhZ/SOb2aIzOr0RMjhQmsYRwbpt3anjlBZ98aOzg7GAkbO80
93X5VVk9vaPRg0zxJQ0Do0YLyzkRisSAIFb0tdKuDnjRGK6y/N2j6At2Hjkxntbt
GQIDAQAB
-----END PUBLIC KEY-----
",
        }
    }
);
my $res;

my $url   = "/";
my $query = "user=french&password=french";
$res = $op->_post(
    "/",
    IO::String->new($query),
    accept => 'text/html',
    length => length($query),
);
my $idpId = expectCookie($res);

my $query =
    "response_type=code&scope=openid%20profile%20email&"
  . "client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Ftest%2F";
$res = $op->_get(
    "/oauth2/authorize",
    query  => "$query",
    accept => 'text/html',
    cookie => "lemonldap=$idpId",
);

my ($code) = expectRedirection( $res, qr#http://test/.*code=([^\&]*)# );

$query =
  "grant_type=authorization_code&code=$code&redirect_uri=http%3A%2F%2Ftest%2F";

$res = $op->_post(
    "/oauth2/token",
    IO::String->new($query),
    accept => 'application/json',
    length => length($query),
    custom => {
        HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpsecret"),
    },
);

my $json          = expectJSON($res);
my $access_token  = $json->{access_token};
my $refresh_token = $json->{refresh_token};
my $id_token      = $json->{id_token};
ok( $access_token,  "Got access token" );
ok( $refresh_token, "Got refresh token" );
ok( $id_token,      "Got ID token" );

my $id_token_payload = JSON::from_json(decode_base64([split /\./, $id_token]->[1]));
is($id_token_payload->{name}, 'Frédéric Accents', 'Found claim in ID token');

# Get userinfo
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'application/json',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $access_token,
    },
);

$json = expectJSON($res);

ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );

# Skip ahead in time
Time::Fake->offset("+2h");

# Access token should have expired
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'application/json',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $access_token,
    },
);

is( $res->[0], 401, "Access token refused" );

# Refresh access token

$query = "grant_type=refresh_token&refresh_token=$refresh_token";

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpsecret"),
        },
    ),
    "Refresh access token"
);
expectOK($res);

$json         = expectJSON($res);
$access_token = $json->{access_token};
$id_token     = $json->{id_token};
ok( $access_token,                   "Got refreshed Access token" );
ok( $id_token,                       "Got refreshed ID token" );
ok( !defined $json->{refresh_token}, "Refresh token not present" );

$id_token_payload = JSON::from_json(decode_base64([split /\./, $id_token]->[1]));
is($id_token_payload->{name}, 'Frédéric Accents', 'Found claim in ID token');

# Try refreshed access token
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'application/json',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $access_token,
    },
);

$json = expectJSON($res);

ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );

# Check failure conditions
$op->logout($idpId);

# Refresh access token

$query = "grant_type=refresh_token&refresh_token=$refresh_token";

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpsecret"),
        },
    ),
    "Refresh access token"
);

is( $res->[0], 401, "Cannot use refresh token tied to expired session" );

## Get userinfo again
ok(
    $res = $op->_post(
        "/oauth2/userinfo",
        IO::String->new(''),
        accept => 'text/html',
        length => 0,
        custom => {
            HTTP_AUTHORIZATION => "Bearer " . $access_token,
        },
    ),
    "Post new access token"
);
is( $res->[0], 401,
    "Cannot use refreshed access token tied to expired session" );

clean_sessions();
done_testing();

