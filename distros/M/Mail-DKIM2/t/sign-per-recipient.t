#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;
use Email::MIME;
use DKIM2TestKeys;

# DKIM2 binds rt= to the envelope recipient (§8.6), so one signature cannot
# cover a multi-recipient message: each recipient needs its own. §9.6 signs
# solely the Message-Instance and DKIM2-Signature header fields, so the body
# hash and the header-fields hash -- everything expensive -- are identical for
# every recipient and belong to the single Message-Instance.
#
# Signer::sign_for_recipient exists so a caller can pay for that once and then
# spend one signature per recipient. These tests prove the cheap path produces
# signatures that actually verify, which is the only thing that matters.

my $TIMESTAMP = 1740000000;
my $DOMAIN    = 'test1.dkim2.com';
my $SELECTOR  = 'sel1';
my $MAILFROM  = 'sender@test1.dkim2.com';
my @RCPTS     = ('one@test2.dkim2.com', 'two@test3.dkim2.com', 'three@test4.dkim2.com');

my $RAW = join("\r\n",
    'MIME-Version: 1.0',
    'Message-Id: <per-recipient@example.com>',
    'Date: Thu, 21 Mar 2024 12:09:37 +1000',
    'From: sender@test1.dkim2.com',
    'To: undisclosed-recipients:;',
    'Subject: one message, several recipients',
    'Content-Type: text/plain',
    '',
    'Body that every recipient receives byte for byte.',
    '',
);

# The Message-Instance is computed ONCE and shared by every recipient.
my $base = Email::MIME->new($RAW);
my $mi   = Mail::DKIM2::MessageInstance->calculate($base->as_string());
$base->header_raw_prepend('Message-Instance', $mi->as_string());
my $with_mi = $base->as_string();

# One pass over the message, then one signature per recipient.
my $signer = Mail::DKIM2::Signer->new(
    Domain    => $DOMAIN,
    Selector  => $SELECTOR,
    Key       => DKIM2TestKeys::private_key($DOMAIN, $SELECTOR),
    MailFrom  => $MAILFROM,
    RcptTo    => [$RCPTS[0]],
    Timestamp => $TIMESTAMP,
);
$signer->PRINT($with_mi);
$signer->CLOSE;

my %header_for;
for my $rcpt (@RCPTS) {
    $header_for{$rcpt} = $signer->sign_for_recipient($rcpt);
}

is(scalar keys %header_for, scalar @RCPTS, 'one signature header per recipient');

# Each recipient's message must verify on its own.
for my $rcpt (@RCPTS) {
    my $header = $header_for{$rcpt};
    $header =~ s{^DKIM2-Signature:\s*}{};

    my $msg = Email::MIME->new($with_mi);
    $msg->header_raw_prepend('DKIM2-Signature', $header);

    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($msg->as_string());
    $v->CLOSE;
    is($v->result, 'pass', "message signed for $rcpt verifies");

    my $sig = ($v->{_dk2_headers}{1} || {})->{sig};
    ok($sig, "$rcpt: signature parsed");
    is_deeply($sig->rcpt_to, ["<$rcpt>"], "$rcpt: rt= names exactly this recipient");
    is($sig->mail_from, "<$MAILFROM>", "$rcpt: mf= is unchanged across recipients");
}

# The whole point: only rt= differs. If anything else moved, the per-recipient
# path would be recomputing work it is supposed to share.
{
    my @stripped = map {
        my $h = $header_for{$_};
        $h =~ s/\brt=[^;]*;?\s*//;   # drop the recipient tag
        $h =~ s/\bs=[^;]*;?\s*//;    # and the signature bytes it changes
        $h =~ s/\s+//g;
        $h;
    } @RCPTS;
    is(scalar(keys %{{ map { $_ => 1 } @stripped }}), 1,
       'signatures are identical apart from rt= and the signature bytes');
}

# The Message-Instance must not have been touched by any of it.
{
    my ($mi_before) = $with_mi =~ /^(Message-Instance:.*?)(?=\r\n\S|\r\n\r\n)/ms;
    for my $rcpt (@RCPTS) {
        my $header = $header_for{$rcpt};
        $header =~ s{^DKIM2-Signature:\s*}{};
        my $msg = Email::MIME->new($with_mi);
        $msg->header_raw_prepend('DKIM2-Signature', $header);
        my ($mi_after) = $msg->as_string() =~ /^(Message-Instance:.*?)(?=\r\n\S|\r\n\r\n)/ms;
        is($mi_after, $mi_before, "$rcpt: Message-Instance is byte-identical (computed once)");
    }
}

# A signature carrying nd= excludes rt= by §8.7, so this path must refuse it
# rather than silently producing a header with both.
{
    my $nd_signer = Mail::DKIM2::Signer->new(
        Domain     => $DOMAIN,
        Selector   => $SELECTOR,
        Key        => DKIM2TestKeys::private_key($DOMAIN, $SELECTOR),
        NextDomain => 'test2.dkim2.com',
        Timestamp  => $TIMESTAMP,
    );
    $nd_signer->PRINT($with_mi);
    $nd_signer->CLOSE;
    my $ok = eval { $nd_signer->sign_for_recipient($RCPTS[0]); 1 };
    ok(!$ok, 'sign_for_recipient refuses a signature carrying nd=');
    like($@, qr/nd=/, 'and says why');
}

done_testing;
