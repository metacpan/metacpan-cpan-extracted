package Langertha::Role::AsyncHTTP;
# ABSTRACT: Async HTTP backend selection (injected > Net::Async::HTTP > sync LWP fallback)
our $VERSION = '0.503';
use Moose::Role;
use Future::AsyncAwait;
use Future;
use Carp qw( croak );
use Scalar::Util qw( blessed reftype );
use URI;

requires 'user_agent';

my $WARNED = 0;

has _async_loop => (
  is => 'ro',
  lazy_build => 1,
);

sub _build__async_loop {
  require IO::Async::Loop;
  return IO::Async::Loop->new;
}

has _async_http => (
  is => 'ro',
  lazy_build => 1,
);

sub _build__async_http {
  my ($self) = @_;
  my $loaded     = eval { require Net::Async::HTTP; 1 };
  my $load_error = $@;
  if ($loaded) {
    # No HTTP/1.1 pipelining: a request pipelined behind a long LLM stream
    # waits for it anyway, and fails with "Connection closed" when that stream
    # is aborted (karr k199, ADR 0027).
    my $http = Net::Async::HTTP->new( pipeline => 0 );
    $self->_async_loop->add($http);
    return $http;
  }
  unless ($WARNED) {
    $WARNED = 1;
    # A missing module is the expected, documented case. Anything else (a
    # missing IO::Async sub-dependency after a partial upgrade, a compile
    # error) is a broken install the user should see, not "not available".
    my $reason = $load_error =~ m{\ACan't locate Net/Async/HTTP\.pm }
      ? 'Net::Async::HTTP not available'
      : 'Net::Async::HTTP failed to load (' . ( split /\n/, $load_error )[0] . ')';
    warn "$reason; Langertha is running HTTP synchronously "
       . "(no concurrency). Install Net::Async::HTTP + IO::Async for real async."
       . _caller_location() . "\n";
  }
  require Langertha::Request::SyncHTTP;
  return Langertha::Request::SyncHTTP->new( user_agent => $self->user_agent );
}

# The builder runs inside a generated Moose accessor called from a Langertha
# role (chat_f, poll_metrics_f, ...), so carp would point into that plumbing.
# Report the first frame outside Langertha, Moose and the Future machinery:
# the user's own call site.
sub _caller_location {
  my $level = 0;
  while ( my ( $package, $file, $line ) = caller $level++ ) {
    next if $package =~ /\A(?:Langertha|Moose|Class::MOP|Eval::Closure|Future)(?:::|\z)/;
    return " at $file line $line.";
  }
  return '';
}


async sub async_request_f {
  my ( $self, $request, %opts ) = @_;
  return await $self->_async_do_request_f( request => $request, %opts );
}

# Every async request core sends goes through here (karr k278, ADR 0027).
# Net::Async::HTTP sets no timeout of its own, so a provider that accepts and
# never answers left the Future pending forever. When the engine has a
# user_agent_timeout it becomes Net::Async::HTTP's per-request timeout: the
# total time for a plain request, the time without a byte (stall_timeout) for
# a streaming one (on_header), where a long steady stream is legitimate. The
# failure is rewritten to name the engine and the URL (query and userinfo
# dropped: Gemini carries its key in the query). A caller's own timeout /
# stall_timeout option wins. The sync shim already has the timeout on its
# LWP user agent, and an injected client of another class keeps its own.
sub _async_do_request_f {
  my ( $self, %args ) = @_;
  my $http = $self->_async_http;
  my $is_nahttp = blessed($http) && $http->isa('Net::Async::HTTP');
  # connect_address (karr k375): only Net::Async::HTTP (per-request host and
  # SSL_* options, _async_one_request_f) and the sync shim over a pinned
  # Langertha::HTTP::UserAgent can pin; any other client would resolve the
  # name itself, so a request to the pinned host fails instead of going out.
  if ( my $pin_host = $self->can('_connect_host') ? $self->_connect_host : undef ) {
    my $target = $args{request} ? $args{request}->uri : $args{uri};
    my $to_pinned = defined $target && URI->new("$target")->can('host')
      && lc( URI->new("$target")->host // '' ) eq $pin_host;
    if ($to_pinned) {
      my $error = $is_nahttp ? $self->_nahttp_pin_error( $http, \%args )
        : blessed($http) && $http->isa('Langertha::Request::SyncHTTP')
          ? $self->_connect_pin_error( $http->user_agent )
        : 'connect_address ' . $self->connect_address . ' cannot be applied through an injected '
          . ( blessed($http) // 'unblessed' ) . ' client (only Net::Async::HTTP or Langertha::Request::SyncHTTP can pin)';
      return Future->fail( ref($self) . ": $error\n", 'connect_address' ) if $error;
    }
  }
  # Only Net::Async::HTTP gets the timeout, the body cap and the redirect policy
  # below. The sync shim and injected clients hand back the still-encoded body,
  # which Role::HTTP::_bounded_decoded_content bounds downstream, and they carry
  # their own timeout (ADR 0027); the sync shim runs the engine's user_agent,
  # a Langertha::HTTP::UserAgent with the same redirect policy (karr k374).
  return $http->do_request(%args) unless $is_nahttp;

  # Redirects (karr k374). Net::Async::HTTP follows a GET redirect with a fresh
  # request carrying the Location's query as it is, so a server echoing the
  # request URI sent Gemini's ?key= to the new host, while on the same origin
  # the credential header was lost. It follows nothing here (max_redirects => 0);
  # each hop is decided by Langertha::HTTP::Redirect, the policy the sync LWP
  # agent follows too. A caller's max_redirects is the hop limit, else the
  # client's own (the max_redirects it was built with, default 3). Only GET and
  # HEAD are ever followed, so any other request is the single hop it was.
  # The client's own limit is Net::Async::HTTP private state (checked against
  # 0.50, where configure stores it in $self->{max_redirects}); read defensively
  # and fall back to that version's default of 3.
  my $hops = exists $args{max_redirects} ? delete $args{max_redirects}
    : ( reftype($http) // '' ) eq 'HASH' && defined $http->{max_redirects} ? $http->{max_redirects}
    : 3;
  $args{max_redirects} = 0;
  # A caller passing uri => instead of request => (no core caller does) gets no
  # redirect following: Net::Async::HTTP builds that request itself, so it is
  # the single hop max_redirects => 0 allows and a 3xx comes back as it is.
  my $request = $args{request};
  return $self->_async_one_request_f( $http, %args )
    unless $hops && $request && ( uc $request->method ) =~ /\A(?:GET|HEAD)\z/;
  require Langertha::HTTP::Redirect;
  return $self->_async_follow_f( $http, \%args, $hops, undef );
}

# One hop of a followed chain, then the next one if the policy follows it. A
# caller's on_header must not see a redirect that is followed (its body is
# discarded, as Net::Async::HTTP does); a redirect that is not followed reaches
# it like any other response. Future->then propagates a cancel of the returned
# future to the hop in flight.
sub _async_follow_f {
  my ( $self, $http, $args, $hops, $previous ) = @_;
  my %hop = %{$args};
  # Decided once per response (on_header and the completed hop both ask), so a
  # refusal's Client-Warning is added once.
  my ( $decided, $next );
  my $follows = sub {
    my ($response) = @_;
    return $next if $decided && $decided == $response;
    $decided = $response;
    $response->previous($previous) if $previous && !$response->previous;
    if ( $hops > 0 ) {
      $next = Langertha::HTTP::Redirect::next_request( $hop{request}, $response,
        $self->can('_connect_host') ? $self->_connect_host : undef );
    }
    else {
      $next = undef;
      $response->push_header( 'Client-Warning' =>
          'redirect not followed: Langertha::HTTP::Redirect: hop limit reached' )
        if $response->is_redirect && defined $response->header('Location');
    }
    return $next;
  };
  if ( my $on_header = $hop{on_header} ) {
    $hop{on_header} = sub {
      my ($response) = @_;
      return sub { return @_ ? () : $response } if $follows->($response);
      return $on_header->($response);
    };
  }
  return $self->_async_one_request_f( $http, %hop )->then( sub {
    my ($response) = @_;
    my $next = $follows->($response);
    return Future->done($response) unless $next;
    return $self->_async_follow_f( $http, { %{$args}, request => $next }, $hops - 1, $response );
  } );
}

# One Net::Async::HTTP request with the connect check, the body cap and the
# timeout applied.
sub _async_one_request_f {
  my ( $self, $http, %args ) = @_;

  # Net::Async::HTTP 0.50 loads IO::Async::Internals::Connector (and
  # IO::Async::SSL for https) only when it connects; when that load dies, the
  # dead connection keeps the host's slot and every later request to the host
  # hangs. Check first, so it is a failed Future naming the module (karr k353).
  my $target = $args{request} ? $args{request}->uri : $args{uri};
  if ( defined $target ) {
    require Langertha::HTTP::ConnectCheck;
    my $error = Langertha::HTTP::ConnectCheck::connect_error( $target, $args{SSL} );
    return Future->fail( ref($self).": $error\n", 'connect' ) if $error;
  }

  # connect_address (karr k375): connect to the checked address, not to a
  # fresh resolution of the name. Net::Async::HTTP 0.50 uses host/port only as
  # the connection target (and its pool key); the Host header comes from the
  # request URI, and for SSL it sets SSL_hostname => host before the request's
  # own SSL_* options, so these name the host for SNI and the certificate check.
  # A redirect is never followed by the client here (max_redirects => 0), so
  # the target cannot leak into another hop.
  if ( defined $target and my $pin_host = $self->can('_connect_host') ? $self->_connect_host : undef ) {
    my $uri = URI->new("$target");
    if ( $uri->can('host') && lc( $uri->host // '' ) eq $pin_host ) {
      %args = ( %args, _connect_pin_args( $uri, $self->connect_address ) );
      $args{on_ready} = $self->_connect_pin_on_ready( $http, $uri, \%args );
    }
  }

  my $stream = $args{on_header} ? 1 : 0;

  # Bound the decoded response body against a decompression bomb (karr k346).
  # Unlike LWP, Net::Async::HTTP inflates a Content-Encoding while it streams and
  # moves the header to X-Original-Content-Encoding, so by the time the finished
  # response reaches _bounded_decoded_content there is no encoding left to bound
  # and a bomb has already been inflated in full. Count the decoded bytes as they
  # arrive (Net::Async::HTTP decodes before this on_header callback) and abort
  # past response_max_bytes -- the same streamed-byte guard the inline-image fetch
  # uses (Langertha::Content::Image::_fetch_net_async_f). Only for a non-streaming
  # request: a caller on_header is a stream, unbounded by design.
  my $max = ( !$stream && $self->can('response_max_bytes') ) ? $self->response_max_bytes : 0;
  my ( $abort, $too_big );
  if ($max) {
    $abort = Future->new;
    $args{on_header} = $self->_body_cap_on_header( $http, $max, \$too_big, $abort );
  }

  # user_agent_timeout -> Net::Async::HTTP's own per-request option, unless the
  # caller set one (karr k278).
  my $secs = $self->can('has_user_agent_timeout') && $self->has_user_agent_timeout
    ? $self->user_agent_timeout : 0;
  my $timed = $secs && !exists $args{timeout} && !exists $args{stall_timeout};

  return $http->do_request(%args) unless $timed || $max;

  my $request_f = $http->do_request( %args,
    $timed ? ( ( $stream ? 'stall_timeout' : 'timeout' ) => $secs ) : () );

  if ($timed) {
    my $uri = $args{request}->uri->clone;
    $uri->query(undef);
    $uri->fragment(undef);
    $uri->userinfo(undef) if $uri->can('userinfo');
    my $what = ref($self) . ': ' . ( $stream ? 'streaming request' : 'request' ) . " to $uri";
    $request_f = $request_f->else( sub {
      my ( $message, $category, @details ) = @_;
      return Future->fail(@_)
        unless defined $category && ( $category eq 'timeout' || $category eq 'stall_timeout' );
      my $text = $category eq 'timeout'
        ? "$what timed out after ${secs}s"
        : "$what timed out after ${secs}s without data ($message)";
      return Future->fail( "$text\n", $category, @details );
    } );
  }

  return $request_f unless $max;

  # Over the cap, whatever ends the fetch first -- the abort cancelling the
  # request, or the server closing the connection -- becomes the size error.
  my $too_big_croak = sub {
    croak "".( ref $self )." response body exceeds response_max_bytes ($max)";
  };
  return Future->wait_any( $request_f, $abort )
    ->then( sub { $too_big ? $too_big_croak->() : Future->done(@_) } )
    ->else( sub { $too_big ? $too_big_croak->() : Future->fail(@_) } );
}

# The Net::Async::HTTP request options that connect a request for $uri to
# $address while naming the host for TLS (karr k375).
sub _connect_pin_args {
  my ( $uri, $address ) = @_;
  my $host = $uri->host;
  my $literal = $host =~ /:/ || $host =~ /\A[0-9.]+\z/;
  return (
    host => $address,
    port => $uri->port,
    ( lc( $uri->scheme // '' ) eq 'https'
      ? ( SSL_hostname => ( $literal ? undef : $host ), SSL_verifycn_name => $host )
      : () ),
  );
}

# The on_ready (Net::Async::HTTP 0.50 runs it with the connection before it
# writes the request, for a new and for a pooled connection alike) that checks
# the connection really is to the pinned address and, over TLS, was verified
# for this host. The client pools connections by host:port, and host is now
# the address: two engines pinning different names to one address on a shared
# client would otherwise share a TLS session verified for the first name
# (karr k375). A refused connection is closed once idle (never under a request
# that is using it), so it leaves the pool and a request queued behind it gets
# a fresh one.
sub _connect_pin_on_ready {
  my ( $self, $http, $uri, $args ) = @_;
  my $address = $self->connect_address;
  my $host    = $uri->host;
  my $https   = lc( $uri->scheme // '' ) eq 'https';
  my $params  = ( reftype($http) // '' ) eq 'HASH' && ref $http->{ssl_params} eq 'HASH' ? $http->{ssl_params} : {};
  # Verification switched off for this request or client: SSL_verify_mode
  # => 0 skips both checks, SSL_verifycn_scheme => 'none' the name check
  # (what the connection itself would have skipped; LWP's verify_hostname
  # => 0 is the same pair on the sync side).
  my %tls = map { $_ => ( exists $args->{$_} ? $args->{$_} : $params->{$_} ) } qw( SSL_verify_mode SSL_verifycn_scheme );
  my $check_chain = $https && !( defined $tls{SSL_verify_mode} && !$tls{SSL_verify_mode} );
  my $check_name  = $check_chain && !( defined $tls{SSL_verifycn_scheme} && $tls{SSL_verifycn_scheme} eq 'none' );
  my $caller_on_ready = $args->{on_ready};
  my $class = ref $self;
  return sub {
    my ($conn) = @_;
    my $handle = $conn->read_handle;
    my $peer = $handle ? eval { $handle->peerhost } : undef;
    require Langertha::HTTP::UserAgent;
    my $error = !( defined $peer && Langertha::HTTP::UserAgent::same_address( $peer, $address ) )
      ? "connect_address $address was not used: the connection goes to " . ( $peer // 'an unknown peer' )
      : undef;
    if ( !$error && $check_chain ) {
      my $tls = Langertha::HTTP::UserAgent::tls_identity_error( $handle, $host,
        chain => 1, name => $check_name );
      $error = "connect_address $address: $tls" if $tls;
    }
    if ($error) {
      $conn->loop->later( sub { $conn->close if $conn->read_handle && $conn->is_idle } ) if $conn->loop;
      return Future->fail( "$class: $error\n", 'connect_address' );
    }
    return $caller_on_ready ? $caller_on_ready->($conn) : Future->done;
  };
}

# Why this Net::Async::HTTP request could not be pinned, or undef (karr k375).
sub _nahttp_pin_error {
  my ( $self, $http, $args ) = @_;
  my $address = $self->connect_address;
  # With uri => Net::Async::HTTP sets host from the URI itself, over ours.
  return "connect_address $address needs a request => HTTP::Request, not uri =>"
    unless $args->{request};
  # A proxy connection goes to the proxy, which resolves the name itself. The
  # client's own proxy settings are private state (hash fields in 0.50).
  my $client = ( reftype($http) // '' ) eq 'HASH' ? $http : {};
  for my $key (qw( proxy_host proxy_path )) {
    return "connect_address $address cannot be used through a proxy ($key)"
      if defined $args->{$key} || defined $client->{$key};
  }
  return undef;
}

# The on_header (Net::Async::HTTP contract) that counts a non-streaming response
# body's decoded bytes and trips the abort once they pass $max (karr k346).
# Mirrors the inline-image counter (Langertha::Content::Image::_fetch_net_async_f):
# the body accumulates on the header response so the finished HTTP::Response still
# carries it, and the abort runs on the loop's next tick because closing the
# connection from inside the read handler is not safe.
sub _body_cap_on_header {
  my ( $self, $http, $max, $too_big_ref, $abort ) = @_;
  return sub {
    my ($header) = @_;
    my $trip = sub {
      return if ${$too_big_ref}++;
      $http->loop->later( sub { $abort->done unless $abort->is_ready } );
    };
    my $length = $header->content_length;
    $trip->() if $header->is_success && defined $length && $length > $max;
    return sub {
      return $header unless @_;
      return if ${$too_big_ref};
      $header->add_content( $_[0] ) if defined $_[0];
      $trip->() if length( ${ $header->content_ref } ) > $max;
      return;
    };
  };
}


sub async_loop {
  my ($self) = @_;
  my $http = $self->_async_http;
  return $http->can('loop') ? $http->loop : undef;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::AsyncHTTP - Async HTTP backend selection (injected > Net::Async::HTTP > sync LWP fallback)

=head1 VERSION

version 0.503

=head2 _async_http

The backend that satisfies the async C<do_request> contract:
C<< do_request( request => $req [, on_header => sub {...}] ) >> returning a
L<Future> that resolves to an L<HTTP::Response>. It is the injection seam —
pass C<< _async_http => $client >> at construction to bring your own client
(any object with that method) and it is used verbatim.

When not injected the builder selects, in order: L<Net::Async::HTTP> if it can
be loaded (a real async client added to L</_async_loop>, built with
C<< pipeline => 0 >>); otherwise
L<Langertha::Request::SyncHTTP> over the engine's C<user_agent>, warning once
per process. The warning names the caller's own C<_f> call site; if
L<Net::Async::HTTP> is installed but fails to load (for example a missing
L<IO::Async> sub-dependency) it says so and includes the first line of the
load error instead of claiming the module is unavailable. The sync fallback runs HTTP B<synchronously and sequentially>
(blocking, no concurrency) — every C<_f> call still works and returns a
L<Future>, but multiple calls awaited "in parallel" run one after another.

The L<Net::Async::HTTP> client does not pipeline HTTP/1.1 requests: a request
pipelined behind a long LLM stream would wait for it anyway, and would fail
with C<Connection closed> if that stream were cancelled or aborted. It keeps
the library's other defaults, including C<max_connections_per_host> (one
keep-alive connection per host; the C<NET_ASYNC_HTTP_MAXCONNS> environment
variable changes it), so concurrent requests on one engine are sent one after
another on that connection. Concurrent requests through different engines use
their own clients. Inject a client configured otherwise to change either.

=head2 async_request_f

    my $response = await $engine->async_request_f($http_request);
    die $response->status_line unless $response->is_success;

    # streaming: on_header passes through to the backend
    await $engine->async_request_f($http_request, on_header => sub { ... });

Sends a prepared L<HTTP::Request> (for example from C<chat_request> or
C<build_tool_chat_request>) through the engine's selected backend
(L</_async_http>) and returns a L<Future> that resolves to the
L<HTTP::Response>. This is the public face of the C<do_request> contract, for
callers outside core that assemble their own requests. On the synchronous
fallback the returned future is already complete.

An HTTP error status (4xx/5xx) B<resolves> the future on every backend: check
C<is_success> on the response. A B<transport-level> failure (connection
refused, DNS, timeout) is B<not> uniform across backends: on
L<Net::Async::HTTP> it B<fails> the future with the socket error, while on the
synchronous fallback it B<resolves> with the 500 response LWP synthesizes
(C<500 Can't connect ...>, header C<Client-Warning: Internal response>) — the
future does not fail. Either way the call did not succeed, so always check
C<is_success>; do not rely on a failed future alone to catch a dead endpoint.
See ADR 0027 for the parity scope.

When the engine has a L<Langertha::Role::HTTP/user_agent_timeout> and the
backend is a L<Net::Async::HTTP>, it is applied here like on the engine's own
C<_f> calls: as the total C<timeout> for a plain request, as the
C<stall_timeout> (time without a byte) when C<on_header> is given. On expiry
the future B<fails> with C<< <engine class>: request to <url> timed out after
Ns >> (query string and userinfo left out of the URL) and the category
C<timeout> or C<stall_timeout>. Passing your own C<timeout> or
C<stall_timeout> option overrides it.

On the L<Net::Async::HTTP> backend the modules it loads only when it connects
are checked before the request is handed to it: L<IO::Async::Internals::Connector>,
and L<IO::Async::SSL> for C<https>. If one fails to load, the future B<fails>
with C<< <engine class>: cannot connect to <scheme>://<host>:<port>: <module>
failed to load (<reason>); ... >> and the category C<connect>. Without the check
L<Net::Async::HTTP> 0.50 would keep the host's connection slot taken by the
connection that never opened, and every later request to that host would wait
forever (karr k353). Inline image fetches through such a client
(L<Langertha::Content::Image/ensure_base64_f>) are checked the same way.

Redirects follow L<Langertha::HTTP::Redirect> on every backend core builds:
on L<Net::Async::HTTP> they are followed here one hop at a time (the client
itself is told C<< max_redirects => 0 >>), on the synchronous fallback by the
engine's L<Langertha::HTTP::UserAgent>. Only C<GET> and C<HEAD> are followed,
never from C<https> to C<http>; a redirect on the same origin keeps the request
as it was, one to another origin drops every header but the representation
ones (so no credential header of any name goes along), the URL's userinfo, and
any query value the request carried as a credential. C<http://host> to
C<https://host> counts as another origin, so a keyed GET behind such a redirect
arrives without its key and gets a 401: configure the C<https> URL. A C<POST>
is never followed. A redirect that is not followed resolves the future with
the 3xx response, with a C<Client-Warning> header naming the reason
(C<redirect not followed: Langertha::HTTP::Redirect: ...>, also when the hop
limit ran out). The hop limit is a C<max_redirects> option if given, else the
client's own (3 by default); the C<timeout> applies per hop. With
C<on_header> the callback sees only the response the chain ends on, a
redirect that was not followed included (karr k374). A request passed as
C<< uri => >> instead of C<< request => >> is not followed at all. An injected
client of another class follows redirects on its own terms.

With a L<Langertha::Role::HTTP/connect_address>, a request to the host of
the engine's C<url> connects to that address: on L<Net::Async::HTTP> the
request is given C<host> / C<port> as the connection target and, for
C<https>, C<SSL_hostname> and C<SSL_verifycn_name> naming the host (the
C<Host> header comes from the request URL as always), and an C<on_ready>
check that the connection (new or pooled) goes to the address and, over TLS,
was verified for the host; on the synchronous fallback the engine's pinned
L<Langertha::HTTP::UserAgent> does it. A
redirect from the pinned host to another host is not followed. A client that
cannot pin (an injected client of another class, the shim over an agent
without the same pin, a L<Net::Async::HTTP> with a proxy, a C<< uri => >>
request) fails the future with category C<connect_address> instead of
sending the request (karr k375).

Any extra named options (such as C<on_header> for streaming) are passed to
C<do_request> unchanged. The backend object itself is not exposed; see
L</async_loop> for the event loop.

On the L<Net::Async::HTTP> backend a B<non-streaming> request (no C<on_header>)
has its decoded response body bounded by
L<Langertha::Role::HTTP/response_max_bytes>: the client inflates a
C<Content-Encoding> as it streams, so the decoded bytes are counted and the
request is aborted past the ceiling, failing the future with C<< <engine class>
response body exceeds response_max_bytes (<n>) >> (a decompression-bomb guard,
karr k346). A streaming request (with C<on_header>) is not bounded. Set
C<response_max_bytes> to C<0> to disable.

=head2 async_loop

    my $loop = $engine->async_loop // IO::Async::Loop->new;
    $loop->add($notifier);
    await $loop->delay_future( after => 2 );

Returns the event loop of the active async backend (L</_async_http>), or
C<undef> — a C<Maybe[loop]>. Core promises no loop (see L</EVENT LOOP>):

=over 4

=item * an injected client that has a C<loop> method: that client's loop,
whatever loop the caller put it on;

=item * the default L<Net::Async::HTTP> backend: the loop it was added to
(L</_async_loop>);

=item * the synchronous fallback (L<Langertha::Request::SyncHTTP>) or an
injected client without a C<loop> method: C<undef>.

=back

Calling it selects the backend if that has not happened yet (so on a clean
install it may emit the one-time fallback warning). Code that needs a loop for
its own notifiers or timers should use this loop when it is defined, so its
futures and the engine's HTTP futures are driven by the same loop; awaiting
futures from two different loops in one chain can hang.

=head1 EVENT LOOP

Core promises no event loop: L<IO::Async> is only recommended, an injected
client may run on any loop, and the synchronous fallback runs on none.
L</async_loop> reports the backend's loop when there is one and C<undef>
otherwise. When it is C<undef> a caller that needs a loop brings its own,
typically C<< IO::Async::Loop->new >> (the process-wide loop).

The backend's loop is not necessarily the process-wide one: an injected
L</_async_http> client can live on any loop, and L</_async_loop> is itself a
constructor argument (C<< _async_loop => $my_loop >>), in which case the
default L<Net::Async::HTTP> backend is added to that loop. L</async_loop>
returns the right loop in all of these cases.

=head2 _async_loop

The L<IO::Async::Loop> the real-async client is added to. Built lazily and
B<only> on the L<Net::Async::HTTP> path; the sync fallback never touches it,
so no event loop is created when running synchronously. The default is
C<< IO::Async::Loop->new >>, the process-wide loop; it can be passed at
construction to put the default backend on another loop (see L</EVENT LOOP>).
Use L</async_loop> to read the backend's loop.

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
