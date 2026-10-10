#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use JSON;
use Email::MIME;
use File::Temp qw(tempdir);
use File::Find ();

# The Mail::Milter::Authentication framework is mocked (t/lib/MockAuthMilter.pm);
# it must load before the handler modules.
use lib 'lib', 't/lib';
use MockAuthMilter qw(run_sign);
use Mail::Milter::Authentication::Handler::DKIM2Verify;
use Mail::Milter::Authentication::Handler::DKIM2Sign;
use Mail::DKIM2::Common qw(parse_dkim_pubkey strip_mi_versions);
use DKIM2TestKeys;

# Helper: feed a raw message through milter verify callbacks
sub run_verify {
    my ($raw, %opts) = @_;
    # _bare: pass only the given options, as a config file that leaves the
    # rest out would.
    my $config = delete $opts{_bare} ? { %opts } : {
        hide_none => 0,
        dns_overrides => undef,
        add_message_instance => 0,
        snapshot_directory => undef,
        %opts,
    };

    my $handler = Mail::Milter::Authentication::Handler::DKIM2Verify->new(
        config => $config,
    );

    # Set up pubkey callback using dns.json
    # (We can't use dns_overrides config because it requires File::Slurp)

    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;

    # Parse headers and body
    my ($header_block, $body) = split /\r\n\r\n/, $raw, 2;
    my @header_lines;
    my $current = '';
    for my $line (split /\r\n/, $header_block) {
        if ($line =~ /^\s/ && $current ne '') {
            $current .= "\r\n$line";
        } else {
            push @header_lines, $current if $current ne '';
            $current = $line;
        }
    }
    push @header_lines, $current if $current ne '';

    # Run callbacks
    $handler->envfrom_callback('<sender@test1.dkim2.com>');

    for my $hline (@header_lines) {
        my ($name, $value) = $hline =~ /^([^\s:]+)\s*:\s*(.*)/s;
        $handler->header_callback($name, $value, $hline);
    }

    $handler->eoh_callback();

    # Now set up the pubkey callback on the verifier object
    my $verifier = $handler->get_object('dkim2_verifier');
    if ($verifier) {
        $verifier->set_pubkey_callback(DKIM2TestKeys::pubkey_callback());
        $verifier->skip_timestamp_check(1);
    }

    # Feed body in chunks
    if (defined $body) {
        my @chunks = ($body =~ /(.{1,256})/gs);
        for my $chunk (@chunks) {
            $handler->body_callback($chunk);
        }
    }

    $handler->eom_callback();

    return $handler;
}

# === Tests ===

diag("=== DKIM2Verify milter tests ===");

# Test 1: Verify a signed message through milter callbacks
{
    # Generate a signed message inline
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;
    my $msg = Email::MIME->new($raw);
    my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
    my $mi_str = "Message-Instance: " . $mi->as_string() . "\r\n";
    my $with_mi = $mi_str . $raw;
    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'test1.dkim2.com',
        Selector => 'rsa1024',
        Key      => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
        MailFrom => 'sender@test1.dkim2.com',
        RcptTo   => ['recipient@test2.dkim2.com'],
    );
    $signer->PRINT($with_mi);
    $signer->CLOSE();
    my $signed_msg = $signer->as_string() . "\r\n" . $with_mi;

    my $handler = run_verify($signed_msg);
    my @auth = @{$handler->{_auth_headers}};
    ok(@auth > 0, "verify signed: auth header added");
    is($auth[0]->{value}, 'pass', "verify signed: result is pass");
}

