package Email::Abuse::Investigator;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use IO::Select;
use IO::Socket::INET;
BEGIN { $Sub::Private::config{mode} = 'enforce' }
use Sub::Private;
use Sub::Protected;
use MIME::QuotedPrint qw( decode_qp );
use MIME::Base64 qw( decode_base64 );
use Object::Configure;
use Params::Get;
use Params::Validate::Strict;
use Readonly;
use Readonly::Values::Months;
use Socket qw( inet_aton inet_ntoa AF_INET );
use Time::Piece;

=head1 NAME

Email::Abuse::Investigator - Analyse spam email to identify originating hosts,
hosted URLs, and suspicious domains

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

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

=head1 DESCRIPTION

C<Email::Abuse::Investigator> examines the raw source of a spam/phishing e-mail
and answers the questions manual abuse investigators ask:

=over 4

=item 1. Where did the message really come from?

Walks the C<Received:> chain, skips private/trusted IPs, and identifies the
first external hop.  Enriches with rDNS, WHOIS/RDAP org name and abuse
contact.  Both IPv4 and IPv6 addresses are supported.

=item 2. Who hosts the advertised web sites?

Extracts every C<http://> and C<https://> URL from both plain-text and HTML
parts, resolves each hostname to an IP, and looks up the network owner.

=item 3. Who owns the reply-to / contact domains?

Extracts domains from C<mailto:> links, bare e-mail addresses in the body,
the C<From:>/C<Reply-To:>/C<Sender:>/C<Return-Path:> headers, C<DKIM-Signature: d=>
(the signing domain), C<List-Unsubscribe:> (the ESP or bulk-sender domain), and the
C<Message-ID:> domain.  For each unique domain it gathers:

=over 8

=item * Domain registrar and registrant (WHOIS)

=item * Web-hosting IP and network owner (A record -> RDAP)

=item * Mail-hosting IP and network owner (MX record -> RDAP)

=item * DNS nameserver operator (NS record -> RDAP)

=item * Whether the domain was recently registered (potential flag)

=back

=back

=cut

# -----------------------------------------------------------------------
# Optional modules -- gracefully degraded when absent
# -----------------------------------------------------------------------

# Net::DNS enables MX, NS, AAAA lookups; falls back to gethostbyname
my $HAS_NET_DNS;

# LWP::UserAgent enables RDAP queries; falls back to raw WHOIS
my $HAS_LWP;
my $HAS_CONN_CACHE;

# HTML::LinkExtor enables structural HTML link extraction
my $HAS_HTML_LINKEXTOR;

# CHI enables a persistent cross-message cache for IP/domain data
my $HAS_CHI;

# IO::Socket::IP provides dual-stack (IPv4+IPv6) socket support
my $HAS_IO_SOCKET_IP;

# Domain::PublicSuffix enables accurate eTLD+1 normalisation
my $HAS_PUBLIC_SUFFIX;

# AnyEvent::DNS enables parallel DNS queries
my $HAS_ANYEVENT_DNS;

BEGIN {
	$HAS_NET_DNS       = eval { require Net::DNS;           1 };
	$HAS_LWP           = eval { require LWP::UserAgent;     1 };
	$HAS_CONN_CACHE    = eval { require LWP::ConnCache;     1 };
	$HAS_HTML_LINKEXTOR= eval { require HTML::LinkExtor;    1 };
	$HAS_CHI           = eval { require CHI;                1 };
	$HAS_IO_SOCKET_IP  = eval { require IO::Socket::IP;     1 };
	$HAS_PUBLIC_SUFFIX = eval { require Domain::PublicSuffix; 1 };
	$HAS_ANYEVENT_DNS  = eval { require AnyEvent::DNS;      1 };
}

# -----------------------------------------------------------------------
# Constants -- all magic numbers and strings live here
# -----------------------------------------------------------------------

# WHOIS protocol port (IANA-assigned)
Readonly::Scalar my $WHOIS_PORT        => 43;

# Bytes to read per sysread() call from a WHOIS socket
Readonly::Scalar my $WHOIS_READ_CHUNK  => 4096;

# Maximum WHOIS response bytes stored in whois_raw (keep reports compact)
Readonly::Scalar my $WHOIS_RAW_MAX     => 2048;

# Maximum multipart nesting depth (recursion guard -- RFC 2046 has no limit
# but we cap it to prevent stack exhaustion on crafted messages)
Readonly::Scalar my $MAX_MULTIPART_DEPTH => 20;

# Number of days before registration that triggers recently_registered flag
Readonly::Scalar my $RECENT_REG_DAYS   => 180;

# Number of days ahead of expiry that triggers domain_expires_soon flag
Readonly::Scalar my $EXPIRY_WARN_DAYS  => 30;

# Seconds in a day -- used in date arithmetic throughout
Readonly::Scalar my $SECS_PER_DAY      => 86400;

# Suspicious date window: dates outside +/- 7 days raise a flag
Readonly::Scalar my $DATE_SKEW_DAYS    => 7;

# Maximum positive timezone offset in minutes (+14:00 = Line Islands)
Readonly::Scalar my $TZ_MAX_POS_MINS   => 840;

# Maximum negative timezone offset in minutes (-12:00 = Baker Island)
Readonly::Scalar my $TZ_MAX_NEG_MINS   => 720;

# High-risk score threshold
Readonly::Scalar my $SCORE_HIGH        => 9;

# Medium-risk score threshold
Readonly::Scalar my $SCORE_MEDIUM      => 5;

# Low-risk score threshold
Readonly::Scalar my $SCORE_LOW         => 2;

# Flag severity weights (contribute to the numeric risk score)
Readonly::Hash my %FLAG_WEIGHT => (
	HIGH   => 3,
	MEDIUM => 2,
	LOW    => 1,
	INFO   => 0,
);

# Maximum merged-role display string length before summarisation kicks in
Readonly::Scalar my $ROLE_MAX_LEN      => 80;

# CHI cache TTL in seconds (1 hour -- IP allocations change slowly)
Readonly::Scalar my $CACHE_TTL_SECS    => 3600;

# Default constructor timeout for network operations (seconds)
Readonly::Scalar my $DEFAULT_TIMEOUT   => 10;

# Maximum role string length before truncation
Readonly::Scalar my $ROLE_WRAP_LEN     => 66;

# Brand names checked in lookalike-domain detection.
# Overridable at runtime via Object::Configure.
Readonly::Array my @LOOKALIKE_BRANDS => qw(
	paypal apple google amazon microsoft netflix ebay
	instagram facebook twitter linkedin bankofamerica
	wellsfargo chase barclays hsbc lloyds santander
);

# -----------------------------------------------------------------------
# Private ranges -- IPs that are never actionable abuse targets
# -----------------------------------------------------------------------

# Both IPv4 and IPv6 private/reserved ranges.  Each entry is a compiled
# regex; _is_private() iterates over them and returns true on first match.
my @PRIVATE_RANGES = (
	# IPv4 ranges
	qr/^0\./,                         # 0.0.0.0/8  this-network (RFC 1122)
	qr/^127\./,                       # 127.0.0.0/8 loopback
	qr/^10\./,                        # 10.0.0.0/8  RFC 1918
	qr/^192\.168\./,                  # 192.168.0.0/16 RFC 1918
	qr/^172\.(?:1[6-9]|2\d|3[01])\./, # 172.16.0.0/12  RFC 1918
	qr/^169\.254\./,                  # 169.254.0.0/16 link-local
	qr/^100\.(?:6[4-9]|[7-9]\d|1(?:[01]\d|2[0-7]))\./,  # 100.64.0.0/10 CGN (RFC 6598)
	qr/^192\.0\.0\./,                 # 192.0.0.0/24  IETF protocol (RFC 6890)
	qr/^192\.0\.2\./,                 # 192.0.2.0/24  TEST-NET-1 (RFC 5737)
	qr/^198\.51\.100\./,              # 198.51.100.0/24 TEST-NET-2 (RFC 5737)
	qr/^203\.0\.113\./,               # 203.0.113.0/24 TEST-NET-3 (RFC 5737)
	qr/^255\./,                       # 255.0.0.0/8 broadcast
	# IPv6 ranges
	qr/^::1$/,                         # IPv6 loopback
	qr/^fe80:/i,                       # IPv6 link-local (fe80::/10)
	qr/^fc/i,                          # IPv6 ULA fc00::/7
	qr/^fd/i,                          # IPv6 ULA fd00::/8
	qr/^2001:db8:/i,                   # IPv6 documentation range (RFC 3849)
	qr/^64:ff9b:/i,                    # IPv6 NAT64 well-known prefix
);

# Priority-ordered patterns for extracting IPs from Received: headers.
# Covers bracketed IPv4, bracketed IPv6, parenthesised address, and bare dotted-quad.
my @RECEIVED_IP_RE = (
	qr/\[\s*([\d.]+)\s*\]/,                          # [1.2.3.4]
	qr/\[\s*([0-9a-fA-F:]+)\s*\]/,                  # [IPv6 address]
	qr/\(\s*[\w.-]*\s*\[?\s*([\d.]+)\s*\]?\s*\)/,   # (hostname [1.2.3.4])
	qr/from\s+[\w.-]+\s+([\d.]+)/,                  # from hostname addr
	qr/([\d]{1,3}\.[\d]{1,3}\.[\d]{1,3}\.[\d]{1,3})/, # bare dotted-quad fallback
);

# -----------------------------------------------------------------------
# Default configuration -- overridable via Object::Configure
# -----------------------------------------------------------------------

# Object::Configure may overlay
# values from a file before new() uses them.  Use Readonly for constants
# that should never be overridden at runtime.

# -----------------------------------------------------------------------
# Trusted domains (infrastructure -- never report these as abuse targets)
# Can be overrideen at runtime by Object::Configure
# -----------------------------------------------------------------------

my %TRUSTED_DOMAINS = map { $_ => 1 } qw(
	gmail.com googlemail.com yahoo.com outlook.com hotmail.com
	google.com microsoft.com apple.com amazon.com
	googlegroups.com groups.google.com
	w3.org
	fedex.com ups.com dhl.com usps.com royalmail.com
);

# -----------------------------------------------------------------------
# URL shortener domains (real destination is hidden behind these)
# -----------------------------------------------------------------------

my %URL_SHORTENERS = map { $_ => 1 } qw(
	bit.ly      bitly.com   tinyurl.com  t.co        ow.ly
	goo.gl      is.gd       buff.ly      ift.tt       dlvr.it
	short.link  rebrand.ly  tiny.cc      cutt.ly      rb.gy
	shorturl.at bl.ink      smarturl.it  yourls.org   clicky.me
	snip.ly     adf.ly      bc.vc        lnkd.in      fb.me
	youtu.be
);

# -----------------------------------------------------------------------
# Well-known provider abuse contacts
# Can be overrideen at runtime by Object::Configure
# -----------------------------------------------------------------------

# Curated table of provider abuse contacts.  Entries with only a 'form'
# key (no 'email') require web-form submission; abuse_contacts() suppresses
# email addresses for those providers and form_contacts() surfaces them.
my %PROVIDER_ABUSE = (
	# Google / Gmail
	'google.com'        => { email => 'abuse@google.com',      note => 'Also report Gmail accounts via https://support.google.com/mail/contact/abuse' },
	'gmail.com'         => { email => 'abuse@google.com',      note => 'Report Gmail spam via https://support.google.com/mail/contact/abuse' },
	'googlemail.com'    => { email => 'abuse@google.com',      note => 'Report via https://support.google.com/mail/contact/abuse' },
	'1e100.net'         => { email => 'abuse@google.com',      note => 'Google infrastructure' },
	'blogspot.com'      => { email => 'abuse@google.com',      note => 'Blogger/Blogspot -- report via https://support.google.com/blogger/answer/76315' },
	'blogger.com'       => { email => 'abuse@google.com',      note => 'Blogger platform abuse' },
	'sites.google.com'  => { email => 'abuse@google.com',      note => 'Google Sites hosted content' },
	# Microsoft
	'microsoft.com'     => { email => 'abuse@microsoft.com',   note => 'Also report via https://www.microsoft.com/en-us/wdsi/support/report-unsafe-site' },
	'outlook.com'       => { email => 'abuse@microsoft.com',   note => 'Report Outlook spam: https://support.microsoft.com/en-us/office/report-phishing' },
	'hotmail.com'       => { email => 'abuse@microsoft.com',   note => 'Report via https://support.microsoft.com/en-us/office/report-phishing' },
	'live.com'          => { email => 'abuse@microsoft.com',   note => 'Microsoft consumer mail' },
	'office365.com'     => { email => 'abuse@microsoft.com',   note => 'Microsoft 365 infrastructure' },
	'protection.outlook.com' => { email => 'abuse@microsoft.com', note => 'Microsoft EOP gateway' },
	# Yahoo
	'yahoo.com'         => { email => 'abuse@yahoo-inc.com',   note => 'Also use https://io.help.yahoo.com/contact/index' },
	'yahoo.co.uk'       => { email => 'abuse@yahoo-inc.com',   note => 'Yahoo UK' },
	# Apple
	'apple.com'         => { email => 'reportphishing@apple.com', note => 'iCloud / Apple Mail abuse' },
	'icloud.com'        => { email => 'reportphishing@apple.com', note => 'iCloud abuse' },
	'me.com'            => { email => 'reportphishing@apple.com', note => 'Apple legacy mail' },
	# Amazon / AWS
	'amazon.com'        => { email => 'abuse@amazonaws.com',   note => 'Also https://aws.amazon.com/forms/report-abuse' },
	'amazonaws.com'     => { email => 'abuse@amazonaws.com',   note => 'AWS abuse form: https://aws.amazon.com/forms/report-abuse' },
	'amazonses.com'     => { email => 'abuse@amazonaws.com',   note => 'Amazon SES sending infrastructure' },
	# Cloudflare
	'cloudflare.com'    => { email => 'abuse@cloudflare.com',  note => 'Report via https://www.cloudflare.com/abuse/' },
	# Fastly / Akamai
	'fastly.net'        => { email => 'abuse@fastly.com',      note => 'Fastly CDN' },
	'akamai.com'        => { email => 'abuse@akamai.com',      note => 'Akamai CDN' },
	'akamaitechnologies.com' => { email => 'abuse@akamai.com', note => 'Akamai CDN' },
	# Namecheap
	'namecheap.com'     => { email => 'abuse@namecheap.com',   note => 'Registrar abuse' },
	# GoDaddy -- web form only; email bounces
	'godaddy.com'       => {
		form        => 'https://supportcenter.godaddy.com/AbuseReport',
		form_paste  => 'Select the abuse type (spam, phishing, malware etc). '
		             . 'Enter the domain name in the Domain field. '
		             . 'Paste the originating IP, risk flags, and the relevant '
		             . 'Received: headers from the report below.',
		form_upload => 'Take a screenshot of the report as a .png or .jpg, '
		             . 'or export it as a .pdf.',
		note        => 'Registrar/host -- email reports not monitored, use web form',
	},
	# SendGrid / Twilio
	'sendgrid.net'      => { email => 'abuse@sendgrid.com',    note => 'ESP -- include full headers' },
	'sendgrid.com'      => { email => 'abuse@sendgrid.com',    note => 'ESP -- include full headers' },
	# Mailchimp / Mandrill
	'mailchimp.com'     => { email => 'abuse@mailchimp.com',   note => 'ESP abuse' },
	'mandrillapp.com'   => { email => 'abuse@mailchimp.com',   note => 'Mandrill transactional ESP' },
	# OVH
	'ovh.net'           => { email => 'abuse@ovh.net',         note => 'OVH hosting' },
	'ovh.com'           => { email => 'abuse@ovh.com',         note => 'OVH hosting' },
	# Hetzner
	'hetzner.com'       => { email => 'abuse@hetzner.com',     note => 'Hetzner hosting' },
	# Digital Ocean
	'digitalocean.com'  => { email => 'abuse@digitalocean.com',note => 'DO abuse form: https://www.digitalocean.com/company/contact/#abuse' },
	# Linode / Akamai
	'linode.com'        => { email => 'abuse@linode.com',      note => 'Linode/Akamai Cloud' },
	# Constant Contact
	'constantcontact.com' => { email => 'abuse@constantcontact.com', note => 'ESP abuse' },
	'r.constantcontact.com' => { email => 'abuse@constantcontact.com', note => 'Constant Contact sending infrastructure' },
	# HubSpot
	'hubspot.com'         => { email => 'abuse@hubspot.com',       note => 'ESP abuse' },
	'hs-analytics.net'    => { email => 'abuse@hubspot.com',       note => 'HubSpot analytics infrastructure' },
	# Campaign Monitor
	'createsend.com'      => { email => 'abuse@campaignmonitor.com', note => 'Campaign Monitor ESP' },
	'cmail20.com'         => { email => 'abuse@campaignmonitor.com', note => 'Campaign Monitor sending infrastructure' },
	# Klaviyo
	'klaviyo.com'         => { email => 'abuse@klaviyo.com',       note => 'ESP abuse' },
	# Brevo (formerly Sendinblue)
	'sendinblue.com'      => { email => 'abuse@sendinblue.com',    note => 'ESP abuse' },
	'brevo.com'           => { email => 'abuse@brevo.com',         note => 'ESP abuse' },
	# Mailgun
	'mailgun.com'         => { email => 'abuse@mailgun.com',       note => 'ESP abuse' },
	'mailgun.org'         => { email => 'abuse@mailgun.com',       note => 'Mailgun sending infrastructure' },
	# Postmark
	'postmarkapp.com'     => { email => 'abuse@postmarkapp.com',   note => 'ESP abuse' },
	# WordPress.com
	'wordpress.com'       => { email => 'abuse@wordpress.com',     note => 'WordPress.com hosted blog -- report via https://en.wordpress.com/abuse/' },
	'wp.com'              => { email => 'abuse@wordpress.com',     note => 'WordPress.com short domain' },
	# Substack
	'substack.com'        => { email => 'abuse@substack.com',      note => 'Substack newsletter platform abuse' },
	# ActiveCampaign
	'activecampaign.com'  => { email => 'abuse@activecampaign.com', note => 'ActiveCampaign ESP' },
	'ac-tinker.com'       => { email => 'abuse@activecampaign.com', note => 'ActiveCampaign tracking infrastructure' },
	# Salesforce Marketing Cloud
	'salesforce.com'      => { email => 'abuse@salesforce.com',    note => 'Salesforce Marketing Cloud / ExactTarget ESP' },
	'mc.salesforce.com'   => { email => 'abuse@salesforce.com',    note => 'Salesforce Marketing Cloud sending infrastructure' },
	'exacttarget.com'     => { email => 'abuse@salesforce.com',    note => 'ExactTarget / Salesforce Marketing Cloud ESP' },
	'et.exacttarget.com'  => { email => 'abuse@salesforce.com',    note => 'ExactTarget sending infrastructure' },
	# Vultr
	'vultr.com'           => { email => 'abuse@vultr.com',         note => 'Vultr hosting' },
	# Contabo
	'contabo.com'         => { email => 'abuse@contabo.com',       note => 'Contabo hosting' },
	# Leaseweb
	'leaseweb.com'        => { email => 'abuse@leaseweb.com',      note => 'Leaseweb hosting' },
	# M247
	'm247.com'            => { email => 'abuse@m247.com',          note => 'M247 hosting' },
	# MarkMonitor -- web form only
	'markmonitor.com'       => {
		form        => 'https://corp.markmonitor.com/domain/ui/abuse-report',
		form_paste  => 'Complete all fields including the domain name and your '
		             . 'description of the abuse.  Paste the originating IP, '
		             . 'risk flags, and the relevant Received: headers from the '
		             . 'report below.',
		form_upload => 'Take a screenshot of the report as a .png or .jpg, or export it as a .pdf.  MarkMonitor does not accept .eml files.',
		note        => 'Brand-protection registrar -- email reports not processed',
	},
	# URL shortener operators
	'is.gd'             => { email => 'abuse@is.gd',           note => 'URL shortener -- report via https://is.gd/contact.php' },
	'bitly.com'         => { email => 'abuse@bitly.com',        note => 'URL shortener abuse' },
	'bit.ly'            => { email => 'abuse@bitly.com',        note => 'URL shortener abuse' },
	'tinyurl.com'       => { email => 'abuse@tinyurl.com',      note => 'URL shortener abuse' },
	'ow.ly'             => { email => 'abuse@hootsuite.com',    note => 'Hootsuite URL shortener' },
	'buff.ly'           => { email => 'abuse@buffer.com',       note => 'Buffer URL shortener' },
	'rb.gy'             => { email => 'abuse@rb.gy',            note => 'URL shortener abuse' },
	'cutt.ly'           => { email => 'abuse@cutt.ly',          note => 'URL shortener abuse' },
	'shorturl.at'       => { email => 'abuse@shorturl.at',      note => 'URL shortener abuse' },
	# Dynadot -- web form only
	'dynadot.com'           => {
		form        => 'https://www.dynadot.com/report-abuse',
		form_paste  => 'Complete all fields including the domain name and your '
		             . 'description of the abuse.  Paste the originating IP, '
		             . 'risk flags, and the relevant Received: headers from the '
		             . 'report below.',
		form_upload => 'Take a screenshot of the report as a .png or .jpg, '
		             . 'or export it as a .pdf.',
		note        => 'Registrar -- email reports not monitored, use web form',
	},
	# Global Domain Group -- web form only
	'globaldomaingroup.com' => {
		form        => 'https://globaldomaingroup.com/report-abuse',
		form_paste  => 'Complete all fields including the domain name and your '
		             . 'description of the abuse.  Paste the originating IP, '
		             . 'risk flags, and the relevant Received: headers from the '
		             . 'report below.',
		form_upload => 'Attach the original spam message as an .eml file.',
		note        => 'Registrar -- email reports explicitly not accepted',
	},
	# TPG / Internode (Australia)
	'tpgi.com.au'       => { email => 'abuse@tpg.com.au',      note => 'TPG Telecom Australia' },
	'tpg.com.au'        => { email => 'abuse@tpg.com.au',      note => 'TPG Telecom Australia' },
	'internode.on.net'  => { email => 'abuse@internode.on.net',note => 'Internode Australia' },
);

