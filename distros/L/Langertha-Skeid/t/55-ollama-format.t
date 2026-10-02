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
use Langertha::Skeid::Protocol::Ollama;

# Ollama's `format` is its structured-output field -- "json" for any JSON object, or a JSON
# schema the answer must match (skeid #46). Both Ollama routes dropped it, so a client asking
# for structured output got free text back and failed where it parses the answer. The OpenAI
# upstream spells the same request as response_format, so the translation is one line of
# mapping (the inverse of what core's Ollama engine does with response_format): "json" is
# json_object, a schema object is json_schema. No `strict` is sent -- Ollama's format has no
# such knob, and inventing one would ask the node for more than the client did.

my $SCHEMA = {
  type       => 'object',
  properties => { city => { type => 'string' }, temp => { type => 'number' } },
  required   => [qw(city temp)],
};

my @upstream_bodies;
my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $req = decode_json($c->req->body);
  push @upstream_bodies, $req;
  unless ($req->{stream}) {
    return $c->render(json => {
      id => 'c1', object => 'chat.completion', model => $req->{model},
      choices => [{ index => 0, message => { role => 'assistant', content => '{"city":"Oslo","temp":4}' }, finish_reason => 'stop' }],
      usage => { prompt_tokens => 5, completion_tokens => 9, total_tokens => 14 },
    });
  }
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  $c->write_chunk(qq{data: {"id":"c1","choices":[{"index":0,"delta":{"content":"{}"},"finish_reason":"stop"}]}\n\n});
  $c->write_chunk(qq{data: [DONE]\n\n});
  $c->write_chunk('' => sub { $c->finish });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $UP_URL = 'http://127.0.0.1:' . $upstream_daemon->ports->[0] . '/v1';

my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => $UP_URL, model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];
my $ua = Mojo::UserAgent->new;

sub post_json {
  my ($path, $payload) = @_;
  @upstream_bodies = ();
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port$path" => json => $payload => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

my %REQUEST = (
  '/api/chat'     => { messages => [{ role => 'user', content => 'Weather in Oslo?' }] },
  '/api/generate' => { prompt => 'Weather in Oslo?' },
);

my @CASES = (
  [ 'format "json"', 'json', { type => 'json_object' } ],
  [ 'a schema',      $SCHEMA, { type => 'json_schema', json_schema => { name => 'ollama_format', schema => $SCHEMA } } ],
);

for my $path (sort keys %REQUEST) {
  for my $stream (0, 1) {
    my $mode = $stream ? 'streamed' : 'non-streamed';
    for my $case (@CASES) {
      my ($label, $format, $expected) = @$case;
      my $res = post_json($path, {
        model => 'm1', format => $format, %{ $REQUEST{$path} },
        stream => ($stream ? JSON::MaybeXS::true : JSON::MaybeXS::false),
      });
      is $res->code, 200, "$path $mode, $label: answered";
      is scalar(@upstream_bodies), 1, "$path $mode, $label: one upstream call";
      is_deeply $upstream_bodies[0]{response_format}, $expected,
        "$path $mode, $label: reaches the upstream as response_format, exactly";
      ok !exists $upstream_bodies[0]{format}, "$path $mode, $label: Ollama's own field is not forwarded";
    }

    # Absent, empty or null: Ollama treats all three as "no format", and so must the upstream.
    for my $none (['absent'], ['empty', ''], ['null', undef]) {
      my ($label, @format) = @$none;
      my $res = post_json($path, {
        model => 'm1', (@format ? (format => $format[0]) : ()), %{ $REQUEST{$path} },
        stream => ($stream ? JSON::MaybeXS::true : JSON::MaybeXS::false),
      });
      is $res->code, 200, "$path $mode, format $label: answered";
      ok !exists $upstream_bodies[0]{response_format}, "$path $mode, format $label: no response_format upstream";
    }
  }
}

# The schema is carried as the client sent it -- no strict, no rewritten name inside it.
{
  my $body = Langertha::Skeid::Protocol::Ollama->request_to_openai({ model => 'm1', messages => [], format => $SCHEMA });
  ok !exists $body->{response_format}{json_schema}{strict}, 'no strict flag is invented';
  is_deeply $body->{response_format}{json_schema}{schema}, $SCHEMA, 'the schema is the client\'s, unchanged';
}

done_testing;
