use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use URI;
use URI::QueryParam;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 4;
my $debug     = 'error';
my ( $issuer, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        fail('POST should not launch SOAP requests');
        count(1);
        return [ 500, [], [] ];
    }
);
our $saml;

SKIP: {
    eval "use Lasso; use Lemonldap::NG::Portal::Lib::SAML;";
    if ($@) {
        skip 'Lasso not found';
    }
    $saml = Lemonldap::NG::Portal::Lib::SAML->new();

    # Initialization
    my $issuer = register( 'issuer', \&issuer );

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

    my $login = eval { getAuthnRequest("HTTP-Redirect"); };

    my $url = URI->new( $login->msg_url );
    ok(
        $res = $issuer->_get(
            $url->path,
            query  => $url->query,
            cookie => "lemonldap=$id",
            accept => 'text/html',
        ),
        ' Follow redirection'
    );
    my ($relayState) =
      $res->[2]->[0] =~ m#<input.+?name="RelayState"[^>]+(?:value="([^"]*?)")#s;

    is(
        $relayState,
        '{&quot;url&quot;: &quot;http://test/%22&quot;}',
        "Correct html encoding of special characters in RelayState"
    );

    sub getAuthnRequest {
        my ($method) = @_;

        my $server = Lasso::Server::new_from_buffers(
            samlProxyMetaDataXML( "proxy", $method ),
            saml_key_proxy_private_sig(),
            undef, undef
        );
        $server->add_provider_from_buffer( 2,
            samlIDPMetaDataXML( "idp", $method ) );

        my $login  = Lasso::Login->new($server);
        my $method = $saml->getHttpMethod($method);
        $login->init_authn_request("http://auth.idp.com/saml/metadata");
        $login->msg_relayState('{"url": "http://test/%22"}');
        $login->build_authn_request_msg();
        return $login;
    }
}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                globalLogoutRule       => 1,
                globalLogoutTimer      => 0,
                issuerDBSAMLActivation => 1,
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
                        samlSPMetaDataXML =>
                          samlProxyMetaDataXML( 'proxy', 'HTTP-Redirect' )
                    },
                },
            }
        }
    );
}
