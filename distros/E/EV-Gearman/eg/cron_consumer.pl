#!/usr/bin/env perl
# Cron-style batch consumer: drain whatever jobs are queued right now,
# then exit. Run it from cron / a systemd timer to process a backlog in
# bounded bursts instead of holding a long-lived worker.
#
# Uses grab_job (not work / work_one): grab_job asks for one job and
# reports "no job" immediately when the queue is empty, so we can stop
# as soon as there's nothing left — exactly the cron semantics. (work
# and work_one would PRE_SLEEP and wait for the next job instead.)
#
# Usage: cron_consumer.pl [max-jobs]   (default: drain until empty)
use strict;
use warnings;
use EV;
use EV::Gearman;

my $max = $ARGV[0];           # undef => no cap
my $func = 'batch::task';

my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);

my $processed = 0;
my $drain; $drain = sub {
    if (defined $max && $processed >= $max) {
        warn "[cron] hit cap of $max jobs\n";
        $g->disconnect; EV::break; return;
    }
    $g->grab_job(sub {
        my ($job, $err) = @_;
        if ($err) {               # "no job" => queue drained, we're done
            warn "[cron] queue empty after $processed job(s)\n";
            $g->disconnect; EV::break; return;
        }
        $processed++;
        my $out = uc $job->workload;
        warn "[cron] #$processed ", $job->handle, ": ", $job->workload,
             " -> $out\n";
        $job->complete($out);
        $drain->();               # grab the next one
    });
};

# Announce the ability (grab_job only receives jobs for functions this
# connection has declared via can_do), then start draining.
$g->on_connect(sub {
    $g->can_do($func);
    $drain->();
});

my $guard = EV::timer 30, 0, sub { warn "[cron] timeout\n"; EV::break };
EV::run;
