<!-- DO NOT EDIT — regenerated from lib/EV/Gearman.pm POD by tools/gen-readme.pl -->

# NAME

EV::Gearman - asynchronous Gearman client and worker on libev

# SYNOPSIS

    use EV;
    use EV::Gearman;

    # ----- client -----
    my $cli = EV::Gearman->new(host => '127.0.0.1', port => 4730);

    # foreground job: callback fires once on WORK_COMPLETE / WORK_FAIL,
    # after any number of intermediate WORK_DATA / WORK_STATUS events
    $cli->submit_job(reverse => 'hello', sub {
        my ($result, $err) = @_;
        die "job failed: $err" if $err;
        print "got: $result\n";          # "olleh"
        EV::break;
    });

    # foreground job with progress events
    $cli->submit_job(crunch => $payload, {
        unique     => 'job-key',         # de-duplicate identical jobs
        on_data    => sub { print "partial: $_[0]\n"     },
        on_status  => sub { printf "%d/%d\n", @_         },
        on_warning => sub { warn "worker warning: $_[0]" },
    }, sub {
        my ($result, $err) = @_;
        ...
    });

    # background job: callback fires once on JOB_CREATED with handle
    $cli->submit_job_bg('mail::send', $payload, sub {
        my ($handle, $err) = @_;
        warn "queued: $handle\n";
    });

    # ----- worker -----
    my $w = EV::Gearman->new(
        host       => '127.0.0.1',
        port       => 4730,
        client_id  => "worker-$$",
        reconnect  => 1,
    );

    # synchronous worker: return value -> WORK_COMPLETE; die -> WORK_FAIL
    $w->register_function(reverse => sub {
        my ($job) = @_;                  # EV::Gearman::Job
        return scalar reverse $job->workload;
    });

    # asynchronous worker: defer completion via a timer / external IO
    $w->register_function(slow => { async => 1 }, sub {
        my $job = shift;
        my $t; $t = EV::timer 5, 0, sub { $job->complete("done"); undef $t };
    });

    $w->work;                            # GRAB → JOB_ASSIGN → WORK_COMPLETE
    EV::run;

# DESCRIPTION

