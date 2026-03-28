# NAME

Email::Abuse::Investigator - Analyse spam email to identify originating hosts,
hosted URLs, and suspicious domains

# VERSION

Version 0.04

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
and answers the questions abuse investigators ask:

- 1. Where did the message really come from?

    Walks the `Received:` chain, skips private/trusted IPs, and identifies the
    first external hop.  Enriches with rDNS, WHOIS/RDAP org name and abuse
    contact.

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
again: all cached state from the previous message is discarded automatically.

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

    Maximum number of seconds to wait for any single network operation: DNS
    lookups, WHOIS TCP connections, and RDAP HTTP requests each respect this
    limit independently.  Set to 0 to disable timeouts (not recommended for
    production use).  Values must be non-negative integers.

- `trusted_relays` (arrayref of strings, default \[\])

    A list of IP addresses or CIDR blocks that are under your own
    administrative control and should be excluded from the Received: chain
    analysis.  Any hop whose IP matches an entry here is skipped when
    determining `originating_ip()`.

    Each element may be:

    - An exact IPv4 address: `'192.0.2.1'`
    - A CIDR block: `'192.0.2.0/24'`, `'10.0.0.0/8'`

    Use this to exclude your own mail relays, load balancers, and internal
    infrastructure so they are never mistaken for the spam origin.

    Example: if your inbound gateway at 203.0.113.5 adds a Received: header
    before passing the message to your mail server, pass
    `trusted_relays => ['203.0.113.5']` and that hop will be ignored.

- `verbose` (boolean, default 0)

    When true, diagnostic messages are written to STDERR as the object
    processes each email.  Messages are prefixed with `[Email::Abuse::Investigator]`
    and describe each major analysis step (header parsing, DNS resolution,
    WHOIS queries, etc.).  Intended for development and debugging; leave false
    in production.

### Returns

A blessed `Email::Abuse::Investigator` object.  The object is immediately usable;
no network I/O is performed during construction.

### Side Effects

None.  The constructor performs no I/O.  All network activity is deferred
until the first call to a method that requires it (`originating_ip()`,
`embedded_urls()`, `mailto_domains()`, or any method that calls them).

### Notes

- The `timeout` option uses `//` (defined-or), so `timeout => 0` is
stored correctly as zero.  All other constructor options also use `//`.
- Unknown option keys are silently ignored.
- The object is not thread-safe.  If you process multiple emails
concurrently, construct a separate `Email::Abuse::Investigator` object per
thread or per-request.
- The `alarm()` mechanism used by the raw WHOIS client is not reliable on
Windows or inside threaded Perl interpreters.  All other functionality
works on those platforms; only WHOIS TCP connections may not respect the
timeout on affected platforms.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    {
        timeout => {
            type     => SCALAR,
            regex    => qr/^\d+$/,
            optional => 1,
            default  => 10,
        },
        trusted_relays => {
            type     => ARRAYREF,
            optional => 1,
            default  => [],
            # Each element: exact IPv4 address or CIDR in the form a.b.c.d/n
            # where n is an integer in the range 0..32
        },
        verbose => {
            type     => SCALAR,
            regex    => qr/^[01]$/,
            optional => 1,
            default  => 0,
        },
    }

#### Output

    # Return::Set compatible specification
    {
        type  => 'Email::Abuse::Investigator',  # blessed object
        isa   => 'Email::Abuse::Investigator',

        # Guaranteed slots on the returned object (public API):
        #   timeout        => non-negative integer
        #   trusted_relays => arrayref of strings
        #   verbose        => 0 or 1
        #
        # All other slots are private (_raw, _headers, etc.) and
        # must not be accessed or modified by the caller.
    }

## parse\_email( $text )

Feeds a raw RFC 2822 email message to the analyser and prepares it for
subsequent interrogation.  This is the only method that must be called
before any other public method; all analysis is driven by the message
supplied here.

If the same object is used for a second message, calling `parse_email()`
again completely replaces all state from the first message.  No trace of
the previous email survives.

### Usage

    # From a scalar
    my $raw = do { local $/; <STDIN> };
    $analyser->parse_email($raw);

    # From a scalar reference (avoids copying large messages)
    $analyser->parse_email(\$raw);

    # Chained with new()
    my $analyser = Email::Abuse::Investigator->new()->parse_email($raw);

    # Re-use the same object for multiple messages
    while (my $msg = $queue->next()) {
        $analyser->parse_email($msg->raw_text());
        my $risk = $analyser->risk_assessment();
        report_if_spam($analyser) if $risk->{level} ne 'INFO';
    }

### Arguments

- `$text` (scalar or scalar reference, required)

    The complete raw source of the email message as it arrived at your MTA,
    including all headers and the body, exactly as transferred over the wire.
    Both LF-only and CRLF line endings are accepted and handled transparently.

    A scalar reference is accepted as an alternative to a plain scalar.  The
    referent is dereferenced internally; the original variable is not modified.

    The following body encodings are decoded automatically:

    - `quoted-printable` (Content-Transfer-Encoding: quoted-printable)
    - `base64` (Content-Transfer-Encoding: base64)
    - `7bit` / `8bit` / `binary` (passed through as-is)

    Multipart messages (`multipart/alternative`, `multipart/mixed`, etc.)
    are split on their boundary and each text part decoded according to its
    own Content-Transfer-Encoding.  Non-text parts (attachments, inline images)
    are silently skipped.

### Returns

The object itself (`$self`), allowing method chaining:

    my $origin = Email::Abuse::Investigator->new()->parse_email($raw)->originating_ip();

### Side Effects

The following work is performed synchronously, with no network I/O:

- Header parsing

    All RFC 2822 headers are parsed into an internal list.  Folded (multi-line)
    header values are unfolded per RFC 2822 section 2.2.3.  The `Received:`
    chain is extracted separately for origin analysis.  Header names are
    normalised to lower-case.  When duplicate headers are present, all copies
    are retained; accessor methods return the first occurrence.

- Body decoding

    The message body is decoded according to its Content-Transfer-Encoding and
    stored as plain text (`_body_plain`) and/or HTML (`_body_html`).
    Multipart messages have each qualifying part appended in order.

- Sending software extraction

    The headers `X-Mailer`, `User-Agent`, `X-PHP-Originating-Script`,
    `X-Source`, `X-Source-Args`, and `X-Source-Host` are extracted if
    present and stored for retrieval via `sending_software()`.

- Received chain tracking data

    Each `Received:` header is scanned for an IP address, an envelope
    recipient (`for <addr@domain.com>`), and a server tracking ID
    (`id token`).  Results are stored for retrieval via `received_trail()`,
    ordered oldest hop first.

- Cache invalidation

    All lazily-computed results from a previous call to `parse_email()` on
    the same object are discarded: `originating_ip()`, `embedded_urls()`,
    `mailto_domains()`, `risk_assessment()`, and the authentication-results
    cache are all reset to `undef` so the next call to any of them analyses
    the new message from scratch.

All network I/O (DNS lookups, WHOIS/RDAP queries) is deferred; it occurs
only when a caller first invokes `originating_ip()`, `embedded_urls()`,
or `mailto_domains()`.

### Notes

- If `$text` is an empty string, contains only whitespace, or contains no
header/body separator, the method returns `$self` without populating any
internal state.  All public methods will return empty lists, `undef`, or
safe zero-value results rather than dying.
- The raw text is stored verbatim (in `_raw`) and is reproduced in the
output of `abuse_report_text()`.  For very large messages this doubles
the memory used.  If memory is a concern, supply a scalar reference so at
least the method argument does not copy the string on the call stack.
- HTML bodies are stored separately from plain-text bodies.  URL and
email-address extraction runs across both.  A URL that appears only in the
HTML part and not in the plain-text part is still reported.
- Decoding errors in base64 or quoted-printable payloads are silenced; the
partially-decoded or raw bytes are used in place of correct output.  This
prevents malformed spam from causing exceptions during analysis.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # (positional argument, not named)
    [
        {
            type => SCALAR | SCALARREF,
            # SCALAR:    the complete raw email text
            # SCALARREF: reference to the complete raw email text;
            #            the referent must be a defined string
            # Both LF and CRLF line endings are accepted.
        },
    ]

#### Output

    # Return::Set compatible specification
    {
        type => 'Email::Abuse::Investigator',  # the invocant, returned for chaining
        isa  => 'Email::Abuse::Investigator',

        # Guaranteed post-conditions on the returned object:
        #   sending_software()  returns a (possibly empty) list
        #   received_trail()    returns a (possibly empty) list
        #   All lazy-analysis caches are reset (undef or empty)
        #   _raw contains the verbatim input text
    }

## originating\_ip()

Identifies the IP address of the machine that originally injected the
message into the mail system, as opposed to any intermediate relay that
passed it along.  This is the address of the spammer's machine, their ISP's
outbound mail server, or a compromised host -- the primary target for an
ISP abuse report.

The method walks the `Received:` chain from oldest to newest, skips every
hop whose IP is in a private, reserved, or trusted range, and returns the
first remaining (external) IP, enriched with reverse DNS, network ownership,
and abuse contact information gathered via rDNS, RDAP, and WHOIS.

If no usable IP can be found in the `Received:` chain, the method falls back
to the `X-Originating-IP` header injected by some webmail providers.

The result is computed once and cached; subsequent calls on the same object
return the same hashref without repeating any network I/O.

