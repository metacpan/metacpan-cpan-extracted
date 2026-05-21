#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# STREAM phase: each_line digests the file in chunks. The digest
# arrives in the caller's scalar after iteration completes.
#
# File::Raw's stream dispatcher reads in 64 KiB chunks (file.c:81), so
# build an input that exceeds that to confirm we hash across multiple
# chunks correctly.

my @lines;
for (1 .. 5000) {
    push @lines, "line $_ - " . ('x' x ($_ % 100)) . "\n";
}
my $payload = join '', @lines;
ok(length($payload) > 65536, 'payload exceeds one chunk');

my ($fh, $path) = tempfile(UNLINK => 1);
binmode $fh;
print $fh $payload;
close $fh;

# One-shot reference digest via the READ phase.
my $expected;
file_slurp($path, plugin => 'hash', algo => 'sha256', into => \$expected);
ok(defined $expected && length($expected) == 64,
   'reference one-shot digest computed');

# Streaming digest via each_line. The hash plugin consumes chunks and
# computes the digest; it doesn't emit records, so the user callback
# is never invoked. That's by design - "use each_line to trigger the
# streaming path; the digest lands in 'into' at EOF".
my $stream_digest;
my $line_count = 0;
File::Raw::each_line($path, sub { $line_count++ },
    plugin => 'hash',
    algo   => 'sha256',
    into   => \$stream_digest,
);

is($line_count, 0,
   'hash plugin does not emit records (callback intentionally not called)');
is($stream_digest, $expected,
   'STREAM digest matches one-shot READ digest across chunks');

# Multi-algo streaming.
{
    my %digests;
    File::Raw::each_line($path, sub {},
        plugin => 'hash',
        algos  => [qw(sha256 md5 crc32)],
        into   => \%digests);

    is_deeply([sort keys %digests], [qw(crc32 md5 sha256)],
              'multi-algo STREAM populates all entries');
    is($digests{sha256}, $expected,
       'multi-algo STREAM sha256 matches one-shot');

    # Compare md5 + crc32 against their own one-shot runs.
    my ($exp_md5, $exp_crc);
    file_slurp($path, plugin => 'hash', algo => 'md5',   into => \$exp_md5);
    file_slurp($path, plugin => 'hash', algo => 'crc32', into => \$exp_crc);
    is($digests{md5},   $exp_md5, 'multi-algo STREAM md5 matches one-shot');
    is($digests{crc32}, $exp_crc, 'multi-algo STREAM crc32 matches one-shot');
}

done_testing;
