# NAME

Email::Abuse::Investigator - Analyse spam email to identify originating hosts,
hosted URLs, and suspicious domains

# VERSION

Version 0.12

# SYNOPSIS

    use Email::Abuse::Investigator;

    my $analyser = Email::Abuse::Investigator->new( verbose => 1 );
    $analyser->parse_email($raw_email_text);

    # Originating IP and its network owner
    my $origin = $analyser->originating_ip();

    # All HTTP/HTTPS URLs found in the body
    my @urls  = $analyser->embedded_urls();

    # All domains extracted from mailto: links and bare addresses in the body
    my @mdoms = $analyser->mailto_domains();

    # All domains mentioned anywhere (union of the above)
    my @adoms = $analyser->all_domains();

    # Full printable report
    print $analyser->report();

# DESCRIPTION

`Email::Abuse::Investigator` examines the raw source of a spam/phishing e-mail
and answers the questions manual abuse investigators ask:

- 1. Where did the message really come from?

    Walks the `Received:` chain, skips private/trusted IPs, and identifies the
    first external hop.  Enriches with rDNS, WHOIS/RDAP org name and abuse
    contact.  Both IPv4 and IPv6 addresses are supported.

- 2. Who hosts the advertised web sites?

    Extracts every `http://` and `https://` URL from both plain-text and HTML
    parts, resolves each hostname to an IP, and looks up the network owner.

- 3. Who owns the reply-to / contact domains?

    Extracts domains from `mailto:` links, bare e-mail addresses in the body,
    the `From:`/`Reply-To:`/`Sender:`/`Return-Path:` headers, `DKIM-Signature: d=`
    (the signing domain), `List-Unsubscribe:` (the ESP or bulk-sender domain), and the
    `Message-ID:` domain.  For each unique domain it gathers:

    - Domain registrar and registrant (WHOIS)
    - Web-hosting IP and network owner (A record -> RDAP)
    - Mail-hosting IP and network owner (MX record -> RDAP)
    - DNS nameserver operator (NS record -> RDAP)
    - Whether the domain was recently registered (potential flag)

# METHODS

## new( %options )

Constructs and returns a new `Email::Abuse::Investigator` analyser object.  The
object is stateless until `parse_email()` is called; all analysis results
are stored on the object and retrieved via the public accessor methods
documented below.

A single object may be reused for multiple emails by calling `parse_email()`
again: all per-message cached state from the previous message is discarded
automatically.  Cross-message IP and domain lookup results are retained
in a shared CHI cache (if `CHI` is installed) to avoid redundant network
queries across messages processed in the same process.

### Usage

    # Minimal -- all options take safe defaults
    my $analyser = Email::Abuse::Investigator->new();

    # With options
    my $analyser = Email::Abuse::Investigator->new(
        timeout        => 15,
        trusted_relays => ['203.0.113.0/24', '10.0.0.0/8'],
        verbose        => 0,
    );

    $analyser->parse_email($raw_rfc2822_text);
    my $origin   = $analyser->originating_ip();
    my @urls     = $analyser->embedded_urls();
    my @domains  = $analyser->mailto_domains();
    my $risk     = $analyser->risk_assessment();
    my @contacts = $analyser->abuse_contacts();
    print $analyser->report();

### Arguments

All arguments are optional named parameters passed as a flat key-value list.

- `timeout` (integer, default 10)

    Maximum seconds to wait for any single network operation.  Set to 0 to
    disable timeouts (not recommended for production use).

- `trusted_relays` (arrayref of strings, default \[\])

    IP addresses or CIDR blocks to skip during Received: chain analysis.
    Each element may be an exact IPv4 address (`'192.0.2.1'`) or a CIDR
    block (`'192.0.2.0/24'`).

- `verbose` (boolean, default 0)

    When true, diagnostic messages are written to STDERR.

### Returns

A blessed `Email::Abuse::Investigator` object.  No network I/O is performed
during construction.

### Side Effects

If `CHI` is installed, a shared in-memory cache is initialised (or
re-used if a cache was already created by a prior call to `new()`).
This cache persists for the lifetime of the process.