# -----------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------

=head1 METHODS

=head2 new( %options )

Constructs and returns a new C<Email::Abuse::Investigator> analyser object.  The
object is stateless until C<parse_email()> is called; all analysis results
are stored on the object and retrieved via the public accessor methods
documented below.

A single object may be reused for multiple emails by calling C<parse_email()>
again: all per-message cached state from the previous message is discarded
automatically.  Cross-message IP and domain lookup results are retained
in a shared CHI cache (if C<CHI> is installed) to avoid redundant network
queries across messages processed in the same process.

=head3 Usage

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

=head3 Arguments

All arguments are optional named parameters passed as a flat key-value list.

=over 4

=item C<timeout> (integer, default 10)

Maximum seconds to wait for any single network operation.  Set to 0 to
disable timeouts (not recommended for production use).

=item C<trusted_relays> (arrayref of strings, default [])

IP addresses or CIDR blocks to skip during Received: chain analysis.
Each element may be an exact IPv4 address (C<'192.0.2.1'>) or a CIDR
block (C<'192.0.2.0/24'>).

=item C<verbose> (boolean, default 0)

When true, diagnostic messages are written to STDERR.

=back

=head3 Returns

A blessed C<Email::Abuse::Investigator> object.  No network I/O is performed
during construction.

=head3 Side Effects

If C<CHI> is installed, a shared in-memory cache is initialised (or
re-used if a cache was already created by a prior call to C<new()>).
This cache persists for the lifetime of the process.

=head3 Notes

=over 4

=item *

Unknown option keys are silently ignored.

=item *

The object is not thread-safe.  Use a separate object per thread.

=item *

WHOIS read timeouts use C<IO::Select> rather than C<alarm()>, so they
work correctly on Windows and in threaded Perl interpreters.

=back

=head3 API Specification

=head4 Input

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

=head4 Output

    {
        type => 'object',
        isa  => 'Email::Abuse::Investigator',
    }

=cut

# Class-level cross-message CHI cache (shared across all instances).
# Populated lazily on first call to new() when CHI is available.
my $_cache;

sub new {
	my $class = shift;

	# Accept hash or hashref arguments uniformly
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params(undef, \@_) || {},
		schema => {
			timeout => {
				'type'     => 'integer',
				'optional' => 1,
				'min'      => 0,
			},
			trusted_relays => {
				'type'         => 'arrayref',
				'element_type' => 'string',
				'optional'     => 1,
			},
			verbose => {
				'type'     => 'boolean',
				'optional' => 1,
			},
		},
	});

	# Merge in any file-based configuration via Object::Configure
	$params = Object::Configure::configure($class, $params);

	# Initialise the cross-message CHI cache on first construction
	if ($HAS_CHI && !$_cache) {
		$_cache = CHI->new(
			driver     => 'Memory',
			global     => 1,
			expires_in => $CACHE_TTL_SECS,
		);
	}

	# Build and bless the object with default slot values
	return bless {
		timeout        => $DEFAULT_TIMEOUT,
		trusted_relays => [],
		verbose        => 0,
		_raw           => '',
		_headers       => [],
		_body_plain    => '',
		_body_html     => '',
		_received      => [],
		_origin        => undef,
		_urls          => undef,     # lazy-computed by embedded_urls()
		_mailto_domains=> undef,     # lazy-computed by mailto_domains()
		_contacts      => undef,     # lazy-computed by abuse_contacts()
		_domain_info   => {},        # per-message domain analysis cache
		_sending_sw    => [],        # X-Mailer / X-PHP-Originating-Script etc.
		_rcvd_tracking => [],        # per-hop tracking IDs from Received: headers
		%{$params},  # Overlay Object::Configure and caller-supplied values
	}, $class;
}

# -----------------------------------------------------------------------
# Public: parse
# -----------------------------------------------------------------------

=head2 parse_email( $text )

Feeds a raw RFC 2822 email message to the analyser and prepares it for
subsequent interrogation.  This is the only method that must be called
before any other public method.

If the same object is used for a second message, calling C<parse_email()>
again completely replaces all per-message state from the first message.
The cross-message CHI cache is B<not> flushed; IP and domain lookups
cached from prior messages are retained.

=head3 Usage

    my $raw = do { local $/; <STDIN> };
    $analyser->parse_email($raw);

    # Scalar reference (avoids copying large messages)
    $analyser->parse_email(\$raw);

    # Chained
    my $analyser = Email::Abuse::Investigator->new()->parse_email($raw);

=head3 Arguments

=over 4

=item C<$text> (string or string reference, required)

Complete raw RFC 2822 email message, including all headers and the body.
Both LF-only and CRLF line endings are accepted.

=back

=head3 Returns

The object itself (C<$self>), enabling method chaining.

=head3 Side Effects

Parses headers, decodes the body (quoted-printable, base64, multipart),
extracts sending-software fingerprints, and populates per-hop tracking
data.  All previously computed lazy results are discarded.

=head3 Notes

=over 4

=item *

If C<$text> is empty or contains no header/body separator, all public
methods will return empty/safe values.

=item *

Decoding errors in base64 or quoted-printable payloads are silenced; raw
bytes are used in place of correct output to prevent exceptions.

=back

=head3 API Specification

=head4 Input

    [
        {
            type => [ 'string', 'stringref' ]
        },
    ]

=head4 Output

    {
        type => 'object',
        isa  => 'Email::Abuse::Investigator',
    }

=cut

# TODO: Allow a Mail::Message object to be passed in
sub parse_email {
	my $self = shift;

	# Accept both positional string and named 'text' argument
	my $args = Params::Get::get_params('text', \@_);
	my $text = $args->{text};

	# Dereference a scalar-ref in a single clean pass
	$text = $$text if ref($text) eq 'SCALAR';

	# Any other reference type is a programming error
	Carp::croak(__PACKAGE__ . ': parse_email() requires a string or scalar reference')
		if ref($text);

	# Sanitise: strip control characters that could affect terminal output.
	# Keep \t (tabs in headers), \n (line endings), \r (CRLF mail format).
	$text =~ s/[^\x09\x0A\x0D\x20-\x7E\x80-\xFF]//g if defined $text;

	# Store the sanitised raw text for later reproduction in reports
	$self->{_raw} = $text // '';

	# Invalidate all per-message lazy caches
	$self->{_origin}         = undef;
	$self->{_urls}           = undef;
	$self->{_mailto_domains} = undef;
	$self->{_contacts}       = undef;
	$self->{_domain_info}    = {};
	$self->{_risk}           = undef;
	$self->{_auth_results}   = undef;
	$self->{_sending_sw}     = [];
	$self->{_rcvd_tracking}  = [];

	# Perform synchronous header/body parsing (no network I/O)
	$self->_split_message($text) if defined $text && $text =~ /\S/;
	return $self;
}

# -----------------------------------------------------------------------
# Public: originating host
# -----------------------------------------------------------------------

=head2 originating_ip()

Identifies the IP address of the machine that originally injected the
message into the mail system by walking the C<Received:> chain, skipping
private/trusted hops, and enriching the first external hop with rDNS,
WHOIS/RDAP organisation name, abuse contact, and country code.

Both IPv4 and IPv6 addresses are extracted and evaluated.

The result is cached; subsequent calls return the same hashref without
repeating network I/O.

