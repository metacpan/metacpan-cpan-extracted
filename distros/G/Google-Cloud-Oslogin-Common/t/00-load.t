#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Cloud::Oslogin::Common' ) || print "Bail out!\n";
}

diag( "Testing Google::Cloud::Oslogin::Common $Google::Cloud::Oslogin::Common::VERSION, Perl $], $^X" );
