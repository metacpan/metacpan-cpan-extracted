#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Numberregistry::V1alpha' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Numberregistry::V1alpha::CloudNumberRegistryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Numberregistry::V1alpha $Google::Cloud::Numberregistry::V1alpha::VERSION, Perl $], $^X" );
