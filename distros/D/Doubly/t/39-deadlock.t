#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Deadlock detection test for Doubly
# This test attempts operations that could cause deadlock and uses
# alarm() to timeout if a deadlock occurs.

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

# Check if we can use alarm (not available on Windows)
eval { alarm(0) };
if ($@) {
    plan skip_all => 'alarm() not available on this platform';
}

use_ok('Doubly');

# Helper to run code with a timeout
# Returns 1 if completed, 0 if timed out
sub with_timeout {
    my ($timeout, $code, $name) = @_;
    
    my $completed :shared = 0;
    
    # Use alarm for timeout detection
    local $SIG{ALRM} = sub { die "TIMEOUT\n" };
    
    eval {
        alarm($timeout);
        $code->();
        alarm(0);
        $completed = 1;
    };
    
    if ($@ && $@ eq "TIMEOUT\n") {
        alarm(0);
        return 0;
    } elsif ($@) {
        alarm(0);
        diag("Error in $name: $@");
        return 0;
    }
    
    return $completed;
}

# Test 1: Single list, multiple threads doing mixed operations
subtest 'No deadlock with mixed operations' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $list = Doubly->new();
        $list->bulk_add(1..100);
        
        my @threads;
        for my $i (1..4) {
            push @threads, threads->create(sub {
                for my $j (1..50) {
                    # Mix of operations that all acquire the mutex
                    $list->add("t${i}_$j");
                    $list->length;
                    $list->remove_from_end if $j % 2 == 0;
                    $list->start;
                    $list->data;
                    $list->end;
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $list->destroy;
    }, 'mixed operations');
    
    ok($ok, 'no deadlock with mixed operations from multiple threads');
};

# Test 2: Rapid lock/unlock cycles
subtest 'No deadlock with rapid lock cycles' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $list = Doubly->new();
        
        my @threads;
        for my $i (1..8) {
            push @threads, threads->create(sub {
                for my $j (1..200) {
                    # Rapid fire operations
                    $list->add($j);
                    $list->length;
                    $list->length;
                    $list->data;
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $list->destroy;
    }, 'rapid lock cycles');
    
    ok($ok, 'no deadlock with rapid lock/unlock cycles');
};

# Test 3: Multiple lists, threads switching between them
subtest 'No deadlock with multiple lists' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $list1 = Doubly->new();
        my $list2 = Doubly->new();
        my $list3 = Doubly->new();
        
        $list1->bulk_add(1..50);
        $list2->bulk_add(51..100);
        $list3->bulk_add(101..150);
        
        my @threads;
        for my $i (1..4) {
            push @threads, threads->create(sub {
                for my $j (1..30) {
                    # Operate on multiple lists - potential for lock ordering issues
                    $list1->add("a$j");
                    $list2->add("b$j");
                    $list3->add("c$j");
                    
                    $list1->length;
                    $list2->length;
                    $list3->length;
                    
                    $list3->remove_from_end;
                    $list2->remove_from_end;
                    $list1->remove_from_end;
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $list1->destroy;
        $list2->destroy;
        $list3->destroy;
    }, 'multiple lists');
    
    ok($ok, 'no deadlock when operating on multiple lists');
};

# Test 4: Create and destroy while other threads are working
subtest 'No deadlock with concurrent create/destroy' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $main_list = Doubly->new();
        $main_list->bulk_add(1..100);
        
        my @threads;
        
        # Worker threads using main list
        for my $i (1..2) {
            push @threads, threads->create(sub {
                for my $j (1..50) {
                    $main_list->add("worker$j");
                    $main_list->length;
                }
                return 1;
            });
        }
        
        # Creator threads making/destroying their own lists
        for my $i (1..2) {
            push @threads, threads->create(sub {
                for my $j (1..30) {
                    my $temp = Doubly->new();
                    $temp->bulk_add(1..10);
                    $temp->length;
                    $temp->destroy;
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $main_list->destroy;
    }, 'concurrent create/destroy');
    
    ok($ok, 'no deadlock with concurrent create/destroy');
};

# Test 5: Callback operations (find, insert with callback)
subtest 'No deadlock with callback operations' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $list = Doubly->new();
        $list->bulk_add(1..100);
        
        my @threads;
        for my $i (1..4) {
            push @threads, threads->create(sub {
                for my $j (1..20) {
                    # find() calls back into Perl, then re-acquires lock
                    $list->find(sub { $_[0] == 50 });
                    $list->add("found_$j");
                    $list->start;  # Reset position
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $list->destroy;
    }, 'callback operations');
    
    ok($ok, 'no deadlock with callback operations');
};

# Test 6: Navigation operations (which hold state in the list)
subtest 'No deadlock with navigation' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $list = Doubly->new();
        $list->bulk_add(1..100);
        
        my @threads;
        for my $i (1..4) {
            push @threads, threads->create(sub {
                for my $j (1..30) {
                    $list->start;
                    for my $k (1..10) {
                        $list->next unless $list->is_end;
                    }
                    $list->end;
                    for my $k (1..10) {
                        $list->prev unless $list->is_start;
                    }
                    $list->data;
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $list->destroy;
    }, 'navigation');
    
    ok($ok, 'no deadlock with concurrent navigation');
};

# Test 7: Insert operations (which modify structure)
subtest 'No deadlock with insert operations' => sub {
    plan tests => 1;
    
    my $ok = with_timeout(10, sub {
        my $list = Doubly->new();
        $list->bulk_add(1..50);
        
        my @threads;
        for my $i (1..4) {
            push @threads, threads->create(sub {
                for my $j (1..20) {
                    $list->start;
                    $list->insert_after("after_${i}_$j");
                    $list->end;
                    $list->insert_before("before_${i}_$j");
                    $list->insert_at_start("start_${i}_$j");
                    $list->insert_at_end("end_${i}_$j");
                }
                return 1;
            });
        }
        
        $_->join for @threads;
        $list->destroy;
    }, 'insert operations');
    
    ok($ok, 'no deadlock with concurrent insert operations');
};

done_testing();
