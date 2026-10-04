#!/usr/bin/perl -w
use 5.020; use strict; use warnings;
use Test::More;
use lib 'lib';
use lib 't/lib';
use Email::MIME;
use Mail::DKIM2::DSN;
use Mail::DKIM2::Signer;
use Mail::DKIM2::MessageInstance;
use Mail::DKIM2::Verifier;
use Mail::DKIM2::Reflector;
use DKIM2TestKeys;

my $TS = 1740000000;

sub mk_signer {
    my (%o) = @_;
    my $sel = $o{selector} // 'rsa1024';
    return Mail::DKIM2::Signer->new(
        Domain    => $o{domain},
        Selector  => $sel,
        Key       => DKIM2TestKeys::private_key($o{domain}, $sel),
        MailFrom  => $o{mailfrom} // '<>',
        RcptTo    => $o{rcptto}   // ['x@example.com'],
        Timestamp => $TS,
    );
}

my $CB = DKIM2TestKeys::pubkey_callback();

# propagate() authenticates the DSN first (§12.1.2) unless told it has been
# done already. The fixtures below deliberately do NOT verify (signed_inbound
# signs d=test1 over a sender@origin.example envelope, which the d=/mf= rule
# rejects), because they exist to exercise the rebuild machinery -- so they
# pass SkipAuthentication and the authentication itself is tested separately.
my %NO_AUTH = (SkipAuthentication => 1);

# Build a v=1 signed inbound message from a sender.
sub signed_inbound {
    my $raw = "From: Sender <sender\@origin.example>\r\n"
            . "To: user\@test1.dkim2.com\r\n"
            . "Subject: hello\r\n"
            . "\r\n"
            . "body line\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
    my $with_mi = "Message-Instance: " . $mi->as_string . "\r\n" . $raw;
    my $signer = mk_signer(domain => 'test1.dkim2.com',
                           mailfrom => 'sender@origin.example',
                           rcptto => ['user@test1.dkim2.com']);
    $signer->PRINT($with_mi); $signer->CLOSE;
    my $sig = $signer->as_string; $sig =~ s/\r?\n$//;
    return $sig . "\r\n" . $with_mi;
}

# Build a 2-hop message: origin signs i=1; forwarder (test2) appends a footer,
# records MI v=2, and signs i=2.
sub forwarded_twohop {
    my $h1 = signed_inbound();                 # MI v=1 + sig i=1
    my $prev = Email::MIME->new($h1);
    my $cur  = Email::MIME->new($h1);
    $cur->body_set($cur->body_raw . "-- \r\nforwarder footer\r\n");
    my $mi = Mail::DKIM2::MessageInstance->calculate($cur, $prev);
    $cur->header_raw_prepend('Message-Instance', $mi->as_string);
    my $signer = mk_signer(domain => 'test2.dkim2.com',
                           mailfrom => 'user@test2.dkim2.com',
                           rcptto => ['dest@test3.dkim2.com']);
    $signer->PRINT($cur->as_string); $signer->CLOSE;
    my $sig = $signer->as_string; $sig =~ s/\r?\n$//;
    $sig =~ s{^DKIM2-Signature:\s*}{};
    $cur->header_raw_prepend('DKIM2-Signature', $sig);
    return $cur->as_string;
}

# === propagate: forwarder returns a received DSN upstream (§12.1.1) ===
{
    my $embedded = forwarded_twohop();
    my $dsn = Email::MIME->create(
        attributes => { content_type => 'multipart/report', encoding => '7bit' },
        header_str => [ From => 'postmaster@test3.dkim2.com',
                        To => 'user@test2.dkim2.com',
                        Subject => 'failure' ],
        parts => [
            Email::MIME->create(attributes => { content_type => 'text/plain', charset=>'UTF-8', encoding=>'7bit' },
                                body_str => "delivery failed\n"),
            Email::MIME->create(attributes => { content_type => 'message/delivery-status' },
                                body => "Reporting-MTA: dns; test3.dkim2.com\r\n\r\n"
                                      . "Final-Recipient: rfc822; dest\@test3.dkim2.com\r\n"
                                      . "Action: failed\r\nStatus: 5.1.1\r\n"),
            Email::MIME->create(attributes => { content_type => 'message/rfc822' },
                                body => $embedded),
        ],
    );

    my $signer = mk_signer(domain => 'test2.dkim2.com');
    my $out = Mail::DKIM2::DSN->propagate(
        Message => $dsn->as_string, ForwarderDomain => 'test2.dkim2.com', Signer => $signer, %NO_AUTH,
    );
    ok($out->{raw}, 'propagate returned a DSN');
    # After stripping the forwarder hop (i=2), the now-top sig is i=1 with
    # mf=sender@origin.example.
    is($out->{upstream_mailfrom}, '<sender@origin.example>',
       'propagated DSN addressed to upstream MAIL FROM');
    my $m = Email::MIME->new($out->{raw});
    like($m->header('Content-Type'), qr{multipart/report}i, 'still multipart/report');
    is(scalar(() = $m->header_raw('Message-Instance')),  1, 'exactly one MI (new message)');
    is(scalar(() = $m->header_raw('DKIM2-Signature')), 1, 'exactly one DKIM2-Signature');
}

