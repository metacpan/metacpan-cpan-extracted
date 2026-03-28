#!/usr/bin/env perl
# =============================================================================
# t/integration.t  —  Black-box, end-to-end integration tests for
#                     Email::Abuse::Investigator
#
# Philosophy
# ----------
# These tests treat the package as a sealed unit.  No internal slots are
# read or written; no private methods are called.  Every subtest:
#
#   1. Constructs a realistic raw email from scratch
#   2. Feeds it to new() + parse_email()
#   3. Calls only the documented public API
#   4. Asserts on the observable output of those calls
#
# Network I/O is replaced with deterministic stubs installed at the package
# level before each subtest and restored afterwards.  The stubs are as
# realistic as possible — they return data shaped exactly like real DNS and
# WHOIS responses, not just empty hashes.
#
# Scenarios are drawn directly from the POD description and Algorithm section.
#
# Run:
#   prove -lv t/integration.t
# =============================================================================

use strict;
use warnings;

use Test::More;
use MIME::Base64      qw( encode_base64 );
use MIME::QuotedPrint qw( encode_qp );
use POSIX             qw( strftime );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";

use_ok('Email::Abuse::Investigator');

# ---------------------------------------------------------------------------
# Network stub infrastructure
# ---------------------------------------------------------------------------
# Each stub_*() function installs package-level overrides that persist for
# the duration of the enclosing lexical block.  Call restore_stubs() at the
# end of every subtest that calls any stub function.

my %_ORIGINAL;
BEGIN {
    for my $fn (qw(
        _reverse_dns  _resolve_host  _whois_ip
        _domain_whois _raw_whois     _rdap_lookup
    )) {
        no strict 'refs';
        $_ORIGINAL{$fn} = \&{ "Email::Abuse::Investigator::$fn" };
    }
}

sub restore_stubs {
    no warnings 'redefine';
    for my $fn (keys %_ORIGINAL) {
        no strict 'refs';
        *{ "Email::Abuse::Investigator::$fn" } = $_ORIGINAL{$fn};
    }
}

