use strict;
use Test::More tests => 7;

use lib "lib";
use List::Enumerator qw/E/;

use Data::Dumper;
sub p ($) { warn Dumper shift }

sub fibonacci {
	my ($p, $i) = (0, 1);
	E(0, 1)->chain(E({
		next => sub {
			my $ret = $p + $i;
			$p = $i;
			$i = $ret;
			$ret;
		},
		rewind => sub {
			($p, $i) = (0, 1);
		}
	}));
}

is_deeply [ fibonacci->take(10) ], [
	0, 1, 1, 2, 3, 5, 8, 13, 21, 34
];


my $fib = fibonacci();

is_deeply [ $fib->take(10) ], [
	0, 1, 1, 2, 3, 5, 8, 13, 21, 34
];

is_deeply [ $fib->take(10) ], [
	0, 1, 1, 2, 3, 5, 8, 13, 21, 34
];

is_deeply [ $fib->drop(10)->take(10) ], [
	55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181
];

is_deeply [ fibonacci->drop(10)->take(10) ], [
	55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181
];

my $fib_drop10 = $fib->drop(10);

is_deeply [ $fib_drop10->take(10) ], [
	55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181
];

is_deeply [ $fib_drop10->take(10) ], [
	55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181
];

# is $fib->[10], 55;
