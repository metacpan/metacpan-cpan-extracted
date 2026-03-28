package Email::Abuse::Investigator;

use strict;
use warnings;

use IO::Socket::INET;
use MIME::QuotedPrint qw( decode_qp );
use MIME::Base64 qw( decode_base64 );
use Object::Configure;
use Params::Get;
use Params::Validate::Strict;
use Readonly::Values::Months;
use Socket qw( inet_aton inet_ntoa );

# Optional - gracefully degraded
my $HAS_NET_DNS;
BEGIN { $HAS_NET_DNS = eval { require Net::DNS; 1 } }

my $HAS_LWP;
BEGIN { $HAS_LWP = eval { require LWP::UserAgent; 1 } }

my $HAS_HTML_LINKEXTOR;
BEGIN { $HAS_HTML_LINKEXTOR = eval { require HTML::LinkExtor; 1 } }

# -----------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------

my @PRIVATE_RANGES = (
	qr/^0\./,                         # 0.0.0.0/8  this-network (RFC 1122)
	qr/^127\./,                       # 127.0.0.0/8 loopback
	qr/^10\./,                        # 10.0.0.0/8  RFC 1918
	qr/^192\.168\./,                 # 192.168.0.0/16 RFC 1918
	qr/^172\.(?:1[6-9]|2\d|3[01])\./, # 172.16.0.0/12  RFC 1918
	qr/^169\.254\./,                 # 169.254.0.0/16 link-local
	qr/^100\.(?:6[4-9]|[7-9]\d|1(?:[01]\d|2[0-7]))\./,  # 100.64.0.0/10 shared address space (RFC 6598)
	qr/^192\.0\.0\./,              # 192.0.0.0/24  IETF protocol (RFC 6890)
	qr/^192\.0\.2\./,              # 192.0.2.0/24  TEST-NET-1 (RFC 5737)
	qr/^198\.51\.100\./,           # 198.51.100.0/24 TEST-NET-2 (RFC 5737)
	qr/^203\.0\.113\./,            # 203.0.113.0/24 TEST-NET-3 (RFC 5737)
	qr/^255\./,                      # 255.0.0.0/8 broadcast
	qr/^::1$/,                        # IPv6 loopback
	qr/^fc/i,                         # IPv6 ULA fc00::/7
	qr/^fd/i,                         # IPv6 ULA fd00::/8
);

my @RECEIVED_IP_RE = (
	qr/\[\s*([\d.]+)\s*\]/,
	qr/\(\s*[\w.-]*\s*\[?\s*([\d.]+)\s*\]?\s*\)/,
	qr/from\s+[\w.-]+\s+([\d.]+)/,
	qr/([\d]{1,3}\.[\d]{1,3}\.[\d]{1,3}\.[\d]{1,3})/,
);

# Domains we never bother reporting on - they are the infrastructure,
# not the criminal.
my %TRUSTED_DOMAINS = map { $_ => 1 } qw(
	gmail.com googlemail.com yahoo.com outlook.com hotmail.com
	google.com microsoft.com apple.com amazon.com
);

# Known URL shortener / redirect domains — real destination is hidden
my %URL_SHORTENERS = map { $_ => 1 } qw(
    bit.ly      bitly.com   tinyurl.com  t.co        ow.ly
    goo.gl      is.gd       buff.ly      ift.tt       dlvr.it
    short.link  rebrand.ly  tiny.cc      cutt.ly      rb.gy
    shorturl.at bl.ink      smarturl.it  yourls.org   clicky.me
    snip.ly     adf.ly      bc.vc        lnkd.in      fb.me
    youtu.be
);

# Well-known providers: use their specific abuse address / report URL
# rather than whatever a generic WHOIS lookup might return.
my %PROVIDER_ABUSE = (
    # Google / Gmail
    'google.com'        => { email => 'abuse@google.com',      note => 'Also report Gmail accounts via https://support.google.com/mail/contact/abuse' },
    'gmail.com'         => { email => 'abuse@google.com',      note => 'Report Gmail spam via https://support.google.com/mail/contact/abuse' },
    'googlemail.com'    => { email => 'abuse@google.com',      note => 'Report via https://support.google.com/mail/contact/abuse' },
    '1e100.net'         => { email => 'abuse@google.com',      note => 'Google infrastructure' },
    # Blogger / Blogspot -- Google-hosted blogging platform frequently abused
    # for spam landing pages.  Subdomains (e.g. ruseriver.blogspot.com) are
    # handled by subdomain stripping to blogspot.com.
    'blogspot.com'      => { email => 'abuse@google.com',      note => 'Blogger/Blogspot -- report via https://support.google.com/blogger/answer/76315' },
    'blogger.com'       => { email => 'abuse@google.com',      note => 'Blogger platform abuse' },
    # Google Sites -- another Google hosting product used for phishing pages
    'sites.google.com'  => { email => 'abuse@google.com',      note => 'Google Sites hosted content' },
    # Microsoft / Outlook / Hotmail
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
    # GoDaddy
    'godaddy.com'       => { email => 'abuse@godaddy.com',     note => 'Registrar/host abuse' },
    # SendGrid / Twilio
    'sendgrid.net'      => { email => 'abuse@sendgrid.com',    note => 'ESP — include full headers' },
    'sendgrid.com'      => { email => 'abuse@sendgrid.com',    note => 'ESP — include full headers' },
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
    # ActiveCampaign
    # Main sending domain plus ac-tinker.com which is used for tracking links.
    # Note: ac-tinker.com cannot be reached via subdomain stripping from
    # activecampaign.com as they are separate registrable domains, so both
    # must be listed explicitly.
    'activecampaign.com'  => { email => 'abuse@activecampaign.com', note => 'ActiveCampaign ESP' },
    'ac-tinker.com'       => { email => 'abuse@activecampaign.com', note => 'ActiveCampaign tracking infrastructure' },
     # Salesforce Marketing Cloud (ExactTarget)
     # Sending infrastructure domains follow the pattern *.mc.salesforce.com,
     # *.exacttarget.com, and customer subdomains routed through their MTAs.
    
        # Salesforce Marketing Cloud (ExactTarget)
    # Sending infrastructure domains follow the pattern *.mc.salesforce.com,
    # *.exacttarget.com, and customer subdomains routed through their MTAs.
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
    # TPG / Internode (Australia)
    'tpgi.com.au'       => { email => 'abuse@tpg.com.au',      note => 'TPG Telecom Australia' },
    'tpg.com.au'        => { email => 'abuse@tpg.com.au',      note => 'TPG Telecom Australia' },
    'internode.on.net'  => { email => 'abuse@internode.on.net',note => 'Internode Australia' },
);

=head1 NAME

Email::Abuse::Investigator - Analyse spam email to identify originating hosts,
hosted URLs, and suspicious domains

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

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
and answers the questions abuse investigators ask:

=over 4

=item 1. Where did the message really come from?

Walks the C<Received:> chain, skips private/trusted IPs, and identifies the
first external hop.  Enriches with rDNS, WHOIS/RDAP org name and abuse
contact.

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

=head1 METHODS

=head2 new( %options )

Constructs and returns a new C<Email::Abuse::Investigator> analyser object.  The
object is stateless until C<parse_email()> is called; all analysis results
are stored on the object and retrieved via the public accessor methods
documented below.

A single object may be reused for multiple emails by calling C<parse_email()>
again: all cached state from the previous message is discarded automatically.

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

Maximum number of seconds to wait for any single network operation: DNS
lookups, WHOIS TCP connections, and RDAP HTTP requests each respect this
limit independently.  Set to 0 to disable timeouts (not recommended for
production use).  Values must be non-negative integers.

=item C<trusted_relays> (arrayref of strings, default [])

A list of IP addresses or CIDR blocks that are under your own
administrative control and should be excluded from the Received: chain
analysis.  Any hop whose IP matches an entry here is skipped when
determining C<originating_ip()>.

Each element may be:

=over 8

=item * An exact IPv4 address: C<'192.0.2.1'>

=item * A CIDR block: C<'192.0.2.0/24'>, C<'10.0.0.0/8'>

=back

Use this to exclude your own mail relays, load balancers, and internal
infrastructure so they are never mistaken for the spam origin.

Example: if your inbound gateway at 203.0.113.5 adds a Received: header
before passing the message to your mail server, pass
C<trusted_relays =E<gt> ['203.0.113.5']> and that hop will be ignored.

=item C<verbose> (boolean, default 0)

When true, diagnostic messages are written to STDERR as the object
processes each email.  Messages are prefixed with C<[Email::Abuse::Investigator]>
and describe each major analysis step (header parsing, DNS resolution,
WHOIS queries, etc.).  Intended for development and debugging; leave false
in production.

=back

=head3 Returns

A blessed C<Email::Abuse::Investigator> object.  The object is immediately usable;
no network I/O is performed during construction.

=head3 Side Effects

None.  The constructor performs no I/O.  All network activity is deferred
until the first call to a method that requires it (C<originating_ip()>,
C<embedded_urls()>, C<mailto_domains()>, or any method that calls them).

=head3 Notes

=over 4

=item *

The C<timeout> option uses C<//> (defined-or), so C<timeout =E<gt> 0> is
stored correctly as zero.  All other constructor options also use C<//>.

=item *

Unknown option keys are silently ignored.

=item *

The object is not thread-safe.  If you process multiple emails
concurrently, construct a separate C<Email::Abuse::Investigator> object per
thread or per-request.

=item *

The C<alarm()> mechanism used by the raw WHOIS client is not reliable on
Windows or inside threaded Perl interpreters.  All other functionality
works on those platforms; only WHOIS TCP connections may not respect the
timeout on affected platforms.

=back

=head3 API Specification

=head4 Input

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

=head4 Output

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

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params(undef, \@_) || {},
		schema => {
			timeout => {
				'type' => 'integer',
				'optional' => 1,
				'min' => 0
			}, trusted_relays => {
				'type' => 'arrayref',
				'optional' => 1,
			}, verbose => {
				'type' => 'boolean',
				'optional' => 1,
			}
		}
	});

	# Load the configuration from a config file, if provided
	$params = Object::Configure::configure($class, $params);

	return bless {
		timeout        => $params->{timeout}        // 10,
		trusted_relays => $params->{trusted_relays} // [],
		verbose        => $params->{verbose}        // 0,
		_raw           => '',
		_headers       => [],
		_body_plain    => '',
		_body_html     => '',
		_received      => [],
		_origin        => undef,
		_urls          => undef,    # lazy
		_mailto_domains=> undef,    # lazy
		_domain_info   => {},       # cache: domain -> hashref
		_sending_sw    => [],       # X-Mailer / X-PHP-Originating-Script etc.
		_rcvd_tracking => [],       # per-hop tracking IDs from Received: headers
	}, $class;
}

=head2 parse_email( $text )

Feeds a raw RFC 2822 email message to the analyser and prepares it for
subsequent interrogation.  This is the only method that must be called
before any other public method; all analysis is driven by the message
supplied here.

If the same object is used for a second message, calling C<parse_email()>
again completely replaces all state from the first message.  No trace of
the previous email survives.

=head3 Usage

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

=head3 Arguments

=over 4

=item C<$text> (scalar or scalar reference, required)

The complete raw source of the email message as it arrived at your MTA,
including all headers and the body, exactly as transferred over the wire.
Both LF-only and CRLF line endings are accepted and handled transparently.

A scalar reference is accepted as an alternative to a plain scalar.  The
referent is dereferenced internally; the original variable is not modified.

The following body encodings are decoded automatically:

=over 8

=item * C<quoted-printable> (Content-Transfer-Encoding: quoted-printable)

=item * C<base64> (Content-Transfer-Encoding: base64)

=item * C<7bit> / C<8bit> / C<binary> (passed through as-is)

=back

Multipart messages (C<multipart/alternative>, C<multipart/mixed>, etc.)
are split on their boundary and each text part decoded according to its
own Content-Transfer-Encoding.  Non-text parts (attachments, inline images)
are silently skipped.

=back

=head3 Returns

The object itself (C<$self>), allowing method chaining:

    my $origin = Email::Abuse::Investigator->new()->parse_email($raw)->originating_ip();

=head3 Side Effects

The following work is performed synchronously, with no network I/O:

=over 4

=item * Header parsing

All RFC 2822 headers are parsed into an internal list.  Folded (multi-line)
header values are unfolded per RFC 2822 section 2.2.3.  The C<Received:>
chain is extracted separately for origin analysis.  Header names are
normalised to lower-case.  When duplicate headers are present, all copies
are retained; accessor methods return the first occurrence.

=item * Body decoding

The message body is decoded according to its Content-Transfer-Encoding and
stored as plain text (C<_body_plain>) and/or HTML (C<_body_html>).
Multipart messages have each qualifying part appended in order.

=item * Sending software extraction

The headers C<X-Mailer>, C<User-Agent>, C<X-PHP-Originating-Script>,
C<X-Source>, C<X-Source-Args>, and C<X-Source-Host> are extracted if
present and stored for retrieval via C<sending_software()>.

=item * Received chain tracking data

Each C<Received:> header is scanned for an IP address, an envelope
recipient (C<for E<lt>addr@domain.comE<gt>>), and a server tracking ID
(C<id token>).  Results are stored for retrieval via C<received_trail()>,
ordered oldest hop first.

=item * Cache invalidation

All lazily-computed results from a previous call to C<parse_email()> on
the same object are discarded: C<originating_ip()>, C<embedded_urls()>,
C<mailto_domains()>, C<risk_assessment()>, and the authentication-results
cache are all reset to C<undef> so the next call to any of them analyses
the new message from scratch.

=back

All network I/O (DNS lookups, WHOIS/RDAP queries) is deferred; it occurs
only when a caller first invokes C<originating_ip()>, C<embedded_urls()>,
or C<mailto_domains()>.

=head3 Notes

=over 4

=item *

If C<$text> is an empty string, contains only whitespace, or contains no
header/body separator, the method returns C<$self> without populating any
internal state.  All public methods will return empty lists, C<undef>, or
safe zero-value results rather than dying.

=item *

The raw text is stored verbatim (in C<_raw>) and is reproduced in the
output of C<abuse_report_text()>.  For very large messages this doubles
the memory used.  If memory is a concern, supply a scalar reference so at
least the method argument does not copy the string on the call stack.

=item *

HTML bodies are stored separately from plain-text bodies.  URL and
email-address extraction runs across both.  A URL that appears only in the
HTML part and not in the plain-text part is still reported.

=item *

Decoding errors in base64 or quoted-printable payloads are silenced; the
partially-decoded or raw bytes are used in place of correct output.  This
prevents malformed spam from causing exceptions during analysis.

=back

=head3 API Specification

=head4 Input

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

=head4 Output

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

=cut

# TODO:  Allow a Mail::Message object to be given
sub parse_email {
    my ($self, $text) = @_;
    $text = $$text if ref $text;
    $self->{_raw}            = $text;
    $self->{_origin}         = undef;
    $self->{_urls}           = undef;
    $self->{_mailto_domains} = undef;
    $self->{_domain_info}    = {};
    $self->{_risk}           = undef;
    $self->{_auth_results}   = undef;
    $self->{_sending_sw}     = [];
    $self->{_rcvd_tracking}  = [];

    $self->_split_message($text);
    return $self;
}

=head2 originating_ip()

Identifies the IP address of the machine that originally injected the
message into the mail system, as opposed to any intermediate relay that
passed it along.  This is the address of the spammer's machine, their ISP's
outbound mail server, or a compromised host -- the primary target for an
ISP abuse report.

The method walks the C<Received:> chain from oldest to newest, skips every
hop whose IP is in a private, reserved, or trusted range, and returns the
first remaining (external) IP, enriched with reverse DNS, network ownership,
and abuse contact information gathered via rDNS, RDAP, and WHOIS.

If no usable IP can be found in the C<Received:> chain, the method falls back
to the C<X-Originating-IP> header injected by some webmail providers.

The result is computed once and cached; subsequent calls on the same object
return the same hashref without repeating any network I/O.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

  {
    ip         => '209.85.218.67',
    rdns       => 'mail-ej1-f67.google.com',
    org        => 'Google LLC',
    abuse      => 'network-abuse@google.com',
    confidence => 'high',
    note       => 'First external hop in Received: chain',
  }

On success, a hashref with the following keys (all always present):

=over 4

=item C<ip> (string)

The dotted-quad IPv4 address of the identified originating host.

=item C<rdns> (string)

The reverse DNS (PTR) hostname for C<ip>.  Set to the literal string
C<'(no reverse DNS)'> if no PTR record exists or the lookup fails.
The presence and format of rDNS is used by C<risk_assessment()> to detect
residential broadband senders.

=item C<org> (string)

The network organisation name that owns the IP block, sourced from RDAP
(preferred) or WHOIS (fallback).  Set to C<'(unknown)'> if neither source
returns an organisation name.

=item C<abuse> (string)

The abuse contact email address for the IP block owner, sourced from RDAP
or WHOIS.  Set to C<'(unknown)'> if no abuse address can be determined.
C<abuse_contacts()> uses this field when building the contact list; entries
with the value C<'(unknown)'> are suppressed.

=item C<confidence> (string)

One of three values reflecting how reliably the IP was identified:

=over 8

=item C<'high'>

Two or more distinct external hops were found in the C<Received:> chain
(after removing private and trusted IPs).  The bottom-most hop is reported.
A chain of two or more external hops is strong evidence the first-seen IP
is the true origin.

=item C<'medium'>

Exactly one external hop was found in the C<Received:> chain.  The IP is
likely correct but cannot be independently corroborated by a relay record.

=item C<'low'>

No usable IP was found in the C<Received:> chain; the IP was taken from the
C<X-Originating-IP> header instead.  This header is injected by webmail
interfaces and is not verifiable; a sender can forge it.

=back

=item C<note> (string)

A human-readable explanation of how the IP was selected.  Examples:

    'First external hop in Received: chain'
    'Taken from X-Originating-IP (webmail, unverified)'

=item C<country> (string or undef)

The two-letter ISO 3166-1 alpha-2 country code for the IP block, sourced
from RDAP or WHOIS.  C<undef> if no country code is available.
C<risk_assessment()> uses this field to raise the C<high_spam_country> flag
for a set of statistically high-volume spam-originating countries.

=back

