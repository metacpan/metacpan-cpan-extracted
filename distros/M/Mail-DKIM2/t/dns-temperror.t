use strict;
use warnings;
use Test::More;
use Email::MIME;
use lib 'lib', 't/lib';
use Mail::DKIM2::Common qw(fold_header);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

# A transient DNS failure (timeout / SERVFAIL / network unreachable) MUST be
# reported as TEMPERROR (retryable), per draft-ietf-dkim-dkim2-spec-06 §10 —
# NOT as a permanent "no verifiable signature items". Only an answer that
# positively says the name has no TXT record (NXDOMAIN, NOERROR, NODATA) is
# permanent and returns undef (no key). Anything else -- including an error
# string this code has never seen -- is treated as transient: a DNS blip must
# never read as a forged signature. fetch_public_key signals the transient
# case by dying, which the verifier's eval maps to temperror.

# Minimal mock resolver: query() always returns no reply; errorstring() is
# whatever we set. Injected via the Verifier's Resolver option.
package MockResolver;
sub new { my ($c, %a) = @_; bless {%a}, $c }
sub query { return undef }
sub errorstring { $_[0]{err} }

package main;

my $tmpl = 'i=1; m=1; t=1; d=example.com; '
         . 'mf=PHNAZXhhbXBsZS5jb20+; rt=PHJAZXhhbXBsZS5jb20+; '
         . 's=sel1:rsa-sha256:AAAA;';

# 1. Transient failures die (→ temperror in the verifier).
for my $err ('query timed out', 'SERVFAIL', 'connection failed', 'network unreachable',
             'something this code has never heard of') {
    my $sig = Mail::DKIM2::Signature->parse($tmpl);
    my $v = Mail::DKIM2::Verifier->new(Resolver => MockResolver->new(err => $err));
    my $ok = eval { $v->fetch_public_key($sig, 0); 1 };
    ok(!$ok, "DNS failure '$err' dies (temperror, not silent undef)");
    like($@, qr/temperror/i, "  ... and the die message is tagged TEMPERROR");
}

# 2. NXDOMAIN / no-record does NOT die; returns undef (genuinely no key → permerror).
for my $err ('NXDOMAIN', 'NOERROR', 'NODATA') {
    my $sig = Mail::DKIM2::Signature->parse($tmpl);
    my $v = Mail::DKIM2::Verifier->new(Resolver => MockResolver->new(err => $err));
    my $r = eval { $v->fetch_public_key($sig, 0) };
    ok(!$@, "no-record '$err' does not die");
    is($r, undef, "  ... and returns undef (no key)");
}

# 2b. A Verifier with a Resolver and no callback uses it for the whole verify.
{
    my $signed = signed_message();
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1,
        Resolver => MockResolver->new(err => 'query timed out'));
    $v->load($signed);
    is($v->result, 'temperror', 'Resolver option drives the default key fetch');
}

# 2c. The pubkey callback is handed the verifier as its third argument, so a
#     callback that only overrides some keys can fall back to the real fetch.
{
    my $signed = signed_message();
    my @seen;
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1,
        Resolver => MockResolver->new(err => 'SERVFAIL'),
        PubkeyCallback => sub { my ($sig, $idx, $verifier) = @_; push @seen, $verifier;
                                return $verifier->fetch_public_key($sig, $idx) });
    $v->load($signed);
    is($seen[0], $v, 'callback receives the verifier');
    is($v->result, 'temperror', '  ... and the fallback fetch is classified as usual');
}

# 3. The same transient failure reached through a *pubkey callback* must also be
#    TEMPERROR.  The verifier used to eval only the no-callback branch, but every
#    real caller (milter, reflector, validator, CLIs) installs a callback -- and
#    the stock callbacks end in $sig->fetch_public_key(), which dies on transient
#    DNS.  So the croak escaped the verifier entirely and took the caller with it:
#    the reflector dropped the message instead of reflecting it unsigned.
#
#    Note what the result must NOT be: if the callback merely returned undef the
#    key would be skipped, leaving "no verifiable signature items" -> 'fail'.
#    A DNS blip must never read as a forged signature.
sub signed_message {
    my $raw = join('',
        "From: sender\@test1.dkim2.com\r\n",
        "To: rcpt\@test2.dkim2.com\r\n",
        "Subject: temperror test\r\n",
        "Date: Fri, 24 Jul 2026 12:00:00 +0000\r\n",
        "Message-ID: <te\@test1.dkim2.com>\r\n",
        "\r\n",
        "Body.\r\n",
    );
    my $msg = Email::MIME->new($raw);
    my $mi  = Mail::DKIM2::MessageInstance->calculate($msg);
    (my $folded = fold_header("Message-Instance: " . $mi->as_string)) =~ s/^Message-Instance:\s*//;
    $msg->header_raw_prepend('Message-Instance', $folded);
    my $signer = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => '<sender@test1.dkim2.com>', RcptTo => ['<rcpt@test2.dkim2.com>'],
        Timestamp => 1740000000,
    );
    $signer->PRINT($msg->as_string); $signer->CLOSE;
    (my $sig = $signer->as_string) =~ s/^DKIM2-Signature:\s*//;
    $msg->header_raw_prepend('DKIM2-Signature', $sig);
    my $out = $msg->as_string;
    $out =~ s/\r?\n/\r\n/g;
    return $out;
}

{
    my $signed = signed_message();

    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(sub { die "TEMPERROR: DNS lookup failed: SERVFAIL\n" });

    my $ok = eval { $v->PRINT($signed); $v->CLOSE; 1 };
    ok($ok, 'a pubkey callback that dies does not crash the verifier')
        or diag("verifier died: $@");
    is($v->result, 'temperror', '  ... the result is temperror');
    isnt($v->result, 'fail', '  ... and NOT fail (a DNS blip is not forgery)');
    like($v->result_detail // '', qr/SERVFAIL/,
        '  ... and the reason is carried through to result_detail');
}

# A callback that returns undef (genuinely no such key) is still a permanent
# condition, and must NOT be softened into temperror by the change above.
{
    my $signed = signed_message();
    my $v = Mail::DKIM2::Verifier->new;
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(sub { return });
    eval { $v->PRINT($signed); $v->CLOSE; 1 };
    isnt($v->result, 'temperror', 'callback returning undef is not temperror');
}

done_testing;
