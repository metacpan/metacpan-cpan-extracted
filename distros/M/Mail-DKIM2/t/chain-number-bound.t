#!/usr/bin/perl
# Every DKIM2-Signature i= and m=, and every Message-Instance m=, is a chain
# number: 1*DIGIT (anything else is a malformed tag), at most three digits
# and 1..MAX_CHAIN_NUMBER (100), so "01" and "001" are 1; and no more than
# MAX_CHAIN_LENGTH (32). Each is a PERMERROR found while the header fields are
# read, before anything walks 1..i= or 1..m= looking for gaps.
# i=99999999999999999999 used to kill the Verifier with "Range iterator
# outside integer range".
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use Email::MIME;
use Mail::DKIM2::Common qw(MAX_CHAIN_LENGTH MAX_CHAIN_NUMBER chain_number_error extract_mi_version);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $EOL = "\015\012";
my $PLAIN = join($EOL,
    'Message-Id: <bound@test1.dkim2.com>',
    'Date: Thu, 10 Sep 2026 15:47:11 +1000',
    'From: Author <author@test1.dkim2.com>',
    'To: user@test2.dkim2.com',
    'Subject: bound',
    '',
    'hello',
    '');

is(MAX_CHAIN_LENGTH, 32, 'MAX_CHAIN_LENGTH is 32');
is(MAX_CHAIN_NUMBER, 100, 'MAX_CHAIN_NUMBER is 100');
is(chain_number_error('DKIM2-Signature', 'i', $_), undef, "i=$_ is in range")
    for qw(1 9 32 01 001 032);
is(chain_number_error('DKIM2-Signature', 'm', $_),
   'PERMERROR DKIM2-Signature m= exceeds the maximum chain length of 32',
   "m=$_ is a chain number but past the chain length")
    for qw(33 99 100 099);
is(chain_number_error('DKIM2-Signature', 'i', $_),
   'PERMERROR DKIM2-Signature i= exceeds the maximum chain number of 100',
   "i=$_ is out of range")
    for qw(101 999 0001 4294967297 99999999999999999999);
