#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Crypt::PK::RSA;
use Crypt::PK::Ed25519;
use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Common qw(load_private_key_data load_private_key);

# load_private_key_data exists for callers whose keys live in a database rather
# than on disk -- Fastmail's outbound signer pulls its key from a row, not a
# file. Key stores differ on whether they keep the PEM armor, so both forms have
# to work, and a bad value must return undef rather than dying: the caller is
# signing live mail and losing the message would be worse than not signing it.

my $rsa = Crypt::PK::RSA->new;
$rsa->generate_key(128, 65537);

subtest 'RSA, PEM as stored' => sub {
    my $key = load_private_key_data($rsa->export_key_pem('private'));
    ok($key, 'loaded');
    isa_ok($key, 'Crypt::PK::RSA');
    ok($key->is_private, 'and it is the private key');
};

subtest 'RSA, armor stripped to bare base64' => sub {
    my $bare = encode_base64($rsa->export_key_der('private'), '');
    my $key = load_private_key_data($bare);
    ok($key, 'loaded');
    isa_ok($key, 'Crypt::PK::RSA');
};

subtest 'RSA, bare base64 with the whitespace key stores tend to add' => sub {
    my $bare = encode_base64($rsa->export_key_der('private'));   # wrapped lines
    my $key = load_private_key_data($bare);
    ok($key, 'newlines inside the base64 are tolerated');
};

subtest 'Ed25519' => sub {
    my $ed = Crypt::PK::Ed25519->new;
    $ed->generate_key();
    my $key = load_private_key_data($ed->export_key_pem('private'));
    ok($key, 'loaded');
    isa_ok($key, 'Crypt::PK::Ed25519');
};

subtest 'bad input returns undef and never dies' => sub {
    for my $case (
        ['undef',            undef],
        ['empty string',     ''],
        ['whitespace only',  "  \n\t "],
        ['not a key',        'this is not a key at all'],
        ['truncated PEM',    "-----BEGIN PRIVATE KEY-----\nAAAA\n-----END PRIVATE KEY-----\n"],
        ['valid b64, junk',  encode_base64('absolutely not a key', '')],
    ) {
        my ($label, $value) = @$case;
        my $key;
        my $lived = eval { $key = load_private_key_data($value); 1 };
        ok($lived, "$label: did not die");
        ok(!$key, "$label: returned undef");
    }
};

subtest 'a public key is not accepted as a private one' => sub {
    # Signing with this would fail later and more confusingly.
    my $key = load_private_key_data($rsa->export_key_pem('public'));
    ok(!$key || !$key->is_private, 'public key material does not yield a private key');
};

done_testing;
