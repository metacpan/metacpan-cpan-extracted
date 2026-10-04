#!/usr/bin/perl -w

use 5.020;
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Email::MIME;
use JSON;
use MIME::Base64;
use lib 'lib', 't/lib';

use Mail::DKIM2::Common qw(dkim2_canonicalize_header parse_dkim_pubkey fold_header);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

# ============================================================
# The progression: 5 hops, each with a different domain/Selector
#
#   brong-orig.eml  -- originator at test1.dkim2.com (sel1)
#   brong-mm.eml    -- mailing list at test2.dkim2.com (sel2)
#   brong-mm2.eml   -- relay adds header at test3.dkim2.com (sel3)
#   brong-mm3.eml   -- relay removes header at test4.dkim2.com (sel1)
#   brong-final.eml -- final delivery at test5.dkim2.com (sel2)
# ============================================================

my @hops = (
    {
        name     => 'originator',
        file     => 'tests/emails/brong-orig.eml',
        domain   => 'test1.dkim2.com',
        selector => 'sel1',
        mailfrom => 'brong@test1.dkim2.com',
        rcptto   => ['list@test2.dkim2.com'],
    },
    {
        name     => 'mailing list',
        file     => 'tests/emails/brong-mm.eml',
        domain   => 'test2.dkim2.com',
        selector => 'sel2',
        mailfrom => 'bounces@test2.dkim2.com',
        rcptto   => ['user@test3.dkim2.com'],
    },
    {
        name     => 'relay adds Extra-Header',
        file     => 'tests/emails/brong-mm2.eml',
        domain   => 'test3.dkim2.com',
        selector => 'sel3',
        mailfrom => 'relay@test3.dkim2.com',
        rcptto   => ['user@test4.dkim2.com'],
    },
    {
        name     => 'relay removes Extra-Header',
        file     => 'tests/emails/brong-mm3.eml',
        domain   => 'test4.dkim2.com',
        selector => 'sel1',
        mailfrom => 'relay@test4.dkim2.com',
        rcptto   => ['user@test5.dkim2.com'],
    },
    {
        # brong-final.eml differs from brong-mm3.eml by a pile of prepended
        # MTA trace/spam headers (Received, ARC-*, Authentication-Results,
        # Received-SPF, X-*) plus a "[test5] " tag hand-added to the front
        # of the Subject header's value. Under spec-06 §4, every one of
        # those prepended headers is unsigned (the last holdout,
        # Received-SPF, moved to unsigned when the `received-` prefix rule
        # landed) -- without the Subject tag, this hop's header+body hash
        # would be bit-identical to hop 4's, add_mi() would correctly
        # decline to add a new Message-Instance (see MI.pm's verify()
        # short-circuit, exercised deliberately by hop 6 below), and this
        # "final delivery" hop would silently collapse into a duplicate of
        # hop 6's "unchanged re-sign" scenario. The Subject tag keeps this
        # hop exercising a genuinely CHANGED (not added/removed) header --
        # coverage no other hop in this chain provides. Do not remove it.
        name     => 'final delivery',
        file     => 'tests/emails/brong-final.eml',
        domain   => 'test5.dkim2.com',
        selector => 'sel2',
        mailfrom => 'forwarder@test5.dkim2.com',
        rcptto   => ['brong@test1.dkim2.com'],
    },
);

# Strip all existing MI/DKIM2 headers from the base files
sub strip_msg {
    my $msg = shift;
    $msg->header_raw_set('Message-Instance');
    $msg->header_raw_set('DKIM2-Signature');
    $msg->header_raw_set('MailVersion');
    $msg->header_raw_set('Mail-Version');
    return $msg;
}

