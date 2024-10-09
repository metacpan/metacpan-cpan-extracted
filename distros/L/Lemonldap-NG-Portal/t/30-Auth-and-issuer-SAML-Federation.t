use warnings;
use Test::More;
use strict;
use IO::String;
use File::Copy "cp";
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $debug = $ENV{DEBUG} ? 'debug' : 'error';
my ( $issuer, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        fail('POST should not launch SOAP requests');
        count(1);
        return [ 500, [], [] ];
    }
);

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found';
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    subtest "Test logging in to a federated IDP" => sub {

        ok(
            $res = $sp->_get(
                '/',
                accept => 'text/html',
                query  => buildForm( {
                        idp =>
                          'https://auth.centrale-marseille.fr/idp/shibboleth'
                    }
                )
            )
        );
        my ( $host, $url, $query ) =
          expectAutoPost( $res, "auth.centrale-marseille.fr",
            "/idp/profile/SAML2/POST/SSO", "SAMLRequest" );
        my $sr = expectSamlRequest($query);

    };

    subtest "Responding to a federated SP" => sub {
        my $res;
        my $query = buildForm( {
                user     => 'french',
                password => 'french',
            }
        );
        $res = $issuer->_post(
            "/",
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        );
        my $id = expectCookie($res);
        ok(
            $res = $issuer->_get(
                '/saml/singleSignOn',
                accept => 'text/html',
                cookie => "lemonldap=$id",
                query  => buildForm( {
                        IDPInitiated => 1,
                        sp           => "https://www.numistral.fr/shibboleth"
                    }
                )
            )
        );
        expectPortalError( $res, 107, "SAML service is not yet known" );

        cp( "t/main-sps-renater-metadata.xml",
            "$main::tmpDir/main-sps-renater-metadata.xml" );

        # After short TTL, service is still not valid
        Time::Fake->offset("+30s");
        ok(
            $res = $issuer->_get(
                '/saml/singleSignOn',
                accept => 'text/html',
                cookie => "lemonldap=$id",
                query  => buildForm( {
                        IDPInitiated => 1,
                        sp           => "https://www.numistral.fr/shibboleth"
                    }
                )
            )
        );
        expectPortalError( $res, 107, "SAML service is still not known" );

        # After long TTL, service is found
        Time::Fake->offset("+900s");
        ok(
            $res = $issuer->_get(
                '/saml/singleSignOn',
                accept => 'text/html',
                cookie => "lemonldap=$id",
                query  => buildForm( {
                        IDPInitiated => 1,
                        sp           => "https://www.numistral.fr/shibboleth"
                    }
                )
            )
        );

        my ( $host, $url, $s ) = expectAutoPost( $res, "www.numistral.fr",
            "/Shibboleth.sso/SAML2/POST", "SAMLResponse" );
        my $sr = expectSamlResponse($s);
        expectXPath(
            $sr,
'//saml:Attribute[@Name="urn:oid:0.9.2342.19200300.100.1.3"]/saml:AttributeValue/text()',
            'fa@badwolf.org',
            'Found attribute'
        );
    };

}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                samlFederationFiles =>
                  "$main::tmpDir/main-sps-renater-metadata.xml",
                logLevel         => $debug,
                domain           => 'idp.com',
                portal           => 'http://auth.idp.com/',
                authentication   => 'Demo',
                userDB           => 'Same',
                demoExportedVars => {
                    "cn"                     => "cn",
                    "eduPersonPrincipalName" => "mail",
                    "displayName"            => "cn",
                },
                issuerDBSAMLActivation => 1,
                issuerDBSAMLRule       => '$uid eq "french"',
                samlSPMetaDataOptions  => {
                    'mysp' => {
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsFederationEntityID       =>
                          'https://podcast.mines-nantes.fr/shibboleth',
                    },
                    'fed' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsEnableIDPInitiatedURL    => 1,
                        samlSPMetaDataOptionsFederationEntityID       =>
                          'https://federation.renater.fr/',
                    },
                },
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.idp.com/",
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_public_enc,
                samlServicePublicKeySig     => saml_key_idp_public_sig,
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                samlFederationFiles =>
"t/main-idps-renater-metadata.xml t/main-sps-renater-metadata.xml",
                logLevel               => $debug,
                domain                 => 'sp.com',
                portal                 => 'http://auth.sp.com/',
                authentication         => 'SAML',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 0,
                restSessionServer      => 1,
                samlIDPMetaDataOptions => {
                    fed => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 0,
                        samlIDPMetaDataOptionsFederationEntityID       =>
                          'https://federation.renater.fr/',
                    },
                    myidp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                        samlIDPMetaDataOptionsFederationEntityID       =>
                          'https://auth.centrale-marseille.fr/idp/shibboleth',
                    },
                },
                samlIDPMetaDataExportedAttributes => {},
                samlOrganizationDisplayName       => "SP",
                samlOrganizationName              => "SP",
                samlOrganizationURL               => "http://www.sp.com",
                samlServicePublicKeySig           => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc          => saml_key_sp_private_enc,
                samlServicePrivateKeySig          => saml_key_sp_private_sig,
                samlServicePublicKeyEnc           => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}
