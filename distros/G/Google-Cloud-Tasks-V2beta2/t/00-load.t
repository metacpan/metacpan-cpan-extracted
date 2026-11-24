#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Tasks::V2beta2' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Tasks::V2beta2::CloudTasksClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Tasks::V2beta2 $Google::Cloud::Tasks::V2beta2::VERSION, Perl $], $^X" );
