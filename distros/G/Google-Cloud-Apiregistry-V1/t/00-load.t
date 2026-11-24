#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Apiregistry::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apiregistry::V1::CloudApiRegistryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Apiregistry::V1 $Google::Cloud::Apiregistry::V1::VERSION, Perl $], $^X" );
