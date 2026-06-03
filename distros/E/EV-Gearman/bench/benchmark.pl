#!/usr/bin/perl
# Benchmark client throughput. Spawns a worker subprocess if none exists.
#
# Usage: bench/benchmark.pl [count]
# Env: BENCH_HOST, BENCH_PORT (default 127.0.0.1:4730)
use strict;
use warnings;
use EV;
use EV::Gearman;
use Time::HiRes qw(time);

my $host = $ENV{BENCH_HOST} || '127.0.0.1';
my $port = $ENV{BENCH_PORT} || 4730;
my $N    = $ARGV[0] || 10000;

# Spawn a worker child unless told otherwise
my $child = 0;
unless ($ENV{BENCH_NO_WORKER}) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        my $g = EV::Gearman->new(host => $host, port => $port);
        $g->register_function('bench_'.$$ => sub { $_[0]->workload });
        $g->work;
        EV::run;
        exit 0;
    }
    $child = $pid;
    sleep 1; # give the worker time to register
}

my $g = EV::Gearman->new(host => $host, port => $port);

# Warm up
my $cv = 0;
for (1..100) {
    $g->submit_job('bench_'.$child, "warmup", sub { $cv++; EV::break if $cv == 100 });
}
EV::run;

# Pipelined throughput
my $start = time;
my $done  = 0;
for my $i (1..$N) {
    $g->submit_job('bench_'.$child, "v$i", sub {
        $done++;
        EV::break if $done == $N;
    });
}
EV::run;
my $dt = time - $start;
printf "%d jobs in %.3fs (%.0f rps)\n", $N, $dt, $N / $dt;

# Sequential round-trip
$start = time;
my $rt = 0;
my $cb; $cb = sub {
    $rt++;
    if ($rt < 1000) { $g->submit_job('bench_'.$child, "v$rt", $cb) }
    else            { EV::break }
};
$g->submit_job('bench_'.$child, "v0", $cb);
EV::run;
my $rt_dt = time - $start;
printf "%d sequential round-trips in %.3fs (%.0f rps)\n", $rt, $rt_dt, $rt / $rt_dt;

# Background submissions
$start = time;
my $bg = 0;
my $BG_N = int($N / 10);
for (1..$BG_N) {
    $g->submit_job_bg('bench_'.$child, "v$_", sub {
        $bg++;
        EV::break if $bg == $BG_N;
    });
}
EV::run;
my $bg_dt = time - $start;
printf "%d background submits in %.3fs (%.0f rps)\n", $BG_N, $bg_dt, $BG_N / $bg_dt;

if ($child) {
    kill 'TERM', $child;
    waitpid $child, 0;
}
