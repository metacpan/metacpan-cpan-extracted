use strict;
use warnings;
use Test2::V0;

# k47 (maintainer decision 2026-09-29): with auto_discover and passthrough
# both on (--from-env, the Docker image), every model the provider listed
# counted as configured and went through the Langertha engine -- Claude Code
# lost the 1:1 bytes (cache_control, usage, tool_use details). Now a model
# known ONLY through auto_discover goes raw passthrough when the client's
# protocol has a passthrough upstream and the model was discovered from that
# very upstream. Explicitly configured models are still routed; a model
# discovered from another provider is still routed (its passthrough upstream
# would not know it); a protocol without an upstream still goes to the
# engine (k41). Discovery keeps feeding the model lists.
#
# Key-free: the passthrough upstream is a local server, the engines are
# offline LangerthaX fakes.

BEGIN {
  package LangerthaX::Engine::TestKnarrDisc;
  use Future;
  use Langertha::Response;
  our @chats;
  sub new { my ($class, %args) = @_; bless \%args, $class }
  sub url { $_[0]{url} }
  sub chat_model { $_[0]{model} }
  # What the provider behind this URL lists.
  sub list_models {
    my ($self) = @_;
    return $self->{url} =~ /other\.invalid/ ? [ 'other-disc' ] : [ 'claude-disc', 'claude-pinned' ];
  }
  sub chat_f {
    my ($self) = @_;
    push @chats, $self->{model};
    return Future->done( Langertha::Response->new( content => 'from-engine', raw => {} ) );
  }
  $INC{'LangerthaX/Engine/TestKnarrDisc.pm'} = __FILE__;
}

BEGIN {
  eval { require Plack::Test; 1 }
    or plan skip_all => 'Plack::Test required for this test';
}
use Plack::Test;
use HTTP::Request;
use HTTP::Response;
use IO::Async::Loop;
use Net::Async::HTTP;
use Net::Async::HTTP::Server;
use JSON::MaybeXS;

use Langertha::Knarr;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Router;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::PSGI;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;

my $SYNC   = qq({"content":[{"text":"from-upstream \xc3\xa4","type":"text"}],"id":"msg_up","stop_reason":"end_turn","usage":{"cache_read_input_tokens":7,"input_tokens":1}});
my @STREAM = ( qq(event: content_block_delta\ndata: {"delta":{"text":"up","type":"text_delta"},"type":"content_block_delta"}\n\n),
  qq(event: message_stop\ndata: {"type":"message_stop"}\n\n) );
my $OPENAI = qq({"choices":[{"finish_reason":"stop","index":0,"message":{"content":"from-upstream","role":"assistant"}}],"id":"up"});

