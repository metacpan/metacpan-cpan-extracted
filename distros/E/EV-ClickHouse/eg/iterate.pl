#!/usr/bin/env perl
# Pull-iterator: synchronous-feeling consumption of a streaming select.
# Useful for procedural ETL / export pipelines where callback-driven
# code doesn't fit the rest of the program. Native protocol only:
# iterate() relies on the per-block on_data hook and croaks on HTTP.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $ch = EV::ClickHouse->new(
    host     => $ENV{CLICKHOUSE_HOST}        // '127.0.0.1',
    port     => $ENV{CLICKHOUSE_NATIVE_PORT} // 9000,
    protocol => 'native',
);

my $it = $ch->iterate("select number from numbers(50_000)");
my $total = 0;
while (my $batch = $it->next(10)) {
    $total += scalar @$batch;
}
die "iteration error: " . $it->error if $it->error;
print "Streamed $total rows in batches\n";
$ch->finish;
