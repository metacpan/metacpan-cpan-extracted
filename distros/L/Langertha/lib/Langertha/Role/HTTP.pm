package Langertha::Role::HTTP;
# ABSTRACT: Role for HTTP APIs
our $VERSION = '0.503';
use Moose::Role;

use Carp qw( croak );
use Scalar::Util ();
use Log::Any qw( $log );
use Time::HiRes qw( gettimeofday tv_interval );
use URI;
use LWP::UserAgent;
use Encode ();
use File::Spec;

use Langertha::Request::HTTP;
use HTTP::Request::Common;

requires qw(
  json
);

has url => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_url',
);


has connect_address => (
  is => 'ro',
  isa => 'Maybe[Str]',
  trigger => sub { $_[0]->_check_connect_address },
);


# The host connect_address pins (lower-cased), or undef without a pin.
sub _connect_host {
  my ($self) = @_;
  return undef unless defined $self->connect_address;
  # The accessor, not has_url: many engines build a default url lazily.
  my $url = $self->url;
  return undef unless defined $url;
  my $uri = URI->new($url);
  return undef unless $uri->can('host') && defined $uri->host && length $uri->host;
  return lc $uri->host;
}

# ( connect_address => ... ) for an engine derived from this one that will use
# $url, when $url is on the pinned host; else nothing (karr k375).
sub _connect_address_for {
  my ( $self, $url ) = @_;
  my $host = $self->_connect_host;
  return () unless defined $host && defined $url;
  my $uri = URI->new("$url");
  return () unless $uri->can('host') && lc( $uri->host // '' ) eq $host;
  return ( connect_address => $self->connect_address );
}

# Runs once, after construction set every attribute (Moose triggers do).
sub _check_connect_address {
  my ($self) = @_;
  my $address = $self->connect_address;
  return unless defined $address;
  require Langertha::HTTP::UserAgent;
  my $error = Langertha::HTTP::UserAgent::connect_address_error($address);
  croak "".(ref $self).": $error" if $error;
  croak "".(ref $self).": connect_address needs a url with an http or https host to pin"
    unless defined $self->_connect_host && ( URI->new( $self->url )->scheme // '' ) =~ /\Ahttps?\z/i;
  if ( $self->has_user_agent and my $why = $self->_connect_pin_error( $self->user_agent ) ) {
    croak "".(ref $self).": $why";
  }
  return;
}

# Why $ua would not pin this engine's requests, or undef when it does.
sub _connect_pin_error {
  my ( $self, $ua ) = @_;
  my $host    = $self->_connect_host;
  my $address = $self->connect_address;
  my $pinned = Scalar::Util::blessed($ua) && $ua->isa('Langertha::HTTP::UserAgent')
    && defined $ua->connect_address && defined $ua->connect_host
    && lc $ua->connect_host eq $host
    && Langertha::HTTP::UserAgent::same_address( $ua->connect_address, $address );
  return undef if $pinned;
  return "connect_address $address cannot be applied through the user_agent passed in ("
    . ( Scalar::Util::blessed($ua) // ref($ua) || 'not an object' ) . '); pass a Langertha::HTTP::UserAgent built with'
    . " connect_host => '$host', connect_address => '$address', or let the engine build its user_agent";
}

has response_max_bytes => (
  is => 'ro',
  isa => 'Int',
  default => 268_435_456,   # 256 MiB
);


sub generate_json_body {
  my ( $self, %args ) = @_;
  return $self->json->encode({ %args });
}


our $boundary = 'XyXLaXyXngXyXerXyXthXyXaXyX';

# Character strings go on the wire as UTF-8, like the JSON body (json->utf8).
sub _multipart_text {
  my ( $value ) = @_;
  return $value unless defined $value;
  return Encode::encode( 'UTF-8', "$value" );
}

# A filename is path-like: a decoded (UTF-8 flagged) name is encoded, an
# undecoded one is already the filesystem's bytes and passes unchanged.
# RFC 7578 section 4.2: the name goes into filename="..." as raw UTF-8 (what
# browsers and the OpenAI SDKs send), never as filename*.
sub _multipart_filename {
  my ( $name ) = @_;
  return $name unless defined $name && utf8::is_utf8($name);
  return Encode::encode( 'UTF-8', $name );
}

sub generate_multipart_body {
  my ( $self, $req, %args ) = @_;
  my @formdata;
  for my $key ( sort { $a cmp $b } keys %args ) {
    my $value = $args{$key};
    if ( ref $value eq 'ARRAY' && $key =~ /\[\]\z/ ) {
      # Multi-valued field (OpenAI: timestamp_granularities[], include[]):
      # one part per element, in order. -- karr k286
      push @formdata, map { ( $key, _multipart_text($_) ) } @$value;
    }
    elsif ( ref $value eq 'HASH' && ref $value->{repeated} eq 'ARRAY' ) {
      # Multi-valued field under the key as given, no [] (Mistral:
      # timestamp_granularities, context_bias). Explicit marker, because a
      # plain-key ArrayRef is a file spec. -- karr k315
      push @formdata, map { ( $key, _multipart_text($_) ) } @{ $value->{repeated} };
    }
    elsif ( ref $value eq 'ARRAY' ) {
      # File spec, HTTP::Request::Common form_data convention:
      # [ $path, $filename, @headers ] or [ undef, $filename, Content => $bytes ].
      my ( $file, $filename, @headers ) = @$value;
      $filename = ( File::Spec->splitpath("$file") )[-1]
        if !defined $filename && defined $file;
      push @formdata, $key, [ $file, _multipart_filename($filename), @headers ];
    }
    elsif ( ref $value ) {
      push @formdata, $key, $value;
    }
    else {
      push @formdata, $key, _multipart_text($value);
    }
  }
  return HTTP::Request::Common::form_data(\@formdata, $boundary, $req);
}


sub generate_http_request {
  my ( $self, $method, $url, $response_call, %args ) = @_;
  my $uri = URI->new($url);
  my $content_type = (delete $args{content_type}||"");
  my $userinfo = $uri->userinfo;
  $uri->userinfo(undef) if $userinfo;
  my $headers = [
    # multipart gets its Content-Type below, from the boundary the body used
    $content_type eq 'multipart/form-data' ? ()
      : ( 'Content-Type', 'application/json; charset=utf-8' )
  ];
  my $request = Langertha::Request::HTTP->new(
    http => [ uc($method), $uri, $headers, ( scalar %args > 0 ?
      ( !$content_type or $content_type eq 'application/json' )
        ? $self->generate_json_body(%args)
          : ()
      : ()
    ) ],
    request_source => $self,
    response_call => $response_call,
  );
  if ($content_type and $content_type eq 'multipart/form-data') {
    my ( $body, $used_boundary ) = $self->generate_multipart_body($request, %args);
    $request->header( 'Content-Type' => 'multipart/form-data; boundary="'.$used_boundary.'"' );
    $request->content($body);
  }
  if ($userinfo) {
    my ( $user, $pass ) = split(/:/, $userinfo);
    if ($user and $pass) {
      $request->authorization_basic($user, $pass);
    }
  }
  $self->update_request($request) if $self->can('update_request');
  return $request;
}


our $error_body_max_length = 500;

# A response body with its Content-Encoding undone, but bounded (karr k346,
# reusing the k342 inflate path): decoded_content inflates a Content-Encoding
# with no size limit, so a hostile or broken endpoint could inflate a tiny
# compressed body to gigabytes in memory. Inflate in bounded blocks through the
# shared Langertha::HTTP::BoundedDecode and refuse a body whose decoded size
# passes response_max_bytes; then run the charset step the same as
# decoded_content, on the already-bounded bytes (a throwaway response carries
# them without a Content-Encoding, so no second inflate). Any %opt
# (default_charset => ...) reaches that charset step. response_max_bytes => 0
# removes the cap and decodes as decoded_content did. An uncompressed body just
# passes through the inflate and gets the charset step.
sub _bounded_decoded_content {
  my ( $self, $response, %opt ) = @_;
  my $max = $self->response_max_bytes;
  return $response->decoded_content(%opt) unless $max;
  require Langertha::HTTP::BoundedDecode;
  require HTTP::Response;
  my $bytes = Langertha::HTTP::BoundedDecode::decode_within(
    $response->content, scalar $response->header('Content-Encoding'), $max, {
      too_big     => sub { croak "".(ref $self)." response body exceeds response_max_bytes ($_[0])" },
      undecodable => sub { croak "".(ref $self)." response body Content-Encoding '$_[0]' cannot be decoded" },
      # An encoding this bounded decoder cannot inflate in blocks (br, zstd, ...)
      # is refused, not passed to decoded_content: falling through to the
      # unbounded decode would reopen the bomb for that encoding. This is a
      # deliberate safety choice -- such a body IS decodable by HTTP::Message,
      # it just cannot be bounded here (karr k346).
      unbounded_encoding => sub { croak "".(ref $self)." response body Content-Encoding '$_[0]'"
        . " cannot be decoded within response_max_bytes ($max)" },
    } );
  my $decoded = HTTP::Response->new(200);
  my $type = $response->header('Content-Type');
  $decoded->header( 'Content-Type' => $type ) if defined $type;
  $decoded->content_ref( \$bytes );
  return $decoded->decoded_content(%opt);
}


sub _error_response_body {
  my ( $self, $response ) = @_;
  my $body = eval { $self->_bounded_decoded_content($response) };
  $body = $response->content unless defined $body && length $body;
  return '' unless defined $body && length $body;
  $body =~ s/\s+/ /g;
  $body =~ s/\A\s+//;
  $body =~ s/\s+\z//;
  return '' unless length $body;
  if ( length($body) > $error_body_max_length ) {
    $body = substr($body, 0, $error_body_max_length) . '...';
  }
  return $body;
}

# The status line of a failed response, with the wait the provider asked for
# as seconds: "429 Too Many Requests (retry after 8s)" (karr k300). Resolved
# as RateLimit->retry_after resolves it, retry-after-ms first (karr k312).
sub _failed_status_line {
  my ( $self, $response ) = @_;
  require Langertha::RateLimit;
  my %raw = Langertha::RateLimit::_collect_headers($response);
  my $wait = Langertha::RateLimit::_resolve_retry_after( \%raw );
  return $response->status_line unless defined $wait;
  if ( $wait != int $wait ) {
    $wait = sprintf( '%.3f', $wait );
    $wait =~ s/\.?0+\z//;
  }
  return $response->status_line . " (retry after ${wait}s)";
}

# The one error text of a failed request, whichever backend ran it: the sync
# croak and every async die use it, so a caller reads the same message
# everywhere (ADR 0027 parity, karr k312). $what is "request", "streaming
# request" or "tool chat request".
sub _request_failed_message {
  my ( $self, $response, $what ) = @_;
  my $body = $self->_error_response_body($response);
  return "".(ref $self)." $what failed: ".$self->_failed_status_line($response)
    .( length $body ? " - ".$body : "" );
}

# "message (code)" of an `error` a provider put into a 200 body: an object
# with message/code, the same nested once more under `error`, or a plain
# string; undef when there is none. Shared by the chat parsers that croak on
# such a body (karr k301, k311).
sub _body_error_text {
  my ( $self, $err ) = @_;
  return undef unless defined $err;
  $err = $err->{error} if ref $err eq 'HASH' && ref $err->{error} eq 'HASH';
  return "$err" unless ref $err eq 'HASH';
  my $message = defined $err->{message} && !ref $err->{message} ? $err->{message} : 'no error message';
  my $code = defined $err->{code} && !ref $err->{code} ? " ($err->{code})" : '';
  return "$message$code";
}

sub parse_response {
  my ( $self, $response ) = @_;
  # Every response, error or not, replaces the engine's rate limit first: a
  # 429's remaining/reset/retry-after is what a caller backs off from (k300).
  $self->_update_rate_limit($response) if $self->can('_update_rate_limit');
  unless ($response->is_success) {
    $log->errorf("[%s] HTTP %s", ref $self, $response->status_line);
    croak $self->_request_failed_message( $response, 'request' );
  }
  # Bounded (karr k346) and computed only when trace is on: decoded_content
  # inflates a Content-Encoding unbounded, and this ran on every response. A
  # body over response_max_bytes (a bomb, or a legitimately huge response) must
  # not turn a trace line into a fatal, so the bound croak is caught here.
  if ( $log->is_trace ) {
    my $body = eval { $self->_bounded_decoded_content($response) };
    $log->tracef("[%s] Response: %s", ref $self,
      defined $body ? $body : $response->status_line);
  }
  # A 200 that is not JSON (a proxy's HTML page, a truncated body) names the
  # engine and shows the body, like the non-2xx path above (k290).
  my $data;
  {
    local $@;
    unless ( eval { $data = $self->json->decode($response->content); 1 } ) {
      my $body = $self->_error_response_body($response);
      croak "".(ref $self)." response is not valid JSON"
        .( length $body ? ": ".$body : " (empty body)" );
    }
  }
  return $data;
}


has user_agent_timeout => (
  isa => 'Int',
  is => 'ro',
  predicate => 'has_user_agent_timeout',
);


has user_agent_agent => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);
sub _build_user_agent_agent {
  my ( $self ) = @_;
  return "".(ref $self)."";
}


has user_agent => (
  isa => 'LWP::UserAgent',
  is => 'ro',
  lazy_build => 1,
);
sub _build_user_agent {
  my ( $self ) = @_;
  require Langertha::HTTP::UserAgent;
  return Langertha::HTTP::UserAgent->new(
    agent => $self->user_agent_agent,
    $self->has_user_agent_timeout ? ( timeout => $self->user_agent_timeout ) : (),
    defined $self->connect_address
      ? ( connect_host => $self->_connect_host, connect_address => $self->connect_address ) : (),
  );
}


sub execute_streaming_request {
  my ($self, $request, $chunk_callback) = @_;

  croak "execute_streaming_request requires Langertha::Role::Streaming"
    unless $self->does('Langertha::Role::Streaming');

  my $t0 = [gettimeofday];
  my $response = $self->user_agent->request($request);

  $self->_update_rate_limit($response) if $self->can('_update_rate_limit');
  unless ($response->is_success) {
    croak $self->_request_failed_message( $response, 'streaming request' );
  }

  my $chunks = $self->process_stream_data($response->content, $chunk_callback);
  my $total_seconds = tv_interval($t0);

  # This path reads the whole stream with one blocking LWP request before
  # process_stream_data runs, so a true TTFT (time to first token) is
  # not observable here; only end-to-end wall-clock. Consumers that need
  # TTFT should use L<Langertha::Role::Chat/simple_chat_stream_realtime_f>,
  # which delivers chunks as they arrive on either backend of
  # L<Langertha::Role::AsyncHTTP> (Net::Async::HTTP, or LWP's content
  # callback on the synchronous fallback).
  return ($chunks, { total_seconds => $total_seconds });
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::HTTP - Role for HTTP APIs

=head1 VERSION

version 0.503

=head2 url

Base URL for API requests. Optional — many engines hard-code their default URL
internally and only require this attribute to be set when pointing at a custom
or self-hosted endpoint.

=head2 connect_address

    my $engine = Langertha::Engine::OpenAI->new(
      url             => 'https://llm.example.com/v1',
      api_key         => $key,
      connect_address => '203.0.113.7',   # what llm.example.com resolved to when you checked it
    );

An IPv4 or IPv6 address literal (no brackets, port or scope; C<undef> means
none). When set, every request the engine sends to the B<host of its
L</url>> opens its TCP connection to this address instead of resolving the
name again. The request still names the host everywhere else: the C<Host>
header, and for C<https> the TLS SNI and the name the server certificate is
verified against. Certificate verification itself is configured as it would
be without the pin. This is for a caller that resolved the host and checked
its addresses against a policy (no loopback, private or cloud-metadata
address, say): without the pin the name is resolved again at connect time,
and a DNS answer that changed in between (DNS rebinding) would send the
request somewhere that was never checked (karr k375).

It covers every request core sends to that host, on every backend core
builds: the synchronous methods and the synchronous fallback of the C<_f>
methods through the engine's L</user_agent> (a L<Langertha::HTTP::UserAgent>
built with the pin), and the L<Net::Async::HTTP> backend of the C<_f>
methods, streaming included (L<Langertha::Role::AsyncHTTP/async_request_f>).
That includes C<list_models>, the capability probe and the metrics scrape,
which go to the same host. Requests to other hosts (a Langfuse endpoint, say)
are not pinned. B<Not pinned either>: image URLs fetched for inlining
(L<Langertha::Content::Image/ensure_base64>, C<ensure_base64_f>) resolve
their host again, even when it is the pinned host; only on the synchronous
fallback, where the fetch runs through a copy of the engine's agent, is a
same-host image pinned. Vet image URLs with
L<Langertha::Role::Chat/inline_image_url_filter> if that matters.

Redirects: a redirect from the pinned host to another host is B<not
followed> on any backend; the 3xx is returned with a C<Client-Warning>
(C<redirect not followed: Langertha::HTTP::Redirect: connect_address pins
...>). The address was checked for this host only, and following would
resolve the new host afresh. A redirect on the same host (another port or
path) stays pinned. Configure the URL the redirect points to, with its own
checked address, instead.

Before a request is written the connection is checked, new or reused: its
peer must be the pinned address and, over C<https>, the session's
certificate chain must have verified and the certificate must be for the
host. Where verification is switched off the check follows: on the
synchronous side both parts apply when LWP's C<verify_hostname> is on (its
default); on L<Net::Async::HTTP> C<< SSL_verify_mode => 0 >> (on the client
or the request) skips both, C<< SSL_verifycn_scheme => 'none' >> the name
part. A connection that fails the check is not used (a C<500> response on the
synchronous side, a failed future with category C<connect_address> on
L<Net::Async::HTTP>). This matters for connection reuse:
L<Net::Async::HTTP> pools connections by address and port, so two engines
pinning different names to one address on a B<shared> client would
otherwise share a TLS session verified for only one of them. With the check,
the request of the engine whose name the pooled connection was not verified
for B<fails> (it is not retried on a new connection); give such engines a
client each. The refused connection is closed once idle, so later requests
get a fresh one. Likewise an LWP C<conn_cache> shared with another agent
could hand over a socket that agent opened elsewhere, or without
verification; such a socket is refused.

What the pin cannot do is refused rather than silently skipped:

=over 4

=item * With a L</user_agent> passed in, it must be a
L<Langertha::HTTP::UserAgent> built with the same pin (C<< connect_host =>
<host of url>, connect_address => ... >>); anything else croaks at
construction, because the synchronous requests go straight to that agent.

=item * An injected C<_async_http> client that is neither a
L<Net::Async::HTTP> nor the synchronous shim over a correctly pinned agent
fails every request to the pinned host (the future fails with C<...
connect_address ... cannot be applied ...>). So does a L<Net::Async::HTTP>
client configured with a C<proxy_host> or C<proxy_path>, and on the
synchronous side a request that LWP would send through a proxy (a C<500>
response): a proxy resolves the name itself. Through a SOCKS proxy the
connection's peer is the proxy, so the peer check refuses it.

=back

Engines derived from this one carry the pin while their URL is on the same
host (L<Langertha::Engine::OpenAI/whisper>, C<< Ollama->openai >>, C<<
LMStudio->openai >> / C<< ->anthropic >>, also with a C<url> of your own on
that host); on another host they get none.

=head2 response_max_bytes

A sanity ceiling, in bytes, on the B<decoded> size of a response body. Default
C<268435456> (256 MiB); C<0> removes the cap. Decoding a C<Content-Encoding>
(C<gzip>, C<deflate>, C<bzip2>) has no size bound of its own, so a hostile or
broken endpoint (a self-hosted C</metrics>, a gateway) could make a small
compressed body expand to gigabytes in memory — a decompression bomb. A body
whose decoded size passes this ceiling is refused with C<< <engine class>
response body exceeds response_max_bytes (<n>) >>. It is a generous ceiling for
genuinely large provider responses, not a tight limit, and an uncompressed body
under it is never affected.

Where the bound is applied depends on the backend, because both must be covered:

=over 4

=item * On the synchronous L<LWP::UserAgent> path (and injected clients that do
not decode) the still-encoded body is inflated in bounded blocks when it is read
(L</_bounded_decoded_content>, via L<Langertha::HTTP::BoundedDecode>, shared with
the inline-image fetch of L<Langertha::Content::Image>).

=item * On L<Net::Async::HTTP> the client inflates the body itself while it
streams (moving C<Content-Encoding> to C<X-Original-Content-Encoding>), so the
decoded bytes are counted as they arrive and the request is aborted past the
ceiling (L<Langertha::Role::AsyncHTTP>).

=back

This covers the non-streaming provider and metrics paths: L</parse_response>'s
trace and error body, C<transcription_result>, C<poll_metrics_f>, and the
non-streaming C<async_request_f>. A true stream (SSE / NDJSON, an C<on_header>
request) is unbounded by design and not affected. An encoding the bounded
decoder cannot inflate in blocks (C<br>, C<zstd>) is refused rather than decoded
unbounded.

=head2 generate_json_body

    my $body = $engine->generate_json_body(%args);

Encodes C<%args> as a JSON string using the engine's L<Langertha::Role::JSON/json>
instance. Used internally when building C<application/json> request bodies.

=head2 generate_multipart_body

    my ( $body, $boundary ) = $engine->generate_multipart_body($request, %args);

Encodes C<%args> as a C<multipart/form-data> body (fields sorted by name) and
returns it together with the boundary it used. The boundary is
C<$Langertha::Role::HTTP::boundary> unless a part contains it, in which case
L<HTTP::Request::Common> picks another one; the C<Content-Type> header must use
the returned value (L</generate_http_request> does). Used internally when the
OpenAPI spec specifies C<multipart/form-data> (e.g. audio upload endpoints).

Values are read as follows:

=over

=item * A plain scalar is a text field. It is a character string and is sent
UTF-8 encoded, the same as a value in a JSON body.

=item * An ArrayRef under a key ending in C<[]> (C<timestamp_granularities[]>,
C<include[]>) is a multi-valued field: one text part per element, each
under the C<[]> key (the OpenAI and Groq form).

=item * C<< { repeated => \@values } >> is a multi-valued field sent as one
text part per element under the key exactly as given, with no C<[]> (the form
Mistral reads: C<< timestamp_granularities => { repeated => ['segment'] } >>).
The marker is explicit because an ArrayRef under a plain key is a file part.

=item * Any other ArrayRef is a file part in the L<HTTP::Request::Common>
C<form_data> form: C<[ $path ]>, C<[ $path, $filename, @headers ]>, or
C<< [ undef, $filename, Content => $bytes, @headers ] >> for in-memory content.
The filename defaults to the basename of C<$path>. A decoded (character)
filename is sent UTF-8 encoded; an undecoded one is taken as the filesystem's
bytes and sent unchanged, as raw UTF-8 in C<filename="..."> (RFC 7578).

=back

=head2 generate_http_request

    my $request = $engine->generate_http_request(
        $method, $url, $response_call, %args
    );

Low-level HTTP request builder. Creates a L<Langertha::Request::HTTP> object
with the appropriate headers and body encoding (JSON or multipart). Calls the
engine's C<update_request> hook if it exists, allowing engines to inject
authentication headers. If the URL contains C<user:password> userinfo, HTTP
Basic authentication is set automatically.

=head2 _bounded_decoded_content

    my $body = $engine->_bounded_decoded_content($http_response);
    my $text = $engine->_bounded_decoded_content($http_response, default_charset => 'UTF-8');

Like L<HTTP::Message/decoded_content>, but the C<Content-Encoding> step is
bounded by L</response_max_bytes> (see there), so a decompression bomb is
refused instead of inflated into memory. C<%opt> passes to the charset step.
Used by L</parse_response>, C<transcription_result> and C<poll_metrics_f>.

=head2 parse_response

    my $data = $engine->parse_response($http_response);

Decodes a successful L<HTTP::Response> body as JSON and returns the data
structure. On failure croaks with the HTTP status line, and appends the
provider's response body (whitespace-collapsed and truncated to
C<$error_body_max_length> characters) so the real cause — e.g. a provider
JSON error object — is visible in the croak message; when the response sent a
C<Retry-After> or C<retry-after-ms>, the status line is followed by
C<(retry after Ns)> (the value of L<Langertha::RateLimit/retry_after>). The
async paths (C<chat_f>, C<simple_chat_f>, C<chat_stream_realtime_f>,
C<chat_with_tools_f>) fail with exactly this text on every backend. If the
engine supports rate limiting, it records the rate limit headers via
C<_update_rate_limit> first, for an error response too, so
L<Langertha::Engine::Remote/rate_limit> describes the failed response after
the croak (and is cleared when the response carried none). A successful response whose body is not JSON croaks with
C<< <engine class> response is not valid JSON: <body> >> (the body shortened
the same way).

