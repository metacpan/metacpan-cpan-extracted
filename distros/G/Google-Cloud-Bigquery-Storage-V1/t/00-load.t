#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::Storage::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Storage::V1::BigQueryReadClient' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Storage::V1::BigQueryWriteClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::Storage::V1 $Google::Cloud::Bigquery::Storage::V1::VERSION, Perl $], $^X" );
