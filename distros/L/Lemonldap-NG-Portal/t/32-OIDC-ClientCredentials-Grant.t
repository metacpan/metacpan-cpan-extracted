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
            domain                          => 'op.com',
            portal                          => 'http://auth.op.com',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            customPlugins                   => 't::OidcHookPlugin',
            issuerDBOpenIDConnectActivation => 1,
            oidcRPMetaDataExportedVars      => {
                rp => {
                    "name"               => "mymacro",
                    "preferred_username" => "hooked_username",
                }
            },
            oidcRPMetaDataMacros => {
                rp => {
                    "mymacro" => "'foo'",
                }
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName                 => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration           => 3600,
                    oidcRPMetaDataOptionsClientID                    => "rpid",
                    oidcRPMetaDataOptionsAllowOffline                => 1,
                    oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg              => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims    => 1,
                    oidcRPMetaDataOptionsRule => '$_scope =~ /\bread\b/',
                },
                scopelessrp => {
                    oidcRPMetaDataOptionsDisplayName       => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                    oidcRPMetaDataOptionsClientID          => "scopelessrp",
                    oidcRPMetaDataOptionsAllowOffline      => 1,
                    oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg              => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims    => 1,
                    oidcRPMetaDataOptionsRule                  => '',
                },
                pubrp => {
                    oidcRPMetaDataOptionsAccessTokenExpiration       => 3600,
                    oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                    oidcRPMetaDataOptionsAllowOffline                => 1,
                    oidcRPMetaDataOptionsBypassConsent               => 1,
                    oidcRPMetaDataOptionsClientID                    => "rpid2",
                    oidcRPMetaDataOptionsDisplayName                 => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration           => 3600,
                    oidcRPMetaDataOptionsIDTokenForceClaims          => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg              => "HS512",
                    oidcRPMetaDataOptionsPublic                      => 1,
                    oidcRPMetaDataOptionsRule       => '$uid eq "french"',
                    oidcRPMetaDataOptionsUserIDAttr => "",
                }
            },
            oidcRPMetaDataScopeRules => {
                rp => {
                    "read"   => '$requested',
                    "always" => '1',
                },
            },
            oidcServicePrivateKeySig      => oidc_key_op_private_sig,
            oidcServicePublicKeySig       => oidc_cert_op_public_sig,
            loginHistoryEnabled           => 1,
            bruteForceProtection          => 1,
            bruteForceProtectionTempo     => 5,
            bruteForceProtectionMaxFailed => 4,
            failedLoginNumber             => 6,
            successLoginNumber            => 4,
        }
    }
);
my $res;

# Resource Owner Password Credentials Grant
# Access Token Request
# https://tools.ietf.org/html/rfc6749#section-4.3
my $badquery = buildForm( {
        client_id  => 'rpid2',
        grant_type => 'client_credentials',
        scope      => 'openid profile email',
    }
);

my $badquery2 = buildForm( {
        client_id     => 'rpid',
        client_secret => 'rpsecret',
        grant_type    => 'client_credentials',
        scope         => 'openid profile email',
    }
);

my $badquery3 = buildForm( {
        client_id     => 'scopelessrp',
        client_secret => 'rpsecret',
        grant_type    => 'client_credentials',
    }
);

my $goodquery = buildForm( {
        client_id     => 'rpid',
        client_secret => 'rpsecret',
        grant_type    => 'client_credentials',
        scope         => 'read profile',
    }
);

## Test a public RP
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($badquery),
    accept => 'application/json',
    length => length($badquery),
);
expectBadRequest($res);

## Test failing rule
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($badquery2),
    accept => 'application/json',
    length => length($badquery2),
);
expectBadRequest($res);

## Test empty scope
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($badquery3),
    accept => 'application/json',
    length => length($badquery3),
);
expectReject( $res, 400, "invalid_scope" );

## Test a confidential RP
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($goodquery),
    accept => 'application/json',
    length => length($goodquery),
);
my $payload = expectJSON($res);

my $access_token = $payload->{access_token};
ok( $access_token, "Access Token found" );
count(1);
my $token_res_scope = $payload->{scope};
ok( $token_res_scope, "Token response returned scope" );

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

$payload = expectJSON($res);

is( $payload->{sub},                'rpid' );
is( $payload->{name},               'foo' );
is( $payload->{preferred_username}, 'hook' );

my $query = "token=$access_token";
ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'text/html',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpsecret"),
        },
    ),
    "Post introspection"
);
$payload = expectJSON($res);
like( $payload->{scope}, qr/\bread\b/,   "Scope read found" );
like( $payload->{scope}, qr/\balways\b/, "Rule-enforced scope found" );
is( $token_res_scope, $payload->{scope},
    "Token response scope match token scope" );

clean_sessions();
done_testing();

