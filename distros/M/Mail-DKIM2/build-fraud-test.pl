#!/usr/bin/perl -w
# Build chain-of-custody test vectors into tests/expected/.  Each forged
# message has a TOP instance (m=2) whose hashes are correct AND whose signature
# is valid; only the recipe lies, so reconstructing m=1 fails its hash check.
# Consumed by t/fraud-detection.t; also used as hand-off vectors for hosted
# verifiers (socketlabs, dkim2.eu).
#
#   chain-fraud-control.eml        honest recipe; whole chain validates.
#   chain-fraud-header.eml         recipe omits an added Reply-To (header lie).
#   chain-fraud-body.eml           body changed, recipe declares no body change.
#   chain-fraud-body-truncate.eml  innocent-looking "drop trailing block" copy-
#                                  range recipe that hides an edited first line.
#   chain-fraud-mi-rewrite.eml     content replaced wholesale; the recipe
#                                  declares no content change but rewrites
#                                  the m=1 Message-Instance to one hashed over
#                                  the new content (a forged history).
#   chain-fraud-mi-rewrite-wsp.eml the same under the key "message-instance "
#                                  (not a field name: invalid JSON).
#
# All signed d=test1.dkim2.com s=sel1 (real DNS published) with NO
# Authentication-Results / Delivered-To, so the only thing that can trip a
# verifier is the recipe reconstruction.

use 5.020;
use strict;
use Path::Tiny;
use Email::MIME;
use lib 'lib';
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use JSON::PP;

sub crlf { my $s = shift; $s =~ s/\r?\n/\r\n/g; return $s }

# ---- Original message (state O) --------------------------------------------
my $body = crlf(<<'EOB');
Please reply to me directly with your thoughts.
EOB

my $orig = Email::MIME->new(crlf(<<'EOH') . "\r\n" . $body);
Date: Tue, 08 Jul 2026 10:00:00 +0000
To: user@test3.dkim2.com
From: alice@test1.dkim2.com
Subject: chain-of-custody forgery test
Message-Id: <orig.20260708@test1.dkim2.com>
EOH

# m=1 Message-Instance over the original.
my $mi1 = Mail::DKIM2::MessageInstance->calculate($orig);
(my $mi1s = "Message-Instance: " . $mi1->as_string()) =~ s/^Message-Instance: //;
$orig->header_raw_prepend('Message-Instance', $mi1s);
# $orig now == "O with m=1 MI" (this is our chain-hop1 / previous state).

# ---- Modified message (state C): a hop adds List-Id and Reply-To -----------
sub make_current {
    my $c = Email::MIME->new($orig->as_string);
    # header_raw_prepend puts these at the top; they are new (absent from O).
    $c->header_raw_prepend('Reply-To', 'attacker@evil.example');
    $c->header_raw_prepend('List-Id', '<test.list.test1.dkim2.com>');
    return $c;
}

sub sign_and_write {
    my ($current, $file) = @_;
    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'test1.dkim2.com',
        Selector => 'sel1',
        KeyFile  => '../keys/sel1._domainkey.test1.dkim2.com.pem',
        Algorithm=> 'rsa-sha256',
        Timestamp=> 1783372800,
        MailFrom => 'bounce@test1.dkim2.com',
        RcptTo   => ['user@test3.dkim2.com'],
    );
    $signer->PRINT($current->as_string());
    $signer->CLOSE;
    (my $sig = $signer->as_string()) =~ s/^DKIM2-Signature:\s*//;
    $current->header_raw_prepend('DKIM2-Signature', $sig);
    path("tests/expected/$file")->spew_raw($current->as_string());
    say "wrote tests/expected/$file";
}

