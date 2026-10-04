use strict;
use warnings;
use Test::More;
use lib 'lib';
use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Common qw(should_skip parse_dkim_pubkey);

is(should_skip('authentication-results'), 1, 'authentication-results is skipped');
is(should_skip('Authentication-Results'), 1, 'Authentication-Results (mixed case) is skipped');
is(should_skip('subject'), 0, 'subject is NOT skipped');
is(should_skip('from'), 0, 'from is NOT skipped');
is(should_skip('received'), 1, 'received is still skipped');
is(should_skip('Delivered-To'), 1, 'Delivered-To is skipped (draft-03 §4.1)');

# parse_dkim_pubkey must accept both ed25519 key encodings and never die on a
# malformed record (a real proteamail.com record publishes a DER SPKI rather
# than the RFC 8463 raw 32-byte form; that previously crashed the reflector).
my $ed_der = 'v=DKIM1; k=ed25519; p=MCowBQYDK2VwAyEAerTO1LqpFWfGB9m+GLIFypeIk6x7cjSrwestuDVoMvQ=';
ok(parse_dkim_pubkey($ed_der), 'ed25519 key in DER SubjectPublicKeyInfo form parses');

# Raw 32-byte form (RFC 8463): derive it from the DER key above for a stable vector.
my $pk_der = parse_dkim_pubkey($ed_der);
my $raw_b64 = encode_base64($pk_der->export_key_raw('public'), '');
ok(parse_dkim_pubkey("v=DKIM1; k=ed25519; p=$raw_b64"), 'ed25519 key in raw 32-byte form parses');

my $bad;
my $ok = eval { $bad = parse_dkim_pubkey('v=DKIM1; k=ed25519; p=bm90YWtleQ=='); 1 };
ok($ok, 'malformed ed25519 key does not die');
is($bad, undef, 'malformed ed25519 key returns undef');

# spec-06 §4: names added by the HDRMAINT survey
for my $h (qw(Apparently-To Auto-Submitted DL-Expansion-History
              Original-Recipient SIO-Label-History VBR-Info
              X400-Received X400-Trace)) {
    ok(Mail::DKIM2::Common::should_skip($h), "spec-06 §4: $h is unsigned");
}

# spec-06 §4: any Received-* field is a trace field
ok(Mail::DKIM2::Common::should_skip('Received-SPF'), 'spec-06 §4: Received-SPF is unsigned');
ok(Mail::DKIM2::Common::should_skip('Received-Anything'), 'spec-06 §4: Received-* is unsigned');

# spec-05 §4: the ARC- prefix narrowed to exactly three names
ok(Mail::DKIM2::Common::should_skip('ARC-Seal'), 'spec-06 §4: ARC-Seal is unsigned');
ok(Mail::DKIM2::Common::should_skip('ARC-Message-Signature'), 'spec-06 §4: ARC-Message-Signature is unsigned');
ok(Mail::DKIM2::Common::should_skip('ARC-Authentication-Results'), 'spec-06 §4: ARC-Authentication-Results is unsigned');
ok(!Mail::DKIM2::Common::should_skip('ARC-Something-Else'), 'spec-06 §4: the ARC- prefix match is gone');

done_testing;
