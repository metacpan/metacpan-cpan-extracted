#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Eshu' ) || print "Bail out!\n";
}

diag( "Testing Eshu $Eshu::VERSION, Perl $], $^X" );
