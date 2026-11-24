#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Metastore::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Metastore::V1beta::DataprocMetastoreClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Metastore::V1beta::DataprocMetastoreFederationClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Metastore::V1beta $Google::Cloud::Metastore::V1beta::VERSION, Perl $], $^X" );
