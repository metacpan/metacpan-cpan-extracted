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
            logLevel                           => $debug,
            domain                             => 'op.com',
            portal                             => 'http://auth.op.com',
            authentication                     => 'Demo',
            userDB                             => 'Same',
            issuerDBOpenIDConnectActivation    => 1,
            oidcServiceAllowOnlyDeclaredScopes => 1,
            oidcRPMetaDataExportedVars         => {
                rp => {
                    email       => "mail",
                    family_name => "cn",
                    name        => "cn"
                },
                oauth => {
                    email       => "mail",
                    family_name => "cn",
                    name        => "cn"
                }
            },
            oidcRPMetaDataScopeRules => {
                rp => {
                    "read"        => '$requested and $uid eq "french"',
                    "write"       => '$uid eq "russian"',
                    "ifrequested" => '$requested and $uid eq "french"',
                    "always"      => '$uid eq "french"',
                },
            },
            oidcRPMetaDataOptionsExtraClaims => {
                rp => {
                    extrascope => "dummy",
                },
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpid",
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
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_cert_op_public_sig,
        }
    }
);

my $idpId = login( $op, "french" );

my $code = codeAuthorize(
    $op, $idpId,
    {
        response_type => "code",
        scope         => "openid profile email read write extrascope unknown",
        client_id     => "rpid",
        state         => "af0ifjsldkj",
        redirect_uri  => "http://rp2.com/"
    }
);

my $json = expectJSON( codeGrant( $op, "rpid", $code, "http://rp2.com/" ) );

my $token = $json->{access_token};
ok( $token, 'Access token present' );
my $token_resp_scope = $json->{scope};
ok( $token_resp_scope, 'Token response returned granted scopes' );

my ( $res, $query );

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

expectReject( $res, 400, 'invalid_client' );

# Bad HTTP authorization
ok(
    $res = $op->_post(
        "/oauth2/introspect",
        IO::String->new($query),
        accept => 'text/html',
        length => length $query,
        custom => {
            HTTP_AUTHORIZATION => "Basic " . encode_base64("oauth:servic2e"),
        },
    ),
    "Post introspection"
);
expectReject( $res, 401, 'invalid_client' );
is( getHeader( $res, "WWW-Authenticate" ), "Basic" );

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
like( $json->{scope}, qr/\bopenid\b/,  "Response contains the default scopes" );
like( $json->{scope}, qr/\bprofile\b/, "Response contains the default scopes" );
like( $json->{scope}, qr/\bemail\b/,   "Response contains the default scopes" );
unlike( $json->{scope}, qr/\bwrite\b/,
    "Response omits a dynamic scope that evaluates to false" );
unlike( $json->{scope}, qr/\bifrequested\b/,
    "Response omits a dynamic scope that was not requested" );
like( $json->{scope}, qr/\bread\b/,
    "Response contains a dynamic scope that is sent only when requested" );
like( $json->{scope}, qr/\balways\b/,
    "Response contains a dynamic scope that is not requested but always sent" );
unlike( $json->{scope}, qr/\bunknown\b/,
    "Response omits a scope that is not declared anywhere" );
like( $json->{scope}, qr/\bextrascope\b/,
    "Response contains scope coming from extra claims definition" );
is( $token_resp_scope, $json->{scope},
    "Token response scope matches token scope" );

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

