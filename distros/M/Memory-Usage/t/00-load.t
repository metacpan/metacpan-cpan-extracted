#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Memory::Usage' ) || print "Bail out!
";
}

diag( "Testing Memory::Usage $Memory::Usage::VERSION, Perl $], $^X" );
