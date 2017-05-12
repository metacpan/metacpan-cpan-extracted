#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JavaScript::Console' ) || print "Bail out!\n";
}

diag( "Testing JavaScript::Console $JavaScript::Console::VERSION, Perl $], $^X" );