### Usage

    $analyser->parse_email($raw);
    my $orig = $analyser->originating_ip();

    if (defined $orig) {
        printf "Origin: %s (%s)\n",   $orig->{ip},  $orig->{rdns};
        printf "Owner:  %s\n",        $orig->{org};
        printf "Abuse:  %s\n",        $orig->{abuse};
        printf "Confidence: %s\n",    $orig->{confidence};
    } else {
        print "Could not determine originating IP.\n";
    }

    # Confidence-gated reporting
    if (defined $orig && $orig->{confidence} eq 'high') {
        send_abuse_report($orig->{abuse}, $analyser->abuse_report_text());
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

    {
      ip         => '209.85.218.67',
      rdns       => 'mail-ej1-f67.google.com',
      org        => 'Google LLC',
      abuse      => 'network-abuse@google.com',
      confidence => 'high',
      note       => 'First external hop in Received: chain',
    }

On success, a hashref with the following keys (all always present):

- `ip` (string)

    The dotted-quad IPv4 address of the identified originating host.

- `rdns` (string)

    The reverse DNS (PTR) hostname for `ip`.  Set to the literal string
    `'(no reverse DNS)'` if no PTR record exists or the lookup fails.
    The presence and format of rDNS is used by `risk_assessment()` to detect
    residential broadband senders.

- `org` (string)

    The network organisation name that owns the IP block, sourced from RDAP
    (preferred) or WHOIS (fallback).  Set to `'(unknown)'` if neither source
    returns an organisation name.

- `abuse` (string)

    The abuse contact email address for the IP block owner, sourced from RDAP
    or WHOIS.  Set to `'(unknown)'` if no abuse address can be determined.
    `abuse_contacts()` uses this field when building the contact list; entries
    with the value `'(unknown)'` are suppressed.

- `confidence` (string)

    One of three values reflecting how reliably the IP was identified:

    - `'high'`

        Two or more distinct external hops were found in the `Received:` chain
        (after removing private and trusted IPs).  The bottom-most hop is reported.
        A chain of two or more external hops is strong evidence the first-seen IP
        is the true origin.

    - `'medium'`

        Exactly one external hop was found in the `Received:` chain.  The IP is
        likely correct but cannot be independently corroborated by a relay record.

    - `'low'`

        No usable IP was found in the `Received:` chain; the IP was taken from the
        `X-Originating-IP` header instead.  This header is injected by webmail
        interfaces and is not verifiable; a sender can forge it.

- `note` (string)

    A human-readable explanation of how the IP was selected.  Examples:

        'First external hop in Received: chain'
        'Taken from X-Originating-IP (webmail, unverified)'

- `country` (string or undef)

    The two-letter ISO 3166-1 alpha-2 country code for the IP block, sourced
    from RDAP or WHOIS.  `undef` if no country code is available.
    `risk_assessment()` uses this field to raise the `high_spam_country` flag
    for a set of statistically high-volume spam-originating countries.

Returns `undef` if no suitable originating IP can be determined (no
`Received:` headers, all IPs are private or trusted, no usable
`X-Originating-IP` header, or `parse_email()` has not been called).

### Side Effects

The first call (or the first call after a `parse_email()`) performs the
following network I/O, subject to the `timeout` set at construction:

- One PTR (rDNS) lookup for the identified IP address.
- One RDAP query to `rdap.arin.net` (if `LWP::UserAgent` is available).
- If RDAP returns no organisation: one WHOIS query to `whois.iana.org`
to obtain the authoritative registry, followed by one WHOIS query to that
registry.

All subsequent calls return the cached hashref.  The cache is invalidated by
`parse_email()`.

### Algorithm: Received: chain traversal

The `Received:` headers are walked from bottom (oldest) to top (most
recent).  For each header, the first IPv4 address is extracted in priority
order:

- 1. A bracketed address: `[1.2.3.4]`
- 2. A parenthesised address: `(hostname [1.2.3.4])`
- 3. An address following `from hostname`
- 4. Any bare dotted-quad as a last resort

An extracted IP is discarded if it:

- Falls in any of the following excluded ranges: 0.0.0.0/8 (RFC 1122),
127.0.0.0/8 (loopback), 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
(RFC 1918), 169.254.0.0/16 (link-local), 100.64.0.0/10 (CGN, RFC 6598),
192.0.0.0/24, 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 (RFC 5737
documentation ranges), 255.0.0.0/8 (broadcast), or IPv6 loopback/ULA.
- Matches any entry in the `trusted_relays` list passed to `new()`.
- Contains an octet greater than 255 (i.e., is syntactically invalid).

All non-discarded IPs are collected; the first (oldest) one is reported as
the origin.  The count of non-discarded IPs determines the confidence level.

### Notes

- Only IPv4 addresses are extracted.  IPv6 addresses in `Received:` headers
are ignored.  This is a known limitation; most spam still travels via IPv4
infrastructure.
- The algorithm trusts the `Received:` headers as written.  A sophisticated
sender who controls an intermediate relay can insert a forged `Received:`
header with an arbitrary IP.  The `confidence` field reflects this: `high`
confidence requires two independent external hops but cannot guarantee that
neither hop forged its Received: line.
- If all `Received:` IPs are private or trusted, the `X-Originating-IP`
header is used as a fallback.  This header is unverifiable and receives
`confidence` `'low'`.  Brackets and whitespace are stripped from its
value before use.
- The `country` key is `undef`, not the empty string, when no country code
is available.  Test with `defined $orig->{country}`, not a boolean
check.
- `org` and `abuse` default to the literal string `'(unknown)'`, not
`undef`.  This means they are always defined; use string equality to test
for the unknown case: `$orig->{abuse} eq '(unknown)'`.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments; invocant must be a Email::Abuse::Investigator object
    # on which parse_email() has previously been called.
    []

#### Output

    # Return::Set compatible specification

    # On success:
    {
        type => HASHREF,
        keys => {
            ip => {
                type  => SCALAR,
                regex => qr/^\d{1,3}(?:\.\d{1,3}){3}$/,  # dotted-quad IPv4
            },
            rdns => {
                type  => SCALAR,
                # hostname string, or the literal '(no reverse DNS)'
            },
            org => {
                type  => SCALAR,
                # organisation name, or the literal '(unknown)'
            },
            abuse => {
                type  => SCALAR,
                # email address, or the literal '(unknown)'
            },
            confidence => {
                type  => SCALAR,
                regex => qr/^(?:high|medium|low)$/,
            },
            note => {
                type => SCALAR,
            },
            country => {
                type     => SCALAR,
                optional => 1,  # present but may be undef
                regex    => qr/^[A-Z]{2}$/,
            },
        },
    }

    # On failure (no usable IP found):
    undef

## embedded\_urls()

Extracts every HTTP and HTTPS URL from the message body and enriches each
one with the hosting IP address, network organisation name, abuse contact,
and country code of the web server it points to.

URL extraction runs across both the plain-text and HTML parts of the
message.  When `HTML::LinkExtor` is available, HTML `href`, `src`, and
`action` attributes are parsed structurally; a plain-text regex pass then
catches any remaining bare URLs in both parts.

Each unique URL is returned as a separate hashref.  When multiple distinct
URLs share the same hostname, DNS resolution and WHOIS are performed only
once for that hostname; all URLs on that host share the cached result.

The result list is computed once and cached; subsequent calls on the same
object return the same data without repeating any network I/O.

### Usage

    $analyser->parse_email($raw);
    my @urls = $analyser->embedded_urls();

    if (@urls) {
        for my $u (@urls) {
            printf "URL:   %s\n", $u->{url};
            printf "Host:  %s  IP: %s\n", $u->{host}, $u->{ip};
            printf "Owner: %s\n", $u->{org};
            printf "Abuse: %s\n", $u->{abuse};
            print  "\n";
        }
    } else {
        print "No HTTP/HTTPS URLs found.\n";
    }

    # Collect unique abuse contacts from URL hosts
    my %seen;
    my @url_contacts = grep { !$seen{$_}++ }
                       map  { $_->{abuse} }
                       grep { $_->{abuse} ne '(unknown)' }
                       @urls;

    # Check for URL shorteners
    my @shorteners = grep { $_->{host} =~ /bit\.ly|tinyurl/i } @urls;
    warn "Message contains URL shortener(s)\n" if @shorteners;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list (not an arrayref) of hashrefs, one per unique URL found in the body,
in the order they were first encountered.  Returns an empty list if the body
contains no HTTP or HTTPS URLs, or if `parse_email()` has not been called.

    {
        url   => 'https://spamsite.example/offer',
        host  => 'spamsite.example',
        ip    => '198.51.100.7',
        org   => 'Dodgy Hosting Ltd',
        abuse => 'abuse@dodgy.example',
    }

Each hashref contains the following keys (all always present):

- `url` (string)

    The complete URL as it appeared in the message body, with any trailing
    punctuation characters (`.`, `,`, `;`, `:`, `!`, `?`, `)`, `>`,
    `]`) stripped.  The scheme is preserved in the original case (`HTTP://`,
    `https://`, etc.).

- `host` (string)

    The hostname portion of the URL, extracted from between the scheme and
    the first `/`, `?`, `:`, `#`, or whitespace character.  Port numbers
    are not included.  Examples: `'www.example.com'`, `'bit.ly'`.

- `ip` (string)

    The IPv4 address the hostname resolved to at analysis time.  Set to the
    literal string `'(unresolved)'` if DNS resolution failed or returned no
    A record.  Note that short-lived spam infrastructure may resolve differently
    at report time than at analysis time.

- `org` (string)

    The network organisation that owns the IP block, from RDAP or WHOIS.
    Set to `'(unknown)'` if no organisation name is available or if the host
    could not be resolved.

- `abuse` (string)

    The abuse contact email address for the IP block owner, from RDAP or WHOIS.
    Set to `'(unknown)'` if no abuse address is available or if the host could
    not be resolved.  `abuse_contacts()` uses this field; entries with the
    value `'(unknown)'` are suppressed in the contact list.

- `country` (string or undef)

    The two-letter ISO 3166-1 alpha-2 country code for the IP block, from RDAP
    or WHOIS.  `undef` if no country code is available or if the host could
    not be resolved.

### Side Effects

The first call (or first call after `parse_email()`) performs network I/O
for each unique hostname found, subject to the `timeout` set at construction.
For each unique hostname:

- One A record (DNS) lookup to resolve the hostname to an IP address.
- If resolution succeeds: one RDAP query to `rdap.arin.net`
(if `LWP::UserAgent` is available).
- If RDAP returns no organisation: one WHOIS query to `whois.iana.org`
followed by one query to the authoritative registry for the IP block.

DNS and WHOIS are performed at most once per unique hostname per
`parse_email()` call, regardless of how many distinct URLs share that
hostname.  All subsequent calls return the cached list.  The cache is
invalidated by `parse_email()`.

### Algorithm: URL extraction

URLs are extracted from the concatenation of the decoded plain-text body
and the decoded HTML body, in that order.  The two extraction passes are:

- 1. Structural HTML parsing (if `HTML::LinkExtor` is installed)

    `href`, `src`, and `action` attributes of all HTML tags are inspected.
    Any value beginning with `http://` or `https://` (case-insensitive) is
    collected.  This correctly handles URLs that contain characters which would
    confuse a plain-text regex, such as embedded spaces in quoted attribute
    values.

- 2. Plain-text regex pass

    A greedy regex `https?://[^\s<`"'\\)\\\]\]+> is applied to the combined body
    text.  This catches bare URLs in plain-text parts and any URLs not captured
    by the structural pass.

After both passes, the combined list is deduplicated (preserving first-seen
order) and trailing punctuation is stripped from each URL.  The host is
then extracted and used as a cache key for DNS and WHOIS lookups.

### Notes

- Only `http://` and `https://` URLs are extracted.  `ftp://`, `mailto:`,
and other schemes are not included.  Bare domain names without a scheme are
also not included (those are handled by `mailto_domains()`).
- Duplicate URLs -- the same complete URL string appearing more than once --
are reported only once.  Two URLs that differ only in case (e.g.
`HTTP://` vs `https://`) are treated as distinct.
- If a hostname appears in multiple distinct URLs, all URLs are returned
individually as separate hashrefs, but the `ip`, `org`, `abuse`, and
`country` fields are identical across all of them (copied from the single
cached lookup).  Callers grouping by host should use the `host` field
as the key.
- `ip`, `org`, and `abuse` use sentinel strings rather than `undef` for
the unknown case: `'(unresolved)'` for `ip` when DNS fails, `'(unknown)'`
for `org` and `abuse` when WHOIS returns nothing.  Only `country` is
`undef` in the unknown case.  Test accordingly:
`$u->{ip} ne '(unresolved)'`, not `defined $u->{ip}`.
- URL shorteners (`bit.ly`, `tinyurl.com`, and several dozen others) are
detected by `risk_assessment()`, which raises a `url_shortener` flag.
`embedded_urls()` itself does not filter them out; they appear in the
returned list so their hosting information can still be reported.
- The order of URLs in the returned list reflects first-seen order across
both the plain-text and HTML extraction passes.  Because the HTML parser
and the regex run over the same combined string, a URL that appears in
both an HTML attribute and as bare text will appear only once (at the
position it was first seen).

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification

    # A list (possibly empty) of hashrefs:
    (
        {
            type => HASHREF,
            keys => {
                url => {
                    type  => SCALAR,
                    regex => qr{^https?://}i,
                },
                host => {
                    type  => SCALAR,
                    # hostname without port; no leading scheme
                },
                ip => {
                    type  => SCALAR,
                    # dotted-quad IPv4, or the literal '(unresolved)'
                },
                org => {
                    type  => SCALAR,
                    # organisation name, or the literal '(unknown)'
                },
                abuse => {
                    type  => SCALAR,
                    # email address, or the literal '(unknown)'
                },
                country => {
                    type     => SCALAR,
                    optional => 1,  # present but may be undef
                    regex    => qr/^[A-Z]{2}$/,
                },
            },
        },
        # ... one hashref per unique URL, in first-seen order
    )

    # Empty list when no HTTP/HTTPS URLs are present in the body.

## mailto\_domains()

Identifies every domain associated with the message as a contact, reply,
or delivery address, then runs a full intelligence pipeline on each one to
determine who hosts its web server, who handles its mail, who operates its
DNS, and who registered it.

This answers POD description item 3: "Who owns the reply-to / contact
domains?"  A spammer may use one sending IP but route replies through an
entirely different organisation's infrastructure.  This method surfaces all
of those parties so each can be contacted independently.

The result is computed once and cached; subsequent calls on the same object
return the same list without repeating any network I/O.

### Usage

    $analyser->parse_email($raw);
    my @domains = $analyser->mailto_domains();

    for my $d (@domains) {
        printf "Domain : %s  (found in %s)\n", $d->{domain}, $d->{source};
        printf "  Web  : %s  owned by %s\n",   $d->{web_ip}  // 'none',
                                                $d->{web_org} // 'unknown';
        printf "  MX   : %s\n", $d->{mx_host} // 'none';
        printf "  Reg  : %s  (registered %s)\n", $d->{registrar}  // 'unknown',
                                                  $d->{registered} // 'unknown';
        if ($d->{recently_registered}) {
            print  "  *** RECENTLY REGISTERED -- possible phishing domain ***\n";
        }
        print "\n";
    }

    # Collect registrar abuse contacts
    my @reg_contacts = map  { $_->{registrar_abuse} }
                       grep { defined $_->{registrar_abuse} }
                       @domains;

    # Find recently registered domains
    my @fresh = grep { $_->{recently_registered} } @domains;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list (not an arrayref) of hashrefs, one per unique non-infrastructure
domain, in the order each domain was first encountered across all sources.
Returns an empty list if no qualifying domains are found, or if
`parse_email()` has not been called.

    {
        domain      => 'sminvestmentsupplychain.com',
        source      => 'mailto in body',

        # Web hosting
        web_ip      => '104.21.30.10',
        web_org     => 'Cloudflare Inc',
        web_abuse   => 'abuse@cloudflare.com',

        # Mail hosting (MX)
        mx_host     => 'mail.example.com',
        mx_ip       => '198.51.100.5',
        mx_org      => 'Hosting Corp',
        mx_abuse    => 'abuse@hostingcorp.example',

        # DNS authority (NS)
        ns_host     => 'ns1.example.com',
        ns_ip       => '198.51.100.1',
        ns_org      => 'DNS Provider Inc',
        ns_abuse    => 'abuse@dnsprovider.example',

        # Domain registration (WHOIS)
        registrar   => 'GoDaddy.com LLC',
        registered  => '2024-11-01',
        expires     => '2025-11-01',
        recently_registered => 1,   # flag: < 180 days old

        # Raw domain WHOIS text (first 2 KB)
        whois_raw   => '...',
    }

Each hashref contains the following keys.  Keys marked "(optional)" are
absent from the hashref when the corresponding information is unavailable;
test with `exists $d->{key}` or `defined $d->{key}` as
appropriate.

- `domain` (string, always present)

    The domain name, lower-cased and with any trailing dot removed.  This is
    the full domain as it appeared in the source header or body (e.g.
    `'sminvestmentsupplychain.com'`), not the registrable eTLD+1.

- `source` (string, always present)

    A human-readable label identifying which header or body section the domain
    was first seen in.  Possible values:

        'From: header'
        'Reply-To: header'
        'Return-Path: header'
        'Sender: header'
        'Message-ID: header'
        'DKIM-Signature: d= (signing domain)'
        'List-Unsubscribe: header'
        'email address / mailto in body'

    When a domain appears in multiple sources, only the first-seen source is
    recorded.

- `web_ip` (string, optional)

    The IPv4 address the domain's A record resolved to.  Absent if the domain
    has no A record or resolution failed.

- `web_org` (string, optional)

    The network organisation hosting the web server at `web_ip`, from RDAP or
    WHOIS.  Absent if `web_ip` is absent or WHOIS returns no organisation.

- `web_abuse` (string, optional)

    The abuse contact email for the web-hosting network, from RDAP or WHOIS.
    Absent if `web_ip` is absent or WHOIS returns no abuse address.

- `mx_host` (string, optional)

    The hostname of the lowest-preference MX record for the domain.
    Only populated when `Net::DNS` is installed.  Absent if no MX record
    exists or `Net::DNS` is unavailable.

- `mx_ip` (string, optional)

    The IPv4 address of the MX host.  Absent if `mx_host` is absent or
    the MX hostname could not be resolved.

- `mx_org` (string, optional)

    The network organisation hosting the MX server, from RDAP or WHOIS.

- `mx_abuse` (string, optional)

    The abuse contact email for the MX hosting network.

- `ns_host` (string, optional)

    The hostname of the first NS (nameserver) record returned for the domain.
    Only populated when `Net::DNS` is installed.

- `ns_ip` (string, optional)

    The IPv4 address of the NS host.

- `ns_org` (string, optional)

    The network organisation operating the nameserver, from RDAP or WHOIS.

- `ns_abuse` (string, optional)

    The abuse contact email for the nameserver network.

- `registrar` (string, optional)

    The registrar name as it appears in the domain's WHOIS record (e.g.
    `'GoDaddy.com LLC'`).  Absent if WHOIS is unavailable or the registrar
    field was not found.

- `registrar_abuse` (string, optional)

    The registrar's abuse contact email, extracted from the WHOIS record
    using the following patterns in priority order:
    `Registrar Abuse Contact Email:`, `Abuse Contact Email:`,
    `abuse-contact:`.  Absent if none of these fields is present.

- `registered` (string, optional)

    The domain's creation date as a string in `YYYY-MM-DD` form (ISO 8601
    date only, time and timezone stripped).  Parsed from WHOIS using the
    following field names in priority order: `Creation Date:`,
    `Created On:`, `Registration Time:`, `registered:`.
    Absent if WHOIS is unavailable or no creation date field is found.

