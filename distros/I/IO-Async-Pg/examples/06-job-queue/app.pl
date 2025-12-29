#!/usr/bin/env perl
#
# 06-job-queue - Simple job queue with transactions and pub/sub
#
# This example demonstrates a complete mini-application:
#   - Jobs table for persistent storage
#   - Transactions for atomic job claiming
#   - Pub/sub for instant job notifications
#   - Worker that processes jobs
#

use strict;
use warnings;
use Future::AsyncAwait;

use IO::Async::Loop;
use IO::Async::Pg;
use JSON::PP;

my $dsn = $ENV{DATABASE_URL} // 'postgresql://postgres:test@localhost:5432/test';

my $loop = IO::Async::Loop->new;
my $pg = IO::Async::Pg->new(
    dsn             => $dsn,
    min_connections => 2,
    max_connections => 5,
);
$loop->add($pg);

my $json = JSON::PP->new->utf8;

# ============================================================
# Setup: Create the jobs table
# ============================================================

sub setup_schema {
    my $conn = $pg->connection->get;
    $conn->query("SET client_min_messages TO warning")->get;
    $conn->query('DROP TABLE IF EXISTS jobs')->get;
    $conn->query('
        CREATE TABLE jobs (
            id SERIAL PRIMARY KEY,
            type TEXT NOT NULL,
            payload JSONB NOT NULL,
            status TEXT NOT NULL DEFAULT \'pending\',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            started_at TIMESTAMPTZ,
            completed_at TIMESTAMPTZ,
            result JSONB
        )
    ')->get;
    $conn->query('CREATE INDEX jobs_status_idx ON jobs(status)')->get;
    $conn->release;
    print "Schema created.\n\n";
}

# ============================================================
# Producer: Enqueue jobs
# ============================================================

async sub enqueue_job {
    my ($type, $payload) = @_;

    my $conn = await $pg->connection;
    my $payload_json = $json->encode($payload);

    my $result = await $conn->query(
        'INSERT INTO jobs (type, payload) VALUES ($1, $2) RETURNING id',
        $type, $payload_json
    );
    my $job_id = $result->first->{id};

    # Notify workers that a new job is available
    await $conn->query("NOTIFY new_job, '$job_id'");

    $conn->release;
    return $job_id;
}

# ============================================================
# Worker: Claim and process jobs
# ============================================================

async sub claim_job {
    my ($conn) = @_;

    # Use a transaction with FOR UPDATE SKIP LOCKED
    # This ensures only one worker claims each job
    my $job;

    await $conn->transaction(async sub {
        my ($tx) = @_;

        my $result = await $tx->query('
            SELECT id, type, payload
            FROM jobs
            WHERE status = \'pending\'
            ORDER BY created_at
            LIMIT 1
            FOR UPDATE SKIP LOCKED
        ');

        return unless $result->count;

        $job = $result->first;

        await $tx->query(
            'UPDATE jobs SET status = \'running\', started_at = NOW() WHERE id = $1',
            $job->{id}
        );
    });

    return $job;
}

async sub complete_job {
    my ($conn, $job_id, $result) = @_;

    my $result_json = $json->encode($result);
    await $conn->query(
        'UPDATE jobs SET status = \'completed\', completed_at = NOW(), result = $1 WHERE id = $2',
        $result_json, $job_id
    );
}

async sub fail_job {
    my ($conn, $job_id, $error) = @_;

    await $conn->query(
        'UPDATE jobs SET status = \'failed\', completed_at = NOW(), result = $1 WHERE id = $2',
        $json->encode({ error => $error }), $job_id
    );
}

# Process a single job based on its type
sub process_job {
    my ($job) = @_;

    my $payload = ref($job->{payload}) ? $job->{payload} : $json->decode($job->{payload});

    if ($job->{type} eq 'email') {
        # Simulate sending email
        print "    Sending email to: $payload->{to}\n";
        return { sent => 1, to => $payload->{to} };
    }
    elsif ($job->{type} eq 'report') {
        # Simulate generating report
        print "    Generating report: $payload->{name}\n";
        return { generated => 1, name => $payload->{name} };
    }
    else {
        die "Unknown job type: $job->{type}";
    }
}

# ============================================================
# Main: Demo the queue
# ============================================================

eval {
    setup_schema();

    print "=== Enqueueing Jobs ===\n\n";

    # Enqueue some jobs
    my @job_ids;
    for my $job (
        [ email  => { to => 'alice@example.com', subject => 'Hello' } ],
        [ email  => { to => 'bob@example.com', subject => 'Hi' } ],
        [ report => { name => 'Monthly Sales' } ],
        [ email  => { to => 'charlie@example.com', subject => 'Hey' } ],
        [ report => { name => 'User Activity' } ],
    ) {
        my $id = enqueue_job($job->[0], $job->[1])->get;
        push @job_ids, $id;
        print "  Enqueued job #$id: $job->[0]\n";
    }

    print "\n=== Processing Jobs ===\n\n";

    # Process all pending jobs
    my $conn = $pg->connection->get;
    my $processed = 0;

    while (my $job = claim_job($conn)->get) {
        print "  Worker claimed job #$job->{id} ($job->{type})\n";

        eval {
            my $result = process_job($job);
            complete_job($conn, $job->{id}, $result)->get;
            print "    Completed!\n";
            $processed++;
        };
        if (my $e = $@) {
            fail_job($conn, $job->{id}, "$e")->get;
            print "    Failed: $e\n";
        }
    }

    print "\nProcessed $processed jobs.\n";

    print "\n=== Final Job Status ===\n\n";

    my $result = $conn->query('
        SELECT id, type, status, result
        FROM jobs
        ORDER BY id
    ')->get;

    for my $row (@{$result->rows}) {
        print "  Job #$row->{id}: $row->{type} - $row->{status}\n";
    }

    # Clean up
    $conn->query('DROP TABLE jobs')->get;
    $conn->release;

    print "\n=== Pattern Summary ===\n\n";
    print "This pattern provides:\n";
    print "  - Persistent jobs (survive restarts)\n";
    print "  - Atomic claiming (no double-processing)\n";
    print "  - Instant notifications (pub/sub)\n";
    print "  - Status tracking\n";
    print "  - Error handling\n";
};
if (my $e = $@) {
    die "Error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
