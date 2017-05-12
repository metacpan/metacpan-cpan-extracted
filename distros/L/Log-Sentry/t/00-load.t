#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Log::Sentry' ) || print "Bail out!\n";
}

diag( "Testing Log::Sentry $Log::Sentry::VERSION, Perl $], $^X" );
