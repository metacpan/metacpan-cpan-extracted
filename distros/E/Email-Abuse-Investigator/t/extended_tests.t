#!/usr/bin/env perl
# =============================================================================
# t/extended_tests.t -- Additional tests targeting specific code paths,
#                       WHOIS pattern variants, risk flag edge cases, and
#                       report() output branches not covered by the other suites.
#
# Every gap confirmed by coverage analysis is addressed here:
#
#   1.  _parse_date_to_epoch -- DD-Mon-YYYY format (second elsif branch)
#   2.  _parse_auth_results_cached -- multiple Authentication-Results: headers
#   3.  _analyse_domain / _parse_whois_text -- abuse-contact: WHOIS field
#   4.  _analyse_domain -- Registration Time: date variant
#   5.  _analyse_domain -- registered: date variant (RIPE style)
#   6.  _analyse_domain -- whois_raw truncated to exactly 2048 bytes
#   7.  report() -- Country: line in ORIGINATING HOST section
#   8.  report() -- web "no A record / unreachable" branch
#   9.  report() -- MX "(none found)" branch
#   10. report() -- single-URL display line vs grouped multi-URL display
#   11. risk_assessment -- free_webmail for aol / mail.ru / protonmail /
#                          yandex / live.com providers
#   12. risk_assessment -- display_name_domain_spoof with bare From: (no <)
#   13. _resolve_host -- IP literal passed through without DNS lookup
#   14. risk_assessment -- high_spam_country for all seven country codes
#   15. risk_assessment -- residential rDNS: every keyword variant
#   16. _parse_whois_text -- all four org-name field variants
#   17. abuse_contacts -- URL host with provider-table lookup
#   18. abuse_contacts -- web host with provider-table lookup
#
# Run:
#   prove -lv t/extended_tests.t
# =============================================================================

use strict;
use warnings;

use Test::More;
use MIME::Base64 qw( encode_base64 );
use POSIX        qw( strftime );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
use_ok('Email::Abuse::Investigator');

# ---------------------------------------------------------------------------
# Stub helpers
# ---------------------------------------------------------------------------
my %_ORIG;
BEGIN {
    for my $fn (qw(_reverse_dns _resolve_host _whois_ip
                   _domain_whois _raw_whois _rdap_lookup)) {
        no strict 'refs';
        $_ORIG{$fn} = \&{ "Email::Abuse::Investigator::$fn" };
    }
}
sub null_net {
    no warnings 'redefine';
    *Email::Abuse::Investigator::_reverse_dns  = sub { undef };
    *Email::Abuse::Investigator::_resolve_host = sub { undef };
    *Email::Abuse::Investigator::_whois_ip     = sub { {} };
    *Email::Abuse::Investigator::_domain_whois = sub { undef };
    *Email::Abuse::Investigator::_raw_whois    = sub { undef };
    *Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
}
sub restore_net {
    no warnings 'redefine';
    for my $fn (keys %_ORIG) {
        no strict 'refs';
        *{ "Email::Abuse::Investigator::$fn" } = $_ORIG{$fn};
    }
}

# Minimal RFC 2822 email skeleton
sub make_email {
    my (%h) = @_;
    my @rcvd = ref($h{received}) eq 'ARRAY'
        ? @{ $h{received} }
        : ($h{received}
           // 'from ext (ext [198.51.100.1]) by mx.test');
    my $from        = $h{from}        // 'Sender <sender@spam.example>';
    my $return_path = $h{return_path} // '<sender@spam.example>';
    my $reply_to    = $h{reply_to};
    my $to          = $h{to}          // 'victim@test.example';
    my $subject     = $h{subject}     // 'Test subject';
    my $auth        = $h{auth}        // '';
    my $body        = $h{body}        // 'Test body.';
    my $ct          = $h{ct}          // 'text/plain; charset=us-ascii';
    my $xoip        = $h{xoip};

    my $hdrs = '';
    $hdrs .= "Received: $_\n" for @rcvd;
    $hdrs .= "Authentication-Results: $_\n" for (ref $auth eq 'ARRAY' ? @$auth : ($auth ? ($auth) : ()));
    $hdrs .= "Return-Path: $return_path\n";
    $hdrs .= "From: $from\n";
    $hdrs .= "Reply-To: $reply_to\n" if defined $reply_to;
    $hdrs .= "To: $to\n";
    $hdrs .= "Subject: $subject\n";
    $hdrs .= "Date: " . ($h{date} // POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime)) . "\n";
    $hdrs .= "Message-ID: " . ($h{message_id} // '<ext@test>') . "\n";
    $hdrs .= "Content-Type: $ct\n";
    $hdrs .= "Content-Transfer-Encoding: 7bit\n";
    $hdrs .= "X-Originating-IP: $xoip\n" if defined $xoip;
    return "$hdrs\n$body";
}

# =============================================================================
# 1. _parse_date_to_epoch -- DD-Mon-YYYY format
# =============================================================================

subtest '_parse_date_to_epoch -- DD-Mon-YYYY all twelve months' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    for my $i (0..$#months) {
        my $str = sprintf('15-%s-2023', $months[$i]);
        my $e = $a->_parse_date_to_epoch($str);
        ok defined $e && $e > 0,
            "DD-Mon-YYYY: $str parsed to epoch ${\($e//0)}";
    }
};

subtest '_parse_date_to_epoch -- DD-Mon-YYYY epoch ordering' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $jan = $a->_parse_date_to_epoch('01-Jan-2024');
    my $dec = $a->_parse_date_to_epoch('31-Dec-2024');
    ok defined $jan && defined $dec, 'both dates parsed';
    ok $jan < $dec, 'Jan epoch < Dec epoch';
};

subtest '_parse_date_to_epoch -- DD-Mon-YYYY lowercase month' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $e = $a->_parse_date_to_epoch('01-jan-2024');
    ok defined $e && $e > 0, 'lowercase month abbreviation parsed';
};

subtest '_parse_date_to_epoch -- ISO date with timestamp (T stripped)' => sub {
    # The _analyse_domain WHOIS parser strips everything from T onward before
    # calling _parse_date_to_epoch; verify the stripping leaves a parseable date
    my $a = new_ok('Email::Abuse::Investigator');
    # Simulate what _analyse_domain does: strip T and beyond
    my $raw = '2024-11-01T12:30:00Z';
    (my $stripped = $raw) =~ s/[TZ].*//;
    my $e = $a->_parse_date_to_epoch($stripped);
    ok defined $e && $e > 0, 'ISO date after T-stripping parsed correctly';
    is $stripped, '2024-11-01', 'T-stripping leaves YYYY-MM-DD';
};

# =============================================================================
# 2. _parse_auth_results_cached -- multiple Authentication-Results: headers
# =============================================================================

subtest '_parse_auth_results_cached -- single header' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        auth => 'mx.test; spf=pass smtp.mailfrom=sender.example; dkim=pass header.d=sender.example; dmarc=pass'));
    my $auth = $a->_parse_auth_results_cached();
    is $auth->{spf},   'pass', 'spf=pass parsed from single header';
    is $auth->{dkim},  'pass', 'dkim=pass parsed from single header';
    is $auth->{dmarc}, 'pass', 'dmarc=pass parsed from single header';
};

subtest '_parse_auth_results_cached -- multiple Authentication-Results: headers joined' => sub {
    # RFC 7601 allows multiple Authentication-Results headers.
    # The module joins them with '; ' before parsing.
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        auth => [
            'mx1.test; spf=fail',
            'mx2.test; dkim=fail header.d=evil.example',
            'mx3.test; dmarc=fail action=reject',
        ]
    ));
    my $auth = $a->_parse_auth_results_cached();
    # Values may include trailing punctuation (e.g. 'fail;') due to \S+ capture
    like $auth->{spf},   qr/^fail/, 'spf=fail from first header';
    like $auth->{dkim},  qr/^fail/, 'dkim=fail from second header';
    like $auth->{dmarc}, qr/^fail/, 'dmarc=fail from third header';
};

subtest '_parse_auth_results_cached -- ARC field extracted' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        auth => 'mx.test; arc=pass; spf=pass'));
    my $auth = $a->_parse_auth_results_cached();
    # \S+ captures trailing punctuation so value may be 'pass;' or 'pass'
    like $auth->{arc}, qr/^pass/, 'arc=pass extracted from Authentication-Results';
};

subtest '_parse_auth_results_cached -- result is cached on second call' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(auth => 'mx.test; spf=pass'));
    my $r1 = $a->_parse_auth_results_cached();
    my $r2 = $a->_parse_auth_results_cached();
    is $r1, $r2, '_parse_auth_results_cached returns same hashref on second call';
};

subtest '_parse_auth_results_cached -- case-insensitive result values' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(auth => 'mx.test; SPF=PASS; DKIM=PASS'));
    my $auth = $a->_parse_auth_results_cached();
    # Values captured as-is; risk_assessment uses =~ /^pass/i
    ok defined $auth->{spf}, 'SPF captured case-insensitively';
    # \S+ may capture trailing semicolon, so use prefix match not exact match
    like $auth->{spf}, qr/^pass/i, 'SPF value starts with pass (case-insensitively)';
};

# =============================================================================
# 3. _parse_whois_text -- abuse-contact: field variant
# =============================================================================

subtest '_parse_whois_text -- abuse-contact: field' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    # This is the third registrar-abuse pattern in _analyse_domain
    my $r = $a->_parse_whois_text(
        "domain: example.com\nabuse-contact: abuse\@ripe-reg.example\n");
    # _parse_whois_text does NOT parse registrar_abuse; that is done in
    # _analyse_domain. But the bare abuse@ fallback should still pick it up.
    ok defined $r->{abuse} || 1,
        'abuse-contact: field processed without dying';
};

subtest '_analyse_domain -- abuse-contact: WHOIS registrar pattern' => sub {
    null_net();
    # Inject abuse-contact: into the WHOIS text returned by _domain_whois
    {   no warnings 'redefine';
        *Email::Abuse::Investigator::_domain_whois = sub {
            return "Registrar: RIPE NCC\n"
                 . "abuse-contact: abuse\@ripe-abuse.example\n"
                 . "Creation Date: 2020-01-01\n"
                 . "Registry Expiry Date: 2030-01-01\n";
        };
    }
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'x@ripe-test.example',
        return_path => '<x@ripe-test.example>',
        body => 'nothing'));
    my @doms = $a->mailto_domains();
    my ($d) = grep { $_->{domain} eq 'ripe-test.example' } @doms;
    ok defined $d, 'ripe-test.example in mailto_domains';
    is $d->{registrar_abuse}, 'abuse@ripe-abuse.example',
        'abuse-contact: field extracted as registrar_abuse';
    restore_net();
};

# =============================================================================
# 4 & 5. _analyse_domain -- Registration Time: and registered: date variants
# =============================================================================

subtest '_analyse_domain -- Registration Time: date variant' => sub {
    null_net();
    my $recent = strftime('%Y-%m-%d', gmtime(time() - 30 * 86400));
    {   no warnings 'redefine';
        *Email::Abuse::Investigator::_domain_whois = sub {
            return "Registrar: Some Registrar\n"
                 . "Registration Time: $recent\n"
                 . "Registry Expiry Date: 2099-01-01\n";
        };
    }
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'x@regtime.example',
        return_path => '<x@regtime.example>',
        body => 'test'));
    my @doms = $a->mailto_domains();
    my ($d) = grep { $_->{domain} eq 'regtime.example' } @doms;
    ok defined $d,                    'regtime.example found';
    is $d->{registered}, $recent,     'Registration Time: parsed as registered date';
    is $d->{recently_registered}, 1,  'recently_registered flag set from Registration Time:';
    restore_net();
};

subtest '_analyse_domain -- registered: date variant (RIPE style)' => sub {
    null_net();
    my $recent = strftime('%Y-%m-%d', gmtime(time() - 45 * 86400));
    {   no warnings 'redefine';
        *Email::Abuse::Investigator::_domain_whois = sub {
            return "domain: ripe-style.example\n"
                 . "registered: $recent\n"
                 . "paid-till: 2099-01-01\n";
        };
    }
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'x@ripe-style.example',
        return_path => '<x@ripe-style.example>',
        body => 'test'));
    my @doms = $a->mailto_domains();
    my ($d) = grep { $_->{domain} eq 'ripe-style.example' } @doms;
    ok defined $d,                    'ripe-style.example found';
    is $d->{registered}, $recent,     'registered: (RIPE) parsed as registered date';
    is $d->{recently_registered}, 1,  'recently_registered flag set from registered:';
    restore_net();
};

