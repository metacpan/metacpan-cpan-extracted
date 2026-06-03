#!/usr/bin/env perl
# Error scenarios and how callbacks see them.
#
# 1. Worker dies               -> ($result=undef, $err="job failed")
# 2. Worker dies + exceptions  -> on_exception($exc) THEN ($undef, "exception")
# 3. Connection drops          -> ($undef, "disconnected")
# 4. Server reports ERROR pkt  -> ($undef, "ERR_CODE: ERR_TEXT")
# 5. Submit while not connected -> croak "not connected"
use strict;
use warnings;
use EV;
use EV::Gearman;

my $cli = EV::Gearman->new(
    host       => '127.0.0.1',
    port       => 4730,
    exceptions => 1,            # ask server to forward exceptions
);
my $wkr = EV::Gearman->new(host => '127.0.0.1', port => 4730);

# 1. Plain die in worker
$wkr->register_function('boom' => sub { die "kaboom!\n" });

# 2. Worker dies *with* exception delivery (since exceptions=1 above)
# (same handler; the WORK_EXCEPTION flow only differs for the client)

# Run a few error cases sequentially via a small driver
my @cases = (
    sub {
        warn "1) worker dies + exceptions=1\n";
        my $exc;
        $cli->submit_job(boom => "x", {
            on_exception => sub { $exc = $_[0]; warn "  on_exception: $exc\n" },
        }, sub {
            my ($r, $e) = @_;
            warn "  result=", ($r // "undef"), " err=", ($e // "undef"), "\n";
            EV::break;
        });
    },
    sub {
        warn "\n2) submit while not connected (synchronous croak)\n";
        my $g = EV::Gearman->new;
        eval { $g->echo("ping", sub {}) };
        warn "  croaked: $@" if $@;
        EV::break;
    },
    sub {
        warn "\n3) disconnect cancels in-flight callbacks\n";
        my $g = EV::Gearman->new(host => '127.0.0.1', port => 4730);
        $g->on_connect(sub {
            $g->submit_job('never_serves_'.$$, "x", sub {
                warn "  cancelled: result=", ($_[0] // "undef"),
                     " err=", ($_[1] // "undef"), "\n";
                EV::break;
            });
            $g->disconnect;
        });
    },
);

$wkr->work;
my $next = sub {};
$next = sub {
    my $case = shift @cases or do { EV::break; return };
    $case->();
};
my $tick; $tick = EV::timer 0, 1.5, sub { $next->() };
EV::run;