sub add_mi {
    my ($msg, $prev_msg) = @_;

    # Skip if the message already has an MI that matches current content
    if ( Mail::DKIM2::MessageInstance->verify($msg) ) {
        return undef;
    }

    my $mi = $prev_msg
        ? Mail::DKIM2::MessageInstance->calculate($msg, $prev_msg)
        : Mail::DKIM2::MessageInstance->calculate($msg);
    my $folded = fold_header("Message-Instance: " . $mi->as_string());
    $folded =~ s/^Message-Instance: //;
    $msg->header_raw_prepend('Message-Instance', $folded);
    return $mi;
}

# Fixed timestamp for reproducible output
my $TIMESTAMP = 1740000000;

sub sign_msg {
    my ($msg, $hop) = @_;
    my $signer = Mail::DKIM2::Signer->new(
        Domain    => $hop->{domain},
        Selector  => $hop->{selector},
        Key       => DKIM2TestKeys::private_key($hop->{domain}, $hop->{selector}),
        MailFrom  => $hop->{mailfrom},
        RcptTo    => $hop->{rcptto},
        Timestamp => $TIMESTAMP,
    );
    $signer->PRINT($msg->as_string());
    $signer->CLOSE;
    my $header = $signer->as_string();
    $header =~ s{^DKIM2-Signature:\s*}{};
    $msg->header_raw_prepend('DKIM2-Signature', $header);
    return $signer;
}

sub verify_msg {
    my ($msg) = @_;
    my $verifier = Mail::DKIM2::Verifier->new();
    $verifier->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $verifier->skip_timestamp_check(1);  # test emails have fixed timestamps
    $verifier->PRINT($msg->as_string());
    $verifier->CLOSE;
    return $verifier;
}

# ============================================================
# Phase 1: Build the full chain, verifying at each step
# ============================================================

diag("=== Building chain ===");

my $out_dir = 'tests/expected';
path($out_dir)->mkpath;

my $current_msg;

for my $i (0..$#hops) {
    my $hop = $hops[$i];
    my $label = "hop " . ($i + 1) . " ($hop->{name})";

    # Load the raw message for this hop
    my $raw = path($hop->{file})->slurp;
    my $msg = Email::MIME->new($raw);
    strip_msg($msg);

    if ($i == 0) {
        # First hop: calculate v=1 MI (no previous message)
        my $mi = add_mi($msg);
        ok($mi->get_tag('m') == 1, "$label: MI version is 1");
    } else {
        # Graft MI and DKIM2-Sig headers from the accumulated chain
        # onto this new message version
        my @mi_headers = $current_msg->header_raw('Message-Instance');
        my @dk2_headers = $current_msg->header_raw('DKIM2-Signature');

        # Prepend in reverse order (bottom-up, so first prepended = bottom)
        for my $h (reverse @dk2_headers) {
            $msg->header_raw_prepend('DKIM2-Signature', $h);
        }
        for my $h (reverse @mi_headers) {
            $msg->header_raw_prepend('Message-Instance', $h);
        }

        # Re-parse to get clean state
        $msg = Email::MIME->new($msg->as_string);

        # Calculate MI diff: $msg is the new version (with modified content
        # but same MI chain), $current_msg is the previous version
        my $mi = add_mi($msg, $current_msg);
        ok($mi->get_tag('m') == $i + 1, "$label: MI version is " . ($i + 1));
    }

    # Re-parse before signing (Email::MIME caching)
    $msg = Email::MIME->new($msg->as_string);

    # Verify MI hashes before signing
    my $mi_check = Mail::DKIM2::MessageInstance->verify($msg);
    ok($mi_check == $i + 1, "$label: MI verify passes at v=" . ($i + 1));

    # Sign
    sign_msg($msg, $hop);

    # Re-parse after signing
    $msg = Email::MIME->new($msg->as_string);

    # Verify the DKIM2 signature
    my $v = verify_msg($msg);
    is($v->result, 'pass', "$label: DKIM2-Signature verifies");

    # Count headers to make sure we accumulated correctly
    my @mi = $msg->header_raw('Message-Instance');
    my @dk2 = $msg->header_raw('DKIM2-Signature');
    is(scalar @mi, $i + 1, "$label: has " . ($i + 1) . " MI headers");
    is(scalar @dk2, $i + 1, "$label: has " . ($i + 1) . " DKIM2-Signature headers");

    # Write out each hop for cross-implementation testing
    my $hop_file = sprintf("%s/chain-hop%d-%s.eml", $out_dir, $i + 1, $hop->{name} =~ s/\s+/-/gr);
    path($hop_file)->spew($msg->as_string);

    $current_msg = $msg;
}

