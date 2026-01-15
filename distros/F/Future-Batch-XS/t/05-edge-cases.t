use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch::XS qw(batch);

# Test single item batch
subtest 'single item' => sub {
    my $result = batch(
        items  => [42],
        worker => sub { Future->done($_[0] * 2) },
    )->get;
    
    is_deeply($result, [84], 'single item processed correctly');
};

# Test large batch
subtest 'large batch' => sub {
    my @items = (1..100);
    my $result = batch(
        items      => \@items,
        concurrent => 10,
        worker     => sub { Future->done($_[0] * 2) },
    )->get;
    
    is(scalar @$result, 100, 'all 100 items processed');
    is($result->[0], 2, 'first result correct');
    is($result->[99], 200, 'last result correct');
    is_deeply($result, [map { $_ * 2 } @items], 'all results correct');
};

# Test with mixed data types
subtest 'mixed data types' => sub {
    my @items = (1, 'two', [3], { four => 4 }, undef);
    
    my $result = batch(
        items  => \@items,
        worker => sub {
            my ($item) = @_;
            return Future->done($item);
        },
    )->get;
    
    is($result->[0], 1, 'number preserved');
    is($result->[1], 'two', 'string preserved');
    is_deeply($result->[2], [3], 'arrayref preserved');
    is_deeply($result->[3], { four => 4 }, 'hashref preserved');
    is($result->[4], undef, 'undef preserved');
};

# Test worker returning multiple values
subtest 'worker returns multiple values' => sub {
    my $result = batch(
        items  => [1, 2, 3],
        worker => sub {
            my ($item) = @_;
            return Future->done($item, $item * 2, $item * 3);
        },
    )->get;
    
    # Each result should be an arrayref of the multiple return values
    is_deeply($result->[0], [1, 2, 3], 'multiple values captured as arrayref');
    is_deeply($result->[1], [2, 4, 6], 'second item multiple values');
    is_deeply($result->[2], [3, 6, 9], 'third item multiple values');
};

# Test with 0 as valid item
subtest 'zero as item' => sub {
    my $result = batch(
        items  => [0],
        worker => sub {
            my ($item) = @_;
            return Future->done($item + 100);
        },
    )->get;
    
    is_deeply($result, [100], 'zero processed correctly');
};

# Test with empty string as item
subtest 'empty string as item' => sub {
    my $result = batch(
        items  => [''],
        worker => sub {
            my ($item) = @_;
            return Future->done("prefix:$item:suffix");
        },
    )->get;
    
    is_deeply($result, ['prefix::suffix'], 'empty string processed correctly');
};

# Test concurrent higher than items count
subtest 'concurrent exceeds items' => sub {
    my $result = batch(
        items      => [1, 2],
        concurrent => 100,
        worker     => sub { Future->done($_[0]) },
    )->get;
    
    is_deeply($result, [1, 2], 'works when concurrent > item count');
};

# Test concurrent = 0 (should use default)
subtest 'concurrent zero uses default' => sub {
    my $batch = Future::Batch::XS->new(concurrent => 0);
    # Should fallback to default
    ok($batch->concurrent >= 1, 'concurrent defaults to at least 1');
};

# Test chained futures
subtest 'chained futures from worker' => sub {
    my $result = batch(
        items  => [1, 2, 3],
        worker => sub {
            my ($item) = @_;
            return Future->done($item)->then(sub {
                my ($val) = @_;
                return Future->done($val * 10);
            });
        },
    )->get;
    
    is_deeply($result, [10, 20, 30], 'chained futures work correctly');
};

# Test modifying items array during processing (shouldn't affect batch)
subtest 'item array modification safety' => sub {
    my @items = (1, 2, 3);
    my $items_ref = \@items;
    
    my $future = batch(
        items  => $items_ref,
        worker => sub {
            my ($item) = @_;
            # Try to modify the array
            push @items, 999;
            return Future->done($item);
        },
    );
    
    my $result = $future->get;
    # Should only have original 3 items processed
    is(scalar(@$result), 3, 'only original items processed');
    is_deeply($result, [1, 2, 3], 'results match original items');
};

# Test result order with varying completion times (simulated)
subtest 'result ordering maintained' => sub {
    my @pending;
    
    my $future = batch(
        items      => [1, 2, 3, 4, 5],
        concurrent => 5,
        worker     => sub {
            my ($item) = @_;
            my $f = Future->new;
            push @pending, { f => $f, item => $item };
            return $f;
        },
    );
    
    # Complete in reverse order
    for my $p (reverse @pending) {
        $p->{f}->done($p->{item} * 10);
    }
    
    my $result = $future->get;
    is_deeply($result, [10, 20, 30, 40, 50], 'results maintain original order despite completion order');
};

# Test with blessed objects as items
subtest 'blessed objects as items' => sub {
    {
        package TestItem;
        sub new { my ($class, $val) = @_; bless { value => $val }, $class }
        sub value { shift->{value} }
    }
    
    my @items = map { TestItem->new($_) } (1, 2, 3);
    
    my $result = batch(
        items  => \@items,
        worker => sub {
            my ($item) = @_;
            return Future->done($item->value * 2);
        },
    )->get;
    
    is_deeply($result, [2, 4, 6], 'blessed objects handled correctly');
};

# Test very high concurrency
subtest 'high concurrency' => sub {
    my $max_concurrent = 0;
    my $current = 0;
    my @pending;
    
    my $future = batch(
        items      => [1..50],
        concurrent => 50,
        worker     => sub {
            my ($item) = @_;
            $current++;
            $max_concurrent = $current if $current > $max_concurrent;
            my $f = Future->new;
            push @pending, { f => $f, item => $item };
            return $f;
        },
    );
    
    is($max_concurrent, 50, 'all 50 started concurrently');
    
    # Complete all
    $_->{f}->done($_->{item}) for @pending;
    
    ok($future->is_done, 'batch completes');
    is(scalar(@{$future->get}), 50, 'all results returned');
};

done_testing;
