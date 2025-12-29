# 08 - Live Dashboard

Real-time metrics display using pub/sub.

## What it shows

- Metrics recording with instant notifications
- Live dashboard updates via LISTEN/NOTIFY
- Pattern for real-time data streaming

## Architecture

```
┌─────────────────┐         NOTIFY           ┌─────────────────┐
│ Metrics Producer│ ─────────────────────────│    Dashboard    │
│                 │                          │                 │
│ record_metric() │                          │  subscribe()    │
│ INSERT + NOTIFY │                          │  display()      │
└────────┬────────┘                          └────────┬────────┘
         │                                            │
         │                                            │
         ▼                                            ▼
    ┌─────────────────────────────────────────────────────┐
    │                    PostgreSQL                       │
    │  metrics table + LISTEN/NOTIFY channels             │
    └─────────────────────────────────────────────────────┘
```

## Pattern

**Producer (records metrics):**
```perl
async sub record_metric {
    my ($name, $value) = @_;
    my $conn = await $pg->connection;

    await $conn->query('INSERT INTO metrics ...', $name, $value);
    await $conn->query("NOTIFY metrics, '$payload'");

    $conn->release;
}
```

**Dashboard (receives updates):**
```perl
my $pubsub = $pg->pubsub;

$pubsub->subscribe('metrics', sub {
    my ($channel, $payload) = @_;
    update_display($payload);
})->get;

# Run event loop to receive notifications
$loop->run;
```

## Real-World Extensions

This pattern extends naturally to:

### Web Dashboard
```perl
# In a web server (e.g., Mojolicious)
$pubsub->subscribe('metrics', sub {
    my ($channel, $payload) = @_;
    # Push to all connected WebSocket clients
    for my $client (@websocket_clients) {
        $client->send($payload);
    }
});
```

### Multiple Channels
```perl
$pubsub->subscribe('cpu', sub { update_cpu_widget(@_) });
$pubsub->subscribe('memory', sub { update_memory_widget(@_) });
$pubsub->subscribe('alerts', sub { show_alert(@_) });
```

### Filtered Subscriptions
```perl
# PostgreSQL NOTIFY doesn't support filters
# But you can filter in the callback:
$pubsub->subscribe('metrics', sub {
    my ($channel, $payload) = @_;
    my $data = decode_json($payload);
    return unless $data->{severity} eq 'critical';
    show_alert($data);
});
```

## Prerequisites

A running PostgreSQL server. The example creates and drops its own table.

## Running

```bash
perl app.pl
```

## Expected output

```
Starting Live Dashboard Demo
(Simulating 10 metric updates)

Dashboard subscribed to 'metrics' channel.

==================================================
        LIVE DASHBOARD (update #0)
==================================================

  Waiting for metrics...

--------------------------------------------------

==================================================
        LIVE DASHBOARD (update #1)
==================================================

  cpu_usage          67.3  #############

--------------------------------------------------

... (updates continue)

==================================================
        LIVE DASHBOARD (update #10)
==================================================

  cpu_usage          45.2  #########
  disk_io            78.9  ###############
  latency_ms         32.1  ######
  memory_pct         89.4  #################
  requests_sec       56.7  ###########

--------------------------------------------------

=== Final Metrics Summary ===

  Metric            Updates  Avg Value
  --------------- -------- ----------
  cpu_usage              3       52.4
  disk_io                2       71.2
  ...

Done!
```

## Production Considerations

- Use connection heartbeats to detect disconnections
- Implement reconnection logic
- Consider message ordering requirements
- For high-volume updates, batch notifications
