#!/usr/bin/perl -w
#
# Recipe copy ranges must ascend: across the "c" steps of one Recipe, each
# start is greater than the previous end (-08 section 5.1 says so for
# header Recipes; the agreed extension applies the same rule to body
# Recipes). Together with 1 <= start <= end <= count, that is the whole
# well-formedness rule for "c". A Recipe that breaks it is malformed and
# the instance does not verify -- and the Verifier reports that as a
# result, never as an exception.
#
# Bounds are JSON integers (schema); a JSON string such as "1" is malformed,
# as every other verifier in the interop set already holds.
#
# On the producing side, calculate() must never emit such a Recipe. A hop
# that reorders header instances makes the next matched index lower than
# the last range's end; that value goes in literally.

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use JSON;
use MIME::Base64 qw(encode_base64 decode_base64);
use lib 'lib', 't/lib';

use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

sub sign_hop {
    my ($msg, %hop) = @_;
    my $signer = Mail::DKIM2::Signer->new(
        Domain   => $hop{domain},
        Selector => $hop{selector},
        Key      => DKIM2TestKeys::private_key($hop{domain}, $hop{selector}),
        MailFrom => $hop{mailfrom},
        RcptTo   => $hop{rcptto},
    );
    $signer->load($msg->as_string);
    (my $header = $signer->as_string) =~ s{^DKIM2-Signature:\s*}{};
    $msg->header_raw_prepend('DKIM2-Signature', $header);
    return $msg;
}

sub verify_result {
    my ($text) = @_;
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    my $ok = eval { $v->load($text); 1 };
    return ('died', $@) unless $ok;
    return ($v->result, $v->details, $v->diagnostic);
}

our $ORIGINAL = join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: list\@test2.dkim2.com\r\n",
    "Subject: order\r\n",
    "Comments: first\r\n",
    "Comments: second\r\n",
    "Message-ID: <order\@test1.dkim2.com>\r\n",
    "Content-Type: text/plain\r\n",
    "\r\n",
    "line 1\r\n",
    "line 2\r\n",
    "line 3\r\n",
);

# Hop 1 at test1.dkim2.com signs $ORIGINAL. Hop 2 at test2.dkim2.com applies
# $change to an Email::MIME of what it received, records m=2, lets $mangle
# rewrite that m=2 header, and signs. Returns the signed hop-2 message, the
# hop-1 message and the m=2 header text.
sub two_hops {
    my ($change, $mangle) = @_;
    my $previous = Email::MIME->new($ORIGINAL);
    my $mi1 = Mail::DKIM2::MessageInstance->calculate($previous);
    $previous->header_raw_prepend('Message-Instance', $mi1->as_string);
    sign_hop($previous,
        domain => 'test1.dkim2.com', selector => 'sel1',
        mailfrom => 'sender@test1.dkim2.com', rcptto => ['list@test2.dkim2.com']);

    my $current = Email::MIME->new($previous->as_string);
    $change->($current);
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($current, $previous);
    my $mi2_text = $mi2->as_string;
    $mi2_text = $mangle->($mi2_text) if $mangle;
    $current->header_raw_prepend('Message-Instance', $mi2_text);
    sign_hop($current,
        domain => 'test2.dkim2.com', selector => 'sel2',
        mailfrom => 'bounces@test2.dkim2.com', rcptto => ['user@test3.dkim2.com']);
    return ($current, $previous, $mi2_text);
}

sub recipe_json {
    my ($mi_text) = @_;
    my ($r) = $mi_text =~ /\br=([A-Za-z0-9+\/=\s]+)/ or return undef;
    $r =~ s/\s+//g;
    return decode_base64($r);
}

# Swap the r= of an MI header for the base64 of $json (a string or a ref).
sub with_recipe {
    my ($mi_text, $json) = @_;
    $json = JSON->new->canonical(1)->encode($json) if ref $json;
    my $b64 = encode_base64($json, '');
    $mi_text =~ s/\br=[A-Za-z0-9+\/=\s]+/r=$b64/ or die "no r= in $mi_text";
    return $mi_text;
}

