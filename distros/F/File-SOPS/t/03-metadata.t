#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::SOPS::Metadata;

# Test new
my $meta = File::SOPS::Metadata->new;
ok($meta, 'created metadata');
is($meta->version, '3.7.3', 'default version');
is($meta->unencrypted_suffix, '_unencrypted', 'default unencrypted_suffix');
is_deeply($meta->age, [], 'empty age keys');

# Test update_lastmodified
$meta->update_lastmodified;
ok($meta->lastmodified, 'lastmodified set');
like($meta->lastmodified, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'ISO format');

# Test add_age_recipient
$meta->add_age_recipient(
    recipient => 'age1test...',
    enc       => '-----BEGIN AGE ENCRYPTED FILE-----...',
);
is(scalar @{$meta->age}, 1, 'one age key');
is($meta->age->[0]{recipient}, 'age1test...', 'recipient stored');

# Test to_hash / from_hash roundtrip
my $hash = $meta->to_hash;
ok($hash->{age}, 'hash has age');
ok($hash->{version}, 'hash has version');

my $restored = File::SOPS::Metadata->from_hash($hash);
is($restored->version, $meta->version, 'version preserved');
is_deeply($restored->age, $meta->age, 'age keys preserved');

# Test should_encrypt_key with unencrypted_suffix
my $m = File::SOPS::Metadata->new(
    unencrypted_suffix => '_unencrypted',
);

ok($m->should_encrypt_key('password'), 'normal key encrypted');
ok($m->should_encrypt_key('secret'), 'secret encrypted');
ok(!$m->should_encrypt_key('config_unencrypted'), 'unencrypted suffix not encrypted');
ok(!$m->should_encrypt_key('debug_unencrypted'), 'another unencrypted suffix');

# Test with encrypted_suffix
my $m2 = File::SOPS::Metadata->new(
    encrypted_suffix => '_encrypted',
    unencrypted_suffix => undef,
);

ok(!$m2->should_encrypt_key('config'), 'without suffix not encrypted');
ok($m2->should_encrypt_key('password_encrypted'), 'with encrypted suffix is encrypted');

done_testing;
