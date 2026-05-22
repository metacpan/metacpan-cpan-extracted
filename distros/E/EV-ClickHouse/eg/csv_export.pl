#!/usr/bin/env perl
# Stream a multi-million-row select directly to a CSV file via on_data,
# without buffering the whole result in memory. Two implementations:
#
#   1. on_data callback - lowest overhead per block.
#   2. iterate() pull form - mirror, useful for procedural code.
#
# Both flush rows incrementally so the producer's RSS stays flat
# regardless of result size.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST}        // '127.0.0.1';
my $nport = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $rows  = $ENV{ROWS}                   // 1_000_000;
my $out   = $ENV{OUT}                    // 'export.csv';

open my $fh, '>', $out or die "open $out: $!";
$fh->autoflush(0);

my $written = 0;

# Path 1: callback-driven streaming via on_data.
my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $nport, protocol => 'native',
    on_connect => sub {
        $ch->query(
            "select number, toString(now() + number) from numbers($rows)",
            { on_data => sub {
                my ($batch) = @_;
                # Each $batch is an arrayref of arrayrefs. CSV-quote the
                # second field (timestamp string) to handle any commas.
                for my $row (@$batch) {
                    print $fh $row->[0], ',', '"', $row->[1], '"', "\n";
                }
                $written += @$batch;
            } },
            sub {
                my (undef, $err) = @_;
                if ($err) { warn "query failed: $err\n" }
                else      { warn "exported $written rows to $out\n" }
                EV::break;
            },
        );
    },
    on_error => sub { warn "error: $_[0]\n"; EV::break },
);
EV::run;
close $fh;
$ch->finish if $ch->is_connected;

# Path 2 (alternative): synchronous-feel via iterate.
#   my $it = $ch->iterate("select ... from numbers($rows)");
#   while (my $batch = $it->next(60)) {
#       for my $row (@$batch) { print $fh ... }
#   }
#   die $it->error if $it->error;