my @hits;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ($srv, $req) = @_;
    push @hits, { path => $req->path, body => $req->body };
    if ( ( $req->body // '' ) =~ /"stream":true/ ) {
      my $head = HTTP::Response->new(200);
      $head->protocol('HTTP/1.1');
      $head->header( 'Content-Type' => 'text/event-stream' );
      $req->respond_chunk_header($head);
      $req->write_chunk($_) for @STREAM;
      $req->write_chunk_eof;
      return;
    }
    my $body = $req->path eq '/v1/messages' ? $SYNC : $OPENAI;
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

# Wired like `knarr start`: Handler::Router with the passthrough fallback,
# and the same passthrough as Knarr's raw passthrough.
my $config = Langertha::Knarr::Config->new( data => {
  auto_discover => 1,
  passthrough   => { anthropic => $up, openai => $up },
  models        => {
    anthropic       => { engine => 'TestKnarrDisc', url => $up },
    other           => { engine => 'TestKnarrDisc', url => 'http://other.invalid/v1' },
    'claude-pinned' => { engine => 'TestKnarrDisc', url => $up, model => 'claude-pinned' },
  },
} );
my $router = Langertha::Knarr::Router->new( config => $config );
my $pt = Langertha::Knarr::Handler::Passthrough->new( upstreams => $config->passthrough, loop => $loop );
my $knarr = Langertha::Knarr->new(
  handler         => Langertha::Knarr::Handler::Router->new( router => $router, passthrough => $pt ),
  router          => $router,
  raw_passthrough => $pt,
  loop            => $loop,
  listen          => [ '127.0.0.1:0' ],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

my $msgs = [ { role => 'user', content => 'hi' } ];
my %path = ( anthropic => '/v1/messages', openai => '/v1/chat/completions', ollama => '/api/chat' );

sub send_chat {
  my ($transport, $protocol, $model, %extra) = @_;
  my $body = $json->encode({ model => $model, messages => $msgs,
    ( $protocol eq 'anthropic' ? ( max_tokens => 5 ) : () ),
    ( $protocol eq 'ollama' ? ( stream => JSON::MaybeXS::false() ) : () ), %extra });
  my @h = ( 'Content-Type' => 'application/json', 'x-api-key' => 'sk-client-own' );
  @hits = (); @LangerthaX::Engine::TestKnarrDisc::chats = ();
  my $resp = $transport eq 'native'
    ? $http->do_request( request =>
        HTTP::Request->new( POST => "http://127.0.0.1:$port$path{$protocol}", \@h, $body ) )->get
    : $psgi->request( HTTP::Request->new( POST => "http://localhost$path{$protocol}", \@h, $body ) );
  return ( $resp, $body );
}

for my $transport ( 'native', 'psgi' ) {
  # A model only discovery knows, from this protocol's upstream: raw.
  {
    my ($resp, $sent) = send_chat( $transport, anthropic => 'claude-disc' );
    is( $resp->code, 200, "$transport: discovered claude-disc answered" );
    is( $resp->content, $SYNC, "$transport: discovered model: the upstream's bytes 1:1" );
    is( scalar @hits, 1, "$transport: discovered model: reached the passthrough upstream" );
    is( $hits[0]{body}, $sent, "$transport: discovered model: client body forwarded 1:1" );
    is( \@LangerthaX::Engine::TestKnarrDisc::chats, [], "$transport: discovered model: no engine call" );
  }
  {
    my ($resp) = send_chat( $transport, anthropic => 'claude-disc', stream => JSON::MaybeXS::true() );
    is( $resp->content, join( '', @STREAM ), "$transport: discovered model stream: upstream SSE 1:1" );
    is( scalar @hits, 1, "$transport: discovered model stream: reached the upstream" );
  }

  # Explicitly configured: routed, even though the provider lists it too.
  for my $model ( 'claude-pinned', 'anthropic' ) {
    my ($resp) = send_chat( $transport, anthropic => $model );
    is( $resp->code, 200, "$transport: configured $model answered" );
    like( $resp->content, qr/from-engine/, "$transport: configured $model goes through the engine" );
    is( scalar @hits, 0, "$transport: configured $model never reaches the passthrough" );
  }

  # Discovered from another provider: its engine, not this protocol's upstream.
  {
    my ($resp) = send_chat( $transport, openai => 'other-disc' );
    like( $resp->content, qr/from-engine/, "$transport: other-disc (other provider) goes through its engine" );
    is( scalar @hits, 0, "$transport: other-disc never reaches the openai upstream" );
  }

  # No passthrough upstream for the protocol: engine routing as before (k41).
  {
    my ($resp) = send_chat( $transport, ollama => 'claude-disc' );
    like( $resp->content, qr/from-engine/, "$transport: ollama (no upstream): discovered model via engine" );
    is( scalar @hits, 0, "$transport: ollama: no passthrough" );
  }

  # Unknown model: passthrough as before.
  {
    my ($resp) = send_chat( $transport, anthropic => 'nobody-knows' );
    is( $resp->content, $SYNC, "$transport: unknown model still passes through" );
  }
}

# Discovery still feeds the model list.
{
  my $resp = $http->do_request( uri => "http://127.0.0.1:$port/v1/models" )->get;
  my %ids = map { $_->{id} => 1 } @{ $json->decode( $resp->content )->{data} };
  ok( $ids{'claude-disc'}, '/v1/models lists the discovered model' );
  ok( $ids{'other-disc'}, '/v1/models lists the other provider\'s discovered model' );
}

done_testing;