# ============================================================
# Phase 2: Full chain unwind — validate all MIs + sigs top-down
# ============================================================

diag("=== Full chain validation (unwind) ===");

{
    my $msg = Email::MIME->new($current_msg->as_string);

    my @mi = $msg->header_raw('Message-Instance');
    my @dk2 = $msg->header_raw('DKIM2-Signature');
    is(scalar @mi, 5, "final message has 5 MI headers");
    is(scalar @dk2, 5, "final message has 5 DKIM2-Signature headers");

    # Unwind from the top
    for my $step (reverse 1..5) {
        my $label = "unwind step $step";

        # Verify DKIM2 signature at current top
        my $v = verify_msg($msg);
        is($v->result, 'pass', "$label: DKIM2-Signature i=$step verifies");

        # Verify MI
        my $mi_check = Mail::DKIM2::MessageInstance->verify($msg);
        is($mi_check, $step, "$label: MI v=$step verifies");

        if ($step > 1) {
            # Remove top DKIM2-Signature
            my @dk2 = $msg->header_raw('DKIM2-Signature');
            $msg->header_raw_set('DKIM2-Signature',
                grep { $_ !~ /\bi=$step\b/ } @dk2);

            # Undo the MI
            Mail::DKIM2::MessageInstance->undo($msg);
            $msg = Email::MIME->new($msg->as_string);
        }
    }
}

# ============================================================
# Phase 3: Negative tests
# ============================================================

diag("=== Negative tests ===");

# Tamper with a header and verify MI fails
{
    my $msg = Email::MIME->new($current_msg->as_string);
    # Modify the Subject header
    $msg->header_raw_set('Subject', 'TAMPERED');
    $msg = Email::MIME->new($msg->as_string);

    my ($result, $error) = Mail::DKIM2::MessageInstance->verify($msg);
    is($result, 0, "MI verify returns 0 on tampered header");
    like($error, qr/header hash mismatch/, "MI verify reports hash mismatch");
}

# Tamper with the signature and verify DKIM2 fails
{
    my $msg = Email::MIME->new($current_msg->as_string);
    my @dk2 = $msg->header_raw('DKIM2-Signature');
    # Corrupt the s= tag by replacing its base64 content with different valid JSON
    # that has a garbage signature value
    my $bad_sigs = encode_base64(
        encode_json([["sel1", "rsa-sha256", "AAAA"]]), '');
    $dk2[0] =~ s/s=\S[\S\s]*$/s=$bad_sigs/;
    $msg->header_raw_set('DKIM2-Signature', @dk2);
    $msg = Email::MIME->new($msg->as_string);

    my $v = verify_msg($msg);
    isnt($v->result, 'pass', "DKIM2 verify fails on tampered signature");
}

# Remove a middle MI header and verify chain fails
{
    my $msg = Email::MIME->new($current_msg->as_string);
    my @mi = $msg->header_raw('Message-Instance');
    # Remove m=3
    my @filtered = grep { $_ !~ /^\s*m=3\b/ } @mi;
    $msg->header_raw_set('Message-Instance', @filtered);
    $msg = Email::MIME->new($msg->as_string);

    # Verifier should detect the gap (the signing input no longer matches
    # because the set of MI headers changed)
    my $v = verify_msg($msg);
    isnt($v->result, 'pass', "verifier detects missing MI m=3 in chain");
}

