#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Language::RAM' ) || print "Bail out!\n";
}

diag( "Testing Language::RAM $Language::RAM::VERSION, Perl $], $^X" );
