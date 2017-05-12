#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::FIX' ) || print "Bail out!
";
}

diag( "Testing Finance::FIX $Finance::FIX::VERSION, Perl $], $^X" );
