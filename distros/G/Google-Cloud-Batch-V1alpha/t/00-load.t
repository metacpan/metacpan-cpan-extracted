#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Batch::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Batch::V1alpha::BatchServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Batch::V1alpha $Google::Cloud::Batch::V1alpha::VERSION, Perl $], $^X" );
