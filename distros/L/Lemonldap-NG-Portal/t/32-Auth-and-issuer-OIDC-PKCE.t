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

# RFC 9700 section 2.1.1: PKCE downgrade attack protection
subtest
  "not required/no PKCE flow/code_verifier rejected (downgrade attack)" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id => "rp",

            # No code_challenge sent
        }
    );

    my $res = codeGrant( $op, "rp", $code, "http://rp.com/",
        code_verifier => $code_verifier );
    expectReject( $res, 400, "invalid_grant" );
  };

# For confidential clients, RequirePKCE=2 does not change behavior:
# secret/jwt authentication is always required
subtest "Confidential with RequirePKCE=2/with secret succeeds" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp_pkce_or_secret",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    my $res = expectJSON(
        codeGrant(
            $op,   "rp_pkce_or_secret",
            $code, "http://rp.com/",
            code_verifier => $code_verifier
        )
    );
    ok( $res->{access_token}, "Access token was provided with secret" );
};

subtest "Confidential with RequirePKCE=2/no secret fails" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp_pkce_or_secret",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    # Even with PKCE, confidential client needs secret
    my $res =
      codeGrantNoSecret( $op, "rp_pkce_or_secret", $code, "http://rp.com/",
        code_verifier => $code_verifier );
    expectReject( $res, 400, "invalid_client" );
};

subtest "PKCE not required/no client_secret fails" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    # Without PKCE required, client_secret is still needed (not public)
    my $res = codeGrantNoSecret( $op, "rp", $code, "http://rp.com/",
        code_verifier => $code_verifier );
    expectReject( $res, 400, "invalid_client" );
};

subtest "Public PKCE-or-secret mode/with PKCE succeeds" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id             => "rp_public_pkce_or_secret",
            code_challenge        => $code_challenge,
            code_challenge_method => $code_challenge_method,
        }
    );

    my $res = expectJSON(
        codeGrantNoSecret(
            $op, "rp_public_pkce_or_secret", $code, "http://rp.com/",
            code_verifier => $code_verifier
        )
    );
    ok( $res->{access_token},
        "Access token was provided for public client with PKCE" );
};

subtest "Public PKCE-or-secret mode/with secret (no PKCE) succeeds" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id => "rp_public_pkce_or_secret",

            # No code_challenge
        }
    );

    # Public client in mode 2 with valid secret should succeed
    my $res = expectJSON(
        codeGrant( $op, "rp_public_pkce_or_secret", $code, "http://rp.com/" ) );
    ok( $res->{access_token},
        "Access token was provided for public client with secret" );
};

subtest "Public PKCE-or-secret mode/without PKCE or secret fails" => sub {
    my $code = codeAuthorize(
        $op, $id,
        {
            %test_authorize_params,
            client_id => "rp_public_pkce_or_secret",

            # No code_challenge
        }
    );

    # Public client in mode 2 without PKCE or secret should fail
    my $res = codeGrantNoSecret( $op, "rp_public_pkce_or_secret", $code,
        "http://rp.com/" );
    expectReject( $res, 400, "invalid_client" );
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
                    rp_pkce_or_secret => {
                        email  => "mail",
                        name   => "cn",
                        groups => "groups",
                    },
                    rp_public_pkce_or_secret => {
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
                    },
                    rp_pkce_or_secret => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID => "rp_pkce_or_secret",
                        oidcRPMetaDataOptionsIDTokenSignAlg => "RS256",
                        oidcRPMetaDataOptionsBypassConsent  => 1,
                        oidcRPMetaDataOptionsClientSecret   =>
                          "rp_pkce_or_secret",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsRedirectUris => 'http://rp.com/',
                        oidcRPMetaDataOptionsRequirePKCE  => 2, # PKCE or secret
                    },
                    rp_public_pkce_or_secret => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          =>
                          "rp_public_pkce_or_secret",
                        oidcRPMetaDataOptionsIDTokenSignAlg => "RS256",
                        oidcRPMetaDataOptionsBypassConsent  => 1,
                        oidcRPMetaDataOptionsClientSecret   =>
                          "rp_public_pkce_or_secret",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsRedirectUris => 'http://rp.com/',
                        oidcRPMetaDataOptionsPublic       => 1,
                        oidcRPMetaDataOptionsRequirePKCE  => 2, # PKCE or secret
                    }
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}

