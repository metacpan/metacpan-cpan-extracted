use warnings;
use Test::More;
use strict;
use IO::String;
use Lemonldap::NG::Common::FormEncode;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

# Initialization
my $op = LLNG::Manager::Test->new(
    {
        ini => {
            domain                          => 'idp.com',
            portal                          => 'http://auth.op.com',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            issuerDBOpenIDConnectActivation => 1,
            issuerDBOpenIDConnectRule       => '$uid eq "french"',
            oidcRPMetaDataExportedVars      => {
                rp1 => {
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
                rp1 => {
                    oidcRPMetaDataOptionsDisplayName           => "RP1",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid1",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                    oidcRPMetaDataOptionsAccessTokenJWT        => 1,
                    oidcRPMetaDataOptionsClientSecret          => "rpid1",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsAllowNativeSso        => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp1.com/',
                },
                rp2 => {
                    oidcRPMetaDataOptionsDisplayName           => "RP2",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid2",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                    oidcRPMetaDataOptionsAccessTokenJWT        => 1,
                    oidcRPMetaDataOptionsClientSecret          => "rpid2",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsAllowNativeSso        => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp2.com/',
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
"response_type=code&scope=openid%20profile%20email%20device_sso&client_id=rpid1&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp1.com%2F";
ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Get authorization code"
);

my ($code) = expectRedirection( $res, qr#http://rp1\.com/\?.*code=([^\&]*)# );

# Exchange code for AT
$query =
"grant_type=authorization_code&code=$code&redirect_uri=http%3A%2F%2Frp1.com%2F";

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid1:rpid1"),
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
my $device_secret = $json->{device_secret};
ok( $device_secret, 'Device secret present' );
my $id_token_payload = id_token_payload($id_token);
ok( $id_token_payload->{ds_hash}, 'Found ds_hash in ID token' );

# Reset conf to make sure to make sure lazy loading works
$op->p->HANDLER->checkConf(1);

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

# Try to get access_token from rp2 using device_secret

$query = build_urlencoded(
    grant_type => 'urn:ietf:params:oauth:grant-type:token-exchange',

    #redirect_uri => 'http://rp1.com/',
    audience           => $id_token_payload->{iss},
    subject_token      => $id_token,
    subject_token_type => 'urn:ietf:params:oauth:token-type:id_token',
    actor_token        => $device_secret,
    actor_token_type   => 'urn:x-oath:params:oauth:token-type:device-secret',
);
ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid2:rpid2"),
        },
    ),
    "Post token"
);

$json = expectJSON($res);
ok( $json->{refresh_token}, 'Get refresh_token' );
ok( $json->{access_token},  'Get access_token' );
expectOK($res);

# Try this access_token
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'application/json',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $json->{access_token},
    },
);

$json = expectJSON($res);
ok(
    (
              $json->{name} eq 'Frédéric Accents'
          and $json->{email} eq 'fa@badwolf.org'
    ),
    'Found attributes'
);

clean_sessions();
done_testing();
