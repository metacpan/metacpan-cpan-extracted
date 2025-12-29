#!/usr/bin/env perl
#
# 05-pubsub - Real-time messaging with LISTEN/NOTIFY
#
# This example shows how to:
#   - Subscribe to channels
#   - Receive notifications
#   - Publish messages
#   - Use pub/sub for real-time updates
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
    print "=== PostgreSQL LISTEN/NOTIFY Pub/Sub ===\n\n";

    # Create a pubsub instance
    # This gets its own dedicated connection for listening
    my $pubsub = $pg->pubsub;

    print "Subscribing to 'events' channel...\n";

    # Subscribe with a callback
    # The callback receives: channel name, payload, and sender's PID
    my @received;
    $pubsub->subscribe('events', sub {
        my ($channel, $payload, $pid) = @_;
        push @received, $payload;
        print "  Received on '$channel': $payload (from PID $pid)\n";
    })->get;

    print "Subscribed!\n\n";

    # Send some notifications
    # In real apps, these would come from other processes/connections
    print "Publishing messages...\n";

    # Method 1: Use the pubsub instance
    $pubsub->notify('events', 'Hello from pubsub!')->get;

    # Method 2: Use any connection with raw NOTIFY
    my $conn = $pg->connection->get;
    $conn->query("NOTIFY events, 'Hello from connection!'")->get;
    $conn->release;

    # Give notifications time to arrive and process them
    $loop->delay_future(after => 0.1)->get;
    $pubsub->_process_notifications;

    print "\nReceived ", scalar(@received), " messages\n";

    print "\n=== Multiple Channels ===\n\n";

    # You can subscribe to multiple channels
    my %counts;
    $pubsub->subscribe('orders', sub {
        my ($channel, $payload) = @_;
        $counts{orders}++;
        print "  [orders] $payload\n";
    })->get;

    $pubsub->subscribe('users', sub {
        my ($channel, $payload) = @_;
        $counts{users}++;
        print "  [users] $payload\n";
    })->get;

    print "Subscribed to: orders, users\n";
    print "Total channels: ", $pubsub->subscribed_channels, "\n\n";

    # Send to different channels
    $pubsub->notify('orders', 'New order #12345')->get;
    $pubsub->notify('users', 'User john@example.com logged in')->get;
    $pubsub->notify('orders', 'Order #12345 shipped')->get;

    $loop->delay_future(after => 0.1)->get;
    $pubsub->_process_notifications;

    print "\nMessage counts: orders=$counts{orders}, users=$counts{users}\n";

    print "\n=== Multiple Subscribers ===\n\n";

    # Multiple callbacks can subscribe to the same channel
    my $cb1_count = 0;
    my $cb2_count = 0;

    my $cb1 = sub { $cb1_count++ };
    my $cb2 = sub { $cb2_count++ };

    $pubsub->subscribe('broadcast', $cb1)->get;
    $pubsub->subscribe('broadcast', $cb2)->get;

    $pubsub->notify('broadcast', 'To everyone!')->get;

    $loop->delay_future(after => 0.1)->get;
    $pubsub->_process_notifications;

    print "Both callbacks received the message:\n";
    print "  Callback 1: $cb1_count messages\n";
    print "  Callback 2: $cb2_count messages\n";

    print "\n=== Unsubscribe ===\n\n";

    # Unsubscribe a specific callback
    $pubsub->unsubscribe('broadcast', $cb1)->get;
    print "Unsubscribed callback 1 from 'broadcast'\n";

    # Unsubscribe all callbacks from a channel
    $pubsub->unsubscribe('orders')->get;
    print "Unsubscribed all from 'orders'\n";

    # Unsubscribe from everything
    $pubsub->unsubscribe_all->get;
    print "Unsubscribed from all channels\n";
    print "Remaining channels: ", $pubsub->subscribed_channels, "\n";

    # Clean up
    $pubsub->disconnect->get;

    print "\n=== Use Cases ===\n\n";
    print "LISTEN/NOTIFY is great for:\n";
    print "  - Real-time notifications (new messages, updates)\n";
    print "  - Cache invalidation signals\n";
    print "  - Job queue notifications\n";
    print "  - Live dashboards\n";
    print "  - Chat applications\n";
    print "\nNote: This is in-process only. For multi-server setups,\n";
    print "use Redis or another external message broker.\n";
};
if (my $e = $@) {
    die "Database error: $e\n";
}

$loop->remove($pg);
print "\nDone!\n";
