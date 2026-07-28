#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Storage::V1::BigqueryWriteClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient $Google::Cloud::Bigquery::Storage::V1::BigqueryReadClient::VERSION, Perl $], $^X" );
