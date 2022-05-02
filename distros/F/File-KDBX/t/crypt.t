#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use Crypt::Misc 0.029 qw(decode_b64 encode_b64);
use File::KDBX::Cipher;
use File::KDBX::Constants qw(CIPHER_UUID_AES256);
use File::KDBX::IO::Crypt;
use IO::Handle;
use Test::More;

subtest 'Round-trip block stream' => sub {
    plan tests => 3;
    my $block_cipher = File::KDBX::Cipher->new(uuid => CIPHER_UUID_AES256, key => 0x01 x 32, iv => 0x01 x 16);
    test_roundtrip($block_cipher,
        'Smell the pretty flowers.',
        decode_b64('pB10mV+mhTuh7bKg0KEUl5H1ajFMaP4uPnTZNcDgq6s='),
    );
};

subtest 'Round-trip cipher stream' => sub {
    plan tests => 3;
    my $cipher_stream = File::KDBX::Cipher->new(stream_id => 2, key => 0x01 x 16);
    test_roundtrip($cipher_stream,
        'Smell the pretty flowers.',
        decode_b64('gNj2Ud9tWtFDy+xDN/U01RxmCoI6MAlTKQ=='),
    );
};

subtest 'Error handling' => sub {
    plan tests => 4;

    my $block_cipher = File::KDBX::Cipher->new(uuid => CIPHER_UUID_AES256, key => 0x01 x 32, iv => 0x01 x 16);
    pipe(my $read, my $write) or die "pipe failed: $!";
    $read = File::KDBX::IO::Crypt->new($read, cipher => $block_cipher);

    print $write "blah blah blah!\1";
    close($write) or die "close failed: $!";

    is $read->error, '', 'Read handle starts out fine';
    my $plaintext = do { local $/; <$read> };
    is $plaintext, '', 'Read can fail';
    is $read->error, 1, 'Read handle can enter an error state';

    like $File::KDBX::IO::Crypt::ERROR, qr/fatal/i,
        'Error object is available';
};

done_testing;
exit;

sub test_roundtrip {
    my $cipher = shift;
    my $expected_plaintext = shift;
    my $expected_ciphertext = shift;

    pipe(my $read, my $write) or die "pipe failed: $!";
    $write = File::KDBX::IO::Crypt->new($write, cipher => $cipher);

    print $write $expected_plaintext;
    close($write) or die "close failed: $!";

    my $ciphertext = do { local $/; <$read> };
    close($read);
    is $ciphertext, $expected_ciphertext, 'Encrypted a string'
        or diag encode_b64($ciphertext);

    my $ciphertext2 = $cipher->encrypt_finish($expected_plaintext);
    is $ciphertext, $ciphertext2, 'Same result';

    open(my $fh, '<', \$ciphertext) or die "open failed: $!\n";
    $fh = File::KDBX::IO::Crypt->new($fh, cipher => $cipher);

    my $plaintext = do { local $/; <$fh> };
    close($fh);
    is $plaintext, $expected_plaintext, 'Decrypted a string'
        or diag encode_b64($plaintext);
}