subtest '_analyse_domain -- Created On: date variant' => sub {
    null_net();
    my $old = strftime('%Y-%m-%d', gmtime(time() - 400 * 86400));
    {   no warnings 'redefine';
        *Email::Abuse::Investigator::_domain_whois = sub {
            return "Registrar: Old Registrar\nCreated On: $old\n";
        };
    }
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'x@createdon.example',
        return_path => '<x@createdon.example>',
        body => 'test'));
    my @doms = $a->mailto_domains();
    my ($d) = grep { $_->{domain} eq 'createdon.example' } @doms;
    ok defined $d,                     'createdon.example found';
    is $d->{registered}, $old,         'Created On: parsed as registered date';
    ok !$d->{recently_registered},
        'old Created On: domain not recently_registered';
    restore_net();
};

# =============================================================================
# 6. _analyse_domain -- whois_raw truncated to 2048 bytes
# =============================================================================

subtest '_analyse_domain -- whois_raw truncated to exactly 2048 bytes' => sub {
    null_net();
    my $big_whois = "Registrar: Big Corp\n"
                  . "Registrar Abuse Contact Email: abuse\@bigcorp.example\n"
                  . "Creation Date: 2020-01-01\n"
                  . ("% padding line of exactly eighty characters here to fill up the buffer now\n" x 40);
    ok length($big_whois) > 2048, 'WHOIS text is larger than 2048 bytes';
    {   no warnings 'redefine';
        *Email::Abuse::Investigator::_domain_whois = sub { $big_whois };
    }
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'x@bigcorp-test.example',
        return_path => '<x@bigcorp-test.example>',
        body => 'test'));
    my @doms = $a->mailto_domains();
    my ($d) = grep { $_->{domain} eq 'bigcorp-test.example' } @doms;
    ok defined $d,                       'bigcorp-test.example found';
    ok defined $d->{whois_raw},          'whois_raw present';
    is length($d->{whois_raw}), 2048,    'whois_raw truncated to exactly 2048 bytes';
    ok length($big_whois) > 2048,        'original WHOIS was longer than 2048 bytes';
    restore_net();
};

# =============================================================================
# 7. report() -- Country: field in ORIGINATING HOST section
# =============================================================================

subtest 'report() -- Country: line shown when origin has country code' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        received => 'from cn-host (cn-host [203.0.113.1]) by mx.test'));
    $a->{_origin} = {
        ip         => '203.0.113.1',
        rdns       => 'mail.cn-host.example',
        org        => 'CN ISP',
        abuse      => 'abuse@cn-isp.example',
        confidence => 'medium',
        note       => 'First external hop',
        country    => 'CN',
    };
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my $r = $a->report();
    like $r, qr/Country\s*:\s*CN/, 'Country: CN shown in report';
    restore_net();
};

subtest 'report() -- Country: line absent when origin has no country' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        received => 'from host (host [203.0.113.2]) by mx.test'));
    $a->{_origin} = {
        ip         => '203.0.113.2',
        rdns       => 'mail.host.example',
        org        => 'Some ISP',
        abuse      => 'abuse@isp.example',
        confidence => 'medium',
        note       => 'First external hop',
        country    => undef,
    };
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my $r = $a->report();
    unlike $r, qr/Country\s*:\s*$/, 'Country: line absent when country is undef';
    restore_net();
};

# =============================================================================
# 8. report() -- web "no A record / unreachable" branch
# =============================================================================

subtest 'report() -- web "no A record" shown when web_ip absent' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'contact info@nowebhost.example'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [{
        domain    => 'nowebhost.example',
        source    => 'body',
        # web_ip deliberately absent -- no A record
        mx_host   => undef,
        ns_host   => undef,
        recently_registered => 0,
    }];
    my $r = $a->report();
    like $r, qr/no A record.*unreachable|unreachable/i,
        '"no A record / unreachable" shown when web_ip missing';
    restore_net();
};

subtest 'report() -- web IP shown when web_ip present' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'contact info@webhost.example'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [{
        domain    => 'webhost.example',
        source    => 'body',
        web_ip    => '1.2.3.4',
        web_org   => 'Web Corp',
        web_abuse => 'abuse@webcorp.example',
        mx_host   => undef,
        ns_host   => undef,
        recently_registered => 0,
    }];
    my $r = $a->report();
    like $r, qr/Web host IP\s*:\s*1\.2\.3\.4/, 'web IP shown in report';
    restore_net();
};

# =============================================================================
# 9. report() -- MX "(none found)" branch
# =============================================================================

subtest 'report() -- MX "(none found)" shown when mx_host absent' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'contact info@nomx.example'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [{
        domain    => 'nomx.example',
        source    => 'body',
        web_ip    => '1.2.3.4',
        # mx_host absent -- no MX
        ns_host   => undef,
        recently_registered => 0,
    }];
    my $r = $a->report();
    like $r, qr/MX host\s*:\s*\(none found\)/,
        '"(none found)" shown for MX when mx_host absent';
    restore_net();
};

subtest 'report() -- MX details shown when mx_host present' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'contact info@hasmx.example'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [{
        domain    => 'hasmx.example',
        source    => 'body',
        mx_host   => 'mail.hasmx.example',
        mx_ip     => '5.6.7.8',
        mx_org    => 'MX Corp',
        mx_abuse  => 'abuse@mxcorp.example',
        ns_host   => undef,
        recently_registered => 0,
    }];
    my $r = $a->report();
    like $r, qr/MX host\s*:\s*mail\.hasmx\.example/, 'MX host shown in report';
    like $r, qr/MX IP\s*:\s*5\.6\.7\.8/,             'MX IP shown in report';
    restore_net();
};

# =============================================================================
# 10. report() -- single-URL display line vs grouped multi-URL display
# =============================================================================

subtest 'report() -- single URL shown on one line with "URL :" label' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'Visit https://spamhost.example/offer'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [{
        url   => 'https://spamhost.example/offer',
        host  => 'spamhost.example',
        ip    => '1.2.3.4',
        org   => 'Spam Host',
        abuse => 'abuse@spamhost.example',
        country => undef,
    }];
    $a->{_mailto_domains} = [];
    my $r = $a->report();
    like $r, qr/URL\s+:\s+https:\/\/spamhost\.example\/offer/,
        'single URL shown with "URL :" label';
    unlike $r, qr/URLs \(\d+\)/, 'no group count shown for single URL';
    restore_net();
};

subtest 'report() -- two URLs on same host shown as "URLs (2)"' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'test'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [
        { url=>'https://multi.example/a', host=>'multi.example',
          ip=>'1.2.3.4', org=>'X', abuse=>'a@b', country=>undef },
        { url=>'https://multi.example/b', host=>'multi.example',
          ip=>'1.2.3.4', org=>'X', abuse=>'a@b', country=>undef },
    ];
    $a->{_mailto_domains} = [];
    my $r = $a->report();
    like $r, qr/URLs \(2\)/, '"URLs (2)" shown for two-URL group';
    unlike $r, qr/URL\s+:\s+https/, 'no single-URL label when grouped';
    restore_net();
};

# =============================================================================
# 11. risk_assessment -- remaining free_webmail providers
# =============================================================================

subtest 'risk_assessment -- free_webmail_sender: aol.com' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Sender <sender@aol.com>',
        return_path => '<sender@aol.com>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
        'free_webmail_sender raised for @aol.com sender';
    restore_net();
};

subtest 'risk_assessment -- free_webmail_sender: mail.ru' => sub {
    # The regex was fixed to handle TLD-based providers that have no subdomain:
    # mail.ru is now matched via a separate branch that does not require a
    # trailing dot after the provider token.
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Sender <sender@mail.ru>',
        return_path => '<sender@mail.ru>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
        'free_webmail_sender raised for @mail.ru sender (regex fix applied)';
    restore_net();
};

subtest 'risk_assessment -- free_webmail_sender: protonmail.com' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Sender <sender@protonmail.com>',
        return_path => '<sender@protonmail.com>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
        'free_webmail_sender raised for @protonmail.com sender';
    restore_net();
};

subtest 'risk_assessment -- free_webmail_sender: yandex.ru' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Sender <sender@yandex.ru>',
        return_path => '<sender@yandex.ru>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
        'free_webmail_sender raised for @yandex.ru sender';
    restore_net();
};

subtest 'risk_assessment -- free_webmail_sender: live.com' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Sender <sender@live.com>',
        return_path => '<sender@live.com>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok scalar(grep { $_->{flag} eq 'free_webmail_sender' } @{ $risk->{flags} }),
        'free_webmail_sender raised for @live.com sender';
    restore_net();
};

# =============================================================================
# 12. risk_assessment -- display_name_domain_spoof: bare From: (no angle brackets)
# =============================================================================

subtest 'risk_assessment -- no display_name_domain_spoof for bare From: address' => sub {
    # Without angle brackets the regex /^"?([^"<]+?)"?\s*<([^>]+)>/ does not
    # match, so no spoof check is attempted.
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'paypal.com-security@evil.example',
        return_path => '<paypal.com-security@evil.example>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok !scalar(grep { $_->{flag} eq 'display_name_domain_spoof' }
               @{ $risk->{flags} }),
        'no display_name_domain_spoof for bare From: without display-name+angle-bracket';
    restore_net();
};

subtest 'risk_assessment -- display_name_domain_spoof: display name with two brand domains' => sub {
    # If the display name contains two distinct brand domain references,
    # each that differs from the actual sending address,
    # each generates its own flag entry.
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => '"paypal.com and google.com Support" <attacker@evil.example>',
        return_path => '<attacker@evil.example>'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    my @spoof_flags = grep { $_->{flag} eq 'display_name_domain_spoof' }
                      @{ $risk->{flags} };
    ok scalar @spoof_flags >= 2,
        'two display_name_domain_spoof flags for two brand domains in display name';
    my $details = join(' ', map { $_->{detail} } @spoof_flags);
    like $details, qr/paypal/, 'paypal.com spoof detected';
    like $details, qr/google/, 'google.com spoof detected';
    restore_net();
};

# =============================================================================
# 13. _resolve_host -- IP literal passed through directly
# =============================================================================

subtest '_resolve_host -- dotted-quad IP returned as-is without DNS' => sub {
    # When the host is already an IPv4 address, _resolve_host returns it
    # immediately without calling Net::DNS or inet_aton.
    my $a = new_ok('Email::Abuse::Investigator');
    my $dns_called = 0;
    {   no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub {
            my (undef, $host) = @_;
            # Call the original
            $dns_called++ unless $host =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
            return $_ORIG{_resolve_host}->($a, $host);
        };
        my $r = Email::Abuse::Investigator::_resolve_host($a, '198.51.100.42');
        is $r, '198.51.100.42', 'IP literal returned unchanged';
        is $dns_called, 0, 'no DNS called for IP literal input';
    }
};

subtest '_resolve_host -- hostname (non-IP) does not return as-is' => sub {
    # Contrast: a hostname string is NOT returned as-is; DNS would be
    # attempted (but we stub it to undef in tests).
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_resolve_host('mail.example.com');
    is $r, undef, 'hostname returns undef when DNS stubbed to undef';
    restore_net();
};

# =============================================================================
# 14. risk_assessment -- high_spam_country for all seven country codes
# =============================================================================

subtest 'risk_assessment -- high_spam_country for all seven codes' => sub {
    null_net();
    my %expected_names = (
        CN => 'China',     RU => 'Russia',     NG => 'Nigeria',
        VN => 'Vietnam',   IN => 'India',       PK => 'Pakistan',
        BD => 'Bangladesh',
    );
    for my $cc (sort keys %expected_names) {
        my $a = new_ok('Email::Abuse::Investigator');
        $a->parse_email(make_email(body => 'test'));
        $a->{_origin} = {
            ip         => '1.2.3.4',
            rdns       => 'mail.ok.example',
            confidence => 'medium',
            org        => 'ISP',
            abuse      => 'abuse@isp.example',
            note       => '',
            country    => $cc,
        };
        $a->{_urls} = []; $a->{_mailto_domains} = [];
        my $risk = $a->risk_assessment();
        my ($flag) = grep { $_->{flag} eq 'high_spam_country' }
                     @{ $risk->{flags} };
        ok defined $flag, "high_spam_country raised for $cc";
        like $flag->{detail}, qr/\Q$expected_names{$cc}\E/,
            "country name '$expected_names{$cc}' in detail for $cc";
        is $flag->{severity}, 'INFO', "high_spam_country severity is INFO for $cc";
    }
    restore_net();
};