# Install a complete, coherent set of network stubs.
# Parameters (all optional):
#   rdns         => sub($ip)         | string  — rDNS result
#   resolve      => sub($host)       | hashref | string — A-record result
#   whois_ip     => sub($ip)         | hashref — IP WHOIS result
#   domain_whois => sub($dom)        | string  — raw domain WHOIS text
sub install_stubs {
    my (%ov) = @_;
    no warnings 'redefine';

    *Email::Abuse::Investigator::_reverse_dns = ref($ov{rdns}) eq 'CODE'
        ? $ov{rdns}
        : sub { $ov{rdns} // undef };

    *Email::Abuse::Investigator::_resolve_host = ref($ov{resolve}) eq 'CODE'
        ? $ov{resolve}
        : sub {
            my (undef, $host) = @_;
            return $host if $host =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
            my $r = $ov{resolve};
            return undef unless defined $r;
            return ref $r eq 'HASH' ? ($r->{$host} // undef) : $r;
        };

    *Email::Abuse::Investigator::_whois_ip = ref($ov{whois_ip}) eq 'CODE'
        ? $ov{whois_ip}
        : sub {
            my (undef, $ip) = @_;
            my $w = $ov{whois_ip};
            return {} unless defined $w;
            return ref $w eq 'HASH' ? $w : {};
        };

    *Email::Abuse::Investigator::_domain_whois = ref($ov{domain_whois}) eq 'CODE'
        ? $ov{domain_whois}
        : sub { $ov{domain_whois} // undef };

    # These are never needed in integration tests (covered by the above)
    *Email::Abuse::Investigator::_raw_whois  = sub { undef };
    *Email::Abuse::Investigator::_rdap_lookup = sub { {} };
}

# ---------------------------------------------------------------------------
# Helper: build a raw RFC 2822 email string
# ---------------------------------------------------------------------------
sub make_raw_email {
    my (%h) = @_;

    # Received: chain — pass an arrayref for multiple hops (most-recent first)
    my @rcvd = ref($h{received}) eq 'ARRAY'
        ? @{ $h{received} }
        : ($h{received} // 'from ext.mail.example (ext.mail.example [91.198.174.42]) by mx.test (Postfix); Mon, 01 Jan 2024 00:00:00 +0000');

    my $from        = $h{from}        // 'Spammer <spammer@spam.example>';
    my $reply_to    = $h{reply_to};
    my $return_path = $h{return_path} // '<spammer@spam.example>';
    my $to          = $h{to}          // 'victim@test.example';
    my $subject     = $h{subject}     // 'Integration test message';
    my $date        = $h{date}        // POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
    my $mid         = $h{message_id}  // '<inttest@spam.example>';
    my $ct          = $h{ct}          // 'text/plain; charset=us-ascii';
    my $cte         = $h{cte}         // '7bit';
    my $auth        = $h{auth}        // '';
    my $xoip        = $h{xoip};
    my $body        = $h{body}        // 'Buy our products now!';

    my $hdrs = '';
    $hdrs .= "Received: $_\n" for @rcvd;
    $hdrs .= "Authentication-Results: $auth\n" if $auth;
    $hdrs .= "Return-Path: $return_path\n";
    $hdrs .= "From: $from\n";
    $hdrs .= "Reply-To: $reply_to\n"           if defined $reply_to;
    $hdrs .= "To: $to\n";
    $hdrs .= "Subject: $subject\n";
    $hdrs .= "Date: $date\n";
    $hdrs .= "Message-ID: $mid\n";
    $hdrs .= "Content-Type: $ct\n";
    $hdrs .= "Content-Transfer-Encoding: $cte\n";
    $hdrs .= "X-Originating-IP: $xoip\n"       if defined $xoip;

    return "$hdrs\n$body";
}

# ---------------------------------------------------------------------------
# Scenario 1 — Classic direct-to-MX spam
#
# POD question 1: "Where did the message really come from?"
# A single external Received: hop from a known bad IP; no private relays.
# All five public pipeline methods are exercised in concert.
# ---------------------------------------------------------------------------
subtest 'Scenario 1: direct-to-MX spam — full pipeline' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail.badactor.example',
        resolve  => { 'spamsite.example' => '91.198.174.99' },
        whois_ip => {
            org     => 'Rogue Hosting Corp',
            abuse   => 'abuse@rogue-hosting.example',
            country => 'RU',
        },
        domain_whois => sub {
            my (undef, $dom) = @_;
            return undef unless $dom eq 'spamsite.example';
            return <<'WHOIS';
Registrar: Dodgy Registrar Inc
Registrar Abuse Contact Email: abuse@dodgy-reg.example
Creation Date: 2025-11-01
Registry Expiry Date: 2026-11-01
WHOIS
        },
    );

    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_raw_email(
        received => 'from badactor (badactor [91.198.174.42]) by mx.test',
        from     => 'Deals <deals@spamsite.example>',
        body     => 'Visit https://spamsite.example/offer to claim your prize.',
    ));

    # --- originating_ip() ---
    my $orig = $a->originating_ip();
    ok defined $orig,                          'originating_ip returns a value';
    is $orig->{ip},         '91.198.174.42',   'correct originating IP extracted';
    is $orig->{rdns},       'mail.badactor.example', 'rDNS resolved';
    is $orig->{confidence}, 'medium',           'single hop → medium confidence';
    like $orig->{org},      qr/Rogue Hosting/,  'org from IP WHOIS';
    like $orig->{abuse},    qr/abuse\@/,        'abuse contact from IP WHOIS';

    # --- embedded_urls() ---
    my @urls = $a->embedded_urls();
    is scalar @urls, 1,                        'one URL found';
    is $urls[0]{host}, 'spamsite.example',     'correct URL host';
    is $urls[0]{ip},   '91.198.174.99',        'URL host resolved to IP';
    like $urls[0]{org}, qr/Rogue Hosting/,     'URL host org from WHOIS';

    # --- mailto_domains() ---
    my @doms = $a->mailto_domains();
    my ($spam_dom) = grep { $_->{domain} eq 'spamsite.example' } @doms;
    ok defined $spam_dom,                      'spamsite.example in mailto_domains';
    is $spam_dom->{registrar},
        'Dodgy Registrar Inc',                 'registrar from domain WHOIS';
    is $spam_dom->{registrar_abuse},
        'abuse@dodgy-reg.example',             'registrar abuse contact from WHOIS';
    is $spam_dom->{recently_registered}, 1,    'recently_registered flag set';

    # --- all_domains() ---
    my @all = $a->all_domains();
    ok scalar(grep { $_ eq 'spamsite.example' } @all),
        'spamsite.example appears in all_domains';
    my %seen; $seen{$_}++ for @all;
    ok !scalar(grep { $seen{$_} > 1 } @all), 'no duplicates in all_domains';

    # --- risk_assessment() ---
    my $risk = $a->risk_assessment();
    ok $risk->{level} ne 'INFO',               'risk level is not INFO for clear spam';
    ok $risk->{score} > 0,                     'non-zero risk score';
    my @flag_names = map { $_->{flag} } @{ $risk->{flags} };
    ok scalar(grep { $_ eq 'recently_registered_domain' } @flag_names),
        'recently_registered_domain flagged';

    # --- abuse_contacts() ---
    my @contacts = $a->abuse_contacts();
    ok @contacts > 0,                          'at least one abuse contact';
    my @addrs = map { lc $_->{address} } @contacts;
    ok scalar(grep { $_ eq 'abuse@rogue-hosting.example' } @addrs),
        'sending ISP abuse contact present';
    ok scalar(grep { $_ eq 'abuse@dodgy-reg.example' } @addrs),
        'registrar abuse contact present';
    # Every contact has the required fields
    for my $c (@contacts) {
        ok $c->{address} =~ /\@/, "contact $c->{address} has valid address";
        ok $c->{via} =~ /^(?:ip-whois|domain-whois|provider-table|rdap)$/,
            "contact via '$c->{via}' is a documented value";
    }

    # --- report() ---
    my $report = $a->report();
    like $report, qr/91.198.174.42/,            'originating IP in report';
    like $report, qr/spamsite\.example/,            'spam domain in report';
    like $report, qr/RECENTLY REGISTERED/,          'recently registered warning in report';
    like $report, qr/https:\/\/spamsite\.example/,  'URL in report';
    like $report, qr/abuse\@rogue-hosting\.example/,'hosting abuse in report';
    like $report, qr/abuse\@dodgy-reg\.example/,    'registrar abuse in report';

    # --- abuse_report_text() ---
    my $art = $a->abuse_report_text();
    like $art, qr/RISK LEVEL/,              'RISK LEVEL in abuse_report_text';
    like $art, qr/ORIGINATING IP/,          'ORIGINATING IP in abuse_report_text';
    like $art, qr/ORIGINAL MESSAGE HEADERS/,'headers section in abuse_report_text';
    like $art, qr/received:/i,              'Received: header included';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 2 — Webmail-sent spam (Gmail origin)
#
# POD description item 1: "Walks the Received: chain, skips private/trusted
# IPs, and identifies the first external hop."
# The chain contains private relays that must be skipped.
# The sending account is Gmail → provider-table contact expected.
# ---------------------------------------------------------------------------
subtest 'Scenario 2: Gmail-sent spam through internal relays' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns    => 'mail-ej1-f67.google.com',
        resolve => sub {
            my (undef, $host) = @_;
            return '209.85.218.67' if $host =~ /google/;
            return undef;
        },
        whois_ip => {
            org     => 'Google LLC',
            abuse   => 'network-abuse@google.com',
            country => 'US',
        },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new(
        trusted_relays => ['172.31.0.0/16'],   # simulate internal AWS relay
    );
    $a->parse_email(make_raw_email(
        received => [
            # Most-recent (top): our MTA received from Google
            'from mail-ej1-f67.google.com (mail-ej1-f67.google.com [209.85.218.67]) by mx.test',
            # Older (bottom): internal relay — must be skipped
            'from internal-relay.corp (internal-relay.corp [172.31.5.10]) by smtp-out.corp',
        ],
        auth => 'mx.test; spf=pass smtp.mailfrom=gmail.com; dkim=pass header.d=gmail.com; dmarc=pass',
        from => 'SM Investments <fakeco@gmail.com>',
        to   => 'undisclosed-recipients:;',
        body => 'Dear Sir/Madam, please contact vendor@supplierco.example',
    ));

    # The private internal relay must be skipped; Google's IP is the origin
    my $orig = $a->originating_ip();
    is $orig->{ip}, '209.85.218.67', 'internal relay skipped; Google IP is origin';
    like $orig->{rdns}, qr/google\.com/, 'rDNS points to Google';

    # SPF/DKIM/DMARC all passed — authentication checks should not fire
    my $risk = $a->risk_assessment();
    my @auth_flags = grep { $_->{flag} =~ /^(?:spf|dkim|dmarc)_fail$/ }
                     @{ $risk->{flags} };
    is scalar @auth_flags, 0, 'no auth-fail flags when SPF/DKIM/DMARC pass';

    # Gmail From: → free_webmail_sender flag
    ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
        'free_webmail_sender flagged for Gmail sender';

    # undisclosed-recipients → undisclosed_recipients flag
    ok scalar(grep { $_->{flag} eq 'undisclosed_recipients' } @{ $risk->{flags} }),
        'undisclosed_recipients flagged';

    # Provider-table gives Google's abuse address
    my @contacts = $a->abuse_contacts();
    ok scalar(grep { lc($_->{address}) eq 'abuse@google.com' } @contacts),
        'abuse@google.com in contacts via provider table';
    ok scalar(grep { $_->{via} eq 'provider-table' } @contacts),
        'at least one contact discovered via provider-table';

    # Contact domain in body captured
    my @doms = $a->mailto_domains();
    ok scalar(grep { $_->{domain} eq 'supplierco.example' } @doms),
        'bare-address domain from body captured';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 3 — Phishing via display-name spoofing
#
# POD risk_assessment flags: display_name_domain_spoof.
# From: display name says "PayPal Security paypal.com" but the actual
# sending address is at an unrelated domain.
# reply_to_differs_from_from is also triggered.
# ---------------------------------------------------------------------------
subtest 'Scenario 3: display-name spoofing and reply-to misdirection' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail.phishhost.example',
        resolve  => '91.198.174.77',
        whois_ip => { org => 'Phish Host LLC', abuse => 'abuse@phishhost.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received  => 'from phishhost (phishhost [91.198.174.77]) by mx.test',
        from      => '"PayPal Security paypal.com" <noreply@ph1sh-paypal.example>',
        reply_to  => 'collect@harvester.example',
        body      => 'Your account is limited. Verify at https://ph1sh-paypal.example/verify',
    ));

    my $risk = $a->risk_assessment();
    my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

    # POD-documented flag: display_name_domain_spoof
    ok scalar(grep { $_ eq 'display_name_domain_spoof' } @flag_names),
        'display_name_domain_spoof flagged';

    # POD-documented flag: reply_to_differs_from_from
    ok scalar(grep { $_ eq 'reply_to_differs_from_from' } @flag_names),
        'reply_to_differs_from_from flagged';

    # Risk level must be HIGH or MEDIUM (not INFO) for a phishing email
    ok $risk->{level} =~ /^(?:HIGH|MEDIUM)$/,
        "risk level is HIGH or MEDIUM for phishing email (got $risk->{level})";

    # The lookalike domain ph1sh-paypal.example should trigger lookalike_domain
    ok scalar(grep { $_ eq 'lookalike_domain' } @flag_names),
        'lookalike_domain flagged for ph1sh-paypal.example';

    # The URL in the body should be found and its host resolved
    my @urls = $a->embedded_urls();
    is scalar @urls, 1, 'one URL found in phishing body';
    is $urls[0]{host}, 'ph1sh-paypal.example', 'phishing URL host correct';

    # Full report mentions both the IP and the deceptive domain
    my $report = $a->report();
    like $report, qr/91.198.174.77/,           'phishing source IP in report';
    like $report, qr/ph1sh-paypal\.example/,       'lookalike domain in report';
    like $report, qr/paypal/i,                    'PayPal reference appears in report';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 4 — Residential broadband sender (no mail infrastructure)
#
# POD description item 1: "Walks the Received: chain … identifies the first
# external hop."
# rDNS matches the broadband/residential pattern → residential_sending_ip flag.
# No reverse DNS → no_reverse_dns flag scenario covered in its own subtest.
# ---------------------------------------------------------------------------
subtest 'Scenario 4: residential broadband sender triggers risk flags' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => '120-88-161-249.tpgi.com.au',
        resolve  => undef,
        whois_ip => { org => 'TPG Internet Pty Ltd', abuse => 'abuse@tpg.com.au', country => 'AU' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from 120-88-161-249.tpgi.com.au (120.88.161.249) by mx.test',
        from     => '"eharmony Partner" <peacelight@firmluminary.example>',
        subject  => 'Ready to Find Someone Special?',
        body     => 'Find love today.',
    ));

    my $orig = $a->originating_ip();
    is $orig->{ip},  '120.88.161.249',             'broadband IP identified';
    like $orig->{rdns}, qr/tpgi\.com\.au/,         'broadband rDNS present';
    is $orig->{confidence}, 'medium',              'single hop confidence';

    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'residential_sending_ip' } @{ $risk->{flags} }),
        'residential_sending_ip flagged for tpgi.com.au rDNS';

    # Provider table has TPG → abuse@tpg.com.au
    my @contacts = $a->abuse_contacts();
    ok scalar(grep { lc($_->{address}) eq 'abuse@tpg.com.au' } @contacts),
        'TPG abuse contact found via provider table';

    # report() mentions the residential IP
    my $report = $a->report();
    like $report, qr/120\.88\.161\.249/, 'residential IP in report';
    like $report, qr/tpgi\.com\.au/,    'residential rDNS in report';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 5 — URL shortener hiding destination
