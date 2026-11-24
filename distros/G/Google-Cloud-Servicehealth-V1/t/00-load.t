#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Servicehealth::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Servicehealth::V1::ServiceHealthClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Servicehealth::V1 $Google::Cloud::Servicehealth::V1::VERSION, Perl $], $^X" );
