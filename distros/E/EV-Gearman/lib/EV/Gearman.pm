package EV::Gearman;
use strict;
use warnings;
use Carp ();
use EV;
use EV::Gearman::Job ();

BEGIN {
    use XSLoader;
    our $VERSION = '0.01';
    XSLoader::load __PACKAGE__, $VERSION;
}

# ===== Submit-job dispatch wrappers =====
#
# Public form:
#   $g->submit_job($func, $workload [, \%opts] [, $cb])
#   $g->submit_job_high($func, $workload [, \%opts] [, $cb])
#   $g->submit_job_low($func, $workload [, \%opts] [, $cb])
#   $g->submit_job_bg($func, $workload [, \%opts] [, $cb])
#   $g->submit_job_high_bg(...)
#   $g->submit_job_low_bg(...)

# Strip an optional trailing \%opts and \&cb in either order.
sub _opts_cb {
    my $opts = (@_ && ref $_[0] eq 'HASH') ? shift : undef;
    my $cb   = (@_ && ref $_[0] eq 'CODE') ? shift : undef;
    ($opts, $cb);
}

sub _build_submitter {
    my ($cmd_idx) = @_;
    return sub {
        my $self     = shift;
        my $func     = shift;
        my $workload = shift;
        my ($opts, $cb) = _opts_cb(@_);
        my $unique = $opts ? $opts->{unique} : undef;
        $self->_submit_internal($cmd_idx, $func, $workload, $unique, $opts, $cb);
    };
}

*submit_job         = _build_submitter(0);
*submit_job_high    = _build_submitter(1);
*submit_job_low     = _build_submitter(2);
*submit_job_bg      = _build_submitter(3);
*submit_job_high_bg = _build_submitter(4);
*submit_job_low_bg  = _build_submitter(5);

sub submit_job_epoch {
    my ($self, $func, $workload, $epoch) = (shift, shift, shift, shift);
    my ($opts, $cb) = _opts_cb(@_);
    my $unique = $opts ? $opts->{unique} : undef;
    $self->_submit_epoch($func, $workload, $unique, $epoch, $cb);
}

sub register_function {
    my $self = shift;
    my $name = shift;
    my $opts = (@_ && ref $_[0] eq 'HASH') ? shift : undef;
    my $cb   = shift;
    Carp::croak("register_function: callback required") unless ref $cb eq 'CODE';
    my $timeout = $opts && $opts->{timeout} ? int $opts->{timeout} : 0;
    my $async   = $opts && $opts->{async}   ? 1 : 0;
    $self->_register_function($name, $cb, $timeout, $async);
}

{
    no strict 'refs';
    *unregister_function = \&cant_do;
    for my $cmd (qw(status workers version)) {
        *{"server_$cmd"} = sub { my $self = shift; $self->admin($cmd, @_) };
    }
}

sub maxqueue {
    my ($self, $func, $size, $cb) = @_;
    # $func and $size are interpolated into a newline-delimited text
    # command, so whitespace/newlines could inject a second admin
    # command. Validate both.
    Carp::croak("maxqueue: function name required") unless defined $func;
    Carp::croak("maxqueue: function name may not contain whitespace")
        if $func =~ /\s/;
    Carp::croak("maxqueue: size must be a non-negative integer")
        unless defined($size) && $size =~ /\A[0-9]+\z/;
    $self->admin("maxqueue $func $size", $cb);
}

sub shutdown_server {
    my ($self, %opts) = @_;
    my $graceful = $opts{graceful} ? ' graceful' : '';
    $self->admin("shutdown$graceful", $opts{cb});
}

1;

=encoding utf8

=head1 NAME

EV::Gearman - asynchronous Gearman client and worker on libev

=head1 SYNOPSIS

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

=head1 DESCRIPTION

A pure-XS Gearman client and worker built on the L<EV> event loop.
The binary protocol is implemented directly — no C<libgearman> build
dependency, no glue layer between Perl and a third-party C client.