is(chain_number_error('Message-Instance', 'm', $_), 'PERMERROR Message-Instance has a malformed m= tag',
   "m=" . join('', map { sprintf('\\x%X', ord) } split //) . " is malformed")
    for ('abc', '', '1.5', '0', '00', '000', '1x', '4294967297x', '30000000x', '0_1', "\x{FF11}", '+1', '-1');
is(chain_number_error('DKIM2-Signature', 'i', 'abc'),
   'PERMERROR DKIM2-Signature has a missing or malformed i= tag', 'malformed i= says so');
is(chain_number_error('Message-Instance', 'm', undef), undef, 'a missing m= is left to the callers');
is(extract_mi_version(" m=01; h=x"), 1, 'extract_mi_version: m=01 is 1');
is(extract_mi_version(" m=001; h=x"), 1, 'extract_mi_version: m=001 is 1');
is(extract_mi_version(" m = 2 ; h=x"), 2, 'extract_mi_version: FWS around =');
is(extract_mi_version(" h=x; m=3"), 3, 'extract_mi_version: m= need not be first');
is(extract_mi_version(" m=4294967297x; h=x"), undef, 'extract_mi_version: no digit prefix of 4294967297x');

my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
my $unsigned = "Message-Instance: " . $mi->as_string . $EOL . $PLAIN;
my $s = Mail::DKIM2::Signer->new(
    Domain => 'test1.dkim2.com', Selector => 'sel1',
    Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
    MailFrom => 'author@test1.dkim2.com', RcptTo => ['user@test2.dkim2.com'],
    Timestamp => time());
$s->PRINT($unsigned); $s->CLOSE;
my $sig = $s->as_string;
my $signed = $sig . $EOL . $unsigned;

sub verify {
    my ($msg) = @_;
    my $v = Mail::DKIM2::Verifier->new(
        PubkeyCallback => DKIM2TestKeys::pubkey_callback());
    $v->PRINT($msg); $v->CLOSE;
    return $v;
}

is(verify($signed)->result, 'pass', 'control: the signed message passes');

my $range = 'exceeds the maximum chain length of 32';
my $number = 'exceeds the maximum chain number of 100';
my %cases = (
    'signature i=33' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=)1;/${1}33;/m }, "DKIM2-Signature i= $range" ],
    'signature i=101' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=)1;/${1}101;/m }, "DKIM2-Signature i= $number" ],
    'signature i=huge' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=)1;/${1}99999999999999999999;/m }, "DKIM2-Signature i= $number" ],
    'signature i=2^32+1' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=)1;/${1}4294967297;/m }, "DKIM2-Signature i= $number" ],
    'signature m=huge' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=1; m=)1;/${1}99999999999999999999;/m }, "DKIM2-Signature m= $number" ],
    'signature m=4294967297x' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=1; m=)1;/${1}4294967297x;/m }, "DKIM2-Signature has a malformed m= tag" ],
    'signature m=abc' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=1; m=)1;/${1}abc;/m }, "DKIM2-Signature has a malformed m= tag" ],
    'signature m=0_1' => [ sub { $_[0] =~ s/^(DKIM2-Signature: i=1; m=)1;/${1}0_1;/m }, "DKIM2-Signature has a malformed m= tag" ],
    'instance m=huge' => [ sub { $_[0] =~ s/^(Message-Instance: m=)1;/${1}99999999999999999999;/m }, "Message-Instance m= $number" ],
    'instance m=33' => [ sub { $_[0] =~ s/^(Message-Instance: m=)1;/${1}33;/m }, "Message-Instance m= $range" ],
    'instance m=101' => [ sub { $_[0] =~ s/^(Message-Instance: m=)1;/${1}101;/m }, "Message-Instance m= $number" ],
    'instance m=4294967297x' => [ sub { $_[0] =~ s/^(Message-Instance: m=)1;/${1}4294967297x;/m }, "Message-Instance has a malformed m= tag" ],
    'instance m=abc' => [ sub { $_[0] =~ s/^(Message-Instance: m=)1;/${1}abc;/m }, "Message-Instance has a malformed m= tag" ],
    'extra junk i=huge' => [ sub { $_[0] = "DKIM2-Signature: i=99999999999999999999; m=2; d=evil.example$EOL$_[0]" }, "DKIM2-Signature i= $number" ],
);
for my $name (sort keys %cases) {
    my ($edit, $detail) = @{$cases{$name}};
    my $msg = $signed;
    $edit->($msg);
    isnt($msg, $signed, "$name: fixture edited");
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $v = eval { verify($msg) };
    is($@, '', "$name: the Verifier does not die");
    is($v && $v->result, 'permerror', "$name: permerror");
    is($v && $v->result_detail, "permerror (PERMERROR $detail)", "$name: says why");

    my $s2 = Mail::DKIM2::Signer->new(
        Domain => 'test2.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
        MailFrom => 'user@test2.dkim2.com', RcptTo => ['x@test3.dkim2.com'],
        Timestamp => time());
    eval { $s2->PRINT($msg); $s2->CLOSE; };
    is($@, '', "$name: the Signer does not die");
    isnt($s2->result, 'pass', "$name: the Signer does not sign over it");
    like($s2->result_detail // '', qr/\Q$detail\E/, "$name: the Signer says why");
    is_deeply(\@warn, [], "$name: no warnings");
}

# Message-Instance chain checks (used by the Gate and the milters on chains
# with no signature) bound m= too.
{
    my $msg = $unsigned;
    $msg =~ s/^(Message-Instance: m=)1;/${1}99999999999999999999;/m or die;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my ($ok, $why) = Mail::DKIM2::MessageInstance->verify($msg);
    ok(!$ok, 'MessageInstance->verify: huge m= fails');
    like($why // '', qr/Message-Instance m= $number/, 'MessageInstance->verify: says why');
    ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($msg);
    ok(!$ok, 'MessageInstance->chain_verifies: huge m= fails');
    like($why // '', qr/Message-Instance m= $number/, 'MessageInstance->chain_verifies: says why');
    is_deeply(\@warn, [], 'MessageInstance: no warnings');

    $msg = $unsigned;
    $msg =~ s/^(Message-Instance: m=)1;/${1}4294967297x;/m or die;
    ($ok, $why) = Mail::DKIM2::MessageInstance->chain_verifies($msg);
    ok(!$ok, 'MessageInstance->chain_verifies: m=4294967297x fails');
    like($why // '', qr/Message-Instance has a malformed m= tag/, '... as a malformed m= tag');
}

# Item: m=01 / m=001 / i=001 are 1 everywhere (the Verifier used to key its
# instances by the m= string, so a Message-Instance m=01 read as "missing m=1").
for my $form ('01', '001') {
    my $mi1 = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    (my $mis = $mi1->as_string) =~ s/^m=1;/m=$form;/ or die;
    my $un = "Message-Instance: $mis$EOL$PLAIN";
    my $sg = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'author@test1.dkim2.com', RcptTo => ['user@test2.dkim2.com'],
        Timestamp => time());
    $sg->PRINT($un); $sg->CLOSE;
    is($sg->result, 'signed', "instance m=$form: the Signer signs over it");
    my $v = verify($sg->as_string . $EOL . $un);
    is($v->result, 'pass', "instance m=$form: verifies") or diag($v->result_detail);
}

done_testing;
