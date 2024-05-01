use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64 qw/encode_base64url/;
use URI::QueryParam;
use Digest::SHA qw/sha256/;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my ( $op, $rp, $res );

# Initialization
ok( $op = register( 'op', sub { op() } ), 'OP portal' );

my $id = login( $op, "french" );

# Example from https://datatracker.ietf.org/doc/html/rfc7636#appendix-B
my $code_verifier         = "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk";
my $code_challenge        = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM";
my $code_challenge_method = "S256";

my %test_authorize_params = (
    response_type => "code",
    scope         => "openid profile",
    state         => "af0ifjsldkj",
    redirect_uri  => "http://rp.com/",
);

subtest "not required/PKCE flow/valid verifier succeeds" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    my $res = expectJSON(
        codeGrant(
            $op, "rp", $code, "http://rp.com/", code_verifier => $code_verifier
        )
    );
    ok( $res->{access_token}, "Access token was provided" );
};

subtest "not required/PKCE flow/invalid verifier fails" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    my $res = codeGrant( $op, "rp", $code, "http://rp.com/",
        code_verifier => "INVALID" );
    expectReject( $res, 400, "invalid_grant" );
};

subtest "PKCE required/non-PKCE flow/fails at authorize step" => sub {
    my $res = authorize(
        $op, $id,
        {
            %test_authorize_params, client_id => "rp_pkce",
        }
    );

    my ($error) = expectRedirection( $res, qr#http://.*error=([^\&]*)# );
    is( $error, "invalid_request",
        "Authorize request failed with invalid_request" );
};

subtest "PKCE required/PKCE flow/valid verifier succeeds" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp_pkce",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    my $res = expectJSON(
        codeGrant(
            $op, "rp_pkce", $code, "http://rp.com/",
            code_verifier => $code_verifier
        )
    );
    ok( $res->{access_token}, "Access token was provided" );
};

subtest "PKCE required/PKCE flow/invalid verifier fails" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp_pkce",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    my $res = codeGrant( $op, "rp_pkce", $code, "http://rp.com/",
        code_verifier => "INVALID" );
    expectReject( $res, 400, "invalid_grant" );
};

clean_sessions();
done_testing();

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                restSessionServer               => 1,
                oidcServiceIgnoreScopeForClaims => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email  => "mail",
                        name   => "cn",
                        groups => "groups",
                    },
                    rp_pkce => {
                        email  => "mail",
                        name   => "cn",
                        groups => "groups",
                    },
                },
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsClientID              => "rp",
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                        oidcRPMetaDataOptionsBypassConsent         => 0,
                        oidcRPMetaDataOptionsClientSecret          => "rp",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsRedirectUris => 'http://rp.com/',
                    },
                    rp_pkce => {
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsClientID              => "rp_pkce",
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                        oidcRPMetaDataOptionsBypassConsent         => 0,
                        oidcRPMetaDataOptionsClientSecret          => "rp_pkce",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsRedirectUris => 'http://rp.com/',
                        oidcRPMetaDataOptionsRequirePKCE  => 1,
                    }
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}