=head2 user_agent_timeout

Optional timeout in seconds for HTTP requests. The synchronous methods get it
through the L<LWP::UserAgent> (seconds without activity on the connection);
when not set, LWP's own default (180 seconds) applies there.

The C<_f> methods (and L<Langertha::Role::AsyncHTTP/async_request_f>) on the
L<Net::Async::HTTP> backend apply it as well: a plain request fails after this
many seconds in total, a streaming one after this many seconds without a byte
(a long stream that keeps delivering is not cut off). The Future then fails
with C<< <engine class>: request to <url> timed out after Ns >> (C<streaming
request ... without data (...)> for a stream), the URL without its query
string, and the Net::Async::HTTP category (C<timeout> / C<stall_timeout>) as
the second failure value. When not set, the async backend has B<no> timeout,
as before. The synchronous fallback uses the L<LWP::UserAgent>'s timeout; an
injected client that is not a L<Net::Async::HTTP> keeps its own.

=head2 user_agent_agent

The C<User-Agent> string sent with HTTP requests. Defaults to the engine's
class name.

=head2 user_agent

The L<LWP::UserAgent> instance used for synchronous HTTP requests (and by the
synchronous fallback of the C<_f> methods). Built lazily with
C<user_agent_agent> and C<user_agent_timeout> as a
L<Langertha::HTTP::UserAgent>, which follows redirects under
L<Langertha::HTTP::Redirect>: only C<GET>/C<HEAD>, never from C<https> to
C<http>, and to another origin without any credential (every header but the
representation ones is dropped, and a credential the request carried in its
query is removed from the new URL). C<http://host> to C<https://host> is
another origin too: a keyed GET behind an http-to-https redirect arrives
without its key and gets a 401, so configure the C<https> URL. A C<POST> is
never redirected, even if you add it to C<requests_redirectable>. A refused
redirect comes back as the 3xx with a C<Client-Warning> naming the reason. The
L<Net::Async::HTTP> backend follows the same policy
(L<Langertha::Role::AsyncHTTP/async_request_f>).

