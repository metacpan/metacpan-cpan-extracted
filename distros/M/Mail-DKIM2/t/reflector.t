#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use Email::MIME;
use MIME::Base64 qw(decode_base64);
use lib 'lib', 't/lib';
use Mail::DKIM2::Common qw(fold_header);
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Signer;
use Mail::DKIM2::MessageInstance;
use DKIM2TestKeys;
use Mail::DKIM2::Reflector;

# Build a known-good DKIM2-signed message (i=1) from test1.dkim2.com.
# Mirrors the full-chain.t pattern: add MI, then sign over it.
sub signed_input {
    my ($raw) = @_;
    $raw =~ s/\r?\n/\r\n/g;
    my $msg = Email::MIME->new($raw);
    my $mi  = Mail::DKIM2::MessageInstance->calculate($msg);
    my $folded = fold_header("Message-Instance: " . $mi->as_string);
    $folded =~ s/^Message-Instance:\s*//;
    $msg->header_raw_prepend('Message-Instance', $folded);
    my $signer = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'sel1',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'sel1'),
        MailFrom => 'a@test1.dkim2.com', RcptTo => ['reflector@test2.dkim2.com'],
        Timestamp => 1740000000,
    );
    $signer->PRINT($msg->as_string); $signer->CLOSE;
    (my $sig = $signer->as_string) =~ s/^DKIM2-Signature:\s*//;
    $msg->header_raw_prepend('DKIM2-Signature', $sig);
    return $msg->as_string;
}

# A message with an inbound MI (m=1) and optional A-R, but NO DKIM2 chain —
# mirrors what the inbound milter produces for non-DKIM2 mail.
sub mi_only_input {
    my ($raw, $ar) = @_;
    $raw =~ s/\r?\n/\r\n/g;
    my $msg = Email::MIME->new($raw);
    my $mi  = Mail::DKIM2::MessageInstance->calculate($msg);
    my $folded = fold_header("Message-Instance: " . $mi->as_string);
    $folded =~ s/^Message-Instance:\s*//;
    $msg->header_raw_prepend('Message-Instance', $folded);
    $msg->header_raw_prepend('Authentication-Results', $ar) if defined $ar;
    return $msg->as_string;
}

my $cb = DKIM2TestKeys::pubkey_callback();
my %common = (
    sender    => 'a@test1.dkim2.com',         # reflect target (rt of our sig)
    domain    => 'test2.dkim2.com',           # reflector identity (test key)
    selector  => 'sel1',
    mailfrom  => 'reflector-bounces@test2.dkim2.com',  # d= must suffix mf domain
    key       => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
    pubkey_cb => $cb,
    skip_timestamp_check => 1,
);

sub reflected_verifies {
    my ($text) = @_;
    my $v = Mail::DKIM2::Verifier->new; $v->skip_timestamp_check(1);
    $v->set_pubkey_callback($cb); $v->PRINT($text); $v->CLOSE;
    return $v->result;
}

# --- raw + passing input -> signed, no new MI, verifies at the recipient ---
{
    my $in = signed_input("From: a\@test1.dkim2.com\r\nTo: reflector-raw\@dkim2.com\r\nSubject: hi\r\n\r\noriginal body\r\n");
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => 'raw', message => $in);
    is($r->{auth}, 'pass', 'raw: incoming verified');
    is($r->{signed}, 1, 'raw: signed because auth passed');
    like($r->{message}, qr/^DKIM2-Signature:/m, 'raw: has a DKIM2-Signature');
    like($r->{message}, qr/^X-DKIM2-Reflector:.*mode=raw.*signed=yes/m, 'raw: X- header');
    like($r->{message}, qr/^Authentication-Results:/m, 'raw: A-R header');
    my @mi = (Email::MIME->new($r->{message}))->header_raw('Message-Instance');
    is(scalar @mi, 1, 'raw: no NEW MI added (still just m=1)');
    is(reflected_verifies($r->{message}), 'pass', 'raw: reflected message verifies');
    like($r->{message}, qr/^X-DKIM2-Info:.*sw=dkim2-reflector\.pl/ms, 'raw: X-DKIM2-Info present');
    like($r->{message}, qr/^X-DKIM2-Info:[^\r\n]*(?:\r\n[ \t][^\r\n]*)*action=verify=pass \(i=1\.\.1 verified\);\r\nAuthentication-Results:/m,
         'raw: X-DKIM2-Info action=verify=pass directly above Authentication-Results');
    like($r->{message}, qr/^X-DKIM2-Info:[^\r\n]*(?:\r\n[ \t][^\r\n]*)*action=sign d=test2\.dkim2\.com a=rsa-sha256;\r\nDKIM2-Signature:/m,
         'raw: X-DKIM2-Info action=sign directly above the signature');
    unlike($r->{message}, qr/action=mi-m/, 'raw: no mi-m action (no new MI)');
}

