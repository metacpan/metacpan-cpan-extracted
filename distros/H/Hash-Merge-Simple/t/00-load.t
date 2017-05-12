#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Hash::Merge::Simple' );
}

diag( "Testing Hash::Merge::Simple $Hash::Merge::Simple::VERSION, Perl $], $^X" );
