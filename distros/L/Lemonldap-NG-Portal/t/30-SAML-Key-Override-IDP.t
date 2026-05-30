use warnings;
use Test::More;
use strict;
no strict "subs";
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $debug = 'error';
my ( $client, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register( denyLwpRequests() );

sub runTest {
    my ( $sp, $expected_cert, $expected_alg ) = @_;

    ok(
        $res = $client->_get(
            '/',
            query  => { idpName => $sp },
            accept => 'text/html',
        ),
        'Initiate authentication'
    );
    expectOK($res);

    my ( $host, $url, $s ) =
      expectAutoPost( $res, "auth.$sp.com", '/saml/singleSignOn',
        'SAMLRequest' );

    my $sr       = expectSamlRequest($s);
    my $sig_cert = getXPath( $sr, '//sig:X509Certificate/text()' )->pop->data;
    is(
        normalizeX509Data($sig_cert),
        normalizeX509Data($expected_cert),
        "Expected key was used"
    );

    expectXPath(
        $sr,
        '//sig:SignatureMethod/@Algorithm',
        "http://www.w3.org/2001/04/xmldsig-more#$expected_alg",
        "Expected alg $expected_alg was used"
    );
}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip('Lasso not found');
    }

    $client = register( 'sp', sub { sp() } );

    # Default metadata contains default keys
    my $md = $client->_get("/saml/metadata/sp");
    expectMetadataCerts(
        $md->[2]->[0],
        [ saml_key_sp_cert_sig() ],
        [ saml_key_sp_cert_sig() ]
    );

    # SP-targeted metadata contains sp-specific key
    $md = $client->_get(
        "/saml/metadata/sp",
        query => {
            idp => "http://auth.override-both.com/saml/metadata",
        }
    );
    expectMetadataCerts(
        $md->[2]->[0],
        [ saml_key_proxy_cert_sig() ],
        [ saml_key_proxy_cert_sig() ]
    );

    # Extra keys can be specified
    $md = $client->_get(
        "/saml/metadata/sp",
        query => {
            idp => "http://auth.override-key.com/saml/metadata",
        }
    );
    expectMetadataCerts(
        $md->[2]->[0],
        [ saml_key_proxy_cert_sig(), saml_key_idp_cert_sig() ],
        [ saml_key_proxy_cert_sig(), saml_key_idp_cert_sig() ]
    );

    # Run signature tests
    runTest( "default-idp",     saml_key_sp_cert_sig(),    "rsa-sha256" );
    runTest( "override-method", saml_key_sp_cert_sig(),    "rsa-sha384" );
    runTest( "override-key",    saml_key_proxy_cert_sig(), "rsa-sha256" );
    runTest( "override-both",   saml_key_proxy_cert_sig(), "rsa-sha384" );

}
clean_sessions();
done_testing();

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                authentication                      => 'SAML',
                samlServiceUseCertificateInResponse => 1,
                samlIDPMetaDataOptions              => {
                    'default-idp' => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                    },
                    'override-method' => {
                        samlIDPMetaDataOptionsEncryptionMode  => 'none',
                        samlIDPMetaDataOptionsSSOBinding      => 'post',
                        samlIDPMetaDataOptionsSLOBinding      => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage  => 1,
                        samlIDPMetaDataOptionsSignSLOMessage  => 1,
                        samlIDPMetaDataOptionsSignatureMethod => "RSA_SHA384",
                    },
                    'override-key' => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsSignatureKey   =>
                          "alt-key,extra-key",
                    },
                    'override-both' => {
                        samlIDPMetaDataOptionsEncryptionMode  => 'none',
                        samlIDPMetaDataOptionsSSOBinding      => 'post',
                        samlIDPMetaDataOptionsSLOBinding      => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage  => 1,
                        samlIDPMetaDataOptionsSignSLOMessage  => 1,
                        samlIDPMetaDataOptionsSignatureMethod => "RSA_SHA384",
                        samlIDPMetaDataOptionsSignatureKey    => "alt-key",
                    },
                },
                samlIDPMetaDataXML => {
                    'default-idp' => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'default-idp', 'HTTP-POST' )
                    },
                    'override-method' => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'override-method', 'HTTP-POST' )
                    },
                    'override-key' => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'override-key', 'HTTP-POST' )
                    },
                    'override-both' => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'override-both', 'HTTP-POST' )
                    },
                },
                keys => {
                    "default-saml-sig" => {
                        keyPrivate => saml_key_sp_private_sig(),
                        keyPublic  => saml_key_sp_cert_sig(),
                    },
                    "alt-key" => {
                        keyPrivate => saml_key_proxy_private_sig(),
                        keyPublic  => saml_key_proxy_cert_sig(),
                    },
                    "extra-key" => {
                        keyPrivate => saml_key_idp_private_sig(),
                        keyPublic  => saml_key_idp_cert_sig(),
                    },
                },
            }
        }
    );
}

1;
