use strict;
use warnings;
use Test::More;
use File::Raw::Base64;
use File::Raw qw(import);
use File::Temp qw(tempfile);

# RFC 4648 §10 test vectors. The spec requires every conforming
# implementation to produce these exact strings.
my @VECTORS = (
    [ '',       ''         ],
    [ 'f',      'Zg=='     ],
    [ 'fo',     'Zm8='     ],
    [ 'foo',    'Zm9v'     ],
    [ 'foob',   'Zm9vYg==' ],
    [ 'fooba',  'Zm9vYmE=' ],
    [ 'foobar', 'Zm9vYmFy' ],
);

for my $v (@VECTORS) {
    my ($plain, $encoded) = @$v;

    # Encode: file_spew the plaintext through the base64 plugin and
    # verify we get the canonical encoding on disk.
    my ($wfh, $wpath) = tempfile(UNLINK => 1);
    close $wfh;
    file_spew($wpath, $plain, plugin => 'base64');
    open my $rfh, '<', $wpath or die "open: $!";
    local $/;
    my $got_enc = <$rfh>;
    close $rfh;
    is($got_enc, $encoded, "encode '$plain' -> '$encoded'");

    # Decode: file_slurp the canonical encoding through the plugin and
    # verify we get the plaintext back.
    my ($efh, $epath) = tempfile(UNLINK => 1);
    print $efh $encoded;
    close $efh;
    my $got_plain = file_slurp($epath, plugin => 'base64');
    is($got_plain, $plain, "decode '$encoded' -> '$plain'");
}

done_testing;
