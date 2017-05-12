use strict;
use List::Util qw(max);
use Heap::Fibonacci::Fast;

my $count = 100;
use Test::More tests => (10*(2*100 + 3));

my $t = Heap::Fibonacci::Fast->new('max');

foreach (1..10) {
	my @data = map { int(rand() * 10 * $count) } (1..$count);
	my @elements = $t->key_insert(map { $_, $_ } @data);

	is(scalar @data, scalar @elements);
	is($t->count(), $count);

	while (scalar @data){
		my $ind = int(rand() * scalar @data);

		$t->remove($elements[$ind]);
		splice @data, $ind, 1;
		splice @elements, $ind, 1;

		is($t->count(), scalar @data);
		is($t->top(), max @data);
	}

	is($t->count(), 0);
}