# --- failing input (no DKIM2) -> not signed, headers present ---
{
    my $unsigned = "From: x\@example.org\r\nTo: reflector-raw\@dkim2.com\r\nSubject: hi\r\n\r\nhello\r\n";
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => 'raw', message => $unsigned);
    isnt($r->{auth}, 'pass', 'no-DKIM2 input does not pass');
    is($r->{signed}, 0, 'not signed when auth fails');
    unlike($r->{message}, qr/^DKIM2-Signature:/m, 'no reflector signature on fail');
    like($r->{message}, qr/^X-DKIM2-Reflector:.*signed=no/m, 'X- header shows signed=no');
}

# --- subject / body / both: new MI with Recipes; verifies; undo restores ---
for my $case (
    { mode => 'subject', restores_subject => 1, restores_body => 0 },
    { mode => 'body',    restores_subject => 0, restores_body => 1 },
    { mode => 'both',    restores_subject => 1, restores_body => 1 },
) {
    my $m = $case->{mode};
    my $in = signed_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-$m\@test2.dkim2.com\r\nSubject: hello\r\n\r\noriginal body\r\n");
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => $m, message => $in);
    is($r->{signed}, 1, "$m: signed");

    my $msg = Email::MIME->new($r->{message});
    my @mi  = $msg->header_raw('Message-Instance');
    is(scalar @mi, 2, "$m: a new MI was added (now 2)");

    like($msg->header('Subject'), qr/^\Q[DKIM2]\E /, "$m: subject prefixed")
        if $m ne 'body';
    like($r->{message}, qr/Reflected and signed by the DKIM2 reflector/, "$m: footer added")
        if $m ne 'subject';

    is(reflected_verifies($r->{message}), 'pass', "$m: reflected verifies");

    # X-DKIM2-Info records the new MI as mi-m=<N> with the hashed-header list,
    # same format as dkim2-milter.
    my $info = join '', grep { /^X-DKIM2-Info:/ } split /(?<=\r\n)(?=\S)/, ($r->{message} =~ s/\r\n[ \t]/ /gr);
    like($info, qr/sw=dkim2-reflector\.pl/, "$m: X-DKIM2-Info present");
    like($info, qr/action=mi-m=2;/, "$m: X-DKIM2-Info action=mi-m=2");
    like($info, qr/\bhc=\d+\b/, "$m: X-DKIM2-Info has header count");
    like($info, qr/\bhn=\S*subject\S*/, "$m: X-DKIM2-Info header list includes subject");

    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($r->{message}));
    is($undone->header('Subject'), 'hello', "$m: undo restores subject")
        if $case->{restores_subject};
    unlike($undone->body_raw, qr/Reflected and signed/, "$m: undo restores body")
        if $case->{restores_body};
}

# --- redacted: footer added, MI body Recipe null, verifies, but undo can't recover ---
{
    my $in = signed_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-redacted\@test2.dkim2.com\r\nSubject: hi\r\n\r\nsecret body\r\n");
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => 'redacted', message => $in);
    is($r->{signed}, 1, 'redacted: signed');

    # Find the highest-m MI and check its Recipe is b:null (base64 JSON).
    my @mi = (Email::MIME->new($r->{message}))->header_raw('Message-Instance');
    my ($top) = sort {
        Mail::DKIM2::MessageInstance->parse($b)->get_tag('m')
            <=> Mail::DKIM2::MessageInstance->parse($a)->get_tag('m')
    } @mi;
    my ($rtag) = $top =~ /r=([^;\s]+)/;
    ok($rtag, 'redacted: top MI has an r= tag');
    like(decode_base64($rtag), qr/"b"\s*:\s*null/, 'redacted: null body recipe');

    is(reflected_verifies($r->{message}), 'pass', 'redacted: reflected verifies (current content)');

    my $undone = Mail::DKIM2::MessageInstance->undo(Email::MIME->new($r->{message}));
    like($undone->body_raw, qr/Reflected and signed/, 'redacted: body NOT recoverable (footer remains)');
}

