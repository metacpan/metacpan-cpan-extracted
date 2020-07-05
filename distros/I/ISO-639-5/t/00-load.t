#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ISO::639::5' ) || print "Bail out!\n";
}

diag( "Testing ISO::639::5 $ISO::639::5::VERSION, Perl $], $^X" );
