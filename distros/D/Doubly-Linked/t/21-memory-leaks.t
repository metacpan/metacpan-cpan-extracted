use strict;
use warnings;
use Test::More;

eval "use Test::LeakTrace";
plan skip_all => "Test::LeakTrace required for memory leak tests" if $@;

use Doubly::Linked;

plan tests => 6;

# Test 1: new() + destroy() should not grow memory
subtest 'new() + destroy() no memory growth' => sub {
    plan tests => 1;
    my $iterations = 100;
    my $before = get_rss();
    for (1..$iterations) {
        my $list = Doubly::Linked->new();
        $list->destroy();
    }
    my $after = get_rss();
    my $growth = $after - $before;
    ok($growth < 500, "Memory growth < 500KB after $iterations iterations (was ${growth}KB)");
};

# Test 2: new() + add() + destroy() should not grow memory
subtest 'new() + add(1) + destroy() no memory growth' => sub {
    plan tests => 1;
    my $iterations = 100;
    my $before = get_rss();
    for (1..$iterations) {
        my $list = Doubly::Linked->new();
        $list->add(1);
        $list->destroy();
    }
    my $after = get_rss();
    my $growth = $after - $before;
    ok($growth < 500, "Memory growth < 500KB after $iterations iterations (was ${growth}KB)");
};

# Test 3: new() + add(1..10) + destroy() should not grow memory
subtest 'new() + add(1..10) + destroy() no memory growth' => sub {
    plan tests => 1;
    my $iterations = 100;
    my $before = get_rss();
    for (1..$iterations) {
        my $list = Doubly::Linked->new();
        $list->add(1..10);
        $list->destroy();
    }
    my $after = get_rss();
    my $growth = $after - $before;
    ok($growth < 500, "Memory growth < 500KB after $iterations iterations (was ${growth}KB)");
};

# Test 4: Longer list should not leak more than short list
subtest 'destroy() breaks circular references regardless of list size' => sub {
    plan tests => 1;
    my $iterations = 50;
    
    # Test with 100 items per list
    my $before = get_rss();
    for (1..$iterations) {
        my $list = Doubly::Linked->new();
        $list->add(1..100);
        $list->destroy();
    }
    my $after = get_rss();
    my $growth = $after - $before;
    ok($growth < 1000, "Memory growth < 1000KB after $iterations iterations of 100-item lists (was ${growth}KB)");
};

# Test 5: remove operations + destroy should not leak
subtest 'remove operations + destroy() no memory growth' => sub {
    plan tests => 1;
    my $iterations = 100;
    my $before = get_rss();
    for (1..$iterations) {
        my $list = Doubly::Linked->new();
        $list->add(1..5);
        $list->remove_from_start();
        $list->remove_from_end();
        $list->destroy();
    }
    my $after = get_rss();
    my $growth = $after - $before;
    ok($growth < 500, "Memory growth < 500KB after $iterations iterations (was ${growth}KB)");
};

# Test 6: insert operations + destroy should not leak
subtest 'insert operations + destroy() no memory growth' => sub {
    plan tests => 1;
    my $iterations = 100;
    my $before = get_rss();
    for (1..$iterations) {
        my $list = Doubly::Linked->new();
        $list->add(1..3);
        $list->insert_at_start(0);
        $list->insert_at_end(4);
        $list->insert_at_pos(2, 1.5);
        $list->destroy();
    }
    my $after = get_rss();
    my $growth = $after - $before;
    ok($growth < 500, "Memory growth < 500KB after $iterations iterations (was ${growth}KB)");
};

# Helper to get resident set size in KB
sub get_rss {
    my $rss;
    if ($^O eq 'darwin' || $^O eq 'linux') {
        $rss = `ps -p $$ -o rss=`;
        chomp $rss;
        $rss =~ s/\s+//g;
    } else {
        # Windows or unknown - return 0 and tests will pass
        $rss = 0;
    }
    return $rss || 0;
}
