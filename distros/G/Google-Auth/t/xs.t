#!perl
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
use 5.006;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use MIME::Base64 qw(decode_base64);

use Google::Auth;

sub decode_base64url {
    my ($s) = @_;
    $s =~ tr{-_}{+/};
    my $padding = length($s) % 4;
    if ($padding) {
        $s .= '=' x ( 4 - $padding );
    }
    return decode_base64($s);
}

subtest 'generating cert and signing/verifying RSA signatures in-process' => sub {
    my $keypair = eval { Google::Auth::generate_self_signed_cert() };
    is( $@, '', 'generate_self_signed_cert succeeded' );
    ok( defined $keypair, 'keypair is defined' );

    my $cert_pem = $keypair->{cert};
    my $pkey_pem = $keypair->{key};

    # Extract public key from certificate
    my $pubkey = eval { Google::Auth::load_pubkey_from_x509_cert($cert_pem) };
    is( $@, '', 'load_pubkey_from_x509_cert succeeded' );
    ok( defined $pubkey, 'pubkey is defined' );
    isa_ok( $pubkey, 'Google::Auth::PublicKey' );

    # Sign a mock message
    my $message   = 'Hello, this is a signed message assertion!';
    my $signature = eval { Google::Auth::rsa_sign_sha256( $pkey_pem, $message ) };
    is( $@, '', 'rsa_sign_sha256 succeeded' );
    ok( defined $signature, 'signature is defined' );
    ok( length($signature) > 0, 'signature is not empty' );

    # Verify signature using public key
    my $verify_ok = eval { Google::Auth::verify_signature( $pubkey, $message, $signature ) };
    is( $@, '', 'verify_signature succeeded' );
    ok( $verify_ok, 'signature successfully verified' );

    # Verify signature fails with wrong message
    my $verify_wrong_msg = eval { Google::Auth::verify_signature( $pubkey, 'Wrong message contents', $signature ) };
    is( $@, '', 'verify_signature succeeded on mismatch test' );
    ok( !$verify_wrong_msg, 'signature verification failed for wrong message' );

    # Verify signature fails with wrong signature
    my $wrong_sig = $signature;
    substr($wrong_sig, 10, 1, chr(ord(substr($wrong_sig, 10, 1)) ^ 0xFF)); # Corrupt 1 byte
    my $verify_wrong_sig = eval { Google::Auth::verify_signature( $pubkey, $message, $wrong_sig ) };
    is( $@, '', 'verify_signature succeeded on corrupt signature test' );
    ok( !$verify_wrong_sig, 'signature verification failed for corrupt signature' );
};

subtest 'loading RSA JWK components' => sub {
    # Decoded binary values for modulus (n) and public exponent (e) from standard JWK
    my $n_bin = pack('H*', 'c0af0f1dffd3675b9d1639d37ce4be79e38bb5ba3506'); # dummy binary modulus
    my $e_bin = pack('H*', '010001'); # 65537

    my $pubkey = eval { Google::Auth::load_rsa_pubkey($n_bin, $e_bin) };
    is( $@, '', 'load_rsa_pubkey succeeded' );
    ok( defined $pubkey, 'loaded pubkey is defined' );
    isa_ok( $pubkey, 'Google::Auth::PublicKey' );
};

subtest 'loading EC JWK components' => sub {
    # Real, valid P-256 / prime256v1 public key point coordinates decoded from standard JWK
    my $x_bin = decode_base64url('SlXFFkJ3JxMsXyXNrqzE3ozl_0913PmNbccLLWfeQFU');
    my $y_bin = decode_base64url('GLSahrZfBErmMUcHP0MGaeVnJdBwquhrhQ8eP05NfCI');

    # Test loading using NIST curve name 'P-256'
    my $pubkey1 = eval { Google::Auth::load_ec_pubkey('P-256', $x_bin, $y_bin) };
    is( $@, '', 'load_ec_pubkey with P-256 succeeded' );
    ok( defined $pubkey1, 'loaded NIST EC pubkey is defined' );
    isa_ok( $pubkey1, 'Google::Auth::PublicKey' );

    # Test loading using standard curve name 'prime256v1'
    my $pubkey2 = eval { Google::Auth::load_ec_pubkey('prime256v1', $x_bin, $y_bin) };
    is( $@, '', 'load_ec_pubkey with prime256v1 succeeded' );
    ok( defined $pubkey2, 'loaded standard EC pubkey is defined' );
    isa_ok( $pubkey2, 'Google::Auth::PublicKey' );
};

done_testing();
