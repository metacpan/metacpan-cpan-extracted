#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JSON::Lines' ) || print "Bail out!\n";
}

diag( "Testing JSON::Lines $JSON::Lines::VERSION, Perl $], $^X" );
