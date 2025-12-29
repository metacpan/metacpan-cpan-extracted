use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 't/lib';
use Test::IO::Async::Pg qw(skip_without_postgres test_dsn);

# Skip if no PostgreSQL available
my $dsn = skip_without_postgres();
skip_all("Set TEST_PG_DSN to run cursor tests") unless $dsn;

use IO::Async::Loop;
use IO::Async::Pg;

my $loop = IO::Async::Loop->new;
my $pg;

sub setup {
    $pg = IO::Async::Pg->new(
        dsn             => test_dsn(),
        min_connections => 0,
        max_connections => 5,
    );
    $loop->add($pg);

    # Create test table with data
    my $conn = $pg->connection->get;
    $conn->query("SET client_min_messages TO warning")->get;
    $conn->query('DROP TABLE IF EXISTS cursor_test')->get;
    $conn->query('CREATE TABLE cursor_test (id SERIAL PRIMARY KEY, name TEXT)')->get;

    # Insert 100 rows
    for my $i (1..100) {
        $conn->query("INSERT INTO cursor_test (name) VALUES (\$1)", "row_$i")->get;
    }

    $conn->release;
}

sub cleanup {
    my $conn = $pg->connection->get;
    $conn->query('DROP TABLE IF EXISTS cursor_test')->get;
    $conn->release;
    $loop->remove($pg);
}

setup();

subtest 'basic cursor iteration' => sub {
    my $conn = $pg->connection->get;

    my $cursor = $conn->cursor(
        'SELECT * FROM cursor_test ORDER BY id',
        { batch_size => 10 }
    )->get;

    isa_ok $cursor, 'IO::Async::Pg::Cursor';
    is $cursor->batch_size, 10, 'batch_size set correctly';

    # Fetch first batch
    my $batch1 = $cursor->next->get;
    is scalar(@$batch1), 10, 'first batch has 10 rows';
    is $batch1->[0]{name}, 'row_1', 'first row correct';
    is $batch1->[9]{name}, 'row_10', 'tenth row correct';

    # Fetch second batch
    my $batch2 = $cursor->next->get;
    is scalar(@$batch2), 10, 'second batch has 10 rows';
    is $batch2->[0]{name}, 'row_11', 'eleventh row correct';

    # Close cursor
    $cursor->close->get;
    ok $cursor->is_closed, 'cursor marked as closed';

    $conn->release;
};

subtest 'cursor exhaust' => sub {
    my $conn = $pg->connection->get;

    my $cursor = $conn->cursor(
        'SELECT * FROM cursor_test WHERE id <= 25 ORDER BY id',
        { batch_size => 10 }
    )->get;

    my @all_rows;
    while (my $batch = $cursor->next->get) {
        push @all_rows, @$batch;
    }

    is scalar(@all_rows), 25, 'got all 25 rows';
    ok $cursor->is_exhausted, 'cursor is exhausted';

    $cursor->close->get;
    $conn->release;
};

subtest 'cursor each()' => sub {
    my $conn = $pg->connection->get;

    my $cursor = $conn->cursor(
        'SELECT * FROM cursor_test WHERE id <= 15 ORDER BY id',
        { batch_size => 5 }
    )->get;

    my @collected;
    my $count = $cursor->each(sub {
        my ($row) = @_;
        push @collected, $row->{name};
    })->get;

    is $count, 15, 'each() returned correct count';
    is scalar(@collected), 15, 'collected 15 rows';
    is $collected[0], 'row_1', 'first collected';
    is $collected[14], 'row_15', 'last collected';

    $cursor->close->get;
    $conn->release;
};

subtest 'cursor all()' => sub {
    my $conn = $pg->connection->get;

    my $cursor = $conn->cursor(
        'SELECT * FROM cursor_test WHERE id <= 23 ORDER BY id',
        { batch_size => 7 }
    )->get;

    my $rows = $cursor->all->get;

    is scalar(@$rows), 23, 'all() returned all rows';
    is $rows->[0]{name}, 'row_1', 'first row';
    is $rows->[22]{name}, 'row_23', 'last row';

    $cursor->close->get;
    $conn->release;
};

subtest 'cursor with bind values' => sub {
    my $conn = $pg->connection->get;

    my $cursor = $conn->cursor(
        'SELECT * FROM cursor_test WHERE id BETWEEN $1 AND $2 ORDER BY id',
        5, 15,
        { batch_size => 10 }
    )->get;

    my $rows = $cursor->all->get;

    is scalar(@$rows), 11, 'got rows 5-15';
    is $rows->[0]{name}, 'row_5', 'starts at row 5';
    is $rows->[10]{name}, 'row_15', 'ends at row 15';

    $cursor->close->get;
    $conn->release;
};

subtest 'cursor within existing transaction' => sub {
    my $conn = $pg->connection->get;

    $conn->transaction(async sub {
        my ($tx) = @_;

        my $cursor = await $tx->cursor(
            'SELECT * FROM cursor_test WHERE id <= 5 ORDER BY id',
            { batch_size => 2 }
        );

        my $rows = await $cursor->all;
        is scalar(@$rows), 5, 'got 5 rows inside transaction';

        await $cursor->close;
    })->get;

    # Connection should still work after
    my $result = $conn->query('SELECT 1 AS one')->get;
    is $result->first->{one}, 1, 'connection works after transaction with cursor';

    $conn->release;
};

subtest 'cursor auto-starts transaction if needed' => sub {
    my $conn = $pg->connection->get;

    ok !$conn->in_transaction, 'not in transaction initially';

    my $cursor = $conn->cursor(
        'SELECT * FROM cursor_test WHERE id <= 3 ORDER BY id',
        { batch_size => 10 }
    )->get;

    ok $conn->in_transaction, 'cursor started a transaction';

    my $rows = $cursor->all->get;
    is scalar(@$rows), 3, 'got 3 rows';

    $cursor->close->get;

    ok !$conn->in_transaction, 'transaction closed when cursor closed';

    $conn->release;
};

cleanup();
done_testing;
