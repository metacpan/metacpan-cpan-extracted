use strict;
use warnings;
use Test2::V0;

use IO::Async::Pg::Results;

subtest 'create from data (for testing)' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' },
        ],
        columns => ['id', 'name'],
    );

    isa_ok $results, 'IO::Async::Pg::Results';
    is $results->count, 2, 'count';
    is $results->columns, ['id', 'name'], 'columns';
};

subtest 'rows accessor' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' },
        ],
        columns => ['id', 'name'],
    );

    is $results->rows, [
        { id => 1, name => 'Alice' },
        { id => 2, name => 'Bob' },
    ], 'rows returns arrayref of hashrefs';
};

subtest 'first method' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' },
        ],
        columns => ['id', 'name'],
    );

    is $results->first, { id => 1, name => 'Alice' }, 'first returns first row';
    is $results->first->{name}, 'Alice', 'can access field from first';
};

subtest 'first on empty result' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [],
        columns => ['id', 'name'],
    );

    is $results->first, undef, 'first returns undef for empty result';
    is $results->count, 0, 'count is 0';
    ok $results->is_empty, 'is_empty returns true';
};

subtest 'scalar method' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [{ count => 42 }],
        columns => ['count'],
    );

    is $results->scalar, 42, 'scalar returns first column of first row';
};

subtest 'scalar with different column name' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [{ total => 100, other => 200 }],
        columns => ['total', 'other'],
    );

    is $results->scalar, 100, 'scalar returns first column value';
};

subtest 'rows_affected' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows          => [],
        columns       => [],
        rows_affected => 5,
    );

    is $results->rows_affected, 5, 'rows_affected accessor';
};

subtest 'is_empty' => sub {
    my $empty = IO::Async::Pg::Results->new_from_data(
        rows    => [],
        columns => [],
    );

    my $not_empty = IO::Async::Pg::Results->new_from_data(
        rows    => [{ id => 1 }],
        columns => ['id'],
    );

    ok $empty->is_empty, 'empty result is_empty';
    ok !$not_empty->is_empty, 'non-empty result not is_empty';
};

subtest 'iterate over rows' => sub {
    my $results = IO::Async::Pg::Results->new_from_data(
        rows    => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' },
            { id => 3, name => 'Charlie' },
        ],
        columns => ['id', 'name'],
    );

    my @names;
    for my $row (@{$results->rows}) {
        push @names, $row->{name};
    }

    is \@names, ['Alice', 'Bob', 'Charlie'], 'can iterate over rows';
};

done_testing;
