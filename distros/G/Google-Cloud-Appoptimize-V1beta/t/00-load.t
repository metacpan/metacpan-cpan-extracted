#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Appoptimize::V1beta' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Appoptimize::V1beta::AppOptimizeClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Appoptimize::V1beta $Google::Cloud::Appoptimize::V1beta::VERSION, Perl $], $^X" );
