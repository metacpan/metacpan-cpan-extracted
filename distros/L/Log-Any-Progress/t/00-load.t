#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Log::Any::Progress' ) || print "Bail out!\n";
}

diag( "Testing Log::Any::Progress $Log::Any::Progress::VERSION, Perl $], $^X" );
