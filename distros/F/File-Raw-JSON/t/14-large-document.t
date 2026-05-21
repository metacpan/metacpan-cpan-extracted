#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Large document round-trip + perf sanity. Aim for a few MiB of nested
# data; nothing wild, just enough to confirm there's no quadratic
# blowup hidden in the value walker.

my $dir = tempdir(CLEANUP => 1);

# Build ~1000 records, each with a few fields; whole structure ~150 KB
# encoded. Bigger than the 64 KiB chunk size so streaming exercises
# multi-chunk behaviour where applicable.
my @records;
for my $i (1..1000) {
    push @records, {
        id    => $i,
        name  => "record-$i",
        tags  => ["tag-$i", "category-" . ($i % 10)],
        value => $i * 1.5,
        meta  => {
            created => "2026-05-05T12:00:00Z",
            ix      => $i,
        },
    };
}
my $payload = { records => \@records, total => scalar @records };

my $f = "$dir/big.json";
File::Raw::spew($f, $payload, plugin => 'json', sort_keys => 1);
my $bytes = -s $f;
ok($bytes > 100_000, "encoded size $bytes bytes (expected > 100k)");

my $back = File::Raw::slurp($f, plugin => 'json');
is($back->{total}, 1000, 'record count round-trips');
is(scalar @{$back->{records}}, 1000, 'array length round-trips');
is_deeply($back->{records}[0],   $records[0],   'first record intact');
is_deeply($back->{records}[499], $records[499], 'mid record intact');
is_deeply($back->{records}[-1],  $records[-1],  'last record intact');

# Same idea via JSONL
my $jl = "$dir/big.jsonl";
File::Raw::spew($jl, \@records, plugin => 'jsonl', sort_keys => 1);
my $jl_bytes = -s $jl;
ok($jl_bytes > 100_000, "jsonl size $jl_bytes bytes");

my $stream_count = 0;
my @stream_first;
File::Raw::each_line($jl, sub {
    $stream_count++;
    push @stream_first, $_[0] if $stream_count <= 3;
}, plugin => 'jsonl');
is($stream_count, 1000, 'streamed all 1000 records');
is_deeply($stream_first[0], $records[0], 'first streamed record intact');

done_testing;
