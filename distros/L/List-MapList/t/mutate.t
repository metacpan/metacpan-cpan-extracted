use Test::More tests => 4;

use strict;
use warnings;

use_ok("List::MapList");

my $code = [
	sub { $_ = 1 },
	sub { $_ = 2 },
	sub { $_ = 3 },
	sub { $_ = 4 }
];

{
	my @digits = qw(1 2 3 4 5 6 7 8 9);

	my @mapped = mapcycle($code, @digits);

	ok(@mapped, 'map array of 1 .. 9, altering $_');

	is_deeply(
		\@mapped,
		[qw(1 2 3 4 1 2 3 4 1)],
		" ... result is correct"
	);

	is_deeply(
		\@digits,
		[qw(1 2 3 4 1 2 3 4 1)],
		" ... and original is changed, too"
	);
}
