#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Filter::PerlTags::Extra' ) || print "Bail out!\n";
}

diag( "Testing Filter::PerlTags::Extra $Filter::PerlTags::Extra::VERSION, Perl $], $^X" );
