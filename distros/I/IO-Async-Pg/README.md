# IO::Async::Pg

Async PostgreSQL client for IO::Async with connection pooling.

**WARNING: This is extremely beta software.** The API is subject to change without notice. Use in production at your own peril.

## Features

- Connection pooling with automatic management
- Async query execution with positional (`$1`) and named (`:name`) placeholders
- Transaction support with savepoints for nesting
- Streaming cursors for large result sets
- LISTEN/NOTIFY pub/sub

## Synopsis

```perl
use IO::Async::Loop;
use IO::Async::Pg;

my $loop = IO::Async::Loop->new;
my $pg = IO::Async::Pg->new(
    dsn             => 'postgresql://user:pass@localhost/mydb',
    min_connections => 2,
    max_connections => 10,
);
$loop->add($pg);

my $conn = $pg->connection->get;
my $result = $conn->query('SELECT * FROM users WHERE id = $1', 42)->get;
print $result->first->{name};
$conn->release;
```

## Installation

```bash
cpanm IO::Async::Pg
```

## Examples

See the `examples/` directory for working examples covering all major features.

## Contributing

See [CONTRIBUTORS.md](CONTRIBUTORS.md) for development setup, testing, and contribution guidelines.

## License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

John Napiorkowski <jjn1056@yahoo.com>