A single C<EV::Gearman> instance can act as a client, a worker, or
both: foreground submissions and worker C<GRAB_JOB> packets multiplex
over the same connection, and responses are routed by their request
type (head of FIFO) or by the job handle (work events). Pipelining is
the default, so submitting N jobs in a tight loop ships them in one
batched write and lets the server stream replies back at full
throughput.

The text/admin protocol (C<status>, C<workers>, C<version>,
C<maxqueue>, C<shutdown>) shares the connection too; multi-line
replies are buffered to the C<".\n"> terminator and delivered as a
single string.

L<AnyEvent> applications work unchanged when EV is the active
backend.

=head1 PROTOCOL OVERVIEW

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

C<EV::Gearman> drives that state machine in C; the per-function
callback only sees a ready-to-process L<EV::Gearman::Job>.

=head1 ENCODING

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

=head1 CALLBACK CONVENTIONS

Every command callback receives C<($result, $err)>. On success
C<$err> is C<undef>; on failure C<$err> is a string like
C<"disconnected">, C<"job failed">, C<"command timeout">, or text
forwarded from the server (e.g. C<"INVALID_FUNCTION_NAME: ...">).

Callback exceptions are caught with C<G_EVAL> and surfaced via
C<warn> so a stray C<die> from your code never unwinds the libev
event loop. Use C<EV::break> to abort the loop deliberately.

=head1 CONSTRUCTOR

=head2 new(%options)

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

If C<host> (or C<path>) is given, a non-blocking connect starts
immediately. With neither, the object is unconfigured; call
C<< $g->connect >> / C<< $g->connect_unix >> later.

All keys default to C<undef> unless noted. Booleans accept any Perl
truthy value.

=head3 Connection

=over

=item C<host =E<gt> $str>

=item C<port =E<gt> $int>

TCP host and port. Default port: C<4730>. Mutually exclusive with
C<path>.

Name resolution is currently synchronous: a non-numeric C<host> is
passed straight to C<getaddrinfo>, which can block the event loop
for the system resolver timeout. Pass an IP literal (or pre-resolve
once) to keep reconnect cycles fully non-blocking.

=item C<path =E<gt> $str>

Unix-domain socket path. Mutually exclusive with C<host>.

=item C<loop =E<gt> $ev_loop>

EV loop to attach to. Default: C<EV::default_loop>.

=item C<priority =E<gt> $num>

EV watcher priority in C<-2 .. +2>. Higher = serviced before other
EV watchers in the same iteration. Default C<0>.

=item C<keepalive =E<gt> $seconds>

TCP keepalive idle interval. C<0> disables. Ignored on Unix sockets.

=back

=head3 Timeouts

=over

=item C<connect_timeout =E<gt> $ms>

Abort an in-progress non-blocking connect after this many ms. C<0>
= no timeout (default).

=item C<command_timeout =E<gt> $ms>

Disconnect with C<"command timeout"> if no response arrives within
this interval. The timer resets on every byte received. C<0> = no
timeout (default).

=back

=head3 Reconnect

=over

=item C<reconnect =E<gt> $bool>

Enable automatic reconnect on transport errors.

=item C<reconnect_delay =E<gt> $ms>

Wait this many ms before each reconnect attempt. Default C<1000>.
The delay is always honored via a timer, so even C<0> defers
through the event loop (no synchronous retry recursion).

=item C<max_reconnect_attempts =E<gt> $num>

Give up after this many consecutive failures and emit
C<"max reconnect attempts reached">. C<0> = unlimited (default).

=back

After a reconnect, all worker C<CAN_DO>/C<CAN_DO_TIMEOUT>
registrations and the C<exceptions> option are re-sent
automatically.

=head3 Worker / option flags

=over

=item C<exceptions =E<gt> $bool>

If true, the C<exceptions> option is sent on every connect, so
foreground clients receive C<WORK_EXCEPTION> packets. For workers,
this also enables forwarding C<die> messages from sync callbacks
as exceptions before the C<WORK_FAIL>.

