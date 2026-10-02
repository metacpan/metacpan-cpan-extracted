#!/usr/bin/env perl
# ABSTRACT: connect_address pins an engine's connection to a checked address, TLS still names the host
use strict; use warnings;
use Test2::Bundle::More;
use FindBin;
use lib "$FindBin::Bin/lib";

# Why (karr k375, from langertha-raider #119): a caller that resolved the
# endpoint host and checked its addresses (no loopback, private or metadata
# address) gains nothing if the engine resolves the name again at connect time:
# a DNS answer that changed in between (DNS rebinding) sends the request, with
# its credential, somewhere that was never checked. connect_address makes the
# engine connect to the checked address on every backend core builds, while
# the request keeps naming the host (Host header, TLS SNI and certificate
# name). A redirect off the pinned host is not followed, and whatever cannot
# pin (a proxy, a foreign client, an unpinned injected agent) fails instead of
# silently resolving the name.
#
# The pinned name here is under .invalid (RFC 6761): it never resolves, so a
# request that reaches the local daemon can only have gone to the pinned
# address.

BEGIN {
  plan skip_all => 'fork-based HTTP::Daemon test not supported on Windows' if $^O eq 'MSWin32';
  eval { require Future::AsyncAwait; 1 }
    or plan skip_all => 'Requires Future::AsyncAwait';
}

use File::Temp ();
use HTTP::Request;
use HTTP::Response;
use JSON::MaybeXS;
use LWP::UserAgent;
use URI;
use Test::LocalHTTPDaemon;
use Langertha::HTTP::Redirect;
use Langertha::HTTP::UserAgent;
use Langertha::Request::SyncHTTP;
use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::vLLM;
use Langertha::Engine::Ollama;
use Langertha::Engine::LMStudio;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $HAVE_NAHTTP = eval { require Net::Async::HTTP; require IO::Async::Loop; 1 };
my $PIN = 'pinned.invalid';

# --- construction: what is accepted, what croaks -------------------------------

{
  my $err = \&Langertha::HTTP::UserAgent::connect_address_error;
  ok !defined $err->($_), "$_ is an address literal" for '127.0.0.1', '203.0.113.7', '::1', '2001:db8::7';
  ok defined $err->($_), "'$_' is refused" for 'localhost', 'pinned.invalid', '[::1]', '127.0.0.1:80', 'fe80::1%eth0', '', '1.2.3';

  my %base = ( url => "https://$PIN/v1", api_key => 'k' );
  ok eval { Langertha::Engine::OpenAI->new( %base, connect_address => undef ); 1 }, 'connect_address => undef means no pin';
  ok !eval { Langertha::Engine::OpenAI->new( %base, connect_address => 'pinned.example' ); 1 }, 'a host name is not an address';
  like $@, qr/connect_address must be an IPv4 or IPv6 address literal/, '... and says so';

  my $engine = Langertha::Engine::OpenAI->new( %base, connect_address => '203.0.113.7' );
  my $ua = $engine->user_agent;
  isa_ok $ua, 'Langertha::HTTP::UserAgent';
  is $ua->connect_host, $PIN, 'the built agent pins the host of url';
  is $ua->connect_address, '203.0.113.7', '... to the address';

  ok !eval { Langertha::Engine::OpenAI->new( %base, connect_address => '203.0.113.7', user_agent => LWP::UserAgent->new ); 1 },
    'a plain LWP::UserAgent passed in cannot pin';
  like $@, qr/cannot be applied through the user_agent passed in \(LWP::UserAgent\)/, '... and the croak says why';
  ok !eval { Langertha::Engine::OpenAI->new( %base, connect_address => '203.0.113.7', user_agent => Langertha::HTTP::UserAgent->new ); 1 },
    'an unpinned Langertha::HTTP::UserAgent is refused too';
  ok !eval { Langertha::Engine::OpenAI->new( %base, connect_address => '203.0.113.7',
      user_agent => Langertha::HTTP::UserAgent->new( connect_host => 'other.invalid', connect_address => '203.0.113.7' ) ); 1 },
    'an agent pinned for another host is refused';
  ok eval { Langertha::Engine::OpenAI->new( %base, connect_address => '203.0.113.7',
      user_agent => Langertha::HTTP::UserAgent->new( connect_host => uc $PIN, connect_address => '203.0.113.7', agent => 'mine' ) ); 1 },
    'an agent with the same pin is accepted' or diag $@;
  ok eval { Langertha::Engine::OpenAI->new( %base, user_agent => LWP::UserAgent->new ); 1 },
    'without a pin any agent is accepted, as before';

  ok !eval { Langertha::HTTP::UserAgent->new( connect_address => '203.0.113.7' ); 1 }, 'the agent wants connect_host with connect_address';
  ok !eval { Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => 'nope' ); 1 }, '... and an address literal';
  is( Langertha::HTTP::UserAgent->new( agent => 'x', timeout => 5 )->timeout, 5, 'LWP arguments still reach LWP' );

  # Engines whose url is a lazily built default (karr k375 review).
  require Langertha::Engine::Groq;
  require Langertha::Engine::Anthropic;
  for my $class (qw( Langertha::Engine::Groq Langertha::Engine::Anthropic )) {
    my $default = eval { $class->new( api_key => 'k', connect_address => '203.0.113.7' ) };
    ok $default, "$class without a url takes connect_address" or diag $@;
    is $default && $default->user_agent->connect_host, URI->new( $default->url )->host, '... pinning its default host' if $default;
  }

  # Engines derived on the same host carry the pin; another url does not.
  my $openai = Langertha::Engine::OpenAI->new( %base, connect_address => '203.0.113.7' );
  is $openai->whisper->connect_address, '203.0.113.7', 'OpenAI->whisper carries the pin';
  is $openai->whisper->user_agent->connect_address, '203.0.113.7', '... into its agent';
  my $ollama = Langertha::Engine::Ollama->new( url => "http://$PIN:11434", model => 'm', connect_address => '203.0.113.7' );
  is $ollama->openai->connect_address, '203.0.113.7', 'Ollama->openai carries the pin';
  ok !defined $ollama->openai( url => 'http://elsewhere.invalid/v1' )->connect_address, '... not onto another host';
  is $ollama->openai( url => "http://$PIN:11434/other/v1" )->connect_address, '203.0.113.7', '... but onto another url on the same host';
  my $lms = Langertha::Engine::LMStudio->new( url => "http://$PIN:1234", model => 'm', connect_address => '203.0.113.7' );
  is $lms->openai->connect_address, '203.0.113.7', 'LMStudio->openai carries the pin';
  is $lms->anthropic->connect_address, '203.0.113.7', 'LMStudio->anthropic carries the pin';
}

