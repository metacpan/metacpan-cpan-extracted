#!/usr/bin/perl -w

use 5.020;
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

# Local policy (spec-06): the highest-numbered DKIM2-Signature MUST NOT carry
# nd=, and every DKIM2-Signature MUST carry i=, m=, t=, d=, s=. The only
# legitimate nd= producer is reflector-brand-nd, which always emits the nd=
# signature together with the matching higher-i= signature, so nd= never
# ends up on top. Non-top (including consecutive) nd= hops must still
# verify+undo per the existing Chain of Custody adjacency logic.

my $TS = 1740000000;

# Build a chain of hops onto a single freshly-originated message (one
# Message-Instance, m=1). Each hop is either an nd= "imaginary" hop
# (next_domain set) or a normal mf=/rt= hop.
sub build_chain {
    my (@hops) = @_;

    my $raw = "From: sender\@test1.dkim2.com\r\nTo: rcpt\@test5.dkim2.com\r\n"
            . "Subject: nd chain test\r\n\r\nbody\r\n";
    my $msg = Email::MIME->new($raw);

    my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
    my $folded = fold_header("Message-Instance: " . $mi->as_string());
    $folded =~ s/^Message-Instance:\s*//;
    $msg->header_raw_prepend('Message-Instance', $folded);
    $msg = Email::MIME->new($msg->as_string);

    for my $hop (@hops) {
        my $selector = $hop->{selector} // 'sel1';
        my %args = (
            Domain    => $hop->{domain},
            Selector  => $selector,
            Key       => DKIM2TestKeys::private_key($hop->{domain}, $selector),
            Timestamp => $TS,
        );
        if ($hop->{next_domain}) {
            $args{NextDomain} = $hop->{next_domain};
        }
        else {
            $args{MailFrom} = $hop->{mailfrom};
            $args{RcptTo}   = $hop->{rcptto};
        }
        my $signer = Mail::DKIM2::Signer->new(%args);
        $signer->PRINT($msg->as_string);
        $signer->CLOSE;
        my $header = $signer->as_string;
        $header =~ s/^DKIM2-Signature:\s*//;
        $msg->header_raw_prepend('DKIM2-Signature', $header);
        $msg = Email::MIME->new($msg->as_string);
    }

    return $msg;
}

sub verify_text {
    my ($text) = @_;
    my $v = Mail::DKIM2::Verifier->new;
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($text);
    $v->CLOSE;
    return $v;
}

# ------------------------------------------------------------------
# Case 1a: single nd= hop (i=1 nd=, i=2 mf/rt top) -> pass
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', next_domain => 'test2.dkim2.com' },
        { domain => 'test2.dkim2.com', mailfrom => 'sender@test2.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'pass', 'single nd= hop chain verifies pass')
        or diag($v->result_detail);
}

# ------------------------------------------------------------------
# Case 1b: doubled/consecutive nd= run (i=1 nd=, i=2 nd=, i=3 mf/rt top)
# -> pass
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', next_domain => 'test2.dkim2.com' },
        { domain => 'test2.dkim2.com', next_domain => 'test3.dkim2.com' },
        { domain => 'test3.dkim2.com', mailfrom => 'sender@test3.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'pass', 'doubled nd= run chain verifies pass')
        or diag($v->result_detail);
}

# ------------------------------------------------------------------
# Case 2: highest-i= signature carries nd= -> permerror
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', next_domain => 'test2.dkim2.com' },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'permerror', 'top nd= rejected');
    like($v->result_detail, qr/DKIM2-Signature i=\d+ unexpected nd= tag/,
        'correct detail for top nd=');
}

# ------------------------------------------------------------------
# Case 3: signature missing t= -> permerror
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => 'sender@test1.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
    );
    my $text = $msg->as_string;

    # Unfold the DKIM2-Signature header, then strip the t= tag entirely.
    $text =~ s/(DKIM2-Signature:.*?\r\n(?:[ \t][^\r\n]*\r\n)*)/_strip_t($1)/e;

    my $v = verify_text($text);
    is($v->result, 'permerror', 'missing t= rejected');
    like($v->result_detail, qr/DKIM2-Signature i=\d+ tag=t missing/,
        'correct detail for missing t=');
}

sub _strip_t {
    my ($header) = @_;
    $header =~ s/\r\n[ \t]+/ /g;   # unfold
    $header =~ s/\bt=\d+;\s*//;
    return $header;
}

# ------------------------------------------------------------------
# Case 5: a Forwarder's §9.3 bridge. The message arrived at test2 (i=1
# rt=), test2 sends it on from a different domain (test3) and bridges the gap
# with an nd= hop made with test2's key, then signs the real hop as test3.
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => 'sender@test1.dkim2.com', rcptto => ['user@test2.dkim2.com'] },
        { domain => 'test2.dkim2.com', next_domain => 'test3.dkim2.com' },
        { domain => 'test3.dkim2.com', mailfrom => 'srs0=x@bounce.test3.dkim2.com', rcptto => ['dest@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'pass', 'a bridged forward keeps the chain of custody')
        or diag($v->result_detail);
}

# ------------------------------------------------------------------
# Case 6: the same shape with a bridge made with a key for a domain the
# message never arrived at: the nd= hop's d= must belong to the previous
# hop's RCPT TO.
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => 'sender@test1.dkim2.com', rcptto => ['user@test2.dkim2.com'] },
        { domain => 'test4.dkim2.com', next_domain => 'test3.dkim2.com' },
        { domain => 'test3.dkim2.com', mailfrom => 'srs0=x@bounce.test3.dkim2.com', rcptto => ['dest@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'fail', 'a bridge from a domain the mail never reached fails');
    like($v->result_detail, qr/i=2 nd= hop d=test4\.dkim2\.com did not match RCPT TO/,
        'correct detail for a mismatched bridge');
}

# ------------------------------------------------------------------
# Case 7: without the bridge, the same forward breaks custody, which is
# what the bridge is for.
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => 'sender@test1.dkim2.com', rcptto => ['user@test2.dkim2.com'] },
        { domain => 'test3.dkim2.com', mailfrom => 'srs0=x@bounce.test3.dkim2.com', rcptto => ['dest@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'fail', 'an unbridged forward from another domain fails custody');
}

done_testing;
