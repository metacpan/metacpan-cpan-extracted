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

# Run a warmup to initialize any one-time allocations (registry, mutex, etc.)
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

# Test 7: remove_from_start operation
subtest 'remove_from_start operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(2);
            $list->add(3);
            my $v1 = $list->remove_from_start();
            my $v2 = $list->remove_from_start();
            $list->destroy();
        }
    }, 'remove_from_start does not leak');
};

# Test 8: remove_from_end operation
subtest 'remove_from_end operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(2);
            $list->add(3);
            my $v1 = $list->remove_from_end();
            my $v2 = $list->remove_from_end();
            $list->destroy();
        }
    }, 'remove_from_end does not leak');
};

# Test 9: Navigation operations (prev/next/start/end)
subtest 'navigation operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(2);
            $list->add(3);
            $list->start();
            $list->next();
            $list->prev();
            $list->end();
            $list->destroy();
        }
    }, 'navigation operations do not leak');
};

# Test 10: bulk_add operation
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

# Test 11: Chained method calls
subtest 'chained method calls' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->add(1)->add(2)->add(3)->start()->next()->end()->prev();
            $list->destroy();
        }
    }, 'chained operations do not leak');
};

# Test 12: data() getter/setter
subtest 'data getter/setter' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new("initial");
            my $d = $list->data();
            $list->data("new value");
            $d = $list->data();
            $list->destroy();
        }
    }, 'data getter/setter does not leak');
};

# Test 13: Rapid create/destroy cycles
subtest 'rapid create/destroy cycles' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..500) {
            my $list = Doubly->new($_);
            $list->destroy();
        }
    }, 'rapid create/destroy does not leak');
};

# Test 14: Complete list removal via remove_from_start
subtest 'complete removal from start' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..50) {
            my $list = Doubly->new();
            $list->add($_) for 1..10;
            while ($list->length > 0) {
                $list->remove_from_start();
            }
            $list->destroy();
        }
    }, 'complete removal from start does not leak');
};

# Test 15: Complete list removal via remove_from_end
subtest 'complete removal from end' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..50) {
            my $list = Doubly->new();
            $list->add($_) for 1..10;
            while ($list->length > 0) {
                $list->remove_from_end();
            }
            $list->destroy();
        }
    }, 'complete removal from end does not leak');
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

# Test 17: ID reuse after destruction
subtest 'ID reuse after destruction' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my @lists;
            push @lists, Doubly->new($_) for 1..10;
            $_->destroy() for @lists;
        }
    }, 'ID reuse after destruction does not leak');
};

# Test 18: remove (current node) operation
subtest 'remove current node' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->bulk_add(1, 2, 3, 4, 5);
            $list->start->next->next;  # Move to middle
            my $v = $list->remove();
            $list->destroy();
        }
    }, 'remove current node does not leak');
};

# Test 19: remove_from_pos operation
subtest 'remove_from_pos operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->bulk_add(1, 2, 3, 4, 5);
            my $v1 = $list->remove_from_pos(2);
            my $v2 = $list->remove_from_pos(0);
            $list->destroy();
        }
    }, 'remove_from_pos does not leak');
};

# Test 20: insert_before operation
subtest 'insert_before operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(2);
            $list->add(4);
            $list->start;
            $list->insert_before(1);
            $list->end;
            $list->insert_before(3);
            $list->destroy();
        }
    }, 'insert_before does not leak');
};

# Test 21: insert_after operation
subtest 'insert_after operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(3);
            $list->start;
            $list->insert_after(2);
            $list->end;
            $list->insert_after(4);
            $list->destroy();
        }
    }, 'insert_after does not leak');
};

# Test 22: insert_at_start operation
subtest 'insert_at_start operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(3);
            $list->insert_at_start(2);
            $list->insert_at_start(1);
            $list->insert_at_start(0);
            $list->destroy();
        }
    }, 'insert_at_start does not leak');
};

# Test 23: insert_at_end operation
subtest 'insert_at_end operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->insert_at_end(2);
            $list->insert_at_end(3);
            $list->insert_at_end(4);
            $list->destroy();
        }
    }, 'insert_at_end does not leak');
};

# Test 24: insert_at_pos operation
subtest 'insert_at_pos operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new(1);
            $list->add(4);
            $list->insert_at_pos(1, 2);
            $list->insert_at_pos(2, 3);
            $list->destroy();
        }
    }, 'insert_at_pos does not leak');
};

# Test 25: find operation
subtest 'find operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->bulk_add(10, 20, 30, 40, 50);
            my $result = $list->find(sub { $_[0] == 30 });
            $result = $list->find(sub { $_[0] == 999 });  # Not found
            $list->destroy();
        }
    }, 'find does not leak');
};

# Test 26: insert with callback operation
subtest 'insert with callback operation' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..100) {
            my $list = Doubly->new();
            $list->bulk_add(10, 30, 50);
            $list->insert(sub { $_[0] > 20 }, 20);
            $list->insert(sub { $_[0] > 40 }, 40);
            $list->destroy();
        }
    }, 'insert with callback does not leak');
};

# Test 27: Mixed insert operations
subtest 'mixed insert operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..50) {
            my $list = Doubly->new();
            $list->add(5);
            $list->insert_at_start(1);
            $list->insert_at_end(10);
            $list->start->next;
            $list->insert_before(4);
            $list->insert_after(6);
            $list->insert_at_pos(1, 2);
            $list->destroy();
        }
    }, 'mixed insert operations do not leak');
};

# Test 28: Mixed remove operations
subtest 'mixed remove operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..50) {
            my $list = Doubly->new();
            $list->bulk_add(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
            $list->remove_from_start();
            $list->remove_from_end();
            $list->remove_from_pos(3);
            $list->start->next->next;
            $list->remove();
            $list->destroy();
        }
    }, 'mixed remove operations do not leak');
};

# Test 29: Complete removal via remove()
subtest 'complete removal via remove' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..50) {
            my $list = Doubly->new();
            $list->bulk_add(1, 2, 3, 4, 5);
            while ($list->length > 0) {
                $list->start;
                $list->remove();
            }
            $list->destroy();
        }
    }, 'complete removal via remove does not leak');
};

# Test 30: Stress test with all operations
subtest 'stress test all operations' => sub {
    plan tests => 1;
    no_leaks_ok(sub {
        for (1..20) {
            my $list = Doubly->new();
            $list->bulk_add(1..10);
            $list->insert_at_start(0);
            $list->insert_at_end(11);
            $list->find(sub { $_[0] == 5 });
            $list->insert_before(4.5);
            $list->insert_after(5.5);
            $list->remove_from_start();
            $list->remove_from_end();
            $list->start->next->next;
            $list->remove();
            $list->remove_from_pos(2);
            $list->insert(sub { $_[0] > 7 }, 6.5);
            $list->destroy();
        }
    }, 'stress test all operations does not leak');
};

done_testing();
