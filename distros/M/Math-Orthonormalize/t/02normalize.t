use strict;
use warnings;

use Test::More;


my @vec = (
	[
	 [qw(0 0 0)],
	 undef
	],
	[
	 [qw(1)],
	 [1]
	],
	[
	 [qw(0 1 0)],
	 [qw(0 1 0)]
	],
	[
	 [qw(2 2 2 2)],
	 [qw(0.5 0.5 0.5 0.5)]
	],
);

plan tests => 1 + @vec + grep {defined $_->[1]} @vec;

use_ok('Math::Orthonormalize', ':all');

foreach my $v (@vec) {
	my $res;
	eval {
		$res = normalize($v->[0]);
	};
	if (not defined $v->[1]) {
		ok($@ and not defined $res);
	}
	else {
		ok(not $@ and defined $res);
		is_deeply($res, $v->[1]);
	}
}

