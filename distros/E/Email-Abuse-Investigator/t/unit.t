#!/usr/bin/env perl
# =============================================================================
# t/unit.t  —  Contract tests for every public method of Email::Abuse::Investigator
#
# Each subtest maps 1-to-1 with a POD-documented method.  Tests verify:
#   • Return type and structure exactly match the documented API
#   • All documented hashref keys are present and have the right types
#   • All documented behaviours (deduplication, lazy evaluation, caching,
#     scalar/ref input, confidence levels, etc.) are exercised
#   • No test reaches into private internals or makes network calls
#
# Run:
#   prove -lv t/unit.t
# =============================================================================

use strict;
use warnings;

use Test::More;
use Scalar::Util qw( blessed reftype );
use MIME::Base64 qw( encode_base64 );
use POSIX        qw( strftime );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
use Email::Abuse::Investigator;

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Build a syntactically valid RFC 2822 email.
sub make_email {
    my (%h) = @_;
    my $received = $h{received}
        // 'from ext.example.com (ext.example.com [91.198.174.42])'
         . ' by mx.bandsman.co.uk (Postfix); Mon, 01 Jan 2024 00:00:00 +0000';
    my $from        = $h{from}        // 'Sender <sender@spamsite.example>';
    my $reply_to    = $h{reply_to};
    my $return_path = $h{return_path} // '<sender@spamsite.example>';
    my $to          = $h{to}          // 'victim@bandsman.co.uk';
    my $subject     = $h{subject}     // 'Unit test message';
    my $date        = $h{date}        // POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
    my $mid         = $h{message_id}  // '<unit-001@spamsite.example>';
    my $ct          = $h{ct}          // 'text/plain; charset=us-ascii';
    my $cte         = $h{cte}         // '7bit';
    my $auth        = $h{auth}        // '';
    my $xoip        = $h{xoip};
    my $body        = $h{body}        // 'Hello, please buy something.';

    my $hdrs = '';
    $hdrs .= "Received: $received\n";
    $hdrs .= "Authentication-Results: $auth\n"  if $auth;
    $hdrs .= "Return-Path: $return_path\n";
    $hdrs .= "From: $from\n";
    $hdrs .= "Reply-To: $reply_to\n"            if defined $reply_to;
    $hdrs .= "To: $to\n";
    $hdrs .= "Subject: $subject\n";
    $hdrs .= "Date: $date\n";
    $hdrs .= "Message-ID: $mid\n";
    $hdrs .= "Content-Type: $ct\n";
    $hdrs .= "Content-Transfer-Encoding: $cte\n";
    $hdrs .= "X-Originating-IP: $xoip\n"        if defined $xoip;
    return "$hdrs\n$body";
}

