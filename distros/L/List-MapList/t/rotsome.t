use Test::More tests => 3;

use strict;
use warnings;

use_ok("List::MapList");

my $rotsome = [
	sub { tr/a-zA-Z/n-za-mN-ZA-M/ },
	sub { tr/a-zA-Z/n-za-mN-ZA-M/ },
	sub { $_ },
];

{
	my $string = "Too many secrets.";
	my @chars  = split //, $string;
	mapcycle($rotsome, @chars);
	is(
		join('', @chars),
		"Gbo zaal frcertf.",
		"partial rot13 encoding"
	);

	mapcycle($rotsome, @chars);
	is(
		join('', @chars),
		"Too many secrets.",
		"partial rot13 decoding"
	);
}
