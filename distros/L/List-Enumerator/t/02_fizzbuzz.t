use strict;
use Test::More tests => 1;

use lib "lib";
use List::Enumerator qw/E/;

use Data::Dumper;
sub p ($) { warn Dumper shift }

my $fizzbuzz =
	E(1)->countup
		->zip(
			E("", "", "Fizz")->cycle,
			E("", "", "", "", "Buzz")->cycle
		)
		->map(sub {
			my ($n, $fizz, $buzz) = @$_;
			$fizz . $buzz || $n;
		});

# E(1)->countup
#     => [1, 2, 3, 4, 5 ....]
# E("", "", "Fizz")->cycle
#     => ["", "", "Fizz", "", "", "Fizz", ...]
# zip
#  [ [1, "", ""], [2, "", ""], [3, "Fizz", ""] ]

is_deeply $fizzbuzz->take(20)->to_a, [
	1,
	2,
	'Fizz',
	4,
	'Buzz',
	'Fizz',
	7,
	8,
	'Fizz',
	'Buzz',
	11,
	'Fizz',
	13,
	14,
	'FizzBuzz',
	16,
	17,
	'Fizz',
	19,
	'Buzz'
];

