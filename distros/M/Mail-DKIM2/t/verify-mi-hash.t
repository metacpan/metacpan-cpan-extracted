#!/usr/bin/perl -w
# §10.7: the verifier must reject a message whose body/headers no longer match
# the top Message-Instance, even when the signature crypto is intact.
use 5.020; use strict; use warnings;
use Test::More;
use Email::MIME;
use lib 'lib', 't/lib';
use Mail::DKIM2::Common qw(fold_header);
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signer;
use Mail::DKIM2::MessageInstance;
use DKIM2TestKeys;

my $cb = DKIM2TestKeys::pubkey_callback();

sub build_signed {
    my $raw = "From: a\@test1.dkim2.com\r\nTo: b\@test2.dkim2.com\r\nSubject: hi\r\n\r\noriginal body\r\n";
    my $msg = Email::MIME->new($raw);
    my $mi  = Mail::DKIM2::MessageInstance->calculate($msg);
    (my $folded = fold_header("Message-Instance: " . $mi->as_string)) =~ s/^Message-Instance:\s*//;
    $msg->header_raw_prepend('Message-Instance', $folded);
    my $signer = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['b@test2.dkim2.com'],
        Timestamp => 1740000000,
    );
    $signer->PRINT($msg->as_string); $signer->CLOSE;
    (my $sig = $signer->as_string) =~ s/^DKIM2-Signature:\s*//;
    $msg->header_raw_prepend('DKIM2-Signature', $sig);
    return $msg->as_string;
}

sub verdict {
    my ($text) = @_;
    my $v = Mail::DKIM2::Verifier->new; $v->skip_timestamp_check(1);
    $v->set_pubkey_callback($cb); $v->PRINT($text); $v->CLOSE;
    return $v->result;
}

my $good = build_signed();
is(verdict($good), 'pass', 'untampered signed message verifies');

# Tamper the body AFTER signing (append a line) — crypto stays valid, but the
# top MI body hash no longer matches.
my $body_tampered = $good . "tampered line\r\n";
is(verdict($body_tampered), 'fail', 'body tamper -> fail (MI body hash mismatch)');

# Tamper a signed header value (Subject) without updating the MI.
(my $hdr_tampered = $good) =~ s/^Subject: hi/Subject: HACKED/m;
is(verdict($hdr_tampered), 'fail', 'header tamper -> fail (MI header hash mismatch)');

done_testing;
