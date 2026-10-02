use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A model that thinks is silent on the wire: nothing moves between the request and the first
# token, and nothing between two tokens that are far apart. Mojolicious closes a connection
# that was silent for longer than its inactivity timeout -- 30s on the server side, 40s in the
# user agent -- so a proxy that allows its upstream 300s has to raise both, or it cuts the
# request itself while the upstream is still working.
#
# The defaults are scaled down here, never waited for: the server's 30s becomes 0.3s, the
# upstream answers after 0.9s.

my $SERVER_TIMEOUT = 0.3;
my $UPSTREAM_DELAY = 0.9;

my @FRAMES = (
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello "},"finish_reason":null}]}\n\n},
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"world"},"finish_reason":"stop"}],"usage":{"prompt_tokens":7,"completion_tokens":2,"total_tokens":9}}\n\n},
  qq{data: [DONE]\n\n},
);

# What the fake upstream waits before it answers, and between two frames of a stream.
my $delay = $UPSTREAM_DELAY;

# Answer later, unless the caller has gone by then: a request the proxy gave up on leaves its
# timer behind, and rendering into a closed connection would only produce noise.
sub later {
  my ($c, $cb) = @_;
  $c->render_later;
  my $timer = Mojo::IOLoop->timer($delay => $cb);
  $c->tx->on(finish => sub { Mojo::IOLoop->remove($timer) });
  return;
}

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  if ($body->{stream}) {
    my @pending = @FRAMES;
    my $write;
    $write = sub {
      my $frame = shift @pending;
      return $c->finish unless defined $frame;
      # The gap between two tokens is as silent as the wait for the first one.
      $c->write_chunk($frame => sub { @pending > 1 ? later($c, $write) : $write->() });
    };
    $c->res->code(200);
    $c->res->headers->content_type('text/event-stream');
    later($c, $write);
    return;
  }
  later($c, sub {
    $c->render(json => {
      id      => 'chatcmpl-slow',
      object  => 'chat.completion',
      model   => ($body->{model} // ''),
      choices => [{
        index         => 0,
        message       => { role => 'assistant', content => 'late but whole' },
        finish_reason => 'stop',
      }],
      usage => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
    });
  });
});
$upstream->routes->post('/v1/embeddings' => sub {
  my ($c) = @_;
  later($c, sub {
    $c->render(json => {
      object => 'list',
      data   => [{ object => 'embedding', index => 0, embedding => [ 0.1, 0.2 ] }],
      usage  => { prompt_tokens => 2, total_tokens => 2 },
    });
  });
});

# The upstream's own server must not be what cuts anything here.
my $up_daemon = Mojo::Server::Daemon->new(
  app                => $upstream,
  listen             => ['http://127.0.0.1'],
  silent             => 1,
  inactivity_timeout => 30,
);
$up_daemon->start;
my $up_port = $up_daemon->ports->[0];

my @daemons;

sub proxy_on {
  my (%daemon_opts) = @_;
  my $skeid = Langertha::Skeid->new(
    store_usage_event => sub { return { ok => 1 } },
  );
  $skeid->add_node(
    id        => 'slow-1',
    url       => 'http://127.0.0.1:'.$up_port.'/v1',
    model     => 'slow-model',
    engine    => 'openai',
    healthy   => 1,
    max_conns => 16,
  );
  my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
  $app->log->level('fatal');
  # Not a proxied route: whatever a proxied request is granted, this one must not get.
  $app->routes->get('/__slow_local' => sub {
    my ($c) = @_;
    later($c, sub { $c->render(json => { ok => 1 }) });
  });
  my $daemon = Mojo::Server::Daemon->new(
    app    => $app,
    listen => ['http://127.0.0.1'],
    silent => 1,
    %daemon_opts,
  );
  $daemon->start;
  push @daemons, $daemon;
  return ($app, $daemon->ports->[0], $skeid);
}

# A patient client, so a cut connection is the proxy's doing.
sub client { Mojo::UserAgent->new(inactivity_timeout => 20, request_timeout => 20) }

