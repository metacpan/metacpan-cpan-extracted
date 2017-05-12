use strict;
use Heap::Fibonacci::Fast;
use List::Util qw(max);

my $count = 100;
use Test::More tests => (2 + 2 * 10 + 10*2*100);

my $t = Heap::Fibonacci::Fast->new('max');

is($t->count(), 0);

my @all;
for my $n (1..10){
	my @elements = map { int(rand() * 10 * $count) } (1..$count);
	push @all, @elements;

	$t->key_insert(map {$_, $_} @elements);
	is($t->count(), $count * $n);
	is($t->top(), max @all);
}

@all = sort { $b <=> $a } @all;

foreach (0..10*$count-1) {
	is($t->extract_top(), $all[$_]);
	is($t->count(), 10*$count - $_ - 1);
}

is($t->count(), 0);
