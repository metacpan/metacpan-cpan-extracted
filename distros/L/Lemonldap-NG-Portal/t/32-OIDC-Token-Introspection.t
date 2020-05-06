use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
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
                },
                rp2 => {
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
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                },
                oauth => {
                    oidcRPMetaDataOptionsDisplayName  => "oauth",
                    oidcRPMetaDataOptionsClientID     => "oauth",
                    oidcRPMetaDataOptionsClientSecret => "service",
                    oidcRPMetaDataOptionsUserIDAttr   => "",
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
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_key_op_public_sig,
        }
    }
);
my $res;

# Authenticate to LLNG
my $url   = "/";
my $query = "user=french&password=french";
ok(
    $res = $op->_post(
        "/",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Post authentication"
);
my $idpId = expectCookie($res);

# Get code for RP1
$query =
"response_type=code&scope=openid%20profile%20email&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp2.com%2F";
ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Get authorization code"
);

my ($code) = expectRedirection( $res, qr#http://rp2\.com/.*code=([^\&]*)# );

# Exchange code for AT
$query =
"grant_type=authorization_code&code=$code&redirect_uri=http%3A%2F%2Frp2.com%2F";

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
my $json  = from_json( $res->[2]->[0] );
my $token = $json->{access_token};
ok( $token, 'Access token present' );

$query = "token=$token";

ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
    ),
    "Try introspection without authentication"
);

expectReject($res);

ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'text/html',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:service"),
        },
    ),
    "Post introspection"
);

expectOK($res);
$json = from_json( $res->[2]->[0] );
ok( $json->{active}, "Token is valid" );
is( $json->{sub}, "french", "Response contains the correct sub" );
is( $json->{iss}, "http://auth.op.com",
    "Response contains the correct issuer" );
is( $json->{client_id}, "rpid", "Response contains the correct client id" );
like( $json->{scope}, qr/\bopenid\b/,  "Response contains the correct scopes" );
like( $json->{scope}, qr/\bprofile\b/, "Response contains the correct scopes" );
like( $json->{scope}, qr/\bemail\b/,   "Response contains the correct scopes" );

# Check status after expiration
Time::Fake->offset("+2h");

$query = "token=$token";
ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'text/html',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:service"),
        },
    ),
    "Post introspection"
);

$res = expectJSON($res);
ok( !$res->{active}, "Token is no longer valid" );

clean_sessions();
done_testing();

