#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Crypt::PK::RSA;
use MIME::Base64 qw(encode_base64);
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Common qw(parse_dkim_pubkey);

# DKIM2 hashes EVERY header field that §4 does not exclude, unlike DKIM1 which
# hashes only what its own h= tag names. That difference is the whole hazard for
# an MTA that adds headers on the way out: anything §4 does not ignore, added
# after the Message-Instance is computed, breaks it.
#
# These tests pin the contract an outbound signer depends on, because getting it
# wrong produces mail that looks fine locally and fails at every receiver:
#
#   - headers §4 ignores may be added after signing (Received, X-*,
#     DKIM-Signature)
#   - headers it does not ignore must be included BEFORE signing (List-Id)
#   - renaming a non-X- header to an X- one removes it from the hash, so a
#     signer must apply that rename before computing the instance
#   - header POSITION does not matter, because §6.2 sorts alphabetically
#
# Fastmail's lmtpprox relies on all four: see OutgoingDKIM2Sign there.

my $EOL = "\015\012";

my $priv = Crypt::PK::RSA->new;
$priv->generate_key(256, 65537);
my $KEY_TXT = 'v=DKIM1; k=rsa; p=' . encode_base64($priv->export_key_der('public'), '');

# The message as it sits in the spool, before the proxy stage touches it.
my $SPOOL = join($EOL,
    'Message-Id: <outbound@sender.example.com>',
    'Date: Thu, 21 Mar 2024 12:09:37 +1000',
    'From: <author@sender.example.com>',
    'To: <user@example.net>',
    'Subject: outbound',
    'Feedback-ID: abc:123:fm',
    'X-ME-Sender: <xms:something>',
    '', 'Body text.', '');

my @EXTRA = ('X-ME-Proxy: [1.2.3.4]', 'Sender: <bounces@sender.example.com>');
my @LIST  = ([ 'List-Id' => '<a.list.example.net>' ]);

# The rename the proxy applies on the way out. Both X-ME-Sender names start with
# X- so §4 ignores them either way, but Feedback-ID does NOT, so renaming it
# removes it from the header hash.
sub apply_outgoing_renames {
    my ($text) = @_;
    $text =~ s/^(X-ME-Sender|Feedback-ID):/X-Remote-$1:/gmi;
    return $text;
}

# Assemble and sign exactly as an outbound signer must: the message as it will
# be SENT, with the renames already applied. Returns (mi_header, sig_header).
sub sign_outbound {
    my ($body_text) = @_;
    my $mi = Mail::DKIM2::MessageInstance->calculate($body_text);
    my $mi_header = $mi->as_string();

    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'sender.example.com',
        Selector => 'sel',
        Key      => $priv,
        MailFrom => 'bounces@sender.example.com',
        RcptTo   => ['user@example.net'],
    );
    $signer->PRINT("Message-Instance: $mi_header$EOL" . $body_text);
    $signer->CLOSE;
    my $sig_header = $signer->sign_for_recipient('user@example.net');
    return ($mi_header, $sig_header);
}

sub verify {
    my ($text) = @_;
    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(sub { return parse_dkim_pubkey($KEY_TXT) });
    $v->PRINT($text);
    $v->CLOSE;
    return $v;
}

# What the signer hashes: extra headers, list headers, then the renamed spool.
my $signed_view = q{};
$signed_view .= "$_$EOL" for @EXTRA;
$signed_view .= $_->[0] . ': ' . $_->[1] . $EOL for @LIST;
$signed_view .= apply_outgoing_renames($SPOOL);

my ($MI_HEADER, $SIG_HEADER) = sign_outbound($signed_view);

# What actually goes on the wire. Note the order differs from the signed view --
# the signature headers come first, before the extra and list headers -- and
# three headers §4 ignores are prepended.
sub sent_message {
    my $out = q{};
    $out .= "Received: from x ([1.2.3.4])$EOL  by internal (MEProxy); now$EOL";
    $out .= "X-ME-Outgoing-Spam: No$EOL";
    $out .= "DKIM-Signature: v=1; a=rsa-sha256; d=sender.example.com; s=sel; b=fake$EOL";
    $out .= "Message-Instance: $MI_HEADER$EOL";
    $out .= $SIG_HEADER;
    $out .= $EOL unless $SIG_HEADER =~ /\015\012\z/;
    $out .= "$_$EOL" for @EXTRA;
    $out .= $_->[0] . ': ' . $_->[1] . $EOL for @LIST;
    $out .= apply_outgoing_renames($SPOOL);
    return $out;
}

subtest 'the sent message verifies' => sub {
    my $v = verify(sent_message());
    is($v->result, 'pass', 'pass despite a different header order and three ignored headers added after signing');
};

subtest 'headers §4 ignores may be added after signing' => sub {
    # Each of these is added after the instance was computed and must not matter.
    for my $late (
        ['Received',            "Received: from later ([5.6.7.8]) by y; now$EOL"],
        ['an X- header',        "X-Spam-Score: 0.1$EOL"],
        ['Received-SPF',        "Received-SPF: pass (example.net)$EOL"],
        ['another DKIM-Signature', "DKIM-Signature: v=1; d=other.example; s=s; b=x$EOL"],
        ['Authentication-Results', "Authentication-Results: mx.example.net; spf=pass$EOL"],
    ) {
        my ($label, $header) = @$late;
        my $v = verify($header . sent_message());
        is($v->result, 'pass', "$label added after signing does not break the instance");
    }
};

subtest 'headers §4 does NOT ignore must be included before signing' => sub {
    # List-Id is a real signed header, so adding one late must break the hash.
    my $v = verify("List-Id: <late.example.net>$EOL" . sent_message());
    isnt($v->result, 'pass', 'a List-Id added after signing breaks the instance');

    # And the one that is actually included verifies, which is what proves the
    # test above is detecting lateness rather than List-Id itself.
    like(sent_message(), qr/^List-Id: <a\.list\.example\.net>/m, 'the signed List-Id is present');
};

subtest 'the X- rename must be mirrored before signing' => sub {
    # Undo the rename in the sent message only: the header hash was computed with
    # Feedback-ID renamed away, so putting it back adds a signed header.
    my $text = sent_message();
    $text =~ s/^X-Remote-Feedback-ID:/Feedback-ID:/mi;
    my $v = verify($text);
    isnt($v->result, 'pass', 'an unmirrored Feedback-ID rename breaks the instance');

    # X-ME-Sender, by contrast, is X- on both sides of the rename, so §4 ignores
    # it either way and getting it "wrong" is harmless.
    my $xms = sent_message();
    $xms =~ s/^X-Remote-X-ME-Sender:/X-ME-Sender:/mi;
    my $v2 = verify($xms);
    is($v2->result, 'pass', 'an unmirrored X- to X- rename is harmless');
};

done_testing;
