#!/usr/bin/perl
# A null body Recipe ("b": null) loses the previous body, not the header
# history: every lower instance's header hashes are still checked, by undoing
# header Recipes only, down to m=1.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mail::DKIM2::MessageInstance;

my $MI = 'Mail::DKIM2::MessageInstance';
my $EOL = "\r\n";

sub with_mi { my ($mi, $msg) = @_; "Message-Instance: " . $mi->as_string . $EOL . $msg }

my $orig = join($EOL, 'From: a@example.com', 'To: list@example.org',
    'Subject: hello', 'Message-ID: <x@example.com>', '', 'body one', 'body two', '');
my $m1 = with_mi($MI->calculate($orig), $orig);

# m=2: the list prefixed the Subject and rewrote the body; body Recipe null.
sub list_hop {
    my ($prev, $tag) = @_;
    my $cur = $prev;
    $cur =~ s/^Subject: /Subject: [$tag] /m;
    $cur .= "rewritten by $tag$EOL";
    my $mi = $MI->calculate($cur, $prev);
    $mi->set_null_body_recipe;
    return with_mi($mi, $cur);
}

{
    my $m2 = list_hop($m1, 'list');
    my ($ok, $why) = $MI->chain_verifies($m2);
    ok($ok, 'null at m=2 over m=1: header history verifies') or diag $why;
}

# A forged history: the list changed To as well as Subject, but its header
# Recipe hides the To change. The top instance matches the message; only
# undoing it shows m=1's header hash no longer matches. DKIM2-Signatures
# cover only Message-Instance and DKIM2-Signature fields (§9.6), so
# nothing else catches this.
sub forge_history {
    my ($prev) = @_;
    my $cur = $prev;
    $cur =~ s/^Subject: /Subject: [list] /m;
    $cur =~ s/^To: list\@example\.org/To: other\@example.org/m;
    $cur .= "rewritten$EOL";
    my $mi = $MI->calculate($cur, $prev);
    $mi->set_null_body_recipe;
    my $rh = $mi->{bits}{rh};
    delete $rh->{$_} for grep { lc($_) eq 'to' } keys %$rh;
    return with_mi($mi, $cur);
}

