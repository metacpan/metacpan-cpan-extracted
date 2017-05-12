#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'Log::Any::Adapter::Dupout' ) || print "Bail out!\n";
    use_ok( 'Log::Any::Adapter::Duperr' ) || print "Bail out!\n";
    use_ok( 'Log::Any::Adapter::Dupstd' ) || print "Bail out!\n";
}

diag( "Testing Log::Any::Adapter::Dupout $Log::Any::Adapter::Dupout::VERSION, Perl $], $^X" );
