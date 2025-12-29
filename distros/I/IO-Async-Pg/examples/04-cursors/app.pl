#!/usr/bin/env perl
#
# 04-cursors - Streaming large result sets
#
# This example shows how to:
#   - Use cursors for memory-efficient processing of large datasets
#   - Fetch results in batches
#   - Iterate with next(), each(), and all()
#   - Use cursors with parameters
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

    # Set up: create a test table with many rows
    $conn->query("SET client_min_messages TO warning")->get;
    $conn->query('DROP TABLE IF EXISTS large_data')->get;
    $conn->query('
        CREATE TABLE large_data (
            id SERIAL PRIMARY KEY,
            value TEXT
        )
    ')->get;

    # Insert 1000 rows
    print "Inserting 1000 rows...\n";
    $conn->query("
        INSERT INTO large_data (value)
        SELECT 'row_' || generate_series(1, 1000)
    ")->get;
    print "Done.\n\n";

    print "=== Batch Processing with next() ===\n\n";

    # Create a cursor with batch_size of 100
    # This fetches 100 rows at a time from the server
    my $cursor = $conn->cursor(
        'SELECT * FROM large_data ORDER BY id',
        { batch_size => 100 }
    )->get;

    print "Cursor created. Fetching in batches of 100:\n";

    my $batch_num = 0;
    while (my $batch = $cursor->next->get) {
        $batch_num++;
        my $first_id = $batch->[0]{id};
        my $last_id = $batch->[-1]{id};
        print "  Batch $batch_num: rows $first_id - $last_id (",
              scalar(@$batch), " rows)\n";
    }

    print "Total batches: $batch_num\n";
    $cursor->close->get;

    print "\n=== Row-by-Row with each() ===\n\n";

    # each() calls a callback for every row
    $cursor = $conn->cursor(
        'SELECT * FROM large_data WHERE id <= 10 ORDER BY id',
        { batch_size => 3 }
    )->get;

    my $count = $cursor->each(sub {
        my ($row) = @_;
        print "  Processing: id=$row->{id} value=$row->{value}\n";
    })->get;

    print "Processed $count rows\n";
    $cursor->close->get;

    print "\n=== Collect with all() ===\n\n";

    # all() collects remaining rows into an array
    # Use with caution on large datasets!
    $cursor = $conn->cursor(
        'SELECT * FROM large_data WHERE id BETWEEN 500 AND 510 ORDER BY id',
        { batch_size => 5 }
    )->get;

    my $rows = $cursor->all->get;
    print "Collected ", scalar(@$rows), " rows:\n";
    for my $row (@$rows) {
        print "  $row->{id}: $row->{value}\n";
    }
    $cursor->close->get;

    print "\n=== Cursors with Parameters ===\n\n";

    # You can use placeholders with cursors
    $cursor = $conn->cursor(
        'SELECT * FROM large_data WHERE id BETWEEN $1 AND $2 ORDER BY id',
        100, 120,
        { batch_size => 10 }
    )->get;

    my $total = 0;
    while (my $batch = $cursor->next->get) {
        $total += @$batch;
        print "  Fetched ", scalar(@$batch), " rows (total: $total)\n";
    }
    $cursor->close->get;

    print "\n=== Memory Efficiency ===\n\n";

    # Without cursors: loads ALL rows into memory at once
    # my $result = $conn->query('SELECT * FROM million_row_table')->get;
    # This could use gigabytes of RAM!

    # With cursors: only batch_size rows in memory at a time
    # Perfect for:
    #   - Exporting large datasets
    #   - ETL pipelines
    #   - Report generation
    #   - Data migrations

    print "Cursors keep memory usage constant regardless of result set size.\n";
    print "Only batch_size rows are held in memory at once.\n";

    # Clean up
    $conn->query('DROP TABLE large_data')->get;
    $conn->release;
};
if (my $e = $@) {
    die "Database error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
