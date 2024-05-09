#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Feed::Data::AlJazeera' ) || print "Bail out!\n";
}

diag( "Testing Feed::Data::AlJazeera $Feed::Data::AlJazeera::VERSION, Perl $], $^X" );
