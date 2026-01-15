use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch::XS qw(batch);

BEGIN {
    eval { require IO::Async::Loop };
    plan skip_all => 'IO::Async::Loop required for loop tests' if $@;
}

use IO::Async::Loop;

# Test without loop - synchronous execution
subtest 'without loop - synchronous' => sub {
    my @order;
    
    my $future = batch(
        items      => [1, 2, 3],
        concurrent => 1,
        worker     => sub {
            my ($item) = @_;
            push @order, "process:$item";
            return Future->done($item * 2);
        },
    );
    
    # All items processed immediately due to immediate futures
    is(scalar @order, 3, 'all items processed synchronously');
    ok($future->is_done, 'future already done');
    is_deeply($future->get, [2, 4, 6], 'results correct');
};

# Test with loop - basic integration
subtest 'with loop - basic' => sub {
    my $loop = IO::Async::Loop->new;
    my @order;
    
    my $future = batch(
        items      => [1, 2, 3],
        concurrent => 1,
        loop       => $loop,
        worker     => sub {
            my ($item) = @_;
            push @order, "process:$item";
            return Future->done($item * 2);
        },
    );
    
    # Run the loop until batch completes
    $loop->await($future);
    
    is(scalar @order, 3, 'all items processed');
    ok($future->is_done, 'future done');
    is_deeply($future->get, [2, 4, 6], 'results correct');
};

# Test loop accessor
subtest 'loop accessor' => sub {
    my $loop = IO::Async::Loop->new;
    
    my $batch = Future::Batch::XS->new(
        concurrent => 5,
        loop       => $loop,
    );
    
    is($batch->loop, $loop, 'loop accessor returns loop');
    
    my $batch2 = Future::Batch::XS->new(concurrent => 5);
    is($batch2->loop, undef, 'loop is undef when not provided');
};

# Test with loop and pending futures
subtest 'loop with pending futures' => sub {
    my $loop = IO::Async::Loop->new;
    my @started;
    my %pending;
    
    my $future = batch(
        items      => [1, 2, 3, 4, 5],
        concurrent => 2,
        loop       => $loop,
        worker     => sub {
            my ($item) = @_;
            push @started, $item;
            my $f = $loop->new_future;
            $pending{$item} = $f;
            
            # Schedule completion after a tiny delay
            $loop->watch_time(
                after => 0.01,
                code  => sub { $f->done("r$item") },
            );
            return $f;
        },
    );
    
    # Run loop to completion
    $loop->await($future);
    
    ok($future->is_done, 'batch complete');
    is(scalar @started, 5, 'all 5 items started');
    is_deeply($future->get, [map { "r$_" } 1..5], 'results correct');
};

# Test with timer-based async work
subtest 'loop with async timers' => sub {
    my $loop = IO::Async::Loop->new;
    my @completed;
    
    my $future = batch(
        items      => [1, 2, 3],
        concurrent => 3,
        loop       => $loop,
        worker     => sub {
            my ($item) = @_;
            my $f = $loop->new_future;
            $loop->watch_time(
                after => 0.01 * $item,
                code  => sub {
                    push @completed, $item;
                    $f->done($item * 10);
                },
            );
            return $f;
        },
    );
    
    $loop->await($future);
    
    # Results should be in original order despite completion order
    is_deeply($future->get, [10, 20, 30], 'results in original order');
    # Completion order may vary based on timing
    is(scalar @completed, 3, 'all items completed');
};

# Test async with concurrency limit
subtest 'async concurrency enforcement' => sub {
    my $loop = IO::Async::Loop->new;
    my $max_concurrent = 0;
    my $current = 0;
    my @order;
    
    my $future = batch(
        items      => [1, 2, 3, 4, 5, 6],
        concurrent => 2,
        loop       => $loop,
        worker     => sub {
            my ($item) = @_;
            $current++;
            $max_concurrent = $current if $current > $max_concurrent;
            push @order, "start:$item";
            
            my $f = $loop->new_future;
            $loop->watch_time(
                after => 0.02,
                code  => sub {
                    push @order, "end:$item";
                    $current--;
                    $f->done($item);
                },
            );
            return $f;
        },
    );
    
    $loop->await($future);
    
    ok($max_concurrent <= 2, "max concurrent was $max_concurrent (should be <= 2)");
    is_deeply($future->get, [1, 2, 3, 4, 5, 6], 'results in order');
};

# Test async with failures
subtest 'async with failures' => sub {
    my $loop = IO::Async::Loop->new;
    
    my $future = batch(
        items      => [1, 2, 3, 4],
        concurrent => 2,
        loop       => $loop,
        worker     => sub {
            my ($item) = @_;
            my $f = $loop->new_future;
            $loop->watch_time(
                after => 0.01,
                code  => sub {
                    if ($item == 3) {
                        $f->fail("item 3 failed");
                    } else {
                        $f->done($item * 10);
                    }
                },
            );
            return $f;
        },
    );
    
    $loop->await($future);
    
    ok($future->is_failed, 'batch failed');
    my ($msg, $cat, $errors, $results) = $future->failure;
    like($msg, qr/1 error/, 'failure message correct');
    is(scalar @$errors, 1, 'one error');
    is($errors->[0]{index}, 2, 'error at index 2');
};

# Test async fail_fast
subtest 'async fail_fast' => sub {
    my $loop = IO::Async::Loop->new;
    my @started;
    
    my $future = batch(
        items      => [1, 2, 3, 4, 5],
        concurrent => 2,
        fail_fast  => 1,
        loop       => $loop,
        worker     => sub {
            my ($item) = @_;
            push @started, $item;
            my $f = $loop->new_future;
            $loop->watch_time(
                after => $item == 1 ? 0.05 : 0.01,  # item 1 slower
                code  => sub {
                    if ($item == 2) {
                        $f->fail("item 2 failed");
                    } else {
                        $f->done($item);
                    }
                },
            );
            return $f;
        },
    );
    
    $loop->await($future);
    
    ok($future->is_failed, 'batch failed');
    my ($msg) = $future->failure;
    like($msg, qr/aborted.*item 2 failed/, 'aborted on item 2');
    # Should not have started all items due to fail_fast
    ok(scalar(@started) < 5, 'fail_fast prevented starting all items');
};

# Test progress callback with async
subtest 'async progress callback' => sub {
    my $loop = IO::Async::Loop->new;
    my @progress;
    
    my $future = batch(
        items       => [1, 2, 3],
        concurrent  => 1,
        loop        => $loop,
        on_progress => sub {
            my ($done, $total) = @_;
            push @progress, "$done/$total";
        },
        worker => sub {
            my ($item) = @_;
            my $f = $loop->new_future;
            $loop->watch_time(
                after => 0.01,
                code  => sub { $f->done($item) },
            );
            return $f;
        },
    );
    
    $loop->await($future);
    
    is_deeply(\@progress, ['1/3', '2/3', '3/3'], 'progress callbacks fired');
};

done_testing;