# --- damage: signed correctly, then a line appended -> recipient verify FAILS ---
{
    my $in = signed_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-damage\@test2.dkim2.com\r\nSubject: hi\r\n\r\nclean body\r\n");
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => 'damage', message => $in);
    is($r->{signed}, 1, 'damage: a signature was produced');
    like($r->{message}, qr/damage line, breaks the signature/, 'damage: breaking line appended');
    # The signature crypto is intact, but the verifier now enforces §10.7:
    # the top MI body hash no longer matches the post-sign body -> reject.
    is(reflected_verifies($r->{message}), 'fail',
       'damage: verifier rejects (MI body hash mismatch, §10.7)');
    ok(!Mail::DKIM2::MessageInstance->verify(Email::MIME->new($r->{message})),
       'damage: top MI body hash no longer matches content');
}

# --- Postfix local(8) pipe prologue: a leading mbox "From " line is stripped ---
# Postfix prepends a Unix mailbox "From sender timestamp" envelope line (no
# colon) when piping a message to an alias command. If it survives into the
# reflected message it prematurely terminates the header block when the reply
# is re-injected, dumping every real header into the body.
{
    my $prologue = "From a\@test1.dkim2.com  Fri Jun 19 05:07:56 2026\r\n";
    my $in = signed_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-raw\@dkim2.com\r\nSubject: hi\r\n\r\noriginal body\r\n");
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => 'raw', message => $prologue . $in);
    unlike($r->{message}, qr/^From [^\r\n]*\r\n/m,
        'mbox From_ prologue line stripped (no bare "From " line survives)');
    is(reflected_verifies($r->{message}), 'pass',
        'reflected message still verifies after prologue stripped');
}

# --- relaxed domain alignment (PSL-free) ---
{
    no warnings 'once';
    ok( Mail::DKIM2::Reflector::_domains_align('brong.net', 'brong.net'),
        'align: exact match');
    ok( Mail::DKIM2::Reflector::_domains_align('BRONG.NET', 'brong.net'),
        'align: case-insensitive');
    ok( Mail::DKIM2::Reflector::_domains_align('mail.brong.net', 'brong.net'),
        'align: from is a subdomain of d');
    ok( Mail::DKIM2::Reflector::_domains_align('brong.net', 'mail.brong.net'),
        'align: d is a subdomain of from');
    ok( !Mail::DKIM2::Reflector::_domains_align('brong.net', 'evil.example'),
        'align: unrelated domains do not align');
    ok( !Mail::DKIM2::Reflector::_domains_align('notbrong.net', 'brong.net'),
        'align: suffix-without-dot does not count as subdomain');
    ok( !Mail::DKIM2::Reflector::_domains_align('brong.net', ''),
        'align: empty d does not align');
}

# --- From: domain extraction ---
{
    no warnings 'once';
    is( Mail::DKIM2::Reflector::_from_domain(
            "From: a\@brong.net\r\nSubject: x\r\n\r\nbody\r\n"),
        'brong.net', 'from_domain: bare addr-spec');
    is( Mail::DKIM2::Reflector::_from_domain(
            "From: \"Bron G\" <bron\@Brong.NET>\r\nSubject: x\r\n\r\nb\r\n"),
        'brong.net', 'from_domain: display name + angle addr, lowercased');
    is( Mail::DKIM2::Reflector::_from_domain(
            "Subject: x\r\n\r\nbody\r\n"),
        undef, 'from_domain: no From header -> undef');
}

