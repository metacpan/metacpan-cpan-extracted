# 02 - Placeholders

Safe parameterized queries using positional and named placeholders.

## What it shows

- Positional placeholders: `$1`, `$2`, `$3`, etc.
- Named placeholders: `:name`, `:value`, etc.
- Type casting with placeholders
- Why placeholders prevent SQL injection

## Positional vs Named

**Positional** - pass values as additional arguments:
```perl
$conn->query('SELECT $1 + $2', 10, 20);
```

**Named** - pass a hashref:
```perl
$conn->query(
    'SELECT :a + :b',
    { a => 10, b => 20 }
);
```

Named placeholders are converted to positional internally, so there's no performance difference. Use whichever is clearer for your query.

## Prerequisites

A running PostgreSQL server. No tables needed.

## Running

```bash
perl app.pl
```

## Expected output

```
=== Positional Placeholders ===

10 + 20 = 30
Doubled: hellohello
30 days after 2024-01-01: 2024-01-31

=== Named Placeholders ===

Full name: John Doe
Subtotal: $99.95
Total (with tax): $107.95
7 doubled: 14, squared: 49

=== Why Placeholders Matter ===

Malicious input safely escaped: '; DROP TABLE users; --
(The dangerous characters are treated as literal text)

Done!
```
