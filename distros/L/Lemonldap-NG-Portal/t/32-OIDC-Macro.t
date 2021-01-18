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
my $res;

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
    "Post authentication"
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
is( $userinfo->{sub}, 'customfrench', 'Sub macro correctly evaluated' );

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
                oidcRPMetaDataMacros                  => {
                    rp => {
                        extract_sn => '(split(/\s/, $cn))[1]',
                        custom_sub => '"custom".$uid',
                    }
                },
                oidcRPMetaDataOptions => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 1,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "custom_sub",
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
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_key_op_public_sig,
            }
        }
    );
}

