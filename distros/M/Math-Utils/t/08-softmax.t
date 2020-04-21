# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 20-softmax.t'
use 5.010001;
use Test::More tests => 2;

use Math::Utils qw(:utility :compare);
use strict;
use warnings;

my $fltcmp = generate_fltcmp(1e-7);

my @trials = (
	[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	[0, 1, 2, 3, 4, 5, 6, 7, 8, 7, 6, 5, 4, 3, 2, 1 ],
);

for my $t (@trials)
{
	my @probs = softmax(@$t);

	ok( (&$fltcmp(fsum(@probs), 1.0) == 0),
		"   softmax(" . join(", ", @$t) . ") returns\n" .
		"   [" . join(", ", @probs)  . "], did not sum to 1.0\n"
	);
}

