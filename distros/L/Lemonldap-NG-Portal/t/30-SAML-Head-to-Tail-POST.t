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

my $maintests = 11;
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

    # Simple SP access
    my $res;
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    my ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            length => length($s)
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    $s = "user=french&password=french&$s";
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            cookie => $pdata,
            length => length($s),
        ),
        'Post authentication'
    );
    my $idpId = expectCookie($res);
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    ( $url, $s ) =
      expectRedirection( $res, qr#^http://auth.sp.com(/?[^\?]*)(?:\?(.*))?$# );
    my $spId = expectCookie($res);

    ok(
        $res = $sp->_get(
            $url || '/',
            query  => $s,
            cookie => "lemonldap=$spId",
            accept => 'text/html',
        ),
        ' Follow redirection'
    );
    expectOK($res);

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
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleLogout',
        'SAMLRequest' );

    # Push SAML logout request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($s)
        ),
        'Post SAML logout request to IdP'
    );
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleLogoutReturn',
        'SAMLResponse' );

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );
    expectOK($res);

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
    expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn', 'SAMLRequest' );
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
                issuerDBSAMLPath       => 'saml',
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
    my $xml = samlIDPMetaDataXML( 'idp', 'HTTP-POST' );
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp.com',
                portal                            => 'http://auth.sp.com',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 1,
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
                        samlIDPMetaDataXML => $xml,
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
