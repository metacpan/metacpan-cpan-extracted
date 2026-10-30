#!/usr/bin/perl
# -08 section 13: a message is a Fully Verified DKIM2 Message only if every
# instance's hashes are checked against the message rebuilt for it. Below a
# null body Recipe the body cannot be rebuilt, so those body hashes cannot
# be checked: the result stays pass, but fully_verified() is false
# (contract D9).
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use Email::MIME;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
use DKIM2TestKeys;

my $EOL = "\015\012";
my $PLAIN = join($EOL,
    'Message-Id: <post@test1.dkim2.com>',
    'From: Author <author@test1.dkim2.com>',
    'To: list@test2.dkim2.com',
    'Subject: a post',
    '',
    'hello list',
    '');

sub sign_as {
    my ($msg, $dom, $mf, $rt) = @_;
    my $s = Mail::DKIM2::Signer->new(
        Domain => $dom, Selector => 'sel1',
        Key => DKIM2TestKeys::private_key($dom, 'sel1'),
        MailFrom => $mf, RcptTo => [$rt], Timestamp => time());
    $s->PRINT($msg); $s->CLOSE;
    return $s->as_string . $EOL . $msg;
}

# i=1 by test1; then the list at test2 rewrites the body and signs i=2 over
# an m=2 whose body Recipe is null ($null) or real.
sub list_post {
    my ($null) = @_;
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    my $signed = sign_as("Message-Instance: " . $mi->as_string . $EOL . $PLAIN,
        'test1.dkim2.com', 'author@test1.dkim2.com', 'list@test2.dkim2.com');
    (my $mod = $signed) .= "--$EOL" . "footer$EOL";
    my $mi2 = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($mod), Email::MIME->new($signed));
    $mi2->set_null_body_recipe if $null;
    return sign_as("Message-Instance: " . $mi2->as_string . $EOL . $mod,
        'test2.dkim2.com', 'list@test2.dkim2.com', 'user@test3.dkim2.com');
}

sub verify {
    my ($text, %o) = @_;
    my $v = Mail::DKIM2::Verifier->new(SkipTimestampCheck => 1, %o);
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->load($text);
    return $v;
}

{
    my $v = verify(list_post(0));
    is($v->result, 'pass', 'a real body Recipe: pass') or diag $v->details;
    ok($v->fully_verified, '... and fully verified');
}
{
    my $v = verify(list_post(1));
    is($v->result, 'pass', 'a null body Recipe: still pass') or diag $v->details;
    ok(!$v->fully_verified, '... but not fully verified: m=1 body unchecked');
}
{
    my $v = verify(list_post(0), HeadersOnly => 1);
    is($v->result, 'pass', 'HeadersOnly: pass') or diag $v->details;
    ok(!$v->fully_verified, '... no body hash was checked: not fully verified');
}
{
    (my $bad = list_post(0)) =~ s/^Subject: a post/Subject: tampered/m;
    my $v = verify($bad);
    isnt($v->result, 'pass', 'a failure');
    ok(!$v->fully_verified, '... is never fully verified');
}

done_testing;
