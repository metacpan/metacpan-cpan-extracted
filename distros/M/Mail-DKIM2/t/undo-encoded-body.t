#!/usr/bin/perl -w
#
# undo() must rebuild the previous body as exact octets. Recipes work on wire
# lines, so for a base64 or quoted-printable part the rebuilt body is already
# encoded; Email::MIME->body_set would encode it again. Found 2026-10-04:
# every base64/QP message Mailman re-encoded (footer appended, body
# re-wrapped) failed "m=1 does not match content" in the Perl verifier and
# the milter refused to sign it, while the Python undo rebuilt the same
# messages byte for byte.

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use MIME::Base64 qw(encode_base64);
use lib 'lib';

use Mail::DKIM2::MessageInstance;

sub hop {
    my ($cte, $prev_body, $cur_body) = @_;
    my $hdr = join('',
        "From: sender\@test1.dkim2.com\r\n",
        "To: list\@test2.dkim2.com\r\n",
        "Subject: encoded body\r\n",
        "Message-ID: <enc-$cte\@test1.dkim2.com>\r\n",
        "MIME-Version: 1.0\r\n",
        "Content-Type: text/plain; charset=utf-8\r\n",
        "Content-Transfer-Encoding: $cte\r\n",
        "\r\n");
    my $previous = Email::MIME->new($hdr . $prev_body);
    my $mi1 = Mail::DKIM2::MessageInstance->calculate($previous);
    $previous->header_raw_prepend('Message-Instance', $mi1->as_string);
    my $current = Email::MIME->new($hdr . $cur_body);
    $current->header_raw_prepend('Message-Instance', $mi1->as_string);
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($current, $previous);
    $current->header_raw_prepend('Message-Instance', $mi2->as_string);
    return ($previous, $current);
}

# base64: the list decoded, appended a footer and re-encoded, so every wire
# line changed and the Recipe is all literals.
{
    my $text = "Apache OpenOffice \xe3\x81\xaf\xe7\x8f\xbe\xe5\x9c\xa8 line one\r\nline two\r\n";
    my $prev_body = encode_base64($text, "\r\n");
    my $cur_body  = encode_base64($text . "-- \r\nList footer\r\n", "\r\n");
    my ($previous, $current) = hop('base64', $prev_body, $cur_body);
    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($current->as_string));
    is($undone->body_raw, $prev_body, 'base64: undo rebuilds the previous wire body exactly')
        or diag "got: " . substr($undone->body_raw, 0, 60);
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($current->as_string);
    ok($ok, 'base64: the chain verifies back to m=1') or diag $why;
}

# quoted-printable: same, with soft breaks moving.
{
    my $prev_body = "Hello=20world, caf=C3=A9 au lait and a long line that the encoder soft-bre=\r\naks here.\r\n";
    my $cur_body  = "Hello=20world, caf=C3=A9 au lait and a long line that the encoder soft-breaks=\r\n here.\r\n-- =\r\nList footer\r\n";
    my ($previous, $current) = hop('quoted-printable', $prev_body, $cur_body);
    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($current->as_string));
    is($undone->body_raw, $prev_body, 'quoted-printable: undo rebuilds the previous wire body exactly');
    my ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($current->as_string);
    ok($ok, 'quoted-printable: the chain verifies back to m=1') or diag $why;
}

# and 8bit, the case that always worked, still does.
{
    my ($previous, $current) = hop('8bit', "caf\xc3\xa9 one\r\ntwo\r\n", "caf\xc3\xa9 one\r\ntwo\r\n-- \r\nfooter\r\n");
    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($current->as_string));
    is($undone->body_raw, "caf\xc3\xa9 one\r\ntwo\r\n", '8bit: undo rebuilds the previous body');
}

done_testing;
