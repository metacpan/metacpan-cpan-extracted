# Leak-prone scenarios. Run alone for a quick sanity check, or under
# valgrind via xt/90_valgrind.t to enforce zero definite leaks.
#
# Each scenario allocates and tears down state in ways that have
# historically been leak-prone in EV::* modules:
#   - DESTROY mid-callback
#   - dropping while jobs in flight
#   - reconnect with worker abilities + options
#   - multiple in-flight foreground submissions cancelled by close
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

# 1. Many short-lived clients
{
    for (1..50) {
        my $g = EV::Gearman->new(host => $host, port => $port);
        my $w = EV::timer 0.05, 0, sub { EV::break };
        EV::run;
        $g->disconnect;
        undef $g;
    }
    pass 'many short-lived clients';
}

# 2. Drop while pending callbacks are in flight
{
    my $g = EV::Gearman->new(host => $host, port => $port);
    $g->on_connect(sub { EV::break });
    my $w = EV::timer 3, 0, sub { EV::break };
    EV::run;
    for (1..20) {
        $g->submit_job('xt_leak_'.$$, "x", sub { });
    }
    undef $g;     # callbacks fire with "disconnected" then memory frees
    pass 'drop with pending callbacks';
}

# 3. Worker registration + reconnect cycles
{
    my $g = EV::Gearman->new(host => $host, port => $port,
        reconnect => 1, reconnect_delay => 50);
    $g->register_function('xt_leak_wkr_'.$$ => sub { 'r' });
    $g->register_function('xt_leak_wkr2_'.$$ => sub { 'r' });
    $g->on_connect(sub { EV::break });
    my $w = EV::timer 3, 0, sub { EV::break };
    EV::run;

    # Bounce the connection
    $g->disconnect;
    $g->connect($host, $port);
    $w = EV::timer 1, 0, sub { EV::break };
    EV::run;

    $g->reset_abilities;
    undef $g;
    pass 'register+reconnect cycle';
}

# 4. Async jobs that never complete (DESTROY drops their refs)
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    my @stash;  # holds job refs forever in normal use
    $wkr->register_function('xt_leak_async_'.$$ => { async => 1 }, sub {
        push @stash, $_[0];     # never call complete
    });
    $wkr->work;
    for (1..5) {
        $cli->submit_job('xt_leak_async_'.$$, "x", sub {});
    }
    my $w = EV::timer 1, 0, sub { EV::break };
    EV::run;
    # On teardown, $cli's pending callbacks fire with "disconnected",
    # $wkr drops the function (whose refcnt may hold $stash entries),
    # and DESTROY frees everything cleanly.
    undef $cli;
    undef $wkr;
    @stash = ();
    pass 'async stash cleanup';
}

# 5. Admin commands intermixed with submissions
{
    my $g = EV::Gearman->new(host => $host, port => $port);
    my $settle;   # retained so the timer actually fires
    $g->on_connect(sub {
        for (1..10) {
            $g->server_status(sub {});
            $g->server_version(sub {});
            $g->echo("ping", sub {});
        }
        $settle = EV::timer 0.3, 0, sub { EV::break };
    });
    my $w = EV::timer 3, 0, sub { EV::break };
    EV::run;
    undef $g;
    pass 'admin intermix cleanup';
}

done_testing;
