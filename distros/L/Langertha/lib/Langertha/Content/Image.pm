package Langertha::Content::Image;
# ABSTRACT: Canonical image content block with cross-provider conversion
our $VERSION = '0.503';
use Moose;
use Moose::Util::TypeConstraints qw( subtype as where message );
use Carp qw( croak );
use MIME::Base64 qw( encode_base64 decode_base64 );
use Future;
use Future::AsyncAwait;
use Scalar::Util qw( blessed );
use Socket qw( getaddrinfo getnameinfo inet_pton AF_INET AF_INET6 SOCK_STREAM
  NI_NUMERICHOST NIx_NOSERV );

with 'Langertha::Content';

# The only schemes the inline fetch talks to (karr k325). data: URLs are
# decoded locally, everything else croaks before any I/O.
my @FETCH_SCHEMES = qw( http https );

# The download cap when the caller passes none (karr k337): provider inline
# image limits sit around 20 MB, and the body is held in memory.
use constant DEFAULT_MAX_BYTES => 20_971_520;

# Redirect hops the Net::Async::HTTP fetch follows itself, the LWP default.
my $MAX_REDIRECTS = 7;


has url => (
  is => 'ro',
  isa => 'Maybe[Str]',
  predicate => 'has_url',
);


has base64 => (
  is => 'rw',
  isa => 'Maybe[Str]',
  predicate => 'has_base64',
);


has media_type => (
  is => 'rw',
  isa => 'Maybe[Str]',
  predicate => 'has_media_type',
);


# Open value, not an enum: the provider judges it (normalize, don't gatekeep;
# a model family may add values before Langertha knows them).
subtype 'Langertha::Content::Image::Detail', as 'Str', where { length },
  message { 'detail must be a non-empty string' };

has detail => (
  is => 'ro',
  isa => 'Langertha::Content::Image::Detail',
  predicate => 'has_detail',
);


sub BUILD {
  my ($self) = @_;
  croak "Langertha::Content::Image requires url, base64, or data"
    unless $self->has_url || $self->has_base64;
}

# --- Constructors ---

sub from_url {
  my ( $class, $url, %extra ) = @_;
  croak "from_url requires a URL" unless defined $url && length $url;
  $class->_check_fetch_scheme($url) unless _is_data_url($url);
  my $media_type = $extra{media_type} // _sniff_media_type($url);
  return $class->new(
    url => $url,
    ( defined $media_type ? ( media_type => $media_type ) : () ),
    _detail_arg(%extra),
  );
}


sub from_file {
  my ( $class, $path, %extra ) = @_;
  croak "from_file requires a path" unless defined $path && length $path;
  croak "from_file: $path not found" unless -f $path;
  open my $fh, '<:raw', $path or croak "open $path: $!";
  my $bytes = do { local $/; <$fh> };
  close $fh;
  my $media_type = $extra{media_type} // _sniff_media_type($path);
  croak "from_file: cannot determine media_type for $path"
    unless defined $media_type;
  return $class->new(
    base64     => encode_base64($bytes, ''),
    media_type => $media_type,
    _detail_arg(%extra),
  );
}


sub from_data {
  my ( $class, $bytes, %extra ) = @_;
  croak "from_data requires bytes" unless defined $bytes;
  croak "from_data requires media_type" unless defined $extra{media_type};
  return $class->new(
    base64     => encode_base64($bytes, ''),
    media_type => $extra{media_type},
    _detail_arg(%extra),
  );
}


sub from_base64 {
  my ( $class, $b64, %extra ) = @_;
  croak "from_base64 requires a base64 string" unless defined $b64 && length $b64;
  croak "from_base64 requires media_type" unless defined $extra{media_type};
  return $class->new(
    base64     => $b64,
    media_type => $extra{media_type},
    _detail_arg(%extra),
  );
}


# --- Base64 materialization ---

# timeout => N comes from the engine's inline_image_fetch_timeout on the
# request-build paths (karr k279). LWP cannot run without a timeout, so 0
# leaves LWP's own default (180s) in place. max_bytes / url_filter come from
# inline_image_max_bytes / inline_image_url_filter (karr k337).
sub ensure_base64 {
  my ( $self, %opt ) = @_;
  return $self->base64 if $self->has_base64;
  croak "ensure_base64: no url to fetch" unless $self->has_url;
  return $self->_inline_data_url if _is_data_url($self->url);
  $self->_check_fetch_scheme($self->url);
  my %limit = _fetch_limits(%opt);
  $self->_check_url_filter( $self->url, $limit{url_filter} );

  my $secs = $opt{timeout} // 30;
  require LWP::UserAgent;
  my %state = ( checked => { _uri_key( $self->url ) => 1 } );   # vetted above
  my $ua = $self->_guard_ua( LWP::UserAgent->new(
    agent => 'Langertha-Content-Image/'.$VERSION,
    ( $secs ? ( timeout => $secs ) : () ),
  ), \%limit, \%state );
  return $self->_inline_fetched( $ua->get($self->url), \%limit, \%state );
}

