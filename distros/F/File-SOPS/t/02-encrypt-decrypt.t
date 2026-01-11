#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::SOPS;
use Crypt::Age;

# Generate test keypair
my ($public, $secret) = Crypt::Age->generate_keypair();
ok($public =~ /^age1/, 'generated public key');
ok($secret =~ /^AGE-SECRET-KEY-1/, 'generated secret key');

# Test data
my $data = {
    database => {
        host     => 'localhost',
        port     => 5432,
        password => 'supersecret',
    },
    api => {
        key => 'abc123',
    },
};

# Encrypt
my $encrypted = File::SOPS->encrypt(
    data       => $data,
    recipients => [$public],
    format     => 'yaml',
);

ok($encrypted, 'encryption produced output');
like($encrypted, qr/ENC\[AES256_GCM,/, 'contains encrypted values');
like($encrypted, qr/sops:/, 'contains sops metadata');
like($encrypted, qr/age:/, 'contains age keys');
like($encrypted, qr/database:/, 'keys are visible');
like($encrypted, qr/password:/, 'nested keys visible');

# Decrypt
my $decrypted = File::SOPS->decrypt(
    encrypted  => $encrypted,
    identities => [$secret],
);

ok($decrypted, 'decryption produced output');
is_deeply($decrypted, $data, 'decrypted data matches original');

# Test JSON format
my $json_encrypted = File::SOPS->encrypt(
    data       => $data,
    recipients => [$public],
    format     => 'json',
);

like($json_encrypted, qr/^\{/, 'JSON format starts with {');
like($json_encrypted, qr/"sops"/, 'contains sops key');

my $json_decrypted = File::SOPS->decrypt(
    encrypted  => $json_encrypted,
    identities => [$secret],
    format     => 'json',
);

is_deeply($json_decrypted, $data, 'JSON roundtrip successful');

# Test with arrays
my $data_with_array = {
    users => ['alice', 'bob', 'charlie'],
    config => {
        enabled => 1,
        values  => [1, 2, 3],
    },
};

my $enc_array = File::SOPS->encrypt(
    data       => $data_with_array,
    recipients => [$public],
);

my $dec_array = File::SOPS->decrypt(
    encrypted  => $enc_array,
    identities => [$secret],
);

is_deeply($dec_array, $data_with_array, 'arrays handled correctly');

# Test multiple recipients
my ($public2, $secret2) = Crypt::Age->generate_keypair();

my $multi = File::SOPS->encrypt(
    data       => $data,
    recipients => [$public, $public2],
);

# Both keys should be able to decrypt
my $dec1 = File::SOPS->decrypt(
    encrypted  => $multi,
    identities => [$secret],
);
is_deeply($dec1, $data, 'first recipient can decrypt');

my $dec2 = File::SOPS->decrypt(
    encrypted  => $multi,
    identities => [$secret2],
);
is_deeply($dec2, $data, 'second recipient can decrypt');

done_testing;
