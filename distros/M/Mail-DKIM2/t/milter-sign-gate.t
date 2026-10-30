#!/usr/bin/perl
# The authentication_milter DKIM2Sign handler applies Mail::DKIM2::Gate before
# it signs, as bin/dkim2-milter and bin/dkim2sign do.  The cases mirror the
# signer-gate fixtures (util/build-signer-gate-fixtures.py), built here in Perl
# as they arrive at the hop that is about to sign:
#
#   fresh                  SIGN, output byte-identical to signing it directly
#   valid-chain            SIGN
#   broken-signature       REFUSE (upstream-chain; no X-DKIM2-Info)
#   broken-mi-chain        REFUSE (the Verifier undoes the signed chain: upstream-chain)
#   mi-only                SIGN (unsigned m=1 + m=2, no signature)
#   mi-only-broken         REFUSE, X-DKIM2-Info not-signed=broken-mi-chain
#   mi-only-null           REFUSE, X-DKIM2-Info not-signed=null-body-recipe;
#                          SIGN with allow_null_body_recipe
#   null-top (unsigned)    REFUSE, X-DKIM2-Info not-signed=null-body-recipe;
#                          SIGN with allow_null_body_recipe (+ action=null-body-recipe)
#   null-top-signed        SIGN without the option (+ action=null-body-recipe)
#   fake-cover-*           REFUSE, with or without the option
#   nd-to-us / nd-to-other SIGN / REFUSE
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use MockAuthMilter qw(run_sign);
use Email::MIME;
use File::Temp qw(tempdir);
use Mail::DKIM2::Common qw(fold_header parse_mime);
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::MessageStore;
use Mail::DKIM2::Signer;
use Mail::DKIM2::Verifier;
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
    my ($msg, $dom, $mf, $rt, %extra) = @_;
    my $s = Mail::DKIM2::Signer->new(
        Domain => $dom, Selector => 'sel1',
        Key => DKIM2TestKeys::private_key($dom, 'sel1'),
        ($extra{NextDomain} ? (NextDomain => $extra{NextDomain})
                            : (MailFrom => $mf, RcptTo => [$rt])),
        Timestamp => time());
    $s->PRINT($msg); $s->CLOSE;
    die "fixture signer: " . $s->result_detail . "\n" unless $s->result eq 'signed';
    return $s->as_string . $EOL . $msg;
}

# i=1/m=1 by test1, to the list at test2.
sub signed_m1 {
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    return sign_as("Message-Instance: " . $mi->as_string . $EOL . $PLAIN,
        'test1.dkim2.com', 'author@test1.dkim2.com', 'list@test2.dkim2.com');
}

# m=1 alone, unsigned (a list manager that adds instances but never signs).
# The signer that comes after it is i=1, so (-08 section 11) the From has
# to be in its domain from m=1 on: the list rewrote it already.
sub unsigned_m1 {
    (my $plain = $PLAIN) =~ s/^From: [^\r\n]*/From: List <list\@test2.dkim2.com>/m;
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($plain));
    return "Message-Instance: " . $mi->as_string . $EOL . $plain;
}

# The list at test2 tags the subject and adds a footer, recording unsigned m=2.
#   null     => m=2 has a null body Recipe
#   forge    => the To: is changed too, but the header Recipe hides it
#   unsigned => on top of an unsigned m=1 instead of i=1/m=1 (mi-only)
sub list_post {
    my (%o) = @_;
    my $signed = $o{unsigned} ? unsigned_m1() : signed_m1();
    my $mod = $signed;
    $mod =~ s/^Subject: /Subject: [list] /m;
    $mod =~ s/^To: .*$/To: tampered\@example.net/m if $o{forge};
    $mod .= "--$EOL" . "footer$EOL";
    my $mi2 = Mail::DKIM2::MessageInstance->calculate(
        Email::MIME->new($mod), Email::MIME->new($signed));
    $mi2->set_null_body_recipe if $o{null};
    if ($o{forge}) {
        my $rh = $mi2->{bits}{rh};
        delete $rh->{$_} for grep { lc($_) eq 'to' } keys %$rh;
    }
    return "Message-Instance: " . $mi2->as_string . $EOL . $mod;
}

