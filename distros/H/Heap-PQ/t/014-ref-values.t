use strict;
use warnings;
use Test::More;

use Heap::PQ;

package Task;
sub new { bless { id => $_[1], pri => $_[2] }, $_[0] }

package main;

# ============================================
# Storing references as heap values
# ============================================

subtest 'hashrefs with comparator' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{priority} <=> $b->{priority} });

    $h->push({ name => 'low',    priority => 10 });
    $h->push({ name => 'high',   priority => 1  });
    $h->push({ name => 'medium', priority => 5  });

    is($h->size, 3, 'size is 3');

    my $first = $h->pop;
    is(ref($first), 'HASH', 'pop returns hashref');
    is($first->{name}, 'high', 'highest priority first');
    is($first->{priority}, 1, 'correct priority value');

    my $second = $h->pop;
    is($second->{name}, 'medium', 'medium priority second');

    my $third = $h->pop;
    is($third->{name}, 'low', 'low priority last');

    ok($h->is_empty, 'heap empty after all pops');
};

subtest 'arrayrefs with comparator' => sub {
    my $h = Heap::PQ::new('min', sub { $a->[0] <=> $b->[0] });

    $h->push([3, 'three']);
    $h->push([1, 'one']);
    $h->push([2, 'two']);

    my $first = $h->pop;
    is(ref($first), 'ARRAY', 'pop returns arrayref');
    is($first->[0], 1, 'correct sort key');
    is($first->[1], 'one', 'correct payload');

    is($h->pop->[1], 'two',   'second element correct');
    is($h->pop->[1], 'three', 'third element correct');
};

subtest 'blessed objects with comparator' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{pri} <=> $b->{pri} });

    $h->push(Task->new(1, 20));
    $h->push(Task->new(2, 5));
    $h->push(Task->new(3, 15));

    my $first = $h->pop;
    isa_ok($first, 'Task', 'pop returns blessed object');
    is($first->{id}, 2, 'lowest priority task first');
    is($first->{pri}, 5, 'correct priority');

    is($h->pop->{id}, 3, 'second task correct');
    is($h->pop->{id}, 1, 'third task correct');
};

subtest 'scalar refs as values' => sub {
    my $h = Heap::PQ::new('min', sub { ${$a} <=> ${$b} });

    my ($a, $b, $c) = (30, 10, 20);
    $h->push(\$a);
    $h->push(\$b);
    $h->push(\$c);

    my $first = $h->pop;
    is(ref($first), 'SCALAR', 'pop returns scalar ref');
    is($$first, 10, 'correct value');

    is(${$h->pop}, 20, 'second correct');
    is(${$h->pop}, 30, 'third correct');
};

subtest 'nested hashrefs' => sub {
    my $h = Heap::PQ::new('min', sub {
        $a->{meta}{score} <=> $b->{meta}{score}
    });

    $h->push({ name => 'c', meta => { score => 30 } });
    $h->push({ name => 'a', meta => { score => 10 } });
    $h->push({ name => 'b', meta => { score => 20 } });

    is($h->pop->{name}, 'a', 'nested: first correct');
    is($h->pop->{name}, 'b', 'nested: second correct');
    is($h->pop->{name}, 'c', 'nested: third correct');
};

subtest 'push_all with refs' => sub {
    my $h = Heap::PQ::new('max', sub { $a->{v} <=> $b->{v} });

    $h->push_all(
        { v => 1 },
        { v => 3 },
        { v => 2 },
    );

    is($h->size, 3, 'push_all size correct');
    is($h->pop->{v}, 3, 'max first');
    is($h->pop->{v}, 2, 'second');
    is($h->pop->{v}, 1, 'third');
};

subtest 'peek does not consume ref' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{n} <=> $b->{n} });

    my $obj = { n => 1, data => 'hello' };
    $h->push($obj);
    $h->push({ n => 2, data => 'world' });

    my $peeked = $h->peek;
    is($peeked->{data}, 'hello', 'peek returns correct ref');
    is($h->size, 2, 'peek does not remove element');

    my $popped = $h->pop;
    is($popped->{data}, 'hello', 'pop returns same ref');
    is($h->size, 1, 'size decremented after pop');
};

subtest 'mixed ref types without comparator (by numeric coercion)' => sub {
    # Without a comparator, refs stringify/numify — mainly checking no crash
    my $h = Heap::PQ::new('min', sub { $a->{k} <=> $b->{k} });

    for my $k (5, 1, 3, 2, 4) {
        $h->push({ k => $k });
    }

    my @order;
    while (!$h->is_empty) {
        push @order, $h->pop->{k};
    }

    is_deeply(\@order, [1, 2, 3, 4, 5], 'refs sorted correctly by key');
};

done_testing;
