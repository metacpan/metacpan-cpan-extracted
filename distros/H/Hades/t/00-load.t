#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hades' ) || print "Bail out!\n";
}

diag( "Testing Hades $Hades::VERSION, Perl $], $^X" );
