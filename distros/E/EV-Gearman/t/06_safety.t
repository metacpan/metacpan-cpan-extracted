# Reentrancy / safety scenarios — undef / disconnect from callbacks
# without crashing or losing pending callbacks.
#
# This used to be xt-only but moved into t/ so CPAN testers exercise it.
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

# 1) undef $cli inside on_connect
{
    my $cli;
    $cli = EV::Gearman->new(
        host       => $host,
        port       => $port,
        on_connect => sub { undef $cli; EV::break },
    );
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok !defined $cli, 'undef from on_connect';
}

# 2) undef $cli from a foreground completion callback
{
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    $wkr->register_function('safe_cmpl_'.$$ => sub { 'r' });
    $wkr->work;

    my $cli;
    $cli = EV::Gearman->new(host => $host, port => $port);
    $cli->on_connect(sub {
        $cli->submit_job('safe_cmpl_'.$$, "x", sub {
            undef $cli;
            EV::break;
        });
    });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok !defined $cli, 'undef from completion callback';
}

# 3) Drop $cli with foreground active jobs in flight — every
#    on_complete callback fires with "disconnected".
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    $cli->on_connect(sub { EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;

    my $count = 0;
    for (1..20) {
        # nonexistent function — gearmand queues the job; the client
        # receives JOB_CREATED, so the job becomes "active". Dropping
        # the client should drain those active callbacks.
        $cli->submit_job('safe_never_'.$$, "x", sub {
            $count++;
            EV::break if $count == 20;
        });
    }
    undef $cli;        # triggers DESTROY drain of active_jobs
    $g = EV::timer 1, 0, sub { EV::break };
    EV::run;
    is $count, 20, 'all 20 active callbacks drained on DESTROY';
}

# 4) Disconnect from inside the first echo callback —
#    remaining queued echo callbacks all get "disconnected".
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    $cli->on_connect(sub { EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;

    my $count = 0;
    for (1..30) {
        $cli->echo("ping-$_", sub {
            $count++;
            $cli->disconnect if $count == 1;
            EV::break if $count == 30;
        });
    }
    $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is $count, 30, 'all 30 echo callbacks fired (some drained)';
}

done_testing;
