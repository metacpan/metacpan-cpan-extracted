#!/usr/bin/env perl
# =============================================================================
# t/function.t  —  White-box test suite for Email::Abuse::Investigator
#
# Design goals
#   • Every public method exercised, both happy-path and all failure/fallback
#     branches (high LCSAJ coverage)
#   • Every private helper called directly where needed to reach branches the
#     public API cannot exercise through normal email parsing alone
#   • No real network I/O: DNS, WHOIS, RDAP and socket calls are replaced
#     with lightweight stubs via local() and direct slot injection
#   • Target: ≥95 % statement/branch coverage under Devel::Cover
#
# Run:
#   prove -lv t/function.t
#   HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/function.t
# =============================================================================

use strict;
use warnings;

use Test::More;
use MIME::Base64      qw( encode_base64 );
use MIME::QuotedPrint qw( encode_qp );
use POSIX             qw( strftime );
use Socket            qw( inet_aton );

use FindBin qw( $Bin );
use lib "$Bin/../lib", "$Bin/..";
use Email::Abuse::Investigator;

# ---------------------------------------------------------------------------
# Utility: build a minimal raw RFC-2822 email string
# ---------------------------------------------------------------------------
sub make_email {
    my (%h) = @_;

    my $received    = $h{received}
        // 'from mail.example.com (mail.example.com [91.198.174.42])'
         . ' by mx.test (Postfix); Mon, 1 Jan 2024 00:00:00 +0000';
    my $from        = $h{from}        // 'Test Sender <sender@example.org>';
    my $reply_to    = $h{reply_to};
    my $return_path = $h{return_path} // '<sender@example.org>';
    my $to          = $h{to}          // 'victim@bandsman.co.uk';
    my $subject     = $h{subject}     // 'Test subject';
    my $date        = $h{date}        // POSIX::strftime('%a, %d %b %Y %H:%M:%S +0000', gmtime);
    my $message_id  = $h{message_id}  // '<test-001@example.org>';
    my $ct          = $h{ct}          // 'text/plain; charset=us-ascii';
    my $cte         = $h{cte}         // '7bit';
    my $auth        = $h{auth}        // '';
    my $xoip        = $h{xoip};
    my $extra       = $h{extra_hdrs}  // '';
    my $body        = $h{body}        // 'Hello world.';

    my $hdrs = '';
    $hdrs .= "Received: $received\n";
    $hdrs .= "Authentication-Results: $auth\n"  if $auth;
    $hdrs .= "Return-Path: $return_path\n";
    $hdrs .= "From: $from\n";
    $hdrs .= "Reply-To: $reply_to\n"            if defined $reply_to;
    $hdrs .= "To: $to\n";
    $hdrs .= "Subject: $subject\n";
    $hdrs .= "Date: $date\n";
    $hdrs .= "Message-ID: $message_id\n";
    $hdrs .= "Content-Type: $ct\n";
    $hdrs .= "Content-Transfer-Encoding: $cte\n";
    $hdrs .= "X-Originating-IP: $xoip\n"        if defined $xoip;
    $hdrs .= $extra                              if $extra;

    return "$hdrs\n$body";
}

# Convenience: does @list contain an element satisfying $predicate?
sub any_flag {
    my ($flags, $name) = @_;
    return scalar grep { $_->{flag} eq $name } @$flags;
}

sub any_addr {
    my ($contacts, $addr) = @_;
    return scalar grep { lc($_->{address}) eq lc($addr) } @$contacts;
}

# ===========================================================================
# 1. CONSTRUCTOR
# ===========================================================================
note '=== 1. Constructor ===';
{
    my $a = new_ok('Email::Abuse::Investigator');
    isa_ok $a, 'Email::Abuse::Investigator', 'new() returns blessed ref';
    is $a->{timeout},  10,  'default timeout 10';
    is $a->{verbose},   0,  'default verbose 0';
    is_deeply $a->{trusted_relays}, [], 'default trusted_relays empty';

    my $b = Email::Abuse::Investigator->new(
        timeout        => 30,
        verbose        => 1,
        trusted_relays => ['10.0.0.0/8'],
    );
    is $b->{timeout}, 30, 'custom timeout stored';
    is $b->{verbose},  1, 'custom verbose stored';
    is_deeply $b->{trusted_relays}, ['10.0.0.0/8'], 'custom trusted_relays stored';
}

# ===========================================================================
# 2. parse_email — scalar / scalar-ref / cache reset
# ===========================================================================
note '=== 2. parse_email ===';
{
    my $raw = make_email();
    my $a   = Email::Abuse::Investigator->new();
    my $ret = $a->parse_email($raw);
    is $ret, $a, 'parse_email returns $self';
    is $a->{_raw}, $raw, '_raw stored';
    ok @{ $a->{_headers} } > 0, 'headers parsed';

    # scalar-ref input
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email(\$raw);
    is_deeply $b->{_headers}, $a->{_headers}, 'scalar-ref gives same headers';

    # re-parse clears caches
    $a->{_origin}         = { ip => '1.2.3.4' };
    $a->{_urls}           = [{ url => 'old' }];
    $a->{_mailto_domains} = [{ domain => 'old.example' }];
    $a->{_domain_info}    = { 'old.example' => {} };
    $a->parse_email($raw);
    is $a->{_origin},         undef, 're-parse clears _origin';
    is $a->{_urls},           undef, 're-parse clears _urls';
    is $a->{_mailto_domains}, undef, 're-parse clears _mailto_domains';
    is_deeply $a->{_domain_info}, {}, 're-parse clears _domain_info';
}

# ===========================================================================
# 3. _split_message — all body-type branches
# ===========================================================================
note '=== 3. _split_message ===';
{
    # Plain text
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(body => "Hello\nworld"));
    is $a->{_body_plain}, "Hello\nworld", 'plain text stored';
    is $a->{_body_html},  '',             'html empty for plain email';

    # HTML content-type
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email(make_email(ct => 'text/html', body => '<b>Hi</b>'));
    is $b->{_body_html},  '<b>Hi</b>', 'html body stored';
    is $b->{_body_plain}, '',          'plain empty for html email';

    # QP decode
    my $qp = encode_qp("Caf\xE9 menu");
    my $c = Email::Abuse::Investigator->new();
    $c->parse_email(make_email(ct => 'text/plain', cte => 'quoted-printable',
                               body => $qp));
    like $c->{_body_plain}, qr/Caf/, 'QP decoded body';

    # Base64 decode
    my $b64 = encode_base64("Base64 content here");
    my $d = Email::Abuse::Investigator->new();
    $d->parse_email(make_email(ct => 'text/plain', cte => 'base64',
                               body => $b64));
    like $d->{_body_plain}, qr/Base64 content/, 'base64 decoded body';

    # multipart/alternative
    my $bnd = 'BNDXYZ';
    my $mp  = "--$bnd\r\nContent-Type: text/plain\r\n\r\nPlain part\r\n"
            . "--$bnd\r\nContent-Type: text/html\r\n\r\n<p>HTML part</p>\r\n"
            . "--$bnd--\r\n";
    my $e = Email::Abuse::Investigator->new();
    $e->parse_email(make_email(ct => qq{multipart/alternative; boundary="$bnd"},
                               cte => '', body => $mp));
    like $e->{_body_plain}, qr/Plain part/, 'multipart plain extracted';
    like $e->{_body_html},  qr/HTML part/,  'multipart html extracted';

    # multipart part with no body (skip branch)
    my $mp_nobody = "--$bnd\r\n\r\n--$bnd--\r\n";
    my $f = Email::Abuse::Investigator->new();
    $f->parse_email(make_email(ct => qq{multipart/alternative; boundary="$bnd"},
                               body => $mp_nobody));
    pass 'multipart with bodyless part does not die';

    # multipart part with no Content-Type -> plain fallback
    my $mp_notype = "--$bnd\r\nX-Foo: bar\r\n\r\nuntyped text\r\n--$bnd--\r\n";
    my $g = Email::Abuse::Investigator->new();
    $g->parse_email(make_email(ct => qq{multipart/alternative; boundary="$bnd"},
                               body => $mp_notype));
    like $g->{_body_plain}, qr/untyped text/, 'untyped part goes to plain';

    # multipart with QP sub-part
    my $qp_part = encode_qp("QP in multipart");
    my $mp_qp = "--$bnd\r\nContent-Type: text/plain\r\n"
              . "Content-Transfer-Encoding: quoted-printable\r\n\r\n"
              . "${qp_part}--$bnd--\r\n";
    my $h = Email::Abuse::Investigator->new();
    $h->parse_email(make_email(ct => qq{multipart/alternative; boundary="$bnd"},
                               body => $mp_qp));
    like $h->{_body_plain}, qr/QP in multipart/, 'QP multipart sub-part decoded';

    # Header unfolding
    my $folded = "From: First\n Last\nSubject: Test\n\nBody";
    my $i = Email::Abuse::Investigator->new();
    $i->parse_email($folded);
    my ($fh) = grep { $_->{name} eq 'from' } @{ $i->{_headers} };
    like $fh->{value}, qr/First\s+Last/, 'folded header unfolded';

    # No Content-Type header at all
    my $j = Email::Abuse::Investigator->new();
    $j->parse_email("From: x\@y.com\nSubject: s\n\nbody text");
    is $j->{_body_plain}, 'body text', 'absent Content-Type defaults to plain';
}

