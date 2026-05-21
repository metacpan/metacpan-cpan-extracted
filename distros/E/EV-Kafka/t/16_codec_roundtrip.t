use strict;
use warnings;
use Test::More;
use EV::Kafka;

plan tests => 20;

# Single record, no compression.
{
    my $bytes = EV::Kafka::_test_encode_batch(
        [{ key => 'k1', value => 'v1' }]
    );
    ok length($bytes) > 0, 'single record encodes to non-empty bytes';

    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    ok $decoded, 'single record decodes';
    is scalar @$decoded, 1, 'one record back';
    is $decoded->[0]{key},   'k1', 'key round-trips';
    is $decoded->[0]{value}, 'v1', 'value round-trips';
}

# Many records.
{
    my @recs = map { { key => "k$_", value => "v$_" } } 1..50;
    my $bytes = EV::Kafka::_test_encode_batch(\@recs);
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is scalar @$decoded, 50, '50-record batch round-trips';
    is $decoded->[0]{value},  'v1',  'first record value preserved';
    is $decoded->[49]{value}, 'v50', 'last record value preserved';
}

# Headers preserved.
{
    my $bytes = EV::Kafka::_test_encode_batch(
        [{ key => 'k', value => 'v', headers => { 'h1' => 'a', 'h2' => 'b' } }]
    );
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is_deeply $decoded->[0]{headers}, { h1 => 'a', h2 => 'b' },
        'headers round-trip';
}

# Null key / null value.
{
    my $bytes = EV::Kafka::_test_encode_batch(
        [{ key => undef, value => undef }]
    );
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    ok !defined $decoded->[0]{key},   'null key preserved';
    ok !defined $decoded->[0]{value}, 'null value preserved';
}

# Idempotent producer fields are encoded but stripped on decode (decoder
# doesn't surface producer_id/epoch — that's broker-only state).
{
    my $bytes = EV::Kafka::_test_encode_batch(
        [{ key => 'k', value => 'v' }],
        { producer_id => 42, producer_epoch => 3, base_sequence => 100 },
    );
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is scalar @$decoded, 1, 'idempotent batch decodes';
    is $decoded->[0]{value}, 'v', 'payload survives idempotent encode';
}

# Compression: gzip.
SKIP: {
    skip "gzip support not built", 2 unless eval {
        my $b = EV::Kafka::_test_encode_batch(
            [{ key => 'k', value => 'gzip-payload' }],
            { compression => 1 },
        );
        defined $b;
    };
    my $bytes = EV::Kafka::_test_encode_batch(
        [ map { { key => "k$_", value => "gzip-$_" } } 1..20 ],
        { compression => 1 },
    );
    ok length($bytes) > 0, 'gzip-compressed batch encodes';
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is scalar @$decoded, 20, 'gzip batch round-trips';
}

# Compression: lz4.
SKIP: {
    skip "lz4 support not built", 2 unless eval {
        my $b = EV::Kafka::_test_encode_batch(
            [{ key => 'k', value => 'lz4-payload' }],
            { compression => 3 },
        );
        defined $b;
    };
    my $bytes = EV::Kafka::_test_encode_batch(
        [ map { { key => "k$_", value => "lz4-$_" } } 1..20 ],
        { compression => 3 },
    );
    ok length($bytes) > 0, 'lz4-compressed batch encodes';
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is scalar @$decoded, 20, 'lz4 batch round-trips';
}

# Highly compressible payload — exercises decompression buffer growth.
SKIP: {
    skip "lz4 not built", 1 unless eval {
        defined EV::Kafka::_test_encode_batch([{key=>'k',value=>'x'}], {compression=>3});
    };
    my $payload = 'a' x 100_000;   # 100k of 'a' compresses ~100x
    my $bytes = EV::Kafka::_test_encode_batch(
        [{ key => 'big', value => $payload }],
        { compression => 3 },
    );
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is length($decoded->[0]{value}), length($payload),
        'highly-compressible lz4 payload survives the doubling decode loop';
}

# Compression: zstd (code 4).
SKIP: {
    skip "zstd not built", 1 unless eval {
        my $b = EV::Kafka::_test_encode_batch([{key=>'k',value=>'z'}], {compression=>4});
        my $r = EV::Kafka::_test_decode_batch($b);
        $r && $r->[0]{value} eq 'z';
    };
    my $bytes = EV::Kafka::_test_encode_batch(
        [ map { { key => "k$_", value => "zstd-$_" } } 1..20 ],
        { compression => 4 },
    );
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is scalar @$decoded, 20, 'zstd batch round-trips';
}

# Compression: snappy (code 2).
SKIP: {
    skip "snappy not built", 1 unless eval {
        my $b = EV::Kafka::_test_encode_batch([{key=>'k',value=>'s'}], {compression=>2});
        my $r = EV::Kafka::_test_decode_batch($b);
        $r && $r->[0]{value} eq 's';
    };
    my $bytes = EV::Kafka::_test_encode_batch(
        [ map { { key => "k$_", value => "snappy-$_" } } 1..20 ],
        { compression => 2 },
    );
    my $decoded = EV::Kafka::_test_decode_batch($bytes);
    is scalar @$decoded, 20, 'snappy batch round-trips';
}
