#!/usr/bin/perl -w
#
# Folding whitespace inside DKIM2 tag values (spec-06 §2.12): FWS may appear
# inside a base64 string and around the colons of an s= item, and "MUST be
# ignored when the value is used".
#
# A fold landing between the Selector colon and the algorithm token is the
# awkward case: splitting the s= item on ':' before stripping FWS leaves
# CRLF+TAB glued to the algorithm name.  Folded output from a conformant signer
# must verify.

use 5.020;
use strict;
use warnings;
use Test::More;
use Email::MIME;
use lib 'lib';
use lib 't/lib';

use Mail::DKIM2::Common qw(fold_header);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signature;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $TIMESTAMP = 1740000000;

my $raw = join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: rcpt\@test2.dkim2.com\r\n",
    "Subject: folding test\r\n",
    "Date: Fri, 24 Jul 2026 12:00:00 +0000\r\n",
    "Message-ID: <fold\@test1.dkim2.com>\r\n",
    "\r\n",
    "Hello folding world.\r\n",
);

my $msg = Email::MIME->new($raw);

# Message-Instance m=1, then the DKIM2-Signature over it.
my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
my $mi_hdr = fold_header("Message-Instance: " . $mi->as_string());
$mi_hdr =~ s{^Message-Instance:\s*}{};
$msg->header_raw_prepend('Message-Instance', $mi_hdr);

my $signer = Mail::DKIM2::Signer->new(
    Domain    => 'test1.dkim2.com',
    Selector  => 'sel1',
    Key       => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
    MailFrom  => '<sender@test1.dkim2.com>',
    RcptTo    => ['<rcpt@test2.dkim2.com>'],
    Timestamp => $TIMESTAMP,
);
$signer->PRINT($msg->as_string());
$signer->CLOSE;
my $sig_hdr = $signer->as_string();
$sig_hdr =~ s{^DKIM2-Signature:\s*}{};
$msg->header_raw_prepend('DKIM2-Signature', $sig_hdr);

my $signed = $msg->as_string();
$signed =~ s/\r?\n/\r\n/g;

sub verify_result {
    my ($text) = @_;
    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($text);
    $v->CLOSE;
    return ($v->result, $v->result_detail // '');
}

# Insert one CRLF+TAB fold into the DKIM2-Signature / Message-Instance headers.
sub refold {
    my ($text, $pattern, $repl) = @_;
    my ($head, $body) = split /\r\n\r\n/, $text, 2;
    $body //= '';

    # Unfold into logical header fields first, so repeated application is safe.
    my @logical;
    for my $line (split /\r\n/, $head) {
        if ($line =~ /^[ \t]/ && @logical) {
            $line =~ s/^[ \t]+/ /;
            $logical[-1] .= $line;
        }
        else {
            push @logical, $line;
        }
    }

    for my $h (@logical) {
        next unless $h =~ /^(?:DKIM2-Signature|Message-Instance):/i;
        $h =~ s/$pattern/$repl/ee;
    }
    return join("\r\n", @logical) . "\r\n\r\n" . $body;
}

my @cases = (
    [ 'mf= base64',   qr/(mf=)([A-Za-z0-9+\/=]{6})/,       q{"$1$2\r\n\t"} ],
    [ 'rt= base64',   qr/(rt=)([A-Za-z0-9+\/=]{6})/,       q{"$1$2\r\n\t"} ],
    [ 's= selector',  qr/(s=[A-Za-z0-9_-]+:)/,             q{"$1\r\n\t"}   ],
    [ 's= algorithm', qr/(:rsa-sha256:)/,                  q{"$1\r\n\t"}   ],
    [ 'h= hashes',    qr/(h=sha256:)([A-Za-z0-9+\/=]{6})/, q{"$1$2\r\n\t"} ],
);

my ($res, $detail) = verify_result($signed);
is($res, 'pass', "baseline as-signed verifies ($detail)");

my $all = $signed;
for my $case (@cases) {
    my ($name, $pattern, $repl) = @$case;
    my $folded = refold($signed, $pattern, $repl);
    isnt($folded, $signed, "$name: fold was actually inserted");
    my ($r, $d) = verify_result($folded);
    is($r, 'pass', "fold in $name still verifies ($d)");
    $all = refold($all, $pattern, $repl);
}

my ($ra, $da) = verify_result($all);
is($ra, 'pass', "every fold point at once still verifies ($da)");

# --- Multi-item lists folded at the comma (spec-06 §2.12) -------------------
#
# The cases above all use a single-key s=, so the value never contains a comma
# and a fold can only land inside an item.  A signer with two keys emits
# "sel1:alg1:sig1,sel2:alg2:sig2", and folding at 72 characters readily puts
# the CRLF+WSP immediately after the comma -- observed in the wild from
# roessner.email.  Splitting on ',' without stripping FWS then glues the fold
# onto the *next* item's Selector, and the public-key DNS lookup goes out for
# "\te01465a...._domainkey.roessner.email", which SERVFAILs.
#
# Only the first item is safe, because it directly follows "s=".
my $vis = sub {
    my $s = shift // '(undef)';
    $s =~ s/([^\x20-\x7e])/sprintf('<%02X>', ord $1)/ge;
    return $s;
};

{
    my $sig = Mail::DKIM2::Signature->parse(
        "DKIM2-Signature: i=1;\r\n\tm=1;\r\n\td=example.com;\r\n"
      . "\ts=sel1:rsa-sha256:AAAA,\r\n\tsel2:ed25519-sha256:BBBB;\r\n");

    my $items = $sig->signatures_data;
    is(scalar @$items, 2, 's= with two items parses as two items');

    is($vis->($items->[0][0]), 'sel1', 'item 0 selector has no FWS');
    is($vis->($items->[1][0]), 'sel2', 'item 1 selector has no FWS (fold after comma)');
    is($vis->($items->[1][1]), 'ed25519-sha256', 'item 1 algorithm has no FWS');
    is($vis->($items->[1][2]), 'BBBB', 'item 1 signature value has no FWS');
}

{
    my $sig = Mail::DKIM2::Signature->parse(
        "DKIM2-Signature: i=1;\r\n\tf=aaa,\r\n\tbbb;\r\n");
    my $flags = $sig->flags;
    is($vis->($flags->[0]), 'aaa', 'f= flag 0 has no FWS');
    is($vis->($flags->[1]), 'bbb', 'f= flag 1 has no FWS (fold after comma)');
}

done_testing();
