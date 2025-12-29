# 04 - Cursors

Streaming large result sets with constant memory usage.

## What it shows

- Creating cursors with `$conn->cursor()`
- Batch processing with `next()`
- Row-by-row iteration with `each()`
- Collecting results with `all()`
- Using placeholders with cursors

## Why Cursors?

Regular queries load the entire result set into memory:

```perl
# Dangerous with large tables!
my $result = $conn->query('SELECT * FROM million_rows')->get;
# All million rows now in memory
```

Cursors fetch rows in batches:

```perl
my $cursor = $conn->cursor(
    'SELECT * FROM million_rows',
    { batch_size => 1000 }
)->get;

while (my $batch = $cursor->next->get) {
    # Only 1000 rows in memory at a time
    process_batch($batch);
}
$cursor->close->get;
```

## Methods

| Method | Returns | Use Case |
|--------|---------|----------|
| `next()` | Arrayref of rows, or undef when done | Batch processing |
| `each($cb)` | Count of rows processed | Row-by-row processing |
| `all()` | All remaining rows | Small result sets |
| `close()` | - | Release cursor resources |

## Prerequisites

A running PostgreSQL server. The example creates and drops its own table.

## Running

```bash
perl app.pl
```

## Expected output

```
Inserting 1000 rows...
Done.

=== Batch Processing with next() ===

Cursor created. Fetching in batches of 100:
  Batch 1: rows 1 - 100 (100 rows)
  Batch 2: rows 101 - 200 (100 rows)
  ...
  Batch 10: rows 901 - 1000 (100 rows)
Total batches: 10

=== Row-by-Row with each() ===

  Processing: id=1 value=row_1
  Processing: id=2 value=row_2
  ...
Processed 10 rows

=== Collect with all() ===

Collected 11 rows:
  500: row_500
  501: row_501
  ...

=== Cursors with Parameters ===

  Fetched 10 rows (total: 10)
  Fetched 10 rows (total: 20)
  Fetched 1 rows (total: 21)

=== Memory Efficiency ===

Cursors keep memory usage constant regardless of result set size.
Only batch_size rows are held in memory at once.

Done!
```
