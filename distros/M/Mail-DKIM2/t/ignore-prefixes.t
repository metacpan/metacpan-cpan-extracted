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
use Mail::DKIM2::Common qw(parse_dkim_pubkey should_skip);

# An operator's own header fields sit on the wrong side of the signature at
# both ends: its border adds them after the sender signed, and strips them
# before the mail reaches anyone else. IgnorePrefixes names them, so the
# operator's signers hash the message its recipients will actually get and
# its verifiers accept mail its own systems have annotated. It is local
# policy, so it is an option on each call and each Verifier -- never state
# shared by every object in the process. A verifier elsewhere still hashes
# those fields, which is why the operator has to strip them at the border.

my $EOL = "\015\012";

my $priv = Crypt::PK::RSA->new;
$priv->generate_key(256, 65537);
my $KEY_TXT = 'v=DKIM1; k=rsa; p=' . encode_base64($priv->export_key_der('public'), '');

my $MESSAGE = join($EOL,
    'Message-Id: <ours@sender.example.com>',
    'Date: Thu, 21 Mar 2024 12:09:37 +1000',
    'From: <author@sender.example.com>',
    'To: <user@example.net>',
    'Subject: our own fields',
    '', 'Body text.', '');

my $OURS = "Fastmail-MaskedEmail: id=masked-1; state=enabled$EOL";
my @PFX  = ('fastmail-');

sub sign {
    my ($text, @opts) = @_;
    my $mi = Mail::DKIM2::MessageInstance->calculate($text, undef, @opts);
    my $with_mi = 'Message-Instance: ' . $mi->as_string() . $EOL . $text;
    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'sender.example.com',
        Selector => 'sel',
        Key      => $priv,
        MailFrom => 'author@sender.example.com',
        RcptTo   => ['user@example.net'],
    );
    $signer->PRINT($with_mi);
    $signer->CLOSE;
    return $signer->sign_for_recipient('user@example.net') . $EOL . $with_mi;
}

sub verify {
    my ($text, @opts) = @_;
    my $v = Mail::DKIM2::Verifier->new(
        PubkeyCallback => sub { return parse_dkim_pubkey($KEY_TXT) },
        @opts,
    );
    $v->PRINT($text);
    $v->CLOSE;
    return $v->result;
}

subtest 'should_skip honours the prefixes it is given' => sub {
    ok(!should_skip('Fastmail-MaskedEmail'), 'none given: hashed like any other field');
    ok(!should_skip('Fastmail-MaskedEmail', []), 'empty list: the same');

    ok(should_skip('fastmail-maskedemail', ['FASTMAIL-']),    'given prefix, any case: ignored');
    ok(should_skip('Fastmail-Sender-Identity', ['FASTMAIL-']), '  ... along with every other name under it');
    ok(!should_skip('Fastmailish', ['FASTMAIL-']),             'a prefix, not a substring');
    ok(!should_skip('Subject', ['FASTMAIL-']),                 'other fields are unaffected');
    ok(should_skip('X-Anything', ['FASTMAIL-']),               "the spec's own exclusions still apply");
};

subtest 'a signer with the list signs what the recipient will get' => sub {
    my $signed = sign($OURS . $MESSAGE, IgnorePrefixes => \@PFX);
    (my $delivered = $signed) =~ s/^Fastmail-MaskedEmail:[^\015]*\015\012//m;
    unlike($delivered, qr/^Fastmail-/m, 'the border stripped our field');

    # The recipient's verifier knows nothing of our list.
    is(verify($delivered), 'pass', 'the stripped copy verifies elsewhere');
    isnt(verify($signed), 'pass', '  ... and the unstripped one would not, so the border strip is not optional');
};

subtest 'a verifier with the list accepts its own annotation' => sub {
    my $signed = sign($MESSAGE);
    my $annotated = $OURS . $signed;
    isnt(verify($annotated), 'pass', 'without the list the field our border added breaks the hash');
    is(verify($annotated, IgnorePrefixes => \@PFX), 'pass', 'with it the field is invisible');
    is(verify($signed, IgnorePrefixes => \@PFX), 'pass', '  ... and mail without the field still verifies');
};

subtest 'the list belongs to the object, not the process' => sub {
    my $annotated = $OURS . sign($MESSAGE);
    my $ours   = Mail::DKIM2::Verifier->new(IgnorePrefixes => \@PFX,
        PubkeyCallback => sub { parse_dkim_pubkey($KEY_TXT) });
    my $theirs = Mail::DKIM2::Verifier->new(
        PubkeyCallback => sub { parse_dkim_pubkey($KEY_TXT) });
    $ours->load($annotated);
    $theirs->load($annotated);
    is($ours->result, 'pass', 'the verifier with the list passes');
    isnt($theirs->result, 'pass', '  ... and one made without it, in the same process, does not');
};

subtest 'MessageInstance class methods take the list too' => sub {
    my $signed = sign($MESSAGE);
    my $annotated = $OURS . $signed;
    ok(!Mail::DKIM2::MessageInstance->verify($annotated), 'verify: without the list the hash differs');
    ok(Mail::DKIM2::MessageInstance->verify($annotated, IgnorePrefixes => \@PFX), '  ... with it, it matches');
    my ($ok) = Mail::DKIM2::MessageInstance->chain_verifies($annotated, IgnorePrefixes => \@PFX);
    ok($ok, 'chain_verifies: with the list');
    my ($nok) = Mail::DKIM2::MessageInstance->chain_verifies($annotated);
    ok(!$nok, '  ... and not without');
};

subtest 'the option must be a list' => sub {
    ok(!eval { Mail::DKIM2::Verifier->new(IgnorePrefixes => 'fastmail-'); 1 },
        'Verifier->new refuses a bare string');
    like($@, qr/IgnorePrefixes must be an array reference/, '  ... and says what it wants');
    ok(!eval { Mail::DKIM2::MessageInstance->verify($MESSAGE, IgnorePrefixes => 'x-'); 1 },
        'MessageInstance->verify refuses one too');
    ok(!eval { Mail::DKIM2::MessageInstance->calculate($MESSAGE, undef, IgnorePrefixes => {}); 1 },
        '  ... as does calculate');
    ok(eval { Mail::DKIM2::Verifier->new(IgnorePrefixes => undef); 1 }, 'undef is fine');
};

done_testing;
