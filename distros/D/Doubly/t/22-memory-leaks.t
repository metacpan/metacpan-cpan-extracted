#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Skip if Test::LeakTrace is not available
eval { require Test::LeakTrace; 1 };
if ($@) {
    plan skip_all => 'Test::LeakTrace required for memory leak tests';
}
Test::LeakTrace->import('no_leaks_ok', 'leaked_count');

use_ok('Doubly');

# Run a warmup to initialize any one-time allocations
{
    my $warmup = Doubly->new();
    $warmup->destroy();
}

# Test 1: Empty list creation and destruction
subtest 'empty list create/destroy' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        my $list = Doubly->new();
        $list->destroy();
    }, 'empty list does not leak');
};

# Test 2: List with initial value
subtest 'list with initial scalar' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(42);
            $list->destroy();
        }
    }, 'list with scalar value does not leak');
};

# Test 3: List with string value
subtest 'list with string value' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new("hello world");
            $list->destroy();
        }
    }, 'list with string value does not leak');
};

# Test 4: Single add operation
subtest 'single add operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->add(1);
            $list->destroy();
        }
    }, 'single add does not leak');
};

# Test 5: Multiple add operations
subtest 'multiple add operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->add($_) for 1..5;
            $list->destroy();
        }
    }, 'multiple adds do not leak');
};

# Test 6: Large list
subtest 'large list with many nodes' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..10) {
            my $list = Doubly->new();
            $list->add($_) for 1..100;
            $list->destroy();
        }
    }, 'large list does not leak');
};

# Test 7: Complex reference data (hashrefs)
subtest 'hashref data' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new({a => 1, b => 2});
            $list->destroy();
        }
    }, 'hashref data does not leak');
};

# Test 8: Complex reference data (arrayrefs)
subtest 'arrayref data' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new([1, 2, 3, 4, 5]);
            $list->destroy();
        }
    }, 'arrayref data does not leak');
};

# Test 9: Mixed complex data
subtest 'mixed complex data' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new({a => 1});
            $list->add([1, 2, 3]);
            $list->add({b => 2, c => [1, 2, 3]});
            $list->destroy();
        }
    }, 'mixed complex data does not leak');
};

# Test 10: remove() operation (which returns data)
subtest 'remove operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(42);
            $list->add(43);
            $list->add(44);
            my $val = $list->remove();
            $list->destroy();
        }
    }, 'remove operation does not leak');
};

# Test 11: remove_from_start/remove_from_end operations
subtest 'remove from start/end operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(2);
            $list->add(3);
            my $v1 = $list->remove_from_start();
            my $v2 = $list->remove_from_end();
            $list->destroy();
        }
    }, 'remove_from_start/end operations do not leak');
};

# Test 12: insert_at_start/insert_at_end operations
subtest 'insert_at_start/end operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->insert_at_start(0);
            $list->insert_at_end(2);
            $list->destroy();
        }
    }, 'insert_at_start/end operations do not leak');
};

# Test 13: insert_before/after operations
subtest 'insert_before/after operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..50) {
            my $list = Doubly->new(1);
            $list->insert_after(2);
            $list->insert_before(0);
            $list->insert_at_start(-1);
            $list->insert_at_end(3);
            $list->destroy();
        }
    }, 'insert operations do not leak');
};

# Test 14: Navigation operations (prev/next/start/end)
subtest 'navigation operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(2);
            $list->add(3);
            $list = $list->next();
            $list = $list->prev();
            $list = $list->start();
            $list = $list->end();
            $list->destroy();
        }
    }, 'navigation operations do not leak');
};

# Test 15: bulk_add operation
subtest 'bulk_add operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->bulk_add(1, 2, 3, 4, 5);
            $list->destroy();
        }
    }, 'bulk_add does not leak');
};

# Test 16: Verify no accumulating leaks over many iterations
subtest 'no accumulating leaks' => sub {
    plan tests => 1;
    my $baseline = leaked_count(sub {
        for (1..10) {
            my $list = Doubly->new($_);
            $list->add($_*2) for 1..5;
            $list->destroy();
        }
    });
    
    my $larger = leaked_count(sub {
        for (1..100) {
            my $list = Doubly->new($_);
            $list->add($_*2) for 1..5;
            $list->destroy();
        }
    });
    
    my $ratio = $larger / ($baseline || 1);
    ok($ratio < 2, "leak count does not scale with iterations (ratio: $ratio)")
        or diag("baseline=$baseline, larger=$larger - indicates per-iteration leak");
};

done_testing();
