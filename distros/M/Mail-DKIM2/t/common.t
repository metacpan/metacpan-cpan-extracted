use strict;
use warnings;
use Test::More;
use lib 'lib';
use MIME::Base64 qw(encode_base64 decode_base64);
use Mail::DKIM2::Common qw(should_skip parse_dkim_pubkey parse_dkim_key_record);

is(should_skip('authentication-results'), 1, 'authentication-results is skipped');
is(should_skip('Authentication-Results'), 1, 'Authentication-Results (mixed case) is skipped');
is(should_skip('subject'), 0, 'subject is NOT skipped');
is(should_skip('from'), 0, 'from is NOT skipped');
is(should_skip('received'), 1, 'received is still skipped');
is(should_skip('Delivered-To'), 1, 'Delivered-To is skipped (draft-03 §4.1)');

# parse_dkim_pubkey takes an Ed25519 key only in its raw 32-octet form, and
# never dies on a malformed record. A real proteamail.com record publishes a
# DER SPKI instead (that once crashed the reflector); -08 section 14.5 makes
# Ed25519 keys exactly 32 octets, so it is malformed (contract D7).
my $ed_der = 'v=DKIM1; k=ed25519; p=MCowBQYDK2VwAyEAerTO1LqpFWfGB9m+GLIFypeIk6x7cjSrwestuDVoMvQ=';
my $der_key;
ok(eval { $der_key = parse_dkim_pubkey($ed_der); 1 }, 'ed25519 key as DER does not die');
is($der_key, undef, '... and is not a usable key');
is((parse_dkim_key_record($ed_der))[1], 'is malformed', '... it is malformed');

# Raw 32-byte form (RFC 8463): the same key's last 32 octets of DER.
my $raw_b64 = encode_base64(substr(decode_base64(($ed_der =~ /p=(\S+)/)[0]), -32), '');
ok(parse_dkim_pubkey("v=DKIM1; k=ed25519; p=$raw_b64"), 'ed25519 key in raw 32-byte form parses');

my $bad;
my $ok = eval { $bad = parse_dkim_pubkey('v=DKIM1; k=ed25519; p=bm90YWtleQ=='); 1 };
ok($ok, 'malformed ed25519 key does not die');
is($bad, undef, 'malformed ed25519 key returns undef');

# -08 §4: names added by the HDRMAINT survey
for my $h (qw(Apparently-To DL-Expansion-History
              Original-Recipient SIO-Label-History
              X400-Received X400-Trace)) {
    ok(Mail::DKIM2::Common::should_skip($h), "-08 §4: $h is unsigned");
}

# -08 §4 took these two off the list: they are hashed now
for my $h (qw(Auto-Submitted VBR-Info)) {
    ok(!Mail::DKIM2::Common::should_skip($h), "-08 §4: $h is signed");
}

# -08 §4: any Received-* field is a trace field
ok(Mail::DKIM2::Common::should_skip('Received-SPF'), '-08 §4: Received-SPF is unsigned');
ok(Mail::DKIM2::Common::should_skip('Received-Anything'), '-08 §4: Received-* is unsigned');

# spec-05 §4: the ARC- prefix narrowed to exactly three names
ok(Mail::DKIM2::Common::should_skip('ARC-Seal'), '-08 §4: ARC-Seal is unsigned');
ok(Mail::DKIM2::Common::should_skip('ARC-Message-Signature'), '-08 §4: ARC-Message-Signature is unsigned');
ok(Mail::DKIM2::Common::should_skip('ARC-Authentication-Results'), '-08 §4: ARC-Authentication-Results is unsigned');
ok(!Mail::DKIM2::Common::should_skip('ARC-Something-Else'), '-08 §4: the ARC- prefix match is gone');

# -08 section 7.2 and 18: address domains, A-labels, the relaxed match.
{
    use Mail::DKIM2::Common qw(domain_of to_alabel relaxed_domain_match);
    is_deeply([domain_of('<A@Example.COM.>')], ['example.com', 0], 'domain_of: lowercased, one trailing dot off');
    is_deeply([domain_of('"a@b"@c.example')], ['c.example', 0], 'domain_of: after the last @');
    is_deeply([domain_of('<x@[192.0.2.1]>')], ['[192.0.2.1]', 1], 'domain_of: a domain literal is marked');
    is_deeply([domain_of('<>')], [], 'domain_of: the null path has none');
    is(to_alabel("b\xc3\xbccher.Example"), 'xn--bcher-kva.Example', 'to_alabel: only the non-ASCII label');
    is(to_alabel("B\xc3\x9cCHER.example"), 'xn--bcher-kva.example', 'to_alabel: lowercased first');
    is(to_alabel("bad\xff.example"), "bad\xff.example", 'to_alabel: not UTF-8, left alone');
    ok(relaxed_domain_match('mail.example.org', 'example.org'), 'relaxed: p1 below p2');
    ok(!relaxed_domain_match('example.org', 'mail.example.org'), 'relaxed: only p1 is shortened');
    ok(relaxed_domain_match('Example.ORG.', 'example.org'), 'relaxed: case and a trailing dot');
    ok(!relaxed_domain_match('[192.0.2.1]', '[192.0.2.1]'), 'relaxed: a literal never matches');
    ok(relaxed_domain_match("u.b\xc3\xbccher.example", 'xn--bcher-kva.example'), 'relaxed: compared as A-labels');
    ok(!relaxed_domain_match('xample.org', 'example.org'), 'relaxed: whole labels only');
}

# from_refusal_note: the milters' log line for a From refusal (final review I3).
{
    use Mail::DKIM2::Common qw(from_refusal_note);
    is(from_refusal_note('lists.example.org', '"A via list" <list@lists.example.net>'),
       "From domain lists.example.net is not d=lists.example.org or below it: a DKIM2 "
       . "list's posting address must be in the domain this milter signs with",
       'from_refusal_note: names the From domain and d=');
    like(from_refusal_note('example.org', "A a\@example.org\r\n"),
         qr/\AFrom domain \(not one mailbox: A a\@example\.org\) is not d=example\.org /,
         'from_refusal_note: a From that is not one mailbox, as one line');
    like(from_refusal_note('example.org', 'a@example.org', 'b@example.org'),
         qr/\AFrom domain \(2 From fields\) is not/, 'from_refusal_note: two From fields');
}

done_testing;
