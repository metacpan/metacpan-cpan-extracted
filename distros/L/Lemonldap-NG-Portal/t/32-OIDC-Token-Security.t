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
            oidcServiceAllowHybridFlow            => 1,
            oidcServiceAllowImplicitFlow          => 1,
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
                rp2 => {
                    oidcRPMetaDataOptionsDisplayName           => "RP2",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rp2id",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rp2secret",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRule => '$uid eq "dwho"',
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
count(1);
my $idpId = expectCookie($res);

# Try to get code for RP1 with invalide scope name
$query =
"response_type=code&scope=openid%20profile%20email%22&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp2.com%2F";
ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Get authorization code for rp1"
);
count(1);
expectPortalError( $res, 24, "Invalid scope" );
#
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
    "Get authorization code for rp1"
);
count(1);

my ($code) = expectRedirection( $res, qr#http://rp2\.com/.*code=([^\&]*)# );

# Play code on RP2
$query = buildForm( {
        grant_type   => 'authorization_code',
        code         => $code,
        redirect_uri => 'http://rp2.com/',
    }
);

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rp2id:rp2secret"),
        },
    ),
    "Post token on wrong RP"
);
count(1);

# Expect an invalid request
expectReject( $res, 400, "invalid_grant" );

is( getHeader( $res, "Access-Control-Allow-Origin" ),
    "*", "CORS header present on Token error response" );
count(1);

# Get new code for RP1
$query =
"response_type=code&scope=openid%20profile%20email&client_id=rpid&state=af0ifjsldkj&redirect_uri=http%3A%2F%2Frp.com%2F";
ok(
    $res = $op->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$idpId",
    ),
    "Get authorization code again"
);
count(1);

($code) = expectRedirection( $res, qr#http://rp\.com/.*code=([^\&]*)# );

# Play code on RP1
$query = buildForm( {
        grant_type   => 'authorization_code',
        code         => $code,
        redirect_uri => 'http://rp.com/',
    }
);

# Bad auth (header)
ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("rpid:invalid"),
        },
    ),
    "Post auth code on correct RP"
);
count(1);
expectReject( $res, 401, "invalid_client" );
is( getHeader( $res, "WWW-Authenticate" ), "Basic" );
count(1);

# Bad auth (form)
$query = buildForm( {
        grant_type    => 'authorization_code',
        code          => $code,
        redirect_uri  => 'http://rp.com/',
        client_id     => 'rpid',
        client_secret => 'rpsecre',
    }
);

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Post auth code on correct RP"
);
count(1);
expectReject( $res, 400, "invalid_client" );
is( getHeader( $res, "WWW-Authenticate" ), undef );
count(1);

# Correct parameters
$query = buildForm( {
        grant_type    => 'authorization_code',
        code          => $code,
        redirect_uri  => 'http://rp.com/',
        client_id     => 'rpid',
        client_secret => 'rpsecret',
    }
);

# Authenticated client with two methods at once (#2474)
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
    "Post auth code on correct RP"
);
count(1);
expectReject( $res, 401, "invalid_client" );
is( getHeader( $res, "WWW-Authenticate" ), "Basic" );
count(1);

ok(
    $res = $op->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'text/html',
        length => length($query),
    ),
    "Post auth code on correct RP"
);
count(1);

is( getHeader( $res, "Access-Control-Allow-Origin" ),
    "*", "CORS header present on Token response" );
count(1);

$res = expectJSON($res);
my $token = $res->{access_token};
ok( $token, 'Access token present' );
count(1);

ok(
    $res = $op->_post(
        "/oauth2/userinfo",
        IO::String->new(""),
        accept => 'text/html',
        length => 0,
        custom => {
            HTTP_AUTHORIZATION => "Bearer " . $token,
        },
    ),
    "post to userinfo",
);
count(1);
ok( $res->[0] == 200, "Userinfo successful" );
count(1);

is( getHeader( $res, "Access-Control-Allow-Origin" ),
    "*", "CORS header present on userinfo response" );
count(1);

Time::Fake->offset("+2h");

ok(
    $res = $op->_post(
        "/oauth2/userinfo",
        IO::String->new(""),
        accept => 'text/html',
        length => 0,
        custom => {
            HTTP_AUTHORIZATION => "Bearer " . $token,
        },
    ),
    "post to userinfo with expired access token"
);
count(1);
ok( $res->[0] == 401, "Access denied with expired token" );
count(1);

is( getHeader( $res, "Access-Control-Allow-Origin" ),
    "*", "CORS header present on userinfo error response" );
count(1);

clean_sessions();
done_testing( count() );