- `expires` (string, optional)

    The domain's expiry date in `YYYY-MM-DD` form.  Parsed from:
    `Registry Expiry Date:`, `Expiry Date:`, `Expiration Date:`,
    `paid-till:`.  Absent if not found.

- `recently_registered` (integer 1, optional)

    Present and set to `1` when the domain's `registered` date is less
    than 180 days before the time of analysis.  Absent (not merely `0`) when
    the domain is not recently registered or when no creation date is available.
    Used by `risk_assessment()` to raise the `recently_registered_domain` flag.

- `whois_raw` (string, optional)

    The first 2048 bytes of the raw WHOIS response for the domain.  Intended
    for human inspection or logging.  Absent if WHOIS is unavailable or returns
    no data.

### Side Effects

The first call (or first call after `parse_email()`) performs network I/O
for each unique domain collected, subject to the `timeout` set at
construction.  For each domain:

- One A record (DNS) lookup for the domain itself (web hosting).
- If `Net::DNS` is installed: one MX record lookup; if an MX record
is found, one further A lookup for the MX hostname.
- If `Net::DNS` is installed: one NS record lookup; if an NS record
is found, one further A lookup for the NS hostname.
- For each resolved IP (web, MX, NS): one RDAP or WHOIS query to
identify the network owner.  The same IP is never queried twice.
- Two WHOIS queries for the domain itself: one to `whois.iana.org`
to obtain the TLD's authoritative registry, followed by one to that registry.

In the worst case (all records present, all IPs distinct, RDAP unavailable),
each domain incurs: 3 A lookups + 1 MX lookup + 1 NS lookup + 3 WHOIS IP
queries (6 TCP connections each) + 2 domain WHOIS queries (2 TCP connections)
&#x3d; up to 17 network operations.  In practice, shared hosting and cached DNS
reduce this considerably.

All results are cached per domain within a single `parse_email()` lifetime.
The cache is invalidated by `parse_email()`.

### Domain collection sources

Domains are collected from the following sources, in this order.  A domain
that appears in multiple sources is recorded only once, with the source
label of its first occurrence.

- 1. `From:`, `Reply-To:`, `Return-Path:`, `Sender:` headers

    All email addresses in these headers are parsed and their domain portions
    extracted.

- 2. `Message-ID:` header

    The domain portion of the Message-ID is extracted.  This often reveals the
    real bulk-sending platform even when `From:` is forged.  Domains that are
    members of the infrastructure exclusion list (`gmail.com`, `outlook.com`,
    `google.com`, `microsoft.com`, `apple.com`, `amazon.com`,
    `yahoo.com`, `googlemail.com`, `hotmail.com`) are skipped here, as are
    any domain whose registrable eTLD+1 is in that list (e.g. `mail.gmail.com`
    is excluded because `gmail.com` is in the list).

- 3. `DKIM-Signature: d=` tag

    The signing domain from the first `DKIM-Signature:` header.  This is the
    organisation that cryptographically vouches for the message, and is
    actionable regardless of whether DKIM passes or fails.

- 4. `List-Unsubscribe:` header

    Both `https://` URLs and `mailto:` addresses in this header are parsed.
    The domains identify the ESP or bulk sender responsible for delivery, who
    may be held accountable under CAN-SPAM and similar laws.

- 5. Body (plain-text and HTML)

    `mailto:` links and bare `user@domain` email addresses are extracted from
    the combined decoded body.  `mailto:` links are recognised even when the
    `@` sign is HTML-entity-encoded (`=40` or `=3D@`) from quoted-printable
    transfer.

In all cases, domain names are lower-cased, trailing dots are stripped, and
domains in the infrastructure exclusion list are silently discarded.

### Notes

