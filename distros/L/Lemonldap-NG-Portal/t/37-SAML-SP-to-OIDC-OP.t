use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
    require 't/saml-lib.pm';
}

my ( $op, $proxy, $sp, $res );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.(op|proxy).com(.*)#, ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $res, $client );
        count(1);
        if ( $host eq 'op' ) {
            pass("  Request from RP(proxy) to OP,     endpoint $url");
            $client = $op;
        }
        elsif ( $host eq 'proxy' ) {
            pass('  Request from OP to RP(proxy)');
            $client = $proxy;
        }
        else {
            fail('  Aborting REST request (external)');
            return HTTP::Response->new(500);
        }
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                '  Execute request'
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    custom => {
                        HTTP_AUTHORIZATION => $req->header('Authorization'),
                    }
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        ok( getHeader( $res, 'Content-Type' ) =~ m#^application/json#,
            '  Content is JSON' )
          or explain( $res->[1], 'Content-Type => application/json' );
        count(4);
        return $res;
    }
);

sub test {
    my ( $method, $hashStorage ) = @_;
    reset_tmpdir;

    # Initialization
    $op = register( 'op', \&op );

    ok(
        $res = $op->_get('/oauth2/jwks'),
        'Get JWKS,     endpoint /oauth2/jwks'
    );
    expectOK($res);
    my $jwks = $res->[2]->[0];

    ok(
        $res = $op->_get('/.well-known/openid-configuration'),
        'Get metadata, endpoint /.well-known/openid-configuration'
    );
    expectOK($res);
    my $metadata = $res->[2]->[0];

    $sp    = register( 'sp',    sub { sp($method) } );
    $proxy = register( 'proxy', sub { proxy( $jwks, $metadata, $method ) } );

    # SAML
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Try SAML SP'
    );
    my ( $host, $url, $query );

    if ( $method eq "Redirect" ) {
        ( $url, $query ) = expectRedirection( $res,
            qr#^http://auth.proxy.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

        # Push SAML request to IdP
        ok(
            $res = $proxy->_get(
                $url,
                query  => $query,
                accept => 'text/html',
            ),
            'Launch SAML request to IdP'
        );
    }
    else {
        ( $host, $url, $query ) =
          expectForm( $res, 'auth.proxy.com', '/saml/singleSignOn',
            'SAMLRequest' );

        # Push SAML request to IdP
        ok(
            $res = $proxy->_post(
                $url, IO::String->new($query),
                length => length($query),
                accept => 'text/html',
            ),
            'Launch SAML request to IdP'
        );
    }

    my $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
    count(1);
    expectOK($res);
    my $opPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    ( $host, undef, $query ) = expectForm( $res, '#', undef );

    # Try to authenticate to OP
    $query =~ s/user=/user=french/;
    $query =~ s/password=/password=french/;
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $opPdata,
        ),
        "Post authentication,        endpoint $url"
    );
    count(1);
    my $opId = expectCookie($res);
    my $tmp;
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldap=$opId;$opPdata",
            length => length($query),
        ),
        "Post confirmation,          endpoint $url"
    );
    count(1);

    ($query) = expectRedirection( $res, qr#^http://auth.proxy.com/?\?(.*)$# );

    # Push OP response to Proxy

    ok(
        $res = $proxy->_get(
            '/',
            query  => $query,
            accept => 'text/html',
            cookie => $proxyPdata
        ),
        'Call openidconnectcallback on Proxy'
    );
    count(1);
    my $proxyId = expectCookie($res);
    ( $url, $query ) = expectRedirection( $res,
        qr#http://auth.proxy.com(/saml[^\?]*)(?:\?(.+))?$# );
    $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$proxyId;$proxyPdata",
        ),
        'Replay SAML request'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Push SAML response to SP
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post SAML response to SP'
    );
    my $spId = expectCookie($res);
    expectRedirection( $res, 'http://auth.sp.com/' );

    # Logout initiated by SP
    ok(
        $res = $sp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'Query SP for logout'
    );
    if ( $method eq "Redirect" ) {
        ( $url, $query ) = expectRedirection( $res,
            qr#^http://auth.proxy.com(/saml/singleLogout)\?(SAMLRequest=.+)# );

        # Push SAML logout request to proxy
        ok(
            $res = $proxy->_get(
                $url,
                query  => $query,
                accept => 'text/html',
                cookie => "lemonldap=$proxyId",
            ),
            'Launch SAML logout request to IdP'
        );
    }
    else {
        ( $host, $url, $query ) =
          expectForm( $res, 'auth.proxy.com', '/saml/singleLogout',
            'SAMLRequest' );

        # Push SAML logout request to proxy
        ok(
            $res = $proxy->_post(
                $url, IO::String->new($query),
                length => length($query),
                accept => 'text/html',
                cookie => "lemonldap=$proxyId",
            ),
            'Launch SAML logout request to IdP'
        );
    }

    ( $url, $query ) =
      expectRedirection( $res, qr#^http://auth.op.com(/oauth2/logout)\?(.+)# );

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    # Push OIDC logout request to op
    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$opId",
        ),
        'Push OIDC logout request to op'
    );

    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldap=$opId",
            length => length($query),
        ),
        "Post logout confirmation",
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.proxy.com(/oauth2/rlogoutreturn)\?(.+)# );
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$proxyId",
        ),
        'Follow OIDC logout response to proxy'
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.proxy.com(/saml/singleLogoutResume)\?(.+)# );
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$proxyId",
        ),
        'Switch to SAML logout resumption URL'
    );

    if ( $method eq "Redirect" ) {
        ( $url, $query ) = expectRedirection( $res,
qr#^http://auth.sp.com(/saml/proxySingleLogoutReturn)\?(SAMLResponse=.+)#
        );

        # Forward logout to SP
        ok(
            $res = $sp->_get(
                $url,
                query  => $query,
                accept => 'text/html',
                cookie => "lemondap=$spId",
            ),
            'Forward logout response to SP'
        );
    }
    else {
        ( $host, $url, $query ) =
          expectForm( $res, 'auth.sp.com', '/saml/proxySingleLogoutReturn',
            'SAMLResponse' );

        # Forward logout to SP
        ok(
            $res = $sp->_post(
                $url, IO::String->new($query),
                length => length($query),
                accept => 'text/html',
                cookie => "lemondap=$spId",
            ),
            'Forward logout response to SP'
        );
    }

    # TODO
    if ( $method eq "Redirect" ) {
        expectOK($res);
    }
    else {
        expectRedirection( $res, 'http://auth.sp.com/?logout=1' );
    }

    is_deeply( getSession($spId)->data,    {}, "SP session was removed" );
    is_deeply( getSession($opId)->data,    {}, "OP session was removed" );
    is_deeply( getSession($proxyId)->data, {}, "Proxy session was removed" );

}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found';
    }

    subtest "Test with Redirect binding" => sub {
        test("Redirect");
    };

    subtest "Test with POST binding" => sub {
        test("POST");
    };
    subtest "Test with POST binding and hashStorage" => sub {
        test( "POST", 1 );
    };
}

