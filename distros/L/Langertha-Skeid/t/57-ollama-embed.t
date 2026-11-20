#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS qw(decode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Ollama POST /api/embed and /api/embeddings. Embeddings worked only in the OpenAI form; an
# Ollama client asking /api/embed got a 404. Both routes are a translation at the edge (ADR 0001)
# to the node's OpenAI /embeddings, routed, admitted and metered like every other face (ADR 0004).

my @upstream_bodies;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/embeddings' => sub {
  my ($c) = @_;
  my $req = decode_json($c->req->body);
  push @upstream_bodies, $req;
  if ($req->{model} eq 'm401') {
    return $c->render(status => 401, json => { error => { message => 'invalid upstream key', type => 'invalid_request_error' } });
  }
  my @inputs = ref($req->{input}) ? @{$req->{input}} : ($req->{input});
  # Out of order on purpose: index says where each vector belongs.
  my @data = reverse map { +{ object => 'embedding', index => $_, embedding => [ $_ + 0.5, length($inputs[$_]) ] } } 0 .. $#inputs;
  $c->render(json => {
    object => 'list', model => $req->{model}, data => \@data,
    usage  => { prompt_tokens => 5, total_tokens => 5 },
  });
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
      pricing  => { '*' => { input_per_million => 2, output_per_million => 0 } },
      policies => { narrow => { models => ['something-else'] } },
      keys     => { $NARROW_ID => 'narrow' },
      aliases  => { 'house-embed' => { tiers => [{ tags => ['emb'], model => 'm1' }] } },
      nodes    => [ map { +{ id => "n-$_", trust => 'internal', url => $UP_URL, model => $_, tags => ['emb'], healthy => 1, max_conns => 4 } } qw(m1 m401) ],
    };
  },
);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];
my $ua = Mojo::UserAgent->new;

sub post {
  my ($path, $payload, %headers) = @_;
  @upstream_bodies = ();
  @events = ();
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port$path" => \%headers => json => $payload
    => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

# --- /api/embed: a list of inputs, vectors in input order, metered ---
{
  my $res = post('/api/embed', { model => 'm1', input => [ 'a', 'bcd' ], truncate => JSON::MaybeXS::true,
    keep_alive => '5m', options => { num_ctx => 512 }, dimensions => 2 });
  is $res->code, 200, '/api/embed is served';
  is $res->headers->header('x-skeid-node'), 'n-m1', 'from the routed node';
  my $j = $res->json;
  is $j->{model}, 'm1', 'model';
  is_deeply $j->{embeddings}, [ [ 0.5, 1 ], [ 1.5, 3 ] ], 'one vector per input, in input order';
  is $j->{prompt_eval_count}, 5, 'prompt_eval_count from usage.prompt_tokens';
  ok !exists $j->{data}, 'no OpenAI field leaks to the Ollama client';

  is scalar(@upstream_bodies), 1, 'one upstream call';
  is_deeply $upstream_bodies[0], { model => 'm1', input => [ 'a', 'bcd' ], dimensions => 2 },
    'the upstream gets an OpenAI embeddings body; truncate, keep_alive and options stay behind';

  is scalar(@events), 1, 'one usage event';
  my $e = $events[0];
  is $e->{api_format}, 'ollama', 'metered under the ollama face';
  is $e->{endpoint}, '/api/embed', 'with its endpoint';
  is $e->{input_tokens}, 5, 'and the input tokens';
}

# --- /api/embed: one string ---
{
  my $res = post('/api/embed', { model => 'm1', input => 'hello' });
  is $res->code, 200, 'a single input string is served';
  is_deeply $res->json->{embeddings}, [ [ 0.5, 5 ] ], 'as a list of one vector';
  is $upstream_bodies[0]{input}, 'hello', 'and goes upstream as a string';
}

# --- /api/embeddings: the older one-prompt route ---
{
  my $res = post('/api/embeddings', { model => 'm1', prompt => 'hello' });
  is $res->code, 200, '/api/embeddings is served';
  is_deeply $res->json, { embedding => [ 0.5, 5 ] }, 'one vector under embedding';
  is_deeply $upstream_bodies[0], { model => 'm1', input => 'hello' }, 'the prompt goes up as input';
  is $events[0]{endpoint}, '/api/embeddings', 'metered under its own endpoint';
}

# --- an alias serves another model; the client sees its own name ---
{
  my $res = post('/api/embed', { model => 'house-embed', input => 'x' });
  is $res->code, 200, 'an alias is served';
  is $upstream_bodies[0]{model}, 'm1', 'the node is asked for the served model';
  is $res->json->{model}, 'house-embed', 'the client sees the name it asked for';
  is $events[0]{requested_model}, 'house-embed', 'the usage event carries both names';
  is $events[0]{model}, 'm1', '...';
}

# --- errors are Ollama-shaped ---
{
  my $res = post('/api/embed', { model => 'm1', input => { not => 'a string' } });
  is $res->code, 400, 'an input that is no string nor list of strings is a 400';
  is_deeply $res->json, { error => 'Invalid request' }, 'in Ollama\'s error shape';
  is scalar(@upstream_bodies), 0, 'and goes nowhere';
  is scalar(@events), 0, 'and is not metered';

  $res = post('/api/embeddings', { model => 'm1' });
  is $res->code, 400, '/api/embeddings without a prompt is a 400';

  $res = post('/api/embed', { model => 'm1', input => 'x' }, Authorization => "Bearer $NARROW_KEY");
  is $res->code, 403, 'a key whose policy does not grant the model is refused';
  ok !ref($res->json->{error}), 'with a string error';

  $res = post('/api/embed', { model => 'm401', input => 'x' });
  is $res->code, 401, 'an upstream error keeps its status';
  ok !ref($res->json->{error}), 'and is Ollama-shaped';
}

done_testing;
