#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Filter::PerlTags' ) || print "Bail out!\n";
}

diag( "Testing Filter::PerlTags $Filter::PerlTags::VERSION, Perl $], $^X" );
