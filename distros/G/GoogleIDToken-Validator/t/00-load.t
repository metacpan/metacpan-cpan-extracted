#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'GoogleIDToken::Validator' ) || print "Bail out!\n";
}

diag( "Testing GoogleIDToken::Validator $GoogleIDToken::Validator::VERSION, Perl $], $^X" );
