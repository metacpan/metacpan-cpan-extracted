#!/usr/bin/perl -T

use Test::More;

BEGIN {

	use_ok( 'Lithium::WebDriver' );
	use_ok( 'Lithium::WebDriver::Utils' );
	use_ok( 'Lithium::WebDriver::Phantom' );

}

diag( "Testing Lithium::WebDriver $Lithium::WebDriver::VERSION, Perl $], $^X" );
done_testing;
