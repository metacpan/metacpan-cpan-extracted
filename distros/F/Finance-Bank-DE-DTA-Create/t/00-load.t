#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::Bank::DE::DTA::Create' ) || print "Bail out!
";
}

diag( "Testing Finance::Bank::DE::DTA::Create $Finance::Bank::DE::DTA::Create::VERSION, Perl $], $^X" );
