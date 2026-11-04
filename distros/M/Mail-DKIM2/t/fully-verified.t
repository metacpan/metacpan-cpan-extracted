#!/usr/bin/perl
# -09 sections 13 and 14.2: below a null body Recipe the body cannot be
# rebuilt, so the checks cannot all be completed: a PERMERROR naming the
# instance that holds the null (contract E2; it replaces -08 D9's "pass,
# not fully verified"). fully_verified() is deprecated: true exactly for a
# pass, and never in HeadersOnly mode.
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
    is($v->result_detail, 'permerror (PERMERROR: Message-Instance m=2 has a null recipe)',
       'a null body Recipe: PERMERROR, naming m=2');
    ok(!$v->fully_verified, '... and not fully verified');
}
{
    # A §14.2 check: it comes before the signatures are checked (contract
    # C9), so a broken i=2 signature over the null still reports the null.
    (my $bad = list_post(1)) =~ s/(DKIM2-Signature: i=2;.*?s=sel1:rsa-sha256:)([A-Za-z])/$1 . ($2 eq 'A' ? 'B' : 'A')/se
        or die 'fixture';
    is(verify($bad)->result_detail, 'permerror (PERMERROR: Message-Instance m=2 has a null recipe)',
       'the null is reported ahead of a bad signature');
    # ... but after the structure: a duplicated instance comes first.
    (my $dup = list_post(1)) =~ s/^(Message-Instance: m=1;.*?\015\012)(?![ \t])/$1$1/ms or die 'fixture';
    is(verify($dup)->result_detail, 'permerror (PERMERROR: Message-Instance m=1 is duplicated)',
       'structure before the null');
}
{
    # Two nulls: the lowest m= is named, the instances being checked in
    # ascending m= with their other Recipe faults (contract E2).
    my $two = list_post(1);
    my $mod = $two . "more$EOL";
    my $mi3 = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($mod), Email::MIME->new($two));
    $mi3->set_null_body_recipe;
    my $three = sign_as("Message-Instance: " . $mi3->as_string . $EOL . $mod,
        'test3.dkim2.com', 'user@test3.dkim2.com', 'user@test4.dkim2.com');
    is(verify($three)->result_detail, 'permerror (PERMERROR: Message-Instance m=2 has a null recipe)',
       'two nulls: the lowest is named');
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