# Hop 2 appends a footer: the body has four lines, and the honest Recipe is
# {"b":[{"c":[1,3]}]}. Each case below replaces it with a malformed one.
my $append_footer = sub { $_[0]->body_set($_[0]->body_raw . "-- \r\nfooter\r\n") };

# -08 §14.2 (contract D6): a bad step is "Recipe <path> is invalid"; a
# fraction or exponent anywhere is the document's fault ("contains invalid
# JSON"); a range past the end is found applying the Recipe, as before.
my $JSON = 'PERMERROR: Message-Instance m=2 contains invalid JSON';
sub step { "PERMERROR: Message-Instance m=2 Recipe $_[0] is invalid" }
my @bad = (
    [ '{"b":[{"c":[3,3]},{"c":[1,2]}]}',   step('b[1]'), 'descending ranges' ],
    [ '{"b":[{"c":[1,2]},{"c":[2,3]}]}',   step('b[1]'), 'overlapping ranges' ],
    [ '{"b":[{"c":[1,3]},{"c":[1,3]}]}',   step('b[1]'), 'the same range twice' ],
    [ '{"b":[{"c":[2,2]},{"c":[2,2]}]}',   step('b[1]'), 'the same line twice' ],
    [ '{"b":[{"c":[0,3]}]}',               step('b[0]'), 'a range from line 0' ],
    [ '{"b":[{"c":[1,6]}]}',               $JSON, 'a range past the end', qr/copies lines 1-6 of 5/ ],
    [ '{"b":[{"c":[3,1]}]}',               step('b[0]'), 'a range that runs backwards' ],
    [ '{"b":[{"c":[1.5,3]}]}',             $JSON, 'a fractional bound' ],
    [ '{"b":[{"c":["x",3]}]}',             step('b[0]'), 'a non-numeric bound' ],
    [ '{"b":[{"c":[true,3]}]}',            step('b[0]'), 'a boolean bound' ],
    [ '{"b":[{"c":[-1,3]}]}',              step('b[0]'), 'a negative bound' ],
    [ '{"b":[{"c":["1","3"]}]}',           step('b[0]'), 'bounds that are JSON strings' ],
    [ '{"b":[{"c":[1,"3"]}]}',             step('b[0]'), 'one bound that is a JSON string' ],
    [ '{"b":[{"c":[1.0,3]}]}',             $JSON, 'a bound with a fraction part of zero' ],
    [ '{"b":[{"c":[1e0,3]}]}',             $JSON, 'a bound in exponent form' ],
    [ '{"b":[{"c":[null,3]}]}',            step('b[0]'), 'a null bound' ],
    [ '{"b":[{"c":[1]}]}',                 step('b[0]'), 'one bound' ],
    [ '{"b":[{"c":[1,2,3]}]}',             step('b[0]'), 'three bounds' ],
    [ '{"b":[{"c":[]}]}',                  step('b[0]'), 'no bounds' ],
    [ '{"h":{"subject":[{"c":[1,1]},{"c":[1,1]}]}}', step('h.subject[1]'),
      'a header range used twice' ],
    [ '{"h":{"comments":[{"c":[2,2]},{"c":[1,1]}]}}', step('h.comments[1]'),
      'descending header ranges' ],
    [ '{"h":{"comments":[{"c":[1,1]}],"b-side":[{"c":[2,1]}]}}', step('h.b-side[0]'),
      'header names in byte order: b-side before comments' ],
    [ '{"b":[{"c":[1,2]}],"h":{"comments":[{"x":1}]}}', step('h.comments[0]'),
      'b is checked before h, and a good b passes on' ],
);

