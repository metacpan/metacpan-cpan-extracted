#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Alloydb::Connectors::V1alpha' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Alloydb::Connectors::V1alpha $Google::Cloud::Alloydb::Connectors::V1alpha::VERSION, Perl $], $^X" );
