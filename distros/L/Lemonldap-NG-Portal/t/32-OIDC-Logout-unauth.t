use warnings;
use strict;
use Test::More;
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $res;
my $op = op();

$res = $op->_post(
    '/oauth2/token',
    {
        grant_type    => "password",
        client_id     => "rpid",
        client_secret => "rpsecret",
        scope         => "openid",
        username      => "dwho",
        password      => "dwho",
    }
);

my $response = expectJSON($res);
my $id_token = $response->{id_token};

sub test {
    my ( $params, $expected_error, $description ) = @_;

    my $redirect = $params->{post_logout_redirect_uri};

    ok(
        $res = $op->_get(
            '/oauth2/logout',
            accept => 'text/html',
            query  => {
                state => 123,
                %$params,
            }

        ),
        $description
    );
    if ($expected_error) {
        expectPortalError( $res, $expected_error );
    }
    else {
        expectRedirection( $res, "$redirect?state=123" );
    }
}

test( {
        post_logout_redirect_uri => 'http://auth.rp.com/oauth2/rlogoutreturn',
    },
    0,
    "Allowed redirect uri but no RP specified"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp2.com/oauth2/rlogoutreturn',
    },
    0,
    "Allowed redirect uri but no RP specified"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp.com/oauth2/rlogoutreturn',
        client_id                => 'rpid',
    },
    0,
    "Allowed redirect uri, RP specified by client_id"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp.com/oauth2/rlogoutreturn',
        id_token_hint            => $id_token,
    },
    0,
    "Allowed redirect uri, RP specified by id token"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp.com/oauth2/rlogoutreturn',
        id_token_hint            => $id_token,
        client_id                => 'rpid2',
    },
    9,
"Mismatch between id_token_hint and client_id causes redirection to be ignored"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp2.com/oauth2/rlogoutreturn',
        id_token_hint            => $id_token,
        client_id                => 'rpid2',
    },
    9,
"Mismatch between id_token_hint and client_id causes redirection to be ignored"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp2.com/oauth2/rlogoutreturn',
        client_id                => 'rpid',
    },
    9,
    "Redirect URI for a different RP than specified by client_id is refused"
);

test( {
        post_logout_redirect_uri => 'http://auth.rp2.com/oauth2/rlogoutreturn',
        id_token_hint            => $id_token,
    },
    9,
    "Redirect URI for a different RP than specified by id token is refused"
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
                restSessionServer               => 1,
                restExportSecretKeys            => 1,
                oidcServiceIgnoreScopeForClaims => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn",
                        groups      => "groups",
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
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration  => 3600,
                        oidcRPMetaDataOptionsAllowPasswordGrant     => 1,
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.rp.com/oauth2/rlogoutreturn",
                        oidcRPMetaDataOptionsRedirectUris =>
                          'http://auth.rp.com/?openidconnectcallback=1',
                    },
                    otherrp => {
                        oidcRPMetaDataOptionsClientID     => "rpid2",
                        oidcRPMetaDataOptionsClientSecret => "rpsecret",
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
                    'loa-4'       => 4,
                    'customacr-1' => 1,
                    'loa-5'       => 5,
                    'loa-2'       => 2,
                    'loa-3'       => 3
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
            }
        }
    );
}
