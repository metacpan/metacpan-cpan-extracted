#!/usr/bin/perl -w
# The draft -07 shared behaviour tests (U1..D1), the cases every
# implementation in the interop repository runs with the same domains,
# addresses and expected strings, plus the -07 review-focus cases.
#
# Every signature is made with test1.dkim2.com's sel1 key whatever its d=,
# and the verifier is given that key for every domain (t/lib/Spec07Fixture.pm),
# so the table's domains need no DNS entries.
use 5.020;
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';

use Mail::DKIM2::Signer;
use Mail::DKIM2::Gate;
use Mail::DKIM2::DSN;
use Email::MIME;
use Spec07Fixture;

*message        = \&Spec07Fixture::message;
*add_mi         = \&Spec07Fixture::add_mi;
*add_sig        = \&Spec07Fixture::add_sig;
*mi_with_recipe = \&Spec07Fixture::mi_with_recipe;
*recipe_json    = \&Spec07Fixture::top_recipe_json;
*verify         = \&Spec07Fixture::verify;

my %HOP1 = (d => 'example.com', mf => '<a@example.com>', rt => ['<list@lists.example.org>']);
my %HOP2 = (d => 'example.org', mf => '<list-bounces@lists.example.org>', rt => ['<b@example.net>']);

sub verdict {
    my ($text, %o) = @_;
    my $v = verify($text, %o);
    return ($v->result, $v->details // '');
}

sub is_pass {
    my ($text, $name, %o) = @_;
    my ($r, $d) = verdict($text, %o);
    is($r, 'pass', $name) or diag($d);
}

sub is_error {
    my ($text, $result, $details, $name, %o) = @_;
    my ($r, $d) = verdict($text, %o);
    is($r, $result, "$name: $result");
    is($d, $details, "$name: details");
}

# A one-hop message signed by example.com, From a@example.com.
my $HOP1_TEXT = add_sig(add_mi(message()), %HOP1);

# --- U1: a header value that is valid UTF-8 goes in a "d" step ----------------
{
    my $orig = message(subject => "caf\xC3\xA9");
    my $t1 = add_sig(add_mi($orig), %HOP1);
    (my $changed = $t1) =~ s/^Subject: caf\xC3\xA9/Subject: x/m;
    my $t2 = add_mi($changed, $t1);
    like(recipe_json($t2), qr/"h":\{"subject":\[\{"d":\["caf\xC3\xA9"\]\}\]\}/,
        'U1: header recipe step is {"d":["café"]}');
    is_pass(add_sig($t2, %HOP2), 'U1: chain verifies');
}

# --- U2: a body line that is not UTF-8 goes in a "u" step ---------------------
{
    my $t1 = add_sig(add_mi(message(body => "caf\xE9\r\n")), %HOP1);
    (my $changed = $t1) =~ s/\r\n\r\ncaf\xE9\r\n\z/\r\n\r\nx\r\n/;
    my $t2 = add_mi($changed, $t1);
    like(recipe_json($t2), qr/"b":\[\{"u":\["Y2Fm6Q=="\]\}\]/,
        'U2: body recipe step is {"u":["Y2Fm6Q=="]}');
    is_pass(add_sig($t2, %HOP2), 'U2: chain verifies');

    # UTF-8 non-ASCII still goes in "d", and undoes byte-exactly.
    my $n1 = add_sig(add_mi(message(body => "na\xC3\xAFve\r\n")), %HOP1);
    (my $nchanged = $n1) =~ s/\r\n\r\nna\xC3\xAFve\r\n\z/\r\n\r\nx\r\n/;
    my $n2 = add_mi($nchanged, $n1);
    like(recipe_json($n2), qr/"b":\[\{"d":\["na\xC3\xAFve"\]\}\]/,
        'U2: a UTF-8 body line is a "d" step');
    is_pass(add_sig($n2, %HOP2), 'U2: the UTF-8 body line undoes byte-exactly');
}

# --- U3, U4, U5, K2: malformed Recipes are invalid JSON -------------------------
{
    my %bad = (
        'U3 u not canonical (pad bits)' => '{"b":[{"u":["QR=="]}]}',
        'U4 the old b step'             => '{"b":[{"b":["eA=="]}]}',
        'U4 two keys in a step'         => '{"b":[{"c":[1,1],"d":["x"]}]}',
        'U4 an empty step'              => '{"b":[{}]}',
        'U5 u decodes to a CR'          => '{"b":[{"u":["YQ1i"]}]}',
        'U5 h with no properties'       => '{"h":{}}',
        'U5 neither h nor b'            => '{"x":1}',
        'K2 header name twice (case)'   => '{"h":{"Subject":[],"subject":[]}}',
        'K2 step key twice (case)'      => '{"b":[{"c":[1,1],"C":[1,1]}]}',
        'c is not two integers'         => '{"b":[{"c":["1",1]}]}',
        'c starts at 0'                 => '{"b":[{"c":[0,1]}]}',
        'u not padded'                  => '{"b":[{"u":["eA"]}]}',
        'd is not UTF-8'                => qq({"b":[{"d":["caf\xE9"]}]}),
        'a header Recipe is not array'  => '{"h":{"subject":{"c":[1,1]}}}',
    );
    for my $name (sort keys %bad) {
        my $t = add_sig(mi_with_recipe($HOP1_TEXT, $bad{$name}), %HOP2);
        is_error($t, 'permerror', 'PERMERROR: Message-Instance m=2 contains invalid JSON', $name);
    }
}

# --- K1: keys match without regard to case --------------------------------------
{
    for my $json ('{"h":{"subject":[{"c":[1,1]}]}}', '{"H":{"Subject":[{"C":[1,1]}]}}',
                  '{"B":[{"C":[1,1]}]}') {
        my $t = add_sig(mi_with_recipe($HOP1_TEXT, $json), %HOP2);
        is_pass($t, "K1: $json verifies");
    }
}

# --- No r= at m=2: no change (-07 sections 9 and 12.1) ---------------------------
{
    (my $no_r = mi_with_recipe($HOP1_TEXT, '{}')) =~ s/; r=[^;]*;/;/;
    unlike($no_r, qr/^Message-Instance: m=2;[^\r\n]*r=/m, 'no-change MI: no r= tag');
    is_pass(add_sig($no_r, %HOP2), 'no-change MI at m=2 passes');
    is_pass(add_sig($no_r, %HOP2), 'no-change MI at m=2 passes (undo walk)', StreamBody => 0);
    # The same instance over a changed message: m=1 then fails its hash.
    (my $changed = $HOP1_TEXT) =~ s/^Subject: test/Subject: other/m;
    (my $lie = mi_with_recipe($changed, '{}')) =~ s/; r=[^;]*;/;/;
    is_error(add_sig($lie, %HOP2), 'fail', 'FAIL: Message-Instance m=1 header hash sha256 mismatch',
        'a no-change MI over a change');
}

# --- F1: donotmodify is just a flag now -----------------------------------------
{
    my $t1 = add_sig(add_mi(message()), %HOP1, f => ['donotmodify']);
    (my $changed = $t1) =~ s/^Subject: test/Subject: [list] test/m;
    is_pass(add_sig(add_mi($changed, $t1), %HOP2), 'F1: a later hop may modify after f=donotmodify');
}

# --- F2: the exploded flag --------------------------------------------------------
{
    my $key = Spec07Fixture::key();
    my $flags = sub {
        my ($text, %o) = @_;
        my $s = Mail::DKIM2::Signer->new(Selector => 'sel1', Key => $key, %o);
        $s->load($text);
        is($s->result, 'signed', 'F2: signed') or diag($s->details);
        return ($s, join ',', @{ $s->signature->flags // [] });
    };
    my $m1 = add_mi(message());
    my %o1 = (Domain => 'example.com', MailFrom => 'a@example.com', RcptTo => ['list@lists.example.org']);
    my ($s1, $f1) = $flags->($m1, %o1, Exploded => 1);
    unlike($f1, qr/exploded/, 'F2: exploded is never set at i=1');
    my (undef, $f1b) = $flags->($m1, %o1, Flags => ['exploded', 'feedback']);
    is($f1b, 'feedback', 'F2: a caller-supplied exploded is dropped at i=1');

    my $t1 = $s1->as_string . "\r\n" . $m1;
    my %o2 = (Domain => 'example.org', MailFrom => 'list-bounces@lists.example.org');
    my ($s2, $f2) = $flags->($t1, %o2, RcptTo => ['b@example.net'], Exploded => 1);
    like($f2, qr/(?:^|,)exploded(?:,|$)/, 'F2: exploded requested at i=2 is set');
    is_pass($s2->as_string . "\r\n" . $t1, 'F2: the exploded i=2 verifies');
    my (undef, $f3) = $flags->($t1, %o2, RcptTo => ['b@example.net', 'c@example.net']);
    like($f3, qr/(?:^|,)exploded(?:,|$)/, 'F2: two rt= addresses at i=2 set exploded');
    my ($s4, $f4) = $flags->($t1, %o2, RcptTo => ['b@example.net']);
    unlike($f4, qr/exploded/, 'F2: one rt= address and no request: no exploded');
    $s4->sign_for_recipient(['b@example.net', 'c@example.net']);
    like(join(',', @{ $s4->signature->flags // [] }), qr/exploded/,
        'F2: sign_for_recipient with two addresses sets exploded');
    $s4->sign_for_recipient('b@example.net');
    unlike(join(',', @{ $s4->signature->flags // [] }), qr/exploded/,
        'F2: ... and one address clears it again');
}

# --- C1..C6: Chain of Custody -------------------------------------------------------
{
    my $c1 = add_sig($HOP1_TEXT, d => 'example.org', mf => '<>', rt => ['<a@example.com>']);
    is_pass($c1, 'C1: mf=<> hop whose d= matches the previous rt=');

    # Postfix-style addresses: uppercase and a trailing dot.
    my $odd = add_sig(add_mi(message()), d => 'example.com', mf => '<A@Example.COM.>',
                      rt => ['<list@Lists.Example.ORG.>']);
    is_pass(add_sig($odd, d => 'example.org', mf => '<>', rt => ['<a@example.com>']),
        'C1: uppercase and trailing-dot domains in mf=/rt= match');
    is_pass(add_sig($odd, %HOP2), 'C1: ... and an mf= hop matches them too');

    my $c2 = add_sig($HOP1_TEXT, d => 'other.net', mf => '<>', rt => ['<a@example.com>']);
    is_error($c2, 'permerror', 'PERMERROR: DKIM2-Signature i=2 d= does not match the rt= of i=1', 'C2');
    # -07 section 13.1: the top signature and top instance are fine, so it
    # is Provisionally Verified all the same.
    my $pv = verify($c2);
    ok($pv->provisionally_verified, 'C2: still Provisionally Verified');
    is($pv->details, 'PERMERROR: DKIM2-Signature i=2 d= does not match the rt= of i=1',
        'C2: ... and the verdict is left alone');
    (my $bad_top = $c2) =~ s/^Subject: test/Subject: changed/m;
    ok(!verify($bad_top)->provisionally_verified, 'a top instance that does not match: not PV');
    ok(!verify(add_sig($HOP1_TEXT, d => 'example.org', nd => 'x.example'))->provisionally_verified,
        'a top nd=: not PV');

    my $base3 = add_sig(add_mi(message()), d => 'example.com', mf => '<a@example.com>',
                        rt => ['<x@mail.example.org>']);
    my $nd = add_sig($base3, d => 'example.org', nd => 'fwd.example.net');
    is_pass(add_sig($nd, d => 'fwd.example.net', mf => '<b@fwd.example.net>', rt => ['<c@dest.example>']),
        'C3: rt= -> nd= hop -> the domain nd= names');
    my $swap = add_sig(add_mi(message()), d => 'example.com', mf => '<a@example.com>',
                       rt => ['<x@example.org>']);
    $swap = add_sig($swap, d => 'mail.example.org', nd => 'fwd.example.net');
    $swap = add_sig($swap, d => 'fwd.example.net', mf => '<b@fwd.example.net>', rt => ['<c@dest.example>']);
    is_error($swap, 'permerror', 'PERMERROR: DKIM2-Signature i=2 d= does not match the rt= of i=1',
        'C3 swapped (only the rt= domain is shortened)');

    my $c4 = add_sig($nd, d => 'other.example', mf => '<b@other.example>', rt => ['<c@dest.example>']);
    is_error($c4, 'permerror', 'PERMERROR: DKIM2-Signature i=2 nd= does not match', 'C4');

    my $lit = add_sig(add_mi(message()), d => 'example.com', mf => '<a@example.com>',
                      rt => ['<x@[192.0.2.1]>']);
    my ($r5, $d5) = verdict(add_sig($lit, d => 'example.org', mf => '<y@[192.0.2.1]>',
                                    rt => ['<c@dest.example>']));
    is($r5, 'permerror', 'C5: a domain literal never matches');
    like($d5, qr/\APERMERROR: DKIM2-Signature i=2 (?:mf= does not match the rt= of i=1|MAIL FROM and d= do not match)\z/,
        'C5: details') or diag($d5);

    my $c6 = add_sig(add_mi(message()), d => 'example.com', mf => '<a@example.net>',
                     rt => ['<list@lists.example.org>']);
    is_error($c6, 'permerror', 'PERMERROR: DKIM2-Signature i=1 MAIL FROM and d= do not match', 'C6');
}

# --- A1..A4: From must be Authentic -----------------------------------------------
{
    is_pass($HOP1_TEXT, 'A1: From A <a@example.com>, d=example.com');
    my $net = add_sig(add_mi(message()), d => 'example.net', mf => '<a@example.net>',
                      rt => ['<list@lists.example.org>']);
    is_error($net, 'permerror', 'PERMERROR: DKIM2-Signature i=1 matching From is not authentic',
        'A1: d=example.net');
    is_pass(add_sig(add_mi(message(from => 'a@sub.example.com')), %HOP1), 'A1: a@sub.example.com');
    is_pass(add_sig(add_mi(message(from => "=?utf-8?q?Caf=C3=A9?=\r\n <a\@example.com>")), %HOP1),
        'A1: a folded From with an RFC 2047 display name');
    is_pass(add_sig(add_mi(message(from => '"Smith, A" <a@example.com> (comment, here)')), %HOP1),
        'A1: commas inside a quoted name and a comment');
    # The last: display text with no angle brackets is not one mailbox
    # (final review T3); all five implementations agree.
    for my $from ('a@example.com, b@example.com', 'a@[192.0.2.1]', 'group: a@example.com;',
                  '"A" <a@example.com>, <b@example.com>', 'A a@example.com') {
        is_error(add_sig(add_mi(message(from => $from)), %HOP1), 'permerror',
            'PERMERROR: DKIM2-Signature i=1 matching From is not authentic', "A1: From: $from");
    }
    my $two = message(extra => "From: a\@example.com\r\n");
    is_error(add_sig(add_mi($two), %HOP1), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 matching From is not authentic', 'A1: two From fields');
    my $none = "To: b\@example.net\r\nSubject: no from\r\n\r\nbody\r\n";
    is_error(add_sig(add_mi($none), %HOP1), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 matching From is not authentic', 'A1: no From field');

    # A2: the list changes From in m=2 and signs i=2.
    (my $changed = $HOP1_TEXT) =~ s/^From: .*$/From: list\@lists.example.org\r/m;
    is_pass(add_sig(add_mi($changed, $HOP1_TEXT), %HOP2), 'A2: From changed in m=2, signed by example.org');
    (my $elsewhere = $HOP1_TEXT) =~ s/^From: .*$/From: x\@elsewhere.net\r/m;
    is_error(add_sig(add_mi($elsewhere, $HOP1_TEXT), %HOP2), 'permerror',
        'PERMERROR: DKIM2-Signature i=2 matching From is not authentic', 'A2: From changed to elsewhere.net');
    # ... and the original From still has to be Authentic against i=1.
    my $bad1 = add_sig(add_mi(message(from => 'a@example.net')), d => 'example.com',
                       mf => '<a@example.com>', rt => ['<list@lists.example.org>']);
    (my $fixed = $bad1) =~ s/^From: .*$/From: list\@lists.example.org\r/m;
    is_error(add_sig(add_mi($fixed, $bad1), %HOP2), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 matching From is not authentic', 'A2: a From before the change is checked too');
    is_error(add_sig(add_mi($fixed, $bad1), %HOP2), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 matching From is not authentic', 'A2: ... with the undo walk',
        StreamBody => 0);

    # Ruling 19: i=1 is checked against the From at state m(i=1). An
    # author's From in an unsigned ingress m=1 that the list rewrote in m=2
    # before signing i=1 over m=2 was never covered, so it is not checked.
    my $ingress = add_mi(message(from => 'A <a@elsewhere.net>'));
    (my $rewritten = $ingress) =~ s/^From: .*$/From: list\@lists.example.org\r/m;
    is_pass(add_sig(add_mi($rewritten, $ingress), %HOP2),
        'Ruling 19: From replaced before the first signature is not checked');
    is_pass(add_sig(add_mi($rewritten, $ingress), %HOP2),
        'Ruling 19: ... with the undo walk', StreamBody => 0);
    my $ingress_ok = add_mi(message());
    (my $tagged = $ingress_ok) =~ s/^Subject: .*$/Subject: [list] test\r/m;
    is_error(add_sig(add_mi($tagged, $ingress_ok), %HOP2), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 matching From is not authentic',
        'Ruling 19: the From at state m(i=1) is checked against i=1');

    # A3: the signer refuses.
    my $s = Mail::DKIM2::Signer->new(Domain => 'example.com', Selector => 'sel1',
        Key => Spec07Fixture::key(), MailFrom => 'a@example.com', RcptTo => ['b@example.net']);
    $s->load(add_mi(message(from => 'a@example.net')));
    is($s->result, 'fail', 'A3: the signer refuses');
    is($s->details, 'From header field is not Authentic for d=example.com', 'A3: details');

    # A4: a U-label From domain matches its A-label d=.
    is_pass(add_sig(add_mi(message(from => "u\@b\xC3\xBCcher.example")),
                    d => 'xn--bcher-kva.example', mf => '<u@xn--bcher-kva.example>',
                    rt => ['<list@lists.example.org>']),
        'A4: From u@bücher.example, d=xn--bcher-kva.example');
}

# --- T1: timestamps -----------------------------------------------------------------
{
    is_pass(add_sig(add_mi(message()), %HOP1, t => time + 7200), 'T1: two hours ahead');
    is_error(add_sig(add_mi(message()), %HOP1, t => time + 172800), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 signature is from the future', 'T1: two days ahead');
    is_error(add_sig(add_mi(message()), %HOP1, t => time - 15 * 86400), 'permerror',
        'PERMERROR: DKIM2-Signature i=1 signature expired', 'T1: fifteen days old');
}

# --- D1: no DSN for a null top mf= ----------------------------------------------------
{
    my %dsn = (Signer => Mail::DKIM2::Signer->new(Domain => 'example.net', Selector => 'sel1',
                   Key => Spec07Fixture::key(), MailFrom => '<>'),
               ReportingMTA => 'example.net', PubkeyCallback => Spec07Fixture::pubkey_cb());
    my $null_top = add_sig($HOP1_TEXT, d => 'example.org', mf => '<>', rt => ['<b@example.net>']);
    my ($ok, $why) = Mail::DKIM2::DSN->may_generate(Message => $null_top,
        PubkeyCallback => Spec07Fixture::pubkey_cb());
    ok(!$ok, 'D1: no DSN when the top mf= is <>');
    like($why, qr/mf= is <>/, 'D1: ... saying why');
    ok(!eval { Mail::DKIM2::DSN->generate(Message => $null_top, %dsn); 1 }, 'D1: generate refuses');
    like($@, qr/mf= is <>/, 'D1: ... with the reason');
    ok(!eval { Mail::DKIM2::DSN->generate(Message => $null_top, To => 'a@example.com', %dsn); 1 },
        'D1: ... even given a To');

    ($ok, $why) = Mail::DKIM2::DSN->may_generate(Message => message(),
        PubkeyCallback => Spec07Fixture::pubkey_cb());
    ok(!$ok, 'no DSN for a message that is not Provisionally Verified');
    (my $tampered = $HOP1_TEXT) =~ s/^Subject: test/Subject: changed/m;
    ($ok, $why) = Mail::DKIM2::DSN->may_generate(Message => $tampered,
        PubkeyCallback => Spec07Fixture::pubkey_cb());
    ok(!$ok, 'no DSN when the top instance does not match');

    ($ok, $why) = Mail::DKIM2::DSN->may_generate(Message => $HOP1_TEXT,
        PubkeyCallback => Spec07Fixture::pubkey_cb());
    ok($ok, 'a Provisionally Verified message may get a DSN') or diag($why);
    my $out = Mail::DKIM2::DSN->generate(Message => $HOP1_TEXT, %dsn);
    is($out->{send_to}, '<a@example.com>', 'the DSN goes to the top mf=');
    is_pass($out->{raw}, 'the DSN verifies');

    # Propagation: once the forwarder's hop is stripped, the mf= the DSN
    # would go to is <>.
    my $bounce = add_sig(add_mi(message()), d => 'example.com', mf => '<>', rt => ['<fwd@example.org>']);
    $bounce = add_sig($bounce, d => 'example.org', mf => '<fwd@example.org>', rt => ['<dest@example.net>']);
    my $report = Email::MIME->create(
        attributes => { content_type => 'multipart/report', encoding => '7bit' },
        header_str => [ From => 'postmaster@example.net', To => 'fwd@example.org', Subject => 'failure' ],
        parts => [
            Email::MIME->create(attributes => { content_type => 'text/plain', encoding => '7bit' },
                                body => "failed\r\n"),
            Email::MIME->create(attributes => { content_type => 'message/delivery-status' },
                                body => "Reporting-MTA: dns; example.net\r\n"),
            Email::MIME->create(attributes => { content_type => 'message/rfc822' }, body => $bounce),
        ])->as_string;
    ok(!eval { Mail::DKIM2::DSN->propagate(Message => $report, ForwarderDomain => 'example.org',
        Signer => Mail::DKIM2::Signer->new(Domain => 'example.org', Selector => 'sel1',
                      Key => Spec07Fixture::key(), MailFrom => '<>'),
        SkipAuthentication => 1); 1 }, 'D1: propagate refuses');
    like($@, qr/mf= is <>/, 'D1: ... because the upstream mf= is <>');
}

# --- Review focus: the signer gate ------------------------------------------------------
{
    my %gate = (PubkeyCallback => Spec07Fixture::pubkey_cb());
    my $key = Spec07Fixture::key();

    # A top nd= naming the outbound signer's own d=.
    my $base = add_sig(add_mi(message()), d => 'example.com', mf => '<a@example.com>',
                       rt => ['<x@mail.example.org>']);
    my $nd = add_sig($base, d => 'example.org', nd => 'fwd.example.net');
    my $g = Mail::DKIM2::Gate->check($nd, SigningDomain => 'fwd.example.net', %gate);
    ok($g->{ok}, 'gate: a top nd= naming our d= may be extended') or diag($g->{message});
    my $s = Mail::DKIM2::Signer->new(Domain => 'fwd.example.net', Selector => 'sel1', Key => $key,
        MailFrom => 'b@fwd.example.net', RcptTo => ['c@dest.example']);
    $s->load($nd);
    is($s->result, 'signed', 'gate: ... and signs') or diag($s->details);
    is_pass($s->as_string . "\r\n" . $nd, 'gate: ... and the result verifies');
    is_error($nd, 'permerror', 'PERMERROR: DKIM2-Signature i=2 unexpected nd= tag', 'inbound top nd=');

    # From changed in an unsigned top instance.
    (my $changed = $HOP1_TEXT) =~ s/^From: .*$/From: list\@lists.example.org\r/m;
    my $unsigned = add_mi($changed, $HOP1_TEXT);
    $g = Mail::DKIM2::Gate->check($unsigned, SigningDomain => 'example.org', %gate);
    ok($g->{ok}, 'gate: From changed in an unsigned top instance') or diag($g->{message});
    my %list = (Selector => 'sel1', Key => $key, MailFrom => 'list-bounces@lists.example.org',
                RcptTo => ['b@example.net']);
    $s = Mail::DKIM2::Signer->new(Domain => 'example.org', %list);
    $s->load($unsigned);
    is($s->result, 'signed', 'gate: signs with a matching d=') or diag($s->details);
    is_pass($s->as_string . "\r\n" . $unsigned, 'gate: ... and it verifies');
    $s = Mail::DKIM2::Signer->new(Domain => 'other.net', %list);
    $s->load($unsigned);
    is($s->result, 'fail', 'gate: refuses with another d=');
    is($s->details, 'From header field is not Authentic for d=other.net', 'gate: ... with the A3 string');

    # Signing an unchanged forward checks nothing about From.
    $s = Mail::DKIM2::Signer->new(Domain => 'other.net', %list, MailFrom => 'f@other.net');
    $s->load($HOP1_TEXT);
    is($s->result, 'signed', 'signer: forwarding without a From change needs no From match');
}

# --- C9: the primary error is the first in -07 section 14 order ------------------------
{
    # DKIM2-Signature i=$i's signature value with one base64 character
    # changed mid-value: still well-formed, no longer valid.
    my $corrupt = sub {
        my ($text, $i) = @_;
        $text =~ s{(DKIM2-Signature:\s*i=$i;.*?sel1:rsa-sha256:\s*.{10})(.)}
                  {$1 . ($2 eq 'A' ? 'B' : 'A')}se or die "no i=$i";
        return $text;
    };
    (my $from = $HOP1_TEXT) =~ s/^From: .*$/From: a\@evil.example/m or die;
    is_error($from, 'fail', 'FAIL: Message-Instance m=1 header hash sha256 mismatch',
        'C9: From changed after signing (14.7 before 14.8)');
    is_error(add_sig(add_mi(message()), %HOP1, mf => '<a@example.net>', t => time - 15 * 86400),
        'permerror', 'PERMERROR: DKIM2-Signature i=1 signature expired',
        'C9: expired and custody (14.3 before 14.4)');
    is_error(add_sig(add_mi(message()), d => 'example.com', nd => 'fwd.example.net', t => time - 15 * 86400),
        'permerror', 'PERMERROR: DKIM2-Signature i=1 signature expired',
        'C9: expired and a top nd= (14.3 before 14.4)');
    is_error($corrupt->(add_sig(add_mi(message()), %HOP1, mf => '<a@example.net>'), 1),
        'permerror', 'PERMERROR: DKIM2-Signature i=1 MAIL FROM and d= do not match',
        'C9: custody and a bad signature (14.4 before 14.6)');
    (my $subj = $corrupt->($HOP1_TEXT, 1)) =~ s/^Subject: .*$/Subject: tampered/m or die;
    is_error($subj, 'fail', 'FAIL: DKIM2-Signature i=1 selector sel1 incorrect signature',
        'C9: a bad signature and a header hash (14.6 before 14.7)');
}

done_testing;
