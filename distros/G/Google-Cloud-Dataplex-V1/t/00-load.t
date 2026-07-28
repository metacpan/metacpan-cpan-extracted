#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 9;

BEGIN {
    use_ok( 'Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::CatalogServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::CmekServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::ContentServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::DataProductServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::DataScanServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::DataTaxonomyServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::DataplexServiceClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Dataplex::V1::MetadataServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient $Google::Cloud::Dataplex::V1::BusinessGlossaryServiceClient::VERSION, Perl $], $^X" );
