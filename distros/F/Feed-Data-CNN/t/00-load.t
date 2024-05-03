#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Feed::Data::CNN' ) || print "Bail out!\n";
}

diag( "Testing Feed::Data::CNN $Feed::Data::CNN::VERSION, Perl $], $^X" );