### Notes

- Unknown option keys are silently ignored.
- The object is not thread-safe.  Use a separate object per thread.
- WHOIS read timeouts use `IO::Select` rather than `alarm()`, so they
work correctly on Windows and in threaded Perl interpreters.

### API Specification

#### Input

    {
        timeout => {
            type     => 'integer',
            optional => 1,
            min      => 0,
            default  => 10,
        },
        trusted_relays => {
            type          => 'arrayref',
            element_type  => 'string',
            optional      => 1,
            default       => [],
        },
        verbose => {
            type     => 'boolean',
            optional => 1,
            default  => 0,
        },
    }

#### Output

    {
        type => 'object',
        isa  => 'Email::Abuse::Investigator',
    }

## parse\_email( $text )

Feeds a raw RFC 2822 email message to the analyser and prepares it for
subsequent interrogation.  This is the only method that must be called
before any other public method.

If the same object is used for a second message, calling `parse_email()`
again completely replaces all per-message state from the first message.
The cross-message CHI cache is **not** flushed; IP and domain lookups
cached from prior messages are retained.

### Usage

    my $raw = do { local $/; <STDIN> };
    $analyser->parse_email($raw);

    # Scalar reference (avoids copying large messages)
    $analyser->parse_email(\$raw);

    # Chained
    my $analyser = Email::Abuse::Investigator->new()->parse_email($raw);

### Arguments

- `$text` (string or string reference, required)

    Complete raw RFC 2822 email message, including all headers and the body.
    Both LF-only and CRLF line endings are accepted.

### Returns

The object itself (`$self`), enabling method chaining.

### Side Effects

Parses headers, decodes the body (quoted-printable, base64, multipart),
extracts sending-software fingerprints, and populates per-hop tracking
data.  All previously computed lazy results are discarded.

### Notes

- If `$text` is empty or contains no header/body separator, all public
methods will return empty/safe values.
- Decoding errors in base64 or quoted-printable payloads are silenced; raw
bytes are used in place of correct output to prevent exceptions.

### API Specification

#### Input

    [
        {
            type => [ 'string', 'stringref' ]
        },
    ]

#### Output

    {
        type => 'object',
        isa  => 'Email::Abuse::Investigator',
    }

## originating\_ip()

Identifies the IP address of the machine that originally injected the
message into the mail system by walking the `Received:` chain, skipping
private/trusted hops, and enriching the first external hop with rDNS,
WHOIS/RDAP organisation name, abuse contact, and country code.

Both IPv4 and IPv6 addresses are extracted and evaluated.

The result is cached; subsequent calls return the same hashref without
repeating network I/O.

