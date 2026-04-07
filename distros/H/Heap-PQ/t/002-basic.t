use strict;
use warnings;
use Test::More tests => 12;

use Heap::PQ;

# Test constructor
my $h = Heap::PQ::new('min');
isa_ok($h, 'Heap::PQ', 'new returns heap object');

# Test type
is($h->type, 'min', 'type returns min');

my $max = Heap::PQ::new('max');
is($max->type, 'max', 'type returns max');

# Test is_empty on new heap
ok($h->is_empty, 'new heap is empty');

# Test size on new heap
is($h->size, 0, 'new heap has size 0');

# Test push increases size
$h->push(5);
is($h->size, 1, 'size is 1 after push');
ok(!$h->is_empty, 'heap is not empty after push');

# Test clear
$h->push(10);
$h->push(15);
is($h->size, 3, 'size is 3 after more pushes');
$h->clear;
is($h->size, 0, 'size is 0 after clear');
ok($h->is_empty, 'heap is empty after clear');

# Test peek on empty heap
is($h->peek, undef, 'peek on empty heap returns undef');

# Test pop on empty heap
is($h->pop, undef, 'pop on empty heap returns undef');
