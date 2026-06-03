# Reentrancy: dropping the connection from inside its own callback
# should defer DESTROY until the unwind, then run cleanly. Without
# the callback_depth guard this is an immediate use-after-free.
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

# Test 1: drop from on_connect
{
    my $cli;
    $cli = EV::Gearman->new(
        host       => $host,
        port       => $port,
        on_connect => sub { undef $cli; EV::break },
    );
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok !defined $cli, 'cleared from on_connect';
    pass 'no crash from drop in on_connect';
}

# Test 2: drop from a job-completion callback
{
    my $wkr = EV::Gearman->new(host => $host, port => $port);
    $wkr->register_function('xt_drop_'.$$ => sub { 'done' });
    $wkr->work;

    my $cli;
    $cli = EV::Gearman->new(host => $host, port => $port);
    $cli->on_connect(sub {
        $cli->submit_job('xt_drop_'.$$, "x", sub {
            undef $cli;
            EV::break;
        });
    });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok !defined $cli, 'cleared from completion callback';
    pass 'no crash from drop in completion';
}

# Test 3: disconnect while many callbacks are queued
# We submit 50 echo round-trips and disconnect from the first
# completion callback. The rest must still be drained with the
# "disconnected" error rather than silently leaked.
{
    my $cli = EV::Gearman->new(host => $host, port => $port);
    $cli->on_connect(sub { EV::break });
    my $g = EV::timer 3, 0, sub { EV::break };
    EV::run;

    my $count = 0;
    my $ok    = 0;
    my $err   = 0;
    for (1..50) {
        $cli->echo("ping-$_", sub {
            $count++;
            if (defined $_[1]) { $err++ } else { $ok++ }
            $cli->disconnect if $count == 1;   # cancel rest from inside cb
            EV::break       if $count == 50;
        });
    }
    $g = EV::timer 5, 0, sub { EV::break };
    EV::run;
    is $count, 50, "all 50 callbacks fired (ok=$ok err=$err)";
}

done_testing;
