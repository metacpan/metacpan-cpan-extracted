#!/usr/bin/perl 

use Test::More;
use strict;
use warnings;
use Storable qw/dclone/;
require_ok('./scripts/importMetadata');

my $xml;
{
    local $/ = undef;    # Slurp mode
    open XML, "t/data/preview-all-test-metadata.xml" or die;
    $xml = <XML>;
    close XML;
}

subtest 'Ignore SP' => sub {
    my $lmConf     = {};
    my $importConf = {
        main => {
            'ignore-sp' => [
                "https://ucopia.univ-brest.fr/",
                "http://icampus-test.univ-paris3.fr"
            ]
        }
    };

    # Run import
    my ( $spCounters, $idpCounters ) =
      transform_config( $importConf, $lmConf, $xml );
    is( $spCounters->{created},  45 );
    is( $spCounters->{ignored},  2 );
    is( $idpCounters->{created}, 12 );
    is( $idpCounters->{ignored}, 0 );
};

subtest 'Ignore IDP' => sub {
    my $lmConf     = {};
    my $importConf = {
        main => {
            'ignore-idp' => [
                "https://serveur.uvs.sn/idp/shibboleth",
                "https://idp-test.insa-rennes.fr/idp/shibboleth"
            ]
        }
    };

    # Run import
    my ( $spCounters, $idpCounters ) =
      transform_config( $importConf, $lmConf, $xml );
    is( $spCounters->{created},  47 );
    is( $spCounters->{ignored},  0 );
    is( $idpCounters->{created}, 10 );
    is( $idpCounters->{ignored}, 2 );
};

subtest 'Conf Prefix' => sub {
    my $lmConf     = {};
    my $importConf = {
        main => {
            'idpconfprefix' => 'renater-idp',
            'spconfprefix'  => 'renater-sp',
        }
    };

    # Run import
    transform_config( $importConf, $lmConf, $xml );
    is( scalar grep( /^renater-sp/, keys( %{ $lmConf->{samlSPMetaDataXML} } ) ),
        47 );
    is(
        scalar
          grep( /^renater-idp/, keys( %{ $lmConf->{samlIDPMetaDataXML} } ) ),
        12
    );
};

# Make sure matching providers who are not in the metadata are removed
# but non-matching providers are left alone
subtest 'Remove' => sub {
    my $lmConf = {
        samlSPMetaDataXML => {
            'sp-toremove' => { samlSPMetaDataXML => "removeme" },
            'tokeep'      => { samlSPMetaDataXML => "keepme" },
        },
        samlSPMetaDataExportedAttributes => {
            'sp-toremove' => {},
            'tokeep'      => {},
        },
        samlSPMetaDataOptions => {
            'sp-toremove' => {},
            'tokeep'      => {},
        },
        samlIDPMetaDataXML => {
            'idp-toremove' => { samlSPMetaDataXML => "removeme" },
            'tokeep'       => { samlSPMetaDataXML => "keepme" },
        },
        samlIDPMetaDataExportedAttributes => {
            'idp-toremove' => {},
            'tokeep'       => {},
        },
        samlIDPMetaDataOptions => {
            'idp-toremove' => {},
            'tokeep'       => {},
        },
    };
    my $importConf = {
        main => {
            'remove' => 1,
        }
    };

    # Run import
    transform_config( $importConf, $lmConf, $xml );
    ok( !$lmConf->{samlSPMetaDataOptions}->{'sp-toremove'} );
    ok( $lmConf->{samlSPMetaDataOptions}->{'tokeep'} );
    ok( !$lmConf->{samlSPMetaDataExportedAttributes}->{'sp-toremove'} );
    ok( $lmConf->{samlSPMetaDataExportedAttributes}->{'tokeep'} );
    ok( !$lmConf->{samlSPMetaDataXML}->{'sp-toremove'} );
    ok( $lmConf->{samlSPMetaDataXML}->{'tokeep'} );
    ok( !$lmConf->{samlIDPMetaDataOptions}->{'idp-toremove'} );
    ok( $lmConf->{samlIDPMetaDataOptions}->{'tokeep'} );
    ok( !$lmConf->{samlIDPMetaDataExportedAttributes}->{'idp-toremove'} );
    ok( $lmConf->{samlIDPMetaDataExportedAttributes}->{'tokeep'} );
    ok( !$lmConf->{samlIDPMetaDataXML}->{'idp-toremove'} );
    ok( $lmConf->{samlIDPMetaDataXML}->{'tokeep'} );
};

