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
my ( $op, $res );

# Initialization
ok( $op = op(), 'OP portal' );

my $idpId = login( $op, "french" );
my $res   = authorize(
    $op, $idpId,
    {
        response_type => "code",
        scope         => "openid profile email",
        client_id     => "rpid",
        state         => "af0ifjsldkj",
        redirect_uri  => "my.mobile.app://callback"
    }
);

my $csp = getHeader( $res, "Content-Security-Policy" );
my ($form_action) = $csp =~ /(\bform-action[^;]*)/;
like( $form_action, qr/my.mobile.app:/, "Allowed custom scheme" );

my ($dest) = $res->[2]->[0] =~ m@<form.+?action="([^"]*)"@is;

my ( $uri, $code ) = $dest =~ m@^([^?]*).*code=([^\&]*)@;
is( $uri, "my.mobile.app://callback", "Correct Redirect URI" );
ok( $code, "Found code" );

my $tokenresp =
  expectJSON( codeGrant( $op, 'rpid', $code, "my.mobile.app://callback" ) );
ok( my $access_token = $tokenresp->{access_token}, 'Found access token' );
ok( $res = getUserinfo( $op, $access_token ) );
my $userinfo = expectJSON( getUserinfo( $op, $access_token ) );
is( $userinfo->{sub}, "french", "Correct subject" );

clean_sessions();
done_testing();

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'idp.com',
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
                jsRedirect                            => 1,
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsClientID              => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "RS256",
                        oidcRPMetaDataOptionsBypassConsent         => 0,
                        oidcRPMetaDataOptionsUserIDAttr            => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsPublic                => 1,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsRedirectUris          =>
                          "my.mobile.app://callback",
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp.com/?logout=1"
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
}