# ===========================================================================
# 4. _decode_body — three branches
# ===========================================================================
note '=== 4. _decode_body ===';
{
    my $a = Email::Abuse::Investigator->new();
    is $a->_decode_body('plain', '7bit'),            'plain',        '7bit passthrough';
    is $a->_decode_body('raw',   undef),             'raw',          'undef cte passthrough';
    like $a->_decode_body('Hello=20world', 'quoted-printable'), qr/Hello world/, 'QP decode';
    my $b64 = encode_base64('decoded text');
    like $a->_decode_body($b64, 'base64'), qr/decoded text/, 'base64 decode';
}

# ===========================================================================
# 5. _header_value
# ===========================================================================
note '=== 5. _header_value ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(subject => 'My Subject'));
    is $a->_header_value('subject'), 'My Subject', 'header found';
    is $a->_header_value('Subject'), 'My Subject', 'case-insensitive lookup';
    is $a->_header_value('x-none'),  undef,         'missing header -> undef';
}

# ===========================================================================
# 6. _is_private — every range + edge cases
# ===========================================================================
note '=== 6. _is_private ===';
{
    my $a = Email::Abuse::Investigator->new();
    ok  $a->_is_private('127.0.0.1'),       'loopback';
    ok  $a->_is_private('10.0.0.1'),        '10/8 low';
    ok  $a->_is_private('10.255.255.255'),  '10/8 high';
    ok  $a->_is_private('192.168.1.1'),     '192.168/16';
    ok  $a->_is_private('172.16.0.1'),      '172.16/12 low';
    ok  $a->_is_private('172.31.255.255'),  '172.31/12 high';
    ok !$a->_is_private('172.15.0.1'),      '172.15 not private';
    ok !$a->_is_private('172.32.0.1'),      '172.32 not private';
    ok  $a->_is_private('169.254.1.1'),     'link-local';
    ok  $a->_is_private('::1'),             'IPv6 loopback';
    ok  $a->_is_private('fc00::1'),         'IPv6 ULA fc';
    ok  $a->_is_private('fd12::1'),         'IPv6 ULA fd';
    ok !$a->_is_private('91.198.174.1'),    'public IP';
    ok  $a->_is_private(undef),             'undef treated private';
    ok  $a->_is_private(''),               'empty string treated private';
}

# ===========================================================================
# 7. _is_trusted — CIDR and exact-match
# ===========================================================================
note '=== 7. _is_trusted ===';
{
    my $a = Email::Abuse::Investigator->new(
        trusted_relays => ['62.105.128.0/24', '91.198.174.5']
    );
    ok  $a->_is_trusted('62.105.128.1'),   'CIDR match';
    ok  $a->_is_trusted('62.105.128.254'), 'CIDR edge';
    ok !$a->_is_trusted('62.105.129.1'),   'outside CIDR';
    ok  $a->_is_trusted('91.198.174.5'),  'exact match';
    ok !$a->_is_trusted('91.198.174.6'),  'near exact not trusted';
    ok !$a->_is_trusted('8.8.8.8'),       'unrelated IP';
}

# ===========================================================================
# 8. _ip_in_cidr — all branches
# ===========================================================================
note '=== 8. _ip_in_cidr ===';
{
    my $a = Email::Abuse::Investigator->new();
    ok  $a->_ip_in_cidr('10.0.0.1',     '10.0.0.0/8'),     '/8 match';
    ok !$a->_ip_in_cidr('11.0.0.1',     '10.0.0.0/8'),     '/8 non-match';
    ok  $a->_ip_in_cidr('192.168.1.1',  '192.168.1.0/24'), '/24 match';
    ok !$a->_ip_in_cidr('192.168.2.1',  '192.168.1.0/24'), '/24 non-match';
    ok  $a->_ip_in_cidr('5.5.5.5',      '5.5.5.5/32'),     '/32 match';
    ok !$a->_ip_in_cidr('5.5.5.6',      '5.5.5.5/32'),     '/32 non-match';
    ok  $a->_ip_in_cidr('1.2.3.4',      '1.2.3.4'),        'exact no-slash match';
    ok !$a->_ip_in_cidr('1.2.3.5',      '1.2.3.4'),        'exact no-slash non-match';
}

# ===========================================================================
# 9. _extract_ip_from_received — all four regex patterns
# ===========================================================================
note '=== 9. _extract_ip_from_received ===';
{
    my $a = Email::Abuse::Investigator->new();

    is $a->_extract_ip_from_received('from host [91.198.174.42] by mx'),
        '91.198.174.42', 'bracket [IP] pattern';

    is $a->_extract_ip_from_received(
        'from mail.x.com (mail.x.com [62.105.128.7]) by mx'),
        '62.105.128.7', 'paren (host [IP]) pattern';

    is $a->_extract_ip_from_received('from relay.example.com 91.198.174.9 by mx'),
        '91.198.174.9', 'from hostname IP pattern';

    is $a->_extract_ip_from_received('HELO spammer; 10.20.30.40'),
        '10.20.30.40', 'bare fallback pattern';

    is $a->_extract_ip_from_received('[999.0.0.1]'),
        undef, 'octet >255 rejected';

    is $a->_extract_ip_from_received('from localhost by mx with LMTP'),
        undef, 'no IP returns undef';

    is $a->_extract_ip_from_received('from host (::1) by mx'),
        undef, 'IPv6 ::1 not matched as IPv4';
}

# ===========================================================================
# 10. originating_ip — all resolution paths
# ===========================================================================
note '=== 10. originating_ip ===';
{
    # single external hop -> medium confidence
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email(make_email(
            received => 'from attacker (attacker [91.198.174.42]) by mx.test'));
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_reverse_dns = sub { 'mail.attacker.example' };
        local *Email::Abuse::Investigator::_whois_ip    = sub { { org => 'Bad ISP', abuse => 'abuse@bad.example' } };
        my $orig = $a->originating_ip();
        is $orig->{ip},         '91.198.174.42',       'single hop ip';
        is $orig->{confidence}, 'medium',              'single hop medium confidence';
        is $orig->{org},        'Bad ISP',             'org populated';
    }

    # two external hops -> high confidence; bottom-most chosen
    {
        my $raw = "Received: from relay1 (relay1 [91.198.174.2]) by relay2\n"
                . "Received: from relay2 (relay2 [91.198.174.1]) by mx\n"
                . "From: x\@example.org\nSubject: s\n\nbody";
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email($raw);
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_reverse_dns = sub { 'relay.example' };
        local *Email::Abuse::Investigator::_whois_ip    = sub { {} };
        my $orig = $a->originating_ip();
        is $orig->{confidence}, 'high',         'two hops -> high confidence';
        is $orig->{ip},         '91.198.174.1', 'bottom-most hop chosen';
    }

    # all Received: IPs private -> X-Originating-IP fallback
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email(make_email(
            received => 'from localhost [127.0.0.1] by mx',
            xoip     => '62.105.128.55',
        ));
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_reverse_dns = sub { 'webmail.example' };
        local *Email::Abuse::Investigator::_whois_ip    = sub { {} };
        my $orig = $a->originating_ip();
        is $orig->{ip},         '62.105.128.55', 'XOIP fallback used';
        is $orig->{confidence}, 'low',          'XOIP confidence low';
    }

    # XOIP is private -> undef
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email(make_email(
            received => 'from localhost [127.0.0.1] by mx',
            xoip     => '192.168.0.1',
        ));
        is $a->originating_ip(), undef, 'private XOIP -> undef';
    }

    # no Received, no XOIP -> undef
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
        is $a->originating_ip(), undef, 'no received + no XOIP -> undef';
    }

    # trusted relay skipped -> undef
    {
        my $a = Email::Abuse::Investigator->new(trusted_relays => ['62.105.128.0/24']);
        $a->parse_email(make_email(
            received => 'from trusted (trusted [62.105.128.1]) by mx'));
        is $a->originating_ip(), undef, 'trusted relay -> undef';
    }

    # result is cached
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email(make_email());
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_reverse_dns = sub { 'r.example' };
        local *Email::Abuse::Investigator::_whois_ip    = sub { {} };
        my $first  = $a->originating_ip();
        my $second = $a->originating_ip();
        is $first, $second, 'originating_ip cached';
    }

    # XOIP with brackets stripped
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email(make_email(
            received => 'from localhost [127.0.0.1] by mx',
            xoip     => '[62.105.128.77]',
        ));
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_reverse_dns = sub { 'webmail.example' };
        local *Email::Abuse::Investigator::_whois_ip    = sub { {} };
        my $orig = $a->originating_ip();
        is $orig->{ip}, '62.105.128.77', 'brackets stripped from XOIP';
    }
}

