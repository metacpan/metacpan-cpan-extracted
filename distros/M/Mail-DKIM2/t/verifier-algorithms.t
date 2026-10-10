use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use Time::HiRes qw(time);
use MIME::Base64 qw(encode_base64);
use DKIM2SignedFixture;
use DKIM2TestKeys;
use Mail::DKIM2::Verifier;

# spec-06 §3.4: Verifiers MUST ignore signatures using algorithms they do
# not implement. Only the exact names rsa-sha256 and ed25519-sha256 are
# implemented (tag values are case significant, §8); anything else is
# skipped before any key lookup, and is never verified as RSA.

my $calls;
my $cb = DKIM2TestKeys::pubkey_callback();
my $counting = sub { $calls++; goto &$cb };

sub run {
    my ($name, $items, $want, $want_calls) = @_;
    $calls = 0;
    my $v = DKIM2SignedFixture::verify(
        DKIM2SignedFixture::signed(items => $items), PubkeyCallback => $counting);
    like($v->result_detail, $want, "$name: " . $v->result_detail);
    is($calls, $want_calls, "$name: $want_calls key lookup(s)");
}

run('rsa-sha256', [['sel1', 'rsa-sha256']], qr/^pass/, 1);
run('unknown algorithm, correctly signed with RSA',
    [['sel1', 'future-alg']], qr/^fail .*DKIM2-Signature i=1 has no signature with a supported algorithm/, 0);
run('RSA-SHA256 is not rsa-sha256',
    [['sel1', 'RSA-SHA256']], qr/^fail .*DKIM2-Signature i=1 has no signature with a supported algorithm/, 0);
run('ed25519-sha256x is not ed25519-sha256',
    [['sel1', 'ed25519-sha256x']], qr/^fail .*DKIM2-Signature i=1 has no signature with a supported algorithm/, 0);
run('unknown item beside a good one',
    [['sel2', 'future-alg', 'AAAA'], ['sel1', 'rsa-sha256']], qr/^pass/, 1);
run('known algorithm, value not base64',
    [['sel1', 'rsa-sha256', '!!notbase64!!']],
    qr/^permerror .*DKIM2-Signature i=1 syntax error/, 0);
run('known algorithm, base64 missing its padding',
    [['sel1', 'rsa-sha256', 'AAA']],
    qr/^permerror .*DKIM2-Signature i=1 syntax error/, 0);
run('unknown algorithm, value not base64: still ignored',
    [['sel2', 'future-alg', '!!x!!'], ['sel1', 'rsa-sha256']], qr/^pass/, 1);

# spec-06 §11.5: an absent key is a PERMERROR when nothing else can be
# checked; an item with no key beside one that verifies is skipped.
{
    my $absent = sub { $calls++; return undef };
    $calls = 0;
    my $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(),
        PubkeyCallback => $absent);
    like($v->result_detail,
        qr/^permerror .*DKIM2-Signature i=1 public key sel1 does not exist/,
        'only key absent: does not exist');
    my $some = sub { my ($sig, $idx) = @_;
        return $sig->selector($idx) eq 'sel1' ? $cb->(@_) : undef };
    $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(
            items => [['gone', 'rsa-sha256', 'AAAA'], ['sel1', 'rsa-sha256']]),
        PubkeyCallback => $some);
    like($v->result_detail, qr/^pass/, 'one key absent, one verifies: pass');
}

# A key of the wrong type for the algorithm, from a callback.
{
    my $ed = DKIM2TestKeys::pubkey_callback();
    my $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(),
        PubkeyCallback => sub {
            my ($sig, $idx) = @_;
            # test1.dkim2.com's Ed25519 key, offered for an rsa-sha256 item
            return Mail::DKIM2::Common::parse_dkim_pubkey(
                DKIM2TestKeys::dns_txt('test1.dkim2.com', 'ed25519'));
        });
    like($v->result_detail,
        qr/^permerror .*DKIM2-Signature i=1 public key sel1 algorithm mismatch/,
        'Ed25519 key for rsa-sha256: algorithm mismatch');
}

# Review R1: thousands of distinct unknown algorithms cost no key lookups
# and no quadratic reparsing of s=.
{
    my @items = map { ["x$_", "unknown$_", q(AAAA)] } 1 .. 4000;
    push @items, ['sel1', 'rsa-sha256'];
    my $raw = DKIM2SignedFixture::signed(items => \@items);
    $calls = 0;
    my $t = time;
    my $v = DKIM2SignedFixture::verify($raw, PubkeyCallback => $counting);
    my $took = time - $t;
    like($v->result_detail, qr/^pass/, '4000 unknown items + one good: pass');
    is($calls, 1, '4000 unknown items: one key lookup');
    # A quadratic reparse took ~4.7s here on a laptop; the bound allows for
    # a small VPS.
    cmp_ok($took, '<', 3, sprintf '4000 unknown items took %.3fs', $took);
}

done_testing;
