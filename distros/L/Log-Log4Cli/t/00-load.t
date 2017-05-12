#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Log4Cli' ) || print "Bail out!\n";
}

diag( "Testing Log::Log4Cli $Log::Log4Cli::VERSION, Perl $], $^X" );