# ===========================================================================
# 11. _decode_mime_words — B and Q encoding
# ===========================================================================
note '=== 11. _decode_mime_words ===';
{
    my $a = Email::Abuse::Investigator->new();

    my $b64_word = '=?UTF-8?B?' . encode_base64('eharmony Partner', '') . '?=';
    is $a->_decode_mime_words($b64_word), 'eharmony Partner', 'Base64 encoded-word decoded';

    my $qp_word = '=?UTF-8?Q?Ready_to_Find_Someone_Special=3F?=';
    is $a->_decode_mime_words($qp_word),
        'Ready to Find Someone Special?', 'QP encoded-word decoded';

    is $a->_decode_mime_words('plain text'), 'plain text', 'plain string unchanged';
    is $a->_decode_mime_words(undef),        '',           'undef -> empty string';

    # Multiple encoded-words
    my $multi = '=?UTF-8?B?' . encode_base64('Hello', '') . '?= '
              . '=?UTF-8?B?' . encode_base64('World', '') . '?=';
    is $a->_decode_mime_words($multi), 'Hello World', 'multiple encoded-words';

    # Lowercase specifier
    my $lc_b = '=?utf-8?b?' . encode_base64('lower', '') . '?=';
    is $a->_decode_mime_words($lc_b), 'lower', 'lowercase b specifier';

    # non-UTF-8 charset: should not die
    my $latin = '=?iso-8859-1?B?' . encode_base64('caf', '') . '?=';
    ok defined $a->_decode_mime_words($latin), 'non-UTF-8 charset does not die';
}

# ===========================================================================
# 12. _registrable — eTLD+1 heuristic
# ===========================================================================
note '=== 12. _registrable ===';
{
    # Called as package function (not a method)
    is Email::Abuse::Investigator::_registrable('www.example.com'),   'example.com',   'strip one subdomain';
    is Email::Abuse::Investigator::_registrable('example.com'),       'example.com',   'already registrable';
    is Email::Abuse::Investigator::_registrable('foo.example.co.uk'), 'example.co.uk', 'two-part ccTLD';
    is Email::Abuse::Investigator::_registrable('a.b.foo.co.uk'),     'foo.co.uk',     'deeper two-part ccTLD';
    is Email::Abuse::Investigator::_registrable('sub.example.com'),   'example.com',   'three-label .com';
    is Email::Abuse::Investigator::_registrable('no-dot'),            undef,           'no dot -> undef';
    is Email::Abuse::Investigator::_registrable(''),                  undef,           'empty -> undef';
    is Email::Abuse::Investigator::_registrable(undef),               undef,           'undef -> undef';
}

# ===========================================================================
# 13. _country_name
# ===========================================================================
note '=== 13. _country_name ===';
{
    is Email::Abuse::Investigator::_country_name('CN'), 'China',      'CN';
    is Email::Abuse::Investigator::_country_name('RU'), 'Russia',     'RU';
    is Email::Abuse::Investigator::_country_name('NG'), 'Nigeria',    'NG';
    is Email::Abuse::Investigator::_country_name('VN'), 'Vietnam',    'VN';
    is Email::Abuse::Investigator::_country_name('IN'), 'India',      'IN';
    is Email::Abuse::Investigator::_country_name('PK'), 'Pakistan',   'PK';
    is Email::Abuse::Investigator::_country_name('BD'), 'Bangladesh', 'BD';
    is Email::Abuse::Investigator::_country_name('AU'), 'AU',         'unknown cc returned verbatim';
}

# ===========================================================================
# 14. _parse_whois_text — all field branches
# ===========================================================================
note '=== 14. _parse_whois_text ===';
{
    my $a = Email::Abuse::Investigator->new();

    my $r;
    $r = $a->_parse_whois_text("OrgName: ACME Corp\n");
    is $r->{org}, 'ACME Corp', 'OrgName parsed';

    $r = $a->_parse_whois_text("org-name: RIPE Org\n");
    is $r->{org}, 'RIPE Org', 'org-name parsed';

    $r = $a->_parse_whois_text("owner: Owner Corp\n");
    is $r->{org}, 'Owner Corp', 'owner parsed';

    $r = $a->_parse_whois_text("descr: Description\n");
    is $r->{org}, 'Description', 'descr parsed';

    $r = $a->_parse_whois_text("OrgAbuseEmail: abuse\@corp.example\n");
    is $r->{abuse}, 'abuse@corp.example', 'OrgAbuseEmail parsed';

    $r = $a->_parse_whois_text("abuse-mailbox: abuse\@ripe.example\n");
    is $r->{abuse}, 'abuse@ripe.example', 'abuse-mailbox parsed';

    $r = $a->_parse_whois_text("Text with abuse\@fallback.example here\n");
    is $r->{abuse}, 'abuse@fallback.example', 'bare abuse@ fallback';

    $r = $a->_parse_whois_text("country: AU\n");
    is $r->{country}, 'AU', 'country parsed';

    # country must be full-line
    $r = $a->_parse_whois_text("not a country: AU thing\n");
    is $r->{country}, undef, 'inline country not matched';

    $r = $a->_parse_whois_text('');
    is_deeply $r, {}, 'empty input -> empty hash';

    $r = $a->_parse_whois_text(undef);
    is_deeply $r, {}, 'undef input -> empty hash';

    # OrgName wins over descr when both present
    $r = $a->_parse_whois_text("descr: Second\nOrgName: First\n");
    is $r->{org}, 'First', 'OrgName priority over descr';
}

# ===========================================================================
# 15. _parse_date_to_epoch — all format branches
# ===========================================================================
note '=== 15. _parse_date_to_epoch ===';
{
    my $a = Email::Abuse::Investigator->new();

    my $e;
    $e = $a->_parse_date_to_epoch('2020-06-15');
    ok defined($e) && $e > 0, 'YYYY-MM-DD parsed';

    $e = $a->_parse_date_to_epoch('2020-06-15T12:00:00Z');
    ok defined($e) && $e > 0, 'ISO datetime parsed';

    $e = $a->_parse_date_to_epoch('15-Jun-2020');
    ok defined($e) && $e > 0, 'DD-Mon-YYYY parsed';

    $e = $a->_parse_date_to_epoch('06/15/2020');
    ok defined($e) && $e > 0, 'MM/DD/YYYY parsed';

    is $a->_parse_date_to_epoch(undef),       undef, 'undef -> undef';
    is $a->_parse_date_to_epoch('not-a-date'), undef, 'garbage -> undef';

    my $e2020 = $a->_parse_date_to_epoch('2020-01-01');
    my $e2025 = $a->_parse_date_to_epoch('2025-01-01');
    ok $e2025 > $e2020, 'later date has larger epoch';
}

