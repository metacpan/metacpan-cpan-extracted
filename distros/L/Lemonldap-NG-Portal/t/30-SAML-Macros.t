use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use XML::LibXML;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $debug = 'error';
my ( $issuer, $res );
my $maintests = 8;

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    ok( $issuer = issuer(), 'Issuer portal' );

    ok(
        $res = $issuer->_post(
            '/', IO::String->new('user=french&password=french'),
            length => 27
        ),
        'Auth query'
    );
    expectOK($res);
    my $idpId = expectCookie($res);

    # Query IdP to access to SP
    ok(
        $res = $issuer->_get(
            '/saml/singleSignOn',
            query  => 'IDPInitiated=1&spConfKey=sp.com',
            cookie => "lemonldap=$idpId",
            accept => 'test/html'
        ),
        'Query IdP to access to SP'
    );
    expectOK($res);
    ok(
        $res->[2]->[0] =~
          m#<form.+?action="http://auth.sp.com(.*?)".+?method="post"#,
        'Form method is POST'
    );
    my $url = $1;
    ok(
        $res->[2]->[0] =~
          /<input type="hidden".+?name="SAMLResponse".+?value="(.+?)"/s,
        'Found SAML response'
    );
    my $s   = decode_base64($1);
    my $dom = XML::LibXML->load_xml( string => $s );
    my $xpc = XML::LibXML::XPathContext->new($dom);
    $xpc->registerNs( 'saml', 'urn:oasis:names:tc:SAML:2.0:assertion' );

    foreach my $value (
        $xpc->findnodes('//saml:Attribute[@Name="sn"]/saml:AttributeValue') )
    {
        is( $value->textContent, 'Accents', 'Check Attribute' );
    }
    foreach my $value (
        $xpc->findnodes('//saml:Attribute[@Name="planet"]/saml:AttributeValue')
      )
    {
        is( $value->textContent, 'Earth', 'Check Attribute' );
    }
    foreach my $value ( $xpc->findnodes('//saml:NameID') ) {
        is( $value->textContent, 'customfrench', 'Check NameID from macro' );
    }
    clean_sessions();
}

count($maintests);
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
                samlSPMetaDataMacros   => {
                    'sp.com' => {
                        extracted_sn => '(split(/\s/, $cn))[1]',
                        customnameid => '"custom".$uid',
                        planet => 'inGroup("earthlings") ? "Earth" : "UNKNOWN"',
                    }
                },
                samlSPMetaDataOptions => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsEnableIDPInitiatedURL    => 1,
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsNameIDSessionKey => 'customnameid',
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'sp.com' => {
                        cn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        extracted_sn =>
'1;sn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        uid =>
'1;uid;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        planet =>
'1;planet;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
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
                          samlSPMetaDataXML( 'sp', 'HTTP-Redirect' )
                    },
                },
            }
        }
    );
}
