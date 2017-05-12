#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Locale::Wolowitz' ) || print "Bail out!
";
}

diag( "Testing Locale::Wolowitz $Locale::Wolowitz::VERSION, Perl $], $^X" );
