use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch::XS qw(batch);

# Test OO new() with all options
subtest 'new with all options' => sub {
    my $batch = Future::Batch::XS->new(
        concurrent => 5,
        fail_fast  => 1,
    );
    
    is($batch->concurrent, 5, 'concurrent set');
    is($batch->fail_fast, 1, 'fail_fast set');
};

# Test OO run() method
subtest 'run method' => sub {
    my $batch = Future::Batch::XS->new(concurrent => 2);
    
    my $result = $batch->run(
        items  => [1, 2, 3],
        worker => sub { Future->done($_[0] * 2) },
    )->get;
    
    is_deeply($result, [2, 4, 6], 'run() method works');
};

# Test reusing batch object
subtest 'reuse batch object' => sub {
    my $batch = Future::Batch::XS->new(concurrent => 2);
    
    my $result1 = $batch->run(
        items  => [1, 2],
        worker => sub { Future->done($_[0] * 2) },
    )->get;
    
    my $result2 = $batch->run(
        items  => [10, 20],
        worker => sub { Future->done($_[0] + 1) },
    )->get;
    
    is_deeply($result1, [2, 4], 'first run correct');
    is_deeply($result2, [11, 21], 'second run correct');
};

# Test functional interface
subtest 'functional batch()' => sub {
    my $result = batch(
        items  => [1, 2, 3],
        worker => sub { Future->done($_[0]) },
    )->get;
    
    is_deeply($result, [1, 2, 3], 'functional interface works');
};

# Test functional interface with all options
subtest 'functional with all options' => sub {
    my @progress;
    
    my $result = batch(
        items       => [1, 2, 3],
        concurrent  => 2,
        fail_fast   => 0,
        on_progress => sub { push @progress, [@_] },
        worker      => sub { Future->done($_[0]) },
    )->get;
    
    is_deeply($result, [1, 2, 3], 'results correct');
    is(scalar @progress, 3, 'progress called');
};

# Test default worker (passthrough)
subtest 'default worker' => sub {
    my $result = batch(
        items => [1, 2, 3],
        # No worker provided - should use default
    )->get;
    
    is_deeply($result, [1, 2, 3], 'default worker passes items through');
};

# Test worker override in run()
subtest 'worker override in run' => sub {
    my $batch = Future::Batch::XS->new(concurrent => 2);
    
    my $result = $batch->run(
        items  => [1, 2],
        worker => sub { Future->done($_[0] * 100) },
    )->get;
    
    is_deeply($result, [100, 200], 'worker from run() used');
};

# Test concurrent override in run()
subtest 'concurrent in functional call' => sub {
    my $max = 0;
    my $cur = 0;
    my @pending;
    
    my $f = batch(
        items      => [1..10],
        concurrent => 3,
        worker     => sub {
            $cur++;
            $max = $cur if $cur > $max;
            my $future = Future->new;
            push @pending, { f => $future, item => $_[0] };
            return $future;
        },
    );
    
    is($max, 3, 'concurrent limit respected');
    
    # Complete all
    $_->{f}->done($_->{item}) for @pending;
    
    ok($f->is_done, 'batch completed');
};

# Test chaining from batch result
subtest 'chain from batch result' => sub {
    my $result = batch(
        items  => [1, 2, 3],
        worker => sub { Future->done($_[0]) },
    )->then(sub {
        my ($results) = @_;
        my $sum = 0;
        $sum += $_ for @$results;
        return Future->done($sum);
    })->get;
    
    is($result, 6, 'can chain from batch result');
};

# Test calling get() multiple times
subtest 'get multiple times' => sub {
    my $future = batch(
        items  => [1, 2, 3],
        worker => sub { Future->done($_[0]) },
    );
    
    my $result1 = $future->get;
    my $result2 = $future->get;
    
    is_deeply($result1, [1, 2, 3], 'first get correct');
    is_deeply($result2, [1, 2, 3], 'second get correct');
};

# Test is_ready/is_done states
subtest 'future states' => sub {
    my @pending;
    
    my $future = batch(
        items  => [1, 2],
        worker => sub {
            my $f = Future->new;
            push @pending, $f;
            return $f;
        },
    );
    
    ok(!$future->is_ready, 'not ready initially');
    ok(!$future->is_done, 'not done initially');
    
    $pending[0]->done(1);
    ok(!$future->is_ready, 'still not ready after partial');
    
    $pending[1]->done(2);
    ok($future->is_ready, 'ready after all complete');
    ok($future->is_done, 'done after all complete');
};

done_testing;
