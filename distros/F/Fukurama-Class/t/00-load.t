#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Fukurama::Class' );
	use_ok( 'Data::Dumper' );
}

diag( "Testing Fukurama::Class $Fukurama::Class::VERSION, Perl $], $^X" );