#
# POD risk_assessment: url_shortener flag.
# Multiple URLs all under bit.ly; plus one legitimate-looking URL.
# ---------------------------------------------------------------------------
subtest 'Scenario 5: URL shortener hides real destination' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns    => 'mail.sender.example',
        resolve => {
            'bit.ly'            => '67.199.248.10',
            'legit.example'     => '192.0.2.50',
        },
        whois_ip => sub {
            my (undef, $ip) = @_;
            return { org => 'Bitly Inc',      abuse => 'abuse@bitly.example'  }
                if $ip eq '67.199.248.10';
            return { org => 'Legit Corp',     abuse => 'abuse@legit.example'  };
        },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from sender (sender [91.198.174.1]) by mx.test',
        body     => 'Click https://bit.ly/abc123 or https://bit.ly/xyz789 '
                  . 'or visit https://legit.example/page for info.',
    ));

    # All three URLs returned
    my @urls = $a->embedded_urls();
    is scalar @urls, 3, 'three URLs found';

    # Hosts correctly identified
    my %hosts = map { $_->{host} => 1 } @urls;
    ok $hosts{'bit.ly'},         'bit.ly identified as URL host';
    ok $hosts{'legit.example'},  'legit.example identified as URL host';

    # WHOIS called once per unique host (two hosts → two calls, not three)
    my $whois_calls = 0;
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_whois_ip = sub {
            $whois_calls++;
            return { org => 'Test', abuse => 'a@b' };
        };
        # Re-parse to reset cached URL data
        $a->parse_email(make_raw_email(
            received => 'from sender (sender [91.198.174.1]) by mx.test',
            body     => 'https://bit.ly/abc123 and https://bit.ly/xyz789 '
                      . 'and https://legit.example/page',
        ));
        my @u2 = $a->embedded_urls();
        is scalar @u2, 3,       're-parsed: three URLs';
        is $whois_calls, 2,     'WHOIS called once per unique host (2 unique hosts)';
    }

    # Restore the real stub so risk_assessment works
    install_stubs(
        rdns    => 'mail.sender.example',
        resolve => { 'bit.ly' => '67.199.248.10', 'legit.example' => '192.0.2.50' },
        whois_ip => { org => 'Test', abuse => 'a@b' },
        domain_whois => undef,
    );
    $a->parse_email(make_raw_email(
        received => 'from sender (sender [91.198.174.1]) by mx.test',
        body     => 'https://bit.ly/abc123 and https://legit.example/page',
    ));

    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'url_shortener' } @{ $risk->{flags} }),
        'url_shortener flagged for bit.ly';
    # Should not flag legit.example as a shortener
    my @shortener_details = grep { $_->{flag} eq 'url_shortener' }
                            @{ $risk->{flags} };
    ok !scalar(grep { $_->{detail} =~ /legit\.example/ } @shortener_details),
        'legit.example not flagged as shortener';

    # Report mentions the shortener warning
    my $report = $a->report();
    like $report, qr/URL SHORTENER/, 'URL SHORTENER warning in report';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 6 — Mailto-only spam (no HTTP links)
