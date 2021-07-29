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

my $idpId = login( $op, "french" );
my $code  = authorize(
    $op, $idpId,
    {
        response_type => "code",
        scope         => "openid profile email",
        client_id     => "rpid",
        state         => "af0ifjsldkj",
        redirect_uri  => "http://rp.com/"
    }
);

my $tokenresp = expectJSON( codeGrant( $op, 'rpid', $code, "http://rp.com/" ) );
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

my $userinfo = expectJSON( getUserinfo( $op, $access_token ) );
is( $userinfo->{family_name}, 'Accents',      'Correct macro value' );
is( $userinfo->{sub},         'customfrench', 'Sub macro correctly evaluated' );

clean_sessions();
done_testing();

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'op.com',
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
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
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
                        oidcRPMetaDataOptionsClientSecret      => "rpid",
                        oidcRPMetaDataOptionsUserIDAttr        => "custom_sub",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsRedirectUri           => 3600,
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

