use Test::More tests => 4;

use strict;
use warnings;

use_ok("List::MapList");

my $code = [
	sub { $_ + 1 },
	sub { $_ + 2 },
	sub { $_ + 3 },
	sub { $_ + 4 }
];

{
	my @digits = qw(1 2 3 4 5 6 7 8 9);

	my @mapped = mapcycle($code, @digits);

	is_deeply(
		\@mapped,
		[qw(2 4 6 8 6 8 10 12 10)],
		"map 1-9 through incremental incrementing"
	);
}

{
	my @digits = qw(9 8 7 6 -1 -2 -3 -4);

	my @mapped = mapcycle($code, @digits);

	is_deeply(
		\@mapped,
		[qw(10 10 10 10 0 0 0 0)],
		"another map through incremental incrementing"
	);
}

{
	my $rotsome = [
		sub { tr/a-zA-Z/n-za-mN-ZA-M/; $_ },
		sub { tr/a-zA-Z/n-za-mN-ZA-M/; $_ },
		sub { $_ },
	];

	my $plaintext  = "Too many secrets.";
	my $cyphertext = join '', mapcycle($rotsome, split //, $plaintext);

	is($cyphertext, "Gbo zaal frcertf.", "correct cyphertext");
}
