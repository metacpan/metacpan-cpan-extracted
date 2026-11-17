#!/usr/bin/perl -w
# Three faults reported against 0.34 (CPAN, 2026-11-16).
#
#  1. A header line that is not a field ("NoColon", a first line starting
#     with WSP, ":x", "Sub ject: x") was dropped by HeaderParser: never
#     hashed, so lines could be added to a signed message unseen by any
#     Message-Instance while other parsers read them (Python's email ends
#     the header section at one). Now the Verifier says PERMERROR and the
#     Signer refuses.
#  2. split_tag_list trimmed a value with (.*?)\s*\z, quadratic in a run
#     of internal whitespace. Linear now; these pin the trimming it does.
#  3. Validate::report walked every level even past MAX_CHAIN_LENGTH.
#     Now it reports the Verifier's PERMERROR and no levels.
use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use DKIM2TestKeys;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::TagValueList;
use Mail::DKIM2::Validate;

my $BAD = 'PERMERROR: malformed header field';

sub signed {
    my ($raw) = @_;
    my $mi  = Mail::DKIM2::MessageInstance->calculate($raw);
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n$raw";
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['b@test2.dkim2.com'],
        Timestamp => 1740000000,
    );
    $s->PRINT($msg); $s->CLOSE;
    (my $sig = $s->as_string) =~ s/\r?\n\z//;
    return "$sig\r\n$msg";
}

sub verify {
    my ($msg) = @_;
    my $v = Mail::DKIM2::Verifier->new(PubkeyCallback => DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($msg); $v->CLOSE;
    return ($v->result, $v->details);
}

# --- 1 ---------------------------------------------------------------
my $head = "From: a\@test1.dkim2.com\r\nTo: b\@test2.dkim2.com\r\nSubject: hi\r\n";
my $good = signed("$head\r\nbody\r\n");
is((verify($good))[0], 'pass', 'control: the signed message passes');

my %junk = (
    'no colon'               => "NoColonHere\r\n",
    'WSP inside the name'    => "Sub ject: x\r\n",
    'empty name'             => ":Empty: x\r\n",
    'no colon, continued'    => "Garbage\r\n Subject: evil\r\n",
    "fold before the colon"  => "Keywords\r\n : x\r\n",
);
for my $what (sort keys %junk) {
    (my $msg = $good) =~ s/^(Subject: hi\r\n)/$1$junk{$what}/m or die;
    is_deeply([verify($msg)], ['permerror', $BAD], "verifier: $what");
    (my $msg2 = $good) =~ s/\A/$junk{$what}/;
    is_deeply([verify($msg2)], ['permerror', $BAD], "verifier: $what, as the first line");
}
my $lead = " Subject: evil\r\n$good";
is_deeply([verify($lead)], ['permerror', $BAD], 'verifier: first line starts with WSP');

# No blank line at all: the header block is parsed at CLOSE.
(my $nobody = $good) =~ s{\r\n\r\n.*\z}{\r\nNoColonHere\r\n}s;
is_deeply([verify($nobody)], ['permerror', $BAD],
          'verifier: no end of header section');

# A message with no DKIM2 field has no DKIM2 result to give: still none.
is((verify("From: a\@x\r\nNoColonHere\r\n\r\nbody\r\n"))[0], 'none',
   'no DKIM2 fields: none, as before');

{
    my $mi  = Mail::DKIM2::MessageInstance->calculate("$head\r\nbody\r\n");
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['b@test2.dkim2.com'],
        Timestamp => 1740000000);
    $s->PRINT("Message-Instance: " . $mi->as_string . "\r\n${head}NoColonHere\r\n\r\nbody\r\n");
    $s->CLOSE;
    is($s->result, 'fail', 'signer: refuses');
    is($s->details, 'malformed header field', '  ... and says why');
}

# --- 2 ---------------------------------------------------------------
for ([ "a=b",              'b' ],
     [ "a = b ",           'b' ],
     [ "a=\r\n b \r\n c\r\n ", "b \r\n c" ],
     [ "a=",               ''  ],
     [ "a= \t ",           ''  ],
     [ "a=b" . (" \r\n" x 50) . "c", "b" . (" \r\n" x 50) . "c" ]) {
    my ($in, $want) = @$_;
    my ($pairs, $ok) = Mail::DKIM2::TagValueList::split_tag_list($in);
    is($pairs->[0][1], $want, "split_tag_list trims '" . ($in =~ s/\r\n/\\r\\n/gr) . "'");
}
{
    my ($pairs, $ok) = Mail::DKIM2::TagValueList::split_tag_list("a=b" . (" \r\n" x 40000) . "c");
    ok($ok && $pairs->[0][1] =~ /\Ab .*c\z/s, 'a long run of internal FWS parses');
}

# --- 3 ---------------------------------------------------------------
{
    my $msg = "Message-Instance: m=1; h=sha256:AAAA:AAAA\r\n";
    $msg .= "DKIM2-Signature: i=$_; m=1; t=1; d=example.com; s=sel:ed25519-sha256:AAAA\r\n"
        for 1 .. 40;
    $msg .= "From: a\@example.com\r\n\r\nbody\r\n";
    my $rep = Mail::DKIM2::Validate::report($msg, PubkeyCallback => sub { die "no key\n" });
    is($rep->{overall}, 'fail', 'validator: over the chain limit fails');
    like($rep->{summary}, qr/PERMERROR: more than 32 DKIM2-Signature fields/,
         '  ... with the Verifier\'s PERMERROR');
    is(scalar @{ $rep->{levels} || [] }, 0, '  ... and walks no levels');
}
is(Mail::DKIM2::Validate::_i('i=' . ('9' x 30)), 0, '_i: not a chain number is 0');
is(Mail::DKIM2::Validate::_m('m=100'), 0, '_m: 100 is not a chain number');
is(Mail::DKIM2::Validate::_i('m=1; i=07'), 7, '_i: 07 is 7');

done_testing;
