#!/usr/bin/env perl
# Dashboard / metrics integration: feed on_query_complete and on_progress
# into a statsd / Prometheus-shaped sink. The hooks are designed for this
# exact pattern - on_query_complete fires once per query with profile
# totals + duration; on_progress fires repeatedly during long selects with
# rows-so-far / bytes-so-far counters.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;

# Stand-in metric backend - replace with Net::Statsd::Tiny / Prometheus etc.
my %counters;
my %histograms;
sub metric_inc { $counters{$_[0]}    += $_[1] // 1 }
sub metric_obs { push @{ $histograms{$_[0]} //= [] }, $_[1] }
sub dump_metrics {
    print "\nCounters:\n";
    printf "  %-32s %d\n", $_, $counters{$_} for sort keys %counters;
    print "Histograms (count / mean):\n";
    for my $k (sort keys %histograms) {
        my @v = @{ $histograms{$k} };
        my $mean = @v ? (eval { my $s = 0; $s += $_ for @v; $s / @v }) : 0;
        printf "  %-32s %d / %.4f\n", $k, scalar @v, $mean;
    }
}

my $ch; $ch = EV::ClickHouse->new(
    host             => $host, port => $nport, protocol => 'native',
    progress_period  => 1,                 # coalesce on_progress to 1Hz
    on_query_complete => sub {
        my ($qid, $rows, $bytes, $err_code, $duration_s, $err) = @_;
        metric_inc 'ch.query.total';
        if ($err) {
            metric_inc 'ch.query.error.total';
            metric_inc "ch.query.error.code.$err_code" if $err_code;
        } else {
            metric_inc 'ch.query.success.total';
            metric_obs 'ch.query.rows',          $rows;
            metric_obs 'ch.query.bytes',         $bytes;
            metric_obs 'ch.query.duration.seconds', $duration_s;
        }
    },
    on_progress => sub {
        my ($rows, $bytes, $total_rows, $written_rows, $written_bytes) = @_;
        metric_inc 'ch.progress.rows',  $rows;
        metric_inc 'ch.progress.bytes', $bytes;
    },
    on_connect       => sub {
        # Mix of fast + slow + failing queries to exercise all paths.
        for my $sql (
            "select 1",
            "select count() from numbers(10_000_000)",
            "select 'broken-on-purpose' from no_such_table_$$",
        ) {
            $ch->query($sql, { on_data => sub { } }, sub { });
        }
        $ch->drain(sub { EV::break });
    },
    on_error => sub { },
);
EV::run;
$ch->finish;
dump_metrics();
