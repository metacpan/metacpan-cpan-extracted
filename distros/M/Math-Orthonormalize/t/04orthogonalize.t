use strict;
use warnings;

use Test::More;

use Math::Symbolic qw/:all/;

my @sets = (
	{
		in => [
		 [qw(2)],
		],
		out => [
		 [qw(2)],
		],
	},
	{
		in => [
		 [qw(1 0)],
		 [qw(0 1)],
		],
		out => [
		 [qw(1 0)],
		 [qw(0 1)],
		],
	},
	{
		in => [
		 [qw(2 1)],
		 [qw(1 1)],
		],
		out => [
		 [qw(2 1)],
		 [qw(-0.2 0.4)],
		],
	},
);

plan tests => 1 + @sets*2;

use_ok('Math::Orthonormalize', ':all');

foreach my $s (@sets) {
	my @res;
	eval {
		@res = orthogonalize(@{$s->{in}});
	};
	ok(not $@);
	is_deeply(\@res, $s->{out});
}

