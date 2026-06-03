#!/usr/bin/env perl
# Graceful worker shutdown.
#
# On SIGTERM / SIGINT: stop grabbing new jobs but let in-flight async
# jobs finish, then disconnect cleanly. Replaces the common bug of
# killing the worker mid-job and leaking gearmand-side state.
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(
    host       => $ENV{GEARMAN_HOST} // '127.0.0.1',
    port       => $ENV{GEARMAN_PORT} // 4730,
    client_id  => "graceful-$$",
    reconnect  => 1,
    on_connect => sub { warn "connected\n" },
);

my %inflight;   # handle -> job (async)

$g->register_function(slow => { async => 1 }, sub {
    my $job = shift;
    my $h = $job->handle;
    $inflight{$h} = $job;
    # Retain the timer: a bare EV::timer in void context is freed when
    # this callback returns, so it would never fire.
    my $t; $t = EV::timer 1, 0, sub {
        $job->complete("done: " . $job->workload);
        delete $inflight{$h};
        undef $t;
    };
});

$g->work;

# Signal-driven shutdown — EV::signal converts the signal into an
# event-loop callback so we don't unwind C state at an unsafe point.
my $shutting_down = 0;
my @sig;
for my $name (qw(TERM INT)) {
    push @sig, EV::signal $name => sub {
        return if $shutting_down++;
        warn "shutdown requested; finishing ", scalar keys %inflight, " jobs...\n";
        $g->work_stop;          # stop GRAB_JOB

        # Poll: when all in-flight jobs have finished, disconnect.
        my $w; $w = EV::timer 0.1, 0.1, sub {
            return if %inflight;
            $g->disconnect;
            undef $w;
            EV::break;
        };
    };
}

EV::run;
warn "bye\n";
