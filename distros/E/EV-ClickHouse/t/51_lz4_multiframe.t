#!/usr/bin/env perl
# Coverage for LZ4-compressed native results that span MULTIPLE compressed
# frames and MULTIPLE Data packets. The rest of the suite only ever exercises
# single small compressed blocks, so the chained-frame path in
# ch_lz4_decompress_chain() was effectively untested.
#
# This is a guard against regressions in the decompression chain (it does not
# by itself reproduce the ~1/256 coalesced-packet misparse, which is timing and
# checksum-content dependent).
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 6;

# ~300k rows each carrying a long-ish string: comfortably exceeds the 1 MiB
# max_compress_block_size, so the server emits several LZ4 frames, and with a
# small max_block_size it also emits many Data packets.
my $ROWS = 300_000;

for my $case (
    { name => 'default block size', settings => {} },
    { name => 'small max_block_size (many packets)',
      settings => { max_block_size => 8192 } },
) {
    my ($rows, $err);

    my $ch; $ch = EV::ClickHouse->new(
        host => $host, port => $nport, protocol => 'native', compress => 1,
        on_connect => sub {
            $ch->query(
                "SELECT number, repeat('x', 64) AS pad FROM numbers($ROWS)",
                { %{ $case->{settings} } },
                sub {
                    ($rows, $err) = @_;
                    EV::break;
                });
        },
        on_error => sub { $err //= $_[1] // 'connection error'; EV::break },
    );
    EV::run;

    is($err, undef, "$case->{name}: no error")
        or diag("error: " . (defined $err ? $err : '(undef)'));
    is(ref($rows) eq 'ARRAY' ? scalar(@$rows) : -1, $ROWS,
       "$case->{name}: all $ROWS rows decoded from the multi-frame stream");
    my $ok = 1;
    if (ref($rows) eq 'ARRAY' && @$rows == $ROWS) {
        # Spot-check first, middle and last row survived the chain intact.
        for my $i (0, int($ROWS / 2), $ROWS - 1) {
            my $r = $rows->[$i];
            unless (ref $r eq 'ARRAY' && $r->[0] == $i && $r->[1] eq ('x' x 64)) {
                $ok = 0;
                diag("row $i mismatch: " . join(',', map { defined() ? $_ : 'undef' } @$r));
                last;
            }
        }
    } else { $ok = 0 }
    ok($ok, "$case->{name}: row contents intact across frame boundaries");
}
