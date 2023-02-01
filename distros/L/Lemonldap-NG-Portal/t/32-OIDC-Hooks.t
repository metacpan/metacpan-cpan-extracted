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
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsAccessTokenJWT        => 1,
                    oidcRPMetaDataOptionsClientSecret          => "rpid",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                },
                oauth => {
                    oidcRPMetaDataOptionsDisplayName  => "oauth",
                    oidcRPMetaDataOptionsClientID     => "oauth",
                    oidcRPMetaDataOptionsClientSecret => "service",
                    oidcRPMetaDataOptionsUserIDAttr   => "",
                }
            },
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            customPlugins            => 't::OidcHookPlugin',
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

my ($code) =
  expectRedirection( $res, qr#http://rp2\.com/\?hooked=1.*code=([^\&]*)# );

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
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpid"),
        },
    ),
    "Post token"
);
my $json  = from_json( $res->[2]->[0] );
my $token = $json->{access_token};
ok( $token, 'Access token present' );
my $id_token = $json->{id_token};
ok( $id_token, 'ID token present' );
my $refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Refresh token present' );
my $id_token_payload = id_token_payload($id_token);
is( $id_token_payload->{id_token_hook}, 1, "Found hooked claim in ID token" );

# Get userinfo
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'application/json',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $token,
    },
);

$json = expectJSON($res);
is( $json->{userinfo_hook}, 1, "Found hooked claim in Userinfo token" );
is( $json->{_auth}, "Demo",    "Found session variable in Userinfo token" );
like( $json->{_scope}, qr/\bopenid\b/, "Scopes are visible in hook" );

expectJWT( $token, access_token_hook => 1 );

# Introspect to find scopes
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

expectOK($res);
$json = from_json( $res->[2]->[0] );
like( $json->{scope}, qr/\bmy_hooked_scope\b/, "Found hook defined scope" );
like( $json->{scope}, qr/\bmyscope\b/, "Found result of oidcResolveScope" );

# Refresh access token
$res  = refreshGrant( $op, 'rpid', $refresh_token );
$json = expectJSON($res);

$token = $json->{access_token};
ok( $token, 'Access token present' );

# Make sure the Refresh hook added a scope to the token
expectJWT( $token,
    scope =>
      "openid profile email my_hooked_scope myscope refreshed_online_french" );

## Test Offline refresh hook
$code = codeAuthorize(
    $op, $idpId,
    {
        response_type => 'code',
        scope         => 'openid profile email offline_access',
        client_id     => 'rpid',
        state         => 'af0ifjsldkj',
        redirect_uri  => 'http://rp2.com/',
    }
);

$json = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp2.com/" ) );
$refresh_token = $json->{refresh_token};
ok( $refresh_token, 'Refresh token present' );

$json = expectJSON( refreshGrant( $op, 'rpid', $refresh_token ) );
expectJWT( $json->{access_token},
    scope => "openid profile email my_hooked_scope myscope refreshed_french" );

clean_sessions();
done_testing();

