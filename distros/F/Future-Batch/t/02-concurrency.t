use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch qw(batch);

# Test that concurrency limit is respected
subtest 'concurrency limit' => sub {
    my $max_concurrent = 0;
    my $current = 0;
    my @pending_futures;
    
    my $batch_future = batch(
        items      => [1..10],
        concurrent => 3,
        worker     => sub {
            my ($item) = @_;
            $current++;
            $max_concurrent = $current if $current > $max_concurrent;
            
            my $f = Future->new;
            push @pending_futures, { future => $f, item => $item };
            return $f;
        },
    );
    
    # At this point, 3 workers should have started
    is($current, 3, 'initial batch starts concurrent workers');
    is($max_concurrent, 3, 'max concurrent is 3');
    is(scalar @pending_futures, 3, '3 pending futures');
    
    # Complete first future
    my $first = shift @pending_futures;
    $current--;
    $first->{future}->done($first->{item} * 2);
    
    # Should have started another
    is($current, 3, 'completing one starts another');
    is(scalar @pending_futures, 3, 'still 3 pending');
    
    # Complete all remaining
    while (@pending_futures) {
        my $p = shift @pending_futures;
        $current--;
        $p->{future}->done($p->{item} * 2);
    }
    
    ok($batch_future->is_done, 'batch completes');
    is($max_concurrent, 3, 'never exceeded concurrency limit');
    
    my $results = $batch_future->get;
    is_deeply($results, [2, 4, 6, 8, 10, 12, 14, 16, 18, 20], 'results correct and ordered');
};

# Test default concurrency
subtest 'default concurrency' => sub {
    my $batch = Future::Batch->new;
    is($batch->concurrent, 10, 'default concurrency is 10');
};

# Test concurrency of 1 (sequential)
subtest 'sequential processing' => sub {
    my @order;
    my $pending;
    
    my $batch_future = batch(
        items      => [1, 2, 3],
        concurrent => 1,
        worker     => sub {
            my ($item) = @_;
            push @order, "start:$item";
            $pending = Future->new;
            $pending->on_done(sub { push @order, "end:$item" });
            return $pending;
        },
    );
    
    is_deeply(\@order, ['start:1'], 'only first item started');
    
    $pending->done('r1');
    is_deeply(\@order, ['start:1', 'end:1', 'start:2'], 'second starts after first ends');
    
    $pending->done('r2');
    $pending->done('r3');
    
    ok($batch_future->is_done, 'batch done');
};

# Test progress callback
subtest 'progress callback' => sub {
    my @progress;
    
    my @pending;
    my $batch_future = batch(
        items       => [1, 2, 3, 4],
        concurrent  => 2,
        on_progress => sub {
            my ($completed, $total) = @_;
            push @progress, [$completed, $total];
        },
        worker => sub {
            my $f = Future->new;
            push @pending, $f;
            return $f;
        },
    );
    
    is_deeply(\@progress, [], 'no progress yet');
    
    # Complete first
    (shift @pending)->done('a');
    is_deeply(\@progress, [[1, 4]], 'progress after first complete');
    
    # Complete rest
    $_->done('x') for @pending;
    
    is(scalar @progress, 4, 'progress called 4 times');
    is_deeply($progress[-1], [4, 4], 'final progress is 4/4');
};

done_testing;
