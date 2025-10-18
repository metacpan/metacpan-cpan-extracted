use Test::More;
use XML::LibXML;

BEGIN {
    use_ok('Lemonldap::NG::Common::Conf::SAML::Metadata');
}
use strict;
require 't/saml-lib.pm';

my $metadata = new_ok(
    'Lemonldap::NG::Common::Conf::SAML::Metadata' => [],
    "Metadata object"
);

my $conf = {
    'portal' => 'http://myportal/',
    'samlAttributeAuthorityDescriptorAttributeServiceSOAP' =>
      'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;#PORTAL#/saml/AA/SOAP;',
    'samlEntityID' => '#PORTAL#/saml/metadata',
    'samlIDPSSODescriptorArtifactResolutionServiceArtifact' =>
      '1;0;urn:oasis:names:tc:SAML:2.0:bindings:SOAP;#PORTAL#/saml/artifact',
    'samlIDPSSODescriptorSingleLogoutServiceHTTPPost' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;#PORTAL#/saml/singleLogout;#PORTAL#/saml/singleLogoutReturn',
    'samlIDPSSODescriptorSingleLogoutServiceHTTPRedirect' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect;#PORTAL#/saml/singleLogout;#PORTAL#/saml/singleLogoutReturn',
    'samlIDPSSODescriptorSingleLogoutServiceSOAP' =>
'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;#PORTAL#/saml/singleLogoutSOAP;',
    'samlIDPSSODescriptorSingleSignOnServiceHTTPArtifact' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact;#PORTAL#/saml/singleSignOnArtifact;',
    'samlIDPSSODescriptorSingleSignOnServiceHTTPPost' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;#PORTAL#/saml/singleSignOn;',
    'samlIDPSSODescriptorSingleSignOnServiceHTTPRedirect' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect;#PORTAL#/saml/singleSignOn;',
    'samlIDPSSODescriptorWantAuthnRequestsSigned' => 1,
    'samlMetadataForceUTF8'                       => 1,
    'samlOrganizationDisplayName'                 => 'SP',
    'samlOrganizationName'                        => 'SP',
    'samlOrganizationURL'                         => 'http://www.sp.com',
    'samlOverrideIDPEntityID'                     => '',
    'samlSPSSODescriptorArtifactResolutionServiceArtifact' =>
      '1;0;urn:oasis:names:tc:SAML:2.0:bindings:SOAP;#PORTAL#/saml/artifact',
    'samlSPSSODescriptorAssertionConsumerServiceHTTPArtifact' =>
'0;1;urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact;#PORTAL#/saml/proxySingleSignOnArtifact',
    'samlSPSSODescriptorAssertionConsumerServiceHTTPPost' =>
'1;0;urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;#PORTAL#/saml/proxySingleSignOnPost',
    'samlSPSSODescriptorAuthnRequestsSigned'         => 1,
    'samlSPSSODescriptorSingleLogoutServiceHTTPPost' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST;#PORTAL#/saml/proxySingleLogout;#PORTAL#/saml/proxySingleLogoutReturn',
    'samlSPSSODescriptorSingleLogoutServiceHTTPRedirect' =>
'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect;#PORTAL#/saml/proxySingleLogout;#PORTAL#/saml/proxySingleLogoutReturn',
    'samlSPSSODescriptorSingleLogoutServiceSOAP' =>
'urn:oasis:names:tc:SAML:2.0:bindings:SOAP;#PORTAL#/saml/proxySingleLogoutSOAP;',
    'samlSPSSODescriptorWantAssertionsSigned' => 1,
    'samlServicePublicKeyEnc'                 => saml_key_idp_public_enc(),
    'samlServicePublicKeySig'                 => saml_key_idp_public_sig(),
};

subtest 'Check basic MD information' => sub {
    my $doc = getMetadataDocument( $conf, "idp" );

    expectValidSchema($doc);

    expectXPath(
        $doc,
        '//md:SingleSignOnService/@Location',
        "http://myportal/saml/singleSignOn",
        "Check SingleSignOnService URL"
    );
};

