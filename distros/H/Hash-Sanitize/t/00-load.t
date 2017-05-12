#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hash::Sanitize' ) || print "Bail out!\n";
}

diag( "Testing Hash::Sanitize $Hash::Sanitize::VERSION, Perl $], $^X" );
