use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Ollama::Stream;

# Ollama answers every error as {"error": "<message>"} -- a string, with the HTTP status of the
# failure -- and a failure inside an open NDJSON stream as one line of the same shape. The Go
# client decodes StatusError.ErrorMessage as a string, and every typed client checks each stream
# line for "error". Skeid answered the Ollama routes in the OpenAI envelope {error: {message,
# type}}, which those clients cannot decode, and a stream that failed after opening ended with a
# done:true line that reads as a complete answer. Every error on /api/* goes through one Ollama
# renderer, like the Anthropic face does for /v1/messages (skeid #47, core karr #224).

# --- upstream: one behaviour per model name ---
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $model = $c->req->json->{model} // '';

  if ($model eq 'bad-model') {
    return $c->render(status => 400,
      json => { error => { message => 'context too long', type => 'invalid_request_error' } });
  }
  if ($model eq 'boom-model') {
    return $c->render(status => 500,
      json => { error => { message => 'kaputt', type => 'server_error' } });
  }
  if ($model eq 'cut-model' || $model eq 'errchunk-model') {
    $c->render_later;
    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    my @frames = (
      qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hel"},"finish_reason":null}]}\n\n},
    );
    push @frames, qq{data: {"error":{"message":"engine fell over","type":"server_error"}}\n\n}
      if $model eq 'errchunk-model';
    my $write;
    $write = sub {
      my $frame = shift @frames;
      unless (defined $frame) {
        return $c->finish if $model ne 'cut-model';
        # Drop the connection mid-stream: headers and a token went out, the end never comes.
        Mojo::IOLoop->stream($c->tx->connection)->close;
        return;
      }
      $c->write_chunk($frame => sub { Mojo::IOLoop->timer(0.02 => $write) });
    };
    Mojo::IOLoop->timer(0.02 => $write);
    return;
  }
  $c->render(json => {
    id => 'chatcmpl-1', object => 'chat.completion', model => $model,
    choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
    usage => { prompt_tokens => 3, completion_tokens => 1, total_tokens => 4 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $up = 'http://127.0.0.1:' . $upstream_daemon->ports->[0] . '/v1';

# A port nothing listens on: the connection is refused, which is an upstream transport error.
my $dead_port = Mojo::IOLoop::Server->generate_port;

my @usage_events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @usage_events, $_[1]; return { ok => 1 } },
  config_loader      => sub {
    return {
      policies => {
        standard => {
          models    => [qw(ok-model busy-model bad-model boom-model cut-model errchunk-model
                           dead-model forbidden-model no-such-model)],
          deny_tags => ['forbidden'],
        },
      },
      default_policy => 'standard',
      routing        => { wait_timeout_ms => 30, wait_poll_ms => 5 },
    };
  },
);
$skeid->add_node(id => "n-$_", url => $up, model => $_, max_conns => 4)
  for qw(ok-model bad-model boom-model cut-model errchunk-model);
$skeid->add_node(id => 'n-busy', url => $up, model => 'busy-model', max_conns => 1);
$skeid->add_node(id => 'n-dead', url => "http://127.0.0.1:$dead_port/v1", model => 'dead-model', max_conns => 4);
$skeid->add_node(id => 'n-forbidden', url => $up, model => 'forbidden-model', max_conns => 4,
  tags => ['forbidden']);
ok $skeid->start_request('n-busy'), 'occupy the only slot of busy-model';

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
$proxy->mode('production');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $base = 'http://127.0.0.1:' . $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub request {
  my ($method, $path, @body) = @_;
  my %headers = ('Authorization' => 'Bearer sk-test', (ref($body[0]) eq 'HASH' ? %{shift @body} : ()));
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->$method("$base$path" => \%headers => @body => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

my %BODY = (
  chat     => sub { (messages => [{ role => 'user', content => 'hi' }]) },
  generate => sub { (prompt => 'hi') },
);

sub ollama {
  my ($kind, $model, %extra) = @_;
  return request(post => "/api/$kind", json => {
    model => $model, stream => \0, $BODY{$kind}->(), %extra,
  });
}

sub is_ollama_error {
  my ($res, $status, $name) = @_;
  is $res->code, $status, "$name: HTTP $status";
  like $res->headers->content_type // '', qr{application/json}, "$name: a JSON body";
  my $body = eval { $res->json };
  is ref($body), 'HASH', "$name: the body decodes" or return '';
  is_deeply [keys %$body], ['error'], "$name: nothing but Ollama's error key";
  ok defined($body->{error}) && !ref($body->{error}), "$name: error is a string, not an object";
  ok length($body->{error} // ''), "$name: the message is set";
  return $body->{error};
}

sub ndjson_lines {
  my ($body) = @_;
  return map { decode_json($_) } grep { length } split /\n/, $body;
}

for my $kind (qw(chat generate)) {
  my $path = "/api/$kind";

  is_deeply is_ollama_error(request(post => $path, { 'Content-Type' => 'application/json' } => 'not json{'),
    400, "$kind: invalid JSON body"), 'Invalid JSON body', "$kind: invalid JSON body: the message";

  like is_ollama_error(ollama($kind, 'not-granted'), 403, "$kind: model not granted to the key"),
    qr/not available for this key/, "$kind: model not granted: says so";
  like is_ollama_error(ollama($kind, 'forbidden-model'), 403, "$kind: model only on denied nodes"),
    qr/not available for this key/, "$kind: model only on denied nodes: says so";
  like is_ollama_error(ollama($kind, 'busy-model'), 429, "$kind: no free capacity"),
    qr/Timed out waiting for free capacity/, "$kind: no free capacity: says so";
  like is_ollama_error(ollama($kind, 'no-such-model'), 503, "$kind: no node serves the model"),
    qr/No healthy node available/, "$kind: no node: says so";

  like is_ollama_error(ollama($kind, 'bad-model'), 400, "$kind: upstream 400"),
    qr/context too long/, "$kind: upstream 400: the upstream's own message, not the reason phrase";
  like is_ollama_error(ollama($kind, 'boom-model'), 500, "$kind: upstream 500"),
    qr/kaputt/, "$kind: upstream 500: the upstream's own message";
  like is_ollama_error(ollama($kind, 'dead-model'), 502, "$kind: upstream unreachable"),
    qr/Upstream error/, "$kind: upstream unreachable: says so";

  # A streamed request that fails before the stream opens is an ordinary HTTP error, as it is at
  # Ollama: there is no line yet to carry it, and no done:true line may follow.
  is_ollama_error(ollama($kind, 'busy-model', stream => \1), 429, "$kind: streamed, no capacity");
  like is_ollama_error(ollama($kind, 'bad-model', stream => \1), 400, "$kind: streamed, upstream 400"),
    qr/context too long/, "$kind: streamed, upstream 400: the upstream's own message";
  like is_ollama_error(ollama($kind, 'boom-model', stream => \1), 500, "$kind: streamed, upstream 500"),
    qr/kaputt/, "$kind: streamed, upstream 500: the upstream's own message";
  is_ollama_error(ollama($kind, 'dead-model', stream => \1), 502, "$kind: streamed, upstream unreachable");

  # Once the stream is open the status is already 200, so the failure travels in-band as
  # Ollama's own error line -- the last line, with no done:true after it claiming a clean end.
  for my $case (
    [ 'cut-model',      qr/Premature connection close/, 'upstream connection dropped mid-stream' ],
    [ 'errchunk-model', qr/engine fell over/,           'upstream sent an error chunk mid-stream' ],
  ) {
    my ($model, $message, $what) = @$case;
    my $name = "$kind: $what";
    @usage_events = ();
    my $res = ollama($kind, $model, stream => \1);
    is $res->code, 200, "$name: the stream had started";
    like $res->headers->content_type // '', qr{application/x-ndjson}, "$name: as NDJSON";
    my @lines = ndjson_lines($res->body);
    ok !exists $lines[0]{error}, "$name: a token got through first";
    is_deeply [keys %{$lines[-1]}], ['error'], "$name: the last line is an Ollama error line";
    like $lines[-1]{error}, $message, "$name: carrying the reason";
    ok !(grep { ref($_->{done}) && $_->{done} } @lines), "$name: no done:true line claims a clean end";
    is scalar(@usage_events), 1, "$name: one usage event";
    is $usage_events[0]{ok}, 0, "$name: recorded as failed";
  }

  # The happy path is untouched.
  {
    my $res = ollama($kind, 'ok-model');
    is $res->code, 200, "$kind: a good request is still answered";
    ok !exists $res->json->{error}, "$kind: without an error";
  }
}

# /api/tags and /api/ps have no failure of their own; they sit behind the same Ollama marker so
# an error rendered there is Ollama-shaped too. Their answers are untouched.
{
  my $res = request(get => '/api/tags');
  is $res->code, 200, '/api/tags answers';
  is ref($res->json->{models}), 'ARRAY', '/api/tags: the model list';
  $res = request(get => '/api/ps');
  is $res->code, 200, '/api/ps answers';
  is_deeply $res->json, { models => [] }, '/api/ps: the empty process list';
}

# The OpenAI face keeps its own shape: the marker is per route, not global.
{
  my $res = request(post => '/v1/chat/completions', json => {
    model => 'not-granted', messages => [{ role => 'user', content => 'hi' }],
  });
  is $res->code, 403, 'openai: model not granted';
  is $res->json->{error}{type}, 'permission_error', 'openai: still the OpenAI error object';
}

# --- the translator on its own ---
{
  my $stream = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'm');
  ok !$stream->errored, 'a fresh stream has not errored';
  my $line = $stream->error_event(500, 'Upstream error: x');
  is $line, qq({"error":"Upstream error: x"}\n), 'error_event is one Ollama NDJSON error line';
  ok $stream->errored, 'and marks the stream as errored';
  is $stream->finish, '', 'no done line follows an error';
  is $stream->delta({ choices => [{ delta => { content => 'late' } }] }), '', 'nor any delta';
  is $stream->error_event(500, 'again'), '', 'a second error is not sent';
}

$skeid->finish_request('n-busy', ok => 1);

done_testing;
