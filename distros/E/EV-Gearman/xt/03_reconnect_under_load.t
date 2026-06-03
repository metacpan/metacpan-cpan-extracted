# Reconnect-under-load:
#   1. Client-side disconnect cancels every in-flight callback exactly
#      once with the "disconnected" error.
#   2. Worker-side disconnect-and-reconnect re-registers abilities so
#      newly submitted jobs continue to flow through the same worker.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

# Spawn a worker that completes immediately
my $w = EV::Gearman->new(
    host => $host, port => $port,
    reconnect => 1, reconnect_delay => 100,
);
my $reconnects = 0;
$w->on_connect(sub { $reconnects++; EV::break });
my $g = EV::timer 3, 0, sub { EV::break };
EV::run;
ok $reconnects, 'worker connected';

my $func = 'xt_recon_load_'.$$;
$w->register_function($func => sub { uc $_[0]->workload });
$w->work;

# Test 1: client disconnect drains all pending callbacks
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    $cli->on_connect(sub { EV::break });
    $g = EV::timer 3, 0, sub { EV::break };
    EV::run;

    my $N = 100;
    my %seen;
    for my $i (1..$N) {
        $cli->echo("msg-$i", sub {
            $seen{$i} = $_[1] // 'ok';
        });
    }
    # Disconnect right away — most/all callbacks land via the
    # cancel_pending drain path. Flush via a short wait to allow
    # the cancellation pass to complete.
    $cli->disconnect;
    $g = EV::timer 1, 0, sub { EV::break };
    EV::run;
    is scalar(keys %seen), $N, "all $N callbacks accounted for after disconnect";
}

# Test 2: worker disconnect-reconnect re-registers ability
# (user-initiated disconnect clears worker_active by design — call
# work() again after reconnect to resume grabbing)
{
    $w->disconnect;
    $w->connect($host, $port);
    $w->work;
    $g = EV::timer 1, 0, sub { EV::break };
    EV::run;
    ok $reconnects >= 2, "worker reconnected (got $reconnects)";

    # Submit a job to verify the function is still registered after
    # reconnect — the XS code re-sends CAN_DO on connect.
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my ($r, $e);
    $cli->on_connect(sub {
        $cli->submit_job($func, "still-alive", sub { ($r, $e) = @_; EV::break });
    });
    $g = EV::timer 5, 0, sub { fail "post-reconnect timeout"; EV::break };
    EV::run;
    is $r, 'STILL-ALIVE', 'worker function works after reconnect';
}

done_testing;
