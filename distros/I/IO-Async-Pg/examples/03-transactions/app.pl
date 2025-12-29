#!/usr/bin/env perl
#
# 03-transactions - Atomic operations with transactions
#
# This example shows how to:
#   - Use transaction() for automatic BEGIN/COMMIT/ROLLBACK
#   - Handle errors that trigger rollback
#   - Use nested transactions (savepoints)
#   - Set isolation levels
#

use strict;
use warnings;
use Future::AsyncAwait;

use IO::Async::Loop;
use IO::Async::Pg;

my $dsn = $ENV{DATABASE_URL} // 'postgresql://postgres:test@localhost:5432/test';

my $loop = IO::Async::Loop->new;
my $pg = IO::Async::Pg->new(
    dsn             => $dsn,
    min_connections => 1,
    max_connections => 5,
);
$loop->add($pg);

eval {
    my $conn = $pg->connection->get;

    # Set up: create a test table
    $conn->query("SET client_min_messages TO warning")->get;
    $conn->query('DROP TABLE IF EXISTS accounts')->get;
    $conn->query('
        CREATE TABLE accounts (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            balance NUMERIC(10,2) NOT NULL DEFAULT 0
        )
    ')->get;

    print "=== Basic Transaction ===\n\n";

    # transaction() takes an async sub and wraps it in BEGIN/COMMIT
    # If the sub dies, it automatically rolls back

    $conn->transaction(async sub {
        my ($tx) = @_;  # $tx is the same connection, but inside a transaction

        await $tx->query(
            "INSERT INTO accounts (name, balance) VALUES (\$1, \$2)",
            'Alice', 1000
        );
        await $tx->query(
            "INSERT INTO accounts (name, balance) VALUES (\$1, \$2)",
            'Bob', 500
        );

        print "Inserted Alice and Bob inside transaction\n";
        # Transaction commits automatically when sub completes
    })->get;

    # Verify the data persisted
    my $result = $conn->query('SELECT name, balance FROM accounts ORDER BY id')->get;
    print "After commit:\n";
    for my $row (@{$result->rows}) {
        print "  $row->{name}: \$$row->{balance}\n";
    }

    print "\n=== Rollback on Error ===\n\n";

    # If anything dies inside transaction(), changes are rolled back
    eval {
        $conn->transaction(async sub {
            my ($tx) = @_;

            await $tx->query(
                "UPDATE accounts SET balance = balance - 200 WHERE name = \$1",
                'Alice'
            );
            print "Deducted \$200 from Alice (not yet committed)\n";

            # Simulate an error
            die "Oops! Something went wrong!\n";

            # This never runs
            await $tx->query(
                "UPDATE accounts SET balance = balance + 200 WHERE name = \$1",
                'Bob'
            );
        })->get;
    };
    if (my $e = $@) {
        print "Caught error: $e";
        print "Transaction was rolled back automatically\n";
    }

    # Verify Alice still has her money
    $result = $conn->query(
        'SELECT balance FROM accounts WHERE name = $1',
        'Alice'
    )->get;
    print "Alice's balance after rollback: \$", $result->first->{balance}, "\n";

    print "\n=== Nested Transactions (Savepoints) ===\n\n";

    # Nested transaction() calls use SAVEPOINTs
    # Inner failures can be caught without rolling back outer work

    $conn->transaction(async sub {
        my ($tx) = @_;

        await $tx->query(
            "UPDATE accounts SET balance = balance - 100 WHERE name = \$1",
            'Alice'
        );
        print "Outer: Deducted \$100 from Alice\n";

        # Nested transaction
        eval {
            await $tx->transaction(async sub {
                my ($tx2) = @_;

                await $tx2->query(
                    "UPDATE accounts SET balance = balance + 100 WHERE name = \$1",
                    'Bob'
                );
                print "Inner: Added \$100 to Bob\n";

                die "Inner transaction failed!\n";
            });
        };
        if (my $e = $@) {
            print "Inner transaction rolled back: $e";
            print "Outer transaction continues...\n";
        }

        # Give the money to a new account instead
        await $tx->query(
            "INSERT INTO accounts (name, balance) VALUES (\$1, \$2)",
            'Charlie', 100
        );
        print "Outer: Created Charlie with \$100\n";

    })->get;

    $result = $conn->query('SELECT name, balance FROM accounts ORDER BY id')->get;
    print "\nFinal balances:\n";
    for my $row (@{$result->rows}) {
        print "  $row->{name}: \$$row->{balance}\n";
    }

    print "\n=== Isolation Levels ===\n\n";

    # You can specify isolation level for stricter guarantees
    $conn->transaction(async sub {
        my ($tx) = @_;
        my $r = await $tx->query('SELECT COUNT(*) AS c FROM accounts');
        print "Account count (serializable): ", $r->first->{c}, "\n";
    }, isolation => 'serializable')->get;

    # Clean up
    $conn->query('DROP TABLE accounts')->get;
    $conn->release;
};
if (my $e = $@) {
    die "Database error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
