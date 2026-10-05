#!/usr/bin/perl -w
#
# Recipe literals with any octet >= 0x80 travel as {"b": ["<base64>", ...]}
# steps (RFC 4648 section 4 alphabet); pure-ASCII literals stay {"d": [...]}.
#
# A Recipe literal is the raw octets of a header value or body line, and
# real mail carries ISO-2022-JP, GB18030, Big5 and Latin-1 in both. JSON
# text is UTF-8, so those octets cannot be written into a "d" step
# unchanged; base64 carries them exactly. Verifiers reject a "b" item that
# is not valid base64 or that decodes to something containing CR or LF, and
# a "d" item containing CR or LF (spec-06 §5.1/§5.2 MUST NOT).
#
# Agreed extension to spec-06 section 5, proposed to the WG 2026-10.

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

# Raw octets, deliberately not UTF-8: a Big5/GB-ish pair and Latin-1 cafe.
my $HDR_BYTES  = "\xb1\xa4";
my $BODY_BYTES = "caf\xe9";

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
    return ($v->result, $v->details);
}

# Hop 1 at test1.dkim2.com signs the original; hop 2 at test2.dkim2.com
# drops the 8-bit header and body line, records m=2 against what it
# received, optionally rewrites that m=2 ($mangle), and signs.
sub two_hops {
    my ($mangle) = @_;
    my $previous = Email::MIME->new(join('',
        "From: sender\@test1.dkim2.com\r\n",
        "To: list\@test2.dkim2.com\r\n",
        "Subject: octets\r\n",
        "Comments: $HDR_BYTES\r\n",
        "Message-ID: <octets\@test1.dkim2.com>\r\n",
        "Content-Type: text/plain\r\n",
        "\r\n",
        "line 1\r\n",
        "$BODY_BYTES\r\n",
        "line 3\r\n",
    ));
    my $mi1 = Mail::DKIM2::MessageInstance->calculate($previous);
    $previous->header_raw_prepend('Message-Instance', $mi1->as_string);
    sign_hop($previous,
        domain => 'test1.dkim2.com', selector => 'sel1',
        mailfrom => 'sender@test1.dkim2.com', rcptto => ['list@test2.dkim2.com']);

    my $current = Email::MIME->new($previous->as_string);
    $current->header_raw_set('Comments');
    $current->body_set("line 1\r\nline 3\r\n");
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

# --- round trip: calculate emits "b", undo and the Verifier rebuild the bytes ---
{
    my ($current, $previous, $mi2_text) = two_hops();
    my $json = recipe_json($mi2_text);
    note $json;
    unlike($json, qr/[\x80-\xff]/, 'recipe JSON is pure ASCII');
    my $hdr_b64  = encode_base64($HDR_BYTES, '');
    my $body_b64 = encode_base64($BODY_BYTES, '');
    like($json, qr/"comments":\[\{"b":\["\Q$hdr_b64\E"\]\}\]/,
        'the 8-bit header value is a "b" item');
    like($json, qr/"b":\[\{"c":\[1,1\]\},\{"b":\["\Q$body_b64\E"\]\},\{"c":\[2,2\]\}\]/,
        'the 8-bit body line is a "b" item between the two copy ranges');
    unlike($json, qr/"d":/, 'nothing is a "d" item here');

    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($current->as_string));
    is($undone->header_raw('Comments'), $HDR_BYTES, 'undo rebuilds the header octets');
    is($undone->body_raw, "line 1\r\n$BODY_BYTES\r\nline 3\r\n", 'undo rebuilds the body octets');
    ok(!utf8::is_utf8($undone->body_raw), 'rebuilt body is a byte string');

    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($current->as_string);
    ok($ok, 'chain_verifies undoes back to m=1') or diag($why);

    my ($result, $details) = verify_result($current->as_string);
    is($result, 'pass', 'full Verifier passes the signed two-hop message') or diag($details);
}