# --- the redirect policy with a pinned host (no network) ----------------------

{
  my $next = \&Langertha::HTTP::Redirect::next_request;
  my $req = HTTP::Request->new( GET => "https://$PIN/v1/models" );
  my $redirect = sub {
    my $response = HTTP::Response->new( 307, 'Temporary Redirect', [ Location => $_[0] ] );
    $response->request($req);
    return $response;
  };
  my $away = $redirect->('https://other.invalid/v1/models');
  ok !$next->( $req, $away, $PIN ), 'a redirect off the pinned host is not followed';
  like $away->header('Client-Warning'), qr/Langertha::HTTP::Redirect: connect_address pins \Q$PIN\E; not to another host \(other\.invalid\)/,
    '... and the 3xx says why';
  ok $next->( $req, $redirect->("https://$PIN:8443/v2/models"), $PIN ), 'the same host on another port is followed (it stays pinned)';
  ok $next->( $req, $redirect->('https://other.invalid/v1/models'), undef ), 'without a pin the cross-host redirect is followed, as before';
  my $unrelated = HTTP::Request->new( GET => 'https://cdn.invalid/img.png' );
  my $from_other = HTTP::Response->new( 302, 'Found', [ Location => 'https://cdn2.invalid/img.png' ] );
  $from_other->request($unrelated);
  ok $next->( $unrelated, $from_other, $PIN ), 'a request that was not to the pinned host is not restricted';
}

# --- the TLS names: what reaches the socket (https cannot be served locally) ---