{
    my ($ok, $why) = $MI->chain_verifies(forge_history($m1));
    ok(!$ok, 'header changed below a null body Recipe is caught');
    like($why // '', qr/m=1 does not match content.*header hash/, 'reason names m=1 header hash');
}

{
    # null at m=3 over a normal m=2 over m=1
    my $cur2 = $m1; $cur2 =~ s/^Subject: /Subject: [fwd] /m;
    my $m2 = with_mi($MI->calculate($cur2, $m1), $cur2);
    my $m3 = list_hop($m2, 'list');
    my ($ok, $why) = $MI->chain_verifies($m3);
    ok($ok, 'null at m=3 over recipe m=2 over m=1 verifies') or diag $why;
}

{
    # A body Recipe below the null must not be applied (the body it would
    # apply to is gone): m=2 appends a footer with a real body Recipe, m=3
    # rewrites the body with a null one.
    my $cur2 = $m1 . "footer$EOL";
    my $m2 = with_mi($MI->calculate($cur2, $m1), $cur2);
    my $m3 = list_hop($m2, 'list');
    my ($ok, $why) = $MI->chain_verifies($m3);
    ok($ok, 'body Recipe below a null instance is skipped, headers still checked') or diag $why;
}

# A header Recipe below the null that does not apply at all: m=2's Subject
# Recipe copies a Subject instance the message does not have. Its hashes
# match its own message, so only applying the Recipe shows the history is
# broken -- that must fail the chain, not be skipped like the body Recipe.
sub bad_header_recipe_below_null {
    my ($prev) = @_;
    my $cur2 = $prev; $cur2 =~ s/^Subject: /Subject: [fwd] /m;
    my $mi2 = $MI->calculate($cur2, $prev);
    $mi2->{bits}{rh}{subject} = [[5, 5]];
    return list_hop(with_mi($mi2, $cur2), 'list');
}

{
    my ($ok, $why) = $MI->chain_verifies(bad_header_recipe_below_null($m1));
    ok(!$ok, 'header Recipe that does not apply below a null body Recipe is caught');
    like($why // '', qr/m=2 did not undo cleanly.*copies lines 5-5 of 1/,
        'reason names the m=2 header Recipe') or diag $why;
}

{
    # verify / undo HeadersOnly directly
    my $m2 = list_hop($m1, 'list');
    my $prev = $MI->undo($m2, HeadersOnly => 1);
    ok($prev, 'undo HeadersOnly returns a message');
    like($prev->body_raw, qr/rewritten by list/, 'body left as it is (not rebuilt)');
    is(scalar $MI->verify($prev, HeadersOnly => 1), 1, 'verify HeadersOnly passes m=1 on header history');
    is(scalar $MI->verify($prev), 0, 'full verify fails m=1 (body differs)');
}

# Null BELOW an ordinary instance: m=3 header-only over m=2 null over m=1.
sub ordinary_hop {
    my ($prev, $hide_to) = @_;
    my $cur = $prev;
    $cur =~ s/^Subject: /Subject: [top] /m;
    $cur =~ s/^To: list\@example\.org/To: other\@example.org/m if $hide_to;
    my $mi = $MI->calculate($cur, $prev);
    if ($hide_to) {
        my $rh = $mi->{bits}{rh};
        delete $rh->{$_} for grep { lc($_) eq 'to' } keys %$rh;
    }
    return with_mi($mi, $cur);
}

{
    my $m3 = ordinary_hop(list_hop($m1, 'list'));
    my ($ok, $why) = $MI->chain_verifies($m3);
    ok($ok, 'ordinary m=3 over null m=2 over m=1 verifies') or diag $why;

    ($ok, $why) = $MI->chain_verifies(ordinary_hop(list_hop($m1, 'list'), 1));
    ok(!$ok, 'hidden To change in m=3 header Recipe over null m=2 is caught');
    like($why // '', qr/m=2 does not match content.*header hash/, 'reason names the failing header hash') or diag $why;
}

{
    # forged variant of the above where the hidden change is in the null instance's own header Recipe
    my $m3 = ordinary_hop(forge_history($m1));
    my ($ok, $why) = $MI->chain_verifies($m3);
    ok(!$ok, 'hidden To change in null m=2 header Recipe, ordinary m=3 above, is caught');
    like($why // '', qr/m=1 does not match content.*header hash/, 'reason names m=1 header hash') or diag $why;
}

# Empty-body chain: no body at all, header-only Recipe at m=2.
my $empty = join($EOL, 'From: a@example.com', 'To: list@example.org',
    'Subject: hello', 'Message-ID: <x@example.com>', '', '');
my $e1 = with_mi($MI->calculate($empty), $empty);
{
    my ($ok, $why) = $MI->chain_verifies(ordinary_hop($e1));
    ok($ok, 'empty-body chain, header-only m=2 verifies') or diag $why;
    ($ok, $why) = $MI->chain_verifies(ordinary_hop($e1, 1));
    ok(!$ok, 'empty-body chain, hidden To change fails');
    like($why // '', qr/m=1 does not match content.*header hash/, 'empty-body: reason names m=1 header hash') or diag $why;
}

# Recipe structure is checked even where the body is gone: m=2 has a body
# Recipe with descending copy ranges, m=3 a null one.
sub malformed_body_below_null {
    my ($prev) = @_;
    my $cur2 = $prev . "footer$EOL";
    my $mi2 = $MI->calculate($cur2, $prev);
    $mi2->{bits}{rb} = [[2, 2], [1, 1]];
    return list_hop(with_mi($mi2, $cur2), 'list');
}

{
    my ($ok, $why) = $MI->chain_verifies(malformed_body_below_null($m1));
    ok(!$ok, 'malformed body Recipe below a null body Recipe is caught');
    like($why // '', qr/m=2 did not undo cleanly.*out of order/, 'reason names the malformed body Recipe') or diag $why;
}

# The structure-only check below a null has no line count: a bad range must
# read sensibly (no dangling "of ") and must not warn.
for my $range ([0, 2], [3, 1]) {
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $cur2 = $m1 . "footer$EOL";
    my $mi2 = $MI->calculate($cur2, $m1);
    $mi2->{bits}{rb} = [$range];
    my ($ok, $why) = $MI->chain_verifies(list_hop(with_mi($mi2, $cur2), 'list'));
    my $r = "[@$range]";
    ok(!$ok, "body Recipe $r below a null is caught");
    unlike($why // '', qr/\bof\s*(?:$|\))/, "$r: no empty 'of' in reason") or diag $why;
    like($why // '', qr/m=2 did not undo cleanly.*\Q$range->[0]-$range->[1]\E/, "$r: reason names the range") or diag $why;
    is_deeply(\@warn, [], "$r: no warnings") or diag @warn;
}

use lib "$FindBin::Bin/lib";
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $signed_m1;
sub sign_i1 {
    my ($msg) = @_;
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'rsa1024',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['list@test2.dkim2.com'],
        Timestamp => 1740000000);
    $s->PRINT($msg); $s->CLOSE;
    return $s->as_string . $EOL . $msg;
}

sub verifier_result {
    my ($msg) = @_;
    my $v = Mail::DKIM2::Verifier->new;
    $v->allow_unsigned_mi(1);
    $v->skip_timestamp_check(1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->PRINT($msg); $v->CLOSE;
    return $v->result_detail;
}

{
    my $signed = sign_i1($m1);
    my $m2 = list_hop($signed, 'list');
    like(verifier_result($m2), qr/^pass/, 'Verifier: null body over signed m=1 passes');

    $signed_m1 = $signed;
    my $forged = forge_history($signed);
    like(verifier_result($forged), qr/^fail.*m=1 does not match content/, 'Verifier: tampered history below null fails on m=1');

    like(verifier_result(bad_header_recipe_below_null($signed)), qr/^fail.*m=2 did not undo cleanly/,
        'Verifier: header Recipe that does not apply below null fails');
}

{
    my $v = verifier_result(malformed_body_below_null($signed_m1));
    unlike($v, qr/^pass/, 'Verifier: malformed body Recipe below null is not a pass');
}

done_testing;