#
# POD description item 3: domains extracted from mailto: links and bare
# addresses.  This scenario has zero HTTP/HTTPS URLs — only email addresses
# appear in the body (like the real SM Investments spam).
# The domain pipeline (A→WHOIS, WHOIS) still runs on those domains.
# ---------------------------------------------------------------------------
subtest 'Scenario 6: mailto-only spam — no HTTP URLs, all contact via email' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail-ej1-f67.google.com',
        resolve  => { 'sminvestmentsupplychain.example' => '104.21.0.1' },
        whois_ip => { org => 'Cloudflare Inc', abuse => 'abuse@cloudflare.com', country => 'US' },
        domain_whois => sub {
            my (undef, $dom) = @_;
            return undef unless $dom eq 'sminvestmentsupplychain.example';
            return <<'WHOIS';
Registrar: NameCheap Inc.
Registrar Abuse Contact Email: abuse@namecheap.com
Creation Date: 2025-10-15
Registry Expiry Date: 2026-10-15
WHOIS
        },
    );

    my $bnd = 'SMTP_BOUNDARY_001';
    my $mp  = "--$bnd\r\nContent-Type: text/plain; charset=\"UTF-8\"\r\n\r\n"
            . "Contact us at Onboarding\@sminvestmentsupplychain.example\r\n"
            . "--$bnd\r\nContent-Type: text/html; charset=\"UTF-8\"\r\n\r\n"
            . '<a href="mailto:Onboarding@sminvestmentsupplychain.example">'
            . 'Onboarding@sminvestmentsupplychain.example</a>'
            . "\r\n--$bnd--\r\n";

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from mail-ej1-f67.google.com (mail-ej1-f67.google.com [209.85.218.67]) by mx.test',
        auth     => 'mx.test; spf=pass; dkim=pass header.d=gmail.com',
        from     => 'SM Investments <denatabradley01@gmail.com>',
        to       => 'undisclosed-recipients:;',
        subject  => 'Invitation to Register as a Vendor',
        ct       => qq{multipart/alternative; boundary="$bnd"},
        body     => $mp,
    ));

    # No HTTP/HTTPS URLs
    my @urls = $a->embedded_urls();
    is scalar @urls, 0, 'no HTTP/HTTPS URLs — mailto-only spam';

    # The supply-chain domain captured from both mailto: and bare address in body
    my @doms = $a->mailto_domains();
    my ($dom) = grep { $_->{domain} eq 'sminvestmentsupplychain.example' } @doms;
    ok defined $dom,                                'supply chain domain found';
    is $dom->{web_ip}, '104.21.0.1',               'A record resolved for domain';
    like $dom->{web_org}, qr/Cloudflare/,           'web hosting org identified';
    is $dom->{registrar}, 'NameCheap Inc.',         'registrar from WHOIS';
    is $dom->{registrar_abuse}, 'abuse@namecheap.com', 'registrar abuse from WHOIS';
    is $dom->{recently_registered}, 1,              'recently registered flag set';

    # all_domains includes the supply-chain domain
    my @all = $a->all_domains();
    ok scalar(grep { $_ eq 'sminvestmentsupplychain.example' } @all),
        'supply chain domain in all_domains';

    # Abuse contacts include Cloudflare (web host) and NameCheap (registrar)
    my @contacts = $a->abuse_contacts();
    my @addrs    = map { lc $_->{address} } @contacts;
    ok scalar(grep { $_ eq 'abuse@cloudflare.com'  } @addrs),
        'Cloudflare web-host abuse in contacts';
    ok scalar(grep { $_ eq 'abuse@namecheap.com'   } @addrs),
        'NameCheap registrar abuse in contacts';
    ok scalar(grep { $_ eq 'abuse@google.com'      } @addrs),
        'Google account-provider abuse in contacts (gmail From:)';

    # Report contains all relevant information
    my $report = $a->report();
    like $report, qr/209\.85\.218\.67/,                    'Google IP in report';
    like $report, qr/sminvestmentsupplychain\.example/,    'supply chain domain in report';
    like $report, qr/RECENTLY REGISTERED/,                 'recently registered warning';
    like $report, qr/none found/i,                         '"none found" for URLs section';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 7 — Authentication failures (SPF/DKIM/DMARC all fail)