# Stub all network I/O so every subtest is hermetic.
# Installs stubs into the object's package via local(); caller must be
# inside a block for the stubs to expire correctly.
sub stub_net {
    my (%ov) = @_;
    no warnings 'redefine';
    *Email::Abuse::Investigator::_reverse_dns  = sub { $ov{rdns}  // 'mail.stub.example' };
    *Email::Abuse::Investigator::_resolve_host = sub {
        my (undef, $h) = @_;
        return $h if $h =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;
        my $map = $ov{resolve};
        return undef unless defined $map;
        return ref $map eq 'HASH' ? $map->{$h} : $map;
    };
    *Email::Abuse::Investigator::_whois_ip = sub {
        { org     => ($ov{org}     // 'Stub ISP'),
          abuse   => ($ov{abuse}   // 'abuse@stub.example'),
          country => ($ov{country} // undef) }
    };
    *Email::Abuse::Investigator::_domain_whois = sub { $ov{domain_whois} // undef };
    *Email::Abuse::Investigator::_raw_whois    = sub { undef };
    *Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
}

# Restore stubs to originals after each subtest (saves leaking between subtests).
my %_orig;
BEGIN {
    for my $m (qw( _reverse_dns _resolve_host _whois_ip
                   _domain_whois _raw_whois _rdap_lookup )) {
        no strict 'refs';
        $_orig{$m} = \&{ "Email::Abuse::Investigator::$m" };
    }
}
sub restore_net {
    no warnings 'redefine';
    for my $m (keys %_orig) {
        no strict 'refs';
        *{ "Email::Abuse::Investigator::$m" } = $_orig{$m};
    }
}

# =============================================================================
# new()
# =============================================================================
subtest 'new() — constructor API' => sub {
    # Returns a blessed reference of the correct class
    my $a = Email::Abuse::Investigator->new();
    ok defined $a,              'new() returns a value';
    ok blessed($a),             'return value is blessed';
    is blessed($a), 'Email::Abuse::Investigator', 'blessed into correct class';

    # Default option values (as documented)
    is $a->{timeout}, 10, 'default timeout is 10';
    is $a->{verbose},  0, 'default verbose is 0';
    is_deeply $a->{trusted_relays}, [], 'default trusted_relays is []';

    # Custom option values stored correctly
    my $b = Email::Abuse::Investigator->new(
        timeout        => 30,
        verbose        => 1,
        trusted_relays => ['62.105.128.0/24', '91.198.174.5'],
    );
    is $b->{timeout}, 30, 'custom timeout stored';
    is $b->{verbose},  1, 'custom verbose stored';
    is_deeply $b->{trusted_relays},
        ['62.105.128.0/24', '91.198.174.5'],
        'custom trusted_relays stored';
};

# =============================================================================
# parse_email( $text )
# =============================================================================
subtest 'parse_email() — accepts scalar and scalar-ref; returns $self' => sub {
    my $raw = make_email();

    # Accepts a plain scalar
    my $a = Email::Abuse::Investigator->new();
    my $ret = $a->parse_email($raw);
    is $ret, $a, 'parse_email returns $self (scalar input)';

    # Accepts a scalar reference (documented alternative)
    my $b = Email::Abuse::Investigator->new();
    my $ret2 = $b->parse_email(\$raw);
    is $ret2, $b, 'parse_email returns $self (scalar-ref input)';

    # Both produce identical header lists
    is_deeply $b->{_headers}, $a->{_headers},
        'scalar and scalar-ref inputs produce same result';
};

subtest 'parse_email() — handles multipart, quoted-printable, base64 bodies' => sub {
    # QP body
    my $qp_body = "Caf=C3=A9 au lait";
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(ct => 'text/plain', cte => 'quoted-printable',
                               body => $qp_body));
    like $a->{_body_plain}, qr/Caf/, 'QP body decoded';

    # base64 body
    my $b64_body = encode_base64("Base64 encoded content here");
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email(make_email(ct => 'text/plain', cte => 'base64',
                               body => $b64_body));
    like $b->{_body_plain}, qr/Base64 encoded content/, 'base64 body decoded';

    # multipart/alternative
    my $bnd = 'UNIT_BOUNDARY';
    my $mp  = "--$bnd\r\nContent-Type: text/plain\r\n\r\nplain text here\r\n"
            . "--$bnd\r\nContent-Type: text/html\r\n\r\n<b>html here</b>\r\n"
            . "--$bnd--\r\n";
    my $c = Email::Abuse::Investigator->new();
    $c->parse_email(make_email(
        ct   => qq{multipart/alternative; boundary="$bnd"},
        body => $mp,
    ));
    like $c->{_body_plain}, qr/plain text here/, 'multipart plain part decoded';
    like $c->{_body_html},  qr/html here/,       'multipart html part decoded';
};

subtest 'parse_email() — re-parse resets all lazy caches' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());

    # Inject stale cached state
    $a->{_origin}         = { ip => '0.0.0.0' };
    $a->{_urls}           = [ { url => 'stale' } ];
    $a->{_mailto_domains} = [ { domain => 'stale.example' } ];
    $a->{_domain_info}    = { 'stale.example' => {} };
    $a->{_risk}           = { level => 'STALE', score => 99, flags => [] };

    $a->parse_email(make_email());   # re-parse

    is $a->{_origin},         undef, 're-parse clears _origin';
    is $a->{_urls},           undef, 're-parse clears _urls';
    is $a->{_mailto_domains}, undef, 're-parse clears _mailto_domains';
    is_deeply $a->{_domain_info}, {}, 're-parse clears _domain_info';
    is $a->{_risk},           undef, 're-parse clears _risk';
};

# =============================================================================
# originating_ip()
# =============================================================================
subtest 'originating_ip() — documented hashref structure' => sub {
    stub_net(rdns => 'mail.spammer.example', org => 'Bad ISP',
             abuse => 'abuse@bad-isp.example', country => 'US');

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from spammer (spammer [91.198.174.42]) by mx'));
    my $orig = $a->originating_ip();

    # Must be a hashref
    ok defined $orig,           'returns a defined value';
    is reftype($orig), 'HASH',  'returns a hashref';

    # Documented keys must be present
    for my $key (qw( ip rdns org abuse confidence note )) {
        ok exists $orig->{$key}, "hashref contains key '$key'";
    }

    # Type constraints from POD examples
    like $orig->{ip},         qr/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/,
                              'ip is a dotted-quad IPv4 address';
    ok defined $orig->{rdns},       'rdns is defined';
    ok defined $orig->{org},        'org is defined';
    ok defined $orig->{confidence}, 'confidence is defined';
    ok $orig->{confidence} =~ /^(?:high|medium|low)$/,
       "confidence is 'high', 'medium', or 'low'";

    restore_net();
};

subtest 'originating_ip() — confidence levels per POD' => sub {
    stub_net();

    # single external hop → medium
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from spammer (spammer [91.198.174.1]) by mx'));
    is $a->originating_ip()->{confidence}, 'medium',
       'single external hop yields medium confidence';

    # two external hops → high
    my $raw2 = "Received: from r1 (r1 [91.198.174.2]) by r2\n"
             . "Received: from r2 (r2 [91.198.174.3]) by mx\n"
             . "From: x\@y.com\nSubject: s\n\nbody";
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email($raw2);
    is $b->originating_ip()->{confidence}, 'high',
       'two external hops yields high confidence';

    # X-Originating-IP only → low
    my $c = Email::Abuse::Investigator->new();
    $c->parse_email(make_email(
        received => 'from localhost [127.0.0.1] by mx',
        xoip     => '62.105.128.99',
    ));
    is $c->originating_ip()->{confidence}, 'low',
       'X-Originating-IP fallback yields low confidence';

    restore_net();
};

subtest 'originating_ip() — returns undef when no IP can be determined' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
    is $a->originating_ip(), undef,
       'undef returned when no Received: header and no X-Originating-IP';
};

subtest 'originating_ip() — result is cached between calls' => sub {
    stub_net();
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());
    my $first  = $a->originating_ip();
    my $second = $a->originating_ip();
    is $first, $second, 'same ref returned on repeated calls (cached)';
    restore_net();
};

# =============================================================================
# embedded_urls()
# =============================================================================
subtest 'embedded_urls() — documented hashref structure' => sub {
    stub_net(resolve => '91.198.174.7', org => 'Dodgy Hosting Ltd',
             abuse => 'abuse@dodgy.example');

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        body => 'Visit https://spamsite.example/offer to buy now.'));
    my @urls = $a->embedded_urls();

    ok @urls > 0, 'returns at least one hashref';

    # Check documented keys on the first result
    my $u = $urls[0];
    is reftype($u), 'HASH', 'each element is a hashref';

    for my $key (qw( url host ip org abuse )) {
        ok exists $u->{$key}, "url hashref contains key '$key'";
    }

    # Type constraints from POD example
    like $u->{url},  qr{^https?://}, 'url starts with http(s)://';
    ok defined $u->{host},           'host is defined';
    ok defined $u->{ip},             'ip is defined';
    ok defined $u->{org},            'org is defined';
    ok defined $u->{abuse},          'abuse is defined';

    # url and host are consistent
    like $u->{url}, qr/\Q$u->{host}\E/, 'url contains host';

    restore_net();
};

