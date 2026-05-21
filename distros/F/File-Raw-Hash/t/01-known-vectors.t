#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# Published test vectors per FIPS 180-4 / RFC 1321. The algorithms in
# this dist are vendored re-implementations; the same vectors are
# checked at the C level by xt/c-codec.t too. This test confirms the
# Perl-side path delivers them through the plugin.

my @CASES = (
    # algo, input, expected (lowercase hex)
    [ sha256 => '',        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' ],
    [ sha256 => 'abc',     'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' ],
    [ sha256 =>
        'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1' ],

    [ sha512 => '',
        'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce'
      . '47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e' ],
    [ sha512 => 'abc',
        'ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a'
      . '2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f' ],

    [ sha1   => '',        'da39a3ee5e6b4b0d3255bfef95601890afd80709' ],
    [ sha1   => 'abc',     'a9993e364706816aba3e25717850c26c9cd0d89d' ],

    [ md5    => '',        'd41d8cd98f00b204e9800998ecf8427e' ],
    [ md5    => 'abc',     '900150983cd24fb0d6963f7d28e17f72' ],
    [ md5    => 'The quick brown fox jumps over the lazy dog',
                           '9e107d9d372bb6826bd81d3542a419d6' ],

    [ crc32  => '',          '00000000' ],
    [ crc32  => '123456789', 'cbf43926' ],
);

for my $c (@CASES) {
    my ($algo, $input, $expected) = @$c;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $input;
    close $fh;

    my $digest;
    my $bytes = file_slurp($path,
        plugin => 'hash',
        algo   => $algo,
        into   => \$digest,
    );

    is($bytes, $input, "$algo: passthrough preserves bytes (" . length($input) . "B)");
    is($digest, $expected, "$algo('$input') = $expected");
}

# Name normalisation: SHA-256, sha_256, SHA256 all map to sha256.
{
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh 'abc';
    close $fh;

    for my $name (qw(sha256 SHA256 SHA-256 sha_256 Sha-256)) {
        my $d;
        file_slurp($path, plugin => 'hash', algo => $name, into => \$d);
        is($d, 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
            "algo name '$name' resolves to sha256");
    }
}

done_testing;
