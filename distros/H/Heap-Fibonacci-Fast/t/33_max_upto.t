use strict;
use Heap::Fibonacci::Fast;

my $count = 100;
use Test::More tests => (2 + 10 * 4 * 2);

my $t = Heap::Fibonacci::Fast->new('max');

is($t->count(), 0);
my (@totest, @all);

@totest = $t->extract_upto($count * 100);
is(scalar @totest, 0);

my $elems = 0;
foreach my $n (1..2) {
	foreach my $m (1..10) {
		{
			my @elements = map { int(rand() * 10 * $count) } (1..$count);
			@all = sort { $b <=> $a } @all, @elements;

			$t->key_insert($_, $_) for (@elements);
			$elems += scalar @elements;

			is($t->count(), $elems);
		}

		@totest = $t->extract_upto($count * 100);
		is(scalar @totest, 0);

		my $ind = int(scalar @all / 2);
		$ind++ while $all[$ind] == $all[$ind + 1];
		@totest = $t->extract_upto($all[$ind]);
		is_deeply(\@totest, [splice @all, 0, $ind + 1]);

		$elems -= $ind + 1;
		is($t->count(), $elems);
	}

	@all = ();
	$elems = 0;
	$t->clear();
}