# ============================================================
# Phase 4: Unchanged message re-sign — no new MI added
# ============================================================

diag("=== Unchanged message re-sign ===");

{
    # Take the final 5-hop message and re-sign without modifications
    my $msg = Email::MIME->new($current_msg->as_string);

    my @mi_before = $msg->header_raw('Message-Instance');
    my @dk2_before = $msg->header_raw('DKIM2-Signature');
    is(scalar @mi_before, 5, "before re-sign: 5 MI headers");
    is(scalar @dk2_before, 5, "before re-sign: 5 DKIM2-Signature headers");

    # Verify the topmost MI still matches — message is unchanged
    my $mi_v = Mail::DKIM2::MessageInstance->verify($msg);
    ok($mi_v, "topmost MI still verifies (v=$mi_v)");

    # add_mi should return undef (skip) since message is unchanged
    my $mi = add_mi($msg);
    ok(!defined $mi, "add_mi returns undef for unchanged message");

    my @mi_after = $msg->header_raw('Message-Instance');
    is(scalar @mi_after, 5, "after add_mi: still 5 MI headers (no new MI added)");

    # Sign with a new hop — signature is added but MI count stays the same
    my $hop6 = {
        name     => 'unchanged re-sign',
        domain   => 'test1.dkim2.com',
        selector => 'sel1',
        mailfrom => 'relay@test1.dkim2.com',
        rcptto   => ['dest@test2.dkim2.com'],
    };
    sign_msg($msg, $hop6);
    $msg = Email::MIME->new($msg->as_string);

    my @mi_final = $msg->header_raw('Message-Instance');
    my @dk2_final = $msg->header_raw('DKIM2-Signature');
    is(scalar @mi_final, 5, "after re-sign: still 5 MI headers");
    is(scalar @dk2_final, 6, "after re-sign: 6 DKIM2-Signature headers");

    # Full chain should still verify
    my $v = verify_msg($msg);
    diag("re-sign result: " . $v->result_detail()) unless $v->result eq 'pass';
    is($v->result, 'pass', "full chain still verifies after unchanged re-sign");

    path("$out_dir/chain-hop6-unchanged-re-sign.eml")->spew($msg->as_string);
}

# ============================================================
# Phase 5: UseEpilogue — body-changing transitions
# ============================================================

diag("=== UseEpilogue body recipe tests ===");

# Normalize a raw body to the form undo() produces: split by line, rejoin
# with CRLF, single trailing CRLF.  Allows comparison independent of
# how many blank lines trail the original multipart body.
sub normalize_body {
    my $b = shift;
    return join("\r\n", split(/\r?\n/, $b), '');
}

# Helper: build a minimal one-hop message with a v=1 MI header.
sub make_v1_msg {
    my ($file) = @_;
    my $msg = Email::MIME->new(path($file)->slurp);
    strip_msg($msg);
    my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
    my $folded = fold_header("Message-Instance: " . $mi->as_string());
    $folded =~ s/^Message-Instance: //;
    $msg->header_raw_prepend('Message-Instance', $folded);
    return Email::MIME->new($msg->as_string);
}

