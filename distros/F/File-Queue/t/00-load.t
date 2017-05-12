#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'File::Queue' );
}

diag( "Testing File::Queue $File::Queue::VERSION, Perl $], $^X" );
