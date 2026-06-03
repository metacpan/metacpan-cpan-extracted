# Async worker concurrency: many in-flight async jobs at once,
# with completion order interleaved arbitrarily. Verifies that
# the active_jobs hash routes correctly under random delivery.
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

# Use multiple parallel workers so the gearmand actually fans out.
my @workers;
my $POOL = 8;
for my $i (1..$POOL) {
    my $w = EV::Gearman->new(host => $host, port => $port);
    my %live;
    $w->register_function('xt_async_'.$$ => { async => 1 }, sub {
        my $job = shift;
        my $h = $job->handle;
        $live{$h} = $job;
        # Random delay 1-100ms
        my $ms = 1 + int rand 100;
        my $t; $t = EV::timer $ms / 1000.0, 0, sub {
            $job->complete($job->workload . "::done");
            delete $live{$h};
            undef $t;
        };
    });
    $w->work;
    push @workers, $w;
}

my $cli = EV::Gearman->new(host => $host, port => $port);
my $N = 200;
my %got;
my $remaining = $N;
my $err_count = 0;
for my $i (1..$N) {
    $cli->submit_job('xt_async_'.$$, "v$i", sub {
        my ($r, $e) = @_;
        $err_count++ if $e;
        $got{$i} = $r;
        EV::break unless --$remaining;
    });
}

my $g = EV::timer 30, 0, sub { fail "async timeout"; EV::break };
EV::run;
is $err_count, 0, 'no async errors';
is scalar(keys %got), $N, "all $N async jobs completed";
my $bad = 0;
for my $i (1..$N) {
    $bad++ unless defined($got{$i}) && $got{$i} eq "v$i\::done";
}
is $bad, 0, 'all results match expected suffix';
done_testing;
