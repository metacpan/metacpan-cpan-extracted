#!/usr/bin/perl
# Mail::DKIM2::Gate: a null body Recipe on a Message-Instance is refused
# (without AllowNullBodyRecipe) only when no DKIM2-Signature covers that
# instance.  A signature with m=k covers instances 1..k, so an instance is
# uncovered when its m= is above the highest m= of every valid signature --
# the top, or one under another unsigned instance.  That is a null THIS hop
# would be the first to sign.  A null that the upstream domain declared and
# signed (a list host's signed post, forwarded unchanged) is extended
# normally.
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
    ok(!$g->{ok}, 'unsigned null top: refused by default');
    is($g->{reason}, 'null-body-recipe', 'unsigned null top: reason null-body-recipe');
    like($g->{message}, qr/unsigned top Message-Instance m=2 has a null body Recipe/,
        'unsigned null top: message says the null top is unsigned');
    like($g->{message}, qr/\(AllowNullBodyRecipe not set\)/, 'library message names the library option');
    unlike($g->{message}, qr/--allow/, 'library message has no CLI flag');
    is($g->{top_null}, 1, 'unsigned null top: top_null');
    is($g->{top_signed}, 0, 'unsigned null top: top_signed is 0 (i=1 covers only m=1)');
    $g = Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 1);
    ok($g->{ok}, 'unsigned null top: signed with AllowNullBodyRecipe');
}

{
    my $msg = signed_null_list_post();
    like($msg, qr/^DKIM2-Signature: i=2; m=2;/m, 'fixture: the list signed m=2');
    my $g = Mail::DKIM2::Gate->check($msg, %cb, SigningDomain => 'test3.dkim2.com');
    ok($g->{ok}, 'signed null top: extended without the option')
        or diag($g->{message});
    is($g->{top_null}, 1, 'signed null top: top_null still reported');
    is($g->{top_signed}, 1, 'signed null top: top_signed');
    $g = Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 1);
    ok($g->{ok}, 'signed null top: and with the option');
}

{
    # Signed or not, the header history below the null must still check out.
    my $g = Mail::DKIM2::Gate->check(signed_null_list_post(forge => 1), %cb);
    ok(!$g->{ok}, 'signed forged null top: refused');
    isnt($g->{reason} // '', 'null-body-recipe', 'signed forged null top: for the chain, not the null');
    $g = Mail::DKIM2::Gate->check(signed_null_list_post(forge => 1), %cb,
        AllowNullBodyRecipe => 1);
    ok(!$g->{ok}, 'signed forged null top: refused even with the option');
}

{
    # Unsigned null m=2 under an unsigned ordinary m=3: the null is not the
    # top, but i=1 covers only m=1, so nothing vouches for it yet.
    my $msg = ordinary_on_top(null_list_post());
    like($msg, qr/^Message-Instance: m=3;/m, 'fixture: an unsigned m=3 on top');
    my $g = Mail::DKIM2::Gate->check($msg, %cb);
    ok(!$g->{ok}, 'null below unsigned top: refused by default');
    is($g->{reason}, 'null-body-recipe', 'null below unsigned top: reason null-body-recipe');
    like($g->{message}, qr/^unsigned Message-Instance m=2 has a null body Recipe/,
        'null below unsigned top: message names the unsigned null m=2');
    is($g->{top_null}, 0, 'null below unsigned top: top_null is 0 (m=3 is ordinary)');
    is($g->{top_signed}, 0, 'null below unsigned top: top_signed is 0');
    is($g->{covered_m}, 1, 'null below unsigned top: covered_m is 1');
    is($g->{unsigned_null}, 2, 'null below unsigned top: unsigned_null is 2');
    $g = Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 1);
    ok($g->{ok}, 'null below unsigned top: signed with AllowNullBodyRecipe')
        or diag($g->{message});

    # The history under both unsigned instances is still checked.
    $g = Mail::DKIM2::Gate->check(ordinary_on_top(null_list_post(forge => 1)), %cb,
        AllowNullBodyRecipe => 1);
    ok(!$g->{ok}, 'forged null below unsigned top: refused even with the option');
}

{
    # The null m=2 is covered by the list's valid i=2/m=2; only an ordinary
    # m=3 is unsigned on top of it.
    my $msg = ordinary_on_top(signed_null_list_post());
    my $g = Mail::DKIM2::Gate->check($msg, %cb, SigningDomain => 'test3.dkim2.com');
    ok($g->{ok}, 'null below signed: extended without the option')
        or diag($g->{message});
    is($g->{covered_m}, 2, 'null below signed: covered_m is 2');
    is($g->{unsigned_null}, 0, 'null below signed: no unsigned null');
    is($g->{top_null}, 0, 'null below signed: top_null is 0');
    $g = Mail::DKIM2::Gate->check($msg, %cb, AllowNullBodyRecipe => 1);
    ok($g->{ok}, 'null below signed: and with the option');
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
        for my $allow (0, 1) {
            my $g = Mail::DKIM2::Gate->check($msg, %cb,
                ($allow ? (AllowNullBodyRecipe => 1) : ()));
            ok(!$g->{ok}, "fake coverage ($name, allow=$allow): refused");
            is($g->{reason}, 'upstream-chain',
                "fake coverage ($name, allow=$allow): for the chain");
            like($g->{verify_result}, qr/^permerror/,
                "fake coverage ($name, allow=$allow): verifier permerror");
            is($g->{top_signed}, 0, "fake coverage ($name, allow=$allow): not top_signed");
        }
        my $g = Mail::DKIM2::Gate->check($msg, %cb, VerifyResult => 'pass');
        is($g->{top_signed}, 0, "fake coverage ($name): not coverage even given 'pass'");
        is($g->{reason}, 'null-body-recipe', "fake coverage ($name): null refused given 'pass'");
        is_deeply(\@warn, [], "fake coverage ($name): no warnings");
    }
}

done_testing;
