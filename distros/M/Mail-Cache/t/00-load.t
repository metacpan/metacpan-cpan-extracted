#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mail::Cache' );
}

diag( "Testing Mail::Cache $Mail::Cache::VERSION, Perl $], $^X" );