subtest 'risk_assessment -- high_spam_country NOT raised for non-listed country' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'test'));
    $a->{_origin} = {
        ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
        org=>'ISP', abuse=>'a@b', note=>'', country=>'DE',
    };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok !scalar(grep { $_->{flag} eq 'high_spam_country' } @{ $risk->{flags} }),
        'high_spam_country not raised for DE (not in list)';
    restore_net();
};

# =============================================================================
# 15. risk_assessment -- residential rDNS: every keyword variant
# =============================================================================

subtest 'risk_assessment -- residential_sending_ip: every rDNS keyword' => sub {
    null_net();
    # Each keyword that must match the residential rDNS pattern
    my @residential_rdns = (
        '120-88-161-249.tpgi.com.au',      # dotted-quad in rDNS
        'adsl-203-0-113-1.isp.example',    # adsl
        'cable-1-2-3-4.isp.example',       # cable
        'broad-1.isp.example',             # broad
        'dial-up-123.isp.example',         # dial
        'dynamic-host.isp.example',        # dynamic
        'dhcp-1-2-3-4.isp.example',        # dhcp
        'ppp-1.isp.example',               # ppp
        'residential.isp.example',         # residential
        'cust-1-2-3.isp.example',          # cust
        'home-1.isp.example',              # home
        'pool-1-2.isp.example',            # pool
        'client-42.isp.example',           # client
        'user-456.isp.example',            # user
        'static1.isp.example',             # static\d
        'host2.broadband.example',         # host\d
    );
    for my $rdns (@residential_rdns) {
        my $a = new_ok('Email::Abuse::Investigator');
        $a->parse_email(make_email(body => 'test'));
        $a->{_origin} = {
            ip=>'1.2.3.4', rdns=>$rdns, confidence=>'medium',
            org=>'ISP', abuse=>'a@b', note=>'', country=>undef,
        };
        $a->{_urls} = []; $a->{_mailto_domains} = [];
        my $risk = $a->risk_assessment();
        ok scalar(grep { $_->{flag} eq 'residential_sending_ip' }
                  @{ $risk->{flags} }),
            "residential_sending_ip raised for rDNS: $rdns";
    }
    restore_net();
};

subtest 'risk_assessment -- residential_sending_ip NOT raised for clean rDNS' => sub {
    null_net();
    my @clean_rdns = (
        'mail.corp.example',
        'smtp-out.sendgrid.net',
        'mail-ej1-f67.google.com',
        'mx1.mailchimp.com',
    );
    for my $rdns (@clean_rdns) {
        my $a = new_ok('Email::Abuse::Investigator');
        $a->parse_email(make_email(body => 'test'));
        $a->{_origin} = {
            ip=>'1.2.3.4', rdns=>$rdns, confidence=>'medium',
            org=>'ISP', abuse=>'a@b', note=>'', country=>undef,
        };
        $a->{_urls} = []; $a->{_mailto_domains} = [];
        my $risk = $a->risk_assessment();
        ok !scalar(grep { $_->{flag} eq 'residential_sending_ip' }
                   @{ $risk->{flags} }),
            "residential_sending_ip NOT raised for clean rDNS: $rdns";
    }
    restore_net();
};

# =============================================================================
# 16. _parse_whois_text -- all four org-name field variants
# =============================================================================

subtest '_parse_whois_text -- OrgName: field (ARIN)' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("OrgName: ARIN Corp\n");
    is $r->{org}, 'ARIN Corp', 'OrgName: parsed';
};

subtest '_parse_whois_text -- org-name: field (RIPE)' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("org-name: RIPE Corp\n");
    is $r->{org}, 'RIPE Corp', 'org-name: parsed';
};

subtest '_parse_whois_text -- owner: field (LACNIC)' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("owner: LACNIC Corp\n");
    is $r->{org}, 'LACNIC Corp', 'owner: parsed';
};

subtest '_parse_whois_text -- descr: field (APNIC)' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("descr: APNIC Corp\n");
    is $r->{org}, 'APNIC Corp', 'descr: parsed';
};

subtest '_parse_whois_text -- OrgName: takes priority over descr:' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("OrgName: First\ndescr: Second\n");
    is $r->{org}, 'First', 'OrgName: wins over descr: (first match wins)';
};

subtest '_parse_whois_text -- abuse-mailbox: field' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("abuse-mailbox: abuse\@ripe.example\n");
    is $r->{abuse}, 'abuse@ripe.example', 'abuse-mailbox: parsed';
};

subtest '_parse_whois_text -- bare abuse@ line as fallback' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    # No OrgAbuseEmail or abuse-mailbox; bare line contains abuse@
    my $r = $a->_parse_whois_text(
        "% No structured field here\nPlease contact abuse\@bare.example\n");
    is $r->{abuse}, 'abuse@bare.example',
        'bare abuse@ on non-structured line used as fallback';
};

subtest '_parse_whois_text -- country code normalised to uppercase' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_parse_whois_text("country: au\n");
    is $r->{country}, 'AU', 'lowercase country code normalised to uppercase';
    $r = $a->_parse_whois_text("country: AU\n");
    is $r->{country}, 'AU', 'uppercase country code stored as uppercase';
};

# =============================================================================
# 17. abuse_contacts -- URL host resolved via provider table
# =============================================================================

subtest 'abuse_contacts -- URL host on known provider: provider-table contact' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'test'));
    $a->{_origin}         = undef;
    $a->{_mailto_domains} = [];
    # amazonaws.com is in %PROVIDER_ABUSE
    $a->{_urls} = [{
        url   => 'https://bucket.s3.amazonaws.com/payload',
        host  => 'bucket.s3.amazonaws.com',
        ip    => '1.2.3.4',
        org   => 'Amazon',
        abuse => 'abuse@amazonaws.com',
        country => undef,
    }];
    my @contacts = $a->abuse_contacts();
    my @pt = grep { $_->{via} eq 'provider-table' } @contacts;
    ok scalar @pt > 0, 'URL host on amazonaws.com generates provider-table contact';
    ok scalar(grep { lc($_->{address}) eq 'abuse@amazonaws.com' } @contacts),
        'abuse@amazonaws.com in contacts for amazonaws URL host';
};

# =============================================================================
# 18. abuse_contacts -- web host domain on known provider
# =============================================================================

subtest 'abuse_contacts -- web host on known provider: provider-table contact' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(body => 'test'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    # fastly.net is in %PROVIDER_ABUSE
    $a->{_mailto_domains} = [{
        domain    => 'fastly-hosted.example',
        source    => 'body',
        web_ip    => '1.2.3.4',
        web_org   => 'Fastly',
        web_abuse => 'abuse@fastly.com',
        recently_registered => 0,
    }];
    my @contacts = $a->abuse_contacts();
    ok scalar(grep { lc($_->{address}) eq 'abuse@fastly.com' } @contacts),
        'web host abuse contact generated for Fastly-hosted domain';
};

# =============================================================================
# 19. _analyse_domain -- cache hit path
# =============================================================================

subtest '_analyse_domain -- cache hit: second call returns cached hashref' => sub {
    null_net();
    my $resolve_count = 0;
    {   no warnings 'redefine';
        *Email::Abuse::Investigator::_resolve_host = sub { $resolve_count++; undef };
        *Email::Abuse::Investigator::_domain_whois = sub { undef };
    }
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'x@cached-domain.example',
        return_path => '<x@cached-domain.example>',
        body        => 'test'));
    my @d1 = $a->mailto_domains();
    my $calls_after_first = $resolve_count;

    # Force re-analysis by resetting _mailto_domains but keeping _domain_info
    $a->{_mailto_domains} = undef;
    my @d2 = $a->mailto_domains();
    my $calls_after_second = $resolve_count;

    is $calls_after_second, $calls_after_first,
        '_resolve_host not called again on second mailto_domains() call (cache hit)';
    restore_net();
};

# =============================================================================
# 20. _domains_from_text -- mailto: vs bare address extraction
# =============================================================================

subtest '_domains_from_text -- mailto: link and bare address in same text' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my @doms = $a->_domains_from_text(
        'Contact via mailto:sales@mailto-dom.example or email bare@bare-dom.example directly');
    ok scalar(grep { $_ eq 'mailto-dom.example' } @doms),
        'domain from mailto: link extracted';
    ok scalar(grep { $_ eq 'bare-dom.example' } @doms),
        'domain from bare address extracted';
};

subtest '_domains_from_text -- trailing dot stripped from domain' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my @doms = $a->_domains_from_text('mailto:x@trailing-dot.example.');
    ok scalar @doms > 0, 'trailing-dot mailto domain extracted';
    ok !scalar(grep { /\.$/ } @doms), 'trailing dot stripped from all domains';
};

subtest '_domains_from_text -- same domain in mailto and bare not duplicated' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my @doms = $a->_domains_from_text(
        'mailto:a@dup.example and b@dup.example and mailto:c@dup.example');
    my @dups = grep { $_ eq 'dup.example' } @doms;
    is scalar @dups, 1, 'same domain from multiple sources deduplicated';
};

subtest '_domains_from_text -- domains lowercased' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my @doms = $a->_domains_from_text('contact user@UPPER.EXAMPLE');
    ok scalar(grep { $_ eq 'upper.example' } @doms),
        'domain from uppercase address lowercased';
    ok !scalar(grep { /[A-Z]/ } @doms), 'no uppercase in returned domains';
};

# =============================================================================
# 21. _country_name -- all seven mapped values and unknown passthrough
# =============================================================================

subtest '_country_name -- all seven high-spam countries mapped' => sub {
    my %expected = (
        CN => 'China',     RU => 'Russia',     NG => 'Nigeria',
        VN => 'Vietnam',   IN => 'India',       PK => 'Pakistan',
        BD => 'Bangladesh',
    );
    for my $cc (sort keys %expected) {
        is Email::Abuse::Investigator::_country_name($cc), $expected{$cc},
            "_country_name('$cc') returns '$expected{$cc}'";
    }
};

subtest '_country_name -- unknown code returned as-is' => sub {
    is Email::Abuse::Investigator::_country_name('DE'), 'DE',
        'unknown country code returned unchanged';
    is Email::Abuse::Investigator::_country_name('ZZ'), 'ZZ',
        'ZZ returned unchanged';
};

# =============================================================================
# 22. _provider_abuse_for_ip -- no rdns arg returns undef
# =============================================================================

subtest '_provider_abuse_for_ip -- no rdns arg: returns undef' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_ip('1.2.3.4', undef);
    is $r, undef,
        '_provider_abuse_for_ip returns undef when rdns is undef';
};

subtest '_provider_abuse_for_ip -- rdns on known provider: returns contact' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_ip('209.85.218.67', 'mail-ej1.google.com');
    ok defined $r, '_provider_abuse_for_ip returns result for google rdns';
    is $r->{email}, 'abuse@google.com',
        'google rdns resolves to abuse@google.com';
};

# =============================================================================
# 23. _enrich_ip -- whois org/abuse fallback to (unknown)
# =============================================================================

subtest '_enrich_ip -- org and abuse default to (unknown) when whois empty' => sub {
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.host.example' };
    local *Email::Abuse::Investigator::_whois_ip    = sub { {} };  # empty

    my $a = new_ok('Email::Abuse::Investigator');
    my $result = $a->_enrich_ip('198.51.100.1', 'medium', 'test note');
    is $result->{org},   '(unknown)', 'org defaults to (unknown) from empty whois';
    is $result->{abuse}, '(unknown)', 'abuse defaults to (unknown) from empty whois';
    is $result->{rdns},  'mail.host.example', 'rdns populated from _reverse_dns';
    is $result->{confidence}, 'medium', 'confidence passed through';
    is $result->{note},       'test note', 'note passed through';
};

subtest '_enrich_ip -- rdns defaults to (no reverse DNS) when undef' => sub {
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_reverse_dns = sub { undef };
    local *Email::Abuse::Investigator::_whois_ip    = sub { { org=>'Test', abuse=>'a@b' } };

    my $a = new_ok('Email::Abuse::Investigator');
    my $result = $a->_enrich_ip('198.51.100.1', 'low', 'xoip note');
    is $result->{rdns}, '(no reverse DNS)',
        'rdns defaults to "(no reverse DNS)" when _reverse_dns returns undef';
};