# --- DKIM1 verdict read from Authentication-Results (scoped to authserv-id) ---
{
    no warnings 'once';
    my $base = "From: a\@brong.net\r\nSubject: x\r\n\r\nbody\r\n";
    my $with_ar = sub {
        my ($ar) = @_;
        return "Authentication-Results: $ar\r\n" . $base;
    };
    is( Mail::DKIM2::Reflector::_dkim1_aligned(
            $with_ar->('mail.dkim2.com; dkim=pass header.d=brong.net'),
            'brong.net', 'mail.dkim2.com'),
        'brong.net', 'dkim1: aligned pass is found');
    is( Mail::DKIM2::Reflector::_dkim1_aligned(
            $with_ar->('mail.dkim2.com; dkim=pass header.d=evil.example'),
            'brong.net', 'mail.dkim2.com'),
        undef, 'dkim1: unaligned d is rejected');
    is( Mail::DKIM2::Reflector::_dkim1_aligned(
            $with_ar->('other.host; dkim=pass header.d=brong.net'),
            'brong.net', 'mail.dkim2.com'),
        undef, 'dkim1: foreign authserv-id is ignored');
    is( Mail::DKIM2::Reflector::_dkim1_aligned(
            $with_ar->('mail.dkim2.com; dkim=fail header.d=spoof.com; dkim=pass header.d=brong.net'),
            'brong.net', 'mail.dkim2.com'),
        'brong.net', 'dkim1: one matching pass among several wins');
    is( Mail::DKIM2::Reflector::_dkim1_aligned($base, 'brong.net', 'mail.dkim2.com'),
        undef, 'dkim1: no A-R header -> undef');
    # Only the topmost A-R bearing our authserv-id is trusted: OpenDKIM prepends
    # its genuine result on top, so a sender-forged copy below it is ignored.
    is( Mail::DKIM2::Reflector::_dkim1_aligned(
            "Authentication-Results: mail.dkim2.com; dkim=fail header.d=brong.net\r\n"
          . "Authentication-Results: mail.dkim2.com; dkim=pass header.d=brong.net\r\n"
          . $base,
            'brong.net', 'mail.dkim2.com'),
        undef, 'dkim1: forged A-R below the genuine top one is ignored');
    # Real OpenDKIM output: folded, with CFWS comments that contain a ';'
    # (e.g. "(2048-bit key; unprotected)") and multiple results.
    is( Mail::DKIM2::Reflector::_dkim1_aligned(
            "Authentication-Results: mail.dkim2.com;\r\n"
          . "\tdkim=pass (2048-bit key; unprotected) header.d=brong.net header.i=\@brong.net header.a=rsa-sha256 header.s=fm3 header.b=N0aU1+d9;\r\n"
          . "\tdkim=pass (2048-bit key; unprotected) header.d=messagingengine.com header.i=\@messagingengine.com header.a=rsa-sha256 header.s=fm1 header.b=DZK/hQT9;\r\n"
          . "\tdkim-atps=neutral\r\n"
          . $base,
            'brong.net', 'mail.dkim2.com'),
        'brong.net', 'dkim1: real folded OpenDKIM A-R with comment semicolons parses');
}

my $AUTHSERV = 'mail.dkim2.com';

# --- T2: no DKIM2 chain but aligned DKIM1 -> bridge-signed ---
{
    my $in = mi_only_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-raw\@dkim2.com\r\nSubject: hi\r\n\r\nbody\r\n",
        "$AUTHSERV; dkim=pass header.d=test1.dkim2.com");
    my $r = Mail::DKIM2::Reflector::reflect(
        %common, authserv_id => $AUTHSERV, mode => 'raw', message => $in);
    is($r->{auth},  'none', 'T2: no DKIM2 chain');
    is($r->{dkim1}, 'pass', 'T2: aligned DKIM1 found');
    is($r->{basis}, 'dkim1', 'T2: signing basis is dkim1');
    is($r->{signed}, 1, 'T2: bridge signed');
    like($r->{message}, qr/^DKIM2-Signature:/m, 'T2: has a DKIM2-Signature');
    like($r->{message}, qr/^X-DKIM2-Reflector:.*basis=dkim1.*signed=yes/m, 'T2: X- header');
    is(reflected_verifies($r->{message}), 'pass', 'T2: bridge-signed message verifies');
}

# --- T2 negative: DKIM1 present but not aligned -> not signed ---
{
    my $in = mi_only_input(
        "From: a\@test1.dkim2.com\r\nSubject: hi\r\n\r\nbody\r\n",
        "$AUTHSERV; dkim=pass header.d=unrelated.example");
    my $r = Mail::DKIM2::Reflector::reflect(
        %common, authserv_id => $AUTHSERV, mode => 'raw', message => $in);
    is($r->{basis}, 'none', 'unaligned DKIM1: no signing basis');
    is($r->{signed}, 0, 'unaligned DKIM1: not signed');
    like($r->{message}, qr/^X-DKIM2-Reflector:.*signed=no/m, 'unaligned: signed=no');
}

