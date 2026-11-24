#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Memorystore::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Memorystore::V1beta::MemorystoreClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Memorystore::V1beta $Google::Cloud::Memorystore::V1beta::VERSION, Perl $], $^X" );
