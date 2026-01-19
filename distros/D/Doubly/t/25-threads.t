#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Thread tests for Doubly - the thread-safe shared list module

BEGIN {
    eval {
        require threads;
        require threads::shared;
    };
    if ($@) {
        plan skip_all => 'threads not available';
    }
}

use threads;
use threads::shared;

use_ok('Doubly');

# Test 1: Basic Shared operations work
subtest 'Basic Doubly operations' => sub {
    plan tests => 10;
    
    my $list = Doubly->new();
    ok($list, 'List created');
    is($list->length, 0, 'Empty list has length 0');
    
    $list->add(1);
    $list->add(2);
    $list->add(3);
    is($list->length, 3, 'Length after adding 3 items');
    
    $list = $list->start;
    is($list->data, 1, 'start returns first item');
    ok($list->is_start, 'is_start true at start');
    
    $list = $list->end;
    is($list->data, 3, 'end returns last item');
    ok($list->is_end, 'is_end true at end');
    
    $list = $list->prev;
    is($list->data, 2, 'prev moves backward');
    
    $list = $list->next;
    is($list->data, 3, 'next moves forward');
    
    $list->destroy;
    ok(1, 'destroy completed');
};

# Test 2: Thread-local lists (each thread has its own)
subtest 'Thread-local lists' => sub {
    plan tests => 1;
    
    my @threads;
    my @results :shared;
    
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $list = Doubly->new();
            for my $j (1..100) {
                $list->add($j);
            }
            return $list->length;
        });
    }
    
    for my $t (@threads) {
        push @results, $t->join;
    }
    
    is_deeply(\@results, [100, 100, 100, 100], 'each thread got 100 items');
};

# Test 3: Shared list - concurrent reads
subtest 'Shared list - concurrent reads' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    for my $i (1..100) {
        $list->add($i);
    }
    
    my @threads;
    my @results :shared;
    
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $len = $list->length;
            return $len;
        });
    }
    
    for my $t (@threads) {
        push @results, $t->join;
    }
    
    is_deeply(\@results, [100, 100, 100, 100], 'all threads see 100 items');
};

# Test 4: Shared list - concurrent adds
subtest 'Shared list - concurrent adds' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    
    my @threads;
    for my $i (1..4) {
        push @threads, threads->create(sub {
            for my $j (1..25) {
                $list->add("${i}_${j}");
            }
            return 1;
        });
    }
    
    for my $t (@threads) {
        $t->join;
    }
    
    is($list->length, 100, '100 items added by 4 threads');
};

# Test 5: Shared list - concurrent removes
subtest 'Shared list - concurrent removes' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    for my $i (1..100) {
        $list->add($i);
    }
    
    my @threads;
    for my $i (1..4) {
        push @threads, threads->create(sub {
            my $count = 0;
            for my $j (1..25) {
                my $val = $list->remove_from_start;
                $count++ if defined $val;
            }
            return $count;
        });
    }
    
    my $total_removed = 0;
    for my $t (@threads) {
        $total_removed += $t->join;
    }
    
    is($total_removed, 100, 'all items removed');
};

# Test 6: Rapid create and destroy
subtest 'Rapid create and destroy in threads' => sub {
    plan tests => 1;
    
    my @threads;
    for my $i (1..4) {
        push @threads, threads->create(sub {
            for my $j (1..50) {
                my $list = Doubly->new();
                $list->add(1);
                $list->add(2);
                $list->destroy;
            }
            return 1;
        });
    }
    
    my $ok = 1;
    for my $t (@threads) {
        $ok = 0 unless $t->join;
    }
    
    ok($ok, 'rapid create/destroy completed');
};

# Test 7: Mixed concurrent operations
subtest 'Mixed concurrent operations' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    
    my @threads;
    
    # Adder threads
    for my $i (1..2) {
        push @threads, threads->create(sub {
            for my $j (1..50) {
                $list->add("add_${i}_${j}");
            }
            return 'add';
        });
    }
    
    # Remover threads
    for my $i (1..2) {
        push @threads, threads->create(sub {
            my $removed = 0;
            for my $j (1..25) {
                my $val = $list->remove_from_end;
                $removed++ if defined $val && $val ne '';
            }
            return $removed;
        });
    }
    
    my ($adds, $removes) = (0, 0);
    for my $t (@threads) {
        my $result = $t->join;
        if ($result eq 'add') {
            $adds++;
        } else {
            $removes += $result;
        }
    }
    
    # We added 100 items and tried to remove 50
    # Final count should be around 50 (may vary due to timing)
    my $final_len = $list->length;
    ok($final_len >= 0 && $final_len <= 100, "final length $final_len is reasonable");
};

# Test 8: Stress test - many operations
subtest 'Stress test with threads' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    
    my @threads;
    for my $i (1..8) {
        push @threads, threads->create(sub {
            for my $j (1..100) {
                $list->add($j);
                if ($j % 3 == 0) {
                    $list->remove_from_start;
                }
            }
            return 1;
        });
    }
    
    my $ok = 1;
    for my $t (@threads) {
        $ok = 0 unless $t->join;
    }
    
    ok($ok, 'stress test completed without errors');
};

# Test 9: Navigation during concurrent modifications
subtest 'Navigation with concurrent mods' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    for my $i (1..50) {
        $list->add($i);
    }
    
    my @threads;
    
    # Navigator thread
    push @threads, threads->create(sub {
        my $moves = 0;
        for my $i (1..100) {
            $list->start;
            $list->next;
            $list->next;
            $list->end;
            $list->prev;
            $moves++;
        }
        return $moves;
    });
    
    # Modifier thread
    push @threads, threads->create(sub {
        for my $i (1..25) {
            $list->add($i + 100);
            $list->remove_from_start;
        }
        return 1;
    });
    
    my $ok = 1;
    for my $t (@threads) {
        my $res = $t->join;
        $ok = 0 unless $res;
    }
    
    ok($ok, 'navigation with concurrent mods completed');
};

done_testing();