#
# POD risk_assessment flags: spf_fail, dkim_fail, dmarc_fail.
# Tests that auth results flow from Authentication-Results: header through
# risk_assessment() and into report() and abuse_report_text().
# ---------------------------------------------------------------------------
subtest 'Scenario 7: authentication failures — SPF, DKIM, DMARC all fail' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail.forgeddomain.example',
        resolve  => undef,
        whois_ip => { org => 'Spammer ISP', abuse => 'abuse@spammisp.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from forged (forged [91.198.174.5]) by mx.test',
        auth     => 'mx.test; spf=fail; dkim=fail; dmarc=fail action=reject',
        from     => 'Fake Bank <security@real-bank.example>',
        body     => 'Your account requires verification.',
    ));

    my $risk = $a->risk_assessment();
    my @flag_names = map { $_->{flag} } @{ $risk->{flags} };

    ok scalar(grep { $_ eq 'spf_fail'   } @flag_names), 'spf_fail flagged';
    ok scalar(grep { $_ eq 'dkim_fail'  } @flag_names), 'dkim_fail flagged';
    ok scalar(grep { $_ eq 'dmarc_fail' } @flag_names), 'dmarc_fail flagged';

    # Three HIGH-severity auth failures → score ≥ 9 → HIGH level
    is $risk->{level}, 'HIGH', 'three auth failures → HIGH risk level';
    ok $risk->{score} >= 9,    'score ≥ 9 for three HIGH-severity flags';

    # Each auth flag has the right severity
    for my $fn (qw(spf_fail dkim_fail dmarc_fail)) {
        my ($f) = grep { $_->{flag} eq $fn } @{ $risk->{flags} };
        is $f->{severity}, 'HIGH', "$fn has HIGH severity";
    }

    # abuse_report_text includes the flag details
    my $art = $a->abuse_report_text();
    like $art, qr/RED FLAGS IDENTIFIED/, 'RED FLAGS section in abuse_report_text';
    like $art, qr/spf/i,                 'SPF result mentioned in abuse_report_text';

    # report() shows risk assessment section with HIGH
    my $report = $a->report();
    like $report, qr/RISK ASSESSMENT:\s*HIGH/, 'HIGH risk level in report';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 8 — Trusted relay excluded; two external hops → high confidence
#
# POD description item 1: "skips private/trusted IPs".
# Also exercises the trusted_relays constructor option.
# ---------------------------------------------------------------------------
subtest 'Scenario 8: trusted relay excluded; two external hops give high confidence' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns    => sub {
            my (undef, $ip) = @_;
            return 'mail.attacker.example'     if $ip eq '91.198.174.10';
            return 'relay.legitrelay.example'  if $ip eq '62.105.128.5';
            return undef;
        },
        whois_ip => { org => 'Attacker ISP', abuse => 'abuse@attacker-isp.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new(
        trusted_relays => ['62.105.128.0/24'],  # our own relay
    );
    $a->parse_email(make_raw_email(
        received => [
            # Top (most recent): our trusted relay accepted from external relay
            'from relay.legitrelay.example (relay.legitrelay.example [62.105.128.5]) by mx.test',
            # Middle: an external relay accepted from the attacker
            'from mail.attacker.example (mail.attacker.example [91.198.174.10]) by relay.legitrelay.example',
            # Bottom: the attacker sent directly from this IP
            'from attacker (attacker [91.198.174.10]) by mail.attacker.example',
        ],
        from => 'attacker@attacker.example',
        body => 'Spam content here.',
    ));

    my $orig = $a->originating_ip();

    # The trusted relay (62.105.128.5) must be excluded
    ok $orig->{ip} ne '62.105.128.5', 'trusted relay IP excluded from origin';

    # Two non-trusted hops (91.198.174.10 appears twice) → high confidence
    is $orig->{confidence}, 'high', 'two external hops → high confidence';
    is $orig->{ip}, '91.198.174.10', 'attacker IP identified as origin';

    # Abuse contact for the attacker's IP present
    my @contacts = $a->abuse_contacts();
    ok scalar(grep { lc($_->{address}) eq 'abuse@attacker-isp.example' } @contacts),
        'attacker ISP abuse contact in contacts';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 9 — MIME-encoded headers decoded in report()
