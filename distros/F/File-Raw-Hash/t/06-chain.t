#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Chains place the hash plugin somewhere in the stack and confirm the
# digest reflects the bytes flowing through *that point*. We chain
# hash with itself using two different sub-hashes... actually we can't
# (only one hash plugin, one set of options).
#
# Realistic chain partners (gzip, base64, json) are separate dists. To
# keep this test self-contained, we use File::Raw::Base64 if it's
# available - that's the simplest non-trivial chain.

eval {
    require File::Raw::Base64;
    File::Raw::Base64->import;
};
if ($@) {
    plan skip_all => 'File::Raw::Base64 not installed; chain test skipped';
}

my $raw_payload = "hello chain world\n" x 10;

# Base64-encode the payload and write that to disk. file_slurp through
# the chain ['hash','base64'] should:
#   1. read the base64 text from disk
#   2. hash the base64 text (passthrough)
#   3. base64-decode it
#   4. return the decoded bytes
# The digest should equal sha256 of the on-disk base64 text.
my $b64_text;
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    close $fh;
    file_spew($path, $raw_payload, plugin => 'base64');
    open my $rfh, '<:raw', $path or die $!;
    local $/;
    $b64_text = <$rfh>;
    close $rfh;
}

# Reference digest of the base64 text.
my $expected_text_digest;
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $b64_text;
    close $fh;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               into => \$expected_text_digest);
}

# Reference digest of the decoded bytes.
my $expected_bytes_digest;
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $raw_payload;
    close $fh;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               into => \$expected_bytes_digest);
}

# Chain ['hash', 'base64']: hash-then-base64-decode.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $b64_text;
    close $fh;

    my $d;
    my $bytes = file_slurp($path,
        plugin => ['hash', 'base64'],
        hash   => { algo => 'sha256', into => \$d },
    );

    is($bytes, $raw_payload, 'chain ["hash","base64"] decodes correctly');
    is($d, $expected_text_digest,
       'chain ["hash","base64"] digests the wire (encoded) bytes');
}

# Chain ['base64', 'hash']: base64-decode-then-hash. The digest
# reflects the decoded bytes.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $b64_text;
    close $fh;

    my $d;
    my $bytes = file_slurp($path,
        plugin => ['base64', 'hash'],
        hash   => { algo => 'sha256', into => \$d },
    );

    is($bytes, $raw_payload, 'chain ["base64","hash"] decodes correctly');
    is($d, $expected_bytes_digest,
       'chain ["base64","hash"] digests the decoded payload');
}

done_testing;
