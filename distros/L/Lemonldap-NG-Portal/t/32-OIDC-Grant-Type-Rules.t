use Test::More;
use strict;
use IO::String;

use Lemonldap::NG::Portal::Main::Constants qw(
  PE_FIRSTACCESS
);

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $res;
my $debug = "error";

my ($portal);
$portal = portal();

my $access_token;

# RP1, should only allow Auth code grant
expectReject( try_access_token_client( $portal, 'rpcode' ),   400 );
expectReject( try_access_token_password( $portal, 'rpcode' ), 400 );
expectRedirection( try_access_token_code( $portal, 'rpcode' ),
    qr#http://.*code=([^\&]*)# );

# RP2, should only allow Client Credentials grant
expectJSON( try_access_token_client( $portal, 'rpclient' ) );
expectReject( try_access_token_password( $portal, 'rpclient' ), 400 );
expectPortalError( try_access_token_code( $portal, 'rpclient' ), 84 );

# RP3, should only allow Password grant
expectReject( try_access_token_client( $portal, 'rppassword' ), 400 );
expectJSON( try_access_token_password( $portal, 'rppassword' ) );
expectPortalError( try_access_token_code( $portal, 'rppassword' ), 84 );

clean_sessions();

done_testing( count() );

sub try_access_token_client {
    my ( $portal, $rp ) = @_;
    my $query = buildForm( {
            client_id     => $rp,
            client_secret => $rp,
            grant_type    => 'client_credentials',
            scope         => 'profile',
        }
    );

    ## Get Access Token with Client Credentials
    my $res = $portal->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
    );
    return $res;
}

sub try_access_token_password {
    my ( $portal, $rp ) = @_;
    ## Get Access Token with Password Grant
    my $query = buildForm( {
            client_id     => $rp,
            client_secret => $rp,
            grant_type    => 'password',
            username      => 'dwho',
            password      => 'dwho',
            scope         => 'profile',
        }
    );
    my $res = $portal->_post(
        "/oauth2/token",
        IO::String->new($query),
        accept => 'application/json',
        length => length($query),
    );
    return $res;
}

sub try_access_token_code {
    my ( $portal, $rp ) = @_;

    my $id = login( $portal, 'dwho' );

    my $params = {
        response_type => "code",

        # Include a weird scope name, to make sure they work (#2168)
        scope        => "openid profile",
        client_id    => $rp,
        state        => "af0ifjsldkj",
        redirect_uri => "http://test"
    };
    my $query = buildForm($params);
    my $res   = $portal->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$id",
    );
    return $res;
}

sub portal {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                           => $debug,
                domain                             => 'op.com',
                portal                             => 'http://auth.op.com',
                authentication                     => 'Demo',
                userDB                             => 'Same',
                issuerDBOpenIDConnectActivation    => 1,
                oidcServiceAllowOnlyDeclaredScopes => 1,
                oidcRPMetaDataOptions              => {
                    rpcode => {
                        oidcRPMetaDataOptionsDisplayName           => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration     => 3600,
                        oidcRPMetaDataOptionsClientID              => "rpcode",
                        oidcRPMetaDataOptionsIDTokenSignAlg        => "HS512",
                        oidcRPMetaDataOptionsClientSecret          => "rpcode",
                        oidcRPMetaDataOptionsUserIDAttr            => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                        oidcRPMetaDataOptionsAllowPasswordGrant          => 1,
                        oidcRPMetaDataOptionsRedirectUris => "http://test",
                        oidcRPMetaDataOptionsRule         =>
                          '$_oidc_grant_type eq "authorizationcode"',
                    },
                    rppassword => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rppassword",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsClientSecret      => "rppassword",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                        oidcRPMetaDataOptionsAllowPasswordGrant          => 1,
                        oidcRPMetaDataOptionsRedirectUris => "http://test",
                        oidcRPMetaDataOptionsRule         =>
                          '$_oidc_grant_type eq "password"',
                    },
                    rpclient => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpclient",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsClientSecret      => "rpclient",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                        oidcRPMetaDataOptionsAllowClientCredentialsGrant => 1,
                        oidcRPMetaDataOptionsAllowPasswordGrant          => 1,
                        oidcRPMetaDataOptionsRedirectUris => "http://test",
                        oidcRPMetaDataOptionsRule         =>
                          '$_oidc_grant_type eq "clientcredentials"',
                    },
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}