# ===========================================================================
# 16. _domains_from_text
# ===========================================================================
note '=== 16. _domains_from_text ===';
{
    my $a = Email::Abuse::Investigator->new();

    my @d = $a->_domains_from_text('mailto:user@spamsite.example');
    ok scalar(grep { $_ eq 'spamsite.example' } @d), 'mailto domain extracted';

    @d = $a->_domains_from_text('Contact: info@evil.example today');
    ok scalar(grep { $_ eq 'evil.example' } @d), 'bare email domain extracted';

    # Deduplication
    @d = $a->_domains_from_text('mailto:a@dup.example and b@dup.example');
    is scalar(grep { $_ eq 'dup.example' } @d), 1, 'duplicate domain deduplicated';

    # Trailing dot stripped
    @d = $a->_domains_from_text('user@trailing.example.');
    ok scalar(grep { $_ eq 'trailing.example' } @d), 'trailing dot stripped';

    # Two distinct domains
    @d = $a->_domains_from_text('a@one.example and b@two.example');
    is scalar @d, 2, 'two distinct domains';
}

# ===========================================================================
# 17. _extract_http_urls
# ===========================================================================
note '=== 17. _extract_http_urls ===';
{
    my $a = Email::Abuse::Investigator->new();

    my $text = 'Visit https://buy.example.com/path and http://short.ly/abc '
             . 'and again https://buy.example.com/path.';
    my @urls = $a->_extract_http_urls($text);

    ok scalar(grep { $_ eq 'https://buy.example.com/path' } @urls), 'https url extracted';
    ok scalar(grep { $_ =~ qr{http://short\.ly/abc} } @urls),       'http url extracted';

    # Deduplication: _extract_http_urls may return two before stripping normalises them;
    # full deduplication is guaranteed by embedded_urls() via the url_seen hash
    my $b2 = Email::Abuse::Investigator->new();
    $b2->parse_email(make_email(body => 'https://dup.example/page and https://dup.example/page'));
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
    my @deduped = $b2->embedded_urls();
    is scalar(grep { $_->{url} eq 'https://dup.example/page' } @deduped), 1,
        'embedded_urls deduplicates identical URLs';

    # Trailing punctuation stripped
    my @s = $a->_extract_http_urls('Go to https://example.com/page.');
    ok scalar(grep { $_ eq 'https://example.com/page' } @s), 'trailing dot stripped from url';

    # Empty body
    my @e = $a->_extract_http_urls('');
    is scalar @e, 0, 'empty body -> no urls';
}

# ===========================================================================
# 18. embedded_urls — lazy eval and host-level caching
# ===========================================================================
note '=== 18. embedded_urls ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        body => 'Click https://spamhost.example/a and https://spamhost.example/b'));

    no warnings 'redefine';
    my $resolve_count = 0;
    local *Email::Abuse::Investigator::_resolve_host = sub {
        my (undef, $host) = @_;
        return $host if $host =~ /^\d/;
        $resolve_count++;
        return '91.198.174.10';
    };
    local *Email::Abuse::Investigator::_whois_ip = sub {
        { org => 'Spam Host', abuse => 'abuse@spamhost.example' }
    };

    my @urls = $a->embedded_urls();
    is scalar @urls,   2,                  'two distinct paths returned';
    is $resolve_count, 1,                  'DNS resolved once per host';
    is $urls[0]{host}, 'spamhost.example', 'host field correct';
    is $urls[0]{ip},   '91.198.174.10',    'ip field correct';
    is $urls[0]{org},  'Spam Host',        'org field correct';

    # Second call uses cache
    my @urls2 = $a->embedded_urls();
    is $resolve_count, 1, 'no extra DNS on second embedded_urls() call';
}

# ===========================================================================
# 19. mailto_domains — extraction from headers and body
# ===========================================================================
note '=== 19. mailto_domains ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from => 'Spammer <spammer@badactor.example>',
        body => 'Contact info@spamco.example or mailto:sales@spamco.example',
    ));

    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my @doms  = $a->mailto_domains();
    my @names = map { $_->{domain} } @doms;

    ok scalar(grep { $_ eq 'badactor.example' } @names), 'From: domain captured';
    ok scalar(grep { $_ eq 'spamco.example'   } @names), 'body email domain captured';
    ok !scalar(grep { $_ eq 'gmail.com'   } @names), 'gmail.com excluded';
    ok !scalar(grep { $_ eq 'outlook.com' } @names), 'outlook.com excluded';

    # deduplication across sources
    is scalar(grep { $_ eq 'spamco.example' } @names), 1, 'domain deduplicated';
}

# ===========================================================================
# 20. all_domains — union of url hosts and mailto domains
# ===========================================================================
note '=== 20. all_domains ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        body => 'https://webhost.example/page and email info@mailhost.example',
        from => 'x@webhost.example',
    ));

    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my @all = $a->all_domains();
    ok scalar(grep { $_ eq 'webhost.example'  } @all), 'url host in all_domains';
    ok scalar(grep { $_ eq 'mailhost.example' } @all), 'email domain in all_domains';

    # no duplicates
    my %cnt;
    $cnt{$_}++ for @all;
    ok !scalar(grep { $cnt{$_} > 1 } @all), 'no duplicates in all_domains';
}

# ===========================================================================
# 21. _parse_auth_results_cached
# ===========================================================================
note '=== 21. _parse_auth_results_cached ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        auth => 'mx.test; spf=pass; dkim=pass; dmarc=pass; arc=pass'));
    my $auth = $a->_parse_auth_results_cached();
    like $auth->{spf},   qr/^pass/, 'spf pass';
    like $auth->{dkim},  qr/^pass/, 'dkim pass';
    like $auth->{dmarc}, qr/^pass/, 'dmarc pass';
    like $auth->{arc},   qr/^pass/, 'arc pass';

    # cached
    is $a->_parse_auth_results_cached(), $auth, 'result cached';

    # fail values (note: regex captures to semicolon sometimes, use like)
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email(make_email(auth => 'mx.test; spf=fail; dkim=neutral; dmarc=fail'));
    my $auth2 = $b->_parse_auth_results_cached();
    like $auth2->{spf},  qr/^fail/,    'spf fail';
    like $auth2->{dkim}, qr/^neutral/, 'dkim neutral';
    like $auth2->{dmarc},qr/^fail/,   'dmarc fail';
    is   $auth2->{arc},  undef,        'arc absent';

    # no auth header
    my $c = Email::Abuse::Investigator->new();
    $c->parse_email(make_email());
    my $auth3 = $c->_parse_auth_results_cached();
    is $auth3->{spf}, undef, 'no auth-results -> undef';
}

# ===========================================================================
# 22. _provider_abuse_for_host — subdomain stripping
# ===========================================================================
note '=== 22. _provider_abuse_for_host ===';
{
    my $a = Email::Abuse::Investigator->new();

    my $r = $a->_provider_abuse_for_host('gmail.com');
    is $r->{email}, 'abuse@google.com', 'gmail.com exact match';

    $r = $a->_provider_abuse_for_host('mail-ej1.gmail.com');
    is $r->{email}, 'abuse@google.com', 'subdomain of gmail matched';

    $r = $a->_provider_abuse_for_host('a.b.c.gmail.com');
    is $r->{email}, 'abuse@google.com', 'deep subdomain matched';

    $r = $a->_provider_abuse_for_host('unknown.example.org');
    is $r, undef, 'unknown host -> undef';

    $r = $a->_provider_abuse_for_host('cloudflare.com');
    is $r->{email}, 'abuse@cloudflare.com', 'cloudflare matched';

    $r = $a->_provider_abuse_for_host('120-88-161-249.tpgi.com.au');
    is $r->{email}, 'abuse@tpg.com.au', 'tpgi.com.au subdomain matched';
}

# ===========================================================================
# 23. _provider_abuse_for_ip
# ===========================================================================
note '=== 23. _provider_abuse_for_ip ===';
{
    my $a = Email::Abuse::Investigator->new();

    my $r = $a->_provider_abuse_for_ip('209.85.218.67', 'mail-ej1.google.com');
    is $r->{email}, 'abuse@google.com', 'provider from rDNS';

    is $a->_provider_abuse_for_ip('8.8.8.8', undef),              undef, 'no rDNS -> undef';
    is $a->_provider_abuse_for_ip('1.2.3.4', 'unknown.net'),      undef, 'unknown rDNS -> undef';
}

# ===========================================================================
# 24. risk_assessment — comprehensive flag coverage
# ===========================================================================
note '=== 24. risk_assessment ===';

# Inject a pre-built origin and clear url/domain caches to isolate flag logic
sub mk_risk {
    my (%opts) = @_;
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(%opts));
    $a->{_origin}         = $opts{_origin}  if exists $opts{_origin};
    $a->{_urls}           = $opts{_urls}    // [];
    $a->{_mailto_domains} = $opts{_mdoms}   // [];
    return $a;
}

