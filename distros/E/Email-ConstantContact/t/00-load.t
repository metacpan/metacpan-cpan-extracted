#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Email::ConstantContact' );
	use_ok( 'Email::ConstantContact::Resource' );
	use_ok( 'Email::ConstantContact::Contact' );
	use_ok( 'Email::ConstantContact::Activity' );
	use_ok( 'Email::ConstantContact::List' );
}

diag( "Testing Email::ConstantContact $Email::ConstantContact::VERSION, Perl $], $^X" );