### Usage

    my $orig = $analyser->originating_ip();
    if (defined $orig) {
        printf "Origin: %s (%s)\n", $orig->{ip}, $orig->{rdns};
        printf "Owner:  %s\n",      $orig->{org};
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A hashref with keys `ip`, `rdns`, `org`, `abuse`, `confidence`,
`note`, and `country` (may be undef).  Returns `undef` if no suitable
originating IP can be determined.

### Side Effects

On first call: one PTR lookup and one RDAP/WHOIS query.  Results are cached
in the object and in the cross-message CHI cache (if available).

### Notes

Only the first (oldest) external IP in the chain is reported.  See
`received_trail()` for the full chain.

### API Specification

#### Input

    []

#### Output

    {
        type => [ 'hashref', 'undef' ],
        keys => {
            ip         => { type => 'string', regex => qr/[\d.:a-fA-F]/ },
            rdns       => { type => 'string' },
            org        => { type => 'string' },
            abuse      => { type => 'string' },
            confidence => { type => 'string', memberof => [ 'high', 'medium', 'low' ] },
            note       => { type => 'string' },
            country    => { type => 'string', optional => 1 },
        },
    }

## embedded\_urls()

Extracts every HTTP and HTTPS URL from the message body and enriches each
one with the hosting IP address, network organisation name, abuse contact,
and country code.  Both IPv4 and IPv6 host addresses are supported.

URL extraction runs across both plain-text and HTML body parts.  DNS
lookups for each unique hostname are optionally parallelised via
`AnyEvent::DNS` if that module is installed.

The result is cached; subsequent calls return the same list without
repeating network I/O.

### Usage

    my @urls = $analyser->embedded_urls();
    for my $u (@urls) {
        printf "URL: %s  host: %s  org: %s\n",
            $u->{url}, $u->{host}, $u->{org};
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list of hashrefs, one per unique URL, in first-seen order.  Returns an
empty list if no HTTP/HTTPS URLs are present.  Each hashref has keys
`url`, `host`, `ip`, `org`, `abuse`, `country`.

### Side Effects

Per unique hostname: one A/AAAA lookup and one RDAP/WHOIS query.  Results
are cached in the object and in the cross-message CHI cache.

### Notes

Only `http://` and `https://` URLs are extracted.  URL shortener hosts
are included in the returned list (they are flagged by `risk_assessment()`).

When [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) is available, URLs whose host is a known URL shortener
or cloud-storage redirect cloaker (Google Cloud Storage `storage.googleapis.com`,
Azure Blob Storage `blob.core.windows.net`, Cloudflare Pages `pages.dev`,
S3 buckets, CloudFront distributions, etc.) are automatically resolved by
following HTTP 3xx redirects and HTML `meta http-equiv="refresh"` or
`window.location` patterns up to `$REDIRECT_MAX_HOPS` hops.  The resolved
destination URL is added to the returned list alongside the original, so abuse
contacts for the real phishing target are always reported even when the email
body contains only an object-store redirect URL.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                url     => { type => 'string', regex => qr{^https?://}i },
                host    => { type => 'string' },
                ip      => { type => 'string' },
                org     => { type => 'string' },
                abuse   => { type => 'string' },
                country => { type => 'string', optional => 1 },
            },
        },
        ...
    )

## mailto\_domains()

Identifies every domain associated with the message as a contact, reply,
or delivery address, then runs a full intelligence pipeline on each one
(A record, MX, NS, WHOIS) to determine hosting and registration details.

The result is cached; subsequent calls return the same list without
repeating network I/O.

### Usage

    my @domains = $analyser->mailto_domains();
    for my $d (@domains) {
        printf "Domain: %s  registrar: %s\n",
            $d->{domain}, $d->{registrar} // 'unknown';
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list of hashrefs, one per unique domain.  See the main POD for the full
set of possible keys.  Returns an empty list if no qualifying domains are
found.

### Side Effects

Per unique domain: up to three A lookups, one MX lookup, one NS lookup,
and two WHOIS queries.  Results are cached in the object and in the
cross-message CHI cache.

### Notes

MX and NS lookups require `Net::DNS`.  Without it those keys are absent
from every returned hashref.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                domain  => { type => 'string' },
                source  => { type => 'string' },
                # All other keys optional -- see main POD
            },
        },
        ...
    )

## all\_domains()

Returns the deduplicated union of every registrable domain seen anywhere
in the message -- URL hosts from `embedded_urls()` and contact domains
from `mailto_domains()` -- normalised to eTLD+1 form.

Triggers `embedded_urls()` and `mailto_domains()` lazily.

### Usage

    my @domains = $analyser->all_domains();
    print "$_\n" for @domains;

### Arguments

None.

### Returns

A list of plain strings (registrable domain names), lower-cased, no
duplicates, in first-seen order.

### Side Effects

Triggers `embedded_urls()` and `mailto_domains()` if not already cached.

### Notes

Normalisation to eTLD+1 uses `Domain::PublicSuffix` if installed, falling
back to a built-in heuristic otherwise.

### API Specification

#### Input

    []

#### Output

    (
        { type => 'string', regex => qr/^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/ },
        ...
    )

## unresolved\_contacts()

Returns a list of domains and URL hosts found in the message for which no
abuse contact could be determined.  Useful for surfacing parties that may
warrant manual investigation.

### Usage

    my @unresolved = $analyser->unresolved_contacts();
    for my $u (@unresolved) {
        printf "Unresolved: %s (%s) via %s\n",
            $u->{domain}, $u->{type}, $u->{source};
    }

