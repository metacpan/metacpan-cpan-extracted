#!perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Enbld' ) || print "Bail out!\n";
}

diag( "Testing Enbld $Enbld::VERSION, Perl $], $^X" );
