use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use JSON::MaybeXS ();
use Langertha::Skeid;
use Langertha::Skeid::Proxy;
use Langertha::Skeid::Protocol::Ollama::Stream;

# The translated formats have a non-streaming path too, and until this file existed nothing
# drove it: every /v1/messages and /api/chat test asked for a stream, where the translation is
# done by the Stream translator on chunks it decodes itself. The plain JSON path takes a
# different route through the proxy -- it is handed the finished upstream response and has to
# turn that into the client's format -- and it was handing the translator a Mojo response
# object where a decoded body was wanted, so every field read off it was undef. Status 200,
# well-formed envelope, no content: the shape of bug that only an end-to-end request finds.

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  $c->render(json => {
    id      => 'chatcmpl-1',
    object  => 'chat.completion',
    model   => 'm1',
    choices => [{
      index         => 0,
      message       => { role => 'assistant', content => 'Hello there' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 7, completion_tokens => 2, total_tokens => 9 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { return { ok => 1 } },
);
$skeid->add_node(id => 'n1', url => "http://127.0.0.1:$upstream_port/v1", model => 'm1', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

# Non-blocking, because the upstream, the proxy and this test share one event loop: a
# blocking request would stop the loop that has to serve it.
sub post_json {
  my ($path, $payload) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$port$path" => json => $payload => sub {
    (undef, $tx) = @_;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

sub get_path {
  my ($path) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->get("http://127.0.0.1:$port$path" => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

# --- Anthropic ---
{
  my $res = post_json('/v1/messages', {
    model => 'm1', max_tokens => 64,
    messages => [{ role => 'user', content => 'hi' }],
  });
  is $res->code, 200, 'a non-streamed Anthropic request is answered';

  my $body = $res->json;
  is $body->{type}, 'message', 'typed as a message';
  is scalar(@{ $body->{content} // [] }), 1, 'one content block -- not an empty array';
  is $body->{content}[0]{type}, 'text', 'the block is text';
  is $body->{content}[0]{text}, 'Hello there', 'carrying what the upstream actually said';
  is $body->{stop_reason}, 'end_turn', 'stop_reason translated from finish_reason';
  is $body->{usage}{input_tokens}, 7, 'input tokens come from the upstream, not from zero';
  is $body->{usage}{output_tokens}, 2, 'output tokens likewise -- a client bills on these';
  like $body->{id}, qr/^msg_chatcmpl-1$/, 'the upstream id is preserved, not replaced by a clock reading';
}

# --- Ollama ---
{
  my $res = post_json('/api/chat', {
    model => 'm1', stream => JSON::MaybeXS::false,
    messages => [{ role => 'user', content => 'hi' }],
  });
  is $res->code, 200, 'a non-streamed Ollama request is answered';

  my $body = $res->json;
  is $body->{message}{content}, 'Hello there', 'the assistant message survives translation';
  is $body->{model}, 'm1', 'the model is reported, not an empty string';
  is $body->{eval_count}, 2, 'eval_count is the completion token count';
  is $body->{prompt_eval_count}, 7, 'prompt_eval_count is the prompt token count';
}

# --- Ollama face: JSON types as Ollama sends them (skeid #44) ---
# Ollama's replies are typed: done is a JSON boolean, the counts and sizes are integers,
# created_at is an RFC 3339 stamp. A typed client (Go's api package, Rust serde, pydantic)
# decodes into those types and rejects "done":1 or "eval_count":"2" -- a Perl or JS client
# never notices, so the assertions read the raw body, not a decoded value that hides the type.
{
  my $rfc3339 = qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)\z/;

  for my $case (
    [ '/api/chat',     { messages => [{ role => 'user', content => 'hi' }] } ],
    [ '/api/generate', { prompt => 'hi' } ],
  ) {
    my ($path, $extra) = @$case;
    my $res = post_json($path, { model => 'm1', stream => JSON::MaybeXS::false, %$extra });
    is $res->code, 200, "$path non-streamed is answered";
    my $raw = $res->body;
    like $raw, qr/"done":true\b/, "$path: done is the JSON boolean true, not the number 1";
    like $raw, qr/"prompt_eval_count":7\b/, "$path: prompt_eval_count is a JSON integer";
    like $raw, qr/"eval_count":2\b/, "$path: eval_count is a JSON integer";
    like $res->json->{created_at}, $rfc3339, "$path: created_at is RFC 3339";
    ok !grep({ /_duration\z/ } keys %{ $res->json }),
      "$path: no *_duration is invented -- Skeid does not measure Ollama's stages";
  }

  my $tags = get_path('/api/tags');
  is $tags->code, 200, '/api/tags is answered';
  like $tags->body, qr/"size":0\b/, '/api/tags: size is a JSON integer';
  my $model = $tags->json->{models}[0];
  is $model->{name}, 'm1', '/api/tags lists the node model';
  like $model->{modified_at}, $rfc3339, '/api/tags: modified_at is RFC 3339';
  is ref($model->{details}), 'HASH', '/api/tags: details is an object';

  my $ps = get_path('/api/ps');
  is $ps->code, 200, '/api/ps is answered';
  is ref($ps->json->{models}), 'ARRAY', '/api/ps: models is an array';
}

# The streamed lines are typed the same way: every delta says "done":false, the closing line
# "done":true, and its counts are integers -- on both stream shapes.
for my $shape (qw(chat generate)) {
  my $stream = Langertha::Skeid::Protocol::Ollama::Stream->new(model => 'm1', shape => $shape);
  my $delta = $stream->delta({ choices => [{ index => 0, delta => { content => 'Hel' } }] });
  $stream->delta({ choices => [], usage => { prompt_tokens => 7, completion_tokens => 2 } });
  my $last = $stream->finish;
  like $delta, qr/"done":false\b/, "$shape stream: a delta line is done:false";
  like $last,  qr/"done":true\b/,  "$shape stream: the closing line is done:true";
  like $last,  qr/"prompt_eval_count":7\b/, "$shape stream: prompt_eval_count is an integer";
  like $last,  qr/"eval_count":2\b/, "$shape stream: eval_count is an integer";
}

done_testing;
