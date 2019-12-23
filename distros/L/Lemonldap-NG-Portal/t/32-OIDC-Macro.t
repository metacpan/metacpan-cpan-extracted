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
my $res;
my $url;

# Initialization
ok( my $op = op(), 'OP portal' );

ok( $res = $op->_get('/oauth2/jwks'), 'Get JWKS,     endpoint /oauth2/jwks' );
expectOK($res);
my $jwks = $res->[2]->[0];

ok(
    $res = $op->_get('/.well-known/openid-configuration'),
    'Get metadata, endpoint /.well-known/openid-configuration'
);
expectOK($res);
my $metadata = $res->[2]->[0];

my $query =
"response_type=code&scope=openid%20profile%20email&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp.com%2F";

# Push request to OP
ok(
    $res =
      $op->_get( "/oauth2/authorize", query => $query, accept => 'text/html' ),
    "Start Authorization Code flow"
);
expectOK($res);

# Try to authenticate to OP
$query = "user=french&password=french&$query";
ok(
    $res = $op->_post(
        "/oauth2/authorize",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Post authentication,        endpoint $url"
);
my $idpId = expectCookie($res);
my ($code) = expectRedirection( $res, qr#http://rp.com/\?.*code=([^&]+)# );

# Get access token
$query =
"grant_type=authorization_code&code=$code&redirect_uri=http%3A%2F%2Frp.com%2F";

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
    "Post token"
);

my $tokenresp = JSON::from_json( $res->[2]->[0] );
ok( my $access_token = $tokenresp->{access_token}, 'Found access token' );

# Get Userinfo
ok(
    $res = $op->_get(
        "/oauth2/userinfo",
        accept => 'text/html',
        custom => {
            HTTP_AUTHORIZATION => "Bearer " . $access_token,
        },
    ),
    "Post token"
);

my $userinfo = JSON::from_json( $res->[2]->[0] );
is( $userinfo->{family_name}, 'Accents', 'Correct macro value' );

clean_sessions();
done_testing();

sub op {
    return LLNG::Manager::Test->new( {
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
                        family_name => "extract_sn",
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
                oidcRPMetaDataMacros                => {
                    rp => {
                        extract_sn => '(split(/\s/, $cn))[1]',
                    }
                },
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 1,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
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
}

