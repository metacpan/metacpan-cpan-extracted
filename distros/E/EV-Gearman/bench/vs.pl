#!/usr/bin/env perl
# bench/vs.pl — compare EV::Gearman against the existing CPAN
# Gearman client/worker libraries:
#   Gearman::Client          (sync, IO::Socket)
#   AnyEvent::Gearman        (async, AnyEvent on top of any backend;
#                             we run it on EV here)
#
# Each scenario runs against a single gearmand instance. The worker
# side, when used, is always EV::Gearman so the worker isn't the
# bottleneck — these numbers measure CLIENT efficiency.
#
# Usage:
#   bench/vs.pl [count]
# Env:
#   BENCH_HOST, BENCH_PORT (default 127.0.0.1:4730)
#   SKIP_SYNC=1            skip Gearman::Client (it can't pipeline)
use strict;
use warnings;
use Time::HiRes qw(time);
use IO::Socket::INET;
use EV;
use AnyEvent;

my $host  = $ENV{BENCH_HOST} || '127.0.0.1';
my $port  = $ENV{BENCH_PORT} || 4730;
my $N     = $ARGV[0]         || 5_000;
my $RT_N  = $ARGV[1]         || 1_000;     # round-trip count
my $skip_sync = $ENV{SKIP_SYNC};

# Probe server
my $probe = IO::Socket::INET->new(PeerAddr => "$host:$port", Timeout => 1)
    or die "no gearmand at $host:$port — start one first (override BENCH_HOST/PORT)\n";
close $probe;

# Detect available libraries
my %have;
for my $mod (qw(EV::Gearman Gearman::Client AnyEvent::Gearman::Client AnyEvent::Gearman::Worker)) {
    eval "require $mod; 1" and $have{$mod} = 1;
}

print "available:\n";
print "  EV::Gearman           = ", $have{'EV::Gearman'}            ? 'yes' : 'no', "\n";
print "  Gearman::Client       = ", $have{'Gearman::Client'}        ? 'yes' : 'no', "\n";
print "  AnyEvent::Gearman     = ", $have{'AnyEvent::Gearman::Client'} ? 'yes' : 'no', "\n";
print "  N=$N pipelined,  RT_N=$RT_N sequential\n";
print "\n";

die "EV::Gearman not built — run perl Makefile.PL && make first\n"
    unless $have{'EV::Gearman'};

# ===== shared worker (EV::Gearman) =====
# Spawn it as a child so we can measure clients in isolation.
my $func = "bench_vs_$$";
my $worker_pid = fork // die "fork: $!";
if (!$worker_pid) {
    # Worker process
    require EV::Gearman;
    my $w = EV::Gearman->new(host => $host, port => $port);
    $w->register_function($func => sub { $_[0]->workload });   # echo
    $w->work;
    EV::run;
    exit 0;
}
sleep 1;     # let the worker register

sub fmt_rps {
    my ($n, $dt) = @_;
    sprintf "%7d in %6.3fs = %8.0f ops/s", $n, $dt, $n / $dt;
}

# ===== EV::Gearman pipelined =====
my %pipelined_results;
{
    my $g = EV::Gearman->new(host => $host, port => $port);
    my $remaining = $N;
    my $start = time;
    for my $i (1 .. $N) {
        $g->submit_job($func, "msg$i", sub {
            EV::break if --$remaining == 0;
        });
    }
    EV::run;
    $pipelined_results{'EV::Gearman'} = time - $start;
    print "pipelined fg / EV::Gearman           : ", fmt_rps($N, $pipelined_results{'EV::Gearman'}), "\n";
    $g->disconnect; undef $g;
}

# ===== AnyEvent::Gearman pipelined =====
if ($have{'AnyEvent::Gearman::Client'}) {
    require AnyEvent::Gearman::Client;
    my $cv = AnyEvent->condvar;
    my $g  = AnyEvent::Gearman::Client->new(job_servers => ["$host:$port"]);
    my $remaining = $N;
    my $start = time;
    for my $i (1..$N) {
        $g->add_task($func, "msg$i",
            on_complete => sub { $cv->send if --$remaining == 0 },
            on_fail     => sub { warn "fail #$i"; $cv->send if --$remaining == 0 },
        );
    }
    $cv->recv;
    $pipelined_results{'AnyEvent::Gearman'} = time - $start;
    print "pipelined fg / AnyEvent::Gearman     : ", fmt_rps($N, $pipelined_results{'AnyEvent::Gearman'}), "\n";
}

