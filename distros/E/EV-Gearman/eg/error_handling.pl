#!/usr/bin/env perl
# Error scenarios and how callbacks see them.
#
# 1. Worker dies + exceptions  -> on_exception($exc) THEN ($undef, "exception")
# 2. Submit while not connected -> croak "not connected"
# 3. Disconnect mid-job        -> ($undef, "disconnected")
use strict;
use warnings;
use EV;
use EV::Gearman;

my $cli = EV::Gearman->new(
    host       => '127.0.0.1',
    port       => 4730,
    exceptions => 1,            # ask server to forward exceptions
);
my $wkr = EV::Gearman->new(
    host       => '127.0.0.1',
    port       => 4730,
    exceptions => 1,            # forward die() as WORK_EXCEPTION, not WORK_FAIL
);
$wkr->register_function('boom' => sub { die "kaboom!\n" });

# Cases run chained: each calls $done when its output is printed.
my @cases = (
    sub {
        my ($done) = @_;
        warn "1) worker dies + exceptions=1\n";
        $cli->submit_job(boom => "x", {
            on_exception => sub { warn "  on_exception: $_[0]\n" },
        }, sub {
            my ($r, $e) = @_;
            warn "  result=", ($r // "undef"), " err=", ($e // "undef"), "\n";
            $done->();
        });
    },
    sub {
        my ($done) = @_;
        warn "\n2) submit while not connected (synchronous croak)\n";
        my $g = EV::Gearman->new;
        eval { $g->echo("ping", sub {}) };
        warn "  croaked: $@" if $@;
        $done->();
    },
    sub {
        my ($done) = @_;
        warn "\n3) disconnect cancels in-flight callbacks\n";
        my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);
        $g->on_connect(sub {
            $g->submit_job('never_serves_'.$$, "x", sub {
                warn "  cancelled: result=", ($_[0] // "undef"),
                     " err=", ($_[1] // "undef"), "\n";
                $done->();
            });
            $g->disconnect;
        });
    },
);

$wkr->work;
my $next;
$next = sub {
    my $case = shift @cases or do { EV::break; return };
    $case->($next);
};
$next->();
my $guard = EV::timer 15, 0, sub { warn "timeout\n"; EV::break };
EV::run;
