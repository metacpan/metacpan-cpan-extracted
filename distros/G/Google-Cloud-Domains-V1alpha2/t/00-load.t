#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Domains::V1alpha2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Domains::V1alpha2::DomainsClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Domains::V1alpha2 $Google::Cloud::Domains::V1alpha2::VERSION, Perl $], $^X" );
