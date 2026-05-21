#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw qw(import);
use File::Raw::Hash;

# HMAC test vectors from RFC 4231 (SHA-2 family) and RFC 2202
# (SHA-1 / MD5). The plugin's HMAC support uses the same RFC 2104
# construction over our vendored hash codecs.

sub spew_bytes {
    my ($bytes) = @_;
    my ($fh, $path) = tempfile(UNLINK => 1);
    binmode $fh;
    print $fh $bytes;
    close $fh;
    return $path;
}

# RFC 4231 test case 1: key = 0x0b * 20, data = "Hi There"
{
    my $key  = "\x0b" x 20;
    my $path = spew_bytes("Hi There");
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               hmac_key => $key, into => \$d);
    is($d, 'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7',
       'HMAC-SHA-256 RFC 4231 test 1');
}

# RFC 4231 test case 2 (short key, ASCII): key = "Jefe"
{
    my $path = spew_bytes('what do ya want for nothing?');
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               hmac_key => 'Jefe', into => \$d);
    is($d, '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
       'HMAC-SHA-256 RFC 4231 test 2 (short key)');
}

# RFC 4231 test case 6: key = 0xaa * 131 (longer than B = 64 -> hash-down)
{
    my $key  = "\xaa" x 131;
    my $path = spew_bytes('Test Using Larger Than Block-Size Key - Hash Key First');
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               hmac_key => $key, into => \$d);
    is($d, '60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54',
       'HMAC-SHA-256 RFC 4231 test 6 (long key, hashed down)');
}

# RFC 2202 test case 1 for HMAC-SHA-1.
{
    my $key  = "\x0b" x 20;
    my $path = spew_bytes('Hi There');
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'sha1',
               hmac_key => $key, into => \$d);
    is($d, 'b617318655057264e28bc0b6fb378c8ef146be00',
       'HMAC-SHA-1 RFC 2202 test 1');
}

# RFC 2202 test case 1 for HMAC-MD5.
{
    my $key  = "\x0b" x 16;
    my $path = spew_bytes('Hi There');
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'md5',
               hmac_key => $key, into => \$d);
    is($d, '9294727a3638bb1c13f48ef8158bfc9d',
       'HMAC-MD5 RFC 2202 test 1');
}

# Multi-algo HMAC: same key, multiple HMACs in one pass.
{
    my $path = spew_bytes('what do ya want for nothing?');
    my %macs;
    file_slurp($path,
        plugin   => 'hash',
        algos    => [qw(sha256 sha1 md5)],
        hmac_key => 'Jefe',
        into     => \%macs,
    );
    is($macs{sha256},
       '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
       'multi-algo HMAC-SHA-256 matches');
    is($macs{md5},
       '750c783e6ab0b503eaa86e310a5db738',
       'multi-algo HMAC-MD5 RFC 2202 test 2');
    like($macs{sha1}, qr/^[0-9a-f]{40}$/,
       'multi-algo HMAC-SHA-1 right shape');
}

# HMAC of empty data with a non-empty key: well-defined result.
{
    my $path = spew_bytes('');
    my $d;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               hmac_key => 'k', into => \$d);
    like($d, qr/^[0-9a-f]{64}$/, 'HMAC of empty data is well-defined');
    isnt($d, 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
         'HMAC differs from plain hash of empty');
}

# HMAC streaming consistency.
{
    my $payload = ('xyzzy' x 20000) . "\n";
    my $path = spew_bytes($payload);
    my $oneshot;
    file_slurp($path, plugin => 'hash', algo => 'sha256',
               hmac_key => 'streamkey', into => \$oneshot);

    my $streamed;
    File::Raw::each_line($path, sub {},
        plugin => 'hash', algo => 'sha256',
        hmac_key => 'streamkey', into => \$streamed);

    is($streamed, $oneshot, 'HMAC STREAM digest matches one-shot');
}

# HMAC rejects non-HMAC-able algos with a clear error.
for my $bad (qw(crc32 xxh64 blake3)) {
    my $path = spew_bytes('payload');
    my $d;
    my $err = eval {
        file_slurp($path, plugin => 'hash', algo => $bad,
                   hmac_key => 'k', into => \$d);
        ''
    } || $@;
    like($err, qr/HMAC is not defined for algo '$bad'/,
         "hmac_key + $bad croaks");
}

# Mixed multi-algo with one non-HMAC-able algo also croaks (the
# pre-flight catches it before any work is done).
{
    my $path = spew_bytes('payload');
    my %h;
    my $err = eval {
        file_slurp($path,
            plugin => 'hash',
            algos  => [qw(sha256 crc32)],
            hmac_key => 'k',
            into   => \%h);
        ''
    } || $@;
    like($err, qr/HMAC is not defined for algo 'crc32'/,
         'mixed multi-algo with crc32 + hmac_key croaks');
}

done_testing;
