#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'GSM::Nbit' ) || print "Bail out!
";
}

diag( "Testing GSM::Nbit $GSM::Nbit::VERSION, Perl $], $^X" );
