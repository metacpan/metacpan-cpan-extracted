#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::InteractiveBrokers::API' ) || print "Bail out!
";
}

diag( "Testing Finance::InteractiveBrokers::API $Finance::InteractiveBrokers::API::VERSION, Perl $], $^X" );
