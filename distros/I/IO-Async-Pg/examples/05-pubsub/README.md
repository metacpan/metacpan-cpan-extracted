# 05 - Pub/Sub

Real-time messaging with PostgreSQL LISTEN/NOTIFY.

## What it shows

- Creating a pubsub instance with `$pg->pubsub`
- Subscribing to channels with callbacks
- Publishing messages with `notify()`
- Multiple channels and subscribers
- Unsubscribing

## Basic Usage

```perl
my $pubsub = $pg->pubsub;

# Subscribe
$pubsub->subscribe('my_channel', sub {
    my ($channel, $payload, $pid) = @_;
    print "Got: $payload\n";
})->get;

# Publish
$pubsub->notify('my_channel', 'Hello!')->get;

# Unsubscribe
$pubsub->unsubscribe('my_channel')->get;

# Clean up
$pubsub->disconnect->get;
```

## How It Works

1. `pubsub` gets a dedicated connection from the pool
2. It sends `LISTEN channel` for each subscription
3. PostgreSQL pushes notifications to that connection
4. Callbacks are invoked when notifications arrive

## Limitations

- **Single process only**: LISTEN/NOTIFY works within one PostgreSQL connection. For multi-server deployments, use Redis, RabbitMQ, or another message broker.
- **No persistence**: If no one is listening, the message is lost.
- **Payload size**: Limited to ~8000 bytes.

## Use Cases

- Real-time notifications (new messages, comments)
- Cache invalidation across workers
- Job queue "work available" signals
- Live dashboard updates
- Simple chat applications

## Prerequisites

A running PostgreSQL server. No tables needed.

## Running

```bash
perl app.pl
```

## Expected output

```
=== PostgreSQL LISTEN/NOTIFY Pub/Sub ===

Subscribing to 'events' channel...
Subscribed!

Publishing messages...
  Received on 'events': Hello from pubsub! (from PID 12345)
  Received on 'events': Hello from connection! (from PID 12346)

Received 2 messages

=== Multiple Channels ===

Subscribed to: orders, users
Total channels: 3

  [orders] New order #12345
  [users] User john@example.com logged in
  [orders] Order #12345 shipped

Message counts: orders=2, users=1

...

Done!
```
