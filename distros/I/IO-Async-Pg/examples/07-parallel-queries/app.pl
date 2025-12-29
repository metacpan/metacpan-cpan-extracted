#!/usr/bin/env perl
#
# 07-parallel-queries - Running queries concurrently
#
# This example demonstrates:
#   - Running multiple queries in parallel
#   - Connection pooling enabling concurrency
#   - Comparing sequential vs parallel performance
#

use strict;
use warnings;
use Future::AsyncAwait;
use Time::HiRes qw(time);

use IO::Async::Loop;
use IO::Async::Pg;

my $dsn = $ENV{DATABASE_URL} // 'postgresql://postgres:test@localhost:5432/test';

my $loop = IO::Async::Loop->new;
my $pg = IO::Async::Pg->new(
    dsn             => $dsn,
    min_connections => 1,
    max_connections => 10,  # Allow up to 10 parallel connections
);
$loop->add($pg);

# Simulate a slow query (100ms each)
sub slow_query {
    return 'SELECT pg_sleep(0.1), $1::int AS id';
}

eval {
    print "=== Sequential vs Parallel Queries ===\n\n";

    my $num_queries = 5;

    # ----------------------------------------
    # Sequential: One query at a time
    # ----------------------------------------
    print "Running $num_queries queries SEQUENTIALLY...\n";

    my $start = time();
    my $conn = $pg->connection->get;

    for my $i (1..$num_queries) {
        $conn->query(slow_query(), $i)->get;
    }

    $conn->release;
    my $sequential_time = time() - $start;

    printf "  Sequential time: %.2f seconds\n", $sequential_time;
    printf "  (%.0fms per query)\n\n", ($sequential_time / $num_queries) * 1000;

    # ----------------------------------------
    # Parallel: All queries at once
    # ----------------------------------------
    print "Running $num_queries queries IN PARALLEL...\n";

    $start = time();

    # Create futures for all queries
    my @futures;
    for my $i (1..$num_queries) {
        # Each query gets its own connection from the pool
        my $future = (async sub {
            my $c = await $pg->connection;
            my $result = await $c->query(slow_query(), $i);
            $c->release;
            return $result->first->{id};
        })->();
        push @futures, $future;
    }

    # Wait for all to complete
    my @results = Future->wait_all(@futures)->get;

    my $parallel_time = time() - $start;

    printf "  Parallel time: %.2f seconds\n", $parallel_time;
    printf "  Speedup: %.1fx faster!\n\n", $sequential_time / $parallel_time;

    # ----------------------------------------
    # Real-world example: Dashboard data
    # ----------------------------------------
    print "=== Real-World Example: Dashboard ===\n\n";

    # Imagine fetching data for a dashboard
    # Each query is independent and can run in parallel

    $start = time();

    my $user_count_f = (async sub {
        my $c = await $pg->connection;
        my $r = await $c->query('SELECT COUNT(*) AS n FROM pg_stat_activity');
        $c->release;
        return $r->first->{n};
    })->();

    my $db_size_f = (async sub {
        my $c = await $pg->connection;
        my $r = await $c->query('SELECT pg_database_size(current_database()) AS size');
        $c->release;
        return $r->first->{size};
    })->();

    my $version_f = (async sub {
        my $c = await $pg->connection;
        my $r = await $c->query('SELECT version() AS v');
        $c->release;
        return $r->first->{v};
    })->();

    my $tables_f = (async sub {
        my $c = await $pg->connection;
        my $r = await $c->query("
            SELECT COUNT(*) AS n
            FROM information_schema.tables
            WHERE table_schema = 'public'
        ");
        $c->release;
        return $r->first->{n};
    })->();

    # Wait for all dashboard data
    my ($users, $size, $version, $tables) = (
        $user_count_f->get,
        $db_size_f->get,
        $version_f->get,
        $tables_f->get,
    );

    my $dashboard_time = time() - $start;

    print "Dashboard data (fetched in parallel):\n";
    print "  Active connections: $users\n";
    printf "  Database size: %.2f MB\n", $size / 1024 / 1024;
    print "  Tables in public: $tables\n";
    print "  PostgreSQL: ", (split /,/, $version)[0], "\n";
    printf "\nFetched in %.3f seconds\n", $dashboard_time;

    # ----------------------------------------
    # Pool statistics
    # ----------------------------------------
    print "\n=== Connection Pool Stats ===\n\n";

    my $stats = $pg->stats;
    print "  Connections created: $stats->{created}\n";
    print "  Current idle: ", $pg->idle_count, "\n";
    print "  Current active: ", $pg->active_count, "\n";
    print "  Total: ", $pg->total_count, "\n";

    print "\n=== Key Takeaways ===\n\n";
    print "1. Async queries allow true parallelism\n";
    print "2. Connection pooling manages concurrent connections\n";
    print "3. Independent queries should run in parallel\n";
    print "4. Dependent queries must run sequentially\n";
};
if (my $e = $@) {
    die "Error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
