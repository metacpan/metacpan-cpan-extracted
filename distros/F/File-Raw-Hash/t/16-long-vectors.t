#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# The longer published vectors: FIPS 180-4's multi-block messages and the
# million-'a' case for SHA-1, SHA-256 and SHA-512, and RFC 1321's suite for
# MD5. Each through the plugin, and through the C ABI's runner fed in uneven
# pieces from an unaligned buffer, so a block-boundary or alignment fault in
# the compress functions cannot hide behind one well-aligned call.

my $million = 'a' x 1_000_000;
my @CASES = (
    [ sha1   => 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
      '84983e441c3bd26ebaae4aa1f95129e5e54670f1' ],
    [ sha1   => $million, '34aa973cd4c4daa4f61eeb2bdbad27316534016f' ],
    [ sha256 => $million, 'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0' ],
    [ sha512 => 'abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu',
      '8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909' ],
    [ sha512 => $million,
      'e718483d0ce769644e2e42c7bc15b4638e1f98b13b2044285632a803afa973ebde0ff244877ea60a4cb0432ce577c31beb009c5c2c49aa2e4eadb217ad8cc09b' ],
    [ md5 => 'a',              '0cc175b9c0f1b6a831c399e269772661' ],
    [ md5 => 'message digest', 'f96b697d7cb7938d525a2f31aaf161d0' ],
    [ md5 => 'abcdefghijklmnopqrstuvwxyz', 'c3fcd3d76192e4007dfb496cca67e13b' ],
    [ md5 => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
      'd174ab98d277d9f5a5611c2c9f419d9f' ],
    [ md5 => '1234567890' x 8, '57edf4a22be3c955ac49da2e2107b67a' ],
    [ md5 => $million, '7707d6ae4e027c70eea2a935c2296f21' ],
);

for my $c (@CASES) {
    my ($algo, $input, $expected) = @$c;
    my $name = length($input) > 40 ? length($input) . ' bytes' : "'$input'";
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $input;
    close $fh;

    my $digest;
    file_slurp($path, plugin => 'hash', algo => $algo, into => \$digest);
    is($digest, $expected, "$algo($name) through the plugin");

    for my $offset (0, 1, 3, 7) {
        is(File::Raw::Hash::_test_feed($algo, $input, $offset, 1, 63, 64, 65, 127, 1000),
           $expected, "$algo($name) through the runner, offset $offset, uneven pieces");
    }
}

done_testing;