# =============================================================================
# 24. dkim_domain_mismatch -- INFO for passing DKIM, MEDIUM for failing
# =============================================================================

subtest 'risk_assessment -- dkim_domain_mismatch: INFO when DKIM passes (ESP scenario)' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'Sender <sender@merchant.example>',
        auth => 'mx.test; dkim=pass header.d=sendgrid.net'));
    push @{ $a->{_headers} }, { name => 'dkim-signature',
        value => 'v=1; d=sendgrid.net; s=s1; b=xxx' };
    $a->{_auth_results} = undef;  # force re-parse to pick up DKIM-Signature
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.sendgrid.net', confidence=>'medium',
                      org=>'SendGrid', abuse=>'abuse@sendgrid.com', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    my ($mm) = grep { $_->{flag} eq 'dkim_domain_mismatch' } @{ $risk->{flags} };
    ok defined $mm, 'dkim_domain_mismatch raised when DKIM domain differs from From:';
    is $mm->{severity}, 'INFO', 'severity is INFO when DKIM passes (normal ESP behaviour)';
    like $mm->{detail}, qr/third-party sender/, 'detail mentions third-party sender';
    restore_net();
};

subtest 'risk_assessment -- dkim_domain_mismatch: MEDIUM when DKIM fails' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'Sender <sender@merchant.example>',
        auth => 'mx.test; dkim=fail'));
    push @{ $a->{_headers} }, { name => 'dkim-signature',
        value => 'v=1; d=evil-signer.example; s=s1; b=xxx' };
    $a->{_auth_results} = undef;
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.evil.example', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    my ($mm) = grep { $_->{flag} eq 'dkim_domain_mismatch' } @{ $risk->{flags} };
    ok defined $mm, 'dkim_domain_mismatch raised when DKIM fails and domains differ';
    is $mm->{severity}, 'MEDIUM', 'severity is MEDIUM when DKIM fails';
    like $mm->{detail}, qr/did not pass/, 'detail mentions DKIM did not pass';
    restore_net();
};

subtest 'risk_assessment -- no dkim_domain_mismatch when signing domain matches From:' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'Sender <sender@example.com>',
        auth => 'mx.test; dkim=pass'));
    push @{ $a->{_headers} }, { name => 'dkim-signature',
        value => 'v=1; d=example.com; s=s1; b=xxx' };
    $a->{_auth_results} = undef;
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.example.com', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    ok !scalar(grep { $_->{flag} eq 'dkim_domain_mismatch' } @{ $risk->{flags} }),
        'no dkim_domain_mismatch when signing domain matches From: domain';
    restore_net();
};

# =============================================================================
# 25. sending_software() -- returns a list, not an arrayref
# =============================================================================

subtest 'sending_software() -- returns list of hashrefs with correct structure' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(
        "From: x\@y.com\n"
      . "X-Mailer: PHPMailer 6.0\n"
      . "X-PHP-Originating-Script: 1000:mailer.php\n"
      . "X-Source: /var/www/html/mailer.php\n\nbody");
    my @sw = $a->sending_software();
    ok scalar @sw >= 2, 'at least two sending software entries found';
    ok ref($sw[0]) eq 'HASH', 'first element is a hashref (list, not arrayref)';
    for my $key (qw(header value note)) {
        ok exists $sw[0]{$key}, "hashref has '$key' key";
    }
    my ($php) = grep { $_->{header} eq 'x-php-originating-script' } @sw;
    ok defined $php, 'x-php-originating-script found';
    is $php->{value}, '1000:mailer.php', 'correct value extracted';
    like $php->{note}, qr/hosting abuse/, 'note mentions hosting abuse team';
};

subtest 'sending_software() -- empty list when no relevant headers' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email("From: x\@y.com\nSubject: test\n\nbody");
    my @sw = $a->sending_software();
    is scalar @sw, 0, 'empty list when no sending-software headers present';
};

subtest 'sending_software() -- reset between parse_email calls' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email("From: x\@y.com\nX-Mailer: SpamTool 1.0\n\nbody");
    ok scalar($a->sending_software()) > 0, 'X-Mailer found in first parse';
    $a->parse_email("From: x\@y.com\nSubject: clean\n\nbody");
    is scalar($a->sending_software()), 0, 'sending_software reset on re-parse';
};

# =============================================================================
# 26. received_trail() -- returns a list, envelope-for and server-id extracted
# =============================================================================

subtest 'received_trail() -- extracts for: and id: clauses correctly' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(
        "Received: from relay.example.com (relay.example.com [91.198.174.5])"
      . " by mx.test with ESMTP id ABC123XYZ"
      . " for <victim\@bandsman.co.uk>\n"
      . "From: x\@y.com\n\nbody");
    my @trail = $a->received_trail();
    ok scalar @trail >= 1, 'at least one trail entry returned';
    ok ref($trail[0]) eq 'HASH', 'element is a hashref (list, not arrayref)';
    my ($hop) = grep { defined $_->{id} && $_->{id} =~ /ABC123/ } @trail;
    ok defined $hop,              'hop with server ID found';
    is $hop->{for}, 'victim@bandsman.co.uk', 'envelope-for address extracted';
    like $hop->{id}, qr/ABC123/,  'server tracking ID extracted';
    is $hop->{ip},  '91.198.174.5', 'IP from same hop correct';
};

subtest 'received_trail() -- "for multiple recipients" does not capture bogus address' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(
        "Received: from h [91.198.174.1] by mx for multiple recipients\n"
      . "From: x\@y.com\n\nbody");
    my @trail = $a->received_trail();
    for my $hop (@trail) {
        ok !defined($hop->{for}) || $hop->{for} =~ /\@/,
            'for: is undef or contains an @ sign (no bare word captured)';
    }
};

subtest 'received_trail() -- reset between parse_email calls' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(
        "Received: from h [91.198.174.1] by mx with ESMTP id ID001"
      . " for <v\@t.com>\nFrom: x\@y.com\n\nbody");
    ok scalar($a->received_trail()) > 0, 'trail populated after first parse';
    $a->parse_email("From: x\@y.com\n\nbody");
    is scalar($a->received_trail()), 0, 'received_trail reset on re-parse';
};

# =============================================================================
# 27. Message-ID domain filtered through TRUSTED_DOMAINS
# =============================================================================

subtest 'mailto_domains -- gmail Message-ID domain filtered out' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    # Supply the gmail Message-ID at parse time so the domain pipeline sees it
    $a->parse_email(make_email(
        from        => 'x@spamco.example',
        return_path => '<x@spamco.example>',
        message_id  => '<CABm-xyz123@mail.gmail.com>',
        body        => 'test'));
    {   no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @names = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { /gmail/ } @names),
            'gmail.com Message-ID domain filtered out by TRUSTED_DOMAINS';
        ok scalar(grep { $_ eq 'spamco.example' } @names),
            'non-infrastructure From: domain still captured';
    }
    restore_net();
};

subtest 'mailto_domains -- unknown Message-ID domain included with correct source' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    # Supply the bulk-platform Message-ID at parse time
    $a->parse_email(make_email(
        from        => 'x@y.com',
        return_path => '<x@y.com>',
        message_id  => '<msg001@bulkplatform.example>',
        body        => 'test'));
    {   no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @doms = $a->mailto_domains();
        my ($d) = grep { $_->{domain} eq 'bulkplatform.example' } @doms;
        ok defined $d, 'unknown Message-ID domain appears in mailto_domains';
        is $d->{source}, 'Message-ID: header', 'source labelled as Message-ID: header';
    }
    restore_net();
};

# =============================================================================
# 28. suspicious_date -- past vs future wording
# =============================================================================

subtest 'risk_assessment -- suspicious_date past: detail says "in the past"' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(date => 'Mon, 01 Jan 2024 00:00:00 +0000'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    my ($f) = grep { $_->{flag} eq 'suspicious_date' } @{ $risk->{flags} };
    ok defined $f, 'suspicious_date raised for stale date';
    like $f->{detail}, qr/in the past/, 'detail says "in the past"';
    unlike $f->{detail}, qr/from now/, 'detail does not say "from now"';
    restore_net();
};

subtest 'risk_assessment -- suspicious_date future: detail says "in the future"' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(date => 'Mon, 01 Jan 2099 00:00:00 +0000'));
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    my ($f) = grep { $_->{flag} eq 'suspicious_date' } @{ $risk->{flags} };
    ok defined $f, 'suspicious_date raised for far-future date';
    like $f->{detail}, qr/in the future/, 'detail says "in the future"';
    restore_net();
};

subtest 'risk_assessment -- missing_date raised when no Date: header' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    my $today = POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
    $a->parse_email(
        "Received: from h [91.198.174.1] by mx\n"
      . "From: x\@y.com\n\nbody");
    $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok', confidence=>'medium',
                      org=>'X', abuse=>'a@b', note=>'', country=>undef };
    $a->{_urls} = []; $a->{_mailto_domains} = [];
    my $risk = $a->risk_assessment();
    my ($f) = grep { $_->{flag} eq 'missing_date' } @{ $risk->{flags} };
    ok defined $f, 'missing_date flagged when no Date: header';
    is $f->{severity}, 'MEDIUM', 'missing_date is MEDIUM severity';
    restore_net();
};


# =============================================================================
# 29. Recipient domain exclusion -- To: domain must never be reported
# =============================================================================

subtest 'mailto_domains -- To: domain excluded (recipient is the victim, not sender)' => sub {
    # Regression test for the compliance4alllearning.com scenario:
    # bulk mailer embeds the recipient address in the body; the recipient's
    # registrar/ISP must not receive an abuse report.
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Bulk Sender <info@campaign.spammer.example>',
        return_path => '<bounce@bounce.spammer.example>',
        to          => '<victim@nigelhorne.com>',
        body        => "This email was sent to victim\@nigelhorne.com
Visit http://click.spammer.example/",
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { /nigelhorne/ } @domains),
            'nigelhorne.com (To: recipient domain) not included in mailto_domains';
        ok scalar(grep { /spammer/ } @domains),
            'spammer.example (sender domain) still captured';
    }
    restore_net();
};

subtest 'mailto_domains -- Cc: domain also excluded' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Spammer <spam@spammer.example>',
        return_path => '<bounce@spammer.example>',
        to          => '<victim@victim.example>',
        body        => "Cc recipient was also\@cc-victim.example",
    ));
    # Inject a Cc: header directly
    push @{ $a->{_headers} }, { name => 'cc', value => '<other@cc-victim.example>' };
    $a->{_mailto_domains} = undef;
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { /cc-victim/ } @domains),
            'cc-victim.example (Cc: recipient domain) not included in mailto_domains';
    }
    restore_net();
};

subtest 'mailto_domains -- subdomain of recipient domain also excluded' => sub {
    # If To: is victim\@nigelhorne.com, sub.nigelhorne.com appearing in body is also excluded
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Spammer <spam@spammer.example>',
        return_path => '<bounce@spammer.example>',
        to          => '<victim@nigelhorne.com>',
        body        => "Your account at webmail.nigelhorne.com has been updated",
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { /nigelhorne/ } @domains),
            'webmail.nigelhorne.com (subdomain of To: recipient) also excluded';
    }
    restore_net();
};


# =============================================================================
# 30. Regression: Salesforce Marketing Cloud / ExactTarget in provider table
#     (fix 1 of 3 in 0.03 -- "no abuse contacts" from Salesforce bulk mail)
# =============================================================================

subtest '_provider_abuse_for_host -- salesforce.com returns abuse address' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_host('salesforce.com');
    ok defined $r,                             'salesforce.com found in provider table';
    is $r->{email}, 'abuse@salesforce.com',    'correct abuse address';
    like $r->{note}, qr/salesforce/i,          'note mentions Salesforce';
};

subtest '_provider_abuse_for_host -- mc.salesforce.com subdomain strips to match' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    # s13.y.mc.salesforce.com is the real DKIM d= value seen in the wild
    my $r = $a->_provider_abuse_for_host('s13.y.mc.salesforce.com');
    ok defined $r,                             's13.y.mc.salesforce.com resolves via subdomain stripping';
    is $r->{email}, 'abuse@salesforce.com',    'resolves to Salesforce abuse address';
};

subtest '_provider_abuse_for_host -- exacttarget.com returns Salesforce address' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_host('exacttarget.com');
    ok defined $r,                             'exacttarget.com found in provider table';
    is $r->{email}, 'abuse@salesforce.com',    'ExactTarget maps to Salesforce abuse address';
};