Returns C<undef> if no suitable originating IP can be determined (no
C<Received:> headers, all IPs are private or trusted, no usable
C<X-Originating-IP> header, or C<parse_email()> has not been called).

=head3 Side Effects

The first call (or the first call after a C<parse_email()>) performs the
following network I/O, subject to the C<timeout> set at construction:

=over 4

=item * One PTR (rDNS) lookup for the identified IP address.

=item * One RDAP query to C<rdap.arin.net> (if C<LWP::UserAgent> is available).

=item * If RDAP returns no organisation: one WHOIS query to C<whois.iana.org>
to obtain the authoritative registry, followed by one WHOIS query to that
registry.

=back

All subsequent calls return the cached hashref.  The cache is invalidated by
C<parse_email()>.

=head3 Algorithm: Received: chain traversal

The C<Received:> headers are walked from bottom (oldest) to top (most
recent).  For each header, the first IPv4 address is extracted in priority
order:

=over 4

=item 1. A bracketed address: C<[1.2.3.4]>

=item 2. A parenthesised address: C<(hostname [1.2.3.4])>

=item 3. An address following C<from hostname>

=item 4. Any bare dotted-quad as a last resort

=back

An extracted IP is discarded if it:

=over 4

=item * Falls in any of the following excluded ranges: 0.0.0.0/8 (RFC 1122),
127.0.0.0/8 (loopback), 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
(RFC 1918), 169.254.0.0/16 (link-local), 100.64.0.0/10 (CGN, RFC 6598),
192.0.0.0/24, 192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24 (RFC 5737
documentation ranges), 255.0.0.0/8 (broadcast), or IPv6 loopback/ULA.

=item * Matches any entry in the C<trusted_relays> list passed to C<new()>.

=item * Contains an octet greater than 255 (i.e., is syntactically invalid).

=back

All non-discarded IPs are collected; the first (oldest) one is reported as
the origin.  The count of non-discarded IPs determines the confidence level.

=head3 Notes

=over 4

=item *

Only IPv4 addresses are extracted.  IPv6 addresses in C<Received:> headers
are ignored.  This is a known limitation; most spam still travels via IPv4
infrastructure.

=item *

The algorithm trusts the C<Received:> headers as written.  A sophisticated
sender who controls an intermediate relay can insert a forged C<Received:>
header with an arbitrary IP.  The C<confidence> field reflects this: C<high>
confidence requires two independent external hops but cannot guarantee that
neither hop forged its Received: line.

=item *

If all C<Received:> IPs are private or trusted, the C<X-Originating-IP>
header is used as a fallback.  This header is unverifiable and receives
C<confidence> C<'low'>.  Brackets and whitespace are stripped from its
value before use.

=item *

The C<country> key is C<undef>, not the empty string, when no country code
is available.  Test with C<defined $orig-E<gt>{country}>, not a boolean
check.

=item *

C<org> and C<abuse> default to the literal string C<'(unknown)'>, not
C<undef>.  This means they are always defined; use string equality to test
for the unknown case: C<$orig-E<gt>{abuse} eq '(unknown)'>.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments; invocant must be a Email::Abuse::Investigator object
    # on which parse_email() has previously been called.
    []

=head4 Output

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

=cut

sub originating_ip {
    my ($self) = @_;
    $self->{_origin} //= $self->_find_origin();
    return $self->{_origin};
}

=head2 embedded_urls()

Extracts every HTTP and HTTPS URL from the message body and enriches each
one with the hosting IP address, network organisation name, abuse contact,
and country code of the web server it points to.

URL extraction runs across both the plain-text and HTML parts of the
message.  When C<HTML::LinkExtor> is available, HTML C<href>, C<src>, and
C<action> attributes are parsed structurally; a plain-text regex pass then
catches any remaining bare URLs in both parts.

Each unique URL is returned as a separate hashref.  When multiple distinct
URLs share the same hostname, DNS resolution and WHOIS are performed only
once for that hostname; all URLs on that host share the cached result.

The result list is computed once and cached; subsequent calls on the same
object return the same data without repeating any network I/O.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list (not an arrayref) of hashrefs, one per unique URL found in the body,
in the order they were first encountered.  Returns an empty list if the body
contains no HTTP or HTTPS URLs, or if C<parse_email()> has not been called.

    {
        url   => 'https://spamsite.example/offer',
        host  => 'spamsite.example',
        ip    => '198.51.100.7',
        org   => 'Dodgy Hosting Ltd',
        abuse => 'abuse@dodgy.example',
    }

Each hashref contains the following keys (all always present):

=over 4

=item C<url> (string)

The complete URL as it appeared in the message body, with any trailing
punctuation characters (C<.>, C<,>, C<;>, C<:>, C<!>, C<?>, C<)>, C<E<gt>>,
C<]>) stripped.  The scheme is preserved in the original case (C<HTTP://>,
C<https://>, etc.).

=item C<host> (string)

The hostname portion of the URL, extracted from between the scheme and
the first C</>, C<?>, C<:>, C<#>, or whitespace character.  Port numbers
are not included.  Examples: C<'www.example.com'>, C<'bit.ly'>.

=item C<ip> (string)

The IPv4 address the hostname resolved to at analysis time.  Set to the
literal string C<'(unresolved)'> if DNS resolution failed or returned no
A record.  Note that short-lived spam infrastructure may resolve differently
at report time than at analysis time.

=item C<org> (string)

The network organisation that owns the IP block, from RDAP or WHOIS.
Set to C<'(unknown)'> if no organisation name is available or if the host
could not be resolved.

=item C<abuse> (string)

The abuse contact email address for the IP block owner, from RDAP or WHOIS.
Set to C<'(unknown)'> if no abuse address is available or if the host could
not be resolved.  C<abuse_contacts()> uses this field; entries with the
value C<'(unknown)'> are suppressed in the contact list.

=item C<country> (string or undef)

The two-letter ISO 3166-1 alpha-2 country code for the IP block, from RDAP
or WHOIS.  C<undef> if no country code is available or if the host could
not be resolved.

=back

=head3 Side Effects

The first call (or first call after C<parse_email()>) performs network I/O
for each unique hostname found, subject to the C<timeout> set at construction.
For each unique hostname:

=over 4

=item * One A record (DNS) lookup to resolve the hostname to an IP address.

=item * If resolution succeeds: one RDAP query to C<rdap.arin.net>
(if C<LWP::UserAgent> is available).

=item * If RDAP returns no organisation: one WHOIS query to C<whois.iana.org>
followed by one query to the authoritative registry for the IP block.

=back

DNS and WHOIS are performed at most once per unique hostname per
C<parse_email()> call, regardless of how many distinct URLs share that
hostname.  All subsequent calls return the cached list.  The cache is
invalidated by C<parse_email()>.

=head3 Algorithm: URL extraction

URLs are extracted from the concatenation of the decoded plain-text body
and the decoded HTML body, in that order.  The two extraction passes are:

=over 4

=item 1. Structural HTML parsing (if C<HTML::LinkExtor> is installed)

C<href>, C<src>, and C<action> attributes of all HTML tags are inspected.
Any value beginning with C<http://> or C<https://> (case-insensitive) is
collected.  This correctly handles URLs that contain characters which would
confuse a plain-text regex, such as embedded spaces in quoted attribute
values.

=item 2. Plain-text regex pass

A greedy regex C<https?://[^\s<>"'\)\]]+> is applied to the combined body
text.  This catches bare URLs in plain-text parts and any URLs not captured
by the structural pass.

=back

After both passes, the combined list is deduplicated (preserving first-seen
order) and trailing punctuation is stripped from each URL.  The host is
then extracted and used as a cache key for DNS and WHOIS lookups.

=head3 Notes

=over 4

=item *

Only C<http://> and C<https://> URLs are extracted.  C<ftp://>, C<mailto:>,
and other schemes are not included.  Bare domain names without a scheme are
also not included (those are handled by C<mailto_domains()>).

=item *

Duplicate URLs -- the same complete URL string appearing more than once --
are reported only once.  Two URLs that differ only in case (e.g.
C<HTTP://> vs C<https://>) are treated as distinct.

=item *

If a hostname appears in multiple distinct URLs, all URLs are returned
individually as separate hashrefs, but the C<ip>, C<org>, C<abuse>, and
C<country> fields are identical across all of them (copied from the single
cached lookup).  Callers grouping by host should use the C<host> field
as the key.

=item *

C<ip>, C<org>, and C<abuse> use sentinel strings rather than C<undef> for
the unknown case: C<'(unresolved)'> for C<ip> when DNS fails, C<'(unknown)'>
for C<org> and C<abuse> when WHOIS returns nothing.  Only C<country> is
C<undef> in the unknown case.  Test accordingly:
C<$u-E<gt>{ip} ne '(unresolved)'>, not C<defined $u-E<gt>{ip}>.

=item *

URL shorteners (C<bit.ly>, C<tinyurl.com>, and several dozen others) are
detected by C<risk_assessment()>, which raises a C<url_shortener> flag.
C<embedded_urls()> itself does not filter them out; they appear in the
returned list so their hosting information can still be reported.

=item *

The order of URLs in the returned list reflects first-seen order across
both the plain-text and HTML extraction passes.  Because the HTML parser
and the regex run over the same combined string, a URL that appears in
both an HTML attribute and as bare text will appear only once (at the
position it was first seen).

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub embedded_urls {
    my ($self) = @_;
    $self->{_urls} //= $self->_extract_and_resolve_urls();
    return @{ $self->{_urls} };
}


=head2 mailto_domains()

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

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list (not an arrayref) of hashrefs, one per unique non-infrastructure
domain, in the order each domain was first encountered across all sources.
Returns an empty list if no qualifying domains are found, or if
C<parse_email()> has not been called.

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
test with C<exists $d-E<gt>{key}> or C<defined $d-E<gt>{key}> as
appropriate.

=over 4

=item C<domain> (string, always present)

The domain name, lower-cased and with any trailing dot removed.  This is
the full domain as it appeared in the source header or body (e.g.
C<'sminvestmentsupplychain.com'>), not the registrable eTLD+1.

=item C<source> (string, always present)

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

=item C<web_ip> (string, optional)

The IPv4 address the domain's A record resolved to.  Absent if the domain
has no A record or resolution failed.

=item C<web_org> (string, optional)

The network organisation hosting the web server at C<web_ip>, from RDAP or
WHOIS.  Absent if C<web_ip> is absent or WHOIS returns no organisation.

=item C<web_abuse> (string, optional)

The abuse contact email for the web-hosting network, from RDAP or WHOIS.
Absent if C<web_ip> is absent or WHOIS returns no abuse address.

=item C<mx_host> (string, optional)

The hostname of the lowest-preference MX record for the domain.
Only populated when C<Net::DNS> is installed.  Absent if no MX record
exists or C<Net::DNS> is unavailable.

=item C<mx_ip> (string, optional)

The IPv4 address of the MX host.  Absent if C<mx_host> is absent or
the MX hostname could not be resolved.

=item C<mx_org> (string, optional)

The network organisation hosting the MX server, from RDAP or WHOIS.

=item C<mx_abuse> (string, optional)

The abuse contact email for the MX hosting network.

=item C<ns_host> (string, optional)

The hostname of the first NS (nameserver) record returned for the domain.
Only populated when C<Net::DNS> is installed.

=item C<ns_ip> (string, optional)

The IPv4 address of the NS host.

=item C<ns_org> (string, optional)

The network organisation operating the nameserver, from RDAP or WHOIS.

=item C<ns_abuse> (string, optional)

The abuse contact email for the nameserver network.

=item C<registrar> (string, optional)

The registrar name as it appears in the domain's WHOIS record (e.g.
C<'GoDaddy.com LLC'>).  Absent if WHOIS is unavailable or the registrar
field was not found.

=item C<registrar_abuse> (string, optional)

The registrar's abuse contact email, extracted from the WHOIS record
using the following patterns in priority order:
C<Registrar Abuse Contact Email:>, C<Abuse Contact Email:>,
C<abuse-contact:>.  Absent if none of these fields is present.

=item C<registered> (string, optional)

The domain's creation date as a string in C<YYYY-MM-DD> form (ISO 8601
date only, time and timezone stripped).  Parsed from WHOIS using the
following field names in priority order: C<Creation Date:>,
C<Created On:>, C<Registration Time:>, C<registered:>.
Absent if WHOIS is unavailable or no creation date field is found.

=item C<expires> (string, optional)

The domain's expiry date in C<YYYY-MM-DD> form.  Parsed from:
C<Registry Expiry Date:>, C<Expiry Date:>, C<Expiration Date:>,
C<paid-till:>.  Absent if not found.

=item C<recently_registered> (integer 1, optional)

Present and set to C<1> when the domain's C<registered> date is less
than 180 days before the time of analysis.  Absent (not merely C<0>) when
the domain is not recently registered or when no creation date is available.
Used by C<risk_assessment()> to raise the C<recently_registered_domain> flag.

=item C<whois_raw> (string, optional)

The first 2048 bytes of the raw WHOIS response for the domain.  Intended
for human inspection or logging.  Absent if WHOIS is unavailable or returns
no data.

=back

=head3 Side Effects

The first call (or first call after C<parse_email()>) performs network I/O
for each unique domain collected, subject to the C<timeout> set at
construction.  For each domain:

=over 4

=item * One A record (DNS) lookup for the domain itself (web hosting).

=item * If C<Net::DNS> is installed: one MX record lookup; if an MX record
is found, one further A lookup for the MX hostname.

=item * If C<Net::DNS> is installed: one NS record lookup; if an NS record
is found, one further A lookup for the NS hostname.

=item * For each resolved IP (web, MX, NS): one RDAP or WHOIS query to
identify the network owner.  The same IP is never queried twice.

=item * Two WHOIS queries for the domain itself: one to C<whois.iana.org>
to obtain the TLD's authoritative registry, followed by one to that registry.

=back

In the worst case (all records present, all IPs distinct, RDAP unavailable),
each domain incurs: 3 A lookups + 1 MX lookup + 1 NS lookup + 3 WHOIS IP
queries (6 TCP connections each) + 2 domain WHOIS queries (2 TCP connections)
= up to 17 network operations.  In practice, shared hosting and cached DNS
reduce this considerably.

All results are cached per domain within a single C<parse_email()> lifetime.
The cache is invalidated by C<parse_email()>.

=head3 Domain collection sources

Domains are collected from the following sources, in this order.  A domain
that appears in multiple sources is recorded only once, with the source
label of its first occurrence.

=over 4

=item 1. C<From:>, C<Reply-To:>, C<Return-Path:>, C<Sender:> headers

All email addresses in these headers are parsed and their domain portions
extracted.

=item 2. C<Message-ID:> header

The domain portion of the Message-ID is extracted.  This often reveals the
real bulk-sending platform even when C<From:> is forged.  Domains that are
members of the infrastructure exclusion list (C<gmail.com>, C<outlook.com>,
C<google.com>, C<microsoft.com>, C<apple.com>, C<amazon.com>,
C<yahoo.com>, C<googlemail.com>, C<hotmail.com>) are skipped here, as are
any domain whose registrable eTLD+1 is in that list (e.g. C<mail.gmail.com>
is excluded because C<gmail.com> is in the list).

=item 3. C<DKIM-Signature: d=> tag

The signing domain from the first C<DKIM-Signature:> header.  This is the
organisation that cryptographically vouches for the message, and is
actionable regardless of whether DKIM passes or fails.

=item 4. C<List-Unsubscribe:> header

Both C<https://> URLs and C<mailto:> addresses in this header are parsed.
The domains identify the ESP or bulk sender responsible for delivery, who
may be held accountable under CAN-SPAM and similar laws.

=item 5. Body (plain-text and HTML)

C<mailto:> links and bare C<user@domain> email addresses are extracted from
the combined decoded body.  C<mailto:> links are recognised even when the
C<@> sign is HTML-entity-encoded (C<=40> or C<=3D@>) from quoted-printable
transfer.

=back

In all cases, domain names are lower-cased, trailing dots are stripped, and
domains in the infrastructure exclusion list are silently discarded.

=head3 Notes

=over 4

=item *

Unlike C<embedded_urls()>, which reports the host of every URL, this method
reports the contact domain -- the domain a human would write to, not
necessarily the domain hosting the content.  A spam campaign might send
from C<firmluminary.com> (contact domain) while linking to CDN URLs at
C<cloudflare.com> (URL host).  Both are captured, by different methods.

=item *

The C<recently_registered> key is absent, not C<0>, when a domain is not
recently registered or when no creation date is available.  Test for it with
C<$d-E<gt>{recently_registered}> (boolean truthiness), not with C<eq '1'>.

=item *

All hosting sub-keys (C<web_ip>, C<mx_host>, C<ns_host>, etc.) are absent
rather than C<undef> when the corresponding lookup yields no result.  This
means C<keys %$d> will contain only the keys for which information was
actually found.  Do not assume any optional key is present.

=item *

MX and NS lookups require C<Net::DNS>.  If C<Net::DNS> is not installed,
only A record and WHOIS information is populated; C<mx_host>, C<mx_ip>,
C<mx_org>, C<mx_abuse>, C<ns_host>, C<ns_ip>, C<ns_org>, and C<ns_abuse>
will all be absent for every domain.

=item *

Date strings in C<registered> and C<expires> have the time and timezone
components stripped (everything from C<T> or C<Z> onward in ISO 8601 form).
They are stored as plain strings, not as epoch integers; use
C<_parse_date_to_epoch()> (private) if a numeric comparison is needed.

=item *

C<whois_raw> is truncated to the first 2048 bytes of the raw WHOIS
response.  The date and registrar fields are parsed from the full response
before truncation, so truncation does not affect the structured fields.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub mailto_domains {
	my $self = $_[0];

	$self->{_mailto_domains} //= $self->_extract_and_analyse_domains();
	return @{ $self->{_mailto_domains} };
}

=head2 all_domains()

Returns the union of every registrable domain seen anywhere in the message:
URL hosts from C<embedded_urls()> and contact domains from
C<mailto_domains()>, collapsed to their registrable eTLD+1 form and
deduplicated.

This is the high-level answer to "what domains does this message reference?"
It is suitable for bulk lookups, domain reputation checks, or feeds into
external threat-intelligence systems where you want a flat, deduplicated
list rather than the detailed per-domain hashrefs returned by the individual
methods.

