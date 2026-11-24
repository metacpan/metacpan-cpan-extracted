#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Metastore::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Metastore::V1alpha::DataprocMetastoreClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Metastore::V1alpha::DataprocMetastoreFederationClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Metastore::V1alpha $Google::Cloud::Metastore::V1alpha::VERSION, Perl $], $^X" );
