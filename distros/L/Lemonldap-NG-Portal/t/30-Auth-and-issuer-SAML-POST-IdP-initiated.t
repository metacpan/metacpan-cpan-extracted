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

my $maintests = 18;
my $debug     = 'error';
my ( $issuer, $sp, $res );

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
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    # Simple authentication on IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            '/', IO::String->new('user=russian&password=russian'),
            length => 29
        ),
        'Auth query'
    );
    expectOK($res);
    my $idpId = expectCookie($res);

    # Query IdP to access to SP (override URL)
    ok(
        $res = $issuer->_get(
            '/saml/singleSignOn',
            query => buildForm( {
                    IDPInitiated => 1,
                    spConfKey    => 'sp.com',
                    spDest       =>
                      'http://auth.alternate.com/saml/proxySingleSignOnPost',
                }
            ),
            cookie => "lemonldap=$idpId",
            accept => 'test/html'
        ),
        'Query IdP to access to SP'
    );
    my ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.alternate.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Query IdP to access to SP (unrecognized URL)
    ok(
        $res = $issuer->_get(
            '/saml/singleSignOn',
            query => buildForm( {
                    IDPInitiated => 1,
                    spConfKey    => 'sp.com',
                    spDest       =>
                      'http://auth.perdu.com/saml/proxySingleSignOnPost',
                }
            ),
            cookie => "lemonldap=$idpId",
            accept => 'test/html'
        ),
        'Query IdP to access to SP'
    );
    expectPortalError( $res, 51, "Bad destination" );

    # Query IdP to access to SP (normal URL)
    ok(
        $res = $issuer->_get(
            '/saml/singleSignOn',
            query  => 'IDPInitiated=1&spConfKey=sp.com',
            cookie => "lemonldap=$idpId",
            accept => 'test/html'
        ),
        'Query IdP to access to SP'
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

    # Verify authentication on SP
    my $spId = expectCookie($res);
    expectRedirection( $res, 'http://auth.sp.com' );

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'ru@badwolf.org@idp' );

    # Verify UTF-8
    ok( $res = $sp->_get("/sessions/global/$spId"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( $res->{cn} eq 'Русский', 'UTF-8 values' )
      or explain( $res, 'cn => Frédéric Accents' );

    # Logout initiated by IdP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Query IdP for logout'
    );
    expectOK($res);

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    ok(
        $res->[2]->[0] =~
m#iframe src="http://auth.idp.com(/saml/relaySingleLogoutPOST)\?(relay=.*?)"#s,
        'Get iframe request'
    ) or explain( $res, '' );
    ( $url, $query ) = ( $1, $2 );
    expectCspChildOK( $res, "auth.idp.com" );
    expectCspChildOK( $res, "http://auth.sp.com" );

    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html'
        ),
        'Get iframe'
    );
    ok( getHeader( $res, 'Content-Security-Policy' ) !~ /frame-ancestors/,
        ' Framing authorized' )
      or explain( $res->[1], 'No frame-ancestors' );
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
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleLogoutReturn',
        'SAMLResponse' );

    # Post SAML logout response to IdP
    switch ('issuer');
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
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if user is reject on IdP'
    );
    expectReject($res);

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
    expectAutoPost($res);
}

count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsEnableIDPInitiatedURL    => 1,
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
                samlOrganizationURL         => "http://www.idp.com/",
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_public_enc,
                samlServicePublicKeySig     => saml_key_idp_public_sig,
                samlSPMetaDataXML           => {
                    "sp.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', 'HTTP-POST' )
                    },
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
                        samlIDPMetaDataOptionsAllowLoginFromIDP        => 1,
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
                          samlIDPMetaDataXML( 'idp', 'HTTP-POST' )
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
