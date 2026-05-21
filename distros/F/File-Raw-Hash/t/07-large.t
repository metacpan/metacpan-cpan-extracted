#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# 5 MB blob round-trip - confirms the streaming code path doesn't trip
# on multi-chunk inputs and that the digest matches the one-shot
# computation byte-for-byte. We deliberately stay below the plan's 50
# MB target so this passes on small CPAN-tester boxes; the 50 MB
# stress lives in xt/ for author-only runs.

my $size = 5 * 1024 * 1024;     # 5 MiB
my $blob = '';
{
    # Deterministic pseudorandom-ish content via a tiny LCG so the test
    # doesn't depend on the system PRNG. Same byte sequence every run.
    my $s = 1;
    while (length($blob) < $size) {
        $s = ($s * 1103515245 + 12345) & 0x7fffffff;
        $blob .= chr($s & 0xff);
    }
}
ok(length($blob) == $size, "blob is $size bytes");

my ($fh, $path) = tempfile(UNLINK => 1);
binmode $fh;
print $fh $blob;
close $fh;

# One-shot READ digest.
my $oneshot;
my $bytes = file_slurp($path,
    plugin => 'hash', algo => 'sha256', into => \$oneshot);
is(length($bytes), $size, 'one-shot READ returns full blob');
ok(defined $oneshot && length($oneshot) == 64,
   'one-shot READ produced a sha256 hex digest');

# STREAM digest - same content, chunked under the hood.
my $streamed;
File::Raw::each_line($path, sub {},
    plugin => 'hash', algo => 'sha256', into => \$streamed);
is($streamed, $oneshot, 'STREAM digest matches one-shot digest on 5 MB blob');

# WRITE round-trip: spew through the plugin, slurp it back, digests
# match.
{
    my ($wfh, $wpath) = tempfile(UNLINK => 1);
    close $wfh;
    my $write_d;
    file_spew($wpath, $blob,
        plugin => 'hash', algo => 'sha256', into => \$write_d);
    is($write_d, $oneshot,
       'WRITE digest of 5 MB blob equals READ digest of original');

    # And the bytes on disk must match.
    open my $rfh, '<:raw', $wpath or die $!;
    binmode $rfh;
    local $/;
    my $back = <$rfh>;
    close $rfh;
    is($back, $blob, 'WRITE: bytes on disk identical to source blob');
}

done_testing;
