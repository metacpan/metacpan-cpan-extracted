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

# Initialization
my $portal = LLNG::Manager::Test->new(
    {
        ini => {
            logLevel                        => $debug,
            domain                          => 'op.com',
            portal                          => 'http://auth.op.com/',
            authentication                  => 'Demo',
            userDB                          => 'Same',
            customPlugins                   => 't::OidcHookPlugin',
            issuerDBOpenIDConnectActivation => 1,
            oidcRPMetaDataExportedVars      => {
                rp => {
                    "name"               => "mymacro",
                    "preferred_username" => "hooked_username",
                }
            },
            oidcRPMetaDataMacros => {
                rp => {
                    "mymacro" => "'foo'",
                }
            },
            oidcRPMetaDataOptions => {
                rp => {
                    oidcRPMetaDataOptionsDisplayName           => "RP",
                    oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                    oidcRPMetaDataOptionsClientID              => "rpid",
                    oidcRPMetaDataOptionsAllowOffline          => 1,
                    oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                    oidcRPMetaDataOptionsClientSecret          => "rpid",
                    oidcRPMetaDataOptionsUserIDAttr            => "",
                    oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                    oidcRPMetaDataOptionsBypassConsent         => 1,
                    oidcRPMetaDataOptionsRefreshToken          => 1,
                    oidcRPMetaDataOptionsIDTokenForceClaims    => 1,
                    oidcRPMetaDataOptionsRedirectUris          => 'http://test',
                },
            },
            oidcRPMetaDataScopeRules => {
                rp => {
                    "read"   => '$requested',
                    "always" => '1',
                },
            },
            oidcServicePrivateKeySig      => oidc_key_op_private_sig,
            oidcServicePublicKeySig       => oidc_cert_op_public_sig,
            loginHistoryEnabled           => 1,
            bruteForceProtection          => 1,
            bruteForceProtectionTempo     => 5,
            bruteForceProtectionMaxFailed => 4,
            failedLoginNumber             => 6,
            successLoginNumber            => 4,
        }
    }
);
my $id = login( $portal, 'dwho' );

my $code = codeAuthorize(
    $portal, $id,
    {
        response_type => "code",
        scope         => "openid profile",
        client_id     => "rpid",
        state         => "af0ifjsldkj",
        redirect_uri  => "http://test"
    }
);

my $res = codeGrant( $portal, 'rpid', $code, 'http://test' );
$res = expectJSON($res);

# Unhandled token exchange request
$res = tokenExchange( $portal, 'rpid', xxx => "zzz" );
expectReject( $res, 400, 'invalid_request' );

# handled token exchange request
$res = tokenExchange( $portal, 'rpid', testtokenexchange => 1 );
my $j = expectJSON($res);
is( $j->{result}, 1, "Request was handled by hook" );

clean_sessions();
done_testing();

