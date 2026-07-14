#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Bigquery::V2' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Bigquery::V2 $Google::Cloud::Bigquery::V2::VERSION, Perl $], $^X" );
