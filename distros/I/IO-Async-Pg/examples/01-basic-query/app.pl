#!/usr/bin/env perl
#
# 01-basic-query - Your first IO::Async::Pg query
#
# This example shows how to:
#   - Create a connection pool
#   - Get a connection
#   - Execute a simple query
#   - Access the results
#   - Release the connection back to the pool
#

use strict;
use warnings;

use IO::Async::Loop;
use IO::Async::Pg;

# Database URL from environment, or sensible default
my $dsn = $ENV{DATABASE_URL} // 'postgresql://postgres:test@localhost:5432/test';

# Create the event loop
my $loop = IO::Async::Loop->new;

# Create the connection pool
my $pg = IO::Async::Pg->new(
    dsn             => $dsn,
    min_connections => 1,    # Keep at least 1 connection ready
    max_connections => 5,    # Allow up to 5 concurrent connections
);

# Add the pool to the event loop
$loop->add($pg);

# Get a connection and run queries
# Note: We use ->get to block and wait for the Future to resolve
#       In async subs, you'd use 'await' instead

eval {
    # Get a connection from the pool
    my $conn = $pg->connection->get;
    print "Connected to PostgreSQL!\n\n";

    # Simple query - no parameters
    my $result = $conn->query('SELECT version()')->get;
    print "PostgreSQL version:\n";
    print "  ", $result->first->{version}, "\n\n";

    # Query returning multiple columns
    $result = $conn->query('SELECT 1 + 1 AS sum, 2 * 3 AS product')->get;
    my $row = $result->first;
    print "Math check:\n";
    print "  1 + 1 = $row->{sum}\n";
    print "  2 * 3 = $row->{product}\n\n";

    # Query returning multiple rows
    $result = $conn->query('SELECT generate_series(1, 5) AS n')->get;
    print "Generated series (", $result->count, " rows):\n";
    for my $row (@{$result->rows}) {
        print "  n = $row->{n}\n";
    }

    # Release the connection back to the pool
    $conn->release;
    print "\nConnection released.\n";
};
if (my $e = $@) {
    die "Database error: $e\n";
}

# Clean up
$loop->remove($pg);
print "Done!\n";
