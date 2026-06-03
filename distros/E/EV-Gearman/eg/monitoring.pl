#!/usr/bin/env perl
# Periodically poll gearmand admin metrics. Useful for prometheus
# exporters, dashboards, or "is it healthy?" probes.
#
# Outputs lines suitable for ingestion by a metric collector:
#   gearman_jobs_total{func="reverse"} 42
#   gearman_jobs_running{func="reverse"} 1
#   gearman_workers{func="reverse"} 3
use strict;
use warnings;
use EV;
use EV::Gearman;

my $g = EV::Gearman->new(
    host       => $ENV{GEARMAN_HOST} // '127.0.0.1',
    port       => $ENV{GEARMAN_PORT} // 4730,
    reconnect  => 1,
    on_error   => sub { warn "monitor: $_[0]\n" },
);

my $interval = $ENV{INTERVAL} // 5;

my $tick; $tick = EV::timer 0, $interval, sub {
    return unless $g->is_connected;
    $g->server_status(sub {
        my ($txt, $err) = @_;
        return warn "status fail: $err\n" if $err;
        my $now = time;
        for my $line (split /\n/, $txt) {
            chomp $line;
            next unless length $line;
            my ($func, $total, $running, $workers) = split /\t/, $line;
            print "gearman_jobs_total{func=\"$func\"} $total $now\n";
            print "gearman_jobs_running{func=\"$func\"} $running $now\n";
            print "gearman_workers{func=\"$func\"} $workers $now\n";
        }
        STDOUT->flush;
    });
};

EV::run;
