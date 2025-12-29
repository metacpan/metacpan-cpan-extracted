use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;

use lib 't/lib';
use Test::IO::Async::Pg qw(skip_without_postgres test_dsn);

# Skip if no PostgreSQL available
my $dsn = skip_without_postgres();
skip_all("Set TEST_PG_DSN to run transaction tests") unless $dsn;

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

    # Create test table
    my $conn = $pg->connection->get;
    $conn->query("SET client_min_messages TO warning")->get;
    $conn->query('DROP TABLE IF EXISTS tx_test')->get;
    $conn->query('CREATE TABLE tx_test (id SERIAL PRIMARY KEY, name TEXT)')->get;
    $conn->release;
}

sub cleanup {
    my $conn = $pg->connection->get;
    $conn->query('DROP TABLE IF EXISTS tx_test')->get;
    $conn->release;
    $loop->remove($pg);
}

setup();

subtest 'basic transaction commit' => sub {
    my $conn = $pg->connection->get;

    my $result = $conn->transaction(async sub {
        my ($tx) = @_;
        await $tx->query("INSERT INTO tx_test (name) VALUES ('Alice')");
        await $tx->query("INSERT INTO tx_test (name) VALUES ('Bob')");
        return 'done';
    })->get;

    is $result, 'done', 'transaction returned value';

    my $count = $conn->query('SELECT COUNT(*) AS c FROM tx_test')->get;
    is $count->first->{c}, 2, 'both rows committed';

    $conn->release;
};

subtest 'transaction rollback on error' => sub {
    my $conn = $pg->connection->get;

    # Clear table
    $conn->query('DELETE FROM tx_test')->get;

    my $err;
    eval {
        $conn->transaction(async sub {
            my ($tx) = @_;
            await $tx->query("INSERT INTO tx_test (name) VALUES ('Charlie')");
            die "Intentional error";
        })->get;
    };
    $err = $@;

    like $err, qr/Intentional error/, 'error propagated';

    my $count = $conn->query('SELECT COUNT(*) AS c FROM tx_test')->get;
    is $count->first->{c}, 0, 'transaction rolled back';

    $conn->release;
};

subtest 'nested transactions with savepoints' => sub {
    my $conn = $pg->connection->get;

    # Clear table
    $conn->query('DELETE FROM tx_test')->get;

    $conn->transaction(async sub {
        my ($tx) = @_;

        await $tx->query("INSERT INTO tx_test (name) VALUES ('Outer')");

        # Nested transaction
        await $tx->transaction(async sub {
            my ($tx2) = @_;
            await $tx2->query("INSERT INTO tx_test (name) VALUES ('Inner')");
        });

    })->get;

    my $count = $conn->query('SELECT COUNT(*) AS c FROM tx_test')->get;
    is $count->first->{c}, 2, 'both outer and inner committed';

    $conn->release;
};

subtest 'nested transaction rollback only inner' => sub {
    my $conn = $pg->connection->get;

    # Clear table
    $conn->query('DELETE FROM tx_test')->get;

    $conn->transaction(async sub {
        my ($tx) = @_;

        await $tx->query("INSERT INTO tx_test (name) VALUES ('Outer')");

        # Nested transaction that fails
        eval {
            await $tx->transaction(async sub {
                my ($tx2) = @_;
                await $tx2->query("INSERT INTO tx_test (name) VALUES ('Inner')");
                die "Inner failed";
            });
        };
        # Ignore inner error, continue with outer

        await $tx->query("INSERT INTO tx_test (name) VALUES ('AfterInner')");

    })->get;

    my $r = $conn->query('SELECT name FROM tx_test ORDER BY id')->get;
    is [ map { $_->{name} } @{$r->rows} ], ['Outer', 'AfterInner'],
        'inner rolled back, outer committed';

    $conn->release;
};

subtest 'isolation level' => sub {
    my $conn = $pg->connection->get;

    # Clear table
    $conn->query('DELETE FROM tx_test')->get;

    $conn->transaction(async sub {
        my ($tx) = @_;
        await $tx->query("INSERT INTO tx_test (name) VALUES ('Isolated')");
    }, isolation => 'serializable')->get;

    my $count = $conn->query('SELECT COUNT(*) AS c FROM tx_test')->get;
    is $count->first->{c}, 1, 'serializable transaction committed';

    $conn->release;
};

subtest 'in_transaction flag' => sub {
    my $conn = $pg->connection->get;

    ok !$conn->in_transaction, 'not in transaction before';

    $conn->transaction(async sub {
        my ($tx) = @_;
        ok $tx->in_transaction, 'in transaction inside block';
    })->get;

    ok !$conn->in_transaction, 'not in transaction after';

    $conn->release;
};

cleanup();
done_testing;
