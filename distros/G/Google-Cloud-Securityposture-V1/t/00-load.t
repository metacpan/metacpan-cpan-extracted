#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Securityposture::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Securityposture::V1::SecurityPostureClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Securityposture::V1 $Google::Cloud::Securityposture::V1::VERSION, Perl $], $^X" );
