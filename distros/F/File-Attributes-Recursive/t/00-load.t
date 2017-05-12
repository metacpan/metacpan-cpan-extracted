#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Attributes::Recursive' );
}

diag( "Testing File::Attributes::Recursive $File::Attributes::Recursive::VERSION, Perl $], $^X" );
