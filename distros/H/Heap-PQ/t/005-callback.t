use strict;
use warnings;
use Test::More tests => 10;

use Heap::PQ;

# Test custom comparator with hash refs
my $h = Heap::PQ::new('min', sub {
    $a->{priority} <=> $b->{priority};
});

$h->push({ name => 'low',    priority => 10 });
$h->push({ name => 'high',   priority => 1  });
$h->push({ name => 'medium', priority => 5  });

my $top = $h->pop;
is($top->{name}, 'high', 'custom comparator: highest priority first');
is($top->{priority}, 1, 'priority is 1');

$top = $h->pop;
is($top->{name}, 'medium', 'second is medium');

$top = $h->pop;
is($top->{name}, 'low', 'third is low');

# Test max-heap with custom comparator
my $max = Heap::PQ::new('max', sub {
    $a->{score} <=> $b->{score};
});

$max->push({ player => 'Alice', score => 100 });
$max->push({ player => 'Bob',   score => 250 });
$max->push({ player => 'Carol', score => 175 });

$top = $max->pop;
is($top->{player}, 'Bob', 'max heap: Bob has highest score');
is($top->{score}, 250, 'score is 250');

$top = $max->pop;
is($top->{player}, 'Carol', 'second is Carol');

# Test string comparison
my $str_heap = Heap::PQ::new('min', sub {
    $a cmp $b;
});

$str_heap->push('banana');
$str_heap->push('apple');
$str_heap->push('cherry');

is($str_heap->pop, 'apple', 'string comparison: apple first');
is($str_heap->pop, 'banana', 'banana second');
is($str_heap->pop, 'cherry', 'cherry third');
