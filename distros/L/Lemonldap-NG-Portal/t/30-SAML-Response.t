use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use URI;
use URI::QueryParam;
use Time::Fake;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my ( $issuer, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register( denyLwpRequests() );
our $saml;

SKIP: {
    eval "use Lasso; use Lemonldap::NG::Portal::Lib::SAML;";
    if ($@) {
        skip 'Lasso not found';
    }

    # Initialization
    my $issuer = register( 'issuer', \&issuer );

    $saml = $issuer->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::SAML'};

    runTest($issuer);

    sub runTest {
        my ($issuer) = @_;

        my $auth_date = time;

        # Login at issuer
        ok(
            $res = $issuer->_post(
                '/',
                IO::String->new('user=dwho&password=dwho'),
                accept => 'text/html',
                length => 23
            ),
            'Auth query'
        );
        my $id = expectCookie($res);

        subtest "Check SessionNotOnOrAfter" => sub {
            Time::Fake->offset("+1h");
            my $saml_request_date       = time;
            my $SAMLResponse            = getSAMLResponse( $issuer, $id );
            my $session_not_on_or_after = $saml->samldate2timestamp(
                $SAMLResponse->Assertion->AuthnStatement->SessionNotOnOrAfter );
            my $auth_instant = $saml->samldate2timestamp(
                $SAMLResponse->Assertion->AuthnStatement->AuthnInstant );

            delta_ok( $auth_instant, $auth_date, 10,
                "AuthnInstant is authentication date" );
            delta_ok( $saml_request_date + 3600, $session_not_on_or_after, 10,
                    "SessionNotOnOrAfter timeout starts running "
                  . "after SAMLResponse generation" );

            Time::Fake->offset("+1h");
        };

        subtest "Check SessionNotOnOrAfter shortly before expiration" => sub {

            # 3h30, so 30m before expiration
            Time::Fake->offset("+12600s");
            my $saml_request_date       = time;
            my $SAMLResponse            = getSAMLResponse( $issuer, $id );
            my $session_not_on_or_after = $saml->samldate2timestamp(
                $SAMLResponse->Assertion->AuthnStatement->SessionNotOnOrAfter );
            my $auth_instant = $saml->samldate2timestamp(
                $SAMLResponse->Assertion->AuthnStatement->AuthnInstant );

            delta_ok( $auth_instant, $auth_date, 10,
                "AuthnInstant is authentication date" );
            delta_ok( $auth_date + ( 3600 * 4 ), $session_not_on_or_after, 10,
                    "When close to expiration date, SessionNotOnOrAfter is"
                  . "expiration date" );

            Time::Fake->offset("+1h");
        };
    }

    sub getSAMLResponse {
        my ( $issuer, $id ) = @_;
        my $login = eval { getAuthnRequest("HTTP-POST"); };

        my $url  = URI->new( $login->msg_url );
        my $url2 = URI->new;
        $url2->query_form( {
                SAMLRequest => $login->msg_body,
            }
        );

        ok(
            $res = $issuer->_post(
                $url->path,
                $url2->query,
                cookie => "lemonldap=$id",
                accept => 'text/html',
            ),
            ' Follow redirection'
        );
        my @responses =
          getHtmlElement( $res, '//input[@name="SAMLResponse"]/@value' );
        is( scalar(@responses), 1, "Found one SAMLResponse" );
        my $SAMLResponse =
          Lasso::Node::new_from_dump( decode_base64( $responses[0]->value ) );
        ok( $SAMLResponse, "SAMLResponse successfully decoded" );
        return $SAMLResponse;
    }

    sub getAuthnRequest {
        my ($method) = @_;

        my $server = Lasso::Server::new_from_buffers(
            samlProxyMetaDataXML( "proxy", $method ),
            saml_key_proxy_private_sig(),
            undef, undef
        );
        $server->add_provider_from_buffer( 2,
            samlIDPMetaDataXML( "idp", $method ) );

        my $login = Lasso::Login->new($server);
        $method = $saml->getHttpMethod($method);
        $login->init_authn_request( "http://auth.idp.com/saml/metadata",
            $method );
        $login->build_authn_request_msg();
        return $login;
    }

    sub delta_ok {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my ( $value1, $value2, $tolerance, $message ) = @_;
        $message ||= "$value1 and $value2 differ by no more than $tolerance";

        cmp_ok( abs( $value2 - $value1 ), "<", $tolerance, $message );
    }
}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com/',
                authentication         => 'Demo',
                userDB                 => 'Same',
                globalLogoutRule       => 1,
                globalLogoutTimer      => 0,
                issuerDBSAMLActivation => 1,
                timeout                => ( 3600 * 4 ),
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsSessionNotOnOrAfterTimeout => 3600,
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
                          samlProxyMetaDataXML( 'proxy', 'HTTP-POST' )
                    },
                },
            }
        }
    );
}