subtest 'IDP Exported attributes' => sub {
    my $lmConf     = {};
    my $importConf = {
        exportedAttributes => {
            cn                     => '0;cn',
            eduPersonPrincipalName => '1;eduPersonPrincipalName',
        },
        'https://univ-machineDebian.fr/idp/shibboleth' => {
            exported_attribute_uid => '0;uid',
        }
    };

    # Run import
    transform_config( $importConf, $lmConf, $xml );
    is_deeply(
        $lmConf->{samlIDPMetaDataExportedAttributes}
          ->{'idp-idp-test-insa-rennes-fr-idp-shibboleth'},
        {
            cn                     => '0;cn',
            eduPersonPrincipalName => '1;eduPersonPrincipalName',
        }
    );
    is_deeply(
        $lmConf->{samlIDPMetaDataExportedAttributes}
          ->{'idp-univ-machineDebian-fr-idp-shibboleth'},
        {
            cn                     => '0;cn',
            eduPersonPrincipalName => '1;eduPersonPrincipalName',
            uid                    => '0;uid',
        }
    );
};

subtest 'SP Exported attributes' => sub {
    my $lmConf     = {};
    my $importConf = {
        ALL => {
            attribute_required => 0,
        },
        'https://ucopia.univ-brest.fr/' => {
            attribute_required     => 1,
            attribute_required_uid => 0,
        }
    };

    # Run import
    transform_config( $importConf, $lmConf, $xml );
    like(
        $lmConf->{samlSPMetaDataExportedAttributes}
          ->{'sp-umr5557-kaa-univ-lyon1-fr-sp'}->{mail},
        qr/^0/,
    );
    like(
        $lmConf->{samlSPMetaDataExportedAttributes}
          ->{'sp-ucopia-univ-brest-fr'}->{mail},
        qr/^1/,
    );
    like(
        $lmConf->{samlSPMetaDataExportedAttributes}
          ->{'sp-ucopia-univ-brest-fr'}->{uid},
        qr/^0/
    );
};

subtest 'Options' => sub {
    my $lmConf     = {};
    my $importConf = {
        ALL => {
            samlSPMetaDataOptionsCheckSSOMessageSignature => 0,
            samlIDPMetaDataOptionsStoreSAMLToken          => 1,
        },
        'https://ucopia.univ-brest.fr/' => {
            samlSPMetaDataOptionsCheckSSOMessageSignature => 1
        },
        'https://univ-machineDebian.fr/idp/shibboleth' => {
            samlIDPMetaDataOptionsForceAuthn => 1,
        },
    };

    # Run import
    transform_config( $importConf, $lmConf, $xml );
    is(
        $lmConf->{samlSPMetaDataOptions}->{'sp-ucopia-univ-brest-fr'}
          ->{samlSPMetaDataOptionsCheckSSOMessageSignature},
        1
    );
    is(
        $lmConf->{samlSPMetaDataOptions}->{'sp-wiki-uness-fr'}
          ->{samlSPMetaDataOptionsCheckSSOMessageSignature},
        0
    );
    is(
        $lmConf->{samlIDPMetaDataOptions}
          ->{'idp-shibboleth-2022-grenoble-archi-fr-idp'}
          ->{samlIDPMetaDataOptionsStoreSAMLToken},
        1
    );
    is(
        $lmConf->{samlIDPMetaDataOptions}
          ->{'idp-shibboleth-2022-grenoble-archi-fr-idp'}
          ->{samlIDPMetaDataOptionsForceAuthn},
        0
    );
    is(
        $lmConf->{samlIDPMetaDataOptions}
          ->{'idp-univ-machineDebian-fr-idp-shibboleth'}
          ->{samlIDPMetaDataOptionsForceAuthn},
        1
    );
};

done_testing();
