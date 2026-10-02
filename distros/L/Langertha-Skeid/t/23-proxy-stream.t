use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Streaming is the path that matters most for an LLM proxy and the one a unit test cannot
# reach: the bug this file exists for produced correct headers, a 200, and an empty body, so
# anything that only inspects a rendered transaction sees a healthy response. It needs a real
# upstream, a real socket, and a client that reads chunks as they arrive.

my @FRAMES = (
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello "},"finish_reason":null}]}\n\n},
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"world"},"finish_reason":null}]}\n\n},
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":7,"completion_tokens":2,"total_tokens":9}}\n\n},
  qq{data: [DONE]\n\n},
);

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  $c->render_later;
  $c->res->code(200);
  $c->res->headers->content_type('text/event-stream');
  my @pending = @FRAMES;
  my $write;
  $write = sub {
    my $frame = shift @pending;
    return $c->finish unless defined $frame;
    $c->write_chunk($frame => sub { $write->() });
  };
  # Delay the first frame so the headers reach the proxy in their own read. A real model does
  # exactly this -- the time to first token is dead air on the wire -- and it makes the proxy
  # see a read event with zero bytes, which is the second half of what used to break here.
  Mojo::IOLoop->timer(0.05 => $write);
});

my $up_daemon = Mojo::Server::Daemon->new(
  app    => $upstream,
  listen => ['http://127.0.0.1'],
  silent => 1,
);
$up_daemon->start;
my $up_port = $up_daemon->ports->[0];

my @events;
my $skeid = Langertha::Skeid->new(
  store_usage_event => sub { push @events, $_[1]; return { ok => 1 } },
);
$skeid->add_node(
  id        => 'stream-1',
  url       => "http://127.0.0.1:$up_port/v1",
  model     => 'stream-model',
  engine    => 'openai',
  healthy   => 1,
  max_conns => 4,
);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(
  app    => $proxy,
  listen => ['http://127.0.0.1'],
  silent => 1,
);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;
my $body = '';
my @chunk_sizes;
my $res_headers;

my $tx = $ua->build_tx(
  POST => "http://127.0.0.1:$proxy_port/v1/chat/completions",
  { 'Content-Type' => 'application/json' },
  json => {
    model    => 'stream-model',
    stream   => \1,
    messages => [{ role => 'user', content => 'hi' }],
  },
);
$tx->res->content->unsubscribe('read')->on(read => sub {
  my ($content, $bytes) = @_;
  return unless length $bytes;
  push @chunk_sizes, length $bytes;
  $body .= $bytes;
});

my $timeout = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
$ua->start($tx => sub {
  my ($ua_, $done) = @_;
  $res_headers = $done->res->headers;
  Mojo::IOLoop->stop;
});
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timeout);

is($tx->res->code, 200, 'streamed response returns 200');

# The regression: the relay used to finalize the response on the first (empty) read event, so
# the client got headers and nothing else.
ok(length($body) > 0, 'streamed body is not empty');
ok(scalar(@chunk_sizes) > 0, 'client received at least one chunk');

# Byte-transparency: Skeid parses the stream to count tokens, it never rewrites it. A client
# parser that works against the upstream must work through the proxy unchanged.
is($body, join('', @FRAMES), 'relayed bytes are identical to what the upstream sent');

is($res_headers->header('x-skeid-node'), 'stream-1', 'response names the node that served it');

# Usage is accumulated out of the stream itself -- there is no response object to read it from
# afterwards, so a broken relay silently produces unbilled requests.
is(scalar(@events), 1, 'exactly one usage event for one streamed request');
is($events[0]{input_tokens}, 7, 'prompt tokens taken from the final SSE frame');
is($events[0]{output_tokens}, 2, 'completion tokens taken from the final SSE frame');
is($events[0]{ok}, 1, 'streamed request recorded as successful');
is($events[0]{node_id}, 'stream-1', 'usage event names the node');

# Admission accounting has to survive the streaming path too: a request that starts and never
# finishes leaks a slot on that node until the process restarts.
is($skeid->node_metrics('stream-1')->{inflight}, 0, 'inflight returns to zero after the stream');

done_testing;
