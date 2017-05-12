#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Kwiki::Formatter::Emphasis' );
}

diag( "Testing Kwiki::Formatter::Emphasis $Kwiki::Formatter::Emphasis::VERSION, Perl $], $^X" );