#
# POD synopsis: the full pipeline with MIME-encoded From: and Subject:.
# Verifies that report() shows decoded text, not raw encoded-word strings.
# ---------------------------------------------------------------------------
subtest 'Scenario 9: MIME-encoded From: and Subject: decoded in report' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail.sender.example',
        resolve  => undef,
        whois_ip => { org => 'Sender ISP', abuse => 'abuse@sender-isp.example' },
        domain_whois => undef,
    );

    my $enc_from = '=?UTF-8?B?' . encode_base64('eharmony Partner', '') . '?=';
    my $enc_subj = '=?UTF-8?B?' . encode_base64('Ready to Find Someone Special?', '') . '?=';

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from sender (sender [91.198.174.1]) by mx.test',
        from     => qq{"$enc_from" <peacelight\@firmluminary.example>},
        subject  => $enc_subj,
        body     => 'Find the joy of real love today.',
    ));

    my $report = $a->report();

    # Decoded display name appears; raw encoded-word should not be the only form —
    # report() shows "decoded [encoded: raw]" so decoded text must appear first
    like $report, qr/eharmony Partner/,           'decoded From: display name in report';
    like $report, qr/Ready to Find Someone Special/, 'decoded Subject in report';

    # The encoded form may appear in brackets, but decoded text must lead
    like $report, qr/eharmony Partner.*\[encoded:/s,
        'decoded form appears before the bracketed raw encoded value';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 10 — Domain intelligence pipeline (POD Algorithm section)
#
# POD: "For each unique non-infrastructure domain … A record → web hosting,
#       MX record → mail hosting, NS record → DNS hosting, WHOIS → registrar"
# Simulates a domain whose web host, MX host, and NS host are all different
# companies — verifying that all three are independently reported.
# ---------------------------------------------------------------------------
subtest 'Scenario 10: domain intelligence pipeline — web/MX/NS all different' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    # Simulate via domain_whois returning full structured data, and resolve
    # returning different IPs per hostname
    install_stubs(
        rdns    => 'mail.sender.example',
        resolve => sub {
            my (undef, $host) = @_;
            my %map = (
                'spamdom.example'      => '104.21.0.1',   # web host (Cloudflare)
                'mail.spamdom.example' => '74.125.0.1',   # MX (Google)
                'ns1.spamdom.example'  => '198.41.0.1',   # NS (Verisign)
            );
            return $map{$host};
        },
        whois_ip => sub {
            my (undef, $ip) = @_;
            my %data = (
                '104.21.0.1'  => { org => 'Cloudflare Inc',  abuse => 'abuse@cloudflare.com' },
                '74.125.0.1'  => { org => 'Google LLC',       abuse => 'network-abuse@google.com' },
                '198.41.0.1'  => { org => 'VeriSign Inc',     abuse => 'abuse@verisign.example' },
                '91.198.174.1'=> { org => 'Sender ISP',       abuse => 'abuse@sender.example' },
            );
            return $data{$ip} // {};
        },
        domain_whois => sub {
            my (undef, $dom) = @_;
            return undef unless $dom eq 'spamdom.example';
            return <<'WHOIS';
Registrar: GoDaddy.com LLC
Registrar Abuse Contact Email: abuse@godaddy.com
Creation Date: 2020-01-15
Registry Expiry Date: 2030-01-15
WHOIS
        },
    );

    # We need Net::DNS to be available for MX/NS lookups; if it isn't,
    # the domain info simply won't have mx_host/ns_host.
    # Inject the full domain info directly so this test works without Net::DNS.
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from sender (sender [91.198.174.1]) by mx.test',
        from     => 'Spammer <spam@spamdom.example>',
        body     => 'Contact us at info@spamdom.example',
    ));

    # Pre-populate the domain cache with fully resolved data
    # (simulates what _analyse_domain would produce with Net::DNS present)
    $a->{_domain_info}{'spamdom.example'} = {
        web_ip   => '104.21.0.1',
        web_org  => 'Cloudflare Inc',
        web_abuse => 'abuse@cloudflare.com',
        mx_host  => 'mail.spamdom.example',
        mx_ip    => '74.125.0.1',
        mx_org   => 'Google LLC',
        mx_abuse => 'network-abuse@google.com',
        ns_host  => 'ns1.spamdom.example',
        ns_ip    => '198.41.0.1',
        ns_org   => 'VeriSign Inc',
        ns_abuse => 'abuse@verisign.example',
        registrar       => 'GoDaddy.com LLC',
        registrar_abuse => 'abuse@godaddy.com',
        registered      => '2020-01-15',
        expires         => '2030-01-15',
        recently_registered => 0,
    };

    my @contacts = $a->abuse_contacts();
    my @addrs = map { lc $_->{address} } @contacts;

    # All four distinct parties must appear independently
    ok scalar(grep { $_ eq 'abuse@cloudflare.com'       } @addrs),
        'Cloudflare web-host abuse contact present';
    ok scalar(grep { $_ eq 'network-abuse@google.com'   } @addrs),
        'Google MX-host abuse contact present';
    ok scalar(grep { $_ eq 'abuse@verisign.example'     } @addrs),
        'VeriSign NS-host abuse contact present';
    ok scalar(grep { $_ eq 'abuse@godaddy.com'          } @addrs),
        'GoDaddy registrar abuse contact present';

    # All four addresses are distinct — no collapsing
    my %addr_seen;
    my @dups = grep { $addr_seen{$_}++ } @addrs;
    is scalar @dups, 0, 'all four party addresses are distinct (no deduplication collapse)';

    # report() shows all three hosting sections for the domain
    my $report = $a->report();
    like $report, qr/Web host/,  'web host section in report';
    like $report, qr/MX host/,   'MX host section in report';
    like $report, qr/NS host/,   'NS host section in report';
    like $report, qr/Registrar/, 'Registrar section in report';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 11 — Re-parsing with a different email resets all state
