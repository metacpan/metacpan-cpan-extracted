#!/usr/bin/perl
# A DKIM2-Signature the Verifier cannot key -- one with no i=, an i= that is
# not a positive integer, or that does not parse -- is a PERMERROR, as in the
# Python, Go, C and JS verifiers.  It used to be ignored silently, which let a
# junk "DKIM2-Signature: m=2" read as covering m=2 to the signer gate.  The
# Signer likewise refuses to sign over one.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use Email::MIME;
use Mail::DKIM2::Common qw(valid_sequence);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $EOL = "\015\012";
my $PLAIN = join($EOL,
    'Message-Id: <unkeyable@test1.dkim2.com>',
    'Date: Thu, 10 Sep 2026 15:47:11 +1000',
    'From: Author <author@test1.dkim2.com>',
    'To: user@test2.dkim2.com',
    'Subject: unkeyable',
    '',
    'hello',
    '');

my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
my $unsigned = "Message-Instance: " . $mi->as_string . $EOL . $PLAIN;
my $s = Mail::DKIM2::Signer->new(
    Domain => 'test1.dkim2.com', Selector => 'sel1',
    Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
    MailFrom => 'author@test1.dkim2.com', RcptTo => ['user@test2.dkim2.com'],
    Timestamp => time());
$s->PRINT($unsigned); $s->CLOSE;
my $signed = $s->as_string . $EOL . $unsigned;

sub verify {
    my ($msg) = @_;
    my $v = Mail::DKIM2::Verifier->new(
        PubkeyCallback => DKIM2TestKeys::pubkey_callback());
    $v->PRINT($msg); $v->CLOSE;
    return $v;
}

is(verify($signed)->result, 'pass', 'control: the signed message passes');

my %junk = (
    'no i='      => 'DKIM2-Signature: m=1; d=evil.example',
    'empty i='   => 'DKIM2-Signature: i=; m=1; d=evil.example',
    'i=0'        => 'DKIM2-Signature: i=0; m=1; d=evil.example',
    'i=abc'      => 'DKIM2-Signature: i=abc; m=1; d=evil.example',
    'i=-1'       => 'DKIM2-Signature: i=-1; m=1; d=evil.example',
    'i=1.5'      => 'DKIM2-Signature: i=1.5; m=1; d=evil.example',
    'empty'      => 'DKIM2-Signature: ',
);
for my $name (sort keys %junk) {
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $v = verify($junk{$name} . $EOL . $signed);
    is($v->result, 'permerror', "$name: permerror");
    is($v->result_detail,
       'permerror (PERMERROR DKIM2-Signature has a missing or malformed i= tag)',
       "$name: says why");

    my $s2 = Mail::DKIM2::Signer->new(
        Domain => 'test2.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
        MailFrom => 'user@test2.dkim2.com', RcptTo => ['x@test3.dkim2.com'],
        Timestamp => time());
    $s2->PRINT($junk{$name} . $EOL . $signed); $s2->CLOSE;
    isnt($s2->result, 'pass', "$name: Signer does not sign over it");
    like($s2->result_detail // '', qr/missing or malformed i= tag/,
        "$name: Signer says why");
    is_deeply(\@warn, [], "$name: no warnings");
}

ok(valid_sequence($_), "valid_sequence($_)") for qw(1 2 10 32);
ok(!valid_sequence($_), "!valid_sequence(" . ($_ =~ s{([^\x20-\x7e])}{sprintf("\\x{%x}", ord $1)}ger) . ")") for ('', '0', '00', 'abc', '-1', ' 1', '1 ', "1\n", "\x{0661}");
ok(!valid_sequence(undef), '!valid_sequence(undef)');

done_testing;
