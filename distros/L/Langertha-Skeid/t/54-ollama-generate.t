use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json encode_json);
use MIME::Base64 qw(encode_base64);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Ollama POST /api/generate (skeid #43). An Ollama client that completes a prompt rather than a
# conversation -- `ollama run` scripts, most editor plugins, the generate half of every Ollama SDK
# -- got a 404 from Skeid. The route is a translation at the edge like every other face (ADR 0001):
# prompt, system and images become one chat conversation on the upstream call, and the answer
# comes back in generate's own shape (`response`, not `message`), streamed as NDJSON by default
# because Ollama defaults `stream` to true. It shares /api/chat's route, admission, policy and
# metering, so the assertions include the usage event (ADR 0004): a face that answers but does
# not bill is worse than a 404.

my $PNG  = encode_base64("\x89PNG\r\n\x1a\n\0\0\0\rIHDR", '');
my $JPEG = encode_base64("\xFF\xD8\xFF\xE0\0\x10JFIF\0\x01", '');

my %USAGE = (prompt_tokens => 7, completion_tokens => 3, total_tokens => 10);

my @upstream_bodies;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $req = decode_json($c->req->body);
  push @upstream_bodies, $req;

  if ($req->{model} eq 'm401') {
    return $c->render(status => 401, json => { error => { message => 'invalid upstream key', type => 'invalid_request_error' } });
  }

  unless ($req->{stream}) {
    return $c->render(json => {
      id => 'c1', object => 'chat.completion', model => $req->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => 'Hello' }, finish_reason => 'stop' }],
      usage => \%USAGE,
    });
  }

  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"role":"assistant"}}]}\n\n});
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"Hel"}}]}\n\n});
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"lo"}}]}\n\n});
  $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [{ index => 0, delta => {}, finish_reason => 'stop' }] }) . "\n\n");
  $c->write_chunk('data: ' . encode_json({ id => 'c1', choices => [], usage => \%USAGE }) . "\n\n");
  $c->write_chunk(qq{data: [DONE]\n\n});
  $c->write_chunk('' => sub { $c->finish });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $UP_URL = 'http://127.0.0.1:' . $upstream_daemon->ports->[0] . '/v1';

my $NARROW_KEY = 'sk-test-only-other-models';
my $NARROW_ID  = Langertha::Skeid->key_id_for_key($NARROW_KEY);

my @events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
  config_loader      => sub {
    return {
      pricing  => { '*' => { input_per_million => 3, output_per_million => 15 } },
      policies => { narrow => { models => ['something-else'] } },
      keys     => { $NARROW_ID => 'narrow' },
      nodes    => [ map { +{ id => "n-$_", url => $UP_URL, model => $_, healthy => 1, max_conns => 4 } } qw(m1 m401) ],
    };
  },
);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];
my $ua = Mojo::UserAgent->new;

