#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FormValidator::Simple::Plugin::Math' );
}

diag( "Testing FormValidator::Simple::Plugin::Math $FormValidator::Simple::Plugin::Math::VERSION, Perl $], $^X" );