for my $case (@bad) {
    my ($json, $want, $name, $detail_re) = @$case;
    my ($current) = two_hops($append_footer, sub { with_recipe($_[0], $json) });
    my $text = $current->as_string;

    my $err = eval { Mail::DKIM2::MessageInstance->undo($text); 1 } ? '' : $@;
    like($err, $detail_re // qr/\A\Q$want\E\n?\z/, "undo refuses $name");

    my ($ok, $why, $detail) = Mail::DKIM2::MessageInstance->chain_verifies($text);
    ok(!$ok, "... chain_verifies does not pass");
    is($why, $want, "... and says why");
    like($detail, $detail_re, "... with the detail") if $detail_re;

    my ($result, $details, $diag) = verify_result($text);
    isnt($result, 'died', "... the Verifier does not throw");
    isnt($result, 'pass', "... and does not accept the message") or diag($details);
    is($details, $want, "... naming the problem");
    like($diag, $detail_re, "... with the detail in diagnostic()") if $detail_re;
}

# The honest footer Recipe still passes, so the failures above are the
# Recipes' doing.
{
    my ($current) = two_hops($append_footer);
    my ($result, $details) = verify_result($current->as_string);
    is($result, 'pass', 'the Recipe calculate() built passes') or diag($details);
}

# --- generation: a hop that swaps the two Comments ---
# Header fields are numbered bottom-up and the builder rebuilds the previous
# set bottom-up too. Previous: second=1, first=2. Current: first=1,
# second=2. "second" matches current index 2; "first" then matches index 1,
# which is not above 2, so it goes in literally: {"c":[2,2]},{"d":["first"]}.
{
    my $swap = sub {
        my ($msg) = @_;
        $msg->header_raw_set('Comments', 'second', 'first');
    };
    my ($current, $previous, $mi2_text) = two_hops($swap);
    my $json = recipe_json($mi2_text);
    note $json;
    my $steps = JSON->new->decode($json)->{h}{comments};
    ok($steps, 'the swap produced a Comments Recipe');
    my $last_end = 0;
    my $ascending = 1;
    for my $step (@$steps) {
        next unless exists $step->{c};
        $ascending = 0 unless $step->{c}[0] > $last_end;
        $last_end = $step->{c}[1];
    }
    ok($ascending, 'every copy range starts after the last one ended');
    is(scalar(grep { exists $_->{c} } @$steps), 1, 'one range, the other value literal');

    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($current->as_string));
    is_deeply([ $undone->header_raw('Comments') ], ['first', 'second'],
        'undo restores the original order');
    my ($result, $details) = verify_result($current->as_string);
    is($result, 'pass', 'the Verifier passes the swapped-header message') or diag($details);
}

# --- generation: a hop that moves one field over the other two ---
# Previous, bottom-up: third=1, second=2, first=3. Current, bottom-up:
# first=1, third=2, second=3. Rebuilding third, second, first matches 2,
# then 3 (one range [2,3]), then 1, which is below 3: literal. Checked the
# same way: ascending, and undoes.
{
    my $rotate = sub {
        my ($msg) = @_;
        $msg->header_raw_set('Comments', 'second', 'third', 'first');
    };
    my $three = $ORIGINAL;
    $three =~ s/Comments: second\r\n/Comments: second\r\nComments: third\r\n/;
    local $ORIGINAL = $three;
    my ($current, $previous, $mi2_text) = two_hops($rotate);
    my $json = recipe_json($mi2_text);
    note $json;
    my $steps = JSON->new->decode($json)->{h}{comments};
    my $last_end = 0;
    my $ascending = 1;
    for my $step (@$steps) {
        next unless exists $step->{c};
        $ascending = 0 unless $step->{c}[0] > $last_end;
        $last_end = $step->{c}[1];
    }
    ok($ascending, 'rotated fields: every copy range starts after the last one ended');
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($current->as_string);
    ok($ok, 'rotated fields undo cleanly') or diag($why);
}

# --- generation: identical values are copied once each, in order ---
# Two identical Comments survive a hop that only changes the Subject: the
# Comments Recipe is not needed at all (unchanged set), but a hop that drops
# a third copy must copy the two that remain as one range [1,2].
{
    my $two_same = $ORIGINAL;
    $two_same =~ s/Comments: first\r\nComments: second\r\n/Comments: same\r\nComments: same\r\nComments: same\r\n/;
    local $ORIGINAL = $two_same;
    my ($current, $previous, $mi2_text) = two_hops(sub {
        $_[0]->header_raw_set('Comments', 'same', 'same');
    });
    my $json = recipe_json($mi2_text);
    note $json;
    like($json, qr/"comments":\[\{"c":\[1,2\]\},\{"d":\["same"\]\}\]/,
        'two surviving identical fields are one range, the dropped one literal');
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($current->as_string);
    ok($ok, 'and the chain undoes cleanly') or diag($why);
}

done_testing;
