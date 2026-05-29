package GDPR::IAB::TCFv2::CMPValidator 0.530;

use v5.12;
use warnings;

use Carp         qw<croak carp>;
use Scalar::Util qw<blessed>;

# JSON::PP and Time::Piece are loaded lazily (see load_from_data and
# _parse_date). They are listed under META "recommends" rather than
# hard-required so the base parser doesn't pull them in for callers
# that never opt into CMPValidator. The HTTP::Tiny dependency is
# handled the same way in load_from_url.

sub new {
  my ($klass, %args) = @_;

  _validate_http_options(\%args);

  my $self = {
    cmps         => {},
    last_updated => undef,
    now          => $args{now},
    verify_ssl   => exists $args{verify_ssl} ? $args{verify_ssl} : 1,
    timeout      => exists $args{timeout}    ? $args{timeout}    : 30,
    http_client  => $args{http_client},
  };
  bless $self, $klass;

  if (defined $args{file}) {
    $self->load_from_file($args{file});
  }
  elsif (defined $args{url}) {

    # Network fetch is opt-in.  A library that silently dials out
    # over the network when handed an arbitrary URL is a footgun
    # (proxy traversal, blocked egress, surprise latency, supply-
    # chain risk).  Force the caller to pass network_ok => 1 so the
    # decision is intentional.
    croak "CMPValidator: refusing to fetch '$args{url}' because "
      . "network_ok was not set. Pass network_ok => 1 to enable "
      . "URL loading, or use file => '...' / data => '...' instead."
      unless $args{network_ok};

    $self->load_from_url($args{url});
  }
  elsif (defined $args{data}) {
    $self->load_from_data($args{data});
  }

  return $self;
}

sub _validate_http_options {
  my ($args) = @_;

  return unless exists $args->{http_client};

  my $client = $args->{http_client};
  croak "http_client must be a blessed object responding to ->get(\$url); got "
    . (ref($client) || (defined $client ? "a non-reference" : "undef"))
    unless blessed($client) && $client->can('get');

  croak "http_client and verify_ssl/timeout are mutually exclusive: configure SSL/timeout on the http_client itself"
    if exists $args->{verify_ssl} || exists $args->{timeout};

  return;
}

sub load_from_file {
  my ($self, $path) = @_;

  open my $fh, '<', $path or croak "Could not open CMP list file '$path': $!";
  my $content = do { local $/ = undef; <$fh> };
  close $fh;

  return $self->load_from_data($content);
}

sub load_from_url {
  my ($self, $url) = @_;

  my $client = $self->{http_client};
  unless (defined $client) {
    eval { require HTTP::Tiny; 1 }
      or croak "HTTP::Tiny is required to load CMP list from URL. " . "Please install it or use a local file instead.";

    # env_proxy => 1: honor https_proxy / http_proxy / no_proxy.
    # verify_SSL => 1 (default): pin the secure default regardless
    # of the installed HTTP::Tiny version (older versions defaulted
    # to 0).
    $client = HTTP::Tiny->new(env_proxy => 1, verify_SSL => $self->{verify_ssl}, timeout => $self->{timeout},);
  }

  my $response = $client->get($url);
  croak "Failed to fetch CMP list from '$url': $response->{reason}" unless $response->{success};

  return $self->load_from_data($response->{content});
}

sub load_from_data {
  my ($self, $json_text) = @_;

  eval { require JSON::PP; 1 }
    or croak "JSON::PP is required to decode the CMP list. " . "Please install it (it is core in Perl 5.14+).";

  my $data = eval { JSON::PP->new->utf8->decode($json_text) };
  croak "Failed to decode CMP list JSON: $@" if $@;

  croak "Invalid CMP list format: missing 'cmps' key" unless ref $data eq 'HASH' && $data->{cmps};

  $self->{cmps}         = $data->{cmps};
  $self->{last_updated} = $data->{lastUpdated};

  $self->_check_age();

  return $self;
}

sub is_valid {
  my ($self, $cmp_id) = @_;

  my $cmp = $self->{cmps}->{$cmp_id};
  return 0 unless $cmp;

  if ($cmp->{deletedDate}) {
    my $deleted = $self->_parse_date($cmp->{deletedDate});
    return 0 if $deleted && $deleted <= $self->_now();
  }

  return 1;
}

sub state {
  my ($self, $cmp_id, $now) = @_;

  my $cmp = $self->{cmps}->{$cmp_id};
  return 'unknown' unless $cmp;

  if ($cmp->{deletedDate}) {
    my $deleted = $self->_parse_date($cmp->{deletedDate});
    my $ref     = defined $now ? $now : $self->_now();
    return 'deleted' if $deleted && $deleted <= $ref;
  }

  return 'active';
}

