#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;
use DKIM2TestKeys;

# The Verifier keeps the body only when it has a signature to check it
# against, and finds the end of the headers however the message is split
# into chunks.

my $DOMAIN = 'test1.dkim2.com';
my $PLAIN  = join("\r\n",
    'From: sender@test1.dkim2.com',
    'To: someone@test2.dkim2.com',
    'Subject: streaming',
    '',
    'first body line',
    'second body line',
    '',
);

sub verify_chunks {
    my ($chunks, %opts) = @_;
    my $v = Mail::DKIM2::Verifier->new;
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->allow_unsigned_mi(1) if $opts{allow_unsigned_mi};
    $v->PRINT($_) for @$chunks;
    my $kept = length($v->{_buf} // '');
    $v->CLOSE;
    return ($v, $kept);
}

{
    my ($v, $kept) = verify_chunks([$PLAIN, "more body\r\n" x 1000]);
    is($v->result, 'none', 'unsigned mail is none');
    ok($v->stopped, '... decided from the headers');
    is($kept, 0, '... keeping none of the body');
}

my $mi   = Mail::DKIM2::MessageInstance->calculate($PLAIN);
my $with = "Message-Instance: " . $mi->as_string . "\r\n$PLAIN";

{
    my ($v, $kept) = verify_chunks([$with, "more body\r\n"]);
    is($v->result, 'permerror', 'a Message-Instance with no signature is a permerror');
    like($v->details, qr/^PERMERROR Message-Instance m=1 is not signed/, '... saying so');
    is($kept, 0, '... keeping none of the body');

    ($v) = verify_chunks([$with], allow_unsigned_mi => 1);
    is($v->result, 'none', 'and none when unsigned instances are allowed');
}

my $signer = Mail::DKIM2::Signer->new(
    Domain    => $DOMAIN,
    Selector  => 'sel1',
    Key       => DKIM2TestKeys::private_key($DOMAIN, 'sel1'),
    MailFrom  => 'sender@test1.dkim2.com',
    RcptTo    => ['someone@test2.dkim2.com'],
    Timestamp => 1740000000,
);
$signer->PRINT($with);
$signer->CLOSE;
(my $sig = $signer->as_string) =~ s/\r?\n\z//;
my $signed = "$sig\r\n$with";

{
    my ($v) = verify_chunks([$signed]);
    is($v->result, 'pass', 'a signed message verifies in one piece')
        or diag($v->details);

    ($v) = verify_chunks([split //, $signed]);
    is($v->result, 'pass', '... and one byte at a time')
        or diag($v->details);

    my ($head, $body) = split /\r\n\r\n/, $signed, 2;
    ($v) = verify_chunks(["$head\r", "\n\r", "\n$body"]);
    is($v->result, 'pass', '... and with the blank line split across chunks')
        or diag($v->details);
}

done_testing;
