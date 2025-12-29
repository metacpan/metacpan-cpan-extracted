# 03 - Transactions

Atomic operations with automatic commit/rollback, nested transactions, and isolation levels.

## What it shows

- `transaction()` for automatic BEGIN/COMMIT
- Automatic ROLLBACK on exception
- Nested transactions using SAVEPOINTs
- Isolation level specification

## Basic Usage

```perl
$conn->transaction(async sub {
    my ($tx) = @_;

    await $tx->query('INSERT INTO ...');
    await $tx->query('UPDATE ...');

    # Commits automatically on success
    # Rolls back automatically on die/exception
})->get;
```

## Nested Transactions

```perl
$conn->transaction(async sub {
    my ($tx) = @_;

    await $tx->query('UPDATE ...');  # Outer work

    try {
        await $tx->transaction(async sub {
            my ($tx2) = @_;
            await $tx2->query('UPDATE ...');  # Uses SAVEPOINT
            die "oops";
        });
    } catch ($e) {
        # Inner rolled back to savepoint
        # Outer continues
    }

    await $tx->query('INSERT ...');  # More outer work
})->get;
```

## Prerequisites

A running PostgreSQL server. The example creates and drops its own table.

## Running

```bash
perl app.pl
```

## Expected output

```
=== Basic Transaction ===

Inserted Alice and Bob inside transaction
After commit:
  Alice: $1000.00
  Bob: $500.00

=== Rollback on Error ===

Deducted $200 from Alice (not yet committed)
Caught error: Oops! Something went wrong!
Transaction was rolled back automatically
Alice's balance after rollback: $1000.00

=== Nested Transactions (Savepoints) ===

Outer: Deducted $100 from Alice
Inner: Added $100 to Bob
Inner transaction rolled back: Inner transaction failed!
Outer transaction continues...
Outer: Created Charlie with $100

Final balances:
  Alice: $900.00
  Bob: $500.00
  Charlie: $100.00

=== Isolation Levels ===

Account count (serializable): 3

Done!
```