{
    # no_reverse_dns
    {
        my $a = mk_risk(
            _origin => { ip=>'91.198.174.42', rdns=>'(no reverse DNS)',
                         confidence=>'medium', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        my $risk = $a->risk_assessment();
        ok any_flag($risk->{flags}, 'no_reverse_dns'), 'no_reverse_dns flagged';
    }

    # residential_sending_ip — dotted-quad in rDNS
    {
        my $a = mk_risk(
            _origin => { ip=>'120.88.161.249', rdns=>'120-88-161-249.tpgi.com.au',
                         confidence=>'medium', org=>'TPG', abuse=>'abuse@tpg.com.au',
                         note=>'', country=>'AU' },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'residential_sending_ip'),
            'residential_sending_ip (dotted-quad)';
    }

    # residential_sending_ip — dsl keyword
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'customer.dsl.isp.example',
                         confidence=>'medium', org=>'ISP', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'residential_sending_ip'),
            'residential_sending_ip (dsl keyword)';
    }

    # low_confidence_origin
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email(make_email(
            received => 'from localhost [127.0.0.1] by mx',
            xoip     => '62.105.128.1',
        ));
        $a->{_urls}           = [];
        $a->{_mailto_domains} = [];
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_reverse_dns  = sub { 'host.example' };
        local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        ok any_flag($a->risk_assessment()->{flags}, 'low_confidence_origin'),
            'low_confidence_origin flagged';
    }

    # high_spam_country
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.cn',
                         confidence=>'high', org=>'CN ISP', abuse=>'a@b',
                         note=>'', country=>'CN' },
        );
        ok  any_flag($a->risk_assessment()->{flags}, 'high_spam_country'),
            'high_spam_country flagged for CN';
    }

    # non-spam country NOT flagged
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.de',
                         confidence=>'high', org=>'DE ISP', abuse=>'a@b',
                         note=>'', country=>'DE' },
        );
        ok !any_flag($a->risk_assessment()->{flags}, 'high_spam_country'),
            'DE not flagged as high_spam_country';
    }

    # spf_fail
    {
        my $a = mk_risk(
            auth    => 'mx; spf=fail',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'spf_fail'), 'spf_fail flagged';
    }

    # dkim_fail
    {
        my $a = mk_risk(
            auth    => 'mx; spf=pass; dkim=neutral',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'dkim_fail'), 'dkim_fail flagged';
    }

    # dmarc_fail
    {
        my $a = mk_risk(
            auth    => 'mx; spf=pass; dkim=pass; dmarc=fail',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'dmarc_fail'), 'dmarc_fail flagged';
    }

    # display_name_domain_spoof
    {
        my $a = mk_risk(
            from    => '"PayPal Security paypal.com" <attacker@gmail.com>',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'display_name_domain_spoof'),
            'display_name_domain_spoof flagged';
    }

    # free_webmail_sender
    {
        my $a = mk_risk(
            from    => 'Spammer <bad@gmail.com>',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'free_webmail_sender'),
            'free_webmail_sender flagged';
    }

    # reply_to_differs_from_from — different addresses
    {
        my $a = mk_risk(
            from     => 'Legit <legit@example.org>',
            reply_to => 'Harvester <harvest@different.example>',
            _origin  => { ip=>'1.2.3.4', rdns=>'mail.ok',
                          confidence=>'high', org=>'X', abuse=>'a@b',
                          note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'reply_to_differs_from_from'),
            'reply_to_differs_from_from flagged';
    }

    # reply_to same as From — not flagged
    {
        my $a = mk_risk(
            from     => 'Legit <legit@example.org>',
            reply_to => 'Also Legit <legit@example.org>',
            _origin  => { ip=>'1.2.3.4', rdns=>'mail.ok',
                          confidence=>'high', org=>'X', abuse=>'a@b',
                          note=>'', country=>undef },
        );
        ok !any_flag($a->risk_assessment()->{flags}, 'reply_to_differs_from_from'),
            'same reply-to not flagged';
    }

    # undisclosed_recipients — explicit header value
    {
        my $a = mk_risk(
            to      => 'undisclosed-recipients:;',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'undisclosed_recipients'),
            'undisclosed_recipients flagged (explicit header)';
    }

    # undisclosed_recipients — missing To: header
    {
        my $a = Email::Abuse::Investigator->new();
        $a->parse_email("From: x\@y.com\nSubject: s\n\nbody");
        $a->{_origin}         = { ip=>'1.2.3.4', rdns=>'mail.ok',
                                  confidence=>'high', org=>'X', abuse=>'a@b',
                                  note=>'', country=>undef };
        $a->{_urls}           = [];
        $a->{_mailto_domains} = [];
        ok any_flag($a->risk_assessment()->{flags}, 'undisclosed_recipients'),
            'undisclosed_recipients flagged (missing To:)';
    }

    # encoded_subject
    {
        my $enc = '=?UTF-8?B?' . encode_base64('Secret Subject', '') . '?=';
        my $a = mk_risk(
            subject => $enc,
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        ok any_flag($a->risk_assessment()->{flags}, 'encoded_subject'),
            'encoded_subject flagged';
    }

    # url_shortener
    {
        my $a = mk_risk(
            body    => 'Click https://bit.ly/abc123 now',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _urls   => [{
                url   => 'https://bit.ly/abc123',
                host  => 'bit.ly',
                ip    => '67.199.248.10',
                org   => 'Bit.ly',
                abuse => '(unknown)',
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'url_shortener'),
            'url_shortener flagged';
    }

    # url_shortener — www prefix stripped
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _urls   => [{
                url   => 'https://www.bit.ly/xyz',
                host  => 'www.bit.ly',
                ip    => '67.199.248.10',
                org   => 'Bit.ly',
                abuse => '(unknown)',
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'url_shortener'),
            'www.bit.ly triggers url_shortener';
    }

    # http_not_https
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _urls   => [{
                url   => 'http://plain.example/page',
                host  => 'plain.example',
                ip    => '1.2.3.4',
                org   => 'Plain Host',
                abuse => '(unknown)',
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'http_not_https'),
            'http_not_https flagged';
    }

    # recently_registered_domain
    {
        my $recent = strftime('%Y-%m-%d', gmtime(time() - 10 * 86400));
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _mdoms  => [{
                domain              => 'newdomain.example',
                source              => 'body',
                recently_registered => 1,
                registered          => $recent,
                expires             => '2099-01-01',
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'recently_registered_domain'),
            'recently_registered_domain flagged';
    }

    # domain_expires_soon
    {
        my $soon = strftime('%Y-%m-%d', gmtime(time() + 15 * 86400));
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _mdoms  => [{
                domain              => 'throwaway.example',
                source              => 'body',
                recently_registered => 0,
                registered          => '2020-01-01',
                expires             => $soon,
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'domain_expires_soon'),
            'domain_expires_soon flagged';
    }

    # domain_expired
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _mdoms  => [{
                domain              => 'expired.example',
                source              => 'body',
                recently_registered => 0,
                registered          => '2020-01-01',
                expires             => '2021-01-01',
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'domain_expired'),
            'domain_expired flagged';
    }

    # lookalike_domain
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _mdoms  => [{
                domain              => 'paypal-security.example',
                source              => 'body',
                recently_registered => 0,
            }],
        );
        ok any_flag($a->risk_assessment()->{flags}, 'lookalike_domain'),
            'lookalike_domain flagged (paypal-)';
    }

    # Real paypal.com NOT flagged
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
            _mdoms  => [{
                domain              => 'paypal.com',
                source              => 'body',
                recently_registered => 0,
            }],
        );
        ok !any_flag($a->risk_assessment()->{flags}, 'lookalike_domain'),
            'paypal.com not flagged as lookalike';
    }

    # Score thresholds: clean email -> INFO
    {
        my $a = mk_risk(
            from    => 'Clean <clean@verifiedcorp.example>',
            to      => 'user@bandsman.co.uk',
            auth    => 'mx; spf=pass; dkim=pass; dmarc=pass',
            _origin => { ip=>'1.2.3.4', rdns=>'mail.verifiedcorp.example',
                         confidence=>'high', org=>'Corp', abuse=>'a@b',
                         note=>'', country=>'GB' },
        );
        my $risk = $a->risk_assessment();
        is $risk->{level}, 'INFO', 'clean email -> INFO level';
    }

    # risk_assessment result cached
    {
        my $a = mk_risk(
            _origin => { ip=>'1.2.3.4', rdns=>'mail.ok',
                         confidence=>'high', org=>'X', abuse=>'a@b',
                         note=>'', country=>undef },
        );
        my $r1 = $a->risk_assessment();
        my $r2 = $a->risk_assessment();
        is $r2, $r1, 'risk_assessment result cached';
    }
}

# ===========================================================================
# 25. abuse_contacts — all role types, deduplication
# ===========================================================================
note '=== 25. abuse_contacts ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from        => 'Spammer <spammer@gmail.com>',
        return_path => '<spammer@gmail.com>',
    ));
    $a->{_origin} = {
        ip    => '209.85.218.67',  rdns => 'mail-ej1-f67.google.com',
        org   => 'Google LLC',     abuse => 'network-abuse@google.com',
        confidence => 'medium',    note => 'First hop', country => undef,
    };
    $a->{_urls} = [{
        url   => 'https://cloudflare.example/page',
        host  => 'cloudflare.example',
        ip    => '104.21.0.1',
        org   => 'CLOUDFLARENET',
        abuse => 'abuse@cloudflare.com',
        country => 'US',
    }];
    $a->{_mailto_domains} = [{
        domain           => 'cloudflare.example',
        source           => 'body',
        web_ip           => '104.21.0.1',
        web_org          => 'CLOUDFLARENET',
        web_abuse        => 'abuse@cloudflare.com',
        mx_host          => 'aspmx.google.com',
        mx_ip            => '209.85.218.26',
        mx_org           => 'Google LLC',
        mx_abuse         => 'network-abuse@google.com',
        ns_host          => 'ns1.cloudflare.com',
        ns_ip            => '173.245.58.1',
        ns_org           => 'CLOUDFLARENET',
        ns_abuse         => 'abuse@cloudflare.com',
        registrar        => 'GoDaddy',
        registrar_abuse  => 'abuse@godaddy.com',
    }];

    my @contacts = $a->abuse_contacts();
    ok @contacts > 0, 'contacts returned';

    ok any_addr(\@contacts, 'abuse@google.com'),     'google abuse contact present';
    ok any_addr(\@contacts, 'abuse@cloudflare.com'), 'cloudflare abuse contact present';
    ok any_addr(\@contacts, 'abuse@godaddy.com'),    'godaddy registrar abuse present';

    # google.com not duplicated even though it appears as XOIP, MX, From:
    is scalar(grep { lc($_->{address}) eq 'abuse@google.com' } @contacts),
       1, 'abuse@google.com not duplicated';

    # Every contact has required fields
    for my $c (@contacts) {
        ok defined $c->{role},    "contact role defined ($c->{address})";
        ok defined $c->{address}, 'contact address defined';
        ok defined $c->{via},     "contact via defined ($c->{address})";
        ok $c->{address} =~ /\@/, 'contact address contains @';
    }
}

