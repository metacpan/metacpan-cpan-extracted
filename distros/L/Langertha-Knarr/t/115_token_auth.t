use strict;
use warnings;
use Test2::V0;

# k82: token auth per model. A platform issues a short-lived token for one
# model; Knarr checks it against a token store (here the in-memory one) in two
# phases: identify before the body is read (unknown / expired / missing token
# 401, store unavailable 503), authorize once action and model are known
# (another model 403). The model lists show only the token's model, a request
# without a model gets the token's, and the client's token never goes
# upstream: no raw passthrough, no Authorization / x-api-key in what a
# passthrough handler would forward. Native server and PSGI answer alike;
# a refused stream gets its status before any 200.

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
use Future;

use Langertha::Knarr;
use Langertha::Knarr::PSGI;
use Langertha::Knarr::Config;
use Langertha::Knarr::Router;
use Langertha::Knarr::Handler::Code;
use Langertha::Knarr::Handler::Passthrough;
use Langertha::Knarr::Authorizer::Token;
use Langertha::Knarr::TokenStore::Memory;

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
my $loop = IO::Async::Loop->new;
my $http = Net::Async::HTTP->new( max_connections_per_host => 0 );
$loop->add($http);

# --- A passthrough upstream that must never be asked.
my @upstream_hits;
my $upstream = Net::Async::HTTP::Server->new(
  on_request => sub {
    my ( $srv, $req ) = @_;
    push @upstream_hits, $req->path;
    my $resp = HTTP::Response->new(200);
    $resp->content_type('application/json');
    $resp->content('{"choices":[{"message":{"role":"assistant","content":"from-upstream"}}]}');
    $resp->content_length( length $resp->content );
    $req->respond($resp);
  },
);
$loop->add($upstream);
$upstream->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $upstream_url = 'http://127.0.0.1:' . $upstream->read_handle->sockport;

# --- Tokens.
my $TOKEN   = 'tok-valid-0123456789';
my $OTHER   = 'tok-other-0123456789';
my $EXPIRED = 'tok-expired-01234567';
my $store = Langertha::Knarr::TokenStore::Memory->new;
$store->add( token => $TOKEN,   model => 'm-allowed', provider => 'p', expires => time + 900 );
$store->add( token => $OTHER,   model => 'm-other',   provider => 'p', expires => time + 900 );
$store->add( token => $EXPIRED, model => 'm-allowed', provider => 'p', expires => time - 10 );

