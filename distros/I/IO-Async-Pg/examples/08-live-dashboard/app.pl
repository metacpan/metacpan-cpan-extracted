#!/usr/bin/env perl
#
# 08-live-dashboard - Real-time metrics with pub/sub
#
# This example demonstrates:
#   - Simulated metrics collection
#   - Real-time updates via LISTEN/NOTIFY
#   - Live dashboard display
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
# Setup: Create metrics table
# ============================================================

sub setup_schema {
    my $conn = $pg->connection->get;
    $conn->query("SET client_min_messages TO warning")->get;
    $conn->query('DROP TABLE IF EXISTS metrics')->get;
    $conn->query('
        CREATE TABLE metrics (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            value NUMERIC NOT NULL,
            recorded_at TIMESTAMPTZ DEFAULT NOW()
        )
    ')->get;
    $conn->release;
}

# ============================================================
# Metrics Producer: Records metrics and notifies
# ============================================================

async sub record_metric {
    my ($name, $value) = @_;

    my $conn = await $pg->connection;

    await $conn->query(
        'INSERT INTO metrics (name, value) VALUES ($1, $2)',
        $name, $value
    );

    # Notify dashboard of new metric
    my $payload = $json->encode({ name => $name, value => $value });
    await $conn->query("NOTIFY metrics, " . $conn->dbh->quote($payload));

    $conn->release;
}

# ============================================================
# Dashboard: Subscribes and displays live updates
# ============================================================

my %current_metrics;
my $update_count = 0;

sub display_dashboard {
    # Clear screen (simple version)
    print "\n" . "=" x 50 . "\n";
    print "        LIVE DASHBOARD (update #$update_count)\n";
    print "=" x 50 . "\n\n";

    if (%current_metrics) {
        for my $name (sort keys %current_metrics) {
            my $value = $current_metrics{$name};
            my $bar = "#" x int($value / 5);
            printf "  %-15s %6.1f  %s\n", $name, $value, $bar;
        }
    } else {
        print "  Waiting for metrics...\n";
    }

    print "\n" . "-" x 50 . "\n";
}

# ============================================================
# Main: Run the demo
# ============================================================

eval {
    setup_schema();

    print "Starting Live Dashboard Demo\n";
    print "(Simulating 10 metric updates)\n\n";

    # Set up the dashboard subscriber
    my $pubsub = $pg->pubsub;

    $pubsub->subscribe('metrics', sub {
        my ($channel, $payload) = @_;
        my $data = $json->decode($payload);
        $current_metrics{$data->{name}} = $data->{value};
        $update_count++;
        display_dashboard();
    })->get;

    print "Dashboard subscribed to 'metrics' channel.\n";
    display_dashboard();

    # Simulate metrics being recorded (in real app, this would be separate process)
    my @metric_names = qw(cpu_usage memory_pct requests_sec latency_ms disk_io);

    for my $i (1..10) {
        # Pick a random metric and value
        my $name = $metric_names[int(rand(@metric_names))];
        my $value = 20 + rand(80);  # Random value 20-100

        # Record it (this triggers the notification)
        record_metric($name, $value)->get;

        # Process any pending notifications
        $loop->delay_future(after => 0.05)->get;
        $pubsub->_process_notifications;

        # Small delay between updates
        $loop->delay_future(after => 0.2)->get;
    }

    print "\n=== Final Metrics Summary ===\n\n";

    my $conn = $pg->connection->get;
    my $result = $conn->query('
        SELECT name, COUNT(*) AS updates, ROUND(AVG(value)::numeric, 1) AS avg_value
        FROM metrics
        GROUP BY name
        ORDER BY name
    ')->get;

    printf "  %-15s %8s %10s\n", "Metric", "Updates", "Avg Value";
    printf "  %-15s %8s %10s\n", "-" x 15, "-" x 8, "-" x 10;
    for my $row (@{$result->rows}) {
        printf "  %-15s %8d %10.1f\n", $row->{name}, $row->{updates}, $row->{avg_value};
    }

    # Clean up
    $conn->query('DROP TABLE metrics')->get;
    $conn->release;
    $pubsub->disconnect->get;

    print "\n=== How It Works ===\n\n";
    print "1. Producer inserts metric and sends NOTIFY\n";
    print "2. Dashboard receives notification instantly\n";
    print "3. Dashboard updates display in real-time\n";
    print "\nIn production:\n";
    print "  - Producers and dashboard are separate processes\n";
    print "  - Dashboard could be a web server pushing to browsers via SSE/WebSocket\n";
    print "  - Multiple dashboards can subscribe to same channel\n";
};
if (my $e = $@) {
    die "Error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
