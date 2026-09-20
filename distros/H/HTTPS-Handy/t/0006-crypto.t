######################################################################
#
# t/0006-crypto.t - Known answer tests for the cryptographic packages.
#
#   Every value below comes from the document that defines the
#   algorithm: FIPS 180-4 for SHA-256, RFC 2104 and RFC 4231 for HMAC,
#   RFC 8439 for ChaCha20-Poly1305, FIPS 186-4 for the P-256 curve,
#   RFC 4648 for Base64. If one of these fails, the TLS layer above it
#   cannot be trusted either.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my ($c, $n) = @_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is { my ($g, $e, $n) = @_; $T++; defined($g) && ("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g ? $g : 'undef')}', exp='$e')\n") }

use HTTPS::Handy;

sub hex_of { return unpack('H*', $_[0]) }
sub bin_of { return pack('H*', $_[0]) }

######################################################################
# SHA-256 (FIPS 180-4)
######################################################################

is(hex_of(HTTPS::Handy::Crypt::sha256('abc')),
   'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
   'SHA-256 of "abc"');
is(hex_of(HTTPS::Handy::Crypt::sha256('')),
   'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
   'SHA-256 of the empty string');
is(hex_of(HTTPS::Handy::Crypt::sha256('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')),
   '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
   'SHA-256 of the 56 byte vector');

# A message longer than one block, to exercise the length encoding
is(hex_of(HTTPS::Handy::Crypt::sha256('a' x 1000)),
   '41edece42d63e8d9bf515a9ba6932e1c20cbc9f5a5d134645adb5db1b9737ea3',
   'SHA-256 of 1000 times "a"');

######################################################################
# HMAC (RFC 2104, RFC 4231)
######################################################################

is(hex_of(HTTPS::Handy::Crypt::hmac_sha256(bin_of('0b' x 20), 'Hi There')),
   'b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7',
   'HMAC-SHA-256 test case 1');
is(hex_of(HTTPS::Handy::Crypt::hmac_sha256('Jefe', 'what do ya want for nothing?')),
   '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843',
   'HMAC-SHA-256 test case 2');
# A key longer than the block size is hashed first
is(hex_of(HTTPS::Handy::Crypt::hmac_sha256(bin_of('aa' x 131),
        'Test Using Larger Than Block-Size Key - Hash Key First')),
   '60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54',
   'HMAC-SHA-256 with a long key');

######################################################################
# ChaCha20 and Poly1305 (RFC 8439)
######################################################################

# The keystream block of section 2.3.2
is(hex_of(substr(HTTPS::Handy::ChaCha::block(pack('C32', 0 .. 31), 1,
                     bin_of('000000090000004a00000000')), 0, 32)),
   '10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4e',
   'ChaCha20 keystream block');

# The AEAD example of section 2.8.2
my $aead_key   = pack('C32', map { 0x80 + $_ } 0 .. 31);
my $aead_nonce = bin_of('070000004041424344454647');
my $aead_aad   = bin_of('50515253c0c1c2c3c4c5c6c7');
my $aead_plain = "Ladies and Gentlemen of the class of '99: If I could offer you only "
               . "one tip for the future, sunscreen would be it.";
my $sealed = HTTPS::Handy::ChaCha::aead_encrypt($aead_key, $aead_nonce,
                                                $aead_aad, $aead_plain);
is(hex_of(substr($sealed, 0, 32)),
   'd31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6',
   'ChaCha20-Poly1305: ciphertext');
is(hex_of(substr($sealed, -16)), '1ae10b594f09e26a7e902ecbd0600691',
   'ChaCha20-Poly1305: authentication tag');
is(HTTPS::Handy::ChaCha::aead_decrypt($aead_key, $aead_nonce, $aead_aad, $sealed),
   $aead_plain, 'ChaCha20-Poly1305: decryption');

# A single altered byte must be refused, not decrypted
my $tampered = $sealed;
substr($tampered, 5, 1) = chr(ord(substr($tampered, 5, 1)) ^ 1);
ok(!defined HTTPS::Handy::ChaCha::aead_decrypt($aead_key, $aead_nonce,
                                               $aead_aad, $tampered),
   'ChaCha20-Poly1305: a tampered record is rejected');