# --- subdomain alignment bridges ---
{
    my $in = mi_only_input(
        "From: a\@mail.test1.dkim2.com\r\nSubject: hi\r\n\r\nbody\r\n",
        "$AUTHSERV; dkim=pass header.d=test1.dkim2.com");
    my $r = Mail::DKIM2::Reflector::reflect(
        %common, authserv_id => $AUTHSERV, mode => 'raw', message => $in);
    is($r->{signed}, 1, 'subdomain From aligns with parent d -> signed');
}

# --- foreign authserv-id is ignored -> not signed ---
{
    my $in = mi_only_input(
        "From: a\@test1.dkim2.com\r\nSubject: hi\r\n\r\nbody\r\n",
        "evil.relay; dkim=pass header.d=test1.dkim2.com");
    my $r = Mail::DKIM2::Reflector::reflect(
        %common, authserv_id => $AUTHSERV, mode => 'raw', message => $in);
    is($r->{signed}, 0, 'foreign authserv-id A-R is not trusted');
}

# --- broken DKIM2 chain does NOT fall back to DKIM1 ---
{
    my $good = signed_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-raw\@dkim2.com\r\nSubject: hi\r\n\r\nbody\r\n");
    # Append a body line so the DKIM2 body hash no longer matches -> dkim2=fail.
    my $broken = $good . "tampered\r\n";
    $broken =~ s/^(From: a\@test1\.dkim2\.com\r\n)/Authentication-Results: $AUTHSERV; dkim=pass header.d=test1.dkim2.com\r\n$1/m;
    my $r = Mail::DKIM2::Reflector::reflect(
        %common, authserv_id => $AUTHSERV, mode => 'raw', message => $broken);
    is($r->{auth}, 'fail', 'broken chain reports dkim2=fail');
    is($r->{dkim1}, 'pass', 'aligned DKIM1 still reported');
    is($r->{basis}, 'none', 'no bridge on a broken chain');
    is($r->{signed}, 0, 'broken chain + DKIM1 -> not signed');
}

# --- MI is emitted for transforming modes even when unsigned (T3) ---
{
    my $in = mi_only_input("From: a\@nodkim.example\r\nSubject: hi\r\n\r\nbody\r\n");
    my $r = Mail::DKIM2::Reflector::reflect(
        %common, authserv_id => $AUTHSERV, mode => 'body', message => $in);
    is($r->{signed}, 0, 'T3: unsigned (no DKIM2, no DKIM1)');
    my @mi = (Email::MIME->new($r->{message}))->header_raw('Message-Instance');
    is(scalar @mi, 2, 'T3: change-recording MI added even though unsigned');
    like($r->{message}, qr/Reflected and signed by the DKIM2 reflector/, 'T3: footer applied');
}

# --- Delivered-To from the alias pipe must not be hashed into our MI ---
# Postfix local(8) prepends a Delivered-To: header when piping to the alias
# command. It is renamed/dropped before the reply is delivered, so if we hash
# it into m=2 the header hash can never be verified. The reflector must strip
# it before signing.
for my $m (qw(both subject body)) {
    my $base = signed_input(
        "From: a\@test1.dkim2.com\r\nTo: reflector-$m\@test2.dkim2.com\r\nSubject: hi\r\n\r\norig body\r\n");
    my $in = "Delivered-To: reflector-$m\@test2.dkim2.com\r\n" . $base;
    my $r = Mail::DKIM2::Reflector::reflect(%common, mode => $m, message => $in);
    is(reflected_verifies($r->{message}), 'pass',
       "$m: reflected message verifies despite an incoming Delivered-To");
    unlike($r->{message}, qr/^Delivered-To:/mi,
       "$m: Delivered-To stripped from the reflected message");
    my ($info) = $r->{message} =~ /^(X-DKIM2-Info:.*?)(?=\r\n\S)/ms;
    $info =~ s/\r\n[ \t]//g;   # unfold
    unlike($info, qr/\bhn=\S*\bdelivered-to\b/,
       "$m: Delivered-To not listed in the hashed-header set");
}

