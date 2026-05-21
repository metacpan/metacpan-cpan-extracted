#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Empty-input vector is the canonical published BLAKE3 hash.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'blake3', into => \$d);
    is($d, 'af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262',
       'BLAKE3 of empty input matches published vector');
}

# A handful of length-based vectors from the official BLAKE3
# test_vectors.json (input is bytes (i % 251) for i in 0..N-1).
sub fill_input {
    my ($n) = @_;
    my $s = '';
    for (my $i = 0; $i < $n; $i++) { $s .= chr($i % 251); }
    return $s;
}

my @LEN_VECTORS = (
    [    1, '2d3adedff11b61f14c886e35afa036736dcd87a74d27b5c1510225d0f592e213' ],
    [    2, '7b7015bb92cf0b318037702a6cdd81dee41224f734684c2c122cd6359cb1ee63' ],
    [    3, 'e1be4d7a8ab5560aa4199eea339849ba8e293d55ca0a81006726d184519e647f' ],
    # 1024-byte boundary: exactly one chunk.
    [ 1024, '42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af7' ],
    # 1025: forces tree path (two chunks).
    [ 1025, 'd00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444' ],
);

for my $v (@LEN_VECTORS) {
    my ($n, $expected) = @$v;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh fill_input($n);
    close $fh;

    my $d;
    file_slurp($path, plugin => 'hash', algo => 'blake3', into => \$d);
    is($d, $expected, "BLAKE3 of length $n matches official vector");
}

# Streaming consistency: each_line over a multi-chunk file matches
# one-shot digest.
{
    my $payload = fill_input(5000);    # almost 5 chunks
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $payload;
    close $fh;

    my $oneshot;
    file_slurp($path, plugin => 'hash', algo => 'blake3', into => \$oneshot);

    my $streamed;
    File::Raw::each_line($path, sub {},
        plugin => 'hash', algo => 'blake3', into => \$streamed);

    is($streamed, $oneshot,
       'BLAKE3 STREAM digest matches one-shot READ digest across chunks');
}

# Multi-algo: blake3 alongside sha256 + xxh64.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh 'abc';
    close $fh;

    my %got;
    file_slurp($path,
        plugin => 'hash',
        algos  => [qw(blake3 sha256 xxh64)],
        into   => \%got,
    );
    like($got{blake3}, qr/^[0-9a-f]{64}$/, 'blake3 multi-algo entry shape');
    is($got{sha256},
       'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
       'sha256 alongside blake3 still correct');
    is($got{xxh64}, '44bc2cf5ad770999', 'xxh64 alongside blake3 still correct');
}

# raw and base64 formats produce the right-length output for blake3.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    my ($raw, $b64);
    file_slurp($path, plugin => 'hash', algo => 'blake3',
               format => 'raw',    into => \$raw);
    file_slurp($path, plugin => 'hash', algo => 'blake3',
               format => 'base64', into => \$b64);
    is(length($raw), 32, 'BLAKE3 raw digest is 32 bytes');
    # 32 bytes -> ceil(32/3)*4 = 44 chars padded
    is(length($b64), 44, 'BLAKE3 base64 digest is 44 chars (padded)');
}

done_testing;