# Build a 2-hop message where the second hop forwards UNCHANGED: no new
# Message-Instance is recorded (body/headers untouched), just a second
# DKIM2-Signature (i=2) stacked on top of the origin's (i=1). Unlike
# forwarded_twohop(), this carries no body-diff ('rb') Recipe, so undo() is a
# clean no-op -- useful for exercising propagate() without also touching the
# unrelated undo/rebuild machinery.
sub forwarded_unchanged {
    my $h1 = signed_inbound();                 # MI v=1 + sig i=1
    my $cur = Email::MIME->new($h1);
    my $signer = mk_signer(domain => 'test2.dkim2.com',
                           mailfrom => 'user@test2.dkim2.com',
                           rcptto => ['dest@test3.dkim2.com']);
    $signer->PRINT($cur->as_string); $signer->CLOSE;
    my $sig = $signer->as_string; $sig =~ s/\r?\n$//;
    $sig =~ s{^DKIM2-Signature:\s*}{};
    $cur->header_raw_prepend('DKIM2-Signature', $sig);
    return $cur->as_string;
}

# === propagate: rejects a multipart/report with >=3 parts but no
# message/delivery-status part (RFC 6522 structural validation, not just a
# bare part count) ===
{
    my $embedded = forwarded_twohop();
    my $dsn = Email::MIME->create(
        attributes => { content_type => 'multipart/report', encoding => '7bit' },
        header_str => [ From => 'postmaster@test3.dkim2.com',
                        To => 'user@test2.dkim2.com',
                        Subject => 'failure' ],
        parts => [
            Email::MIME->create(attributes => { content_type => 'text/plain', charset=>'UTF-8', encoding=>'7bit' },
                                body_str => "delivery failed\n"),
            # No message/delivery-status part here -- just a second text/plain,
            # so @parts >= 3 but the RFC 6522 structure is not satisfied.
            Email::MIME->create(attributes => { content_type => 'text/plain', charset=>'UTF-8', encoding=>'7bit' },
                                body_str => "not a delivery-status part\n"),
            Email::MIME->create(attributes => { content_type => 'message/rfc822' },
                                body => $embedded),
        ],
    );

    my $signer = mk_signer(domain => 'test2.dkim2.com');
    eval {
        Mail::DKIM2::DSN->propagate(
            Message => $dsn->as_string, ForwarderDomain => 'test2.dkim2.com', Signer => $signer, %NO_AUTH,
        );
    };
    like($@, qr/propagate/i,
         'propagate rejects a >=3-part DSN lacking a message/delivery-status part');
}

# === propagate: accepts a well-formed 3-part DSN whose embedded original is
# text/rfc822-headers (the other half of the message/rfc822 OR
# text/rfc822-headers structural requirement) ===
{
    my $embedded = forwarded_unchanged();
    my $dsn = Email::MIME->create(
        attributes => { content_type => 'multipart/report', encoding => '7bit' },
        header_str => [ From => 'postmaster@test3.dkim2.com',
                        To => 'user@test2.dkim2.com',
                        Subject => 'failure' ],
        parts => [
            Email::MIME->create(attributes => { content_type => 'text/plain', charset=>'UTF-8', encoding=>'7bit' },
                                body_str => "delivery failed\n"),
            Email::MIME->create(attributes => { content_type => 'message/delivery-status' },
                                body => "Reporting-MTA: dns; test3.dkim2.com\r\n\r\n"
                                      . "Final-Recipient: rfc822; dest\@test3.dkim2.com\r\n"
                                      . "Action: failed\r\nStatus: 5.1.1\r\n"),
            Email::MIME->create(attributes => { content_type => 'text/rfc822-headers' },
                                body => Email::MIME->new($embedded)->header_obj->as_string),
        ],
    );

    my $signer = mk_signer(domain => 'test2.dkim2.com');
    my $out = Mail::DKIM2::DSN->propagate(
        Message => $dsn->as_string, ForwarderDomain => 'test2.dkim2.com', Signer => $signer, %NO_AUTH,
    );
    ok($out->{raw}, 'propagate accepts a valid 3-part DSN (text/rfc822-headers variant)');
    is($out->{upstream_mailfrom}, '<sender@origin.example>',
       'propagated DSN (headers-only variant) addressed to upstream MAIL FROM');
}

