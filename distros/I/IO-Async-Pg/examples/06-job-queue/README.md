# 06 - Job Queue

A simple but complete job queue using transactions and pub/sub.

## What it shows

- **Transactions** for atomic job claiming with `FOR UPDATE SKIP LOCKED`
- **Pub/sub** for instant "new job" notifications
- **JSONB** for flexible job payloads
- **Status tracking** with timestamps

## Architecture

```
┌─────────────┐     NOTIFY      ┌─────────────┐
│  Producer   │ ───────────────▶│   Worker    │
│             │                 │             │
│ enqueue_job │                 │  claim_job  │
└──────┬──────┘                 └──────┬──────┘
       │                               │
       │ INSERT                        │ SELECT FOR UPDATE
       │                               │ SKIP LOCKED
       ▼                               ▼
  ┌─────────────────────────────────────────┐
  │              jobs table                 │
  │  id | type | payload | status | ...     │
  └─────────────────────────────────────────┘
```

## Key Techniques

### Atomic Job Claiming

```perl
await $conn->transaction(async sub {
    my ($tx) = @_;

    # FOR UPDATE SKIP LOCKED prevents race conditions
    my $result = await $tx->query('
        SELECT * FROM jobs
        WHERE status = \'pending\'
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    ');

    return unless $result->count;
    my $job = $result->first;

    await $tx->query(
        'UPDATE jobs SET status = \'running\' WHERE id = $1',
        $job->{id}
    );
});
```

### Instant Notifications

```perl
# Producer notifies after insert
await $conn->query("NOTIFY new_job, '$job_id'");

# Worker listens
$pubsub->subscribe('new_job', sub {
    my ($channel, $job_id) = @_;
    # Wake up and claim the job
});
```

## Job States

| Status | Meaning |
|--------|---------|
| pending | Waiting to be processed |
| running | Currently being processed |
| completed | Finished successfully |
| failed | Processing failed |

## Prerequisites

A running PostgreSQL server. The example creates and drops its own table.

## Running

```bash
perl app.pl
```

## Expected output

```
Schema created.

=== Enqueueing Jobs ===

  Enqueued job #1: email
  Enqueued job #2: email
  Enqueued job #3: report
  ...

=== Processing Jobs ===

  Worker claimed job #1 (email)
    Sending email to: alice@example.com
    Completed!
  Worker claimed job #2 (email)
    Sending email to: bob@example.com
    Completed!
  ...

=== Final Job Status ===

  Job #1: email - completed
  Job #2: email - completed
  ...

Done!
```

## Production Considerations

For production use, consider adding:

- Retry logic with backoff
- Dead letter queue for failed jobs
- Job timeouts
- Priority queues
- Scheduled jobs (run at specific time)
