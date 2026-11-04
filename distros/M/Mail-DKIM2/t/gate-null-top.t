#!/usr/bin/perl
# Mail::DKIM2::Gate and null body Recipes (0.29, -09 contract E2). A
# signature with m=k covers instances 1..k, so an instance is uncovered when
# its m= is above the highest m= of every valid signature: a null THIS hop
# is introducing, which is always signed (it PERMERRORs downstream anyway,
# but our header changes are signed). A null that the upstream domain
# declared and signed fails upstream verification and is refused.
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
use DKIM2TestKeys;

my $EOL = "\015\012";
my $PLAIN = join($EOL,
    'MIME-Version: 1.0',
    'Message-Id: <post@test1.dkim2.com>',
    'Date: Thu, 10 Sep 2026 15:47:11 +1000',
    'From: Author <author@test1.dkim2.com>',
    'To: list@test2.dkim2.com',
    'Subject: a post',
    'Content-Type: text/plain',
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

# i=1/m=1 by test1, then the list test2 tags the subject and rewrites the
# body, recording m=2 with a null body Recipe.  m=2 is unsigned here.
sub null_list_post {
    my (%o) = @_;
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    my $signed = sign_as("Message-Instance: " . $mi->as_string . $EOL . $PLAIN,
        'test1.dkim2.com', 'author@test1.dkim2.com', 'list@test2.dkim2.com');
    my $mod = $signed;
    $mod =~ s/^Subject: /Subject: [list] /m;
    $mod =~ s/^To: .*$/To: tampered\@example.net/m if $o{forge};
    $mod .= "--$EOL" . "rewritten$EOL";
    my $mi2 = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($mod), Email::MIME->new($signed));
    $mi2->set_null_body_recipe;
    if ($o{forge}) {
        my $rh = $mi2->{bits}{rh};
        delete $rh->{$_} for grep { lc($_) eq 'to' } keys %$rh;
    }
    return "Message-Instance: " . $mi2->as_string . $EOL . $mod;
}

# ... and the list domain signs its own m=2 (i=2, m=2) to the forwarder.
sub signed_null_list_post {
    return sign_as(null_list_post(@_), 'test2.dkim2.com',
        'list-bounces@test2.dkim2.com', 'subscriber@test3.dkim2.com');
}

# An ordinary hop on top of $msg: another Subject tag and a footer, recorded as
# a new UNSIGNED Message-Instance with real Recipes.
sub ordinary_on_top {
    my ($msg) = @_;
    my $mod = $msg;
    $mod =~ s/^Subject: /Subject: [fwd] /m;
    $mod .= "footer$EOL";
    my $mi = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($mod), Email::MIME->new($msg));
    return "Message-Instance: " . $mi->as_string . $EOL . $mod;
}

my %cb = (PubkeyCallback => DKIM2TestKeys::pubkey_callback());

{
    my $msg = null_list_post();
    my $g = Mail::DKIM2::Gate->check($msg, %cb);
    ok($g->{ok}, 'unsigned null top: signed (0.29: our own null is always signed)')
        or diag($g->{message});
    is($g->{reason}, undef, 'unsigned null top: no refusal');
    is($g->{top_null}, 1, 'unsigned null top: top_null');
    is($g->{top_signed}, 0, 'unsigned null top: top_signed is 0 (i=1 covers only m=1)');
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, @_ };
        $g = Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 0);
        is(scalar @warn, 0, 'AllowNullBodyRecipe => 0 (as hm passes it) does not warn');
        Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 1);
        Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 1);
    }
    ok($g->{ok}, 'AllowNullBodyRecipe => 0 no longer refuses');
    is(scalar @warn, 1, 'AllowNullBodyRecipe => 1 warns, once per process');
    like($warn[0] // '', qr/AllowNullBodyRecipe is deprecated and does nothing/, '... saying so');
}

{
    my $msg = signed_null_list_post();
    like($msg, qr/^DKIM2-Signature: i=2; m=2;/m, 'fixture: the list signed m=2');
    my $g = Mail::DKIM2::Gate->check($msg, %cb, SigningDomain => 'test3.dkim2.com');
    ok(!$g->{ok}, 'signed null top: refused (only our own nulls are signed)');
    is($g->{reason}, 'upstream-chain', 'signed null top: for the upstream chain');
    is($g->{verify_result}, 'permerror (PERMERROR: Message-Instance m=2 has a null recipe)',
       'signed null top: the verifier says why');
    is($g->{top_null}, 1, 'signed null top: top_null still reported');
    is($g->{top_signed}, 1, 'signed null top: top_signed');
}

