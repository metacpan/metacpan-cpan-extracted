use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 2;
my $debug     = 'error';

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    my $client = portal();

    my $id = login( $client, "dwho", "dwho" );
    my $res;
    ok(
        $res = $client->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$id"
        ),
        'Get Menu',
    );

    my %applications =
      map { ( split( " ", $_->getAttribute("class") ) )[1] => 1 }
      getHtmlElement( $res, '//div[contains(@class,"application")]' );
    is_deeply(
        \%applications,
        {
            cas_ok  => 1,
            saml_ok => 1,
            oidc_ok => 1,
        }
    );
}

count($maintests);
clean_sessions();
done_testing( count() );

sub portal {
    return LLNG::Manager::Test->new( {
            ini => {
                "applicationList" => {
                    "0001-cat" => {
                        "catname" => "Sample applications",
                        "type"    => "category",
                        map {
                            $_ => {
                                "options" => {
                                    "logo"    => "$_.png",
                                    "uri"     => "http://$_",
                                    "display" => "sp:$_",
                                },
                                "type" => "application"
                            }
                        } qw/ saml_ok saml_ko cas_ok cas_ko oidc_ok oidc_ko /,
                    }
                },
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.example.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => "1",
                issuerDBCASActivation           => "1",
                issuerDBSAMLActivation          => "1",
                oidcRPMetaDataOptions           => {
                    'oidc_ok' => {
                        oidcRPMetaDataOptionsRule     => '$uid eq "dwho"',
                        oidcRPMetaDataOptionsClientID => "oidc-ok",
                    },
                    'oidc_ko' => {
                        oidcRPMetaDataOptionsRule     => '$uid eq "rtyler"',
                        oidcRPMetaDataOptionsClientID => "oidc-ko",
                    }
                },
                casAppMetaDataOptions => {
                    'cas_ok' => {
                        casAppMetaDataOptionsRule    => '$uid eq "dwho"',
                        casAppMetaDataOptionsService => 'http://cas_ok/',
                    },
                    'cas_ko' => {
                        casAppMetaDataOptionsRule    => '$uid eq "rtyler"',
                        casAppMetaDataOptionsService => 'http://cas_ko/',
                    }
                },
                samlSPMetaDataOptions => {
                    'saml_ok' => {
                        samlSPMetaDataOptionsRule => '$uid eq "dwho"',
                    },
                    'saml_ko' => {
                        samlSPMetaDataOptionsRule => '$uid eq "rtyler"',
                    }
                },
                samlSPMetaDataXML => {
                    'saml_ok' => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'ok', 'HTTP-POST' ),
                    },
                    'saml_ko' => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'ko', 'HTTP-POST' ),
                    },
                },
                oidcServicePrivateKeySig => oidc_key_op_private_sig,
                oidcServicePublicKeySig  => oidc_cert_op_public_sig,
                samlServicePrivateKeyEnc => saml_key_idp_private_enc,
                samlServicePrivateKeySig => saml_key_idp_private_sig,
                samlServicePublicKeyEnc  => saml_key_idp_public_enc,
                samlServicePublicKeySig  => saml_key_idp_public_sig,
            }
        }
    );
}