# === propagate: §12.1.1's null Recipe — an upstream that declares the
# previous body unrecoverable gets the header fields back, not a body we
# cannot reconstruct. The forwarder's whole hop comes off: its instance goes
# with the signature that covered it, or the returned message carries an
# instance above its own top signature (§11 "is not signed") upstream. ===
{
    my $h1 = signed_inbound();                 # MI v=1 + sig i=1
    my $cur = Email::MIME->new($h1);
    $cur->body_set("replaced entirely\r\n");
    # A null "b" Recipe: the previous body cannot be put back. Built by hand
    # from the digest primitives -- calculate() has no way to emit one, and
    # its diff form would compute a real (reversible) body Recipe instead.
    my $hh = Mail::DKIM2::MessageInstance::h_digest($cur, 'sha256');
    my $bh = Mail::DKIM2::MessageInstance::b_digest($cur, 'sha256');
    my $r  = Mail::DKIM2::Common::encode_tag_json({ b => undef });
    $cur->header_raw_prepend('Message-Instance', "m=2; h=sha256:$hh:$bh; r=$r;");
    my $signer = mk_signer(domain => 'test2.dkim2.com',
                           mailfrom => 'user@test2.dkim2.com',
                           rcptto => ['dest@test3.dkim2.com']);
    $signer->PRINT($cur->as_string); $signer->CLOSE;
    (my $sig = $signer->as_string) =~ s/\r?\n$//;
    $sig =~ s{^DKIM2-Signature:\s*}{};
    $cur->header_raw_prepend('DKIM2-Signature', $sig);

    my $out = Mail::DKIM2::DSN->propagate(
        Message => dsn_around($cur->as_string), ForwarderDomain => 'test2.dkim2.com',
        Signer => mk_signer(domain => 'test2.dkim2.com'), %NO_AUTH,
    );
    is($out->{upstream_mailfrom}, '<sender@origin.example>',
       'a null-Recipe DSN still propagates to the upstream MAIL FROM');

    my $m = Email::MIME->new($out->{raw});
    my @types = map { ($_->content_type // '') =~ m{^([^;]+)} ? $1 : '' } $m->subparts;
    ok((grep { m{^text/rfc822-headers} } @types),
       '  ... returning the header fields alone') or diag("@types");
    ok(!(grep { m{^message/rfc822} } @types),
       '  ... and not a body it could not reconstruct');

    my ($part) = grep { ($_->content_type // '') =~ m{^text/rfc822-headers} } $m->subparts;
    my $inner = Email::MIME->new($part->body);
    is(scalar(() = $inner->header_raw('Message-Instance')), 1,
       '  ... with the forwarder\'s instance stripped along with its hop');
    my @isigs = map { Mail::DKIM2::Signature->parse($_) } $inner->header_raw('DKIM2-Signature');
    is(scalar @isigs, 1, '  ... and one signature left');
    is($isigs[0]->sequence, 1, '  ... the upstream\'s i=1');
}

# === generate: reflector-dsn behaviour ===
{
    my $inbound = signed_inbound();
    my $bouncer = mk_signer(domain => 'test2.dkim2.com');
    my $out = Mail::DKIM2::DSN->generate(
        Message => $inbound, Signer => $bouncer, ReportingMTA => 'test2.dkim2.com',
    );
    ok($out->{raw}, 'generate returned a DSN');
    is($out->{send_to}, '<sender@origin.example>', 'DSN addressed to original sender');

    my $m = Email::MIME->new($out->{raw});
    like($m->header('Content-Type'), qr{multipart/report}i, 'is multipart/report');
    like($m->header('Content-Type'), qr{report-type=delivery-status}i, 'has report-type');

    my @mi  = $m->header_raw('Message-Instance');
    my @sig = $m->header_raw('DKIM2-Signature');
    is(scalar(@mi),  1, 'exactly one Message-Instance (new message)');
    is(scalar(@sig), 1, 'exactly one DKIM2-Signature (new message)');

    # The generated DSN verifies as a fresh DKIM2 message.
    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($m->as_string); $v->CLOSE;
    is($v->result, 'pass', 'generated DSN verifies (pass)');
}

# === generate: works for UNSIGNED inbound too (bounce regardless) ===
{
    my $inbound = "From: nobody\@origin.example\r\nTo: user\@test1.dkim2.com\r\n"
                . "Subject: unsigned\r\n\r\nhi\r\n";
    my $bouncer = mk_signer(domain => 'test2.dkim2.com');
    my $out = Mail::DKIM2::DSN->generate(
        Message => $inbound, Signer => $bouncer, To => 'nobody@origin.example',
    );
    is($out->{send_to}, 'nobody@origin.example', 'unsigned mail: bounced to envelope sender');
    my $m = Email::MIME->new($out->{raw});
    my @sig = $m->header_raw('DKIM2-Signature');
    is(scalar(@sig), 1, 'unsigned-source DSN is DKIM2-signed');
}

# === reflector-dsn: Reflector::generate_dsn end to end -> a fresh DKIM2 DSN
# (per spec: MAIL FROM <>, one Message-Instance + one DKIM2-Signature on the
# top message, embedding the original as message/rfc822) that verifies. ===
{
    my $inbound = signed_inbound();
    my $out = Mail::DKIM2::Reflector::generate_dsn(
        sender   => 'sender@origin.example',
        message  => $inbound,
        domain   => 'test2.dkim2.com',
        selector => 'rsa1024',
        key      => DKIM2TestKeys::private_key('test2.dkim2.com', 'rsa1024'),
        now      => $TS,
    );
    ok($out, 'generate_dsn produced a DSN');
    my $m = Email::MIME->new($out);
    like($m->header('Content-Type'), qr{multipart/report}i, 'reflector-dsn is multipart/report');
    is($m->header('To'), 'sender@origin.example', 'reflector-dsn returned to the sender');
    like($out, qr/^DKIM2-Signature:/m,  'DSN carries its own DKIM2-Signature (top message)');
    like($out, qr/^Message-Instance:/m, 'DSN carries its own Message-Instance (top message)');
    like($out, qr{message/rfc822}i,     'DSN embeds the original as message/rfc822');

    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($m->as_string); $v->CLOSE;
    is($v->result, 'pass', 'reflector-dsn output verifies (pass)');
}

# === reflector-dsn: the embedded original round-trips -- the message/rfc822
# part holds the inbound message verbatim, so the sender can see what bounced. ===
{
    my $raw = "From: Sender <sender\@test1.dkim2.com>\r\n"
            . "To: user\@test2.dkim2.com\r\n"
            . "Subject: hello\r\n"
            . "\r\n"
            . "body line\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
    my $with_mi = "Message-Instance: " . $mi->as_string . "\r\n" . $raw;
    my $signer = mk_signer(domain => 'test1.dkim2.com',
                           mailfrom => 'sender@test1.dkim2.com',
                           rcptto   => ['user@test2.dkim2.com']);
    $signer->PRINT($with_mi); $signer->CLOSE;
    my $sig = $signer->as_string; $sig =~ s/\r?\n$//;
    my $inbound = $sig . "\r\n" . $with_mi;

    my $out = Mail::DKIM2::Reflector::generate_dsn(
        sender   => 'sender@test1.dkim2.com',
        message  => $inbound,
        domain   => 'test2.dkim2.com',
        selector => 'rsa1024',
        key      => DKIM2TestKeys::private_key('test2.dkim2.com', 'rsa1024'),
        now      => $TS,
    );
    ok($out, 'generate_dsn produced a DSN');
    my $m = Email::MIME->new($out);
    is($m->header('To'), 'sender@test1.dkim2.com', 'reflector-dsn returned to the sender');
    like($out, qr{message/rfc822}i, 'DSN embeds the original as message/rfc822');
    like($out, qr/Subject: hello/,  'embedded original message is present verbatim');

    my $v = Mail::DKIM2::Verifier->new();
    $v->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
    $v->skip_timestamp_check(1);
    $v->PRINT($out); $v->CLOSE;
    is($v->result, 'pass', 'reflector-dsn DSN verifies (pass)');
}

# === authenticate: §12.1.2, the returned original's chain must verify ===

# The fixtures above never verify (signed_inbound signs d=test1 over a
# sender@origin.example envelope, which the d=/mf= rule rejects), which the
# propagate tests never needed. authenticate does, so build a chain that
# holds: test1 originates to a user at test2, who forwards to test3.
sub verifiable_twohop {
    my $raw = "From: Sender <sender\@test1.dkim2.com>\r\n"
            . "To: user\@test2.dkim2.com\r\n"
            . "Subject: hello\r\n"
            . "\r\n"
            . "body line\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n" . $raw;
    for my $hop ([ 'test1.dkim2.com', 'sender@test1.dkim2.com', 'user@test2.dkim2.com' ],
                 [ 'test2.dkim2.com', 'user@test2.dkim2.com',   'dest@test3.dkim2.com' ]) {
        my ($domain, $mf, $rt) = @$hop;
        my $signer = mk_signer(domain => $domain, mailfrom => $mf, rcptto => [$rt]);
        $signer->PRINT($msg); $signer->CLOSE;
        (my $sig = $signer->as_string) =~ s/\r?\n$//;
        $msg = "$sig\r\n$msg";
    }
    return $msg;
}

sub dsn_around {
    my ($embedded, %o) = @_;
    my $orig = $o{headers_only}
        ? Email::MIME->create(attributes => { content_type => 'text/rfc822-headers' },
                              body => Email::MIME->new($embedded)->header_obj->as_string)
        : Email::MIME->create(attributes => { content_type => 'message/rfc822' },
                              body => $embedded);
    return Email::MIME->create(
        attributes => { content_type => 'multipart/report', encoding => '7bit' },
        header_str => [ From => 'postmaster@test3.dkim2.com',
                        To => 'user@test2.dkim2.com',
                        Subject => 'failure' ],
        parts => [
            Email::MIME->create(attributes => { content_type => 'text/plain', charset=>'UTF-8', encoding=>'7bit' },
                                body_str => "delivery failed\n"),
            Email::MIME->create(attributes => { content_type => 'message/delivery-status' },
                                body => "Reporting-MTA: dns; test3.dkim2.com\r\n\r\n"
                                      . "Final-Recipient: rfc822; dest\@test3.dkim2.com\r\n"
                                      . "Action: failed\r\nStatus: 5.1.1\r\n"),
            $orig,
        ],
    )->as_string;
}

{
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => dsn_around(verifiable_twohop()),
        PubkeyCallback => DKIM2TestKeys::pubkey_callback(),
        SkipTimestampCheck => 1,
    );
    ok($auth->{ok}, 'a DSN returning an intact two-hop message authenticates')
        or diag($auth->{details});
    is($auth->{top}->sequence, 2, '  ... top is the forwarder\'s i=2');
    is($auth->{top}->domain, 'test2.dkim2.com', '  ... which the forwarder can recognise as its own by d=');
    is($auth->{headers_only}, 0, '  ... and the body was there to check');
}

{
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => dsn_around(verifiable_twohop(), headers_only => 1),
        PubkeyCallback => DKIM2TestKeys::pubkey_callback(),
        SkipTimestampCheck => 1,
    );
    ok($auth->{ok}, 'a headers-only DSN authenticates from the headers alone')
        or diag($auth->{details});
    is($auth->{headers_only}, 1, '  ... and says so');
}

{
    # A returned original whose headers were changed after signing: the top
    # instance's header hash no longer matches, with or without a body.
    (my $tampered = verifiable_twohop()) =~ s/^Subject: hello/Subject: hullo/m;
    for my $headers_only (0, 1) {
        my $auth = Mail::DKIM2::DSN->authenticate(
            Message => dsn_around($tampered, headers_only => $headers_only),
            PubkeyCallback => DKIM2TestKeys::pubkey_callback(),
            SkipTimestampCheck => 1,
        );
        ok(!$auth->{ok}, "a tampered returned message does not authenticate (headers_only=$headers_only)");
        like($auth->{details} // '', qr/header hash mismatch/, '  ... because the header hash differs');
    }
}

{
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => dsn_around("From: a\@b.example\r\nTo: c\@d.example\r\nSubject: plain\r\n\r\nhi\r\n"),
        PubkeyCallback => DKIM2TestKeys::pubkey_callback(),
    );
    ok(!$auth->{ok}, 'a DSN returning an unsigned message does not authenticate');
    is($auth->{result}, 'none', '  ... and reports none, so a caller can fall back to legacy handling');
    ok(!$auth->{top}, '  ... with no top signature');
}

# === propagate: a Forwarder's §9.3 bridge goes with its hop ===
{
    # test1 -> user@test2; test2 bridges with nd= and sends from test3 to test5.
    my $raw = "From: Sender <sender\@test1.dkim2.com>\r\nTo: user\@test2.dkim2.com\r\n"
            . "Subject: bridged\r\n\r\nbody line\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw));
    my $msg = "Message-Instance: " . $mi->as_string . "\r\n" . $raw;
    for my $hop (
        [ 'test1.dkim2.com', MailFrom => 'sender@test1.dkim2.com', RcptTo => ['user@test2.dkim2.com'] ],
        [ 'test2.dkim2.com', NextDomain => 'test3.dkim2.com' ],
        [ 'test3.dkim2.com', MailFrom => 'srs0=x@bounce.test3.dkim2.com', RcptTo => ['dest@test5.dkim2.com'] ],
    ) {
        my ($domain, %env) = @$hop;
        my $signer = Mail::DKIM2::Signer->new(
            Domain => $domain, Selector => 'sel1',
            Key => DKIM2TestKeys::private_key($domain, 'sel1'), Timestamp => $TS, %env,
        );
        $signer->PRINT($msg); $signer->CLOSE;
        (my $sig = $signer->as_string) =~ s/\r?\n$//;
        $msg = "$sig\r\n$msg";
    }

    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => dsn_around($msg), PubkeyCallback => DKIM2TestKeys::pubkey_callback(), SkipTimestampCheck => 1,
    );
    ok($auth->{ok}, 'a DSN returning a bridged chain authenticates') or diag($auth->{details});

    # This chain verifies, so propagate can do its own §12.1.2 authentication
    # rather than being told to skip it.
    my $out = Mail::DKIM2::DSN->propagate(
        Message => dsn_around($msg), ForwarderDomain => 'test3.dkim2.com',
        Signer => mk_signer(domain => 'test2.dkim2.com'),
        PubkeyCallback => $CB, SkipTimestampCheck => 1,
    );
    is($out->{upstream_mailfrom}, '<sender@test1.dkim2.com>',
       'the bridge is stripped with the hop: the report goes to the hop before both');
    my $m = Email::MIME->new($out->{raw});
    my ($orig) = grep { ($_->content_type // '') =~ m{^message/rfc822} } $m->subparts;
    my @inner = map { Mail::DKIM2::Signature->parse($_) } Email::MIME->new($orig->body)->header_raw('DKIM2-Signature');
    is(scalar @inner, 1, 'one signature left on the returned message');
    ok(!defined $inner[0]->next_domain, '  ... and it is not the nd= bridge');
}

# === §12.1.2 point 1: the DSN's own signing domain must be aligned with the
# rt= of the returned message's top signature -- i.e. the bounce came from the
# system we handed the message to. Checked only on a d= we have verified: an
# unverified d= is whatever the forger typed. ===

# Wrap $embedded in a DSN and sign the DSN as a new message (as §12.1.1 makes
# it: MAIL FROM <>, one Message-Instance, one DKIM2-Signature).
sub signed_dsn_around {
    my ($embedded, %o) = @_;
    (my $text = dsn_around($embedded, %o)) =~ s/\r?\n/\r\n/g;
    my $mi = Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($text));
    my $with_mi = "Message-Instance: " . $mi->as_string . "\r\n" . $text;
    my $signer = mk_signer(domain => $o{domain}, selector => 'sel1',
                           mailfrom => '<>', rcptto => ['user@test2.dkim2.com']);
    $signer->PRINT($with_mi); $signer->CLOSE;
    (my $sig = $signer->as_string) =~ s/\r?\n$//;
    return "$sig\r\n$with_mi";
}

{
    # verifiable_twohop()'s top signature is i=2 rt=<dest@test3.dkim2.com>, so
    # a DSN for it must be signed by test3.dkim2.com.
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => signed_dsn_around(verifiable_twohop(), domain => 'test3.dkim2.com'),
        PubkeyCallback => $CB, SkipTimestampCheck => 1,
    );
    ok($auth->{ok}, 'a DSN signed by the domain the message was delivered to authenticates')
        or diag("$auth->{details} / $auth->{dsn_details} / $auth->{alignment_detail}");
    is($auth->{dsn_result}, 'pass', '  ... the DSN itself verifies');
    is($auth->{dsn_sig}->domain, 'test3.dkim2.com', '  ... and it is the DSN we checked d= of');
    is($auth->{alignment}, 'pass', '  ... alignment with the returned rt= passes');
    like($auth->{alignment_detail}, qr/aligned with rt= <dest\@test3\.dkim2\.com>/,
        '  ... naming the recipient it aligned with');
}

{
    # The same DSN signed by a domain the message was never sent to: every
    # signature verifies and the returned message is intact, so nothing but
    # point 1 can tell this is not a bounce from where we sent the mail.
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => signed_dsn_around(verifiable_twohop(), domain => 'test4.dkim2.com'),
        PubkeyCallback => $CB, SkipTimestampCheck => 1,
    );
    is($auth->{result}, 'pass', 'the returned message still verifies on its own');
    is($auth->{dsn_result}, 'pass', '  ... and so does the DSN');
    is($auth->{alignment}, 'fail', '  ... but the DSN is not aligned with the rt=');
    ok(!$auth->{ok}, '  ... so the DSN does not authenticate');
    like($auth->{alignment_detail}, qr/d=test4\.dkim2\.com is not aligned/,
        '  ... naming the domain that signed it');
}

