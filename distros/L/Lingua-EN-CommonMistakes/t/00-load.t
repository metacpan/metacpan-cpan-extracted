#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lingua::EN::CommonMistakes' ) || print "Bail out!\n";
}

diag( "Testing Lingua::EN::CommonMistakes $Lingua::EN::CommonMistakes::VERSION, Perl $], $^X" );