{
    # No data -> empty contacts
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(received => 'from localhost [127.0.0.1] by mx'));
    $a->{_origin}         = undef;
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my @contacts = $a->abuse_contacts();
    is scalar @contacts, 0, 'no data -> empty contacts';
}

{
    # abuse = '(unknown)' not added
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());
    $a->{_origin} = {
        ip=>'1.2.3.4', rdns=>'unknown.rdns.example',
        org=>'X', abuse=>'(unknown)',
        confidence=>'medium', note=>'', country=>undef,
    };
    $a->{_urls}           = [];
    $a->{_mailto_domains} = [];
    my @contacts = $a->abuse_contacts();
    ok !any_addr(\@contacts, '(unknown)'), '(unknown) not added as contact';
}

# ===========================================================================
# 26. abuse_report_text
# ===========================================================================
note '=== 26. abuse_report_text ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from     => 'Spammer <spammer@gmail.com>',
        subject  => 'Buy now',
        body     => 'Visit https://spamsite.example/buy',
        received => 'from attacker (attacker [91.198.174.42]) by mx',
    ));
    $a->{_origin} = {
        ip => '91.198.174.42', rdns => 'dial.residential.isp.example',
        org => 'Bad ISP', abuse => 'abuse@bad-isp.example',
        confidence => 'high', note => 'First hop', country => 'NG',
    };
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'Spam Host', abuse=>'abuse@spam.example' } };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $text = $a->abuse_report_text();
    like $text, qr/automated abuse report/i,          'report intro present';
    like $text, qr/RISK LEVEL/,                       'RISK LEVEL present';
    like $text, qr/ORIGINATING IP.*91\.198\.174\.42/s,'originating IP present';
    like $text, qr/ORIGINAL MESSAGE HEADERS/,         'headers section present';
    like $text, qr/from:/i,                           'from header included';

    # No contacts branch (all unknown)
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email(make_email());
    $b->{_origin}         = { ip=>'1.2.3.4', rdns=>'mail.ok',
                              confidence=>'high', org=>'X', abuse=>'(unknown)',
                              note=>'', country=>undef };
    $b->{_urls}           = [];
    $b->{_mailto_domains} = [];
    my $text2 = $b->abuse_report_text();
    like $text2, qr/RISK LEVEL/, 'report generated even without contacts';
}

# ===========================================================================
# 27. report() — all sections and branches
# ===========================================================================
note '=== 27. report() ===';
{
    # Full report with encoded headers, shortener, multiple URLs
    my $enc_subj = '=?UTF-8?B?' . encode_base64('Ready to Find Love', '') . '?=';
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email(
        from     => 'Spammer <spammer@gmail.com>',
        subject  => $enc_subj,
        body     => 'https://bit.ly/spam and http://spamsite.example/buy',
        received => 'from spammer (spammer [120.88.161.249]) by mx',
        auth     => 'mx; spf=fail; dkim=fail',
    ));
    $a->{_origin} = {
        ip => '120.88.161.249', rdns => '120-88-161-249.tpgi.com.au',
        org => 'TPG Internet', abuse => 'abuse@tpg.com.au',
        confidence => 'medium', note => 'First hop', country => 'AU',
    };
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'Test Org', abuse=>'abuse@testorg.example', country=>'US' } };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $report = $a->report();
    like $report, qr/Email::Abuse::Investigator Report/,  'report title';
    like $report, qr/RISK ASSESSMENT/,              'risk section';
    like $report, qr/ORIGINATING HOST/,             'originating host section';
    like $report, qr/120\.88\.161\.249/,            'originating IP';
    like $report, qr/EMBEDDED HTTP\/HTTPS URLs/,    'url section';
    like $report, qr/URL SHORTENER/,               'shortener warning';
    like $report, qr/CONTACT \/ REPLY-TO DOMAINS/, 'domains section';
    like $report, qr/WHERE TO SEND ABUSE REPORTS/, 'contacts section';
    like $report, qr/Ready to Find Love/,           'encoded subject decoded';

    # No-origin path
    my $b = Email::Abuse::Investigator->new();
    $b->parse_email("From: x\@y.com\nSubject: s\n\nbody");
    $b->{_origin}         = undef;
    $b->{_urls}           = [];
    $b->{_mailto_domains} = [];
    my $r2 = $b->report();
    like $r2, qr/could not determine originating IP/, 'no-origin message';
    like $r2, qr/none found/,                         'no-urls message';

    # Multiple URLs same host -> grouped
    my $c = Email::Abuse::Investigator->new();
    $c->parse_email(make_email(body => 'https://multi.example/a and https://multi.example/b'));
    $c->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok',
                      confidence=>'high', org=>'X', abuse=>'a@b',
                      note=>'', country=>undef };
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { '1.2.3.4' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'T', abuse=>'a@b' } };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    my $r3 = $c->report();
    like $r3, qr/URLs \(2\)/, 'multiple URLs grouped under host';

    # Contact domain with all sub-sections present
    my $d = Email::Abuse::Investigator->new();
    $d->parse_email(make_email(from => 'x@example-domain.tld'));
    $d->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.ok',
                      confidence=>'high', org=>'X', abuse=>'a@b',
                      note=>'', country=>undef };
    $d->{_urls}           = [];
    $d->{_mailto_domains} = [{
        domain              => 'example-domain.tld',
        source              => 'From: header',
        recently_registered => 1,
        registered          => '2025-12-01',
        expires             => '2026-12-01',
        registrar           => 'NameCheap',
        registrar_abuse     => 'abuse@namecheap.com',
        web_ip              => '5.5.5.5',
        web_org             => 'Host Co',
        web_abuse           => 'abuse@hostco.example',
        mx_host             => 'mail.example-domain.tld',
        mx_ip               => '6.6.6.6',
        mx_org              => 'Mail Co',
        mx_abuse            => 'abuse@mailco.example',
        ns_host             => 'ns1.example-domain.tld',
        ns_ip               => '7.7.7.7',
        ns_org              => 'NS Co',
        ns_abuse            => 'abuse@nsco.example',
    }];
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    my $r4 = $d->report();
    like $r4, qr/RECENTLY REGISTERED/,      'recently_registered warning present';
    like $r4, qr/Web host IP.*5\.5\.5\.5/s, 'web host IP present';
    like $r4, qr/MX host.*mail\.example/s,  'MX host present';
    like $r4, qr/NS host.*ns1\.example/s,   'NS host present';
    like $r4, qr/Reg\. abuse.*namecheap/si, 'registrar abuse present';

    # No abuse contacts path — stub ALL network calls so no contact slips through
    {
        my $e2 = Email::Abuse::Investigator->new();
        $e2->parse_email(make_email(received => 'from localhost [127.0.0.1] by mx'));
        $e2->{_origin}         = undef;
        $e2->{_urls}           = [];
        $e2->{_mailto_domains} = [];
        no warnings 'redefine';
        local *Email::Abuse::Investigator::_resolve_host = sub { undef };
        local *Email::Abuse::Investigator::_reverse_dns  = sub { undef };
        local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
        local *Email::Abuse::Investigator::_domain_whois = sub { undef };
        local *Email::Abuse::Investigator::_rdap_lookup  = sub { {} };
        local *Email::Abuse::Investigator::_raw_whois    = sub { undef };
        my $r5 = $e2->report();
        like $r5, qr/no abuse contacts could be determined/, 'no-contacts message';
    }

    # Risk with no flags -> 'no specific red flags detected'
    my $f = Email::Abuse::Investigator->new();
    $f->parse_email(make_email(
        from    => 'Clean <clean@verifiedcorp.example>',
        to      => 'user@bandsman.co.uk',
        auth    => 'mx; spf=pass; dkim=pass; dmarc=pass',
    ));
    $f->{_origin} = { ip=>'1.2.3.4', rdns=>'mail.verifiedcorp.example',
                      confidence=>'high', org=>'Corp', abuse=>'a@b',
                      note=>'', country=>'GB' };
    $f->{_urls}           = [];
    $f->{_mailto_domains} = [];
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    my $r6 = $f->report();
    like $r6, qr/no specific red flags detected/, 'no-flags message in report';
}