=item C<client_id =E<gt> $str>

Sent as C<SET_CLIENT_ID> on every connect. Visible in the admin
C<workers> output.

=item C<grab_unique =E<gt> $bool>

If true, the worker GRAB loop uses C<GRAB_JOB_UNIQ>, so the job
object exposes the unique key supplied by the submitter.

=back

=head3 Event handlers

=over

=item C<on_error =E<gt> $cb-E<gt>($errstr)>

Connection-level error callback. Default: C<warn>. User callbacks
are run under C<G_EVAL>.

=item C<on_connect =E<gt> $cb-E<gt>()>

Fires once the TCP/Unix connection is fully established and the
client has enqueued its options and worker-function CAN_DOs.
Those packets sit ahead of any user submissions made from inside
the callback — so submitting a job here is safe even though the
ability registrations haven't yet hit the socket.

=item C<on_disconnect =E<gt> $cb-E<gt>()>

Fires after a disconnect, after pending callbacks have been
cancelled with the disconnect error. For server-initiated close,
this fires before C<on_error>.

=back

=head1 CONNECTION

=head2 connect($host, [$port])

Connect to a TCP host. Port defaults to 4730. Cancels any pending
auto-reconnect timer and clears any prior C<path>.

=head2 connect_unix($path)

Connect via Unix socket.

=head2 disconnect

Disconnect cleanly. Cancels reconnect, drains pending callbacks
with C<(undef, "disconnected")>, fires C<on_disconnect>.
C<on_error> does B<not> fire on user-initiated disconnect — this
distinguishes it from server-initiated close.

=head2 is_connected

Returns true while a session is established B<or> connection is in
progress.

=head1 CLIENT API

=head2 echo($data, [$cb-E<gt>($echoed, $err)])

Round-trip C<ECHO_REQ>. Useful as a ping or to verify that all
prior pipelined requests have been consumed.

=head2 submit_job($func, $workload, [\%opts], [$cb])

=head2 submit_job_high($func, $workload, [\%opts], [$cb])

=head2 submit_job_low($func, $workload, [\%opts], [$cb])

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

The status callback receives C<$numerator> and C<$denominator> as
strings, matching the wire format (Gearman doesn't constrain them
to integers).

A single packet (function name + unique key + workload) is capped at
256 MiB; a larger submission C<croak>s before anything is sent. This
applies to every C<submit_job*> variant.

=head2 submit_job_bg($func, $workload, [\%opts], [$cb])

=head2 submit_job_high_bg($func, $workload, [\%opts], [$cb])

=head2 submit_job_low_bg($func, $workload, [\%opts], [$cb])

Background submission. Callback fires once on C<JOB_CREATED> with
C<($handle, $err)>; subsequent work events are not delivered to
this client. C<unique> in C<%opts> is honored; per-event handlers
(C<on_data>, C<on_warning>, ...) are ignored because the server
emits no work events to a background submitter.

=head2 submit_job_epoch($func, $workload, $epoch, [\%opts], [$cb])

Schedule a background job for absolute epoch time C<$epoch>
(seconds since 1970-01-01 UTC). Same callback shape as
C<submit_job_bg>: C<($handle, $err)> on C<JOB_CREATED>. Of
C<%opts>, only C<unique> is meaningful — the per-event handlers
(C<on_data>, C<on_warning>, etc.) are silently ignored because the
server delivers no work events to the submitting client for
scheduled / background jobs. Server must be built with persistent
queue support for scheduled jobs to survive a restart.

=head2 get_status($handle, $cb-E<gt>($info, $err))

Query the server about a known handle:

    $info = {
        handle      => 'H:host:1',
        known       => 0|1,           # server has the job
        running     => 0|1,           # a worker grabbed it
        numerator   => '42',          # last reported progress
        denominator => '100',
    }

=head2 get_status_unique($unique, $cb-E<gt>($info, $err))

Status by unique key; C<$info> additionally has C<unique> and
C<client_count> (how many clients are listening).

