#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::SimpleQuery' );
}

diag( "Testing File::SimpleQuery $File::SimpleQuery::VERSION, Perl $], $^X" );
