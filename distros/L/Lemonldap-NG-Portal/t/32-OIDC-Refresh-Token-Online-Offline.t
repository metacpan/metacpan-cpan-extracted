# Test that when both oidcRPMetaDataOptionsRefreshToken and
# oidcRPMetaDataOptionsAllowOffline are enabled:
# - requesting without offline_access scope gives an online refresh token
# - requesting with offline_access scope gives an offline refresh token

use strict;
use Test::More;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $op = LLNG::Manager::Test->new( {
        ini => {
            domain                          => 'op.com',
            portal                          => 'http://auth.op.com/',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            issuerDBOpenIDConnectActivation => 1,
            oidcRPMetaDataExportedVars      => {
                rp => {
                    email       => "mail",
                    family_name => "cn",
                    name        => "cn"
                }
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsClientID       => "rpid",
                    oidcRPMetaDataOptionsClientSecret   => "rpid",
                    oidcRPMetaDataOptionsDisplayName    => "RP",
                    oidcRPMetaDataOptionsIDTokenSignAlg => "RS256",
                    oidcRPMetaDataOptionsUserIDAttr     => "",
                    oidcRPMetaDataOptionsBypassConsent  => 1,
                    oidcRPMetaDataOptionsRedirectUris   => 'http://test/',

                    # Main options off this test
                    oidcRPMetaDataOptionsAllowOffline => 1,
                    oidcRPMetaDataOptionsRefreshToken => 1,
                }
            },
            oidcServicePrivateKeySig => oidc_key_op_private_sig,
            oidcServicePublicKeySig  => oidc_cert_op_public_sig,
        }
    }
);

subtest "Without offline_access scope: online refresh token" => sub {
    Time::Fake->reset;
    my $idpId = login( $op, "french" );

    # Authorize without offline_access
    my $code = codeAuthorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid profile email",
            client_id     => "rpid",
            state         => "af0ifjsldkj",
            redirect_uri  => "http://test/"
        }
    );

    my $json = expectJSON( codeGrant( $op, "rpid", $code, "http://test/" ) );
    my $refresh_token = $json->{refresh_token};
    ok( $refresh_token, "Got refresh token" );

    # Verify it is an online refresh token (has user_session_id)
    my $rt_session = getSamlSession($refresh_token);
    ok(
        $rt_session->{data}->{user_session_id},
        "Refresh token has user_session_id (== online)"
    );

    # Verify refresh works while session is active
    $json = expectJSON( refreshGrant( $op, "rpid", $refresh_token ) );
    ok( $json->{access_token}, "Refresh works while session is active" );

    # Logout and verify refresh fails (online token tied to session)
    $op->logout($idpId);
    expectReject( refreshGrant( $op, "rpid", $refresh_token ),
        400, 'invalid_grant', );

    Time::Fake->reset;
};

subtest "With offline_access scope: offline refresh token" => sub {
    Time::Fake->reset;
    my $idpId = login( $op, "french" );

    # Authorize with offline_access
    my $code = codeAuthorize(
        $op, $idpId,
        {
            response_type => "code",
            scope         => "openid profile email offline_access",
            client_id     => "rpid",
            state         => "af0ifjsldkj",
            redirect_uri  => "http://test/"
        }
    );

    my $json = expectJSON( codeGrant( $op, "rpid", $code, "http://test/" ) );
    my $refresh_token = $json->{refresh_token};
    ok( $refresh_token, "Got refresh token" );

    # Verify it is an offline refresh token (no user_session_id)
    my $rt_session = getSamlSession($refresh_token);
    ok(
        !$rt_session->{data}->{user_session_id},
        "Refresh token has no user_session_id (offline)"
    );

    # Verify refresh works while session is active
    $json = expectJSON( refreshGrant( $op, "rpid", $refresh_token ) );
    ok( $json->{access_token}, "Refresh works while session is active" );

    # Logout and verify refresh still works (offline token survives logout)
    $op->logout($idpId);
    $json = expectJSON( refreshGrant( $op, "rpid", $refresh_token ) );
    ok( $json->{access_token},
        "Refresh still works after logout (offline token)" );

    Time::Fake->reset;
};

clean_sessions();
done_testing();
