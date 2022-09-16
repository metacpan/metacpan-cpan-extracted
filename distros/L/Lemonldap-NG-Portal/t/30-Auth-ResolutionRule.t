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
my $maintests = 0;

sub testchoiceredirection {
    my ( $issuer, $choice, $url ) = @_;
    my $res;
    ok(
        $res = $issuer->_get(
            '/',
            query  => 'lmAuth=' . $choice,
            accept => 'text/html',
        ),
        'Auth query'
    );
    count(1);
    expectRedirection( $res, $url );
}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    ok( $issuer = issuer(), 'Issuer portal' );
    count(1);

    testchoiceredirection( $issuer, 'SAML1',
        qr,http://auth.idp.com/saml/singleSignOn, );
    testchoiceredirection( $issuer, 'SAML2',
        qr,http://auth.idp2.com/saml/singleSignOn, );
    testchoiceredirection( $issuer, 'OIDC1',
        qr,http://auth.op.com/oauth2/authorize, );
    testchoiceredirection( $issuer, 'OIDC2',
        qr,http://auth.op2.com/oauth2/authorize, );
    testchoiceredirection( $issuer, 'CAS1', qr,http://auth.srv.com/cas/login, );
    testchoiceredirection( $issuer, 'CAS2',
        qr,http://auth.srv2.com/cas/login, );

    clean_sessions();
}

count($maintests);
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'example.com',
                portal            => 'http://auth.example.com',
                authentication    => 'Choice',
                userDB            => 'Same',
                authChoiceModules => {
                    'OIDC1' => 'OpenIDConnect;Null;Null',
                    'OIDC2' => 'OpenIDConnect;Null;Null',
                    'SAML1' => 'SAML;Null;Null',
                    'SAML2' => 'SAML;Null;Null',
                    'CAS1'  => 'CAS;Null;Null',
                    'CAS2'  => 'CAS;Null;Null',
                },

                samlIDPMetaDataOptions => {
                    "idp.com" => {
                        samlIDPMetaDataOptionsResolutionRule =>
                          '$_choice eq "SAML1"',
                    },
                    "idp2.com" => {
                        samlIDPMetaDataOptionsResolutionRule =>
                          '$_choice eq "SAML2"',
                    },
                },
                samlIDPMetaDataXML => {
                    "idp.com" => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
                    },
                    "idp2.com" => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp2', 'HTTP-Redirect' )
                    },
                },
                samlServicePrivateKeyEnc => saml_key_idp_private_enc,
                samlServicePrivateKeySig => saml_key_idp_private_sig,
                samlServicePublicKeyEnc  => saml_key_idp_public_enc,
                samlServicePublicKeySig  => saml_key_idp_public_sig,

                casSrvMetaDataOptions => {
                    idp => {
                        casSrvMetaDataOptionsUrl => 'http://auth.srv.com/cas',
                        casSrvMetaDataOptionsResolutionRule =>
                          '$_choice eq "CAS1"',
                    },
                    idp2 => {
                        casSrvMetaDataOptionsUrl => 'http://auth.srv2.com/cas',
                        casSrvMetaDataOptionsResolutionRule =>
                          '$_choice eq "CAS2"',
                    },
                },

                oidcOPMetaDataOptions => {
                    op => {
                        oidcOPMetaDataOptionsClientSecret   => "rpsecret",
                        oidcOPMetaDataOptionsResolutionRule =>
                          '$_choice eq "OIDC1"',
                    },
                    op2 => {
                        oidcOPMetaDataOptionsResolutionRule =>
                          '$_choice eq "OIDC2"',
                    },
                },
                oidcOPMetaDataJSON => {
                    op =>
'{"authorization_endpoint":"http://auth.op.com/oauth2/authorize"}',
                    op2 =>
'{"authorization_endpoint":"http://auth.op2.com/oauth2/authorize"}',
                }

            }
        }
    );
}