sub last_updated_epoch {
  my ($self) = @_;
  return unless $self->{last_updated};
  return $self->_parse_date($self->{last_updated});
}

sub _check_age {
  my ($self) = @_;

  my $epoch = $self->last_updated_epoch();
  return unless $epoch;

  my $age_days = ($self->_now() - $epoch) / 86400;
  if ($age_days > 28) {
    carp sprintf "CMP list is older than 28 days (last updated: %s)", $self->{last_updated};
  }
  return;
}

sub _now {
  my ($self) = @_;
  return $self->{now} // time();
}

sub _load_time_piece {
  return 1 if $INC{'Time/Piece.pm'};
  require Time::Piece;
  return 1;
}

sub _parse_date {
  my ($self, $date_str) = @_;

  # IAB Registry timestamps come as "2020-04-27T20:27:54Z" or
  # "2020-04-27T20:27:54.2Z".  Strip the optional fractional seconds
  # and the timezone suffix (always Z in the IAB feed) before handing
  # to Time::Piece, which doesn't grok %z portably.
  if ($date_str =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
    $self->_load_time_piece();

    my $t_str = "$1-$2-$3 $4:$5:$6";
    my $epoch = eval { Time::Piece->strptime($t_str, "%Y-%m-%d %H:%M:%S")->epoch; };
    return $epoch;
  }
  return;
}

1;

__END__

=encoding utf8

=head1 NAME

GDPR::IAB::TCFv2::CMPValidator - IAB Registry-based Consent Management Platform validation

=head1 SYNOPSIS

    use GDPR::IAB::TCFv2::CMPValidator;

    # Load from a local snapshot of the IAB CMP registry JSON
    my $cmp_validator = GDPR::IAB::TCFv2::CMPValidator->new(
        file => '/path/to/cmp-list.json',
    );

    if ( $cmp_validator->is_valid(21) ) {
        print "CMP 21 exists and has not been retired\n";
    }

    # Compose with the main validator
    use GDPR::IAB::TCFv2::Validator;

    my $validator = GDPR::IAB::TCFv2::Validator->new(
        vendor_id     => 284,
        cmp_validator => $cmp_validator,
    );

    my $tc_string = '...';
    my $result = $validator->validate($tc_string);
    warn "compliance failed: $result\n" unless $result;

=head1 DESCRIPTION

C<GDPR::IAB::TCFv2::CMPValidator> validates the C<cmp_id> embedded in a
TC string against a snapshot of the IAB TCF CMP registry.  A registered
CMP that has been retired (the JSON record carries a C<deletedDate> in
the past) is treated as invalid.

This module B<does not refresh the registry on its own>.  The caller is
responsible for periodically downloading a fresh copy of
L<https://cmplist.consensu.org/v2/cmp-list.json> (or wherever the IAB
publishes the current registry) and pointing this validator at it.

=head1 NETWORK FETCH IS OPT-IN

The C<url> form does not fetch by default.  A library that silently
dials out over the network on construction is a footgun -- it traps
on blocked egress, surprises operators with latency, and broadens the
supply-chain surface.  To enable, pass C<network_ok =E<gt> 1> alongside
C<url>:

    GDPR::IAB::TCFv2::CMPValidator->new(
        url        => 'https://cmplist.consensu.org/v2/cmp-list.json',
        network_ok => 1,
    );

Without C<network_ok>, passing C<url> croaks with a message pointing
the caller at C<file =E<gt> ...> / C<data =E<gt> ...> instead.

=head1 CONSTRUCTOR

=head2 new

    my $v = GDPR::IAB::TCFv2::CMPValidator->new( %args );

Recognized keys:

=over 4

=item *

C<file> -- path to a local JSON file in the IAB CMP-list shape.  Read
synchronously via C<load_from_file>.

=item *

C<data> -- raw JSON text in the same shape.  Parsed via
C<load_from_data>.

=item *

C<url> -- HTTP(S) URL of the registry.  B<Requires> C<network_ok =E<gt> 1>
to actually fetch (see L</NETWORK FETCH IS OPT-IN>).  Uses L<HTTP::Tiny>
when allowed; croaks if the module is not installed.

=item *

C<network_ok> -- boolean.  Without it, the C<url> path croaks rather
than dialing out.

=item *