# So must the right ciphertext under the wrong additional data
ok(!defined HTTPS::Handy::ChaCha::aead_decrypt($aead_key, $aead_nonce,
                                               'other', $sealed),
   'ChaCha20-Poly1305: wrong additional data is rejected');

######################################################################
# The P-256 curve (FIPS 186-4)
######################################################################

# Twice the generator, from the published table of small multiples
my ($x2, $y2) = HTTPS::Handy::EC::mul_generator(
                    HTTPS::Handy::BigInt::b_from_int(2));
is(HTTPS::Handy::BigInt::b_to_hex($x2),
   '7cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978',
   'P-256: x coordinate of 2G');
is(HTTPS::Handy::BigInt::b_to_hex($y2),
   '07775510db8ed040293d9ac69f7430dbba7dade63ce982299e04b79d227873d1',
   'P-256: y coordinate of 2G');
is(HTTPS::Handy::EC::is_on_curve($x2, $y2), 1, 'P-256: 2G lies on the curve');

# A point with one coordinate altered must be refused
my $off = HTTPS::Handy::BigInt::b_add($x2, [ 1 ]);
is(HTTPS::Handy::EC::is_on_curve($off, $y2), 0,
   'P-256: a point off the curve is rejected');

# Two parties reach the same shared secret, and neither sends it
my $key_a = HTTPS::Handy::EC::generate_key();
my $key_b = HTTPS::Handy::EC::generate_key();
is($key_a->{'type'}, 'ec', 'generate_key returns an elliptic curve key');
my $shared_a = HTTPS::Handy::EC::ecdh_shared($key_a->{'d'}, $key_b->{'x'}, $key_b->{'y'});
my $shared_b = HTTPS::Handy::EC::ecdh_shared($key_b->{'d'}, $key_a->{'x'}, $key_a->{'y'});
is(length($shared_a), 32, 'ECDH: the shared secret is 32 bytes');
is(hex_of($shared_a), hex_of($shared_b), 'ECDH: both sides agree');
ok(hex_of($shared_a) ne HTTPS::Handy::BigInt::b_to_hex($key_a->{'x'}),
   'ECDH: the shared secret is not simply a public value');

# A point in uncompressed form survives the round trip
my $wire = HTTPS::Handy::EC::point_to_bin($key_a->{'x'}, $key_a->{'y'});
is(length($wire), 65, 'a curve point on the wire is 65 bytes');
my ($rx, $ry) = HTTPS::Handy::EC::point_from_bin($wire);
is(HTTPS::Handy::BigInt::b_to_hex($rx),
   HTTPS::Handy::BigInt::b_to_hex($key_a->{'x'}), 'point round trip');

# Two signatures over the same message differ, because k is fresh
my $sig1 = HTTPS::Handy::EC::sign($key_a, 'message');
my $sig2 = HTTPS::Handy::EC::sign($key_a, 'message');
ok($sig1 ne $sig2, 'ECDSA: a fresh random k gives a different signature');
is(unpack('C', substr($sig1, 0, 1)), 0x30, 'ECDSA: the signature is a DER sequence');

######################################################################
# TLS 1.2 pseudo random function
######################################################################

# The published TLS 1.2 PRF-SHA256 test vector
is(hex_of(HTTPS::Handy::Crypt::prf(bin_of('9bbe436ba940f017b17652849a71db35'),
                                   'test label',
                                   bin_of('a0ba9f936cda311827a6f796ffd5198c'), 100)),
   'e3f229ba727be17b8d122620557cd453c2aab21d07c3d495329b52d4e61edb5a'
 . '6b301791e90d35c9c9a46b4e14baf9af0fa022f7077def17abfd3797c0564bab'
 . '4fbc91666e9def9b97fce34f796789baa48082d122ee42c5a72e5a5110fff701'
 . '87347b66',
   'TLS 1.2 PRF matches the published vector');

my $out = HTTPS::Handy::Crypt::prf('secret', 'label', 'seed', 100);
is(length($out), 100, 'PRF returns the requested number of bytes');
is(hex_of(substr($out, 0, 16)),
   hex_of(substr(HTTPS::Handy::Crypt::prf('secret', 'label', 'seed', 16), 0, 16)),
   'PRF output is a prefix of a longer run');