{
    # Which domain relationships count as "aligned" is a decision about
    # relaxed matching on its own, and the shared test DNS has keys for
    # test1..test5.dkim2.com only -- no subdomain and no parent -- so there is
    # no way to build a real signed DSN for either shape. The accept and
    # reject behaviour through the real entry point is covered above; this
    # pins the direction question, which is what would otherwise be guessed.
    my $rt_test3 = Mail::DKIM2::Signature->parse(
        'i=2; m=1; t=1; d=test2.dkim2.com; mf=PHVzZXJAdGVzdDIuZGtpbTIuY29tPg==; '
      . 'rt=PGRlc3RAdGVzdDMuZGtpbTIuY29tPg==; s=sel1:rsa-sha256:AAAA;');
    my $sig_of = sub {
        Mail::DKIM2::Signature->parse(
            "i=1; m=1; t=1; d=$_[0]; mf=PD4=; rt=PHVzZXJAdGVzdDIuZGtpbTIuY29tPg==; "
          . 's=sel1:rsa-sha256:AAAA;');
    };
    # §9.4's direction: labels come off the ADDRESS domain, so d= may be the
    # delivery domain or a parent of it.
    for my $d ('test3.dkim2.com', 'dkim2.com') {
        my ($state, $detail) =
            Mail::DKIM2::DSN::_check_alignment($sig_of->($d), $rt_test3);
        is($state, 'pass', "d=$d counts as aligned with rt=<dest\@test3.dkim2.com>")
            or diag($detail);
    }
    # Never a child of it: a system with a dedicated bounce domain signs as its
    # org domain and puts the bounce address on the subdomain, so this shape
    # has no legitimate producer.
    for my $d ('bounce.test3.dkim2.com', 'test4.dkim2.com',
               'test3.dkim2.com.evil.example', 'evil.example') {
        my ($state) = Mail::DKIM2::DSN::_check_alignment($sig_of->($d), $rt_test3);
        is($state, 'fail', "d=$d does not count as aligned");
    }
    # An nd= top signature on the returned message has no rt= to align with.
    my $nd_top = Mail::DKIM2::Signature->parse(
        'i=2; m=1; t=1; d=test2.dkim2.com; nd=test3.dkim2.com; s=sel1:rsa-sha256:AAAA;');
    my ($state, $detail) =
        Mail::DKIM2::DSN::_check_alignment($sig_of->('test3.dkim2.com'), $nd_top);
    is($state, 'none', 'no rt= on the returned top signature means alignment is not checkable');
    like($detail, qr/no rt=/, '  ... and says so');
}