# Async twin of ensure_base64 (karr k274): the GET goes through $http, any
# client with the async do_request contract (ADR 0027) -- the engine's
# _async_http on the _f paths, so a URL image never blocks the event loop on
# LWP. A transport failure and an error status fail the Future with the text
# ensure_base64 croaks.
async sub ensure_base64_f {
  my ( $self, $http, %opt ) = @_;
  return $self->base64 if $self->has_base64;
  croak "ensure_base64_f: no url to fetch" unless $self->has_url;
  return $self->_inline_data_url if _is_data_url($self->url);
  $self->_check_fetch_scheme($self->url);
  croak "ensure_base64_f requires a client with do_request"
    unless blessed($http) && $http->can('do_request');
  my %limit = _fetch_limits(%opt);
  $self->_check_url_filter( $self->url, $limit{url_filter} );

  my %state = ( checked => { _uri_key( $self->url ) => 1 } );   # vetted above
  if ( $http->isa('Net::Async::HTTP') ) {
    my $response = await $self->_fetch_net_async_f( $http, \%limit );
    return $self->_inline_fetched( $response, \%limit, \%state );
  }
  # The sync LWP shim runs the engine's own user_agent, which allows every
  # scheme LWP knows and has no size cap: fetch through a copy guarded like
  # ensure_base64's agent (karr k325, k337).
  if ( $http->isa('Langertha::Request::SyncHTTP')
    && blessed( $http->user_agent ) && $http->user_agent->isa('LWP::UserAgent') ) {
    $http = Langertha::Request::SyncHTTP->new(
      user_agent => $self->_guard_ua( $http->user_agent->clone, \%limit, \%state ) );
  }
  else {
    # Any other client follows redirects on its own terms: its chain is
    # checked after the fact, and nothing from a refused hop is stored.
    $state{check_chain} = 1;
  }

  my $response = await $self->_fetch_one_f( $http, $self->url );
  return $self->_inline_fetched( $response, \%limit, \%state );
}

# One GET through the async contract; a transport failure fails with the text
# ensure_base64 croaks.
sub _fetch_one_f {
  my ( $self, $http, $url, %args ) = @_;
  require HTTP::Request;
  my $request = HTTP::Request->new( GET => $url,
    [ 'User-Agent' => 'Langertha-Content-Image/'.$VERSION ] );
  my $orig = $self->url;
  # The Net::Async::HTTP connect-module check of Role::AsyncHTTP: a module that
  # fails to load at connect time would wedge the host's slot (karr k353).
  if ( $http->isa('Net::Async::HTTP') ) {
    require Langertha::HTTP::ConnectCheck;
    my $error = Langertha::HTTP::ConnectCheck::connect_error($url);
    return Future->fail("ensure_base64: failed to fetch $orig: $error\n") if $error;
  }
  return $http->do_request( request => $request, %args )->else( sub {
    my ($err) = @_;
    $err =~ s/\s+\z//;
    Future->fail("ensure_base64: failed to fetch $orig: $err\n");
  } );
}

# Net::Async::HTTP (karr k337). Redirects are followed here, one hop at a
# time with max_redirects => 0, so the scheme rule and the url filter see
# every hop before it is requested. The body streams through on_header and is
# counted; past the cap the request is abandoned: wait_any cancels it, which
# closes the connection. That abort waits for the loop's next tick, because
# the chunk callback runs inside the connection's read handler, where closing
# the connection is not safe; a response that completes within the same read
# is refused by the flag instead.
async sub _fetch_net_async_f {
  my ( $self, $http, $limit ) = @_;
  require URI;
  my $max = $limit->{max_bytes};
  my $uri = URI->new( $self->url );
  my $previous;
  for my $hop ( 0 .. $MAX_REDIRECTS ) {
    my $too_big;
    my $abort = Future->new;
    my %stream = $max ? ( on_header => sub {
      my ($header) = @_;
      my $trip = sub {
        return if $too_big++;
        $http->loop->later( sub { $abort->done unless $abort->is_ready } );
      };
      my $length = $header->content_length;
      $trip->() if $header->is_success && defined $length && $length > $max;
      return sub {
        return $header unless @_;
        return if $too_big;
        $header->add_content( $_[0] ) if defined $_[0];
        $trip->() if length( ${ $header->content_ref } ) > $max;
        return;
      };
    } ) : ();
    # Over the cap, whatever ends the fetch (the abort, or the server closing
    # the connection first) ends in the size error.
    my $response = await Future->wait_any(
      $self->_fetch_one_f( $http, "$uri", max_redirects => 0, %stream ), $abort,
    )->else( sub { $too_big ? Future->done : Future->fail(@_) } );
    $self->_croak_too_big($max) if $too_big;
    $response->previous($previous) if $previous;
    my $location = $response->is_redirect && $response->header('Location');
    return $response unless $location && $hop < $MAX_REDIRECTS;
    $uri = URI->new_abs( $location, $uri );
    $self->_check_fetch_scheme("$uri");
    $self->_check_url_filter( "$uri", $limit->{url_filter} );
    $previous = $response;
  }
  return;   # not reached: the last hop returns above
}

