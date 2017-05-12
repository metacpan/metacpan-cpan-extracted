use strict;
use Heap::Fibonacci::Fast;

my $count = 100;
use Test::More tests => (6 + 9 * 100);

sub compare { $a <=> $b }
my $t = Heap::Fibonacci::Fast->new('code', \&compare);

#initial state
is($t->count(), 0);
is($t->top(), undef);

#array context add
my @elements = map { int(rand() * 10 * $count) } (1..$count);
my $min = $count * 100;
foreach (@elements) {
	ok($t->insert($_));

	$min = $min < $_ ? $min : $_;
	is($t->top(), $min);
}
is($t->count(), $count);

#void context add
my @add = map { int(rand() * 10 * $count) } (1..$count);
foreach (@add) {
	$t->insert($_);

	$min = $min < $_ ? $min : $_;
	is($t->top(), $min);
}

is($t->count(), 2 * $count);

my @sorted = sort { $a <=> $b } @elements, @add;

foreach (0..2*$count-1) {
	is($t->top(), $sorted[$_]);
	is($t->extract_top(), $sorted[$_]);
	is($t->count(), 2*$count - $_ - 1);
}

#again initial
is($t->count(), 0);
is($t->top(), undef);
