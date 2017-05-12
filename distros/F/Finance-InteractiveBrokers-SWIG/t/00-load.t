#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::SWIG' ) || print "Bail out!
";
}

diag( "Testing Finance::InteractiveBrokers::SWIG $Finance::InteractiveBrokers::SWIG::VERSION, Perl $], $^X" );
