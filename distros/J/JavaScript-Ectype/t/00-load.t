#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JavaScript::Ectype' ) || print "Bail out!
";
}

diag( "Testing JavaScript::Ectype $JavaScript::Ectype::VERSION, Perl $], $^X" );
