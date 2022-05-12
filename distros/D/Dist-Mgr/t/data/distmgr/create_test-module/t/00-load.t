#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::Module' ) || print "Bail out!\n";
}

diag( "Testing Test::Module $Test::Module::VERSION, Perl $], $^X" );
