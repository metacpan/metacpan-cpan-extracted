use warnings;
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

my $op = LLNG::Manager::Test->new( {
        ini => {
            logLevel                           => $debug,
            domain                             => 'op.com',
            portal                             => 'http://auth.op.com/',
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
                rp_jwt => {
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
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                    oidcRPMetaDataOptionsClientSecret          => "rpid",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRedirectUris => 'http://rp.com/',
                },

                # Resource server with JWT introspection (RFC 9701)
                rp_jwt => {
                    oidcRPMetaDataOptionsDisplayName          => "rp_jwt",
                    oidcRPMetaDataOptionsClientID             => "rp_jwt",
                    oidcRPMetaDataOptionsClientSecret         => "jwt_service",
                    oidcRPMetaDataOptionsUserIDAttr           => "",
                    oidcRPMetaDataOptionsIntrospectionSignAlg => "RS256",
                },
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
        scope         => "openid profile email",
        client_id     => "rpid",
        state         => "state1",
        redirect_uri  => "http://rp.com/"
    }
);

my $json  = expectJSON( codeGrant( $op, "rpid", $code, "http://rp.com/" ) );
my $token = $json->{access_token};
ok( $token, 'Access token present' );

my ( $res, $query );

subtest "JWT introspection response (RFC 9701)" => sub {
    $query = "token=$token";
    ok(
        $res = $op->_post(
            "/oauth2/introspect",
            IO::String->new($query),
            accept => 'application/json',
            length => length $query,
            custom => {
                HTTP_AUTHORIZATION => "Basic "
                  . encode_base64("rp_jwt:jwt_service"),
            },
        ),
        "Post introspection with JWT-enabled RP (rp_jwt)"
    );

    expectOK($res);

    # Check Content-Type is JWT (RFC 9701)
    my $content_type = getHeader( $res, "Content-Type" );
    is(
        $content_type,
        "application/token-introspection+jwt",
        "Content-Type is application/token-introspection+jwt"
    );

    my $jwt_response = $res->[2]->[0];

    # Verify JWT header
    my $jwt_header = getJWTHeader($jwt_response);
    is( $jwt_header->{typ}, "token-introspection+jwt",
        "JWT typ header is correct" );
    is( $jwt_header->{alg}, "RS256", "JWT alg header is RS256" );

    # Verify JWT payload
    my $jwt_payload = getJWTPayload($jwt_response);
    is( $jwt_payload->{iss}, "http://auth.op.com/",
        "JWT iss claim is correct" );
    is( $jwt_payload->{aud}, "rp_jwt",
        "JWT aud claim matches calling client_id" );
    ok( $jwt_payload->{iat}, "JWT iat claim is present" );

    # RFC 9701: response is wrapped in token_introspection claim
    ok(
        exists $jwt_payload->{token_introspection},
        "token_introspection claim exists"
    );

    my $introspection = $jwt_payload->{token_introspection};
    ok( $introspection->{active}, "Token is active" );
    is( $introspection->{sub}, "french", "Introspection contains correct sub" );
    is( $introspection->{client_id},
        "rpid",
        "Introspection contains correct client_id (token's original RP)" );
    ok( $introspection->{exp}, "Introspection contains exp" );
    ok( $introspection->{iat}, "Introspection contains iat" );
    like( $introspection->{scope}, qr/openid/, "Introspection contains scope" );

    # RFC 9701: sub and exp should NOT be at root level
    ok( !exists $jwt_payload->{sub}, "sub is NOT at JWT root level" );
    ok( !exists $jwt_payload->{exp}, "exp is NOT at JWT root level" );
};

subtest "JWT introspection for inactive token" => sub {

    # Fast forward time to expire the token
    Time::Fake->offset("+2h");

    $query = "token=$token";
    ok(
        $res = $op->_post(
            "/oauth2/introspect",
            IO::String->new($query),
            accept => 'application/json',
            length => length $query,
            custom => {
                HTTP_AUTHORIZATION => "Basic "
                  . encode_base64("rp_jwt:jwt_service"),
            },
        ),
        "Post introspection for expired token"
    );

    expectOK($res);

    # Check Content-Type is still JWT
    my $content_type = getHeader( $res, "Content-Type" );
    is(
        $content_type,
        "application/token-introspection+jwt",
        "Content-Type is application/token-introspection+jwt"
    );

    my $jwt_response = $res->[2]->[0];
    my $jwt_payload  = getJWTPayload($jwt_response);

    # Verify JWT claims are present even for inactive token
    is( $jwt_payload->{iss}, "http://auth.op.com/",
        "JWT iss claim is correct" );
    is( $jwt_payload->{aud}, "rp_jwt",
        "JWT aud claim matches calling client_id" );
    ok(
        exists $jwt_payload->{token_introspection},
        "token_introspection claim exists"
    );

    # Token should be inactive
    my $introspection = $jwt_payload->{token_introspection};
    ok( !$introspection->{active}, "Token is inactive" );

    # Reset time
    Time::Fake->reset();
};

subtest "Metadata includes introspection algorithms (RFC 9701)" => sub {
    ok(
        $res = $op->_get(
            "/.well-known/openid-configuration",
            accept => 'application/json',
        ),
        "Get OpenID Connect configuration"
    );

    expectOK($res);
    my $metadata = from_json( $res->[2]->[0] );

    ok(
        exists $metadata->{introspection_signing_alg_values_supported},
        "introspection_signing_alg_values_supported is present"
    );
    ok(
        ref( $metadata->{introspection_signing_alg_values_supported} ) eq
          'ARRAY',
        "introspection_signing_alg_values_supported is an array"
    );

    ok(
        exists $metadata->{introspection_encryption_alg_values_supported},
        "introspection_encryption_alg_values_supported is present"
    );

    ok(
        exists $metadata->{introspection_encryption_enc_values_supported},
        "introspection_encryption_enc_values_supported is present"
    );
};

clean_sessions();
done_testing();
