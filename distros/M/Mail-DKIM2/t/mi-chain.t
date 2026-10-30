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
    like($why, qr/\APERMERROR: Message-Instance m=2 contains invalid JSON\z|\AFAIL: Message-Instance m=1 (?:header|body) hash sha256 mismatch\z/, 'failure names the broken instance');
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

# --- -08 §12.1: a first instance may carry Recipes (ruling 17) ---
# A list host that stamped an unsigned m=1 on arrival, then changed the post
# (a From munge, a footer), sends it as ONE m=1: hashes of what it sends and
# Recipes back to the message as it arrived.
{
    my $arrived = "From: Author <a\@example.com>\r\nSubject: hi\r\n\r\nbody line\r\n";
    my $sent    = "From: Author via list <list\@example.net>\r\nReply-To: a\@example.com\r\n"
                . "Subject: [list] hi\r\n\r\nbody line\r\nfooter\r\n";

    # calculate() with a previous message and no instances on either: m=1.
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($sent), Email::MIME->new($arrived));
    is($mi->get_tag('m'), 1, 'calculate: no instances on either gives m=1');
    ok($mi->get_tag('rh') && $mi->get_tag('rb'), 'calculate: that m=1 carries header and body Recipes');
    my $out = "Message-Instance: " . $mi->as_string . "\r\n" . $sent;
    ok(scalar Mail::DKIM2::MessageInstance->verify($out), 'calculate: the m=1 matches what is sent');
    my $undone = Mail::DKIM2::MessageInstance->undo($out);
    is($undone->header('From'), 'Author <a@example.com>', 'calculate: undo restores the From');
    is($undone->body_raw, "body line\r\n", 'calculate: undo restores the body');

    # calculate_first(): the arrival snapshot carries the stamped m=1 and a
    # local m=2 (a wrap); the message carries both, unchanged. The result is
    # m=1 back to the message before its first instance.
    my $s1  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($arrived));
    my $st1 = "Message-Instance: " . $s1->as_string . "\r\n" . $arrived;
    (my $wrapped = $st1) =~ s/body line/wrapped line/;
    my $s2  = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($wrapped), Email::MIME->new($st1));
    my $snap = "Message-Instance: " . $s2->as_string . "\r\n" . $wrapped;
    (my $listed = $snap) =~ s/^From: [^\r\n]*/From: Author via list <list\@example.net>/m;
    $listed .= "footer\r\n";
    my $first = Mail::DKIM2::MessageInstance->calculate_first($listed, $snap);
    is($first->get_tag('m'), 1, 'calculate_first: m=1');
    my $sent2 = "Message-Instance: " . $first->as_string . "\r\n"
              . ($listed =~ s/^Message-Instance:[^\r\n]*\r\n(?:[ \t][^\r\n]*\r\n)*//mgr);
    ok(scalar Mail::DKIM2::MessageInstance->verify($sent2), 'calculate_first: matches the message less its instances');
    my $back = Mail::DKIM2::MessageInstance->undo($sent2);
    is($back->header('From'), 'Author <a@example.com>', 'calculate_first: undo restores the arrival From');
    is($back->body_raw, "body line\r\n", 'calculate_first: undo goes back past the wrap');
    ok(!$back->header_raw('Message-Instance'), 'calculate_first: nothing left to undo');

    # A previous message whose chain does not undo is refused.
    (my $bad = $snap) =~ s/wrapped line/tampered line/;
    ok(!eval { Mail::DKIM2::MessageInstance->calculate_first($listed, $bad); 1 },
       'calculate_first: a previous message whose chain does not verify is refused');
}

done_testing;
