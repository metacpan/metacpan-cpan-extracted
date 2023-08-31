use warnings;
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

# Update this if you change the content of the file
my $idp_in_file = 12;
my $sp_in_file  = 48;

my $lmConf     = {};
my $importConf = {};

# Run import
my ( $spCounters, $idpCounters ) =
  transform_config( $importConf, $lmConf, $xml );

# Check statistics
is_deeply(
    $spCounters,
    {
        'created'  => $sp_in_file,
        'found'    => $sp_in_file + 1,
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
        'created'  => $idp_in_file,
        'found'    => $idp_in_file + 1,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 0
    },
    "IDP counters are expected"
);

is( keys %{ $lmConf->{samlIDPMetaDataXML} },
    $idp_in_file, "Correct amount of providers" );
is( keys %{ $lmConf->{samlIDPMetaDataExportedAttributes} },
    $idp_in_file, "Correct amount of providers" );
is( keys %{ $lmConf->{samlIDPMetaDataOptions} },
    $idp_in_file, "Correct amount of providers" );
is( keys %{ $lmConf->{samlSPMetaDataXML} },
    $sp_in_file, "Correct amount of providers" );
is( keys %{ $lmConf->{samlSPMetaDataExportedAttributes} },
    $sp_in_file, "Correct amount of providers" );
is( keys %{ $lmConf->{samlSPMetaDataOptions} },
    $sp_in_file, "Correct amount of providers" );

my $idp = "idp-idp-test-insa-rennes-fr-idp-shibboleth";
my $sp  = "sp-ucopia-univ-brest-fr";
my $eduroam =
  "sp-monitor-eduroam-org-sp-module-php-saml-sp-metadata-php-default-sp";

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

is(

    $lmConf->{samlSPMetaDataExportedAttributes}->{$eduroam}->{'subjectId'},
    join( ';',
        0,
        'urn:oasis:names:tc:SAML:attribute:subject-id',
        'urn:oasis:names:tc:SAML:2.0:attrname-format:uri', 'subject-id' ),
    "Found subject ID"
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
        'found'    => $sp_in_file + 1,
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
        'found'    => $idp_in_file + 1,
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
        'found'    => $sp_in_file + 1,
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
        'found'    => $idp_in_file + 1,
        'ignored'  => 0,
        'rejected' => 1,
        'removed'  => 0,
        'updated'  => 0
    },
    "IDP counters are expected"
);

is_deeply( $lmConf, $oldLmConf );
done_testing();
