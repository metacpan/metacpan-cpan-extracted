#!/usr/bin/perl
# Mail::DKIM2::Gate: when the Gate runs the Verifier itself and it passes, the
# Verifier has already walked the Message-Instance chain, so the Gate must not
# walk it a second time; with no signatures or a caller-supplied VerifyResult
# it still does.  A broken chain is still refused with the same reason.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use Email::MIME;
use Mail::DKIM2::Gate;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $EOL = "\015\012";
my $PLAIN = join($EOL,
    'MIME-Version: 1.0', 'Message-Id: <p@test1.dkim2.com>',
    'Date: Thu, 10 Sep 2026 15:47:11 +1000',
    'From: A <a@test1.dkim2.com>', 'To: l@test2.dkim2.com',
    'Subject: hi', 'Content-Type: text/plain', '', 'hello', '');

my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
my $with_mi = "Message-Instance: " . $mi->as_string . $EOL . $PLAIN;
my $s = Mail::DKIM2::Signer->new(Domain => 'test1.dkim2.com', Selector => 'sel1',
    Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
    MailFrom => 'a@test1.dkim2.com', RcptTo => ['l@test2.dkim2.com'],
    Timestamp => time());
$s->PRINT($with_mi); $s->CLOSE;
my $signed = $s->as_string . $EOL . $with_mi;

my %cb = (PubkeyCallback => DKIM2TestKeys::pubkey_callback());

my ($walks, $gate_walks) = (0, 0);
{
    no warnings 'redefine';
    my $v = \&Mail::DKIM2::Verifier::_verify_mi_chain;
    my $c = \&Mail::DKIM2::MessageInstance::chain_verifies;
    *Mail::DKIM2::Verifier::_verify_mi_chain = sub { $walks++; goto &$v };
    *Mail::DKIM2::MessageInstance::chain_verifies = sub { $gate_walks++; goto &$c };
}
sub counts { ($walks, $gate_walks) = (0, 0); my $g = Mail::DKIM2::Gate->check(@_); return ($g, $walks, $gate_walks) }

my ($g, $w, $gw) = counts($signed, %cb);
ok($g->{ok}, 'valid signed chain passes');
is("$w/$gw", '1/0', 'one chain walk (the Verifier), none by the Gate');

($g, $w, $gw) = counts($with_mi, %cb);
is("$w/$gw", '0/1', 'no signatures: the Gate walks');

($g, $w, $gw) = counts($signed, %cb, VerifyResult => 'pass');
is("$w/$gw", '0/1', 'caller-supplied VerifyResult: the Gate walks');

# Content changed under the signed top MI: refused for the chain/upstream.
(my $bad = $signed) =~ s/hello/tampered/;
($g, $w, $gw) = counts($bad, %cb);
ok(!$g->{ok}, 'tampered body refused');
is($g->{reason}, 'upstream-chain', 'reason as before (the Verifier fails first)');

# Broken chain with a caller-supplied pass still gives broken-mi-chain.
($g) = counts($bad, %cb, VerifyResult => 'pass');
is($g->{reason}, 'broken-mi-chain', 'broken-mi-chain still reported');

done_testing;
