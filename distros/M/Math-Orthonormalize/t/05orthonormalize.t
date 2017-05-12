use strict;
use warnings;

use Test::More;

use Math::Symbolic qw/:all/;

my @sets = (
	{
		is_nasty => 0,
		in => [
		 [qw(2)],
		],
		out => [
		 [qw(1)],
		],
	},
	{
		is_nasty => 0,
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
		is_nasty => 1,
		in => [
		 [qw(2 1)],
		 [qw(1 1)],
		],
		out => [
		 [qw(0.894427190999916 0.447213595499958)],
		 [qw(-0.447213595499958 0.894427190999916)],
		],
	},
);

plan tests => 1 + @sets*2;

use_ok('Math::Orthonormalize', ':all');

foreach my $s (@sets) {
	my @res;
	eval {
		@res = orthonormalize(@{$s->{in}});
	};
	ok(not $@);
	if ($s->{is_nasty}) {
		TODO: {
			local $TODO = 'Comparing floats is comparing ' .
				'apples to oranges.';
			is_deeply(\@res, $s->{out});
		}
	}
	else {
		is_deeply(\@res, $s->{out});
	}
}