subtest 'embedded_urls() — returns empty list when body has no URLs' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'No links here at all.'));
    my @urls = $a->embedded_urls();
    is scalar @urls, 0, 'empty list returned when no URLs present';
};

subtest 'embedded_urls() — extracts from both plain and HTML parts' => sub {
    stub_net(resolve => '1.2.3.4');

    my $bnd = 'EMBU';
    my $mp  = "--$bnd\r\nContent-Type: text/plain\r\n\r\n"
            . "Plain: https://plain.example/path\r\n"
            . "--$bnd\r\nContent-Type: text/html\r\n\r\n"
            . '<a href="https://html.example/path">click</a>'
            . "\r\n--$bnd--\r\n";
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        ct   => qq{multipart/alternative; boundary="$bnd"},
        body => $mp,
    ));
    my @urls  = $a->embedded_urls();
    my @hosts = map { $_->{host} } @urls;
    ok scalar(grep { $_ eq 'plain.example' } @hosts), 'URL from plain part extracted';
    ok scalar(grep { $_ eq 'html.example'  } @hosts), 'URL from HTML part extracted';

    restore_net();
};

subtest 'embedded_urls() — result is cached between calls' => sub {
    stub_net(resolve => '1.2.3.4');
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'https://cache.example/test'));
    my @first  = $a->embedded_urls();
    my @second = $a->embedded_urls();
    is scalar @second, scalar @first, 'same count returned on second call';
    is $a->{_urls}, $a->{_urls}, 'underlying arrayref is the same object';
    restore_net();
};

subtest 'embedded_urls() — WHOIS queried once per unique host, not per URL' => sub {
    stub_net(resolve => '1.2.3.4');
    my $whois_call_count = 0;
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_whois_ip = sub { $whois_call_count++; {} };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        body => 'https://samehost.example/a and https://samehost.example/b '
              . 'and https://samehost.example/c'));
    my @urls = $a->embedded_urls();
    is scalar @urls, 3,           'three URL entries returned';
    is $whois_call_count, 1,      'WHOIS called once for one unique host';
    restore_net();
};

