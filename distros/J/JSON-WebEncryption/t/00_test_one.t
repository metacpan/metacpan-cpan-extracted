use strict;
use warnings;
use t::Util;

use Crypt::Rijndael;

use Test::More tests => 4;
use Test::Requires 'Crypt::OpenSSL::RSA';

my $secret      = Crypt::CBC->random_bytes( 16 );
my $rsa         = Crypt::OpenSSL::RSA->generate_key(1024);
my $private_key = $rsa->get_private_key_string;
my $public_key  = $rsa->get_public_key_string;

my $rsa2         = Crypt::OpenSSL::RSA->generate_key(1024);
my $private_key2 = $rsa2->get_private_key_string;
my $public_key2  = $rsa2->get_public_key_string;

# plaintext encoding public_key private_key secret algorithm extra_headers
test_encode_decode(
    desc  => 'RSA1_5 / A128CBC-HS256',
    input => {
        plaintext   => 'Hello World',
        private_key => $private_key,
        public_key  => $public_key,
        algorithm   => 'RSA1_5',
        encoding    => 'A128CBC-HS256'
    },
);

test_encode_decode(
    desc  => 'dir / A128CBC-HS256',
    input => {
        plaintext   => 'Hello World',
        secret      => $secret,
        algorithm   => 'dir',
        encoding    => 'A128CBC-HS256'
    },
);

test_encode_decode_object(
    desc  => 'RSA1_5 / A128CBC-HS256 => Object',
    input => {
        plaintext   => 'Hello World',
        private_key => $private_key,
        public_key  => $public_key,
        algorithm   => 'RSA1_5',
        encoding    => 'A128CBC-HS256'
    },
);

test_encode_decode_object(
    desc  => 'dir / A128CBC-HS256 => Object',
    input => {
        plaintext   => 'Hello World',
        secret      => $secret,
        algorithm   => 'dir',
        encoding    => 'A128CBC-HS256'
    },
);

done_testing;
