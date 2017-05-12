#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';
plan tests => 1;

BEGIN {
    use_ok( 'Lingua::Sindarin::Dictionary' ) || print "Bail out!\n";
}

diag( "Testing Lingua::Sindarin::Dictionary $Lingua::Sindarin::Dictionary::VERSION, Perl $], $^X" );