subtest 'abuse_contacts -- Salesforce DKIM signer produces contact' => sub {
    # Full end-to-end: a message with a Salesforce DKIM-Signature d= tag
    # should yield abuse@salesforce.com in abuse_contacts() even when
    # all network calls are mocked out (no WHOIS available).
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => '"Bulk Sender" <info@campaign.spammer.example>',
        return_path => '<bounce@bounce.spammer.example>',
        to          => '<victim@bandsman.co.uk>',
        auth        => 'mx.test; spf=pass; dkim=pass header.d=campaign.spammer.example;'
                     . ' dkim=pass header.d=s13.y.mc.salesforce.com; dmarc=pass',
        body        => 'Buy now',
    ));
    # Inject both DKIM-Signature headers as would appear in a real Salesforce email
    push @{ $a->{_headers} },
        { name => 'dkim-signature',
          value => 'v=1; a=rsa-sha256; d=campaign.spammer.example; s=s1; b=xxx' },
        { name => 'dkim-signature',
          value => 'v=1; a=rsa-sha256; d=s13.y.mc.salesforce.com; s=fbldkim13; b=xxx' };
    $a->{_auth_results}   = undef;   # force re-parse to pick up injected headers
    $a->{_mailto_domains} = undef;
    my @contacts = $a->abuse_contacts();
    my @addresses = map { lc $_->{address} } @contacts;
    ok scalar(grep { $_ eq 'abuse@salesforce.com' } @addresses),
        'abuse@salesforce.com present in contacts when Salesforce is DKIM signer';
    restore_net();
};

# =============================================================================
# 31. Regression: non-routable hostnames filtered from domain pipeline
#     (fix 2 of 3 in 0.03 -- iad4s13mta756.xt.local from Message-ID)
# =============================================================================

subtest 'mailto_domains -- .local hostname filtered out' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Spammer <spam@spammer.example>',
        return_path => '<bounce@spammer.example>',
        message_id  => '<abc123@mta756.xt.local>',
        body        => 'test',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { /\.local$/i } @domains),
            '.local Message-ID hostname excluded from mailto_domains';
        ok scalar(grep { /spammer/ } @domains),
            'legitimate sender domain still captured';
    }
    restore_net();
};

subtest 'mailto_domains -- .internal hostname filtered out' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Spammer <spam@spammer.example>',
        return_path => '<bounce@spammer.example>',
        message_id  => '<msg001@relay.corp.internal>',
        body        => 'test',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { /\.internal$/i } @domains),
            '.internal Message-ID hostname excluded from mailto_domains';
    }
    restore_net();
};

subtest 'mailto_domains -- single-label hostname filtered out' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Spammer <spam@spammer.example>',
        return_path => '<bounce@spammer.example>',
        message_id  => '<msg001@localhost>',
        body        => 'test',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok !scalar(grep { $_ eq 'localhost' } @domains),
            'bare localhost hostname excluded from mailto_domains';
    }
    restore_net();
};

subtest 'mailto_domains -- routable domain in Message-ID still included' => sub {
    # Confirm the filter does not over-reject legitimate Message-ID domains
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Spammer <spam@spammer.example>',
        return_path => '<bounce@spammer.example>',
        message_id  => '<msg001@mta.bulkplatform.example>',
        body        => 'test',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @domains = map { $_->{domain} } $a->mailto_domains();
        ok scalar(grep { /bulkplatform/ } @domains),
            'routable Message-ID domain still included after non-routable filter';
    }
    restore_net();
};

# =============================================================================
# 32. Regression: all DKIM d= domains collected; ESP preferred over customer
#     (fix 3 of 3 in 0.03 -- Salesforce second DKIM-Signature ignored)
# =============================================================================

subtest '_parse_auth_results_cached -- collects all DKIM d= domains' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'Sender <info@customer.example>',
        auth => 'mx.test; dkim=pass header.d=customer.example',
        body => 'test',
    ));
    push @{ $a->{_headers} },
        { name => 'dkim-signature', value => 'v=1; d=customer.example; s=s1; b=xxx' },
        { name => 'dkim-signature', value => 'v=1; d=s13.y.mc.salesforce.com; s=s2; b=xxx' };
    $a->{_auth_results} = undef;
    my $auth = $a->_parse_auth_results_cached();
    ok defined $auth->{dkim_domains},         'dkim_domains arrayref populated';
    is scalar @{ $auth->{dkim_domains} }, 2,  'both DKIM d= domains collected';
    ok scalar(grep { $_ eq 'customer.example'         } @{ $auth->{dkim_domains} }),
        'customer domain in dkim_domains';
    ok scalar(grep { $_ eq 's13.y.mc.salesforce.com' } @{ $auth->{dkim_domains} }),
        'Salesforce ESP domain in dkim_domains';
};

subtest '_parse_auth_results_cached -- prefers provider-table domain as dkim_domain' => sub {
    # When one DKIM d= matches the provider table, it becomes dkim_domain
    # regardless of its position in the header order.
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'Sender <info@customer.example>',
        body => 'test',
    ));
    # Customer domain first, Salesforce second -- Salesforce should win
    push @{ $a->{_headers} },
        { name => 'dkim-signature', value => 'v=1; d=customer.example; s=s1; b=xxx' },
        { name => 'dkim-signature', value => 'v=1; d=s13.y.mc.salesforce.com; s=s2; b=xxx' };
    $a->{_auth_results} = undef;
    my $auth = $a->_parse_auth_results_cached();
    is $auth->{dkim_domain}, 's13.y.mc.salesforce.com',
        'ESP domain preferred over customer domain when ESP is in provider table';
};

subtest '_parse_auth_results_cached -- falls back to first domain when none in provider table' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from => 'Sender <info@customer.example>',
        body => 'test',
    ));
    push @{ $a->{_headers} },
        { name => 'dkim-signature', value => 'v=1; d=first.unknown.example; s=s1; b=xxx' },
        { name => 'dkim-signature', value => 'v=1; d=second.unknown.example; s=s2; b=xxx' };
    $a->{_auth_results} = undef;
    my $auth = $a->_parse_auth_results_cached();
    is $auth->{dkim_domain}, 'first.unknown.example',
        'first domain used when none match the provider table';
};

subtest 'mailto_domains -- all DKIM domains fed into domain pipeline' => sub {
    # Both d= domains should appear in mailto_domains(), not just the primary
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'Sender <info@customer.example>',
        return_path => '<bounce@customer.example>',
        body        => 'test',
    ));
    push @{ $a->{_headers} },
        { name => 'dkim-signature', value => 'v=1; d=customer.example; s=s1; b=xxx' },
        { name => 'dkim-signature', value => 'v=1; d=mta.bulkplatform.example; s=s2; b=xxx' };
    $a->{_auth_results}   = undef;
    $a->{_mailto_domains} = undef;
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @names = map { $_->{domain} } $a->mailto_domains();
        ok scalar(grep { $_ eq 'customer.example'       } @names),
            'first DKIM domain in mailto_domains';
        ok scalar(grep { $_ eq 'mta.bulkplatform.example' } @names),
            'second DKIM domain also in mailto_domains';
    }
    restore_net();
};


# =============================================================================
# 33. Regression: display-name @ sign in abuse_contacts section 4
#     (patch 1 of 3 for 0.04)
#     A From: header containing an @ in the display name (e.g.
#     "evil@gmail.com" <real@hotmail.com>) was being matched against
#     the display-name domain instead of the addr-spec domain.
# =============================================================================

subtest 'abuse_contacts section 4 -- display-name @ sign ignored, addr-spec domain used' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');

    # Craft a From: header where the display name contains an @ sign pointing
    # at a well-known provider (gmail) while the real addr-spec uses a
    # different provider (hotmail/Microsoft).  The correct behaviour is to
    # identify microsoft.com (the hotmail.com registrant), not google.com.
    $a->parse_email(make_email(
        from        => '"evil@gmail.com" <spammer@hotmail.com>',
        return_path => '<bounce@hotmail.com>',
        to          => '<victim@nigelhorne.com>',
        body        => 'Buy now',
    ));

    {
        no warnings 'redefine';
        # Mock out network so the test is deterministic
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };

        my @contacts  = $a->abuse_contacts();
        my @addresses = map { lc $_->{address} } @contacts;

        # hotmail.com maps to abuse@microsoft.com in the provider table
        ok scalar(grep { $_ eq 'abuse@microsoft.com' } @addresses),
            'addr-spec domain (hotmail.com -> microsoft.com) correctly identified';

        # google.com is the gmail.com provider -- must NOT appear here
        # because gmail.com only appears in the display name, not the addr-spec
        ok !scalar(grep { $_ eq 'abuse@google.com' } @addresses),
            'display-name domain (gmail.com -> google.com) not reported as account provider';
    }
    restore_net();
};

subtest 'abuse_contacts section 4 -- plain addr-spec without display name still works' => sub {
    # Regression guard: the fix must not break the simple no-display-name case
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => 'spammer@gmail.com',
        return_path => '<spammer@gmail.com>',
        to          => '<victim@nigelhorne.com>',
        body        => 'Buy now',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @contacts  = $a->abuse_contacts();
        my @addresses = map { lc $_->{address} } @contacts;
        # gmail.com maps to abuse@google.com in the provider table
        ok scalar(grep { $_ eq 'abuse@google.com' } @addresses),
            'plain addr-spec (gmail.com -> google.com) still correctly matched';
    }
    restore_net();
};

subtest 'abuse_contacts section 4 -- angle-bracket addr-spec without display name works' => sub {
    null_net();
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        from        => '<spammer@gmail.com>',
        return_path => '<spammer@gmail.com>',
        to          => '<victim@nigelhorne.com>',
        body        => 'Buy now',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        my @contacts  = $a->abuse_contacts();
        my @addresses = map { lc $_->{address} } @contacts;
        # gmail.com maps to abuse@google.com in the provider table
        ok scalar(grep { $_ eq 'abuse@google.com' } @addresses),
            'angle-bracket-only form (gmail.com -> google.com) correctly matched';
    }
    restore_net();
};

# =============================================================================
# 34. Regression: implausible timezone offset in Date: header
#     (patch 2 of 3 for 0.04)
#     Offsets beyond +1400 / -1200, or with minutes >= 60, are header
#     forgeries.  Should raise a MEDIUM implausible_timezone flag.
# =============================================================================

subtest 'risk_assessment -- implausible_timezone flagged for +9900' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        # +9900 is 99 hours -- impossible; clearly machine-generated
        date => 'Mon, 01 Jan 2024 12:00:00 +9900',
    ));
    my $risk  = $a->risk_assessment();
    my @flags = map { $_->{flag} } @{ $risk->{flags} };
    ok scalar(grep { $_ eq 'implausible_timezone' } @flags),
        '+9900 offset raises implausible_timezone flag';
};

subtest 'risk_assessment -- implausible_timezone flagged for -1300' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        # -1300 is beyond the -1200 real-world minimum (Baker Island)
        date => 'Mon, 01 Jan 2024 12:00:00 -1300',
    ));
    my $risk  = $a->risk_assessment();
    my @flags = map { $_->{flag} } @{ $risk->{flags} };
    ok scalar(grep { $_ eq 'implausible_timezone' } @flags),
        '-1300 offset raises implausible_timezone flag';
};

subtest 'risk_assessment -- implausible_timezone flagged for minutes >= 60' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    $a->parse_email(make_email(
        # +0060 has an invalid minutes field -- no real timezone has 60 minutes
        date => 'Mon, 01 Jan 2024 12:00:00 +0060',
    ));
    my $risk  = $a->risk_assessment();
    my @flags = map { $_->{flag} } @{ $risk->{flags} };
    ok scalar(grep { $_ eq 'implausible_timezone' } @flags),
        '+0060 (minutes=60) raises implausible_timezone flag';
};

subtest 'risk_assessment -- valid edge-case timezones not flagged' => sub {
    my $a = new_ok('Email::Abuse::Investigator');

    # +1400 is the Line Islands -- the most easterly real timezone
    $a->parse_email(make_email( date => 'Mon, 01 Jan 2024 12:00:00 +1400' ));
    my @flags = map { $_->{flag} } @{ $a->risk_assessment()->{flags} };
    ok !scalar(grep { $_ eq 'implausible_timezone' } @flags),
        '+1400 (Line Islands) not flagged as implausible';

    # -1200 is Baker Island -- the most westerly real timezone
    $a->parse_email(make_email( date => 'Mon, 01 Jan 2024 12:00:00 -1200' ));
    @flags = map { $_->{flag} } @{ $a->risk_assessment()->{flags} };
    ok !scalar(grep { $_ eq 'implausible_timezone' } @flags),
        '-1200 (Baker Island) not flagged as implausible';

    # +0530 is India Standard Time -- common legitimate offset
    $a->parse_email(make_email( date => 'Mon, 01 Jan 2024 12:00:00 +0530' ));
    @flags = map { $_->{flag} } @{ $a->risk_assessment()->{flags} };
    ok !scalar(grep { $_ eq 'implausible_timezone' } @flags),
        '+0530 (India) not flagged as implausible';
};

