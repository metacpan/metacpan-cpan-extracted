use lib 'inc';
use Test::More;
use strict;
use IO::String;
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

    my $saml =
      $issuer->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::SAML'};
    my $entityID = "https://podcast.mines-nantes.fr/shibboleth";
    $saml->lazy_load_metadata($entityID);
    $entityID = "https://www.numistral.fr/shibboleth";
    $saml->lazy_load_metadata($entityID);
    is(
        $saml->spList->{'https://podcast.mines-nantes.fr/shibboleth'}
          ->{confKey},
        "mysp", "confKey from config"
    );
    is(
        $saml->spList->{'https://www.numistral.fr/shibboleth'}->{confKey},
        "fed:https://www.numistral.fr/shibboleth",
        "confKey was generated"
    );
    is(
        $saml->spOptions->{'https://podcast.mines-nantes.fr/shibboleth'}
          ->{'samlSPMetaDataOptionsRule'},
        '$uid eq "sp"',
        'Rule from SP config'
    );
    is(
        $saml->spOptions->{'https://www.numistral.fr/shibboleth'}
          ->{'samlSPMetaDataOptionsRule'},
        '$uid eq "fed"',
        'Rule from federation defaults'
    );

    # Check policy: optional attributes are not imported,
    # mandatory attributes are made optional
    # attributes defined in SP config are added
    is_deeply(
        $saml->spAttributes->{'https://podcast.mines-nantes.fr/shibboleth'},
        {
            'additionalcn' =>
              '1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
            'eduPersonPrincipalName' =>
'0;urn:oid:1.3.6.1.4.1.5923.1.1.1.6;urn:oasis:names:tc:SAML:2.0:attrname-format:uri;eduPersonPrincipalName'
        },

        "SP attributes have been imported as configured by policy",
    );
    is_deeply(
        $saml->spAttributes->{'https://www.numistral.fr/shibboleth'},
        {
            'eduPersonPrincipalName' =>
'0;urn:oid:1.3.6.1.4.1.5923.1.1.1.6;urn:oasis:names:tc:SAML:2.0:attrname-format:uri;eduPersonPrincipalName',
            'mail' =>
'0;urn:oid:0.9.2342.19200300.100.1.3;urn:oasis:names:tc:SAML:2.0:attrname-format:uri;mail'
        },
        "SP attributes have been imported as configured by policy",
    );

    $saml     = $sp->p->loadedModules->{'Lemonldap::NG::Portal::Auth::SAML'};
    $entityID = "https://idp4.crous-lorraine.fr/idp/shibboleth";
    $saml->lazy_load_metadata($entityID);
    $entityID = "https://auth.centrale-marseille.fr/idp/shibboleth";
    $saml->lazy_load_metadata($entityID);
    is(
        $saml->idpOptions->{
            'https://auth.centrale-marseille.fr/idp/shibboleth'}
          ->{'samlIDPMetaDataOptionsSLOBinding'},
        'post',
        "IDP option from config override"
    );
    is(
        $saml->idpOptions->{'https://idp4.crous-lorraine.fr/idp/shibboleth'}
          ->{'samlIDPMetaDataOptionsForceUTF8'},
        '0', "IDP option from federation defaults"
    );
    $saml->lazy_load_metadata("Notfound");

    is_deeply(
        $saml->idpAttributes->{'https://idp4.crous-lorraine.fr/idp/shibboleth'},
        {
            'cn'  => '1;cn;;',
            'uid' => '0;uid;;'
        },
        "IDP attributes from federation defaults"
    );

    is_deeply(
        $saml->idpAttributes->{
            'https://auth.centrale-marseille.fr/idp/shibboleth'},
        {
            'givenName' => '1;givenName;;',
            'sn'        => '0;cn;;'
        },
        "IDP attributes from configuration override"
    );

}
clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                samlFederationFiles =>
"t/main-idps-renater-metadata.xml t/main-sps-renater-metadata.xml",
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                issuerDBSAMLRule       => '$uid eq "french"',
                samlSPMetaDataOptions  => {
                    'mysp' => {
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsRule => '$uid eq "sp"',
                        samlSPMetaDataOptionsFederationEntityID =>
                          'https://podcast.mines-nantes.fr/shibboleth',
                        samlSPMetaDataOptionsFederationOptionalAttributes =>
                          'ignore',
                        samlSPMetaDataOptionsFederationRequiredAttributes =>
                          'optional',
                    },
                    'fed' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsRule => '$uid eq "fed"',
                        samlSPMetaDataOptionsFederationEntityID =>
                          'https://federation.renater.fr/',
                        samlSPMetaDataOptionsFederationOptionalAttributes =>
                          'ignore',
                        samlSPMetaDataOptionsFederationRequiredAttributes =>
                          'optional',
                    },
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsRule => '$uid eq "dwho"',
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'mysp' => {
                        additionalcn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
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

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                samlFederationFiles =>
"t/main-idps-renater-metadata.xml t/main-sps-renater-metadata.xml",
                logLevel               => $debug,
                domain                 => 'sp.com',
                portal                 => 'http://auth.sp.com',
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
                    idp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                    fed => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                    myidp => {
                        "sn"        => "0;cn;;",
                        "givenName" => "1;givenName;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
                    },
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