{
    # A DSN whose own signature is broken: it claims DKIM2 and lies, so it must
    # not be propagated, and point 1 cannot be applied to a d= we cannot trust.
    (my $tampered = signed_dsn_around(verifiable_twohop(), domain => 'test3.dkim2.com'))
        =~ s/^Subject: failure/Subject: FAILURE/m;
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => $tampered, PubkeyCallback => $CB, SkipTimestampCheck => 1,
    );
    isnt($auth->{dsn_result}, 'pass', "a DSN whose own signature is broken does not verify");
    is($auth->{alignment}, 'none', '  ... and its d= is not used for alignment');
    ok(!$auth->{ok}, '  ... so it does not authenticate');
}

{
    # An unsigned DSN is not what §12.1.2 is about ("when a system receives a
    # DKIM2 signed DSN"), so it is reported, not failed: a caller can require
    # a signed DSN, or keep handling legacy bounces.
    my $auth = Mail::DKIM2::DSN->authenticate(
        Message => dsn_around(verifiable_twohop()),
        PubkeyCallback => $CB, SkipTimestampCheck => 1,
    );
    is($auth->{dsn_result}, 'none', 'an unsigned DSN reports dsn_result none');
    is($auth->{alignment}, 'none', '  ... with no alignment to check');
    ok(!$auth->{dsn_sig}, '  ... and no DSN signature');
    ok($auth->{ok}, '  ... and still authenticates on the returned message alone');
}

