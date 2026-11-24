#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Gkehub::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Gkehub::V1::GkeHubClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Gkehub::V1 $Google::Cloud::Gkehub::V1::VERSION, Perl $], $^X" );
