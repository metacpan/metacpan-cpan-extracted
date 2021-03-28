#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Decl::Tok' ) || print "Bail out!\n";
}

diag( "Testing Decl::Tok $Decl::Tok::VERSION, Perl $], $^X" );