=head2 option($name, [$cb-E<gt>($ok, $err)])

Send an C<OPTION_REQ>. The C<exceptions> option is also tracked
client-side so reconnects re-enable it without your help.

=head1 WORKER API

=head2 register_function($name, [\%opts], $cb-E<gt>($job))

Register a worker handler for function C<$name>. Sends C<CAN_DO>
(or C<CAN_DO_TIMEOUT>) on the wire if connected; otherwise the
ability is queued and sent on connect.

C<%opts>:

    timeout => $seconds   # CAN_DO_TIMEOUT instead of CAN_DO
    async   => $bool      # see below

Sync mode (default): the callback's return value is sent as the
C<WORK_COMPLETE> body. C<die> becomes C<WORK_FAIL> (and
C<WORK_EXCEPTION> when the C<exceptions> option is on).

Async mode: the callback's return value is ignored; you must
explicitly call C<< $job->complete($result) >>, C<< $job->fail >>,
or C<< $job->exception($data) >> from a later event. The worker
loop B<does> immediately grab the next job after dispatching to
your async callback, so async workers process jobs concurrently —
bounded only by what the server has queued. To cap concurrency,
call C<< $g->work_stop >> in the callback when you reach the cap
and C<< $g->work >> again from C<complete>/C<fail> when a slot
frees up. See C<eg/worker_pool.pl> for a worked example.

=head2 unregister_function($name)

Alias for C<cant_do>.

=head2 can_do($name, [$timeout])

Lower-level: announce ability without a Perl handler. Combine with
C<grab_job> to build a custom worker loop.

=head2 cant_do($name)

Withdraw an ability.

=head2 reset_abilities

Withdraw all abilities (sends C<RESET_ABILITIES>).

=head2 set_client_id($id)

Send C<SET_CLIENT_ID>. This is what shows up in the admin
C<workers> command.

=head2 work([$on_idle])

Activate the worker loop. Issues a C<GRAB_JOB[_UNIQ]> on the
wire as soon as the connection is established (deferred until
then if called pre-connect); on C<JOB_ASSIGN> the registered
function callback runs; on C<NO_JOB> the connection sleeps via
C<PRE_SLEEP> until the server sends C<NOOP>, then resumes
grabbing. C<$on_idle> fires every time the loop enters the
sleep state.

=head2 work_one([$cb])

Dispatch exactly one job, then stop the loop. Issues a
C<GRAB_JOB>; on C<NO_JOB> the worker enters C<PRE_SLEEP> and
waits for the server's C<NOOP> wake-up just like C<work>, so
this is a "wait for one job" — not "try once and bail" (use
C<grab_job> for that).

In B<sync> mode the loop stops after the user callback returns
and the C<WORK_COMPLETE>/C<WORK_FAIL> packet has been queued.
In B<async> mode it stops as soon as the user callback has been
B<dispatched> — the job is still in flight at the server until
the user explicitly calls C<< $job->complete(...) >> or
C<< $job->fail >>.

The optional C<$cb> is invoked when the worker enters the sleep
state, and shares storage with C<work>'s C<$on_idle> — calling
C<work_one> after C<work> overwrites whatever idle handler
C<work> set, and vice versa.

=head2 work_stop

Drop out of the worker loop. The connection stays up; in-flight
jobs continue to deliver their results, but no new C<GRAB_JOB>
will be sent.

=head2 grab_job($cb)

Lower-level: request exactly one C<GRAB_JOB[_UNIQ]>. The callback
gets a job object on C<JOB_ASSIGN>, or C<(undef, "no job")> on
C<NO_JOB>. The user is responsible for completing the job. Requires a
prior C<can_do> (or C<register_function>) so the server knows this
connection serves the function.

Unlike the managed C<work> loop, C<grab_job> does not de-duplicate:
calling it again before the previous grab has been answered puts a
second C<GRAB_JOB> on the wire. Drive one grab at a time (issue the
next from the previous callback) as in F<eg/cron_consumer.pl>.

=head2 all_yours

