#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Google::Cloud::Datacatalog::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Datacatalog::V1::DataCatalogClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Datacatalog::V1::PolicyTagManagerClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Datacatalog::V1::PolicyTagManagerSerializationClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Datacatalog::V1 $Google::Cloud::Datacatalog::V1::VERSION, Perl $], $^X" );
