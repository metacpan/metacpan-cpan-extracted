#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::Storage::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Storage::V1alpha::MetastorePartitionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::Storage::V1alpha $Google::Cloud::Bigquery::Storage::V1alpha::VERSION, Perl $], $^X" );