{
  # Sync: capture the socket options LWP will use, from a request_send handler
  # that answers in place of the network (it runs inside send_request, where
  # the pin is in force), asking the protocol object LWP would connect with.
  require LWP::Protocol; require LWP::Protocol::http; require LWP::Protocol::https;
  my $orig_opts = LWP::Protocol::http->can('_extra_sock_opts');
  my $capture = sub {
    my ($ua) = @_;
    my $opts = [];
    $ua->add_handler( request_send => sub {
      my ($request) = @_;
      my $uri = $request->uri;
      my $host = $uri->host =~ /:/ ? '[' . $uri->host . ']' : $uri->host;   # as _new_socket passes it
      @$opts = LWP::Protocol::create( $uri->scheme, $ua )->_extra_sock_opts( $host, $uri->port );
      return HTTP::Response->new( 204, 'No Content' );
    } );
    return $opts;
  };
  my $ua = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '203.0.113.7' );
  my $opts = $capture->($ua);
  $ua->request( HTTP::Request->new( GET => "https://$PIN/v1/models" ) );
  my %opt = @$opts;
  is $opt{PeerAddr}, '203.0.113.7', 'sync https: the socket connects to the pinned address';
  is $opt{PeerHost}, '203.0.113.7', '... PeerHost too (IO::Socket::IP prefers it)';
  is $opt{SSL_hostname}, $PIN, 'sync https: SNI names the host';
  is $opt{SSL_verifycn_name}, $PIN, 'sync https: the certificate is checked against the host name';
  is( LWP::Protocol::http->can('_extra_sock_opts'), $orig_opts, 'the wrapped hook does not outlive the request' );

  my %plain_opt = LWP::Protocol::create( 'https', $ua )->_extra_sock_opts( $PIN, 443 );
  ok !exists $plain_opt{PeerAddr}, 'outside a request the agent adds nothing';

  $ua->request( HTTP::Request->new( GET => "http://$PIN/v1/models" ) );
  %opt = @$opts;
  is $opt{PeerAddr}, '203.0.113.7', 'sync http: pinned too';
  ok !exists $opt{SSL_hostname}, 'sync http: no TLS options';

  my $v6 = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '2001:db8::7' );
  $opts = $capture->($v6);
  $v6->request( HTTP::Request->new( GET => "https://$PIN/" ) );
  %opt = @$opts;
  is $opt{PeerAddr}, '[2001:db8::7]', 'an IPv6 address is bracketed for Net::HTTP';
  is $opt{PeerHost}, '2001:db8::7', '... and bare as PeerHost';

  my $lit = Langertha::HTTP::UserAgent->new( connect_host => '198.51.100.1', connect_address => '203.0.113.7' );
  $opts = $capture->($lit);
  $lit->request( HTTP::Request->new( GET => 'https://198.51.100.1/' ) );
  %opt = @$opts;
  ok exists $opt{SSL_hostname} && !defined $opt{SSL_hostname}, 'no SNI when the host is an address literal';
  is $opt{SSL_verifycn_name}, '198.51.100.1', '... the certificate is still checked against it';

  $opts = $capture->($ua);
  $ua->request( HTTP::Request->new( GET => 'https://other.invalid/' ) );
  %opt = @$opts;
  ok !exists $opt{PeerAddr}, 'another host is not pinned';

  # Another agent's request inside a pinned request (a content callback, say)
  # is not pinned: the hooks act for their own agent only.
  my $other = LWP::UserAgent->new;
  my %inner;
  my $outer = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '203.0.113.7' );
  $outer->add_handler( request_send => sub {
    %inner = LWP::Protocol::create( 'https', $other )->_extra_sock_opts( $PIN, 443 );
    return HTTP::Response->new(204);
  } );
  $outer->request( HTTP::Request->new( GET => "https://$PIN/" ) );
  ok !exists $inner{PeerAddr}, "another agent's request to the same host is not pinned";

  # The peer LWP reports must be the pinned address; anything else is refused.
  my $liar = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '203.0.113.7' );
  $liar->add_handler( request_send => sub {
    HTTP::Response->new( 200, 'OK', [ 'Client-Peer' => '10.0.0.9:443' ], 'from the wrong peer' );
  } );
  my $res = $liar->request( HTTP::Request->new( GET => "https://$PIN/" ) );
  is $res->code, 500, 'a response from another peer than the pinned address is refused';
  like $res->message, qr/connect_address 203\.0\.113\.7 was not used: LWP connected to 10\.0\.0\.9/, '... naming both';

  # No Client-Peer at all and no checked connection: the backstop fails closed.
  my $silent = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '203.0.113.7' );
  $silent->add_handler( request_send => sub { HTTP::Response->new( 200, 'OK', [], 'from nowhere checked' ) } );
  $res = $silent->request( HTTP::Request->new( GET => "https://$PIN/" ) );
  is $res->code, 500, 'a response that never passed the connection check is refused';
  like $res->message, qr/the connection was not checked before sending/, '... and says so';
  $silent = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '203.0.113.7' );
  $silent->add_handler( request_send => sub {
    HTTP::Response->new( 500, "Can't connect", [ 'Client-Warning' => 'Internal response' ] ) } );
  $res = $silent->request( HTTP::Request->new( GET => "https://$PIN/" ) );
  is $res->message, "Can't connect", "LWP's own internal error responses pass unchanged";

  my $proxied = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '203.0.113.7' );
  $proxied->proxy( [ 'http', 'https' ], 'http://proxy.invalid:3128' );
  $res = $proxied->request( HTTP::Request->new( GET => "http://$PIN/" ) );
  is $res->code, 500, 'a request that would go through a proxy is not sent';
  like $res->message, qr/cannot be used for a request that goes through a proxy/, '... and says why';
}