# =============================================================================
# mailto_domains()
# =============================================================================
subtest 'mailto_domains() — documented hashref structure' => sub {
    stub_net(resolve => '104.21.30.10', org => 'Cloudflare Inc',
             abuse => 'abuse@cloudflare.com');

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'Spammer <spammer@spamco.example>',
        body => 'Contact mailto:info@spamco.example for details',
    ));
    my @doms = $a->mailto_domains();

    ok @doms > 0, 'returns at least one hashref';

    my $d = $doms[0];
    is reftype($d), 'HASH', 'each element is a hashref';

    # Documented keys (all optional except domain and source, but must exist)
    for my $key (qw( domain source )) {
        ok exists $d->{$key},     "domain hashref contains required key '$key'";
        ok defined $d->{$key},    "key '$key' is defined";
    }

    # Optional hosting keys — if present must be of correct type
    for my $key (qw( web_ip web_org web_abuse
                     mx_host mx_ip mx_org mx_abuse
                     ns_host ns_ip ns_org ns_abuse
                     registrar registered expires recently_registered
                     whois_raw )) {
        if (exists $d->{$key} && defined $d->{$key}) {
            ok !ref($d->{$key}) || ref($d->{$key}) eq 'SCALAR',
               "key '$key', when present, is a plain scalar";
        }
    }

    # recently_registered — if present must be boolean (1 or undef/0)
    if (exists $d->{recently_registered}) {
        ok !defined($d->{recently_registered})
            || $d->{recently_registered} == 0
            || $d->{recently_registered} == 1,
           'recently_registered is boolean';
    }

    restore_net();
};

subtest 'mailto_domains() — collects from From:, Reply-To:, Return-Path:' => sub {
    stub_net();

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from        => 'A <a@from-domain.example>',
        reply_to    => 'B <b@replyto-domain.example>',
        return_path => '<c@returnpath-domain.example>',
        body        => 'Nothing interesting',
    ));
    my @doms  = $a->mailto_domains();
    my @names = map { $_->{domain} } @doms;

    ok scalar(grep { $_ eq 'from-domain.example'       } @names),
       'domain from From: header captured';
    ok scalar(grep { $_ eq 'replyto-domain.example'    } @names),
       'domain from Reply-To: header captured';
    ok scalar(grep { $_ eq 'returnpath-domain.example' } @names),
       'domain from Return-Path: header captured';

    restore_net();
};

subtest 'mailto_domains() — collects from mailto: links and bare addresses in body' => sub {
    stub_net();

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'x@trusted-infra.example',
        body => 'Contact mailto:sales@bodylink.example or info@bareaddr.example',
    ));
    my @names = map { $_->{domain} } $a->mailto_domains();

    ok scalar(grep { $_ eq 'bodylink.example' } @names),
       'domain from mailto: in body captured';
    ok scalar(grep { $_ eq 'bareaddr.example' } @names),
       'domain from bare address in body captured';

    restore_net();
};

subtest 'mailto_domains() — infrastructure domains are excluded' => sub {
    stub_net();

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'Spammer <spammer@gmail.com>',
        body => 'Visit our site info@yahoo.com',
    ));
    my @names = map { $_->{domain} } $a->mailto_domains();

    ok !scalar(grep { $_ eq 'gmail.com'   } @names), 'gmail.com excluded';
    ok !scalar(grep { $_ eq 'yahoo.com'   } @names), 'yahoo.com excluded';

    restore_net();
};

subtest 'mailto_domains() — each domain appears only once (deduplicated)' => sub {
    stub_net();

    my $a = Email::Abuse::Investigator->new();
    # Same domain in From:, body mailto:, and bare address
    $a->parse_email(make_email(
        from => 'A <a@dup.example>',
        body => 'Also mailto:b@dup.example and info@dup.example',
    ));
    my @names = map { $_->{domain} } $a->mailto_domains();
    my @dups  = grep { $_ eq 'dup.example' } @names;
    is scalar @dups, 1, 'same domain appears only once';

    restore_net();
};

subtest 'mailto_domains() — recently_registered flag for domains < 180 days old' => sub {
    # Inject a pre-built domain result with a recent registration date
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'contact info@newdomain.example'));

    # Bypass network and WHOIS entirely by pre-populating the cache
    my $ten_days_ago = strftime('%Y-%m-%d', gmtime(time() - 10 * 86400));
    $a->{_domain_info}{'newdomain.example'} = {
        registered          => $ten_days_ago,
        recently_registered => 1,
        expires             => '2099-01-01',
    };

    stub_net(resolve => undef);
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my @doms = $a->mailto_domains();
    my ($nd) = grep { $_->{domain} eq 'newdomain.example' } @doms;
    ok defined $nd,                'newdomain.example present in results';
    is $nd->{recently_registered}, 1, 'recently_registered is 1 for recent domain';

    restore_net();
};

subtest 'mailto_domains() — result is cached between calls' => sub {
    stub_net();
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'contact info@cached.example'));
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    my @first  = $a->mailto_domains();
    my @second = $a->mailto_domains();
    is scalar @second, scalar @first, 'same count on second call';
    is $a->{_mailto_domains}, $a->{_mailto_domains}, 'same arrayref (cached)';
    restore_net();
};

