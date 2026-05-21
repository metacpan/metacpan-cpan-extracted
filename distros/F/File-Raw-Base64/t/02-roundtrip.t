use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# Random binary blobs round-trip cleanly through encode -> decode.
sub random_bytes {
    my $n = shift;
    my $s = '';
    $s .= chr(int rand 256) for 1 .. $n;
    return $s;
}

srand(42);  # deterministic across CPAN testers

for my $len (0, 1, 2, 3, 4, 7, 16, 64, 100, 1024, 65535) {
    my $bytes = random_bytes($len);

    # encode to file
    my ($efh, $epath) = tempfile(UNLINK => 1);
    close $efh;
    file_spew($epath, $bytes, plugin => 'base64');

    # read encoded form back as bytes (no plugin) just to make sure
    # it's pure ASCII
    my $enc = do { local (@ARGV, $/) = $epath; <> };
    $enc = '' unless defined $enc;
    like($enc, qr/^[A-Za-z0-9+\/=]*$/, "len=$len: encoded form is pure base64");

    # decode through the plugin, expect identical bytes
    my $got = file_slurp($epath, plugin => 'base64');
    is($got, $bytes, "len=$len: round-trip preserves bytes")
        or diag(sprintf("got %d bytes, want %d", length($got), length($bytes)));
}

done_testing;
