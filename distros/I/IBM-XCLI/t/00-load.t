#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'IBM::XCLI' ) || print "Bail out!
";
}

diag( "Testing IBM::XCLI $IBM::XCLI::VERSION, Perl $], $^X" );