# For each hop pair where the body actually changes, verify that:
#   1. calculate(..., UseEpilogue => 1) sets an rb Recipe
#   2. MI verifies on the modified (epilogue-carrying) message
#   3. undo() restores the exact previous body
for my $i (1..$#hops) {
    my $label = "UseEpilogue hop $i->".($i+1)." ($hops[$i]{name})";

    # Build a clean previous message with a v=1 MI
    my $prev = make_v1_msg($hops[$i-1]{file});
    my $prev_body = $prev->body_raw;

    # Build the current message and graft the previous MI headers onto it
    my $cur = Email::MIME->new(path($hops[$i]{file})->slurp);
    strip_msg($cur);
    for my $h (reverse $prev->header_raw('Message-Instance')) {
        $cur->header_raw_prepend('Message-Instance', $h);
    }
    $cur = Email::MIME->new($cur->as_string);

    my $cur_body = $cur->body_raw;
    if ($cur_body eq $prev_body) {
        pass("$label: body unchanged, skipping epilogue test");
        next;
    }

    # Calculate MI with UseEpilogue — modifies $cur in place
    my $mi = Mail::DKIM2::MessageInstance->calculate(
        $cur, $prev, UseEpilogue => 1,
    );
    ok($mi->get_tag('rb'), "$label: rb recipe present");

    # Add the MI header to the now-modified (epilogue-carrying) message
    my $folded = fold_header("Message-Instance: " . $mi->as_string());
    $folded =~ s/^Message-Instance: //;
    $cur->header_raw_prepend('Message-Instance', $folded);
    $cur = Email::MIME->new($cur->as_string);

    # MI must verify against the epilogue-carrying body
    my $v = Mail::DKIM2::MessageInstance->verify($cur);
    ok($v, "$label: MI verifies on epilogue-carrying message (v=$v)");

    # undo() must restore the previous body.  undo() normalizes trailing
    # CRLF via split/join, so compare against the normalized form.
    my $restored = Mail::DKIM2::MessageInstance->undo(
        Email::MIME->new($cur->as_string)
    );
    is($restored->body_raw, normalize_body($prev_body),
        "$label: undo restores previous body");
}

# ============================================================
# Phase 6: UseEpilogue long chain
#
# Build a chain where every body-changing hop uses UseEpilogue.
# Each new hop's message has the previous version's body in its
# MIME epilogue (and any header changes in rh).  Unwind from the
# top and verify the body is restored at every step.
# ============================================================

diag("=== UseEpilogue long chain ===");

{
    # Accumulate messages hop by hop, using UseEpilogue when the body changes.
    my @chain_msgs;   # one per hop, in order
    my @chain_bodies; # original body (normalized) of each hop, for comparison

    my $prev_msg;

    for my $i (0..$#hops) {
        my $hop   = $hops[$i];
        my $label = "epilogue chain hop " . ($i + 1) . " ($hop->{name})";

        my $msg = Email::MIME->new(path($hop->{file})->slurp);
        strip_msg($msg);

        if ($i == 0) {
            # First hop: no previous, plain v=1 MI.
            my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
            my $folded = fold_header("Message-Instance: " . $mi->as_string());
            $folded =~ s/^Message-Instance: //;
            $msg->header_raw_prepend('Message-Instance', $folded);
            $msg = Email::MIME->new($msg->as_string);
        } else {
            # Graft accumulated MI headers onto the new message.
            for my $h (reverse $prev_msg->header_raw('Message-Instance')) {
                $msg->header_raw_prepend('Message-Instance', $h);
            }
            $msg = Email::MIME->new($msg->as_string);

            my $body_changed = ($msg->body_raw ne $prev_msg->body_raw);

            my $mi;
            if ($body_changed) {
                $mi = Mail::DKIM2::MessageInstance->calculate(
                    $msg, $prev_msg, UseEpilogue => 1
                );
                ok($mi->get_tag('rb'), "$label: UseEpilogue set rb recipe");
            } else {
                $mi = Mail::DKIM2::MessageInstance->calculate($msg, $prev_msg);
            }
            ok($mi->get_tag('m') == $i + 1, "$label: MI version is " . ($i + 1));

            my $folded = fold_header("Message-Instance: " . $mi->as_string());
            $folded =~ s/^Message-Instance: //;
            $msg->header_raw_prepend('Message-Instance', $folded);
            $msg = Email::MIME->new($msg->as_string);
        }

        my $v = Mail::DKIM2::MessageInstance->verify($msg);
        ok($v == $i + 1, "$label: MI v=" . ($i + 1) . " verifies");

        push @chain_msgs,   $msg;
        push @chain_bodies, normalize_body($msg->body_raw);
        $prev_msg = $msg;
    }

    # Now unwind from the top, checking body restoration at each step.
    my $msg = Email::MIME->new($chain_msgs[-1]->as_string);
    for my $step (reverse 1..$#hops) {
        my $label = "epilogue chain unwind to hop $step";

        # Undo the top MI
        $msg = Mail::DKIM2::MessageInstance->undo($msg);
        $msg = Email::MIME->new($msg->as_string);

        my $v = Mail::DKIM2::MessageInstance->verify($msg);
        ok($v == $step, "$label: MI v=$step verifies after undo");

        is(normalize_body($msg->body_raw), $chain_bodies[$step - 1],
            "$label: body matches hop $step original");
    }
}