# Test 2: options left out of the config take their documented defaults.
# The authentication_milter framework never merges default_config() into
# the running config, so the handler applies its own: add_message_instance
# is on unless set to 0.
{
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;
    my $signer = Mail::DKIM2::Signer->new(
        Domain   => 'test1.dkim2.com',
        Selector => 'rsa1024',
        Key      => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
        MailFrom => 'sender@test1.dkim2.com',
        RcptTo   => ['recipient@test2.dkim2.com'],
    );
    my $with_mi = "Message-Instance: "
        . Mail::DKIM2::MessageInstance->calculate(Email::MIME->new($raw))->as_string() . "\r\n" . $raw;
    $signer->PRINT($with_mi);
    $signer->CLOSE();
    my $signed_msg = $signer->as_string() . "\r\n" . $with_mi;

    my $snap = tempdir(CLEANUP => 1);
    my $handler = run_verify($signed_msg, _bare => 1, snapshot_directory => $snap);
    is($handler->{_auth_headers}[0]{value}, 'pass', 'defaults: verify passes');
    my $files_in = sub { my @f; File::Find::find(sub { push @f, $File::Find::name if -f }, $_[0]); @f };
    my @stored = $files_in->($snap);
    ok(@stored, 'defaults: add_message_instance defaults on (snapshot stored)');

    # Without a snapshot_directory there is nothing to store, so the handler
    # must not run MessageInstance->verify just to pick a key.
    {
        my $calls = 0;
        no warnings 'redefine';
        my $orig = \&Mail::DKIM2::MessageInstance::verify;
        local *Mail::DKIM2::MessageInstance::verify = sub { $calls++; goto &$orig };
        run_verify($signed_msg, _bare => 1);
        my $without = $calls;
        $calls = 0;
        run_verify($signed_msg, _bare => 1, snapshot_directory => tempdir(CLEANUP => 1));
        is($calls - $without, 1, 'no snapshot_directory: the snapshot-key verify is skipped');
    }

    my $snap0 = tempdir(CLEANUP => 1);
    run_verify($signed_msg, _bare => 1, snapshot_directory => $snap0, add_message_instance => 0);
    my @none = $files_in->($snap0);
    is(scalar @none, 0, 'defaults: an explicit add_message_instance => 0 still wins');
}

# Test 3: Message with no DKIM2-Signature
{
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    my $handler = run_verify($raw);
    my @auth = @{$handler->{_auth_headers}};
    ok(@auth > 0, "no-sig: auth header added");
    is($auth[0]->{value}, 'none', "no-sig: result is none");
}

diag("=== DKIM2Sign milter tests ===");

# Test 5: Sign a message through milter callbacks
{
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    my ($handler, $mock) = run_sign($raw,
        domains => {
            'test1.dkim2.com' => {
                selector => 'rsa1024',
                key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'rsa1024'),
            },
        },
    );

    my @pre = @{$mock->{pre_headers}};
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @pre;
    ok(@dk2 > 0, "sign: DKIM2-Signature header added");

    # Check the signature has expected structure
    my $sig_value = $dk2[0]->{value};
    like($sig_value, qr/i=1/, "sign: signature has i=1");
    like($sig_value, qr/d=test1\.dkim2\.com/, "sign: signature has correct domain");
    like($sig_value, qr/s=/, "sign: signature has s= tag");

    # Check MI was also added
    my @mi = grep { $_->{field} eq 'Message-Instance' } @pre;
    ok(@mi > 0, "sign: Message-Instance header added");
}

# Test 6: Sign should not fire for unauthenticated senders
{
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    my ($handler, $mock) = run_sign($raw,
        _authenticated => 0,
        _local => 0,
        domains => {
            'test1.dkim2.com' => {
                selector => 'rsa1024',
                key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'rsa1024'),
            },
        },
    );

    my @pre = @{$mock->{pre_headers}};
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @pre;
    is(scalar @dk2, 0, "unauth: no signature added");
}

# Test 7: Sign should not fire when domain has no config
{
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    my ($handler, $mock) = run_sign($raw,
        domains => {},  # no domains configured
    );

    my @pre = @{$mock->{pre_headers}};
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @pre;
    is(scalar @dk2, 0, "no-config: no signature added");
}

