use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

# ------------      -----------------------------     ----------------
# | SAML SP  |  <-> |SAML IDP + SAML SP (proxy) | <-> | SAML IdP     |
# ------------      -----------------------------     ----------------
#
# Use case:
# - login from SP up to SAML IdP
# - logout asked from SP, and propagated up to SAML IdP
# logout between all SAML SP and IdP is done with SOAP binding

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 13;
my $debug     = 'error';
my ( $sp, $proxy, $idp, $res );

# Overloads method register, for enabling direct POST requests between SP, PROXY and IDP
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:sp|proxy|idp)).com(.*)#,
            ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $res, $client );
        count(1);
        if ( $host eq 'sp' ) {
            pass("  Request to SP,     endpoint $url");
            $client = $sp;
        }
        elsif ( $host eq 'proxy' ) {
            pass('  Request from PROXY to PROXY');
            $client = $proxy;
        }
        elsif ( $host eq 'idp' ) {
            pass('  Request to IDP');
            $client = $idp;
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
                '  Execute post request'
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
                '  Execute get request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        ok(
            getHeader( $res, 'Content-Type' ) =~
              m#^(application/json|text/xml)#,
            '  Content is JSON|XML'
          )
          or
          explain( $res->[1], 'Content-Type => (application/json|text/xml)' );
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
    $idp   = register( 'idp',   \&idp );
    $sp    = register( 'sp',    \&sp );
    $proxy = register( 'proxy', \&proxy );

    # LOGIN PROCESS ############################################################

    # Query SP for auth
    ok( $res = $sp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.proxy.com(/saml/singleSignOn)\?(.*)$# );

    # Push request to PROXY
    switch ('proxy');
    ok( $res = $proxy->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to PROXY,         endpoint $url" );

    my $pdataproxy = expectCookie( $res, 'lemonldappdata' );

    my ( $urlidp, $queryidp ) =
      expectRedirection( $res,
        qr#http://auth.idp.com(/saml/singleSignOn)\?(.*)$# );

    # Push request to IDP
    switch ('idp');

    # Try to authenticate to IdP
    ok(
        $res = $idp->_get( $urlidp, query => $queryidp, accept => 'text/html' ),
        "SAML Authentication on idp,        endpoint $urlidp"
    );
    my $pdataidp = expectCookie( $res, 'lemonldappdata' );

    my ( $host, $tmp );

    # expectForm (result, host, uri, @requiredfield)
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef,
        ( 'url', 'timezone', 'skin', 'user', 'password' ) );
    $query =~ s/user=/user=dwho/;
    $query =~ s/password=/password=dwho/;

    ok(
        $res = $idp->_post(
            $urlidp,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataidp",
            length => length($query),
        ),
        "Post authentication,          endpoint $urlidp"
    );

    $pdataidp = expectCookie( $res, 'lemonldappdata' );
    my $cookieidp = expectCookie( $res, 'lemonldap' );

    ( $host, $url, $query ) =
      expectForm( $res, 'auth.proxy.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse', 'RelayState' );

    my ($resp) = $query =~ qr/SAMLResponse=([^&]*)/;

    # Post SAML response to PROXY
    switch ('proxy');
    ok(
        $res = $proxy->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldappdata=$pdataproxy",
        ),
        'Post SAML response to PROXY'
    );

    $pdataproxy = expectCookie( $res, 'lemonldappdata' );
    my $cookieproxy = expectCookie( $res, 'lemonldap' );

    ( $url, $query ) =
      expectRedirection( $res, qr#^http://auth.proxy.com(/saml)\?*(.*)$# );
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataproxy; lemonldap=$cookieproxy"
        ),
        "internal redirection to PROXY,        endpoint $url"
    );

    ( $host, $url, $query ) =
      expectForm( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    ($resp) = $query =~ qr/SAMLResponse=([^&]*)/;

    # Post SAML response to PROXY
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post SAML response to SP'
    );

    my $cookiesp = expectCookie( $res, 'lemonldap' );

    # Authentication done on SP + PROXY + IDP

    # LOGOUT PROCESS ###########################################################
    $url   = '/';
    $query = 'logout=1';
    ok(
        $res = $sp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$cookiesp",
        ),
        'Call logout from SP'
    );

    # lemonldap cookie set to "0"
    $cookiesp = expectCookie( $res, 'lemonldap' );
    ok( $cookiesp eq "0", 'Test empty cookie on SP' );

    ok( $res->[2]->[0] =~ /trmsg="47"/, 'Test disconnexion message on SP' );

    # test connexion on PROXY
    switch ('proxy');
    ok(
        $res = $proxy->_get(
            '/',
            query  => '',
            accept => 'text/html',
            cookie => "lemonldap=$cookieproxy",
        ),
        'Test if still logged on PROXY'
    );

    ( $urlidp, $queryidp ) =
      expectRedirection( $res,
        qr#http://auth.idp.com(/saml/singleSignOn)\?(.*)$# );

    # test connexion on IDP
    switch ('idp');
    ok(
        $res = $idp->_get(
            '/',
            query  => '',
            accept => 'text/html',
            cookie => "lemonldap=$cookieidp",
        ),
        'Test if still logged on IDP'
    );

    like( $res->[2]->[0],
        qr/userfield/,
        'test presence of user field in form (prove successful logout)' );

}

