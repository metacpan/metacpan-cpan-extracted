#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Log::JSON::Lines' ) || print "Bail out!\n";
}

diag( "Testing Log::JSON::Lines $Log::JSON::Lines::VERSION, Perl $], $^X" );
