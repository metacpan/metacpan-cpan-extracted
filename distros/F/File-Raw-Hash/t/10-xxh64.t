#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Published xxh64 test vectors from the official xxHash specification.
my @VECTORS = (
    # data,                                            seed,         expected (16 hex)
    [ '',                                               0,           'ef46db3751d8e999' ],
    [ 'Nobody inspects the spammish repetition',        0,           'fbcea83c8a378bf1' ],
);

for my $v (@VECTORS) {
    my ($data, $seed, $expected) = @$v;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $data;
    close $fh;

    my $d;
    file_slurp($path,
        plugin     => 'hash',
        algo       => 'xxh64',
        xxh64_seed => $seed,
        into       => \$d,
    );
    is($d, $expected, "xxh64 spec vector seed=$seed (" . length($data) . " B)");
}

# Default seed is 0.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    my $d_default;
    my $d_explicit;
    file_slurp($path, plugin => 'hash', algo => 'xxh64',
                                          into => \$d_default);
    file_slurp($path, plugin => 'hash', algo => 'xxh64',
               xxh64_seed => 0,           into => \$d_explicit);
    is($d_default, $d_explicit, 'omitting xxh64_seed defaults to 0');
}

# Different seeds produce different digests.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh 'abc';
    close $fh;
    my ($a, $b);
    file_slurp($path, plugin => 'hash', algo => 'xxh64',
               xxh64_seed => 0,    into => \$a);
    file_slurp($path, plugin => 'hash', algo => 'xxh64',
               xxh64_seed => 12345, into => \$b);
    isnt($a, $b, 'different xxh64 seeds yield different digests');
}

# Multi-algo with xxh64 + sha256 in one pass.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh 'Nobody inspects the spammish repetition';
    close $fh;

    my %got;
    file_slurp($path,
        plugin => 'hash',
        algos  => [qw(xxh64 sha256)],
        xxh64_seed => 0,
        into   => \%got,
    );
    is($got{xxh64},  'fbcea83c8a378bf1', 'multi-algo xxh64 entry');
    like($got{sha256}, qr/^[0-9a-f]{64}$/, 'multi-algo sha256 entry shape');
}

# STREAM path (each_line) for xxh64 over a large-ish input.
{
    my $payload = ('abcdefghij' x 7000) . "\n";   # > 64 KiB to force chunking
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $payload;
    close $fh;

    my $oneshot;
    file_slurp($path, plugin => 'hash', algo => 'xxh64', into => \$oneshot);

    my $streamed;
    File::Raw::each_line($path, sub {},
        plugin => 'hash', algo => 'xxh64', into => \$streamed);

    is($streamed, $oneshot,
       'xxh64 STREAM digest matches one-shot READ digest');
}

done_testing;
