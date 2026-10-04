#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use lib 'lib'; use lib 't/lib';
use Email::MIME;
use Mail::DKIM2::Signer; use Mail::DKIM2::Signature; use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier; use DKIM2TestKeys;
my $TS = 1740000000;

sub sign_msg {
    my (%o) = @_;
    my $raw = "From: s\@$o{dom}\r\nTo: r\@x.example\r\nSubject: t\r\n\r\nbody\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
    my $with = "Message-Instance: ".$mi->as_string."\r\n".$raw;
    my $s = Mail::DKIM2::Signer->new(Domain=>$o{dom}, Selector=>'rsa1024',
        Key=>DKIM2TestKeys::private_key($o{dom},'rsa1024'),
        MailFrom=>$o{mf}, RcptTo=>$o{rt}, Timestamp=>$TS);
    $s->PRINT($with); $s->CLOSE;
    return ($s->as_string, $with);
}

# 1. bare address in -> bracketed on the wire
my ($sig_hdr) = sign_msg(dom=>'test1.dkim2.com', mf=>'sender@test1.dkim2.com',
                         rt=>['rcpt@test2.dkim2.com']);
(my $only = $sig_hdr) =~ s/^DKIM2-Signature:\s*//s;
my $sig = Mail::DKIM2::Signature->parse($only);
is($sig->mail_from, '<sender@test1.dkim2.com>', 'mf= wraps bare address in <>');
is_deeply($sig->rcpt_to, ['<rcpt@test2.dkim2.com>'], 'rt= wraps bare address in <>');

# 2. null sender stays <>
my ($sig2) = sign_msg(dom=>'test1.dkim2.com', mf=>'<>', rt=>['<rcpt@test2.dkim2.com>']);
(my $only2 = $sig2) =~ s/^DKIM2-Signature:\s*//s;
is(Mail::DKIM2::Signature->parse($only2)->mail_from, '<>', 'null sender stays <>');

# 3. enforcement: a hand-built signature with a BARE mf= fails verification
my ($ok_hdr, $with) = sign_msg(dom=>'test1.dkim2.com', mf=>'sender@test1.dkim2.com',
                               rt=>['rcpt@test2.dkim2.com']);
my $signed_ok = $ok_hdr."\r\n".$with;
# tamper: replace the bracketed mf= base64 with the BARE base64 (no <>)
use MIME::Base64 qw(encode_base64);
my $bare_b64 = encode_base64('sender@test1.dkim2.com','');
my $brkt_b64 = encode_base64('<sender@test1.dkim2.com>','');
(my $bad = $signed_ok) =~ s/\Q$brkt_b64\E/$bare_b64/;
my $v = Mail::DKIM2::Verifier->new; $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback()); $v->skip_timestamp_check(1);
$v->PRINT($bad); $v->CLOSE;
is($v->result, 'fail', 'bare mf= fails verification');
like($v->result_detail, qr/7\.5|bracket/i, 'failure reason cites mf= bracket rule');

# 4. the well-formed (bracketed) message verifies pass
my $v2 = Mail::DKIM2::Verifier->new; $v2->set_pubkey_callback(DKIM2TestKeys::pubkey_callback()); $v2->skip_timestamp_check(1);
$v2->PRINT($signed_ok); $v2->CLOSE;
is($v2->result, 'pass', 'bracketed message verifies pass');
done_testing;