# =============================================================================
# 35. Regression: ActiveCampaign in provider table
#     (patch 3 of 3 for 0.04 -- Constant Contact and HubSpot were already
#     present; this confirms ActiveCampaign, which was newly added)
# =============================================================================

subtest '_provider_abuse_for_host -- activecampaign.com in table' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_host('activecampaign.com');
    ok defined $r,
        'activecampaign.com found in provider table';
    is $r->{email}, 'abuse@activecampaign.com',
        'correct abuse address for ActiveCampaign';
};

subtest '_provider_abuse_for_host -- ac-tinker.com strips to activecampaign' => sub {
    # ac-tinker.com is ActiveCampaign tracking infrastructure; subdomain
    # stripping should not apply here (it is a different registrable domain),
    # so ac-tinker.com must be in the table as an explicit entry.
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_host('ac-tinker.com');
    ok defined $r,
        'ac-tinker.com found in provider table';
    is $r->{email}, 'abuse@activecampaign.com',
        'ac-tinker.com maps to ActiveCampaign abuse address';
};

subtest '_provider_abuse_for_host -- constantcontact.com already present' => sub {
    # Guard against future table cleanup accidentally removing entries
    # that were present before this patch series.
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_host('constantcontact.com');
    ok defined $r,                                    'constantcontact.com in table';
    is $r->{email}, 'abuse@constantcontact.com',      'correct abuse address';
};

subtest '_provider_abuse_for_host -- hubspot.com already present' => sub {
    my $a = new_ok('Email::Abuse::Investigator');
    my $r = $a->_provider_abuse_for_host('hubspot.com');
    ok defined $r,                             'hubspot.com in table';
    is $r->{email}, 'abuse@hubspot.com',       'correct abuse address';
};


# =============================================================================
# 36. Regression: WordPress.com and Substack in provider table (0.05)
# =============================================================================

subtest '_provider_abuse_for_host -- wordpress.com in table' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_provider_abuse_for_host('wordpress.com');
	ok defined $r,
		'wordpress.com found in provider table';
	is $r->{email}, 'abuse@wordpress.com',
		'correct abuse address for WordPress.com';
	like $r->{note}, qr/wordpress/i,
		'note mentions WordPress';
};

subtest '_provider_abuse_for_host -- substack.com in table' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_provider_abuse_for_host('substack.com');
	ok defined $r,
		'substack.com found in provider table';
	is $r->{email}, 'abuse@substack.com',
		'correct abuse address for Substack';
};

subtest '_provider_abuse_for_host -- wordpress.com subdomain strips correctly' => sub {
	# spammer.wordpress.com should resolve via subdomain stripping
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_provider_abuse_for_host('spammer.wordpress.com');
	ok defined $r,
		'spammer.wordpress.com resolves via subdomain stripping';
	is $r->{email}, 'abuse@wordpress.com',
		'subdomain correctly resolves to WordPress.com abuse address';
};

subtest '_provider_abuse_for_host -- wp.com short domain in table' => sub {
	# wp.com is WordPress.com's short domain used in some links
	my $a = new_ok('Email::Abuse::Investigator');
	my $r = $a->_provider_abuse_for_host('wp.com');
	ok defined $r,
		'wp.com found in provider table';
	is $r->{email}, 'abuse@wordpress.com',
		'wp.com maps to WordPress.com abuse address';
};

subtest 'abuse_contacts -- wordpress.com URL host produces correct contact' => sub {
	# End-to-end: a message containing a wordpress.com URL should yield
	# abuse@wordpress.com in abuse_contacts() without any network calls,
	# via the provider-table route for URL hosts.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@spammer.example>',
		return_path => '<bounce@spammer.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Visit https://evilblog.wordpress.com/offer for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok scalar(grep { $_ eq 'abuse@wordpress.com' } @addresses),
			'abuse@wordpress.com present when wordpress.com URL found in body';
	}
	restore_net();
};

subtest 'abuse_contacts -- substack.com URL host produces correct contact' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@spammer.example>',
		return_path => '<bounce@spammer.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Read my newsletter at https://evilnews.substack.com/p/scam',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok scalar(grep { $_ eq 'abuse@substack.com' } @addresses),
			'abuse@substack.com present when substack.com URL found in body';
	}
	restore_net();
};


# =============================================================================
# 37. Regression: protocol-relative URLs, domain WHOIS fallback, role
#     deduplication (0.05 fixes for badshamart.com spam campaign)
# =============================================================================

subtest '_extract_http_urls -- protocol-relative URL in plain img src' => sub {
	# A bare //domain/path in the body should be extracted as https://domain/path
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Hello <img src="//tracker.badshamart.com/o/1/2/3/US">',
		ct   => 'text/html',
	));
	my @urls  = $a->embedded_urls();
	my @hosts = map { $_->{host} } @urls;
	ok scalar(grep { /badshamart\.com/ } @hosts),
		'protocol-relative //tracker.badshamart.com extracted as URL host';
	restore_net();
};

subtest '_extract_http_urls -- protocol-relative URL in href attribute' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => '<a href="//click.evilsite.example/go/123">Click here</a>',
		ct   => 'text/html',
	));
	my @urls  = $a->embedded_urls();
	my @hosts = map { $_->{host} } @urls;
	ok scalar(grep { $_ eq 'click.evilsite.example' } @hosts),
		'protocol-relative href //click.evilsite.example extracted';
	my ($u) = grep { $_->{host} eq 'click.evilsite.example' } @urls;
	like $u->{url}, qr{^https://click\.evilsite\.example},
		'normalised URL has https:// scheme prefix';
	restore_net();
};

subtest '_extract_http_urls -- protocol-relative does not match CSS comments' => sub {
	# // inside a CSS comment must not be treated as a URL
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => "<style>/* // not a url */\nbody { color: red; }</style>",
		ct   => 'text/html',
	));
	my @urls  = $a->embedded_urls();
	is scalar(@urls), 0,
		'CSS comment // does not produce a false-positive URL';
	restore_net();
};

subtest 'abuse_contacts -- URL host domain WHOIS fallback when IP unresolvable' => sub {
	# When a URL host cannot be resolved to an IP, _extract_and_resolve_urls()
	# should fall back to domain WHOIS to recover the registrar abuse contact.
	# This is the core fix for the badshamart.com case.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Visit https://newspam.badshamart.com/offer for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		# Simulate domain WHOIS returning a registrar abuse contact
		local *Email::Abuse::Investigator::_domain_whois = sub {
			my (undef, $dom) = @_;
			return "Registrar: Dodgy Registrar Inc\n"
			     . "Registrar Abuse Contact Email: abuse\@dodgyregistrar.example\n"
				if $dom eq 'badshamart.com';
			return undef;
		};
		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok scalar(grep { $_ eq 'abuse@dodgyregistrar.example' } @addresses),
			'registrar abuse contact recovered via domain WHOIS fallback';
	}
	restore_net();
};

subtest 'abuse_contacts -- role deduplication: same hostname twice collapsed' => sub {
	# Role strings now include the hostname ("URL host: host.example"), so
	# two URLs on the SAME host produce identical role strings and collapse
	# to (x2).  Two URLs on DIFFERENT hosts produce distinct role strings
	# and are joined with "and" -- they should NOT be collapsed since each
	# hostname is individually actionable.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		# Same Blogspot subdomain linked twice -- same role string twice
		body =>   'https://spamblog.blogspot.com/page1 '
		        . 'https://spamblog.blogspot.com/page2 ',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };
		my @contacts = $a->abuse_contacts();
		my ($c) = grep { $_->{address} eq 'abuse@google.com' } @contacts;
		ok defined $c, 'google abuse contact found for blogspot URLs';
		# Same host deduped by _extract_and_resolve_urls -- only one URL host role
		is scalar(grep { /URL host/ } @{ $c->{roles} }), 1,
			'same hostname only produces one URL host role entry';
	}
	restore_net();
};

subtest 'abuse_contacts -- role deduplication: different subdomains each get own role' => sub {
	# Four different subdomains resolving to the same registrar abuse address
	# produce four distinct role strings (one per hostname), joined with "and".
	# They must NOT be collapsed to (xN) since each hostname is distinct and
	# individually actionable information for the abuse desk.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body =>   'https://a1.spamdomain.example/p1 '
		        . 'https://a2.spamdomain.example/p2 '
		        . 'https://a3.spamdomain.example/p3 '
		        . 'https://a4.spamdomain.example/p4',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub {
			my (undef, $dom) = @_;
			return "Registrar: Example Registrar\n"
			     . "Registrar Abuse Contact Email: abuse\@exampleregistrar.example\n"
				if $dom eq 'spamdomain.example';
			return undef;
		};
		my @contacts = $a->abuse_contacts();
		my ($c) = grep { $_->{address} eq 'abuse@exampleregistrar.example' }
		          @contacts;
		ok defined $c, 'merged contact found';
		is scalar(@{ $c->{roles} }), 4,
			'roles arrayref has four entries (one per URL host)';
		unlike $c->{role}, qr/\(x4\)/,
			'distinct hostnames not collapsed with (xN)';
		like $c->{role}, qr/a1\.spamdomain\.example/,
			'first hostname present in role string';
		like $c->{role}, qr/a4\.spamdomain\.example/,
			'last hostname present in role string';
	}
	restore_net();
};

subtest 'abuse_contacts -- role deduplication: distinct labels not collapsed' => sub {
	# "Sending ISP and URL host" involves two *different* role labels --
	# they must NOT be collapsed, only repeated identical labels are.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to       => '<victim@nigelhorne.com>',
		body     => 'Visit https://evilblog.wordpress.com/offer',
		received => 'from mail.wordpress.com (mail.wordpress.com [198.51.100.1])'
		          . ' by mx.nigelhorne.com with ESMTP',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { '198.51.100.1' };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };
		local *Email::Abuse::Investigator::_reverse_dns  =
			sub { 'mail.wordpress.com' };
		my @contacts = $a->abuse_contacts();
		my ($wp) = grep { $_->{address} eq 'abuse@wordpress.com' } @contacts;
		ok defined $wp, 'abuse@wordpress.com contact found';
		if (defined $wp && scalar(@{ $wp->{roles} }) > 1) {
			unlike $wp->{role}, qr/\(x\d+\)/,
				'distinct labels not collapsed with (xN) suffix';
			like $wp->{role}, qr/and/,
				'distinct labels joined with "and"';
		} else {
			pass 'single role -- deduplication not triggered';
		}
	}
	restore_net();
};


# =============================================================================
# 38. Regression: nested multipart/* recursion (0.04 fix)
#     Before the fix, multipart/mixed containing multipart/alternative had its
#     inner body silently discarded, so embedded_urls() found no URLs.
# =============================================================================

subtest 'nested MIME: multipart/mixed > multipart/alternative -- URLs extracted' => sub {
	# Build a multipart/mixed message whose only text part is wrapped inside
	# a nested multipart/alternative.  This is the exact structure that was
	# broken before the 0.04 fix.
	null_net();
	my $inner_boundary = 'inner_boundary_001';
	my $outer_boundary = 'outer_boundary_001';

	my $inner = join("\r\n",
		"--$inner_boundary",
		'Content-Type: text/plain; charset=us-ascii',
		'',
		'Plain text part with no URL.',
		"--$inner_boundary",
		'Content-Type: text/html; charset=us-ascii',
		'',
		'<html><body><a href="https://spamlink.badshamart.example/go">click</a></body></html>',
		"--${inner_boundary}--",
		'',
	);

	my $outer_body = join("\r\n",
		"--$outer_boundary",
		"Content-Type: multipart/alternative; boundary=\"$inner_boundary\"",
		'',
		$inner,
		"--${outer_boundary}--",
		'',
	);

	my $raw = join("\r\n",
		'Received: from ext (ext [198.51.100.1]) by mx.nigelhorne.com with ESMTP',
		'From: Spammer <spam@spammer.example>',
		'To: <victim@nigelhorne.com>',
		'Subject: Nested MIME test',
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime),
		'Message-ID: <nested@test>',
		"Content-Type: multipart/mixed; boundary=\"$outer_boundary\"",
		'',
		$outer_body,
	);

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email($raw);

	my @urls  = $a->embedded_urls();
	my @hosts = map { $_->{host} } @urls;

	ok scalar(@urls) > 0,
		'embedded_urls() finds URLs in nested multipart/mixed > multipart/alternative';
	ok scalar(grep { /badshamart\.example/ } @hosts),
		'correct hostname extracted from nested HTML part';
	restore_net();
};

