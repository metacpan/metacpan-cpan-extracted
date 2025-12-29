# 01 - Basic Query

Your first IO::Async::Pg query. Demonstrates connecting to PostgreSQL, running simple queries, and accessing results.

## What it shows

- Creating a connection pool with `IO::Async::Pg->new`
- Adding the pool to an event loop
- Getting a connection with `$pg->connection`
- Executing queries with `$conn->query`
- Accessing results: `->first`, `->rows`, `->count`
- Releasing connections back to the pool

## Prerequisites

A running PostgreSQL server. No tables needed - uses built-in functions.

## Running

```bash
# With default localhost connection
perl app.pl

# With custom database URL
DATABASE_URL='postgresql://user:pass@host:5432/dbname' perl app.pl
```

## Expected output

```
Connected to PostgreSQL!

PostgreSQL version:
  PostgreSQL 16.1 on x86_64-pc-linux-musl, compiled by gcc...

Math check:
  1 + 1 = 2
  2 * 3 = 6

Generated series (5 rows):
  n = 1
  n = 2
  n = 3
  n = 4
  n = 5

Connection released.
Done!
```
