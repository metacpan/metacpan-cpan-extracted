use strict;
use Test;
use Math::RandomOrg qw(randnum randbyte);

BEGIN {
	plan tests => (3*3*20)
}

foreach my $max (1, 1_000, 1_000_000_000) {
	foreach my $min (1, 0, -1_000_000_000) {
		for (1 .. 20) {
			my $number	= randnum( $min, $max );
			($number >= $min and $number <= $max) ? ok(1) : ok(0);
		}
	}
}

