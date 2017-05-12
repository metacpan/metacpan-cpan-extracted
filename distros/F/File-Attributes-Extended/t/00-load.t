#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Attributes::Extended' );
}

diag( "Testing File::Attributes::Extended $File::Attributes::Extended::VERSION, Perl $], $^X" );
