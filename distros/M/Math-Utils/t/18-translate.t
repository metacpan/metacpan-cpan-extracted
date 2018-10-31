# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 16-evaluate.t'
use 5.010001;
use Test::More tests => 4;

use Math::Utils qw(:polynomial);
use Math::Complex;
use strict;
use warnings;

my $x = [8, 3, 1];

my @case = (
	[[1, 1], [12, 5, 1]],
	[[-1, 1], [6, 1, 1]],
	[[3, 1], [26, 9, 1]],
	[[-8, 0, 0, 1], [48, 0, 0, -13, 0, 0, 1]],
);

foreach (@case)
{
	my($y, $z) = @$_;

	my $ans = pl_translate($x, $y);

	is_deeply( $z, $ans,
		" y = [ " . join(", ", @$y) . " ] returned" .
		"   [ " . join(", ", @$ans) . " ]"
	);
}

1;

