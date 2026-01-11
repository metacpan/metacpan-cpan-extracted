#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::SOPS::Encrypted;

# Test is_encrypted
ok(!File::SOPS::Encrypted->is_encrypted('plain text'), 'plain text is not encrypted');
ok(!File::SOPS::Encrypted->is_encrypted(undef), 'undef is not encrypted');
ok(!File::SOPS::Encrypted->is_encrypted(''), 'empty string is not encrypted');

my $enc_str = 'ENC[AES256_GCM,data:dGVzdA==,iv:dGVzdGl2MTIzNDU2,tag:dGVzdHRhZzEyMzQ1Njc4,type:str]';
ok(File::SOPS::Encrypted->is_encrypted($enc_str), 'encrypted string detected');

# Test parse
my $enc = File::SOPS::Encrypted->parse($enc_str);
ok($enc, 'parsed encrypted string');
is($enc->algorithm, 'AES256_GCM', 'algorithm correct');
is($enc->type, 'str', 'type correct');

# Test to_string roundtrip
my $back = $enc->to_string;
ok($back =~ /^ENC\[AES256_GCM,/, 'to_string produces ENC format');

# Test encrypt/decrypt roundtrip
my $key = 'x' x 32;  # 256-bit key
my $original = 'secret value';

my $encrypted = File::SOPS::Encrypted->encrypt_value(
    value => $original,
    key   => $key,
    aad   => 'test:path',
);

ok($encrypted, 'encrypted value');
isa_ok($encrypted, 'File::SOPS::Encrypted');

my $enc_string = $encrypted->to_string;
ok($enc_string =~ /^ENC\[AES256_GCM,/, 'encrypted string format');

# Decrypt
my $decrypted = $encrypted->decrypt_value(key => $key, aad => 'test:path');
is($decrypted, $original, 'decrypt roundtrip successful');

# Test different types
for my $test (
    ['42', 'int', 42],
    ['3.14', 'float', 3.14],
    ['true', 'bool', 1],
    ['hello world', 'str', 'hello world'],
) {
    my ($value, $type, $expected) = @$test;
    my $enc = File::SOPS::Encrypted->encrypt_value(
        value => $value,
        key   => $key,
    );
    my $dec = $enc->decrypt_value(key => $key);
    is($dec, $expected, "roundtrip for $type");
}

# Test wrong AAD fails
my $enc_with_aad = File::SOPS::Encrypted->encrypt_value(
    value => 'test',
    key   => $key,
    aad   => 'correct:path',
);

eval {
    $enc_with_aad->decrypt_value(key => $key, aad => 'wrong:path');
};
ok($@, 'wrong AAD causes authentication failure');

done_testing;
