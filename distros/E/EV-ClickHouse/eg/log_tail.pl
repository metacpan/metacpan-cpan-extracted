#!/usr/bin/env perl
# tail -f for ClickHouse system.text_log.
#
# Polls system.text_log on a fixed interval, prints any new rows whose
# event_time is past the last cursor. Filters by minimum severity
# (default 'Information'). Lightweight alternative to wiring on_log
# at the protocol level when you want a server-side history view.
#
# Requires <text_log> enabled in the server config — skips silently
# if the table isn't present.
#
# Usage:
#   LEVEL=Warning POLL=2 ./eg/log_tail.pl

use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $port  = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $level = $ENV{LEVEL}                  // 'Information';
my $poll  = $ENV{POLL}            // 1;       # seconds

# CH log levels go Trace=1 < Debug=2 < Information=3 < Notice=4 <
# Warning=5 < Error=6 < Critical=7 < Fatal=8.
my %lvl = (
    Trace => 1, Debug => 2, Information => 3, Notice => 4,
    Warning => 5, Error => 6, Critical => 7, Fatal => 8,
);
my $min = $lvl{$level} or die "unknown LEVEL=$level (want one of: " . join(',', sort keys %lvl) . ")\n";

my $cursor;     # event_time_microseconds of the last row we printed
my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $port, protocol => 'native',
    on_connect => sub {
        # Check the table exists. system.text_log requires explicit
        # config in the server's <text_log> section.
        $ch->query(
            "select 1 from system.tables where database='system' and name='text_log'",
            sub {
                my ($r) = @_;
                unless ($r && @$r) {
                    warn "system.text_log not enabled (add <text_log> to config.xml)\n";
                    return EV::break;
                }
                # Start from "now" so we only see new entries.
                $ch->query("select now64()", sub {
                    $cursor = $_[0][0][0];
                    schedule_poll();
                });
            });
    },
    on_error => sub { warn "ch: $_[0]\n"; EV::break },
);

my $timer;
sub schedule_poll {
    $timer = EV::timer($poll, $poll, sub {
        $ch->query(
            "select event_time_microseconds, level, message, query_id"
          . " from system.text_log"
          . " where event_time_microseconds > {since:DateTime64(6)}"
          . "   and toUInt8(level) >= {min:UInt8}"
          . " order by event_time_microseconds",
            { params => { since => $cursor, min => $min } },
            sub {
                my ($rows, $err) = @_;
                return warn "poll: $err\n" if $err;
                for my $r (@$rows) {
                    my ($ts, $lvl_name, $msg, $qid) = @$r;
                    printf "[%s] %-11s %s %s\n",
                           $ts, $lvl_name, $qid || '-', $msg;
                    $cursor = $ts;
                }
            });
    });
}

my $sig = EV::signal('INT', sub { EV::break });
EV::run;
$ch->finish;
