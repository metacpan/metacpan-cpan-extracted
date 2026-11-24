#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Apiregistry::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Apiregistry::V1beta::CloudApiRegistryClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Apiregistry::V1beta $Google::Cloud::Apiregistry::V1beta::VERSION, Perl $], $^X" );
