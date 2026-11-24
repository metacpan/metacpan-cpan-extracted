#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Faulttesting::V1alpha' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Faulttesting::V1alpha $Google::Cloud::Faulttesting::V1alpha::VERSION, Perl $], $^X" );