=head3 Usage

    my $orig = $analyser->originating_ip();
    if (defined $orig) {
        printf "Origin: %s (%s)\n", $orig->{ip}, $orig->{rdns};
        printf "Owner:  %s\n",      $orig->{org};
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A hashref with keys C<ip>, C<rdns>, C<org>, C<abuse>, C<confidence>,
C<note>, and C<country> (may be undef).  Returns C<undef> if no suitable
originating IP can be determined.

=head3 Side Effects

On first call: one PTR lookup and one RDAP/WHOIS query.  Results are cached
in the object and in the cross-message CHI cache (if available).

=head3 Notes

Only the first (oldest) external IP in the chain is reported.  See
C<received_trail()> for the full chain.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub originating_ip {
	my $self = $_[0];

	# Return the cached result if we already have it
	$self->{_origin} //= $self->_find_origin();
	return $self->{_origin};
}

# -----------------------------------------------------------------------
# Public: HTTP/HTTPS URLs
# -----------------------------------------------------------------------

=head2 embedded_urls()

Extracts every HTTP and HTTPS URL from the message body and enriches each
one with the hosting IP address, network organisation name, abuse contact,
and country code.  Both IPv4 and IPv6 host addresses are supported.

URL extraction runs across both plain-text and HTML body parts.  DNS
lookups for each unique hostname are optionally parallelised via
C<AnyEvent::DNS> if that module is installed.

The result is cached; subsequent calls return the same list without
repeating network I/O.

=head3 Usage

    my @urls = $analyser->embedded_urls();
    for my $u (@urls) {
        printf "URL: %s  host: %s  org: %s\n",
            $u->{url}, $u->{host}, $u->{org};
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list of hashrefs, one per unique URL, in first-seen order.  Returns an
empty list if no HTTP/HTTPS URLs are present.  Each hashref has keys
C<url>, C<host>, C<ip>, C<org>, C<abuse>, C<country>.

=head3 Side Effects

Per unique hostname: one A/AAAA lookup and one RDAP/WHOIS query.  Results
are cached in the object and in the cross-message CHI cache.

=head3 Notes

Only C<http://> and C<https://> URLs are extracted.  URL shortener hosts
are included in the returned list (they are flagged by C<risk_assessment()>).

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub embedded_urls {
	my $self = $_[0];

	$self->{_urls} //= $self->_extract_and_resolve_urls();
	return @{ $self->{_urls} };
}

# -----------------------------------------------------------------------
# Public: mailto / reply-to / from domains
# -----------------------------------------------------------------------

=head2 mailto_domains()

Identifies every domain associated with the message as a contact, reply,
or delivery address, then runs a full intelligence pipeline on each one
(A record, MX, NS, WHOIS) to determine hosting and registration details.

The result is cached; subsequent calls return the same list without
repeating network I/O.

=head3 Usage

    my @domains = $analyser->mailto_domains();
    for my $d (@domains) {
        printf "Domain: %s  registrar: %s\n",
            $d->{domain}, $d->{registrar} // 'unknown';
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list of hashrefs, one per unique domain.  See the main POD for the full
set of possible keys.  Returns an empty list if no qualifying domains are
found.

=head3 Side Effects

Per unique domain: up to three A lookups, one MX lookup, one NS lookup,
and two WHOIS queries.  Results are cached in the object and in the
cross-message CHI cache.

=head3 Notes

MX and NS lookups require C<Net::DNS>.  Without it those keys are absent
from every returned hashref.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub mailto_domains {
	my $self = $_[0];

	$self->{_mailto_domains} //= $self->_extract_and_analyse_domains();
	return @{ $self->{_mailto_domains} };
}

=head2 all_domains()

Returns the deduplicated union of every registrable domain seen anywhere
in the message -- URL hosts from C<embedded_urls()> and contact domains
from C<mailto_domains()> -- normalised to eTLD+1 form.

Triggers C<embedded_urls()> and C<mailto_domains()> lazily.

=head3 Usage

    my @domains = $analyser->all_domains();
    print "$_\n" for @domains;

=head3 Arguments

None.

=head3 Returns

A list of plain strings (registrable domain names), lower-cased, no
duplicates, in first-seen order.

=head3 Side Effects

Triggers C<embedded_urls()> and C<mailto_domains()> if not already cached.

=head3 Notes

Normalisation to eTLD+1 uses C<Domain::PublicSuffix> if installed, falling
back to a built-in heuristic otherwise.

=head3 API Specification

=head4 Input

    []

=head4 Output

    (
        { type => 'string', regex => qr/^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/ },
        ...
    )

=cut

sub all_domains {
	my $self = $_[0];
	my (%seen, @out);

	# Collect registrable domains from URL hosts first
	for my $u ($self->embedded_urls()) {
		my $dom = _registrable($u->{host});
		push @out, $dom if $dom && !$seen{$dom}++;
	}

	# Then from contact domains (normalise subdomains to registrable parent)
	for my $d ($self->mailto_domains()) {
		my $dom = _registrable($d->{domain}) // $d->{domain};
		push @out, $dom if $dom && !$seen{$dom}++;
	}
	return @out;
}

=head2 unresolved_contacts()

Returns a list of domains and URL hosts found in the message for which no
abuse contact could be determined.  Useful for surfacing parties that may
warrant manual investigation.

=head3 Usage

    my @unresolved = $analyser->unresolved_contacts();
    for my $u (@unresolved) {
        printf "Unresolved: %s (%s) via %s\n",
            $u->{domain}, $u->{type}, $u->{source};
    }

=head3 Arguments

None.

=head3 Returns

A list of hashrefs, each with keys C<domain>, C<type> (C<'url_host'> or
C<'domain'>), and C<source> (where the domain was found).

=head3 Side Effects

Triggers C<embedded_urls()>, C<mailto_domains()>, C<abuse_contacts()>,
and C<form_contacts()> if not already cached.

=head3 Notes

Domains sourced only from spoofable sending headers (C<From:>,
C<Return-Path:>, C<Sender:>) are excluded.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub unresolved_contacts {
	my $self = $_[0];

	# Build a set of domains already covered by email or form contacts
	my %covered;
	for my $c ($self->abuse_contacts(), $self->form_contacts()) {
		my $dom = $c->{form_domain};
		unless ($dom) {
			# Extract domain from abuse email address
			($dom) = ($c->{address} // '') =~ /\@([\w.-]+)/;
		}
		$covered{lc $dom}++ if $dom;
	}

	# Also mark URL hosts that already have a resolved abuse address
	for my $u ($self->embedded_urls()) {
		(my $bare = lc $u->{host}) =~ s/^www\.//;
		$covered{$bare}++ if $u->{abuse} && $u->{abuse} ne '(unknown)';
	}

	my (@out, %seen);

	# Check URL hosts first
	for my $u ($self->embedded_urls()) {
		(my $bare = lc $u->{host}) =~ s/^www\.//;
		next if $covered{$bare};
		next if $seen{"url:$bare"}++;
		push @out, {
			domain => $u->{host},
			type   => 'url_host',
			source => 'URL in body',
		};
	}

	# Then check contact domains, skipping spoofable-header-only sources
	for my $d ($self->mailto_domains()) {
		my $dom    = $d->{domain};
		my $source = $d->{source} // '';
		next if $source =~ /^(?:From:|Return-Path:|Sender:) header$/;
		next if $covered{lc $dom};
		next if $seen{"dom:$dom"}++;
		push @out, {
			domain => $dom,
			type   => 'domain',
			source => $source,
		};
	}

	return @out;
}

# -----------------------------------------------------------------------
# Public: sending software fingerprint
# -----------------------------------------------------------------------

=head2 sending_software()

Returns information extracted from headers that identify the software or
server-side infrastructure used to compose or inject the message.  Headers
such as C<X-PHP-Originating-Script> reveal the exact PHP script and Unix
account responsible on shared-hosting platforms.

Data is extracted during C<parse_email()> with no network I/O.

=head3 Usage

    my @sw = $analyser->sending_software();
    for my $s (@sw) {
        printf "%-30s : %s\n", $s->{header}, $s->{value};
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list of hashrefs in alphabetical header-name order.  Returns an empty
list if none of the watched headers are present.  Each hashref has keys
C<header>, C<value>, and C<note>.

=head3 Side Effects

None.  Data is pre-collected during C<parse_email()>.

=head3 Notes

Header names are lower-cased.  Header values are stored verbatim.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub sending_software {
	my $self = $_[0];

	return @{ $self->{_sending_sw} };
}

# -----------------------------------------------------------------------
# Public: per-hop tracking IDs
# -----------------------------------------------------------------------

=head2 received_trail()

Returns per-hop tracking data extracted from the C<Received:> header chain:
the IP address, envelope recipient address, and server session ID for each
relay.  ISP postmasters use these identifiers to locate the SMTP session in
their logs.

=head3 Usage

    my @trail = $analyser->received_trail();
    for my $hop (@trail) {
        printf "IP: %s  ID: %s\n",
            $hop->{ip} // '?', $hop->{id} // '?';
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list of hashrefs in oldest-first order.  Returns an empty list if no
C<Received:> headers are present or none yielded extractable data.  Each
hashref has keys C<received>, C<ip> (may be undef), C<for> (may be undef),
C<id> (may be undef).

=head3 Side Effects

None.  Data is pre-collected during C<parse_email()>.

=head3 Notes

Private IPs are NOT filtered here; all IPs including RFC 1918 addresses
are returned as found.  Filtering is applied only by C<originating_ip()>.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub received_trail {
	my $self = $_[0];

	return @{ $self->{_rcvd_tracking} };
}

# -----------------------------------------------------------------------
# Public: risk assessment
# -----------------------------------------------------------------------

=head2 risk_assessment()

Evaluates the message against heuristic checks and returns an overall risk
level, a weighted numeric score, and a list of every specific red flag.

The assessment covers five categories: originating IP, email authentication,
Date: header validity, identity/header consistency, and URL/domain properties.

The result is cached; subsequent calls return the same hashref without
repeating any analysis.

=head3 Usage

    my $risk = $analyser->risk_assessment();
    printf "Risk: %s (score: %d)\n", $risk->{level}, $risk->{score};
    for my $f (@{ $risk->{flags} }) {
        printf "  [%s] %s\n", $f->{severity}, $f->{detail};
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A hashref with keys C<level> (HIGH/MEDIUM/LOW/INFO), C<score> (integer),
and C<flags> (arrayref of hashrefs with C<severity>, C<flag>, C<detail>).

=head3 Side Effects

Triggers C<originating_ip()>, C<embedded_urls()>, and C<mailto_domains()>
if not already cached.

=head3 Notes

Scores: HIGH >= 9, MEDIUM >= 5, LOW >= 2, INFO < 2.
Flag weights: HIGH=3, MEDIUM=2, LOW=1, INFO=0.

=head3 API Specification

=head4 Input

    []

=head4 Output

    {
        type => 'hashref',
        keys => {
            level => { type => 'string', memberof => ['HIGH', 'MEDIUM', 'LOW', 'INFO'] },
            score => { type => 'integer' },
            flags => { type => 'arrayref' },
        },
    }

=cut

sub risk_assessment {
	my $self = $_[0];

	return $self->{_risk} if $self->{_risk};

	my (@flags, $score);
	$score = 0;

	# Closure to record a flag and accumulate its weight
	my $flag = sub {
		my ($severity, $name, $detail) = @_;
		$score += $FLAG_WEIGHT{$severity} // 1;
		push @flags, { severity => $severity, flag => $name, detail => $detail };
	};

	$self->_risk_check_origin($flag);
	$self->_risk_check_auth($flag);
	$self->_risk_check_date($flag);
	$self->_risk_check_identity($flag);
	$self->_risk_check_urls_and_domains($flag);

	# Determine overall risk level from accumulated score
	my $level = $score >= $SCORE_HIGH   ? 'HIGH'
	          : $score >= $SCORE_MEDIUM ? 'MEDIUM'
	          : $score >= $SCORE_LOW    ? 'LOW'
	          :                           'INFO';

	$self->{_risk} = { level => $level, score => $score, flags => \@flags };
	return $self->{_risk};
}

# _risk_check_origin( $flag )
#
# Purpose:
#   Evaluate the originating IP for residential rDNS, absent rDNS,
#   low-confidence origin, and high-spam-volume country.
#
# Entry criteria:
#   $flag -- coderef( severity, name, detail ) that accumulates flags.
#
# Exit status:
#   Returns nothing; side effects via $flag closure.

sub _risk_check_origin :Private {
	my ($self, $flag) = @_;
	my $orig = $self->originating_ip();
	return unless $orig;

	# Residential / broadband rDNS patterns suggest a compromised host
	if ($orig->{rdns} && $orig->{rdns} =~ /
		\d+[-_.]\d+[-_.]\d+[-_.]\d+   # dotted-quad in rDNS
		| (?:dsl|adsl|cable|broad|dial|dynamic|dhcp|ppp|
		     residential|cust|home|pool|client|user|
		     static\d|host\d)
	/xi) {
		$flag->('HIGH', 'residential_sending_ip',
			"Sending IP $orig->{ip} rDNS '$orig->{rdns}' looks like a broadband/residential line, not a legitimate mail server");
	}

	# Absence of rDNS is a strong spam indicator
	if (!$orig->{rdns} || $orig->{rdns} eq '(no reverse DNS)') {
		$flag->('HIGH', 'no_reverse_dns',
			"Sending IP $orig->{ip} has no reverse DNS -- legitimate mail servers always have rDNS");
	}

	# Low-confidence origin means the IP came from an unverifiable header
	if ($orig->{confidence} eq 'low') {
		$flag->('MEDIUM', 'low_confidence_origin',
			"Originating IP taken from unverified header ($orig->{note})");
	}

	# Statistically high-volume spam countries (informational only)
	if ($orig->{country} && $orig->{country} =~ /^(?:CN|RU|NG|VN|IN|PK|BD)$/) {
		$flag->('INFO', 'high_spam_country',
			'Sending IP is in ' . _country_name($orig->{country}) .
			" ($orig->{country}) -- statistically high spam volume country");
	}
}

# _risk_check_auth( $flag )
#
# Purpose:
#   Evaluate SPF, DKIM, DMARC results and DKIM signing domain alignment.
#
# Entry criteria:
#   $flag -- accumulator coderef.
#
# Exit status:
#   Returns nothing; side effects via $flag closure.

sub _risk_check_auth :Private {
	my ($self, $flag) = @_;
	my $auth = $self->_parse_auth_results_cached();

	if (defined $auth->{spf}) {
		if ($auth->{spf} =~ /^fail/i) {
			$flag->('HIGH', 'spf_fail',
				"SPF result: $auth->{spf} -- sending IP not authorised by domain's SPF record");
		} elsif ($auth->{spf} =~ /^softfail/i) {
			$flag->('MEDIUM', 'spf_softfail',
				"SPF result: softfail (~all) -- sending IP not explicitly authorised");
		} elsif ($auth->{spf} !~ /^pass/i) {
			$flag->('HIGH', 'spf_fail',
				"SPF result: $auth->{spf} -- sending IP not authorised");
		}
	}
	if (defined $auth->{dkim} && $auth->{dkim} !~ /^pass/i) {
		$flag->('HIGH', 'dkim_fail',
			"DKIM result: $auth->{dkim} -- message signature invalid or absent");
	}
	if (defined $auth->{dmarc} && $auth->{dmarc} !~ /^pass/i) {
		$flag->('HIGH', 'dmarc_fail', "DMARC result: $auth->{dmarc}");
	}

	# DKIM signing domain vs From: domain mismatch check
	return unless $auth->{dkim_domain};
	my ($from_domain) = ($self->_header_value('from') // '') =~ /\@([\w.-]+)/;
	return unless $from_domain;
	my $reg_dkim = _registrable($auth->{dkim_domain}) // $auth->{dkim_domain};
	my $reg_from = _registrable(lc $from_domain)     // lc $from_domain;
	return if $reg_dkim eq $reg_from;

	# Passing DKIM with a different domain is normal for ESPs
	if ($auth->{dkim} && $auth->{dkim} =~ /^pass/i) {
		$flag->('INFO', 'dkim_domain_mismatch',
			"DKIM signed by '$auth->{dkim_domain}' but From: domain is '$from_domain'"
			. ' -- message sent via third-party sender (normal for bulk/ESP mail)');
	} else {
		# Failing DKIM plus mismatched domain is more suspicious
		$flag->('MEDIUM', 'dkim_domain_mismatch',
			"DKIM signed by '$auth->{dkim_domain}' but From: domain is '$from_domain'"
			. ' and DKIM did not pass -- possible impersonation');
	}
}

# _risk_check_date( $flag )
#
# Purpose:
#   Validate the Date: header for presence, plausible timezone, and
#   date not too far in the past or future.
#
# Entry criteria:
#   $flag -- accumulator coderef.
#
# Exit status:
#   Returns nothing; side effects via $flag closure.

sub _risk_check_date :Private {
	my ($self, $flag) = @_;
	my $date_raw = $self->_header_value('date');

	if (!$date_raw || $date_raw !~ /\S/) {
		$flag->('MEDIUM', 'missing_date',
			'No Date: header -- violates RFC 5322; common in spam');
		return;
	}

	# Check for an implausible timezone offset (outside real-world bounds)
	if ($date_raw =~ /([+-])(\d{2})(\d{2})\s*$/) {
		my ($sign, $hh, $mm) = ($1, $2, $3);
		my $offset_mins = $hh * 60 + $mm;
		my $implausible = $mm >= 60
			|| ($sign eq '+' && $offset_mins > $TZ_MAX_POS_MINS)
			|| ($sign eq '-' && $offset_mins > $TZ_MAX_NEG_MINS);
		if ($implausible) {
			$flag->('MEDIUM', 'implausible_timezone',
				"Date: '$date_raw' contains an implausible timezone offset "
				. "($sign$hh$mm) -- header is likely forged");
		}
	}

	# Check for dates more than DATE_SKEW_DAYS outside the analysis window
	my $date_epoch = _parse_rfc2822_date($date_raw);
	return unless defined $date_epoch;
	my $delta = time() - $date_epoch;
	if ($delta > $DATE_SKEW_DAYS * $SECS_PER_DAY) {
		$flag->('LOW', 'suspicious_date',
			"Date: '$date_raw' is more than $DATE_SKEW_DAYS days in the past");
	} elsif ($delta < -($DATE_SKEW_DAYS * $SECS_PER_DAY)) {
		$flag->('LOW', 'suspicious_date',
			"Date: '$date_raw' is more than $DATE_SKEW_DAYS days in the future");
	}
}

# _risk_check_identity( $flag )
#
# Purpose:
#   Check From: display-name spoofing, free webmail, Reply-To mismatch,
#   undisclosed recipients, and MIME-encoded Subject.
#
# Entry criteria:
#   $flag -- accumulator coderef.
#
# Exit status:
#   Returns nothing; side effects via $flag closure.

sub _risk_check_identity :Private {
	my ($self, $flag) = @_;
	my $from_raw     = $self->_header_value('from') // '';
	my $from_decoded = $self->_decode_mime_words($from_raw);

	# Display-name domain spoofing: "PayPal paypal.com" <phish@evil.example>
	if ($from_decoded =~ /^"?([^"<]+?)"?\s*<([^>]+)>/) {
		my ($display, $addr) = ($1, $2);
		while ($display =~ /\b([\w-]+\.(?:com|net|org|io|co|uk|au|gov|edu))\b/gi) {
			my $disp_domain = lc $1;
			my ($addr_domain) = $addr =~ /\@([\w.-]+)/;
			$addr_domain = lc($addr_domain // '');
			my $reg_disp = _registrable($disp_domain);
			my $reg_addr = _registrable($addr_domain);
			if ($reg_disp && $reg_addr && $reg_disp ne $reg_addr) {
				$flag->('HIGH', 'display_name_domain_spoof',
					"From: display name mentions '$disp_domain' but actual address is <$addr>");
			}
		}
	}

	# Free webmail sender flag (no corporate infrastructure)
	if ($from_raw =~ /\@(gmail|yahoo|hotmail|outlook|live|aol|protonmail|yandex)\./i
	 || $from_raw =~ /\@mail\.ru(?:[\s>]|$)/i) {
		$flag->('MEDIUM', 'free_webmail_sender',
			"Message sent from free webmail address ($from_raw)");
	}

	# Reply-To differs from From: -- replies harvested by different address
	my $reply_to = $self->_header_value('reply-to');
	if ($reply_to) {
		my ($from_addr)  = $from_raw =~ /([\w.+%-]+\@[\w.-]+)/;
		my ($reply_addr) = $reply_to =~ /([\w.+%-]+\@[\w.-]+)/;
		if ($from_addr && $reply_addr && lc($from_addr) ne lc($reply_addr)) {
			$flag->('MEDIUM', 'reply_to_differs_from_from',
				"Reply-To ($reply_addr) differs from From: ($from_addr)");
		}
	}

	# Undisclosed or absent To: header
	my $to = $self->_header_value('to') // '';
	if ($to =~ /undisclosed|:;/ || $to eq '') {
		$flag->('MEDIUM', 'undisclosed_recipients',
			"To: header is '$to' -- message was bulk-sent with hidden recipient list");
	}

	# MIME-encoded Subject (potential filter evasion)
	my $subj_raw = $self->_header_value('subject') // '';
	if ($subj_raw =~ /=\?[^?]+\?[BQ]\?/i) {
		$flag->('LOW', 'encoded_subject',
			"Subject line is MIME-encoded: '$subj_raw' (decoded: '"
			. $self->_decode_mime_words($subj_raw) . "')");
	}
}

# _risk_check_urls_and_domains( $flag )
#
# Purpose:
#   Check embedded URLs for shorteners and plain HTTP, and contact domains
#   for recent registration, imminent expiry, and lookalike brand names.
#
# Entry criteria:
#   $flag -- accumulator coderef.
#
# Exit status:
#   Returns nothing; side effects via $flag closure.

sub _risk_check_urls_and_domains :Private {
	my ($self, $flag) = @_;
	my (%shortener_seen, %url_host_seen);

	for my $u ($self->embedded_urls()) {
		# Skip trusted infrastructure -- these are not spam indicators
		my $bare = lc $u->{host};
		$bare =~ s/^www\.//;
		next if $self->{trusted_domains}->{$bare};
		next if $TRUSTED_DOMAINS{$bare};

		# URL shortener hides real destination
		if(($URL_SHORTENERS{$bare} || $self->{url_shorteners}->{$bare}) && !$shortener_seen{$bare}++) {
			$flag->('MEDIUM', 'url_shortener',
				"$u->{host} is a URL shortener -- the real destination is hidden");
		}
		# Plain HTTP provides no encryption
		if ($u->{url} =~ m{^http://}i && !$url_host_seen{ $u->{host} }++) {
			$flag->('LOW', 'http_not_https',
				"$u->{host} linked over plain HTTP -- no encryption");
		}
	}

	# Domain-level checks against contact/reply domains
	for my $d ($self->mailto_domains()) {
		# Recently registered domain is a common phishing indicator
		if ($d->{recently_registered}) {
			$flag->('HIGH', 'recently_registered_domain',
				"$d->{domain} was registered $d->{registered} (less than ${\$RECENT_REG_DAYS} days ago)");
		}

		# Domain expiry checks
		if ($d->{expires}) {
			if(my $exp = $self->_parse_date_to_epoch($d->{expires})) {
				my $now      = time();
				my $remaining = $exp - $now;
				if ($remaining > 0 && $remaining < $EXPIRY_WARN_DAYS * $SECS_PER_DAY) {
					$flag->('HIGH', 'domain_expires_soon',
						"$d->{domain} expires $d->{expires} -- may be a throwaway domain");
				} elsif ($remaining <= 0) {
					$flag->('HIGH', 'domain_expired',
						"$d->{domain} expired $d->{expires} -- domain has lapsed");
				}
			}
		}

		# Lookalike domain check (brand name in a non-brand domain)
		for my $brand (@LOOKALIKE_BRANDS) {
			if ($d->{domain} =~ /\Q$brand\E/i &&
			    $d->{domain} !~ /^\Q$brand\E\.(?:com|co\.uk|net|org)$/) {
				$flag->('HIGH', 'lookalike_domain',
					"$d->{domain} contains brand name '$brand' but is not the real domain -- possible phishing");
				last;
			}
		}
	}
}

# -----------------------------------------------------------------------
# Public: abuse report text
# -----------------------------------------------------------------------

=head2 abuse_report_text()

Produces a compact, plain-text string suitable for sending as the body of
an abuse report email.  It summarises risk level, red flags, originating IP,
abuse contacts, and original message headers.  The message body is omitted
to keep the report concise.

Use C<abuse_contacts()> to get the recipient addresses and this method for
the body text.

=head3 Usage

    my $text     = $analyser->abuse_report_text();
    my @contacts = $analyser->abuse_contacts();
    for my $c (@contacts) {
        send_email(to => $c->{address}, body => $text);
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A plain scalar string, newline-terminated, Unix line endings.  Never empty
or undef.

=head3 Side Effects

Calls C<risk_assessment()>, C<originating_ip()>, and C<abuse_contacts()>
if not already cached.

=head3 Notes

Output text is sanitised: control characters that could affect terminal or
HTML rendering are stripped from all user-derived content before inclusion.

=head3 API Specification

=head4 Input

    []

=head4 Output

    { type => 'string' }

=cut

sub abuse_report_text {
	my $self = $_[0];
	my @out;

	push @out, 'This is an automated abuse report generated by Email::Abuse::Investigator.',
		 'Please investigate the following spam/phishing message.',
		'';

	my $risk = $self->risk_assessment();
	push @out, "RISK LEVEL: $risk->{level} (score: $risk->{score})",
		'';

	# List each red flag with its severity prefix
	if (@{ $risk->{flags} }) {
		push @out, 'RED FLAGS IDENTIFIED:';
		for my $f (@{ $risk->{flags} }) {
			push @out, "  [$f->{severity}] " . _sanitise_output($f->{detail});
		}
		push @out, '';
	}

	# Originating IP summary block
	my $orig = $self->originating_ip();
	if ($orig) {
		push @out, 'ORIGINATING IP: ' . _sanitise_output("$orig->{ip} ($orig->{rdns})"),
			'NETWORK OWNER:  ' . _sanitise_output($orig->{org}),
			'';
	}

	# Email abuse contacts
	my @contacts = $self->abuse_contacts();
	if (@contacts) {
		push @out, 'ABUSE CONTACTS:';
		push @out, '  ' . _sanitise_output("$_->{address} ($_->{role})") for @contacts;
		push @out, '';
	}

	# Web-form contacts (providers that reject email)
	if(my @form_cs = $self->form_contacts()) {
		push @out, 'WEB-FORM REPORTS REQUIRED:',
			'  The following parties do not accept email -- submit manually:';
		for my $c (@form_cs) {
			push @out, "  [$c->{role}]",
				'    Form   : ' . _sanitise_output($c->{form});
			push @out, '    Domain : ' . _sanitise_output($c->{form_domain}) if $c->{form_domain};
			push @out, '    Paste  : ' . _sanitise_output($c->{form_paste})  if $c->{form_paste};
			push @out, '    Upload : ' . _sanitise_output($c->{form_upload}) if $c->{form_upload};
		}
		push @out, '';
	}

	# Separator and raw headers (body excluded for brevity)
	push @out, '-' x 72,
		'ORIGINAL MESSAGE HEADERS:',
		'-' x 72;

	for my $h (@{ $self->{_headers} }) {
		push @out, _sanitise_output("$h->{name}: $h->{value}");
	}
	push @out, '';

	return join("\n", @out);
}

# -----------------------------------------------------------------------
# Public: abuse contacts
# -----------------------------------------------------------------------

=head2 abuse_contacts()

Collates the complete set of parties that should receive an abuse report:
the sending ISP, URL host operators, contact domain web/mail/DNS/registrar
contacts, account providers identified from key headers, the DKIM signer,
and the ESP identified via List-Unsubscribe.

Addresses are deduplicated globally; if the same address is found via
multiple routes, a single entry is kept and role strings are merged.

=head3 Usage

    my @contacts = $analyser->abuse_contacts();
    my @addrs    = map { $_->{address} } @contacts;

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list of hashrefs, one per unique abuse address, in discovery order.
Each hashref has keys C<role>, C<roles> (arrayref), C<address>, C<note>,
C<via>.  Returns an empty list if no contacts can be determined.

=head3 Side Effects

Triggers C<originating_ip()>, C<embedded_urls()>, and C<mailto_domains()>
if not already cached.

=head3 Notes

The result is not independently cached; each call recomputes the contact
list from the cached results of the underlying methods.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub abuse_contacts {
	my $self = $_[0];
	$self->{_contacts} //= [ $self->_compute_abuse_contacts() ];
	return @{ $self->{_contacts} };
}

# _compute_abuse_contacts() -> list of contact hashrefs
#
# Purpose:
#   Actual implementation of abuse_contacts(). Separated so the public
#   method can cache without duplicating logic.
#
# Entry criteria:
#   parse_email() must have been called.
#
# Exit status:
#   Returns list of deduplicated contact hashrefs.

sub _compute_abuse_contacts :Private {
	my $self = $_[0];

	my (@contacts, %seen_idx);

	# Inner closure: add one contact entry, merging roles for duplicate addresses
	my $add = sub {
		my (%args) = @_;
		my $addr = lc($args{address} // '');
		return unless $addr && $addr =~ /\@/;

		# Suppress addresses belonging to form-only providers (no email accepted)
		if ($addr =~ /\@([\w.-]+)$/) {
			my $dom = $1;
			my $pa  = $self->_provider_abuse_for_host($dom);
			return if $pa && $pa->{form} && !$pa->{email};
		}

		if (exists $seen_idx{$addr}) {
			# Merge the new role into the existing entry
			my $entry = $contacts[ $seen_idx{$addr} ];
			push @{ $entry->{roles} }, $args{role};

			# Collapse repeated role labels to avoid unreadable strings
			my (%role_counts, @ordered_roles);
			for my $r (@{ $entry->{roles} }) {
				push @ordered_roles, $r unless $role_counts{$r}++;
			}
			my @display = map {
				$role_counts{$_} > 1 ? "$_ (x$role_counts{$_})" : $_
			} @ordered_roles;
			my $joined = join(' and ', @display);

			# Summarise if the merged string is too long to read
			if (length($joined) > $ROLE_MAX_LEN) {
				my @short;
				for (@display) {
					(my $s = $_) =~ s/[:(\d].*//;
					$s =~ s/\s+$//;
					push @short, $s;
				}
				$joined = scalar(@display) . ' routes: ' . join(', ', @short);
			}
			$entry->{role} = $joined;
			return;
		}

		# First time seeing this address -- record and store
		$seen_idx{$addr} = scalar @contacts;
		$args{roles} = [ $args{role} ];
		push @contacts, \%args;
	};

	# Route 1 -- Sending ISP (originating IP)
	my $orig = $self->originating_ip();
	if ($orig) {
		my $pa = $self->_provider_abuse_for_ip($orig->{ip}, $orig->{rdns});
		if ($pa) {
			$add->(
				role    => 'Sending ISP',
				address => $pa->{email},
				note    => "$orig->{ip} ($orig->{rdns}) -- $pa->{note}",
				via     => 'provider-table',
			);
		}
		if ($orig->{abuse} && $orig->{abuse} ne '(unknown)') {
			$add->(
				role    => 'Sending ISP',
				address => $orig->{abuse},
				note    => "Network owner of originating IP $orig->{ip} ($orig->{org})",
				via     => 'ip-whois',
			);
		}
	}

	# Route 2 -- URL hosts
	my %url_host_seen;
	for my $u ($self->embedded_urls()) {
		next if $url_host_seen{ $u->{host} }++;
		my $bare_host = lc $u->{host};
		$bare_host =~ s/^www\.//;
		# Skip trusted infrastructure (Google, W3C, etc.)
		next if $self->{trusted_domains}->{$bare_host};
		next if $TRUSTED_DOMAINS{$bare_host};
		my $pa = $self->_provider_abuse_for_host($u->{host});
		if ($pa) {
			$add->(
				role    => "URL host: $u->{host}",
				address => $pa->{email},
				note    => "$u->{host} -- $pa->{note}",
				via     => 'provider-table',
			);
		}
		if ($u->{abuse} && $u->{abuse} ne '(unknown)') {
			$add->(
				role    => "URL host: $u->{host}",
				address => $u->{abuse},
				note    => "Hosting $u->{host} ($u->{ip}, $u->{org})",
				via     => 'ip-whois',
			);
		}
	}

	# Route 3 -- Contact domain hosting and registration
	for my $d ($self->mailto_domains()) {
		my $dom = $d->{domain};

		# Web host contact
		if ($d->{web_abuse}) {
			my $pa = $self->_provider_abuse_for_host($dom);
			if ($pa) {
				$add->(role => "Web host of $dom", address => $pa->{email},
				       note => $pa->{note}, via => 'provider-table');
			}
			$add->(
				role    => "Web host of $dom",
				address => $d->{web_abuse},
				note    => sprintf('Hosting %s (%s, %s)',
				             $dom             // '(unknown domain)',
				             $d->{web_ip}     // '(unknown IP)',
				             $d->{web_org}    // '(unknown org)'),
				via     => 'ip-whois',
			);
		}

		# MX (mail host) contact
		if ($d->{mx_abuse}) {
			$add->(
				role    => "Mail host (MX) for $dom",
				address => $d->{mx_abuse},
				note    => sprintf('MX %s (%s, %s)',
				             $d->{mx_host} // '(unknown host)',
				             $d->{mx_ip}   // '(unknown IP)',
				             $d->{mx_org}  // '(unknown org)'),
				via     => 'ip-whois',
			);
		}

		# NS (DNS host) contact
		if ($d->{ns_abuse}) {
			$add->(
				role    => "DNS host (NS) for $dom",
				address => $d->{ns_abuse},
				note    => sprintf('NS %s (%s, %s)',
				             $d->{ns_host} // '(unknown host)',
				             $d->{ns_ip}   // '(unknown IP)',
				             $d->{ns_org}  // '(unknown org)'),
				via     => 'ip-whois',
			);
		}

		# Domain registrar (skip if domain only seen in spoofable headers)
		if ($d->{registrar_abuse}) {
			my $spoofable_only =
				$d->{source} =~ /^(?:From:|Return-Path:|Sender:) header$/ &&
				!scalar(grep {
					$_->{host} &&
					_registrable($_->{host}) eq (_registrable($dom) // $dom)
				} $self->embedded_urls());
			unless ($spoofable_only) {
				$add->(
					role    => "Domain registrar for $dom",
					address => $d->{registrar_abuse},
					note    => 'Registrar: ' . ($d->{registrar} // '(unknown)'),
					via     => 'domain-whois',
				);
			}
		}
	}

	# Route 4 -- From:/Reply-To:/Return-Path:/Sender: account provider
	for my $hname (qw(from reply-to return-path sender)) {
		my $val = $self->_header_value($hname) // next;

		# Extract addr-spec from angle-bracket form to avoid display-name @-signs
		my $addr_spec = ($val =~ /<([^>]*)>\s*$/) ? $1 : $val;
		my ($addr_domain) = $addr_spec =~ /\@([\w.-]+)/;
		next unless $addr_domain;

		# Skip SRS-rewritten forwarder addresses (not the real sender)
		next if $addr_spec =~ /\+SRS[0-9]?=/i;

		my $pa = $self->_provider_abuse_for_host($addr_domain);
		if ($pa) {
			my $role_addr = $addr_spec =~ /\@/ ? $addr_spec : $val;
			$role_addr =~ s/^\s+|\s+$//g;
			$add->(
				role    => "Account provider ($hname: $role_addr)",
				address => $pa->{email},
				note    => $pa->{note},
				via     => 'provider-table',
			);
		}
	}

	# Route 5 -- DKIM signing organisation
	my $auth = $self->_parse_auth_results_cached();
	if ($auth->{dkim_domain}) {
		my $pa = $self->_provider_abuse_for_host($auth->{dkim_domain});
		if ($pa) {
			$add->(
				role    => "DKIM signer: $auth->{dkim_domain}",
				address => $pa->{email},
				note    => $pa->{note},
				via     => 'provider-table',
			);
		}
	}

	# Route 6 -- List-Unsubscribe ESP domain
	my $unsub = $self->_header_value('list-unsubscribe');
	if ($unsub) {
		my @unsub_domains;
		while ($unsub =~ m{https?://([^/:?\s>]+)}gi) {
			push @unsub_domains, lc $1;
		}
		while ($unsub =~ m{mailto:[^@\s>]+\@([\w.-]+)}gi) {
			push @unsub_domains, lc $1;
		}
		my %unsub_seen;
		for my $dom (grep { !$unsub_seen{$_}++ } @unsub_domains) {
			my $pa = $self->_provider_abuse_for_host($dom);
			if ($pa) {
				$add->(
					role    => "ESP / bulk sender (List-Unsubscribe: $dom)",
					address => $pa->{email},
					note    => "$pa->{note} -- responsible for this bulk delivery",
					via     => 'provider-table',
				);
			}
		}
	}

	# Route 7 -- Reply addresses embedded in the message body
	my %body_addr_seen;
	my $combined_body = $self->{_body_plain} . "\n" . $self->{_body_html};
	for my $addr_dom ($self->_domains_from_text($combined_body)) {
		next if $body_addr_seen{$addr_dom}++;
		my $pa = $self->_provider_abuse_for_host($addr_dom);
		next unless $pa && $pa->{email};
		my ($example_addr) = $combined_body =~ /(\S+\@\Q$addr_dom\E)/i;
		$example_addr //= "\@$addr_dom";
		$add->(
			role    => "Reply address in body ($example_addr)",
			address => $pa->{email},
			note    => $pa->{note},
			via     => 'provider-table',
		);
	}

	return @contacts;
}

# -----------------------------------------------------------------------
# Public: form contacts (providers that require web-form submission)
# -----------------------------------------------------------------------

=head2 form_contacts()

Returns the list of parties that require abuse reports via a web form
rather than email.  These are providers whose C<%PROVIDER_ABUSE> entry
has a C<form> key.  Each hashref includes the form URL, paste
instructions, upload instructions, and the discovery role.

=head3 Usage

    my @forms = $analyser->form_contacts();
    for my $c (@forms) {
        printf "Open: %s\n", $c->{form};
    }

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list of hashrefs, one per unique form contact.  Each hashref has keys
C<form>, C<role>, C<note>, C<form_paste> (optional), C<form_upload>
(optional), and C<via>.  Returns an empty list if no form contacts are found.

=head3 Side Effects

Triggers C<originating_ip()>, C<embedded_urls()>, and C<mailto_domains()>
if not already cached.

=head3 Notes

Deduplication is by form URL.

=head3 API Specification

=head4 Input

    []

=head4 Output

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

=cut

sub form_contacts {
	my $self = $_[0];

	my (@contacts, %seen);

	# Inner closure: add one form-contact entry, deduplicating by form URL
	my $add = sub {
		my (%args) = @_;
		my $form = $args{form} // '';
		return unless $form;
		return if $seen{$form}++;
		push @contacts, \%args;
	};

	# Route 1 -- Sending ISP
	my $orig = $self->originating_ip();
	if ($orig) {
		my $pa = $self->_provider_abuse_for_ip($orig->{ip}, $orig->{rdns});
		if ($pa && $pa->{form}) {
			$add->(
				role        => 'Sending ISP',
				form        => $pa->{form},
				note        => $pa->{note} // '',
				form_paste  => $pa->{form_paste}  // '',
				form_upload => $pa->{form_upload} // '',
				via         => 'provider-table',
			);
		}
	}

	# Route 2 -- URL hosts
	my %url_host_seen;
	for my $u ($self->embedded_urls()) {
		next if $url_host_seen{ $u->{host} }++;
		my $pa = $self->_provider_abuse_for_host($u->{host});
		if ($pa && $pa->{form}) {
			$add->(
				role        => "URL host: $u->{host}",
				form        => $pa->{form},
				form_domain => $u->{host},
				note        => $pa->{note} // '',
				form_paste  => $pa->{form_paste}  // '',
				form_upload => $pa->{form_upload} // '',
				via         => 'provider-table',
			);
		}
	}

	# Route 3 -- Contact domains (web host + registrar)
	for my $d ($self->mailto_domains()) {
		my $dom = $d->{domain};
		my $pa  = $self->_provider_abuse_for_host($dom);
		if ($pa && $pa->{form}) {
			$add->(
				role        => "Web host of $dom",
				form        => $pa->{form},
				form_domain => $dom,
				note        => $pa->{note} // '',
				form_paste  => $pa->{form_paste}  // '',
				form_upload => $pa->{form_upload} // '',
				via         => 'provider-table',
			);
		}

		# Registrar identified via WHOIS -- check for form-only registrar
		if ($d->{registrar_abuse} && $d->{registrar_abuse} =~ /\@([\w.-]+)/) {
			my $reg_domain = lc $1;
			my $rpa = $self->_provider_abuse_for_host($reg_domain);
			if ($rpa && $rpa->{form}) {
				$add->(
					role        => "Domain registrar for $dom (web form only)",
					form        => $rpa->{form},
					form_domain => $dom,
					note        => $rpa->{note} // '',
					form_paste  => $rpa->{form_paste}  // '',
					form_upload => $rpa->{form_upload} // '',
					via         => 'provider-table',
				);
			}
		}
	}

	# Route 4 -- Account provider headers
	for my $hname (qw(from reply-to return-path sender)) {
		my $val = $self->_header_value($hname) // next;
		my $addr_spec = ($val =~ /<([^>]*)>\s*$/) ? $1 : $val;
		my ($addr_domain) = $addr_spec =~ /\@([\w.-]+)/;
		next unless $addr_domain;
		# Skip SRS forwarder rewrite addresses
		next if $addr_spec =~ /\+SRS[0-9]?=/i;
		my $pa = $self->_provider_abuse_for_host($addr_domain);
		if ($pa && $pa->{form}) {
			my $role_addr = $addr_spec =~ /@/ ? $addr_spec : $val;
			$role_addr =~ s/^\s+|\s+$//g;
			$add->(
				role        => "Account provider ($hname: $role_addr)",
				form        => $pa->{form},
				note        => $pa->{note} // '',
				form_paste  => $pa->{form_paste}  // '',
				form_upload => $pa->{form_upload} // '',
				via         => 'provider-table',
			);
		}
	}

	# Route 5 -- DKIM signer
	my $auth = $self->_parse_auth_results_cached();
	if ($auth->{dkim_domain}) {
		my $pa = $self->_provider_abuse_for_host($auth->{dkim_domain});
		if ($pa && $pa->{form}) {
			$add->(
				role        => "DKIM signer: $auth->{dkim_domain}",
				form        => $pa->{form},
				note        => $pa->{note} // '',
				form_paste  => $pa->{form_paste}  // '',
				form_upload => $pa->{form_upload} // '',
				via         => 'provider-table',
			);
		}
	}

	# Route 6 -- List-Unsubscribe ESP domains
	my $unsub = $self->_header_value('list-unsubscribe');
	if ($unsub) {
		my @unsub_domains;
		while ($unsub =~ m{https?://([^/:?\s>]+)}gi) { push @unsub_domains, lc $1 }
		while ($unsub =~ m{mailto:[^@\s>]+\@([\w.-]+)}gi) { push @unsub_domains, lc $1 }
		my %useen;
		for my $dom (grep { !$useen{$_}++ } @unsub_domains) {
			my $pa = $self->_provider_abuse_for_host($dom);
			if ($pa && $pa->{form}) {
				$add->(
					role        => "ESP / bulk sender (List-Unsubscribe: $dom)",
					form        => $pa->{form},
					note        => $pa->{note} // '',
					form_paste  => $pa->{form_paste}  // '',
					form_upload => $pa->{form_upload} // '',
					via         => 'provider-table',
				);
			}
		}
	}

	return @contacts;
}

# -----------------------------------------------------------------------
# Public: full analyst report
# -----------------------------------------------------------------------

=head2 report()

Produces a comprehensive, analyst-facing plain-text report covering all
findings: envelope fields, risk assessment, originating host, sending
software, received chain tracking IDs, embedded URLs, contact domain
intelligence, and recommended abuse contacts.

Use C<report()> for human review or ticketing systems.  Use
C<abuse_report_text()> for sending to ISP abuse desks.

=head3 Usage

    print $analyser->report();

    open my $fh, '>', 'report.txt' or croak "Cannot open: $!";
    print $fh $analyser->report();
    close $fh;

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A plain scalar string, newline-terminated, Unix line endings.  Never empty
or undef.

=head3 Side Effects

Triggers all analysis methods if not already cached.

=head3 Notes

The report is idempotent: calling it multiple times on the same object
always returns an identical string.  All user-derived content is sanitised
before output.

=head3 API Specification

=head4 Input

    []

=head4 Output

    { type => 'string' }

=cut

sub report {
	my $self = $_[0];

	my @out;

	# Banner header
	push @out, '=' x 72;
	push @out, "  Email::Abuse::Investigator Report  (v$VERSION)";
	push @out, '=' x 72;
	push @out, '';

	# Envelope summary -- decode MIME encoded-words for readability
	for my $f (qw(from reply-to return-path subject date message-id)) {
		my $v = $self->_header_value($f);
		next unless defined $v;
		my $decoded = $self->_decode_mime_words($v);
		my $label   = ucfirst($f);
		push @out, sprintf('  %-14s : %s', $label,
			_sanitise_output($decoded ne $v ? "$decoded  [encoded: $v]" : $v));
	}
	push @out, '';

	# Risk assessment section
	my $risk = $self->risk_assessment();
	push @out, "[ RISK ASSESSMENT: $risk->{level} (score: $risk->{score}) ]";
	if (@{ $risk->{flags} }) {
		for my $f (@{ $risk->{flags} }) {
			push @out, "  [$f->{severity}] " . _sanitise_output($f->{detail});
		}
	} else {
		push @out, '  (no specific red flags detected)';
	}
	push @out, '';

	# Originating host section
	push @out, '[ ORIGINATING HOST ]';
	my $orig = $self->originating_ip();
	if ($orig) {
		push @out, '  IP           : ' . _sanitise_output($orig->{ip});
		push @out, '  Reverse DNS  : ' . _sanitise_output($orig->{rdns})    if $orig->{rdns};
		push @out, '  Country      : ' . _sanitise_output($orig->{country}) if $orig->{country};
		push @out, '  Organisation : ' . _sanitise_output($orig->{org})     if $orig->{org};
		push @out, '  Abuse addr   : ' . _sanitise_output($orig->{abuse})   if $orig->{abuse};
		push @out, "  Confidence   : $orig->{confidence}";
		push @out, '  Note         : ' . _sanitise_output($orig->{note})    if $orig->{note};
	} else {
		push @out, '  (could not determine originating IP)';
	}
	push @out, '';

	# Sending software section (omitted if none found)
	my @sw = $self->sending_software();
	if (@sw) {
		push @out, '[ SENDING SOFTWARE / INFRASTRUCTURE CLUES ]';
		for my $s (@sw) {
			push @out, sprintf('  %-14s : %s', $s->{header}, _sanitise_output($s->{value}));
			push @out, "  Note           : $s->{note}";
			push @out, '';
		}
	}

	# Received chain tracking IDs (only hops with id or for are shown)
	my @trail = grep { defined $_->{id} || defined $_->{for} }
	            $self->received_trail();
	if (@trail) {
		push @out, '[ RECEIVED CHAIN TRACKING IDs ]';
		push @out, '  (Supply these to the relevant ISP abuse team to trace the session)';
		push @out, '';
		for my $hop (@trail) {
			push @out, '  IP           : ' . (_sanitise_output($hop->{ip}) // '(unknown)');
			push @out, '  Envelope for : ' . _sanitise_output($hop->{for}) if $hop->{for};
			push @out, '  Server ID    : ' . _sanitise_output($hop->{id})  if $hop->{id};
			push @out, '';
		}
	}

	# Embedded URLs section -- grouped by hostname
	push @out, '[ EMBEDDED HTTP/HTTPS URLs ]';
	my @urls = $self->embedded_urls();
	if (@urls) {
		my (%host_order, %host_meta, %host_paths);
		my $seq = 0;
		for my $u (@urls) {
			my $h = $u->{host};
			unless (exists $host_order{$h}) {
				$host_order{$h} = $seq++;
				$host_meta{$h}  = {
					ip      => $u->{ip},
					org     => $u->{org},
					abuse   => $u->{abuse},
					country => $u->{country},
				};
			}
			push @{ $host_paths{$h} }, $u->{url};
		}

		# Output each host group in first-seen order
		for my $h (sort { $host_order{$a} <=> $host_order{$b} } keys %host_order) {
			my $m    = $host_meta{$h};
			my $bare = lc $h; $bare =~ s/^www\.//;
			push @out, '  Host         : ' . _sanitise_output($h) .
			           (($URL_SHORTENERS{$bare} || $self->{url_shorteners}->{$bare})
			            ? '  *** URL SHORTENER -- real destination hidden ***' : '');
			push @out, '  IP           : ' . _sanitise_output($m->{ip})      if $m->{ip};
			push @out, '  Country      : ' . _sanitise_output($m->{country}) if $m->{country};
			push @out, '  Organisation : ' . _sanitise_output($m->{org})     if $m->{org};
			push @out, '  Abuse addr   : ' . _sanitise_output($m->{abuse})   if $m->{abuse};
			my @paths = @{ $host_paths{$h} };
			if (@paths == 1) {
				push @out, '  URL          : ' . _sanitise_output($paths[0]);
			} else {
				push @out, '  URLs (' . scalar(@paths) . ')     :';
				push @out, '    ' . _sanitise_output($_) for @paths;
			}
			push @out, '';
		}
	} else {
		push @out, '  (none found)';
		push @out, '';
	}

	# Contact / reply-to domains section
	push @out, '[ CONTACT / REPLY-TO DOMAINS ]';
	my @mdoms = $self->mailto_domains();
	if (@mdoms) {
		for my $d (@mdoms) {
			push @out, '  Domain       : ' . _sanitise_output($d->{domain});
			push @out, '  Found in     : ' . _sanitise_output($d->{source});
			if ($d->{recently_registered}) {
				push @out, '  *** WARNING: RECENTLY REGISTERED - possible phishing domain ***';
			}
			push @out, '  Registered   : ' . $d->{registered}       if $d->{registered};
			push @out, '  Expires      : ' . $d->{expires}           if $d->{expires};
			push @out, '  Registrar    : ' . _sanitise_output($d->{registrar})       if $d->{registrar};
			push @out, '  Reg. abuse   : ' . _sanitise_output($d->{registrar_abuse}) if $d->{registrar_abuse};
			if ($d->{web_ip}) {
				push @out, '  Web host IP  : ' . _sanitise_output($d->{web_ip});
				push @out, '  Web host org : ' . _sanitise_output($d->{web_org})   if $d->{web_org};
				push @out, '  Web abuse    : ' . _sanitise_output($d->{web_abuse}) if $d->{web_abuse};
			} else {
				push @out, '  Web host     : (no A record / unreachable)';
			}
			if ($d->{mx_host}) {
				push @out, '  MX host      : ' . _sanitise_output($d->{mx_host});
				push @out, '  MX IP        : ' . _sanitise_output($d->{mx_ip})    if $d->{mx_ip};
				push @out, '  MX org       : ' . _sanitise_output($d->{mx_org})   if $d->{mx_org};
				push @out, '  MX abuse     : ' . _sanitise_output($d->{mx_abuse}) if $d->{mx_abuse};
			} else {
				push @out, '  MX host      : (none found)';
			}
			if ($d->{ns_host}) {
				push @out, '  NS host      : ' . _sanitise_output($d->{ns_host});
				push @out, '  NS IP        : ' . _sanitise_output($d->{ns_ip})    if $d->{ns_ip};
				push @out, '  NS org       : ' . _sanitise_output($d->{ns_org})   if $d->{ns_org};
				push @out, '  NS abuse     : ' . _sanitise_output($d->{ns_abuse}) if $d->{ns_abuse};
			}
			push @out, '';
		}
	} else {
		push @out, '  (none found)';
		push @out, '';
	}

	# Abuse contacts summary
	push @out, '[ WHERE TO SEND ABUSE REPORTS ]';
	my @contacts = $self->abuse_contacts();
	if (@contacts) {
		for my $c (@contacts) {
			push @out, '  Role         : ' . _sanitise_output($c->{role});
			push @out, '  Send to      : ' . _sanitise_output($c->{address});
			push @out, '  Note         : ' . _sanitise_output($c->{note}) if $c->{note};
			push @out, "  Discovered   : $c->{via}";
			push @out, '';
		}
	} else {
		push @out, '  (no abuse contacts could be determined)';
		push @out, '';
	}

	# Web-form contacts (providers that require manual form submission)
	my @form_cs = $self->form_contacts();
	if (@form_cs) {
		push @out, '[ WHERE TO FILE WEB-FORM REPORTS ]';
		push @out, '  The following parties require manual submission via a web form.';
		push @out, '  Open each URL in a browser, then follow the instructions below it.';
		push @out, '';
		for my $c (@form_cs) {
			push @out, '  Role         : ' . _sanitise_output($c->{role});
			push @out, '  Form URL     : ' . _sanitise_output($c->{form});
			push @out, '  Domain/URL   : ' . _sanitise_output($c->{form_domain}) if $c->{form_domain};
			push @out, '  Note         : ' . _sanitise_output($c->{note})        if $c->{note};
			if ($c->{form_paste}) {
				# Word-wrap the paste hint at ROLE_WRAP_LEN characters
				my $hint  = $c->{form_paste};
				my @words = split /\s+/, $hint;
				my (@lines, $line);
				for my $w (@words) {
					if (defined $line && length("$line $w") > $ROLE_WRAP_LEN) {
						push @lines, $line;
						$line = $w;
					} else {
						$line = defined $line ? "$line $w" : $w;
					}
				}
				push @lines, $line if defined $line;
				push @out, '  Paste        : ' . shift @lines if @lines;
				push @out, '                 ' . $_ for @lines;
			}
			push @out, '  Upload       : ' . _sanitise_output($c->{form_upload}) if $c->{form_upload};
			push @out, '';
		}
	}

	push @out, '=' x 72;
	return join("\n", @out) . "\n";
}

# -----------------------------------------------------------------------
# Private: output sanitisation
# -----------------------------------------------------------------------

# _sanitise_output( $str ) -> $str
#
# Purpose:
#   Strip control characters that could affect terminal rendering or HTML
#   injection from any string that will appear in a report or abuse email.
#   Preserves printable ASCII, high-bytes (for UTF-8 content), tabs, and
#   line endings.
#
# Entry criteria:
#   $str -- a defined or undef scalar.
#
# Exit status:
#   Returns the sanitised string, or the empty string if $str is undef.
#
# Notes:
#   Only strips C0 control characters below 0x20 (except \t) and the DEL
#   character (0x7F).  High bytes (0x80-0xFF) are preserved because they
#   form valid UTF-8 multi-byte sequences in headers and body text.

sub _sanitise_output :Private {
	my $str = $_[0];
	return '' unless defined $str;
	# Remove C0 controls (except tab) and DEL
	$str =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g;
	return $str;
}

# -----------------------------------------------------------------------
# Private: message parsing
# -----------------------------------------------------------------------

# _split_message( $text )
#
# Purpose:
#   Split a raw RFC 2822 email into headers and body, parse all headers,
#   decode the body (including multipart), extract sending-software
#   fingerprints, and populate per-hop tracking data.
#
# Entry criteria:
#   $text -- defined scalar, already dereferenced by parse_email().
#   $self->{_sending_sw} and $self->{_rcvd_tracking} reset to [] by caller.
#
# Exit status:
#   Returns undef silently if the header block is empty/whitespace-only.
#   Otherwise all results are communicated via side effects on $self.
#
# Side effects:
#   Populates _headers, _received, _body_plain, _body_html, _sending_sw,
#   and _rcvd_tracking.
#
# Notes:
#   Delegates to _decode_multipart() for multipart/* content types.
#   Lines not matching the header pattern are silently discarded.
#   Boundary extraction uses a simple regex; missing boundary causes the
#   body to be skipped silently.

sub _split_message :Private {
	my ($self, $text) = @_;

	# Split at the first blank line (RFC 2822 header/body separator)
	my ($header_block, $body_raw) = split /\r?\n\r?\n/, $text, 2;

	return unless defined $header_block && $header_block =~ /\S/;
	$body_raw //= '';

	# Unfold RFC 2822 continuation lines (s2.2.3)
	$header_block =~ s/\r?\n([ \t]+)/ $1/g;

	# Parse each header line into a { name, value } pair
	my @headers;
	for my $line (split /\r?\n/, $header_block) {
		if ($line =~ /^([\w-]+)\s*:\s*(.*)/) {
			push @headers, { name => lc($1), value => $2 };
		}
	}
	$self->{_headers}  = \@headers;

	# Collect all Received: header values (most-recent first, as in message)
	$self->{_received} = [
		map  { $_->{value} }
		grep { $_->{name} eq 'received' } @headers
	];

	# Determine content type and transfer encoding from top-level headers
	my ($ct_h)  = grep { $_->{name} eq 'content-type' }              @headers;
	my ($cte_h) = grep { $_->{name} eq 'content-transfer-encoding' } @headers;
	my $ct  = defined $ct_h  ? $ct_h->{value}  : '';
	my $cte = defined $cte_h ? $cte_h->{value} : '';

	# Decode multipart or single-part body as appropriate
	if ($ct =~ /multipart/i) {
		my ($boundary) = $ct =~ /boundary="?([^";]+)"?/i;
		# Pass depth=0 to enforce the MAX_MULTIPART_DEPTH recursion guard
		$self->_decode_multipart($body_raw, $boundary, 0) if $boundary;
	} else {
		my $decoded = $self->_decode_body($body_raw, $cte);
		if ($ct =~ /html/i) { $self->{_body_html}  = $decoded }
		else                 { $self->{_body_plain} = $decoded }
	}

	$self->_debug(sprintf 'Parsed %d headers, %d Received lines',
		scalar @headers, scalar @{ $self->{_received} });

	# --- Sending software fingerprints ---
	# These headers identify the mailer or shared-hosting script that sent
	# the message; invaluable for shared-hosting abuse reports.
	my %sw_notes = (
		'x-php-originating-script' => 'PHP script on shared hosting -- report to hosting abuse team',
		'x-source'                 => 'Source file on shared hosting -- report to hosting abuse team',
		'x-source-host'            => 'Sending hostname injected by shared hosting provider',
		'x-source-args'            => 'Command-line args injected by shared hosting provider',
		'x-mailer'                 => 'Email client or bulk-mailer identifier',
		'user-agent'               => 'Email client identifier',
	);
	for my $sw_hdr (sort keys %sw_notes) {
		my ($h) = grep { $_->{name} eq $sw_hdr } @headers;
		next unless $h;
		push @{ $self->{_sending_sw} }, {
			header => $sw_hdr,
			value  => $h->{value},
			note   => $sw_notes{$sw_hdr},
		};
	}

	# --- Per-hop tracking IDs from Received: chain ---
	# Walk oldest-first (reverse) so _rcvd_tracking is oldest-first
	for my $rcvd (reverse @{ $self->{_received} }) {
		my $ip = $self->_extract_ip_from_received($rcvd);
		my ($for_addr) = $rcvd =~ /\bfor\s+<?([^\s>]+\@[\w.-]+\.[\w]+)>?/i;
		my ($srv_id)   = $rcvd =~ /\bid\s+([\w.-]+)/i;
		# Skip hops with no actionable tracking data
		next unless defined $ip || defined $for_addr || defined $srv_id;
		push @{ $self->{_rcvd_tracking} }, {
			received => $rcvd,
			ip       => $ip,
			for      => $for_addr,
			id       => $srv_id,
		};
	}
}

# _decode_multipart( $body, $boundary, $depth )
#
# Purpose:
#   Recursively split a MIME multipart body on its boundary and decode each
#   text/plain and text/html part.  Nested multipart/* containers are
#   recursed into up to MAX_MULTIPART_DEPTH levels deep.
#
# Entry criteria:
#   $body     -- the raw body text of the multipart container.
#   $boundary -- the boundary string from the Content-Type header.
#   $depth    -- current recursion depth (starts at 0 from _split_message).
#
# Exit status:
#   Returns undef if $depth >= MAX_MULTIPART_DEPTH (recursion guard).
#   Otherwise all results via side effects.
#
# Side effects:
#   Appends decoded text to $self->{_body_plain} and $self->{_body_html}.
#
# Notes:
#   Whitespace-only MIME segments between boundaries are silently skipped.
#   Decoding errors are silenced; raw bytes are used as fallback.

sub _decode_multipart :Private {
	my ($self, $body, $boundary, $depth) = @_;
	$depth //= 0;

	# Enforce the recursion depth limit to prevent stack exhaustion on
	# pathological crafted messages with deeply nested multipart structures.
	if ($depth >= $MAX_MULTIPART_DEPTH) {
		Carp::carp 'Email::Abuse::Investigator: multipart nesting depth limit',
			"($MAX_MULTIPART_DEPTH) exceeded; stopping recursion";
		return;
	}

	# Split on the boundary marker; the (?:--)? suffix handles closing boundary
	my @parts = split /--\Q$boundary\E(?:--)?/, $body;

	for my $part (@parts) {
		# Skip whitespace-only segments between boundaries
		next unless $part =~ /\S/;

		$part =~ s/^\r?\n//;

		# Each MIME part has its own headers separated from body by a blank line
		my ($phdr_block, $pbody) = split /\r?\n\r?\n/, $part, 2;
		next unless defined $pbody;

		# Unfold continuation header lines within this part
		$phdr_block =~ s/\r?\n([ \t]+)/ $1/g;

		# Parse this part's headers into a simple hash
		my %phdr;
		for my $line (split /\r?\n/, $phdr_block) {
			$phdr{ lc($1) } = $2 if $line =~ /^([\w-]+)\s*:\s*(.*)/;
		}

		my $pct  = $phdr{'content-type'}              // '';
		my $pcte = $phdr{'content-transfer-encoding'} // '';

		# Nested multipart/* must be recursed into; without this URLs in
		# multipart/alternative inside multipart/mixed would be missed.
		if ($pct =~ /multipart/i) {
			my ($inner_boundary) = $pct =~ /boundary\s*=\s*"?([^";]+)"?/i;
			if ($inner_boundary) {
				$inner_boundary =~ s/\s+$//;
				# Increment depth counter for the recursion guard
				$self->_decode_multipart($pbody, $inner_boundary, $depth + 1);
			}
			next;
		}

		# Decode transfer encoding and accumulate by content type
		my $decoded = $self->_decode_body($pbody, $pcte);
		if    ($pct =~ /text\/html/i)    { $self->{_body_html}  .= $decoded }
		elsif ($pct =~ /text/i || !$pct) { $self->{_body_plain} .= $decoded }
	}
}

# _decode_body( $body, $cte ) -> string
#
# Purpose:
#   Decode a MIME body part according to its Content-Transfer-Encoding.
#
# Entry criteria:
#   $body -- raw body string (may be undef).
#   $cte  -- Content-Transfer-Encoding value string (may be undef).
#
# Exit status:
#   Returns the decoded string, or the original string if the encoding is
#   7bit/8bit/binary or unrecognised.
#
# Notes:
#   decode_qp and decode_base64 are imported from MIME:: modules; errors
#   from malformed content are silenced by the eval wrappers they provide.

sub _decode_body :Private {
	my ($self, $body, $cte) = @_;
	$cte //= '';
	return decode_qp($body)     if $cte =~ /quoted-printable/i;
	return decode_base64($body) if $cte =~ /base64/i;
	return $body // '';
}

# -----------------------------------------------------------------------
# Private: Received-chain -> originating IP
# -----------------------------------------------------------------------

# _find_origin()
#
# Purpose:
#   Walk the Received: chain (oldest-first) to find the first external IP,
#   or fall back to X-Originating-IP.  Enrich with rDNS and WHOIS.
#
# Entry criteria:
#   $self->{_received} populated by _split_message().
#   $self->{trusted_relays} set by new().
#
# Exit status:
#   Returns { ip, rdns, org, abuse, country, confidence, note } on success.
#   Returns undef if no usable IP can be identified.
#
# Side effects:
#   Network I/O via _enrich_ip(): one PTR lookup, one RDAP/WHOIS query.
#   Results are also stored in the CHI cross-message cache if available.
#
# Notes:
#   confidence 'high' = 2+ distinct external IPs;
#   'medium' = exactly one external IP;
#   'low' = taken from X-Originating-IP.

sub _find_origin :Private {
	my $self = $_[0];

	my @candidates;

	# Walk oldest-first (reverse) to collect external IPs
	for my $hdr (reverse @{ $self->{_received} }) {
		my $ip = $self->_extract_ip_from_received($hdr) // next;
		next if $self->_is_private($ip);
		next if $self->_is_trusted($ip);
		push @candidates, $ip;
	}

	# Fall back to X-Originating-IP if no external IPs in Received: chain
	unless (@candidates) {
		my $xoip = $self->_header_value('x-originating-ip');
		if ($xoip) {
			$xoip =~ s/[\[\]\s]//g;
			return $self->_enrich_ip($xoip, 'low',
				'Taken from X-Originating-IP (webmail, unverified)')
				unless $self->_is_private($xoip);
		}
		return;
	}

	# Report the oldest (first) external IP; confidence depends on count
	return $self->_enrich_ip(
		$candidates[0],
		@candidates > 1 ? 'high' : 'medium',
		'First external hop in Received: chain',
	);
}

# _extract_ip_from_received( $hdr ) -> ipv4_or_ipv6_string | undef
#
# Purpose:
#   Extract the most-significant IP address from a raw Received: header
#   value, trying patterns in priority order.  Supports both IPv4 dotted-
#   quad and IPv6 bracket notation.
#
# Entry criteria:
#   $hdr -- a defined Received: header value string.
#
# Exit status:
#   Returns the IP string on success, undef if no IP can be extracted.
#
# Notes:
#   IPv4 addresses are validated (all octets <= 255).
#   IPv6 addresses are returned as-is if they contain colons.

sub _extract_ip_from_received :Private {
	my ($self, $hdr) = @_;
	for my $re (@RECEIVED_IP_RE) {
		if ($hdr =~ $re) {
			my $ip = $1;

			# Accept IPv6 addresses (contain colons) without further validation
			return $ip if $ip =~ /:/;

			# Validate IPv4 format and octet range
			next unless $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
			next if grep { $_ > 255 } split /\./, $ip;
			return $ip;
		}
	}
	return;
}

# _is_private( $ip ) -> bool
#
# Purpose:
#   Test whether an IP address falls in any private, reserved, or special-
#   use range (IPv4 or IPv6) that should never be reported as a spam origin.
#
# Entry criteria:
#   $ip -- a scalar IP string (IPv4 or IPv6); may be undef.
#
# Exit status:
#   Returns 1 (true) if the IP is private/reserved, 0 (false) otherwise.
#   Returns 1 for undef or empty strings.
#
# Notes:
#   Uses the module-level @PRIVATE_RANGES array of pre-compiled regexes.
#   Covers all ranges listed in RFC 1122, 1918, 5737, 6598, and RFC 4193.

sub _is_private :Private {
	my ($self, $ip) = @_;
	return 1 if !defined($ip) || $ip eq '';
	for my $re (@PRIVATE_RANGES) { return 1 if $ip =~ $re }
	return 0;
}

# _is_trusted( $ip ) -> bool
#
# Purpose:
#   Test whether an IP address matches any entry in the caller-supplied
#   trusted_relays list (exact IP or CIDR block).
#
# Entry criteria:
#   $ip -- a defined IPv4 address string.
#   $self->{trusted_relays} -- arrayref of exact IPs or CIDR strings.
#
# Exit status:
#   Returns 1 (true) if the IP matches any trusted relay, 0 otherwise.

sub _is_trusted :Private {
	my ($self, $ip) = @_;
	for my $cidr (@{ $self->{trusted_relays} }) {
		return 1 if $self->_ip_in_cidr($ip, $cidr);
	}
	return 0;
}

# -----------------------------------------------------------------------
# Private: HTTP/HTTPS URL extraction and resolution
# -----------------------------------------------------------------------

# _extract_and_resolve_urls() -> arrayref of url hashrefs
#
# Purpose:
#   Extract all HTTP/HTTPS URLs from the decoded body, resolve each unique
#   hostname to an IP, and enrich with WHOIS/RDAP data.  Optionally uses
#   AnyEvent::DNS to parallelise the DNS resolution step.
#
# Entry criteria:
#   $self->{_body_plain} and $self->{_body_html} populated by _split_message().
#
# Exit status:
#   Returns an arrayref of url hashrefs (possibly empty).
#
# Side effects:
#   Network I/O per unique hostname: one A/AAAA lookup, one RDAP/WHOIS.
#   Results stored in the CHI cross-message cache if available.

sub _extract_and_resolve_urls :Private {
	my $self = $_[0];
	my (%url_seen, %host_cache);
	my @results;
	my $combined = $self->{_body_plain} . "\n" . $self->{_body_html};

	# Collect unique URLs from body
	my @urls = grep { !$url_seen{$_}++ } $self->_extract_http_urls($combined);

	# Extract unique hostnames for parallel DNS resolution
	my %hostname_needed;
	for my $url (@urls) {
		my ($host) = $url =~ m{https?://([^/:?\s#]+)}i;
		$hostname_needed{$host}++ if $host;
	}

	# Parallelise DNS lookups if AnyEvent::DNS is available
	if ($HAS_ANYEVENT_DNS && scalar(keys %hostname_needed) > 1) {
		$self->_parallel_resolve_hosts(\%hostname_needed, \%host_cache);
	}

	# Process each URL: resolve hostname and WHOIS-enrich
	for my $url (@urls) {
		my ($host) = $url =~ m{https?://([^/:?\s#]+)}i;
		next unless $host;

		# Resolve and WHOIS once per unique hostname, then cache the result
		unless (exists $host_cache{$host}) {
			# Check the cross-message CHI cache first
			my $cached = $_cache ? $_cache->get("url:$host") : undef;
			if ($cached) {
				$host_cache{$host} = $cached;
			} else {
				my $ip    = $self->_resolve_host($host) // '(unresolved)';
				my $whois = $ip ne '(unresolved)'
				          ? $self->_whois_ip($ip)
				          : {};

				# Fall back to domain WHOIS if IP lookup returned nothing
				if (!$whois->{abuse}) {
					my $reg = _registrable($host) // $host;
					my $dw  = $self->_parse_domain_whois_abuse($reg);
					$whois  = $dw if $dw->{abuse};
				}

				my $entry = {
					ip      => $ip,
					org     => $whois->{org}     // '(unknown)',
					abuse   => $whois->{abuse}   // '(unknown)',
					country => $whois->{country} // undef,
				};
				$host_cache{$host} = $entry;

				# Store in cross-message cache for reuse across messages
				$_cache->set("url:$host", $entry) if $_cache;
			}
		}

		push @results, { url => $url, host => $host, %{ $host_cache{$host} } };
	}
	return \@results;
}

# _parallel_resolve_hosts( \%hostnames, \%cache )
#
# Purpose:
#   Resolve multiple hostnames to IPs in parallel using AnyEvent::DNS.
#   Populates the cache with resolved IPs so the sequential loop in
#   _extract_and_resolve_urls() can skip the DNS step for pre-resolved hosts.
#
# Entry criteria:
#   $hostnames_ref -- hashref keyed by hostname (values ignored).
#   $cache_ref     -- hashref to populate with { ip => '...' } results.
#   AnyEvent::DNS must be installed ($HAS_ANYEVENT_DNS is true).
#
# Exit status:
#   Returns undef; all results written to %$cache_ref via side effects.
#
# Notes:
#   Errors (NXDOMAIN, timeout) are silently swallowed; the sequential
#   resolution loop will return '(unresolved)' for those hosts.

sub _parallel_resolve_hosts :Private {
	my ($self, $hostnames_ref, $cache_ref) = @_;
	return unless $HAS_ANYEVENT_DNS;

	# Build an AnyEvent condvar to wait for all lookups to complete
	my $cv      = AnyEvent->condvar;
	my $pending = scalar keys %$hostnames_ref;

	for my $host (keys %$hostnames_ref) {
		# Fire an async A (and AAAA) query for each hostname
		AnyEvent::DNS::resolve(
			$host, 'A',
			sub {
				my @answers = @_;
				if (@answers) {
					# Cache the first A record result
					$cache_ref->{$host} = { ip => $answers[0][4] };
				}
				# Decrement the pending counter; signal when all done
				$cv->send if --$pending <= 0;
			},
		);
	}

	# Block until all DNS queries complete (subject to AnyEvent's own timeouts)
	$cv->recv;
}

# _extract_http_urls( $body ) -> list of url strings
#
# Purpose:
#   Extract all HTTP and HTTPS URLs from a body string, using both
#   structural HTML parsing (if HTML::LinkExtor is available) and a
#   plain-text regex pass.  Deduplicates and strips trailing punctuation.
#
# Entry criteria:
#   $body -- combined plain+HTML body string.
#
# Exit status:
#   Returns a list of URL strings (possibly empty), deduplicated.

sub _extract_http_urls :Private {
	my ($self, $body) = @_;
	my @urls;

	# Structural HTML link extraction (handles quoted attributes correctly)
	if ($HAS_HTML_LINKEXTOR) {
		my $p = HTML::LinkExtor->new(sub {
			my ($tag, %attrs) = @_;
			for my $attr (qw(href src action)) {
				my $val = $attrs{$attr} // '';
				if ($val =~ m{^https?://}i) {
					push @urls, $val;
				} elsif ($val =~ m{^//[\w.-]}) {
					# Protocol-relative -- assume https
					push @urls, 'https:' . $val;
				}
			}
		});
		$p->parse($body);
	}

	# Plain-text regex pass for bare URLs not in HTML attributes
	while ($body =~ m{(https?://[^\s<>"'\)\]]+)}gi) {
		push @urls, $1;
	}

	# Protocol-relative URLs not caught above
	while ($body =~ m{(?:^|[\s"'=])(//[\w.-][^\s<>"'\)\]]*)}gim) {
		push @urls, 'https:' . $1;
	}

	# Deduplicate and strip trailing punctuation
	my %seen;
	my @all = grep { !$seen{$_}++ } @urls;
	s/[.,;:!?\)>\]]+$// for @all;
	return @all;
}

# -----------------------------------------------------------------------
# Private: domain extraction and full analysis
# -----------------------------------------------------------------------

# _extract_and_analyse_domains() -> arrayref of domain hashrefs
#
# Purpose:
#   Collect all non-infrastructure contact domains from headers and body,
#   run the full domain intelligence pipeline on each, and return an arrayref
#   suitable for storage in $self->{_mailto_domains}.
#
# Entry criteria:
#   _split_message() must have been called.
#
# Exit status:
#   Always returns an arrayref; never undef.
#
# Side effects:
#   Network I/O per domain via _analyse_domain().
#   Results stored in $self->{_domain_info} and CHI cache.

sub _extract_and_analyse_domains :Private {
	my $self = $_[0];
	my (%seen, @domains_with_source);

	# Build a set of recipient domains to exclude (victims, not senders)
	my %recipient_domains;
	for my $hname (qw(to cc)) {
		my $val = $self->_header_value($hname) // next;
		for my $dom ($self->_domains_from_text($val)) {
			my $reg = _registrable($dom) // $dom;
			$recipient_domains{$dom}++;
			$recipient_domains{$reg}++;
		}
	}

	# Also exclude domains from Received: "for" envelope recipients
	for my $hop (@{ $self->{_rcvd_tracking} }) {
		next unless $hop->{for} && $hop->{for} =~ /\@([\w.-]+)/;
		my $dom = lc $1;
		my $reg = _registrable($dom) // $dom;
		$recipient_domains{$dom}++;
		$recipient_domains{$reg}++;
	}

	# Inner closure: record a domain if it passes all filters
	my $record = sub {
		my ($dom, $source) = @_;
		$dom = lc $dom;
		$dom =~ s/\.$//;
		next if $self->{trusted_domains}->{$dom};
		return if $TRUSTED_DOMAINS{$dom};
		return if $recipient_domains{$dom};
		return if $recipient_domains{ _registrable($dom) // $dom };
		# Discard non-routable hostnames (single-label, pseudo-TLDs, etc.)
		return unless $dom =~ /\.[a-zA-Z]{2,}$/;
		return if $dom =~ /\.(?:local|internal|lan|localdomain|arpa)$/i;
		return if $seen{$dom}++;
		push @domains_with_source, { domain => $dom, source => $source };
	};

	# Collect from standard sender/reply headers
	my %header_sources = (
		'from'        => 'From: header',
		'reply-to'    => 'Reply-To: header',
		'return-path' => 'Return-Path: header',
		'sender'      => 'Sender: header',
	);
	for my $hname (sort keys %header_sources) {
		my $val = $self->_header_value($hname) // next;
		$record->($_, $header_sources{$hname})
			for $self->_domains_from_text($val);
	}

	# Message-ID domain often reveals the real bulk-sending platform
	my $mid = $self->_header_value('message-id');
	if ($mid && $mid =~ /\@([\w.-]+)/) {
		my $mid_dom = lc $1;
		my $mid_reg = _registrable($mid_dom) // $mid_dom;
		$record->($mid_dom, 'Message-ID: header')
			unless $TRUSTED_DOMAINS{$mid_dom} || $TRUSTED_DOMAINS{$mid_reg} || $self->{trusted_domains}->{$mid_dom} || $self->{trusted_domains}->{$mid_reg};
	}

	# DKIM signing domain(s) -- the organisation that vouches for the message
	my $auth = $self->_parse_auth_results_cached();
	for my $dkim_d (@{ $auth->{dkim_domains} // [] }) {
		$record->($dkim_d, 'DKIM-Signature: d= (signing domain)');
	}

	# List-Unsubscribe identifies the ESP or bulk sender
	my $unsub = $self->_header_value('list-unsubscribe');
	if ($unsub) {
		while ($unsub =~ m{https?://([^/:?\s>]+)}gi) {
			$record->(lc $1, 'List-Unsubscribe: header');
		}
		while ($unsub =~ m{mailto:[^@\s>]+\@([\w.-]+)}gi) {
			$record->(lc $1, 'List-Unsubscribe: header');
		}
	}

	# Body email addresses (mailto: and bare user@domain forms)
	my $combined = $self->{_body_plain} . "\n" . $self->{_body_html};
	$record->($_, 'email address / mailto in body')
		for $self->_domains_from_text($combined);

	# Run the full intelligence pipeline on each collected domain
	my @results;
	for my $entry (@domains_with_source) {
		my $info = $self->_analyse_domain($entry->{domain});
		push @results, { %$entry, %$info };
	}
	return \@results;
}

# _domains_from_text( $text ) -> list of domain strings
#
# Purpose:
#   Extract unique domain names from mailto: links and bare user@domain
#   addresses in a block of text.
#
# Entry criteria:
#   $text -- a defined scalar of decoded body or header text.
#
# Exit status:
#   Returns a list of lower-cased domain strings (possibly empty).

sub _domains_from_text :Private {
	my ($self, $text) = @_;
	my (%seen, @out);

	# mailto: links (including HTML-entity-encoded @ signs from QP)
	while ($text =~ /mailto:(?:[^@\s<>"]+)@([\w.-]+)/gi) {
		my $dom = lc $1; $dom =~ s/\.$//;
		push @out, $dom unless $seen{$dom}++;
	}

	# Bare user@domain patterns
	while ($text =~ /\b[\w.+%-]+@([\w.-]+\.[a-zA-Z]{2,})\b/g) {
		my $dom = lc $1; $dom =~ s/\.$//;
		push @out, $dom unless $seen{$dom}++;
	}
	return @out;
}

# _analyse_domain( $domain ) -> hashref
#
# Purpose:
#   Run the complete intelligence pipeline for a single domain: A record
#   (web hosting), MX record (mail hosting), NS record (DNS hosting),
#   and WHOIS (registrar, creation/expiry dates, abuse contact).
#   Each IP is enriched via RDAP/WHOIS.  Results are cached per domain
#   in $self->{_domain_info} and in the CHI cross-message cache.
#
# Entry criteria:
#   $domain -- lower-cased, no trailing dot, not in TRUSTED_DOMAINS.
#   $self->{timeout} used for all network operations.
#
# Exit status:
#   Always returns a hashref reference; never undef; may be empty ({}).
#   Possible keys: web_ip, web_org, web_abuse, mx_host, mx_ip, mx_org,
#   mx_abuse, ns_host, ns_ip, ns_org, ns_abuse, registrar,
#   registrar_abuse, registered, expires, recently_registered, whois_raw.
#
# Side effects:
#   Network I/O; writes result to $self->{_domain_info}{$domain} and CHI.
#
# Notes:
#   MX/NS lookups require Net::DNS; absent without it.
#   recently_registered is set to 1 (not 0) when the threshold is met.
#   whois_raw is truncated to WHOIS_RAW_MAX bytes.

sub _analyse_domain :Private {
	my ($self, $domain) = @_;

	# Return the per-message cached result if already analysed
	return $self->{_domain_info}{$domain}
		if $self->{_domain_info}{$domain};

	# Check the cross-message CHI cache before hitting the network
	if ($_cache) {
		my $cached = $_cache->get("dom:$domain");
		if ($cached) {
			$self->{_domain_info}{$domain} = $cached;
			return $cached;
		}
	}

	$self->_debug("Analysing domain: $domain");
	my %info;

	# --- A record -> web hosting IP ---
	my $web_ip = $self->_resolve_host($domain);
	if ($web_ip) {
		$info{web_ip} = $web_ip;
		my $w = $self->_whois_ip($web_ip);
		$info{web_org}   = $w->{org}   if $w->{org};
		$info{web_abuse} = $w->{abuse} if $w->{abuse};
	}

	# MX and NS lookups require Net::DNS
	if ($HAS_NET_DNS) {
		my $res = Net::DNS::Resolver->new(
			tcp_timeout => $self->{timeout},
			udp_timeout => $self->{timeout},
		);

		# --- MX record -> mail hosting ---
		my $mxq = $res->search($domain, 'MX');
		if ($mxq) {
			my ($best) = sort { $a->preference <=> $b->preference }
			             grep { $_->type eq 'MX' } $mxq->answer;
			if ($best) {
				(my $mx_host = lc $best->exchange) =~ s/\.$//;
				$info{mx_host} = $mx_host;
				my $mx_ip = $self->_resolve_host($mx_host);
				if ($mx_ip) {
					$info{mx_ip} = $mx_ip;
					my $mw = $self->_whois_ip($mx_ip);
					$info{mx_org}   = $mw->{org}   if $mw->{org};
					$info{mx_abuse} = $mw->{abuse} if $mw->{abuse};
				}
			}
		}

		# --- NS record -> DNS hosting ---
		my $nsq = $res->search($domain, 'NS');
		if ($nsq) {
			my ($first) = grep { $_->type eq 'NS' } $nsq->answer;
			if ($first) {
				(my $ns_host = lc $first->nsdname) =~ s/\.$//;
				$info{ns_host} = $ns_host;
				my $ns_ip = $self->_resolve_host($ns_host);
				if ($ns_ip) {
					$info{ns_ip} = $ns_ip;
					my $nw = $self->_whois_ip($ns_ip);
					$info{ns_org}   = $nw->{org}   if $nw->{org};
					$info{ns_abuse} = $nw->{abuse} if $nw->{abuse};
				}
			}
		}
	}

	# --- Domain WHOIS -> registrar + dates ---
	my $domain_whois = $self->_domain_whois($domain);
	if ($domain_whois) {
		# Truncate raw WHOIS for storage but parse structured fields from full text
		$info{whois_raw} = substr($domain_whois, 0, $WHOIS_RAW_MAX);

		# Registrar name
		if ($domain_whois =~ /Registrar:\s*(.+)/i) {
			($info{registrar} = $1) =~ s/\s+$//;
		}

		# Registrar abuse contact email (try multiple field names)
		for my $pat (
			qr/Registrar Abuse Contact Email:\s*(\S+@\S+)/i,
			qr/Abuse Contact Email:\s*(\S+@\S+)/i,
			qr/abuse-contact:\s*(\S+@\S+)/i,
		) {
			if (!$info{registrar_abuse} && $domain_whois =~ $pat) {
				($info{registrar_abuse} = $1) =~ s/\s+$//;
			}
		}

		# Domain creation date (multiple registrar field name variations)
		for my $pat (
			qr/Creation Date:\s*(\S+)/i,
			qr/Created(?:\s+On)?:\s*(\S+)/i,
			qr/Registration Time:\s*(\S+)/i,
			qr/^registered:\s*(\S+)/im,
		) {
			if (!$info{registered} && $domain_whois =~ $pat) {
				($info{registered} = $1) =~ s/[TZ].*//;
			}
		}

		# Domain expiry date
		for my $pat (
			qr/Registry Expiry Date:\s*(\S+)/i,
			qr/Expir(?:y|ation)(?: Date)?:\s*(\S+)/i,
			qr/paid-till:\s*(\S+)/i,
		) {
			if (!$info{expires} && $domain_whois =~ $pat) {
				($info{expires} = $1) =~ s/[TZ].*//;
			}
		}

		# Flag recently-registered domains (< RECENT_REG_DAYS old)
		if ($info{registered}) {
			my $epoch = $self->_parse_date_to_epoch($info{registered});
			$info{recently_registered} = 1
				if $epoch && (time() - $epoch) < $RECENT_REG_DAYS * $SECS_PER_DAY;
		}
	}

	# Store in per-message and cross-message caches
	$self->{_domain_info}{$domain} = \%info;
	$_cache->set("dom:$domain", \%info) if $_cache;

	return \%info;
}

# -----------------------------------------------------------------------
# Private: DNS helpers
# -----------------------------------------------------------------------

# _resolve_host( $host ) -> ip_string | undef
#
# Purpose:
#   Resolve a hostname to an IPv4 (or IPv6) address.  Uses Net::DNS for
#   both A and AAAA queries when available; falls back to inet_aton for
#   pure IPv4 resolution.
#
# Entry criteria:
#   $host -- hostname string or already-numeric IP.
#
# Exit status:
#   Returns the first resolved IP string, or undef on failure.
#
# Notes:
#   When the input is already a dotted-quad IPv4 it is returned immediately.
#   AAAA records are tried if the A query fails and Net::DNS is available.

sub _resolve_host :Protected {
	my ($self, $host) = @_;
	return $host if $host =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;

	# Check the CHI cache before hitting DNS
	if ($_cache) {
		my $cached_ip = $_cache->get("resolve:$host");
		return $cached_ip if defined $cached_ip;
	}

	my $ip;

	if ($HAS_NET_DNS) {
		my $res = Net::DNS::Resolver->new(
			tcp_timeout => $self->{timeout},
			udp_timeout => $self->{timeout},
		);

		# Try A record first, then AAAA for IPv6
		for my $type (qw(A AAAA)) {
			my $query = $res->search($host, $type);
			if ($query) {
				for my $rr ($query->answer) {
					if ($rr->type eq 'A') {
						$ip = $rr->address;
						last;
					} elsif ($rr->type eq 'AAAA') {
						$ip = $rr->address;
						last;
					}
				}
			}
			last if defined $ip;
		}
	} else {
		# Fallback: gethostbyname (IPv4 only)
		my $packed = eval { inet_aton($host) };
		$ip = $packed ? inet_ntoa($packed) : undef;
	}

	# Cache the result (including undef as '' to avoid repeated failed lookups)
	if ($_cache) {
		$_cache->set("resolve:$host", $ip // '');
	}

	return $ip;
}

# _reverse_dns( $ip ) -> hostname | undef
#
# Purpose:
#   Perform a PTR (reverse DNS) lookup for an IP address.  Supports both
#   IPv4 and IPv6 via Net::DNS when available; falls back to gethostbyaddr.
#
# Entry criteria:
#   $ip -- a defined IPv4 or IPv6 address string.
#
# Exit status:
#   Returns the PTR hostname string, or undef if no record exists.

sub _reverse_dns :Protected {
	my ($self, $ip) = @_;
	return unless $ip;

	if ($HAS_NET_DNS) {
		my $res   = Net::DNS::Resolver->new(tcp_timeout => $self->{timeout});
		my $query = $res->search($ip, 'PTR');
		if ($query) {
			for my $rr ($query->answer) {
				return $rr->ptrdname if $rr->type eq 'PTR';
			}
		}
		return;
	}

	# Fallback for IPv4 only
	return scalar gethostbyaddr(inet_aton($ip), AF_INET);
}

# -----------------------------------------------------------------------
# Private: WHOIS / RDAP
# -----------------------------------------------------------------------

# _whois_ip( $ip ) -> hashref
#
# Purpose:
#   Enrich an IP address with organisation name, abuse contact, and country
#   code.  Tries RDAP first (if LWP is available), then falls back to raw
#   WHOIS via IANA referral.  Results are cached in CHI if available.
#
# Entry criteria:
#   $ip -- a defined IPv4 or IPv6 address string.
#
# Exit status:
#   Returns { org, abuse, country } hashref; keys absent when unknown.

sub _whois_ip :Protected {
	my ($self, $ip) = @_;

	# Check CHI cache before going to the network
	if ($_cache) {
		my $cached = $_cache->get("whois_ip:$ip");
		return $cached if $cached;
	}

	my $result = $HAS_LWP ? $self->_rdap_lookup($ip) : {};

	# Fall back to raw WHOIS if RDAP returned no organisation
	unless ($result->{org}) {
		my $raw = $self->_raw_whois($ip, 'whois.iana.org');
		if ($raw) {
			my ($ref) = $raw =~ /whois:\s*([\w.-]+)/i;
			my $detail = $ref ? $self->_raw_whois($ip, $ref) : $raw;
			$result = $self->_parse_whois_text($detail) if $detail;
		}
	}

	# Cache the enrichment result
	$_cache->set("whois_ip:$ip", $result) if $_cache && $result;

	return $result;
}

# _domain_whois( $domain ) -> raw_whois_string | undef
#
# Purpose:
#   Perform a two-step WHOIS lookup for a domain: first ask IANA for the
#   TLD's authoritative WHOIS server, then query that server.
#
# Entry criteria:
#   $domain -- a lower-cased domain name string.
#
# Exit status:
#   Returns the raw WHOIS response string, or undef on failure.

sub _domain_whois :Protected {
	my ($self, $domain) = @_;
	my $iana = $self->_raw_whois($domain, 'whois.iana.org') // return;
	my ($server) = $iana =~ /whois:\s*([\w.-]+)/i;
	return unless $server;
	return $self->_raw_whois($domain, $server);
}

# _parse_domain_whois_abuse( $domain ) -> hashref
#
# Purpose:
#   Lightweight domain WHOIS lookup to extract only registrar name and
#   abuse contact.  Used as a fallback in _extract_and_resolve_urls() when
#   a URL host cannot be resolved to an IP.
#
# Entry criteria:
#   $domain -- a registrable domain name string.
#
# Exit status:
#   Returns { org, abuse } hashref; empty hashref on failure.

sub _parse_domain_whois_abuse :Private {
	my ($self, $domain) = @_;
	my $raw = $self->_domain_whois($domain) // return {};
	my %info;
	if ($raw =~ /Registrar:\s*(.+)/i) {
		($info{org} = $1) =~ s/\s+$//;
	}
	# Try multiple field name patterns for the abuse email
	for my $pat (
		qr/Registrar Abuse Contact Email:\s*(\S+\@\S+)/i,
		qr/Abuse Contact Email:\s*(\S+\@\S+)/i,
		qr/abuse-contact:\s*(\S+\@\S+)/i,
	) {
		if (!$info{abuse} && $raw =~ $pat) {
			($info{abuse} = $1) =~ s/\s+$//;
		}
	}
	return \%info;
}

# _rdap_lookup( $ip ) -> hashref
#
# Purpose:
#   Query the ARIN RDAP API for IP block ownership information.  RDAP is
#   preferred over raw WHOIS because it returns structured JSON.
#
# Entry criteria:
#   $ip     -- a defined IPv4 or IPv6 address string.
#   LWP::UserAgent must be installed.
#
# Exit status:
#   Returns { org, abuse, country } hashref; empty hashref on failure.

sub _rdap_lookup :Protected {
	my ($self, $ip) = @_;
	return {} unless $HAS_LWP;

	my $ua = $self->{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(
			timeout => $self->{timeout},
			agent   => "Email-Abuse-Investigator/$VERSION",
		);

		if($HAS_CONN_CACHE) {
			my $conn_cache = LWP::ConnCache->new();
			$conn_cache->total_capacity(10);
			$ua->conn_cache($conn_cache);
		}

		$ua->env_proxy(1);
		$self->{ua} = $ua;
	}

	# Use the ARIN RDAP endpoint; it covers the ARIN region and redirects
	# for RIPE/APNIC/LACNIC/AfriNIC allocations.
	my $res = eval { $ua->get("https://rdap.arin.net/registry/ip/$ip") };
	return {} unless $res && $res->is_success();

	my $j = $res->decoded_content();
	my %info;

	# Extract organisation name from the JSON response
	if ($j =~ /"name"\s*:\s*"([^"]+)"/)   { $info{org}    = $1 }
	if ($j =~ /"handle"\s*:\s*"([^"]+)"/) { $info{handle} = $1 }

	# Extract abuse email from the vcardArray contact block
	if ($j =~ /"abuse".*?"email"\s*:\s*"([^"]+)"/s) {
		$info{abuse} = $1;
	} elsif ($j =~ /"email"\s*:\s*"([^@"]+@[^"]+)"/) {
		$info{abuse} = $1;
	}

	# Country code from the network's country field
	if ($j =~ /"country"\s*:\s*"([A-Z]{2})"/) { $info{country} = $1 }

	return \%info;
}

# _raw_whois( $query, $server ) -> string | undef
#
# Purpose:
#   Open a TCP connection to a WHOIS server on port 43, send the query,
#   and return the full response as a string.  Uses IO::Select for read
#   timeouts so that alarm() is never needed (alarm() is unreliable on
#   Windows and in threaded Perl).  Supports IPv6 WHOIS servers via
#   IO::Socket::IP when that module is available.
#
# Entry criteria:
#   $query   -- the domain name or IP to query (defined, non-empty).
#   $server  -- the WHOIS server hostname (default: 'whois.iana.org').
#   $self->{timeout} -- seconds used for connect and per-read waits.
#
# Exit status:
#   Returns the raw WHOIS response string, or undef on connection/write failure.
#
# Notes:
#   Uses IO::Socket::IP (dual-stack) when available, falling back to
#   IO::Socket::INET (IPv4 only) otherwise.  The IO::Select loop reads
#   until the server closes the connection or the per-read timeout expires.

sub _raw_whois :Protected {
	my ($self, $query, $server) = @_;
	$server //= 'whois.iana.org';
	$self->_debug("WHOIS $server -> $query");

	# Choose the socket class based on what is installed.
	# IO::Socket::IP supports both IPv4 and IPv6 WHOIS servers.
	my $sock_class = $HAS_IO_SOCKET_IP ? 'IO::Socket::IP' : 'IO::Socket::INET';

	# Attempt TCP connection to port 43 on the WHOIS server
	my $sock = eval {
		$sock_class->new(
			PeerAddr => $server,
			PeerPort => $WHOIS_PORT,
			Proto    => 'tcp',
			Timeout  => $self->{timeout},
		);
	};
	return unless $sock;

	# Send the WHOIS query in wire format (CRLF-terminated per RFC 3912)
	$sock->print("$query\r\n") or do { $sock->close(); return };

	# Use IO::Select to implement per-read timeouts without alarm()
	my $sel      = IO::Select->new($sock);
	my $response = '';
	my $buf      = '';

	# Read until EOF (server closes) or timeout
	while ($sel->can_read($self->{timeout})) {
		# Wrap in eval to catch 'Connection reset by peer' thrown by Fatal/autodie
		my $n = eval { sysread($sock, $buf, $WHOIS_READ_CHUNK) };

		if ($@ || !defined $n || $n <= 0) {
			$self->_debug("WHOIS read failed: $@") if $@;
			last;
		}
		last if !defined($n) || $n <= 0;
		$response .= $buf;
	}

	$sock->close();
	return $response || undef;
}

# _parse_whois_text( $text ) -> hashref
#
# Purpose:
#   Parse a raw WHOIS IP block response to extract organisation name,
#   abuse contact email, and country code.
#
# Entry criteria:
#   $text -- a defined WHOIS response string.
#
# Exit status:
#   Returns { org, abuse, country } hashref; keys absent when not found.

sub _parse_whois_text :Private {
	my ($self, $text) = @_;
	return {} unless $text;
	my %info;

	# Try multiple field names for the organisation name
	for my $pat (
		qr/^OrgName:\s*(.+)/mi,    qr/^org-name:\s*(.+)/mi,
		qr/^owner:\s*(.+)/mi,      qr/^descr:\s*(.+)/mi,
	) {
		if (!$info{org} && $text =~ $pat) {
			($info{org} = $1) =~ s/\s+$//;
		}
	}

	# Try multiple field names for the abuse email
	for my $pat (
		qr/OrgAbuseEmail:\s*(\S+@\S+)/mi,
		qr/abuse-mailbox:\s*(\S+@\S+)/mi,
	) {
		if (!$info{abuse} && $text =~ $pat) {
			($info{abuse} = $1) =~ s/\s+$//;
		}
	}

	# Last-resort: any abuse@ address in the response
	if (!$info{abuse} && $text =~ /(abuse\@[\w.-]+)/i) { $info{abuse} = $1 }

	# Country code (case-insensitive match, normalised to uppercase)
	if ($text =~ /^country:\s*([A-Za-z]{2})\s*$/m) {
		$info{country} = uc $1;
	}
	return \%info;
}

# -----------------------------------------------------------------------
# Private: authentication results parsing
# -----------------------------------------------------------------------

# _parse_auth_results_cached() -> hashref
#
# Purpose:
#   Parse the Authentication-Results: header(s) from the message once,
#   cache the result, and return it.  Extracts SPF, DKIM, DMARC, ARC
#   results and the DKIM signing domain(s).
#
# Entry criteria:
#   $self->{_headers} populated by _split_message().
#
# Exit status:
#   Returns { spf, dkim, dmarc, arc, dkim_domain, dkim_domains } hashref.
#   Keys absent when the corresponding header or field is not present.

sub _parse_auth_results_cached :Private {
	my $self = $_[0];
	return $self->{_auth_results} if $self->{_auth_results};

	my %auth;

	# Concatenate all Authentication-Results: header values
	my $raw = join('; ',
		map  { $_->{value} }
		grep { $_->{name} eq 'authentication-results' }
		@{ $self->{_headers} }
	);

	# Extract individual authentication mechanism results
	if ($raw =~ /\bspf=(\S+)/i)   { $auth{spf}   = $1 }
	if ($raw =~ /\bdkim=(\S+)/i)  { $auth{dkim}  = $1 }
	if ($raw =~ /\bdmarc=(\S+)/i) { $auth{dmarc} = $1 }
	if ($raw =~ /\barc=(\S+)/i)   { $auth{arc}   = $1 }

	# Strip trailing punctuation captured by the greedy \S+
	for my $k (qw(spf dkim dmarc arc)) {
		$auth{$k} =~ s/[;,\s]+$// if defined $auth{$k};
	}

	# Extract DKIM signing domains from all DKIM-Signature: d= tags.
	# Prefer the first domain that matches the provider table (identifies ESP).
	my @dkim_domains;
	for my $h (grep { $_->{name} eq 'dkim-signature' } @{ $self->{_headers} }) {
		if ($h->{value} =~ /\bd=([^;,\s]+)/) {
			push @dkim_domains, lc $1;
		}
	}

	if (@dkim_domains) {
		# Check if any signing domain matches a known provider
		my $preferred;
		for my $d (@dkim_domains) {
			if ($self->_provider_abuse_for_host($d)) {
				$preferred = $d;
				last;
			}
		}
		$auth{dkim_domain}  = $preferred // $dkim_domains[0];
		$auth{dkim_domains} = \@dkim_domains;
	}

	$self->{_auth_results} = \%auth;
	return \%auth;
}

# -----------------------------------------------------------------------
# Private: provider-table lookups
# -----------------------------------------------------------------------

# _provider_abuse_for_host( $host ) -> hashref | undef
#
# Purpose:
#   Look up a hostname (and each of its parent domains, stripping one label
#   at a time from the left) in the %PROVIDER_ABUSE table.
#
# Entry criteria:
#   $host -- a defined hostname or domain string.
#
# Exit status:
#   Returns the %PROVIDER_ABUSE entry hashref on match, undef otherwise.

sub _provider_abuse_for_host :Private {
	my ($self, $host) = @_;
	$host = lc $host;
	# Strip successive subdomains until we find a match or exhaust labels
	while ($host =~ /\./) {
		return $self->{provider_abuse}->{$host} if $self->{provider_abuse}->{$host};
		return $PROVIDER_ABUSE{$host} if $PROVIDER_ABUSE{$host};
		$host =~ s/^[^.]+\.//;
	}
	return;
}

# _provider_abuse_for_ip( $ip, $rdns ) -> hashref | undef
#
# Purpose:
#   Look up an IP's reverse-DNS hostname in the %PROVIDER_ABUSE table to
#   identify well-known provider networks by rDNS pattern.
#
# Entry criteria:
#   $ip   -- IPv4 or IPv6 address string (used as fallback if $rdns absent).
#   $rdns -- optional rDNS hostname string.
#
# Exit status:
#   Returns the %PROVIDER_ABUSE entry on match, undef otherwise.

sub _provider_abuse_for_ip :Private {
	my ($self, $ip, $rdns) = @_;
	return $self->_provider_abuse_for_host($rdns) if $rdns;
	return;
}

# -----------------------------------------------------------------------
# Private: eTLD+1 normalisation
# -----------------------------------------------------------------------

# _registrable( $host ) -> string | undef
#
# Purpose:
#   Return the registrable eTLD+1 form of a hostname.  Uses
#   Domain::PublicSuffix when installed for accurate results; falls back
#   to a built-in heuristic for the common two-letter ccTLD+2 pattern.
#
# Entry criteria:
#   $host -- a hostname string (may include subdomains).
#
# Exit status:
#   Returns the registrable domain string, or undef for single-label
#   hostnames (e.g. 'localhost').
#
# Notes:
#   The heuristic handles co.uk, com.au, net.jp, org.nz etc. but not
#   uncommon second-level delegations like ltd.uk or plc.uk.

sub _registrable :Private {
	my $host = $_[0];
	return unless $host && $host =~ /\./;

	# Use Domain::PublicSuffix for accurate PSL-based normalisation
	if ($HAS_PUBLIC_SUFFIX) {
		my $psl = Domain::PublicSuffix->new();
		my $root = $psl->get_root_domain(lc $host);
		return $root if $root;
	}

	# Built-in heuristic fallback
	my @labels = split /\./, lc $host;
	return $host if @labels <= 2;

	# Detect common ccTLD second-level patterns (e.g. co.uk, com.au)
	if ($labels[-1] =~ /^[a-z]{2}$/ &&
	    $labels[-2] =~ /^(?:co|com|net|org|gov|edu|ac|me)$/) {
		return join('.', @labels[-3..-1]);
	}
	return join('.', @labels[-2..-1]);
}

# -----------------------------------------------------------------------
# Private: utilities
# -----------------------------------------------------------------------

# _enrich_ip( $ip, $confidence, $note ) -> origin hashref
#
# Purpose:
#   Perform rDNS and WHOIS/RDAP for a single IP and package the results
#   into the standard origin hashref returned by originating_ip().
#
# Entry criteria:
#   $ip         -- a defined, non-private IPv4 or IPv6 address string.
#   $confidence -- 'high', 'medium', or 'low'.
#   $note       -- human-readable explanation of why this IP was chosen.
#
# Exit status:
#   Returns { ip, rdns, org, abuse, country, confidence, note } hashref.

sub _enrich_ip :Private {
	my ($self, $ip, $confidence, $note) = @_;
	my $rdns  = $self->_reverse_dns($ip);
	my $whois = $self->_whois_ip($ip);
	return {
		ip         => $ip,
		rdns       => $rdns  // '(no reverse DNS)',
		org        => $whois->{org}     // '(unknown)',
		abuse      => $whois->{abuse}   // '(unknown)',
		country    => $whois->{country} // undef,
		confidence => $confidence,
		note       => $note,
	};
}

# _header_value( $name ) -> value_string | undef
#
# Purpose:
#   Return the value of the first header matching the given lower-cased
#   header name.
=head2 header_value

Returns the value of the first occurrence of a named header field, or
C<undef> if the header is absent.  The name comparison is case-insensitive.

=head3 API SPECIFICATION

  Input:  name => Str  (required) - header field name, e.g. 'Subject'
  Output: Str | undef

=head3 MESSAGES

  (none - returns undef on missing header, never throws)

=cut

sub header_value {
	my ($self, $name) = @_;
	return $self->_header_value($name);
}

#
# _header_value( $name ) -> string | undef
#
# Purpose:
#   Internal implementation for header_value().  Walks _headers list and
#   returns the value of the first matching header.
#
# Entry criteria:
#   $name -- a lower-cased header name string.
#   $self->{_headers} populated by _split_message().
#
# Exit status:
#   Returns the value string, or undef if the header is not present.

sub _header_value :Private {
	my ($self, $name) = @_;
	for my $h (@{ $self->{_headers} }) {
		return $h->{value} if $h->{name} eq lc($name);
	}
	return;
}

# _ip_in_cidr( $ip, $cidr ) -> bool
#
# Purpose:
#   Test whether an IPv4 address falls within a CIDR block or is an exact
#   match (when $cidr contains no '/' separator).
#
# Entry criteria:
#   $ip   -- a defined dotted-quad IPv4 address string.
#   $cidr -- a CIDR string like '10.0.0.0/8' or an exact IP.
#
# Exit status:
#   Returns 1 (true) if the IP is within the CIDR block, 0 otherwise.

sub _ip_in_cidr :Private {
	my ($self, $ip, $cidr) = @_;
	return $ip eq $cidr unless $cidr =~ m{/};
	my ($net_addr, $prefix) = split m{/}, $cidr;
	return 0 if !defined($prefix) || $prefix !~ /^\d+$/ || $prefix > 32;

	# Compute the network mask and compare masked network addresses
	my $mask  = ~0 << (32 - $prefix);
	my $net_n = unpack 'N', (inet_aton($net_addr) // return 0);
	my $ip_n  = unpack 'N', (inet_aton($ip)       // return 0);
	return ($ip_n & $mask) == ($net_n & $mask);
}

# _decode_mime_words( $str ) -> decoded_string
#
# Purpose:
#   Decode MIME encoded-words (=?charset?B/Q?...?=) in a header value
#   string for human-readable display in reports.
#
# Entry criteria:
#   $str -- a defined header value string; may be undef.
#
# Exit status:
#   Returns the decoded string, or '' if $str is undef.

sub _decode_mime_words :Private {
	my ($self, $str) = @_;
	return '' unless defined $str;
	# Replace each encoded-word with its decoded equivalent
	$str =~ s/=\?([^?]+)\?([BbQq])\?([^?]*)\?=/_decode_ew($1,$2,$3)/ge;
	return $str;
}

# _decode_ew( $charset, $enc, $text ) -> decoded_bytes
#
# Purpose:
#   Decode a single MIME encoded-word component (base64 or quoted-printable).
#
# Notes:
#   Non-UTF-8 charsets return raw bytes; good enough for display-name spoof
#   detection which only needs ASCII matching.

sub _decode_ew :Private {
	my ($charset, $enc, $text) = @_;
	my $raw;
	if (uc($enc) eq 'B') {
		$raw = decode_base64($text);
	} else {
		# Quoted-printable encoded-word uses underscore for space
		$text =~ s/_/ /g;
		$raw  = decode_qp($text);
	}
	return $raw;
}

# _parse_date_to_epoch( $str ) -> epoch_int | undef
#
# Purpose:
#   Parse common WHOIS date strings to a Unix epoch integer.
#   Handles YYYY-MM-DD, YYYY-MM-DDThh:mm:ssZ, and DD-Mon-YYYY formats.
#
# Entry criteria:
#   $str -- a defined date string; may be undef.
#
# Exit status:
#   Returns epoch integer on success, undef if the string cannot be parsed.

sub _parse_date_to_epoch :Private {
	my ($self, $str) = @_;
	return unless $str;

	# Clean the string of trailing whitespace/newlines
	$str =~ s/^\s+|\s+$//g;

	# Guard Regex: Validates the strict YYYY-MM-DDThh:mm:ssZ format
	if ($str =~ /^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(?:\.\d+)?Z$/) {
		# Parse the string
		# We use 'strptime' to create a Time::Piece object.
		# The 'Z' indicates UTC (Zulu time).
		my $epoch = eval {
			my $t = Time::Piece->strptime($1, '%Y-%m-%dT%H:%M:%S');

			# Return seconds since the epoch
			# Time::Piece handles the timezone offset internally when calling ->epoch

			# strptime returns a local time object. 
			# We must subtract the local timezone offset to get the true UTC epoch.
			return $t->epoch - $t->tzoffset->seconds;
		};
		return $epoch if defined $epoch;
	}
	my ($y, $m, $d);

	if    ($str =~ /^(\d{4})-(\d{2})-(\d{2})/)         { ($y,$m,$d)=($1,$2,$3) }
	elsif ($str =~ /^(\d{2})-([A-Za-z]{3})-(\d{4})/)   { ($d,$m,$y)=($1,$Readonly::Values::Months::months{lc$2}//0,$3) }
	elsif ($str =~ /^(\d{2})\/(\d{2})\/(\d{4})/)        { ($m,$d,$y)=($1,$2,$3) }

	return unless $y && $m && $d;

	if (eval { require Time::Local; 1 }) {
		return eval { Time::Local::timegm(0,0,0,$d,$m-1,$y-1900) };
	}
	# Approximate fallback without Time::Local
	return ($y-1970)*365.25*$SECS_PER_DAY + ($m-1)*30.5*$SECS_PER_DAY + ($d-1)*$SECS_PER_DAY;
}

# _parse_rfc2822_date( $str ) -> epoch_int | undef
#
# Purpose:
#   Parse an RFC 2822 Date: header value to a Unix epoch integer.
#   Timezone offsets are intentionally ignored; the function returns a
#   UTC-equivalent value.  For the 7-day suspicious_date window the
#   maximum error is ~14 hours, well within the tolerance.
#
# Entry criteria:
#   $str -- a defined Date: header value string.
#
# Exit status:
#   Returns epoch integer on success, undef if the string cannot be parsed.

sub _parse_rfc2822_date :Private {
	my $str = $_[0];
	return unless $str;

	# Match: DD Mon YYYY HH:MM:SS (timezone offset ignored)
	if ($str =~ /(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/) {
		my ($d, $m, $y, $H, $M, $S) =
			($1, $Readonly::Values::Months::months{ lc $2 } // 0, $3, $4, $5, $6);
		return unless $m;
		if (eval { require Time::Local; 1 }) {
			return eval { Time::Local::timegm($S, $M, $H, $d, $m - 1, $y - 1900) };
		}
	}
	return;
}

# _country_name( $cc ) -> country_name_string
#
# Purpose:
#   Return a human-readable country name for a two-letter ISO 3166-1
#   alpha-2 country code.  Only the small set of statistically high-volume
#   spam-originating countries is covered; other codes are returned as-is.
#
# Entry criteria:
#   $cc -- a two-letter uppercase country code string.
#
# Exit status:
#   Returns the country name string, or the code itself if not in the table.

sub _country_name :Private {
	my $cc = $_[0];
	my %names = (
		CN => 'China',       RU => 'Russia',    NG => 'Nigeria',
		VN => 'Vietnam',     IN => 'India',      PK => 'Pakistan',
		BD => 'Bangladesh',
	);
	return $names{$cc} // $cc;
}

# _debug( $msg )
#
# Purpose:
#   Write a diagnostic message to STDERR when verbose mode is enabled.
#
# Entry criteria:
#   $msg -- a defined message string.
#
# Notes:
#   Messages are prefixed with the class name for easy grepping.

sub _debug :Private {
	my ($self, $msg) = @_;

	if($self->{verbose}) {
		if (my $logger = $self->{logger}) { # Set via Object::Configure
			$logger->debug("[Email::Abuse::Investigator] $msg");
		} else {
			print STDERR "[Email::Abuse::Investigator] $msg\n";
		}
	}
}

1;

__END__

=head1 ALGORITHM: DOMAIN INTELLIGENCE PIPELINE

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

=head1 CACHING

Two levels of caching are used:

=over 4

=item Per-message cache (C<$self-E<gt>{_domain_info}>)

Stores domain analysis results for the lifetime of one C<parse_email()>
call.  Invalidated by each call to C<parse_email()>.

=item Cross-message cache (CHI Memory driver, if C<CHI> is installed)

Stores IP WHOIS, DNS resolution, and domain analysis results across all
messages processed by the same process.  TTL is one hour.  Prevents
redundant WHOIS queries for infrastructure that appears in multiple
messages in the same run (e.g. a sending ISP seen in 500 spam messages).

=back

=head1 IPV6 SUPPORT

IPv6 addresses are extracted from C<Received:> headers using bracketed
notation (C<[2001:db8::1]>).  They are tested against the private range
list (which covers ::1, fe80::/10, fc00::/7, fd00::/8, and the
documentation range 2001:db8::/32) and passed through C<_whois_ip()> and
C<_rdap_lookup()> in the same way as IPv4 addresses.

C<_resolve_host()> attempts both A and AAAA lookups when C<Net::DNS> is
installed.  C<_raw_whois()> uses C<IO::Socket::IP> for dual-stack WHOIS
connections when that module is installed.

=head1 SEE ALSO

=over 4

=item * L<Configure an Object at Runtime|Object::Configure>

The provider_abuse, trusted_domains and url_shorteners tables can all be overridden at runtime

=item * L<Test Dashboard|https://nigelhorne.github.io/Email-Abuse-Investigator/coverage/>

=item * L<ARIN RDAP|https://rdap.arin.net/>

=item * L<Net::DNS>, L<LWP::UserAgent>, L<HTML::LinkExtor>

=item * L<CHI>, L<AnyEvent::DNS>, L<IO::Socket::IP>, L<Domain::PublicSuffix>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Email-Abuse-Investigator>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-email-abuse-investigator at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Abuse-Investigator>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Email::Abuse::Investigator

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Email-Abuse-Investigator>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Abuse-Investigator>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Email-Abuse-Investigator>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Email-Abuse-Investigator>

=back

=head1 REQUIRED MODULES

The following modules are mandatory:

    Readonly::Values::Months
    Socket              (core since Perl 5)
    IO::Socket::INET    (core since Perl 5)
    MIME::QuotedPrint   (core since Perl 5.8)
    MIME::Base64        (core since Perl 5.8)

The following are optional but strongly recommended:

    Net::DNS            -- enables MX, NS, AAAA record lookups
    LWP::UserAgent      -- enables RDAP (faster and richer than raw WHOIS)
    HTML::LinkExtor     -- enables structural HTML link extraction
    CHI                 -- enables cross-message IP/domain result caching
    IO::Socket::IP      -- enables IPv6 WHOIS connections

=head1 LIMITATIONS

=over 4

=item No charset conversion

Body text is stored as raw bytes.  Non-ASCII content (UTF-8, Latin-1,
ISO-2022-JP, etc.) is not decoded to Perl's internal Unicode representation.
URL and domain extraction from non-ASCII bodies may miss or misparse content.
Use C<Email::MIME> if full charset support is needed.

=item Hand-rolled MIME parser

The built-in MIME parser handles common cases but is not a conforming
implementation of RFC 2045/2046.  It silently drops parts it cannot decode,
does not handle C<message/rfc822> attachments, and does not parse
C<Content-Disposition> filenames.  Replace with C<Email::MIME> or
C<MIME::Entity> for production use with untrusted input.

=item IPv4-only CIDR matching for trusted_relays

C<_ip_in_cidr()> and the C<trusted_relays> constructor argument only support
IPv4 CIDR notation.  IPv6 trusted relay entries are accepted but silently
never match.

=item WHOIS rate-limiting not handled

C<_raw_whois()> does not retry on rate-limit responses (typically a
"quota exceeded" reply).  Under high-volume processing the module will
silently return empty enrichment data for affected IPs and domains.

=item Not thread-safe

The class-level C<$_cache> variable and the optional-module C<$HAS_*> flags
are shared across all threads.  Create a separate object per thread and do
not share objects across threads.

=item DMARC policy not fetched

The module reads the C<Authentication-Results: dmarc=> result from the
message headers but does not perform live C<_dmarc.domain> TXT record
lookups.  A missing DMARC result in the headers is not independently flagged.

=item C<abuse_contacts()> routes duplicated in C<form_contacts()>

Both methods iterate the same six discovery routes independently.  Any new
discovery route must be added to both.  A future refactor should share a
single routing pass.

=item CHI cache is a class-level mutable global

The cross-message cache is shared across all instances in the process.
Tests that populate the cache will affect subsequent tests.  Pass the cache
in via C<new()> (not currently supported) to enable proper isolation.

=back

=encoding utf-8

=head1 FORMAL SPECIFICATION

=head2 new

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

=head2 parse_email

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

=head2 originating_ip

    -- Z notation
    originating_ip == [
      Xi Email::Abuse::Investigator;
      result! : IP_INFO | undefined
    ]
    pre:  self._raw /= ''
    post: result! = self._origin /\
          (result! /= undefined => result!.ip in EXTERNAL_IPS)

=head2 embedded_urls

    -- Z notation
    embedded_urls == [
      Xi Email::Abuse::Investigator;
      result! : seq URL_INFO
    ]
    pre:  self._raw /= ''
    post: result! = self._urls /\
          forall u : result! @ u.url =~ m{^https?://}i

=head2 mailto_domains

    -- Z notation
    mailto_domains == [
      Xi Email::Abuse::Investigator;
      result! : seq DOMAIN_INFO
    ]
    pre:  self._raw /= ''
    post: result! = self._mailto_domains /\
          forall d : result! @ d.domain =~ /\.[a-zA-Z]{2,}$/

=head2 all_domains

    -- Z notation
    all_domains == [
      Xi Email::Abuse::Investigator;
      result! : seq STRING
    ]
    post: result! = deduplicate(
                      map(_registrable, url_hosts union mailto_domains)
                    )

=head2 unresolved_contacts

    -- Z notation
    unresolved_contacts == [
      Xi Email::Abuse::Investigator;
      result! : seq UNRESOLVED_INFO
    ]
    post: forall u : result! @
            u.domain not_in covered_domains(abuse_contacts, form_contacts)

=head2 sending_software

    -- Z notation
    sending_software == [
      Xi Email::Abuse::Investigator;
      result! : seq SW_INFO
    ]
    post: result! = self._sending_sw

=head2 received_trail

    -- Z notation
    received_trail == [
      Xi Email::Abuse::Investigator;
      result! : seq HOP_INFO
    ]
    post: result! = self._rcvd_tracking

=head2 risk_assessment

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

=head2 abuse_report_text

    -- Z notation
    abuse_report_text == [
      Xi Email::Abuse::Investigator;
      result! : STRING
    ]
    post: result! /= '' /\ result! ends_with '\n'

=head2 abuse_contacts

    -- Z notation
    abuse_contacts == [
      Xi Email::Abuse::Investigator;
      result! : seq CONTACT_INFO
    ]
    post: forall c : result! @ c.address contains '@' /\
          forall c1, c2 : result! @ c1 /= c2 => c1.address /= c2.address

=head2 form_contacts

    -- Z notation
    form_contacts == [
      Xi Email::Abuse::Investigator;
      result! : seq FORM_CONTACT_INFO
    ]
    post: forall c : result! @ c.form =~ m{^https?://} /\
          forall c1, c2 : result! @ c1 /= c2 => c1.form /= c2.form

=head2 report

    -- Z notation
    report == [
      Xi Email::Abuse::Investigator;
      result! : STRING
    ]
    post: result! /= '' /\ result! ends_with '\n'

=head2 header_value

  header_value : Object × FieldName → Maybe FieldValue
  header_value(o, n) ≜ first { lc(h.name) = lc(n) } o._headers .value

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
