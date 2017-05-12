#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Locale::BR' ) || print "Bail out!
";
}

diag( "Testing Locale::BR $Locale::BR::VERSION, Perl $], $^X" );
