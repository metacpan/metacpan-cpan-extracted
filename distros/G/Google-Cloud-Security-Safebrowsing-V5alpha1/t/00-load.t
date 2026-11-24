#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Security::Safebrowsing::V5alpha1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Security::Safebrowsing::V5alpha1::SafeBrowsingClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Security::Safebrowsing::V5alpha1 $Google::Cloud::Security::Safebrowsing::V5alpha1::VERSION, Perl $], $^X" );
