# Worker drains HIGH > NORMAL > LOW priority classes regardless of
# submission order. Populate the queue before the worker grabs.
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

my $cli  = EV::Gearman->new(host => $host, port => $port);
my $wkr  = EV::Gearman->new(host => $host, port => $port);
my $func = "prio_test_$$";

my @order;
$wkr->register_function($func => sub {
    push @order, $_[0]->workload;
    return "ok";
});

# Submit interleaved priorities BEFORE the worker grabs.
my $remaining = 6;
my $cb = sub { EV::break unless --$remaining };
$cli->submit_job_low ($func, "low-1",   $cb);
$cli->submit_job     ($func, "norm-1",  $cb);
$cli->submit_job_low ($func, "low-2",   $cb);
$cli->submit_job_high($func, "HIGH-1",  $cb);
$cli->submit_job     ($func, "norm-2",  $cb);
$cli->submit_job_high($func, "HIGH-2",  $cb);

# All six jobs must be queued server-side before the worker grabs, or
# the priority ordering isn't well-defined. An echo round-trip on the
# client is a deterministic barrier: its reply means gearmand has
# processed every preceding SUBMIT_JOB. Start the worker from there
# (rather than guessing with a fixed delay).
$cli->echo("sync", sub { $wkr->work });
my $g = EV::timer 5, 0, sub { fail "prio timeout"; EV::break };
EV::run;

is scalar @order, 6, 'six jobs handled';

# HIGH first, then NORMAL, then LOW; FIFO within class.
my @class = map { /^HIGH/  ? 'H' :
                  /^low/   ? 'L' :
                  /^norm/  ? 'N' : '?' } @order;
is "@class", 'H H N N L L', "priority order: H H N N L L (got: @order)";

done_testing;
