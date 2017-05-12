#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'KelpX::AppBuilder' ) || print "Bail out!\n";
}

diag( "Testing KelpX::AppBuilder $KelpX::AppBuilder::VERSION, Perl $], $^X" );
