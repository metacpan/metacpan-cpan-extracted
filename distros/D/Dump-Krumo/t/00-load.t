#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dump::Krumo' ) || print "Bail out!\n";
}

diag( "Testing Dump::Krumo $Dump::Krumo::VERSION, Perl $], $^X" );