- Unlike `embedded_urls()`, which reports the host of every URL, this method
reports the contact domain -- the domain a human would write to, not
necessarily the domain hosting the content.  A spam campaign might send
from `firmluminary.com` (contact domain) while linking to CDN URLs at
`cloudflare.com` (URL host).  Both are captured, by different methods.
- The `recently_registered` key is absent, not `0`, when a domain is not
recently registered or when no creation date is available.  Test for it with
`$d->{recently_registered}` (boolean truthiness), not with `eq '1'`.
- All hosting sub-keys (`web_ip`, `mx_host`, `ns_host`, etc.) are absent
rather than `undef` when the corresponding lookup yields no result.  This
means `keys %$d` will contain only the keys for which information was
actually found.  Do not assume any optional key is present.
- MX and NS lookups require `Net::DNS`.  If `Net::DNS` is not installed,
only A record and WHOIS information is populated; `mx_host`, `mx_ip`,
`mx_org`, `mx_abuse`, `ns_host`, `ns_ip`, `ns_org`, and `ns_abuse`
will all be absent for every domain.
- Date strings in `registered` and `expires` have the time and timezone
components stripped (everything from `T` or `Z` onward in ISO 8601 form).
They are stored as plain strings, not as epoch integers; use
`_parse_date_to_epoch()` (private) if a numeric comparison is needed.
- `whois_raw` is truncated to the first 2048 bytes of the raw WHOIS
response.  The date and registrar fields are parsed from the full response
before truncation, so truncation does not affect the structured fields.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification

    # A list (possibly empty) of hashrefs, one per domain:
    (
        {
            type => HASHREF,
            keys => {
                # Always present:
                domain => { type => SCALAR },
                source => { type => SCALAR },

                # Optional -- absent when information is unavailable:
                web_ip    => { type => SCALAR, optional => 1,
                               regex => qr/^\d{1,3}(?:\.\d{1,3}){3}$/ },
                web_org   => { type => SCALAR, optional => 1 },
                web_abuse => { type => SCALAR, optional => 1 },

                mx_host  => { type => SCALAR, optional => 1 },
                mx_ip    => { type => SCALAR, optional => 1,
                              regex => qr/^\d{1,3}(?:\.\d{1,3}){3}$/ },
                mx_org   => { type => SCALAR, optional => 1 },
                mx_abuse => { type => SCALAR, optional => 1 },

                ns_host  => { type => SCALAR, optional => 1 },
                ns_ip    => { type => SCALAR, optional => 1,
                              regex => qr/^\d{1,3}(?:\.\d{1,3}){3}$/ },
                ns_org   => { type => SCALAR, optional => 1 },
                ns_abuse => { type => SCALAR, optional => 1 },

                registrar       => { type => SCALAR, optional => 1 },
                registrar_abuse => { type => SCALAR, optional => 1 },

                registered => { type => SCALAR, optional => 1,
                                regex => qr/^\d{4}-\d{2}-\d{2}$/ },
                expires    => { type => SCALAR, optional => 1,
                                regex => qr/^\d{4}-\d{2}-\d{2}$/ },

                recently_registered => { type => SCALAR, optional => 1,
                                         regex => qr/^1$/ },

                whois_raw => { type => SCALAR, optional => 1 },
            },
        },
        # ... one hashref per unique domain, in first-seen order
    )

    # Empty list when no qualifying domains are found.

## all\_domains()

Returns the union of every registrable domain seen anywhere in the message:
URL hosts from `embedded_urls()` and contact domains from
`mailto_domains()`, collapsed to their registrable eTLD+1 form and
deduplicated.

This is the high-level answer to "what domains does this message reference?"
It is suitable for bulk lookups, domain reputation checks, or feeds into
external threat-intelligence systems where you want a flat, deduplicated
list rather than the detailed per-domain hashrefs returned by the individual
methods.

Unlike `mailto_domains()`, this method triggers no additional network I/O
beyond what `embedded_urls()` and `mailto_domains()` already perform; it
is a pure in-memory union and normalisation of their results.

### Usage

    $analyser->parse_email($raw);
    my @domains = $analyser->all_domains();

    # Print every unique registrable domain
    print "$_\n" for @domains;

    # Feed into a reputation lookup
    for my $dom (@domains) {
        my $score = $reputation_api->lookup($dom);
        warn "Known bad domain: $dom\n" if $score > 0.8;
    }

    # Check for overlap with a known-bad domain list
    my %blocklist = map { $_ => 1 } @known_bad_domains;
    my @hits = grep { $blocklist{$_} } @domains;

### Arguments

None.  `parse_email()` must have been called first.  Calling
`all_domains()` before `embedded_urls()` or `mailto_domains()` is safe;
it will trigger both lazily.

### Returns

A list (not an arrayref) of plain strings, each being a registrable
eTLD+1 domain name (see Algorithm below), lower-cased, with no duplicates,
in first-seen order.  Returns an empty list if the message contains no
URLs and no contact domains, or if `parse_email()` has not been called.

The list contains plain scalars, not hashrefs.  For the full intelligence
detail associated with each domain, call `embedded_urls()` and
`mailto_domains()` directly.

### Side Effects

Triggers `embedded_urls()` and `mailto_domains()` if they have not
already been called on the current message, which in turn performs network
I/O as documented in those methods.  No additional network I/O is performed
beyond what those two methods require.  Results are not independently cached;
the caching is handled by `embedded_urls()` and `mailto_domains()`.

### Algorithm: eTLD+1 normalisation

Both input sources are normalised to their registrable domain
(eTLD+1) before deduplication, using the following heuristic:

- A hostname with no dot (e.g. `localhost`) is discarded (returns `undef`
from the internal function and is skipped).
- A hostname with exactly two labels (e.g. `example.com`, `evil.ru`) is
returned as-is; it is already registrable.
- A hostname with three or more labels is inspected at the TLD (last label)
and the second-level (penultimate label).  If the TLD is a two-letter
country code (`uk`, `au`, `jp`, etc.) and the second-level label is one
of the common delegated second-levels `co`, `com`, `net`, `org`,
`gov`, `edu`, `ac`, or `me`, then three labels are kept (e.g.
`mail.evil.co.uk` becomes `evil.co.uk`).  Otherwise two labels are kept
(e.g. `mail.evil.com` becomes `evil.com`).

This heuristic handles the most common cases correctly.  It is not a full
Public Suffix List implementation; uncommon second-level delegations (e.g.
`.ltd.uk`, `.plc.uk`, `.asn.au`) are not recognised and will produce
a two-label result that includes the second-level label rather than three
labels.

The normalisation is applied to both sources:

- URL hosts (from `embedded_urls()`): the host extracted from each
URL is normalised.  For example, the URL
`https://www.spamco.example/offer` contributes `spamco.example`.
- Contact domains (from `mailto_domains()`): the full domain
stored in each hashref is normalised.  For example, the From: address
`<spammer@sub.spamco.example>` contributes `spamco.example`.

This means a URL at `www.spamco.example` and a contact address at
`sub.spamco.example` both collapse to `spamco.example`, and that domain
appears only once in the result.

### Notes

- Domains from `mailto_domains()` are normalised before deduplication;
domains from `embedded_urls()` are also normalised.  This differs from
`mailto_domains()` itself, which stores the full subdomain (e.g.
`sub.spamco.example`) in its `domain` key.  The loss of subdomain
granularity is intentional: `all_domains()` is designed for registrar-
and ISP-level lookups, where the registrable domain is the relevant unit.
- The returned strings are lower-cased.  No trailing dot is ever present.
- The order of elements is: URL-host domains first (in the order URLs were
first seen), followed by contact domains (in the order they were first
collected by `mailto_domains()`), with any domain already seen from the
URL pass omitted from the contact-domain pass.
- A domain that appears only as a subdomain in one source and only as a
registrable domain in another source will still be deduplicated correctly,
because both are normalised to the same registrable form before the
deduplication check.
- Calling `all_domains()` does not interfere with or invalidate the caches
of `embedded_urls()` or `mailto_domains()`; those methods can still be
called afterwards to retrieve their full detail.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification

    # A list (possibly empty) of plain strings:
    (
        {
            type  => SCALAR,
            regex => qr/^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/,
            # Lower-cased registrable domain; no trailing dot;
            # at least two dot-separated labels.
        },
        # ... one string per unique registrable domain, in first-seen order
    )

    # Empty list when the message contains no URLs and no contact domains.

## sending\_software()

Returns information extracted from headers that identify the software or
server-side infrastructure used to compose or inject the message.  These
headers are injected by email clients, bulk-mailing libraries, and shared
hosting control panels, and are often the most direct evidence of how the
spam was sent and from which server.

Headers examined: `X-Mailer`, `User-Agent`, `X-PHP-Originating-Script`,
`X-Source`, `X-Source-Args`, `X-Source-Host`.

The `X-PHP-Originating-Script`, `X-Source`, and `X-Source-Host` headers
in particular are injected automatically by many shared hosting providers
(cPanel, Plesk, DirectAdmin) and reveal the exact PHP script path and
hostname responsible.  A hosting abuse team can use these values to
identify the compromised or malicious account immediately, without needing
to search logs.

The data is extracted synchronously during `parse_email()` with no network
I/O.  This method simply returns the pre-built list.

### Usage

    $analyser->parse_email($raw);
    my @sw = $analyser->sending_software();

    for my $s (@sw) {
        printf "%-30s : %s\n", $s->{header}, $s->{value};
        printf "  Note: %s\n", $s->{note};
    }

    # Check for shared-hosting injection headers
    my @hosting = grep {
        $_->{header} =~ /^x-(?:php-originating-script|source)/
    } @sw;

    if (@hosting) {
        print "Shared-hosting script detected -- report to hosting abuse team:\n";
        print "  $_->{header}: $_->{value}\n" for @hosting;
    }

    # Extract the mailer name if present
    my ($mailer) = grep { $_->{header} eq 'x-mailer' } @sw;
    printf "Sent with: %s\n", $mailer->{value} if $mailer;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list (not an arrayref) of hashrefs, one per recognised software-fingerprint
header that was present in the message, in alphabetical order of header name.
Returns an empty list if none of the watched headers are present, or if
`parse_email()` has not been called.

    {
        header => 'X-PHP-Originating-Script',
        value  => '1000:newsletter.php',
        note   => 'PHP script on shared hosting - report to hosting abuse team',
    }

Each hashref contains exactly three keys, all always present:

- `header` (string)

    The header name, lower-cased.  One of the six values listed in the
    Algorithm section below.

- `value` (string)

    The header value exactly as it appeared in the message (not decoded or
    transformed in any way).

- `note` (string)

    A fixed, human-readable annotation describing what this header represents
    and the recommended action.  The note string is determined by the header
    name and is the same for all messages; it is not derived from the value.
    See the Algorithm section for the note associated with each header.

### Side Effects

None.  All data is collected during `parse_email()` and this method
only returns the pre-collected list.  No network I/O is performed.

### Algorithm: headers examined

The following six headers are examined during `parse_email()`.  They are
checked in alphabetical order; the result list preserves that order
(i.e. `user-agent` appears before `x-mailer` which appears before
`x-php-originating-script`, etc.).  At most one entry per header name is
produced even if the header appears more than once; the first occurrence is
used.

- `user-agent`

    Note: `"Email client identifier"`

    Set by some email clients (Thunderbird, Evolution) as an alternative to
    `X-Mailer`.  Identifies the application that composed the message.

- `x-mailer`

    Note: `"Email client or bulk-mailer identifier"`

    The most widely used header for identifying the sending application.
    Values range from standard clients (`"Apple Mail"`, `"Microsoft Outlook"`)
    to bulk-mailing libraries (`"PHPMailer 6.0"`, `"MailMate"`).  Its presence
    in spam often reveals the library used to generate the campaign.

- `x-php-originating-script`

    Note: `"PHP script on shared hosting -- report to hosting abuse team"`

    Injected by cPanel and similar shared-hosting control panels when a PHP
    script sends mail via the local MTA.  The value typically takes the form
    `uid:script.php` (e.g. `"1000:newsletter.php"`), directly identifying
    the Unix user account and the script responsible.  This is the single most
    actionable header for shared-hosting abuse reports.

- `x-source`

    Note: `"Source file on shared hosting -- report to hosting abuse team"`

    Also injected by shared-hosting platforms, typically containing the full
    filesystem path to the sending script (e.g.
    `"/home/user/public_html/contact.php"`).  Complements
    `X-PHP-Originating-Script`.

- `x-source-args`

    Note: `"Command-line args injected by shared hosting provider"`

    The command-line arguments of the process that sent the mail, injected by
    some hosting platforms.  May reveal interpreter invocations or script
    parameters useful for forensic analysis.

