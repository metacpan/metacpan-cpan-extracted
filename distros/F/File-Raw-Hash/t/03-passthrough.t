#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# The plugin must hand the bytes through unchanged on read AND on write.

my @inputs = (
    '',
    'hello',
    "x" x 4096,
    join('', map { chr(int(rand(256))) } 1 .. 8192),
    "\x00\x01\x02 mixed binary \xff\xfe \nnewlines\n",
);

for my $i (0 .. $#inputs) {
    my $payload = $inputs[$i];

    # READ: slurp through the plugin returns identical bytes.
    {
        my ($fh, $path) = tempfile(UNLINK => 1);
        binmode $fh;
        print $fh $payload;
        close $fh;

        my $d;
        my $back = file_slurp($path,
            plugin => 'hash', algo => 'sha256', into => \$d);
        is($back, $payload, "READ: passthrough on input #$i (" . length($payload) . "B)");

        # And the plugin output must equal a plain slurp.
        my $plain = file_slurp($path);
        is($back, $plain, "READ: matches plain file_slurp on input #$i");
    }

    # WRITE: the file on disk must match the original payload.
    {
        my ($fh, $path) = tempfile(UNLINK => 1);
        close $fh;

        my $d;
        file_spew($path, $payload,
            plugin => 'hash', algo => 'sha256', into => \$d);

        open my $rfh, '<:raw', $path or die "open: $!";
        local $/;
        my $on_disk = <$rfh>;
        close $rfh;
        is($on_disk, $payload, "WRITE: bytes on disk match input #$i");
    }
}

done_testing;