An agent passed in is used as it is, with its own redirect behaviour: a plain
L<LWP::UserAgent> clones the request with every header but C<Authorization>
(and keeps even that before LWP 6.83), so an C<x-api-key> or similar header
would reach whatever host a server redirects to. Pass a
L<Langertha::HTTP::UserAgent> (it takes the same arguments) to keep the policy.

With a L</connect_address> the built agent carries the pin
(C<connect_host> / C<connect_address> of L<Langertha::HTTP::UserAgent>); an
agent passed in must carry the same pin, or construction croaks.

=head2 execute_streaming_request

    my ($chunks, $timing) = $engine->execute_streaming_request($request, $chunk_callback);
    my ($chunks, $timing) = $engine->execute_streaming_request($request);

Executes a streaming HTTP request synchronously using L<LWP::UserAgent> and
delegates stream parsing to L<Langertha::Role::Streaming/process_stream_data>.
Requires the engine to also compose L<Langertha::Role::Streaming>. The
response's rate limit headers replace the engine's rate limit first, as in
L</parse_response>. On a non-success response croaks with the HTTP status line and the provider's
response body appended (whitespace-collapsed and length-limited), mirroring
L</parse_response>. Returns an
ArrayRef of L<Langertha::Stream::Chunk> objects and a timing HashRef with
C<total_seconds> (Float, seconds). C<ttft_seconds> is omitted because this
method reads the whole body before parsing — use
L<Langertha::Role::Chat/chat_stream_realtime_f> for true TTFT (it streams
incrementally on both backends of L<Langertha::Role::AsyncHTTP>, including the
synchronous LWP fallback). If C<$chunk_callback> is provided it is called with each chunk
as it is parsed.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::JSON> - JSON encoding/decoding (required by this role)

=item * L<Langertha::Role::Streaming> - Stream processing

=item * L<Langertha::Role::OpenAPI> - OpenAPI request generation

=item * L<Langertha::Request::HTTP> - HTTP request object created by this role

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
