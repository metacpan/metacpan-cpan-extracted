#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Container::V1beta1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Container::V1beta1::ClusterManagerClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Container::V1beta1 $Google::Cloud::Container::V1beta1::VERSION, Perl $], $^X" );
