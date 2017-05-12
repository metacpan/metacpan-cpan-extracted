#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Log4perl::Lazy' ) || print "Bail out!\n";
}

diag( "Testing Log::Log4perl::Lazy $Log::Log4perl::Lazy::VERSION, Perl $], $^X" );
