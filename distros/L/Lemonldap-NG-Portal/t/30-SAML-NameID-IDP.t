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
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        fail('POST should not launch SOAP requests');
        return [ 500, [], [] ];
    }
);

sub runTest {
    my %args           = @_;
    my $req_nif        = $args{'requested_format'};
    my $idp_nif        = $args{'idp_conf'};
    my $force_attr     = $args{'idp_attr'};
    my $expect_res_nif = $args{'expected_format'};
    my $expect_nameid  = $args{'expected_nameid'};

    # Initialization
    $issuer = register( 'issuer', sub { issuer( $idp_nif, $force_attr ) } );
    my $id = $issuer->login("french");

    my $request = getAuthnRequest($req_nif);

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
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    my $sr = expectSamlResponse($s);
    expectXPath(
        $sr, '/samlp:Response/saml:Assertion/saml:Subject/saml:NameID/@Format',
        $expect_res_nif, 'Found expected NameID Format in response',
    );

    if ($expect_nameid) {
        my $nameidvalue = expectXPath( $sr,
            '/samlp:Response/saml:Assertion/saml:Subject/saml:NameID/text()' );
        note "Found NameID $nameidvalue with format $expect_res_nif";
        if ( ref($expect_nameid) eq "Regexp" ) {
            like( $nameidvalue, $expect_nameid, "NameID matches" );
        }
        else {
            is( $nameidvalue, $expect_nameid, "NameID matches" );
        }
        return $nameidvalue;
    }
}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip('Lasso not found');
    }

    # Default settings use the email NIF
    runTest(

        # requested NameIDFormat (sp side)
        requested_format => undef,

        # configured NameIDFormatKey (idp side)
        idp_conf => undef,

        # Name ID session key
        idp_attr => undef,

        # Expected NameIDFormat in SAMLResponse
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",

        # Expected NameID value
        expected_nameid => 'fa@badwolf.org'
    );

    # Override session key
    runTest(
        requested_format => undef,
        idp_conf         => undef,
        idp_attr         => "uid",
        expected_format  =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        expected_nameid => 'french'
    );

    # Using email explicitly return the email
    runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        idp_conf        => "email",
        idp_attr        => undef,
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        expected_nameid => 'fa@badwolf.org'
    );

    # Changing the format on the IDP side has no effect if the client
    # specifies a NIF
    runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        idp_conf        => "kerberos",
        idp_attr        => undef,
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
        expected_nameid => 'fa@badwolf.org'
    );

    # Using unspecified on the requesting side causes IDP settings to be honored
    # specifies a NIF
    runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        idp_conf        => "kerberos",
        idp_attr        => undef,
        expected_format => "urn:oasis:names:tc:SAML:2.0:nameid-format:kerberos",
        expected_nameid => 'french'
    );

    # Unspecified both ways + no forced key returns no value
    runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        idp_conf        => "unspecified",
        idp_attr        => undef,
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        expected_nameid => undef,
    );

    # Unspecified both ways returns forced key in unspecified format
    runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        idp_conf        => "unspecified",
        idp_attr        => 'mail',
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        expected_nameid => 'fa@badwolf.org',
    );

    # persistent asked by SP returns a value
    my $persistent_id = runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        idp_conf        => "email",
        idp_attr        => undef,
        expected_format =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        expected_nameid => qr/./,
    );

    # persistent chosen by IDP returns a value
    runTest(
        requested_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
        idp_conf        => "persistent",
        idp_attr        => undef,
        expected_format =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        expected_nameid => $persistent_id,
    );

   # Missing NameIDFormat in request + persistent in config is correctly handled
    runTest(
        requested_format => undef,
        idp_conf         => "persistent",
        idp_attr         => undef,
        expected_format  =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
        expected_nameid => $persistent_id,
    );

    # Missing NameIDFormat in request + transient in config is correctly handled
    my $transient_id = runTest(
        requested_format => undef,
        idp_conf         => "transient",
        idp_attr         => undef,
        expected_format  =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:transient",
        expected_nameid => qr/./,
    );
    isnt( $transient_id, $persistent_id,
        "Transient ID is different from persistent ID" );

}
clean_sessions();
done_testing();

sub getAuthnRequest {
    my ($nameIDPolicy) = @_;
    my $server =
      Lasso::Server::new_from_buffers( samlSPMetaDataXML( "sp", "HTTP-POST" ),
        saml_key_sp_private_sig(), undef, undef );
    $server->add_provider_from_buffer(
        Lasso::Constants::PROVIDER_ROLE_IDP,
        samlIDPMetaDataXML( "idp", "HTTP-POST" )
    );

    my $login = Lasso::Login->new($server);
    $login->init_authn_request(
        "http://auth.idp.com/saml/metadata",
        Lasso::Constants::HTTP_METHOD_POST
    );
    $login->set_signature_hint(Lasso::Constants::PROFILE_SIGNATURE_HINT_FORBID);

    if ($nameIDPolicy) {
        $login->request->NameIDPolicy->Format($nameIDPolicy);
        $login->request->NameIDPolicy->AllowCreate(0);
    }
    else {
        $login->request->NameIDPolicy(undef);
    }

    $login->build_authn_request_msg();
    note "Generated SAML Request: " . $login->request->dump;
    return $login->msg_body;
}

sub issuer {
    my ( $res_nif, $force_attr ) = @_;
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
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 0,
                        (
                            $res_nif
                            ? ( samlSPMetaDataOptionsNameIDFormat => $res_nif, )
                            : ()
                        ),
                        (
                            $force_attr
                            ? ( samlSPMetaDataOptionsNameIDSessionKey =>
                                  $force_attr, )
                            : ()
                        ),
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
                          samlSPMetaDataXML( 'sp', 'HTTP-POST' )
                    },
                },
            }
        }
    );
}
