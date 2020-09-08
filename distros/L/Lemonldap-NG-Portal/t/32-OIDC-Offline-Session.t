use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

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
            oidcRPMetaDataMacros => {
                rp => {
                    custom_sub => '"custom".$uid',
                }
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "custom_sub",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims    => 1,
                    oidcRPMetaDataOptionsAdditionalAudiences =>
                      "http://my.extra.audience/test urn:extra2",

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

my $url   = "/";
my $query = "user=french&password=french";
$res = $op->_post(
    "/",
    IO::String->new($query),
    accept => 'text/html',
    length => length($query),
);
my $idpId = expectCookie($res);

# Include a weird scope name, to make sure they work (#2168)
$query =
    "response_type=code&scope=openid%20profile%20email%20"
  . "offline_access%20%21weird%3Ascope.name~&"
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
    accept => 'text/html',
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

my $id_token_payload = id_token_payload($id_token);
is( $id_token_payload->{name}, 'Frédéric Accents',
    'Found claim in ID token' );
is( $id_token_payload->{sub}, 'customfrench', 'Found sub in ID token' );

# Get userinfo
$res = $op->_post(
    "/oauth2/userinfo",
    IO::String->new(''),
    accept => 'text/html',
    length => 0,
    custom => {
        HTTP_AUTHORIZATION => "Bearer " . $access_token,
    },
);

$json = expectJSON($res);

ok( $json->{'name'} eq "Frédéric Accents", 'Got User Info' );
ok( $json->{'sub'} eq "customfrench",              'Got User Info' );

$op->logout($idpId);

# Refresh access token after logging out

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
    "Refresh access token (after logout)"
);
expectOK($res);

$json         = expectJSON($res);
$access_token = $json->{access_token};
my $refresh_token2 = $json->{refresh_token};
$id_token = $json->{id_token};
ok( $access_token,            "Got refreshed Access token" );
ok( $id_token,                "Got refreshed ID token" );
ok( !defined $refresh_token2, "Refresh token not present" );

$id_token_payload = id_token_payload($id_token);
is( $id_token_payload->{name}, 'Frédéric Accents',
    'Found claim in ID token' );
is( $id_token_payload->{sub}, 'customfrench', 'Found sub in ID token' );

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
expectOK($res);
$json = expectJSON($res);

ok( $json->{name} eq "Frédéric Accents", "Correct user info" );
ok( $json->{'sub'} eq "customfrench",            'Got User Info' );

# Make sure offline session is still valid long after natural session expiration time

Time::Fake->offset("+10d");

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
    "Refresh access token (in the future)"
);
expectOK($res);

$json           = expectJSON($res);
$access_token   = $json->{access_token};
$refresh_token2 = $json->{refresh_token};
$id_token       = $json->{id_token};
ok( $access_token,            "Got refreshed Access token" );
ok( $id_token,                "Got refreshed ID token" );
ok( !defined $refresh_token2, "Refresh token not present" );

$id_token_payload = id_token_payload($id_token);
is( $id_token_payload->{name}, 'Frédéric Accents',
    'Found claim in ID token' );
ok( ( grep { $_ eq "rpid" } @{ $id_token_payload->{aud} } ),
    'Check that clientid is in audience' );
ok( (
        grep { $_ eq "http://my.extra.audience/test" }
          @{ $id_token_payload->{aud} }
    ),
    'Check for additional audiences'
);
ok( ( grep { $_ eq "urn:extra2" } @{ $id_token_payload->{aud} } ),
    'Check for additional audiences' );

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
expectOK($res);
$json = expectJSON($res);

ok( $json->{name} eq "Frédéric Accents", "Correct user info" );
ok( $json->{'sub'} eq "customfrench",            'Got User Info' );

## Test introspection of refreshed token #2171
my $req = 'client_id=rpid&client_secret=rpsecret&token=' . $access_token;
ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($req),
        accept => 'application/json',
        length => length($req),
    ),
    "Post new access token"
);
$json = expectJSON($res);

is( $json->{active},    1,        'Token is active' );
is( $json->{client_id}, 'rpid',   'Introspection contains client_id' );
is( $json->{sub},       'customfrench', 'Introspection contains sub' );

# #2168
ok( ( grep { $_ eq "!weird:scope.name~" } ( split /\s+/, $json->{scope} ) ),
    "Scope contains weird scope name" );

clean_sessions();
done_testing();