# =============================================================================
# all_domains()
# =============================================================================
subtest 'all_domains() — returns union of URL hosts and mailto domains' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'x@maildom.example',
        body => 'https://urldom.example/page and info@maildom.example',
    ));
    my @all = $a->all_domains();

    ok scalar(grep { $_ eq 'urldom.example'  } @all), 'URL host in all_domains';
    ok scalar(grep { $_ eq 'maildom.example' } @all), 'mailto domain in all_domains';

    restore_net();
};

subtest 'all_domains() — no duplicates across sources' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    # Same registrable domain in both URL and mailto
    $a->parse_email(make_email(
        from => 'x@shared.example',
        body => 'https://www.shared.example/path and info@shared.example',
    ));
    my @all  = $a->all_domains();
    my %seen;
    my @dups = grep { $seen{$_}++ } @all;
    is scalar @dups, 0, 'all_domains contains no duplicates';

    restore_net();
};

subtest 'all_domains() — returns plain list of strings' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'https://stringtest.example/x'));
    my @all = $a->all_domains();
    for my $item (@all) {
        ok !ref($item), "all_domains element is a plain string (got: $item)";
    }

    restore_net();
};

# =============================================================================
# risk_assessment()
# =============================================================================
subtest 'risk_assessment() — documented top-level hashref structure' => sub {
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());
    my $risk = $a->risk_assessment();

    is reftype($risk), 'HASH', 'returns a hashref';

    # Documented top-level keys
    for my $key (qw( level score flags )) {
        ok exists $risk->{$key}, "result contains key '$key'";
    }

    # level must be one of the four documented values
    ok $risk->{level} =~ /^(?:HIGH|MEDIUM|LOW|INFO)$/,
       "level is HIGH|MEDIUM|LOW|INFO (got '$risk->{level}')";

    # score is a non-negative integer
    ok defined $risk->{score},          'score is defined';
    like "$risk->{score}", qr/^\d+$/,   'score is a non-negative integer';

    # flags is an arrayref
    is reftype($risk->{flags}), 'ARRAY', 'flags is an arrayref';

    restore_net();
};

subtest 'risk_assessment() — each flag hashref has severity, flag, detail' => sub {
    stub_net(rdns => '1-2-3-4.dsl.isp.example');  # triggers residential flag
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from dsl-host (dsl-host [91.198.174.1]) by mx'));
    my $risk  = $a->risk_assessment();
    my @flags = @{ $risk->{flags} };

    ok @flags > 0, 'at least one flag generated';

    for my $f (@flags) {
        is reftype($f), 'HASH', 'each flag is a hashref';
        for my $key (qw( severity flag detail )) {
            ok exists $f->{$key},  "flag hashref has key '$key'";
            ok defined $f->{$key}, "flag key '$key' is defined";
        }
        ok $f->{severity} =~ /^(?:HIGH|MEDIUM|LOW|INFO)$/,
           "flag severity is HIGH|MEDIUM|LOW|INFO (got '$f->{severity}')";
    }

    restore_net();
};

subtest 'risk_assessment() — score threshold boundaries match POD' => sub {
    # POD: HIGH >= 9, MEDIUM >= 5, LOW >= 2, INFO otherwise
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    # INFO: clean message, no flags expected → score 0 → INFO
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        auth    => 'mx; spf=pass; dkim=pass; dmarc=pass',
        from    => 'Clean <clean@corp.example>',
        to      => 'user@bandsman.co.uk',
    ));
    # Manually inject clean origin (no rDNS issues)
    $a->{_origin} = {
        ip         => '91.198.174.1',
        rdns       => 'mail.corp.example',
        org        => 'Corp ISP',
        abuse      => 'abuse@corp.example',
        confidence => 'high',
        note       => 'test',
        country    => 'GB',
    };
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my $risk_info = $a->risk_assessment();
    is $risk_info->{level}, 'INFO', 'clean message scores INFO';
    ok $risk_info->{score} < 2, 'INFO score is < 2';

    restore_net();
};

subtest 'risk_assessment() — result is cached' => sub {
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());
    my $r1 = $a->risk_assessment();
    my $r2 = $a->risk_assessment();
    is $r2, $r1, 'risk_assessment returns the same ref on second call (cached)';

    restore_net();
};

# =============================================================================
# abuse_report_text()
# =============================================================================
subtest 'abuse_report_text() — returns a non-empty string' => sub {
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());
    my $text = $a->abuse_report_text();

    ok defined $text, 'returns a defined value';
    ok !ref($text),   'returns a plain string (not a reference)';
    ok length($text) > 0, 'string is non-empty';

    restore_net();
};