SKIP: {
  skip 'Net::Async::HTTP not installed', 1 unless $HAVE_NAHTTP;
  # Async: capture what Net::Async::HTTP 0.50 hands its connection layer after
  # merging the request's options over its own (SSL_hostname => the connect
  # host first, the request's SSL_* after), then stop there.
  {
    package Test::CaptureHTTP;
    our @ISA = ('Net::Async::HTTP');
    our @seen;
    sub get_connection { my ( $self, %args ) = @_; push @seen, \%args; return Future->fail( "captured\n", 'test' ) }
  }
  my $http = Test::CaptureHTTP->new;
  IO::Async::Loop->new->add($http);
  my $engine = Langertha::Engine::OpenAI->new( url => "https://$PIN/v1", api_key => 'k',
    connect_address => '203.0.113.7', _async_http => $http );
  my $f = $engine->async_request_f( $engine->list_models_request );
  $f->await;
  my ($args) = @Test::CaptureHTTP::seen;
  subtest 'Net::Async::HTTP https: connection target and TLS names' => sub {
    ok $args, 'the request reached the connection layer' or return;
    is $args->{host}, '203.0.113.7', 'the connection goes to the pinned address';
    is $args->{port}, 443, '... on the port of the URL';
    ok $args->{SSL}, 'over TLS';
    is $args->{SSL_hostname}, $PIN, 'SNI names the host, not the address';
    is $args->{SSL_verifycn_name}, $PIN, 'the certificate is checked against the host name';
  };
  @Test::CaptureHTTP::seen = ();
  $engine->async_request_f( HTTP::Request->new( GET => 'https://other.invalid/' ) )->await;
  is $Test::CaptureHTTP::seen[0]{host}, 'other.invalid', 'another host is not pinned';

  my $proxied = Net::Async::HTTP->new( proxy_host => 'proxy.invalid', proxy_port => 3128 );
  IO::Async::Loop->new->add($proxied);
  my $pe = Langertha::Engine::OpenAI->new( url => "http://$PIN/v1", api_key => 'k',
    connect_address => '203.0.113.7', _async_http => $proxied );
  my $pf = $pe->async_request_f( $pe->list_models_request );
  $pf->await;
  ok $pf->is_failed, 'a Net::Async::HTTP client with a proxy cannot pin: the request fails';
  like( ( $pf->failure )[0], qr/cannot be used through a proxy \(proxy_host\)/, '... and says why' );
  is( ( $pf->failure )[1], 'connect_address', '... with category connect_address' );

  my $plain = Net::Async::HTTP->new;
  IO::Async::Loop->new->add($plain);
  my $ue = Langertha::Engine::OpenAI->new( url => "http://$PIN/v1", api_key => 'k',
    connect_address => '127.0.0.1', _async_http => $plain );
  my $uf = $ue->async_request_f( undef, uri => URI->new("http://$PIN/v1/models") );
  $uf->await;
  ok $uf->is_failed, 'a uri => request cannot be pinned (Net::Async::HTTP takes host from the URI)';
  like( ( $uf->failure )[0], qr/needs a request => HTTP::Request, not uri =>/, '... and says so' );

  # The on_ready check, with a connection whose peer is not the pinned address.
  {
    package Test::StubHandle; sub new { bless { peer => $_[1] }, $_[0] } sub peerhost { $_[0]{peer} }
    package Test::StubConn;   sub new { bless { h => $_[1] }, $_[0] } sub read_handle { $_[0]{h} } sub loop { undef }
  }
  my $on_ready = $ue->_connect_pin_on_ready( $plain, URI->new("http://$PIN/v1/models"), {} );
  my $rf = $on_ready->( Test::StubConn->new( Test::StubHandle->new('10.0.0.9') ) );
  ok $rf->is_failed, 'on_ready refuses a connection to another peer';
  like( ( $rf->failure )[0], qr/connect_address 127\.0\.0\.1 was not used: the connection goes to 10\.0\.0\.9/, '... naming both' );
  is( ( $rf->failure )[1], 'connect_address', '... category connect_address' );
  ok $on_ready->( Test::StubConn->new( Test::StubHandle->new('::ffff:127.0.0.1') ) )->is_done,
    '... and accepts the pinned address (also IPv4-mapped)';
}

{
  # Clients that cannot pin fail the request instead of resolving the name.
  {
    package Test::ForeignClient;
    sub new { bless {}, shift }
    sub do_request { die "must not be called\n" }
  }
  my $e = Langertha::Engine::OpenAI->new( url => "http://$PIN/v1", api_key => 'k',
    connect_address => '127.0.0.1', _async_http => Test::ForeignClient->new );
  my $f = $e->async_request_f( $e->list_models_request );
  ok $f->is_failed, 'an injected client of another class cannot pin';
  like( ( $f->failure )[0], qr/cannot be applied through an injected Test::ForeignClient client/, '... and says so' );

  my $shim = Langertha::Engine::OpenAI->new( url => "http://$PIN/v1", api_key => 'k',
    connect_address => '127.0.0.1', _async_http => Langertha::Request::SyncHTTP->new( user_agent => LWP::UserAgent->new ) );
  $f = $shim->async_request_f( $shim->list_models_request );
  ok $f->is_failed, 'the sync shim over an unpinned agent cannot pin';
  like( ( $f->failure )[0], qr/cannot be applied through the user_agent passed in/, '... and says so' );
}

# --- real round-trips against the local daemon ----------------------------------

sub recorder {
  my $file = File::Temp->new;
  my $name = $file->filename;
  return {
    file  => $file,
    log   => sub {
      my ($r) = @_;
      open my $fh, '>>', $name or die $!;
      print {$fh} $json->encode({ method => $r->method, uri => $r->uri->path_query, host => scalar $r->header('Host') }), "\n";
      close $fh;
    },
    seen  => sub { open my $fh, '<', $name or return []; [ map { $json->decode($_) } <$fh> ] },
    reset => sub { open my $fh, '>', $name or die $! },
  };
}