sub generate {
  my ($payload, %headers) = @_;
  @upstream_bodies = ();
  @events = ();
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port/api/generate" => \%headers => json => $payload
    => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

my $PRICE = 7 / 1e6 * 3 + 3 / 1e6 * 15;

sub near {
  my ($got, $expected, $name) = @_;
  ok(defined($got) && abs($got - $expected) < 1e-12, $name)
    or diag(sprintf('got %s, expected %.10f', $got // 'undef', $expected));
}

# --- non-streamed: generate's shape, one conversation upstream, metered ---
{
  my $res = generate({
    model   => 'm1',
    prompt  => 'Why is the sky blue?',
    system  => 'Answer in one word.',
    options => { temperature => 0.2, num_predict => 32 },
    stream  => JSON::MaybeXS::false,
  });
  is $res->code, 200, 'non-streamed generate is served';
  like $res->headers->content_type, qr{application/json}, 'as one JSON object';
  is $res->headers->header('x-skeid-node'), 'n-m1', 'from the routed node';

  my $j = $res->json;
  is $j->{response}, 'Hello', 'the answer is under response, where an Ollama generate client reads it';
  ok !exists $j->{message}, 'not under a chat message';
  is $j->{model}, 'm1', 'model';
  like $j->{created_at}, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, 'created_at is an ISO stamp';
  ok ref($j->{done}) && $j->{done}, 'done is a JSON true, not the number 1';
  is $j->{done_reason}, 'stop', 'done_reason';
  is $j->{prompt_eval_count}, 7, 'prompt_eval_count';
  is $j->{eval_count}, 3, 'eval_count';

  is scalar(@upstream_bodies), 1, 'one upstream call';
  my $up = $upstream_bodies[0];
  is_deeply $up->{messages}, [
    { role => 'system', content => 'Answer in one word.' },
    { role => 'user',   content => 'Why is the sky blue?' },
  ], 'system and prompt become one chat conversation';
  is $up->{temperature}, 0.2, 'options.temperature lifted as on /api/chat';
  is $up->{max_tokens}, 32, 'options.num_predict becomes max_tokens';
  ok !exists $up->{stream}, 'the upstream call does not stream';
  ok !exists $up->{prompt} && !exists $up->{system}, 'no generate field leaks to the OpenAI upstream';

  is scalar(@events), 1, 'one usage event';
  my $ev = $events[0];
  is $ev->{endpoint}, '/api/generate', 'recorded under its own endpoint';
  is $ev->{api_format}, 'ollama', 'on the Ollama face';
  is $ev->{ok}, 1, 'as served';
  is $ev->{input_tokens}, 7, 'input tokens';
  is $ev->{output_tokens}, 3, 'output tokens';
  near $ev->{cost_total_usd}, $PRICE, 'priced by the pricing rule';
}

# --- streamed by default: NDJSON with response deltas and a closing done line ---
{
  my $res = generate({ model => 'm1', prompt => 'hi' });
  is $res->code, 200, 'a generate request without stream is streamed, as Ollama does';
  like $res->headers->content_type, qr{application/x-ndjson}, 'as NDJSON';
  ok $upstream_bodies[0]{stream}, 'the upstream was asked to stream';
  ok $upstream_bodies[0]{stream_options}{include_usage}, 'with include_usage, for the closing counts';

  my @lines = map { decode_json($_) } grep { length } split /\n/, $res->body;
  ok scalar(@lines) >= 2, 'delta lines plus a closing line';
  my $last = pop @lines;
  is join('', map { $_->{response} } @lines), 'Hello', 'the deltas carry the text under response';
  ok !(grep { exists $_->{message} } @lines, $last), 'no line carries a chat message';
  ok !(grep { $_->{done} } @lines), 'delta lines are not done';
  ok ref($last->{done}) && $last->{done}, 'the closing line is done';
  is $last->{response}, '', 'with an empty response';
  is $last->{done_reason}, 'stop', 'done_reason';
  is $last->{prompt_eval_count}, 7, 'prompt_eval_count from the usage frame';
  is $last->{eval_count}, 3, 'eval_count from the usage frame';

  is scalar(@events), 1, 'one usage event for the stream';
  is $events[0]{endpoint}, '/api/generate', 'under /api/generate';
  is $events[0]{ok}, 1, 'as served';
  near $events[0]{cost_total_usd}, $PRICE, 'priced like the same answer in one piece (skeid #41)';
  is $events[0]{content_bytes}, 5, 'content_bytes counts the text the stream wrote';
}

# --- images: request-level images become image_url parts of the one user message ---
{
  my $res = generate({ model => 'm1', prompt => 'What is this?', images => [$PNG, $JPEG], stream => JSON::MaybeXS::false });
  is $res->code, 200, 'generate with images is served';
  is_deeply $upstream_bodies[0]{messages}, [{
    role    => 'user',
    content => [
      { type => 'text',      text      => 'What is this?' },
      { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } },
      { type => 'image_url', image_url => { url => "data:image/jpeg;base64,$JPEG" } },
    ],
  }], 'the prompt then each image, typed from its magic bytes, as on /api/chat';

  generate({ model => 'm1', prompt => '', images => [$PNG], stream => JSON::MaybeXS::false });
  is_deeply $upstream_bodies[0]{messages}[0]{content},
    [ { type => 'image_url', image_url => { url => "data:image/png;base64,$PNG" } } ],
    'an empty prompt adds no empty text part';
}

# --- policy: the key's policy applies before anything is routed ---
{
  my $res = generate({ model => 'm1', prompt => 'hi', stream => JSON::MaybeXS::false },
    Authorization => "Bearer $NARROW_KEY");
  is $res->code, 403, 'a key whose policy does not grant the model is refused';
  # Ollama's error shape, a plain string under error, not the OpenAI object (skeid #47).
  like $res->json->{error}, qr/not available for this key/, 'as a permission answer, in Ollama\'s string shape';
  is scalar(@upstream_bodies), 0, 'and the upstream was never called';
}

# --- an upstream 401 is the client's answer, and a failed usage event ---
for my $stream (0, 1) {
  my $label = $stream ? 'streamed' : 'non-streamed';
  my $res = generate({ model => 'm401', prompt => 'hi',
    stream => ($stream ? JSON::MaybeXS::true : JSON::MaybeXS::false) });
  is $res->code, 401, "$label: the upstream's 401 reaches the client";
  like $res->json->{error}, qr/invalid upstream key/, "$label: as an Ollama error carrying the upstream's message";
  is scalar(@events), 1, "$label: one usage event";
  is $events[0]{ok}, 0, "$label: recorded as failed";
  is $events[0]{status_code}, 401, "$label: with the upstream status";
  is $events[0]{endpoint}, '/api/generate', "$label: under /api/generate";
}

# --- invalid body ---
{
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port/api/generate" => { 'Content-Type' => 'application/json' } => 'nope'
    => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  is $tx->res->code, 400, 'a body that is not a JSON object is a 400';
  is_deeply $tx->res->json, { error => 'Invalid JSON body' }, 'in Ollama\'s error shape';
}

done_testing;
