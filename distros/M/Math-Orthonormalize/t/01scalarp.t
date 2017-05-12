use strict;
use warnings;

use Test::More;

use constant NUMERIC => 0;
use constant SYMBOLIC => 1;
my @test_sets = (
	[
	 [qw()],
	 [qw()],
	 NUMERIC,
	 undef
	],
	[
	 [qw(0)],
	 [qw(1 0)],
	 NUMERIC,
	 undef
	],
	[
	 [qw(0 2 3 4)],
	 [qw(1 0)],
	 NUMERIC,
	 undef
	],
	[
	 [qw(2)],
	 [qw(1)],
	 NUMERIC,
	 2
	],
	[
	 [qw(0 1)],
	 [qw(1 0)],
	 NUMERIC,
	 0
	],
	[
	 [qw(5 4 3 2 1)],
	 [qw(1 2 3 4 5)],
	 NUMERIC,
	 5+8+9+8+5
	],
	[
	 [qw(1 2 3 4)],
	 [qw(x y z)],
	 SYMBOLIC,
	 undef
	],
	[
	 [qw(1 2 3 4)],
	 [qw(a x y z)],
	 SYMBOLIC,
	 '(1*a)+(2*x)+(3*y)+(4*z)'
	],
	[
	 [qw(1 2 3 4)],
	 [qw(1 2 3 4)],
	 SYMBOLIC,
	 '(1*1)+(2*2)+(3*3)+(4*4)'
	],
);

plan tests => 1
	+ @test_sets
	+ grep {$_->[2] == SYMBOLIC and defined $_->[3]} @test_sets;
use_ok('Math::Orthonormalize', ':all');
use Math::Symbolic qw/parse_from_string/;

foreach my $set (@test_sets) {
	my ($v1, $v2) = ($set->[0], $set->[1]);
	my $type = $set->[2];
	my $result = $set->[3];
	if ($type == SYMBOLIC) {
		@$v1 = map {parse_from_string($_)} @$v1;
		@$v2 = map {parse_from_string($_)} @$v2;
		$result = parse_from_string($result) if defined $result;
	}

	my $res;
	eval {
		$res = scalar_product($v1, $v2);
	};
	if (not defined $result) {
		ok($@ and not defined $res);
	}
	else {
		if ($type == SYMBOLIC) {
			ok(not $@ and ref($res) =~ /^Math::Symbolic/);
			ok($res->is_identical($result));
		}
		else {
			ok(not $@ and defined $res and $res == $result);
		}
	}
}

