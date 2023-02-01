use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

# ------------      ---------------------------     ----------------
# | OIDC RP  |  <-> | OIDC provider + SAML SP | <-> | SAML IdP     |
# ------------      ---------------------------     ----------------
#
# Use case:
# - login from RP up to SAML IdP
# - logout asked from RP, and propagated up to SAML IdP
# logout between SAML SP and IdP is done with Redirect binding

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 17;
my $debug     = 'error';

#my $debug     = 'error';
my ( $op, $rp, $idp, $res );

# Overloads method register, for enabling direct POST requests between RP and OP
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:op|rp|idp)).com(.*)#,
            ' REST request' );
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

    $idp = register( 'idp', \&idp );

    $rp = register( 'rp', sub { rp( $jwks, $metadata ) } );

    # LOGIN PROCESS ############################################################

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.op.com(/oauth2/authorize)\?(.*)$# );

    # Push request to OP
    switch ('op');
    ok( $res = $op->_get( $url, query => $query, accept => 'text/html' ),
        "Push request to OP,         endpoint $url" );

    my $pdataop = expectCookie( $res, 'lemonldappdata' );

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
      expectForm( $res, 'auth.op.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse', 'RelayState' );

    my ($resp) = $query =~ qr/SAMLResponse=([^&]*)/;

    # Post SAML response to SP
    switch ('op');
    ok(
        $res = $op->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldappdata=$pdataop",
        ),
        'Post SAML response to SP'
    );

    $pdataop = expectCookie( $res, 'lemonldappdata' );
    my $cookieop = expectCookie( $res, 'lemonldap' );

    ( $url, $query ) =
      expectRedirection( $res, qr#^http://auth.op.com(/oauth2)\?*(.*)$# );

    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataop; lemonldap=$cookieop",
        ),
        'Call OP from SAML SP'
    );

    $pdataop = expectCookie( $res, 'lemonldappdata' );

# No consent here because we have disabled it (oidcRPMetaDataOptionsBypassConsent)

    ($query) = expectRedirection( $res, qr#^http://auth.rp.com/?\?(.*)$# );

    # Push OP response to RP
    switch ('rp');

    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Call openidconnectcallback on RP' );
    my $cookierp = expectCookie( $res, 'lemonldap' );

    # Authentication done on RP + OP + IDP

    # LOGOUT PROCESS ###########################################################
    $url   = '/';
    $query = 'logout=1';
    ok(
        $res = $rp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$cookierp",
        ),
        'Call logout from RP'
    );

    # lemonldap cookie set to "0"
    $cookierp = expectCookie( $res, 'lemonldap' );
    ok( $cookierp eq "0", 'Test empty cookie on RP' );

    # forward logout to OP
    ( $url, $query ) =
      expectRedirection( $res, qr#^http://auth.op.com(/.*)\?(.*)$# );

    switch ('op');

    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataop; lemonldap=$cookieop",
        ),
        'Forward logout to OP'
    );

    # expectForm (result, host, uri, @requiredfield)
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef,
        ( 'post_logout_redirect_uri', 'confirm', 'skin' ) );

    ok(
        $res = $op->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataop; lemonldap=$cookieop",
            length => length($query),
        ),
        "Post logout confirmation to OP,          endpoint $url"
    );

    # lemonldap cookie set to "0"
    $cookieop = expectCookie( $res, 'lemonldap' );
    ok( $cookieop eq "0", 'Test empty cookie on OP' );

    ( $url, $query ) =
      expectRedirection( $res, qr#^http://auth.idp.com(/.*)\?(.*)$# );

    switch ('idp');

    ok(
        $res = $idp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataidp; lemonldap=$cookieidp",
        ),
        'redirect to IdP'
    );

    # lemonldap cookie set to "0"
    $cookieidp = expectCookie( $res, 'lemonldap' );
    ok( $cookieidp eq "0", 'Test empty cookie on IDP' );

    ( $url, $query ) =
      expectRedirection( $res, qr#^http://auth.op.com(/.*)\?(.*)$# );

    switch ('op');

    ok(
        $res = $op->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldappdata=$pdataop; lemonldap=$cookieop",
        ),
        'redirect to OP'
    );

    expectOK($res);

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
                authentication                  => 'SAML',
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

                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.op.com/",
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlIDPSSODescriptorWantAuthnRequestsSigned => 1,
                samlSPSSODescriptorWantAssertionsSigned     => 1,
                samlIDPMetaDataXML                          => {
                    'idp' => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
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
                        'samlIDPMetaDataOptionsSLOBinding' => 'http-redirect',
                        'samlIDPMetaDataOptionsSSOBinding' => 'http-redirect',
                        'samlIDPMetaDataOptionsSignSLOMessage'  => 1,
                        'samlIDPMetaDataOptionsSignSSOMessage'  => 1,
                        'samlIDPMetaDataOptionsSignatureMethod' => '',
                        'samlIDPMetaDataOptionsStoreSAMLToken'  => 0
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    'idp' => {
                        'cn'  => '1;cn',
                        'uid' => '1;uid'
                    }
                },
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
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'op', 'HTTP-Redirect' ),
                        'samlSPSSODescriptorAuthnRequestsSigned'  => 1,
                        'samlSPSSODescriptorWantAssertionsSigned' => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'sp' => {
                        'cn'  => '1;cn',
                        'uid' => '1;uid'
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
