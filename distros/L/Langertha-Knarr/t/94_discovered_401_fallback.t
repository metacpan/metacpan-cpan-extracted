use strict;
use warnings;
use Test2::V0;

# Maintainer decision 2026-09-30: a client SDK with a placeholder key (Bearer
# dummy) got the provider's 401 for a model Knarr knows only through
# auto_discover, since that model goes raw passthrough whenever the request
# carries some provider key (k47, k52). Now, when the upstream answers such a
# raw passthrough with 401, the request is answered through the handler
# chain instead -- Handler::Router, the engine that listed the model, Knarr's
# key -- and the client never sees the 401. Streaming too: the status is
# known before any byte goes to the client. The upstream is asked once, the
# request is traced once, with the fallback in its metadata. A model nobody
# configured or discovered still gets the upstream's 401, a configured model
# never reaches the upstream, and any other status passes through as before.
#
# Key-free: the passthrough upstream is a local server, the engines are
# offline LangerthaX fakes.

BEGIN {
  package LangerthaX::Engine::TestKnarr401;
  use Future;
  use Langertha::Response;
  our @chats;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub url { $_[0]{url} }
  sub chat_model { $_[0]{model} }
  sub list_models { $_[0]{url} =~ m{/v1\z} ? [ 'gpt-disc' ] : [ 'claude-disc' ] }
  sub chat_f {
    my ($self) = @_;
    push @chats, { model => $self->{model}, api_key => $self->{api_key} };
    return Future->done( Langertha::Response->new( content => 'from-engine', raw => {} ) );
  }
  $INC{'LangerthaX/Engine/TestKnarr401.pm'} = __FILE__;
}

{
  package MockTracer401;
  sub new { bless { events => [] }, shift }
  sub events { $_[0]{events} }
  sub start_trace {
    my ($self, %opts) = @_;
    push @{ $self->{events} }, { kind => 'start', %opts };
    return { trace_id => scalar @{ $self->{events} } };
  }
  sub end_trace {
    my ($self, $info, %opts) = @_;
    push @{ $self->{events} }, { kind => 'end', trace_id => $info->{trace_id}, %opts };
  }
}

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use Future;
use HTTP::Request;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my %SYNC = (
  '/v1/messages'         => qq({"content":[{"text":"from-upstream","type":"text"}],"stop_reason":"end_turn"}),
  '/v1/chat/completions' => qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"from-upstream","role":"assistant"}}]}),
);
my %STREAM = (
  '/v1/messages'         => qq(event: content_block_delta\ndata: {"delta":{"text":"from-upstream","type":"text_delta"},"type":"content_block_delta"}\n\nevent: message_stop\ndata: {"type":"message_stop"}\n\n),
  '/v1/chat/completions' => qq(data: {"choices":[{"delta":{"content":"from-upstream"},"index":0}]}\n\ndata: [DONE]\n\n),
);
# What the provider answers a key with; anything else is accepted.
my %REFUSED = ( 'sk-dummy' => 401, 'sk-forbidden' => 403, 'sk-limited' => 429, 'sk-broken' => 500 );
my $REFUSAL = qq({"error":{"message":"refused","type":"authentication_error"},"type":"error"});