sub answer {
  my ($r) = @_;
  my $path = $r->uri->path;
  my $host = $r->header('Host') // '';
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/plain' ], "vllm:num_requests_running 2\n" )
    if $path =~ m{/metrics\z};
  if ( $path =~ m{/chat/completions\z} ) {
    my $body = eval { $json->decode( $r->content ) } || {};
    if ( $body->{stream} ) {
      my $chunk = $json->encode({ id => 'c', object => 'chat.completion.chunk', model => 'm',
        choices => [ { index => 0, delta => { role => 'assistant', content => "host=$host" }, finish_reason => undef } ] });
      return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/event-stream' ],
        "data: $chunk\n\ndata: [DONE]\n\n" );
    }
    return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], $json->encode({
      id => 'c', object => 'chat.completion', model => 'm',
      choices => [ { index => 0, message => { role => 'assistant', content => "host=$host" }, finish_reason => 'stop' } ] }) );
  }
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode({ data => [ { id => "host=$host" } ] }) );
}

my $b_log = recorder();
my $daemon_b = Test::LocalHTTPDaemon->start( sub { $b_log->{log}->( $_[0] ); answer( $_[0] ) } );
my ($B_PORT) = $daemon_b->url =~ /:(\d+)\z/;

my $a_log = recorder();
my $daemon_a = Test::LocalHTTPDaemon->start( sub {
  my ($r) = @_;
  $a_log->{log}->($r);
  my $pq = $r->uri->path_query;
  # /away/... -> 307 to origin B by its address (another host)
  return HTTP::Response->new( 307, 'Temporary Redirect', [ Location => "http://127.0.0.1:$B_PORT$pq" ], '' )
    if $pq =~ m{\A/away/};
  # /port/... -> 307 to the pinned host on B's port (same host, another port)
  return HTTP::Response->new( 307, 'Temporary Redirect', [ Location => "http://$PIN:$B_PORT$pq" ], '' )
    if $pq =~ m{\A/port/};
  # /same/... -> 307 to /final/... on this origin
  return HTTP::Response->new( 307, 'Temporary Redirect', [ Location => $pq =~ s{\A/same/}{/final/}r ], '' )
    if $pq =~ m{\A/same/};
  return answer($r);
} );
my ($A_PORT) = $daemon_a->url =~ /:(\d+)\z/;
my $A = "http://$PIN:$A_PORT";

