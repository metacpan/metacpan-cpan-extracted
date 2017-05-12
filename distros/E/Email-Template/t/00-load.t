#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Email::Template' );
}

diag( "Testing Email::Template $Email::Template::VERSION, Perl $], $^X" );
