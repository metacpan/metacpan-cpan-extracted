use Test::More tests => 3;

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

	my @mapped = maplist($code, @digits);

	is_deeply(
		\@mapped,
		[qw(2 4 6 8)],
		"map 1-9 through incremental incrementing"
	);
}

{
	my @digits = qw(9 8 7 6 -1 -2 -3 -4);

	my @mapped = maplist($code, @digits);

	is_deeply(
		\@mapped,
		[qw(10 10 10 10)],
		"another map through incremental incrementing"
	);
}
