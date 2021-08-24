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

my $debug     = 'error';
my $maintests = 132;
my ( $issuer, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        fail('POST should not launch SOAP requests');
        return [ 500, [], [] ];
    }
);

sub runTest {
    my ( $req_nif, $res_nif, $force_attr, $expect_req_nif, $expect_res_nif,
        $expect_nameid )
      = @_;

    # Initialization
    $issuer = register( 'issuer', sub { issuer( $res_nif, $force_attr ) } );
    $sp     = register( 'sp',     sub { sp($req_nif) } );

    # Simple SP access
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

    my $sr = expectSamlRequest($s);
    expectXPath(
        $sr,             '/samlp:AuthnRequest/samlp:NameIDPolicy/@Format',
        $expect_req_nif, 'Found expected NameID Format in request',
    );

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

    $sr = expectSamlResponse($s);
    expectXPath(
        $sr, '/samlp:Response/saml:Assertion/saml:Subject/saml:NameID/@Format',
        $expect_res_nif, 'Found expected NameID Format in response',
    );

    if ($expect_nameid) {
        my $nameidvalue = expectXPath( $sr,
            '/samlp:Response/saml:Assertion/saml:Subject/saml:NameID/text()' );
        if ( ref($expect_nameid) eq "Regexp" ) {
            like( $nameidvalue, $expect_nameid, "NameID matches" );
        }
        else {
            is( $nameidvalue, $expect_nameid, "NameID matches" );
        }
    }
}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip( 'Lasso not found', $maintests );
    }

    # Default settings use the email NIF
    runTest(
        # requested NameIDFormat (sp side)
        undef,

        # returned NameIDFormat (idp side)
        undef,

        # Name ID session key
        undef,

        # Expected NameIDFormat in SAMLRequest
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",

        # Expected NameIDFormat in SAMLResponse
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",

        # Expected NameID value
        'fa@badwolf.org'
    );

    # Override session key
    runTest(
        undef,
        undef,
        "uid",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        'french'
    );

    # Using email explicitely return the email
    runTest(
        "email",
        "email",
        undef,
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        'fa@badwolf.org'
    );

    # Changing the format on the IDP side has no effect if the client
    # specifies a NIF
    runTest(
        "email",
        "kerberos",
        undef,
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        'fa@badwolf.org'
    );

    # Using unspecified on the requesting side causes IDP settings to be honored
    # specifies a NIF
    runTest(
        "unspecified",
        "kerberos",
        undef,
        "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        "urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos",
        'french'
    );

    # Unspecified both ways + no forced key returns no value
    runTest(
        "unspecified",
        "unspecified",
        undef,
        "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        undef,
    );

    # Unspecified both ways returns forced key in unspecified format
    runTest(
        "unspecified",
        "unspecified",
        'mail',
        "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        'fa@badwolf.org',
    );

    # persistent asked by SP returns a value
    runTest(
        "persistent",
        "email",
        undef,
        "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        qr/./,
    );

    # persistent chosen by IDP returns a value
    runTest(
        "unspecified",
        "persistent",
        undef,
        "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        qr/./,
    );

}
count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    my ( $res_nif, $force_attr ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                issuerDBSAMLRule       => '$uid eq "french"',
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 0,
                        (
                            $res_nif
                            ? ( samlSPMetaDataOptionsNameIDFormat => $res_nif, )
                            : ()
                        ),
                        (
                            $force_attr
                            ? ( samlSPMetaDataOptionsNameIDSessionKey =>
                                  $force_attr, )
                            : ()
                        ),
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
    my ($req_nif) = @_;
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
                        samlIDPMetaDataOptionsSignSSOMessage           => 0,
                        (
                            $req_nif
                            ? ( samlIDPMetaDataOptionsNameIDFormat => $req_nif,
                              )
                            : ()
                        ),
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
