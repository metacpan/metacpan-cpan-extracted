#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Markdown::Simple' ) || print "Bail out!\n";
}

diag( "Testing Markdown::Simple $Markdown::Simple::VERSION, Perl $], $^X" );
