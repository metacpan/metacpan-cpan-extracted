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

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    expectOK($res);
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
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

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
    expectRedirection( $res, 'http://auth.sp.com' );
    my $spId = expectCookie($res);

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

    # Verify UTF-8
    ok( $res = $sp->_get("/sessions/global/$spId"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
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

    # The SP doesn't have an SLO endpoint for its response (Hi Renater!) , in
    # this case, the portal should display a nice user message instead of
    # erroring.
    expectOK($res);

    ok( $res->[2]->[0] =~ /trmsg="47"/, 'Found logout message' );

    my $logoutCookie = expectCookie($res);
    is( $logoutCookie, 0, "IDP cookie removed" );

    # Test if logout is done
    ok(
        $res = $issuer->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if old cookie is denied by IdP'
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
                        samlSPMetaDataXML => <<EOF
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
entityID="http://auth.sp.com/saml/metadata">
  <SPSSODescriptor AuthnRequestsSigned="true"
  WantAssertionsSigned="true"
  protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">

    <KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            u4iToYAEmWQxgZDihGVzMMql1elPn37domWcvXeU2E4yt2hh5jkQHiFjgodfOlNeRIw5QJVlUBwr
            +CQvbaKRFXd7BrOhQIDC0TZPRVB0XHarUtsCuDekN4/2GKSzHsoToKUVPWq9thsuek3xkpsJGZNX
            7bglfEc9+QQpYTqN1rkdN1PVU0epNMokFFGho5pLRqLUV5+I/QXAL49jfTjaSxsp4UndTI8/+mGS
            RSq+nrT2zyQRM/vkj5vR9ZVz67HO/+Wk3Mx6RAwkVcMdgMAqCq8odmbI0yCRZiTL9ybKWRKqWJoK
            J0p5+Q2fPEBPupQZR09Jt/JPuLVSsGfCxi9Nqw==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <KeyDescriptor use="encryption">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:KeyValue>
          <RSAKeyValue xmlns="http://www.w3.org/2000/09/xmldsig#">
            <Modulus>
            sRaod2RZ8hMFBl+VhsnhyPM8l/Fj1obnBxfQIaWuHFIFfXiGe/CYHuZ5QJQLnZxHMJX6LL3Sh+Us
            og3p0jpijpcg0QgfBSEkfopKTgReYN8DiDIll0rV1XdTni7E85Nd1YyNy3ui/ZD+UShWwqu6jLVL
            R+QUm+/1LIKYb3OCBTvOlY7xHoP6NSU1+Mr+YzGBUacdO2vnNxe/PQhxIeP1zO0njuqGHkwEpy8r
            UWRZbbDn31TmKjqlhgtsz5HPhbRaYEExhyepKgBiNz+RyxtYXVhuG8OrWQDoS5gYHSjdw1CTJyix
            eJwyoqA9RGYguG5nh9zndi3LWAh7Z0lx+tIz+w==</Modulus>
            <Exponent>AQAB</Exponent>
          </RSAKeyValue>
        </ds:KeyValue>
      </ds:KeyInfo>
    </KeyDescriptor>
    <ArtifactResolutionService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:SOAP"
     Location="http://auth.sp.com/saml/artifact" />
    <NameIDFormat>
    urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <NameIDFormat>
    urn:oasis:names:tc:SAML:1.1:nameid-format:X509SubjectName</NameIDFormat>
    <NameIDFormat>
    urn:oasis:names:tc:SAML:1.1:nameid-format:WindowsDomainQualifiedName</NameIDFormat>
    <NameIDFormat>
    urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos</NameIDFormat>
    <NameIDFormat>
    urn:oasis:names:tc:SAML:2.0:nameid-format:entity</NameIDFormat>
    <NameIDFormat>
    urn:oasis:names:tc:SAML:2.0:nameid-format:transient</NameIDFormat>
    <AssertionConsumerService isDefault="true" index="0"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
     Location="http://auth.sp.com/saml/proxySingleSignOnPost" />
    <AssertionConsumerService isDefault="false" index="1"
     Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact"
     Location="http://auth.sp.com/saml/proxySingleSignOnArtifact" />
  </SPSSODescriptor>
  <Organization>
    <OrganizationName xml:lang="en">org</OrganizationName>
    <OrganizationDisplayName xml:lang="en">
    org</OrganizationDisplayName>
    <OrganizationURL xml:lang="en">
    http://www.org.com</OrganizationURL>
  </Organization>
</EntityDescriptor>
EOF
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
