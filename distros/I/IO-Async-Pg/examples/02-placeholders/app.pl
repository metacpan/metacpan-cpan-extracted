#!/usr/bin/env perl
#
# 02-placeholders - Safe parameterized queries
#
# This example shows how to:
#   - Use positional placeholders ($1, $2, ...)
#   - Use named placeholders (:name, :value, ...)
#   - Avoid SQL injection by never interpolating values
#

use strict;
use warnings;

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

    print "=== Positional Placeholders ===\n\n";

    # PostgreSQL uses $1, $2, $3 for positional placeholders
    # Pass values as additional arguments to query()

    my $result = $conn->query(
        'SELECT $1::int + $2::int AS sum',
        10, 20
    )->get;
    print "10 + 20 = ", $result->first->{sum}, "\n";

    # Multiple uses of same placeholder
    $result = $conn->query(
        'SELECT $1::text || $1::text AS doubled',
        'hello'
    )->get;
    print "Doubled: ", $result->first->{doubled}, "\n";

    # With type casting for clarity
    $result = $conn->query(
        'SELECT $1::date + $2::interval AS future_date',
        '2024-01-01', '30 days'
    )->get;
    print "30 days after 2024-01-01: ", $result->first->{future_date}, "\n";

    print "\n=== Named Placeholders ===\n\n";

    # Named placeholders use :name syntax
    # Pass a hashref with the values

    $result = $conn->query(
        'SELECT :first_name || \' \' || :last_name AS full_name',
        { first_name => 'John', last_name => 'Doe' }
    )->get;
    print "Full name: ", $result->first->{full_name}, "\n";

    # Named placeholders are great for complex queries
    $result = $conn->query(
        'SELECT
            :quantity::int * :price::numeric AS subtotal,
            :quantity::int * :price::numeric * (1 + :tax_rate::numeric) AS total',
        {
            quantity => 5,
            price    => 19.99,
            tax_rate => 0.08,
        }
    )->get;
    my $row = $result->first;
    printf "Subtotal: \$%.2f\n", $row->{subtotal};
    printf "Total (with tax): \$%.2f\n", $row->{total};

    # Reusing named placeholders
    $result = $conn->query(
        'SELECT :val::int * 2 AS doubled, :val::int * :val::int AS squared',
        { val => 7 }
    )->get;
    $row = $result->first;
    print "7 doubled: $row->{doubled}, squared: $row->{squared}\n";

    print "\n=== Why Placeholders Matter ===\n\n";

    # NEVER do this (SQL injection vulnerability):
    #   my $name = "'; DROP TABLE users; --";
    #   $conn->query("SELECT * FROM users WHERE name = '$name'");
    #
    # ALWAYS use placeholders:
    #   $conn->query('SELECT * FROM users WHERE name = $1', $name);

    my $malicious_input = "'; DROP TABLE users; --";
    $result = $conn->query(
        'SELECT $1::text AS safely_escaped',
        $malicious_input
    )->get;
    print "Malicious input safely escaped: ", $result->first->{safely_escaped}, "\n";
    print "(The dangerous characters are treated as literal text)\n";

    $conn->release;
};
if (my $e = $@) {
    die "Database error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
