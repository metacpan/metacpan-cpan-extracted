#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Google::Cloud::Devicestreaming::V1' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Devicestreaming::V1::DirectAccessServiceClient' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Devicestreaming::V1 $Google::Cloud::Devicestreaming::V1::VERSION, Perl $], $^X" );