# Test 8: Round-trip: sign then verify
{
    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    my ($sign_handler, $mock) = run_sign($raw,
        domains => {
            'test1.dkim2.com' => {
                selector => 'rsa1024',
                key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'rsa1024'),
            },
        },
    );

    # Build the signed message from pre_headers + original
    my @pre = @{$mock->{pre_headers}};
    my $EOL = "\r\n";
    my $signed_msg = '';
    for my $h (reverse @pre) {
        $signed_msg .= "$h->{field}: $h->{value}$EOL";
    }
    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;
    $signed_msg .= $raw;

    # Now verify it
    my $verify_handler = run_verify($signed_msg);
    my @auth = @{$verify_handler->{_auth_headers}};
    ok(@auth > 0, "round-trip: auth header added");
    is($auth[0]->{value}, 'pass', "round-trip: verify passes after sign");
}

# Bounce signing: a Postfix-style null-sender DSN gets origin-signed.
{
    my $raw = join("\r\n",
        'From: Mail Delivery System <MAILER-DAEMON@test1.dkim2.com>',
        'To: sender@origin.example',
        'Subject: Undelivered Mail Returned to Sender',
        'Content-Type: multipart/report; report-type=delivery-status; boundary="B"',
        'MIME-Version: 1.0',
        '',
        '--B',
        'Content-Type: text/plain',
        '',
        'This is the mail system. Delivery permanently failed.',
        '--B',
        'Content-Type: message/delivery-status',
        '',
        'Reporting-MTA: dns; mail.test1.dkim2.com',
        'Action: failed',
        'Status: 5.1.1',
        '--B',
        'Content-Type: message/rfc822',
        '',
        'From: orig@elsewhere.example',
        'Subject: greetings',
        '',
        'hello',
        '--B--',
        '');

    my ($handler, $mock) = run_sign($raw,
        env_from => '<>',
        env_rcpt => '<sender@origin.example>',
        domains  => {
            'test1.dkim2.com' => {
                selector => 'rsa1024',
                key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'rsa1024'),
            },
        },
    );

    my @pre = @{$mock->{pre_headers}};
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @pre;
    ok(@dk2 > 0, "bounce: DKIM2-Signature added for null sender");
    my $sig = $dk2[0]->{value};
    like($sig, qr/i=1/,                  "bounce: i=1");
    like($sig, qr/d=test1\.dkim2\.com/,  "bounce: d= from From: header");
    like($sig, qr/mf=PD4=/,              "bounce: mf=<> (base64 PD4=)");
    my @mi = grep { $_->{field} eq 'Message-Instance' } @pre;
    ok(@mi > 0, "bounce: Message-Instance m=1 added");
    like($mi[0]->{value}, qr/m=1/, "bounce: MI is m=1");
}

# Negative: null sender whose From: domain has no key is left unsigned.
{
    my $raw = join("\r\n",
        'From: Mail Delivery System <MAILER-DAEMON@unknown.example>',
        'To: sender@origin.example',
        'Subject: bounce',
        '', 'x', '');
    my ($handler, $mock) = run_sign($raw,
        env_from => '<>',
        env_rcpt => '<sender@origin.example>',
        domains  => {
            'test1.dkim2.com' => {
                selector => 'rsa1024',
                key => DKIM2TestKeys::private_key_pem('test1.dkim2.com', 'rsa1024'),
            },
        },
    );
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @{$mock->{pre_headers}};
    is(scalar @dk2, 0, "bounce: unknown From: domain not signed");
}

diag("=== Forwarding flow tests ===");

# These tests simulate a complete inbound→processing→outbound flow through
# a forwarding MTA that uses DKIM2Verify on inbound and DKIM2Sign on outbound.
#
# INBOUND (DKIM2Verify):
#   1. Message arrives with DKIM2-Signature i=1 + Message-Instance v=1
#   2. Verify checks signatures and MI — passes
#   3. Since MI v=1 already matches content, no new MI is added
#   4. The message is stored as a snapshot, keyed by the MI v=1 value
#
# LOCAL PROCESSING:
#   The MTA may modify the message (add headers, rewrite body, etc.)
#   It may or may not add its own Message-Instance header.
#
# OUTBOUND (DKIM2Sign):
#   1. Sign reconstructs the message from headers+body seen in callbacks
#   2. If add_message_instance is on, checks if topmost MI matches content
#   3. If MI matches → no new MI needed (Case 1 and 3)
#      If MI doesn't match → looks up snapshot for any MI, computes diff
#      MI v=2 with Recipes (Case 2)
#   4. Creates DKIM2-Signature i=2