### Arguments

None.

### Returns

A list of hashrefs, each with keys `domain`, `type` (`'url_host'` or
`'domain'`), and `source` (where the domain was found).

### Side Effects

Triggers `embedded_urls()`, `mailto_domains()`, `abuse_contacts()`,
and `form_contacts()` if not already cached.

### Notes

Domains sourced only from spoofable sending headers (`From:`,
`Return-Path:`, `Sender:`) are excluded.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                domain => { type => 'string' },
                type   => { type => 'string', memberof => [ 'url_host', 'domain' ] },
                source => { type => 'string' },
            },
        },
        ...
    )

## sending\_software()

Returns information extracted from headers that identify the software or
server-side infrastructure used to compose or inject the message.  Headers
such as `X-PHP-Originating-Script` reveal the exact PHP script and Unix
account responsible on shared-hosting platforms.

Data is extracted during `parse_email()` with no network I/O.

### Usage

    my @sw = $analyser->sending_software();
    for my $s (@sw) {
        printf "%-30s : %s\n", $s->{header}, $s->{value};
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list of hashrefs in alphabetical header-name order.  Returns an empty
list if none of the watched headers are present.  Each hashref has keys
`header`, `value`, and `note`.

### Side Effects

None.  Data is pre-collected during `parse_email()`.

### Notes

Header names are lower-cased.  Header values are stored verbatim.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                header => { type => 'string' },
                value  => { type => 'string' },
                note   => { type => 'string' },
            },
        },
        ...
    )

## received\_trail()

Returns per-hop tracking data extracted from the `Received:` header chain:
the IP address, envelope recipient address, and server session ID for each
relay.  ISP postmasters use these identifiers to locate the SMTP session in
their logs.

### Usage

    my @trail = $analyser->received_trail();
    for my $hop (@trail) {
        printf "IP: %s  ID: %s\n",
            $hop->{ip} // '?', $hop->{id} // '?';
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list of hashrefs in oldest-first order.  Returns an empty list if no
`Received:` headers are present or none yielded extractable data.  Each
hashref has keys `received`, `ip` (may be undef), `for` (may be undef),
`id` (may be undef).

### Side Effects

None.  Data is pre-collected during `parse_email()`.

### Notes

Private IPs are NOT filtered here; all IPs including RFC 1918 addresses
are returned as found.  Filtering is applied only by `originating_ip()`.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                received => { type => 'string' },
                ip       => { type => 'string', optional => 1 },
                for      => { type => 'string', optional => 1 },
                id       => { type => 'string', optional => 1 },
            },
        },
        ...
    )

## risk\_assessment()

Evaluates the message against heuristic checks and returns an overall risk
level, a weighted numeric score, and a list of every specific red flag.

The assessment covers five categories: originating IP, email authentication,
Date: header validity, identity/header consistency, and URL/domain properties.

The result is cached; subsequent calls return the same hashref without
repeating any analysis.