# --- fresh: originate a brand-new single-instance message ---
{
    my $msg = Mail::DKIM2::Reflector::generate(
        sender     => 'a@test1.dkim2.com',
        domain     => 'test2.dkim2.com',
        selector   => 'sel1',
        key        => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
        mailfrom   => 'reflector-bounces@test2.dkim2.com',
        now        => 1740000000,
        message_id => '<fresh-test@test2.dkim2.com>',
    );
    my $em = Email::MIME->new($msg);
    is($em->header('To'), 'a@test1.dkim2.com', 'fresh: To is the sender');
    like($em->header('From'), qr/<fresh\@test2\.dkim2\.com>/, 'fresh: From is the generator identity');
    my @sigs = $em->header_raw('DKIM2-Signature');
    my @mis  = $em->header_raw('Message-Instance');
    is(scalar @sigs, 1, 'fresh: exactly one signature (no chain)');
    is(scalar @mis, 1, 'fresh: exactly one Message-Instance');
    like($msg, qr/^X-DKIM2-Info:[^\r\n]*(?:\r\n[ \t][^\r\n]*)*action=sign d=test2\.dkim2\.com a=rsa-sha256;\r\nDKIM2-Signature:/m,
         'fresh: X-DKIM2-Info action=sign directly above the signature');
    like($msg, qr/^X-DKIM2-Info:[^\r\n]*(?:\r\n[ \t][^\r\n]*)*action=mi-m=1;(?:[^\r\n]|\r\n[ \t])*\r\nMessage-Instance:/m,
         'fresh: X-DKIM2-Info action=mi-m=1 directly above the Message-Instance');
    unlike($msg, qr/action=generate/, 'fresh: no emitter-specific action');
    unlike($msg, qr/^X-DKIM2-Reflector:/mi, 'fresh: no X-DKIM2-Reflector on the originated message');
    is(Mail::DKIM2::MessageInstance->verify(Email::MIME->new($msg)), 1, 'fresh: MI m=1 verifies');
    is(reflected_verifies($msg), 'pass', 'fresh: generated message verifies end to end');
    # determinism
    my $msg2 = Mail::DKIM2::Reflector::generate(
        sender => 'a@test1.dkim2.com', domain => 'test2.dkim2.com', selector => 'sel1',
        key => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
        mailfrom => 'reflector-bounces@test2.dkim2.com',
        now => 1740000000, message_id => '<fresh-test@test2.dkim2.com>');
    is($msg2, $msg, 'fresh: deterministic for fixed now + message_id');
}