# === §12.1.2: "If the verification fails then the DSN MUST NOT be propagated
# any further" -- propagate enforces that itself. ===
{
    my $signer = mk_signer(domain => 'test2.dkim2.com');
    eval {
        Mail::DKIM2::DSN->propagate(
            Message => dsn_around(verifiable_twohop()),
            ForwarderDomain => 'test2.dkim2.com', Signer => $signer,
        );
    };
    like($@, qr/need PubkeyCallback to authenticate/,
        'propagate will not propagate without the means to authenticate');
}

{
    # The returned message does not verify (signed_inbound's d=/mf= mismatch).
    my $signer = mk_signer(domain => 'test2.dkim2.com');
    eval {
        Mail::DKIM2::DSN->propagate(
            Message => dsn_around(forwarded_unchanged()),
            ForwarderDomain => 'test2.dkim2.com', Signer => $signer,
            PubkeyCallback => $CB, SkipTimestampCheck => 1,
        );
    };
    like($@, qr/did not authenticate/,
        'propagate refuses a DSN whose returned message does not verify');
}

{
    # Everything verifies, but the DSN came from a domain the message was
    # never sent to -- the forged-bounce case point 1 exists for.
    my $signer = mk_signer(domain => 'test2.dkim2.com');
    eval {
        Mail::DKIM2::DSN->propagate(
            Message => signed_dsn_around(verifiable_twohop(), domain => 'test4.dkim2.com'),
            ForwarderDomain => 'test2.dkim2.com', Signer => $signer,
            PubkeyCallback => $CB, SkipTimestampCheck => 1,
        );
    };
    like($@, qr/not aligned/,
        'propagate refuses a DSN that is not aligned with the returned rt=');
}