# ===========================================================================
# 28. _analyse_domain — WHOIS field parsing and caching
# ===========================================================================
note '=== 28. _analyse_domain ===';
{
    my $a = Email::Abuse::Investigator->new();
    $a->parse_email(make_email());

    my $whois = <<'WHOIS';
Registrar: Dodgy Registrar Inc
Registrar Abuse Contact Email: abuse@dodgy-reg.example
Creation Date: 2025-11-15T00:00:00Z
Registry Expiry Date: 2026-11-15T00:00:00Z
WHOIS

    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { '5.5.5.5' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'Host Co', abuse=>'abuse@hostco.example' } };
    local *Email::Abuse::Investigator::_domain_whois = sub { $whois };

    my $info = $a->_analyse_domain('newdomain.example');
    is $info->{web_ip},          '5.5.5.5',                'web_ip from A record';
    is $info->{web_org},         'Host Co',                'web_org populated';
    is $info->{registrar},       'Dodgy Registrar Inc',    'registrar parsed';
    is $info->{registrar_abuse}, 'abuse@dodgy-reg.example','registrar_abuse parsed';
    like $info->{registered},    qr/2025-11-15/,           'registered date';
    like $info->{expires},       qr/2026-11-15/,           'expiry date';
    is   $info->{recently_registered}, 1,                  'recently_registered flagged';

    # cached on second call — _resolve_host must not be called again
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { die 'should not be called' };
    my $info2 = $a->_analyse_domain('newdomain.example');
    is $info2, $info, '_analyse_domain cached';

    # No WHOIS -> no registrar fields
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };
    my $info3 = $a->_analyse_domain('nowhois.example');
    is $info3->{registrar}, undef, 'no WHOIS -> no registrar';

    # Old domain -> not recently_registered
    my $old = "Creation Date: 2010-01-01\nRegistry Expiry Date: 2099-01-01\n";
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_domain_whois = sub { $old };
    my $info4 = $a->_analyse_domain('oldomain.example');
    ok !$info4->{recently_registered}, 'old domain not recently_registered';

    # Alternative date patterns
    my $alt = "Created On: 2025-10-01\npaid-till: 2026-10-01\n";
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_domain_whois = sub { $alt };
    my $info5 = $a->_analyse_domain('altdates.example');
    like $info5->{registered}, qr/2025-10-01/, 'Created On: pattern';
    like $info5->{expires},    qr/2026-10-01/, 'paid-till: pattern';

    # Abuse Contact Email alternative
    my $altab = "Abuse Contact Email: abuse\@altabuse.example\n"
              . "Creation Date: 2010-01-01\nRegistry Expiry Date: 2099-01-01\n";
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_domain_whois = sub { $altab };
    my $info6 = $a->_analyse_domain('altabuse.example');
    is $info6->{registrar_abuse}, 'abuse@altabuse.example', 'Abuse Contact Email pattern';
}

# ===========================================================================
# 29. _whois_ip — RDAP then raw WHOIS fallback branches
# ===========================================================================
note '=== 29. _whois_ip fallback ===';
{
    my $a = Email::Abuse::Investigator->new();

    # RDAP returns no org -> raw WHOIS fallback with referral
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_rdap_lookup = sub { {} };
    local *Email::Abuse::Investigator::_raw_whois   = sub {
        my (undef, undef, $server) = @_;
        return "whois: whois.arin.net\n" if $server eq 'whois.iana.org';
        return "OrgName: Fallback Corp\nOrgAbuseEmail: abuse\@fallback.example\n";
    };
    my $r1 = $a->_whois_ip('8.8.8.8');
    is $r1->{org},   'Fallback Corp',          'fallback org';
    is $r1->{abuse}, 'abuse@fallback.example', 'fallback abuse';

    # No IANA response -> empty result
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_rdap_lookup = sub { {} };
    local *Email::Abuse::Investigator::_raw_whois   = sub { undef };
    my $r2 = $a->_whois_ip('8.8.8.8');
    is_deeply $r2, {}, 'no whois at all -> empty result';

    # IANA response without whois: line -> parse IANA text directly
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_rdap_lookup = sub { {} };
    my $calls = 0;
    local *Email::Abuse::Investigator::_raw_whois = sub {
        $calls++;
        return $calls == 1 ? "OrgName: IANA Direct\n" : undef;
    };
    my $r3 = $a->_whois_ip('8.8.8.8');
    is $r3->{org}, 'IANA Direct', 'IANA text parsed when no referral';
}

# ===========================================================================
# 30. _domain_whois — referral chain
# ===========================================================================
note '=== 30. _domain_whois ===';
{
    my $a = Email::Abuse::Investigator->new();

    # Two-hop: IANA -> registrar
    no warnings 'redefine';
    my $calls = 0;
    local *Email::Abuse::Investigator::_raw_whois = sub {
        my (undef, undef, $server) = @_;
        $calls++;
        return $server eq 'whois.iana.org'
            ? "whois: whois.verisign-grs.com\n"
            : "Registrar: GoDaddy\nCreation Date: 2020-01-01\n";
    };
    my $result = $a->_domain_whois('example.com');
    like $result, qr/GoDaddy/, 'domain whois referral followed';
    is $calls, 2, 'exactly 2 WHOIS queries';

    # No IANA response -> undef
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_raw_whois = sub { undef };
    is $a->_domain_whois('nope.example'), undef, 'no IANA -> undef';

    # IANA response without whois: line -> undef
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_raw_whois = sub { "% no referral\n" };
    is $a->_domain_whois('noreferral.example'), undef, 'no whois: line -> undef';
}