### Usage

    my $risk = $analyser->risk_assessment();
    printf "Risk: %s (score: %d)\n", $risk->{level}, $risk->{score};
    for my $f (@{ $risk->{flags} }) {
        printf "  [%s] %s\n", $f->{severity}, $f->{detail};
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A hashref with keys `level` (HIGH/MEDIUM/LOW/INFO), `score` (integer),
and `flags` (arrayref of hashrefs with `severity`, `flag`, `detail`).

### Side Effects

Triggers `originating_ip()`, `embedded_urls()`, and `mailto_domains()`
if not already cached.

### Notes

Scores: HIGH >= 9, MEDIUM >= 5, LOW >= 2, INFO < 2.
Flag weights: HIGH=3, MEDIUM=2, LOW=1, INFO=0.

### API Specification

#### Input

    []

#### Output

    {
        type => 'hashref',
        keys => {
            level => { type => 'string', memberof => ['HIGH', 'MEDIUM', 'LOW', 'INFO'] },
            score => { type => 'integer' },
            flags => { type => 'arrayref' },
        },
    }

## abuse\_report\_text()

Produces a compact, plain-text string suitable for sending as the body of
an abuse report email.  It summarises risk level, red flags, originating IP,
abuse contacts, and original message headers.  The message body is omitted
to keep the report concise.

Use `abuse_contacts()` to get the recipient addresses and this method for
the body text.

### Usage

    my $text     = $analyser->abuse_report_text();
    my @contacts = $analyser->abuse_contacts();
    for my $c (@contacts) {
        send_email(to => $c->{address}, body => $text);
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A plain scalar string, newline-terminated, Unix line endings.  Never empty
or undef.

### Side Effects

Calls `risk_assessment()`, `originating_ip()`, and `abuse_contacts()`
if not already cached.

### Notes

Output text is sanitised: control characters that could affect terminal or
HTML rendering are stripped from all user-derived content before inclusion.

### API Specification

#### Input

    []

#### Output

    { type => 'string' }

## abuse\_contacts()

Collates the complete set of parties that should receive an abuse report:
the sending ISP, URL host operators, contact domain web/mail/DNS/registrar
contacts, account providers identified from key headers, the DKIM signer,
and the ESP identified via List-Unsubscribe.

Addresses are deduplicated globally; if the same address is found via
multiple routes, a single entry is kept and role strings are merged.

### Usage

    my @contacts = $analyser->abuse_contacts();
    my @addrs    = map { $_->{address} } @contacts;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list of hashrefs, one per unique abuse address, in discovery order.
Each hashref has keys `role`, `roles` (arrayref), `address`, `note`,
`via`.  Returns an empty list if no contacts can be determined.

### Side Effects

Triggers `originating_ip()`, `embedded_urls()`, and `mailto_domains()`
if not already cached.

### Notes

The result is cached on the object; subsequent calls return the same list
without repeating the contact-collection logic.  The underlying per-IP and
per-domain lookups are themselves cached by `originating_ip()`,
`embedded_urls()`, and `mailto_domains()`.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                role    => { type => 'string' },
                roles   => { type => 'arrayref' },
                address => { type => 'string', regex => qr/\@/ },
                note    => { type => 'string' },
                via     => { type => 'string', memberof => [ 'provider-table', 'ip-whois', 'domain-whois' ] }
            },
        },
        ...
    )

## form\_contacts()

Returns the list of parties that require abuse reports via a web form
rather than email.  These are providers whose `%PROVIDER_ABUSE` entry
has a `form` key.  Each hashref includes the form URL, paste
instructions, upload instructions, and the discovery role.

