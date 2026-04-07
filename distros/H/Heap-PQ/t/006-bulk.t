use strict;
use warnings;
use Test::More tests => 8;

use Heap::PQ;

# Test push_all
my $h = Heap::PQ::new('min');
$h->push_all(5, 3, 7, 1, 4);

is($h->size, 5, 'push_all adds all elements');
is($h->pop, 1, 'elements are properly heapified');
is($h->pop, 3, 'second element');
is($h->pop, 4, 'third element');

# Test method chaining
my $h2 = Heap::PQ::new('min');
$h2->push(10)->push(5)->push(15);

is($h2->size, 3, 'chained push works');
is($h2->peek, 5, 'chained elements heapified');

# Test larger dataset
my $h3 = Heap::PQ::new('min');
my @numbers = (50, 30, 70, 10, 40, 60, 20, 80, 90, 100);
$h3->push_all(@numbers);

is($h3->size, 10, 'larger dataset size correct');

my @sorted;
while (!$h3->is_empty) {
    push @sorted, $h3->pop;
}

my @expected = sort { $a <=> $b } @numbers;
is_deeply(\@sorted, \@expected, 'heap sort produces correct order');
