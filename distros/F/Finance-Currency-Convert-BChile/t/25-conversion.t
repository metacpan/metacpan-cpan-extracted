#!perl -T

use Test::More tests => 2;

BEGIN {
	use Finance::Currency::Convert::BChile;

	my $object = Finance::Currency::Convert::BChile->new();

	my $result = $object->update('500');

	is( $object->CLP2USD(20170), 40.34, 'conversion clp2usd' );
	is( $object->USD2CLP(2.13), 1065, 'conversion usd2clp' );
}

