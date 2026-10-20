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

# -07 canonical error-string forms (contract C6). Each case below builds a
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
    is($v->result, 'permerror', 'd=/mf= domain mismatch fails');
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
    is($v->result, 'permerror', 'nd= adjacency mismatch fails');
    is($v->details, 'PERMERROR: DKIM2-Signature i=1 nd= does not match', 'nd= adjacency detail');
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
    is($v->result, 'permerror', 'chain of custody break fails');
    is($v->details, 'PERMERROR: DKIM2-Signature i=2 mf= does not match the rt= of i=1',
        'chain-of-custody detail');
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
    is($v->details, 'PERMERROR: DKIM2-Signature i=2 mf= does not match the rt= of i=1',
        'missing-MAIL-FROM custody detail');
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
    is($v->details, 'PERMERROR: DKIM2-Signature i=2 mf= does not match the rt= of i=1',
        'missing-RCPT-TO custody detail');
}

# ------------------------------------------------------------------
# -07 sections 14.2 to 14.8: the exact strings, one message each (built
# with t/lib/Spec07Fixture.pm, which signs whatever it is asked to).
# ------------------------------------------------------------------
{
    require Spec07Fixture;
    my %h1 = (d => 'example.com', mf => '<a@example.com>', rt => ['<list@lists.example.org>']);
    my %h2 = (d => 'example.org', mf => '<x@lists.example.org>', rt => ['<b@example.net>']);
    my $m1 = Spec07Fixture::add_mi(Spec07Fixture::message());
    my $one = Spec07Fixture::add_sig($m1, %h1);
    my $fresh = sub { my $v = Spec07Fixture::verify($_[0]); [$v->result, $v->details] };
    my $key_from = sub {    # a PubkeyCallback dying as fetch_public_key does
        my ($why) = @_;
        return sub { die "PERMERROR: $why\n" };
    };

    my @cases = (
        [ 'no DKIM2 header fields',
          Spec07Fixture::message(), ['none', 'no DKIM2-Signature headers found'] ],
        [ 'instances but no signature', $m1,
          ['permerror', 'PERMERROR: Message-Instance m=1 is not signed'] ],
        [ 'an instance above the top signature',
          Spec07Fixture::add_mi(($one =~ s/^Subject: test/Subject: x/mr), $one),
          ['permerror', 'PERMERROR: Message-Instance m=2 is not signed'] ],
        [ 'a missing instance',
          Spec07Fixture::add_sig($one, %h2, m => 2),
          ['permerror', 'PERMERROR: Message-Instance m=2 missing'] ],
        [ 'a missing signature',
          ($one =~ s/^DKIM2-Signature: i=1;/DKIM2-Signature: i=2;/mr),
          ['permerror', 'PERMERROR: DKIM2-Signature i=1 missing'] ],
        [ 'an instance with no h=',
          Spec07Fixture::add_sig("Message-Instance: m=1;\r\n" . Spec07Fixture::message(), %h1),
          ['permerror', 'PERMERROR: Message-Instance m=1 tag=h missing'] ],
        [ 'an instance with ";;"',
          ($one =~ s/^Message-Instance: m=1;/Message-Instance: m=1;;/mr),
          ['permerror', 'PERMERROR: Message-Instance m=1 syntax error'] ],
        [ 'an instance tag twice in different case',
          ($one =~ s/^Message-Instance: m=1;/Message-Instance: m=1; M=1;/mr),
          ['permerror', 'PERMERROR: Message-Instance m=1 syntax error'] ],
        [ 'a signature tag twice in different case',
          ($one =~ s/^DKIM2-Signature: i=1;/DKIM2-Signature: i=1; D=example.com;/mr),
          ['permerror', 'PERMERROR: DKIM2-Signature i=1 syntax error'] ],
        [ 'no t=',
          ($one =~ s/\bt=\d+; //r),
          ['permerror', 'PERMERROR: DKIM2-Signature i=1 tag=t missing'] ],
        [ 'nd= with mf=',
          Spec07Fixture::add_sig(Spec07Fixture::add_sig($m1, %h1, nd => 'example.org'), %h2),
          ['permerror', 'PERMERROR: DKIM2-Signature i=1 tag=mf was unexpected'] ],
        [ 'nd= with rt=',
          Spec07Fixture::add_sig(Spec07Fixture::add_sig($m1, d => 'example.com',
              rt => ['<b@example.org>'], nd => 'example.org'), %h2),
          ['permerror', 'PERMERROR: DKIM2-Signature i=1 tag=rt was unexpected'] ],
        [ 'no rt=',
          Spec07Fixture::add_sig($m1, d => 'example.com', mf => '<a@example.com>'),
          ['permerror', 'PERMERROR: DKIM2-Signature i=1 tag=rt missing'] ],
    );
    for my $c (@cases) {
        my ($name, $text, $want) = @$c;
        is_deeply($fresh->($text), $want, "-07 string: $name");
    }

    # The key strings, from what fetch_public_key dies with.
    for my $why ('has multiple records', 'has a syntax error', 'has been revoked', 'algorithm mismatch') {
        my $v = Spec07Fixture::verify($one, PubkeyCallback => $key_from->($why));
        is($v->details, "PERMERROR: DKIM2-Signature i=1 public key sel1 $why", "-07 string: key $why");
    }
    my $v = Spec07Fixture::verify($one, PubkeyCallback => sub { undef });
    is($v->details, 'PERMERROR: DKIM2-Signature i=1 public key sel1 does not exist', '-07 string: no key');
    $v = Spec07Fixture::verify($one, PubkeyCallback => sub { die "TEMPERROR: timed out\n" });
    is_deeply([$v->result, $v->details, $v->diagnostic],
        ['temperror', 'TEMPERROR: DKIM2-Signature i=1 public key sel1 could not be fetched', 'TEMPERROR: timed out'],
        '-07 string: key not fetched, the reason in diagnostic()');

    # Selector rules (section 10.9).
    (my $dupsel = $one) =~ s/(s=sel1:rsa-sha256:[^;]*)/$1,sel1:ed25519-sha256:AAAA/;
    is(Spec07Fixture::verify($dupsel)->details, 'PERMERROR: DKIM2-Signature i=1 has a duplicate selector',
        '-07 string: duplicate selector');
    (my $three = $one) =~ s/(s=sel1:rsa-sha256:[^;]*)/$1,s2:rsa-sha256:AAAA,s3:rsa-sha256:AAAA/;
    is(Spec07Fixture::verify($three)->details, 'PERMERROR: DKIM2-Signature i=1 has more selectors than allowed',
        '-07 string: more selectors than allowed');
}

done_testing;
