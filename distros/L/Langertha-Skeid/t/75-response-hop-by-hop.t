use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# The node's `Connection: close` and `Keep-Alive: timeout=5, max=100` describe the node's
# connection to Skeid. Relayed, they tell the customer's client the same and make Skeid drop
# the customer's keep-alive connection (skeid k107). The node here is a raw socket.

my $node = Mojo::IOLoop->server({ address => '127.0.0.1' } => sub {
  my (undef, $stream) = @_;
  my $buf = '';
  $stream->on(read => sub {
    $buf .= $_[1];
    return unless $buf =~ /\r\n\r\n/;
    my ($head, $body) = split /\r\n\r\n/, $buf, 2;
    my ($len) = $head =~ /^content-length:\s*(\d+)/mi;
    return if length($body // '') < ($len // 0);
    my ($payload, $ctype);
    if ($body =~ /"stream"\s*:\s*true/) {
      $ctype = 'text/event-stream';
      $payload = join '', map { "data: $_\n\n" }
        '{"id":"c","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}',
        '{"id":"c","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":1,"total_tokens":4}}',
        '[DONE]';
    }
    else {
      $ctype = 'application/json';
      $payload = '{"id":"c","object":"chat.completion","model":"m","choices":[{"index":0,"message":{"role":"assistant","content":"Hello"},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":1,"total_tokens":4}}';
    }
    $stream->write("HTTP/1.1 200 OK\r\nContent-Type: $ctype\r\nConnection: close\r\nKeep-Alive: timeout=5, max=100\r\nX-Node-Marker: kept\r\nContent-Length: " . length($payload) . "\r\n\r\n$payload"
      => sub { $stream->close });
  });
});
my $port = Mojo::IOLoop->acceptor($node)->port;

my @usage_events;
my $skeid = Langertha::Skeid->new(store_usage_event => sub { push @usage_events, $_[1]; return { ok => 1 } });
$skeid->add_node(id => 'n1', url => 'http://127.0.0.1:' . $port . '/v1', model => 'm', max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$daemon->start;
my $base = 'http://127.0.0.1:' . $daemon->ports->[0];
my $ua = Mojo::UserAgent->new;

for my $stream (0, 1) {
  @usage_events = ();
  my $tx;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post($base . '/v1/chat/completions' => { Authorization => 'Bearer sk-test' } => json => {
    model => 'm', stream => ($stream ? \1 : \0), messages => [{ role => 'user', content => 'hi' }],
  } => sub { (undef, $tx) = @_; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  my $label = 'stream=' . $stream;
  ok $tx, $label . ': answered';
  my $res = $tx && $tx->res;
  is $res && $res->code, 200, $label . ': HTTP 200';
  like $res && $res->body, qr/Hello/, $label . ': the answer is relayed';
  ok !defined($res && $res->headers->header('Keep-Alive')), $label . ': Keep-Alive is not relayed';
  ok !defined($res && $res->headers->header('Connection')), $label . ': Connection is not relayed';
  is $res && $res->headers->header('X-Node-Marker'), 'kept', $label . ': other node headers still are';
  is scalar(@usage_events), 1, $label . ': one usage event';
}

done_testing;
