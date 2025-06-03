#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Debug::Helper::Flag' ) || print "Bail out!\n";
}

diag( "Testing Debug::Helper::Flag $Debug::Helper::Flag::VERSION, Perl $], $^X" );