# Helper: create a signed originator message for forwarding tests
sub make_originator_message {
    use Mail::DKIM2::Signer;
    use Mail::DKIM2::MessageInstance;

    my $raw = path("tests/emails/brong-orig.eml")->slurp;
    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;

    # Calculate MI v=1
    my $msg = Email::MIME->new($raw);
    my $mi = Mail::DKIM2::MessageInstance->calculate($msg);
    my $mi_str = "Message-Instance: " . $mi->as_string() . "\r\n";

    # Prepend MI to message, then sign
    my $with_mi = $mi_str . $raw;
    my $signer = Mail::DKIM2::Signer->new(
        Domain    => 'test1.dkim2.com',
        Selector  => 'rsa1024',
        Key       => DKIM2TestKeys::private_key('test1.dkim2.com', 'rsa1024'),
        MailFrom  => 'sender@test1.dkim2.com',
        RcptTo    => ['foo@test2.dkim2.com'],
        Timestamp => 1740000000,
    );
    $signer->PRINT($with_mi);
    $signer->CLOSE();

    my $result = $signer->as_string() . "\r\n" . $with_mi;

    # Write the originator message for interop testing
    path("tests/expected")->child("milter-originator.eml")->spew($result);

    return $result;
}

# Helper: run the full inbound verify with snapshot storage
sub run_inbound_verify {
    my ($raw, $snapshot_dir) = @_;
    return run_verify($raw,
        add_message_instance => 1,
        snapshot_directory   => $snapshot_dir,
    );
}

# Helper: run the full outbound sign with snapshot lookup
sub run_outbound_sign {
    my ($raw, $snapshot_dir, %extra) = @_;
    my ($handler, $mock) = run_sign($raw,
        domains => {
            'test2.dkim2.com' => {
                selector => 'rsa1024',
                key => DKIM2TestKeys::private_key_pem('test2.dkim2.com', 'rsa1024'),
            },
        },
        add_message_instance => 1,
        snapshot_directory   => $snapshot_dir,
        _authenticated       => 0,
        _local               => 1,
        %extra,
    );
    # Override env_from for the forwarding domain
    $handler->{'env_from'} = '<forwarder@test2.dkim2.com>';
    # Re-run addheader with corrected env_from
    $mock = { pre_headers => [], add_headers => [] };
    $handler->{_changed_headers} = [];
    $handler->addheader_callback($mock);
    # Header changes go through the framework's change_header(), not the
    # mock handler object.
    $mock->{changed_headers} = $handler->{_changed_headers};
    return ($handler, $mock);
}

