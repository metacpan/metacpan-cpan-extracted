use strict;
use Test;
use Math::RandomOrg qw(randnum randbyte);

BEGIN {
	plan tests => (10)
}

for my $i (1 .. 10) {
	my $octets	= randbyte( $i );
	ok( length($octets), $i );
}