subtest 'Default metadata with two different keys' => sub {

    my $doc = getMetadataDocument( $conf, "idp" );

    my @encryption_keys = getXPath(
        $doc,
        '//md:IDPSSODescriptor/md:KeyDescriptor[@use="encryption"]/sig:KeyInfo',
    );
    is( scalar(@encryption_keys), 1, "Found one encryption key" );

    my @signing_keys =
      getXPath( $doc,
        '//md:IDPSSODescriptor/md:KeyDescriptor[@use="signing"]/sig:KeyInfo',
      );
    is( scalar(@encryption_keys), 1, "Found one signing key" );

    isnt(
        $signing_keys[0]->toString,
        $encryption_keys[0]->toString,
        "Signing and encryption keys are different"
    );
};

subtest 'Default metadata with only one key' => sub {
    my $doc = getMetadataDocument( {
            %$conf, samlServicePublicKeyEnc => undef
        },
        "idp"
    );

    my @encryption_keys = getXPath(
        $doc,
        '//md:IDPSSODescriptor/md:KeyDescriptor[@use="encryption"]/sig:KeyInfo',
    );
    is( scalar(@encryption_keys), 1, "Found one encryption key" );

    my @signing_keys =
      getXPath( $doc,
        '//md:IDPSSODescriptor/md:KeyDescriptor[@use="signing"]/sig:KeyInfo',
      );
    is( scalar(@signing_keys), 1, "Found one signing key" );

    is(
        $signing_keys[0]->toString,
        $encryption_keys[0]->toString,
        "Signing key was used as encryption key too"
    );
};

subtest 'Use certificate' => sub {
    my $doc = getMetadataDocument( {
            %$conf,
            samlServicePublicKeyEnc => undef,
            samlServicePublicKeySig => saml_key_idp_cert_sig(),
        },
        "idp"
    );

    expectMetadataCerts(
        $doc,
        [ saml_key_idp_cert_sig() ],
        [ saml_key_idp_cert_sig() ]
    );
};

subtest 'Override signing or encryption keys' => sub {
    my $doc = getMetadataDocument( {
            %$conf,
            samlServicePublicKeyEnc => undef,
            samlServicePublicKeySig => saml_key_idp_cert_sig(),
        },
        "idp",

        # As LLNG structs with a "public => " field
        signing_keys => [
            { public => saml_key_proxy_cert_sig() },
            { public => saml_key_sp_cert_sig() }
        ],

        # As a plain string
        encryption_keys => [ saml_key_sp_cert_sig() ],
    );

    expectMetadataCerts(
        $doc,
        [ saml_key_proxy_cert_sig(), saml_key_sp_cert_sig() ],
        [ saml_key_sp_cert_sig() ]
    );
};

done_testing();

sub getMetadataDocument {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $xml = $metadata->serviceToXML(@_);
    my $dom = XML::LibXML->load_xml( string => $xml );
    ok( $dom, 'XML successfully parsed' );
    return $dom;
}

sub expectValidSchema {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($doc) = @_;

    my $xmlschema = XML::LibXML::Schema->new(
        location   => "t/saml-schemas/saml-schema-metadata-2.0.xsd",
        no_network => 1
    );
    my $result = eval { $xmlschema->validate($doc); };
    is( $result, 0, "Metadata validates SAML 2.0 schema" ) or diag $@;

}

sub expectMetadataCerts {
    my ( $doc, $expected_signing_keys, $expected_encryption_keys ) = @_;

    my @signing_keys = map { $_->data } getXPath(
        $doc,
'//md:IDPSSODescriptor/md:KeyDescriptor[@use="signing"]/sig:KeyInfo/sig:X509Data/sig:X509Certificate/text()',
    );

    is_deeply(
        [ map { normalizeX509Data($_) } @signing_keys ],
        [ map { normalizeX509Data($_) } @$expected_signing_keys ],
        "Offered signing certs match excepted ones"
    );

    my @encryption_keys = map { $_->data } getXPath(
        $doc,
'//md:IDPSSODescriptor/md:KeyDescriptor[@use="encryption"]/sig:KeyInfo/sig:X509Data/sig:X509Certificate/text()',
    );

    is_deeply(
        [ map { normalizeX509Data($_) } @encryption_keys ],
        [ map { normalizeX509Data($_) } @$expected_encryption_keys ],
        "Offered encryption certs match excepted ones"
    );
}

sub normalizeX509Data {
    my ($data) = @_;

    # Remove heading lines
    $data =~ s/^---.*---$//mg;

    # Remove heading/trailing ws
    $data =~ s/(?:^\s+|\s+$)//g;

    return $data;
}