ok(HTTPS::Handy::Crypt::prf('secret', 'label', 'seed2', 16)
   ne HTTPS::Handy::Crypt::prf('secret', 'label', 'seed', 16),
   'PRF depends on the seed');

######################################################################
# Random bytes
######################################################################

my $r1 = HTTPS::Handy::Crypt::random_bytes(32);
my $r2 = HTTPS::Handy::Crypt::random_bytes(32);
is(length($r1), 32, 'random_bytes returns the requested length');
ok($r1 ne $r2, 'two calls to random_bytes differ');

######################################################################
# Big integers
######################################################################

my $a = HTTPS::Handy::BigInt::b_from_hex('123456789abcdef0112233445566778899');
my $b = HTTPS::Handy::BigInt::b_from_hex('fedcba98765432100fedcba987654321');
is(HTTPS::Handy::BigInt::b_to_hex(HTTPS::Handy::BigInt::b_add($a, $b)),
   '13333333333333222132210ffeeddccbba', 'big integer addition');
is(HTTPS::Handy::BigInt::b_to_hex(HTTPS::Handy::BigInt::b_mul($a, $b)),
   '121fa00ad77d7422359e37bdec7f31bd9e1945cc3508d01347ad181f061185a6b9',
   'big integer multiplication');
my ($q, $r) = HTTPS::Handy::BigInt::b_divmod($a, $b);
is(HTTPS::Handy::BigInt::b_to_hex($q), '12', 'big integer division');
is(HTTPS::Handy::BigInt::b_to_hex($r), '48d159e26af36af0037af269e158d047',
   'big integer remainder');

my $m = HTTPS::Handy::BigInt::b_from_hex('fedcba9876543211');
is(HTTPS::Handy::BigInt::b_to_hex(HTTPS::Handy::BigInt::b_modexp($a, $b, $m)),
   '17a28dac7cbde4e8', 'modular exponentiation');
is(HTTPS::Handy::BigInt::b_to_hex(HTTPS::Handy::BigInt::b_modinv($b, $m)),
   '6bc87c05d590ffc0', 'modular inverse');

is(HTTPS::Handy::BigInt::b_to_int(
       HTTPS::Handy::BigInt::b_from_bin(pack('H*', '010001'))), 65537,
   'byte string to big integer');
is(unpack('H*', HTTPS::Handy::BigInt::b_to_bin(
       HTTPS::Handy::BigInt::b_from_int(65537), 4)), '00010001',
   'big integer to padded byte string');

######################################################################
# Base64 and DER (RFC 4648, X.690)
######################################################################

my $b64 = HTTPS::Handy::X509::b64_encode('any carnal pleasure.');
$b64 =~ s/\s//g;
is($b64, 'YW55IGNhcm5hbCBwbGVhc3VyZS4=', 'Base64 encoding');
is(HTTPS::Handy::X509::b64_decode('YW55IGNhcm5hbCBwbGVhc3VyZS4='),
   'any carnal pleasure.', 'Base64 decoding');
is(HTTPS::Handy::X509::b64_decode(HTTPS::Handy::X509::b64_encode("\x00\xFF" x 100)),
   "\x00\xFF" x 100, 'Base64 round trip over binary data');

is(hex_of(HTTPS::Handy::X509::der_integer(pack('H*', '80'))), '02020080',
   'DER integer: a leading zero is added when the top bit is set');
is(hex_of(HTTPS::Handy::X509::der_oid('1.2.840.113549.1.1.11')),
   '06092a864886f70d01010b', 'DER object identifier');
is(hex_of(HTTPS::Handy::X509::der_sequence(HTTPS::Handy::X509::der_null())),
   '30020500', 'DER sequence');

# A long form length, which needs more than one byte
my $long = HTTPS::Handy::X509::der_sequence('x' x 300);
is(hex_of(substr($long, 0, 4)), '3082012c', 'DER long form length');
my ($tag, $body) = HTTPS::Handy::X509::der_next($long, 0);
is($tag, 0x30, 'DER reader: tag');
is(length($body), 300, 'DER reader: contents');

print "1..$T\n";
exit($FAIL ? 1 : 0);
