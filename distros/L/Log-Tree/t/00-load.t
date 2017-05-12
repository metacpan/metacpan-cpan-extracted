#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Log::Tree' ) || print "Bail out!
";
}

diag( "Testing Log::Tree $Log::Tree::VERSION, Perl $], $^X" );
