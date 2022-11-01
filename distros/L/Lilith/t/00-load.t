#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lilith' ) || print "Bail out!\n";
}

diag( "Testing Lilith $Lilith::VERSION, Perl $], $^X" );
