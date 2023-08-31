use warnings;
use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use Plack::Request;
use Plack::Response;
use URI;
use XML::LibXML;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/cas-lib.pm';
    require 't/oidc-lib.pm';
}

subtest "Log into OIDC RP, logout from CAS, OIDC logout is called" => sub {

    my ( $issuer, $res );

    $issuer = issuer();
    my $id = $issuer->login('dwho');

    my $code = codeAuthorize(
        $issuer, $id,
        {
            response_type => 'code',
            scope         => 'openid profile email offline_access',
            client_id     => 'rpid',
            state         => 'af0ifjsldkj',
            redirect_uri  => 'http://rp.com/',
        }
    );

    expectJSON( codeGrant( $issuer, 'rpid', $code, "http://rp.com/" ) );

    ok(
        $res = $issuer->_get(
            '/cas/logout',
            cookie => "lemonldap=$id",
            accept => 'text/html'
        ),
        'Initiate CAS logout',
    );

    ok( getHtmlElement( $res, '//iframe[@src="http://rp.com/logout"]' ),
        "Found OIDC logout iframe" );

};

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                issuerDBCASActivation           => 1,
                issuerDBOpenIDConnectActivation => 1,
                casBackChannelSingleLogout      => 0,
                casAppMetaDataOptions           => {
                    sp1 => {
                        casAppMetaDataOptionsService => 'https://auth.sp.com/',
                        casAppMetaDataOptionsDisplayName => 'My CAS App',
                        casAppMetaDataOptionsLogout      => 1,
                    },
                    sp2 => {
                        casAppMetaDataOptionsService => 'https://auth.sp2.com/',
                        casAppMetaDataOptionsDisplayName => 'My Other App',
                        casAppMetaDataOptionsLogout      => -1,
                    },
                },
                casAccessControlPolicy     => 'error',
                oidcRPMetaDataExportedVars => {
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
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsClientSecret      => "rpid",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsLogoutUrl         =>
                          "http://rp.com/logout",
                        oidcRPMetaDataOptionsLogoutType            => "front",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                    },
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
