#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Geo::Parser::Text' ) || print "Bail out!\n";
}

diag( "Testing Geo::Parser::Text $Geo::Parser::Text::VERSION, Perl $], $^X" );