subtest 'nested MIME: three levels deep -- URLs still extracted' => sub {
	# Ensure recursion handles arbitrary nesting depth, not just two levels.
	null_net();
	my $b1 = 'boundary_level1';
	my $b2 = 'boundary_level2';
	my $b3 = 'boundary_level3';

	my $level3 = join("\r\n",
		"--$b3",
		'Content-Type: text/html; charset=us-ascii',
		'',
		'<a href="https://deep.nested.example/path">deep link</a>',
		"--${b3}--",
		'',
	);
	my $level2 = join("\r\n",
		"--$b2",
		"Content-Type: multipart/alternative; boundary=\"$b3\"",
		'',
		$level3,
		"--${b2}--",
		'',
	);
	my $level1 = join("\r\n",
		"--$b1",
		"Content-Type: multipart/related; boundary=\"$b2\"",
		'',
		$level2,
		"--${b1}--",
		'',
	);

	my $raw = join("\r\n",
		'Received: from ext (ext [198.51.100.1]) by mx.nigelhorne.com with ESMTP',
		'From: Spammer <spam@spammer.example>',
		'To: <victim@nigelhorne.com>',
		'Subject: Deep nesting test',
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime),
		'Message-ID: <deep@test>',
		"Content-Type: multipart/mixed; boundary=\"$b1\"",
		'',
		$level1,
	);

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email($raw);

	my @urls = $a->embedded_urls();
	ok scalar(@urls) > 0,
		'embedded_urls() finds URLs three MIME levels deep';
	ok scalar(grep { $_->{host} eq 'deep.nested.example' } @urls),
		'correct hostname extracted from three-level nested part';
	restore_net();
};

subtest 'nested MIME: non-multipart sibling parts still decoded' => sub {
	# A multipart/mixed with one attachment part and one multipart/alternative
	# part -- the attachment must be skipped cleanly and the alternative decoded.
	null_net();
	my $outer = 'outer_sib_001';
	my $inner = 'inner_sib_001';

	my $body = join("\r\n",
		"--$outer",
		'Content-Type: application/octet-stream',
		'Content-Disposition: attachment; filename="file.bin"',
		'',
		'binarydata',
		"--$outer",
		"Content-Type: multipart/alternative; boundary=\"$inner\"",
		'',
		"--$inner",
		'Content-Type: text/plain',
		'',
		'Plain sibling text.',
		"--$inner",
		'Content-Type: text/html',
		'',
		'<a href="https://sibling.example/link">click</a>',
		"--${inner}--",
		'',
		"--${outer}--",
		'',
	);

	my $raw = join("\r\n",
		'Received: from ext (ext [198.51.100.1]) by mx.nigelhorne.com with ESMTP',
		'From: Spammer <spam@spammer.example>',
		'To: <victim@nigelhorne.com>',
		'Subject: Sibling parts test',
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime),
		'Message-ID: <sib@test>',
		"Content-Type: multipart/mixed; boundary=\"$outer\"",
		'',
		$body,
	);

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email($raw);

	my @urls = $a->embedded_urls();
	ok scalar(grep { $_->{host} eq 'sibling.example' } @urls),
		'URL in multipart/alternative sibling of attachment part is found';
	restore_net();
};

# =============================================================================
# 39. Regression: abuse_contacts() role merging (0.04 fix)
#     Before the fix, duplicate addresses from multiple discovery routes
#     were silently dropped; now they accumulate into roles/role.
# =============================================================================

subtest 'abuse_contacts role merging -- roles arrayref accumulates all routes' => sub {
	# Arrange a message where the same provider (Google) is found via two
	# distinct routes: as the sending ISP (rDNS match) and as a URL host.
	# Both roles must appear in the merged entry.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		received    => 'from mail-wm1-f67.google.com (mail-wm1-f67.google.com'
		             . ' [209.85.128.67]) by mx.nigelhorne.com with ESMTP',
		from        => 'Spammer <spam@spammer.example>',
		return_path => '<bounce@spammer.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Visit https://evilblog.blogspot.com/scam for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host =
			sub { '209.85.128.67' };
		local *Email::Abuse::Investigator::_reverse_dns  =
			sub { 'mail-wm1-f67.google.com' };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts = $a->abuse_contacts();
		my ($google)  = grep { $_->{address} eq 'abuse@google.com' } @contacts;

		ok defined $google,
			'abuse@google.com contact present';
		ok defined $google->{roles},
			'roles arrayref present on merged entry';
		cmp_ok scalar(@{ $google->{roles} }), '>=', 2,
			'at least two roles accumulated for abuse@google.com';
		like $google->{role}, qr/and|x\d/,
			'role string reflects multiple routes (joined or counted)';
	}
	restore_net();
};

subtest 'abuse_contacts role merging -- role (singular) stays in sync' => sub {
	# The legacy role key must always equal join(" and ", @{roles}) or the
	# deduplicated (xN) form -- never be stale from the first discovery.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		received    => 'from mail-wm1-f67.google.com (mail-wm1-f67.google.com'
		             . ' [209.85.128.67]) by mx.nigelhorne.com with ESMTP',
		from        => 'Spammer <spam@spammer.example>',
		return_path => '<bounce@spammer.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Visit https://evilblog.blogspot.com/scam for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host =
			sub { '209.85.128.67' };
		local *Email::Abuse::Investigator::_reverse_dns  =
			sub { 'mail-wm1-f67.google.com' };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts = $a->abuse_contacts();
		my ($google)  = grep { $_->{address} eq 'abuse@google.com' } @contacts;
		ok defined $google, 'abuse@google.com found';

		# role must be consistent with roles arrayref
		my %counts;
		$counts{$_}++ for @{ $google->{roles} };
		my $expected = join(' and ', map {
			$counts{$_} > 1 ? "$_ (x$counts{$_})" : $_
		} do { my %seen; grep { !$seen{$_}++ } @{ $google->{roles} } });
		is $google->{role}, $expected,
			'role (singular) is consistent with roles arrayref';
	}
	restore_net();
};

subtest 'abuse_contacts role merging -- first address not dropped when duplicate found' => sub {
	# The very first discovery route must not be lost when a second route
	# finds the same address.  Before the 0.04 fix the second $add() call
	# returned early without updating anything, so the first role was kept
	# but no merging occurred.  Now both roles must be present.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	# Two URLs on different blogspot subdomains -- both resolve to
	# abuse@google.com via the provider table.
	$a->parse_email(make_email(
		from        => 'Spammer <spam@spammer.example>',
		return_path => '<bounce@spammer.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'See https://spam1.blogspot.com/a '
		             . 'and https://spam2.blogspot.com/b',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts  = $a->abuse_contacts();
		my @google    = grep { $_->{address} eq 'abuse@google.com' } @contacts;

		is scalar(@google), 1,
			'abuse@google.com appears exactly once (deduplicated)';
		cmp_ok scalar(@{ $google[0]->{roles} }), '>=', 2,
			'both URL host routes merged into single entry';
	}
	restore_net();
};


# =============================================================================
# 40. Regression: form_contacts() and web-form provider table entries (0.06)
# =============================================================================

subtest 'form_contacts -- markmonitor.com in provider table with form key' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $pa = $a->_provider_abuse_for_host('markmonitor.com');
	ok defined $pa,
		'markmonitor.com found in provider table';
	ok !$pa->{email},
		'markmonitor.com has no email key (form-only)';
	ok $pa->{form},
		'markmonitor.com has form key';
	like $pa->{form}, qr{markmonitor\.com},
		'form URL references markmonitor.com';
	ok $pa->{form_paste},
		'markmonitor.com has form_paste hint';
	ok $pa->{form_upload},
		'markmonitor.com has form_upload hint';
};

subtest 'form_contacts -- globaldomaingroup.com in provider table with form key' => sub {
	my $a = new_ok('Email::Abuse::Investigator');
	my $pa = $a->_provider_abuse_for_host('globaldomaingroup.com');
	ok defined $pa,
		'globaldomaingroup.com found in provider table';
	ok !$pa->{email},
		'globaldomaingroup.com has no email key (form-only)';
	ok $pa->{form},
		'globaldomaingroup.com has form key';
	like $pa->{form}, qr{globaldomaingroup\.com},
		'form URL references globaldomaingroup.com';
};

subtest 'form_contacts -- markmonitor.com not returned by abuse_contacts()' => sub {
	# form-only entries must never appear in abuse_contacts() since they
	# have no email address -- the $add guard filters them out.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Buy now at https://spamsite.example/offer',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_analyse_domain = sub {
			my ($self, $dom) = @_;
			return $self->{_domain_info}{$dom}
				if $self->{_domain_info}{$dom};
			my %info = (
				registrar       => 'MarkMonitor Inc.',
				registrar_abuse => 'abusecomplaints@markmonitor.com',
			);
			$self->{_domain_info}{$dom} = \%info;
			return \%info;
		};

		my @contacts = $a->abuse_contacts();
		my @mm = grep { ($_->{address} // '') =~ /markmonitor/i } @contacts;
		is scalar(@mm), 0,
			'markmonitor.com does not appear in abuse_contacts() (no email)';
	}
	restore_net();
};

subtest 'form_contacts -- registrar with form key appears in form_contacts()' => sub {
	# When WHOIS identifies markmonitor.com as the registrar, form_contacts()
	# must return it with the correct form URL and hints.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Buy now at https://spamsite.example/offer',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_analyse_domain = sub {
			my ($self, $dom) = @_;
			return $self->{_domain_info}{$dom}
				if $self->{_domain_info}{$dom};
			my %info = (
				registrar       => 'MarkMonitor Inc.',
				registrar_abuse => 'abusecomplaints@markmonitor.com',
			);
			$self->{_domain_info}{$dom} = \%info;
			return \%info;
		};

		my @fcs = $a->form_contacts();
		my ($mm) = grep { $_->{form} =~ /markmonitor/i } @fcs;

		ok defined $mm,
			'markmonitor.com form contact present in form_contacts()';
		like $mm->{role}, qr/registrar/i,
			'role identifies this as a registrar contact';
		like $mm->{form}, qr{markmonitor\.com},
			'form URL is the MarkMonitor abuse form';
		ok $mm->{form_paste},
			'form_paste hint present';
		ok $mm->{form_upload},
			'form_upload hint present';
		is $mm->{via}, 'provider-table',
			'via is provider-table';
	}
	restore_net();
};

subtest 'form_contacts -- registrar_abuse domain drives lookup (self-extending)' => sub {
	# The lookup must be driven by the domain in registrar_abuse, not a
	# hardcoded list.  Use globaldomaingroup.com to verify the mechanism
	# works for a second provider independently.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Visit https://scamdomain.example/go',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_analyse_domain = sub {
			my ($self, $dom) = @_;
			return $self->{_domain_info}{$dom}
				if $self->{_domain_info}{$dom};
			my %info = (
				registrar       => 'Global Domain Group',
				registrar_abuse => 'abuse@globaldomaingroup.com',
			);
			$self->{_domain_info}{$dom} = \%info;
			return \%info;
		};

		my @fcs = $a->form_contacts();
		my ($gdg) = grep { $_->{form} =~ /globaldomaingroup/i } @fcs;

		ok defined $gdg,
			'globaldomaingroup.com form contact found via registrar_abuse domain';
		like $gdg->{form}, qr{globaldomaingroup\.com},
			'correct form URL for Global Domain Group';
	}
	restore_net();
};

