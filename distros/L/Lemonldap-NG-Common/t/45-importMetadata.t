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

my $lmConf     = {};
my $importConf = {};

# Run import
my ( $spCounters, $idpCounters ) =
  transform_config( $importConf, $lmConf, $xml );

# Check statistics
is_deeply(
    $spCounters,
    {
        'created'  => 47,
        'found'    => 48,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 0
    },
    "SP counters are expected"
);
is_deeply(
    $idpCounters,
    {
        'created'  => 12,
        'found'    => 13,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 0
    },
    "IDP counters are expected"
);

is( keys %{ $lmConf->{samlIDPMetaDataXML} }, 12,
    "Correct amount of providers" );
is( keys %{ $lmConf->{samlIDPMetaDataExportedAttributes} },
    12, "Correct amount of providers" );
is( keys %{ $lmConf->{samlIDPMetaDataOptions} },
    12, "Correct amount of providers" );
is( keys %{ $lmConf->{samlSPMetaDataXML} }, 47, "Correct amount of providers" );
is( keys %{ $lmConf->{samlSPMetaDataExportedAttributes} },
    47, "Correct amount of providers" );
is( keys %{ $lmConf->{samlSPMetaDataOptions} },
    47, "Correct amount of providers" );

my $idp = "idp-idp-test-insa-rennes-fr-idp-shibboleth";
my $sp  = "sp-ucopia-univ-brest-fr";

is(
    $lmConf->{samlIDPMetaDataExportedAttributes}->{$idp}
      ->{eduPersonPrincipalName},
    '0;eduPersonPrincipalName', "Found exported attribute"
);

is(
    $lmConf->{samlSPMetaDataExportedAttributes}->{$sp}->{supannEtablissement},
    join( ';',
        0,
        'urn:oid:1.3.6.1.4.1.7135.1.2.1.14',
        'urn:oasis:names:tc:SAML:2.0:attrname-format:uri',
        'supannEtablissement' ),
    "Found optional attribute"
);

is(
    $lmConf->{samlSPMetaDataExportedAttributes}->{$sp}->{uid},
    join( ';',
        1,
        'urn:oid:0.9.2342.19200300.100.1.1',
        'urn:oasis:names:tc:SAML:2.0:attrname-format:uri', 'uid' ),
    "Found required attribute"
);

# Check update
$lmConf->{samlSPMetaDataOptions}->{$sp}
  ->{samlSPMetaDataOptionsCheckSSOMessageSignature} = 0;
$lmConf->{samlIDPMetaDataOptions}->{$idp}
  ->{samlIDPMetaDataOptionsAllowLoginFromIDP} = 1;
( $spCounters, $idpCounters ) = transform_config( $importConf, $lmConf, $xml );

# Check statistics
is_deeply(
    $spCounters,
    {
        'created'  => 0,
        'found'    => 48,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 1
    },
    "SP counters are expected"
);
is_deeply(
    $idpCounters,
    {
        'created'  => 0,
        'found'    => 13,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 1
    },
    "IDP counters are expected"
);
is(
    $lmConf->{samlSPMetaDataOptions}->{$sp}
      ->{samlSPMetaDataOptionsCheckSSOMessageSignature},
    1, "Configuration was updated"
);
is(
    $lmConf->{samlIDPMetaDataOptions}->{$idp}
      ->{samlIDPMetaDataOptionsAllowLoginFromIDP},
    0, "Configuration was updated"
);

# Check idempotence
my $oldLmConf = dclone $lmConf;
( $spCounters, $idpCounters ) = transform_config( $importConf, $lmConf, $xml );

is_deeply(
    $spCounters,
    {
        'created'  => 0,
        'found'    => 48,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 0
    },
    "SP counters are expected"
);
is_deeply(
    $idpCounters,
    {
        'created'  => 0,
        'found'    => 13,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 0
    },
    "IDP counters are expected"
);

is_deeply( $lmConf, $oldLmConf );
done_testing();