# --- mixed runs: literals of each kind coalesce, kinds alternate ---
{
    my $list = ['plain', 'ascii', "\xe9", "\xb1\xa4", [3, 4], 'tail'];
    my $enc = Mail::DKIM2::MessageInstance::_encode_recipe_list($list);
    is_deeply($enc, [
        { d => ['plain', 'ascii'] },
        { b => [encode_base64("\xe9", ''), encode_base64("\xb1\xa4", '')] },
        { c => [3, 4] },
        { d => ['tail'] },
    ], 'consecutive literals of one kind share a step; kinds alternate');
    my $dec = Mail::DKIM2::MessageInstance::_decode_recipe_list($enc, 2);
    is_deeply($dec, $list, 'and the decoder gives the list back');
}

# --- parse accepts a hand-built "b" and gives back the octets ---
{
    my $b64 = encode_base64('{"b":[{"b":["' . encode_base64("\xe9", '') . '"]}]}', '');
    my $mi = Mail::DKIM2::MessageInstance->parse("m=2; h=sha256:x:y; r=$b64;");
    is_deeply($mi->get_tag('rb'), ["\xe9"], '"b" item decodes to the raw octets');
}

# --- reject: bad "b" items make the instance fail, never throw out of the Verifier ---
my @bad = (
    [ { b => [ { b => ['not base64!'] } ] },
      qr/malformed base64 literal/, 'characters outside the alphabet' ],
    [ { b => [ { b => ['QUJD='] } ] },
      qr/malformed base64 literal/, 'wrong padding' ],
    [ { b => [ { b => ['QQ'] } ] },
      qr/malformed base64 literal/, 'missing padding' ],
    [ { b => [ { b => [ 'QUJD', 7 ] } ] },
      qr/malformed base64 literal/, 'a non-string item' ],
    [ { b => [ { b => 'QUJD' } ] },
      qr/malformed base64 literal/, '"b" that is not an array' ],
    [ { b => [ { b => [ encode_base64("a\r\nb", '') ] } ] },
      qr/literal contains CR or LF/, 'CRLF in the decoded octets' ],
    [ { b => [ { b => [ encode_base64("a\nb", '') ] } ] },
      qr/literal contains CR or LF/, 'bare LF in the decoded octets' ],
    [ { h => { comments => [ { b => [ encode_base64("x\ry", '') ] } ] } },
      qr/literal contains CR or LF/, 'bare CR in a header literal' ],
    # spec-06 §5.1/§5.2: "d" text MUST NOT contain CR or LF either
    [ { b => [ { d => [ "a\r\nb" ] } ] },
      qr/literal contains CR or LF/, 'CRLF in a "d" body line' ],
    [ { b => [ { d => [ "a\nb" ] } ] },
      qr/literal contains CR or LF/, 'bare LF in a "d" body line' ],
    [ { h => { comments => [ { d => [ "x\ry" ] } ] } },
      qr/literal contains CR or LF/, 'bare CR in a "d" header value' ],
    [ { h => { comments => [ { d => [ "ok", "x\ny" ] } ] } },
      qr/literal contains CR or LF/, 'LF in the second of two "d" header values' ],
    # schema: "d" and "b" have minItems 1
    [ { b => [ { b => [] } ] },
      qr/empty literal step/, 'an empty "b" array' ],
    [ { b => [ { d => [] } ] },
      qr/empty literal step/, 'an empty "d" array' ],
    [ { h => { comments => [ { d => [] } ] } },
      qr/empty literal step/, 'an empty "d" array in a header Recipe' ],
    [ { b => [ { d => 'x' } ] },
      qr/empty literal step/, '"d" that is not an array' ],
);

for my $case (@bad) {
    my ($recipe, $error, $name) = @$case;
    my ($current) = two_hops(sub { with_recipe($_[0], $recipe) });
    my $text = $current->as_string;

    my $err = eval { Mail::DKIM2::MessageInstance->parse(
        ($current->header_raw('Message-Instance'))[0]); 1 } ? '' : $@;
    like($err, qr/^PERMERROR Message-Instance m=2 Recipe .*$error/, "parse refuses $name");

    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($text);
    ok(!$ok, "... chain_verifies does not pass");

    my ($result, $details) = verify_result($text);
    isnt($result, 'died', "... the Verifier does not throw");
    is($result, 'permerror', "... and reports permerror") or diag($details);
    like($details, $error, "... naming the problem");
}

done_testing;