count($maintests);
clean_sessions();
done_testing( count() );

sub proxy {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'proxy.com',
                portal                          => 'http://auth.proxy.com',
                authentication                  => 'SAML',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",

                samlOrganizationDisplayName => "proxy",
                samlOrganizationName        => "proxy",
                samlOrganizationURL         => "http://www.proxy.com/",
                samlServicePrivateKeyEnc    => saml_key_proxy_private_enc,
                samlServicePrivateKeySig    => saml_key_proxy_private_sig,
                samlServicePublicKeyEnc     => saml_key_proxy_public_enc,
                samlServicePublicKeySig     => saml_key_proxy_public_sig,
                samlIDPSSODescriptorWantAuthnRequestsSigned => 1,
                samlSPSSODescriptorWantAssertionsSigned     => 1,
                samlIDPMetaDataXML                          => {
                    'idp' => {
                        samlIDPMetaDataXML => samlIDPComplexMetaDataXML(
                            'idp', 'HTTP-Redirect', 'SOAP'
                        )
                    },
                },
                samlIDPMetaDataOptions => {
                    'idp' => {
                        'samlIDPMetaDataOptionsAdaptSessionUtime'        => 0,
                        'samlIDPMetaDataOptionsAllowLoginFromIDP'        => 0,
                        'samlIDPMetaDataOptionsCheckAudience'            => 1,
                        'samlIDPMetaDataOptionsCheckSLOMessageSignature' => 1,
                        'samlIDPMetaDataOptionsCheckSSOMessageSignature' => 1,
                        'samlIDPMetaDataOptionsCheckTime'                => 1,
                        'samlIDPMetaDataOptionsDisplayName'           => 'idp',
                        'samlIDPMetaDataOptionsEncryptionMode'        => 'none',
                        'samlIDPMetaDataOptionsForceAuthn'            => 0,
                        'samlIDPMetaDataOptionsForceUTF8'             => 0,
                        'samlIDPMetaDataOptionsIcon'                  => '',
                        'samlIDPMetaDataOptionsIsPassive'             => 0,
                        'samlIDPMetaDataOptionsNameIDFormat'          => '',
                        'samlIDPMetaDataOptionsRelayStateURL'         => 0,
                        'samlIDPMetaDataOptionsRequestedAuthnContext' => '',
                        'samlIDPMetaDataOptionsResolutionRule'        => '',
                        'samlIDPMetaDataOptionsSLOBinding' => 'http-soap',
                        'samlIDPMetaDataOptionsSSOBinding' => 'http-redirect',
                        'samlIDPMetaDataOptionsSignSLOMessage'  => 1,
                        'samlIDPMetaDataOptionsSignSSOMessage'  => 1,
                        'samlIDPMetaDataOptionsSignatureMethod' => '',
                        'samlIDPMetaDataOptionsStoreSAMLToken'  => 0
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    'idp' => {
                        'cn'   => '1;cn',
                        'uid'  => '1;uid',
                        'mail' => '1;mail',
                    }
                },

                issuerDBSAMLActivation => 1,
                restSessionServer      => 1,
                samlSPMetaDataOptions  => {
                    sp => {
                        'samlSPMetaDataOptionsCheckSLOMessageSignature' => 1,
                        'samlSPMetaDataOptionsCheckSSOMessageSignature' => 1,
                        'samlSPMetaDataOptionsEnableIDPInitiatedURL'    => 0,
                        'samlSPMetaDataOptionsEncryptionMode'      => 'none',
                        'samlSPMetaDataOptionsForceUTF8'           => 1,
                        'samlSPMetaDataOptionsNameIDFormat'        => '',
                        'samlSPMetaDataOptionsNotOnOrAfterTimeout' => 72000,
                        'samlSPMetaDataOptionsOneTimeUse'          => 0,
                        'samlSPMetaDataOptionsSessionNotOnOrAfterTimeout' =>
                          72000,
                        'samlSPMetaDataOptionsSignSLOMessage'  => -1,
                        'samlSPMetaDataOptionsSignSSOMessage'  => 1,
                        'samlSPMetaDataOptionsSignatureMethod' => ''
                    }
                },
                samlSPMetaDataXML => {
                    sp => {
                        samlSPMetaDataXML => samlSPComplexMetaDataXML(
                            'sp', 'HTTP-Redirect', 'SOAP'
                        ),
                        'samlSPSSODescriptorAuthnRequestsSigned'  => 1,
                        'samlSPSSODescriptorWantAssertionsSigned' => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'sp' => {
                        'cn'   => '1;cn',
                        'uid'  => '1;uid',
                        'mail' => '1;mail',
                    }
                },
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'sp.com',
                portal                          => 'http://auth.sp.com',
                authentication                  => 'SAML',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                samlOrganizationDisplayName     => "SP",
                samlOrganizationName            => "SP",
                samlOrganizationURL             => "http://www.sp.com/",
                samlServicePrivateKeyEnc        => saml_key_sp_private_enc,
                samlServicePrivateKeySig        => saml_key_sp_private_sig,
                samlServicePublicKeyEnc         => saml_key_sp_public_enc,
                samlServicePublicKeySig         => saml_key_sp_public_sig,
                samlIDPSSODescriptorWantAuthnRequestsSigned => 1,
                samlSPSSODescriptorWantAssertionsSigned     => 1,
                samlIDPMetaDataXML                          => {
                    'proxy' => {
                        samlIDPMetaDataXML => samlProxyComplexMetaDataXML(
                            'proxy', 'HTTP-Redirect', 'SOAP'
                        )
                    },
                },
                samlIDPMetaDataOptions => {
                    'proxy' => {
                        'samlIDPMetaDataOptionsAdaptSessionUtime'        => 0,
                        'samlIDPMetaDataOptionsAllowLoginFromIDP'        => 0,
                        'samlIDPMetaDataOptionsCheckAudience'            => 1,
                        'samlIDPMetaDataOptionsCheckSLOMessageSignature' => 1,
                        'samlIDPMetaDataOptionsCheckSSOMessageSignature' => 1,
                        'samlIDPMetaDataOptionsCheckTime'                => 1,
                        'samlIDPMetaDataOptionsDisplayName'    => 'proxy',
                        'samlIDPMetaDataOptionsEncryptionMode' => 'none',
                        'samlIDPMetaDataOptionsForceAuthn'     => 0,
                        'samlIDPMetaDataOptionsForceUTF8'      => 0,
                        'samlIDPMetaDataOptionsIcon'           => '',
                        'samlIDPMetaDataOptionsIsPassive'      => 0,
                        'samlIDPMetaDataOptionsNameIDFormat'   => '',
                        'samlIDPMetaDataOptionsRelayStateURL'  => 0,
                        'samlIDPMetaDataOptionsRequestedAuthnContext' => '',
                        'samlIDPMetaDataOptionsResolutionRule'        => '',
                        'samlIDPMetaDataOptionsSLOBinding' => 'http-soap',
                        'samlIDPMetaDataOptionsSSOBinding' => 'http-redirect',
                        'samlIDPMetaDataOptionsSignSLOMessage'  => 1,
                        'samlIDPMetaDataOptionsSignSSOMessage'  => 1,
                        'samlIDPMetaDataOptionsSignatureMethod' => '',
                        'samlIDPMetaDataOptionsStoreSAMLToken'  => 0
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    'proxy' => {
                        'cn'   => '1;cn',
                        'uid'  => '1;uid',
                        'mail' => '1;mail',
                    }
                },
            }
        }
    );
}