# --- A handler that records what reached it.
my @calls;
my $handler = Langertha::Knarr::Handler::Code->new(
  code => sub {
    my ( $session, $req ) = @_;
    push @calls, { kind => 'chat', model => $req->model, grant => $req->grant,
      extra => { %{ $req->extra } }, fwd => [ $req->forward_header_pairs ] };
    return 'answer for ' . ( $req->model // 'none' );
  },
  stream_code => sub {
    my ( $session, $req ) = @_;
    push @calls, { kind => 'stream', model => $req->model, grant => $req->grant };
    my @p = ( 'tok', 'en' );
    return sub { @p ? shift @p : undef };
  },
  models => [ map { { id => $_, object => 'model' } } qw( m-allowed m-other m-secret ) ],
);

my $authorizer = Langertha::Knarr::Authorizer::Token->new( store => $store );
my $knarr = Langertha::Knarr->new(
  handler    => $handler,
  authorizer => $authorizer,
  loop       => $loop,
  listen     => ['127.0.0.1:0'],
  # Everything a raw passthrough needs: an unknown model would go upstream
  # with the client's key under the static key -- never under a token.
  router          => Langertha::Knarr::Router->new( config => Langertha::Knarr::Config->new( data => { models => {} } ) ),
  raw_passthrough => Langertha::Knarr::Handler::Passthrough->new(
    upstreams => { openai => $upstream_url, anthropic => $upstream_url, ollama => $upstream_url },
    loop      => $loop,
  ),
);
$knarr->start;
my $port = $knarr->_server->read_handle->sockport;
my $psgi = Plack::Test->create( Langertha::Knarr::PSGI->new( knarr => $knarr )->to_app );

sub bearer { [ Authorization => "Bearer $_[0]" ] }

# Native and PSGI answer for one request; $body is a hashref (JSON) or a string.
sub run_both {
  my ( $method, $path, $body, $headers ) = @_;
  my $content = !defined $body ? undef : ref $body ? $json->encode($body) : $body;
  my @h = ( @{ $headers // [] }, defined $content ? ( 'Content-Type' => 'application/json' ) : () );
  my $native = $http->do_request(
    request => HTTP::Request->new( $method => "http://127.0.0.1:$port$path", \@h, $content ) )->get;
  my $p = $psgi->request( HTTP::Request->new( $method => "http://localhost$path", \@h, $content ) );
  return ( $native, $p );
}

# Both transports give $status; same status, content type and body.
sub both_are {
  my ( $status, $method, $path, $body, $headers, $name ) = @_;
  my ( $native, $p ) = run_both( $method, $path, $body, $headers );
  is( $native->code, $status, "$name: native $status" )
    or diag $native->decoded_content;
  is( $p->code, $status, "$name: PSGI $status" ) or diag $p->decoded_content;
  # A streamed answer carries timestamps and ids; refusals and buffered
  # JSON answers must be the same bytes.
  if ( $status != 200 ) {
    is( $p->header('Content-Type'), $native->header('Content-Type'), "$name: same content type" );
    is( $p->decoded_content, $native->decoded_content, "$name: same body" );
  }
  return ( $native, $p );
}

my $msgs = [ { role => 'user', content => 'hi' } ];
my %chat = (
  openai    => [ '/v1/chat/completions', sub { { model => $_[0], messages => $msgs } } ],
  anthropic => [ '/v1/messages', sub { { model => $_[0], max_tokens => 10, messages => $msgs } } ],
  ollama    => [ '/api/chat', sub { { model => $_[0], messages => $msgs, stream => JSON::MaybeXS::false() } } ],
  generate  => [ '/api/generate', sub { { model => $_[0], prompt => 'hi', stream => JSON::MaybeXS::false() } } ],
  acp       => [ '/runs', sub { { agent_name => $_[0], mode => 'sync',
    input => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ] } } ],
  agui      => [ '/awp', sub { { model => $_[0], threadId => 't', runId => 'r', messages => $msgs } } ],
);

subtest 'a valid token for its model: 200 on every chat protocol, nothing upstream' => sub {
  for my $proto ( sort keys %chat ) {
    my ( $path, $body ) = @{ $chat{$proto} };
    @calls = ();
    my ($native) = both_are( 200, POST => $path, $body->('m-allowed'), bearer($TOKEN), "$proto valid token" );
    # AG-UI always streams (the stream handler answers).
    like( $native->decoded_content, qr/answer for m-allowed|"delta":"tok"/, "$proto: answered by the handler" );
    is( scalar @calls, 2, "$proto: handler reached once per transport" );
    is( $calls[0]{grant}, { model => 'm-allowed', provider => 'p', expires => D() },
      "$proto: the request carries the token's grant" );
    ok( !grep( { /tok-/ } map { $json->encode($_) } @calls ), "$proto: no token on the parsed request" );
  }
  both_are( 200, POST => '/v1/chat/completions', $chat{openai}[1]->('m-allowed'),
    [ 'x-api-key' => $TOKEN ], 'token as x-api-key' );
  both_are( 200, POST => '/v1/chat/completions', $chat{openai}[1]->('m-allowed'),
    [ Authorization => "Bearer $TOKEN", 'x-api-key' => $TOKEN ], 'the same token in both headers' );
  is( \@upstream_hits, [], 'the raw passthrough never ran (unknown model, client key present)' );
};

subtest 'the client token is not forwarded' => sub {
  @calls = ();
  both_are( 200, POST => '/api/chat', $chat{ollama}[1]->('m-allowed'), bearer($TOKEN), 'ollama' );
  both_are( 200, POST => '/v1/messages', $chat{anthropic}[1]->('m-allowed'),
    [ 'x-api-key' => $TOKEN, 'anthropic-version' => '2023-06-01' ], 'anthropic' );
  for my $call (@calls) {
    ok( !grep( { $_->[0] =~ /\A(?:authorization|x-api-key)\z/i } @{ $call->{fwd} } ),
      'no Authorization / x-api-key among the forward_headers' );
  }
  is( [ map { $_->[0] } @{ $calls[-1]{fwd} } ], ['anthropic-version'], 'other headers still forwarded' );
};

subtest 'identify: 401 without a valid token' => sub {
  my %bad = (
    'no token'          => [],
    'unknown token'     => bearer('tok-unknown-123'),
    'expired token'     => bearer($EXPIRED),
    'token without Bearer' => [ Authorization => $TOKEN ],
    'two distinct tokens'  => [ Authorization => "Bearer $TOKEN", 'x-api-key' => $OTHER ],
  );
  for my $name ( sort keys %bad ) {
    for my $proto ( sort keys %chat ) {
      my ( $path, $body ) = @{ $chat{$proto} };
      @calls = ();
      my ($native) = both_are( 401, POST => $path, $body->('m-allowed'), $bad{$name}, "$proto $name" );
      like( $native->decoded_content, qr/unauthorized/, "$proto $name: unauthorized" );
      is( \@calls, [], "$proto $name: handler not reached" );
    }
  }
  # Before the body is read: an unauthenticated client learns no 400.
  for my $proto ( sort keys %chat ) {
    both_are( 401, POST => $chat{$proto}[0], '{not json', [], "$proto broken JSON without a token" );
  }
  both_are( 400, POST => '/v1/chat/completions', '{not json', bearer($TOKEN), 'broken JSON with a token' );
};

subtest 'authorize: 403 for another model' => sub {
  for my $proto ( sort keys %chat ) {
    my ( $path, $body ) = @{ $chat{$proto} };
    @calls = ();
    my ($native) = both_are( 403, POST => $path, $body->('m-secret'), bearer($TOKEN), "$proto other model" );
    like( $native->decoded_content, qr/forbidden: model not allowed for this token/, "$proto: 403 message" );
    unlike( $native->decoded_content, qr/m-allowed|m-secret/, "$proto: no model name in the answer" );
    is( \@calls, [], "$proto: handler not reached" );
  }
  my ($native) = both_are( 403, POST => '/v1/messages', $chat{anthropic}[1]->('m-secret'), bearer($TOKEN),
    'anthropic error shape' );
  is( $json->decode( $native->decoded_content )->{type}, 'error', 'Anthropic error envelope' );
  is( $json->decode( ( run_both( POST => '/api/chat', $chat{ollama}[1]->('m-secret'), bearer($TOKEN) ) )[0]
    ->decoded_content ), { error => 'forbidden: model not allowed for this token' }, 'Ollama error shape' );
};

subtest 'a request without a model gets the token model' => sub {
  my $a2a = { jsonrpc => '2.0', id => 7, method => 'tasks/send',
    params => { id => 't1', message => { role => 'user', parts => [ { type => 'text', text => 'hi' } ] } } };
  @calls = ();
  my ($native) = both_are( 200, POST => '/', $a2a, bearer($TOKEN), 'A2A' );
  is( [ map { $_->{model} } @calls ], [ 'm-allowed', 'm-allowed' ], 'A2A: the token model filled in' );
  my $acp = { mode => 'sync', input => [ { parts => [ { content_type => 'text/plain', content => 'hi' } ] } ] };
  @calls = ();
  both_are( 200, POST => '/runs', $acp, bearer($OTHER), 'ACP without agent_name' );
  is( [ map { $_->{model} } @calls ], [ 'm-other', 'm-other' ], 'ACP: the token model filled in' );
  both_are( 401, POST => '/', $a2a, [], 'A2A without a token' );
};

subtest 'model lists show the token model only' => sub {
  my ($o) = both_are( 200, GET => '/v1/models', undef, bearer($TOKEN), 'OpenAI /v1/models' );
  is( [ map { $_->{id} } @{ $json->decode( $o->decoded_content )->{data} } ], ['m-allowed'], 'OpenAI list' );
  my ($t) = both_are( 200, GET => '/api/tags', undef, bearer($TOKEN), 'Ollama /api/tags' );
  is( [ map { $_->{name} } @{ $json->decode( $t->decoded_content )->{models} } ], ['m-allowed'], 'Ollama list' );
  my ($a) = both_are( 200, GET => '/agents', undef, bearer($OTHER), 'ACP /agents' );
  is( [ map { $_->{name} } @{ $json->decode( $a->decoded_content )->{agents} } ], ['m-other'], 'ACP list' );
  both_are( 401, GET => '/v1/models', undef, [], 'model list without a token' );

  my ($s) = both_are( 200, POST => '/api/show', { model => 'm-allowed' }, bearer($TOKEN), '/api/show own model' );
  ok( $json->decode( $s->decoded_content )->{capabilities}, '/api/show answers' );
  my ($f) = both_are( 403, POST => '/api/show', { model => 'm-secret' }, bearer($TOKEN), '/api/show other model' );
  is( $json->decode( $f->decoded_content ), { error => 'forbidden: model not allowed for this token' },
    '/api/show 403 in Ollama shape' );
  both_are( 401, POST => '/api/show', { model => 'm-allowed' }, [], '/api/show without a token' );
};

subtest 'other routes' => sub {
  both_are( 200, GET => '/api/version', undef, bearer($TOKEN), '/api/version with a token' );
  both_are( 401, GET => '/api/version', undef, [], '/api/version without' );
  my ($m) = both_are( 403, GET => '/.well-known/langertha.json', undef, bearer($TOKEN), 'manifest with a token' );
  like( $m->decoded_content, qr/forbidden: not available with token auth/, 'manifest refused' );
  unlike( $m->decoded_content, qr/m-allowed|m-secret|m-other/, 'manifest names no model' );
  both_are( 401, GET => '/.well-known/langertha.json', undef, [], 'manifest without a token' );
  both_are( 200, GET => '/.well-known/agent.json', undef, [], 'A2A agent card stays anonymous' );
};

subtest 'streams: 200 with the end marker, 403 before any 200' => sub {
  my %stream = (
    openai    => [ '/v1/chat/completions', { model => 'm-allowed', messages => $msgs, stream => JSON::MaybeXS::true() },
      qr/data: \[DONE\]/ ],
    anthropic => [ '/v1/messages', { model => 'm-allowed', max_tokens => 10, messages => $msgs, stream => JSON::MaybeXS::true() },
      qr/event: message_stop/ ],
    ollama    => [ '/api/chat', { model => 'm-allowed', messages => $msgs }, qr/"done":true/ ],
  );
  for my $proto ( sort keys %stream ) {
    my ( $path, $body, $end ) = @{ $stream{$proto} };
    @calls = ();
    my ( $native, $p ) = both_are( 200, POST => $path, $body, bearer($TOKEN), "$proto stream" );
    like( $native->decoded_content, $end, "$proto: native stream ends with its marker" );
    like( $p->decoded_content, $end, "$proto: PSGI stream ends with its marker" );
    like( $native->decoded_content, qr/tok.*en/s, "$proto: chunks arrive" );
    is( [ map { $_->{kind} } @calls ], [ 'stream', 'stream' ], "$proto: streamed" );

    @calls = ();
    my %wrong = ( %$body, model => 'm-secret' );
    ($native) = both_are( 403, POST => $path, \%wrong, bearer($TOKEN), "$proto stream, other model" );
    unlike( $native->decoded_content, $end, "$proto: a refused stream never started" );
    is( \@calls, [], "$proto: stream handler not reached" );
    both_are( 401, POST => $path, $body, bearer($EXPIRED), "$proto stream, expired token" );
  }
};

subtest 'cache: hits are cached, still checked for expiry, dropped on notify' => sub {
  my $short = 'tok-short-0123456789';
  $store->add( token => $short, model => 'm-allowed', provider => 'p', expires => time + 2 );
  my $body = $chat{openai}[1]->('m-allowed');
  my $native = sub {
    my ($tok) = @_;
    return $http->do_request( request => HTTP::Request->new( POST => "http://127.0.0.1:$port/v1/chat/completions",
      [ Authorization => "Bearer $tok", 'Content-Type' => 'application/json' ], $json->encode($body) ) )->get->code;
  };
  my $before = $store->lookups;
  is( $native->($short), 200, 'first request: looked up' );
  is( $store->lookups, $before + 1, 'one lookup' );
  is( $native->($short), 200, 'second request: cache hit' );
  is( $store->lookups, $before + 1, 'no new lookup' );
  sleep 3;
  is( $native->($short), 401, 'an expired cache hit is refused' );
  is( $store->lookups, $before + 1, 'without asking the store' );

  # Revocation: until the store's notification the cache answers; after it
  # the token is gone -- no restart.
  my $rev = 'tok-revoke-0123456789';
  $store->add( token => $rev, model => 'm-allowed', provider => 'p', expires => time + 900 );
  is( $native->($rev), 200, 'valid before the revocation' );
  $store->revoke( token => $rev );
  is( $native->($rev), 200, 'revoked, not yet notified: cached' );
  $store->notify;
  my ( $n, $p ) = run_both( POST => '/v1/chat/completions', $body, bearer($rev) );
  is( [ $n->code, $p->code ], [ 401, 401 ], 'revoked and notified: 401 on both transports' );
};

subtest 'store unavailable: 503 until it is back' => sub {
  my $body = $chat{openai}[1]->('m-allowed');
  both_are( 200, POST => '/v1/chat/completions', $body, bearer($TOKEN), 'before the disconnect' );
  $store->disconnect;
  my ($native) = both_are( 503, POST => '/v1/chat/completions', $body, bearer($TOKEN), 'disconnected, valid token' );
  like( $native->decoded_content, qr/token check unavailable/, '503 message' );
  both_are( 503, POST => '/v1/messages', $chat{anthropic}[1]->('m-allowed'), bearer($TOKEN), 'anthropic shape' );
  both_are( 503, GET => '/v1/models', undef, bearer($TOKEN), 'model list' );
  both_are( 401, POST => '/v1/chat/completions', $body, [], 'no token at all is still 401' );
  both_are( 200, GET => '/.well-known/agent.json', undef, [], 'agent card still anonymous' );
  $store->reconnect;
  both_are( 200, POST => '/v1/chat/completions', $body, bearer($TOKEN), 'reconnected' );
};

subtest 'a pending lookup does not hold the loop' => sub {
  {
    package SlowStore;
    use Moose;
    extends 'Langertha::Knarr::TokenStore::Memory';
    has pending => ( is => 'ro', default => sub { [] } );
    around lookup_f => sub {
      my ( $orig, $self, @args ) = @_;
      my $answer = $self->$orig(@args);
      my $f = Future->new;
      push @{ $self->pending }, [ $f, $answer ];
      return $f;
    };
    sub release { my ($self) = @_; $_->[0]->done( $_->[1]->get ) for splice @{ $self->pending } }
    __PACKAGE__->meta->make_immutable;
  }
  my $slow = SlowStore->new;
  $slow->add( token => $TOKEN, model => 'm-allowed', provider => 'p', expires => time + 900 );
  my $k = Langertha::Knarr->new(
    handler    => $handler,
    authorizer => Langertha::Knarr::Authorizer::Token->new( store => $slow ),
    loop       => $loop,
    listen     => ['127.0.0.1:0'],
  );
  $k->start;
  my $kport = $k->_server->read_handle->sockport;
  my $held = $http->do_request( request => HTTP::Request->new( POST => "http://127.0.0.1:$kport/v1/chat/completions",
    [ Authorization => "Bearer $TOKEN", 'Content-Type' => 'application/json' ],
    $json->encode( $chat{openai}[1]->('m-allowed') ) ) );
  $loop->loop_once(0.05) until @{ $slow->pending } || $held->is_ready;
  ok( !$held->is_ready, 'the token request waits for its lookup' );
  my $card = $http->do_request( uri => "http://127.0.0.1:$kport/.well-known/agent.json" )->get;
  is( $card->code, 200, 'another request is served meanwhile' );
  $slow->release;
  is( $held->get->code, 200, 'the token request is answered once the lookup is done' );

  # A notification while a lookup is in flight: the answer serves its
  # request, but the row it brought must not go into the fresh cache.
  my $chat = sub {
    $http->do_request( request => HTTP::Request->new( POST => "http://127.0.0.1:$kport/v1/chat/completions",
      [ Authorization => "Bearer $TOKEN", 'Content-Type' => 'application/json' ],
      $json->encode( $chat{openai}[1]->('m-allowed') ) ) );
  };
  my $lookups = $slow->lookups;
  is( $chat->()->get->code, 200, 'second request: a cache hit' );
  is( $slow->lookups, $lookups, 'no lookup for it' );
  $slow->notify;
  my $racing = $chat->();
  $loop->loop_once(0.05) until @{ $slow->pending } || $racing->is_ready;
  is( scalar @{ $slow->pending }, 1, 'after the notification: a lookup again' );
  $slow->notify;   # comes in while that lookup is in flight
  $slow->release;
  is( $racing->get->code, 200, 'the in-flight lookup answers its request' );
  $lookups = $slow->lookups;
  my $next = $chat->();
  $loop->loop_once(0.05) until @{ $slow->pending } || $next->is_ready;
  ok( scalar @{ $slow->pending }, 'its row was not cached: the next request looks up again' );
  $slow->release;
  is( $next->get->code, 200, 'and is answered' );
};

done_testing;
