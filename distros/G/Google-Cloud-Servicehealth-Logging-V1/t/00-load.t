#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Servicehealth::Logging::V1' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Servicehealth::Logging::V1 $Google::Cloud::Servicehealth::Logging::V1::VERSION, Perl $], $^X" );
