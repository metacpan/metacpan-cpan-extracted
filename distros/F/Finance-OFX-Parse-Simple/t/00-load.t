#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::OFX::Parse::Simple' );
}

diag( "Testing Finance::OFX::Parse::Simple $Finance::OFX::Parse::Simple::VERSION, Perl $], $^X" );