my @BACKENDS = (
  [ 'sync LWP' => sub { $_[0]->new( @_[ 1 .. $#_ ] ) } ],
  [ 'sync fallback shim' => sub {
      my ( $class, %args ) = @_;
      my $ua = $class->new(%args)->user_agent;
      $class->new( %args, user_agent => $ua, _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ) );
    } ],
  ( $HAVE_NAHTTP ? [ 'Net::Async::HTTP' => sub { $_[0]->new( @_[ 1 .. $#_ ] ) } ] : () ),
);
diag 'Net::Async::HTTP not installed: its backend is not exercised' unless $HAVE_NAHTTP;

# A GET through the backend: the engine's own sync call, or async_request_f.
sub get_models {
  my ( $bname, $engine, $request ) = @_;
  $request //= $engine->list_models_request;
  return $bname eq 'sync LWP' ? $engine->user_agent->request($request) : $engine->async_request_f($request)->get;
}

for my $backend (@BACKENDS) {
  my ( $bname, $make ) = @$backend;
  my %args = ( api_key => 'k', model => 'm', connect_address => '127.0.0.1' );

  subtest "$bname: list models, chat and streaming reach the pinned address and name the host" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', %args, url => "$A/v1" );
    my $res = get_models( $bname, $engine );
    ok $res->is_success, 'list models answered' or diag $res->status_line;
    like $res->content, qr/"host=\Q$PIN:$A_PORT\E"/, 'the Host header named the pinned host';

    my $chat = eval { $bname eq 'sync LWP' ? $engine->simple_chat('hi') : $engine->simple_chat_f('hi')->get };
    is "".( $chat // '' ), "host=$PIN:$A_PORT", 'chat (POST) reached the daemon under the host name' or diag $@;

    if ( $bname ne 'sync LWP' ) {
      my $text = '';
      my $ok = eval { $engine->simple_chat_stream_realtime_f( sub { $text .= $_[0]->content // '' }, 'hi' )->get; 1 };
      ok $ok, 'streaming chat completed' or diag $@;
      is $text, "host=$PIN:$A_PORT", 'streaming reached the daemon under the host name';
    }
    else {
      my $text = '';
      eval { $engine->simple_chat_stream( sub { $text .= $_[0]->content // '' }, 'hi' ); 1 } or diag $@;
      is $text, "host=$PIN:$A_PORT", 'sync streaming reached the daemon under the host name';
    }
    ok !grep( { ( $_->{host} // '' ) ne "$PIN:$A_PORT" } @{ $a_log->{seen}->() } ), 'every request named the host';
  };

  subtest "$bname: the probe and the metrics scrape are pinned too" => sub {
    my $router = $make->( 'Langertha::Engine::OpenRouter', %args, url => "$A/v1" );
    my $ok = eval { $router->probe_model_capabilities_f( models => ['m'] )->get; 1 };
    ok $ok, 'probe_model_capabilities_f reached the daemon' or diag $@;
    my $vllm = $make->( 'Langertha::Engine::vLLM', url => "$A/v1", model => 'm', connect_address => '127.0.0.1' );
    my $metrics = eval { $vllm->poll_metrics_f->get };
    ok $metrics, 'poll_metrics_f reached the daemon' or diag $@;
  };

  subtest "$bname: without the pin the name is resolved (and does not resolve)" => sub {
    my $engine = $make->( 'Langertha::Engine::OpenAI', api_key => 'k', model => 'm', url => "$A/v1" );
    my $res = eval { get_models( $bname, $engine ) };
    ok !( $res && $res->is_success ), 'the unpinned request does not reach the daemon';
  };

  subtest "$bname: a redirect on the pinned host stays pinned" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', %args, url => "$A/same" );
    my $res = get_models( $bname, $engine );
    ok $res->is_success, 'followed' or diag $res->status_line;
    is_deeply [ map { $_->{uri} } @{ $a_log->{seen}->() } ], [ '/same/models', '/final/models' ], 'both hops reached the pinned address';

    $_->{reset}->() for $a_log, $b_log;
    $engine = $make->( 'Langertha::Engine::OpenAI', %args, url => "$A/port" );
    $res = get_models( $bname, $engine );
    ok $res->is_success, 'a hop to the same host on another port is followed' or diag $res->status_line;
    my ($at_b) = @{ $b_log->{seen}->() };
    is $at_b && $at_b->{host}, "$PIN:$B_PORT", '... to the pinned address, naming the host';
  };

  subtest "$bname: a redirect off the pinned host is not followed" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', %args, url => "$A/away" );
    my $res = get_models( $bname, $engine );
    is $res->code, 307, 'the 307 is the result';
    like $res->header('Client-Warning') // '', qr/Langertha::HTTP::Redirect: connect_address pins \Q$PIN\E; not to another host/,
      '... with the reason';
    is scalar @{ $b_log->{seen}->() }, 0, 'the other host received nothing';

    my $ok = eval { $engine->list_models( force_refresh => 1 ); 1 };
    ok !$ok, 'list_models fails on it';
    like $@, qr/307/, '... naming the redirect';
  };

  next if $bname eq 'sync LWP';

  subtest "$bname: streaming GET with on_header is pinned" => sub {
    $_->{reset}->() for $a_log, $b_log;
    my $engine = $make->( 'Langertha::Engine::OpenAI', %args, url => "$A/v1" );
    my $body = '';
    my $res = $engine->async_request_f( $engine->list_models_request, on_header => sub {
      my ($header) = @_;
      return sub { $body .= $_[0] if @_ && defined $_[0]; return $header unless @_; return };
    } )->get;
    ok $res->is_success, 'answered';
    like $body, qr/"host=\Q$PIN:$A_PORT\E"/, 'the streamed body came from the pinned address';
  };
}

subtest 'the pin ends before content callbacks run: their own requests are not pinned' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', url => "$A/v1", connect_address => '127.0.0.1' );
  my $shim = Langertha::Request::SyncHTTP->new( user_agent => $engine->user_agent );
  my $inner;
  my $res = $shim->do_request( request => $engine->list_models_request, on_header => sub {
    return sub {
      $inner //= LWP::UserAgent->new( timeout => 5 )->get("http://$PIN:$A_PORT/v1/models") if @_ && defined $_[0];
      return;
    };
  } )->get;
  ok $res->is_success, 'the pinned request answered';
  ok $inner, 'the callback sent its own request';
  ok !$inner->is_success, '... which was not pinned (the name does not resolve)' or diag $inner->status_line;
};

subtest 'a socket from a shared conn_cache is checked before anything is written' => sub {
  # Two agents share one LWP::ConnCache (keyed by host:port of the name). The
  # second pins the same name to another address; the cached socket goes to
  # the first one's address, so the request must not be sent over it.
  require LWP::ConnCache;
  my $log = recorder();
  my $keep = Test::LocalHTTPDaemon->start( sub { $log->{log}->( $_[0] ); answer( $_[0] ) }, keep_alive => 1 );
  my ($port) = $keep->url =~ /:(\d+)\z/;
  my $cache = LWP::ConnCache->new( total_capacity => 5 );
  my $first  = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '127.0.0.1', conn_cache => $cache );
  my $second = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '127.0.0.2', conn_cache => $cache );
  my $res = $first->get("http://$PIN:$port/v1/models");
  ok $res->is_success, 'the first agent reached its address' or diag $res->status_line;
  $res = $second->get("http://$PIN:$port/v1/models");
  is $res->code, 500, "the second agent refuses the cached socket to the other address";
  like $res->message, qr/connect_address 127\.0\.0\.2 was not used: the connection goes to 127\.0\.0\.1/, '... naming both';
  is scalar @{ $log->{seen}->() }, 1, 'nothing was written over it';
};

# --- real TLS: the certificate is checked against the host name -----------------

SKIP: {
  skip 'IO::Socket::SSL::Utils not available', 1 unless eval { require IO::Socket::SSL::Utils; 1 };
  require Test::LocalTLSDaemon;
  my $tls_log = recorder();
  my $tls = Test::LocalTLSDaemon->start( names => [$PIN], handler => sub { $tls_log->{log}->( $_[0] ); answer( $_[0] ) } );
  my ( $port, $ca ) = ( $tls->port, $tls->ca_file );

  my $sync_engine = sub {
    my ($host) = @_;
    my $ua = Langertha::HTTP::UserAgent->new( connect_host => $host, connect_address => '127.0.0.1',
      ssl_opts => { SSL_ca_file => $ca, verify_hostname => 1 } );
    return Langertha::Engine::OpenAI->new( url => "https://$host:$port/v1", api_key => 'SEKRET-TLS',
      connect_address => '127.0.0.1', user_agent => $ua,
      _async_http => Langertha::Request::SyncHTTP->new( user_agent => $ua ) );
  };

  subtest 'sync LWP over TLS' => sub {
    $tls_log->{reset}->();
    my $engine = $sync_engine->($PIN);
    my $res = $engine->user_agent->request( $engine->list_models_request );
    ok $res->is_success, 'the certificate for the pinned name is accepted' or diag $res->status_line;
    like $res->content, qr/"host=\Q$PIN:$port\E"/, '... Host names the host';
    my $wrong = $sync_engine->('other.invalid');
    $res = $wrong->user_agent->request( $wrong->list_models_request );
    ok !$res->is_success, 'a name the certificate does not carry is refused, although the address is the same';
    like $res->status_line, qr/certificate verify failed|hostname verification failed/i, '... by the certificate check';
    is scalar @{ $tls_log->{seen}->() }, 1, 'the wrong name sent nothing';
  };

  subtest 'sync: a cached TLS socket another agent opened with weaker checks is refused' => sub {
    require LWP::ConnCache;
    # Name check off (verify_hostname => 0), chain verified: a socket for a
    # name the certificate does not carry ends up in the shared cache.
    $tls_log->{reset}->();
    my $cache = LWP::ConnCache->new( total_capacity => 5 );
    my $lax = Langertha::HTTP::UserAgent->new( connect_host => 'other.invalid', connect_address => '127.0.0.1',
      conn_cache => $cache, ssl_opts => { verify_hostname => 0, SSL_verify_mode => 1, SSL_ca_file => $ca } );
    my $strict = Langertha::HTTP::UserAgent->new( connect_host => 'other.invalid', connect_address => '127.0.0.1',
      conn_cache => $cache, ssl_opts => { verify_hostname => 1, SSL_ca_file => $ca } );
    my $res = $lax->get("https://other.invalid:$port/v1/models");
    ok $res->is_success, 'the lax agent got through without a name check' or diag $res->status_line;
    $res = $strict->get("https://other.invalid:$port/v1/models");
    is $res->code, 500, 'the strict agent refuses the cached socket';
    like $res->message, qr/certificate is not for other\.invalid/, '... by the name check';
    is scalar @{ $tls_log->{seen}->() }, 1, 'nothing was written over it';

    # No verification at all: the name matches, the chain was never verified.
    $tls_log->{reset}->();
    $cache = LWP::ConnCache->new( total_capacity => 5 );
    $lax = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '127.0.0.1',
      conn_cache => $cache, ssl_opts => { verify_hostname => 0, SSL_verify_mode => 0 } );
    $strict = Langertha::HTTP::UserAgent->new( connect_host => $PIN, connect_address => '127.0.0.1',
      conn_cache => $cache, ssl_opts => { verify_hostname => 1, SSL_ca_file => $ca } );
    $res = $lax->get("https://$PIN:$port/v1/models");
    ok $res->is_success, 'the unverifying agent got through' or diag $res->status_line;
    $res = $strict->get("https://$PIN:$port/v1/models");
    is $res->code, 500, 'the strict agent refuses the unverified cached socket';
    like $res->message, qr/certificate chain is not verified/, '... by the chain check';
    is scalar @{ $tls_log->{seen}->() }, 1, 'nothing was written over it';
  };

  subtest 'sync fallback shim over TLS' => sub {
    my $res = $sync_engine->($PIN)->async_request_f( $sync_engine->($PIN)->list_models_request )->get;
    ok $res->is_success, 'accepted' or diag $res->status_line;
  };

  skip 'Net::Async::HTTP not installed', 1 unless $HAVE_NAHTTP;
  my $loop = IO::Async::Loop->new;
  my $client = sub {
    my $http = Net::Async::HTTP->new( SSL_ca_file => $ca, pipeline => 0 );
    $loop->add($http);
    return $http;
  };
  my $async_engine = sub {
    my ( $host, $http ) = @_;
    return Langertha::Engine::OpenAI->new( url => "https://$host:$port/v1", api_key => "SEKRET-$host",
      connect_address => '127.0.0.1', _async_http => $http );
  };

  subtest 'Net::Async::HTTP over TLS' => sub {
    $tls_log->{reset}->();
    my $res = eval { $async_engine->( $PIN, $client->() )->async_request_f( $async_engine->( $PIN, $client->() )->list_models_request )->get };
    ok $res && $res->is_success, 'the certificate for the pinned name is accepted' or diag $@;
    my $wrong = $async_engine->( 'other.invalid', $client->() );
    my $f = $wrong->async_request_f( $wrong->list_models_request );
    $f->await;
    ok $f->is_failed, 'a name the certificate does not carry is refused';
    is scalar @{ $tls_log->{seen}->() }, 1, 'the wrong name sent nothing';
  };

  subtest 'Net::Async::HTTP shared by two pinned engines: no request rides a session verified for another name' => sub {
    # The client pools connections by host:port and host is the address, so
    # without the on_ready check engine B (other.invalid) reused engine A's
    # connection, verified for pinned.invalid, and its credential went there.
    $tls_log->{reset}->();
    my $shared = $client->();
    my $engine_a = $async_engine->( $PIN, $shared );
    my $engine_b = $async_engine->( 'other.invalid', $shared );
    my $res = $engine_a->async_request_f( $engine_a->list_models_request )->get;
    ok $res->is_success, 'A (the certificate has its name) is served';
    my $f = $engine_b->async_request_f( $engine_b->list_models_request );
    $f->await;
    ok $f->is_failed, "B is refused on A's connection";
    like( ( $f->failure )[0] // '', qr/connect_address 127\.0\.0\.1: the connection's certificate is not for other\.invalid/, '... by the name check' );
    is( ( $f->failure )[1], 'connect_address', '... with category connect_address' );
    is_deeply [ map { $_->{host} } @{ $tls_log->{seen}->() } ], [ "$PIN:$port" ], 'only A reached the server';
    $loop->delay_future( after => 0.05 )->get;   # the refused connection is closed on a later tick
    $res = eval { $engine_a->async_request_f( $engine_a->list_models_request )->get };
    ok $res && $res->is_success, 'A still works afterwards (on a new connection)' or diag $@;
  };

  subtest 'Net::Async::HTTP shared: requests queued behind a refused connection still run' => sub {
    # A, B and A again at once on one client (one connection per host, no
    # pipelining): B is refused on A's connection. Unless that connection is
    # closed, the second A stays queued for it forever.
    my $shared = $client->();
    my $engine_a = $async_engine->( $PIN, $shared );
    my $engine_b = $async_engine->( 'other.invalid', $shared );
    my @f = (
      $engine_a->async_request_f( $engine_a->list_models_request ),
      $engine_b->async_request_f( $engine_b->list_models_request ),
      $engine_a->async_request_f( $engine_a->list_models_request ),
    );
    my $all = Future->wait_all(@f);
    # without_cancel: the timeout must not cancel (and so "finish") the waiters.
    Future->wait_any( $all->without_cancel, $loop->delay_future( after => 10 ) )->get;
    ok $all->is_ready, 'all three finished within 10s (no request left waiting)'
      or return diag join ', ', map { $_->state } @f;
    ok $f[0]->is_done && $f[0]->get->is_success, 'the first A is served';
    ok $f[1]->is_failed && ( $f[1]->failure )[1] eq 'connect_address', 'B is refused with category connect_address';
    ok $f[2]->is_done && $f[2]->get->is_success, 'the second A is served on a new connection';
  };

  subtest 'Net::Async::HTTP: a pooled connection opened without verification does not pass' => sub {
    # The client trusts no test CA. A raw request with SSL_verify_mode => 0
    # leaves a connection to the address in the pool whose certificate has
    # the right name but was never verified; the pinned engine must not use it.
    $tls_log->{reset}->();
    my $http = Net::Async::HTTP->new( pipeline => 0 );
    $loop->add($http);
    my $raw = $http->do_request( request => HTTP::Request->new( GET => "https://$PIN:$port/v1/models" ),
      host => '127.0.0.1', SSL_verify_mode => 0, SSL_hostname => $PIN )->get;
    ok $raw->is_success, 'the unverified connection is in the pool';
    my $engine = $async_engine->( $PIN, $http );
    my $f = $engine->async_request_f( $engine->list_models_request );
    Future->wait_any( $f, $loop->delay_future( after => 10 ) )->await;
    ok $f->is_failed, 'the pinned request refuses it';
    like( ( $f->failure )[0] // '', qr/certificate chain is not verified/, '... by the chain check' );
    is scalar @{ $tls_log->{seen}->() }, 1, 'nothing was written over it';
  };
}

done_testing;
