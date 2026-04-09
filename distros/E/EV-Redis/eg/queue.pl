#!/usr/bin/env perl
use strict;
use warnings;
use EV::Redis;

$| = 1;

# Reliable queue pattern using lists.
# Producer pushes jobs, worker blocks waiting for them.

my $producer = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Producer error: @_\n" },
);

my $worker = EV::Redis->new(
    host     => '127.0.0.1',
    on_error => sub { warn "Worker error: @_\n" },
);

my $queue = 'jobs';
my $jobs_total = 5;
my $jobs_done  = 0;

# Worker: block-pop jobs, process them
sub wait_for_job {
    $worker->brpop($queue, 2, sub {
        my ($res, $err) = @_;
        if ($err) {
            warn "BRPOP error: $err\n";
            return;
        }
        unless ($res) {
            # Timeout — no more jobs
            print "\nWorker: queue empty, done.\n";
            $worker->disconnect;
            $producer->disconnect;
            return;
        }

        my ($list, $job) = @$res;
        $jobs_done++;
        print "Worker: processed '$job' ($jobs_done/$jobs_total)\n";
        wait_for_job();  # wait for next
    });
}

# Start worker first (it blocks waiting)
wait_for_job();

# Producer: push jobs with a small delay between each
my $i = 0;
my $w; $w = EV::timer 0.1, 0.2, sub {
    $i++;
    my $job = "job_$i";
    $producer->lpush($queue, $job, sub {
        print "Producer: enqueued '$job'\n";
    });
    if ($i >= $jobs_total) {
        undef $w;
    }
};

EV::run;
