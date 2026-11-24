#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Confidentialcomputing::V1alpha1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Confidentialcomputing::V1alpha1::ConfidentialComputingClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Confidentialcomputing::V1alpha1 $Google::Cloud::Confidentialcomputing::V1alpha1::VERSION, Perl $], $^X" );
