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
            logLevel       => $debug,
            domain         => 'op.com',
            portal         => 'http://auth.op.com',
            authentication => 'Demo',
            userDB         => 'Same',
            macros         => {
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
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims    => 1,
                    oidcRPMetaDataOptionsRule => '$uid eq "french"',
                }
            },
            oidcServicePrivateKeySig      => oidc_key_op_private_sig,
            oidcServicePublicKeySig       => oidc_key_op_public_sig,
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
        scope         => 'openid profile email',
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

clean_sessions();
done_testing();

