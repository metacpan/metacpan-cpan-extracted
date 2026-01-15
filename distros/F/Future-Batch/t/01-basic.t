use strict;
use warnings;
use Test::More;
use Future;
use Future::Batch qw(batch);

# Test basic functionality with immediate futures
subtest 'basic batch processing' => sub {
    my @items = (1, 2, 3, 4, 5);
    
    my $future = batch(
        items  => \@items,
        worker => sub {
            my ($item) = @_;
            return Future->done($item * 2);
        },
    );
    
    ok($future->isa('Future'), 'batch returns a Future');
    
    my $results = $future->get;
    is_deeply($results, [2, 4, 6, 8, 10], 'results are correct and ordered');
};

# Test empty items
subtest 'empty items' => sub {
    my $future = batch(
        items  => [],
        worker => sub { die "should not be called" },
    );
    
    my $results = $future->get;
    is_deeply($results, [], 'empty input returns empty results');
};

# Test OO interface
subtest 'OO interface' => sub {
    my $batch = Future::Batch->new(concurrent => 2);
    
    is($batch->concurrent, 2, 'concurrent accessor works');
    is($batch->fail_fast, 0, 'fail_fast defaults to false');
    
    my $results = $batch->run(
        items  => [10, 20, 30],
        worker => sub { Future->done($_[0] + 1) },
    )->get;
    
    is_deeply($results, [11, 21, 31], 'OO interface produces correct results');
};

# Test worker receives index
subtest 'worker receives index' => sub {
    my @received_indices;
    
    batch(
        items  => ['a', 'b', 'c'],
        worker => sub {
            my ($item, $idx) = @_;
            push @received_indices, $idx;
            return Future->done($item);
        },
    )->get;
    
    is_deeply([sort { $a <=> $b } @received_indices], [0, 1, 2], 'worker receives correct indices');
};

# Test non-Future return value gets wrapped
subtest 'non-Future return wrapped' => sub {
    my $results = batch(
        items  => [1, 2, 3],
        worker => sub { $_[0] * 10 },  # returns plain value, not Future
    )->get;
    
    is_deeply($results, [10, 20, 30], 'plain return values are wrapped in Future->done');
};

# Test undef return
subtest 'undef return' => sub {
    my $results = batch(
        items  => [1],
        worker => sub { return undef },
    )->get;
    
    is_deeply($results, [undef], 'undef return is handled');
};

done_testing;
