use warnings;
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
    unless (
        eval
'use Lasso; (Lasso::check_version( 2, 6, 0, Lasso::Constants::CHECK_VERSION_NUMERIC) )? 1 : 0'
      )
    {
        skip 'Lasso not found or too old';
    }
    if ($@) {
        skip 'Lasso not found';
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    my $saml =
      $issuer->p->loadedModules->{'Lemonldap::NG::Portal::Issuer::SAML'};
    my $entityID = "https://podcast.mines-nantes.fr/shibboleth";
    $saml->load_config($entityID);
    $entityID = "https://www.numistral.fr/shibboleth";
    $saml->load_config($entityID);
    $entityID =
"https://monitor.eduroam.org/sp/module.php/saml/sp/metadata.php/default-sp";
    $saml->load_config($entityID);
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

    is(
        $saml->spOptions->{'https://podcast.mines-nantes.fr/shibboleth'}
          ->{samlSPMetaDataOptionsNameIDFormat},
        undef, 'default NameID Format'
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

    is(
        $saml->spAttributes->{
'https://monitor.eduroam.org/sp/module.php/saml/sp/metadata.php/default-sp'
        }->{'subjectId'},
'0;urn:oasis:names:tc:SAML:attribute:subject-id;urn:oasis:names:tc:SAML:2.0:attrname-format:uri;subject-id'
    );

    is(
        $saml->spOptions->{'https://www.numistral.fr/shibboleth'}
          ->{samlSPMetaDataOptionsNameIDFormat},
        'persistent', 'eduPersonTargetedID sets required persistent NameID'
    );

    $saml     = $sp->p->loadedModules->{'Lemonldap::NG::Portal::Auth::SAML'};
    $entityID = "https://idp4.crous-lorraine.fr/idp/shibboleth";
    $saml->load_config($entityID);
    $entityID = "https://auth.centrale-marseille.fr/idp/shibboleth";
    $saml->load_config($entityID);
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
    $saml->load_config("Notfound");

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

    # Tests for getIssuer
    # Redirect binding
    my $msg =
"SAMLRequest=fVHJasMwEP0Vo3tqRXY2YRvcOIFAl9CUHnopwpkkAllyNeMuf1%2FZaSG95PrmLfNmMlSNaWXZ0ck%2BwXsHSNFXYyzKYZCzzlvpFGqUVjWAkmq5K%2B%2FvpLjhsvWOXO0Mu5BcVyhE8KSdZdGmytnbNEmTBV%2Bli9ulKMt5KlbVfDkbizWfcVEmUxa9gMfAz1mQBxFiBxuLpCwFiIvxiE9H48mz4FJMZJq8sqgKHbRVNKhORK2MY71vJzFqezSw00f7GPLXztcw9M7ZQRmE3n0bFtQf8IcUWV9JDqm%2B%2BPXCYNUAqb0ilcWXhOx8zIdQe1NtndH1dx%2FTKLp%2BlR7R%2B9FhoMq2b4wEllhUGuM%2Blx4UhZ3Id8Di4pz5%2F2fFDw%3D%3D&RelayState=fake";
    is( $saml->getIssuer($msg), "http://sp5/metadata", "getIssuer" );

 # Check that Lasso bug https://dev.entrouvert.org/issues/97575 is worked around
    $msg =
"SAMLRequest=fVHJasMwEP0Vo3tqRXY2YRvcOIFAl9CUHnopwpkkAllyNeMuf1%2FZaSG95PrmLfNmMlSNaWXZ0ck%2BwXsHSNFXYyzKYZCzzlvpFGqUVjWAkmq5K%2B%2FvpLjhsvWOXO0Mu5BcVyhE8KSdZdGmytnbNEmTBV%2Bli9ulKMt5KlbVfDkbizWfcVEmUxa9gMfAz1mQBxFiBxuLpCwFiIvxiE9H48mz4FJMZJq8sqgKHbRVNKhORK2MY71vJzFqezSw00f7GPLXztcw9M7ZQRmE3n0bFtQf8IcUWV9JDqm%2B%2BPXCYNUAqb0ilcWXhOx8zIdQe1NtndH1dx%2FTKLp%2BlR7R%2B9FhoMq2b4wEllhUGuM%2Blx4UhZ3Id8Di4pz5%2F2fFDw%3D%3D&RelayState=";
    is( $saml->getIssuer($msg), "http://sp5/metadata", "getIssuer" );

    # POST
    $msg =
"PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiPz4KPHNhbWxwOkF1dGhuUmVxdWVzdCB4bWxuczpzYW1scD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6Mi4wOnByb3RvY29sIgpJRD0ibGZub2VoY2ZnYWdmYmVmaWFpamFlZmRwbmRlcHBnbWZsbGVuZWxpayIgVmVyc2lvbj0iMi4wIgpJc3N1ZUluc3RhbnQ9IjIwMTAtMDktMjdUMTI6NTU6MjlaIgpQcm90b2NvbEJpbmRpbmc9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDpiaW5kaW5nczpIVFRQLVBPU1QiClByb3ZpZGVyTmFtZT0iZ29vZ2xlLmNvbSIgSXNQYXNzaXZlPSJmYWxzZSIKQXNzZXJ0aW9uQ29uc3VtZXJTZXJ2aWNlVVJMPSJodHRwczovL3d3dy5nb29nbGUuY29tL2EvbGluaWQub3JnL2FjcyI+PHNhbWw6SXNzdWVyCnhtbG5zOnNhbWw9InVybjpvYXNpczpuYW1lczp0YzpTQU1MOjIuMDphc3NlcnRpb24iPmdvb2dsZS5jb208L3NhbWw6SXNzdWVyPjxzYW1scDpOYW1lSURQb2xpY3kKQWxsb3dDcmVhdGU9InRydWUiCkZvcm1hdD0idXJuOm9hc2lzOm5hbWVzOnRjOlNBTUw6MS4xOm5hbWVpZC1mb3JtYXQ6dW5zcGVjaWZpZWQiCi8+PC9zYW1scDpBdXRoblJlcXVlc3Q+Cg==";
    is( $saml->getIssuer($msg), "google.com", "getIssuer" );

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
                portal                 => 'http://auth.idp.com/',
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