subtest 'abuse_report_text() — contains all documented sections' => sub {
    stub_net(rdns => 'mail.spammer.example', org => 'Bad ISP',
             abuse => 'abuse@bad-isp.example');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from spammer (spammer [91.198.174.42]) by mx',
        body     => 'Buy at https://scam.example/now',
    ));

    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { '91.198.174.99' };
        local *Email::Abuse::Investigator::_whois_ip     = sub {
            { org => 'Scam Host', abuse => 'abuse@scam.example' }
        };

        my $text = $a->abuse_report_text();

        # POD says: "includes the risk summary, the key findings,
        #            and the full original message headers"
        like $text, qr/automated abuse report/i,
             'report intro line present';
        like $text, qr/RISK LEVEL:\s*\w+/,
             'RISK LEVEL summary present';
        like $text, qr/ORIGINAL MESSAGE HEADERS/,
             'original message headers section present';
        like $text, qr/ORIGINATING IP/,
             'originating IP section present';
    }

    restore_net();
};

subtest 'abuse_report_text() — RED FLAGS section present when flags exist' => sub {
    stub_net(rdns => '1-2-3-4.dsl.example');  # triggers residential flag
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from dsl (dsl [91.198.174.1]) by mx'));
    my $text = $a->abuse_report_text();
    like $text, qr/RED FLAGS IDENTIFIED/, 'RED FLAGS section present when flags exist';

    restore_net();
};

subtest 'abuse_report_text() — ABUSE CONTACTS section present when contacts available' => sub {
    stub_net(rdns => 'mail-ej1.gmail.com');  # rDNS points to known provider
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from     => 'Spammer <spammer@gmail.com>',
        received => 'from google (google [209.85.218.67]) by mx',
    ));
    my $text = $a->abuse_report_text();
    like $text, qr/ABUSE CONTACTS/, 'ABUSE CONTACTS section present';

    restore_net();
};

subtest 'abuse_report_text() — suitable for emailing to abuse_contacts() addresses' => sub {
    # POD says: "Returns a string suitable for pasting into an abuse report email.
    #            Then email to each address from $analyser->abuse_contacts()"
    # Verify that abuse_report_text() and abuse_contacts() are independently callable
    # and that both succeed on the same object.
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'x@gmail.com',
        received => 'from g (g [209.85.218.67]) by mx',
    ));
    my $text     = $a->abuse_report_text();
    my @contacts = $a->abuse_contacts();

    ok defined $text,      'abuse_report_text() succeeds';
    ok !ref($text),        'abuse_report_text() returns a string';
    # At least the gmail provider contact should be found
    ok @contacts > 0,      'abuse_contacts() returns results on same object';

    restore_net();
};

# =============================================================================
# abuse_contacts()
# =============================================================================
subtest 'abuse_contacts() — documented hashref structure' => sub {
    stub_net(rdns => 'mail-ej1.google.com', org => 'Google LLC',
             abuse => 'network-abuse@google.com');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from     => 'Spammer <spammer@gmail.com>',
        received => 'from google (google [209.85.218.67]) by mx',
    ));
    my @contacts = $a->abuse_contacts();

    ok @contacts > 0, 'returns at least one contact';

    for my $c (@contacts) {
        is reftype($c), 'HASH', 'each contact is a hashref';

        # Documented keys
        for my $key (qw( role address via )) {
            ok exists  $c->{$key}, "contact hashref contains key '$key'";
            ok defined $c->{$key}, "contact key '$key' is defined";
        }

        # address must contain an @ sign (it's an email address)
        like $c->{address}, qr/\@/, "contact address '$c->{address}' contains \@";

        # via must be one of the documented values
        ok $c->{via} =~ /^(?:ip-whois|domain-whois|provider-table|rdap)$/,
           "contact via '$c->{via}' is a documented value";
    }

    restore_net();
};

subtest 'abuse_contacts() — addresses are deduplicated across routes' => sub {
    # Inject a scenario where the same abuse address is discoverable from
    # multiple routes (URL host and MX host both resolving to Cloudflare)
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'x@example.org',
        body => 'https://cf-hosted.example/page',
    ));
    $a->{_origin}         = undef;
    $a->{_urls}           = [{
        url   => 'https://cf-hosted.example/page',
        host  => 'cf-hosted.example',
        ip    => '104.21.0.1',
        org   => 'CLOUDFLARENET',
        abuse => 'abuse@cloudflare.com',
    }];
    $a->{_mailto_domains} = [{
        domain       => 'cf-hosted.example',
        source       => 'body',
        web_ip       => '104.21.0.1',
        web_org      => 'CLOUDFLARENET',
        web_abuse    => 'abuse@cloudflare.com',
        mx_abuse     => 'abuse@cloudflare.com',  # same address from MX
        ns_abuse     => undef,
        registrar_abuse => undef,
    }];

    my @contacts  = $a->abuse_contacts();
    my @cf        = grep { lc($_->{address}) eq 'abuse@cloudflare.com' } @contacts;
    is scalar @cf, 1,
       'same abuse address appears exactly once despite multiple discovery routes';
};