# Helper: assemble the final outbound message from sign mock output.
# pre_headers are prepended (in reverse, as milters do) to the message
# that was fed to the signer.
sub assemble_outbound {
    my ($input_msg, $mock) = @_;
    my $EOL = "\r\n";
    my $result = '';
    for my $h (reverse @{$mock->{pre_headers}}) {
        my $val = $h->{value};
        $val =~ s/\r?\n/\r\n/gs;
        $result .= "$h->{field}: $val$EOL";
    }
    $input_msg =~ s/\r//gs;
    $input_msg =~ s/\n/\r\n/gs;
    # Apply the header changes the handler asked the framework for (e.g.
    # deleting stripped broken MI headers), in order, as the MTA does: an
    # empty value deletes the index'th field of that name (1-based).
    for my $c (@{$mock->{changed_headers} // []}) {
        my ($hdr, $body) = split /\r\n\r\n/, $input_msg, 2;
        my @fields;
        for my $line (split /\r\n/, $hdr) {
            if ($line =~ /^[ \t]/ && @fields) { $fields[-1] .= "\r\n$line" }
            else                               { push @fields, $line }
        }
        my $n = 0;
        @fields = map {
            my $hit = /^\Q$c->{field}\E\s*:/i && ++$n == $c->{index};
            $hit ? ($c->{value} eq '' ? () : ("$c->{field}: $c->{value}")) : ($_)
        } @fields;
        $input_msg = join("\r\n", @fields) . "\r\n\r\n" . $body;
    }
    $result .= $input_msg;
    return $result;
}

my $expected_dir = path("tests/expected");

# Case 1: Unchanged forwarding
#
# Email arrives at foo@test2.dkim2.com and is forwarded to bar@example.net
# with no changes made.
#
# Flow:
#   Inbound:  DK2-Sig i=1 + MI v=1 arrives → verify pass → MI v=1
#             matches → no new MI → snapshot stored keyed by MI v=1
#   Processing: nothing changes
#   Outbound: MI v=1 still matches → no new MI → sign with DK2-Sig i=2
{
    my $snapshot_dir = tempdir(CLEANUP => 1);
    my $signed_msg = make_originator_message();

    # Inbound
    my $verify_handler = run_inbound_verify($signed_msg, $snapshot_dir);
    is($verify_handler->{_auth_headers}[0]{value}, 'pass',
        'case1: inbound verify passes');
    my @mi_prepended = grep { $_->{field} eq 'Message-Instance' }
                       @{$verify_handler->{_prepended}};
    is(scalar @mi_prepended, 0,
        'case1: inbound did not add MI (v=1 already matches)');

    # No modifications — forward as-is

    # Outbound
    my ($sign_handler, $mock) = run_outbound_sign($signed_msg, $snapshot_dir);
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @{$mock->{pre_headers}};
    my @mi  = grep { $_->{field} eq 'Message-Instance' } @{$mock->{pre_headers}};

    ok(@dk2 > 0,        'case1: outbound added DKIM2-Signature i=2');
    is(scalar @mi, 0,   'case1: outbound did NOT add MI (unchanged)');

    # Write the final outbound message for interop testing
    my $outbound = assemble_outbound($signed_msg, $mock);
    $expected_dir->child("milter-case1-unchanged-forward.eml")->spew($outbound);
}

# Case 2: Modified message, no intermediate MI
#
# Email arrives, local processing adds a List-Id header, but the code
# that added it did not add a Message-Instance header.  The outbound
# sign handler detects the change, finds the snapshot from inbound,
# computes a diff MI v=2 with Recipes, and signs.
#
# Flow:
#   Inbound:  verify pass → snapshot stored keyed by MI v=1
#   Processing: List-Id header added (changes header hash)
#   Outbound: MI v=1 doesn't match → finds snapshot for MI v=1 →
#             computes diff MI v=2 with header Recipe → signs with i=2
{
    my $snapshot_dir = tempdir(CLEANUP => 1);
    my $signed_msg = make_originator_message();

    # Inbound — stores snapshot
    my $verify_handler = run_inbound_verify($signed_msg, $snapshot_dir);
    is($verify_handler->{_auth_headers}[0]{value}, 'pass',
        'case2: inbound verify passes');

    # Local processing adds a header
    my $modified = $signed_msg;
    $modified =~ s/\r\n\r\n/\r\nList-Id: test.list\r\n\r\n/;

    # Outbound — should detect change and compute diff MI
    my ($sign_handler, $mock) = run_outbound_sign($modified, $snapshot_dir);
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @{$mock->{pre_headers}};
    my @mi  = grep { $_->{field} eq 'Message-Instance' } @{$mock->{pre_headers}};

    ok(@dk2 > 0,      'case2: outbound added DKIM2-Signature');
    ok(@mi > 0,        'case2: outbound added MI v=2 (message was modified)');
    if (@mi) {
        like($mi[0]{value}, qr/^m=2/, 'case2: new MI is version 2');
        like($mi[0]{value}, qr/r=/,   'case2: new MI has recipes (diff from snapshot)');
    }

    # Write the final outbound message for interop testing
    my $outbound = assemble_outbound($modified, $mock);
    $expected_dir->child("milter-case2-modified-no-intermediate-mi.eml")->spew($outbound);
}

# Case 2b: the body changed too, and max_recipe_literals decides whether
# the snapshot diff carries the old line or declares the body unrecoverable
# (this handler only adds header fields, so there is no epilogue). Signing
# over its own null is then the host's choice: allow_null_body_recipe.
for my $c (
    ['default', 'diff'],
    ['max_recipe_literals 0', 'refused', max_recipe_literals => 0],
    ['max_recipe_literals 0, allow_null_body_recipe', 'null',
        max_recipe_literals => 0, allow_null_body_recipe => 1],
) {
    my ($name, $want, %extra) = @$c;
    my $snapshot_dir = tempdir(CLEANUP => 1);
    my $signed_msg = make_originator_message();
    run_inbound_verify($signed_msg, $snapshot_dir);
    my $modified = $signed_msg;
    $modified =~ s/(\r\n\r\n)[^\r\n]+/${1}A rewritten first body line/ or die;
    my (undef, $mock) = run_outbound_sign($modified, $snapshot_dir, %extra);
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @{$mock->{pre_headers}};
    my ($mi) = grep { $_->{field} eq 'Message-Instance' } @{$mock->{pre_headers}};
    if ($want eq 'refused') {
        ok(!@dk2 && !$mi, "case2b $name: not signed");
        next;
    }
    ok(@dk2 && $mi, "case2b $name: signed with MI v=2") or next;
    my $p = Mail::DKIM2::MessageInstance->parse($mi->{value});
    is($p->unrecoverable ? 'null' : 'diff', $want, "case2b $name: body Recipe $want");
}

# Case 3: Modified message, intermediate code already added MI v=2
#
# Same as case 2, but the code that added List-Id also correctly added
# its own Message-Instance v=2 describing the change.  The outbound
# sign handler sees MI v=2 matches current content and does NOT add
# another MI — it just signs.
#
# Flow:
#   Inbound:  verify pass → snapshot stored keyed by MI v=1
#   Processing: List-Id added + MI v=2 (with Recipes) added by app code
#   Outbound: MI v=2 matches → no new MI → signs with i=2
{
    my $snapshot_dir = tempdir(CLEANUP => 1);
    my $signed_msg = make_originator_message();

    # Inbound — stores snapshot
    run_inbound_verify($signed_msg, $snapshot_dir);

    # Local processing adds header + computes MI v=2
    my $modified = $signed_msg;
    $modified =~ s/\r\n\r\n/\r\nList-Id: test.list\r\n\r\n/;

    my $orig_msg = Email::MIME->new($signed_msg);
    my $mod_msg  = Email::MIME->new($modified);
    my $mi2 = Mail::DKIM2::MessageInstance->calculate($mod_msg, $orig_msg);
    my $with_mi2 = "Message-Instance: " . $mi2->as_string() . "\r\n" . $modified;

    # Sanity check: MI v=2 should match the modified message
    my $check = Email::MIME->new($with_mi2);
    is(Mail::DKIM2::MessageInstance->verify($check), 2,
        'case3: intermediate MI v=2 matches modified message');

    # Outbound — MI v=2 matches, no new MI needed
    my ($sign_handler, $mock) = run_outbound_sign($with_mi2, $snapshot_dir);
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @{$mock->{pre_headers}};
    my @mi  = grep { $_->{field} eq 'Message-Instance' } @{$mock->{pre_headers}};

    ok(@dk2 > 0,       'case3: outbound added DKIM2-Signature');
    is(scalar @mi, 0,  'case3: outbound did NOT add MI (v=2 already matches)');

    # Write the final outbound message for interop testing
    my $outbound = assemble_outbound($with_mi2, $mock);
    $expected_dir->child("milter-case3-modified-with-intermediate-mi.eml")->spew($outbound);
}

# Case 4: Broken intermediate MI — strip-and-recompute
#
# An upstream hop (e.g. Mailman with a bug) added an MI v=2 whose hash
# is wrong.  The outbound signer detects the mismatch, finds the valid
# snapshot for MI v=1, strips the bad MI v=2 from the chain, and computes
# a correct MI v=2 from the v=1 snapshot.  The resulting outbound message
# has a clean, verifiable chain.
#
# Flow:
#   Inbound:  verify pass → snapshot stored for MI v=1
#   Processing: fake broken MI v=2 prepended (wrong hashes)
#   Outbound: top MI v=2 doesn't match → finds v=1 snapshot →
#             strips v=2 → computes correct MI v=2 → signs with i=2
{
    my $snapshot_dir = tempdir(CLEANUP => 1);
    my $signed_msg = make_originator_message();

    # Inbound — stores snapshot keyed by MI v=1
    my $verify_handler = run_inbound_verify($signed_msg, $snapshot_dir);
    is($verify_handler->{_auth_headers}[0]{value}, 'pass',
        'case4: inbound verify passes');

    # Simulate: mailman added List-Id header BUT computed a broken MI v=2
    # (wrong hashes — all A's — doesn't describe the actual modification)
    my $bad_hash = 'A' x 43 . '=';   # 44-char base64 (32 bytes, all 0x00)
    my $broken_mi2_val = "m=2; h=sha256:${bad_hash}:${bad_hash}";
    my $modified = $signed_msg;
    $modified =~ s/\r//gs;
    $modified =~ s/\n/\r\n/gs;
    $modified =~ s/\r\n\r\n/\r\nList-Id: test.list\r\n\r\n/;   # content change
    my $broken_mi2_line = "Message-Instance: $broken_mi2_val\r\n";
    my $with_broken_mi2 = $broken_mi2_line . $modified;

    # Outbound — should detect v=2 is wrong, strip it, recompute from v=1
    my ($sign_handler, $mock) = run_outbound_sign($with_broken_mi2, $snapshot_dir);
    my @dk2 = grep { $_->{field} eq 'DKIM2-Signature' } @{$mock->{pre_headers}};
    my @mi  = grep { $_->{field} eq 'Message-Instance' } @{$mock->{pre_headers}};
    my @rem = grep { lc($_->{field}) eq 'message-instance' } @{$mock->{changed_headers}};

    ok(@dk2 > 0,       'case4: outbound added DKIM2-Signature');
    ok(@mi > 0,        'case4: outbound added a new MI v=2');
    ok(@rem > 0,       'case4: outbound asked the framework to delete the bad MI v=2');
    if (@mi) {
        like($mi[0]{value}, qr/^m=2/, 'case4: new MI is version 2');
        like($mi[0]{value}, qr/r=/,   'case4: new MI has recipes (diff from snapshot)');
    }
    if (@rem) {
        is(scalar @rem, 1, 'case4: one header deleted');
        is($rem[0]{index}, 1, 'case4: the first Message-Instance field (the broken m=2)');
        is($rem[0]{value}, '', 'case4: deleted (empty value)');
    }

    # Assemble the outbound message (with bad MI v=2 stripped)
    my $outbound = assemble_outbound($with_broken_mi2, $mock);

    # The outbound message must NOT contain the broken MI v=2
    my $parsed = Email::MIME->new($outbound);
    my @all_mi = $parsed->header_raw('Message-Instance');
    my %mi_versions = map { (Mail::DKIM2::Common::extract_mi_version($_) || 0) => 1 } @all_mi;
    ok(!$mi_versions{2} || do {
        # Verify the m=2 that IS there is the new correct one (not the fake)
        my ($good_mi2) = grep { (Mail::DKIM2::Common::extract_mi_version($_) || 0) == 2 } @all_mi;
        defined $good_mi2 && $good_mi2 !~ /\Q$bad_hash\E/;
    }, 'case4: outbound does not contain the broken MI v=2');

    # The assembled outbound message must verify clean
    my $verify2 = run_verify($outbound);
    is($verify2->{_auth_headers}[0]{value}, 'pass',
        'case4: outbound message verifies clean after strip-and-recompute');

    $expected_dir->child("milter-case4-broken-mi-stripped.eml")->spew($outbound);
}

done_testing();
