#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Google::Api::Common' ) || print "Bail out!\n";
}

diag( "Testing Google::Api::Common $Google::Api::Common::VERSION, Perl $], $^X" );
