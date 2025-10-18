use warnings;
use Test::More;
use strict;
use URI;
use URI::QueryParam;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $op;

# Initialization
ok( $op = register( 'op', sub { op() } ), 'OP portal' );

sub test {
    my ( $params, $expected_error, $description ) = @_;
    subtest $description => sub {

        my $redirect = $params->{post_logout_redirect_uri};
        my $res;

        ok(
            $res = $op->_post(
                "/",
                {
                    user     => "french",
                    password => "french",
                },
                accept => 'text/html',
            ),
            "Post authentication",
        );
        my $idpId = expectCookie($res);

        # Automatically set id_token_hint to an actual ID token
        if ( $params->{id_token_hint} ) {
            ok(
                $res = $op->_get(
                    "/oauth2/authorize",
                    query => {
                        client_id    => "rpid",
                        redirect_uri =>
                          "http://auth.rp.com/?openidconnectcallback=1",
                        response_type => "id_token",
                        nonce         => 123,
                        scope         => "openid",
                    },
                    cookie => "lemonldap=$idpId",
                    accept => 'text/html',
                ),
                "Try to obtain ID token",
            );

            my ($redir) = expectRedirection( $res,
                qr,(http://auth.rp.com/\?openidconnectcallback=1.*), );
            my $uri = URI->new($redir);
            $uri->query( $uri->fragment );
            ok( my $id_token = $uri->query_param('id_token'),
                "Found ID token" );
            $params->{id_token_hint} = $id_token;
        }

        $res = $op->_get(
            '/oauth2/logout',
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            query  => {
                state => 123,
                %$params,
            }

        );
        if ($expected_error) {
            expectPortalError( $res, $expected_error );
        }
        else {
            expectRedirection( $res, "$redirect?state=123" );
        }
    };
}

test( {
        post_logout_redirect_uri => "http://unauthorized",
    },
    108,
    "Specifying an unauthorized logout URL stops the logout"
);

test( {
        post_logout_redirect_uri => "http://auth.rp2.com/oauth2/rlogoutreturn",
        client_id                => "rpid",
    },
    108,
    "Redirect URI is allowed for a different RP than specified"
);

test( {
        post_logout_redirect_uri => "http://auth.rp2.com/oauth2/rlogoutreturn",
        id_token_hint            => "xxx",
    },
    108,
    "Redirect URI is allowed for a different RP than specified"
);

test( {
        post_logout_redirect_uri => "http://auth.rp.com/oauth2/rlogoutreturn",
        id_token_hint            => "xxx",
        client_id                => "rpid2",
    },
    24,
    "Mismatch between id_token_hint and client_id"
);

test( {
        post_logout_redirect_uri => "http://auth.rp2.com/oauth2/rlogoutreturn",
        id_token_hint            => "xxx",
        client_id                => "rpid2",
    },
    24,
    "Mismatch between id_token_hint and client_id"
);

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
                oidcRPMetaDataExportedVars      => {
                    rp => {
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
                        oidcRPMetaDataOptionsBypassConsent     => 1,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration  => 3600,
                        oidcRPMetaDataOptionsLogoutSessionRequired  => 0,
                        oidcRPMetaDataOptionsLogoutBypassConfirm    => 0,
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp.com/oauth2/rlogoutreturn",
                        oidcRPMetaDataOptionsRedirectUris =>
                          'http://auth.rp.com/?openidconnectcallback=1',
                    },
                    rp2 => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid2",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration  => 3600,
                        oidcRPMetaDataOptionsLogoutSessionRequired  => 0,
                        oidcRPMetaDataOptionsLogoutBypassConfirm    => 0,
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp2.com/oauth2/rlogoutreturn",
                        oidcRPMetaDataOptionsRedirectUris =>
                          'http://auth.rp2.com/?openidconnectcallback=1',
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