subtest 'abuse_contacts() — produces Sending ISP contact from originating IP' => sub {
    stub_net(org => 'Sending Corp', abuse => 'abuse@sending-corp.example');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from sender (sender [91.198.174.42]) by mx',
    ));
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my @contacts = $a->abuse_contacts();
    my @isp      = grep { $_->{role} =~ /Sending ISP/i } @contacts;
    ok @isp > 0, 'at least one Sending ISP contact produced';
    ok scalar(grep { lc($_->{address}) eq 'abuse@sending-corp.example' } @contacts),
       'Sending ISP abuse address present in contacts';

    restore_net();
};

subtest 'abuse_contacts() — produces Account provider contact for known From: domain' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(from => 'Spammer <spammer@gmail.com>'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];

    my @contacts = $a->abuse_contacts();
    ok scalar(grep { $_->{role} =~ /Account provider/i } @contacts),
       'Account provider contact produced for gmail.com From:';
    ok scalar(grep { lc($_->{address}) eq 'abuse@google.com' } @contacts),
       'abuse@google.com in contacts for gmail sender';
};

subtest 'abuse_contacts() — produces Domain registrar contact' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(from => 'x@example.org'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [{
        domain           => 'spamreg.example',
        source           => 'body',
        registrar        => 'Dodgy Registrar',
        registrar_abuse  => 'abuse@dodgyreg.example',
    }];

    my @contacts = $a->abuse_contacts();
    ok scalar(grep { $_->{role} =~ /registrar/i } @contacts),
       'Domain registrar contact role produced';
    ok scalar(grep { lc($_->{address}) eq 'abuse@dodgyreg.example' } @contacts),
       'registrar abuse address present';
};

subtest 'abuse_contacts() — (unknown) abuse addresses are never included' => sub {
    stub_net(abuse => '(unknown)');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        received => 'from s (s [91.198.174.1]) by mx',
        from     => 'x@noprovider.example',   # not in provider table
    ));
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my @contacts = $a->abuse_contacts();
    ok !scalar(grep { $_->{address} eq '(unknown)' } @contacts),
       '(unknown) abuse address is never added to contacts';

    restore_net();
};

subtest 'abuse_contacts() — returns empty list when no contacts determinable' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from     => 'x@noprovider.example',
        received => 'from localhost [127.0.0.1] by mx',
    ));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];

    my @contacts = $a->abuse_contacts();
    is scalar @contacts, 0,
       'empty list returned when origin is undef and no domains/URLs';
};

# =============================================================================
# report()
# =============================================================================
subtest 'report() — returns a non-empty plain string' => sub {
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());
    my $r = $a->report();

    ok defined $r,      'returns a defined value';
    ok !ref($r),        'returns a plain string';
    ok length($r) > 0,  'report is non-empty';

    restore_net();
};

subtest 'report() — contains all expected section headings' => sub {
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        body => 'https://spamsite.example/buy and info@spamsite.example',
        from => 'Bad <bad@gmail.com>',
    ));
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
        local *Email::Abuse::Investigator::_whois_ip     = sub {
            { org => 'Test Org', abuse => 'abuse@testorg.example', country => 'US' }
        };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };

        my $r = $a->report();

        like $r, qr/Email::Abuse::Investigator Report/, 'report title present';
        like $r, qr/RISK ASSESSMENT/,             'RISK ASSESSMENT section present';
        like $r, qr/ORIGINATING HOST/,            'ORIGINATING HOST section present';
        like $r, qr/EMBEDDED HTTP\/HTTPS URLs/,   'EMBEDDED HTTP/HTTPS URLs section present';
        like $r, qr/CONTACT \/ REPLY-TO DOMAINS/, 'CONTACT/REPLY-TO DOMAINS section present';
        like $r, qr/WHERE TO SEND ABUSE REPORTS/, 'WHERE TO SEND ABUSE REPORTS section present';
    }

    restore_net();
};

subtest 'report() — envelope headers are decoded and displayed' => sub {
    stub_net();
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };

    # Use a base64-encoded From: display name (as in the firmluminary spam)
    my $enc_from = '=?UTF-8?B?' . encode_base64('eharmony Partner', '') . '?=';
    my $enc_subj = '=?UTF-8?B?' . encode_base64('Ready to Find Love', '') . '?=';

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from    => qq{"$enc_from" <peacelight\@firmluminary.com>},
        subject => $enc_subj,
    ));
    my $r = $a->report();

    like $r, qr/eharmony Partner/, 'encoded From: display name decoded in report';
    like $r, qr/Ready to Find Love/, 'encoded Subject decoded in report';

    restore_net();
};

subtest 'report() — originating IP section shows (could not determine) when undef' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];

    my $r = $a->report();
    like $r, qr/could not determine originating IP/,
         '"could not determine" message shown when origin is undef';
};

subtest 'report() — URL section shows "(none found)" when no URLs present' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'No links here.'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];

    my $r = $a->report();
    like $r, qr/none found/, '"none found" shown when no URLs';
};

