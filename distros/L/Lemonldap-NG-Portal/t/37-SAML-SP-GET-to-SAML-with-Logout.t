use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 16;
my $debug     = 'error';
my ( $idp, $proxy, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        fail('POST should not launch SOAP requests');
        count(1);
        return [ 500, [], [] ];
    }
);

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    $idp   = register( 'idp',   \&idp );
    $sp    = register( 'sp',    \&sp );
    $proxy = register( 'proxy', \&proxy );

    # SP
    switch ('sp');
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Try SAML SP'
    );
    my $spPdata;
    my ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.proxy.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

    # Push SAML request to Proxy
    switch ('proxy');
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        'Launch SAML request to proxy'
    );
    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );
    my $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Push SAML request to Proxy
    switch ('idp');
    ok(
        $res = $idp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        'Launch SAML request to proxy'
    );
    my $idpPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Expect login form
    ( my $host, $url, $query ) =
      expectForm( $res, '#', undef, 'user', 'password' );

    # Try to authenticate to IDP
    $query =~ s/user=/user=french/;
    $query =~ s/password=/password=french/;
    ok(
        $res = $idp->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $idpPdata,
        ),
        "Post authentication,        endpoint $url"
    );
    count(1);
    my $idpId = expectCookie($res);
    $idpPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    expectRedirection( $res, qr#http://auth.idp.com/saml# );

    # Follow redirection to issuer
    ok(
        $res = $idp->_get(
            '/saml',
            accept => 'text/html',
            cookie => "$idpPdata; lemonldap=$idpId",
        ),
        "Follow redirection to issuer"
    );
    $idpPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Follow autoPost back to proxy
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.proxy.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    switch ('proxy');
    ok(
        $res = $proxy->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $proxyPdata,
        ),
        "Post SAMLResponse to proxy"
    );

    my $proxyId = expectCookie($res);
    $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    expectRedirection( $res, qr#http://auth.proxy.com/saml# );

    # Follow redirection to issuer
    ok(
        $res = $proxy->_get(
            '/saml',
            accept => 'text/html',
            cookie => "$proxyPdata; lemonldap=$proxyId",
        ),
        "Follow redirection to issuer"
    );
    $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Follow autoPost back to SP
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    switch ('sp');
    ok(
        $res = $sp->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $spPdata,
        ),
        "Post SAMLResponse to SP"
    );

    my $spId = expectCookie($res);
    expectRedirection( $res, qr#http://auth.sp.com# );

    # Now, try to logout from SP
    ok(
        $res = $sp->_get(
            '/logout',
            accept => 'text/html',
            length => length($query),
            cookie => "$spPdata;lemonldap=$spId",
        ),
        "Initiate logout"
    );
    is( expectCookie($res), 0, "Removed lemonldap cookie at sp" );

    # Expect redirection to proxy
    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.proxy.com(/saml/singleLogout)\?(SAMLRequest=.+)# );

    # Follow redirection to Proxy
    switch ('proxy');
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$proxyId",
        ),
        "Forward logout to proxy"
    );

    # Expect redirection to Idp
    is( expectCookie($res), 0, "Removed lemonldap cookie at proxy" );
    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleLogout)\?(SAMLRequest=.+)# );

    # Follow redirection to IDP
    switch ('idp');
    ok(
        $res = $idp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        "Forward logout to IDP"
    );
    is( expectCookie($res), 0, "Removed lemonldap cookie at idp" );

    # Expect redirection to proxy
    ( $url, $query ) = expectRedirection( $res,
qr#^http://auth.proxy.com(/saml/proxySingleLogoutReturn)\?(SAMLResponse=.+)#
    );

    # Follow redirection to Proxy
    switch ('proxy');
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        "Forward logout to proxy"
    );

    # Redirect to session logout resumption endpoint
    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.proxy.com(/saml/singleLogoutResume)\?(ResumeParams=.+)#
    );

    # Follow redirection to session resumption endpoint
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        "Resume proxy logout process"
    );

    # Expect redirection to SP
    ( $url, $query ) = expectRedirection( $res,
qr#^http://auth.sp.com(/saml/proxySingleLogoutReturn)\?(SAMLResponse=.+)#
    );

    # Follow redirection to SP
    switch ('sp');
    ok(
        $res = $sp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        "Forward logout to sp"
    );

    expectPortalError( $res, 47, "Logout OK" );
}

count($maintests);
clean_sessions();
done_testing( count() );

sub idp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                restSessionServer      => 1,
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'proxy' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'proxy' => {
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
                    "proxy" => {
                        samlSPMetaDataXML =>
                          samlProxyMetaDataXML( 'proxy', 'HTTP-Redirect' )
                    },
                },
            }
        }
    );
}

sub proxy {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'proxy.com',
                portal                 => 'http://auth.proxy.com',
                authentication         => 'SAML',
                userDB                 => 'Same',
                restSessionServer      => 1,
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsNameIDSessionKey => '_user',
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
                samlOrganizationDisplayName => "Proxy",
                samlOrganizationName        => "Proxy",
                samlOrganizationURL         => "http://www.proxy.com/",
                samlServicePrivateKeyEnc    => saml_key_proxy_private_enc,
                samlServicePrivateKeySig    => saml_key_proxy_private_sig,
                samlServicePublicKeyEnc     => saml_key_proxy_public_enc,
                samlServicePublicKeySig     => saml_key_proxy_public_sig,
                samlSPMetaDataXML           => {
                    "sp.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', 'HTTP-Redirect' )
                    },
                },
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
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
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
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
                    }
                },
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
                    proxy => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    proxy => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    proxy => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    proxy => {
                        samlIDPMetaDataXML =>
                          samlProxyMetaDataXML( 'proxy', 'HTTP-Redirect' )
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
