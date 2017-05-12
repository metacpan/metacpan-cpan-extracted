#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JavaScript::Minifier' ) || print "Bail out!\n";
}

diag( "Testing JavaScript::Minifier $JavaScript::Minifier::VERSION, Perl $], $^X" );