A pure-XS Gearman client and worker built on the [EV](https://metacpan.org/pod/EV) event loop.
The binary protocol is implemented directly — no `libgearman` build
dependency, no glue layer between Perl and a third-party C client.

A single `EV::Gearman` instance can act as a client, a worker, or
both: foreground submissions and worker `GRAB_JOB` packets multiplex
over the same connection, and responses are routed by their request
type (head of FIFO) or by the job handle (work events). Pipelining is
the default, so submitting N jobs in a tight loop ships them in one
batched write and lets the server stream replies back at full
throughput.

The text/admin protocol (`status`, `workers`, `version`,
`maxqueue`, `shutdown`) shares the connection too; multi-line
replies are buffered to the `".\n"` terminator and delivered as a
single string.

[AnyEvent](https://metacpan.org/pod/AnyEvent) applications work unchanged when EV is the active
backend.

# PROTOCOL OVERVIEW

The Gearman wire format is a 12-byte header followed by a payload:

    +--------+---------------+----------------+----------------+
    | magic  |  command (BE) |  data len (BE) |     data       |
    | 4 byte |    4 bytes    |    4 bytes     |   data len B   |
    +--------+---------------+----------------+----------------+
      "\0REQ"     uint32         uint32        NUL-separated
        or                                     args (last arg
      "\0RES"                                  unterminated)

Foreground job lifecycle (client perspective):

    SUBMIT_JOB           -->                              # request
                         <--   JOB_CREATED(handle)        # ack
                         <--   WORK_DATA(handle, ...)*    # 0..N
                         <--   WORK_WARNING(handle, ...)*
                         <--   WORK_STATUS(handle, n,d)*
                         <--   WORK_EXCEPTION(handle,..)* # if option set
                         <--   WORK_COMPLETE(handle, r)   # terminal
                                 -- or --
                         <--   WORK_FAIL(handle)          # terminal

The handle binds the per-job event callbacks to the right submission
even when many submissions are in flight at once.

Worker lifecycle:

    CAN_DO(func)         -->                              # advertise
                         repeat ----------------------+
    GRAB_JOB             -->                          |
                         <--   JOB_ASSIGN(h,fn,wl)    |   # got work
                                 ... user callback   |
    WORK_COMPLETE(h, r)  -->                          |
                         -------------- or -----------+
                         <--   NO_JOB                 |
    PRE_SLEEP            -->                          |
                         <--   NOOP                   |   # wake-up
                         ----------------------------+

`EV::Gearman` drives that state machine in C; the per-function
callback only sees a ready-to-process [EV::Gearman::Job](https://metacpan.org/pod/EV%3A%3AGearman%3A%3AJob).

# ENCODING

All function names, payloads, results, and handles are byte strings
on the wire. Encode UTF-8 yourself before passing data in:

    use Encode;
    $cli->submit_job(reverse => encode_utf8($str), sub {
        my $result = decode_utf8($_[0] // '');
        ...
    });

Workload and result values can contain arbitrary bytes including
embedded NULs — Gearman's framing puts the payload last in the
packet and uses the header's length field, so it is not NUL-bounded.

# CALLBACK CONVENTIONS

Every command callback receives `($result, $err)`. On success
`$err` is `undef`; on failure `$err` is a string like
`"disconnected"`, `"job failed"`, `"command timeout"`, or text
forwarded from the server (e.g. `"INVALID_FUNCTION_NAME: ..."`).

Callback exceptions are caught with `G_EVAL` and surfaced via
`warn` so a stray `die` from your code never unwinds the libev
event loop. Use `EV::break` to abort the loop deliberately.

# CONSTRUCTOR

## new(%options)

    my $g = EV::Gearman->new(
        host             => '127.0.0.1',
        port             => 4730,
        on_error         => sub { warn "@_" },
        on_connect       => sub { ... },
        on_disconnect    => sub { ... },
        connect_timeout  => 5_000,    # ms
        command_timeout  => 30_000,   # ms
        reconnect        => 1,
        reconnect_delay  => 1000,     # ms
        keepalive        => 60,       # seconds (TCP only)
        exceptions       => 1,        # request "exceptions" option
        client_id        => "worker-$$",
        grab_unique      => 1,        # use GRAB_JOB_UNIQ
    );

If `host` (or `path`) is given, a non-blocking connect starts
immediately. With neither, the object is unconfigured; call
`$g->connect` / `$g->connect_unix` later.

All keys default to `undef` unless noted. Booleans accept any Perl
truthy value.

### Connection

- `host => $str`
- `port => $int`

    TCP host and port. Default port: `4730`. Mutually exclusive with
    `path`.

    Name resolution is currently synchronous: a non-numeric `host` is
    passed straight to `getaddrinfo`, which can block the event loop
    for the system resolver timeout. Pass an IP literal (or pre-resolve
    once) to keep reconnect cycles fully non-blocking.

- `path => $str`

    Unix-domain socket path. Mutually exclusive with `host`.

- `loop => $ev_loop`

    EV loop to attach to. Default: `EV::default_loop`.

- `priority => $num`

    EV watcher priority in `-2 .. +2`. Higher = serviced before other
    EV watchers in the same iteration. Default `0`.

- `keepalive => $seconds`

    TCP keepalive idle interval. `0` disables. Ignored on Unix sockets.

### Timeouts

- `connect_timeout => $ms`

    Abort an in-progress non-blocking connect after this many ms. `0`
    &#x3d; no timeout (default).

- `command_timeout => $ms`

    Disconnect with `"command timeout"` if no response arrives within
    this interval. The timer resets on every byte received. `0` = no
    timeout (default).

### Reconnect

- `reconnect => $bool`

    Enable automatic reconnect on transport errors.

- `reconnect_delay => $ms`

    Wait this many ms before each reconnect attempt. Default `1000`.
    The delay is always honored via a timer, so even `0` defers
    through the event loop (no synchronous retry recursion).

- `max_reconnect_attempts => $num`

    Give up after this many consecutive failures and emit
    `"max reconnect attempts reached"`. `0` = unlimited (default).

After a reconnect, all worker `CAN_DO`/`CAN_DO_TIMEOUT`
registrations and the `exceptions` option are re-sent
automatically.

### Worker / option flags

- `exceptions => $bool`

    If true, the `exceptions` option is sent on every connect, so
    foreground clients receive `WORK_EXCEPTION` packets. For workers,
    this also enables forwarding `die` messages from sync callbacks
    as exceptions before the `WORK_FAIL`.

- `client_id => $str`

    Sent as `SET_CLIENT_ID` on every connect. Visible in the admin
    `workers` output.

- `grab_unique => $bool`

    If true, the worker GRAB loop uses `GRAB_JOB_UNIQ`, so the job
    object exposes the unique key supplied by the submitter.

### Event handlers

- `on_error => $cb->($errstr)`

    Connection-level error callback. Default: `warn`. User callbacks
    are run under `G_EVAL`.

- `on_connect => $cb->()`

    Fires once the TCP/Unix connection is fully established and the
    client has enqueued its options and worker-function CAN\_DOs.
    Those packets sit ahead of any user submissions made from inside
    the callback — so submitting a job here is safe even though the
    ability registrations haven't yet hit the socket.

- `on_disconnect => $cb->()`

    Fires after a disconnect, after pending callbacks have been
    cancelled with the disconnect error. For server-initiated close,
    this fires before `on_error`.

# CONNECTION

## connect($host, \[$port\])

Connect to a TCP host. Port defaults to 4730. Cancels any pending
auto-reconnect timer and clears any prior `path`.

## connect\_unix($path)

Connect via Unix socket.

## disconnect

Disconnect cleanly. Cancels reconnect, drains pending callbacks
with `(undef, "disconnected")`, fires `on_disconnect`.
`on_error` does **not** fire on user-initiated disconnect — this
distinguishes it from server-initiated close.

## is\_connected

Returns true while a session is established **or** connection is in
progress.

# CLIENT API

## echo($data, \[$cb->($echoed, $err)\])

Round-trip `ECHO_REQ`. Useful as a ping or to verify that all
prior pipelined requests have been consumed.

## submit\_job($func, $workload, \[\\%opts\], \[$cb\])

## submit\_job\_high($func, $workload, \[\\%opts\], \[$cb\])

## submit\_job\_low($func, $workload, \[\\%opts\], \[$cb\])

Foreground submission with normal / high / low priority. The
callback fires once on the terminal event:

    $cb->($result, undef)        # WORK_COMPLETE
    $cb->(undef, "job failed")   # WORK_FAIL
    $cb->(undef, "exception")    # WORK_EXCEPTION (data via on_exception)
    $cb->(undef, $errstr)        # ERROR / disconnect

Optional opts:

    unique       => $key                   # de-dup / coalesce
    on_data      => $cb->($partial)        # WORK_DATA
    on_warning   => $cb->($w)              # WORK_WARNING
    on_status    => $cb->($num, $denom)    # WORK_STATUS
    on_exception => $cb->($exc)            # WORK_EXCEPTION

The status callback receives `$numerator` and `$denominator` as
strings, matching the wire format (Gearman doesn't constrain them
to integers).

A single packet (function name + unique key + workload) is capped at
256 MiB; a larger submission `croak`s before anything is sent. This
applies to every `submit_job*` variant.

## submit\_job\_bg($func, $workload, \[\\%opts\], \[$cb\])

## submit\_job\_high\_bg($func, $workload, \[\\%opts\], \[$cb\])

## submit\_job\_low\_bg($func, $workload, \[\\%opts\], \[$cb\])

Background submission. Callback fires once on `JOB_CREATED` with
`($handle, $err)`; subsequent work events are not delivered to
this client. `unique` in `%opts` is honored; per-event handlers
(`on_data`, `on_warning`, ...) are ignored because the server
emits no work events to a background submitter.

## submit\_job\_epoch($func, $workload, $epoch, \[\\%opts\], \[$cb\])

Schedule a background job for absolute epoch time `$epoch`
(seconds since 1970-01-01 UTC). Same callback shape as
`submit_job_bg`: `($handle, $err)` on `JOB_CREATED`. Of
`%opts`, only `unique` is meaningful — the per-event handlers
(`on_data`, `on_warning`, etc.) are silently ignored because the
server delivers no work events to the submitting client for
scheduled / background jobs. Server must be built with persistent
queue support for scheduled jobs to survive a restart.

## get\_status($handle, $cb->($info, $err))

Query the server about a known handle:

    $info = {
        handle      => 'H:host:1',
        known       => 0|1,           # server has the job
        running     => 0|1,           # a worker grabbed it
        numerator   => '42',          # last reported progress
        denominator => '100',
    }

## get\_status\_unique($unique, $cb->($info, $err))

Status by unique key; `$info` additionally has `unique` and
`client_count` (how many clients are listening).

## option($name, \[$cb->($ok, $err)\])

Send an `OPTION_REQ`. The `exceptions` option is also tracked
client-side so reconnects re-enable it without your help.

# WORKER API

## register\_function($name, \[\\%opts\], $cb->($job))

Register a worker handler for function `$name`. Sends `CAN_DO`
(or `CAN_DO_TIMEOUT`) on the wire if connected; otherwise the
ability is queued and sent on connect.

`%opts`:

    timeout => $seconds   # CAN_DO_TIMEOUT instead of CAN_DO
    async   => $bool      # see below

Sync mode (default): the callback's return value is sent as the
`WORK_COMPLETE` body. `die` becomes `WORK_FAIL` (and
`WORK_EXCEPTION` when the `exceptions` option is on).

Async mode: the callback's return value is ignored; you must
explicitly call `$job->complete($result)`, `$job->fail`,
or `$job->exception($data)` from a later event. The worker
loop **does** immediately grab the next job after dispatching to
your async callback, so async workers process jobs concurrently —
bounded only by what the server has queued. To cap concurrency,
call `$g->work_stop` in the callback when you reach the cap
and `$g->work` again from `complete`/`fail` when a slot
frees up. See `eg/worker_pool.pl` for a worked example.

## unregister\_function($name)

Alias for `cant_do`.

## can\_do($name, \[$timeout\])

Lower-level: announce ability without a Perl handler. Combine with
`grab_job` to build a custom worker loop.

## cant\_do($name)

Withdraw an ability.

## reset\_abilities

Withdraw all abilities (sends `RESET_ABILITIES`).

## set\_client\_id($id)

Send `SET_CLIENT_ID`. This is what shows up in the admin
`workers` command.

## work(\[$on\_idle\])

Activate the worker loop. Issues a `GRAB_JOB[_UNIQ]` on the
wire as soon as the connection is established (deferred until
then if called pre-connect); on `JOB_ASSIGN` the registered
function callback runs; on `NO_JOB` the connection sleeps via
`PRE_SLEEP` until the server sends `NOOP`, then resumes
grabbing. `$on_idle` fires every time the loop enters the
sleep state.

## work\_one(\[$cb\])

Dispatch exactly one job, then stop the loop. Issues a
`GRAB_JOB`; on `NO_JOB` the worker enters `PRE_SLEEP` and
waits for the server's `NOOP` wake-up just like `work`, so
this is a "wait for one job" — not "try once and bail" (use
`grab_job` for that).

In **sync** mode the loop stops after the user callback returns
and the `WORK_COMPLETE`/`WORK_FAIL` packet has been queued.
In **async** mode it stops as soon as the user callback has been
**dispatched** — the job is still in flight at the server until
the user explicitly calls `$job->complete(...)` or
`$job->fail`.

The optional `$cb` is invoked when the worker enters the sleep
state, and shares storage with `work`'s `$on_idle` — calling
`work_one` after `work` overwrites whatever idle handler
`work` set, and vice versa.

## work\_stop

Drop out of the worker loop. The connection stays up; in-flight
jobs continue to deliver their results, but no new `GRAB_JOB`
will be sent.

## grab\_job($cb)

Lower-level: request exactly one `GRAB_JOB[_UNIQ]`. The callback
gets a job object on `JOB_ASSIGN`, or `(undef, "no job")` on
`NO_JOB`. The user is responsible for completing the job. Requires a
prior `can_do` (or `register_function`) so the server knows this
connection serves the function.

Unlike the managed `work` loop, `grab_job` does not de-duplicate:
calling it again before the previous grab has been answered puts a
second `GRAB_JOB` on the wire. Drive one grab at a time (issue the
next from the previous callback) as in `eg/cron_consumer.pl`.

## all\_yours

Send `ALL_YOURS`. Hint to the server that this worker handles all
known abilities and should be preferred for new jobs.

# ADMIN / TEXT PROTOCOL

The Gearman text protocol shares the same TCP/Unix connection. We
dispatch each incoming byte stream to either the binary parser or
the text parser based on whether the first byte is `\0` (binary)
or printable (admin). Multi-line replies are accumulated to the
`".\n"` terminator and delivered as a single string.

## admin($command, \[$cb->($text, $err)\])

Send a raw text command (newline appended automatically). Replies
are accumulated until the `".\n"` terminator for the multi-line
commands `status`, `workers`, and `prioritystatus`; everything
else is treated as single-line.

## server\_status(\[$cb\])

Tab-separated lines: `FUNC \t TOTAL_JOBS \t RUNNING_JOBS \t WORKERS`.

## server\_workers(\[$cb\])

One line per connected worker.

## server\_version(\[$cb\])

Single-line reply (e.g. `"OK 1.1.21+ds"`).

## maxqueue($func, $size, \[$cb\])

Set the per-function queue size cap. Reply is `"OK\n"`.

## shutdown\_server(graceful => $bool, cb => $cb)

Send `shutdown` or `shutdown graceful`. The server replies with
`"OK\n"` and then closes the connection.

# INTROSPECTION

## pending\_count

Number of binary requests sent and awaiting a response.

## waiting\_count

Number of requests held in the local pre-connect queue.

## active\_count

Number of foreground jobs whose handle has been received but
which haven't yet completed.

# ACCESSORS

These tunables have a getter / setter of the same name. Calling
without arguments reads the current value; with one argument, writes
and (where meaningful) takes effect immediately:

    $g->connect_timeout($ms);
    $g->command_timeout($ms);
    $g->priority($num);
    $g->keepalive($seconds);
    $g->on_error($cb);         # set; pass undef to clear
    $g->on_connect($cb);
    $g->on_disconnect($cb);

The remaining `new` options (`host`, `port`, `path`,
`exceptions`, `client_id`, `grab_unique`, ...) are set once at
construction and have no accessor.

`reconnect` is the exception — it is a setter only; pass `0`/`1`
plus optional new delay and attempt cap:

    $g->reconnect($enable, [$delay_ms], [$max_attempts]);

Omitting `$delay_ms` / `$max_attempts` leaves the previously
configured values unchanged.

## reconnect\_enabled

The getter that `reconnect` lacks: returns true while automatic
reconnect is enabled, false otherwise. Takes no arguments.

# LIFECYCLE AND DESTRUCTION

When a connection drops, the FIFO of pending requests is drained
with `(undef, "disconnected")`; foreground active jobs are drained
with the same error. Reconnect (if enabled) re-runs the connect
sequence and re-registers worker abilities.

When the `EV::Gearman` object goes out of scope, every pending
and active callback fires once with `(undef, "disconnected")`,
then the FD is closed. The clean-shutdown idiom is:

    $g->disconnect;            # drains queues, fires on_disconnect
    undef $g;

If callbacks close over `$g` (a common mistake — every reference
inside a closure keeps the object alive), break the cycle first:

    $g->on_error(undef);
    $g->on_connect(undef);
    $g->on_disconnect(undef);
    undef $g;

DESTROY is reentrancy-safe: if a callback fired during teardown
drops the last external reference to a separate `EV::Gearman`,
that object's DESTROY is correctly deferred and run once unwound.

# PERFORMANCE

Loopback benchmark on Linux, Perl 5.40, gearmand 1.1.21, single
worker (always [EV::Gearman](https://metacpan.org/pod/EV%3A%3AGearman) so the worker isn't the bottleneck).

`bench/benchmark.pl` measures one client by itself:

                                     ops/sec
    Pipelined foreground jobs        ~53,000
    Sequential round-trip            ~19,000
    Background submissions          ~280,000

`bench/vs.pl` compares against the existing CPAN clients
([Gearman::Client](https://metacpan.org/pod/Gearman%3A%3AClient) 2.004.015 sync, [AnyEvent::Gearman](https://metacpan.org/pod/AnyEvent%3A%3AGearman) 0.10
async). Numbers in operations / second:

                          EV::Gearman   AnyEvent::Gearman   Gearman::Client
    pipelined foreground   ~51,000          ~5,200              n/a (1)
    sequential round-trip  ~19,000          ~5,900             ~5,400
    background submits    ~248,000          ~5,400              n/a (1)

    (1) Gearman::Client is synchronous — it has neither pipelining
        nor concurrent background submits.

EV::Gearman is roughly **10x** the foreground throughput of
AnyEvent::Gearman, **45x** the background submission rate, and
**3x** the sequential round-trip rate. The gap comes from three
places:

- Pipelining is the default. Submitting N jobs in a tight loop
ships them in batched writes; responses are demultiplexed by
handle as they stream back. AnyEvent::Gearman is async but
serializes one request per round-trip, so it pays a full RTT per
job.
- The protocol implementation is C/XS — packet encode/decode,
buffer growth, and FIFO bookkeeping run without per-call Perl
allocations.
- The IO layer is direct `ev_io` on the gearmand socket, so each
read/write involves no AnyEvent guard-object construction or
backend-dispatch overhead.

Background submissions are particularly fast because the
JOB\_CREATED reply is the only round-trip — no work events to
demultiplex — so the limit is just network latency and parser
throughput.

Sequential round-trip throughput is the worst case: each job
waits for its own reply before the next is built, so pipelining
buys nothing. EV::Gearman is still ~3x faster here purely from
the C-side protocol parser.

Numbers reproduce with `bench/vs.pl` (run with `--help` for
options).

## Memory

Each connection keeps one read and one write buffer that grow on
demand to fit the largest packet seen. After a buffer fully drains,
anything that grew past ~1 MiB is released back to the initial 16 KiB,
so a one-off large job (or status reply) does not pin its
high-water-mark allocation for the life of the connection. Steady
small-packet traffic never reallocates.

Pass byte strings, not Perl lists: building an N-byte payload with
`join '', map chr(...), 1..$n` materializes N scalars first. For
large payloads use the repeat operator (`$block x $count`) or
`pack`.

# EXAMPLES

The `eg/` directory has runnable scripts (point them at a local
gearmand on `127.0.0.1:4730`):

- **Clients** — `client.pl` (one foreground job), `pipeline.pl`
(concurrent submissions), `background.pl` (fire-and-forget),
`scheduled.pl` (`submit_job_epoch` delayed jobs), `unique.pl`
(job coalescing + `get_status_unique`), `event_client.pl`
(consume `WORK_DATA`/`WORK_STATUS`), `fanout.pl` (scatter/gather),
`priority_queue.pl`, `json_payload.pl` (structured payloads),
`retry.pl` (client-side backoff).
- **Workers** — `worker.pl` (serve forever), `async_worker.pl`
(timer-driven completion), `worker_pool.pl` (concurrency cap),
`graceful_worker.pl` (drain on `SIGTERM`), `cron_consumer.pl`
(`grab_job` drain-and-exit batch), `exceptions.pl`
(`WORK_EXCEPTION` round-trip).
- **Operations** — `admin.pl`, `monitoring.pl` (poll metrics),
`reconnect.pl` (survive a server bounce), `multi_server.pl`
(round-robin across a farm), `unix_socket.pl` (`connect_unix`),
`error_handling.pl`, `anyevent.pl` (run under [AnyEvent](https://metacpan.org/pod/AnyEvent)).

# SEE ALSO

[EV](https://metacpan.org/pod/EV), [AnyEvent](https://metacpan.org/pod/AnyEvent).

[Gearman::Client](https://metacpan.org/pod/Gearman%3A%3AClient), [Gearman::Worker](https://metacpan.org/pod/Gearman%3A%3AWorker) — the synchronous reference
client and worker on CPAN.

[AnyEvent::Gearman](https://metacpan.org/pod/AnyEvent%3A%3AGearman) — older AE-based async client.

[https://gearman.org/protocol/](https://gearman.org/protocol/) — the upstream protocol spec.

This module is one of the `EV-*` family on CPAN by the same
author: [EV::Memcached](https://metacpan.org/pod/EV%3A%3AMemcached), [EV::Redis](https://metacpan.org/pod/EV%3A%3ARedis), [EV::Nats](https://metacpan.org/pod/EV%3A%3ANats), [EV::Pg](https://metacpan.org/pod/EV%3A%3APg),
[EV::ClickHouse](https://metacpan.org/pod/EV%3A%3AClickHouse), [EV::Kafka](https://metacpan.org/pod/EV%3A%3AKafka), [EV::MariaDB](https://metacpan.org/pod/EV%3A%3AMariaDB), [EV::cares](https://metacpan.org/pod/EV%3A%3Acares),
[EV::Etcd](https://metacpan.org/pod/EV%3A%3AEtcd), [EV::Websockets](https://metacpan.org/pod/EV%3A%3AWebsockets).

# AUTHOR

vividsnow

# LICENSE

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
