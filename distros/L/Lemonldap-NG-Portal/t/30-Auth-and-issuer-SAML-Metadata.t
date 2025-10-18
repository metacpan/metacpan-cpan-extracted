use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 11;
my $debug     = 'error';
my ( $issuer, $res );

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );

    ok( $res = $issuer->_get('/saml/metadata'),         'Get metadata' );
    ok( $res->[2]->[0] =~ m#^<\?xml version="1.0"\?>#s, 'Metadata is XML' );

    expectMetadataCerts(
        $res->[2]->[0],
        [ saml_key_idp_cert_sig(), saml_key_proxy_cert_sig() ],
        [ saml_key_idp_cert_enc(), saml_key_proxy_cert_sig() ]
    );

    ok( $res = $issuer->_get('/saml/metadata/idp'),     'Get IDP metadata' );
    ok( $res->[2]->[0] =~ m#^<\?xml version="1.0"\?>#s, 'Metadata is XML' );
    ok(
        $res->[2]->[0] !~ m#<SPSSODescriptor#s,
        'Metadata does not contain SP information'
    );
    ok( $res->[2]->[0] =~ m#entityID="urn:example\.com"#s,
        'IDP EntityID is overridden' );

    ok( $res = $issuer->_get('/saml/metadata/sp'),      'Get SP metadata' );
    ok( $res->[2]->[0] =~ m#^<\?xml version="1.0"\?>#s, 'Metadata is XML' );
    ok(
        $res->[2]->[0] !~ m#<IDPSSODescriptor#s,
        'Metadata does not contain IDP information'
    );
}

count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                    => $debug,
                domain                      => 'idp.com',
                portal                      => 'http://auth.idp.com/',
                authentication              => 'Demo',
                userDB                      => 'Same',
                issuerDBSAMLActivation      => 1,
                samlOverrideIDPEntityID     => 'urn:example.com',
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.idp.com/",
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_cert_enc,
                samlServicePublicKeySig     => saml_key_idp_cert_sig,
                samlServiceSignatureKey     => "default-saml-sig,extra-sig",
                samlServiceEncryptionKey    => "default-saml-enc,extra-sig",
                keys                        => {
                    "extra-sig" => {
                        keyPrivate => saml_key_proxy_private_sig,
                        keyPublic  => saml_key_proxy_cert_sig,
                    }
                },
            }
        }
    );
}