{
    # ... and propagates the one that authenticates in full.
    my $out = Mail::DKIM2::DSN->propagate(
        Message => signed_dsn_around(verifiable_twohop(), domain => 'test3.dkim2.com'),
        ForwarderDomain => 'test2.dkim2.com',
        Signer => mk_signer(domain => 'test2.dkim2.com'),
        PubkeyCallback => $CB, SkipTimestampCheck => 1,
    );
    is($out->{upstream_mailfrom}, '<sender@test1.dkim2.com>',
        'propagate does propagate a DSN that authenticates in full');
    # The inbound DSN was itself signed -- the only kind §12.1.2 is about --
    # so its own instance and signature must not survive into ours.
    my $m = Email::MIME->new($out->{raw});
    is(scalar(() = $m->header_raw('Message-Instance')), 1,
        '  ... carrying exactly one Message-Instance, not the sender\'s as well');
    my @sigs = map { Mail::DKIM2::Signature->parse($_) } $m->header_raw('DKIM2-Signature');
    is(scalar @sigs, 1, '  ... and exactly one DKIM2-Signature');
    is($sigs[0]->domain, 'test2.dkim2.com', '  ... ours');
    is($sigs[0]->version, 1, '  ... covering m=1, not m=2 of somebody else\'s chain');
}

done_testing;
