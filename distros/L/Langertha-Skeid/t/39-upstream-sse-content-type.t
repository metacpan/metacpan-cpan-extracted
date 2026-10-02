use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Mojolicious (9.x) parses a response body itself when its Content-Type is exactly
# text/event-stream -- no charset -- and the body is not chunked: it turns the bytes into `sse`
# events and never emits `read`. The relay reads the upstream on `read`, so such an upstream
# (a Content-Length or close-delimited stream, as some servers send) was relayed as nothing:
# 0 bytes on the OpenAI face, an empty message on the Anthropic face, and both metered ok=1
# with no tokens -- a served request that billed nothing (ADR 0004). The relay must see the
# upstream's bytes whatever its exact media type (skeid karr #30, core karr #229).

my $SSE = join '', map { "data: $_\n\n" }
  q({"id":"c","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}),
  q({"id":"c","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":1,"total_tokens":4}}),
  '[DONE]';

# Raw-socket upstreams: a Mojolicious app always sends text/event-stream chunked, which is the
# case that already worked. Each model name is one framing of the charset-less media type.
my %framing = (
  'cl-model'    => "Content-Length: " . length($SSE) . "\r\n",
  'close-model' => "Connection: close\r\n",
);
my %raw_port;
for my $model (sort keys %framing) {
  my $raw = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\n$framing{$model}\r\n$SSE";
  my $id = Mojo::IOLoop->server({ address => '127.0.0.1' } => sub {
    my (undef, $stream) = @_;
    my $buf = '';
    $stream->on(read => sub {
      $buf .= $_[1];
      return unless $buf =~ /\r\n\r\n/ && $buf =~ /\}\s*\z/;
      $stream->write($raw => sub { $stream->close });
    });
  });
  $raw_port{$model} = Mojo::IOLoop->acceptor($id)->port;
}

my @usage_events;
my $skeid = Langertha::Skeid->new(
  store_usage_event => sub { push @usage_events, $_[1]; return { ok => 1 } },
  config_loader     => sub {
    return { policies => { standard => { models => [ sort keys %raw_port ] } },
             default_policy => 'standard' };
  },
);
$skeid->add_node(id => "n-$_", url => "http://127.0.0.1:$raw_port{$_}/v1", model => $_, max_conns => 4)
  for keys %raw_port;

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $base = 'http://127.0.0.1:' . $proxy_daemon->ports->[0];
my $ua = Mojo::UserAgent->new;

sub stream_post {
  my ($path, $model) = @_;
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("$base$path" => { 'x-api-key' => 'sk-test' } => json => {
    model => $model, max_tokens => 16, stream => \1, messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return $tx->res;
}

sub is_metered_with_tokens {
  my ($name) = @_;
  is scalar(@usage_events), 1, "$name: one usage event";
  my $event = $usage_events[0] // {};
  is $event->{ok}, 1, "$name: recorded as served";
  # An ok=1 event with no tokens is exactly the silent-swallow symptom.
  is $event->{input_tokens},  3, "$name: input tokens metered";
  is $event->{output_tokens}, 1, "$name: output tokens metered";
}

for my $model (sort keys %raw_port) {
  # OpenAI face: no translator, the upstream's bytes go out verbatim.
  @usage_events = ();
  my $res = stream_post('/v1/chat/completions', $model);
  is $res->code, 200, "openai $model: HTTP 200";
  is $res->body, $SSE, "openai $model: the upstream stream is relayed byte for byte";
  is_metered_with_tokens("openai $model");

  # Anthropic face: translated, so the token has to reach the client as a text delta.
  @usage_events = ();
  $res = stream_post('/v1/messages', $model);
  is $res->code, 200, "anthropic $model: HTTP 200";
  my @events;
  my $body = $res->body;
  push @events, [ $1, decode_json($2) ] while $body =~ /event: (\S+)\ndata: ([^\n]*)\n\n/g;
  my ($delta) = grep { $_->[0] eq 'content_block_delta' } @events;
  is $delta && $delta->[1]{delta}{text}, 'Hello', "anthropic $model: the token is relayed";
  is $events[-1] && $events[-1][0], 'message_stop', "anthropic $model: the message ends cleanly";
  is_metered_with_tokens("anthropic $model");
}

done_testing;
