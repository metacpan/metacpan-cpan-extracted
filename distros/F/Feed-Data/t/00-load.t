#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Feed::Data' ) || print "Bail out!\n";
}

diag( "Testing Feed::Data $Feed::Data::VERSION, Perl $], $^X" );