# ---- CONTROL: honest recipe ------------------------------------------------
{
    my $c = make_current();
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($c, $orig);
    say "honest recipe rh keys: ", join(",", sort keys %{ $mi2->{bits}{rh} // {} });
    (my $s = "Message-Instance: " . $mi2->as_string()) =~ s/^Message-Instance: //;
    $c->header_raw_prepend('Message-Instance', $s);
    sign_and_write($c, 'chain-fraud-control.eml');
}

# ---- FRAUD (header): lying recipe drops the reply-to entry -----------------
{
    my $c = make_current();
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($c, $orig);
    delete $mi2->{bits}{rh}{'reply-to'};   # <-- the lie: undeclared Reply-To
    say "fraud-header recipe rh keys: ", join(",", sort keys %{ $mi2->{bits}{rh} // {} });
    (my $s = "Message-Instance: " . $mi2->as_string()) =~ s/^Message-Instance: //;
    $c->header_raw_prepend('Message-Instance', $s);
    sign_and_write($c, 'chain-fraud-header.eml');
}

# ---- FRAUD (body): body content changed, recipe claims it was NOT ----------
# A hop rewrites the body (e.g. swaps payment details) but declares no body
# recipe, so reconstructing m=1 leaves the tampered body and its body hash no
# longer matches the signed m=1 body hash.  The "ideal" forgery: the top MI
# body hash is genuinely correct for the tampered body AND validly signed;
# only the recipe lies about the body being unchanged.
{
    my $c = Email::MIME->new($orig->as_string);       # O + m=1 MI
    $c->body_set(crlf("Please send payment to account EVIL-9999 instead.\r\n"));
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($c, $orig);
    # calculate() produced a body recipe (rb) that would rebuild the old body.
    # The lie: delete it so the recipe claims the body never changed.
    delete $mi2->{bits}{rb};
    say "fraud-body has body recipe after tamper: ",
        (exists $mi2->{bits}{rb} ? "yes" : "no (lie)");
    (my $s = "Message-Instance: " . $mi2->as_string()) =~ s/^Message-Instance: //;
    $c->header_raw_prepend('Message-Instance', $s);
    sign_and_write($c, 'chain-fraud-body.eml');
}

# ---- FRAUD (body, sneaky): truncating copy-range recipe --------------------
# The recipe DOES describe a body change (so "changed hash but no body recipe"
# is not enough to catch it): it says "the trailing signature/footer block was
# added, drop it to recover the previous body" -> rb = [ {"c":[1,1]} ].  That
# is exactly what an honest footer-append would look like.  The lie: the hop
# ALSO rewrote line 1 (GOOD -> EVIL).  Copying current line 1 reproduces the
# tampered line, so the reconstructed m=1 body hash != the signed m=1 hash.
# Only a verifier that actually APPLIES the recipe and re-hashes notices; one
# that trusts a plausible-looking recipe does not.  The appended sig block is
# the cover story — the signature the recipe "cuts off".
{
    my $o2 = Email::MIME->new(crlf(<<'EOH2') . "\r\n" . crlf("Pay account GOOD-0001\r\n"));
Date: Tue, 08 Jul 2026 10:00:00 +0000
To: user@test3.dkim2.com
From: alice@test1.dkim2.com
Subject: invoice
Message-Id: <inv.20260708@test1.dkim2.com>
EOH2
    my $m1 = Mail::DKIM2::MessageInstance->calculate($o2);
    (my $m1s = "Message-Instance: " . $m1->as_string()) =~ s/^Message-Instance: //;
    $o2->header_raw_prepend('Message-Instance', $m1s);

    my $c = Email::MIME->new($o2->as_string);
    # attacker rewrites line 1 AND appends a plausible signature block:
    $c->body_set(crlf("Pay account EVIL-9999\r\n-- \r\nAlice <alice\@test1.dkim2.com>\r\n"));
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($c, $o2);
    # Overwrite the honest diff with the innocent-looking "drop the footer"
    # recipe: copy only current line 1.  h1/b1 (hashes of the delivered body)
    # stay correct, so the TOP MI still passes.
    $mi2->{bits}{rb} = [ [1, 1] ];
    delete $mi2->{bits}{rh};   # no header changes to declare
    say "fraud-body-truncate rb = [[1,1]] (\"drop trailing signature block\")";
    (my $s = "Message-Instance: " . $mi2->as_string()) =~ s/^Message-Instance: //;
    $c->header_raw_prepend('Message-Instance', $s);
    sign_and_write($c, 'chain-fraud-body-truncate.eml');
}

# ---- FRAUD (history): a header Recipe that rewrites Message-Instance --------
# The hop replaces headers and body wholesale, declares no content change, and
# instead names message-instance in its header Recipe with a literal m=1 hashed
# over the NEW content. A verifier that re-reads the instances from the rebuilt
# message checks m=1 against the forgery and reports the original as unchanged.
# Message-Instance and DKIM2-Signature fields are never content (-09 section
# 6.2): a Recipe naming them acts on content fields of that name, of which
# there are none, so the received m=1 still governs and its header hash fails.
{
    my $c = Email::MIME->new(crlf(<<'EOH3') . "\r\n" . crlf("Please wire \$1M to account 666\r\n"));
Date: Tue, 08 Jul 2026 10:00:00 +0000
To: victim@example.org
From: alice@test1.dkim2.com
Subject: URGENT wire money
Message-Id: <evil.20260708@test1.dkim2.com>
EOH3
    my $forged = Mail::DKIM2::MessageInstance->calculate($c)->as_string;
    $c->header_raw_prepend('Message-Instance', $mi1s);   # the genuine m=1
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($c, $c);
    delete $mi2->{bits}{rb};
    $mi2->{bits}{rh} = { 'message-instance' => [ " $forged" ] };
    say "fraud-mi-rewrite rh = { message-instance => [forged m=1] }";
    (my $s = "Message-Instance: " . $mi2->as_string()) =~ s/^Message-Instance: //;
    my $c2 = Email::MIME->new($c->as_string);
    $c->header_raw_prepend('Message-Instance', $s);
    sign_and_write($c, 'chain-fraud-mi-rewrite.eml');

    # The same under a key with WSP in it, "message-instance ": no field
    # name, so invalid JSON -- where name matching that drops WSP before a
    # colon would take it for Message-Instance.
    $mi2->{bits}{rh} = { 'message-instance ' => [ " $forged" ] };
    (my $s2 = "Message-Instance: " . $mi2->as_string()) =~ s/^Message-Instance: //;
    $c2->header_raw_prepend('Message-Instance', $s2);
    sign_and_write($c2, 'chain-fraud-mi-rewrite-wsp.eml');
}
