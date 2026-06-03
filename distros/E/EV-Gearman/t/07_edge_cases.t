# Edge cases: argument parsing, idempotency, fire-and-forget queueing,
# negative timeouts, double-connect, grab_job direct delivery.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

# 1) Negative timeouts get clamped to 0 (= "no timeout")
{
    my $g = EV::Gearman->new;
    $g->connect_timeout(-100);
    is $g->connect_timeout, 0, 'negative connect_timeout clamps to 0';
    $g->command_timeout(-1);
    is $g->command_timeout, 0, 'negative command_timeout clamps to 0';
}

# 2) double-connect is rejected
{
    my $g = EV::Gearman->new(host => $host, port => $port);
    eval { $g->connect($host, $port) };
    like $@, qr/already connected/, 'double-connect croaks';
}

# 3) Submitting before connect: queues the packet, fires after
{
    my $cli = EV::Gearman->new;        # no host yet — unconfigured
    eval { $cli->echo("x", sub {}) };
    like $@, qr/not connected/, 'submit-before-connect croaks (unconfigured)';
}

# 4) Submitting during a pending non-blocking connect — should
#    queue, then drain after on_connect.
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my $r;
    $cli->echo("queued-pre-connect", sub { $r = $_[0]; EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $r, "queued-pre-connect", 'echo queued before on_connect drained';
}

# 5) grab_job direct callback (no register_function) — JOB_ASSIGN path
# Use a server-side echo to confirm the worker's can_do has been
# processed before we submit the job: that synchronizes the test
# without depending on a fixed timer.
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    my $func = "edge_grab_$$";

    $wkr->can_do($func);
    # echo round-trip flushes all preceding writes (including CAN_DO)
    # — by the time the echo callback fires, gearmand has registered
    # this worker's ability for $func.
    $wkr->echo("sync", sub { EV::break });
    my $g = EV::timer 5, 0, sub { fail "echo sync timeout"; EV::break };
    EV::run;

    # Submit and grab live on different connections, so the server
    # could see GRAB before SUBMIT if both are racing on the wire.
    # Defer the grab until $cli has seen JOB_CREATED — then the job
    # is definitely queued server-side before the worker asks for it.
    my ($got_job);
    $cli->submit_job_bg($func, "WORK", sub {
        my ($handle) = @_;
        $wkr->grab_job(sub {
            my ($j, $err) = @_;
            $got_job = $j;
            $j->complete(scalar reverse $j->workload) if $j;
            EV::break;
        });
    });
    $g = EV::timer 5, 0, sub { fail "grab_job timeout"; EV::break };
    EV::run;
    ok $got_job, 'grab_job delivered a job';
    is $got_job && $got_job->workload, 'WORK', 'job workload correct';
}

# 6) grab_job direct callback (no register_function) — NO_JOB path
{
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    my $func = "edge_nojob_$$";   # never submitted to
    $wkr->can_do($func);

    my ($job, $err);
    $wkr->on_connect(sub {
        $wkr->grab_job(sub { ($job, $err) = @_; EV::break });
    });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok !$job, 'grab_job got no job';
    is $err, 'no job', '"no job" error string';
}

# 7) accessor round-trip
{
    my $g = EV::Gearman->new;
    $g->priority(2);
    is $g->priority, 2, 'priority round-trip';
    $g->keepalive(120);
    is $g->keepalive, 120, 'keepalive round-trip';
}

# 8) is_connected progresses through the connecting → connected phases
{
    my $g = EV::Gearman->new(host => $host, port => $port);
    ok $g->is_connected, 'is_connected true while connecting';
    $g->on_connect(sub { EV::break });
    my $w = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok $g->is_connected, 'is_connected true after on_connect';
    $g->disconnect;
    ok !$g->is_connected, 'is_connected false after disconnect';
}

done_testing;