- `x-source-host`

    Note: `"Sending hostname injected by shared hosting provider"`

    The hostname of the server that submitted the message, injected by the
    hosting platform.  Useful when the IP in the `Received:` chain is a shared
    outbound relay rather than the originating server.

### Notes

- The result list is reset to empty by each call to `parse_email()`.  If no
watched headers are present in the current message, the list is empty.
- The alphabetical ordering of entries is a side effect of iterating over
the `%sw_notes` hash in sorted key order.  It is stable across calls on
the same message.
- Header names are stored lower-cased (e.g. `'x-mailer'`, not `'X-Mailer'`).
Header values are stored verbatim, preserving the original case and
whitespace.
- The `note` field is a fixed annotation string chosen by the module, not
text extracted from the message.  It is safe to display directly in reports
without sanitisation.
- If both `X-PHP-Originating-Script` and `X-Source` are present (common on
cPanel systems), both are returned as separate list entries.  A caller
building a hosting abuse report should include all entries whose `header`
begins with `x-`.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification

    # A list (possibly empty) of hashrefs, in alphabetical header-name order:
    (
        {
            type => HASHREF,
            keys => {
                header => {
                    type  => SCALAR,
                    regex => qr/^(?:user-agent|x-mailer|x-php-originating-script
                                   |x-source|x-source-args|x-source-host)$/x,
                },
                value => {
                    type => SCALAR,
                    # Verbatim header value; may be any non-empty string.
                },
                note => {
                    type  => SCALAR,
                    # Fixed annotation string; one of the six strings
                    # documented in the Algorithm section above.
                },
            },
        },
        # ... one hashref per recognised header present, alphabetical order
    )

    # Empty list when none of the six watched headers are present.

## received\_trail()

Returns the per-hop tracking data extracted from the `Received:` header
chain: the IP address, envelope recipient address, and server-assigned
session ID for each relay that handled the message.

When filing an abuse report with a transit ISP or relay operator, these
are the identifiers their postmaster team needs to look up the specific
SMTP session in their mail logs.  Without the session ID or envelope
recipient, an ISP typically cannot locate a single message among billions
of log entries; with them, the lookup takes seconds.

The data is extracted synchronously during `parse_email()` with no network
I/O.  This method simply returns the pre-built list.

