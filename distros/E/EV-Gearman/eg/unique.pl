#!/usr/bin/env perl
# Job coalescing with unique keys.
#
# When several clients submit the same logical work — "rebuild cache
# for user 42", "render thumbnail for image 7" — a `unique` key tells
# gearmand to coalesce them into a single job. Every client that
# submitted that key is attached to the one running job and receives
# the same result, so the work runs once instead of N times.
#
# get_status_unique lets you query/observe a job by its key (including
# how many clients are currently waiting on it).
use strict;
use warnings;
use EV;
use EV::Gearman;

my $cli = EV::Gearman->new(host => '127.0.0.1', port => 4730);
# grab_unique => 1 so the worker is told the submitter's unique key
# (JOB_ASSIGN_UNIQ); without it $job->unique is empty.
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => 4730, grab_unique => 1);

# A deliberately slow worker so the coalescing window is observable.
# Async, so retain the timer watcher until it fires (a bare
# `EV::timer` in void context is destroyed immediately and never runs).
my $runs = 0;
$wkr->register_function('cache::rebuild' => { async => 1 }, sub {
    my $job = shift;
    my $n = ++$runs;
    warn "[worker] run #$n for unique=", $job->unique, "\n";
    my $t; $t = EV::timer 1, 0, sub {
        $job->complete("rebuilt by run #$n");
        undef $t;
    };
});
$wkr->work;

# Fire five submissions for the SAME unique key. gearmand coalesces
# them: the worker runs once, but all five callbacks get the result.
my $key = "user-42";
my $pending = 5;
for my $i (1 .. 5) {
    $cli->submit_job('cache::rebuild', "req-$i", { unique => $key }, sub {
        my ($result, $err) = @_;
        warn "[client] submission $i got: ", ($result // "err:$err"), "\n";
        EV::break unless --$pending;
    });
}

# While they're in flight, observe the shared job by its key. Retain
# the timer (a bare EV::timer in void context would be freed before it
# fires).
my $observe; $observe = EV::timer 0.2, 0, sub {
    undef $observe;
    $cli->get_status_unique($key, sub {
        my ($info) = @_;
        warn "[client] unique=$key known=$info->{known} ",
             "running=$info->{running} clients=$info->{client_count}\n";
    });
};

my $guard = EV::timer 10, 0, sub { warn "timeout\n"; EV::break };
EV::run;

warn "[client] worker ran the job $runs time(s) for 5 submissions\n";
