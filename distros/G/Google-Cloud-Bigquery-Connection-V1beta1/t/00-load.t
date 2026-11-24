#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::Connection::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Bigquery::Connection::V1beta1::ConnectionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::Connection::V1beta1 $Google::Cloud::Bigquery::Connection::V1beta1::VERSION, Perl $], $^X" );
