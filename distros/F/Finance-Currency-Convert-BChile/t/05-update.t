#!perl -T

use Test::More tests => 1;

BEGIN {
	use Finance::Currency::Convert::BChile;

	my $object = Finance::Currency::Convert::BChile->new();

	my $result = $object->update('500');

	is( $result, 1, 'Update' );
}

