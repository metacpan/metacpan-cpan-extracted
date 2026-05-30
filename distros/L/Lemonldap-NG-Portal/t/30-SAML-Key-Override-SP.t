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
my ( $issuer, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register( denyLwpRequests() );

sub runTest {
    my ( $sp, $expected_cert, $expected_alg ) = @_;

    my $id = $issuer->login("french");

    # Initialization
    my $request = getAuthnRequest($sp);

    # Push SAML request to IdP
    ok(
        $res = $issuer->_post(
            '/saml/singleSignOn',
            { SAMLRequest => $request },
            accept => 'text/html',
            cookie => "lemonldap=$id",
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);

    my ( $host, $url, $s ) =
      expectAutoPost( $res, "auth.$sp.com", '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    my $sr       = expectSamlResponse($s);
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

    $issuer = register( 'issuer', sub { issuer() } );

    # Default metadata contains default keys
    my $md = $issuer->_get("/saml/metadata/idp");
    expectMetadataCerts(
        $md->[2]->[0],
        [ saml_key_idp_cert_sig() ],
        [ saml_key_idp_cert_sig() ]
    );

    # SP-targeted metadata contains sp-specific key
    $md = $issuer->_get(
        "/saml/metadata/idp",
        query => {
            sp => "http://auth.override-both.com/saml/metadata",
        }
    );
    expectMetadataCerts(
        $md->[2]->[0],
        [ saml_key_proxy_cert_sig() ],
        [ saml_key_proxy_cert_sig() ]
    );

    # Extra keys can be specified
    $md = $issuer->_get(
        "/saml/metadata/idp",
        query => {
            sp => "http://auth.override-key.com/saml/metadata",
        }
    );
    expectMetadataCerts(
        $md->[2]->[0],
        [ saml_key_proxy_cert_sig(), saml_key_sp_cert_sig() ],
        [ saml_key_proxy_cert_sig(), saml_key_sp_cert_sig() ]
    );

    # Run signature tests
    runTest( "default-sp",      saml_key_idp_cert_sig(),   "rsa-sha256" );
    runTest( "override-method", saml_key_idp_cert_sig(),   "rsa-sha384" );
    runTest( "override-key",    saml_key_proxy_cert_sig(), "rsa-sha256" );
    runTest( "override-both",   saml_key_proxy_cert_sig(), "rsa-sha384" );

}
clean_sessions();
done_testing();

sub getAuthnRequest {
    my ($sp) = @_;
    my $server =
      Lasso::Server::new_from_buffers( samlSPMetaDataXML( $sp, "HTTP-POST" ),
        saml_key_sp_private_sig(), undef, undef );
    $server->add_provider_from_buffer(
        Lasso::Constants::PROVIDER_ROLE_IDP,
        samlIDPMetaDataXML( "example", "HTTP-POST" )
    );

    my $login = Lasso::Login->new($server);
    $login->init_authn_request(
        "http://auth.example.com/saml/metadata",
        Lasso::Constants::HTTP_METHOD_POST
    );
    $login->set_signature_hint(Lasso::Constants::PROFILE_SIGNATURE_HINT_FORBID);

    $login->request->NameIDPolicy(undef);
    $login->build_authn_request_msg();
    note "Generated SAML Request: " . $login->request->dump;
    return $login->msg_body;
}

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                issuerDBSAMLActivation              => 1,
                samlServiceUseCertificateInResponse => 1,
                samlSPMetaDataOptions               => {
                    'default-sp' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 0,
                    },
                    'override-method' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 0,
                        samlSPMetaDataOptionsSignatureMethod => "RSA_SHA384",
                    },
                    'override-key' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 0,
                        samlSPMetaDataOptionsSignatureKey             =>
                          "alt-key,extra-key",
                    },
                    'override-both' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 0,
                        samlSPMetaDataOptionsSignatureMethod => "RSA_SHA384",
                        samlSPMetaDataOptionsSignatureKey    => "alt-key",
                    },
                },
                samlSPMetaDataXML => {
                    "default-sp" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'default-sp', 'HTTP-POST' )
                    },
                    "override-method" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'override-method', 'HTTP-POST' )
                    },
                    "override-key" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'override-key', 'HTTP-POST' )
                    },
                    "override-both" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'override-both', 'HTTP-POST' )
                    },
                },
                keys => {
                    "default-saml-sig" => {
                        keyPrivate => saml_key_idp_private_sig(),
                        keyPublic  => saml_key_idp_cert_sig(),
                    },
                    "alt-key" => {
                        keyPrivate => saml_key_proxy_private_sig(),
                        keyPublic  => saml_key_proxy_cert_sig(),
                    },
                    "extra-key" => {
                        keyPrivate => saml_key_sp_private_sig(),
                        keyPublic  => saml_key_sp_cert_sig(),
                    },
                },
            }
        }
    );
}

1;
