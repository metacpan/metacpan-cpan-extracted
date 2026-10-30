use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use MIME::Base64 qw(encode_base64);
use DKIM2SignedFixture;
use DKIM2TestKeys;
use Mail::DKIM2::Verifier;

# -08 §14.6: an algorithm a Verifier does not implement is a PERMERROR item,
# so it passes only beside a "|" alternative that does. Only the exact names
# rsa-sha256 and ed25519-sha256 are implemented (names are case-sensitive,
# §2.14); anything else gets no key lookup, and is never verified as RSA.

my $calls;
my $cb = DKIM2TestKeys::pubkey_callback();
my $counting = sub { $calls++; goto &$cb };

sub run {
    my ($name, $items, $want, $want_calls) = @_;
    $calls = 0;
    my $v = DKIM2SignedFixture::verify(
        DKIM2SignedFixture::signed(ref $items ? (items => $items) : (s => $items)),
        PubkeyCallback => $counting);
    like($v->result_detail, $want, "$name: " . $v->result_detail);
    is($calls, $want_calls, "$name: $want_calls key lookup(s)");
}

run('rsa-sha256', [['sel1', 'rsa-sha256']], qr/^pass/, 1);
my $UNKNOWN = qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel1 algorithm unknown\)$/;
run('unknown algorithm, correctly signed with RSA', [['sel1', 'future-alg']], $UNKNOWN, 0);
run('RSA-SHA256 is not rsa-sha256', [['sel1', 'RSA-SHA256']], $UNKNOWN, 0);
run('ed25519-sha256x is not ed25519-sha256', [['sel1', 'ed25519-sha256x']], $UNKNOWN, 0);
run('unknown item "|" a good one',
    'sel2:future-alg:AAAA|sel1:rsa-sha256:SIG', qr/^pass/, 1);
run('unknown item "," a good one',
    [['sel2', 'future-alg', 'AAAA'], ['sel1', 'rsa-sha256']],
    qr/^permerror \(PERMERROR: DKIM2-Signature i=1 selector sel2 algorithm unknown\)$/, 1);
run('known algorithm, value not base64',
    [['sel1', 'rsa-sha256', '!!notbase64!!']],
    qr/^permerror .*DKIM2-Signature i=1 syntax error/, 0);
run('known algorithm, base64 missing its padding',
    [['sel1', 'rsa-sha256', 'AAA']],
    qr/^permerror .*DKIM2-Signature i=1 syntax error/, 0);
run('unknown algorithm, value not base64: a syntax error all the same',
    'sel2:future-alg:!!x!!|sel1:rsa-sha256:SIG',
    qr/^permerror \(PERMERROR: DKIM2-Signature i=1 syntax error\)$/, 0);

# -08 §14.5, §14.6: an absent key is a PERMERROR item, overridden only by
# a "|" alternative that passes.
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
    like($v->result_detail,
        qr/^permerror \(PERMERROR: DKIM2-Signature i=1 public key gone does not exist\)$/,
        'one key absent "," one that verifies: does not exist');
    $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(
            s => 'gone:rsa-sha256:AAAA|sel1:rsa-sha256:SIG'),
        PubkeyCallback => $some);
    like($v->result_detail, qr/^pass/, 'one key absent "|" one that verifies: pass');
}

# -08 section 14.6: every signature is checked; one failing in a "," group
# fails the group, naming its selector.
# (sel2's key is test1's sel2 key; the fixture signs every item with sel1's.)
{
    my $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(
        items => [['sel2', 'rsa-sha256']]));
    is($v->details, 'FAIL: DKIM2-Signature i=1 selector sel2 incorrect signature',
        'the only signature fails: selector incorrect signature');
    $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(
        items => [['sel1', 'rsa-sha256'], ['sel2', 'rsa-sha256']]));
    is($v->result, 'fail', 'one passes, one fails: fail');
    is($v->details, 'FAIL: DKIM2-Signature i=1 selector sel2 incorrect signature',
        '... naming the one that failed');
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

# Review R1: thousands of items cost no key lookups: past
# MAX_SIGNATURE_ITEMS the field is refused before any is fetched.
{
    my $s = join('|', map { "x$_:unknown$_:AAAA" } 1 .. 4000) . '|sel1:rsa-sha256:SIG';
    my $raw = DKIM2SignedFixture::signed(s => $s);
    $calls = 0;
    my $v = DKIM2SignedFixture::verify($raw, PubkeyCallback => $counting);
    is($v->result_detail, 'permerror (PERMERROR: DKIM2-Signature i=1 has more than 8 signatures)',
        '4001 items: refused');
    is($calls, 0, '4001 items: no key lookup');
    $s = join('|', map { "x$_:unknown$_:AAAA" } 1 .. 7) . '|sel1:rsa-sha256:SIG';
    $calls = 0;
    $v = DKIM2SignedFixture::verify(DKIM2SignedFixture::signed(s => $s), PubkeyCallback => $counting);
    like($v->result_detail, qr/^pass/, '7 unknown items + one good: pass');
    is($calls, 1, '... with one key lookup');
}

done_testing;