#
# POD parse_email: "Accepts a scalar or scalar-ref."
# Tests that a second call to parse_email on the same object completely
# replaces all analysis state — no leakage from the first email.
# ---------------------------------------------------------------------------
subtest 'Scenario 11: re-parsing replaces all state — no leakage between emails' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns    => 'mail.first.example',
        resolve => { 'firstsite.example' => '91.198.174.10' },
        whois_ip => { org => 'First ISP', abuse => 'abuse@first.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();

    # First email: has URL, high-risk sender
    $a->parse_email(make_raw_email(
        received => 'from first (first [91.198.174.10]) by mx.test',
        from     => 'Spammer <bad@gmail.com>',
        body     => 'Visit https://firstsite.example/buy now!',
    ));

    my $orig1  = $a->originating_ip();
    my @urls1  = $a->embedded_urls();
    my @doms1  = $a->mailto_domains();
    my $risk1  = $a->risk_assessment();
    my @cont1  = $a->abuse_contacts();

    is $orig1->{ip}, '91.198.174.10', 'first email: correct origin';
    is scalar @urls1, 1,              'first email: one URL';
    ok $risk1->{score} > 0,           'first email: non-zero risk score';

    # Second email: clean, no URLs, different sender
    install_stubs(
        rdns    => 'mail.clean.example',
        resolve => undef,
        whois_ip => { org => 'Clean ISP', abuse => 'abuse@clean.example' },
        domain_whois => undef,
    );

    $a->parse_email(make_raw_email(
        received => 'from clean (clean [62.105.128.1]) by mx.test',
        from     => 'Newsletter <news@cleanorg.example>',
        body     => 'Monthly newsletter — no links.',
    ));

    my $orig2 = $a->originating_ip();
    my @urls2  = $a->embedded_urls();
    my $risk2  = $a->risk_assessment();

    # Origin completely replaced
    is $orig2->{ip}, '62.105.128.1',    're-parse: new origin IP';
    ok $orig2->{ip} ne $orig1->{ip},   're-parse: origin differs from first email';

    # URLs cleared
    is scalar @urls2, 0, 're-parse: no URLs in second email';

    # Risk cache cleared — second risk is independent of first
    isnt $risk2, $risk1, 're-parse: risk_assessment result is a new object';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 12 — Clean, benign email scores INFO
#
# POD risk_assessment: level is INFO when score < 2.
# SPF/DKIM/DMARC all pass, known sender, normal To:, no URLs, no flags.
# Verifies that the module does not false-positive on legitimate email.
# ---------------------------------------------------------------------------
subtest 'Scenario 12: clean legitimate email scores INFO — no false positives' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail.verifiedcorp.example',
        resolve  => undef,
        whois_ip => { org => 'Verified Corp ISP', abuse => 'abuse@vcorp-isp.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new(
        trusted_relays => ['62.105.128.0/24'],
    );
    $a->parse_email(make_raw_email(
        received     => 'from mail.verifiedcorp.example (mail.verifiedcorp.example [62.105.128.10]) by mx.test',
        auth         => 'mx.test; spf=pass; dkim=pass header.d=verifiedcorp.example; dmarc=pass',
        from         => 'Newsletter <news@verifiedcorp.example>',
        return_path  => '<news@verifiedcorp.example>',
        to           => 'subscriber@test.example',
        subject      => 'Monthly Update',
        message_id   => '<monthly-001@verifiedcorp.example>',
        body         => 'Please find the monthly update attached. No links.',
    ));

    # Clean Received: chain — our trusted relay is the only hop
    # so originating_ip may return undef (all hops trusted)
    # That is correct documented behaviour

    my $risk = $a->risk_assessment();
    is $risk->{level}, 'INFO', 'clean email scores INFO';
    ok $risk->{score} < 2,     'INFO-level score is less than 2';

    # No auth-failure flags
    my @flag_names = map { $_->{flag} } @{ $risk->{flags} };
    ok !scalar(grep { /^(?:spf|dkim|dmarc)_fail$/ } @flag_names),
        'no auth-failure flags on clean email';

    # No URL-related flags
    ok !scalar(grep { /^(?:url_shortener|http_not_https)$/ } @flag_names),
        'no URL flags on email with no URLs';

    # all_domains contains only verifiedcorp.example (the sender domain);
    # no external or unrelated domains should appear
    my @all = $a->all_domains();
    ok !scalar(grep { $_ ne 'verifiedcorp.example' } @all),
        'all_domains contains only the sender domain for a clean single-sender email';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 13 — abuse_contacts() deduplication across all routes
#
# POD abuse_contacts: "Addresses are deduplicated so the same address never
# appears twice, even if it is discovered through multiple routes."
# Cloudflare hosts the web server, NS, and appears in the URL list too.
# ---------------------------------------------------------------------------
subtest 'Scenario 13: abuse_contacts() deduplication across all discovery routes' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        from => 'x@example.org',
        body => 'https://cf-site.example/page',
    ));

    # Cloudflare appears as URL host, web host, NS host, and MX host
    $a->{_origin} = undef;
    $a->{_urls}   = [{
        url   => 'https://cf-site.example/page',
        host  => 'cf-site.example',
        ip    => '104.21.0.1',
        org   => 'CLOUDFLARENET',
        abuse => 'abuse@cloudflare.com',
    }];
    $a->{_mailto_domains} = [{
        domain    => 'cf-site.example',
        source    => 'URL',
        web_abuse => 'abuse@cloudflare.com',
        web_ip    => '104.21.0.1',
        web_org   => 'CLOUDFLARENET',
        mx_abuse  => 'abuse@cloudflare.com',
        mx_host   => 'mx.cf-site.example',
        mx_ip     => '104.21.0.2',
        mx_org    => 'CLOUDFLARENET',
        ns_abuse  => 'abuse@cloudflare.com',
        ns_host   => 'ns1.cf-site.example',
        ns_ip     => '104.21.0.3',
        ns_org    => 'CLOUDFLARENET',
        registrar_abuse => 'abuse@registrar.example',
        registrar       => 'Some Registrar',
    }];

    my @contacts = $a->abuse_contacts();
    my @cf_contacts = grep { lc($_->{address}) eq 'abuse@cloudflare.com' } @contacts;

    is scalar @cf_contacts, 1,
        'abuse@cloudflare.com appears exactly once despite 4 discovery routes';

    # The registrar address is different and should appear once
    my @reg_contacts = grep { lc($_->{address}) eq 'abuse@registrar.example' } @contacts;
    is scalar @reg_contacts, 1, 'registrar abuse address appears exactly once';

    # Total distinct addresses
    my %addr_count;
    $addr_count{ lc $_->{address} }++ for @contacts;
    ok !scalar(grep { $addr_count{$_} > 1 } keys %addr_count),
        'no address appears more than once across all contacts';
};

# ---------------------------------------------------------------------------
# Scenario 14 — report() and abuse_report_text() are consistent
#
# Both methods are called on the same object; they must reference the same
# underlying analysis without re-running it.  The abuse contacts listed in
# abuse_report_text() must be a subset of those returned by abuse_contacts().
# ---------------------------------------------------------------------------
subtest 'Scenario 14: report() and abuse_report_text() consistent on same object' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'mail.spam.example',
        resolve  => { 'spammer.example' => '91.198.174.55' },
        whois_ip => { org => 'Spam ISP', abuse => 'abuse@spam-isp.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from spam (spam [91.198.174.55]) by mx.test',
        from     => 'Offers <offers@spammer.example>',
        body     => 'Big savings at https://spammer.example/deals',
    ));

    my $report = $a->report();
    my $art    = $a->abuse_report_text();
    my @contacts = $a->abuse_contacts();
    my $risk     = $a->risk_assessment();

    # Both texts share the same risk level
    like $report, qr/RISK ASSESSMENT:\s*$risk->{level}/,
        'report() shows same risk level as risk_assessment()';
    like $art, qr/RISK LEVEL:\s*$risk->{level}/,
        'abuse_report_text() shows same risk level';

    # Every contact address from abuse_contacts() must appear in at least one of
    # the two texts (the report shows them; the abuse_report_text shows them too)
    for my $c (@contacts) {
        my $addr = $c->{address};
        my $in_either = ($report =~ /\Q$addr\E/) || ($art =~ /\Q$addr\E/);
        ok $in_either,
            "contact address '$addr' appears in report() or abuse_report_text()";
    }

    # The originating IP appears in both
    my $orig = $a->originating_ip();
    if (defined $orig) {
        like $report, qr/\Q$orig->{ip}\E/, 'originating IP in report()';
        like $art,    qr/\Q$orig->{ip}\E/, 'originating IP in abuse_report_text()';
    }

    # Calling all methods a second time returns identical results (idempotent)
    my $report2 = $a->report();
    is $report2, $report, 'report() is idempotent on same object';

    my $art2 = $a->abuse_report_text();
    is $art2, $art, 'abuse_report_text() is idempotent on same object';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 15 — Multipart HTML spam with tracking pixel and unsubscribe link
