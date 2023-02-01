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
            logLevel            => $debug,
            domain              => 'op.com',
            portal              => 'http://auth.op.com',
            authChoiceAuthBasic => "MyChoice",
            authentication      => 'Choice',
            userDB              => 'Same',
            'authChoiceModules' => {
                'MyChoice' => 'Demo;Demo;Null;;;{}'
            },

            macros => {
                gender       => '"32"',
                _whatToTrace => '$uid',
                nickname     => '"froggie; frenchie"',
            },
            issuerDBOpenIDConnectActivation => 1,
            oidcRPMetaDataExportedVars      => {
                rp => {
                    email              => "mail;string;always",
                    preferred_username => "uid",
                    name               => "cn",
                    gender             => "gender;int;auto",
                    nickname           => "nickname",
                }
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsAllowPasswordGrant    => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpsecret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 120,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims    => 1,
                    oidcRPMetaDataOptionsRule => '$uid eq "french"',
                }
            },
            oidcRPMetaDataScopeRules => {
                rp => {
                    "read"   => '$requested',
                    "french" => '$uid eq "french"',
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
        client_id     => 'rpid',
        client_secret => 'rpsecret',
        grant_type    => 'password',
        username      => 'french',
        password      => 'hacker',
        scope         => 'openid profile email',
    }
);
my $goodquery = buildForm( {
        client_id     => 'rpid',
        client_secret => 'rpsecret',
        grant_type    => 'password',
        username      => 'french',
        password      => 'french',
        scope         => 'profile email openid',
    }
);

## Brute-force the endpoint
for ( 1 .. 10 ) {
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($badquery),
        accept => 'application/json',
        length => length($badquery),
    );
}

## Make sure a valid login fails
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($goodquery),
    accept => 'application/json',
    length => length($goodquery),
);
expectBadRequest($res);

# Wait out the brute force protection
Time::Fake->offset("+300s");

## Login should now be valid
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
ok( $token_res_scope,     "Scope found in token response" );
ok( $payload->{id_token}, "Found ID token in original grant" );

my $refresh_token = $payload->{refresh_token};
ok( $refresh_token, "Got refresh token" );
count(3);

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

ok( $payload->{'name'} eq "Frédéric Accents", 'Got User Info' );
like( $res->[2]->[0], qr/"gender":32/, "Attribute released as int in JSON" );
is( ref( $payload->{email} ),
    "ARRAY", "Single valued attribute forced as array" );
is( ref( $payload->{nickname} ),
    "ARRAY", "Multi valued attribute exposed as array" );

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
unlike( $payload->{scope}, qr/\bread\b/,
    "Scope read not asked, and thus not found" );
like( $payload->{scope}, qr/\bfrench\b/, "Attribute-based scope found" );
like( $payload->{scope}, qr/\balways\b/, "Rule-enforced scope found" );
is( $payload->{scope}, $token_res_scope,
    "Token response scope matches token scope" );

# Expire token
Time::Fake->offset("+305m");

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

$res = expectJSON($res);
is( $res->{active}, 0, "Token is no longer active" );

$query = buildForm( {
        grant_type    => 'refresh_token',
        refresh_token => $refresh_token,
    }
);

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/json',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:rpsecret"),
        },
    ),
    "Post introspection"
);
$res = expectJSON($res);
ok( $res->{id_token}, "Found ID token in refresh grant" );

clean_sessions();
done_testing();

