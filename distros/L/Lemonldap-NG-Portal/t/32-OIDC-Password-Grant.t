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
            logLevel     => $debug,
            domain       => 'op.com',
            portal       => 'http://auth.op.com',
            requireToken => 1,
            macros       => {
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
                scopelessrp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "scopelessrp",
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
                },
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
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_cert_op_public_sig,
        }
    }
);
my $res;

# Resource Owner Password Credentials Grant
# Access Token Request
# https://tools.ietf.org/html/rfc6749#section-4.3

# Wrong password should fail
my $query = buildForm( {
        client_id     => 'rpid',
        client_secret => 'rpsecret',
        grant_type    => 'password',
        username      => 'french',
        password      => 'invalid',
        scope         => 'profile email',
    }
);

## Wrong password should fail
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($query),
    accept => 'application/json',
    length => length($query),
);

expectReject( $res, 400, "invalid_grant" );

# Empty scope should fail
my $query = buildForm( {
        client_id     => 'scopelessrp',
        client_secret => 'rpsecret',
        grant_type    => 'password',
        username      => 'french',
        password      => 'french',
    }
);
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($query),
    accept => 'application/json',
    length => length($query),
);

expectReject( $res, 400, "invalid_scope" );

$query = buildForm( {
        client_id     => 'rpid',
        client_secret => 'rpsecret',
        grant_type    => 'password',
        username      => 'french',
        password      => 'french',
        scope         => 'profile email',
    }
);

## Login should be valid
$res = $op->_post(
    "/oauth2/token",
    IO::String->new($query),
    accept => 'application/json',
    length => length($query),
);
my $payload = expectJSON($res);

my $access_token = $payload->{access_token};
ok( $access_token, "Access Token found" );
count(1);

my $token_res_scope = $payload->{scope};
ok( $token_res_scope, "Scope found in token response" );
is( $payload->{id_token}, undef, "No ID token in original request" );

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

$query = "token=$access_token";
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
Time::Fake->offset("+5m");

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
is( $res->{id_token}, undef, "No ID token in refreshed response" );

clean_sessions();
done_testing();