### Usage

    $analyser->parse_email($raw);
    my @trail = $analyser->received_trail();

    for my $hop (@trail) {
        printf "Hop IP : %s\n",  $hop->{ip}       // '(unknown)';
        printf "  For  : %s\n",  $hop->{for}       if defined $hop->{for};
        printf "  ID   : %s\n",  $hop->{id}        if defined $hop->{id};
        printf "  Raw  : %s\n",  $hop->{received};
        print  "\n";
    }

    # Build a list of session IDs to include in an abuse report
    my @ids = map  { "$_->{ip}: id $_->{id}" }
              grep { defined $_->{id} }
              @trail;

    # Find which ISP handled a particular relay IP
    my ($hop) = grep { ($_->{ip} // '') eq '91.198.174.5' } @trail;
    if ($hop) {
        print "Session ID at that relay: $hop->{id}\n" if defined $hop->{id};
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list (not an arrayref) of hashrefs, one per `Received:` hop from which
at least one of an IP address, an envelope recipient address, or a server
session ID could be extracted, in oldest-first order (i.e. the first element
is the outermost relay, the last element is the most recent hop before your
own server).  Returns an empty list if no `Received:` headers are present
or none yielded any extractable data, or if `parse_email()` has not been
called.

    (
      { received => '...raw header...', ip => '1.2.3.4',
        for => 'victim@example.com', id => 'ABC123' },
      ...
    )

Each hashref contains exactly four keys:

- `received` (string, always present)

    The complete raw value of the `Received:` header for this hop, exactly as
    it appeared in the message.  Suitable for including verbatim in an abuse
    report so the receiving ISP can see the full context.

- `ip` (string or undef)

    The IPv4 address extracted from this `Received:` hop, or `undef` if no
    recognisable IPv4 address was found.  Uses the same four-pattern extraction
    priority as `originating_ip()`: bracketed `[1.2.3.4]` first, then
    parenthesised, then `from hostname addr`, then any bare dotted-quad as a
    last resort.  Private, reserved, and trusted IPs are **not** filtered here;
    all IPs including RFC 1918 addresses are returned as found.  (Filtering is
    applied only by `originating_ip()`.)

- `for` (string or undef)

    The envelope recipient address extracted from the `for` clause of the
    `Received:` header (e.g. `for <victim@example.com>`), or `undef`
    if no such clause is present or it does not contain a fully-qualified email
    address (one with both a local part and a domain containing at least one
    dot).  Bare postmaster addresses, `for multiple recipients`, and similar
    non-address forms are not captured and result in `undef`.

- `id` (string or undef)

    The server's internal session or queue identifier from the `id` clause
    of the `Received:` header (e.g. `with ESMTP id ABC123XYZ`), or `undef`
    if no `id` clause is present.  The value is a single whitespace-delimited
    token of word characters and dots; longer or more structured ID formats may
    be truncated at the first whitespace boundary.

### Side Effects

None.  All data is collected during `parse_email()` and this method only
returns the pre-collected list.  No network I/O is performed.

### Algorithm: extraction and ordering

During `parse_email()`, the `Received:` headers are walked in reverse
message order (i.e. oldest hop first, which is the same order as
`originating_ip()`'s chain walk).  For each header:

1. The IP address is extracted using the same four-pattern priority sequence
documented in `originating_ip()`.
2. The envelope recipient is extracted with the pattern
`\bfor\s+<?([^\s`\]+@\[\\w.-\]+\\.\[\\w\]+)>?> (case-insensitive).  The
domain portion of the address must contain at least one dot; single-label
names such as `postmaster` are not matched.
3. The session ID is extracted with the pattern `\bid\s+([\w.-]+)`
(case-insensitive), capturing the first word-character token following the
keyword `id`.
4. If none of the three fields can be extracted (all are `undef`), the hop is
silently discarded and does not appear in the result list.  This suppresses
internal or synthetic hops that carry no useful tracking information.

The result list therefore contains only hops that carry at least one
actionable piece of tracking data.

### Notes

- The result list is reset to empty by each call to `parse_email()`.  It
reflects the `Received:` headers of the current message only.
- Oldest-first ordering means `$trail[0]` is the first relay the message
passed through after leaving the sender, and `$trail[-1]` is the last hop
before your own server.  This is the natural order for walking the chain
when composing a forwarded abuse report.
- `ip` may be `undef` for a hop that nonetheless has a valid `for` or
`id` field -- for example, a `Received:` header added by a local
delivery agent that does not record an IP.  Always test `defined
$hop->{ip}` before using it.
- `for` and `id` are `undef`, not the empty string, when absent.  `ip`
is also `undef`, not `'(unknown)'` as in some other methods.  All four
fields must be tested with `defined`, not boolean truthiness, to
distinguish between absent and empty.
- `report()` applies an additional filter when displaying this data: it only
shows hops where `id` or `for` is defined, suppressing hops where only
an IP was found.  `received_trail()` itself returns all hops with any
extractable data, including IP-only hops, giving callers the full picture.
- The `received` field is the unfolded header value as stored after RFC 2822
line-folding is removed during `parse_email()`.  Continuation whitespace
is replaced with a single space; the value will not contain embedded
newlines.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification

    # A list (possibly empty) of hashrefs, oldest-hop first:
    (
        {
            type => HASHREF,
            keys => {
                received => {
                    type => SCALAR,
                    # Complete unfolded Received: header value; always defined.
                },
                ip => {
                    type     => SCALAR,
                    optional => 1,  # present but may be undef
                    regex    => qr/^\d{1,3}(?:\.\d{1,3}){3}$/,
                },
                for => {
                    type     => SCALAR,
                    optional => 1,  # present but may be undef
                    # Fully-qualified email address: local@domain.tld
                    regex    => qr/^[^\s@]+\@[\w.-]+\.[a-zA-Z]{2,}$/,
                },
                id => {
                    type     => SCALAR,
                    optional => 1,  # present but may be undef
                    regex    => qr/^[\w.-]+$/,
                },
            },
        },
        # ... one hashref per hop with at least one extractable field,
        #     in oldest-first (outermost relay first) order
    )

    # Empty list when no Received: headers are present or none yielded
    # any extractable data.

## risk\_assessment()

Evaluates the message against a set of heuristic checks and returns an
overall risk level, a weighted numeric score, and a list of every specific
red flag that contributed to the score.

The assessment covers five categories: originating IP characteristics, email
authentication results, `Date:` header validity, identity and header
consistency, and URL and domain properties.  Each finding is assigned a
severity, a machine-readable flag name, and a human-readable detail string.

The result is computed once and cached; subsequent calls on the same object
return the same hashref without repeating any analysis.  Calling
`risk_assessment()` also implicitly triggers `originating_ip()`,
`embedded_urls()`, and `mailto_domains()` if they have not already been
called, performing all associated network I/O.

### Usage

    $analyser->parse_email($raw);
    my $risk = $analyser->risk_assessment();

    printf "Risk level : %s (score: %d)\n", $risk->{level}, $risk->{score};

    for my $f (@{ $risk->{flags} }) {
        printf "  [%-6s] %s\n    %s\n",
            $f->{severity}, $f->{flag}, $f->{detail};
    }

    # Gate an automated report on HIGH level only
    if ($risk->{level} eq 'HIGH') {
        send_abuse_report($analyser->abuse_report_text());
    }

    # Collect only HIGH and MEDIUM flags for a summary
    my @significant = grep { $_->{severity} =~ /^(?:HIGH|MEDIUM)$/ }
                      @{ $risk->{flags} };

    # Check for a specific flag
    my ($flag) = grep { $_->{flag} eq 'recently_registered_domain' }
                 @{ $risk->{flags} };
    warn "Phishing domain suspected\n" if $flag;

    # INFO level means no actionable red flags
    if ($risk->{level} eq 'INFO') {
        print "No significant red flags detected.\n";
    }

### Arguments

None.  `parse_email()` must have been called first.

### Returns

Returns a hashref with an overall risk level and a list of specific
red flags found in the message:

    {
        level => 'HIGH',          # HIGH | MEDIUM | LOW | INFO
        score => 7,               # raw weighted score
        flags => [
            { severity => 'HIGH',   flag => 'recently_registered_domain',
              detail => 'firmluminary.com registered 2025-09-01 (< 180 days ago)' },
            { severity => 'MEDIUM', flag => 'residential_sending_ip',
              detail => 'rDNS 120-88-161-249.tpgi.com.au looks like a broadband line' },
            { severity => 'MEDIUM', flag => 'url_shortener',
              detail => 'bit.ly used - real destination hidden' },
            ...
        ],
    }

A hashref with exactly three keys, all always present:

- `level` (string)

    The overall risk classification, determined by the weighted score:

        Score >= 9  =>  'HIGH'
        Score >= 5  =>  'MEDIUM'
        Score >= 2  =>  'LOW'
        Score <  2  =>  'INFO'

    `'INFO'` means either no flags were raised or only zero-weight (INFO
    severity) flags were raised.  It does not mean the message is definitely
    legitimate; it means no significant heuristic evidence of spam was found.

- `score` (integer)

    The sum of the weights of all flags raised.  Weights by severity:

        HIGH   => 3
        MEDIUM => 2
        LOW    => 1
        INFO   => 0

    The score is a non-negative integer.  Multiple flags of the same severity
    each contribute their full weight independently; there is no cap on the
    score.

- `flags` (arrayref of hashrefs)

    A reference to a list of flag hashrefs, one per red flag raised, in the
    order they were detected.  Each hashref contains exactly three keys:

    - `severity` (string)

        One of `'HIGH'`, `'MEDIUM'`, `'LOW'`, or `'INFO'`.

    - `flag` (string)

        A lower-cased, underscore-separated machine-readable identifier.  See the
        Algorithm section for the full list of possible flag names.

    - `detail` (string)

        A human-readable sentence describing the specific finding, including the
        values from the message that triggered the flag (domain name, IP address,
        header value, etc.).  Suitable for inclusion in an abuse report or log.

    The arrayref is empty (`[]`) when no flags are raised.

### Side Effects

The first call triggers `originating_ip()`, `embedded_urls()`, and
`mailto_domains()` if they have not already run on the current message.
Each of those methods may perform network I/O as documented in their own
entries.  Specifically:

- `originating_ip()` performs a PTR lookup and RDAP/WHOIS for the
sending IP.
- `embedded_urls()` performs an A lookup and RDAP/WHOIS for each
unique URL hostname.
- `mailto_domains()` performs A, MX, NS, and WHOIS queries for
each unique contact domain.

All results are cached.  Subsequent calls to `risk_assessment()` on the
same object return the cached hashref immediately.  The cache is invalidated
by `parse_email()`.

### Algorithm: flags and scoring

The following flags may be raised.  They are evaluated in five groups, in
the order shown.  The same flag name is never raised more than once per
message.

**Group 1 -- Originating IP** (requires `originating_ip()` to return a
result):

- `residential_sending_ip` (HIGH, weight 3)

    The rDNS of the sending IP matches patterns associated with residential
    broadband or dynamically-assigned addresses: an embedded dotted-quad, or
    any of the substrings `dsl`, `adsl`, `cable`, `broad`, `dial`,
    `dynamic`, `dhcp`, `ppp`, `residential`, `cust`, `home`, `pool`,
    `client`, `user`, `staticN`, or `hostN`.

- `no_reverse_dns` (HIGH, weight 3)

    The sending IP has no PTR record, or the PTR lookup returned the sentinel
    `'(no reverse DNS)'`.  Legitimate mail servers invariably have rDNS.

- `low_confidence_origin` (MEDIUM, weight 2)

    The originating IP was taken from an unverified header (`X-Originating-IP`)
    rather than from the `Received:` chain.  Confidence level is `'low'`.

- `high_spam_country` (INFO, weight 0)

    The sending IP's country code is one of: `CN` (China), `RU` (Russia),
    `NG` (Nigeria), `VN` (Vietnam), `IN` (India), `PK` (Pakistan),
    `BD` (Bangladesh).  Informational only; does not contribute to the score.

**Group 2 -- Email authentication** (from `Authentication-Results:` header):

- `spf_fail` (HIGH, weight 3)

    SPF result is `fail`, `permerror`, `temperror`, `none`, or any value
    other than `pass` or `softfail`.  The sending IP is not authorised by
    the domain's SPF record.

- `spf_softfail` (MEDIUM, weight 2)

    SPF result is `softfail` (`~all`).  The sending IP is not explicitly
    authorised but the domain policy does not hard-fail it.

- `dkim_fail` (HIGH, weight 3)

    DKIM result is present and is any value other than `pass`.

- `dmarc_fail` (HIGH, weight 3)

    DMARC result is present and is any value other than `pass`.

- `dkim_domain_mismatch` (INFO or MEDIUM, weight 0 or 2)

    The DKIM signing domain (`d=` tag) differs from the registrable domain
    of the `From:` address.  Raised at INFO (weight 0) when DKIM passes --
    this is normal for bulk senders using ESPs such as SendGrid or Mailchimp.
    Raised at MEDIUM (weight 2) when DKIM fails or is absent -- a differing
    domain combined with a failed signature is more suspicious.

**Group 3 -- Date: header**:

- `missing_date` (MEDIUM, weight 2)

    No `Date:` header is present, or it contains only whitespace.  Violates
    RFC 5322; common in programmatically-generated spam.

- `suspicious_date` (LOW, weight 1)

    The `Date:` header is present but more than 7 days in the past or more
    than 7 days in the future relative to the time of analysis.  Timezone
    offsets are ignored during comparison (maximum error: approximately 14
    hours, well within the 7-day window).

**Group 4 -- Header identity and consistency**:

- `display_name_domain_spoof` (HIGH, weight 3)

    The `From:` display name contains a domain name (matched against the
    suffixes `.com`, `.net`, `.org`, `.io`, `.co`, `.uk`, `.au`,
    `.gov`, `.edu`) that differs at the registrable level from the actual
    `From:` address domain.  Example: `"PayPal paypal.com" <phish@evil.example>`.

- `free_webmail_sender` (MEDIUM, weight 2)

    The `From:` address belongs to a free webmail provider: Gmail, Yahoo,
    Hotmail, Outlook, Live, AOL, ProtonMail, Yandex, or mail.ru.

- `reply_to_differs_from_from` (MEDIUM, weight 2)

    A `Reply-To:` header is present and its email address differs from the
    `From:` address (case-insensitive comparison).  Replies will be harvested
    by a different address than the apparent sender.

- `undisclosed_recipients` (MEDIUM, weight 2)

    The `To:` header is absent, empty, contains the string `undisclosed`, or
    matches the group-syntax sentinel `:;`.

- `encoded_subject` (LOW, weight 1)

    The `Subject:` header contains a MIME encoded-word sequence
    (`=?charset?encoding?text?=`).  Often used to evade keyword filters.

**Group 5 -- URLs and domains** (from `embedded_urls()` and
`mailto_domains()`):

- `url_shortener` (MEDIUM, weight 2)

    At least one URL hostname is in the built-in URL shortener list (over 25
    services including `bit.ly`, `tinyurl.com`, `t.co`, `ow.ly`, etc.).
    Raised at most once per unique shortener hostname per message.

- `http_not_https` (LOW, weight 1)

    At least one URL uses the plain `http://` scheme rather than `https://`.
    Raised at most once per unique hostname.

- `recently_registered_domain` (HIGH, weight 3)

    At least one contact domain was registered less than 180 days before the
    time of analysis.

- `domain_expires_soon` (HIGH, weight 3)

    At least one contact domain expires within the next 30 days.  Suggests a
    throwaway domain.

- `domain_expired` (HIGH, weight 3)

    At least one contact domain has already passed its expiry date.

- `lookalike_domain` (HIGH, weight 3)

    At least one contact domain contains the name of a well-known brand
    (`paypal`, `apple`, `google`, `amazon`, `microsoft`, `netflix`,
    `ebay`, `instagram`, `facebook`, `twitter`, `linkedin`,
    `bankofamerica`, `wellsfargo`, `chase`, `barclays`, `hsbc`,
    `lloyds`, `santander`) but is not the brand's own canonical domain
    (e.g. `paypal.com`, `paypal.co.uk`).

### Notes

- The `flags` arrayref is a reference to the module's internal list.
Callers must not modify it.  To iterate safely, use `@{ $risk->{flags} }`.
- Flags are not deduplicated across categories.  If `spf_fail` and
`dkim_fail` both apply, both appear in the list and both contribute to
the score.
- `high_spam_country` and `dkim_domain_mismatch` (when DKIM passes)
contribute zero to the score.  Their presence does not change the level
classification, but they appear in the `flags` list so callers can
include them in reports.
- The level thresholds are fixed constants: HIGH >= 9, MEDIUM >= 5, LOW >= 2,
INFO < 2.  They are not configurable.
- `risk_assessment()` does not directly raise flags for domains found only
in URLs (`embedded_urls()` hosts); domain checks in Group 5 apply only
to domains from `mailto_domains()`.  URL hostname checks (shorteners,
HTTP) use the `embedded_urls()` list.
- If `parse_email()` has not been called, or was called with an empty or
malformed message, `risk_assessment()` returns a valid hashref with
`level => 'INFO'`, `score => 0`, and `flags => []`.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification
    {
        type => HASHREF,
        keys => {
            level => {
                type  => SCALAR,
                regex => qr/^(?:HIGH|MEDIUM|LOW|INFO)$/,
            },
            score => {
                type  => SCALAR,
                regex => qr/^\d+$/,  # non-negative integer
            },
            flags => {
                type => ARRAYREF,
                # Reference to a list (possibly empty) of hashrefs:
                # [
                #   {
                #     severity => qr/^(?:HIGH|MEDIUM|LOW|INFO)$/,
                #     flag     => qr/^[a-z][a-z0-9_]+$/,
                #     detail   => SCALAR,  # human-readable string
                #   },
                #   ...
                # ]
            },
        },
    }

## abuse\_report\_text()

Produces a compact, plain-text string intended to be sent as the body of
an abuse report email to an ISP or hosting provider.  It summarises the
risk level, lists every red flag with its detail, identifies the originating
IP and its network owner, lists the abuse contacts, and appends the complete
message headers so the recipient can trace the session in their own logs.

The message body is intentionally omitted to keep the report concise.
Headers are sufficient for an ISP to locate the relevant mail session; the
body adds bulk without aiding the investigation.

This method is the companion to `abuse_contacts()`: call
`abuse_contacts()` to obtain the addresses to send the report to, and
`abuse_report_text()` to obtain the text to send.  Use `report()` instead
when you want a comprehensive analyst-facing document rather than a
send-ready ISP report.

### Usage

    $analyser->parse_email($raw);

    my $text     = $analyser->abuse_report_text();
    my @contacts = $analyser->abuse_contacts();

    for my $c (@contacts) {
        send_email(
            to      => $c->{address},
            subject => 'Abuse report: ' . ($analyser->originating_ip()->{ip} // 'unknown'),
            body    => $text,
        );
    }

    # Print to stdout for manual review before sending
    print $text;

    # Write to file for a ticketing system
    open my $fh, '>', 'abuse_report.txt' or die $!;
    print $fh $text;
    close $fh;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A plain scalar string containing the report text.  The string is
newline-terminated and uses Unix line endings (`\n`) throughout.
The string is never empty; it always contains at least the boilerplate
introduction and the risk-level line, even if no red flags were found.

The report is structured as follows, in order:

- 1. Introduction

    Two fixed lines:

        This is an automated abuse report generated by Email::Abuse::Investigator.
        Please investigate the following spam/phishing message.

- 2. Risk level

        RISK LEVEL: HIGH (score: 11)

- 3. Red flags (omitted if no flags were raised)

        RED FLAGS IDENTIFIED:
          [HIGH] firmluminary.com was registered 2025-09-01 (less than 180 days ago)
          [MEDIUM] rDNS 120-88-161-249.tpgi.com.au looks like a broadband line
          ...

    Each flag is formatted as `[SEVERITY] detail-string`, one per line,
    indented two spaces.  The flag machine-name is not included; only the
    human-readable detail string is shown, matching what a postmaster would
    want to read.

- 4. Originating IP (omitted if `originating_ip()` returns `undef`)

        ORIGINATING IP: 120.88.161.249 (120-88-161-249.tpgi.com.au)
        NETWORK OWNER:  TPG Telecom Limited

- 5. Abuse contacts (omitted if `abuse_contacts()` returns an empty list)

        ABUSE CONTACTS:
          abuse@tpg.com.au (Sending ISP)
          abuse@registrar.example (Domain registrar for firmluminary.com)

- 6. Original message headers

        ------------------------------------------------------------------------
        ORIGINAL MESSAGE HEADERS:
        ------------------------------------------------------------------------
        received: from 120-88-161-249.tpgi.com.au ...
        from: Sender <spammer@firmluminary.com>
        ...

    All parsed headers are emitted, one per line, in the order they appeared
    in the original message.  Header names are lower-cased (as normalised
    during `parse_email()`).  Header values are verbatim.  The message
    body is not included.

### Side Effects

Calls `risk_assessment()`, `originating_ip()`, and `abuse_contacts()`
if they have not already run, which in turn may perform network I/O as
documented in those methods.  All results are cached; the text is not
itself cached, but re-computing it is cheap since all the underlying data
is already cached.

### Notes

- Header names in the output are lower-cased (e.g. `from:`, `received:`),
because that is how they are stored internally after `parse_email()`
normalises them.  Postmasters are accustomed to receiving headers in their
original mixed case; if canonical capitalisation is required, a simple
substitution (`s/^([\w-]+)/\u\L$1/`) will restore it.
- The message body is deliberately excluded.  This avoids transmitting
potentially malicious or offensive content to third parties, keeps the
report below common size limits for abuse mailboxes, and is consistent
with the RFC 2646 / ARF (Abuse Reporting Format) practice of including
only the headers in a first-contact report.  To include the body, callers
can append `$self->{_raw}` directly, though this is not recommended.
- The separator lines are exactly 72 hyphens (`-` x 72), matching the
separator width used by `report()`.
- The output is suitable for use as a plain-text email body.  It is not
ARF (RFC 5965) compliant; it does not include a `message/feedback-report`
MIME part.  For ARF-compliant reporting, use the output of this method as
the human-readable first part and add the ARF metadata separately.
- If `parse_email()` has not been called, all sections that depend on
analysis will be empty (no flags, no originating IP, no contacts) and the
header section will be blank.  The method will not die.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification
    {
        type  => SCALAR,
        # Non-empty plain-text string, newline-terminated.
        # Always defined; never undef.
        # Line endings: Unix LF (\n) only.
        # Minimum content: introduction + risk-level line.
    }

## abuse\_contacts()

Collates the complete set of parties that should receive an abuse report
for this message: the ISP that owns the sending IP, the operators of every
URL host, the web, mail, and DNS hosts of every contact domain, each
domain's registrar, the webmail or ESP account provider identified from
key headers, the DKIM signing organisation, and the ESP identified via
the `List-Unsubscribe:` header.

For each party the method produces the role description, the abuse email
address, a supporting note, and the source of the information.  Addresses
are deduplicated globally: if the same address is discovered through
multiple routes (e.g. Google as both the sending ISP and the owner of a
blogspot.com URL in the message body), it appears only once.  The `role`
string for that entry is the combined description of all routes that found
it, joined by `" and "`, and the `roles` key holds the individual role
strings as an arrayref.

This method is designed to be used together with `abuse_report_text()`:
iterate over the returned contacts to obtain the list of addresses, and
send the text from `abuse_report_text()` to each one.

### Usage

    $analyser->parse_email($raw);
    my @contacts = $analyser->abuse_contacts();

    for my $c (@contacts) {
        printf "Role    : %s\n", $c->{role};
        printf "Send to : %s\n", $c->{address};
        printf "Note    : %s\n", $c->{note}  if $c->{note};
        printf "Source  : %s\n", $c->{via};
        print  "\n";
    }

    # Collect addresses for sending
    my @addresses = map { $_->{address} } @contacts;

    # Filter to WHOIS-discovered contacts only
    my @whois_contacts = grep { $_->{via} =~ /whois/ } @contacts;

    # Check whether any registrar abuse contacts were found
    my @registrar = grep { $_->{role} =~ /registrar/ } @contacts;

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A list (not an arrayref) of hashrefs, one per unique abuse contact address,
in the order they were first discovered.  Returns an empty list if no
actionable abuse contacts can be determined, or if `parse_email()` has
not been called.

Returns a de-duplicated list of hashrefs, one per party that should
receive an abuse report, in priority order:

    {
        role    => 'Sending ISP',          # human-readable role
        address => 'abuse@senderisp.example',
        note    => 'IP block 120.88.0.0/14 owner',
        via     => 'ip-whois',             # ip-whois | domain-whois | provider-table | rdap
    }

Roles produced (in order):

    Sending ISP            - network owner of the originating IP
    URL host               - network owner of each unique web-server IP
    Mail host (MX)         - network owner of the domain's MX record IP
    DNS host (NS)          - network owner of the authoritative NS IP
    Domain registrar       - registrar abuse contact from domain WHOIS
    Account provider       - e.g. Gmail / Outlook for the From:/Sender: account
    DKIM signer            - the organisation whose key signed the message
    ESP / bulk sender      - identified via List-Unsubscribe: domain

Addresses are deduplicated so the same address never appears twice,
even if it is discovered through multiple routes.

Each hashref contains the following keys, all always present:

- `role` (string)

    A human-readable description of the party's relationship to the message.
    When the same address was found via multiple discovery routes, the role
    strings from each route are joined with `" and "` (e.g.
    `"Sending ISP (provider table) and URL host (provider table)"`).
    See the Algorithm section for the full set of role string patterns.

- `roles` (arrayref of strings)

    The individual role strings for each discovery route that found this
    address, in discovery order.  Contains exactly one element when the
    address was found via a single route; two or more elements when multiple
    routes converged on the same address.  The `role` key is always the
    `join(' and ', @{$c-`{roles}})> of this arrayref.

- `address` (string)

    The abuse contact email address, lower-cased.  Always contains an `@`
    sign.  Deduplicated globally: each distinct address appears at most once
    across the entire list, regardless of how many discovery routes found it.

- `note` (string)

    Supporting information about why this party was identified and what action
    to request.  For provider-table entries this is the note from the built-in
    table (which may include a URL to a web-based abuse form).  For WHOIS- and
    RDAP-discovered entries this describes the IP block or domain involved.
    Always defined; may be the empty string for entries where no note is
    available.  When roles are merged, this reflects the note from the first
    discovery route.

- `via` (string)

    The discovery method for the first route that found this address.  One of:

    - `'provider-table'`

        The address was found in the module's built-in table of well-known
        providers (Google, Microsoft, Cloudflare, SendGrid, Mailchimp, etc.).
        Provider-table addresses take priority over WHOIS for the same entity
        because they are curated and point to the right team, whereas generic
        WHOIS contacts sometimes route to NOCs rather than abuse desks.

    - `'ip-whois'`

        The address was obtained from an RDAP or WHOIS lookup on an IP block
        (the sending IP, a URL host IP, or an MX/NS IP).

    - `'domain-whois'`

        The address was obtained from a WHOIS lookup on a domain name (registrar
        abuse contact from the `Registrar Abuse Contact Email:` or equivalent
        field).

### Side Effects

Triggers `originating_ip()`, `embedded_urls()`, and `mailto_domains()`
if they have not already run on the current message, performing all
associated network I/O as documented in those methods.  Additionally
consults the built-in provider table and the cached authentication results;
neither requires network I/O.

The result is not independently cached.  Each call recomputes the contact
list from the cached results of the underlying methods.  Because those
results are cached, subsequent calls are fast (no network I/O), but they
do re-execute the collation and deduplication logic.

### Algorithm: discovery routes

Contacts are discovered through six routes, applied in order.
Deduplication is global across all routes: if an address is found by
more than one route, a single entry is kept and the role strings from
every route that found it are accumulated into `roles` and joined into
`role`.  An entry is suppressed entirely if its address is empty, does
not contain an `@` sign, or is the sentinel `'(unknown)'`.

- Route 1 -- Sending ISP

    The originating IP from `originating_ip()` is looked up in the built-in
    provider table (by rDNS hostname, stripping subdomains until a match is
    found).  If found, a `provider-table` entry is added with role
    `"Sending ISP (provider table)"`.

    The `abuse` field from `originating_ip()` (obtained from RDAP/WHOIS) is
    then added as an `ip-whois` entry with role `"Sending ISP"`, unless it
    is `'(unknown)'`.

- Route 2 -- URL hosts

    For each unique hostname in `embedded_urls()`, the built-in provider
    table is consulted (by hostname, stripping subdomains).  If found, a
    `provider-table` entry is added with role `"URL host (provider table)"`.

    The `abuse` field from the URL hashref is then added as an `ip-whois`
    entry with role `"URL host"`, unless it is `'(unknown)'`.

    Each unique hostname is processed at most once; multiple URLs on the same
    host do not generate multiple contacts.

- Route 3 -- Contact domain hosting and registration

    For each domain from `mailto_domains()`, up to four contacts may be
    generated:

    - **Web host**: if `web_abuse` is present, both a provider-table lookup
    on the domain name and the WHOIS-derived `web_abuse` address are tried.
    Role: `"Web host of $domain"` or `"Web host of $domain (provider table)"`.
    - **Mail host (MX)**: if `mx_abuse` is present.
    Role: `"Mail host (MX) for $domain"`, via `ip-whois`.
    - **DNS host (NS)**: if `ns_abuse` is present.
    Role: `"DNS host (NS) for $domain"`, via `ip-whois`.
    - **Domain registrar**: if `registrar_abuse` is present.
    Role: `"Domain registrar for $domain"`, via `domain-whois`.

- Route 4 -- Account provider

    The `From:`, `Reply-To:`, `Return-Path:`, and `Sender:` header values
    are inspected in that order.  The domain portion of each address is looked
    up in the built-in provider table (stripping subdomains until a match).
    If found, a `provider-table` entry is added with role
    `"Account provider ($header: $value)"`.  This identifies the webmail
    or ESP service that hosts the sender's account.

- Route 5 -- DKIM signing organisation

    The `d=` tag from the `DKIM-Signature:` header is looked up in the
    built-in provider table.  If found, a `provider-table` entry is added
    with role `"DKIM signer (provider table): $domain"`.  The full domain
    pipeline (web/MX/NS/WHOIS) for this domain is already handled via Route 3
    through `mailto_domains()`.

- Route 6 -- ESP / bulk sender (List-Unsubscribe)

    Both `https://` URLs and `mailto:` addresses in the `List-Unsubscribe:`
    header are parsed for their domains.  Each unique domain is looked up in
    the built-in provider table.  If found, a `provider-table` entry is added
    with role `"ESP / bulk sender (List-Unsubscribe: $domain)"`.

### Notes

- Deduplication is by lower-cased address only.  Two contacts with different
roles but the same address result in a single entry using the data from
whichever route found it first.  The later route's role and note are
silently discarded.
- The provider table contains curated entries for approximately 50
well-known domains including major webmail providers (Gmail, Outlook,
Yahoo, Apple), CDNs and hosters (Cloudflare, Fastly, Akamai, AWS,
DigitalOcean, Vultr, Hetzner, Contabo, Leaseweb, M247, OVH, Linode),
ESPs (SendGrid, Mailchimp, Mailgun, Postmark, Brevo, Klaviyo, Campaign
Monitor, Constant Contact, HubSpot), registrars (GoDaddy, Namecheap),
and ISPs (TPG, Internode).  Subdomain matching strips labels left-to-right
until a match is found, so `mail.sendgrid.net` matches `sendgrid.net`.
- Provider-table entries take priority in the sense that they are added
first; if the WHOIS address happens to match the provider-table address,
the WHOIS entry is suppressed by deduplication.  If they differ (unusual
but possible), both are added.
- The result is not cached.  If you call `abuse_contacts()` multiple times
on the same object, the full collation runs each time.  If this is a
concern, store the result in a variable:
`my @contacts = $analyser->abuse_contacts()`.
- An empty list is returned if the message has no usable originating IP, no
extractable URLs, no contact domains, and no recognised provider-table
matches.  This is unusual in practice but can occur for very sparse or
malformed messages.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification

    # A list (possibly empty) of hashrefs, in discovery order:
    (
        {
            type => HASHREF,
            keys => {
                role => {
                    type => SCALAR,
                    # Human-readable role description; always defined,
                    # may contain inline domain/IP/header values.
                },
                address => {
                    type  => SCALAR,
                    regex => qr/^[^\s@]+\@[^\s@]+$/,
                    # Lower-cased email address; unique across the list.
                },
                note => {
                    type => SCALAR,
                    # Supporting detail; always defined, may be empty string.
                },
                via => {
                    type  => SCALAR,
                    regex => qr/^(?:provider-table|ip-whois|domain-whois)$/,
                },
            },
        },
        # ... one hashref per unique address, in first-discovered order
    )

    # Empty list when no actionable abuse contacts can be determined.

## report()

Returns a formatted plain-text abuse report.

Produces a comprehensive, analyst-facing plain-text report covering all
findings from every analysis method.  It is the single-document summary
of everything the module knows about a message: envelope fields, risk
assessment, originating host, sending software, received chain tracking
IDs, embedded URLs grouped by hostname, contact domain intelligence, and
the recommended abuse contacts.

Use `report()` when you want a human-readable document for review,
logging, or a ticketing system.  Use `abuse_report_text()` when you want
a compact string to transmit to an ISP abuse desk.

### Usage

    $analyser->parse_email($raw);
    my $text = $analyser->report();
    print $text;

    # Write to a file
    open my $fh, '>', 'report.txt' or die $!;
    print $fh $analyser->report();
    close $fh;

    # Log the risk level line from the report
    my ($level_line) = $analyser->report() =~ /(\[ RISK ASSESSMENT: [^\]]+\])/;
    $logger->info($level_line);

    # Check idempotency -- safe to call multiple times
    my $r1 = $analyser->report();
    my $r2 = $analyser->report();
    # $r1 eq $r2 is always true for the same parsed message