clean_sessions();
done_testing();

sub op {
    my ($hashStorage) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                ( $hashStorage ? ( hashedSessionStore => 1 ) : () ),
                domain                          => 'op.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                oidcRPMetaDataExportedVars      => {
                    proxy => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    }
                },
                oidcRPMetaDataOptionsExtraClaims => {
                    proxy => {
                        email => 'email',
                    },
                },
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    proxy => {
                        oidcRPMetaDataOptionsDisplayName       => "Proxy",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsRedirectUris          =>
                          'http://auth.proxy.com/?openidconnectcallback=1',
                        oidcRPMetaDataOptionsPostLogoutRedirectUris =>
                          "http://auth.proxy.com/oauth2/rlogoutreturn",
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

sub proxy {
    my ( $jwks, $metadata, $method, $hashStorage ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                ( $hashStorage ? ( hashedSessionStore => 1 ) : () ),
                domain                     => 'proxy.com',
                portal                     => 'http://auth.proxy.com/',
                authentication             => 'OpenIDConnect',
                userDB                     => 'Same',
                restSessionServer          => 1,
                oidcOPMetaDataExportedVars => {
                    op => {
                        cn   => "name",
                        uid  => "sub",
                        sn   => "family_name",
                        mail => "email"
                    }
                },
                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsJWKSTimeout  => 0,
                        oidcOPMetaDataOptionsClientSecret => "rpsecret",
                        oidcOPMetaDataOptionsScope => "openid profile email",
                        oidcOPMetaDataOptionsStoreIDToken     => 0,
                        oidcOPMetaDataOptionsDisplay          => "",
                        oidcOPMetaDataOptionsClientID         => "rpid",
                        oidcOPMetaDataOptionsConfigurationURI =>
"https://auth.proxy.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJWKS => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                },
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'sp.com' => {
                        cn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        uid =>
'1;uid;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    }
                },
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.proxy.com/",
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_public_enc,
                samlServicePublicKeySig     => saml_key_idp_public_sig,
                samlSPMetaDataXML           => {
                    "sp.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', "HTTP-$method" )
                    },
                },
            }
        }
    );
}

sub sp {
    my ( $method, $hashStorage ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                ( $hashStorage ? ( hashedSessionStore => 1 ) : () ),
                domain                            => 'sp.com',
                portal                            => 'http://auth.sp.com/',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 0,
                restSessionServer                 => 1,
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    idp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => lc($method),
                        samlIDPMetaDataOptionsSLOBinding     => lc($method),
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'proxy', "HTTP-$method" )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.sp.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}
