use warnings;
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

my $debug = 'error';
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
        skip 'Lasso not found';
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    subtest "SP-initiated flow, unauthorized user" => sub {

        # SP-initiated flow
        my $res;
        ok(
            $res = $sp->_get(
                '/', accept => 'text/html',
            ),
            'Unauth SP request'
        );
        expectOK($res);
        my ( $host, $url, $s ) =
          expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
            'SAMLRequest' );
        my $pdata_hash = expectPdata($res);
        is( $pdata_hash->{genRequestHookCalled},
            1, 'samlGenerateRequestHook called' );

        # Push SAML request to IdP
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
        my $rawCookie = getHeader( $res, 'Set-Cookie' );
        ok( $rawCookie =~ /;\s*SameSite=None/, 'Found SameSite=None' );

        # Try to authenticate with an unauthorized user to IdP
        $s = "user=dwho&password=dwho&$s";
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
        ok( $res->[2]->[0] =~ /trmsg="89"/, 'Reject reason is 89' )
          or print STDERR Dumper( $res->[2]->[0] );
    };

    subtest "SP-initiated flow, authorized user" => sub {

        my $res;

        # Simple SP access
        ok(
            $res = $sp->_get(
                '/', accept => 'text/html',
            ),
            'Unauth SP request'
        );
        expectOK($res);
        my ( $host, $url, $s ) =
          expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
            'SAMLRequest' );

        # Push SAML request to IdP
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

        # Try to authenticate with an authorized user to IdP
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

        # Expect pdata to be cleared
        $pdata = expectCookie( $res, 'lemonldappdata' );
        ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' )
          or explain( $pdata, 'not issuerRequestsaml' );

        ( $host, $url, $s ) =
          expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
            'SAMLResponse' );

        my $resp = expectSamlResponse($s);
        like(
            $resp,
            qr/AuthnInstant="2000-01-01T00:00:01Z"/,
            "Found AuthnInstant modified by hook"
        );

        my $pdata_hash = expectPdata($res);
        is( $pdata_hash->{gotRequestHookCalled},
            1, 'samlGotRequestHookCalled called' );

        # Post SAML response to SP
        ok(
            $res = $sp->_post(
                $url, IO::String->new($s),
                accept => 'text/html',
                length => length($s),
            ),
            'Post SAML response to SP'
        );

        # Verify authentication on SP
        expectRedirection( $res, 'http://auth.sp.com' );
        my $spId      = expectCookie($res);
        my $rawCookie = getHeader( $res, 'Set-Cookie' );
        ok( $rawCookie =~ /;\s*SameSite=None/, 'Found SameSite=None' );

        ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ),
            'Get / on SP' );
        expectOK($res);
        expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

        # Verify UTF-8
        $res = getSession($spId)->data;
        is( $res->{gotResponseHookCalled}, 1, 'samlGotResponseHook called' );
        ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
          or explain( $res, 'cn => Frédéric Accents' );

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
        is( $removedCookie, 0, "IDP Cookie removed" );

        # Post SAML response to SP
        ok(
            $res = $sp->_post(
                $url, IO::String->new($s),
                accept => 'text/html',
                length => length($s),
            ),
            'Post SAML response to SP'
        );
        expectRedirection( $res, 'http://auth.sp.com' );

        # Test if logout is done
        ok(
            $res = $issuer->_get(
                '/', cookie => "lemonldap=$idpId",
            ),
            'Test if user is reject on IdP'
        );
        expectReject($res);

        ok(
            $res = $sp->_get(
                '/',
                accept => 'text/html',
                cookie => "lemonldap=$spId"
            ),
            'Test if user is reject on SP'
        );
        expectOK($res);
        expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
            'SAMLRequest' );
    };

    subtest "SP-initiated flow, authorized user, with redirection" => sub {

        my $res;

        # Simple SP access
        ok(
            $res = $sp->_get(
                '/', accept => 'text/html',
            ),
            'Unauth SP request'
        );
        expectOK($res);
        my ( $host, $url, $s ) =
          expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
            'SAMLRequest' );

        # Push SAML request to IdP
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

        # Try to authenticate with an authorized user to IdP
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

        # Expect pdata to be cleared
        $pdata = expectCookie( $res, 'lemonldappdata' );
        ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' )
          or explain( $pdata, 'not issuerRequestsaml' );

        ( $host, $url, $s ) =
          expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
            'SAMLResponse' );

        my $resp = expectSamlResponse($s);
        like(
            $resp,
            qr/AuthnInstant="2000-01-01T00:00:01Z"/,
            "Found AuthnInstant modified by hook"
        );

        my $pdata_hash = expectPdata($res);
        is( $pdata_hash->{gotRequestHookCalled},
            1, 'samlGotRequestHookCalled called' );

        # Post SAML response to SP
        ok(
            $res = $sp->_post(
                $url, IO::String->new($s),
                accept => 'text/html',
                length => length($s),
            ),
            'Post SAML response to SP'
        );

        # Verify authentication on SP
        expectRedirection( $res, 'http://auth.sp.com' );
        my $spId      = expectCookie($res);
        my $rawCookie = getHeader( $res, 'Set-Cookie' );
        ok( $rawCookie =~ /;\s*SameSite=None/, 'Found SameSite=None' );

        ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ),
            'Get / on SP' );
        expectOK($res);
        expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

        # Verify UTF-8
        $res = getSession($spId)->data;
        is( $res->{gotResponseHookCalled}, 1, 'samlGotResponseHook called' );
        ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
          or explain( $res, 'cn => Frédéric Accents' );

        # Logout initiated by SP
        ok(
            $res = $sp->_get(
                '/',
                query => buildForm( {
                        logout => 1,
                        url    => encodeUrl("http://test1.example.com")
                    }
                ),
                cookie => "lemonldap=$spId",
                accept => 'text/html'
            ),
            'Query SP for logout'
        );
        ( $host, $url, $s ) =
          expectAutoPost( $res, 'auth.idp.com', '/saml/singleLogout',
            'SAMLRequest' );

        # Push SAML logout request to IdP
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
        is( $removedCookie, 0, "IDP Cookie removed" );

        # Post SAML response to SP
        ok(
            $res = $sp->_post(
                $url, IO::String->new($s),
                accept => 'text/html',
                length => length($s),
            ),
            'Post SAML response to SP'
        );
        expectRedirection( $res, 'http://test1.example.com' );

        # Test if logout is done
        ok(
            $res = $issuer->_get(
                '/', cookie => "lemonldap=$idpId",
            ),
            'Test if user is reject on IdP'
        );
        expectReject($res);

        ok(
            $res = $sp->_get(
                '/',
                accept => 'text/html',
                cookie => "lemonldap=$spId"
            ),
            'Test if user is reject on SP'
        );
        expectOK($res);
        expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
            'SAMLRequest' );
    };
}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                globalLogoutRule       => 1,
                globalLogoutTimer      => 0,
                issuerDBSAMLActivation => 1,
                issuerDBSAMLRule       => '$uid eq "french"',
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
                customPlugins => 't::SamlHookPlugin',
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
                customPlugins                          => 't::SamlHookPlugin',

            },
        }
    );
}
