#!/usr/bin/perl -w
# -09 section 14.4: the SMTP envelope a message arrived with must match the
# top DKIM2-Signature -- MAIL FROM exactly equal to mf=, every RCPT TO present
# in rt= -- local-parts exactly, domains without regard to case. The Verifier
# checks it when it is given the envelope (MailFrom, RcptTo); without them it
# cannot, and leaves it to its caller as before.
use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use DKIM2TestKeys;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;

my $raw = "From: Alice <alice\@test1.dkim2.com>\r\nTo: bob\@test2.dkim2.com\r\n"
        . "Subject: envelope\r\n\r\nbody\r\n";
my $mi  = Mail::DKIM2::MessageInstance->calculate($raw);
my $msg = "Message-Instance: " . $mi->as_string . "\r\n$raw";
my $signer = Mail::DKIM2::Signer->new(
    Domain => 'test1.dkim2.com', Selector => 'sel1',
    Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
    MailFrom => 'Alice@test1.dkim2.com',
    RcptTo => ['Bob@test2.dkim2.com', 'carol@test2.dkim2.com'],
    Timestamp => 1740000000,
);
$signer->PRINT($msg); $signer->CLOSE;
(my $sig = $signer->as_string) =~ s/\r?\n\z//;
$msg = "$sig\r\n$msg";

sub verify {
    my (%env) = @_;
    my $v = Mail::DKIM2::Verifier->new(
        PubkeyCallback => DKIM2TestKeys::pubkey_callback(), %env);
    $v->skip_timestamp_check(1);
    $v->PRINT($msg); $v->CLOSE;
    return ($v->result, $v->result_detail);
}

my ($r, $d) = verify();
is($r, 'pass', 'no envelope given: not checked') or diag $d;

($r, $d) = verify(MailFrom => '<Alice@test1.dkim2.com>', RcptTo => ['<Bob@test2.dkim2.com>']);
is($r, 'pass', 'the envelope the message was signed for') or diag $d;

($r, $d) = verify(MailFrom => 'Alice@TEST1.dkim2.com',
                  RcptTo => ['Bob@Test2.DKIM2.com', 'carol@test2.dkim2.com']);
is($r, 'pass', 'brackets optional, domains compared without regard to case') or diag $d;

($r, $d) = verify(MailFrom => 'Alice@test1.dkim2.com', RcptTo => ['mallory@test2.dkim2.com']);
is($r, 'fail', 'a recipient the signer did not name fails');
like($d, qr/\(FAIL: DKIM2-Signature i=1 RCPT TO <mallory\@test2\.dkim2\.com> did not match\)\z/,
     '  ... with section 14.4\'s error');

($r, $d) = verify(MailFrom => 'Alice@test1.dkim2.com',
                  RcptTo => ['Bob@test2.dkim2.com', 'mallory@test2.dkim2.com']);
is($r, 'fail', 'one stray recipient among good ones fails');

($r, $d) = verify(MailFrom => 'Alice@test1.dkim2.com', RcptTo => ['bob@test2.dkim2.com']);
is($r, 'fail', 'a local-part differing only in case does not match');

($r, $d) = verify(MailFrom => 'alice@test1.dkim2.com', RcptTo => ['Bob@test2.dkim2.com']);
is($r, 'fail', 'MAIL FROM must match mf= exactly');
like($d, qr/\(FAIL: DKIM2-Signature i=1 MAIL FROM <alice\@test1\.dkim2\.com> did not match\)\z/,
     '  ... with section 14.4\'s error');

($r, $d) = verify(MailFrom => '<>', RcptTo => ['Bob@test2.dkim2.com']);
is($r, 'fail', 'a null MAIL FROM does not match a non-null mf=');

($r, $d) = verify(RcptTo => ['mallory@test2.dkim2.com']);
is($r, 'fail', 'RcptTo alone is checked');
($r, $d) = verify(MailFrom => 'Alice@test1.dkim2.com');
is($r, 'pass', 'MailFrom alone is checked') or diag $d;

# -09 section 13.2 step 4: a message whose envelope does not match its top
# signature is not Provisionally Verified either, when the envelope is known.
sub provisional {
    my (%env) = @_;
    my $v = Mail::DKIM2::Verifier->new(
        PubkeyCallback => DKIM2TestKeys::pubkey_callback(), %env);
    $v->PRINT($msg); $v->CLOSE;      # timestamps checked: t= is long expired
    return ($v->result, $v->provisionally_verified);
}
is_deeply([provisional()], ['fail', 1], 'expired, no envelope: Provisionally Verified');
is_deeply([provisional(MailFrom => 'Alice@test1.dkim2.com', RcptTo => ['Bob@test2.dkim2.com'])],
    ['fail', 1], 'expired, the right envelope: Provisionally Verified');
is_deeply([provisional(RcptTo => ['mallory@test2.dkim2.com'])],
    ['fail', 0], 'expired, a recipient the signer did not name: not');
is_deeply([provisional(MailFrom => '<>')],
    ['fail', 0], 'expired, another MAIL FROM: not');

# -09 section 14.3: t= is checked against when the message was accepted.
sub at {
    my $v = Mail::DKIM2::Verifier->new(
        PubkeyCallback => DKIM2TestKeys::pubkey_callback(), AcceptedAt => $_[0]);
    $v->PRINT($msg); $v->CLOSE;
    return $v->result_detail;
}
is(at(1740000000 + 3600), 'pass (i=1..1 verified)', 'AcceptedAt an hour after t=: pass');
like(at(1740000000 + 15 * 86400), qr/i=1 signature expired/, 'fifteen days after: expired');
like(at(1740000000 - 2 * 86400), qr/i=1 signature is from the future/, 'two days before: from the future');
eval { Mail::DKIM2::Verifier->new(AcceptedAt => 'yesterday') };
like($@, qr/AcceptedAt/, 'AcceptedAt must be a number of seconds');

eval { Mail::DKIM2::Verifier->new(RcptTo => 'bob@test2.dkim2.com') };

like($@, qr/RcptTo/, 'RcptTo must be a list');

done_testing;