C<verify_ssl> -- boolean, default C<1>.  Convenience option for the
default L<HTTP::Tiny> client: when true, server certificates are
verified.  Disable only when targeting a CMP server with a self-signed
or otherwise non-public-CA certificate.  Mutually exclusive with
C<http_client> (configure SSL on the injected client itself).

=item *

C<timeout> -- integer seconds, default C<30>.  Convenience option for
the default L<HTTP::Tiny> client.  Mutually exclusive with
C<http_client>.

=item *

C<http_client> -- a pre-built object that responds to
C<-E<gt>get($url)> in the L<HTTP::Tiny>-compatible shape (see
L</INJECTING AN HTTP CLIENT>).  When provided, the validator uses this
object verbatim and does not construct its own L<HTTP::Tiny>; the
C<verify_ssl> and C<timeout> options are not accepted in this case
(passing either alongside C<http_client> croaks).

=item *

C<now> -- B<test only.>  Override the wall clock used for
C<deletedDate> comparisons and the 28-day staleness check
(e.g. C<now =E<gt> 1776254400> pins comparisons to 2026-04-15).
Production code should leave this unset; the validator reads the real
wall clock by default.

=back

=head1 METHODS

=head2 is_valid

    my $ok = $v->is_valid($cmp_id);

Returns true when the registry knows about C<$cmp_id> and the entry
either carries no C<deletedDate> or its C<deletedDate> is still in the
future relative to L</now>.

=head2 last_updated_epoch

Returns the registry's C<lastUpdated> timestamp as a Unix epoch, or
undef when the field is absent or unparseable.

=head2 load_from_file($path)

Drop-in load that re-reads the registry from C<$path>.  Useful when
the file has been refreshed out-of-band.

=head2 load_from_data($json_text)

Re-load from a raw JSON string.

=head2 load_from_url($url)

Fetch and load from C<$url>.  Bypasses the C<network_ok> gate -- the
intent is that the caller has already validated they want to make a
network call.  Uses the C<http_client> passed to the constructor when
present; otherwise constructs a default L<HTTP::Tiny> with
C<env_proxy =E<gt> 1>, C<verify_SSL> from C<verify_ssl>, and C<timeout>
from C<timeout>.

=head1 NETWORK PROXIES

When C<load_from_url> uses the default L<HTTP::Tiny> client (i.e. no
C<http_client> was injected), the standard HTTP-proxy environment
variables are honored automatically:

=over 4

=item *

C<https_proxy> -- proxy for C<https://> URLs.

=item *

C<http_proxy> -- proxy for C<http://> URLs.

=item *

C<all_proxy> -- fallback for both.

=item *

C<no_proxy> -- comma-separated host/domain patterns to bypass
(e.g. C<localhost,*.internal>).

=back

Lowercase names are the canonical form.  HTTP::Tiny accepts uppercase
as well, but the lowercase variants are preferred (some hardened
environments treat the uppercase form as a security risk because of
historical CGI injection bugs).

When an injected C<http_client> is used, this module does no proxy
configuration of its own: configure the client however you need before
handing it in.

=head1 INJECTING AN HTTP CLIENT

For test fakes, custom CA bundles, signed-request middleware, or any
other case the convenience options do not cover, hand the validator a
pre-built object via C<http_client>:

    package FakeHttp;
    sub new { bless { responses => $_[1] }, $_[0] }
    sub get { my $self = shift; shift @{ $self->{responses} } }

    my $cmp_validator = GDPR::IAB::TCFv2::CMPValidator->new(
        url         => 'https://does-not-matter.example/',
        network_ok  => 1,
        http_client => FakeHttp->new( [
            { success => 1, content => '{"cmps": {"7": {"id": 7}}}' },
        ] ),
    );

The injected object must be a blessed reference that responds to a
C<-E<gt>get($url)> method returning a hashref in the L<HTTP::Tiny>
shape: at minimum, C<success> (boolean), C<content> (response body on
success), and C<reason> (error text on failure).  The constructor
verifies the object is blessed and L<UNIVERSAL/can> a C<get> method,
so AUTOLOAD-using classes must override C<can> to advertise their
methods (the standard Perl convention).

=head1 STALE DATA WARNING

When the registry's C<lastUpdated> is older than 28 days (relative to
L</now>), the constructor emits a warning via C<Carp::carp>.  Suppress
with a local C<$SIG{__WARN__}> if your audit pipeline does not benefit
from it.

=head1 SEE ALSO

L<GDPR::IAB::TCFv2::Validator> for the rule engine that composes this
class as the C<cmp_validator> rule.

=cut
