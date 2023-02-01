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
    require 't/saml-lib.pm';
}

my $maintests = 23;
my $debug     = 'error';
my ( $op, $rp, $sp, $res );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:o|r)p).com(.*)#, ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $res, $client );
        count(1);
        if ( $host eq 'op' ) {
            pass("  Request from RP to OP,     endpoint $url");
            $client = $op;
        }
        elsif ( $host eq 'rp' ) {
            pass('  Request from OP to RP');
            $client = $rp;
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

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

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

    $sp = register( 'sp', \&sp );

    $rp = register( 'rp', sub { rp( $jwks, $metadata ) } );

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    switch ('op');
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    $query = "user=french&password=french&$query";
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $pdata,
        ),
        "Post authentication,        endpoint $url"
    );
    my $idpId = expectCookie($res);
    my ( $host, $tmp );
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($query),
        ),
        "Post confirmation,          endpoint $url"
    );

    ($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Push OP response to RP
    switch ('rp');

    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Call openidconnectcallback on RP' );
    my $rpId = expectCookie($res);

    switch ('op');
    ok(
        $res = $op->_get( '/oauth2/checksession.html', accept => 'text.html' ),
        'Check session,      endpoint /oauth2/checksession.html'
    );
    expectOK($res);
    ok( getHeader( $res, 'Content-Security-Policy' ) !~ /frame-ancestors/,
        ' Frame can be embedded' )
      or explain( $res->[1],
        'Content-Security-Policy does not contain a frame-ancestors' );

    # SAML
    switch ('sp');
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Try SAML SP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.op.com', '/saml/singleSignOn',
        'SAMLRequest' );

    switch ('op');
    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$idpId",
        ),
        'Post SAML request to IdP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post SAML response to SP'
    );
    my $spId = expectCookie($res);

    # Logout initiated by RP
    switch ('rp');
    ok(
        $res = $rp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$rpId",
            accept => 'text/html'
        ),
        'Query SP for logout'
    );
    ( $url, $query ) = expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/logout)\?(post_logout_redirect_uri=.+)$#
    );

    # Push logout to OP
    switch ('op');

    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        "Push logout request to OP,     endpoint $url"
    );

    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    ok(
        $res = $op->_post(
            $url, IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$idpId",
            accept => 'text/html',
        ),
        "Confirm logout,                endpoint $url"
    );
    expectOK($res);

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    ok(
        $res->[2]->[0] =~
m#iframe src="http://auth.op.com(/saml/relaySingleLogoutPOST)\?(relay=.*?)"#s,
        'Get iframe request'
    ) or explain( $res, '' );
    ( $url, $query ) = ( $1, $2 );
    switch ('op');
    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            accept => 'text/html'
        ),
        'Get iframe'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleLogout',
        'SAMLRequest' );

    # Post SAML logout request to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$spId",
        ),
        'Post SAML logout request to SP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.op.com', '/saml/singleLogoutReturn',
        'SAMLResponse' );

    # Post SAML logout response to IdP
    switch ('op');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$spId",
        ),
        'Post SAML logout response to IdP'
    );

    # Test if logout is done
    ok(
        $res = $op->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if user is reject on IdP'
    );
    expectReject($res);

    switch ('rp');
    ok(
        $res = $rp->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$rpId"
        ),
        'Test if user is reject on SP'
    );
    expectRedirection( $res, qr#^http://auth.op.com/oauth2/authorize# );

    switch ('sp');
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$spId"
        ),
        'Test if user is reject on SP'
    );
    expectOK($res);
    expectAutoPost( $res, 'auth.op.com', '/saml/singleSignOn', 'SAMLRequest' );
}

count($maintests);
clean_sessions();
done_testing( count() );

sub op {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'op.com',
                portal                          => 'http://auth.op.com',
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
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600
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
                issuerDBSAMLActivation   => 1,
                samlSPMetaDataOptions    => {
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
                samlOrganizationURL         => "http://www.op.com/",
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_public_enc,
                samlServicePublicKeySig     => saml_key_idp_public_sig,
                samlSPMetaDataXML           => {
                    "sp.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', 'HTTP-POST' )
                    },
                }
            }
        }
    );
}

sub rp {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'rp.com',
                portal                     => 'http://auth.rp.com',
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
                        oidcOPMetaDataOptionsScope        => "openid profile",
                        oidcOPMetaDataOptionsStoreIDToken => 0,
                        oidcOPMetaDataOptionsDisplay      => "",
                        oidcOPMetaDataOptionsClientID     => "rpid",
                        oidcOPMetaDataOptionsConfigurationURI =>
                          "https://auth.op.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJWKS => {
                    op => $jwks,
                },
                oidcOPMetaDataJSON => {
                    op => $metadata,
                }
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp.com',
                portal                            => 'http://auth.sp.com',
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
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
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
                          samlIDPMetaDataXML( 'op', 'HTTP-POST' )
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
