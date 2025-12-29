# 07 - Parallel Queries

Running multiple queries concurrently for better performance.

## What it shows

- Sequential vs parallel query execution
- Connection pooling enabling concurrency
- Real-world dashboard data fetching
- Pool statistics

## Why Parallel?

Sequential queries wait for each to complete:

```
Query 1 ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░  100ms
Query 2             ████████████░░░░░░░░░░░░░░░░  100ms
Query 3                         ████████████░░░░  100ms
Total: 300ms
```

Parallel queries run simultaneously:

```
Query 1 ████████████  100ms
Query 2 ████████████  100ms
Query 3 ████████████  100ms
Total: ~100ms (3x faster!)
```

## Pattern

```perl
# Create futures for parallel queries
my @futures;
for my $query (@queries) {
    my $f = (async sub {
        my $conn = await $pg->connection;  # Gets pooled connection
        my $result = await $conn->query($query);
        $conn->release;
        return $result;
    })->();
    push @futures, $f;
}

# Wait for all to complete
my @results = Future->wait_all(@futures)->get;
```

## When to Use Parallel Queries

**Good candidates:**
- Dashboard widgets (independent data)
- Search across multiple tables
- Aggregating from different sources
- Batch lookups

**Not suitable:**
- Queries that depend on previous results
- Queries that must see consistent data (use transaction instead)

## Prerequisites

A running PostgreSQL server. No tables needed.

## Running

```bash
perl app.pl
```

## Expected output

```
=== Sequential vs Parallel Queries ===

Running 5 queries SEQUENTIALLY...
  Sequential time: 0.52 seconds
  (104ms per query)

Running 5 queries IN PARALLEL...
  Parallel time: 0.11 seconds
  Speedup: 4.7x faster!

=== Real-World Example: Dashboard ===

Dashboard data (fetched in parallel):
  Active connections: 3
  Database size: 8.42 MB
  Tables in public: 0
  PostgreSQL: PostgreSQL 16.1

Fetched in 0.015 seconds

=== Connection Pool Stats ===

  Connections created: 6
  Current idle: 5
  Current active: 0
  Total: 5

=== Key Takeaways ===

1. Async queries allow true parallelism
2. Connection pooling manages concurrent connections
3. Independent queries should run in parallel
4. Dependent queries must run sequentially

Done!
```

## Connection Pool Sizing

The pool's `max_connections` limits parallelism:

| max_connections | Parallel queries | Notes |
|-----------------|------------------|-------|
| 1 | None (sequential) | Simple, but slow |
| 5 | Up to 5 | Good default |
| 20+ | High parallelism | Watch DB limits |

Don't exceed PostgreSQL's `max_connections` (default: 100).