# --- brand: delegated two-signature message on a single MI ---
{
    my %common_brand = (
        sender   => 'brand@test1.dkim2.com',     # the brand
        domain   => 'test2.dkim2.com',           # the dkim2.com-role signer
        selector => 'sel1',
        key      => DKIM2TestKeys::private_key('test2.dkim2.com', 'sel1'),
        mailfrom => 'reflector-bounces@test2.dkim2.com',
        brand_selector => 'dkim2test',
        brand_key => DKIM2TestKeys::private_key('test1.dkim2.com', 'dkim2test'),
        now => 1740000000, message_id => '<brand-test@test2.dkim2.com>',
    );

    # delegated -> two signatures, one MI, verifies
    my $msg = Mail::DKIM2::Reflector::generate_brand(%common_brand, delegated => 1);
    my $em = Email::MIME->new($msg);
    is($em->header('From'), 'dkim2demo@test1.dkim2.com', 'brand: From is dkim2demo@<brand>');
    is($em->header('To'), 'brand@test1.dkim2.com', 'brand: To is the sender');
    # The platform/ESP identity (the reflector domain test2.dkim2.com, and the
    # reflector-brand intake) must not appear in the visible headers.
    unlike($em->header('From').'|'.$em->header('To').'|'.$em->header('Subject'),
           qr/test2\.dkim2\.com|reflector-brand/, 'brand: platform identity not in visible From/To/Subject');
    my @sigs = $em->header_raw('DKIM2-Signature');
    my @mis  = $em->header_raw('Message-Instance');
    is(scalar @sigs, 2, 'brand: two signatures');
    is(scalar @mis, 1, 'brand: one Message-Instance');
    my @sign_info = ($msg =~ /action=sign d=([\w.-]+) a=rsa-sha256;/g);
    is_deeply(\@sign_info, ['test2.dkim2.com', 'test1.dkim2.com'],
              'brand: a sign field per signature, platform above brand');
    like($msg, qr/action=mi-m=1;/, 'brand: mi-m=1 recorded');
    unlike($msg, qr/action=brand/, 'brand: no emitter-specific action');
    like("@sigs", qr/\bd=test1\.dkim2\.com\b/, 'brand: i=1 signs as the brand domain');
    like("@sigs", qr/\bd=test2\.dkim2\.com\b/, 'brand: i=2 signs as dkim2.com role');
    is(reflected_verifies($msg), 'pass', 'brand: two-sig message verifies (chain of custody ok)');
    like($msg, qr/\Qsent for test1.dkim2.com\E/, 'brand: body names the brand domain (no $bd apostrophe bug)');

    # not delegated -> fresh style with an error body, single signature
    my $err = Mail::DKIM2::Reflector::generate_brand(%common_brand, delegated => 0);
    my $eem = Email::MIME->new($err);
    my @esigs = $eem->header_raw('DKIM2-Signature');
    is(scalar @esigs, 1, 'brand(no cname): single signature');
    like($eem->header('From'), qr/<fresh\@test2\.dkim2\.com>/, 'brand(no cname): fresh From identity');
    like($err, qr/dkim2test\._domainkey/, 'brand(no cname): body explains the missing CNAME');

    # nd variant -> i=1 carries nd=<platform> instead of mf=/rt= (draft-03 §9.3)
    my $ndmsg = Mail::DKIM2::Reflector::generate_brand(%common_brand, delegated => 1, nd => 1);
    my $ndem = Email::MIME->new($ndmsg);
    my %byi = map { Mail::DKIM2::Signature->parse($_)->sequence => Mail::DKIM2::Signature->parse($_) }
              $ndem->header_raw('DKIM2-Signature');
    is(scalar(keys %byi), 2, 'brand-nd: two signatures');
    is($byi{1}->next_domain, 'test2.dkim2.com', 'brand-nd: i=1 has nd=<platform domain>');
    is($byi{1}->mail_from, undef, 'brand-nd: i=1 omits mf=');
    is($byi{1}->rcpt_to,   undef, 'brand-nd: i=1 omits rt=');
    ok(defined $byi{2}->mail_from, 'brand-nd: i=2 keeps real mf=');
    is(scalar(() = $ndmsg =~ /action=sign d=/g), 2, 'brand-nd: a sign field per signature');
    unlike($ndmsg, qr/action=brand/, 'brand-nd: no emitter-specific action');
    is(reflected_verifies($ndmsg), 'pass', 'brand-nd: nd= chain verifies');
}

# --- key fetch temperrors -> reflect UNSIGNED, never drop the message ---------
#
# A sender whose chain we cannot verify because of a transient DNS failure must
# still get their mail back, unsigned.  Previously the croak from the pubkey
# fetch escaped the verifier and aborted reflect() outright, so every
# reflector-* address went silent for that sender -- no reply, no bounce.
#
# The DKIM1 bridge deliberately does NOT apply here: it is reserved for
# auth='none' (no DKIM2 chain at all).  A chain we failed to check is not a
# chain we should vouch for, so basis stays 'none'.
{
    my $in = signed_input("From: a\@test1.dkim2.com\r\nTo: reflector-raw\@dkim2.com\r\nSubject: hi\r\n\r\noriginal body\r\n");

    my $r = eval {
        Mail::DKIM2::Reflector::reflect(
            %common, mode => 'raw', message => $in,
            pubkey_cb => sub { die "TEMPERROR: DNS lookup failed: SERVFAIL\n" },
        );
    };
    my $err = $@;

    ok($r, 'temperror: reflect() returns a message instead of dying')
        or diag("reflect died: $err");

  SKIP: {
        skip 'reflect() died', 6 unless $r;
        is($r->{auth},   'temperror', 'temperror: auth reported as temperror');
        is($r->{basis},  'none',      'temperror: no signing basis (DKIM1 bridge not used)');
        is($r->{signed}, 0,           'temperror: reflected unsigned');
        like($r->{message}, qr/^X-DKIM2-Reflector:.*auth=temperror.*signed=no/m,
            'temperror: X-DKIM2-Reflector reports auth=temperror, signed=no');
        like($r->{message}, qr/^Authentication-Results:.*dkim2=temperror/m,
            'temperror: A-R reports dkim2=temperror');
        like($r->{message}, qr/^Authentication-Results:.*dkim2=temperror \([^()]*SERVFAIL[^()]*\)/m,
            'temperror: A-R carries the reason, with no unbalanced parens');
    }
}

done_testing;