my @hits;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    my $key = $req->header('x-api-key') // $req->header('Authorization') // '';
    $key =~ s/\ABearer\s+//i;
    push @hits, { path => $req->path, key => $key };
    if ( my $code = $REFUSED{$key} ) {
      my $resp = HTTP::Response->new($code);
      $resp->protocol('HTTP/1.1');
      $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $REFUSAL );
      $resp->content($REFUSAL);
      return $req->respond($resp);
    }
    if ( ( $req->body // '' ) =~ /"stream":true/ ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => 'text/event-stream' );
      $req->respond_chunk_header($head);
      $req->write_chunk( $STREAM{ $req->path } // '' );
      $req->write_chunk_eof;
      return;
    }
    my $body = $SYNC{ $req->path } // '{}';
    my $resp = HTTP::Response->new(200);
    $resp->protocol('HTTP/1.1');
    $resp->header( 'Content-Type' => 'application/json', 'Content-Length' => length $body );
    $resp->content($body);
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $up = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

# Wired like `knarr start --from-env` with Langfuse: both endpoints are the
# passthrough upstreams of their protocol and hold Knarr's own key; one
# tracer for the handler chain and the raw passthrough.
my $config = Langertha::Knarr::Config->new( data => {
  auto_discover => 1,
  passthrough   => { anthropic => $up, openai => $up },
  models        => {
    anthropic       => { engine => 'TestKnarr401', url => $up,       api_key => 'sk-knarr-anthropic' },
    openai          => { engine => 'TestKnarr401', url => "$up/v1", api_key => 'sk-knarr-openai' },
    'claude-pinned' => { engine => 'TestKnarr401', url => $up, model => 'claude-pinned', api_key => 'sk-knarr-anthropic' },
  },
} );
my $router = Langertha::Knarr::Router->new( config => $config );
my $pt = Langertha::Knarr::Handler::Passthrough->new( upstreams => $config->passthrough, loop => $loop );
my $tracer = MockTracer401->new;
my $knarr = Langertha::Knarr->new(
  handler => Langertha::Knarr::Handler::Tracing->new(
    wrapped => Langertha::Knarr::Handler::Router->new( router => $router, passthrough => $pt ),
    tracing => $tracer,
  ),
  router          => $router,
  raw_passthrough => $pt,
  tracing         => $tracer,
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my %path = ( anthropic => '/v1/messages', openai => '/v1/chat/completions' );
my %key_header = ( anthropic => 'x-api-key', openai => 'Authorization' );

sub send_chat {
  my ($transport, $protocol, $model, $key, $stream) = @_;
  my $body = $json->encode({ model => $model, messages => [ { role => 'user', content => 'hi' } ],
    ( $protocol eq 'anthropic' ? ( max_tokens => 5 ) : () ),
    ( $stream ? ( stream => JSON::MaybeXS::true() ) : () ) });
  my @h = ( 'Content-Type' => 'application/json',
    $key_header{$protocol} => ( $protocol eq 'openai' ? "Bearer $key" : $key ) );
  @hits = (); @LangerthaX::Engine::TestKnarr401::chats = (); @{ $tracer->events } = ();
  return $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port$path{$protocol}", \@h, $body ) )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path{$protocol}", \@h, $body ) );
}

# The engine's answer in the client protocol's shape.
sub engine_text {
  my ($protocol, $resp, $stream) = @_;
  return $resp->content if $stream;
  my $data = eval { $json->decode( $resp->content ) } or return '';
  return $protocol eq 'anthropic'
    ? $data->{content}[0]{text}
    : $data->{choices}[0]{message}{content};
}

my %END_MARKER = ( anthropic => qr/event: message_stop\ndata: [^\n]*\n\n\z/, openai => qr/data: \[DONE\]\n\n\z/ );
my %DISCOVERED = ( anthropic => 'claude-disc', openai => 'gpt-disc' );

for my $transport ( 'native', 'psgi' ) {
  for my $protocol ( 'anthropic', 'openai' ) {
    for my $stream ( 0, 1 ) {
      my $label = "$transport $protocol" . ( $stream ? ' stream' : '' );
      my $model = $DISCOVERED{$protocol};

      # A discovered model the upstream refuses the client's key for: the
      # engine answers, with Knarr's key.
      {
        my $resp = send_chat( $transport, $protocol, $model, 'sk-dummy', $stream );
        is( $resp->code, 200, "$label: 401 for a discovered model: the client gets 200" );
        like( engine_text( $protocol, $resp, $stream ), qr/from-engine/,
          "$label: ...with the engine's answer" );
        unlike( $resp->content, qr/refused|from-upstream/, "$label: ...and nothing of the upstream's" );
        like( $resp->content, $END_MARKER{$protocol}, "$label: ...ended by the protocol's end marker" )
          if $stream;
        like( scalar $resp->header('Content-Type'),
          $stream ? qr/text\/event-stream/ : qr/application\/json/, "$label: ...in the protocol's content type" );
        is( [ map { $_->{key} } @hits ], [ 'sk-dummy' ], "$label: the upstream was asked exactly once" );
        is( [ map { $_->{api_key} } @LangerthaX::Engine::TestKnarr401::chats ], [ "sk-knarr-$protocol" ],
          "$label: the engine answered once, with Knarr's key" );
        my @ev = @{ $tracer->events };
        is( [ map { $_->{kind} } @ev ], [ 'start', 'end' ], "$label: one trace" );
        isnt( $ev[0]{engine}, 'passthrough', "$label: traced by the handler chain" );
        is( $ev[0]{passthrough_fallback}, 401, "$label: the trace records the fallback" );
        is( $ev[1]{output}, 'from-engine', "$label: the trace holds the engine's answer" );
      }

      # The client's own key is accepted: raw passthrough as before, one
      # trace, dated from when the request went out.
      {
        my $resp = send_chat( $transport, $protocol, $model, 'sk-own', $stream );
        is( $resp->code, 200, "$label: own key: 200" );
        is( $resp->content, ( $stream ? \%STREAM : \%SYNC )->{ $path{$protocol} },
          "$label: own key: the upstream's bytes 1:1" );
        is( scalar @hits, 1, "$label: own key: one upstream request" );
        is( \@LangerthaX::Engine::TestKnarr401::chats, [], "$label: own key: no engine call" );
        my @ev = @{ $tracer->events };
        is( [ map { $_->{kind} } @ev ], [ 'start', 'end' ], "$label: own key: one trace" );
        is( $ev[0]{engine}, 'passthrough', "$label: own key: traced as passthrough" );
        is( ref $ev[0]{start_hires}, 'ARRAY', "$label: own key: started at the request's send time" );
        ok( !exists $ev[0]{passthrough_fallback}, "$label: own key: no fallback recorded" );
      }

      # Any other refusal of a discovered model passes through unchanged.
      for my $key ( 'sk-forbidden', 'sk-limited', 'sk-broken' ) {
        my $resp = send_chat( $transport, $protocol, $model, $key, $stream );
        is( $resp->code, $REFUSED{$key}, "$label: $REFUSED{$key} passes through" );
        is( $resp->content, $REFUSAL, "$label: $REFUSED{$key}: the upstream's body 1:1" );
        is( scalar @hits, 1, "$label: $REFUSED{$key}: one upstream request" );
        is( \@LangerthaX::Engine::TestKnarr401::chats, [], "$label: $REFUSED{$key}: no engine call" );
        is( [ map { $_->{kind} } @{ $tracer->events } ], [ 'start', 'end' ], "$label: $REFUSED{$key}: one trace" );
      }

      # A model nobody configured or discovered: the upstream's 401 as is.
      {
        my $resp = send_chat( $transport, $protocol, 'nobody-knows', 'sk-dummy', $stream );
        is( $resp->code, 401, "$label: unknown model: the upstream's 401" );
        is( $resp->content, $REFUSAL, "$label: unknown model: the upstream's body 1:1" );
        is( scalar @hits, 1, "$label: unknown model: one upstream request" );
        is( \@LangerthaX::Engine::TestKnarr401::chats, [], "$label: unknown model: no engine call" );
        my @ev = @{ $tracer->events };
        is( [ map { $_->{kind} } @ev ], [ 'start', 'end' ], "$label: unknown model: one trace" );
        is( $ev[0]{engine}, 'passthrough', "$label: unknown model: traced as passthrough" );
      }
    }
  }

  # An explicitly configured model never reaches the upstream at all.
  {
    my $resp = send_chat( $transport, 'anthropic', 'claude-pinned', 'sk-dummy', 0 );
    is( $resp->code, 200, "$transport: configured model: 200" );
    is( engine_text( 'anthropic', $resp, 0 ), 'from-engine', "$transport: configured model: the engine's answer" );
    is( \@hits, [], "$transport: configured model: never reaches the upstream" );
    ok( !exists $tracer->events->[0]{passthrough_fallback}, "$transport: configured model: no fallback recorded" );
  }
}

# The real tracer: the fallback lands in the trace's metadata, and a trace
# started late keeps the start time it is given.
{
  package CapturingHTTP401;
  sub new { bless {}, shift }
  sub do_request { Future->done( HTTP::Response->new(200) ) }
}
{
  my $tracing = Langertha::Knarr::Tracing->new(
    config => Langertha::Knarr::Config->new( data => { models => {},
      langfuse => { public_key => 'pk-lf-test', secret_key => 'sk-lf-test', url => 'http://127.0.0.1:1' } } ),
    _http => CapturingHTTP401->new,
  );
  my $trace = $tracing->start_trace( model => 'm', format => 'anthropic', passthrough_fallback => 401,
    start_hires => [ 1_700_000_000, 250_000 ] );
  my ($create) = grep { $_->{type} eq 'trace-create' } @{ $tracing->_batch };
  my ($gen)    = grep { $_->{type} eq 'generation-create' } @{ $tracing->_batch };
  is( $create->{body}{metadata}{passthrough_fallback}, 401, 'Tracing: passthrough_fallback in the trace metadata' );
  like( $gen->{body}{startTime}, qr/\A2023-11-14T22:13:20\.250/, 'Tracing: start_hires sets the start time' );
  is( $trace->{start_hires}, [ 1_700_000_000, 250_000 ], 'Tracing: and anchors the trace to it' );

  $tracing->_batch([]);
  $tracing->start_trace( model => 'm', format => 'anthropic' );
  ($create) = grep { $_->{type} eq 'trace-create' } @{ $tracing->_batch };
  ok( !exists $create->{body}{metadata}{passthrough_fallback}, 'Tracing: no fallback key without a fallback' );
}

done_testing;
