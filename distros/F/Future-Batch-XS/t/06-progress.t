use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch::XS qw(batch);

# Test progress callback reports correctly
subtest 'progress callback accuracy' => sub {
    my @progress_reports;
    
    # Use immediate futures for predictable behavior
    my $future = batch(
        items       => [1, 2, 3, 4, 5],
        concurrent  => 2,
        on_progress => sub {
            my ($completed, $total) = @_;
            push @progress_reports, { completed => $completed, total => $total };
        },
        worker => sub {
            my ($item) = @_;
            return Future->done($item * 10);
        },
    );
    
    $future->get;  # Wait for completion
    
    is(scalar @progress_reports, 5, 'progress called for each completion');
    
    for my $i (0..$#progress_reports) {
        is($progress_reports[$i]{completed}, $i + 1, "progress report $i: completed = " . ($i + 1));
        is($progress_reports[$i]{total}, 5, "progress report $i: total = 5");
    }
};

# Test progress not called when no callback provided
subtest 'no progress callback' => sub {
    # Should not crash even without on_progress
    my $result = batch(
        items  => [1, 2, 3],
        worker => sub { Future->done($_[0]) },
    )->get;
    
    is_deeply($result, [1, 2, 3], 'works without progress callback');
};

# Test progress with empty items
subtest 'progress with empty items' => sub {
    my $progress_called = 0;
    
    batch(
        items       => [],
        on_progress => sub { $progress_called++ },
        worker      => sub { die "should not be called" },
    )->get;
    
    is($progress_called, 0, 'progress not called for empty items');
};

# Test progress with single item
subtest 'progress with single item' => sub {
    my @progress_reports;
    
    batch(
        items       => [42],
        on_progress => sub {
            my ($completed, $total) = @_;
            push @progress_reports, [$completed, $total];
        },
        worker => sub { Future->done($_[0]) },
    )->get;
    
    is(scalar @progress_reports, 1, 'progress called once');
    is_deeply($progress_reports[0], [1, 1], 'reports 1/1');
};

# Test progress during failures (fail_fast = false)
subtest 'progress with failures' => sub {
    my @progress_reports;
    
    batch(
        items       => [1, 2, 3],
        fail_fast   => 0,
        on_progress => sub {
            my ($completed, $total) = @_;
            push @progress_reports, [$completed, $total];
        },
        worker => sub {
            my ($item) = @_;
            if ($item == 2) {
                return Future->fail("error on $item");
            }
            return Future->done($item);
        },
    );
    
    is(scalar @progress_reports, 3, 'progress called for all items including failures');
};

# Test progress percentage calculation
subtest 'progress percentage' => sub {
    my @percentages;
    
    batch(
        items       => [1, 2, 3, 4],
        on_progress => sub {
            my ($completed, $total) = @_;
            my $pct = int(($completed / $total) * 100);
            push @percentages, $pct;
        },
        worker => sub { Future->done($_[0]) },
    )->get;
    
    is_deeply(\@percentages, [25, 50, 75, 100], 'percentages calculated correctly');
};

# Test progress callback receives correct values during concurrent execution
subtest 'progress with high concurrency' => sub {
    my @progress_reports;
    my @pending;
    
    my $future = batch(
        items       => [1..10],
        concurrent  => 10,
        on_progress => sub {
            my ($completed, $total) = @_;
            push @progress_reports, { completed => $completed, total => $total };
        },
        worker => sub {
            my ($item) = @_;
            my $f = Future->new;
            push @pending, { f => $f, item => $item };
            return $f;
        },
    );
    
    # Complete all at once
    $_->{f}->done($_->{item}) for @pending;
    
    is(scalar @progress_reports, 10, 'progress called 10 times');
    
    # Verify monotonically increasing
    my $prev = 0;
    for my $report (@progress_reports) {
        ok($report->{completed} > $prev, "completed increases: $report->{completed} > $prev");
        $prev = $report->{completed};
    }
};

# Test progress callback can modify external state
subtest 'progress callback side effects' => sub {
    my $external_counter = 0;
    
    batch(
        items       => [1, 2, 3],
        on_progress => sub {
            $external_counter++;
        },
        worker => sub { Future->done($_[0]) },
    )->get;
    
    is($external_counter, 3, 'progress callback can modify external state');
};

done_testing;