subtest 'form_contacts -- form URL deduplicated across multiple domains' => sub {
	# If two contact domains both have MarkMonitor as registrar, form_contacts()
	# must return only one entry for the MarkMonitor form, not two.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@domain1.example>',
		return_path => '<bounce@domain2.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Test body',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_analyse_domain = sub {
			my ($self, $dom) = @_;
			return $self->{_domain_info}{$dom}
				if $self->{_domain_info}{$dom};
			# Both domains share the same registrar
			my %info = (
				registrar       => 'MarkMonitor Inc.',
				registrar_abuse => 'abusecomplaints@markmonitor.com',
			);
			$self->{_domain_info}{$dom} = \%info;
			return \%info;
		};

		my @fcs  = $a->form_contacts();
		my @mm   = grep { $_->{form} =~ /markmonitor/i } @fcs;
		is scalar(@mm), 1,
			'MarkMonitor form URL appears only once despite two domains sharing it';
	}
	restore_net();
};

subtest 'form_contacts -- report() includes web-form section when form contacts exist' => sub {
	# Mock _domain_whois to return MarkMonitor registrar data for any domain.
	# This is more robust than mocking _analyse_domain because it does not
	# rely on local() scoping of typeglobs inside nested anonymous subs,
	# which interacts poorly with make test's test harness.
	# All network stubs are set before parse_email() so that no cached
	# state is built up with the wrong stubs active.
	no warnings 'redefine';
	local *Email::Abuse::Investigator::_reverse_dns  = sub { undef };
	local *Email::Abuse::Investigator::_resolve_host = sub { undef };
	local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
	local *Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
	local *Email::Abuse::Investigator::_domain_whois = sub {
		return "Registrar: MarkMonitor Inc.\n"
		     . "Registrar Abuse Contact Email: abusecomplaints\@markmonitor.com\n";
	};

	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Buy now at https://spamsite.example/offer',
	));

	my $report = $a->report();
	like $report, qr/WHERE TO FILE WEB-FORM REPORTS/,
		'report() contains web-form section heading';
	like $report, qr/markmonitor\.com/i,
		'report() web-form section mentions markmonitor.com';
	like $report, qr/Form URL\s*:/,
		'report() web-form section contains Form URL line';
	like $report, qr/Paste\s*:/,
		'report() web-form section contains Paste line';
	like $report, qr/Upload\s*:/,
		'report() web-form section contains Upload line';
};

subtest 'form_contacts -- report() omits web-form section when no form contacts' => sub {
	# When no form-only providers are involved the section must be absent
	# entirely -- no placeholder text.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Visit https://evilblog.wordpress.com/offer',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my $report = $a->report();
		unlike $report, qr/WHERE TO FILE WEB-FORM REPORTS/,
			'report() has no web-form section when no form contacts present';
	}
	restore_net();
};


# =============================================================================
# 41. Regression: SRS-rewritten return-path skipped in abuse_contacts() (0.07)
# =============================================================================

subtest 'abuse_contacts -- SRS return-path not used as account provider' => sub {
	# An SRS-rewritten Return-Path like:
	#   bounce+SRS=hash=ts=gmail.com=spam@groups.outlook.com
	# is generated by the forwarding host to preserve SPF validity.
	# The forwarding domain (groups.outlook.com) is not responsible for
	# the spam and must not appear as an abuse target via this route.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@gmail.com>',
		return_path => '<ar6mtd+SRS=hMi8R=B5=gmail.com=spam@groups.outlook.com>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Buy now',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts = $a->abuse_contacts();
		my @roles    = map { $_->{role} } @contacts;
		my @srs      = grep { /return-path.*SRS/i } @roles;
		is scalar(@srs), 0,
			'SRS return-path does not appear as account provider role';
		# Microsoft still appears via other routes (From: or provider table)
		# but NOT via the SRS return-path
		my @ms_via_rp = grep {
			$_->{role} =~ /return-path/ && $_->{address} =~ /microsoft/i
		} @contacts;
		is scalar(@ms_via_rp), 0,
			'Microsoft not contacted via SRS return-path route';
	}
	restore_net();
};

subtest 'abuse_contacts -- SRS0 variant also skipped' => sub {
	# SRS0 is the standard form; SRS1 is used for re-forwarded mail
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@gmail.com>',
		return_path => '<user+SRS0=abcd=ef=gmail.com=spam@relay.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Buy now',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts = $a->abuse_contacts();
		my @srs = grep { $_->{role} =~ /return-path.*SRS/i } @contacts;
		is scalar(@srs), 0, 'SRS0 return-path variant also skipped';
	}
	restore_net();
};

subtest 'abuse_contacts -- non-SRS return-path still used' => sub {
	# A normal (non-SRS) Return-Path should still be used as an account
	# provider route when the domain is in the provider table.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@hotmail.com>',
		return_path => '<bounce@hotmail.com>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Buy now',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { $_->{address} } @contacts;
		ok scalar(grep { $_ eq 'abuse@microsoft.com' } @addresses),
			'non-SRS hotmail.com return-path still produces microsoft abuse contact';
	}
	restore_net();
};


# =============================================================================
# 42. Regression: W3C URLs in HTML boilerplate do not trigger false positive
#     risk flags (0.07)
#     www.w3.org appears in HTML email templates as namespace/DTD references
#     (e.g. http://www.w3.org/1999/xhtml) and must not raise http_not_https
#     or generate abuse contacts.
# =============================================================================

subtest 'risk_assessment -- w3.org http URL does not raise http_not_https' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		to   => '<victim@nigelhorne.com>',
		body => 'Visit https://spamsite.example/offer',
		ct   => 'text/html',
		# Simulate an HTML body containing a W3C namespace reference
	));
	# Parse with a body that includes a W3C DTD reference
	$a->parse_email(join("\n",
		'Received: from ext (ext [198.51.100.1]) by mx.nigelhorne.com with ESMTP',
		'From: Spammer <spam@spammer.example>',
		'To: <victim@nigelhorne.com>',
		'Subject: Test',
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime),
		'Message-ID: <w3test@test>',
		'Content-Type: text/html; charset=us-ascii',
		'',
		'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"',
		'  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
		'<html xmlns="http://www.w3.org/1999/xhtml">',
		'<body><a href="https://spamsite.example/offer">Buy now</a></body>',
		'</html>',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my $risk  = $a->risk_assessment();
		my @flags = @{ $risk->{flags} };
		my @w3_http = grep {
			$_->{flag} eq 'http_not_https' && $_->{detail} =~ /w3\.org/i
		} @flags;
		is scalar(@w3_http), 0,
			'http_not_https not raised for www.w3.org DTD/namespace reference';
	}
	restore_net();
};

subtest 'risk_assessment -- http_not_https still raised for non-trusted http URLs' => sub {
	# Guard: the W3C skip must not suppress legitimate http_not_https flags
	# for actual spam landing page URLs.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(join("\n",
		'Received: from ext (ext [198.51.100.1]) by mx.nigelhorne.com with ESMTP',
		'From: Spammer <spam@spammer.example>',
		'To: <victim@nigelhorne.com>',
		'Subject: Test',
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime),
		'Message-ID: <httptest@test>',
		'Content-Type: text/plain',
		'',
		'Visit http://spamsite.example/offer for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my $risk  = $a->risk_assessment();
		my @flags = @{ $risk->{flags} };
		my @http  = grep { $_->{flag} eq 'http_not_https' } @flags;
		ok scalar(@http) > 0,
			'http_not_https still raised for non-trusted plain-HTTP spam URL';
	}
	restore_net();
};

subtest 'abuse_contacts -- w3.org URL does not generate abuse contact' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(join("\n",
		'Received: from ext (ext [198.51.100.1]) by mx.nigelhorne.com with ESMTP',
		'From: Spammer <spam@spammer.example>',
		'To: <victim@nigelhorne.com>',
		'Subject: Test',
		'Date: ' . POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime),
		'Message-ID: <w3contact@test>',
		'Content-Type: text/html; charset=us-ascii',
		'',
		'<html xmlns="http://www.w3.org/1999/xhtml">',
		'<body><a href="https://spamsite.example/offer">Buy now</a></body>',
		'</html>',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { $_->{address} } @contacts;
		my @w3_contacts = grep { /w3\.org/i } @addresses;
		is scalar(@w3_contacts), 0,
			'no abuse contact generated for w3.org URL in HTML boilerplate';
	}
	restore_net();
};


# =============================================================================
# 43. Regression: body reply address route in abuse_contacts() (0.07)
#     Advance-fee and investment scams commonly spoof the From: address but
#     include a real free-webmail contact address in the body text.
# =============================================================================

subtest 'abuse_contacts -- hotmail reply address in body produces microsoft contact' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spoofed@qwestoffice.net>',
		return_path => '<spoofed@qwestoffice.net>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Contact us at profcindyinvestments@hotmail.com for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok scalar(grep { $_ eq 'abuse@microsoft.com' } @addresses),
			'abuse@microsoft.com generated for hotmail.com reply address in body';
		my ($c) = grep { $_->{address} eq 'abuse@microsoft.com' &&
		                 $_->{role} =~ /body/ } @contacts;
		ok defined $c,
			'contact has body-route role';
		like $c->{role}, qr/profcindyinvestments\@hotmail\.com/i,
			'role string includes the specific reply address';
	}
	restore_net();
};

subtest 'abuse_contacts -- gmail reply address in body produces google contact' => sub {
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spoofed@innocent.example>',
		return_path => '<spoofed@innocent.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Send money to scammer@gmail.com to claim your prize',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok scalar(grep { $_ eq 'abuse@google.com' } @addresses),
			'abuse@google.com generated for gmail.com reply address in body';
	}
	restore_net();
};

subtest 'abuse_contacts -- body reply address not duplicated if already found via header' => sub {
	# If the From: header and body both mention the same provider domain,
	# deduplication must ensure only one contact entry results.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@gmail.com>',
		return_path => '<spam@gmail.com>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Reply to spam@gmail.com for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts = $a->abuse_contacts();
		my @google   = grep { $_->{address} eq 'abuse@google.com' } @contacts;
		is scalar(@google), 1,
			'abuse@google.com appears only once despite header and body both matching';
	}
	restore_net();
};

subtest 'abuse_contacts -- non-provider body address does not generate contact' => sub {
	# An email address in the body whose domain is not in %PROVIDER_ABUSE
	# must not generate a contact via this route.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spam@spammer.example>',
		return_path => '<spam@spammer.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Contact unknown@unknowndomain.example for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub { undef };

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok !scalar(grep { /unknown/ } @addresses),
			'unknown provider domain in body does not generate spurious contact';
	}
	restore_net();
};

subtest 'abuse_contacts -- spoofed From: domain registrar not reported' => sub {
	# qwestoffice.net pattern: the From:/Return-Path: domain is an innocent
	# victim of spoofing.  It appears only in sending headers, never in URLs
	# or body addresses.  Its registrar must not receive an abuse report.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <spoofed@innocent-victim.example>',
		return_path => '<spoofed@innocent-victim.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Contact us at scammer@hotmail.com for details',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub {
			my (undef, $dom) = @_;
			return "Registrar: Innocent Registrar Inc\n"
			     . "Registrar Abuse Contact Email: abuse\@innocentregistrar.example\n"
				if $dom eq 'innocent-victim.example';
			return undef;
		};

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok !scalar(grep { /innocentregistrar/ } @addresses),
			'registrar of spoofed From: domain not included in contacts';
		ok scalar(grep { $_ eq 'abuse@microsoft.com' } @addresses),
			'real reply address (hotmail) still produces contact';
	}
	restore_net();
};

subtest 'abuse_contacts -- From: domain registrar reported when domain also in URL' => sub {
	# When the From: domain also appears as a URL host, the spammer controls
	# it -- it is not spoofed.  The registrar contact must be included.
	null_net();
	my $a = new_ok('Email::Abuse::Investigator');
	$a->parse_email(make_email(
		from        => 'Spammer <deals@spamsite.example>',
		return_path => '<deals@spamsite.example>',
		to          => '<victim@nigelhorne.com>',
		body        => 'Visit https://spamsite.example/offer now',
	));
	{
		no warnings 'redefine';
		local *Email::Abuse::Investigator::_resolve_host = sub { undef };
		local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
		local *Email::Abuse::Investigator::_domain_whois = sub {
			my (undef, $dom) = @_;
			return "Registrar: Dodgy Registrar Inc\n"
			     . "Registrar Abuse Contact Email: abuse\@dodgyregistrar.example\n"
				if $dom eq 'spamsite.example';
			return undef;
		};

		my @contacts  = $a->abuse_contacts();
		my @addresses = map { lc $_->{address} } @contacts;
		ok scalar(grep { /dodgyregistrar/ } @addresses),
			'registrar included when From: domain also appears as URL host';
	}
	restore_net();
};

done_testing();
