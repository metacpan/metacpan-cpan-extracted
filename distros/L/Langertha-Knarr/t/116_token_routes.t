use strict;
use warnings;
use Test2::V0;

# k82: under token auth a request goes where its token's provider column
# says (routes:), with Knarr's key for that route from the environment:
# `local` to an OpenAI-compatible upstream (Skeid), `openai` / `anthropic` to
# that provider's Langertha engine. A provider without a route is refused
# with 403 and nothing is sent; an unset key variable is a 503. The client's
# token reaches no upstream, and neither the token, its hash nor a route key
# shows up in an answer, a log line, the request log or a Langfuse payload.
#
# Key-free and offline: every upstream is a local mock server, the keys are
# made up, Langfuse is a fake that keeps its batches.

BEGIN {
  # Nothing of the host may leak in: engines read Langfuse keys from the
  # environment, and the request log its file.
  delete @ENV{ grep { /\A(?:LANGFUSE_|KNARR_|LANGERTHA_)/ } keys %ENV };
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
use Path::Tiny;
use Digest::SHA qw( sha256_hex );
use Log::Any::Adapter;

my @logs;
Log::Any::Adapter->set( 'Capture', to => \@logs, log_level => 'trace' );

use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Config;
use Langertha::Knarr::Tracing;
use Langertha::Knarr::RequestLog;
use Langertha::Knarr::Handler::Tracing;
use Langertha::Knarr::Handler::RequestLog;
use Langertha::Knarr::Handler::TokenRoutes;
use Langertha::Knarr::Authorizer::Token;
use Langertha::Knarr::TokenStore::Memory;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

sub serve {
  my ($on_request) = @_;
  my $server = Net::Async::HTTP::Server->new( on_request => $on_request );
  $loop->add($server);
  $server->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
  return 'http://127.0.0.1:' . $server->read_handle->sockport;
}

# --- The upstreams: one mock that plays Skeid (/skeid/v1), OpenAI
# (/openai/v1) and Anthropic (/anthropic/v1/messages), and keeps every request.
my ( @received, @all_received );
my $mock = serve( sub {
  my ( $srv, $req ) = @_;
  my $headers = join "\n", map { "$_->[0]: $_->[1]" } $req->headers;
  push @all_received, "$headers\n" . ( $req->body // '' );
  push @received, { path => $req->path, headers => $headers, body => $req->body // '',
    auth => scalar $req->header('Authorization'), api_key => scalar $req->header('x-api-key') };
  my $data = eval { $json->decode( $req->body ) } || {};
  my ($who) = $req->path =~ m{\A/(\w+)/};
  my $resp = HTTP::Response->new(200);
  $resp->protocol('HTTP/1.1');
  if ( $req->path =~ m{/v1/messages\z} ) {
    $resp->content_type('application/json');
    $resp->content( $json->encode({ id => 'msg_1', type => 'message', role => 'assistant',
      model => $data->{model}, content => [ { type => 'text', text => "from $who" } ],
      stop_reason => 'end_turn', usage => { input_tokens => 3, output_tokens => 2 } }) );
  }
  elsif ( $data->{stream} ) {
    $resp->content_type('text/event-stream');
    $resp->content( join '',
      map { 'data: ' . $json->encode($_) . "\n\n" }
        { id => 'c1', object => 'chat.completion.chunk', model => $data->{model},
          choices => [ { index => 0, delta => { role => 'assistant', content => 'from ' } } ] },
        { id => 'c1', object => 'chat.completion.chunk', model => $data->{model},
          choices => [ { index => 0, delta => { content => $who }, finish_reason => 'stop' } ] } );
    $resp->add_content("data: [DONE]\n\n");
  }
  else {
    $resp->content_type('application/json');
    $resp->content( $json->encode({ id => 'c1', object => 'chat.completion', model => $data->{model},
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => "from $who" } } ],
      usage => { prompt_tokens => 3, completion_tokens => 2, total_tokens => 5 } }) );
  }
  $resp->content_length( length $resp->content );
  $req->respond($resp);
} );

# --- Fake Langfuse.
my @batches;
my $langfuse = serve( sub {
  my ( $srv, $req ) = @_;
  push @batches, $req->body;
  my $resp = HTTP::Response->new(207);
  $resp->content_type('application/json');
  $resp->content('{"successes":[],"errors":[]}');
  $resp->content_length( length $resp->content );
  $req->respond($resp);
} );

# --- Keys and tokens.
my %KEY = (
  SKEID_TEST_KEY     => 'sk-skeid-route-key-111',
  OPENAI_TEST_KEY    => 'sk-openai-route-key-222',
  ANTHROPIC_TEST_KEY => 'sk-ant-route-key-333',
);
$ENV{$_} = $KEY{$_} for keys %KEY;
delete $ENV{UNSET_TEST_KEY};

