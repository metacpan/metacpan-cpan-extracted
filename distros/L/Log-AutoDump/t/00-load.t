#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::AutoDump' ) || print "Bail out!\n";
}

diag( "Testing Log::AutoDump $Log::AutoDump::VERSION, Perl $], $^X" );
