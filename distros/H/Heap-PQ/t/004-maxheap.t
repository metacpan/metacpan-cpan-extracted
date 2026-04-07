use strict;
use warnings;
use Test::More tests => 12;

use Heap::PQ;

# Test max-heap ordering
my $h = Heap::PQ::new('max');

$h->push(5);
$h->push(3);
$h->push(7);
$h->push(1);
$h->push(4);

is($h->size, 5, 'heap has 5 elements');

# Peek should return largest
is($h->peek, 7, 'peek returns largest (7)');

# Pop should return in descending order
is($h->pop, 7, 'first pop returns 7');
is($h->pop, 5, 'second pop returns 5');
is($h->pop, 4, 'third pop returns 4');
is($h->pop, 3, 'fourth pop returns 3');
is($h->pop, 1, 'fifth pop returns 1');

# Test with negative numbers
$h->push(-5);
$h->push(0);
$h->push(-10);
$h->push(5);

is($h->pop, 5, 'largest positive first');
is($h->pop, 0, 'zero second');
is($h->pop, -5, '-5 third');
is($h->pop, -10, '-10 last');

# Test floats
$h->push(3.14);
$h->push(2.71);
$h->push(1.41);

is($h->pop, 3.14, 'float comparison works');