#
# POD embedded_urls: "Extracts every http:// and https:// URL from both
# plain-text and HTML parts."
# Tracking pixels (img src) and linked text all produce URL entries.
# All URLs on the same host are grouped; WHOIS is called once.
# ---------------------------------------------------------------------------
subtest 'Scenario 15: multipart HTML spam — tracking pixel, click link, unsubscribe' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    my $whois_calls = 0;
    install_stubs(
        rdns    => 'mail.mailer.example',
        resolve => { 'www.firmluminary.example' => '104.21.13.60' },
        whois_ip => sub {
            $whois_calls++;
            return { org => 'CLOUDFLARENET', abuse => 'abuse@cloudflare.com', country => 'US' };
        },
        domain_whois => undef,
    );

    my $bnd = 'FRM_BOUND';
    # QP-encoded HTML body with three URLs on the same host
    my $html_raw = '<a href="https://www.firmluminary.example/c/link1">Click</a>'
                 . '<a href="https://www.firmluminary.example/u/unsub">Unsubscribe</a>'
                 . '<img src="https://www.firmluminary.example/o/track">';
    my $mp = "--$bnd\r\nContent-Type: text/plain\r\n\r\nPlain version.\r\n"
           . "--$bnd\r\nContent-Type: text/html; charset=utf-8\r\n"
           . "Content-Transfer-Encoding: quoted-printable\r\n\r\n"
           . encode_qp($html_raw, '')
           . "\r\n--$bnd--\r\n";

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => 'from 120-88-161-249.tpgi.com.au (120.88.161.249) by mx.test',
        from     => '"eharmony Partner" <peacelight@firmluminary.example>',
        subject  => 'Ready to Find Someone Special?',
        ct       => qq{multipart/alternative; boundary="$bnd"},
        body     => $mp,
    ));

    my @urls = $a->embedded_urls();

    # All three URLs found
    is scalar @urls, 3, 'three URLs extracted (click, unsubscribe, tracking pixel)';

    # All on the same host
    my @hosts = do { my %h; grep { !$h{$_}++ } map { $_->{host} } @urls };
    is scalar @hosts, 1,                          'all three URLs on single host';
    is $hosts[0], 'www.firmluminary.example',     'correct host identified';

    # WHOIS called once despite three URLs
    is $whois_calls, 1, 'WHOIS queried once for the shared host';

    # report() groups them as "URLs (3)"
    my $report = $a->report();
    like $report, qr/URLs \(3\)/, 'three URLs shown as grouped count in report';
    my @host_lines = ($report =~ /Host\s*:\s*www\.firmluminary\.example/g);
    is scalar @host_lines, 1,     'host shown only once despite three URLs';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 16 — X-Originating-IP webmail fallback
#
# POD originating_ip: falls back to X-Originating-IP when all Received:
# hops are private, with confidence 'low'.
# ---------------------------------------------------------------------------
subtest 'Scenario 16: webmail origin — X-Originating-IP fallback at low confidence' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns     => 'webmail.bigprovider.example',
        whois_ip => { org => 'Big Provider', abuse => 'abuse@bigprovider.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        received => [
            'from webmail.bigprovider.example (webmail.bigprovider.example [10.0.0.1]) by mx.test',
            'from localhost (localhost [127.0.0.1]) by webmail.bigprovider.example',
        ],
        xoip => '62.105.128.200',
        from => 'Webmail User <user@bigprovider.example>',
        body => 'Webmail spam content.',
    ));

    my $orig = $a->originating_ip();
    ok defined $orig,                       'originating_ip returns a value';
    is $orig->{ip},         '62.105.128.200','X-Originating-IP used as origin';
    is $orig->{confidence}, 'low',          'confidence is low for XOIP fallback';
    like $orig->{note}, qr/X-Originating-IP/i,
        'note mentions X-Originating-IP source';

    # Low confidence triggers low_confidence_origin risk flag
    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'low_confidence_origin' } @{ $risk->{flags} }),
        'low_confidence_origin risk flag raised';

    restore_stubs();
};

# ---------------------------------------------------------------------------
# Scenario 17 — all_domains() is the union, no method order dependency
#
# POD all_domains: "Union of every domain seen across HTTP URLs and
# mailto/reply domains."
# Calls all_domains() before embedded_urls() and mailto_domains() to confirm
# lazy evaluation triggers both pipelines correctly.
# ---------------------------------------------------------------------------
subtest 'Scenario 17: all_domains() triggers both pipelines regardless of call order' => sub {
    restore_stubs();  # defensive reset in case prior subtest exited early
    install_stubs(
        rdns    => 'mail.sender.example',
        resolve => {
            'urlhost.example'   => '91.198.174.1',
            'mailhost.example'  => '91.198.174.2',
        },
        whois_ip => { org => 'Test ISP', abuse => 'abuse@test.example' },
        domain_whois => undef,
    );

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_raw_email(
        from => 'x@mailhost.example',
        body => 'Visit https://urlhost.example/page and contact info@mailhost.example',
    ));

    # Call all_domains() FIRST — before embedded_urls() or mailto_domains()
    my @all = $a->all_domains();

    ok scalar(grep { $_ eq 'urlhost.example'  } @all),
        'URL host in all_domains when called before embedded_urls()';
    ok scalar(grep { $_ eq 'mailhost.example' } @all),
        'email domain in all_domains when called before mailto_domains()';

    # Now call the individual methods — they should return consistent data
    my @urls  = $a->embedded_urls();
    my @mdoms = $a->mailto_domains();

    ok scalar(grep { $_->{host} eq 'urlhost.example'   } @urls),
        'embedded_urls() consistent after all_domains() was called first';
    ok scalar(grep { $_->{domain} eq 'mailhost.example' } @mdoms),
        'mailto_domains() consistent after all_domains() was called first';

    restore_stubs();
};

done_testing();
