#!/usr/bin/env perl
use strict;
use warnings;
use Benchmark qw(:all);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";

use Heap::PQ;

# Build test data: 1000 hash refs with a numeric 'priority' key
my @items = map { { priority => int(rand(10000)), id => $_ } } 1..1000;
my @prios = map { $_->{priority} } @items;

print "Benchmark: push 1000 hash refs with custom comparator, then pop all\n";
print "Comparator uses \$a/\$b\n";
print "=" x 60, "\n\n";

cmpthese(-3, {
    'custom_comparator' => sub {
        my $h = Heap::PQ::new('min', sub {
            $a->{priority} <=> $b->{priority}
        });
        $h->push($_) for @items;
        $h->pop while !$h->is_empty;
    },
    'key_path' => sub {
        my $h = Heap::PQ::new('min', 'priority');
        $h->push($_) for @items;
        $h->pop while !$h->is_empty;
    },
    'no_comparator' => sub {
        my $h = Heap::PQ::new('min');
        $h->push($_) for @prios;
        $h->pop while !$h->is_empty;
    },
});

print "\n\nBenchmark: push/pop cycle (push 1 item, pop 1 item) x 10000\n";
print "=" x 60, "\n\n";

cmpthese(-3, {
    'custom_push_pop' => sub {
        my $h = Heap::PQ::new('min', sub {
            $a->{priority} <=> $b->{priority}
        });
        for my $i (1..10000) {
            $h->push({ priority => int(rand(10000)), id => $i });
            $h->pop if $h->size > 100;
        }
    },
    'plain_push_pop' => sub {
        my $h = Heap::PQ::new('min');
        for my $i (1..10000) {
            $h->push(int(rand(10000)));
            $h->pop if $h->size > 100;
        }
    },
});
