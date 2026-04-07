use strict;
use warnings;
use Test::More tests => 15;

use Heap::PQ;

# Test min-heap ordering
my $h = Heap::PQ::new('min');

$h->push(5);
$h->push(3);
$h->push(7);
$h->push(1);
$h->push(4);

is($h->size, 5, 'heap has 5 elements');

# Peek should return smallest
is($h->peek, 1, 'peek returns smallest (1)');
is($h->size, 5, 'peek does not change size');

# Pop should return in ascending order
is($h->pop, 1, 'first pop returns 1');
is($h->pop, 3, 'second pop returns 3');
is($h->pop, 4, 'third pop returns 4');
is($h->pop, 5, 'fourth pop returns 5');
is($h->pop, 7, 'fifth pop returns 7');
is($h->pop, undef, 'sixth pop returns undef');

# Test with duplicates
$h->push(5);
$h->push(5);
$h->push(3);
$h->push(5);

is($h->pop, 3, 'pop with duplicates returns 3 first');
is($h->pop, 5, 'second pop returns 5');
is($h->pop, 5, 'third pop returns 5');
is($h->pop, 5, 'fourth pop returns 5');

# Test with negative numbers
$h->push(-5);
$h->push(0);
$h->push(-10);
$h->push(5);

is($h->pop, -10, 'smallest negative first');
is($h->pop, -5, 'second smallest');
