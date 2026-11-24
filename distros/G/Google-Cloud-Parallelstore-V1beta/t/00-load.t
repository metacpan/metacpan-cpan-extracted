#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Parallelstore::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Parallelstore::V1beta::ParallelstoreClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Parallelstore::V1beta $Google::Cloud::Parallelstore::V1beta::VERSION, Perl $], $^X" );