### Usage

    my @forms = $analyser->form_contacts();
    for my $c (@forms) {
        printf "Open: %s\n", $c->{form};
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list of hashrefs, one per unique form contact.  Each hashref has keys
`form`, `role`, `note`, `form_paste` (optional), `form_upload`
(optional), and `via`.  Returns an empty list if no form contacts are found.

### Side Effects

Triggers `originating_ip()`, `embedded_urls()`, and `mailto_domains()`
if not already cached.

### Notes

Deduplication is by form URL.

### API Specification

#### Input

    []

#### Output

    (
        {
            type => 'hashref',
            keys => {
                form        => { type => 'string', regex => qr{^https?://} },
                role        => { type => 'string' },
                note        => { type => 'string' },
                form_paste  => { type => 'string', optional => 1 },
                form_upload => { type => 'string', optional => 1 },
                via         => { type => 'string' },
            },
        },
        ...
    )

## report()

Produces a comprehensive, analyst-facing plain-text report covering all
findings: envelope fields, risk assessment, originating host, sending
software, received chain tracking IDs, embedded URLs, contact domain
intelligence, and recommended abuse contacts.

Use `report()` for human review or ticketing systems.  Use
`abuse_report_text()` for sending to ISP abuse desks.

### Usage

    print $analyser->report();

    open my $fh, '>', 'report.txt' or croak "Cannot open: $!";
    print $fh $analyser->report();
    close $fh;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A plain scalar string, newline-terminated, Unix line endings.  Never empty
or undef.

### Side Effects

Triggers all analysis methods if not already cached.

### Notes

The report is idempotent: calling it multiple times on the same object
always returns an identical string.  All user-derived content is sanitised
before output.

### API Specification

#### Input

    []

#### Output

    { type => 'string' }

## header\_value( $name )

Returns the value of the first occurrence of a named header field, or
`undef` if the header is absent.  The name comparison is case-insensitive.

### Usage

    my $subj = $analyser->header_value('Subject');
    my $from  = $analyser->header_value('From');
    my $msgid = $analyser->header_value('Message-ID');

### Arguments

- `$name` (string, required)

    The header field name, e.g. `'Subject'`, `'From'`, `'X-Mailer'`.
    Comparison is case-insensitive.

### Returns

The raw header value string (not decoded), or `undef` if the named header
is not present.  When the same header appears more than once, only the value
of the first occurrence is returned.

### Side Effects

None.  Header data is pre-parsed during `parse_email()`.

### Notes

Header values are returned verbatim, including any MIME encoded-word sequences
(`=?charset?B/Q?...?=`).  Pass the result through `_decode_mime_words()`
internally if human-readable output is needed.

### API Specification

#### Input

    {
        name => { type => 'string', required => 1 },
    }

#### Output

    { type => [ 'string', 'undef' ] }

### Messages

None -- returns `undef` on a missing header, never throws.

# ALGORITHM: DOMAIN INTELLIGENCE PIPELINE

For each unique non-infrastructure domain found in the email, the module
runs the following pipeline:

    Domain name
        |
        +-- A/AAAA record --> web hosting IP --> RDAP --> org + abuse contact
        |
        +-- MX record --> mail server hostname --> A --> RDAP --> org + abuse
        |
        +-- NS record --> nameserver hostname  --> A --> RDAP --> org + abuse
        |
        +-- WHOIS (TLD whois server via IANA referral)
               +-- Registrar name + abuse contact
               +-- Creation date  (-> recently-registered flag if < 180 days)
               +-- Expiry date    (-> expires-soon or expired flags)

Domains are collected from:

    From:/Reply-To:/Sender:/Return-Path: headers
    DKIM-Signature: d=  (signing domain)
    List-Unsubscribe:   (ESP / bulk sender domain)
    Message-ID:         (often reveals real sending platform)
    mailto: links and bare addresses in the body

# CACHING

Two levels of caching are used:

- Per-message cache (`$self->{_domain_info}`)

    Stores domain analysis results for the lifetime of one `parse_email()`
    call.  Invalidated by each call to `parse_email()`.

- Cross-message cache (CHI Memory driver, if `CHI` is installed)

    Stores IP WHOIS, DNS resolution, and domain analysis results across all
    messages processed by the same process.  TTL is one hour.  Prevents
    redundant WHOIS queries for infrastructure that appears in multiple
    messages in the same run (e.g. a sending ISP seen in 500 spam messages).

# IPV6 SUPPORT

IPv6 addresses are extracted from `Received:` headers using bracketed
notation (`[2001:db8::1]`).  They are tested against the private range
list (which covers ::1, fe80::/10, fc00::/7, fd00::/8, and the
documentation range 2001:db8::/32) and passed through `_whois_ip()` and
`_rdap_lookup()` in the same way as IPv4 addresses.

`_resolve_host()` attempts both A and AAAA lookups when `Net::DNS` is
installed.  `_raw_whois()` uses `IO::Socket::IP` for dual-stack WHOIS
connections when that module is installed.

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)

    The provider\_abuse, trusted\_domains and url\_shorteners tables can all be overridden at runtime

- [Test Dashboard](https://nigelhorne.github.io/Email-Abuse-Investigator/coverage/)
- [ARIN RDAP](https://rdap.arin.net/)
- [Net::DNS](https://metacpan.org/pod/Net%3A%3ADNS), [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent), [HTML::LinkExtor](https://metacpan.org/pod/HTML%3A%3ALinkExtor)
- [CHI](https://metacpan.org/pod/CHI), [AnyEvent::DNS](https://metacpan.org/pod/AnyEvent%3A%3ADNS), [IO::Socket::IP](https://metacpan.org/pod/IO%3A%3ASocket%3A%3AIP), [Domain::PublicSuffix](https://metacpan.org/pod/Domain%3A%3APublicSuffix)

# REPOSITORY

[https://github.com/nigelhorne/Email-Abuse-Investigator](https://github.com/nigelhorne/Email-Abuse-Investigator)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-email-abuse-investigator at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Abuse-Investigator](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Abuse-Investigator).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Email::Abuse::Investigator

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Email-Abuse-Investigator](https://metacpan.org/dist/Email-Abuse-Investigator)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Abuse-Investigator](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Abuse-Investigator)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Email-Abuse-Investigator](http://matrix.cpantesters.org/?dist=Email-Abuse-Investigator)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Email-Abuse-Investigator](http://deps.cpantesters.org/?module=Email-Abuse-Investigator)

# REQUIRED MODULES

The following modules are mandatory:

    Readonly::Values::Months
    Socket              (core since Perl 5)
    IO::Socket::INET    (core since Perl 5)
    MIME::QuotedPrint   (core since Perl 5.8)
    MIME::Base64        (core since Perl 5.8)

The following are optional but strongly recommended:

    Net::DNS            -- enables MX, NS, AAAA record lookups
    LWP::UserAgent      -- enables RDAP (faster and richer than raw WHOIS)
                          and following redirect chains for URL shorteners
                          and cloud-storage redirect cloakers
    LWP::ConnCache      -- enables HTTP connection reuse (used with LWP::UserAgent)
    HTML::LinkExtor     -- enables structural HTML link extraction with entity decoding
    CHI                 -- enables cross-message IP/domain result caching
    IO::Socket::IP      -- enables IPv6 WHOIS connections
    Domain::PublicSuffix -- enables accurate eTLD+1 domain normalisation
    AnyEvent::DNS       -- enables parallel DNS resolution for multiple URL hosts

# LIMITATIONS

- No charset conversion

    Body text is stored as raw bytes.  Non-ASCII content (UTF-8, Latin-1,
    ISO-2022-JP, etc.) is not decoded to Perl's internal Unicode representation.
    URL and domain extraction from non-ASCII bodies may miss or misparse content.
    Use `Email::MIME` if full charset support is needed.

- Hand-rolled MIME parser

    The built-in MIME parser handles common cases but is not a conforming
    implementation of RFC 2045/2046.  It silently drops parts it cannot decode,
    does not handle `message/rfc822` attachments, and does not parse
    `Content-Disposition` filenames.  Replace with `Email::MIME` or
    `MIME::Entity` for production use with untrusted input.

- IPv4-only CIDR matching for trusted\_relays

    `_ip_in_cidr()` and the `trusted_relays` constructor argument only support
    IPv4 CIDR notation.  IPv6 trusted relay entries are accepted but silently
    never match.

- WHOIS rate-limiting not handled

    `_raw_whois()` does not retry on rate-limit responses (typically a
    "quota exceeded" reply).  Under high-volume processing the module will
    silently return empty enrichment data for affected IPs and domains.

- Not thread-safe

    The class-level `$_cache` variable and the optional-module `$HAS_*` flags
    are shared across all threads.  Create a separate object per thread and do
    not share objects across threads.

- DMARC policy not fetched

    The module reads the `Authentication-Results: dmarc=` result from the
    message headers but does not perform live `_dmarc.domain` TXT record
    lookups.  A missing DMARC result in the headers is not independently flagged.

- `abuse_contacts()` routes duplicated in `form_contacts()`

    Both methods iterate the same six discovery routes independently.  Any new
    discovery route must be added to both.  A future refactor should share a
    single routing pass.

- CHI cache is a class-level mutable global

    The cross-message cache is shared across all instances in the process.
    Tests that populate the cache will affect subsequent tests.  Pass the cache
    in via `new()` (not currently supported) to enable proper isolation.

# FORMAL SPECIFICATION

## new

    -- Z notation (simplified)
    new == [
      timeout        : N;
      trusted_relays : seq STRING;
      verbose        : BOOL;
      _raw           : STRING;
      _headers       : seq (STRING x STRING);
      _origin?       : IP_INFO | undefined;
      _urls?         : seq URL_INFO | undefined;
      _risk?         : RISK_INFO | undefined
    ]
    pre: timeout >= 0
    post: self.timeout = params.timeout /\ self._raw = ''

## parse\_email

    -- Z notation
    parse_email == [
      Delta Email::Abuse::Investigator;
      text? : STRING | ref STRING
    ]
    pre:  defined text?
    post: self._raw = deref(text?) /\
          self._origin = undefined /\
          self._urls   = undefined /\
          self._risk   = undefined

## originating\_ip

    -- Z notation
    originating_ip == [
      Xi Email::Abuse::Investigator;
      result! : IP_INFO | undefined
    ]
    pre:  self._raw /= ''
    post: result! = self._origin /\
          (result! /= undefined => result!.ip in EXTERNAL_IPS)

## embedded\_urls

    -- Z notation
    embedded_urls == [
      Xi Email::Abuse::Investigator;
      result! : seq URL_INFO
    ]
    pre:  self._raw /= ''
    post: result! = self._urls /\
          forall u : result! @ u.url =~ m{^https?://}i

## mailto\_domains

    -- Z notation
    mailto_domains == [
      Xi Email::Abuse::Investigator;
      result! : seq DOMAIN_INFO
    ]
    pre:  self._raw /= ''
    post: result! = self._mailto_domains /\
          forall d : result! @ d.domain =~ /\.[a-zA-Z]{2,}$/

## all\_domains

    -- Z notation
    all_domains == [
      Xi Email::Abuse::Investigator;
      result! : seq STRING
    ]
    post: result! = deduplicate(
                      map(_registrable, url_hosts union mailto_domains)
                    )

## unresolved\_contacts

    -- Z notation
    unresolved_contacts == [
      Xi Email::Abuse::Investigator;
      result! : seq UNRESOLVED_INFO
    ]
    post: forall u : result! @
            u.domain not_in covered_domains(abuse_contacts, form_contacts)

## sending\_software

    -- Z notation
    sending_software == [
      Xi Email::Abuse::Investigator;
      result! : seq SW_INFO
    ]
    post: result! = self._sending_sw

## received\_trail

    -- Z notation
    received_trail == [
      Xi Email::Abuse::Investigator;
      result! : seq HOP_INFO
    ]
    post: result! = self._rcvd_tracking

## risk\_assessment

    -- Z notation
    risk_assessment == [
      Xi Email::Abuse::Investigator;
      result! : RISK_INFO
    ]
    post: result!.score = sum({ w(f.severity) | f in result!.flags }) /\
          result!.level = classify(result!.score)
    where:
      w(HIGH) = 3; w(MEDIUM) = 2; w(LOW) = 1; w(INFO) = 0
      classify(s) = HIGH   if s >= 9
                  | MEDIUM if s >= 5
                  | LOW    if s >= 2
                  | INFO   otherwise

## abuse\_report\_text

    -- Z notation
    abuse_report_text == [
      Xi Email::Abuse::Investigator;
      result! : STRING
    ]
    post: result! /= '' /\ result! ends_with '\n'

## abuse\_contacts

    -- Z notation
    abuse_contacts == [
      Xi Email::Abuse::Investigator;
      result! : seq CONTACT_INFO
    ]
    post: forall c : result! @ c.address contains '@' /\
          forall c1, c2 : result! @ c1 /= c2 => c1.address /= c2.address

## form\_contacts

    -- Z notation
    form_contacts == [
      Xi Email::Abuse::Investigator;
      result! : seq FORM_CONTACT_INFO
    ]
    post: forall c : result! @ c.form =~ m{^https?://} /\
          forall c1, c2 : result! @ c1 /= c2 => c1.form /= c2.form

## report

    -- Z notation
    report == [
      Xi Email::Abuse::Investigator;
      result! : STRING
    ]
    post: result! /= '' /\ result! ends_with '\n'

## header\_value

    header_value : Object × FieldName → Maybe FieldValue
    header_value(o, n) ≜ first { lc(h.name) = lc(n) } o._headers .value

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.