my $PUBKEY_CB = DKIM2TestKeys::pubkey_callback();

# Run $raw through the handler, signing as $dom (sel1).
sub gate_sign {
    my ($raw, $dom, %cfg) = @_;
    my ($h, $mock) = run_sign($raw,
        env_from => "<bounces\@$dom>",
        env_rcpt => '<rcpt@test4.dkim2.com>',
        signature_timestamp => undef,
        domains => { $dom => { selector => 'sel1',
            key => DKIM2TestKeys::private_key_pem($dom, 'sel1') } },
        %cfg);
    return ($h, $mock);
}

sub fields { my ($mock, $f) = @_; grep { $_->{field} eq $f } @{$mock->{pre_headers}} }

# The message as it leaves: the handler's header changes applied in order as
# the MTA does (an empty value deletes the index'th field of that name,
# 1-based), then pre_headers prepended in reverse, as milters do.
sub assemble {
    my ($raw, $mock, $h) = @_;
    for my $c (@{ $h ? $h->{_changed_headers} // [] : [] }) {
        my ($hdr, $body) = split /$EOL$EOL/, $raw, 2;
        my @f;
        for my $line (split /$EOL/, $hdr) {
            if ($line =~ /^[ \t]/ && @f) { $f[-1] .= "$EOL$line" } else { push @f, $line }
        }
        my $n = 0;
        @f = map {
            my $hit = /^\Q$c->{field}\E[ \t]*:/i && ++$n == $c->{index};
            $hit ? ($c->{value} eq '' ? () : ("$c->{field}: $c->{value}")) : ($_)
        } @f;
        $raw = join($EOL, @f) . "$EOL$EOL" . $body;
    }
    my $out = '';
    for my $p (reverse @{$mock->{pre_headers}}) {
        (my $v = $p->{value}) =~ s/\015?\012/$EOL/g;
        $out .= "$p->{field}: $v$EOL";
    }
    return $out . $raw;
}

sub verify_out {
    my ($msg, $ignore) = @_;
    my $v = Mail::DKIM2::Verifier->new(PubkeyCallback => $PUBKEY_CB,
        ($ignore ? (IgnorePrefixes => $ignore) : ()));
    $v->PRINT($msg); $v->CLOSE;
    return $v->result_detail;
}

sub expect_sign {
    my ($name, $raw, $dom, $want_i, %cfg) = @_;
    my ($h, $mock) = gate_sign($raw, $dom, %cfg);
    my @sig = fields($mock, 'DKIM2-Signature');
    is(scalar @sig, 1, "$name: signed");
    like($sig[0]{value} // '', qr/^i=$want_i;/, "$name: i=$want_i")
        if @sig;
    like(verify_out(assemble($raw, $mock, $h), $cfg{ignore_header_prefixes}), qr/^pass/, "$name: the result verifies");
    return ($h, $mock);
}

sub expect_refuse {
    my ($name, $raw, $dom, $reason, %cfg) = @_;
    my ($h, $mock) = gate_sign($raw, $dom, %cfg);
    is(scalar(fields($mock, 'DKIM2-Signature')), 0, "$name: not signed");
    is(scalar(fields($mock, 'Message-Instance')), 0, "$name: no Message-Instance added");
    my $p = parse_mime($raw);
    my ($logged) = grep { /^Not signing for \Q$dom\E: / } map { $_->[1] // '' } @{$h->{_log}};
    ok($logged, "$name: refusal logged") or diag(explain($h->{_log}));
    diag($logged) if $ENV{GATE_DIAG};
    # -08 section 13: with an upstream DKIM2-Signature on it, the message is
    # not sent on: 550 5.7.1 with the reason, and nothing else done to it.
    if ($p->header_raw('DKIM2-Signature')) {
        like($h->{_reject} // '', qr/\A550 5\.7\.1 not signing: \S/, "$name: rejected 550 5.7.1");
        is_deeply($mock->{pre_headers}, [], "$name: nothing added");
        return ($h, $mock);
    }
    ok(!defined $h->{_reject}, "$name: not rejected (no upstream signature)");
    # Not signing: every Message-Instance no DKIM2-Signature covers (m=
    # above every signature's m=) is removed, and the removal recorded.
    my $covered = 0;
    for ($p->header_raw('DKIM2-Signature')) {
        my ($m) = /(?:\A|;)\s*m\s*=\s*(\d+)/;
        $covered = $m if defined $m && $m > $covered;
    }
    my @mi = map { (/\bm=(\d+)/)[0] } $p->header_raw('Message-Instance');
    my @gone = grep { $mi[$_ - 1] > $covered } 1 .. @mi;
    is_deeply([ map { [$_->{field}, $_->{index}, $_->{value}] }
                grep { lc $_->{field} eq 'message-instance' } @{$h->{_changed_headers} // []} ],
              [ map { ['Message-Instance', $_, ''] } reverse @gone ],
              "$name: removes exactly the instances no signature covers");
    my @info = map { $_->{value} } fields($mock, 'X-DKIM2-Info');
    my @removed = grep { /\baction=removed-unsigned-mi=/ } @info;
    is(scalar @removed, @gone ? 1 : 0, "$name: removal recorded iff any");
    my @other = grep { !/\baction=removed-unsigned-mi=/ } @info;
    if ($reason eq 'upstream-chain') {
        is(scalar @other, 0, "$name: no not-signed X-DKIM2-Info (the verifier's A-R reports it)");
    } else {
        is(scalar @other, 1, "$name: one not-signed X-DKIM2-Info");
        like($other[0] // '', qr/\baction=not-signed=\Q$reason\E;/,
            "$name: X-DKIM2-Info not-signed=$reason");
    }
    return ($h, $mock);
}

# --- fresh: no chain, signed exactly as before the gate -----------------------
{
    my ($h, $mock) = run_sign($PLAIN,
        domains => { 'test1.dkim2.com' => { selector => 'rsa1024',
            key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'rsa1024') } });
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    (my $mi_value = fold_header('Message-Instance: ' . $mi->as_string))
        =~ s/^Message-Instance: //;
    my $s = Mail::DKIM2::Signer->new(
        Domain => 'test1.dkim2.com', Selector => 'rsa1024',
        Key => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
        Timestamp => 1740000000,
        MailFrom => 'sender@test1.dkim2.com', RcptTo => ['recipient@test2.dkim2.com']);
    $s->PRINT("Message-Instance: $mi_value$EOL$PLAIN"); $s->CLOSE;
    (my $sig_value = $s->as_string) =~ s/^DKIM2-Signature:\s*//;
    is_deeply($mock->{pre_headers}, [
        { field => 'Message-Instance', value => $mi_value },
        { field => 'DKIM2-Signature',  value => $sig_value },
    ], 'fresh: exactly the Message-Instance and signature a direct signing gives');
    is_deeply($h->{_changed_headers} // [], [], 'fresh: nothing removed');
}

# --- options left out of the config take their documented defaults ------------
# The real authentication_milter does not merge default_config() into the
# operator's config: an option the operator leaves out is just undef. The
# handler applies its own defaults (sign_authenticated, sign_local,
# add_message_instance, record_smtp_params all 1).
{
    my ($h, $mock) = run_sign($PLAIN,
        domains => { 'test1.dkim2.com' => { selector => 'sel1',
            key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'sel1') } },
        map { $_ => undef } qw(sign_authenticated sign_local add_message_instance
            record_smtp_params snapshot_directory ignore_header_prefixes
            allow_null_body_recipe key_endpoint key_endpoint_timeout));
    my @sig = fields($mock, 'DKIM2-Signature');
    is(scalar @sig, 1, 'defaults: signs an authenticated sender with sign_* left out');
    is(scalar(fields($mock, 'Message-Instance')), 1,
        'defaults: add_message_instance defaults on');
    like($sig[0]{value} // '', qr/\bmf=/, 'defaults: record_smtp_params defaults on (mf=)');
    like($sig[0]{value} // '', qr/\brt=/, 'defaults: record_smtp_params defaults on (rt=)');

    ($h, $mock) = run_sign($PLAIN,
        domains => { 'test1.dkim2.com' => { selector => 'sel1',
            key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'sel1') } },
        sign_authenticated => undef, sign_local => undef,
        _authenticated => 0, _local => 1);
    is(scalar(fields($mock, 'DKIM2-Signature')), 1, 'defaults: sign_local defaults on');

    ($h, $mock) = run_sign(list_post(null => 1),
        domains => { 'test2.dkim2.com' => { selector => 'sel1',
            key => DKIM2TestKeys::private_key_pem('test2.dkim2.com', 'sel1') } },
        env_from => '<bounces@test2.dkim2.com>', signature_timestamp => undef,
        allow_null_body_recipe => undef);
    is(scalar(fields($mock, 'DKIM2-Signature')), 0,
        'defaults: allow_null_body_recipe defaults off');

    ($h, $mock) = run_sign($PLAIN,
        domains => { 'test1.dkim2.com' => { selector => 'sel1',
            key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'sel1') } },
        sign_authenticated => 0, sign_local => 0);
    is(scalar(fields($mock, 'DKIM2-Signature')), 0, 'defaults: an explicit 0 still wins');
}
expect_sign('fresh (sel1)', $PLAIN, 'test1.dkim2.com', 1);

# --- valid chain ----------------------------------------------------------------
expect_sign('valid-chain', list_post(), 'test2.dkim2.com', 2);
expect_sign('i=1 forwarded unchanged', signed_m1(), 'test2.dkim2.com', 2);

# --- broken upstream signature -----------------------------------------------------
{
    my $msg = signed_m1();
    $msg =~ s/^(DKIM2-Signature: .*?\bt=)(\d+)/$1 . ($2 + 1)/se or die 'no t=';
    my ($h) = expect_refuse('broken-signature', $msg, 'test2.dkim2.com', 'upstream-chain');
    expect_refuse('broken-signature (allow_null_body_recipe)', $msg, 'test2.dkim2.com',
        'upstream-chain', allow_null_body_recipe => 1);
}

# --- broken Message-Instance chain --------------------------------------------------
# Signed below: the Verifier itself undoes the chain to check m=1, so the
# upstream signature fails first.  Unsigned (mi-only-broken): the gate's own
# chain check refuses it, and says so on the message.
expect_refuse('broken-mi-chain', list_post(forge => 1), 'test2.dkim2.com', 'upstream-chain');
expect_refuse('mi-only-broken', list_post(forge => 1, unsigned => 1), 'test2.dkim2.com',
    'broken-mi-chain');
expect_refuse('mi-only-broken (allow_null_body_recipe)',
    list_post(forge => 1, unsigned => 1), 'test2.dkim2.com', 'broken-mi-chain',
    allow_null_body_recipe => 1);
{
    # -08 section 12.1 (ruling 17): instances with no signature under them
    # leave as ONE m=1 -- here the matching top undoes to the list's m=1, so
    # no snapshot is needed.
    my $raw = list_post(unsigned => 1);
    my ($h, $mock) = expect_sign('mi-only', $raw, 'test2.dkim2.com', 1);
    my $out = assemble($raw, $mock, $h);
    is_deeply([ $out =~ /^Message-Instance:[ \t]*m=(\d+)/mg ], [1], 'mi-only: one Message-Instance, m=1');
    my @info = map { $_->{value} } fields($mock, 'X-DKIM2-Info');
    ok((grep { /\baction=restarted-unsigned-mi=m=1,m=2;/ } @info), 'mi-only: X-DKIM2-Info records the restart');
    my $back = Mail::DKIM2::MessageInstance->undo($out);
    is($back->header('Subject'), 'a post', 'mi-only: m=1 undoes to the list\'s first form');
}

# --- stock route: unsigned post, From munged, snapshot from arrival ---------------
# The inbound side stamped an unsigned m=1 over the author's post and kept a
# snapshot under an X-DKIM2-Snapshot token; stock Mailman then munged the From
# (rule R15). The copy leaves with ONE m=1 whose Recipes go back to the post as
# it arrived, signed as i=1 by the list domain (-08 sections 11, 12.1).
{
    my $mi1 = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($PLAIN));
    my $arrived = "Message-Instance: " . $mi1->as_string . $EOL . $PLAIN;
    my $dir = tempdir(CLEANUP => 1);
    my $tok = 'fedcba9876543210fedcba9876543210';
    Mail::DKIM2::MessageStore->new(directory => $dir)->store("X-DKIM2-Snapshot:$tok", $arrived);
    (my $listed = $arrived) =~ s/^From: [^\r\n]*/From: Author via list <list\@test2.dkim2.com>${EOL}Reply-To: author\@test1.dkim2.com/m
        or die 'fixture';
    $listed =~ s/^Subject: /Subject: [list] /m;
    $listed .= "-- $EOL" . "list footer$EOL";
    my $raw = "X-DKIM2-Snapshot: $tok$EOL" . $listed;
    my ($h, $mock) = expect_sign('munge', $raw, 'test2.dkim2.com', 1, snapshot_directory => $dir);
    my ($sig) = fields($mock, 'DKIM2-Signature');
    like($sig->{value} // '', qr/\bd=test2\.dkim2\.com;/, 'munge: d= the list domain');
    my $out = assemble($raw, $mock, $h);
    is_deeply([ $out =~ /^Message-Instance:[ \t]*m=(\d+)/mg ], [1], 'munge: one Message-Instance, m=1');
    my $back = Mail::DKIM2::MessageInstance->undo($out);
    is($back->header('From'), 'Author <author@test1.dkim2.com>', 'munge: undo restores the author From');
    ok(!defined $back->header('Reply-To'), 'munge: undo removes the Reply-To');
    is($back->body_raw, "hello list$EOL", 'munge: undo restores the body');

    # Without the munge the Signer refuses: the author's From is not
    # Authentic for the list domain (rule R15 is why operators munge).
    (my $nomunge = $arrived) =~ s/^Subject: /Subject: [list] /m;
    $nomunge = "X-DKIM2-Snapshot: $tok$EOL" . $nomunge;
    my ($h2, $mock2) = gate_sign($nomunge, 'test2.dkim2.com', snapshot_directory => $dir);
    is(scalar(fields($mock2, 'DKIM2-Signature')), 0, 'no munge: not signed');
    ok((grep { /not Authentic for d=test2\.dkim2\.com/ } map { $_->[1] // '' } @{$h2->{_log}}),
       'no munge: the Signer\'s refusal is logged');
    ok((grep { /From domain test1\.dkim2\.com is not d=test2\.dkim2\.com or below it/ }
            map { $_->[1] // '' } @{$h2->{_log}}),
       'no munge: the log names the From domain and d= (final review I3)');
}
expect_refuse('mi-only-null', list_post(null => 1, unsigned => 1), 'test2.dkim2.com',
    'null-body-recipe');
expect_sign('mi-only-null (allow_null_body_recipe)', list_post(null => 1, unsigned => 1),
    'test2.dkim2.com', 1, allow_null_body_recipe => 1);

# --- the handler's own instance over an unsigned null ------------------------------
# The list's unsigned null m=2 is snapshotted; the message then changes again on
# this host (a List-Help field), so the handler computes its own ordinary m=3
# over the null and signs that.  The null is no longer the top, but nothing
# upstream covers it (i=1 has m=1): refused like a null top, unless
# allow_null_body_recipe.
{
    my $post = list_post(null => 1);
    my $dir  = tempdir(CLEANUP => 1);
    # The snapshot is found through the X-DKIM2-Snapshot token DKIM2Verify
    # would have put on the message.
    my $tok = '0123456789abcdef0123456789abcdef';
    Mail::DKIM2::MessageStore->new(directory => $dir)->store("X-DKIM2-Snapshot:$tok", $post);
    (my $msg = $post) =~ s/^(Subject: )/List-Help: <mailto:list-help\@test2.dkim2.com>$EOL$1/m
        or die 'fixture';
    $msg = "X-DKIM2-Snapshot: $tok$EOL" . $msg;
    my ($h, $mock) = expect_refuse('own instance over unsigned null', $msg, 'test2.dkim2.com',
        'null-body-recipe', snapshot_directory => $dir);
    my ($logged) = grep { /^Not signing/ } map { $_->[1] // '' } @{$h->{_log}};
    like($logged // '', qr/unsigned Message-Instance m=2 has a null body Recipe/,
        'own instance over unsigned null: the log names the unsigned null m=2');
    my (undef, $mock2) = expect_sign('own instance over unsigned null (allow_null_body_recipe)',
        $msg, 'test2.dkim2.com', 2, allow_null_body_recipe => 1, snapshot_directory => $dir);
    my @mi = fields($mock2, 'Message-Instance');
    like($mi[0]{value} // '', qr/^m=3;/, 'own instance over unsigned null: the handler added m=3');
    my @info = map { $_->{value} } fields($mock2, 'X-DKIM2-Info');
    like($info[0] // '', qr/\baction=null-body-recipe;/,
        'own instance over unsigned null (allowed): X-DKIM2-Info action=null-body-recipe');
}

# --- unsigned null top: this hop's own null --------------------------------------
{
    my $msg = list_post(null => 1);
    expect_refuse('null-top', $msg, 'test2.dkim2.com', 'null-body-recipe');
    my (undef, $mock) = expect_sign('null-top (allow_null_body_recipe)', $msg,
        'test2.dkim2.com', 2, allow_null_body_recipe => 1);
    my @info = map { $_->{value} } fields($mock, 'X-DKIM2-Info');
    is(scalar @info, 1, 'null-top (allowed): one X-DKIM2-Info');
    like($info[0] // '', qr/\baction=null-body-recipe;/,
        'null-top (allowed): X-DKIM2-Info action=null-body-recipe');
    like($info[0] // '', qr/\bsw=authentication_milter-DKIM2Sign;/,
        'null-top (allowed): sw= names the handler');
    is($mock->{pre_headers}[-1]{field}, 'X-DKIM2-Info',
        'null-top (allowed): X-DKIM2-Info directly above the signature');
    expect_refuse('null-top-forged (allow_null_body_recipe)',
        list_post(null => 1, forge => 1), 'test2.dkim2.com', 'upstream-chain',
        allow_null_body_recipe => 1);
}

# --- signed null top: the list declared and signed it --------------------------
{
    my $msg = sign_as(list_post(null => 1), 'test2.dkim2.com',
        'list-bounces@test2.dkim2.com', 'subscriber@test3.dkim2.com');
    my (undef, $mock) = expect_sign('null-top-signed', $msg, 'test3.dkim2.com', 3);
    my @info = map { $_->{value} } fields($mock, 'X-DKIM2-Info');
    like($info[0] // '', qr/\baction=null-body-recipe;/,
        'null-top-signed: X-DKIM2-Info action=null-body-recipe');
}

# --- fake coverage: a junk DKIM2-Signature claiming m=2 is no cover -----------------
{
    my $base = list_post(null => 1);
    (my $real) = $base =~ /^(DKIM2-Signature: i=1; m=1;.*?\015\012)(?![ \t])/ms;
    ok($real, 'fixture: the real i=1 signature');
    (my $rewritten = $real) =~ s/i=1; m=1;/m=2;/;
    my %fake = (
        'no-i'         => "DKIM2-Signature: m=2; d=evil.example$EOL",
        'i0'           => "DKIM2-Signature: i=0; m=2; t=1; d=evil.example; s=sel1:rsa-sha256:AAAA$EOL",
        'i-abc'        => "DKIM2-Signature: i=abc; m=2; d=evil.example$EOL",
        'm-rewritten'  => $rewritten,
        'unparseable'  => "DKIM2-Signature: m=2; i=2; garbage without equals$EOL",
    );
    for my $name (sort keys %fake) {
        my @warn;
        local $SIG{__WARN__} = sub { push @warn, @_ };
        my $msg = $fake{$name} . $base;
        expect_refuse("fake-cover-$name", $msg, 'test2.dkim2.com', 'upstream-chain');
        expect_refuse("fake-cover-$name (allow_null_body_recipe)", $msg,
            'test2.dkim2.com', 'upstream-chain', allow_null_body_recipe => 1);
        is_deeply(\@warn, [], "fake-cover-$name: no warnings");
    }
}

# --- ignore_header_prefixes reaches the gate ----------------------------------------
{
    # A field this host adds and neither end hashes: with the prefix ignored
    # m=1 still describes the message; without, it does not (and with no
    # snapshot there is no new instance), so the gate refuses.
    my $msg = "Fm-Local: 1$EOL" . signed_m1();
    expect_sign('ignored local field', $msg, 'test2.dkim2.com', 2,
        ignore_header_prefixes => ['Fm-']);
    expect_refuse('unignored local field', $msg, 'test2.dkim2.com', 'upstream-chain');
}

# --- nd= bridge -------------------------------------------------------------------------
{
    my $us = sign_as(signed_m1(), 'test2.dkim2.com', undef, undef,
        NextDomain => 'test3.dkim2.com');
    like($us, qr/^DKIM2-Signature: i=2;.*?\bnd=test3\.dkim2\.com/ms, 'fixture: nd= bridge');
    expect_sign('nd-to-us', $us, 'test3.dkim2.com', 3);
    my $other = sign_as(signed_m1(), 'test2.dkim2.com', undef, undef,
        NextDomain => 'test4.dkim2.com');
    expect_refuse('nd-to-other', $other, 'test3.dkim2.com', 'upstream-chain');
}

# --- X-DKIM2-Exploded: the list manager's request for the exploded flag (-08) ----------
{
    my $flags = sub {
        my ($mock) = @_;
        my ($sig) = fields($mock, 'DKIM2-Signature');
        return $sig && $sig->{value} =~ /\bf=([^;]*)/ ? $1 =~ s/\s+//gr : '';
    };
    my $post = "X-DKIM2-Exploded: yes$EOL" . list_post();
    my ($h, $mock) = expect_sign('exploded hint', $post, 'test2.dkim2.com', 2);
    is($flags->($mock), 'exploded', 'exploded hint: f=exploded');
    is_deeply([ grep { $_->{field} eq 'X-DKIM2-Exploded' } @{$h->{_changed_headers} // []} ],
              [ { field => 'X-DKIM2-Exploded', index => 1, value => '' } ],
              'exploded hint: the hint is removed');
    ($h, $mock) = expect_sign('no hint', list_post(), 'test2.dkim2.com', 2);
    is($flags->($mock), '', 'no hint, one recipient: no f=');
    # Ignored at i=1 (an originating hop never explodes).
    ($h, $mock) = run_sign("X-DKIM2-Exploded: yes$EOL$PLAIN",
        domains => { 'test1.dkim2.com' => { selector => 'sel1',
            key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'sel1') } });
    is($flags->($mock), '', 'exploded hint at i=1: no f=');
}

done_testing;
