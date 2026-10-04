#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signer;
use Mail::DKIM2::MessageInstance;
use Email::MIME;
use DKIM2TestKeys;
use Path::Tiny;
use Mail::DKIM2::Common qw(parse_dkim_pubkey);

# Fixed timestamp for reproducible signing
my $TIMESTAMP = 1740000000;

my $RAW_EMAIL = join("\r\n",
    'MIME-Version: 1.0',
    'Message-Id: <test-mi-coverage@example.com>',
    'Date: Thu, 21 Mar 2024 12:09:37 +1000',
    'From: sender@test1.dkim2.com',
    'To: recipient@test2.dkim2.com',
    'Subject: MI coverage test',
    'Content-Type: text/plain',
    '',
    'Test body for MI coverage verification.',
    '',
);

# Helper: sign a message and return Email::MIME object with the new DKIM2-Signature prepended
sub sign_msg {
    my ($msg, %hop) = @_;
    my $signer = Mail::DKIM2::Signer->new(
        Domain    => $hop{domain},
        Selector  => $hop{selector},
        Key       => DKIM2TestKeys::private_key($hop{domain}, $hop{selector}),
        MailFrom  => $hop{mailfrom},
        RcptTo    => $hop{rcptto},
        Timestamp => $TIMESTAMP,
    );
    $signer->PRINT($msg->as_string());
    $signer->CLOSE;
    my $header = $signer->as_string();
    $header =~ s{^DKIM2-Signature:\s*}{};
    $msg->header_raw_prepend('DKIM2-Signature', $header);
    return $signer;
}

# Helper: verify a message using test key callback
sub verify_msg {
    my ($msg) = @_;
    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);  # test emails have fixed timestamps
    $v->PRINT($msg->as_string());
    $v->CLOSE;
    return $v;
}

# Build a signed message: add MI m=1, sign i=1 m=1
my $msg = Email::MIME->new($RAW_EMAIL);

# Add MI m=1
my $mi = Mail::DKIM2::MessageInstance->calculate($msg->as_string());
$msg->header_raw_prepend('Message-Instance', $mi->as_string());

# Sign with i=1, m=1
sign_msg($msg,
    domain   => 'test1.dkim2.com',
    selector => 'sel1',
    mailfrom => 'sender@test1.dkim2.com',
    rcptto   => ['recipient@test2.dkim2.com'],
);

# Verify the original signed message passes
{
    my $signed_with_mi = $msg->as_string();
    like($signed_with_mi, qr/m=1/i, 'signed message contains m=1 reference');
    my $v = verify_msg($msg);
    is($v->result, 'pass', 'original message with MI m=1 covered by i=1 m=1 verifies');
}

# Tamper: prepend an uncovered MI m=2 header (fake hashes, not signed by any signature)
{
    my $tampered = Email::MIME->new($msg->as_string());
    $tampered->header_raw_prepend('Message-Instance',
        ' m=2; h=sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA:BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
    );

    my $v = verify_msg($tampered);
    # spec-06 §11 classes this as PERMERROR, not fail, and gives the wording:
    # "PERMERROR Message-Instance m=<x> is not signed".
    is($v->result, 'permerror', 'uncovered MI m=2 prepended without new signature must be permerror');
    like($v->result_detail, qr/m=2 is not signed/, 'result_detail uses the spec wording');
}

# spec-06 §11 again, the case the coverage check above could never reach: a
# message carrying a Message-Instance and NO DKIM2-Signature at all. This read
# as 'none' ("no DKIM2 here") until the check moved ahead of that return, which
# meant an unsigned instance was silently accepted. croessner/dkim2 rejects such
# a message outright (PERMERROR/missing_protocol).
{
    my $stripped = Email::MIME->new($msg->as_string());
    $stripped->header_raw_set('DKIM2-Signature');

    my $v = verify_msg($stripped);
    is($v->result, 'permerror', 'MI with no DKIM2-Signature at all must be permerror, not none');
    like($v->result_detail, qr/m=1 is not signed/, 'result_detail names the unsigned instance');
}

# The outbound path holds a new Message-Instance before the signature covering
# it exists, so a Signer verifying its own in-progress state must be able to
# opt out of the rule above.
{
    my $stripped = Email::MIME->new($msg->as_string());
    $stripped->header_raw_set('DKIM2-Signature');

    my $v = Mail::DKIM2::Verifier->new();
    $v->allow_unsigned_mi(1);
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($stripped->as_string());
    $v->CLOSE;
    isnt($v->result, 'permerror', 'allow_unsigned_mi suppresses the unsigned-MI permerror');
}

# The case that opt-out exists for, with real bytes: a Fastmail-signed post
# (m=1/i=1, d=unstable.email) after Mailman on mail.dkim2.com has tagged the
# subject, added List-* fields and a footer, and recorded the change as an
# UNSIGNED Message-Instance m=2 -- exactly what the outbound milter is handed
# to sign. Captured 2026-09-10, the first day Fastmail signed: the milter's
# pre-sign verify ran WITHOUT the opt-out, reported this PERMERROR, and every
# list post with a signed upstream left unsigned (bin/dkim2-milter; see
# t/milter-script.t for the end-to-end guard). unstable.email's fm3 key is
# pinned here so the fixture does not depend on live DNS or key rotation.
{
    my $raw = path("$FindBin::Bin/../tests/emails/mailman-m2-unsigned.eml")->slurp_raw;
    my $fm3 = 'v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvNUm+tvS0U30of4pAM4H6vX4Y9JK3H6om8lTIVZdl8MnbOvyn6xu5NPocIdwlQYZso4yFvNkSzbeCglvk3cCJHT8Xze1GNgUVSAJ7U8NjZKBD038pHeKtKQ6/3tEI0TgXZB2E+S8BL4v0w7xnq9lZMktqPbf7tZC7+5Tgyl/67lDN6j7ZQQMOkGCVhMsq58YIggcTrTrABIpoQmZ5Murj5EvTC6AulupdGJRblS8kUxU8caP+TiRPpgAIRY0J9rcJWQL767l6chVEFEdXbTiSW1gsaH7MYlYFomEJzJqVZVoJbL4ezPWoAELzDztlLCAs1SxHsEAbJuFs+HX8zKFtQIDAQAB';
    my $pinned = sub {
        my ($sig, $idx) = @_;
        return unless $sig->domain eq 'unstable.email' && $sig->selector($idx // 0) eq 'fm3';
        return parse_dkim_pubkey($fm3);
    };
    my $run = sub {
        my ($allow) = @_;
        my $v = Mail::DKIM2::Verifier->new;
        $v->allow_unsigned_mi($allow);
        $v->skip_timestamp_check(1);
        $v->set_pubkey_callback($pinned);
        $v->PRINT($raw); $v->CLOSE;
        return $v;
    };

    my $wire = $run->(0);
    is($wire->result, 'permerror', 'captured list post: as a receiver, the unsigned m=2 is PERMERROR');
    like($wire->result_detail, qr/m=2 is not signed/, 'captured list post: spec wording');

    my $signer = $run->(1);
    is($signer->result, 'pass', 'captured list post: as the signer of m=2, the upstream chain passes')
        or diag($signer->result_detail);
    like($signer->result_detail, qr/i=1\.\.1 verified/, 'captured list post: i=1 verified');

    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($raw);
    ok($ok, "captured list post: Mailman's m=2 matches the content and undoes to m=1")
        or diag($why);
}

done_testing;
