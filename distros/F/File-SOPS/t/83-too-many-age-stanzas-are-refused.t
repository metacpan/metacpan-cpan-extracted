#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use File::SOPS::Backend::Age;
use Crypt::Age;

# ----------------------------------------------------------------------------
# k192 / CVE-2026-85783 -- the age backend bounds the number of age stanzas it
# will attempt on decrypt.
#
# decrypt_data_key loops over @$age_keys (the entries in a document's sops.age
# list) and hands each one to Crypt::Age->decrypt. Every attempt costs an
# X25519 scalar multiplication per stanza in the blob before anything is
# authenticated, so a document carrying many age entries multiplies the DoS by
# entries x stanzas x identities. The upstream cap (Crypt::Age 0.004) is
# per-blob; the outer loop here is bounded by max_stanzas, default 64.
#
# This test is fully offline. The refusal fires on the COUNT, ahead of the
# loop, so the over-limit cases never touch Crypt::Age at all -- proven below
# by a mock that dies if it is ever called. The at-limit cases mock
# Crypt::Age::decrypt so nothing real (and nothing networked) is attempted.
# ----------------------------------------------------------------------------

# N age stanzas. The enc blobs are dummy: an over-limit count is refused before
# any of them is looked at, and an at-limit count reaches a mocked decrypt.
sub stanzas {
    my ($n) = @_;
    return [ map { { recipient => "age1recipient$_", enc => "dummy-enc-$_" } } 1 .. $n ];
}

my $IDENTITIES = ['AGE-SECRET-KEY-1FAKEIDENTITYFORTESTSONLYNONETWORKHERE'];

subtest 'the default limit is 64: 65 stanzas are refused, 64 are not' => sub {
    my $over = eval {
        File::SOPS::Backend::Age->decrypt_data_key(
            age_keys   => stanzas(65),
            identities => $IDENTITIES,
        );
    };
    my $err = $@;
    is $over, undef, '65 age stanzas: decrypt_data_key does not return';
    like $err, qr/exceeding the max_stanzas limit of 64/,
        '  ... it names the default limit of 64';
    like $err, qr/\b65\b/, '  ... and the count it received (65)';
    unlike $err, qr/Could not decrypt/,
        '  ... the count guard fires before the decrypt loop is reached';

    # 64 is at the limit and must pass the guard. Mock decrypt so the first
    # stanza yields a valid 32-byte data key without any real age work.
    no warnings 'redefine';
    local *Crypt::Age::decrypt = sub { return 'K' x 32 };
    my $at = eval {
        File::SOPS::Backend::Age->decrypt_data_key(
            age_keys   => stanzas(64),
            identities => $IDENTITIES,
        );
    };
    is $@, '', '64 age stanzas: no croak';
    is $at, 'K' x 32, '  ... the guard lets exactly 64 through and it decrypts';
};

subtest 'the guard fires before any age decryption is attempted' => sub {
    my $calls = 0;
    no warnings 'redefine';
    local *Crypt::Age::decrypt = sub { $calls++; die "should never run when over the limit" };

    my $dk = eval {
        File::SOPS::Backend::Age->decrypt_data_key(
            age_keys   => stanzas(65),
            identities => $IDENTITIES,
        );
    };
    like $@, qr/max_stanzas/, 'over-limit document is refused';
    is $calls, 0,
        '  ... and Crypt::Age->decrypt was never called (no scalar multiplications spent)';
    is $dk, undef, '  ... nothing is returned';
};

subtest 'max_stanzas is honoured when set explicitly' => sub {
    my $over = eval {
        File::SOPS::Backend::Age->decrypt_data_key(
            age_keys    => stanzas(3),
            identities  => $IDENTITIES,
            max_stanzas => 2,
        );
    };
    like $@, qr/exceeding the max_stanzas limit of 2/,
        '3 stanzas under max_stanzas => 2 is refused, naming the caller limit';
    is $over, undef, '  ... nothing returned';

    no warnings 'redefine';
    local *Crypt::Age::decrypt = sub { return 'K' x 32 };
    my $at = eval {
        File::SOPS::Backend::Age->decrypt_data_key(
            age_keys    => stanzas(2),
            identities  => $IDENTITIES,
            max_stanzas => 2,
        );
    };
    is $@, '', '2 stanzas under max_stanzas => 2: no croak';
    is $at, 'K' x 32, '  ... exactly at the caller limit still decrypts';
};

subtest 'the refusal carries counts, not recipient or blob material' => sub {
    my $err = eval {
        File::SOPS::Backend::Age->decrypt_data_key(
            age_keys   => stanzas(65),
            identities => $IDENTITIES,
        );
        1;
    } ? '' : $@;
    like $err, qr/max_stanzas/, 'refused';
    unlike $err, qr/age1recipient/, '  ... the message does not leak recipients';
    unlike $err, qr/dummy-enc/,     '  ... nor the encrypted blobs';
};

subtest 'can_decrypt inherits the bound and its non-throwing contract' => sub {
    # Over the default limit: the wrapped croak turns into a false answer.
    is +File::SOPS::Backend::Age->can_decrypt(
        age_keys   => stanzas(65),
        identities => $IDENTITIES,
    ), 0, 'can_decrypt returns false for an over-limit document (does not throw)';

    # At the limit, with a mocked decrypt, it reports true.
    no warnings 'redefine';
    local *Crypt::Age::decrypt = sub { return 'K' x 32 };
    is +File::SOPS::Backend::Age->can_decrypt(
        age_keys   => stanzas(64),
        identities => $IDENTITIES,
    ), 1, 'can_decrypt returns true at the limit';

    # And max_stanzas passes through can_decrypt too.
    is +File::SOPS::Backend::Age->can_decrypt(
        age_keys    => stanzas(3),
        identities  => $IDENTITIES,
        max_stanzas => 2,
    ), 0, 'can_decrypt honours an explicit max_stanzas';
};

done_testing;