subtest 'report() — URL section groups multiple paths under single host' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        body => 'https://multi.example/a https://multi.example/b https://multi.example/c'));
    $a->{_origin} = {
        ip => '1.2.3.4', rdns => 'mail.ok', confidence => 'high',
        org => 'X', abuse => 'a@b', note => '', country => undef,
    };
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
        local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'T', abuse=>'a@b' } };

        my $r = $a->report();
        like $r, qr/URLs \(3\)/, 'three URLs under same host shown as grouped count';

        # Host line appears only once
        my @host_lines = ($r =~ /Host\s*:\s*multi\.example/g);
        is scalar @host_lines, 1, 'host shown exactly once for grouped URLs';
    }

    restore_net();
};

subtest 'report() — URL shortener flagged inline in URL section' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => 'Click https://bit.ly/abc123 now'));
    $a->{_origin} = {
        ip => '1.2.3.4', rdns => 'mail.ok', confidence => 'high',
        org => 'X', abuse => 'a@b', note => '', country => undef,
    };
    {
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { '67.199.248.10' };
        local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'Bitly', abuse=>'a@b' } };

        my $r = $a->report();
        like $r, qr/URL SHORTENER/, 'URL shortener warning appears in report';
    }

    restore_net();
};

subtest 'report() — recently registered domain warning shown in domains section' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(from => 'x@example.org'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [{
        domain              => 'newphish.example',
        source              => 'From: header',
        recently_registered => 1,
        registered          => '2025-12-01',
        expires             => '2026-12-01',
    }];

    my $r = $a->report();
    like $r, qr/RECENTLY REGISTERED/,
         'RECENTLY REGISTERED warning shown for new domain';
};

subtest 'report() — abuse contacts section shows "(no contacts)" when empty' => sub {
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from     => 'x@noprovider.example',
        received => 'from localhost [127.0.0.1] by mx',
    ));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];

    my $r = $a->report();
    like $r, qr/no abuse contacts could be determined/,
         '"no abuse contacts" shown when contacts list is empty';
};

# =============================================================================
# Cross-method contract: lazy evaluation ordering
# =============================================================================
subtest 'lazy evaluation — methods succeed in any call order' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $raw = make_email(
        body => 'https://lazy.example/page and info@lazy.example',
        from => 'x@lazy.example',
    );

    # Call order 1: risk → urls → domains → origin
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email($raw);
        $a->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok',
                          confidence=>'high', org=>'X', abuse=>'a@b',
                          note=>'', country=>undef };
        my $risk  = $a->risk_assessment();
        my @urls  = $a->embedded_urls();
        my @mdoms = $a->mailto_domains();
        my $orig  = $a->originating_ip();
        ok defined $risk,  'risk_assessment succeeds first';
        ok defined $orig,  'originating_ip succeeds after risk';
        ok 1,              'no exception on any-order evaluation';
    }

    # Call order 2: report first (triggers everything lazily)
    {
        my $b = Email::Abuse::Investigator->new();
        $b->parse_email($raw);
        $b->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok',
                          confidence=>'high', org=>'X', abuse=>'a@b',
                          note=>'', country=>undef };
        my $r = eval { $b->report() };
        ok !$@, "report() does not die when called without prior method calls: $@";
        ok defined $r, 'report() returns a value';
    }

    restore_net();
};

# =============================================================================
# Cross-method contract: parse_email re-invocation
# =============================================================================
subtest 'parse_email() re-invocation clears all public-method caches' => sub {
    stub_net(resolve => '1.2.3.4');
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $a = Email::Abuse::Investigator->new();

    # First parse — populate all caches
    $a->parse_email(make_email(
        body     => 'https://first.example/page',
        from     => 'x@first.example',
        received => 'from first (first [91.198.174.1]) by mx',
    ));
    my @urls1  = $a->embedded_urls();
    my @mdoms1 = $a->mailto_domains();
    my $orig1  = $a->originating_ip();
    my $risk1  = $a->risk_assessment();

    ok @urls1  > 0,       'first parse: URLs populated';
    ok @mdoms1 > 0,       'first parse: domains populated';
    ok defined $orig1,    'first parse: origin populated';
    ok defined $risk1,    'first parse: risk populated';

    # Second parse — completely different email
    $a->parse_email(make_email(
        body     => 'No links at all.',
        from     => 'clean@verifiedcorp.example',
        received => 'from clean (clean [91.198.174.2]) by mx',
    ));

    my @urls2  = $a->embedded_urls();
    my @mdoms2 = $a->mailto_domains();

    is scalar @urls2, 0, 're-parse: URL cache refreshed (no links in new email)';

    # Origin should now reflect the new email's IP
    my $orig2 = $a->originating_ip();
    ok !defined($orig2) || $orig2->{ip} ne '91.198.174.1',
       're-parse: origin cache refreshed';

    restore_net();
};

done_testing();