# ===== Gearman::Client (sync, no pipelining possible) =====
# Sync client can do_task() one at a time. Measured as sequential.
my %seq_results;
if ($have{'Gearman::Client'} && !$skip_sync) {
    my $g = Gearman::Client->new(job_servers => ["$host:$port"]);
    my $start = time;
    for my $i (1..$RT_N) {
        my $r = $g->do_task($func, "msg$i");
    }
    $seq_results{'Gearman::Client'} = time - $start;
    print "sequential rt / Gearman::Client      : ", fmt_rps($RT_N, $seq_results{'Gearman::Client'}), "\n";
}

# ===== EV::Gearman sequential round-trip =====
{
    require EV::Gearman;
    my $g = EV::Gearman->new(host => $host, port => $port);
    my $remaining = $RT_N;
    my $i = 0;
    my $cb; $cb = sub {
        if (++$i < $RT_N) { $g->submit_job($func, "msg$i", $cb) }
        else              { EV::break }
    };
    my $start = time;
    $g->submit_job($func, "msg0", $cb);
    EV::run;
    $seq_results{'EV::Gearman'} = time - $start;
    print "sequential rt / EV::Gearman          : ", fmt_rps($RT_N, $seq_results{'EV::Gearman'}), "\n";
    $g->disconnect; undef $g;
}

# ===== AnyEvent::Gearman sequential round-trip =====
if ($have{'AnyEvent::Gearman::Client'}) {
    require AnyEvent::Gearman::Client;
    my $g = AnyEvent::Gearman::Client->new(job_servers => ["$host:$port"]);
    my $cv = AnyEvent->condvar;
    my $i = 0;
    my $sub; $sub = sub {
        if ($i >= $RT_N) { $cv->send; return }
        $i++;
        $g->add_task($func, "msg$i",
            on_complete => $sub,
            on_fail     => sub { warn "fail at $i"; $cv->send },
        );
    };
    my $start = time;
    $sub->();
    $cv->recv;
    $seq_results{'AnyEvent::Gearman'} = time - $start;
    print "sequential rt / AnyEvent::Gearman    : ", fmt_rps($RT_N, $seq_results{'AnyEvent::Gearman'}), "\n";
}

# ===== Background submissions =====
my %bg_results;
my $BG_N = $N;
{
    require EV::Gearman;
    my $g = EV::Gearman->new(host => $host, port => $port);
    my $remaining = $BG_N;
    my $start = time;
    for my $i (1..$BG_N) {
        $g->submit_job_bg($func, "msg$i", sub {
            EV::break if --$remaining == 0;
        });
    }
    EV::run;
    $bg_results{'EV::Gearman'} = time - $start;
    print "background     / EV::Gearman          : ", fmt_rps($BG_N, $bg_results{'EV::Gearman'}), "\n";
    $g->disconnect; undef $g;
}
if ($have{'AnyEvent::Gearman::Client'}) {
    require AnyEvent::Gearman::Client;
    my $g = AnyEvent::Gearman::Client->new(job_servers => ["$host:$port"]);
    my $cv = AnyEvent->condvar;
    my $remaining = $BG_N;
    my $start = time;
    for my $i (1..$BG_N) {
        $g->add_task_bg($func, "msg$i",
            on_created => sub { $cv->send if --$remaining == 0 },
            on_fail    => sub { $cv->send if --$remaining == 0 },
        );
    }
    $cv->recv;
    $bg_results{'AnyEvent::Gearman'} = time - $start;
    print "background     / AnyEvent::Gearman    : ", fmt_rps($BG_N, $bg_results{'AnyEvent::Gearman'}), "\n";
}

# Cleanup
kill 'TERM', $worker_pid;
waitpid $worker_pid, 0;

# ===== Summary table =====
print "\n=== SUMMARY ===\n";
my @cols = ('EV::Gearman', 'AnyEvent::Gearman', 'Gearman::Client');
printf "%-22s | %12s | %12s | %12s\n", '', @cols;
print '-' x 76, "\n";
my $row = sub {
    my ($label, $h, $count) = @_;
    printf "%-22s |", $label;
    for my $col (@cols) {
        if (defined $h->{$col}) {
            printf " %12.0f |", $count / $h->{$col};
        } else {
            printf " %12s |", '-';
        }
    }
    print "\n";
};
$row->('pipelined fg ops/s',  \%pipelined_results, $N);
$row->('sequential rt ops/s', \%seq_results,       $RT_N);
$row->('background  ops/s',   \%bg_results,        $BG_N);
print "\n(N=$N for pipelined/background, RT_N=$RT_N for sequential)\n";