Unlike C<mailto_domains()>, this method triggers no additional network I/O
beyond what C<embedded_urls()> and C<mailto_domains()> already perform; it
is a pure in-memory union and normalisation of their results.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.  Calling
C<all_domains()> before C<embedded_urls()> or C<mailto_domains()> is safe;
it will trigger both lazily.

=head3 Returns

A list (not an arrayref) of plain strings, each being a registrable
eTLD+1 domain name (see Algorithm below), lower-cased, with no duplicates,
in first-seen order.  Returns an empty list if the message contains no
URLs and no contact domains, or if C<parse_email()> has not been called.

The list contains plain scalars, not hashrefs.  For the full intelligence
detail associated with each domain, call C<embedded_urls()> and
C<mailto_domains()> directly.

=head3 Side Effects

Triggers C<embedded_urls()> and C<mailto_domains()> if they have not
already been called on the current message, which in turn performs network
I/O as documented in those methods.  No additional network I/O is performed
beyond what those two methods require.  Results are not independently cached;
the caching is handled by C<embedded_urls()> and C<mailto_domains()>.

=head3 Algorithm: eTLD+1 normalisation

Both input sources are normalised to their registrable domain
(eTLD+1) before deduplication, using the following heuristic:

=over 4

=item *

A hostname with no dot (e.g. C<localhost>) is discarded (returns C<undef>
from the internal function and is skipped).

=item *

A hostname with exactly two labels (e.g. C<example.com>, C<evil.ru>) is
returned as-is; it is already registrable.

=item *

A hostname with three or more labels is inspected at the TLD (last label)
and the second-level (penultimate label).  If the TLD is a two-letter
country code (C<uk>, C<au>, C<jp>, etc.) and the second-level label is one
of the common delegated second-levels C<co>, C<com>, C<net>, C<org>,
C<gov>, C<edu>, C<ac>, or C<me>, then three labels are kept (e.g.
C<mail.evil.co.uk> becomes C<evil.co.uk>).  Otherwise two labels are kept
(e.g. C<mail.evil.com> becomes C<evil.com>).

=back

This heuristic handles the most common cases correctly.  It is not a full
Public Suffix List implementation; uncommon second-level delegations (e.g.
C<.ltd.uk>, C<.plc.uk>, C<.asn.au>) are not recognised and will produce
a two-label result that includes the second-level label rather than three
labels.

The normalisation is applied to both sources:

=over 4

=item * URL hosts (from C<embedded_urls()>): the host extracted from each
URL is normalised.  For example, the URL
C<https://www.spamco.example/offer> contributes C<spamco.example>.

=item * Contact domains (from C<mailto_domains()>): the full domain
stored in each hashref is normalised.  For example, the From: address
C<E<lt>spammer@sub.spamco.exampleE<gt>> contributes C<spamco.example>.

=back

This means a URL at C<www.spamco.example> and a contact address at
C<sub.spamco.example> both collapse to C<spamco.example>, and that domain
appears only once in the result.

=head3 Notes

=over 4

=item *

Domains from C<mailto_domains()> are normalised before deduplication;
domains from C<embedded_urls()> are also normalised.  This differs from
C<mailto_domains()> itself, which stores the full subdomain (e.g.
C<sub.spamco.example>) in its C<domain> key.  The loss of subdomain
granularity is intentional: C<all_domains()> is designed for registrar-
and ISP-level lookups, where the registrable domain is the relevant unit.

=item *

The returned strings are lower-cased.  No trailing dot is ever present.

=item *

The order of elements is: URL-host domains first (in the order URLs were
first seen), followed by contact domains (in the order they were first
collected by C<mailto_domains()>), with any domain already seen from the
URL pass omitted from the contact-domain pass.

=item *

A domain that appears only as a subdomain in one source and only as a
registrable domain in another source will still be deduplicated correctly,
because both are normalised to the same registrable form before the
deduplication check.

=item *

Calling C<all_domains()> does not interfere with or invalidate the caches
of C<embedded_urls()> or C<mailto_domains()>; those methods can still be
called afterwards to retrieve their full detail.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub all_domains {
    my ($self) = @_;
    my %seen;
    my @out;
    for my $u ($self->embedded_urls()) {
        my $dom = _registrable($u->{host});
        push @out, $dom if $dom && !$seen{$dom}++;
    }
    for my $d ($self->mailto_domains()) {
        # mailto_domains() stores the full domain from the address;
        # normalise to registrable domain so sub.spamco.example and
        # a URL at www.spamco.example both collapse to spamco.example.
        my $dom = _registrable($d->{domain}) // $d->{domain};
        push @out, $dom if $dom && !$seen{$dom}++;
    }
    return @out;
}

=head2 sending_software()

Returns information extracted from headers that identify the software or
server-side infrastructure used to compose or inject the message.  These
headers are injected by email clients, bulk-mailing libraries, and shared
hosting control panels, and are often the most direct evidence of how the
spam was sent and from which server.

Headers examined: C<X-Mailer>, C<User-Agent>, C<X-PHP-Originating-Script>,
C<X-Source>, C<X-Source-Args>, C<X-Source-Host>.

The C<X-PHP-Originating-Script>, C<X-Source>, and C<X-Source-Host> headers
in particular are injected automatically by many shared hosting providers
(cPanel, Plesk, DirectAdmin) and reveal the exact PHP script path and
hostname responsible.  A hosting abuse team can use these values to
identify the compromised or malicious account immediately, without needing
to search logs.

The data is extracted synchronously during C<parse_email()> with no network
I/O.  This method simply returns the pre-built list.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list (not an arrayref) of hashrefs, one per recognised software-fingerprint
header that was present in the message, in alphabetical order of header name.
Returns an empty list if none of the watched headers are present, or if
C<parse_email()> has not been called.

    {
        header => 'X-PHP-Originating-Script',
        value  => '1000:newsletter.php',
        note   => 'PHP script on shared hosting - report to hosting abuse team',
    }

Each hashref contains exactly three keys, all always present:

=over 4

=item C<header> (string)

The header name, lower-cased.  One of the six values listed in the
Algorithm section below.

=item C<value> (string)

The header value exactly as it appeared in the message (not decoded or
transformed in any way).

=item C<note> (string)

A fixed, human-readable annotation describing what this header represents
and the recommended action.  The note string is determined by the header
name and is the same for all messages; it is not derived from the value.
See the Algorithm section for the note associated with each header.

=back

=head3 Side Effects

None.  All data is collected during C<parse_email()> and this method
only returns the pre-collected list.  No network I/O is performed.

=head3 Algorithm: headers examined

The following six headers are examined during C<parse_email()>.  They are
checked in alphabetical order; the result list preserves that order
(i.e. C<user-agent> appears before C<x-mailer> which appears before
C<x-php-originating-script>, etc.).  At most one entry per header name is
produced even if the header appears more than once; the first occurrence is
used.

=over 4

=item C<user-agent>

Note: C<"Email client identifier">

Set by some email clients (Thunderbird, Evolution) as an alternative to
C<X-Mailer>.  Identifies the application that composed the message.

=item C<x-mailer>

Note: C<"Email client or bulk-mailer identifier">

The most widely used header for identifying the sending application.
Values range from standard clients (C<"Apple Mail">, C<"Microsoft Outlook">)
to bulk-mailing libraries (C<"PHPMailer 6.0">, C<"MailMate">).  Its presence
in spam often reveals the library used to generate the campaign.

=item C<x-php-originating-script>

Note: C<"PHP script on shared hosting -- report to hosting abuse team">

Injected by cPanel and similar shared-hosting control panels when a PHP
script sends mail via the local MTA.  The value typically takes the form
C<uid:script.php> (e.g. C<"1000:newsletter.php">), directly identifying
the Unix user account and the script responsible.  This is the single most
actionable header for shared-hosting abuse reports.

=item C<x-source>

Note: C<"Source file on shared hosting -- report to hosting abuse team">

Also injected by shared-hosting platforms, typically containing the full
filesystem path to the sending script (e.g.
C<"/home/user/public_html/contact.php">).  Complements
C<X-PHP-Originating-Script>.

=item C<x-source-args>

Note: C<"Command-line args injected by shared hosting provider">

The command-line arguments of the process that sent the mail, injected by
some hosting platforms.  May reveal interpreter invocations or script
parameters useful for forensic analysis.

=item C<x-source-host>

Note: C<"Sending hostname injected by shared hosting provider">

The hostname of the server that submitted the message, injected by the
hosting platform.  Useful when the IP in the C<Received:> chain is a shared
outbound relay rather than the originating server.

=back

=head3 Notes

=over 4

=item *

The result list is reset to empty by each call to C<parse_email()>.  If no
watched headers are present in the current message, the list is empty.

=item *

The alphabetical ordering of entries is a side effect of iterating over
the C<%sw_notes> hash in sorted key order.  It is stable across calls on
the same message.

=item *

Header names are stored lower-cased (e.g. C<'x-mailer'>, not C<'X-Mailer'>).
Header values are stored verbatim, preserving the original case and
whitespace.

=item *

The C<note> field is a fixed annotation string chosen by the module, not
text extracted from the message.  It is safe to display directly in reports
without sanitisation.

=item *

If both C<X-PHP-Originating-Script> and C<X-Source> are present (common on
cPanel systems), both are returned as separate list entries.  A caller
building a hosting abuse report should include all entries whose C<header>
begins with C<x->.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub sending_software {
	my $self = $_[0];

	return @{ $self->{_sending_sw} };
}


=head2 received_trail()

Returns the per-hop tracking data extracted from the C<Received:> header
chain: the IP address, envelope recipient address, and server-assigned
session ID for each relay that handled the message.

When filing an abuse report with a transit ISP or relay operator, these
are the identifiers their postmaster team needs to look up the specific
SMTP session in their mail logs.  Without the session ID or envelope
recipient, an ISP typically cannot locate a single message among billions
of log entries; with them, the lookup takes seconds.

The data is extracted synchronously during C<parse_email()> with no network
I/O.  This method simply returns the pre-built list.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list (not an arrayref) of hashrefs, one per C<Received:> hop from which
at least one of an IP address, an envelope recipient address, or a server
session ID could be extracted, in oldest-first order (i.e. the first element
is the outermost relay, the last element is the most recent hop before your
own server).  Returns an empty list if no C<Received:> headers are present
or none yielded any extractable data, or if C<parse_email()> has not been
called.

    (
      { received => '...raw header...', ip => '1.2.3.4',
        for => 'victim@example.com', id => 'ABC123' },
      ...
    )

Each hashref contains exactly four keys:

=over 4

=item C<received> (string, always present)

The complete raw value of the C<Received:> header for this hop, exactly as
it appeared in the message.  Suitable for including verbatim in an abuse
report so the receiving ISP can see the full context.

=item C<ip> (string or undef)

The IPv4 address extracted from this C<Received:> hop, or C<undef> if no
recognisable IPv4 address was found.  Uses the same four-pattern extraction
priority as C<originating_ip()>: bracketed C<[1.2.3.4]> first, then
parenthesised, then C<from hostname addr>, then any bare dotted-quad as a
last resort.  Private, reserved, and trusted IPs are B<not> filtered here;
all IPs including RFC 1918 addresses are returned as found.  (Filtering is
applied only by C<originating_ip()>.)

=item C<for> (string or undef)

The envelope recipient address extracted from the C<for> clause of the
C<Received:> header (e.g. C<for E<lt>victim@example.comE<gt>>), or C<undef>
if no such clause is present or it does not contain a fully-qualified email
address (one with both a local part and a domain containing at least one
dot).  Bare postmaster addresses, C<for multiple recipients>, and similar
non-address forms are not captured and result in C<undef>.

=item C<id> (string or undef)

The server's internal session or queue identifier from the C<id> clause
of the C<Received:> header (e.g. C<with ESMTP id ABC123XYZ>), or C<undef>
if no C<id> clause is present.  The value is a single whitespace-delimited
token of word characters and dots; longer or more structured ID formats may
be truncated at the first whitespace boundary.

=back

=head3 Side Effects

None.  All data is collected during C<parse_email()> and this method only
returns the pre-collected list.  No network I/O is performed.

=head3 Algorithm: extraction and ordering

