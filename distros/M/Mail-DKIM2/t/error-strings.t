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

# spec-06 canonical error-string forms (Task 3.1). Each case below builds a
# purpose-built failing message and asserts the verifier's result_detail
# matches the exact canonical wording, byte-for-byte (including the
# deliberate "MAIL nd=" spec typo for the nd= adjacency case).

my $TS = 1740000000;

# Build a chain of hops onto a single freshly-originated message (one
# Message-Instance, m=1), following the same pattern as t/nd-chain.t.
sub build_chain {
    my (@hops) = @_;

    my $raw = "From: sender\@test1.dkim2.com\r\nTo: rcpt\@test5.dkim2.com\r\n"
            . "Subject: error string test\r\n\r\nbody\r\n";
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
# Case 1: d= vs mf= domain mismatch
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => 'sender@test2.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'fail', 'd=/mf= domain mismatch fails');
    like($v->result_detail, qr/\QDKIM2-Signature i=1 MAIL FROM and d= do not match\E/,
        'canonical d=/mf= mismatch detail');
}

# ------------------------------------------------------------------
# Case 2: nd= adjacency mismatch (nd= declares a domain that the next
# signature's d= does not match)
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', next_domain => 'test2.dkim2.com' },
        { domain => 'test3.dkim2.com', mailfrom => 'sender@test3.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'fail', 'nd= adjacency mismatch fails');
    like($v->result_detail, qr/\QDKIM2-Signature i=1 MAIL nd= does not match\E/,
        'canonical nd= adjacency detail (verbatim MAIL typo preserved)');
}

# ------------------------------------------------------------------
# Case 3: Chain of Custody break (mf= domain doesn't relaxed-match any
# rt= of the previous hop)
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => 'sender@test1.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
        { domain => 'test2.dkim2.com', mailfrom => 'sender@test2.dkim2.com',
          rcptto => ['rcpt@test5.dkim2.com'] },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'fail', 'chain of custody break fails');
    like($v->result_detail,
        qr/\QDKIM2-Signature i=2 MAIL FROM <sender\E\@\Qtest2.dkim2.com> did not match\E/,
        'canonical chain-of-custody detail cites offending mf= value');
}

# ------------------------------------------------------------------
# Case 4: neither nd= nor mf=+rt= present (representative missing tag)
# ------------------------------------------------------------------
{
    my $msg = build_chain(
        { domain => 'test1.dkim2.com', mailfrom => undef, rcptto => undef },
    );
    my $v = verify_text($msg->as_string);
    is($v->result, 'permerror', 'missing mf=/rt=/nd= is a permerror');
    like($v->result_detail, qr/\QDKIM2-Signature i=1 tag=mf missing\E/,
        'canonical missing-chain-tags detail');
}

# ------------------------------------------------------------------
# Case 5: missing MAIL FROM on a non-nd hop (custody-check level, not the
# per-signature required-tag check -- mf= tag present but decodes empty)
# ------------------------------------------------------------------
{
    my $sig1 = Mail::DKIM2::Signature->new(
        Sequence => 1, Version => 0, Timestamp => $TS,
        Domain   => 'test1.dkim2.com',
        MailFrom => 'sender@test1.dkim2.com',
        RcptTo   => ['rcpt@test5.dkim2.com'],
    );
    my $sig2 = Mail::DKIM2::Signature->new(
        Sequence => 2, Version => 0, Timestamp => $TS,
        Domain   => 'test2.dkim2.com',
        RcptTo   => ['rcpt@test5.dkim2.com'],
    );
    # mf= tag present-but-empty (decodes to ''), distinct from "tag truly
    # absent" which is caught earlier by the per-signature required-tag
    # check with a different message ("tag=mf missing").
    $sig2->set_tag('mf', '');

    my $v = Mail::DKIM2::Verifier->new;
    $v->{_dk2_headers} = { 1 => { sig => $sig1 }, 2 => { sig => $sig2 } };
    my $ok = $v->_verify_chain();
    ok(!$ok, 'chain check rejects empty mf= on non-nd hop');
    like($v->result_detail, qr/\QDKIM2-Signature i=2 MAIL FROM <> did not match\E/,
        'canonical missing-MAIL-FROM custody detail');
}

# ------------------------------------------------------------------
# Case 6: missing RCPT TO on a non-nd hop (custody-check level, not the
# per-signature required-tag check -- driving _verify_chain() directly
# lets us exercise a prior hop whose rt= tag is truly absent, which the
# per-signature required-tag check would otherwise catch first with a
# different message)
# ------------------------------------------------------------------
{
    my $sig1 = Mail::DKIM2::Signature->new(
        Sequence => 1, Version => 0, Timestamp => $TS,
        Domain   => 'test1.dkim2.com',
        MailFrom => 'sender@test1.dkim2.com',
        # RcptTo intentionally omitted: rt= tag itself absent, so
        # rcpt_to() resolves to undef (distinct from present-but-empty).
    );
    my $sig2 = Mail::DKIM2::Signature->new(
        Sequence => 2, Version => 0, Timestamp => $TS,
        Domain   => 'test2.dkim2.com',
        MailFrom => 'sender@test2.dkim2.com',
        RcptTo   => ['rcpt@test5.dkim2.com'],
    );

    my $v = Mail::DKIM2::Verifier->new;
    $v->{_dk2_headers} = { 1 => { sig => $sig1 }, 2 => { sig => $sig2 } };
    my $ok = $v->_verify_chain();
    ok(!$ok, 'chain check rejects empty rt= on non-nd hop');
    like($v->result_detail, qr/\QDKIM2-Signature i=1 RCPT TO <> did not match\E/,
        'canonical missing-RCPT-TO custody detail');
}

done_testing;