### Arguments

None.  `parse_email()` must have been called first.

### Returns

A plain scalar string containing the full report, newline-terminated,
using Unix line endings (`\n`) throughout.  The string is never empty;
it always contains at least the header banner and envelope summary section.

The report is structured as nine sections separated by blank lines, in
this fixed order:

- 1. Banner

        ========================================================================
          Email::Abuse::Investigator Report  (vX.XX)
        ========================================================================

    A row of 72 equals signs, the module name and version number, and a
    closing row of 72 equals signs.

- 2. Envelope summary

    Up to six header fields, each decoded from MIME encoded-words where
    applicable.  If a field was encoded, the decoded form is shown first
    followed by the raw encoded original in brackets:

        From           : PayPal Security <phish@evil.example>
        Reply-to       : Replies <harvest@collector.example>
        Return-path    : <phish@evil.example>
        Subject        : Account Alert  [encoded: =?UTF-8?B?QWNjb3VudA==?=]
        Date           : Mon, 01 Jan 2024 00:00:00 +0000
        Message-id     : <msg001@evil.example>

    Fields examined (in order): `From:`, `Reply-To:`, `Return-Path:`,
    `Subject:`, `Date:`, `Message-ID:`.  Fields not present in the message
    are silently omitted.

- 3. Risk assessment

        [ RISK ASSESSMENT: HIGH (score: 11) ]
          [HIGH] firmluminary.com was registered 2025-09-01 (less than 180 days ago)
          [MEDIUM] rDNS 120-88-161-249.tpgi.com.au looks like a broadband/residential line
          ...

    Or, when no flags were raised:

        [ RISK ASSESSMENT: INFO (score: 0) ]
          (no specific red flags detected)

    Each flag is shown as `[SEVERITY] detail-string`.