# Stores a fetched HTTP::Response as the inline payload (both doors above).
sub _inline_fetched {
  my ( $self, $response, $limit, $state ) = @_;
  $self->_refuse_url( @{$state}{qw( refused filter_error )} ) if $state->{refused};
  croak "ensure_base64: failed to fetch ".$self->url.": ".$response->status_line
    unless $response->is_success;
  # LWP stops at max_size (Client-Aborted) or at the Content-Length check of
  # _guard_ua (X-Died); a body from any other client is measured here (k337).
  my $max  = $limit->{max_bytes};
  my $died = $response->header('X-Died');
  $self->_croak_too_big($max) if $max && ( $state->{too_big}
    || ( $response->header('Client-Aborted') // '' ) eq 'max_size'
    || ( $response->content_length // 0 ) > $max
    || length( ${ $response->content_ref } ) > $max );
  croak "ensure_base64: failed to fetch ".$self->url.": $died" if defined $died;
  # Whatever client ran the fetch, a body that came from another scheme (a
  # redirect it followed) is never stored (karr k325).
  my $final = $response->request && $response->request->uri;
  $self->_check_fetch_scheme("$final") if defined $final;
  # A client that followed redirects on its own: every hop it took must pass
  # the url filter too, or nothing is stored (karr k337).
  if ( $limit->{url_filter} && $state->{check_chain} ) {
    my @chain;
    for ( my $hop = $response; $hop; $hop = $hop->previous ) {
      unshift @chain, $hop->request->uri if $hop->request && $hop->request->uri;
    }
    for my $hop (@chain) {
      $self->_check_url_filter( "$hop", $limit->{url_filter} )
        unless $state->{checked}{ _uri_key($hop) }++;
    }
  }

  $self->base64( encode_base64( $self->_decoded_body( $response, $max ), '' ) );
  unless ($self->has_media_type) {
    my $ct = $response->header('Content-Type') // '';
    $ct =~ s/;.*$//;
    $ct =~ s/^\s+|\s+$//g;
    $self->media_type($ct) if length $ct;
  }
  return $self->base64;
}

# The body with its Content-Encoding undone (karr k342). The cap above counts
# the bytes on the wire; a compressed body is inflated in blocks and refused as
# soon as its decoded size passes the cap, so a small gzip body cannot expand to
# gigabytes in memory. No backend is trusted to have decoded it: Net::Async::HTTP
# decodes (and counts) only the encodings it knows and leaves the rest here.
# Without a cap, HTTP::Message decodes as before. The bounded inflate itself is
# shared with the provider/metrics decoders (Langertha::HTTP::BoundedDecode,
# karr k346); the image-flavoured error text stays here through the handlers.
sub _decoded_body {
  my ( $self, $response, $max ) = @_;
  return $response->decoded_content( charset => 'none' ) unless $max;
  require Langertha::HTTP::BoundedDecode;
  return Langertha::HTTP::BoundedDecode::decode_within(
    $response->content, scalar $response->header('Content-Encoding'), $max, {
      too_big     => sub { $self->_croak_too_big( $_[0] ) },
      undecodable => sub { $self->_undecodable( $_[0] ) },
      unbounded_encoding => sub {
        croak "ensure_base64: failed to fetch ".$self->url
          . ": cannot decode Content-Encoding '$_[0]' within inline_image_max_bytes";
      },
    } );
}

sub _undecodable {
  my ( $self, $encoding ) = @_;
  croak "ensure_base64: failed to fetch ".$self->url.": cannot decode Content-Encoding '$encoding'";
}

# max_bytes (undef: the default cap, 0: none) and url_filter out of the
# ensure_base64(_f) options.
sub _fetch_limits {
  my (%opt) = @_;
  my $filter = $opt{url_filter};
  croak "url_filter must be a CODE reference" if defined $filter && ref $filter ne 'CODE';
  return ( max_bytes => $opt{max_bytes} // DEFAULT_MAX_BYTES, url_filter => $filter );
}

# The LWP agent of a fetch, guarded (karr k325, k337): only http/https, also
# on redirects; max_size stops reading past the cap, and a Content-Length over
# it stops before the body; request_prepare runs for the first request and for
# every redirect hop before it connects, so a hop the url filter refuses is
# never requested. LWP turns a die in either handler into a response (X-Died,
# or a 400), so the verdict is kept in $state for _inline_fetched. A handler
# rather than a redirect_ok override: that would mean reblessing the clone of
# the engine's user_agent into a generated subclass.
sub _guard_ua {
  my ( $self, $ua, $limit, $state ) = @_;
  $ua->protocols_allowed([@FETCH_SCHEMES]);
  if ( my $max = $limit->{max_bytes} ) {
    $ua->max_size($max);
    $ua->add_handler( response_header => sub {
      my ($response) = @_;
      my $length = $response->content_length;
      return unless defined $length && $length > $max;
      $state->{too_big} = 1;
      die "inline_image_max_bytes exceeded\n";
    }, m_code => 2 );
  }
  if ( my $filter = $limit->{url_filter} ) {
    $ua->add_handler( request_prepare => sub {
      my ($request) = @_;
      return if $state->{checked}{ _uri_key( $request->uri ) }++;
      my ( $ok, $error ) = _filter_verdict( $filter, $request->uri );
      return if $ok;
      @{$state}{qw( refused filter_error )} = ( $request->uri->as_string, $error );
      die "refused by inline_image_url_filter\n";
    } );
  }
  return $ua;
}

# (allowed, error) for one URL: the filter gets a URI object and returns true
# to allow; a filter that dies refuses, and its error is reported.
sub _filter_verdict {
  my ( $filter, $url ) = @_;
  require URI;
  my $ok;
  return ( 0, $@ =~ s/\s+\z//r ) unless eval { $ok = $filter->( URI->new("$url") ); 1 };
  return ( $ok ? 1 : 0, undef );
}

# A URL's canonical string, so a URL the filter already passed is not asked
# (and resolved) twice.
sub _uri_key {
  require URI;
  return URI->new("$_[0]")->canonical->as_string;
}

sub _check_url_filter {
  my ( $self, $url, $filter ) = @_;
  return unless $filter;
  my ( $ok, $error ) = _filter_verdict( $filter, $url );
  $self->_refuse_url( $url, $error ) unless $ok;
  return;
}

sub _refuse_url {
  my ( $self, $url, $error ) = @_;
  my $class = ref $self || $self;
  croak "$class refuses to fetch image URL $url: "
    . ( defined $error ? "inline_image_url_filter died: $error" : 'rejected by inline_image_url_filter' );
}

sub _croak_too_big {
  my ( $self, $max ) = @_;
  my $class = ref $self || $self;
  croak "$class image at ".$self->url." exceeds inline_image_max_bytes ($max)";
}



# --- SSRF filter (karr k337) ---

sub deny_private_hosts {
  my ( $class, %opt ) = @_;
  my $resolver = $opt{resolver} // \&_resolve_host;
  croak "deny_private_hosts: resolver must be a CODE reference" unless ref $resolver eq 'CODE';
  return sub {
    my ($uri) = @_;
    my $host = eval { $uri->host };
    return 0 unless defined $host && length $host;
    my @addresses = $resolver->($host);
    return 0 unless @addresses;
    for my $address (@addresses) {
      return 0 if _is_private_address($address);
    }
    return 1;
  };
}


sub _resolve_host {
  my ($host) = @_;
  my ( $err, @found ) = getaddrinfo( $host, undef, { socktype => SOCK_STREAM } );
  return () if $err;
  my @addresses;
  for my $entry (@found) {
    my ( $name_err, $ip ) = getnameinfo( $entry->{addr}, NI_NUMERICHOST, NIx_NOSERV );
    push @addresses, $ip unless $name_err;
  }
  return @addresses;
}

# True for an address on an internal network (the deny_private_hosts list),
# and for anything that does not parse as an IP address.
sub _is_private_address {
  my ($address) = @_;
  ( my $ip = $address // '' ) =~ s/%.*\z//s;   # IPv6 zone index
  $ip =~ s/\A\[(.*)\]\z/$1/;
  if ( defined( my $v4 = inet_pton( AF_INET, $ip ) ) ) {
    return _is_private_v4($v4);
  }
  my $v6 = inet_pton( AF_INET6, $ip );
  return 1 unless defined $v6;
  my $head = substr $v6, 0, 12;
  return _is_private_v4( substr $v6, 12 ) if $head eq ( "\0" x 10 ) . "\xff\xff";
  return 1 if $head eq "\0" x 12;
  # IPv4 addresses a gateway translates to (karr k343): SIIT ::ffff:0:0:0/96,
  # NAT64 64:ff9b::/96 and the local-use 64:ff9b:1::/48 (RFC 8215), and 6to4
  # 2002::/16. A local NAT64 address outside the /96 layout does not say where
  # its IPv4 address sits, so it is refused outright.
  return _is_private_v4( substr $v6, 12 )
    if $head eq ( "\0" x 8 ) . "\xff\xff\0\0"
    || $head eq "\0\x64\xff\x9b" . ( "\0" x 8 );
  if ( substr( $v6, 0, 6 ) eq "\0\x64\xff\x9b\0\x01" ) {
    return 1 unless substr( $v6, 6, 6 ) eq "\0" x 6;
    return _is_private_v4( substr $v6, 12 );
  }
  return _is_private_v4( substr $v6, 2, 4 ) if substr( $v6, 0, 2 ) eq "\x20\x02";
  # Teredo 2001:0000::/32 (RFC 4380, karr k346): the client's IPv4 sits in the
  # last 32 bits, obfuscated (bit-inverted), so it cannot be re-checked like
  # 6to4 or NAT64 above -- refuse the whole prefix outright. A non-Teredo
  # 2001::/16 address (2001:db8::, 2001:4860::, ...) does not match and passes.
  return 1 if substr( $v6, 0, 4 ) eq "\x20\x01\0\0";
  my ( $first, $second ) = unpack 'C2', $v6;
  return 1 if ( $first & 0xfe ) == 0xfc;                          # fc00::/7
  return 1 if $first == 0xfe && ( $second & 0x80 ) == 0x80;       # fe80::/10, fec0::/10
  return 1 if $first == 0xff;                                     # ff00::/8
  return 0;
}

sub _is_private_v4 {
  my ($packed) = @_;
  my ( $first, $second ) = unpack 'C2', $packed;
  return 1 if $first == 0 || $first == 10 || $first == 127;
  return 1 if $first == 169 && $second == 254;
  return 1 if $first == 172 && ( $second & 0xf0 ) == 16;
  return 1 if $first == 192 && $second == 168;
  return 1 if $first == 192 && $second == 0 && unpack( 'x2 C', $packed ) == 0;   # 192.0.0.0/24
  return 1 if $first == 198 && ( $second & 0xfe ) == 18;                          # 198.18.0.0/15
  return 1 if $first == 100 && ( $second & 0xc0 ) == 64;
  return 1 if $first >= 224;
  return 0;
}

# --- Serializers ---

sub data_url {
  my ($self) = @_;
  $self->ensure_base64;
  return sprintf('data:%s;base64,%s',
    ($self->media_type // 'application/octet-stream'),
    $self->base64,
  );
}


# The image as one string for wires that take "URL or data URL" in one field.
# inline => 1 forces the data URL (fetching a URL-only image first, like
# to_gemini) for endpoints that reject remote image URLs (karr k267).
sub _url_or_data_url {
  my ( $self, %opt ) = @_;
  return $self->url if $self->has_url && !$opt{inline};
  return $self->data_url;
}

sub to_openai {
  my ( $self, %opt ) = @_;
  return { type => 'image_url', image_url => {
    url => $self->_url_or_data_url(%opt),
    ( $self->has_detail ? ( detail => $self->detail ) : () ),
  } };
}


sub to_responses {
  my ( $self, %opt ) = @_;
  return {
    type      => 'input_image',
    image_url => $self->_url_or_data_url(%opt),
    ( $self->has_detail ? ( detail => $self->detail ) : () ),
  };
}


sub to_ollama {
  my ($self) = @_;
  return $self->ensure_base64;
}


sub to_lmstudio {
  my ($self) = @_;
  return { type => 'image', data_url => $self->data_url };
}


sub to_anthropic {
  my ($self) = @_;
  if ($self->has_url) {
    return {
      type   => 'image',
      source => { type => 'url', url => $self->url },
    };
  }
  croak "to_anthropic: base64 image requires media_type"
    unless $self->has_media_type;
  return {
    type   => 'image',
    source => {
      type       => 'base64',
      media_type => $self->media_type,
      data       => $self->base64,
    },
  };
}


sub to_gemini {
  my ($self) = @_;
  $self->ensure_base64;
  croak "to_gemini: image requires media_type"
    unless $self->has_media_type;
  return {
    inline_data => {
      mime_type => $self->media_type,
      data      => $self->base64,
    },
  };
}


# --- JSON ---

# Compact on purpose: TO_JSON fires implicitly wherever a message array holding
# the image is encoded (a trace, a log line), and the base64 payload would blow
# those up (karr k273). The payload is described by its decoded size instead.
sub TO_JSON {
  my ($self) = @_;
  my $url = $self->has_url ? $self->url : undef;
  $url = undef if defined $url && $url =~ /\Adata:/i;
  my %out = (
    type   => 'image',
    source => ( defined $url ? 'url' : 'base64' ),
    ( defined $url ? ( url => $url ) : () ),
    ( defined $self->media_type ? ( media_type => $self->media_type ) : () ),
    ( $self->has_detail ? ( detail => $self->detail ) : () ),
  );
  if ( defined $self->base64 ) {
    ( my $b64 = $self->base64 ) =~ s/\s+//g;
    my $pad = $b64 =~ /(=+)\z/ ? length $1 : 0;
    $out{bytes} = int( length($b64) * 3 / 4 ) - $pad;
  }
  return \%out;
}


# --- Helpers ---

sub _is_data_url { defined $_[0] && $_[0] =~ /\Adata:/i }

sub _check_fetch_scheme {
  my ( $self, $url ) = @_;
  my ($scheme) = $url =~ /\A([a-zA-Z][a-zA-Z0-9+.\-]*):/;
  return if defined $scheme && grep { lc $scheme eq $_ } @FETCH_SCHEMES;
  my $class = ref $self || $self;
  croak "$class refuses to fetch image URL "
    . ( defined $scheme ? "with scheme '$scheme'" : 'without a scheme' )
    . " (only http/https; use Content::Image->from_file for local files)";
}

# Decodes a data: URL image in process, no I/O.
sub _inline_data_url {
  my ($self) = @_;
  require URI;
  my $uri = URI->new( $self->url );
  my $bytes = $uri->data;
  croak "ensure_base64: cannot decode data: URL" unless defined $bytes;
  $self->base64( encode_base64( $bytes, '' ) );
  unless ( $self->has_media_type ) {
    ( my $ct = $uri->media_type // '' ) =~ s/;.*$//;
    $self->media_type($ct) if length $ct;
  }
  return $self->base64;
}

# detail => ... out of a from_* constructor's %extra; undef means unset.
sub _detail_arg {
  my (%extra) = @_;
  return defined $extra{detail} ? ( detail => $extra{detail} ) : ();
}

my %EXT_MAP = (
  jpg  => 'image/jpeg',
  jpeg => 'image/jpeg',
  png  => 'image/png',
  gif  => 'image/gif',
  webp => 'image/webp',
  bmp  => 'image/bmp',
  svg  => 'image/svg+xml',
  heic => 'image/heic',
  heif => 'image/heif',
);

sub _sniff_media_type {
  my ($path) = @_;
  return undef unless defined $path;
  ( my $clean = $path ) =~ s/[?#].*$//;
  if ( $clean =~ /\.([a-zA-Z0-9]+)$/ ) {
    return $EXT_MAP{ lc $1 };
  }
  return undef;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Content::Image - Canonical image content block with cross-provider conversion

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    use Langertha::Content::Image;

    # From a remote URL
    my $img = Langertha::Content::Image->from_url('https://example.com/cat.jpg');

    # From a local file (media_type sniffed from extension)
    my $img = Langertha::Content::Image->from_file('/tmp/cat.png');

    # From raw bytes
    my $img = Langertha::Content::Image->from_data($bytes, media_type => 'image/jpeg');

    # From an existing base64 string
    my $img = Langertha::Content::Image->from_base64($b64, media_type => 'image/png');

    # Embed in a chat message — Langertha::Role::Chat converts per engine
    my $response = $engine->simple_chat_f({
        role    => 'user',
        content => [ 'What is in this image?', $img ],
    });

=head1 DESCRIPTION

Provider-neutral image block. Carries either a remote URL, a base64 payload,
or both, plus an IANA C<media_type>. Serializes to these vision-chat wire
formats:

=over

=item * OpenAI chat completions — C<{ type => 'image_url', image_url => { url => ... } }>

=item * Anthropic messages — C<{ type => 'image', source => { type => 'url' | 'base64', ... } }>

=item * Google Gemini — C<{ inline_data => { mime_type => ..., data => <base64> } }>

=item * Open-Responses — C<{ type => 'input_image', image_url => <url or data: URL> }>

=item * Ollama native — the raw base64 string, for the message C<images> array

=item * LM Studio native — C<{ type => 'image', data_url => <data: URL> }>

=back

The optional L</detail> hint goes out only on the two wires that have the
field (OpenAI chat completions and Open-Responses) and is ignored elsewhere.
L</TO_JSON> gives a compact description for logs and traces, never the
payload.

Gemini, Ollama native and LM Studio native require inline data, so their
serializers transparently download a remote URL on first call (cached on the
object). Engines whose OpenAI-compatible endpoint rejects remote image URLs
get the same treatment through C<< to_openai( inline => 1 ) >>. On the C<_f>
methods of L<Langertha::Role::Chat> the download happens earlier, through the
engine's async HTTP backend (L</ensure_base64_f>), so the serializers find the
payload cached and do not block the event loop.

=head2 url

Remote HTTP(S) URL of the image. May be passed through directly (OpenAI,
Anthropic) or auto-downloaded and base64-encoded (Gemini).

=head2 base64

The base64-encoded image payload (no C<data:> URL prefix). Can be supplied
at construction, or populated lazily when a provider that requires inline
data (Gemini) is targeted.

=head2 media_type

IANA media type (C<image/jpeg>, C<image/png>, C<image/gif>, C<image/webp>).
Required for base64 payloads on Anthropic and Gemini. Sniffed from the file
extension by C<from_file> and from the URL path by C<from_url>.

=head2 detail

Optional image-detail hint, a non-empty string. The known values are C<low>,
C<high> and C<auto>; any other value is sent unchanged, and the provider
decides whether it takes it. Unset by default, and
then no C<detail> field goes on any wire. When set, L</to_openai> sends it as
C<image_url.detail> and L</to_responses> as C<input_image.detail>; the other
serializers ignore it, because their wires have no such field. Every C<from_*>
constructor takes it:

    my $img = Langertha::Content::Image->from_url($url, detail => 'low');

=head2 from_url

    my $img = Langertha::Content::Image->from_url($url);
    my $img = Langertha::Content::Image->from_url($url, media_type => 'image/jpeg');

Builds an image block referencing a remote URL. Media type is sniffed from
the URL extension when not provided.

Only C<http>, C<https> and C<data:> URLs are accepted. Any other scheme
(C<file>, C<ftp>, C<gopher>, ...) croaks here, before any I/O, because the
engines that have to inline images would otherwise read it (a C<file:> URL
from a caller's message would send a server-local file to the provider). For
a local file use L</from_file>. See L</ensure_base64> for what the fetch does
not protect against.

=head2 from_file

    my $img = Langertha::Content::Image->from_file('/tmp/cat.png');

Reads a local file, base64-encodes it, and sniffs the media type from the
extension (unless C<media_type> is passed).

=head2 from_data

    my $img = Langertha::Content::Image->from_data($bytes, media_type => 'image/jpeg');

Builds an image block from raw bytes. C<media_type> is required.

=head2 from_base64

    my $img = Langertha::Content::Image->from_base64($b64, media_type => 'image/png');

Builds an image block from an existing base64 string.

=head2 ensure_base64

    my $b64 = $img->ensure_base64;
    my $b64 = $img->ensure_base64( timeout => 5 );
    my $b64 = $img->ensure_base64(
      max_bytes  => 5_000_000,
      url_filter => Langertha::Content::Image->deny_private_hosts,
    );

Returns the base64 payload, fetching the URL over HTTP if necessary.
Populates C<media_type> from the response C<Content-Type> header when the
image was URL-only. Caches the result on the object.

Only C<http> and C<https> URLs are fetched; a C<data:> URL is decoded locally.
Any other scheme croaks before any I/O:

    Langertha::Content::Image refuses to fetch image URL with scheme 'file'
    (only http/https; use Content::Image->from_file for local files)

A redirect to another scheme is not followed, and a fetch that ended on one
anyway is not stored.

C<max_bytes> caps the download, C<20971520> (20 MiB) by default; C<0> means no
cap. A C<Content-Length> over the cap stops the fetch before the body, and a
body that grows past it stops reading there. The cap holds for the decoded
size too: a body sent with a C<Content-Encoding> (C<gzip>, C<deflate>,
C<bzip2>) is inflated in blocks and refused once it passes the cap, and one in
any other encoding is refused as undecodable while a cap is set. Nothing is
stored, and the call croaks:

    Langertha::Content::Image image at https://... exceeds inline_image_max_bytes (20971520)

C<url_filter> is a code reference that decides which URLs may be fetched,
against server-side request forgery (SSRF) through image URLs from untrusted
input. It gets each URL as a L<URI> object and returns true to allow it. It
runs on the image URL before any I/O, and again on every redirect hop before
that hop is requested. Without it, the default, every C<http> and C<https> host
is fetched. A refused URL, or a filter that dies, croaks:

    Langertha::Content::Image refuses to fetch image URL http://10.0.0.5/x.png:
    rejected by inline_image_url_filter

L</deny_private_hosts> builds a ready-made filter.
L<Langertha::Role::Chat> passes the engine's
L<Langertha::Role::Chat/inline_image_max_bytes> and
L<Langertha::Role::Chat/inline_image_url_filter> as these two options.

The fetch is a blocking L<LWP::UserAgent> GET that gives up after
C<timeout> seconds of inactivity, C<30> by default. When
L<Langertha::Role::Chat> builds a request it passes the engine's
L<Langertha::Role::Chat/inline_image_fetch_timeout>. C<< timeout => 0 >> leaves
LWP's own default (180 seconds) in place, because LWP cannot run without a
timeout.

=head2 ensure_base64_f

    my $b64 = await $img->ensure_base64_f($http);
    my $b64 = await $img->ensure_base64_f( $http, max_bytes => ..., url_filter => ... );

The async L</ensure_base64>: returns a L<Future> of the base64 payload and
fetches the URL through C<$http>, any client that answers the async
C<do_request> contract (L<Langertha::Role::AsyncHTTP>), instead of a blocking
L<LWP::UserAgent>. A transport error or a non-success status fails the Future.
The scheme rules of L</ensure_base64> apply unchanged: a non-HTTP(S) URL fails
the Future before any request, a C<data:> URL is decoded locally, and on the
synchronous LWP fallback (L<Langertha::Request::SyncHTTP>) the fetch runs over
a copy of its user agent restricted to C<http> and C<https>.

C<max_bytes> and C<url_filter> work as on L</ensure_base64> and fail the
Future with the same text. On L<Net::Async::HTTP> the body is counted as it
arrives and the request is abandoned (its connection closed) once it passes
the cap, and redirects (up to 7) are followed one hop at a time, so the filter
sees each hop before it is requested. On the LWP fallback the copy of its user
agent carries the cap and the filter. Any other client follows redirects on its
own: there the filter sees the hops only after the fetch, and the payload of a
fetch with a refused hop is not stored; the cap is checked on the finished
body.
The C<_f> methods of L<Langertha::Role::Chat> call it with the engine's backend
for every URL image the engine has to inline, before the request is built.

=head2 deny_private_hosts

    my $engine = Langertha::Engine::Gemini->new(
      api_key                 => $key,
      inline_image_url_filter => Langertha::Content::Image->deny_private_hosts,
    );

    # With a resolver of your own (tests, a caching resolver):
    my $filter = Langertha::Content::Image->deny_private_hosts(
      resolver => sub { my ($host) = @_; return @ip_addresses },
    );

Returns a URL filter for L</ensure_base64>'s C<url_filter> (and the engine's
L<Langertha::Role::Chat/inline_image_url_filter>) that refuses hosts on
internal networks. It resolves the URL's host and refuses it when any address
it resolves to is one of:

=over

=item * IPv4 C<0.0.0.0/8> (this host), C<127.0.0.0/8> (loopback), C<10.0.0.0/8>,
C<172.16.0.0/12>, C<192.168.0.0/16> (RFC 1918), C<100.64.0.0/10> (carrier-grade
NAT), C<169.254.0.0/16> (link-local, including the cloud metadata address
C<169.254.169.254>), C<192.0.0.0/24> (IETF protocol assignments, including the
NAT64 discovery addresses), C<198.18.0.0/15> (benchmarking), C<224.0.0.0/3>
(multicast, C<240.0.0.0/4> reserved, C<255.255.255.255> broadcast)

=item * IPv6 C<::/96> (unspecified, loopback C<::1>, IPv4-compatible),
C<fe80::/10> (link-local), C<fec0::/10> (site-local), C<fc00::/7> (unique local,
including the AWS metadata address C<fd00:ec2::254>), C<ff00::/8> (multicast)

=item * an IPv6 address that carries an IPv4 address in the list above:
IPv4-mapped C<::ffff:a.b.c.d>, SIIT C<::ffff:0:a.b.c.d>, NAT64 C<64:ff9b::a.b.c.d>
and C<64:ff9b:1::a.b.c.d>, and 6to4 C<2002:AABB:CCDD::/48>. Any other address in
the local-use NAT64 prefix C<64:ff9b:1::/48> is refused, since it does not say
where its IPv4 address sits.

=item * Teredo C<2001:0000::/32> (RFC 4380): its client IPv4 is embedded
I<obfuscated> (bit-inverted) in the low 32 bits, so unlike 6to4 and NAT64 it
cannot be re-checked as a plain address — the whole prefix is refused outright.
A non-Teredo C<2001::/16> address (C<2001:db8::>, C<2001:4860::>, ...) is not
matched and passes.

=back

A host that does not resolve, and a URL without a host, are refused too.

The default resolver is the system's C<getaddrinfo> (L<Socket>); an IP literal
is not looked up. The lookup blocks, also on the C<_f> paths, where it holds
the event loop for its duration. C<resolver> replaces it: a code reference
that gets the host name and returns its addresses as strings.

B<DNS rebinding:> the host is resolved here, before the HTTP client connects,
and the client resolves it again on its own. A name whose DNS answer changes
between the two lookups (a short TTL pointing first at a public address, then
at C<127.0.0.1>) passes the filter and still reaches the internal address.
The filter stops URLs that name or resolve to an internal address; for a
guarantee against rebinding, fetch through an egress proxy or firewall that
enforces the same rule on the connection itself.

=head2 data_url

    my $uri = $img->data_url;   # data:image/png;base64,...

Returns the image as a C<data:> URL, fetching a URL-only image first (see
L</ensure_base64>). The media type falls back to C<application/octet-stream>.

=head2 to_openai

    my $block = $img->to_openai;
    # { type => 'image_url', image_url => { url => ... } }
    my $block = $img->to_openai( inline => 1 );   # always a data: URL

Serializes to the OpenAI chat-completions image block. Uses the URL when
available, otherwise emits a C<data:> URL from the base64 payload. With
C<< inline => 1 >> it always emits the C<data:> URL, fetching a URL-only image
first; L<Langertha::Role::Chat> passes it for engines whose endpoint rejects
remote image URLs. A set L</detail> goes out as C<image_url.detail>.

=head2 to_responses

    my $block = $img->to_responses;
    # { type => 'input_image', image_url => 'https://...' }   (or a data: URL)

Serializes to the Open-Responses C<input_image> part (OpenAI C</v1/responses>,
Perplexity C</v1/agent>). C<image_url> is a plain string, not an object: the
URL when available, otherwise a C<data:> URL. Takes C<< inline => 1 >> like
L</to_openai>. A set L</detail> goes out as the part's C<detail> field.

=head2 to_ollama

    my $b64 = $img->to_ollama;

Returns the raw base64 payload (no C<data:> prefix) for one entry of the
Ollama native C</api/chat> message C<images> array. Fetches a URL-only image
first, because that wire takes no image URLs.

=head2 to_lmstudio

    my $item = $img->to_lmstudio;
    # { type => 'image', data_url => 'data:image/png;base64,...' }

Serializes to an LM Studio native C</api/v1/chat> C<input> image item. That
wire takes only base64 data URLs, so a URL-only image is fetched first.

=head2 to_anthropic

    my $block = $img->to_anthropic;
    # { type => 'image', source => { type => 'url', url => ... } }
    # or
    # { type => 'image', source => { type => 'base64', media_type => ..., data => ... } }

Serializes to the Anthropic messages image block. Prefers a URL source
when available; otherwise emits an inline base64 source (C<media_type>
required).

=head2 to_gemini

    my $block = $img->to_gemini;
    # { inline_data => { mime_type => ..., data => <base64> } }

Serializes to the Gemini C<inlineData> part. Auto-downloads URL-only
images because Gemini has no URL-fetching equivalent.

=head2 TO_JSON

    my $json = JSON::MaybeXS->new( convert_blessed => 1 )
      ->encode([ { role => 'user', content => [ 'What is this?', $img ] } ]);
    # ... {"bytes":48213,"media_type":"image/png","source":"base64","type":"image"} ...

Serialization hook for JSON encoders configured with C<convert_blessed> (the
engine's own L<Langertha::Role::JSON/json> is one), so a message array holding
images can be written to a log or a trace. Returns a compact description,
B<never the image data>:

    { type       => 'image',
      source     => 'url' | 'base64',
      url        => ...,     # only for a URL image
      media_type => ...,     # when known
      detail     => ...,     # when set
      bytes      => ... }    # decoded payload size, when base64 is present

C<source> is C<url> for an image built from a URL (even after
L</ensure_base64> has fetched it; C<bytes> then gives the fetched size), and
C<base64> otherwise. A C<data:> URL passed as C<url> is reported as
C<base64> without the URL, because it I<is> the payload. This is not a wire
format: request bodies are built by the C<to_*> serializers, never through
C<TO_JSON>.

=head1 SEE ALSO

=over

=item * L<Langertha::Content> - Base role this class implements

=item * L<Langertha::Role::Chat> - Normalizes content blocks per engine during C<chat_messages>

=item * L<Langertha::ToolChoice> - Sibling value object for tool_choice normalization

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
