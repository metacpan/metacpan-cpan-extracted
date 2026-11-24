#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Functions::V2beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Functions::V2beta::FunctionServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Functions::V2beta $Google::Cloud::Functions::V2beta::VERSION, Perl $], $^X" );
