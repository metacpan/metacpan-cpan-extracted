#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Metastore::V1::DataprocMetastoreClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Metastore::V1::DataprocMetastoreFederationClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Metastore::V1::DataprocMetastoreClient $Google::Cloud::Metastore::V1::DataprocMetastoreClient::VERSION, Perl $], $^X" );
