#!/usr/bin/env perl
# Scheduled (delayed) background jobs via submit_job_epoch.
#
# The job is handed to the server now but only dispatched to a worker
# at the given wall-clock epoch — handy for "send this email in an
# hour" or "retry at 02:00" without a separate scheduler.
#
# IMPORTANT: epoch scheduling is a server feature. A stock in-memory
# gearmand accepts the job (you get a handle, and get_status reports it
# as "known") but only actually dispatches it at the due time if it was
# started with a persistent queue backend
# (e.g. --queue-type=builtin / libsqlite3 / mysql). This example shows
# the client side — scheduling and observing — and exits without
# waiting for dispatch so it works against any gearmand.
#
# Usage: scheduled.pl [seconds-from-now]   (default 5)
use strict;
use warnings;
use EV;
use EV::Gearman;

my $delay = $ARGV[0] // 5;
my $when  = time() + $delay;

my $cli = EV::Gearman->new(host => '127.0.0.1', port => 4730);

# Schedule the job. The callback fires immediately on JOB_CREATED with
# the handle — not when the job eventually runs.
$cli->submit_job_epoch('report::nightly', "payload-$$", $when, sub {
    my ($handle, $err) = @_;
    die "schedule failed: $err\n" if $err;
    warn "[client] scheduled $handle for ", scalar(localtime $when),
         " (${delay}s from now)\n";

    # Observe the scheduled job a few times, then stop. (With a
    # persistent-queue server, `known` flips to 0 once it has run.)
    my $polls = 0;
    my $poll; $poll = EV::timer 0, 1, sub {
        $cli->get_status($handle, sub {
            my ($info) = @_;
            warn "[client] status: known=$info->{known} ",
                 "running=$info->{running}\n";
            if (!$info->{known}) {
                warn "[client] job dispatched and completed\n";
                undef $poll; EV::break;
            }
            elsif (++$polls >= 3) {
                warn "[client] still scheduled; not waiting for dispatch ",
                     "(needs a persistent-queue gearmand)\n";
                undef $poll; EV::break;
            }
        });
    };
});

my $guard = EV::timer 30, 0, sub { warn "timeout\n"; EV::break };
EV::run;
