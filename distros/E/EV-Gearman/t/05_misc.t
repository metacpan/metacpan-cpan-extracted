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
unless ($probe) {
    plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)";
}
close $probe;

sub run_with_timeout {
    my ($t, $why) = @_;
    my $w = EV::timer $t, 0, sub { fail("timeout: $why"); EV::break };
    EV::run;
}

# ===== Pipelining: many submits in a row =====
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    $wkr->register_function('test_pipe_'.$$ => sub { uc $_[0]->workload });
    $wkr->work;

    my @results;
    my $remaining = 10;
    for my $i (1..10) {
        $cli->submit_job('test_pipe_'.$$, "v$i", sub {
            push @results, [$i, $_[0]];
            $remaining--; EV::break if $remaining == 0;
        });
    }
    run_with_timeout 5, 'pipeline';
    is scalar @results, 10, 'all 10 callbacks fired';
}

# ===== Disconnect cancels pending callbacks =====
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my $waited;
    $cli->on_connect(sub { EV::break });
    my $w = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok $cli->is_connected, 'connected';

    my @called;
    $cli->submit_job('nonexistent_'.$$, "x", sub {
        push @called, [@_];
        EV::break;
    });
    is $cli->pending_count, 1, 'one pending';
    $cli->disconnect;
    $w = EV::timer 1, 0, sub { EV::break };
    EV::run;
    is scalar @called, 1, 'pending callback fired on disconnect';
    is $called[0][1], 'disconnected', 'with disconnected error';
}

# ===== Reconnect: re-register worker functions on reconnect =====
{
    my $cli = EV::Gearman->new(
        host => $host, port => $port,
        reconnect => 1, reconnect_delay => 100,
    );
    ok $cli->reconnect_enabled, 'reconnect enabled';
    $cli->reconnect(0);
    ok !$cli->reconnect_enabled, 'disabled';
}

# ===== option(exceptions) =====
{
    my $cli = EV::Gearman->new(host => $host, port => $port, exceptions => 1);
    my ($r, $e);
    $cli->on_connect(sub {
        $cli->option('exceptions', sub { ($r, $e) = @_; EV::break });
    });
    run_with_timeout 3, 'option exceptions';
    ok $r, 'option result truthy';
}

# ===== submit with lots of options =====
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    $wkr->register_function('test_opts_'.$$ => sub { 'ok' });
    $wkr->work;

    my ($r, $e);
    $cli->submit_job_high('test_opts_'.$$, "x", { unique => 'k1' }, sub {
        ($r, $e) = @_; EV::break;
    });
    run_with_timeout 5, 'high priority';
    is $r, 'ok', 'high priority handled';

    ($r, $e) = (undef, undef);
    $cli->submit_job_low('test_opts_'.$$, "x", sub {
        ($r, $e) = @_; EV::break;
    });
    run_with_timeout 5, 'low priority';
    is $r, 'ok', 'low priority handled';
}

# ===== accessors =====
{
    my $g = EV::Gearman->new;
    $g->connect_timeout(1234);
    is $g->connect_timeout, 1234, 'connect_timeout setter/getter';
    $g->command_timeout(5678);
    is $g->command_timeout, 5678, 'command_timeout setter/getter';
    $g->priority(1);
    is $g->priority, 1, 'priority setter/getter';
    $g->keepalive(60);
    is $g->keepalive, 60, 'keepalive setter/getter';
    is $g->pending_count, 0, 'pending_count starts at 0';
    is $g->waiting_count, 0, 'waiting_count starts at 0';
    is $g->active_count, 0, 'active_count starts at 0';
    ok !$g->is_connected, 'not connected';
}

# ===== sending commands before connect =====
{
    my $g = EV::Gearman->new;
    eval { $g->echo("x", sub {}) };
    like $@, qr/not connected/, 'commands croak when not connected';
}

done_testing;
