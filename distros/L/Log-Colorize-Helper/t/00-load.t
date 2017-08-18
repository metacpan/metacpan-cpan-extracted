#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Log::Colorize::Helper' ) || print "Bail out!\n";
}

diag( "Testing Log::Colorize::Helper $Log::Colorize::Helper::VERSION, Perl $], $^X" );