- 4. Originating host

        [ ORIGINATING HOST ]
          IP           : 120.88.161.249
          Reverse DNS  : 120-88-161-249.tpgi.com.au
          Country      : AU
          Organisation : TPG Telecom Limited
          Abuse addr   : abuse@tpg.com.au
          Confidence   : high
          Note         : First external hop in Received: chain

    Or `(could not determine originating IP)` if `originating_ip()` returns
    `undef`.  Fields with no value are omitted.

- 5. Sending software (omitted entirely if no software headers found)

        [ SENDING SOFTWARE / INFRASTRUCTURE CLUES ]
          x-php-originating-script : 1000:mailer.php
          Note           : PHP script on shared hosting -- report to hosting abuse team

    One block per detected header, with its note.

- 6. Received chain tracking IDs (omitted if no hops have id or for fields)

        [ RECEIVED CHAIN TRACKING IDs ]
          (Supply these to the relevant ISP abuse team to trace the session)

          IP           : 91.198.174.5
          Envelope for : victim@bandsman.co.uk
          Server ID    : ABC123XYZ

    Only hops that have at least one of a session ID (`id`) or envelope
    recipient (`for`) are shown; IP-only hops are suppressed.  Oldest hop
    first.

- 7. Embedded HTTP/HTTPS URLs

        [ EMBEDDED HTTP/HTTPS URLs ]
          Host         : bit.ly  *** URL SHORTENER - real destination hidden ***
          IP           : 67.199.248.11
          Country      : US
          Organisation : Bit.ly LLC
          Abuse addr   : abuse@bit.ly
          URL          : https://bit.ly/scam123

    URLs are grouped by hostname; if multiple URLs share a hostname, all
    paths are listed together under the single host block.  Known URL
    shorteners are annotated inline.  Shown as `(none found)` when the
    body contains no HTTP/HTTPS URLs.

- 8. Contact / reply-to domains

        [ CONTACT / REPLY-TO DOMAINS ]
          Domain       : firmluminary.com
          Found in     : From: header
          *** WARNING: RECENTLY REGISTERED - possible phishing domain ***
          Registered   : 2025-09-01
          Expires      : 2026-09-01
          Registrar    : GoDaddy.com LLC
          Reg. abuse   : abuse@godaddy.com
          Web host IP  : 104.21.30.10
          Web host org : Cloudflare Inc
          Web abuse    : abuse@cloudflare.com
          MX host      : mail.firmluminary.com
          MX IP        : 198.51.100.5
          MX org       : Hosting Corp
          MX abuse     : abuse@hostingcorp.example
          NS host      : ns1.cloudflare.com
          NS IP        : 173.245.58.51
          NS org       : Cloudflare Inc
          NS abuse     : abuse@cloudflare.com

    One block per domain from `mailto_domains()`.  Recently-registered
    domains receive an inline warning banner.  Shown as `(none found)`
    when no qualifying contact domains are present.

- 9. Where to send abuse reports

        [ WHERE TO SEND ABUSE REPORTS ]
          Role         : Sending ISP
          Send to      : abuse@tpg.com.au
          Note         : Network owner of originating IP 120.88.161.249 (TPG Telecom)
          Discovered   : ip-whois

          Role         : Domain registrar for firmluminary.com
          Send to      : abuse@godaddy.com
          Note         : Registrar: GoDaddy.com LLC
          Discovered   : domain-whois

    One block per contact from `abuse_contacts()`.  Shown as
    `(no abuse contacts could be determined)` when the list is empty.

The report ends with a closing row of 72 equals signs.

### Side Effects

Calls `risk_assessment()`, `originating_ip()`, `sending_software()`,
`received_trail()`, `embedded_urls()`, `mailto_domains()`, and
`abuse_contacts()` if they have not already run on the current message,
performing all associated network I/O as documented in those methods.  All
underlying results are cached; the report text itself is not cached, but
re-computation is inexpensive since the data is already available.

### Notes

- The report is idempotent: calling `report()` multiple times on the same
object always returns an identical string, because all underlying methods
are cached.
- MIME encoded-words in the `From:`, `Subject:`, and other displayed
headers are decoded for readability.  When a header was encoded, both the
decoded form and the raw encoded original are shown, so the report is
useful both for human reading and for log parsing.
- URL hosts in section 7 are grouped by hostname and shown in first-seen
order.  Multiple URLs on the same host are listed together rather than
repeating the host's IP and WHOIS information, keeping the output compact
even when a message contains dozens of tracking-pixel and click-redirect
URLs all on the same CDN.
- The received-trail section (section 6) filters out hops that have only an
IP address and no `id` or `for` clause.  The full unfiltered trail is
available via `received_trail()`.
- Section 5 (sending software) and section 6 (received chain tracking IDs)
are entirely omitted -- no heading, no placeholder text -- when no relevant
headers are present.  All other sections always appear, using a
`(none found)` or equivalent placeholder when their data is empty.
- The version number in the banner is the value of `$Email::Abuse::Investigator::VERSION`
at the time `report()` is called.

### API Specification

#### Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

#### Output

    # Return::Set compatible specification
    {
        type  => SCALAR,
        # Non-empty plain-text string, newline-terminated (\n).
        # Always defined; never undef.
        # Line endings: Unix LF (\n) only.
        # Structure: nine fixed sections in the order documented above,
        #            separated by blank lines, framed by 72-character
        #            equals-sign banners.
    }

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# ALGORITHM: DOMAIN INTELLIGENCE PIPELINE

For each unique non-infrastructure domain found in the email, the module
runs the following pipeline:

    Domain name
        |
        +-- A record  --> web hosting IP  --> RDAP --> org + abuse contact
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

# WHY WEB HOSTING != MAIL HOSTING != DNS HOSTING

A fraudster registering `sminvestmentsupplychain.com` might:

- Register the domain at GoDaddy (registrar)
- Point the NS records at Cloudflare (DNS/CDN)
- Have no web server at all (A record absent)
- Route the MX records to Google Workspace or similar

Each of these parties has an abuse contact, and each can independently
take action to disrupt the spam/phishing operation.  The module reports
all of them separately.

# RECENTLY-REGISTERED FLAG

Phishing domains are very commonly registered hours or days before the
spam run.  The module flags any domain whose WHOIS creation date is
less than 180 days ago with `recently_registered => 1`.

# SEE ALSO

[Net::DNS](https://metacpan.org/pod/Net%3A%3ADNS), [LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent), [HTML::LinkExtor](https://metacpan.org/pod/HTML%3A%3ALinkExtor), [MIME::QuotedPrint](https://metacpan.org/pod/MIME%3A%3AQuotedPrint),
[ARIN RDAP](https://rdap.arin.net/)

# REPOSITORY

[https://github.com/nigelhorne/Email-Abuse-Investigator](https://github.com/nigelhorne/Email-Abuse-Investigator)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-email-abuse-investigator at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Abuse-Investigator](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Abuse-Investigator)
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Mail::Message::Abuse

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/Email-Abuse-Investigator](https://metacpan.org/dist/Email-Abuse-Investigator)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Abuse-Investigator](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Abuse-Investigator)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=Email-Abuse-Investigator](http://matrix.cpantesters.org/?dist=Email-Abuse-Investigator)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=Mail::Message::Abuse](http://deps.cpantesters.org/?module=Mail::Message::Abuse)

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
