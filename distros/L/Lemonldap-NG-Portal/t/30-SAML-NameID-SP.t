use warnings;
use lib 'inc';
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

sub runTestSp {
    my %args           = @_;
    my $sp_nif         = $args{'sp_conf'};
    my $expect_req_nif = $args{'expected_format'};

    my $sp = register( 'sp', sub { sp($sp_nif) } );
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html'
        )
    );

    my ( $host, $url, $query ) =
      expectAutoPost( $res, "auth.idp.com",
        "/saml/singleSignOn", "SAMLRequest" );
    my $sr = expectSamlRequest($query);

    expectXPath(
        $sr,             '/samlp:AuthnRequest/samlp:NameIDPolicy/@Format',
        $expect_req_nif, 'Found expected NameID Format in response',
    );

}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip('Lasso not found');
    }

    runTestSp(
        sp_conf         => undef,
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    );
    runTestSp(
        sp_conf         => "unspecified",
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
    );
    runTestSp(
        sp_conf         => "email",
        expected_format =>
          "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    );
    runTestSp(
        sp_conf         => "persistent",
        expected_format =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
    );
    runTestSp(
        sp_conf         => "transient",
        expected_format =>
          "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
    );
}
clean_sessions();
done_testing();

sub sp {
    my ($req_nif) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp.com',
                portal                            => 'http://auth.sp.com',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 0,
                restSessionServer                 => 1,
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    idp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                        samlIDPMetaDataOptionsSignSSOMessage           => 0,
                        (
                            $req_nif
                            ? ( samlIDPMetaDataOptionsNameIDFormat => $req_nif,
                              )
                            : ()
                        ),
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-POST' )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.sp.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}
