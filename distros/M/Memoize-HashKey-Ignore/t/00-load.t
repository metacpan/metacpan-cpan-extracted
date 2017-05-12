#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Memoize::HashKey::Ignore' ) || print "Bail out!\n";
}

diag( "Testing Memoize::HashKey::Ignore $Memoize::HashKey::Ignore::VERSION, Perl $], $^X" );