{
    # The header history below our own null must still check out.
    my $g = Mail::DKIM2::Gate->check(null_list_post(forge => 1), %cb);
    ok(!$g->{ok}, 'forged unsigned null top: refused');
    isnt($g->{reason} // '', 'null-body-recipe', 'forged unsigned null top: for the chain');
}

{
    # Unsigned null m=2 under an unsigned ordinary m=3: both ours.
    my $msg = ordinary_on_top(null_list_post());
    like($msg, qr/^Message-Instance: m=3;/m, 'fixture: an unsigned m=3 on top');
    my $g = Mail::DKIM2::Gate->check($msg, %cb);
    ok($g->{ok}, 'null below unsigned top: signed') or diag($g->{message});
    is($g->{top_null}, 0, 'null below unsigned top: top_null is 0 (m=3 is ordinary)');
    is($g->{top_signed}, 0, 'null below unsigned top: top_signed is 0');
    is($g->{covered_m}, 1, 'null below unsigned top: covered_m is 1');
    is($g->{unsigned_null}, 2, 'null below unsigned top: unsigned_null is 2');

    # The history under both unsigned instances is still checked.
    $g = Mail::DKIM2::Gate->check(ordinary_on_top(null_list_post(forge => 1)), %cb);
    ok(!$g->{ok}, 'forged null below unsigned top: refused');
}

{
    # The null m=2 is covered by the list's i=2/m=2; an ordinary m=3 is
    # unsigned on top of it. The null is upstream's: refused.
    my $msg = ordinary_on_top(signed_null_list_post());
    my $g = Mail::DKIM2::Gate->check($msg, %cb, SigningDomain => 'test3.dkim2.com');
    ok(!$g->{ok}, 'null below signed: refused');
    is($g->{reason}, 'upstream-chain', 'null below signed: for the upstream chain');
    is($g->{covered_m}, 2, 'null below signed: covered_m is 2');
    is($g->{unsigned_null}, 0, 'null below signed: no unsigned null');
}

{
    my $g = Mail::DKIM2::Gate->check(null_list_post(), %cb);
    is($g->{unsigned_null}, 2, 'unsigned null top: unsigned_null is the top m=');
    is($g->{covered_m}, 1, 'unsigned null top: covered_m');
    $g = Mail::DKIM2::Gate->check(signed_null_list_post(), %cb);
    is($g->{unsigned_null}, 0, 'signed null top: no unsigned null');
}

{
    # A DKIM2-Signature that names m=2 but that no verifier can key is not
    # coverage.  The Verifier PERMERRORs on it, so the gate refuses with or
    # without the option; and even if a caller hands in VerifyResult 'pass',
    # it does not count towards top_signed (defence in depth).
    my $base = null_list_post();
    (my $real) = $base =~ /^(DKIM2-Signature: i=1; m=1;.*?\015\012)(?![ \t])/ms;
    ok($real, 'fixture: the real i=1 signature');
    (my $rewritten = $real) =~ s/i=1; m=1;/m=2;/;
    my %fake = (
        'no i='        => "DKIM2-Signature: m=2; d=evil.example$EOL",
        'i=0'          => "DKIM2-Signature: i=0; m=2; t=1; d=evil.example; s=sel1:rsa-sha256:AAAA$EOL",
        'empty i='     => "DKIM2-Signature: i=; m=2; d=evil.example$EOL",
        'i=abc'        => "DKIM2-Signature: i=abc; m=2; d=evil.example$EOL",
        'i=-1'         => "DKIM2-Signature: i=-1; m=2; d=evil.example$EOL",
        'FWS m = 2'    => "DKIM2-Signature: m = 2 ; d=evil.example$EOL",
        'm rewritten'  => $rewritten,
    );
    for my $name (sort keys %fake) {
        my $msg = $fake{$name} . $base;
        my @warn;
        local $SIG{__WARN__} = sub { push @warn, @_ };
        {
            my $g = Mail::DKIM2::Gate->check($msg, %cb);
            ok(!$g->{ok}, "fake coverage ($name): refused");
            is($g->{reason}, 'upstream-chain', "fake coverage ($name): for the chain");
            like($g->{verify_result}, qr/^permerror/, "fake coverage ($name): verifier permerror");
            is($g->{top_signed}, 0, "fake coverage ($name): not top_signed");
        }
        my $g = Mail::DKIM2::Gate->check($msg, %cb, VerifyResult => 'pass');
        is($g->{top_signed}, 0, "fake coverage ($name): not coverage even given 'pass'");
        ok($g->{ok}, "fake coverage ($name): given 'pass', the null counts as ours and is signed");
        is_deeply(\@warn, [], "fake coverage ($name): no warnings");
    }
}

done_testing;