Send C<ALL_YOURS>. Hint to the server that this worker handles all
known abilities and should be preferred for new jobs.

=head1 ADMIN / TEXT PROTOCOL

The Gearman text protocol shares the same TCP/Unix connection. We
dispatch each incoming byte stream to either the binary parser or
the text parser based on whether the first byte is C<\0> (binary)
or printable (admin). Multi-line replies are accumulated to the
C<".\n"> terminator and delivered as a single string.

=head2 admin($command, [$cb-E<gt>($text, $err)])

Send a raw text command (newline appended automatically). Replies
are accumulated until the C<".\n"> terminator for the multi-line
commands C<status>, C<workers>, and C<prioritystatus>; everything
else is treated as single-line.

=head2 server_status([$cb])

Tab-separated lines: C<FUNC \t TOTAL_JOBS \t RUNNING_JOBS \t WORKERS>.

=head2 server_workers([$cb])

One line per connected worker.

=head2 server_version([$cb])

Single-line reply (e.g. C<"OK 1.1.21+ds">).

=head2 maxqueue($func, $size, [$cb])

Set the per-function queue size cap. Reply is C<"OK\n">.

=head2 shutdown_server(graceful => $bool, cb => $cb)

Send C<shutdown> or C<shutdown graceful>. The server replies with
C<"OK\n"> and then closes the connection.

=head1 INTROSPECTION

=head2 pending_count

Number of binary requests sent and awaiting a response.

=head2 waiting_count

Number of requests held in the local pre-connect queue.

=head2 active_count

Number of foreground jobs whose handle has been received but
which haven't yet completed.

=head1 ACCESSORS

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

The remaining C<new> options (C<host>, C<port>, C<path>,
C<exceptions>, C<client_id>, C<grab_unique>, ...) are set once at
construction and have no accessor.

C<reconnect> is the exception — it is a setter only; pass C<0>/C<1>
plus optional new delay and attempt cap:

    $g->reconnect($enable, [$delay_ms], [$max_attempts]);

Omitting C<$delay_ms> / C<$max_attempts> leaves the previously
configured values unchanged.

=head2 reconnect_enabled

The getter that C<reconnect> lacks: returns true while automatic
reconnect is enabled, false otherwise. Takes no arguments.

=head1 LIFECYCLE AND DESTRUCTION

When a connection drops, the FIFO of pending requests is drained
with C<(undef, "disconnected")>; foreground active jobs are drained
with the same error. Reconnect (if enabled) re-runs the connect
sequence and re-registers worker abilities.

When the C<EV::Gearman> object goes out of scope, every pending
and active callback fires once with C<(undef, "disconnected")>,
then the FD is closed. The clean-shutdown idiom is:

    $g->disconnect;            # drains queues, fires on_disconnect
    undef $g;

If callbacks close over C<$g> (a common mistake — every reference
inside a closure keeps the object alive), break the cycle first:

    $g->on_error(undef);
    $g->on_connect(undef);
    $g->on_disconnect(undef);
    undef $g;

DESTROY is reentrancy-safe: if a callback fired during teardown
drops the last external reference to a separate C<EV::Gearman>,
that object's DESTROY is correctly deferred and run once unwound.

=head1 PERFORMANCE

