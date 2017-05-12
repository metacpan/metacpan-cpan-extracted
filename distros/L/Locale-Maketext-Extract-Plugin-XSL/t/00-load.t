#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Locale::Maketext::Extract::Plugin::XSL' );
}

diag( "Testing Locale::Maketext::Extract::Plugin::XSL $Locale::Maketext::Extract::Plugin::XSL::VERSION, Perl $], $^X" );
