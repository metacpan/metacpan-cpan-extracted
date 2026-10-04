#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use lib 'lib';
use lib 't/lib';
use Email::MIME;
use Mail::DKIM2::Signer;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signature;
use DKIM2TestKeys;

my $TS = 1740000000;

# A fresh origin message signed with a null envelope sender, as a
# Postfix-generated bounce/DSN would be.
my $raw = "From: Mail Delivery System <MAILER-DAEMON\@test1.dkim2.com>\r\n"
        . "To: sender\@origin.example\r\n"
        . "Subject: Undelivered Mail Returned to Sender\r\n"
        . "\r\n"
        . "delivery failed\r\n";

my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
my $with_mi = "Message-Instance: " . $mi->as_string . "\r\n" . $raw;

my $signer = Mail::DKIM2::Signer->new(
    Domain    => 'test1.dkim2.com',
    Selector  => 'rsa1024',
    Key       => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
    MailFrom  => '<>',
    RcptTo    => ['sender@origin.example'],
    Timestamp => $TS,
);
$signer->PRINT($with_mi);
$signer->CLOSE;
is($signer->result, 'signed', 'null-MailFrom message signs');

my $sig_hdr = $signer->as_string;
my $signed  = $sig_hdr . "\r\n" . $with_mi;

# Parse the signature and confirm mf=<> and rt=recipient.
(my $sig_only = $sig_hdr) =~ s/^DKIM2-Signature:\s*//s;
my $sig = Mail::DKIM2::Signature->parse($sig_only);
is($sig->mail_from, '<>', 'mf decodes to <>');
is_deeply($sig->rcpt_to, ['<sender@origin.example>'], 'rt decodes to recipient');

my $v = Mail::DKIM2::Verifier->new;
# $TS is a fixed past timestamp, outside the verifier's 14-day freshness
# window (same reason t/dsn.t and t/reflector.t skip this check).
$v->skip_timestamp_check(1);
$v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
$v->PRINT($signed);
$v->CLOSE;
is($v->result, 'pass', 'null-MailFrom signed message verifies pass');

done_testing;
