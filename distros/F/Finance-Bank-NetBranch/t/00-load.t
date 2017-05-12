#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::Bank::NetBranch' );
}

diag( "Testing Finance::Bank::NetBranch $Finance::Bank::NetBranch::VERSION, Perl $], $^X" );