my %TOKEN = (
  local     => [ 'tok-local-aaaaaaaaaaaa',     'skeid-model' ],
  openai    => [ 'tok-openai-bbbbbbbbbbbb',    'gpt-test' ],
  anthropic => [ 'tok-anthropic-cccccccccccc', 'claude-test' ],
  mistral   => [ 'tok-noroute-dddddddddddd',   'mistral-test' ],
  nokey     => [ 'tok-nokey-eeeeeeeeeeee',     'nokey-model' ],
);
my $store = Langertha::Knarr::TokenStore::Memory->new;
$store->add( token => $TOKEN{$_}[0], model => $TOKEN{$_}[1], provider => $_, expires => time + 900 )
  for keys %TOKEN;
my @secrets = ( values %KEY, map { ( $_->[0], sha256_hex( $_->[0] ) ) } values %TOKEN );
my $SECRET_RE = join '|', map { quotemeta } @secrets;
$SECRET_RE = qr/$SECRET_RE/i;

# --- The chain knarr start builds: request log outside, tracing, the routes.
my $logfile = Path::Tiny->tempfile( SUFFIX => '.jsonl' );
my $config = Langertha::Knarr::Config->new( data => {
  langfuse => { public_key => 'pk-lf-test', secret_key => 'sk-lf-test', url => $langfuse },
  logging  => { file => $logfile->stringify },
} );
my $routes = Langertha::Knarr::Handler::TokenRoutes->new( routes => {
  local     => { upstream => "$mock/skeid/v1", key_env => 'SKEID_TEST_KEY' },
  openai    => { provider => 'openai', url => "$mock/openai/v1", key_env => 'OPENAI_TEST_KEY' },
  anthropic => { provider => 'anthropic', url => "$mock/anthropic", key_env => 'ANTHROPIC_TEST_KEY' },
  nokey     => { upstream => "$mock/nokey/v1", key_env => 'UNSET_TEST_KEY' },
} );
my $handler = Langertha::Knarr::Handler::RequestLog->new(
  request_log => Langertha::Knarr::RequestLog->new( config => $config ),
  wrapped     => Langertha::Knarr::Handler::Tracing->new(
    tracing => Langertha::Knarr::Tracing->new( config => $config ),
    wrapped => $routes,
  ),
);
my $knarr = Langertha::Knarr->new(
  handler    => $handler,
  authorizer => Langertha::Knarr::Authorizer::Token->new( store => $store ),
  loop       => $loop,
  listen     => ['127.0.0.1:0'],
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

my @answers;
sub run_both {
  my ( $path, $body, $token ) = @_;
  my @h = ( Authorization => "Bearer $token", 'x-api-key' => $token, 'Content-Type' => 'application/json' );
  my $content = $json->encode($body);
  my $native = $http->do_request(
    request => HTTP::Request->new( POST => "http://127.0.0.1:$port$path", \@h, $content ) )->get;
  my $p = $psgi->request( HTTP::Request->new( POST => "http://localhost$path", \@h, $content ) );
  push @answers, map { $_->as_string } $native, $p;
  return ( $native, $p );
}

my $msgs = [ { role => 'user', content => 'hello' } ];
sub openai_body { { model => $_[0], messages => $msgs, ( $_[1] ? ( stream => JSON::MaybeXS::true() ) : () ) } }

subtest 'local: the OpenAI-compatible upstream, with the route key' => sub {
  @received = ();
  my ( $n, $p ) = run_both( '/v1/chat/completions', openai_body('skeid-model'), $TOKEN{local}[0] );
  is( [ $n->code, $p->code ], [ 200, 200 ], 'answered on both transports' );
  is( $json->decode( $n->decoded_content )->{choices}[0]{message}{content}, 'from skeid', 'the upstream answered' );
  is( scalar @received, 2, 'one upstream request per transport' );
  for my $r (@received) {
    is( $r->{path}, '/skeid/v1/chat/completions', 'to the route upstream' );
    is( $r->{auth}, "Bearer $KEY{SKEID_TEST_KEY}", 'with the key from key_env' );
    is( $json->decode( $r->{body} )->{model}, 'skeid-model', 'for the token model' );
  }
};

subtest 'local, streamed' => sub {
  @received = ();
  my ( $n, $p ) = run_both( '/v1/chat/completions', openai_body( 'skeid-model', 1 ), $TOKEN{local}[0] );
  is( [ $n->code, $p->code ], [ 200, 200 ], 'stream answered' );
  for my $res ( $n, $p ) {
    like( $res->decoded_content, qr/from .*skeid/s, 'upstream text streamed' );
    like( $res->decoded_content, qr/data: \[DONE\]\n\n\z/, 'ends with the OpenAI end marker' );
  }
  is( [ map { $_->{auth} } @received ], [ ("Bearer $KEY{SKEID_TEST_KEY}") x 2 ], 'route key upstream' );
};

subtest 'openai: the provider engine' => sub {
  @received = ();
  my ( $n, $p ) = run_both( '/v1/chat/completions', openai_body('gpt-test'), $TOKEN{openai}[0] );
  is( [ $n->code, $p->code ], [ 200, 200 ], 'answered' );
  is( [ map { $_->{path} } @received ], [ ('/openai/v1/chat/completions') x 2 ], 'to the provider' );
  is( [ map { $_->{auth} } @received ], [ ("Bearer $KEY{OPENAI_TEST_KEY}") x 2 ], 'with its key' );
  isa_ok( $routes->router->engine_for( $routes->route_def( openai => 'gpt-test' ), 'gpt-test' ),
    ['Langertha::Engine::OpenAI'], 'provider openai' );
};

subtest 'anthropic: the provider engine, any client protocol' => sub {
  @received = ();
  my ( $n, $p ) = run_both( '/api/chat',
    { model => 'claude-test', messages => $msgs, stream => JSON::MaybeXS::false() }, $TOKEN{anthropic}[0] );
  is( [ $n->code, $p->code ], [ 200, 200 ], 'answered' );
  is( $json->decode( $n->decoded_content )->{message}{content}, 'from anthropic', 'Ollama face, Anthropic answer' );
  is( [ map { $_->{path} } @received ], [ ('/anthropic/v1/messages') x 2 ], 'to the provider' );
  is( [ map { $_->{api_key} } @received ], [ ( $KEY{ANTHROPIC_TEST_KEY} ) x 2 ], 'with its key' );
  is( [ map { $json->decode( $_->{body} )->{model} } @received ], [ ('claude-test') x 2 ], 'token model' );
};

subtest 'a provider without a route: 403, nothing sent' => sub {
  @received = ();
  my ( $n, $p ) = run_both( '/v1/chat/completions', openai_body('mistral-test'), $TOKEN{mistral}[0] );
  is( [ $n->code, $p->code ], [ 403, 403 ], 'refused' );
  is( $p->decoded_content, $n->decoded_content, 'same answer' );
  like( $n->decoded_content, qr/forbidden: no route for this token/, 'the reason' );
  ( $n, $p ) = run_both( '/v1/messages', { model => 'mistral-test', max_tokens => 5, messages => $msgs },
    $TOKEN{mistral}[0] );
  is( [ $n->code, $p->code ], [ 403, 403 ], 'refused on the Anthropic face' );
  is( $json->decode( $n->decoded_content )->{type}, 'error', 'in its error shape' );
  ( $n, $p ) = run_both( '/v1/chat/completions', openai_body( 'mistral-test', 1 ), $TOKEN{mistral}[0] );
  is( [ $n->code, $p->code ], [ 403, 403 ], 'a stream is refused with a status' );
  unlike( $n->decoded_content, qr/\[DONE\]/, 'no stream started' );
  is( \@received, [], 'no upstream request' );
};

subtest 'key variable unset: 503, nothing sent, the log names the variable only' => sub {
  @received = ();
  my $from = @logs;
  my ( $n, $p ) = run_both( '/v1/chat/completions', openai_body('nokey-model'), $TOKEN{nokey}[0] );
  is( [ $n->code, $p->code ], [ 503, 503 ], 'unavailable' );
  unlike( $n->decoded_content, qr/UNSET_TEST_KEY/, 'the answer does not name the variable' );
  ok( ( grep { ( $_->[2] // "" ) =~ /UNSET_TEST_KEY/ } @logs[ $from .. $#logs ] ), 'the log does' );
  is( \@received, [], 'no upstream request' );
};

subtest 'no token, hash or route key anywhere' => sub {
  # Let Langfuse get its batches.
  my $deadline = time + 5;
  $loop->loop_once(0.05) until @batches || time > $deadline;
  $loop->loop_once(0.05) for 1 .. 10;
  ok( scalar @batches, 'Langfuse received batches' );
  ok( -s $logfile, 'the request log was written' );
  ok( scalar @logs, 'there are log lines' );

  my @tokens = map { quotemeta $_->[0] } values %TOKEN;
  my $TOKEN_RE = join '|', @tokens;
  ok( scalar @all_received, 'the upstreams were asked' );
  unlike( join( "\n", @all_received ), qr/$TOKEN_RE/, 'no client token in any upstream request' );
  unlike( join( "\n", @answers ), $SECRET_RE, 'no secret in any answer' );
  unlike( join( "\n", map { $_->[2] // "" } @logs ), $SECRET_RE, 'no secret in any log line' );
  unlike( $logfile->slurp_raw, $SECRET_RE, 'no secret in the request log' );
  unlike( join( "\n", @batches ), $SECRET_RE, 'no secret in a Langfuse payload' );
};

done_testing;
