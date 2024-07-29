#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Kanboard::API' ) || print "Bail out!\n";
}

diag( "Testing Kanboard::API $Kanboard::API::VERSION, Perl $], $^X" );