# ===========================================================================
# 31. _debug — verbose on/off
# ===========================================================================
note '=== 31. _debug ===';
{
    # verbose=1 -> prints to STDERR
    my $a = Email::Abuse::Investigator->new(verbose => 1);
    my $stderr = '';
    open my $save_err, '>&', \*STDERR or die $!;
    close STDERR;
    open STDERR, '>>', \$stderr or die $!;
    $a->_debug('test debug message');
    close STDERR;
    open STDERR, '>&', $save_err or die $!;
    like $stderr, qr/test debug message/, 'verbose=1 prints to STDERR';

    # verbose=0 -> silent
    my $b = Email::Abuse::Investigator->new(verbose => 0);
    my $silent = '';
    open $save_err, '>&', \*STDERR or die $!;
    close STDERR;
    open STDERR, '>>', \$silent or die $!;
    $b->_debug('silent message');
    close STDERR;
    open STDERR, '>&', $save_err or die $!;
    unlike $silent, qr/silent message/, 'verbose=0 is silent';
}

# ===========================================================================
# 32. _enrich_ip — all fields
# ===========================================================================
note '=== 32. _enrich_ip ===';
{
    my $a = Email::Abuse::Investigator->new();

    no warnings 'redefine';
    local *Email::Abuse::Investigator::_reverse_dns = sub { 'rdns.example' };
    local *Email::Abuse::Investigator::_whois_ip    = sub { { org=>'TestOrg', abuse=>'abuse@testorg.example', country=>'AU' } };

    my $r = $a->_enrich_ip('91.198.174.1', 'high', 'test note');
    is $r->{ip},         '91.198.174.1',         'ip field';
    is $r->{rdns},       'rdns.example',          'rdns field';
    is $r->{org},        'TestOrg',               'org field';
    is $r->{abuse},      'abuse@testorg.example', 'abuse field';
    is $r->{country},    'AU',                    'country field';
    is $r->{confidence}, 'high',                  'confidence field';
    is $r->{note},       'test note',             'note field';

    # No rDNS -> default string; no org/abuse -> defaults
    no warnings 'redefine';
    local *Email::Abuse::Investigator::_reverse_dns = sub { undef };
    local *Email::Abuse::Investigator::_whois_ip    = sub { {} };
    my $r2 = $a->_enrich_ip('1.2.3.4', 'low', '');
    is $r2->{rdns},  '(no reverse DNS)', 'no rDNS -> default';
    is $r2->{org},   '(unknown)',        'no org -> (unknown)';
    is $r2->{abuse}, '(unknown)',        'no abuse -> (unknown)';
}

# ===========================================================================
# 33. Real-world email: SM Investments spam
# ===========================================================================
note '=== 33. SM Investments spam ===';
{
    my $sm = <<'EMAIL';
Return-Path: <denatabradley01@gmail.com>
Received: from mail-ej1-f67.google.com (mail-ej1-f67.google.com [209.85.218.67])
 by mail.bandsman.co.uk (8.14.7) with ESMTP
Authentication-Results: mx.google.com; spf=pass; dkim=pass header.d=gmail.com
From: SM Investments <denatabradley01@gmail.com>
Subject: Invitation to Register as a Vendor
To: undisclosed-recipients:;
Content-Type: multipart/alternative; boundary="BOUND001"
Message-ID: <test@mail.gmail.com>
Date: Sun, 22 Mar 2026 17:23:54 -0700

--BOUND001
Content-Type: text/plain; charset="UTF-8"

Dear Sir/Madam, contact us at Onboarding@sminvestmentsupplychain.com

--BOUND001
Content-Type: text/html; charset="UTF-8"

<a href="mailto:Onboarding@sminvestmentsupplychain.com">Contact us</a>

--BOUND001--
EMAIL

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email($sm);

    no warnings 'redefine';
    local *Email::Abuse::Investigator::_reverse_dns  = sub { 'mail-ej1-f67.google.com' };
    local *Email::Abuse::Investigator::_resolve_host = sub { undef };
    local *Email::Abuse::Investigator::_whois_ip     = sub { {} };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    my $orig = $a->originating_ip();
    is $orig->{ip}, '209.85.218.67', 'SM Investments: origin IP';

    my @urls = $a->embedded_urls();
    is scalar @urls, 0, 'SM Investments: no HTTP URLs';

    my @mdoms = $a->mailto_domains();
    my @names  = map { $_->{domain} } @mdoms;
    ok scalar(grep { $_ eq 'sminvestmentsupplychain.com' } @names),
        'SM Investments: sminvestmentsupplychain.com found';

    my $risk = $a->risk_assessment();
    ok any_flag($risk->{flags}, 'undisclosed_recipients'),
        'SM Investments: undisclosed_recipients flagged';
}

# ===========================================================================
# 34. Real-world email: firmluminary.com spam
# ===========================================================================
note '=== 34. firmluminary.com spam ===';
{
    my $enc_from = '=?UTF-8?B?' . encode_base64('eharmony Partner', '') . '?=';
    my $enc_subj = '=?UTF-8?B?' . encode_base64('Ready to Find Someone Special?', '') . '?=';

    my $firm = <<"EMAIL";
Received: from 120-88-161-249.tpgi.com.au (120.88.161.249) by SJ1PEPF000023CB
Authentication-Results: spf=pass smtp.mailfrom=firmluminary.com; dkim=pass header.d=firmluminary.com; dmarc=pass
DKIM-Signature: v=1; d=firmluminary.com; s=default; b=xxx
From: "$enc_from" <peacelight\@firmluminary.com>
Subject: $enc_subj
To: victim\@test.example
Return-Path: peacelight\@firmluminary.com
Content-Type: text/html; charset="utf-8"
Content-Transfer-Encoding: quoted-printable
Message-ID: <firm001\@firmluminary.com>
Date: Mon, 23 Mar 2026 00:12:04 +0000

<a href=3D"https://www.firmluminary.com/c/link1">Click</a>
<a href=3D"https://www.firmluminary.com/u/unsub">Unsubscribe</a>
<img src=3D"https://www.firmluminary.com/o/track">
EMAIL

    my $a = Email::Abuse::Investigator->new();
    $a->parse_email($firm);

    no warnings 'redefine';
    local *Email::Abuse::Investigator::_reverse_dns  = sub { '120-88-161-249.tpgi.com.au' };
    local *Email::Abuse::Investigator::_resolve_host = sub { '104.21.13.60' };
    local *Email::Abuse::Investigator::_whois_ip     = sub { { org=>'CLOUDFLARENET', abuse=>'abuse@cloudflare.com', country=>'US' } };
    local *Email::Abuse::Investigator::_domain_whois = sub { undef };

    # Origin
    my $orig = $a->originating_ip();
    is $orig->{ip}, '120.88.161.249', 'firmluminary: origin IP';
    like $orig->{rdns}, qr/tpgi\.com\.au/, 'firmluminary: rDNS';

    # URLs on single host
    my @urls = $a->embedded_urls();
    ok @urls >= 2, 'firmluminary: multiple URLs found';
    ok !scalar(grep { $_->{host} ne 'www.firmluminary.com' } @urls),
        'firmluminary: all URLs on www.firmluminary.com';

    # firmluminary.com in contact domains
    my @mdoms = $a->mailto_domains();
    my @names  = map { $_->{domain} } @mdoms;
    ok scalar(grep { $_ eq 'firmluminary.com' } @names),
        'firmluminary: firmluminary.com found as domain';

    # Decoded From/Subject
    my $dfrom = $a->_decode_mime_words($a->_header_value('from') // '');
    like $dfrom, qr/eharmony Partner/, 'firmluminary: From decoded';

    my $dsubj = $a->_decode_mime_words($a->_header_value('subject') // '');
    like $dsubj, qr/Ready to Find Someone Special/, 'firmluminary: Subject decoded';

    # Risk: residential IP
    my $risk = $a->risk_assessment();
    ok any_flag($risk->{flags}, 'residential_sending_ip'),
        'firmluminary: residential_sending_ip flagged';

    # Abuse contacts: TPG and Cloudflare
    my @contacts = $a->abuse_contacts();
    ok any_addr(\@contacts, 'abuse@tpg.com.au'),     'firmluminary: TPG abuse contact';
    ok any_addr(\@contacts, 'abuse@cloudflare.com'), 'firmluminary: Cloudflare abuse contact';

    # Full report
    my $report = $a->report();
    like $report, qr/eharmony Partner/,    'firmluminary: decoded From in report';
    like $report, qr/120\.88\.161\.249/,   'firmluminary: IP in report';
}

done_testing();
