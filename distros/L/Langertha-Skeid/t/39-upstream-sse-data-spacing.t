use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# The SSE field `data:` takes an optional space before its value. The relay read along only
# `data: ` lines, so an upstream writing `data:{...}` was relayed untouched but metered as zero
# tokens (ok=1, billed nothing, ADR 0004), and the translated faces carried no text (skeid k106).

my @frames = (
  q({"id":"c","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}),
  q({"id":"c","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":1,"total_tokens":4}}),
  '[DONE]',
);
my %sse = (
  'space-model'   => join('', map { "data: $_\n\n" } @frames),
  'nospace-model' => join('', map { "data:$_\n\n" } @frames),
  'crlf-model'    => join('', map { "data:$_\r\n\r\n" } @frames),
);

my %raw_port;
for my $model (sort keys %sse) {
  my $body = $sse{$model};
  my $raw = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nContent-Length: " . length($body) . "\r\n\r\n$body";
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
my $daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$daemon->start;
my $base = 'http://127.0.0.1:' . $daemon->ports->[0];
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

sub metered {
  my ($name) = @_;
  is scalar(@usage_events), 1, "$name: one usage event";
  my $event = $usage_events[0] // {};
  is $event->{ok}, 1, "$name: recorded as served";
  is $event->{input_tokens},  3, "$name: input tokens metered";
  is $event->{output_tokens}, 1, "$name: output tokens metered";
}

for my $model (sort keys %sse) {
  @usage_events = ();
  my $res = stream_post('/v1/chat/completions', $model);
  is $res->code, 200, "openai $model: HTTP 200";
  is $res->body, $sse{$model}, "openai $model: relayed byte for byte";
  metered("openai $model");

  @usage_events = ();
  $res = stream_post('/v1/messages', $model);
  is $res->code, 200, "anthropic $model: HTTP 200";
  my @events;
  my $body = $res->body;
  push @events, [ $1, decode_json($2) ] while $body =~ /event: (\S+)\ndata: ([^\n]*)\n\n/g;
  my ($delta) = grep { $_->[0] eq 'content_block_delta' } @events;
  is $delta && $delta->[1]{delta}{text}, 'Hello', "anthropic $model: the token is delivered";
  metered("anthropic $model");
}

done_testing;
