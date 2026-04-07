use strict;
use warnings;
use Test::More;

use Heap::PQ;

# ============================================
# Behaviour when priorities are equal
# ============================================

subtest 'duplicate numeric values - min heap' => sub {
    my $h = Heap::PQ::new('min');

    $h->push(5);
    $h->push(5);
    $h->push(5);

    is($h->size, 3, 'all three pushed');
    is($h->pop, 5, 'first pop');
    is($h->pop, 5, 'second pop');
    is($h->pop, 5, 'third pop');
    ok($h->is_empty, 'empty after all pops');
};

subtest 'duplicate numeric values - max heap' => sub {
    my $h = Heap::PQ::new('max');

    $h->push(7);
    $h->push(7);
    $h->push(7);

    is($h->size, 3, 'all three pushed');
    is($h->pop, 7, 'first pop');
    is($h->pop, 7, 'second pop');
    is($h->pop, 7, 'third pop');
    ok($h->is_empty, 'empty after all pops');
};

subtest 'mixed values with duplicates - min heap' => sub {
    my $h = Heap::PQ::new('min');

    $h->push(3);
    $h->push(1);
    $h->push(3);
    $h->push(2);
    $h->push(1);
    $h->push(2);

    my @result;
    push @result, $h->pop while !$h->is_empty;

    is_deeply(\@result, [1, 1, 2, 2, 3, 3], 'duplicates sorted correctly');
};

subtest 'mixed values with duplicates - max heap' => sub {
    my $h = Heap::PQ::new('max');

    $h->push(3);
    $h->push(1);
    $h->push(3);
    $h->push(2);
    $h->push(1);
    $h->push(2);

    my @result;
    push @result, $h->pop while !$h->is_empty;

    is_deeply(\@result, [3, 3, 2, 2, 1, 1], 'duplicates sorted correctly descending');
};

subtest 'equal priority hashrefs - all returned' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{priority} <=> $b->{priority} });

    $h->push({ name => 'a', priority => 5 });
    $h->push({ name => 'b', priority => 5 });
    $h->push({ name => 'c', priority => 5 });

    is($h->size, 3, 'all three items stored');

    my @names;
    push @names, $h->pop->{name} while !$h->is_empty;

    is(scalar(@names), 3, 'all three items returned');
    ok($h->is_empty, 'heap empty after all pops');

    # All names should be present, order among equals is unspecified
    my %seen;
    $seen{$_}++ for @names;
    is($seen{a}, 1, 'item a returned');
    is($seen{b}, 1, 'item b returned');
    is($seen{c}, 1, 'item c returned');
};

subtest 'mixed priorities with ties - correct grouping' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{priority} <=> $b->{priority} });

    $h->push({ name => 'a', priority => 1 });
    $h->push({ name => 'b', priority => 2 });
    $h->push({ name => 'c', priority => 1 });
    $h->push({ name => 'd', priority => 3 });
    $h->push({ name => 'e', priority => 2 });

    # Priority 1 items come first, then 2, then 3
    my $first  = $h->pop;
    my $second = $h->pop;
    is($first->{priority},  1, 'first item has priority 1');
    is($second->{priority}, 1, 'second item has priority 1');

    my $third  = $h->pop;
    my $fourth = $h->pop;
    is($third->{priority},  2, 'third item has priority 2');
    is($fourth->{priority}, 2, 'fourth item has priority 2');

    my $fifth = $h->pop;
    is($fifth->{priority}, 3, 'fifth item has priority 3');
    is($fifth->{name},     'd', 'only priority-3 item is d');
};

subtest 'secondary sort on tied priority' => sub {
    # Comparator breaks ties with a secondary key
    my $h = Heap::PQ::new('min', sub {
        $a->{priority} <=> $b->{priority}
            ||
        $a->{seq} <=> $b->{seq}
    });

    $h->push({ name => 'c', priority => 1, seq => 3 });
    $h->push({ name => 'a', priority => 1, seq => 1 });
    $h->push({ name => 'b', priority => 1, seq => 2 });
    $h->push({ name => 'd', priority => 2, seq => 1 });

    is($h->pop->{name}, 'a', 'tied priority, lowest seq first');
    is($h->pop->{name}, 'b', 'second by seq');
    is($h->pop->{name}, 'c', 'third by seq');
    is($h->pop->{name}, 'd', 'higher priority last');
};

subtest 'all same priority - size and peek stable' => sub {
    my $h = Heap::PQ::new('min');

    $h->push_all(4, 4, 4, 4, 4);

    is($h->size, 5, 'correct size');
    is($h->peek, 4, 'peek returns correct value');

    my $count = 0;
    $count++ while !$h->is_empty && $h->pop == 4;
    is($count, 5, 'all five equal values popped');
};

subtest 'raw array API with duplicates' => sub {
    my @arr = (3, 1, 3, 2, 1, 2);
    Heap::PQ::make_heap_min(\@arr);

    my @result;
    push @result, Heap::PQ::pop_heap_min(\@arr) while @arr;

    is_deeply(\@result, [1, 1, 2, 2, 3, 3], 'raw API handles duplicates correctly');
};

subtest 'numeric heap with duplicate NVs' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push_all(2.5, 1.0, 2.5, 1.0, 3.0);

    is($h->size, 5, 'correct size');

    my @result;
    push @result, $h->pop while !$h->is_empty;

    is_deeply(\@result, [1.0, 1.0, 2.5, 2.5, 3.0], 'nv heap handles duplicate floats');
};

done_testing;