During C<parse_email()>, the C<Received:> headers are walked in reverse
message order (i.e. oldest hop first, which is the same order as
C<originating_ip()>'s chain walk).  For each header:

=over 4

=item 1.

The IP address is extracted using the same four-pattern priority sequence
documented in C<originating_ip()>.

=item 2.

The envelope recipient is extracted with the pattern
C<\bfor\s+E<lt>?([^\s>]+@[\w.-]+\.[\w]+)E<gt>?> (case-insensitive).  The
domain portion of the address must contain at least one dot; single-label
names such as C<postmaster> are not matched.

=item 3.

The session ID is extracted with the pattern C<\bid\s+([\w.-]+)>
(case-insensitive), capturing the first word-character token following the
keyword C<id>.

=item 4.

If none of the three fields can be extracted (all are C<undef>), the hop is
silently discarded and does not appear in the result list.  This suppresses
internal or synthetic hops that carry no useful tracking information.

=back

The result list therefore contains only hops that carry at least one
actionable piece of tracking data.

=head3 Notes

=over 4

=item *

The result list is reset to empty by each call to C<parse_email()>.  It
reflects the C<Received:> headers of the current message only.

=item *

Oldest-first ordering means C<$trail[0]> is the first relay the message
passed through after leaving the sender, and C<$trail[-1]> is the last hop
before your own server.  This is the natural order for walking the chain
when composing a forwarded abuse report.

=item *

C<ip> may be C<undef> for a hop that nonetheless has a valid C<for> or
C<id> field -- for example, a C<Received:> header added by a local
delivery agent that does not record an IP.  Always test C<defined
$hop-E<gt>{ip}> before using it.

=item *

C<for> and C<id> are C<undef>, not the empty string, when absent.  C<ip>
is also C<undef>, not C<'(unknown)'> as in some other methods.  All four
fields must be tested with C<defined>, not boolean truthiness, to
distinguish between absent and empty.

=item *

C<report()> applies an additional filter when displaying this data: it only
shows hops where C<id> or C<for> is defined, suppressing hops where only
an IP was found.  C<received_trail()> itself returns all hops with any
extractable data, including IP-only hops, giving callers the full picture.

=item *

The C<received> field is the unfolded header value as stored after RFC 2822
line-folding is removed during C<parse_email()>.  Continuation whitespace
is replaced with a single space; the value will not contain embedded
newlines.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub received_trail {
	my $self = $_[0];

	return @{ $self->{_rcvd_tracking} };
}

=head2 risk_assessment()

Evaluates the message against a set of heuristic checks and returns an
overall risk level, a weighted numeric score, and a list of every specific
red flag that contributed to the score.

The assessment covers five categories: originating IP characteristics, email
authentication results, C<Date:> header validity, identity and header
consistency, and URL and domain properties.  Each finding is assigned a
severity, a machine-readable flag name, and a human-readable detail string.

The result is computed once and cached; subsequent calls on the same object
return the same hashref without repeating any analysis.  Calling
C<risk_assessment()> also implicitly triggers C<originating_ip()>,
C<embedded_urls()>, and C<mailto_domains()> if they have not already been
called, performing all associated network I/O.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

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

=over 4

=item C<level> (string)

The overall risk classification, determined by the weighted score:

    Score >= 9  =>  'HIGH'
    Score >= 5  =>  'MEDIUM'
    Score >= 2  =>  'LOW'
    Score <  2  =>  'INFO'

C<'INFO'> means either no flags were raised or only zero-weight (INFO
severity) flags were raised.  It does not mean the message is definitely
legitimate; it means no significant heuristic evidence of spam was found.

=item C<score> (integer)

The sum of the weights of all flags raised.  Weights by severity:

    HIGH   => 3
    MEDIUM => 2
    LOW    => 1
    INFO   => 0

The score is a non-negative integer.  Multiple flags of the same severity
each contribute their full weight independently; there is no cap on the
score.

=item C<flags> (arrayref of hashrefs)

A reference to a list of flag hashrefs, one per red flag raised, in the
order they were detected.  Each hashref contains exactly three keys:

=over 8

=item C<severity> (string)

One of C<'HIGH'>, C<'MEDIUM'>, C<'LOW'>, or C<'INFO'>.

=item C<flag> (string)

A lower-cased, underscore-separated machine-readable identifier.  See the
Algorithm section for the full list of possible flag names.

=item C<detail> (string)

A human-readable sentence describing the specific finding, including the
values from the message that triggered the flag (domain name, IP address,
header value, etc.).  Suitable for inclusion in an abuse report or log.

=back

The arrayref is empty (C<[]>) when no flags are raised.

=back

=head3 Side Effects

The first call triggers C<originating_ip()>, C<embedded_urls()>, and
C<mailto_domains()> if they have not already run on the current message.
Each of those methods may perform network I/O as documented in their own
entries.  Specifically:

=over 4

=item * C<originating_ip()> performs a PTR lookup and RDAP/WHOIS for the
sending IP.

=item * C<embedded_urls()> performs an A lookup and RDAP/WHOIS for each
unique URL hostname.

=item * C<mailto_domains()> performs A, MX, NS, and WHOIS queries for
each unique contact domain.

=back

All results are cached.  Subsequent calls to C<risk_assessment()> on the
same object return the cached hashref immediately.  The cache is invalidated
by C<parse_email()>.

=head3 Algorithm: flags and scoring

The following flags may be raised.  They are evaluated in five groups, in
the order shown.  The same flag name is never raised more than once per
message.

B<Group 1 -- Originating IP> (requires C<originating_ip()> to return a
result):

=over 4

=item C<residential_sending_ip> (HIGH, weight 3)

The rDNS of the sending IP matches patterns associated with residential
broadband or dynamically-assigned addresses: an embedded dotted-quad, or
any of the substrings C<dsl>, C<adsl>, C<cable>, C<broad>, C<dial>,
C<dynamic>, C<dhcp>, C<ppp>, C<residential>, C<cust>, C<home>, C<pool>,
C<client>, C<user>, C<staticN>, or C<hostN>.

=item C<no_reverse_dns> (HIGH, weight 3)

The sending IP has no PTR record, or the PTR lookup returned the sentinel
C<'(no reverse DNS)'>.  Legitimate mail servers invariably have rDNS.

=item C<low_confidence_origin> (MEDIUM, weight 2)

The originating IP was taken from an unverified header (C<X-Originating-IP>)
rather than from the C<Received:> chain.  Confidence level is C<'low'>.

=item C<high_spam_country> (INFO, weight 0)

The sending IP's country code is one of: C<CN> (China), C<RU> (Russia),
C<NG> (Nigeria), C<VN> (Vietnam), C<IN> (India), C<PK> (Pakistan),
C<BD> (Bangladesh).  Informational only; does not contribute to the score.

=back

B<Group 2 -- Email authentication> (from C<Authentication-Results:> header):

=over 4

=item C<spf_fail> (HIGH, weight 3)

SPF result is C<fail>, C<permerror>, C<temperror>, C<none>, or any value
other than C<pass> or C<softfail>.  The sending IP is not authorised by
the domain's SPF record.

=item C<spf_softfail> (MEDIUM, weight 2)

SPF result is C<softfail> (C<~all>).  The sending IP is not explicitly
authorised but the domain policy does not hard-fail it.

=item C<dkim_fail> (HIGH, weight 3)

DKIM result is present and is any value other than C<pass>.

=item C<dmarc_fail> (HIGH, weight 3)

DMARC result is present and is any value other than C<pass>.

=item C<dkim_domain_mismatch> (INFO or MEDIUM, weight 0 or 2)

The DKIM signing domain (C<d=> tag) differs from the registrable domain
of the C<From:> address.  Raised at INFO (weight 0) when DKIM passes --
this is normal for bulk senders using ESPs such as SendGrid or Mailchimp.
Raised at MEDIUM (weight 2) when DKIM fails or is absent -- a differing
domain combined with a failed signature is more suspicious.

=back

B<Group 3 -- Date: header>:

=over 4

=item C<missing_date> (MEDIUM, weight 2)

No C<Date:> header is present, or it contains only whitespace.  Violates
RFC 5322; common in programmatically-generated spam.

=item C<suspicious_date> (LOW, weight 1)

The C<Date:> header is present but more than 7 days in the past or more
than 7 days in the future relative to the time of analysis.  Timezone
offsets are ignored during comparison (maximum error: approximately 14
hours, well within the 7-day window).

=back

B<Group 4 -- Header identity and consistency>:

=over 4

=item C<display_name_domain_spoof> (HIGH, weight 3)

The C<From:> display name contains a domain name (matched against the
suffixes C<.com>, C<.net>, C<.org>, C<.io>, C<.co>, C<.uk>, C<.au>,
C<.gov>, C<.edu>) that differs at the registrable level from the actual
C<From:> address domain.  Example: C<"PayPal paypal.com" E<lt>phish@evil.exampleE<gt>>.

=item C<free_webmail_sender> (MEDIUM, weight 2)

The C<From:> address belongs to a free webmail provider: Gmail, Yahoo,
Hotmail, Outlook, Live, AOL, ProtonMail, Yandex, or mail.ru.

=item C<reply_to_differs_from_from> (MEDIUM, weight 2)

A C<Reply-To:> header is present and its email address differs from the
C<From:> address (case-insensitive comparison).  Replies will be harvested
by a different address than the apparent sender.

=item C<undisclosed_recipients> (MEDIUM, weight 2)

The C<To:> header is absent, empty, contains the string C<undisclosed>, or
matches the group-syntax sentinel C<:;>.

=item C<encoded_subject> (LOW, weight 1)

The C<Subject:> header contains a MIME encoded-word sequence
(C<=?charset?encoding?text?=>).  Often used to evade keyword filters.

=back

B<Group 5 -- URLs and domains> (from C<embedded_urls()> and
C<mailto_domains()>):

=over 4

=item C<url_shortener> (MEDIUM, weight 2)

At least one URL hostname is in the built-in URL shortener list (over 25
services including C<bit.ly>, C<tinyurl.com>, C<t.co>, C<ow.ly>, etc.).
Raised at most once per unique shortener hostname per message.

=item C<http_not_https> (LOW, weight 1)

At least one URL uses the plain C<http://> scheme rather than C<https://>.
Raised at most once per unique hostname.

=item C<recently_registered_domain> (HIGH, weight 3)

At least one contact domain was registered less than 180 days before the
time of analysis.

=item C<domain_expires_soon> (HIGH, weight 3)

At least one contact domain expires within the next 30 days.  Suggests a
throwaway domain.

=item C<domain_expired> (HIGH, weight 3)

At least one contact domain has already passed its expiry date.

=item C<lookalike_domain> (HIGH, weight 3)

At least one contact domain contains the name of a well-known brand
(C<paypal>, C<apple>, C<google>, C<amazon>, C<microsoft>, C<netflix>,
C<ebay>, C<instagram>, C<facebook>, C<twitter>, C<linkedin>,
C<bankofamerica>, C<wellsfargo>, C<chase>, C<barclays>, C<hsbc>,
C<lloyds>, C<santander>) but is not the brand's own canonical domain
(e.g. C<paypal.com>, C<paypal.co.uk>).

=back

=head3 Notes

=over 4

=item *

The C<flags> arrayref is a reference to the module's internal list.
Callers must not modify it.  To iterate safely, use C<@{ $risk-E<gt>{flags} }>.

=item *

Flags are not deduplicated across categories.  If C<spf_fail> and
C<dkim_fail> both apply, both appear in the list and both contribute to
the score.

=item *

C<high_spam_country> and C<dkim_domain_mismatch> (when DKIM passes)
contribute zero to the score.  Their presence does not change the level
classification, but they appear in the C<flags> list so callers can
include them in reports.

=item *

The level thresholds are fixed constants: HIGH >= 9, MEDIUM >= 5, LOW >= 2,
INFO < 2.  They are not configurable.

=item *

C<risk_assessment()> does not directly raise flags for domains found only
in URLs (C<embedded_urls()> hosts); domain checks in Group 5 apply only
to domains from C<mailto_domains()>.  URL hostname checks (shorteners,
HTTP) use the C<embedded_urls()> list.

=item *

If C<parse_email()> has not been called, or was called with an empty or
malformed message, C<risk_assessment()> returns a valid hashref with
C<level =E<gt> 'INFO'>, C<score =E<gt> 0>, and C<flags =E<gt> []>.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub risk_assessment {
	my ($self) = @_;
	return $self->{_risk} if $self->{_risk};

	my @flags;
	my $score = 0;

    my $flag = sub {
        my ($severity, $name, $detail) = @_;
        my %weight = (HIGH => 3, MEDIUM => 2, LOW => 1, INFO => 0);
        $score += $weight{$severity} // 1;
        push @flags, { severity => $severity, flag => $name, detail => $detail };
    };

    # ---- Originating IP checks ----
    my $orig = $self->originating_ip();
    if ($orig) {
        # Residential / broadband rDNS patterns
        if ($orig->{rdns} && $orig->{rdns} =~ /
            \d+[-_.]\d+[-_.]\d+[-_.]\d+   # dotted-quad in rDNS
            | (?:dsl|adsl|cable|broad|dial|dynamic|dhcp|ppp|
                 residential|cust|home|pool|client|user|
                 static\d|host\d)
        /xi) {
            $flag->('HIGH', 'residential_sending_ip',
                "Sending IP $orig->{ip} rDNS '$orig->{rdns}' looks like a broadband/residential line, not a legitimate mail server");
        }

        # No rDNS at all
        if (!$orig->{rdns} || $orig->{rdns} eq '(no reverse DNS)') {
            $flag->('HIGH', 'no_reverse_dns',
                "Sending IP $orig->{ip} has no reverse DNS — legitimate mail servers always have rDNS");
        }

        # Low confidence origin
        if ($orig->{confidence} eq 'low') {
            $flag->('MEDIUM', 'low_confidence_origin',
                "Originating IP taken from unverified header ($orig->{note})");
        }

        # Country flag for high-spam-originating countries (informational)
        if ($orig->{country} && $orig->{country} =~ /^(?:CN|RU|NG|VN|IN|PK|BD)$/) {
            $flag->('INFO', 'high_spam_country',
                "Sending IP is in " . _country_name($orig->{country}) .
                " ($orig->{country}) — statistically high spam volume country");
        }
    }

    # ---- Authentication checks ----
    my $auth = $self->_parse_auth_results_cached();
    if (defined $auth->{spf}) {
        if ($auth->{spf} =~ /^fail/i) {
            $flag->('HIGH', 'spf_fail',
                "SPF result: $auth->{spf} — sending IP not authorised by domain's SPF record");
        } elsif ($auth->{spf} =~ /^softfail/i) {
            $flag->('MEDIUM', 'spf_softfail',
                "SPF result: softfail (~all) — sending IP not explicitly authorised");
        } elsif ($auth->{spf} !~ /^pass/i) {
            $flag->('HIGH', 'spf_fail',
                "SPF result: $auth->{spf} — sending IP not authorised by domain's SPF record");
        }
    }
    if (defined $auth->{dkim} && $auth->{dkim} !~ /^pass/i) {
        $flag->('HIGH', 'dkim_fail',
            "DKIM result: $auth->{dkim} — message signature invalid or absent");
    }
    if (defined $auth->{dmarc} && $auth->{dmarc} !~ /^pass/i) {
        $flag->('HIGH', 'dmarc_fail',
            "DMARC result: $auth->{dmarc}");
    }

    # DKIM signing domain vs From: domain
    if ($auth->{dkim_domain}) {
        my ($from_domain) = ($self->_header_value('from') // '') =~ /\@([\w.-]+)/;
        if ($from_domain) {
            my $reg_dkim = _registrable($auth->{dkim_domain}) // $auth->{dkim_domain};
            my $reg_from = _registrable(lc $from_domain)     // lc $from_domain;
            if ($reg_dkim ne $reg_from) {
                if ($auth->{dkim} && $auth->{dkim} =~ /^pass/i) {
                    # DKIM passes but signing domain differs — normal for bulk ESPs
                    # (SendGrid, Mailchimp etc. sign with their own domain)
                    $flag->('INFO', 'dkim_domain_mismatch',
                        "DKIM signed by '$auth->{dkim_domain}' but From: domain is '$from_domain'"
                        . " — message sent via third-party sender (normal for bulk/ESP mail)");
                } else {
                    # DKIM fails AND domains differ — more suspicious
                    $flag->('MEDIUM', 'dkim_domain_mismatch',
                        "DKIM signed by '$auth->{dkim_domain}' but From: domain is '$from_domain'"
                        . " and DKIM did not pass — possible impersonation");
                }
            }
        }
    }

    # ---- Date: header checks ----
    my $date_raw = $self->_header_value('date');
    if (!$date_raw || $date_raw !~ /\S/) {
        $flag->('MEDIUM', 'missing_date',
            'No Date: header — violates RFC 5322; common in spam');
    } else {
        # Check the timezone offset before anything else.
        # RFC 2822 allows numeric offsets; in practice no real timezone exceeds
        # +1400 (Line Islands) or -1200 (Baker Island).  Anything beyond those
        # bounds, or with a minutes field >= 60, is an unambiguous forgery.
        if ($date_raw =~ /([+-])(\d{2})(\d{2})\s*$/) {
            my ($sign, $hh, $mm) = ($1, $2, $3);
            # Convert hours and minutes to a total offset in minutes.
            my $offset_mins = $hh * 60 + $mm;
            # The minutes field must always be 00-59 regardless of sign.
            # Positive offsets: real-world maximum is +1400 = 840 minutes.
            # Negative offsets: real-world minimum is -1200 = 720 minutes.
            # The bounds are checked separately because a single symmetric
            # limit would wrongly accept -1300 (780 min, which is < 840).
            my $implausible = $mm >= 60
                || ($sign eq '+' && $offset_mins > 840)
                || ($sign eq '-' && $offset_mins > 720);
            if ($implausible) {
                $flag->('MEDIUM', 'implausible_timezone',
                    "Date: '$date_raw' contains an implausible timezone offset "
                    . "($sign$hh$mm) -- header is likely forged");
            }
        }

        # Check for dates wildly outside the current window (> 7 days off).
        # Note: timezone offsets are ignored; the window is wide enough that
        # this does not cause false positives for any real timezone.
        my $date_epoch = _parse_rfc2822_date($date_raw);
        if (defined $date_epoch) {
            my $delta = time() - $date_epoch;
            if ($delta > 7 * 86400) {
                $flag->('LOW', 'suspicious_date',
                    "Date: '$date_raw' is more than 7 days in the past — possible header forgery or very stale message");
            } elsif ($delta < -(7 * 86400)) {
                $flag->('LOW', 'suspicious_date',
                    "Date: '$date_raw' is more than 7 days in the future — possible header forgery");
            }
        }
    }

    # ---- Header identity checks ----
    # From: display name spoofing another domain
    my $from_raw = $self->_header_value('from') // '';
    my $from_decoded = $self->_decode_mime_words($from_raw);
    if ($from_decoded =~ /^"?([^"<]+?)"?\s*<([^>]+)>/) {
        my ($display, $addr) = ($1, $2);
        # Extract domains from display name
        while ($display =~ /\b([\w-]+\.(?:com|net|org|io|co|uk|au|gov|edu))\b/gi) {
            my $disp_domain = lc $1;
            my ($addr_domain) = $addr =~ /\@([\w.-]+)/;
            $addr_domain = lc($addr_domain // '');
            my $reg_disp = _registrable($disp_domain);
            my $reg_addr = _registrable($addr_domain);
            if ($reg_disp && $reg_addr && $reg_disp ne $reg_addr) {
                $flag->('HIGH', 'display_name_domain_spoof',
                    "From: display name mentions '$disp_domain' but actual address is <$addr> — classic impersonation technique");
            }
        }
    }

    # From: is a free webmail provider
    if ($from_raw =~ /\@(gmail|yahoo|hotmail|outlook|live|aol|protonmail|yandex)\./i
     || $from_raw =~ /\@mail\.ru(?:[\s>]|$)/i) {
        $flag->('MEDIUM', 'free_webmail_sender',
            "Message sent from free webmail address ($from_raw) — no corporate mail infrastructure");
    }

    # Reply-To differs from From:
    my $reply_to = $self->_header_value('reply-to');
    if ($reply_to) {
        my ($from_addr)  = $from_raw =~ /([\w.+%-]+\@[\w.-]+)/;
        my ($reply_addr) = $reply_to =~ /([\w.+%-]+\@[\w.-]+)/;
        if ($from_addr && $reply_addr &&
            lc($from_addr) ne lc($reply_addr)) {
            $flag->('MEDIUM', 'reply_to_differs_from_from',
                "Reply-To ($reply_addr) differs from From: ($from_addr) — replies will go to a different address");
        }
    }

    # To: is undisclosed-recipients or missing
    my $to = $self->_header_value('to') // '';
    if ($to =~ /undisclosed|:;/ || $to eq '') {
        $flag->('MEDIUM', 'undisclosed_recipients',
            "To: header is '$to' — message was bulk-sent with hidden recipient list");
    }

    # Subject encoded to hide content from filters
    my $subj_raw = $self->_header_value('subject') // '';
    if ($subj_raw =~ /=\?[^?]+\?[BQ]\?/i) {
        $flag->('LOW', 'encoded_subject',
            "Subject line is MIME-encoded: '$subj_raw' (decoded: '" .
            $self->_decode_mime_words($subj_raw) . "')");
    }

    # ---- URL checks ----
    my (%shortener_seen, %url_host_seen);
    for my $u ($self->embedded_urls()) {
        # URL shorteners
        my $bare = lc $u->{host};
        $bare =~ s/^www\.//;
        if ($URL_SHORTENERS{$bare} && !$shortener_seen{$bare}++) {
            $flag->('MEDIUM', 'url_shortener',
                "$u->{host} is a URL shortener - the real destination is hidden");
        }
        # HTTP not HTTPS
        if ($u->{url} =~ m{^http://}i && !$url_host_seen{ $u->{host} }++) {
            $flag->('LOW', 'http_not_https',
                "$u->{host} linked over plain HTTP — no encryption");
        }
    }

    # ---- Domain checks ----
    for my $d ($self->mailto_domains()) {
        if ($d->{recently_registered}) {
            $flag->('HIGH', 'recently_registered_domain',
                "$d->{domain} was registered $d->{registered} (less than 180 days ago)");
        }
        # Domain expiry checks — parse once, test twice
        if ($d->{expires}) {
            my $exp  = $self->_parse_date_to_epoch($d->{expires});
            my $now  = time();
            if ($exp) {
                my $remaining = $exp - $now;
                if ($remaining > 0 && $remaining < 30 * 86400) {
                    $flag->('HIGH', 'domain_expires_soon',
                        "$d->{domain} expires $d->{expires} — may be a throwaway domain");
                }
                elsif ($remaining <= 0) {
                    $flag->('HIGH', 'domain_expired',
                        "$d->{domain} expired $d->{expires} — domain has lapsed");
                }
            }
        }
        # Lookalike domain (contains well-known brand name but isn't it)
        for my $brand (qw(paypal apple google amazon microsoft netflix ebay
                          instagram facebook twitter linkedin bankofamerica
                          wellsfargo chase barclays hsbc lloyds santander)) {
            if ($d->{domain} =~ /\Q$brand\E/i &&
                $d->{domain} !~ /^\Q$brand\E\.(?:com|co\.uk|net|org)$/) {
                $flag->('HIGH', 'lookalike_domain',
                    "$d->{domain} contains brand name '$brand' but is not the real domain — possible phishing");
                last;
            }
        }
    }

    my $level = $score >= 9 ? 'HIGH'
              : $score >= 5 ? 'MEDIUM'
              : $score >= 2 ? 'LOW'
              :               'INFO';

    $self->{_risk} = { level => $level, score => $score, flags => \@flags };
    return $self->{_risk};
}

=head2 abuse_report_text()

Produces a compact, plain-text string intended to be sent as the body of
an abuse report email to an ISP or hosting provider.  It summarises the
risk level, lists every red flag with its detail, identifies the originating
IP and its network owner, lists the abuse contacts, and appends the complete
message headers so the recipient can trace the session in their own logs.

The message body is intentionally omitted to keep the report concise.
Headers are sufficient for an ISP to locate the relevant mail session; the
body adds bulk without aiding the investigation.

This method is the companion to C<abuse_contacts()>: call
C<abuse_contacts()> to obtain the addresses to send the report to, and
C<abuse_report_text()> to obtain the text to send.  Use C<report()> instead
when you want a comprehensive analyst-facing document rather than a
send-ready ISP report.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A plain scalar string containing the report text.  The string is
newline-terminated and uses Unix line endings (C<\n>) throughout.
The string is never empty; it always contains at least the boilerplate
introduction and the risk-level line, even if no red flags were found.

The report is structured as follows, in order:

=over 4

=item 1. Introduction

Two fixed lines:

    This is an automated abuse report generated by Email::Abuse::Investigator.
    Please investigate the following spam/phishing message.

=item 2. Risk level

    RISK LEVEL: HIGH (score: 11)

=item 3. Red flags (omitted if no flags were raised)

    RED FLAGS IDENTIFIED:
      [HIGH] firmluminary.com was registered 2025-09-01 (less than 180 days ago)
      [MEDIUM] rDNS 120-88-161-249.tpgi.com.au looks like a broadband line
      ...

Each flag is formatted as C<[SEVERITY] detail-string>, one per line,
indented two spaces.  The flag machine-name is not included; only the
human-readable detail string is shown, matching what a postmaster would
want to read.

=item 4. Originating IP (omitted if C<originating_ip()> returns C<undef>)

    ORIGINATING IP: 120.88.161.249 (120-88-161-249.tpgi.com.au)
    NETWORK OWNER:  TPG Telecom Limited

=item 5. Abuse contacts (omitted if C<abuse_contacts()> returns an empty list)

    ABUSE CONTACTS:
      abuse@tpg.com.au (Sending ISP)
      abuse@registrar.example (Domain registrar for firmluminary.com)

=item 6. Original message headers

    ------------------------------------------------------------------------
    ORIGINAL MESSAGE HEADERS:
    ------------------------------------------------------------------------
    received: from 120-88-161-249.tpgi.com.au ...
    from: Sender <spammer@firmluminary.com>
    ...

All parsed headers are emitted, one per line, in the order they appeared
in the original message.  Header names are lower-cased (as normalised
during C<parse_email()>).  Header values are verbatim.  The message
body is not included.

=back

=head3 Side Effects

Calls C<risk_assessment()>, C<originating_ip()>, and C<abuse_contacts()>
if they have not already run, which in turn may perform network I/O as
documented in those methods.  All results are cached; the text is not
itself cached, but re-computing it is cheap since all the underlying data
is already cached.

=head3 Notes

=over 4

=item *

Header names in the output are lower-cased (e.g. C<from:>, C<received:>),
because that is how they are stored internally after C<parse_email()>
normalises them.  Postmasters are accustomed to receiving headers in their
original mixed case; if canonical capitalisation is required, a simple
substitution (C<s/^([\w-]+)/\u\L$1/>) will restore it.

=item *

The message body is deliberately excluded.  This avoids transmitting
potentially malicious or offensive content to third parties, keeps the
report below common size limits for abuse mailboxes, and is consistent
with the RFC 2646 / ARF (Abuse Reporting Format) practice of including
only the headers in a first-contact report.  To include the body, callers
can append C<$self-E<gt>{_raw}> directly, though this is not recommended.

=item *

The separator lines are exactly 72 hyphens (C<-> x 72), matching the
separator width used by C<report()>.

=item *

The output is suitable for use as a plain-text email body.  It is not
ARF (RFC 5965) compliant; it does not include a C<message/feedback-report>
MIME part.  For ARF-compliant reporting, use the output of this method as
the human-readable first part and add the ARF metadata separately.

=item *

If C<parse_email()> has not been called, all sections that depend on
analysis will be empty (no flags, no originating IP, no contacts) and the
header section will be blank.  The method will not die.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

    # Return::Set compatible specification
    {
        type  => SCALAR,
        # Non-empty plain-text string, newline-terminated.
        # Always defined; never undef.
        # Line endings: Unix LF (\n) only.
        # Minimum content: introduction + risk-level line.
    }

=cut

sub abuse_report_text {
	my $self = $_[0];
	my @out;

	push @out, "This is an automated abuse report generated by Email::Abuse::Investigator.";
	push @out, "Please investigate the following spam/phishing message.";
	push @out, '';

	my $risk = $self->risk_assessment();
	push @out, "RISK LEVEL: $risk->{level} (score: $risk->{score})";
	push @out, '';

    if (@{ $risk->{flags} }) {
        push @out, "RED FLAGS IDENTIFIED:";
        for my $f (@{ $risk->{flags} }) {
            push @out, "  [$f->{severity}] $f->{detail}";
        }
        push @out, '';
    }

    my $orig = $self->originating_ip();
    if ($orig) {
        push @out, "ORIGINATING IP: $orig->{ip} ($orig->{rdns})";
        push @out, "NETWORK OWNER:  $orig->{org}";
        push @out, '';
    }

    my @contacts = $self->abuse_contacts();
    if (@contacts) {
        push @out, "ABUSE CONTACTS:";
        push @out, "  $_->{address} ($_->{role})" for @contacts;
        push @out, '';
    }

	push @out, '-' x 72;
	push @out, 'ORIGINAL MESSAGE HEADERS:';
	push @out, '-' x 72;

	# Emit only the headers (not the body) to keep report concise
	for my $h (@{ $self->{_headers} }) {
		push @out, "$h->{name}: $h->{value}";
	}
	push @out, '';

	return join("\n", @out);
}

=head2 abuse_contacts()

Collates the complete set of parties that should receive an abuse report
for this message: the ISP that owns the sending IP, the operators of every
URL host, the web, mail, and DNS hosts of every contact domain, each
domain's registrar, the webmail or ESP account provider identified from
key headers, the DKIM signing organisation, and the ESP identified via
the C<List-Unsubscribe:> header.

For each party the method produces the role description, the abuse email
address, a supporting note, and the source of the information.  Addresses
are deduplicated globally: if the same address is discovered through
multiple routes (e.g. Google as both the sending ISP and the owner of a
blogspot.com URL in the message body), it appears only once.  The C<role>
string for that entry is the combined description of all routes that found
it, joined by C<" and ">, and the C<roles> key holds the individual role
strings as an arrayref.

This method is designed to be used together with C<abuse_report_text()>:
iterate over the returned contacts to obtain the list of addresses, and
send the text from C<abuse_report_text()> to each one.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A list (not an arrayref) of hashrefs, one per unique abuse contact address,
in the order they were first discovered.  Returns an empty list if no
actionable abuse contacts can be determined, or if C<parse_email()> has
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

=over 4

=item C<role> (string)

A human-readable description of the party's relationship to the message.
When the same address was found via multiple discovery routes, the role
strings from each route are joined with C<" and "> (e.g.
C<"Sending ISP (provider table) and URL host (provider table)">).
See the Algorithm section for the full set of role string patterns.

=item C<roles> (arrayref of strings)

The individual role strings for each discovery route that found this
address, in discovery order.  Contains exactly one element when the
address was found via a single route; two or more elements when multiple
routes converged on the same address.  The C<role> key is always the
C<join(' and ', @{$c->{roles}})> of this arrayref.

=item C<address> (string)

The abuse contact email address, lower-cased.  Always contains an C<@>
sign.  Deduplicated globally: each distinct address appears at most once
across the entire list, regardless of how many discovery routes found it.

=item C<note> (string)

Supporting information about why this party was identified and what action
to request.  For provider-table entries this is the note from the built-in
table (which may include a URL to a web-based abuse form).  For WHOIS- and
RDAP-discovered entries this describes the IP block or domain involved.
Always defined; may be the empty string for entries where no note is
available.  When roles are merged, this reflects the note from the first
discovery route.

=item C<via> (string)

The discovery method for the first route that found this address.  One of:

=over 8

=item C<'provider-table'>

The address was found in the module's built-in table of well-known
providers (Google, Microsoft, Cloudflare, SendGrid, Mailchimp, etc.).
Provider-table addresses take priority over WHOIS for the same entity
because they are curated and point to the right team, whereas generic
WHOIS contacts sometimes route to NOCs rather than abuse desks.

=item C<'ip-whois'>

The address was obtained from an RDAP or WHOIS lookup on an IP block
(the sending IP, a URL host IP, or an MX/NS IP).

=item C<'domain-whois'>

The address was obtained from a WHOIS lookup on a domain name (registrar
abuse contact from the C<Registrar Abuse Contact Email:> or equivalent
field).

=back

=back

=head3 Side Effects

Triggers C<originating_ip()>, C<embedded_urls()>, and C<mailto_domains()>
if they have not already run on the current message, performing all
associated network I/O as documented in those methods.  Additionally
consults the built-in provider table and the cached authentication results;
neither requires network I/O.

The result is not independently cached.  Each call recomputes the contact
list from the cached results of the underlying methods.  Because those
results are cached, subsequent calls are fast (no network I/O), but they
do re-execute the collation and deduplication logic.

=head3 Algorithm: discovery routes

Contacts are discovered through six routes, applied in order.
Deduplication is global across all routes: if an address is found by
more than one route, a single entry is kept and the role strings from
every route that found it are accumulated into C<roles> and joined into
C<role>.  An entry is suppressed entirely if its address is empty, does
not contain an C<@> sign, or is the sentinel C<'(unknown)'>.

=over 4

=item Route 1 -- Sending ISP

The originating IP from C<originating_ip()> is looked up in the built-in
provider table (by rDNS hostname, stripping subdomains until a match is
found).  If found, a C<provider-table> entry is added with role
C<"Sending ISP (provider table)">.

The C<abuse> field from C<originating_ip()> (obtained from RDAP/WHOIS) is
then added as an C<ip-whois> entry with role C<"Sending ISP">, unless it
is C<'(unknown)'>.

=item Route 2 -- URL hosts

For each unique hostname in C<embedded_urls()>, the built-in provider
table is consulted (by hostname, stripping subdomains).  If found, a
C<provider-table> entry is added with role C<"URL host (provider table)">.

The C<abuse> field from the URL hashref is then added as an C<ip-whois>
entry with role C<"URL host">, unless it is C<'(unknown)'>.

Each unique hostname is processed at most once; multiple URLs on the same
host do not generate multiple contacts.

=item Route 3 -- Contact domain hosting and registration

For each domain from C<mailto_domains()>, up to four contacts may be
generated:

=over 8

=item *

B<Web host>: if C<web_abuse> is present, both a provider-table lookup
on the domain name and the WHOIS-derived C<web_abuse> address are tried.
Role: C<"Web host of $domain"> or C<"Web host of $domain (provider table)">.

=item *

B<Mail host (MX)>: if C<mx_abuse> is present.
Role: C<"Mail host (MX) for $domain">, via C<ip-whois>.

=item *

B<DNS host (NS)>: if C<ns_abuse> is present.
Role: C<"DNS host (NS) for $domain">, via C<ip-whois>.

=item *

B<Domain registrar>: if C<registrar_abuse> is present.
Role: C<"Domain registrar for $domain">, via C<domain-whois>.

=back

=item Route 4 -- Account provider

The C<From:>, C<Reply-To:>, C<Return-Path:>, and C<Sender:> header values
are inspected in that order.  The domain portion of each address is looked
up in the built-in provider table (stripping subdomains until a match).
If found, a C<provider-table> entry is added with role
C<"Account provider ($header: $value)">.  This identifies the webmail
or ESP service that hosts the sender's account.

=item Route 5 -- DKIM signing organisation

The C<d=> tag from the C<DKIM-Signature:> header is looked up in the
built-in provider table.  If found, a C<provider-table> entry is added
with role C<"DKIM signer (provider table): $domain">.  The full domain
pipeline (web/MX/NS/WHOIS) for this domain is already handled via Route 3
through C<mailto_domains()>.

=item Route 6 -- ESP / bulk sender (List-Unsubscribe)

Both C<https://> URLs and C<mailto:> addresses in the C<List-Unsubscribe:>
header are parsed for their domains.  Each unique domain is looked up in
the built-in provider table.  If found, a C<provider-table> entry is added
with role C<"ESP / bulk sender (List-Unsubscribe: $domain)">.

=back

=head3 Notes

=over 4

=item *

Deduplication is by lower-cased address only.  Two contacts with different
roles but the same address result in a single entry using the data from
whichever route found it first.  The later route's role and note are
silently discarded.

=item *

The provider table contains curated entries for approximately 50
well-known domains including major webmail providers (Gmail, Outlook,
Yahoo, Apple), CDNs and hosters (Cloudflare, Fastly, Akamai, AWS,
DigitalOcean, Vultr, Hetzner, Contabo, Leaseweb, M247, OVH, Linode),
ESPs (SendGrid, Mailchimp, Mailgun, Postmark, Brevo, Klaviyo, Campaign
Monitor, Constant Contact, HubSpot), registrars (GoDaddy, Namecheap),
and ISPs (TPG, Internode).  Subdomain matching strips labels left-to-right
until a match is found, so C<mail.sendgrid.net> matches C<sendgrid.net>.

=item *

Provider-table entries take priority in the sense that they are added
first; if the WHOIS address happens to match the provider-table address,
the WHOIS entry is suppressed by deduplication.  If they differ (unusual
but possible), both are added.

=item *

The result is not cached.  If you call C<abuse_contacts()> multiple times
on the same object, the full collation runs each time.  If this is a
concern, store the result in a variable:
C<my @contacts = $analyser-E<gt>abuse_contacts()>.

=item *

An empty list is returned if the message has no usable originating IP, no
extractable URLs, no contact domains, and no recognised provider-table
matches.  This is unusual in practice but can occur for very sparse or
malformed messages.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub abuse_contacts {
    my ($self) = @_;
    my (@contacts, %seen_idx);

    # $add records an abuse contact.  If the address has already been seen,
    # the new role is appended to the existing entry rather than discarded.
    # This means abuse_contacts() returns one hashref per unique address, with
    # a 'roles' arrayref carrying every route by which that address was found,
    # and 'role' (singular) set to the joined string for backward compatibility.
    my $add = sub {
        my (%args) = @_;
        my $addr = lc($args{address} // '');
        return unless $addr && $addr =~ /\@/;
        if (exists $seen_idx{$addr}) {
            # Address already present -- merge the new role into the existing entry
            # rather than dropping it.  This preserves the information that, for
            # example, Google was identified as both the sending ISP and the URL
            # host, which is useful context for the abuse report recipient.
            my $entry = $contacts[ $seen_idx{$addr} ];
            push @{ $entry->{roles} }, $args{role};
            # Keep 'role' (singular) in sync for any caller using the old key
            $entry->{role} = join(' and ', @{ $entry->{roles} });
            return;
        }
        # First time we have seen this address -- record its position and add it
        $seen_idx{$addr} = scalar @contacts;
        $args{roles} = [ $args{role} ];   # arrayref for multi-role merging
        push @contacts, \%args;
    };

    # 1. Sending ISP (originating IP)
    my $orig = $self->originating_ip();
    if ($orig) {
        my $pa = $self->_provider_abuse_for_ip($orig->{ip}, $orig->{rdns});
        if ($pa) {
            $add->(role    => 'Sending ISP (provider table)',
                   address => $pa->{email},
                   note    => "$orig->{ip} ($orig->{rdns}) — $pa->{note}",
                   via     => 'provider-table');
        }
        if ($orig->{abuse} && $orig->{abuse} ne '(unknown)') {
            $add->(role    => 'Sending ISP',
                   address => $orig->{abuse},
                   note    => "Network owner of originating IP $orig->{ip} ($orig->{org})",
                   via     => 'ip-whois');
        }
    }

    # 2. URL hosts
    my (%url_host_seen);
    for my $u ($self->embedded_urls()) {
        next if $url_host_seen{ $u->{host} }++;
        my $pa = $self->_provider_abuse_for_host($u->{host});
        if ($pa) {
            $add->(role    => "URL host (provider table)",
                   address => $pa->{email},
                   note    => "$u->{host} — $pa->{note}",
                   via     => 'provider-table');
        }
        if ($u->{abuse} && $u->{abuse} ne '(unknown)') {
            $add->(role    => 'URL host',
                   address => $u->{abuse},
                   note    => "Hosting $u->{host} ($u->{ip}, $u->{org})",
                   via     => 'ip-whois');
        }
    }

    # 3. Contact/reply domains — web host, MX, NS, registrar, From: account
    for my $d ($self->mailto_domains()) {
        my $dom = $d->{domain};

        # Web host
        if ($d->{web_abuse}) {
            my $pa = $self->_provider_abuse_for_host($dom);
            if ($pa) {
                $add->(role    => "Web host of $dom (provider table)",
                       address => $pa->{email},
                       note    => $pa->{note},
                       via     => 'provider-table');
            }
            $add->(role    => "Web host of $dom",
                   address => $d->{web_abuse},
                   note    => sprintf('Hosting %s (%s, %s)',
                                  $dom              // '(unknown domain)',
                                  $d->{web_ip}      // '(unknown IP)',
                                  $d->{web_org}     // '(unknown org)'),
                   via     => 'ip-whois');
        }

        # MX host
        if ($d->{mx_abuse}) {
            $add->(role    => "Mail host (MX) for $dom",
                   address => $d->{mx_abuse},
                   note    => sprintf('MX %s (%s, %s)',
                                  $d->{mx_host} // '(unknown host)',
                                  $d->{mx_ip}   // '(unknown IP)',
                                  $d->{mx_org}  // '(unknown org)'),
                   via     => 'ip-whois');
        }

        # NS host
        if ($d->{ns_abuse}) {
            $add->(role    => "DNS host (NS) for $dom",
                   address => $d->{ns_abuse},
                   note    => sprintf('NS %s (%s, %s)',
                                  $d->{ns_host} // '(unknown host)',
                                  $d->{ns_ip}   // '(unknown IP)',
                                  $d->{ns_org}  // '(unknown org)'),
                   via     => 'ip-whois');
        }

        # Domain registrar
        if ($d->{registrar_abuse}) {
            $add->(role    => "Domain registrar for $dom",
                   address => $d->{registrar_abuse},
                   note    => 'Registrar: ' . ($d->{registrar} // '(unknown)'),
                   via     => 'domain-whois');
        }
    }

    # 4. From: / Reply-To: / Return-Path: / Sender: account provider
    # For each of the four headers that may identify the sending account,
    # extract the domain from the addr-spec.  We must be careful to pull
    # the domain from the actual email address, not from a display name
    # that may itself contain an @ sign (e.g. "evil@gmail.com" <real@isp.com>).
    # Strategy: if angle brackets are present, take only the content of the
    # last <...> pair as the addr-spec; otherwise use the whole header value.
    for my $hname (qw(from reply-to return-path sender)) {
        my $val = $self->_header_value($hname) // next;

        # Extract the addr-spec from the rightmost angle-bracket pair.
        # RFC 2822 display-name form: "Display Name" <local@domain>
        # If no angle brackets are present the whole value is the addr-spec.
        my $addr_spec;
        if ($val =~ /<([^>]*)>\s*$/) {
            # Angle-bracket form -- use only what is inside the brackets.
            # This correctly ignores any @ signs in the display-name portion.
            $addr_spec = $1;
        } else {
            # No angle brackets -- treat the whole value as the addr-spec.
            $addr_spec = $val;
        }

        # Pull the domain from the right-hand side of the @ in the addr-spec.
        my ($addr_domain) = $addr_spec =~ /\@([\w.-]+)/;
        next unless $addr_domain;

        # Look up the domain (and its parents via subdomain stripping) in
        # the built-in provider table.  A hit means the account is hosted
        # by a known webmail or ESP provider we can contact directly.
        my $pa = $self->_provider_abuse_for_host($addr_domain);
        if ($pa) {
            $add->(role    => "Account provider ($hname: $val)",
                   address => $pa->{email},
                   note    => $pa->{note},
                   via     => 'provider-table');
        }
    }

    # 5. DKIM signing domain — the organisation that vouches for the message
    # The full domain pipeline (web/MX/NS/WHOIS) is already run on the DKIM
    # domain via mailto_domains(), so here we only need the provider-table
    # lookup for fast resolution of well-known ESPs.
    my $auth = $self->_parse_auth_results_cached();
    if ($auth->{dkim_domain}) {
        my $pa = $self->_provider_abuse_for_host($auth->{dkim_domain});
        if ($pa) {
            $add->(role    => "DKIM signer (provider table): $auth->{dkim_domain}",
                   address => $pa->{email},
                   note    => $pa->{note},
                   via     => 'provider-table');
        }
    }

    # 6. List-Unsubscribe domain — the ESP or bulk sender responsible for delivery
    my $unsub = $self->_header_value('list-unsubscribe');
    if ($unsub) {
        # Extract both mailto: and https: addresses
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
                $add->(role    => "ESP / bulk sender (List-Unsubscribe: $dom)",
                       address => $pa->{email},
                       note    => "$pa->{note} — responsible for this bulk delivery",
                       via     => 'provider-table');
            }
        }
    }

    return @contacts;
}

=head2 report()

Returns a formatted plain-text abuse report.

Produces a comprehensive, analyst-facing plain-text report covering all
findings from every analysis method.  It is the single-document summary
of everything the module knows about a message: envelope fields, risk
assessment, originating host, sending software, received chain tracking
IDs, embedded URLs grouped by hostname, contact domain intelligence, and
the recommended abuse contacts.

Use C<report()> when you want a human-readable document for review,
logging, or a ticketing system.  Use C<abuse_report_text()> when you want
a compact string to transmit to an ISP abuse desk.

=head3 Usage

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

=head3 Arguments

None.  C<parse_email()> must have been called first.

=head3 Returns

A plain scalar string containing the full report, newline-terminated,
using Unix line endings (C<\n>) throughout.  The string is never empty;
it always contains at least the header banner and envelope summary section.

The report is structured as nine sections separated by blank lines, in
this fixed order:

=over 4

=item 1. Banner

    ========================================================================
      Email::Abuse::Investigator Report  (vX.XX)
    ========================================================================

A row of 72 equals signs, the module name and version number, and a
closing row of 72 equals signs.

=item 2. Envelope summary

Up to six header fields, each decoded from MIME encoded-words where
applicable.  If a field was encoded, the decoded form is shown first
followed by the raw encoded original in brackets:

    From           : PayPal Security <phish@evil.example>
    Reply-to       : Replies <harvest@collector.example>
    Return-path    : <phish@evil.example>
    Subject        : Account Alert  [encoded: =?UTF-8?B?QWNjb3VudA==?=]
    Date           : Mon, 01 Jan 2024 00:00:00 +0000
    Message-id     : <msg001@evil.example>

Fields examined (in order): C<From:>, C<Reply-To:>, C<Return-Path:>,
C<Subject:>, C<Date:>, C<Message-ID:>.  Fields not present in the message
are silently omitted.

=item 3. Risk assessment

    [ RISK ASSESSMENT: HIGH (score: 11) ]
      [HIGH] firmluminary.com was registered 2025-09-01 (less than 180 days ago)
      [MEDIUM] rDNS 120-88-161-249.tpgi.com.au looks like a broadband/residential line
      ...

Or, when no flags were raised:

    [ RISK ASSESSMENT: INFO (score: 0) ]
      (no specific red flags detected)

Each flag is shown as C<[SEVERITY] detail-string>.

=item 4. Originating host

    [ ORIGINATING HOST ]
      IP           : 120.88.161.249
      Reverse DNS  : 120-88-161-249.tpgi.com.au
      Country      : AU
      Organisation : TPG Telecom Limited
      Abuse addr   : abuse@tpg.com.au
      Confidence   : high
      Note         : First external hop in Received: chain

Or C<(could not determine originating IP)> if C<originating_ip()> returns
C<undef>.  Fields with no value are omitted.

=item 5. Sending software (omitted entirely if no software headers found)

    [ SENDING SOFTWARE / INFRASTRUCTURE CLUES ]
      x-php-originating-script : 1000:mailer.php
      Note           : PHP script on shared hosting -- report to hosting abuse team

One block per detected header, with its note.

=item 6. Received chain tracking IDs (omitted if no hops have id or for fields)

    [ RECEIVED CHAIN TRACKING IDs ]
      (Supply these to the relevant ISP abuse team to trace the session)

      IP           : 91.198.174.5
      Envelope for : victim@bandsman.co.uk
      Server ID    : ABC123XYZ

Only hops that have at least one of a session ID (C<id>) or envelope
recipient (C<for>) are shown; IP-only hops are suppressed.  Oldest hop
first.

=item 7. Embedded HTTP/HTTPS URLs

    [ EMBEDDED HTTP/HTTPS URLs ]
      Host         : bit.ly  *** URL SHORTENER - real destination hidden ***
      IP           : 67.199.248.11
      Country      : US
      Organisation : Bit.ly LLC
      Abuse addr   : abuse@bit.ly
      URL          : https://bit.ly/scam123

URLs are grouped by hostname; if multiple URLs share a hostname, all
paths are listed together under the single host block.  Known URL
shorteners are annotated inline.  Shown as C<(none found)> when the
body contains no HTTP/HTTPS URLs.

=item 8. Contact / reply-to domains

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

One block per domain from C<mailto_domains()>.  Recently-registered
domains receive an inline warning banner.  Shown as C<(none found)>
when no qualifying contact domains are present.

=item 9. Where to send abuse reports

    [ WHERE TO SEND ABUSE REPORTS ]
      Role         : Sending ISP
      Send to      : abuse@tpg.com.au
      Note         : Network owner of originating IP 120.88.161.249 (TPG Telecom)
      Discovered   : ip-whois

      Role         : Domain registrar for firmluminary.com
      Send to      : abuse@godaddy.com
      Note         : Registrar: GoDaddy.com LLC
      Discovered   : domain-whois

One block per contact from C<abuse_contacts()>.  Shown as
C<(no abuse contacts could be determined)> when the list is empty.

=back

The report ends with a closing row of 72 equals signs.

=head3 Side Effects

Calls C<risk_assessment()>, C<originating_ip()>, C<sending_software()>,
C<received_trail()>, C<embedded_urls()>, C<mailto_domains()>, and
C<abuse_contacts()> if they have not already run on the current message,
performing all associated network I/O as documented in those methods.  All
underlying results are cached; the report text itself is not cached, but
re-computation is inexpensive since the data is already available.

=head3 Notes

=over 4

=item *

The report is idempotent: calling C<report()> multiple times on the same
object always returns an identical string, because all underlying methods
are cached.

=item *

MIME encoded-words in the C<From:>, C<Subject:>, and other displayed
headers are decoded for readability.  When a header was encoded, both the
decoded form and the raw encoded original are shown, so the report is
useful both for human reading and for log parsing.

=item *

URL hosts in section 7 are grouped by hostname and shown in first-seen
order.  Multiple URLs on the same host are listed together rather than
repeating the host's IP and WHOIS information, keeping the output compact
even when a message contains dozens of tracking-pixel and click-redirect
URLs all on the same CDN.

=item *

The received-trail section (section 6) filters out hops that have only an
IP address and no C<id> or C<for> clause.  The full unfiltered trail is
available via C<received_trail()>.

=item *

Section 5 (sending software) and section 6 (received chain tracking IDs)
are entirely omitted -- no heading, no placeholder text -- when no relevant
headers are present.  All other sections always appear, using a
C<(none found)> or equivalent placeholder when their data is empty.

=item *

The version number in the banner is the value of C<$Email::Abuse::Investigator::VERSION>
at the time C<report()> is called.

=back

=head3 API Specification

=head4 Input

    # Params::Validate::Strict compatible specification
    # No arguments.
    []

=head4 Output

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

=cut

sub report {
	my $self = $_[0];
	my @out;

	push @out, '=' x 72;
	push @out, "  Email::Abuse::Investigator Report  (v$VERSION)";
	push @out, '=' x 72;
	push @out, '';

    # ---- envelope summary ----
    for my $f (qw(from reply-to return-path subject date message-id)) {
        my $v = $self->_header_value($f);
        next unless defined $v;
        my $decoded = $self->_decode_mime_words($v);
        my $label   = ucfirst($f);
        push @out, sprintf("  %-14s : %s", $label,
            $decoded ne $v ? "$decoded  [encoded: $v]" : $v);
    }
    push @out, '';

    # ---- risk assessment ----
    my $risk = $self->risk_assessment();
    push @out, "[ RISK ASSESSMENT: $risk->{level} (score: $risk->{score}) ]";
    if (@{ $risk->{flags} }) {
        for my $f (@{ $risk->{flags} }) {
            push @out, "  [$f->{severity}] $f->{detail}";
        }
    } else {
        push @out, "  (no specific red flags detected)";
    }
    push @out, '';

    # ---- originating host ----
    push @out, "[ ORIGINATING HOST ]";
    my $orig = $self->originating_ip();
    if ($orig) {
        push @out, "  IP           : $orig->{ip}";
        push @out, "  Reverse DNS  : $orig->{rdns}"       if $orig->{rdns};
        push @out, "  Country      : $orig->{country}"    if $orig->{country};
        push @out, "  Organisation : $orig->{org}"         if $orig->{org};
        push @out, "  Abuse addr   : $orig->{abuse}"       if $orig->{abuse};
        push @out, "  Confidence   : $orig->{confidence}";
        push @out, "  Note         : $orig->{note}"        if $orig->{note};
    } else {
        push @out, "  (could not determine originating IP)";
    }
    push @out, '';

    # ---- Sending software / infrastructure clues ----
    my @sw = $self->sending_software();
    if (@sw) {
        push @out, "[ SENDING SOFTWARE / INFRASTRUCTURE CLUES ]";
        for my $s (@sw) {
            push @out, sprintf("  %-14s : %s", $s->{header}, $s->{value});
            push @out, "  Note           : $s->{note}";
            push @out, '';
        }
    }

    # ---- Received chain tracking IDs ----
    my @trail = grep { defined $_->{id} || defined $_->{for} }
                $self->received_trail();
    if (@trail) {
        push @out, "[ RECEIVED CHAIN TRACKING IDs ]";
        push @out, "  (Supply these to the relevant ISP abuse team to trace the session)";
        push @out, '';
        for my $hop (@trail) {
            push @out, "  IP           : " . ($hop->{ip} // '(unknown)');
            push @out, "  Envelope for : $hop->{for}" if $hop->{for};
            push @out, "  Server ID    : $hop->{id}"  if $hop->{id};
            push @out, '';
        }
    }

    # ---- HTTP/HTTPS URLs ----
    push @out, "[ EMBEDDED HTTP/HTTPS URLs ]";
    my @urls = $self->embedded_urls();
    if (@urls) {
        # Group by hostname so host/IP/org is shown once,
        # with all distinct paths listed beneath it
        my (%host_order, %host_meta, %host_paths);
        my $seq = 0;
        for my $u (@urls) {
            my $h = $u->{host};
            unless (exists $host_order{$h}) {
                $host_order{$h} = $seq++;
                $host_meta{$h}  = { ip => $u->{ip}, org => $u->{org},
                                    abuse => $u->{abuse}, country => $u->{country} };
            }
            push @{ $host_paths{$h} }, $u->{url};
        }

        for my $h (sort { $host_order{$a} <=> $host_order{$b} } keys %host_order) {
            my $m    = $host_meta{$h};
            my $bare = lc $h; $bare =~ s/^www\.//;
            push @out, "  Host         : $h" .
                       ($URL_SHORTENERS{$bare} ? '  *** URL SHORTENER — real destination hidden ***' : '');
            push @out, "  IP           : $m->{ip}"    if $m->{ip};
            push @out, "  Country      : $m->{country}" if $m->{country};
            push @out, "  Organisation : $m->{org}"   if $m->{org};
            push @out, "  Abuse addr   : $m->{abuse}" if $m->{abuse};
            my @paths = @{ $host_paths{$h} };
            if (@paths == 1) {
                push @out, "  URL          : $paths[0]";
            } else {
                push @out, "  URLs (" . scalar(@paths) . ")     :";
                push @out, "    $_" for @paths;
            }
            push @out, '';
        }
    } else {
        push @out, "  (none found)";
        push @out, '';
    }

    # ---- contact / reply domains ----
    push @out, "[ CONTACT / REPLY-TO DOMAINS ]";
    my @mdoms = $self->mailto_domains();
    if (@mdoms) {
        for my $d (@mdoms) {
            push @out, "  Domain       : $d->{domain}";
            push @out, "  Found in     : $d->{source}";

            if ($d->{recently_registered}) {
                push @out, "  *** WARNING: RECENTLY REGISTERED - possible phishing domain ***";
            }
            push @out, "  Registered   : $d->{registered}" if $d->{registered};
            push @out, "  Expires      : $d->{expires}"     if $d->{expires};
            push @out, "  Registrar    : $d->{registrar}"         if $d->{registrar};
            push @out, "  Reg. abuse   : $d->{registrar_abuse}"   if $d->{registrar_abuse};

            if ($d->{web_ip}) {
                push @out, "  Web host IP  : $d->{web_ip}";
                push @out, "  Web host org : $d->{web_org}"   if $d->{web_org};
                push @out, "  Web abuse    : $d->{web_abuse}" if $d->{web_abuse};
            } else {
                push @out, "  Web host     : (no A record / unreachable)";
            }

            if ($d->{mx_host}) {
                push @out, "  MX host      : $d->{mx_host}";
                push @out, "  MX IP        : $d->{mx_ip}"    if $d->{mx_ip};
                push @out, "  MX org       : $d->{mx_org}"   if $d->{mx_org};
                push @out, "  MX abuse     : $d->{mx_abuse}" if $d->{mx_abuse};
            } else {
                push @out, "  MX host      : (none found)";
            }

            if ($d->{ns_host}) {
                push @out, "  NS host      : $d->{ns_host}";
                push @out, "  NS IP        : $d->{ns_ip}"    if $d->{ns_ip};
                push @out, "  NS org       : $d->{ns_org}"   if $d->{ns_org};
                push @out, "  NS abuse     : $d->{ns_abuse}" if $d->{ns_abuse};
            }

            push @out, '';
        }
    } else {
        push @out, "  (none found)";
        push @out, '';
    }

    # ---- Abuse contacts summary ----
    push @out, "[ WHERE TO SEND ABUSE REPORTS ]";
    my @contacts = $self->abuse_contacts();
    if (@contacts) {
        for my $c (@contacts) {
            push @out, "  Role         : $c->{role}";
            push @out, "  Send to      : $c->{address}";
            push @out, "  Note         : $c->{note}" if $c->{note};
            push @out, "  Discovered   : $c->{via}";
            push @out, '';
        }
    } else {
        push @out, '  (no abuse contacts could be determined)';
        push @out, '';
    }

	push @out, '=' x 72;
	return join("\n", @out) . "\n";
}

# _split_message( $text )
#
# Entry criteria:
#   $text  -- a defined scalar containing a raw RFC 2822 email message,
#             with headers and body separated by a blank line (\n\n or
#             \r\n\r\n).  Both LF and CRLF line endings are accepted.
#             The text must already be dereferenced (parse_email() handles
#             the scalar-ref case before calling this method).
#             Called only from parse_email(); $self->{_sending_sw} and
#             $self->{_rcvd_tracking} must have been reset to [] by the
#             caller before this method is invoked.
#
# Exit status:
#   Returns undef (and does nothing further) if $header_block is undef or
#   contains only whitespace -- i.e. the message has no headers or is
#   empty.  Otherwise returns no meaningful value; all results are
#   communicated through side effects on $self.
#
# Side effects:
#   $self->{_headers}      set to an arrayref of { name => lc, value => raw }
#                          hashrefs, one per parsed header, in message order.
#                          Folded (multi-line) values are unfolded before
#                          parsing (RFC 2822 s2.2.3).  Header names are
#                          normalised to lower-case.
#   $self->{_received}     set to an arrayref of raw Received: header values
#                          (not decoded), in message order (most-recent first).
#   $self->{_body_plain}   set to the decoded plain-text body.  Appended to
#                          (not replaced) for each text/* part in multipart
#                          messages.
#   $self->{_body_html}    set to the decoded HTML body.  Appended to for
#                          each text/html part in multipart messages.
#   $self->{_sending_sw}   populated with { header, value, note } hashrefs
#                          for any of the six recognised software-fingerprint
#                          headers that are present, in alphabetical key order.
#   $self->{_rcvd_tracking} populated with { received, ip, for, id } hashrefs,
#                          one per Received: hop from which at least one of
#                          an IP, envelope recipient, or session ID could be
#                          extracted, in oldest-first order.
#
# Notes:
#   Delegates body decoding to _decode_multipart() for multipart/* content
#   types (which recursively handles each part) or to _decode_body() for
#   single-part messages.  If Content-Type is absent or unrecognised, the
#   body is treated as plain text with 7bit encoding.
#   The boundary parameter in multipart Content-Type is extracted with a
#   simple regex; missing or malformed boundaries cause the body to be
#   silently skipped.
#   Lines that do not match the header pattern /^([\w-]+)\s*:\s*(.*)/ are
#   silently discarded (covers blank lines and non-header preamble text).

sub _split_message {
    my ($self, $text) = @_;

    my ($header_block, $body_raw) = split /\r?\n\r?\n/, $text, 2;

    return unless defined $header_block && $header_block =~ /\S/;
    $body_raw //= '';

    # Unfold continuation lines (RFC 2822 s2.2.3)
    $header_block =~ s/\r?\n([ \t]+)/ $1/g;

    my @headers;
    for my $line (split /\r?\n/, $header_block) {
        if ($line =~ /^([\w-]+)\s*:\s*(.*)/) {
            push @headers, { name => lc($1), value => $2 };
        }
    }
    $self->{_headers}  = \@headers;
    $self->{_received} = [ map  { $_->{value} }
                           grep { $_->{name} eq 'received' } @headers ];

    my ($ct_h)  = grep { $_->{name} eq 'content-type' }              @headers;
    my ($cte_h) = grep { $_->{name} eq 'content-transfer-encoding' } @headers;
    my $ct  = defined $ct_h  ? $ct_h->{value}  : '';
    my $cte = defined $cte_h ? $cte_h->{value} : '';

    if ($ct =~ /multipart/i) {
        my ($boundary) = $ct =~ /boundary="?([^";]+)"?/i;
        $self->_decode_multipart($body_raw, $boundary) if $boundary;
    } else {
        my $decoded = $self->_decode_body($body_raw, $cte);
        if ($ct =~ /html/i) { $self->{_body_html}  = $decoded }
        else                 { $self->{_body_plain} = $decoded }
    }

    $self->_debug(sprintf "Parsed %d headers, %d Received lines",
        scalar @headers, scalar @{ $self->{_received} });

    # ---- Sending software fingerprints ----
    my %sw_notes = (
        'x-php-originating-script' => 'PHP script on shared hosting - report to hosting abuse team',
        'x-source'                 => 'Source file on shared hosting - report to hosting abuse team',
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

    # ---- Per-hop tracking IDs from Received: chain (oldest first) ----
    for my $rcvd (reverse @{ $self->{_received} }) {
        my $ip  = $self->_extract_ip_from_received($rcvd);
        my ($for_addr) = $rcvd =~ /\bfor\s+<?([^\s>]+\@[\w.-]+\.[\w]+)>?/i;
        my ($srv_id)   = $rcvd =~ /\bid\s+([\w.-]+)/i;
        next unless defined $ip || defined $for_addr || defined $srv_id;
        push @{ $self->{_rcvd_tracking} }, {
            received => $rcvd,
            ip       => $ip,
            for      => $for_addr,
            id       => $srv_id,
        };
    }
}

sub _decode_multipart {
    my ($self, $body, $boundary) = @_;

    # Split on the boundary marker.  The (?:--)? suffix matches both the
    # regular boundary (--BOUNDARY) and the closing boundary (--BOUNDARY--).
    my @parts = split /--\Q$boundary\E(?:--)?/, $body;

    for my $part (@parts) {
        # Skip whitespace-only segments that appear between boundaries
        next unless $part =~ /\S/;

        # Each part begins with a blank line separating headers from body
        $part =~ s/^\r?\n//;
        my ($phdr_block, $pbody) = split /\r?\n\r?\n/, $part, 2;
        next unless defined $pbody;

        # Unfold continuation header lines (RFC 2822 s.2.2.3)
        $phdr_block =~ s/\r?\n([ \t]+)/ $1/g;

        # Parse the per-part headers into a simple hash
        my %phdr;
        for my $line (split /\r?\n/, $phdr_block) {
            $phdr{ lc($1) } = $2 if $line =~ /^([\w-]+)\s*:\s*(.*)/;
        }

        my $pct  = $phdr{'content-type'}              // '';
        my $pcte = $phdr{'content-transfer-encoding'} // '';

        # Nested multipart/* (e.g. multipart/alternative inside multipart/mixed)
        # must be recursed into; the URL or body text lives inside those parts.
        # Without recursion the inner content is silently discarded, causing
        # embedded_urls() to miss all URLs in the message.
        if ($pct =~ /multipart/i) {
            # Extract the boundary parameter from the nested Content-Type header.
            # The parameter may be quoted or unquoted.
            my ($inner_boundary) = $pct =~ /boundary\s*=\s*"?([^";]+)"?/i;
            if ($inner_boundary) {
                $inner_boundary =~ s/\s+$//;   # strip trailing whitespace
                # Recurse to decode the inner MIME container
                $self->_decode_multipart($pbody, $inner_boundary);
            }
            next;   # do not fall through to the text handlers below
        }

        # Decode the part body according to its transfer encoding
        my $decoded = $self->_decode_body($pbody, $pcte);

        # Accumulate plain-text and HTML body content separately.
        # Both are used by embedded_urls() and mailto_domains().
        if    ($pct =~ /text\/html/i)    { $self->{_body_html}  .= $decoded }
        elsif ($pct =~ /text/i || !$pct) { $self->{_body_plain} .= $decoded }
    }
}

sub _decode_body {
	my ($self, $body, $cte) = @_;

	$cte //= '';

	return decode_qp($body)     if $cte =~ /quoted-printable/i;
	return decode_base64($body) if $cte =~ /base64/i;
	return $body;
}

# _find_origin()
#
#   Identifies the IP address of the machine that originally injected the
#   message into the public mail system by walking the Received: chain and
#   discarding every hop that belongs to private, reserved, or
#   caller-trusted infrastructure.  The first remaining (oldest external)
#   IP is enriched with reverse DNS, organisation, abuse contact, and
#   country information and returned as the origin hashref.
#
#   This is the back-end implementation for the public originating_ip()
#   method, which caches the result.  _find_origin() itself performs no
#   caching and must not be called directly; always call originating_ip().
#
# Entry criteria:
#   No arguments beyond $self.
#   $self->{_received}     must be populated (by _split_message()).
#   $self->{_headers}      must be populated (by _split_message()), so
#                          that _header_value('x-originating-ip') works.
#   $self->{trusted_relays} must be an arrayref (set by new(); may be []).
#
# Exit status:
#   Returns a hashref on success -- the same structure as originating_ip():
#     { ip, rdns, org, abuse, country, confidence, note }
#   Returns undef if no usable originating IP can be determined:
#     -- all Received: IPs are private, reserved, or trusted; AND
#     -- X-Originating-IP is absent, private, or unparseable.
#
# Side effects:
#   Performs network I/O via _enrich_ip():
#     - one PTR (rDNS) lookup for the chosen IP (_reverse_dns)
#     - one RDAP or WHOIS query for the chosen IP (_whois_ip)
#   No state is written to $self; the result is returned, not cached here.
#
# Notes:
#   The Received: chain is walked in reverse message order -- i.e. from
#   the oldest header (bottom of the header block) to the most recent --
#   so that candidates are accumulated in oldest-first order.  $candidates[0]
#   is always the outermost (first) external relay.
#
#   Confidence levels are assigned as follows:
#     'high'   -- two or more distinct external IPs found in the chain.
#                 Multiple independent relay records corroborate the origin.
#     'medium' -- exactly one external IP found in the chain.
#     'low'    -- no usable Received: IP; origin taken from
#                 X-Originating-IP, which is injected by webmail providers
#                 and is not independently verifiable.  Brackets and
#                 whitespace are stripped from the header value before use.
#
#   _is_private() treats undef and the empty string as private, so a
#   Received: header from which no IP can be extracted is silently skipped
#   without special-casing.
#
#   IPv6 addresses are not extracted by _extract_ip_from_received(); only
#   dotted-quad IPv4 addresses are considered.

sub _find_origin {
	my $self = $_[0];
	my @candidates;

	for my $hdr (reverse @{ $self->{_received} }) {
		my $ip = $self->_extract_ip_from_received($hdr) // next;
		next if $self->_is_private($ip);
		next if $self->_is_trusted($ip);
		push @candidates, $ip;
	}

    unless (@candidates) {
        my $xoip = $self->_header_value('x-originating-ip');
        if ($xoip) {
            $xoip =~ s/[\[\]\s]//g;
            return $self->_enrich_ip($xoip, 'low',
                'Taken from X-Originating-IP (webmail, unverified)')
                unless $self->_is_private($xoip);
        }
        return undef;
    }

    return $self->_enrich_ip(
        $candidates[0],
        @candidates > 1 ? 'high' : 'medium',
        'First external hop in Received: chain',
    );
}

sub _extract_ip_from_received {
    my ($self, $hdr) = @_;
    for my $re (@RECEIVED_IP_RE) {
        if ($hdr =~ $re) {
            my $ip = $1;
            next unless $ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;
            next if grep { $_ > 255 } split /\./, $ip;
            return $ip;
        }
    }
    return undef;
}

# Not using Data::Validate::IP::is_private_ipv4 here: that function covers
# only RFC 1918, loopback, and link-local.  We additionally need to exclude
# CGN (100.64.0.0/10, RFC 6598), the three RFC 5737 documentation ranges,
# 0.0.0.0/8, broadcast, and IPv6 ULA -- all of which appear in real or test
# Received: headers and must not be reported as origins.
sub _is_private {
    my ($self, $ip) = @_;
    return 1 unless defined $ip && $ip ne '';
    for my $re (@PRIVATE_RANGES) { return 1 if $ip =~ $re }
    return 0;
}

sub _is_trusted {
    my ($self, $ip) = @_;
    for my $cidr (@{ $self->{trusted_relays} }) {
        return 1 if $self->_ip_in_cidr($ip, $cidr);
    }
    return 0;
}

sub _extract_and_resolve_urls {
    my ($self) = @_;
    my (%url_seen, %host_cache);
    my @results;
    my $combined = $self->{_body_plain} . "\n" . $self->{_body_html};

    for my $url ($self->_extract_http_urls($combined)) {
        next if $url_seen{$url}++;
        my ($host) = $url =~ m{https?://([^/:?\s#]+)}i;
        next unless $host;

        # Resolve and WHOIS once per unique hostname, then cache
        unless (exists $host_cache{$host}) {
            my $ip    = $self->_resolve_host($host) // '(unresolved)';
            my $whois = $ip ne '(unresolved)' ? $self->_whois_ip($ip) : {};
            $host_cache{$host} = {
                ip      => $ip,
                org     => $whois->{org}     // '(unknown)',
                abuse   => $whois->{abuse}   // '(unknown)',
                country => $whois->{country} // undef,
            };
        }

        push @results, {
            url   => $url,
            host  => $host,
            %{ $host_cache{$host} },
        };
    }
    return \@results;
}

sub _extract_http_urls {
    my ($self, $body) = @_;
    my @urls;

    if ($HAS_HTML_LINKEXTOR) {
        my $p = HTML::LinkExtor->new(sub {
            my ($tag, %attrs) = @_;
            for my $attr (qw(href src action)) {
                push @urls, $attrs{$attr}
                    if ($attrs{$attr} // '') =~ m{^https?://}i;
            }
        });
        $p->parse($body);
    }

    while ($body =~ m{(https?://[^\s<>"'\)\]]+)}gi) {
        push @urls, $1;
    }

	my %seen;
	my @all = grep { !$seen{$_}++ } @urls;
	s/[.,;:!?\)>\]]+$// for @all;
	return @all;
}

sub _extract_and_analyse_domains {
	my $self = $_[0];
	my %seen;
	my @domains_with_source;

    # Build a set of recipient domains to exclude from analysis.
    # The To: and Cc: headers identify the message recipients -- the victims,
    # not the senders.  Their domains must never be reported as abuse targets,
    # even though bulk mailers routinely embed the recipient's address in the
    # message body (personalisation footers, unsubscribe confirmations, etc.).
    # We also exclude domains found in Received: "for" clauses for the same
    # reason.  Exclusion is by registrable eTLD+1 so that sub.victim.com and
    # victim.com are both excluded when victim.com is in To:.
    my %recipient_domains;
    for my $hname (qw(to cc)) {
        my $val = $self->_header_value($hname) // next;
        for my $dom ($self->_domains_from_text($val)) {
            my $reg = _registrable($dom) // $dom;
            $recipient_domains{$dom}++;
            $recipient_domains{$reg}++;
        }
    }
    # Also exclude domains extracted from Received: "for" envelope recipients
    for my $hop (@{ $self->{_rcvd_tracking} }) {
        next unless $hop->{for} && $hop->{for} =~ /\@([\w.-]+)/;
        my $dom = lc $1;
        my $reg = _registrable($dom) // $dom;
        $recipient_domains{$dom}++;
        $recipient_domains{$reg}++;
    }

    my $record = sub {
        my ($dom, $source) = @_;
        $dom = lc $dom;
        $dom =~ s/\.$//;
        return if $TRUSTED_DOMAINS{$dom};
        return if $recipient_domains{$dom};
        return if $recipient_domains{ _registrable($dom) // $dom };

	# Discard non-routable hostnames: single-label names (no dot),
	# .local / .internal / .lan / .arpa pseudo-TLDs, and anything
	# without at least one alphabetic-only TLD of 2+ characters.
	# These are MTA-internal identifiers that have no WHOIS record
	# and no actionable abuse contact (e.g. iad4s13mta756.xt.local).
	return unless $dom =~ /\.[a-zA-Z]{2,}$/;
	return if $dom =~ /\.(?:local|internal|lan|localdomain|arpa)$/i;

        return if $seen{$dom}++;
        push @domains_with_source, { domain => $dom, source => $source };
    };

    # Header fields that may carry contact domains
    my %header_sources = (
        'from'         => 'From: header',
        'reply-to'     => 'Reply-To: header',
        'return-path'  => 'Return-Path: header',
        'sender'       => 'Sender: header',
    );
    for my $hname (sort keys %header_sources) {
        my $val = $self->_header_value($hname) // next;
        $record->($_, $header_sources{$hname})
            for $self->_domains_from_text($val);
    }

    # Message-ID domain — often reveals the real sending platform.
    # Skip well-known infrastructure domains (gmail.com, outlook.com etc.)
    # that appear in Message-IDs but are never actionable abuse targets.
    # Check both the exact domain and its registrable parent.
    my $mid = $self->_header_value('message-id');
    if ($mid && $mid =~ /\@([\w.-]+)/) {
        my $mid_dom = lc $1;
        my $mid_reg = _registrable($mid_dom) // $mid_dom;
        $record->($mid_dom, 'Message-ID: header')
            unless $TRUSTED_DOMAINS{$mid_dom} || $TRUSTED_DOMAINS{$mid_reg};
    }

	# DKIM signing domain(s) -- the organisation(s) that vouch for the message.
	# All d= domains are recorded; dkim_domain is the preferred (ESP) one.
	my $auth = $self->_parse_auth_results_cached();
	for my $dkim_d (@{ $auth->{dkim_domains} // [] }) {
		$record->($dkim_d, 'DKIM-Signature: d= (signing domain)');
	}

    # List-Unsubscribe domain — identifies the ESP / bulk sender
    my $unsub = $self->_header_value('list-unsubscribe');
    if ($unsub) {
        while ($unsub =~ m{https?://([^/:?\s>]+)}gi) {
            $record->(lc $1, 'List-Unsubscribe: header');
        }
        while ($unsub =~ m{mailto:[^@\s>]+\@([\w.-]+)}gi) {
            $record->(lc $1, 'List-Unsubscribe: header');
        }
    }

    # Body (plain + HTML)
    my $combined = $self->{_body_plain} . "\n" . $self->{_body_html};
    $record->($_, 'email address / mailto in body')
        for $self->_domains_from_text($combined);

    # Analyse each domain
    my @results;
    for my $entry (@domains_with_source) {
        my $info = $self->_analyse_domain($entry->{domain});
        push @results, { %$entry, %$info };
    }
    return \@results;
}

# Extract unique domains from mailto: links and bare user@domain addresses
sub _domains_from_text {
    my ($self, $text) = @_;
    my %seen;
    my @out;

    # mailto:user@domain  (handles HTML-entity = from quoted-printable)
    while ($text =~ /mailto:(?:[^@\s<>"]+)@([\w.-]+)/gi) {
        my $dom = lc $1;  $dom =~ s/\.$//;
        push @out, $dom unless $seen{$dom}++;
    }

    # bare user@domain
    while ($text =~ /\b[\w.+%-]+@([\w.-]+\.[a-zA-Z]{2,})\b/g) {
        my $dom = lc $1;  $dom =~ s/\.$//;
        push @out, $dom unless $seen{$dom}++;
    }

    return @out;
}

# Full domain intelligence gathering
#
# _analyse_domain( $domain )
#
#   Runs the complete intelligence pipeline for a single domain name:
#   resolves its web-hosting IP (A record), mail-hosting IP (MX record),
#   DNS-hosting IP (NS record), and queries WHOIS for registrar, creation
#   date, expiry date, and abuse contact.  Each IP is enriched with
#   organisation name and abuse address via RDAP or WHOIS.
#
#   The result is cached in $self->{_domain_info}{$domain} so that if
#   the same domain is encountered in multiple sources (e.g. From: header
#   and body) the network queries are only performed once.
#
#   Called exclusively from _extract_and_analyse_domains(), which merges
#   the returned hashref with the { domain, source } record to produce
#   the per-domain hashrefs returned by mailto_domains().
#
# Entry criteria:
#   $domain  -- a defined, non-empty, lower-cased domain string with no
#               trailing dot (normalisation is the caller's responsibility).
#               Must not be in %TRUSTED_DOMAINS (filtering is the caller's
#               responsibility).
#   $self->{timeout}  -- used for all DNS and WHOIS socket operations.
#   $self->{_domain_info}  -- hashref cache; may already contain an entry
#                             for $domain from a prior call.
#
# Exit status:
#   Always returns a hashref reference -- never undef, never dies.
#   The hashref may be empty ({}) if all lookups fail or return nothing.
#   Keys present depend entirely on what the lookups return; all are
#   optional.  Possible keys and their types:
#     web_ip              string  -- dotted-quad IPv4 of A record
#     web_org             string  -- organisation owning web_ip
#     web_abuse           string  -- abuse contact for web_ip network
#     mx_host             string  -- lowest-preference MX hostname
#     mx_ip               string  -- dotted-quad IPv4 of mx_host
#     mx_org              string  -- organisation owning mx_ip
#     mx_abuse            string  -- abuse contact for mx_ip network
#     ns_host             string  -- first NS hostname returned
#     ns_ip               string  -- dotted-quad IPv4 of ns_host
#     ns_org              string  -- organisation owning ns_ip
#     ns_abuse            string  -- abuse contact for ns_ip network
#     registrar           string  -- registrar name from WHOIS
#     registrar_abuse     string  -- registrar abuse email from WHOIS
#     registered          string  -- creation date YYYY-MM-DD
#     expires             string  -- expiry date YYYY-MM-DD
#     recently_registered integer -- 1 if registered < 180 days ago
#     whois_raw           string  -- first 2048 bytes of WHOIS response
#
# Side effects:
#   Network I/O, subject to $self->{timeout}, in this order:
#     1. One A record lookup (_resolve_host) for the domain itself.
#     2. If web_ip found: one RDAP/WHOIS query (_whois_ip) -- up to two
#        TCP connections (IANA referral + authoritative registry).
#     3. If Net::DNS available: one MX record lookup.
#        If MX found: one A lookup for the MX hostname, then one
#        RDAP/WHOIS query for its IP (up to two TCP connections).
#     4. If Net::DNS available: one NS record lookup.
#        If NS found: one A lookup for the NS hostname, then one
#        RDAP/WHOIS query for its IP (up to two TCP connections).
#     5. Two TCP WHOIS connections for the domain itself: first to
#        whois.iana.org to obtain the TLD's authoritative registry,
#        then to that registry.
#   Worst-case total: 3 A lookups + 1 MX lookup + 1 NS lookup +
#   3x RDAP/WHOIS IP queries (up to 6 TCP connections) +
#   2 domain WHOIS TCP connections = up to 17 network operations.
#   Writes result hashref to $self->{_domain_info}{$domain} (cache).
#
# Notes:
#   Result is served from $self->{_domain_info}{$domain} on all
#   subsequent calls for the same domain within one parse_email() lifetime.
#   The cache is invalidated (reset to {}) by parse_email().
#
#   MX selection: the lowest-preference MX record is used (most preferred
#   server).  Only the primary MX is analysed; backup MXs are ignored.
#
#   NS selection: the first NS record returned by the resolver is used.
#   DNS resolvers do not guarantee a consistent ordering; the choice of
#   nameserver may vary between calls on different machines or at different
#   times.
#
#   MX and NS lookups are skipped entirely when Net::DNS is not installed.
#   In that case mx_*, ns_* keys are never present in the result.
#
#   WHOIS date fields (registered, expires) have time and timezone
#   components stripped by removing everything from the first 'T' or 'Z'
#   onward; the stored value is a plain YYYY-MM-DD string.  Parsing
#   uses the first matching pattern from a priority list; any fields not
#   found in the WHOIS response are absent from the result (not undef).
#
#   whois_raw is truncated to the first 2048 bytes of the raw WHOIS
#   response.  Structured fields (registrar, dates, abuse) are parsed from
#   the full response before truncation.
#
#   recently_registered is set to integer 1 when present; it is absent
#   (not 0) when the domain is not recently registered or when no creation
#   date was found.  The threshold is 180 days before time() at the moment
#   of analysis.
sub _analyse_domain {
	my ($self, $domain) = @_;

	return $self->{_domain_info}{$domain} if $self->{_domain_info}{$domain};

	$self->_debug("Analysing domain: $domain");
	my %info;

    # --- A record -> web hosting ---
    my $web_ip = $self->_resolve_host($domain);
    if ($web_ip) {
        $info{web_ip} = $web_ip;
        my $w = $self->_whois_ip($web_ip);
        $info{web_org}   = $w->{org}   if $w->{org};
        $info{web_abuse} = $w->{abuse} if $w->{abuse};
    }

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
        $info{whois_raw} = substr($domain_whois, 0, 2048);

        if ($domain_whois =~ /Registrar:\s*(.+)/i) {
            ($info{registrar} = $1) =~ s/\s+$//;
        }

        # Registrar abuse contact email
        for my $pat (
            qr/Registrar Abuse Contact Email:\s*(\S+@\S+)/i,
            qr/Abuse Contact Email:\s*(\S+@\S+)/i,
            qr/abuse-contact:\s*(\S+@\S+)/i,
        ) {
            if (!$info{registrar_abuse} && $domain_whois =~ $pat) {
                ($info{registrar_abuse} = $1) =~ s/\s+$//;
            }
        }

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

        for my $pat (
            qr/Registry Expiry Date:\s*(\S+)/i,
            qr/Expir(?:y|ation)(?: Date)?:\s*(\S+)/i,
            qr/paid-till:\s*(\S+)/i,
        ) {
            if (!$info{expires} && $domain_whois =~ $pat) {
                ($info{expires} = $1) =~ s/[TZ].*//;
            }
        }

        # Flag recently registered domains (common phishing indicator)
        if ($info{registered}) {
            my $epoch = $self->_parse_date_to_epoch($info{registered});
            $info{recently_registered} = 1
                if $epoch && (time() - $epoch) < 180 * 86400;
        }
    }

    $self->{_domain_info}{$domain} = \%info;
    return \%info;
}

sub _resolve_host {
    my ($self, $host) = @_;
    return $host if $host =~ /^\d{1,3}(?:\.\d{1,3}){3}$/;

    if ($HAS_NET_DNS) {
        my $res   = Net::DNS::Resolver->new(
            tcp_timeout => $self->{timeout},
            udp_timeout => $self->{timeout},
        );
        my $query = $res->search($host, 'A');
        if ($query) {
            for my $rr ($query->answer) {
                return $rr->address if $rr->type eq 'A';
            }
        }
        return undef;
    }

    my $packed = eval { inet_aton($host) };
    return $packed ? inet_ntoa($packed) : undef;
}

sub _reverse_dns {
    my ($self, $ip) = @_;
    return undef unless $ip;

    if ($HAS_NET_DNS) {
        my $res   = Net::DNS::Resolver->new(tcp_timeout => $self->{timeout});
        my $query = $res->search($ip, 'PTR');
        if ($query) {
            for my $rr ($query->answer) {
                return $rr->ptrdname if $rr->type eq 'PTR';
            }
        }
        return undef;
    }

    return scalar gethostbyaddr(inet_aton($ip), Socket::AF_INET());
}

# IP WHOIS: RDAP preferred, raw WHOIS TCP fallback
sub _whois_ip {
    my ($self, $ip) = @_;
    my $result = $HAS_LWP ? $self->_rdap_lookup($ip) : {};
    unless ($result->{org}) {
        my $raw = $self->_raw_whois($ip, 'whois.iana.org');
        if ($raw) {
            my ($ref) = $raw =~ /whois:\s*([\w.-]+)/i;
            my $detail = $ref ? $self->_raw_whois($ip, $ref) : $raw;
            $result = $self->_parse_whois_text($detail) if $detail;
        }
    }
    return $result;
}

# Domain WHOIS: ask IANA for the TLD's whois server, then query it
sub _domain_whois {
    my ($self, $domain) = @_;
    my $iana = $self->_raw_whois($domain, 'whois.iana.org') // return undef;
    my ($server) = $iana =~ /whois:\s*([\w.-]+)/i;
    return undef unless $server;
    return $self->_raw_whois($domain, $server);
}

sub _rdap_lookup {
    my ($self, $ip) = @_;
    return {} unless $HAS_LWP;
    my $ua  = LWP::UserAgent->new(timeout => $self->{timeout},
                                  agent   => "Email-Abuse-Investigator/$VERSION");
    my $res = eval { $ua->get("https://rdap.arin.net/registry/ip/$ip") };
    return {} unless $res && $res->is_success;
    my $j = $res->decoded_content;
    my %info;
    $info{org}    = $1 if $j =~ /"name"\s*:\s*"([^"]+)"/;
    $info{handle} = $1 if $j =~ /"handle"\s*:\s*"([^"]+)"/;
    if ($j =~ /"abuse".*?"email"\s*:\s*"([^"]+)"/s) {
        $info{abuse} = $1;
    } elsif ($j =~ /"email"\s*:\s*"([^@"]+@[^"]+)"/) {
        $info{abuse} = $1;
    }
    # Country code from RDAP
    $info{country} = $1 if $j =~ /"country"\s*:\s*"([A-Z]{2})"/;
    return \%info;
}

sub _raw_whois {
    my ($self, $query, $server) = @_;
    $server //= 'whois.iana.org';
    $self->_debug("WHOIS $server -> $query");
    my $sock = eval {
        IO::Socket::INET->new(
            PeerAddr => $server,
            PeerPort => 43,
            Proto    => 'tcp',
            Timeout  => $self->{timeout},
        );
    };
    return undef unless $sock;
    print $sock "$query\r\n";
    my $response = '';
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm($self->{timeout});
        while (my $line = <$sock>) { $response .= $line }
        alarm(0);
    };
    alarm(0);
    close $sock;
    return $response || undef;
}

sub _parse_whois_text {
    my ($self, $text) = @_;
    return {} unless $text;
    my %info;
    for my $pat (
        qr/^OrgName:\s*(.+)/mi,   qr/^org-name:\s*(.+)/mi,
        qr/^owner:\s*(.+)/mi,     qr/^descr:\s*(.+)/mi,
    ) {
        if (!$info{org} && $text =~ $pat) {
            ($info{org} = $1) =~ s/\s+$//;
        }
    }
    for my $pat (
        qr/OrgAbuseEmail:\s*(\S+@\S+)/mi,
        qr/abuse-mailbox:\s*(\S+@\S+)/mi,
    ) {
        if (!$info{abuse} && $text =~ $pat) {
            ($info{abuse} = $1) =~ s/\s+$//;
        }
    }
    $info{abuse} //= $1 if $text =~ /(abuse\@[\w.-]+)/i;
    # Country — match case-insensitively but normalise to uppercase
    if ($text =~ /^country:\s*([A-Za-z]{2})\s*$/m) {
        $info{country} = uc $1;
    }
    return \%info;
}

sub _enrich_ip {
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

sub _header_value {
    my ($self, $name) = @_;
    for my $h (@{ $self->{_headers} }) {
        return $h->{value} if $h->{name} eq lc($name);
    }
    return undef;
}

sub _ip_in_cidr {
    my ($self, $ip, $cidr) = @_;
    return $ip eq $cidr unless $cidr =~ m{/};
    my ($net_addr, $prefix) = split m{/}, $cidr;
    return 0 unless defined $prefix && $prefix =~ /^\d+$/ && $prefix <= 32;
    my $mask  = ~0 << (32 - $prefix);
    my $net_n = unpack 'N', (inet_aton($net_addr) // return 0);
    my $ip_n  = unpack 'N', (inet_aton($ip)       // return 0);
    return ($ip_n & $mask) == ($net_n & $mask);
}

# Lightweight date-to-epoch for common WHOIS date formats:
#   2024-11-01   2024-11-01T12:00:00Z   01-Nov-2024
sub _parse_date_to_epoch {
	my ($self, $str) = @_;

	return undef unless $str;

	my ($y, $m, $d);
	if    ($str =~ /^(\d{4})-(\d{2})-(\d{2})/)         { ($y,$m,$d)=($1,$2,$3) }
	elsif ($str =~ /^(\d{2})-([A-Za-z]{3})-(\d{4})/)   { ($d,$m,$y)=($1,$months{lc$2}//0,$3) }	# Readonly::Values::Months
	elsif ($str =~ /^(\d{2})\/(\d{2})\/(\d{4})/)        { ($m,$d,$y)=($1,$2,$3) }

	return unless $y && $m && $d;

	if (eval { require Time::Local; 1 }) {
		return eval { Time::Local::timegm(0,0,0,$d,$m-1,$y-1900) };
	}

	return ($y-1970)*365.25*86400 + ($m-1)*30.5*86400 + ($d-1)*86400;
}

# Parse a RFC 2822 date string to a Unix epoch.
# Handles: "Mon, 01 Jan 2024 00:00:00 +0000" and common variants.
# Returns undef if the string cannot be parsed.
#
# NOTE: timezone offsets (+0530, -0800 etc.) are intentionally ignored.
# The function returns UTC-equivalent seconds assuming the time component
# is UTC.  For the sole current use-case (7-day suspicious_date window)
# the maximum error is ~14 hours, which is well within the 7-day tolerance.
sub _parse_rfc2822_date {
	my $str = $_[0];

	return undef unless $str;

	if ($str =~ /(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/) {
		# Readonly::Values::Months
		my ($d, $m, $y, $H, $M, $S) = ($1, $months{ lc $2 } // 0, $3, $4, $5, $6);
		return undef unless $m;
		if (eval { require Time::Local; 1 }) {
			return eval { Time::Local::timegm($S, $M, $H, $d, $m - 1, $y - 1900) };
		}
	}
	return undef;
}

sub _decode_mime_words {
    my ($self, $str) = @_;
    return '' unless defined $str;
    $str =~ s/=\?([^?]+)\?([BbQq])\?([^?]*)\?=/_decode_ew($1,$2,$3)/ge;
    return $str;
}

sub _decode_ew {
    my ($charset, $enc, $text) = @_;
    my $raw;
    if (uc($enc) eq 'B') {
        $raw = decode_base64($text);
    } else {
        $text =~ s/_/ /g;
        $raw  = decode_qp($text);
    }
    # Best-effort UTF-8; silently ignore decode errors
    if (lc($charset) ne 'utf-8') {
        # For non-UTF-8 charsets just return the raw bytes — good enough
        # for display-name spoof detection which only needs ASCII matching
    }
    return $raw;
}

sub _parse_auth_results_cached {
	my $self = $_[0];

    return $self->{_auth_results} if $self->{_auth_results};

    my %auth;
    my $raw = join('; ',
        map { $_->{value} }
        grep { $_->{name} eq 'authentication-results' }
        @{ $self->{_headers} }
    );
    $auth{spf}   = $1 if $raw =~ /\bspf=(\S+)/i;
    $auth{dkim}  = $1 if $raw =~ /\bdkim=(\S+)/i;
    $auth{dmarc} = $1 if $raw =~ /\bdmarc=(\S+)/i;
    $auth{arc}   = $1 if $raw =~ /\barc=(\S+)/i;
    # Strip trailing punctuation captured by \S+
    for my $k (qw(spf dkim dmarc arc)) {
        $auth{$k} =~ s/[;,\s]+$// if defined $auth{$k};
    }

        # Extract DKIM signing domains from all DKIM-Signature: d= tags.
    # Multiple signatures are common: the first is usually the customer
    # domain, the second the ESP infrastructure domain (e.g. Salesforce,
    # SendGrid).  Prefer the first domain whose registrable parent is in
    # the provider table (it identifies the actionable ESP); fall back to
    # the first domain found.  All domains are stored in dkim_domains (an
    # arrayref) for use by the domain pipeline; dkim_domain holds the
    # primary one for risk_assessment and abuse_contacts.
    my @dkim_domains;
    for my $h (grep { $_->{name} eq 'dkim-signature' } @{ $self->{_headers} }) {
        if ($h->{value} =~ /\bd=([^;,\s]+)/) {
            push @dkim_domains, lc $1;
        }
    }
    if (@dkim_domains) {
        # Prefer a domain that matches the provider table (the ESP)
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

sub _registrable {
    my ($host) = @_;
    return undef unless $host && $host =~ /\./;
    my @labels = split /\./, lc $host;
    return $host if @labels <= 2;
    if ($labels[-1] =~ /^[a-z]{2}$/ &&
        $labels[-2] =~ /^(?:co|com|net|org|gov|edu|ac|me)$/) {
        return join('.', @labels[-3..-1]);
    }
    return join('.', @labels[-2..-1]);
}

sub _country_name {
	my $cc = $_[0];

	my %names = ( CN => 'China', RU => 'Russia', NG => 'Nigeria',
		VN => 'Vietnam', IN => 'India', PK => 'Pakistan',
		BD => 'Bangladesh' );
	return $names{$cc} // $cc;
}

# Look up provider abuse contact by plain domain name
sub _provider_abuse_for_host {
    my ($self, $host) = @_;
    $host = lc $host;
    # Try exact match, then strip successive subdomains
    while ($host =~ /\./) {
        return $PROVIDER_ABUSE{$host} if $PROVIDER_ABUSE{$host};
        $host =~ s/^[^.]+\.//;
    }
    return undef;
}

# Look up provider abuse contact by IP and/or rDNS hostname
sub _provider_abuse_for_ip {
	my ($self, $ip, $rdns) = @_;

	return $self->_provider_abuse_for_host($rdns) if $rdns;
	return undef;
}

sub _debug {
	my ($self, $msg) = @_;

	if($self->{logger}) {
		$self->{logger}->debug($msg);
	}
	print STDERR '[', __PACKAGE__, "] $msg\n" if $self->{verbose};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 ALGORITHM: DOMAIN INTELLIGENCE PIPELINE

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

=head1 WHY WEB HOSTING != MAIL HOSTING != DNS HOSTING

A fraudster registering C<sminvestmentsupplychain.com> might:

=over 4

=item * Register the domain at GoDaddy (registrar)

=item * Point the NS records at Cloudflare (DNS/CDN)

=item * Have no web server at all (A record absent)

=item * Route the MX records to Google Workspace or similar

=back

Each of these parties has an abuse contact, and each can independently
take action to disrupt the spam/phishing operation.  The module reports
all of them separately.

=head1 RECENTLY-REGISTERED FLAG

Phishing domains are very commonly registered hours or days before the
spam run.  The module flags any domain whose WHOIS creation date is
less than 180 days ago with C<recently_registered =E<gt> 1>.

=head1 SEE ALSO

L<Net::DNS>, L<LWP::UserAgent>, L<HTML::LinkExtor>, L<MIME::QuotedPrint>,
L<ARIN RDAP|https://rdap.arin.net/>

=head1 REPOSITORY

L<https://github.com/nigelhorne/Email-Abuse-Investigator>

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-email-abuse-investigator at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Abuse-Investigator>
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Mail::Message::Abuse

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Email-Abuse-Investigator>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Abuse-Investigator>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Email-Abuse-Investigator>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Mail::Message::Abuse>

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
