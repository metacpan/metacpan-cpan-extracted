#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Feed::Data::BBC' ) || print "Bail out!\n";
}

diag( "Testing Feed::Data::BBC $Feed::Data::BBC::VERSION, Perl $], $^X" );
