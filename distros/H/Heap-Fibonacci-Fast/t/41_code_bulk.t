use strict;
use Heap::Fibonacci::Fast;
use List::Util qw(min);

my $count = 100;
use Test::More tests => (2 + 2 * 10 + 10*2*100);

sub compare { $a <=> $b }
my $t = Heap::Fibonacci::Fast->new('code', \&compare);

is($t->count(), 0);

my @all;
for my $n (1..10){
	my @elements = map { int(rand() * 10 * $count) } (1..$count);
	push @all, @elements;

	$t->insert(@elements);
	is($t->count(), $count * $n);
	is($t->top(), min @all);
}

@all = sort { $a <=> $b } @all;

foreach (0..10*$count-1) {
	is($t->extract_top(), $all[$_]);
	is($t->count(), 10*$count - $_ - 1);
}

is($t->count(), 0);
