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
        ok( $req->uri =~ m#http://auth.((?:id|s)p).com(.*)#, 'SOAP request' );
        my $host = $1;
        my $url  = $2;
        my $res;
        my $s      = $req->content;
        my $client = ( $host eq 'idp' ? $issuer : $sp );
        ok(
            $res = $client->_post(
                $url, IO::String->new($s),
                length => length($s),
                type   => 'application/xml',
            ),
            'Execute request'
        );
        ok( ( $res->[0] == 200 or $res->[0] == 400 ), 'Response is 200 or 400' )
          or explain( $res->[0], "200 or 400" );
        ok( getHeader( $res, 'Content-Type' ) =~ m#^text/xml#,
            'Content is XML' )
          or explain( $res->[1], 'Content-Type => text/xml' );
        count(4);
        return $res;
    }
);

SKIP: {
    unless (
        eval
'use Lasso; (Lasso::check_version( 2, 5, 1, Lasso::Constants::CHECK_VERSION_NUMERIC) )? 1 : 0'
      )
    {
        skip 'Lasso not found or too old';
    }
    if ($@) {
        skip 'Lasso not found';
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

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

        my ( $host, $url, $s ) = expectForm( $res, '#', undef, 'lmAuth' );

        # Choose SAML
        ok(
            $res = $sp->_post(
                '/',
                IO::String->new($s),
                accept => 'text/html',
                length => length($s)
            ),
            'Post Choice request to IdP'
        );

        ( $host, $url, $s ) =
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

        # Post SAML response to SP
        ok(
            $res = $sp->_post(
                $url, IO::String->new($s),
                accept => 'text/html',
                length => length($s),
            ),
            'Post SAML response to SP'
        );

        ( $host, $url, $s ) =
          expectForm( $res, undef, '/ext2fcheck?skin=bootstrap', 'token',
            'code' );

        $s =~ s/code=/code=A1b2C0/;
        ok(
            $res = $sp->_post(
                '/ext2fcheck',
                IO::String->new($s),
                length => length($s),
                accept => 'text/html',
            ),
            'Post code'
        );

        # Verify authentication on SP
        expectRedirection( $res, 'http://auth.sp.com/' );
        my $spId      = expectCookie($res);
        my $rawCookie = getHeader( $res, 'Set-Cookie' );
        ok( $rawCookie =~ /;\s*SameSite=None/, 'Found SameSite=None' );

        ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ),
            'Get / on SP' );
        expectOK($res);
        expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

        # Verify UTF-8
        ok( getSession($spId)->data->{cn} eq 'Frédéric Accents',
            'UTF-8 values' )
          or explain( $res, 'cn => Frédéric Accents' );

        # Logout initiated by IDP
        ok(
            $res = $issuer->_get(
                '/',
                query  => 'logout',
                cookie => "lemonldap=$idpId",
                accept => 'text/html'
            ),
            'Query IDP for logout'
        );

        my $removedCookie = expectCookie($res);
        is( $removedCookie, 0, "IDP Cookie removed" );

        ok(
            $res->[2]->[0] =~
m#img src="http://auth.idp.com(/saml/relaySingleLogoutSOAP)\?(relay=.*?)"#s,
            'Get image request'
        );

        ok(
            $res = $issuer->_get(
                $1,
                query  => $2,
                accept => 'text/html'
            ),
            'Get image'
        );
        expectRedirection( $res,
            "http://auth.idp.com/static/common/icons/ok.png" );

        # Test if logout is done
        ok(
            $res = $sp->_get(
                '/', cookie => "lemonldap=$spId"
            ),
            'Test if user is reject on SP'
        );
        expectReject($res);
    };
}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com/',
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
                          samlSPComplexMetaDataXML( 'sp', 'HTTP-POST', 'SOAP' )
                    },
                },
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'sp.com',
                portal            => 'http://auth.sp.com/',
                authentication    => 'Choice',
                userDB            => 'Same',
                authChoiceModules => {
                    '1_SAML' => 'SAML;SAML;Null;;;{}',
                },
                userDB                            => 'Same',
                ext2fActivation                   => 1,
                ext2fCodeActivation               => 'A1b2C0',
                ext2FSendCommand                  => '/bin/true',
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
                        samlIDPMetaDataOptionsSignatureMethod => "RSA_SHA256",
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

            },
        }
    );
}
