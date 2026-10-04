#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use lib 'lib';
use Email::MIME;
use Mail::DKIM2::MessageInstance;

# Build a 2-instance chain: m=1 over the original, then append a footer and
# record m=2 as a diff against m=1.
my $orig = "From: a\@example.com\r\nSubject: hi\r\n\r\nbody line\r\n";
my $mi1  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($orig));
my $with1 = "Message-Instance: " . $mi1->as_string . "\r\n" . $orig;

my $cur = Email::MIME->new($with1);
$cur->body_set($cur->body_raw . "footer line\r\n");

# --- good chain: m=2 carries a diff Recipe that reverses to m=1 ---
{
    my $good = Email::MIME->new($cur->as_string);
    my $mi2  = Mail::DKIM2::MessageInstance->calculate($good, Email::MIME->new($with1));
    $good->header_raw_prepend('Message-Instance', $mi2->as_string);
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($good->as_string);
    ok($ok, 'reversible chain verifies') or diag($why);
}

# --- single instance: trivially verifies (nothing to undo) ---
{
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($with1);
    ok($ok, 'single Message-Instance verifies') or diag($why);
}

# --- no Message-Instance at all: nothing to check ---
{
    my ($ok) = Mail::DKIM2::MessageInstance->chain_verifies($orig);
    ok($ok, 'message with no MI passes (nothing to undo)');
}

# --- broken chain: m=2 records NO Recipe, so undo cannot rebuild the body and
#     the reconstruction no longer matches m=1 ---
{
    my $bad = Email::MIME->new($cur->as_string);
    # Hand-build m=2 with the modified content's hashes but no r= Recipe.
    my $hh = Mail::DKIM2::MessageInstance::h_digest($bad);
    my $bh = Mail::DKIM2::MessageInstance::b_digest($bad);
    $bad->header_raw_prepend('Message-Instance', "m=2; h=sha256:$hh:$bh;");
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($bad->as_string);
    ok(!$ok, 'non-reversible chain is rejected');
    like($why, qr/m=1 does not match|did not undo/, 'failure names the broken instance');
}

# --- Recipe-less m=2 over UNCHANGED content: legal, and must be accepted ---
#     An instance with no r= asserts no change.  We never emit one (an
#     unmodified hop reuses the existing m= per §9.1/§9.2.5), but an upstream
#     may, and rejecting it would break the chain for no reason.
{
    my $same = Email::MIME->new($with1);
    my $hh = Mail::DKIM2::MessageInstance::h_digest($same);
    my $bh = Mail::DKIM2::MessageInstance::b_digest($same);
    $same->header_raw_prepend('Message-Instance', "m=2; h=sha256:$hh:$bh;");
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($same->as_string);
    ok($ok, 'recipe-less instance asserting no change is accepted') or diag($why);
}

done_testing;
