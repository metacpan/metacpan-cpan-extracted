#!perl -T

use Test::More tests => 1;

BEGIN {
	use Finance::Currency::Convert::BChile;

	my $object = Finance::Currency::Convert::BChile->new();

	isa_ok( $object, 'Finance::Currency::Convert::BChile' );
}