sub idp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                restSessionServer      => 1,
                samlSPMetaDataOptions  => {
                    proxy => {
                        'samlSPMetaDataOptionsCheckSLOMessageSignature' => 1,
                        'samlSPMetaDataOptionsCheckSSOMessageSignature' => 1,
                        'samlSPMetaDataOptionsEnableIDPInitiatedURL'    => 0,
                        'samlSPMetaDataOptionsEncryptionMode'      => 'none',
                        'samlSPMetaDataOptionsForceUTF8'           => 1,
                        'samlSPMetaDataOptionsNameIDFormat'        => '',
                        'samlSPMetaDataOptionsNotOnOrAfterTimeout' => 72000,
                        'samlSPMetaDataOptionsOneTimeUse'          => 0,
                        'samlSPMetaDataOptionsSessionNotOnOrAfterTimeout' =>
                          72000,
                        'samlSPMetaDataOptionsSignSLOMessage'  => -1,
                        'samlSPMetaDataOptionsSignSSOMessage'  => 1,
                        'samlSPMetaDataOptionsSignatureMethod' => ''
                    }
                },
                samlSPMetaDataXML => {
                    proxy => {
                        samlSPMetaDataXML => samlProxyComplexMetaDataXML(
                            'proxy', 'HTTP-Redirect', 'SOAP'
                        ),
                        'samlSPSSODescriptorAuthnRequestsSigned'  => 1,
                        'samlSPSSODescriptorWantAssertionsSigned' => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'proxy' => {
                        'cn'   => '1;cn',
                        'uid'  => '1;uid',
                        'mail' => '1;mail',
                    }
                },
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.idp.com",
                samlServicePublicKeySig     => saml_key_idp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}