Loopback benchmark on Linux, Perl 5.40, gearmand 1.1.21, single
worker (always L<EV::Gearman> so the worker isn't the bottleneck).

C<bench/benchmark.pl> measures one client by itself:

                                     ops/sec
    Pipelined foreground jobs        ~53,000
    Sequential round-trip            ~19,000
    Background submissions          ~280,000

C<bench/vs.pl> compares against the existing CPAN clients
(L<Gearman::Client> 2.004.015 sync, L<AnyEvent::Gearman> 0.10
async). Numbers in operations / second:

                          EV::Gearman   AnyEvent::Gearman   Gearman::Client
    pipelined foreground   ~51,000          ~5,200              n/a (1)
    sequential round-trip  ~19,000          ~5,900             ~5,400
    background submits    ~248,000          ~5,400              n/a (1)

    (1) Gearman::Client is synchronous — it has neither pipelining
        nor concurrent background submits.

EV::Gearman is roughly B<10x> the foreground throughput of
AnyEvent::Gearman, B<45x> the background submission rate, and
B<3x> the sequential round-trip rate. The gap comes from three
places:

=over

=item *

Pipelining is the default. Submitting N jobs in a tight loop
ships them in batched writes; responses are demultiplexed by
handle as they stream back. AnyEvent::Gearman is async but
serializes one request per round-trip, so it pays a full RTT per
job.

=item *

The protocol implementation is C/XS — packet encode/decode,
buffer growth, and FIFO bookkeeping run without per-call Perl
allocations.

=item *

The IO layer is direct C<ev_io> on the gearmand socket, so each
read/write involves no AnyEvent guard-object construction or
backend-dispatch overhead.

=back

Background submissions are particularly fast because the
JOB_CREATED reply is the only round-trip — no work events to
demultiplex — so the limit is just network latency and parser
throughput.

Sequential round-trip throughput is the worst case: each job
waits for its own reply before the next is built, so pipelining
buys nothing. EV::Gearman is still ~3x faster here purely from
the C-side protocol parser.

Numbers reproduce with C<bench/vs.pl> (run with C<--help> for
options).

=head2 Memory

Each connection keeps one read and one write buffer that grow on
demand to fit the largest packet seen. After a buffer fully drains,
anything that grew past ~1 MiB is released back to the initial 16 KiB,
so a one-off large job (or status reply) does not pin its
high-water-mark allocation for the life of the connection. Steady
small-packet traffic never reallocates.

Pass byte strings, not Perl lists: building an N-byte payload with
C<join '', map chr(...), 1..$n> materializes N scalars first. For
large payloads use the repeat operator (C<$block x $count>) or
C<pack>.

=head1 EXAMPLES

The C<eg/> directory has runnable scripts (point them at a local
gearmand on C<127.0.0.1:4730>):

=over

=item *

B<Clients> — C<client.pl> (one foreground job), C<pipeline.pl>
(concurrent submissions), C<background.pl> (fire-and-forget),
C<scheduled.pl> (C<submit_job_epoch> delayed jobs), C<unique.pl>
(job coalescing + C<get_status_unique>), C<event_client.pl>
(consume C<WORK_DATA>/C<WORK_STATUS>), C<fanout.pl> (scatter/gather),
C<priority_queue.pl>, C<json_payload.pl> (structured payloads),
C<retry.pl> (client-side backoff).

=item *

B<Workers> — C<worker.pl> (serve forever), C<async_worker.pl>
(timer-driven completion), C<worker_pool.pl> (concurrency cap),
C<graceful_worker.pl> (drain on C<SIGTERM>), C<cron_consumer.pl>
(C<grab_job> drain-and-exit batch), C<exceptions.pl>
(C<WORK_EXCEPTION> round-trip).

=item *

B<Operations> — C<admin.pl>, C<monitoring.pl> (poll metrics),
C<reconnect.pl> (survive a server bounce), C<multi_server.pl>
(round-robin across a farm), C<unix_socket.pl> (C<connect_unix>),
C<error_handling.pl>, C<anyevent.pl> (run under L<AnyEvent>).

=back

=head1 SEE ALSO

L<EV>, L<AnyEvent>.

L<Gearman::Client>, L<Gearman::Worker> — the synchronous reference
client and worker on CPAN.

L<AnyEvent::Gearman> — older AE-based async client.

L<https://gearman.org/protocol/> — the upstream protocol spec.

This module is one of the C<EV-*> family on CPAN by the same
author: L<EV::Memcached>, L<EV::Redis>, L<EV::Nats>, L<EV::Pg>,
L<EV::ClickHouse>, L<EV::Kafka>, L<EV::MariaDB>, L<EV::cares>,
L<EV::Etcd>, L<EV::Websockets>.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
