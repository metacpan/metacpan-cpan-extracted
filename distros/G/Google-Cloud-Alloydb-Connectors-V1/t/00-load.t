#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Alloydb::Connectors::V1' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Alloydb::Connectors::V1 $Google::Cloud::Alloydb::Connectors::V1::VERSION, Perl $], $^X" );
