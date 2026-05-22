#!/usr/bin/env perl
# Periodic health probe via is_healthy: ping every N seconds with a
# bounded timeout, log transitions, and trigger recovery on failure.
# Pattern works for HTTP load balancers (orchestrators consult some
# external metric) and for self-monitoring daemons.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $every = $ENV{PROBE_INTERVAL}         // 5;     # seconds
my $bound = $ENV{PROBE_TIMEOUT}          // 2;     # seconds

my $last_state = -1;     # -1 = unknown, 0 = down, 1 = up
my $ch = EV::ClickHouse->new(
    host           => $host, port => $nport, protocol => 'native',
    auto_reconnect => 1,
    reconnect_delay  => 0.5,
    reconnect_jitter => 0.2,        # spread retries when many probes converge
    on_error => sub { },            # absorb; the probe itself reports state
);

my $probe = EV::timer(0, $every, sub {
    $ch->is_healthy(sub {
        my ($ok, $err) = @_;
        my $now = scalar localtime;
        if ($ok && $last_state != 1) {
            print "[$now] UP   on ", $ch->current_host, ':',
                  $ch->current_port, "\n";
        } elsif (!$ok && $last_state != 0) {
            print "[$now] DOWN ($err)\n";
            $ch->reset;             # kick off recovery
        }
        $last_state = $ok ? 1 : 0;
    }, $bound);
});

my $shutdown = EV::signal('INT', sub { EV::break });
EV::run;
$ch->finish;