# Runs every request at once and returns when the last one is answered or cut.
sub fetch_all {
  my ($ua, $port, %requests) = @_;
  my %result;
  my $pending = keys %requests;
  my $guard = Mojo::IOLoop->timer(25 => sub { Mojo::IOLoop->stop });
  for my $name (sort keys %requests) {
    my ($method, $path, $json) = @{ $requests{$name} };
    my $tx = $ua->build_tx(
      $method => 'http://127.0.0.1:'.$port.$path,
      ( $json ? ( { 'Content-Type' => 'application/json' }, json => $json ) : () ),
    );
    my $body = '';
    $tx->res->content->unsubscribe('read')->on(read => sub { $body .= $_[1] });
    $ua->start($tx => sub {
      my ($ua_, $done) = @_;
      $result{$name} = {
        code       => $done->res->code,
        body       => $body,
        connection => $done->connection,
        error      => ($done->error ? ($done->error->{message} // 'unknown') : ''),
      };
      Mojo::IOLoop->stop unless --$pending;
    });
  }
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  return \%result;
}

my @messages = ({ role => 'user', content => 'hi' });
my %PROXIED = (
  chat       => [ POST => '/v1/chat/completions', { model => 'slow-model', messages => \@messages } ],
  stream     => [ POST => '/v1/chat/completions', { model => 'slow-model', messages => \@messages, stream => \1 } ],
  embeddings => [ POST => '/v1/embeddings', { model => 'slow-model', input => 'hi' } ],
  anthropic  => [ POST => '/v1/messages', { model => 'slow-model', max_tokens => 16, messages => \@messages } ],
  ollama_chat => [ POST => '/api/chat', { model => 'slow-model', messages => \@messages, stream => \0 } ],
  ollama_generate => [ POST => '/api/generate', { model => 'slow-model', prompt => 'hi', stream => \0 } ],
);

subtest 'the client side waits for a slow upstream' => sub {
  my ($app, $port, $skeid) = proxy_on(inactivity_timeout => $SERVER_TIMEOUT);

  my $got = fetch_all(client(), $port,
    %PROXIED,
    local => [ GET => '/__slow_local' ],
  );

  # The premise: a connection silent for longer than the server's timeout is closed, and a
  # route that calls no upstream keeps living under that timeout.
  is($got->{local}{code}, undef, 'a slow route that is not proxied is still cut by the server timeout');
  isnt($got->{local}{error}, '', 'the cut reaches the client as an error: '.$got->{local}{error});

  for my $name (sort keys %PROXIED) {
    is($got->{$name}{error}, '', $name.': the connection was not cut');
    is($got->{$name}{code}, 200, $name.': answered 200 after '.$UPSTREAM_DELAY.'s of silence');
  }

  like($got->{chat}{body}, qr/late but whole/, 'the late completion arrives whole');
  is($got->{stream}{body}, join('', @FRAMES),
    'a stream with a slow first token and a slow gap between tokens arrives whole');
  is($skeid->node_metrics('slow-1')->{inflight}, 0, 'inflight returns to zero');
};

subtest 'the longer timeout ends with the request' => sub {
  my ($app, $port) = proxy_on(inactivity_timeout => $SERVER_TIMEOUT);

  # One client, one kept-alive connection, two requests one after the other. What the proxied
  # request was granted must not be left on the connection for whatever comes next.
  my $ua = client();
  my $first = fetch_all($ua, $port, chat => $PROXIED{chat});
  is($first->{chat}{code}, 200, 'a proxied request is answered');
  my $second = fetch_all($ua, $port, local => [ GET => '/__slow_local' ]);
  is($second->{local}{connection}, $first->{chat}{connection}, 'the next request reuses its connection');
  is($second->{local}{code}, undef, 'and is under the server timeout again');
};

subtest 'the upstream side waits for a slow upstream' => sub {
  # Mojo::UserAgent's own default of 40s, scaled down. The proxy's server is patient here, so
  # what is cut is the connection to the upstream.
  local $ENV{MOJO_INACTIVITY_TIMEOUT} = $SERVER_TIMEOUT;
  my ($app, $port, $skeid) = proxy_on(inactivity_timeout => 30);

  my $got = fetch_all(client(), $port, map { $_ => $PROXIED{$_} } qw( chat stream ));

  is($got->{chat}{code}, 200, 'a completion slower than the user agent default is answered')
    or diag $got->{chat}{body};
  like($got->{chat}{body}, qr/late but whole/, 'and arrives whole');
  is($got->{stream}{code}, 200, 'a stream slower than the user agent default is answered')
    or diag $got->{stream}{body};
  is($got->{stream}{body}, join('', @FRAMES), 'and arrives whole');
  is($skeid->node_metrics('slow-1')->{inflight}, 0, 'inflight returns to zero');
};

subtest 'one setting for both sides' => sub {
  {
    local $ENV{SKEID_UPSTREAM_TIMEOUT};
    delete $ENV{SKEID_UPSTREAM_TIMEOUT};
    my ($app) = proxy_on();
    is($app->ua->request_timeout, 300, 'an upstream request may take 300s by default');
    is($app->ua->inactivity_timeout, 300, 'and may be silent for all of it');
  }

  for my $bad ('', 0, 'soon', '-5', '1.5') {
    local $ENV{SKEID_UPSTREAM_TIMEOUT} = $bad;
    my ($app) = proxy_on();
    is($app->ua->request_timeout, 300, 'SKEID_UPSTREAM_TIMEOUT="'.$bad.'" is not a timeout, the default stays');
  }

  local $ENV{SKEID_UPSTREAM_TIMEOUT} = 1;
  my ($app, $port, $skeid) = proxy_on(inactivity_timeout => $SERVER_TIMEOUT);
  is($app->ua->request_timeout, 1, 'SKEID_UPSTREAM_TIMEOUT sets the upstream request timeout');
  is($app->ua->inactivity_timeout, 1, 'and the upstream inactivity timeout');

  # An upstream that is within the setting is waited for; one beyond it is given up on, and
  # the client is still there to be told so rather than finding its connection closed.
  $delay = 0.6;
  my $within = fetch_all(client(), $port, chat => $PROXIED{chat});
  is($within->{chat}{code}, 200, 'an upstream within the setting is answered');

  $delay = 5;
  my $beyond = fetch_all(client(), $port, map { $_ => $PROXIED{$_} } qw( chat stream ));
  for my $name (qw( chat stream )) {
    is($beyond->{$name}{error}, 'Bad Gateway', $name.': the client gets a response, not a closed connection');
    is($beyond->{$name}{code}, 502, $name.': an upstream beyond the setting is a 502');
    like($beyond->{$name}{body}, qr/Request timeout/, $name.': which says that the upstream timed out');
  }
  $delay = $UPSTREAM_DELAY;
  is($skeid->node_metrics('slow-1')->{inflight}, 0, 'inflight returns to zero');
};

$_->stop for @daemons, $up_daemon;

done_testing;