# ============================================================
# Phase 7: EpilogueThreshold
#
# EpilogueThreshold => N: use epilogue when the diff would produce
# more than N literal (non-range) lines.
#   Threshold=0  => always epilogue for any body change
#   Threshold=99999 => always diff (same as no option)
# ============================================================

diag("=== EpilogueThreshold tests ===");

for my $i (1..$#hops) {
    my $label_base = "EpilogueThreshold hop $i->".($i+1)." ($hops[$i]{name})";

    # Build clean v=1 previous message
    my $prev = make_v1_msg($hops[$i-1]{file});
    my $prev_body = $prev->body_raw;

    # Build current message with previous MI headers grafted on
    my $make_cur = sub {
        my $cur = Email::MIME->new(path($hops[$i]{file})->slurp);
        strip_msg($cur);
        for my $h (reverse $prev->header_raw('Message-Instance')) {
            $cur->header_raw_prepend('Message-Instance', $h);
        }
        return Email::MIME->new($cur->as_string);
    };

    my $cur_body = $make_cur->()->body_raw;
    if ($cur_body eq $prev_body) {
        pass("$label_base: body unchanged, skipping epilogue threshold test");
        pass("$label_base: body unchanged, skipping default diff test");
        next;
    }

    # --- Threshold=0: every body change triggers epilogue ---
    {
        my $cur = $make_cur->();
        my $mi = Mail::DKIM2::MessageInstance->calculate(
            $cur, $prev, EpilogueThreshold => 0,
        );
        ok($mi->get_tag('rb'), "$label_base threshold=0: rb recipe present (epilogue)");

        my $folded = fold_header("Message-Instance: " . $mi->as_string());
        $folded =~ s/^Message-Instance: //;
        $cur->header_raw_prepend('Message-Instance', $folded);
        $cur = Email::MIME->new($cur->as_string);

        my $v = Mail::DKIM2::MessageInstance->verify($cur);
        ok($v, "$label_base threshold=0: MI verifies (v=$v)");

        my $restored = Mail::DKIM2::MessageInstance->undo(
            Email::MIME->new($cur->as_string)
        );
        is($restored->body_raw, normalize_body($prev_body),
            "$label_base threshold=0: undo restores previous body");
    }

    # --- No option (default): diff always used ---
    {
        my $cur = $make_cur->();
        my $orig_body = $cur->body_raw;
        my $mi = Mail::DKIM2::MessageInstance->calculate($cur, $prev);

        # Body of $cur must not have been modified (no epilogue added)
        is($cur->body_raw, $orig_body,
            "$label_base default: cur body not modified (diff used)");

        my $folded = fold_header("Message-Instance: " . $mi->as_string());
        $folded =~ s/^Message-Instance: //;
        $cur->header_raw_prepend('Message-Instance', $folded);
        $cur = Email::MIME->new($cur->as_string);

        my $v = Mail::DKIM2::MessageInstance->verify($cur);
        ok($v, "$label_base default: MI verifies (v=$v)");

        my $restored = Mail::DKIM2::MessageInstance->undo(
            Email::MIME->new($cur->as_string)
        );
        is($restored->body_raw, normalize_body($prev_body),
            "$label_base default: undo restores previous body");
    }
}

done_testing();
