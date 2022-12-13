#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Finance::SEC::EdgarData' ) || print "Bail out!\n";
}

diag( "Testing Finance::SEC::EdgarData $Finance::SEC::EdgarData::VERSION, Perl $], $^X" );
