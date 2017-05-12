#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hash::Abbrev' ) || print "Bail out!
";
}

diag( "Testing Hash::Abbrev $Hash::Abbrev::VERSION, Perl $], $^X" );
