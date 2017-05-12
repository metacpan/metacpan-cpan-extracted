#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Indexuri::Apartament' ) || print "Bail out!\n";
}

diag( "Testing Indexuri::Apartament $Indexuri::Apartament::VERSION, Perl $], $^X" );
