use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch::XS qw(batch);

# Test failure collection (fail_fast = false)
subtest 'collect failures' => sub {
    my $batch_future = batch(
        items     => [1, 2, 3, 4, 5],
        fail_fast => 0,
        worker    => sub {
            my ($item) = @_;
            if ($item == 3) {
                return Future->fail("item 3 failed", "test");
            }
            return Future->done($item * 2);
        },
    );
    
    ok($batch_future->is_failed, 'batch failed');
    
    my ($message, $category, $errors, $results) = $batch_future->failure;
    
    like($message, qr/failed with 1 error/, 'failure message mentions error count');
    is($category, 'batch', 'category is batch');
    is(scalar @$errors, 1, 'one error captured');
    is($errors->[0]{index}, 2, 'error at index 2');
    is($errors->[0]{item}, 3, 'error item is 3');
    is_deeply($errors->[0]{failure}, ["item 3 failed", "test"], 'failure details captured');
    
    # Partial results should exist
    is($results->[0], 2, 'result 0 exists');
    is($results->[1], 4, 'result 1 exists');
    is($results->[3], 8, 'result 3 exists');
    is($results->[4], 10, 'result 4 exists');
};

# Test multiple failures
subtest 'multiple failures' => sub {
    my $batch_future = batch(
        items  => [1, 2, 3, 4],
        worker => sub {
            my ($item) = @_;
            return Future->fail("even fail") if $item % 2 == 0;
            return Future->done($item);
        },
    );
    
    my ($message, $category, $errors) = $batch_future->failure;
    
    like($message, qr/failed with 2 error/, 'two errors reported');
    is(scalar @$errors, 2, 'two errors captured');
};

# Test fail_fast mode
subtest 'fail_fast mode' => sub {
    my @started;
    my @pending;
    
    my $batch_future = batch(
        items      => [1, 2, 3, 4, 5],
        concurrent => 2,
        fail_fast  => 1,
        worker     => sub {
            my ($item) = @_;
            push @started, $item;
            my $f = Future->new;
            push @pending, { f => $f, item => $item };
            return $f;
        },
    );
    
    is_deeply(\@started, [1, 2], 'first 2 started');
    
    # Fail the first one
    $pending[0]{f}->fail("boom");
    
    ok($batch_future->is_failed, 'batch failed immediately');
    my ($message) = $batch_future->failure;
    like($message, qr/aborted/, 'message says aborted');
    
    # Item 3 should NOT have started
    ok(!grep({ $_ == 3 } @started), 'item 3 never started due to fail_fast');
};

# Test worker dies
subtest 'worker dies' => sub {
    my $batch_future = batch(
        items  => [1, 2, 3],
        worker => sub {
            my ($item) = @_;
            die "worker died on $item" if $item == 2;
            return Future->done($item);
        },
    );
    
    ok($batch_future->is_failed, 'batch failed when worker died');
    my ($message, $category, $errors) = $batch_future->failure;
    like($errors->[0]{failure}[0], qr/worker died on 2/, 'die message captured');
};

# Test all items succeed
subtest 'all succeed' => sub {
    my $batch_future = batch(
        items  => [1, 2, 3],
        worker => sub { Future->done($_[0]) },
    );
    
    ok($batch_future->is_done, 'batch succeeded');
    ok(!$batch_future->is_failed, 'batch not failed');
};

done_testing;
