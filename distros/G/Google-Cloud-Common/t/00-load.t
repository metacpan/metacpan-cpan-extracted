#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Common' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Common $Google::Cloud::Common::VERSION, Perl $], $^X" );
