#!/usr/bin/perl
# A message read from a filehandle, a piece at a time: Gate->check and load()
# reach the verdicts they reach from the message as a string, and a Signer
# fed only the header block makes the signature it makes from the whole
# message.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
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
    'Subject: hi', 'Content-Type: text/plain', '',
    ('a line of body text, long enough to add up' x 1) x 5000, 'hello', '');

my $TIME = time();
sub signer {
    return Mail::DKIM2::Signer->new(Domain => 'test1.dkim2.com',
        Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['l@test2.dkim2.com'],
        Timestamp => $TIME);
}

my $mi = Mail::DKIM2::MessageInstance->calculate($PLAIN);
my $with_mi = "Message-Instance: " . $mi->as_string . $EOL . $PLAIN;
my $s = signer();
$s->PRINT($with_mi); $s->CLOSE;
my $signed = $s->as_string . $EOL . $with_mi;
(my $tampered = $signed) =~ s/hello/tampered/;
(my $header_tampered = $signed) =~ s/Subject: hi/Subject: changed/;
(my $unsigned_tampered = $with_mi) =~ s/hello/tampered/;

my %cb = (PubkeyCallback => DKIM2TestKeys::pubkey_callback());

sub handle {
    my ($text, $lf) = @_;
    $text =~ s/\r\n/\n/g if $lf;
    open(my $fh, '<', \$text) or die;
    return $fh;
}

# A minimal object with getline, as a host joins its own header block to a
# body read from a file.
{
    package LineReader;
    sub new { my ($c, $t) = @_; bless { lines => [ $t =~ /([^\n]*\n|[^\n]+\z)/g ] }, $c }
    sub getline { shift @{$_[0]{lines}} }
}

my %cases = (
    'a valid chain'          => $signed,
    'a tampered body'        => $tampered,
    'a tampered header'      => $header_tampered,
    'an unsigned instance'   => $with_mi,
    'a tampered unsigned instance' => $unsigned_tampered,
    'no DKIM2 at all'        => $PLAIN,
);
for my $name (sort keys %cases) {
    my $text = $cases{$name};
    for my $opts ([], [VerifyResult => 'pass']) {
        my $want = Mail::DKIM2::Gate->check($text, %cb, @$opts);
        my $label = @$opts ? "$name, VerifyResult" : $name;
        note("$label: ok=$want->{ok} " . ($want->{message} // $want->{verify_result}));
        is_deeply(Mail::DKIM2::Gate->check(handle($text), %cb, @$opts), $want,
            "Gate: $label, from a filehandle");
        is_deeply(Mail::DKIM2::Gate->check(handle($text, 1), %cb, @$opts), $want,
            "Gate: $label, from a LF file");
        is_deeply(Mail::DKIM2::Gate->check(LineReader->new($text), %cb, @$opts),
            $want, "Gate: $label, from an object with getline");
    }
}

for my $name (sort keys %cases) {
    my $text = $cases{$name};
    my $want = Mail::DKIM2::Verifier->new(%cb)->load($text)->result_detail;
    is(Mail::DKIM2::Verifier->new(%cb)->load(handle($text, 1))->result_detail,
        $want, "Verifier load: $name, from a LF file");
}

subtest 'a Signer fed the header block alone' => sub {
    my ($head) = $with_mi =~ /\A(.*?\r\n\r\n)/s;
    my $whole = signer();
    $whole->PRINT($with_mi); $whole->CLOSE;
    my $part = signer();
    $part->PRINT($head); $part->CLOSE;
    is($part->result, 'signed', 'signs');
    is($part->as_string, $whole->as_string, 'the same signature');
    is($whole->{_buf}, '', 'the body was not kept');
};

done_testing;
