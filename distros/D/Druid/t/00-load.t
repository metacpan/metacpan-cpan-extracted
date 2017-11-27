#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Druid' ) || print "Bail out!\n";
}

diag( "Testing PerlDruid $PerlDruid::VERSION, Perl $], $^X" );
