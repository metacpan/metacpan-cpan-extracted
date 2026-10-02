use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use JSON::MaybeXS qw(encode_json);
use Scalar::Util qw(weaken);
use Langertha::Skeid;
use Langertha::Skeid::KeyBroker;
use Langertha::Skeid::Proxy;

# A client that hangs up before its answer is complete is an exit path like any other: the
# request stops waiting for capacity, the upstream call it caused is cancelled, the slot it took
# is given back exactly once, what the upstream had reported by then is billed (ADR 0004), and
# nothing keeps the controller alive. The client here is a raw connection, because hanging up
# is the one thing a well-behaved user agent does not do on request.

{
  package Local::AbortSkeid;
  use parent 'Langertha::Skeid';

  # How often admission found every eligible node busy: one count per poll of a waiting request.
  sub busy_polls { $_[0]{_abort_busy_polls}{$_[1]} // 0 }

  sub call_function {
    my ($self, $name, $args) = @_;
    my $result = $self->SUPER::call_function($name, $args);
    $self->{_abort_busy_polls}{$args->{model}}++
      if $name eq 'route.state' && $result->{has_eligible} && !$result->{has_available};
    return $result;
  }
}

{
  package Local::HoldingBroker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';

  # Never answers on its own -- the test decides when the vault replies.
  has held => (is => 'ro', default => sub { [] });
  sub resolve_key { die 'the request path must not call the blocking resolve_key' }
  sub resolve_key_async {
    my ($self, $ref, $cb) = @_;
    push @{$self->held}, $cb;
    return;
  }
  sub release {
    my ($self, $key) = @_;
    my @cbs = splice @{$self->held};
    $_->($key, undef) for @cbs;
    return scalar @cbs;
  }
}

my @usage_events;
my $broker = Local::HoldingBroker->new;
my $skeid = Local::AbortSkeid->new(
  route_wait_timeout_ms => 400,
  route_wait_poll_ms    => 5,
  key_broker            => $broker,
  store_usage_event     => sub { push @usage_events, $_[1]; return { ok => 1 } },
);

my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');
$app->mode('production');

my %CLIENT_PATH = map { $_ => 1 } qw(/v1/chat/completions /v1/messages /api/chat);
my @client_controllers;
my $last_client_connection;
$app->hook(before_dispatch => sub {
  my ($c) = @_;
  return unless $CLIENT_PATH{$c->req->url->path->to_string};
  push @client_controllers, $c;
  weaken($client_controllers[-1]);
  $last_client_connection = $c->tx->connection;
});

# Usage rides on the first frame already (a running total, as with continuous usage stats), so a
# stream that is abandoned after it has something to bill.
my $FIRST_FRAME = qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"ok"},"finish_reason":null}],"usage":{"prompt_tokens":7,"completion_tokens":1,"total_tokens":8}}\n\n};
my $LAST_FRAMES = join '',
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":7,"completion_tokens":3,"total_tokens":10}}\n\n},
  qq{data: [DONE]\n\n};
my $BIG_FRAMES = 192;
my $BIG_FRAME = 'data: ' . encode_json({
  id      => 'c1',
  object  => 'chat.completion.chunk',
  choices => [{ index => 0, delta => { content => 'x' x 65536 }, finish_reason => undef }],
}) . "\n\n";

sub completion {
  my ($model) = @_;
  return {
    id      => 'chatcmpl-abort',
    object  => 'chat.completion',
    model   => $model,
    choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
  };
}

# One record per request the fake upstream received. `hung_up` is the upstream's own view: its
# connection ended before it had answered.
my @upstream;
$app->routes->post('/__fake_upstream/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body  = $c->req->json || {};
  my $model = $body->{model} // '';
  my $seen  = { model => $model, answered => 0, hung_up => 0 };
  push @upstream, $seen;
  $c->on(finish => sub {
    $seen->{hung_up} = 1 unless $seen->{answered};
    delete $seen->{answer};
  });

  # hold-*: answers only when the test says so.
  if ($model =~ /^hold-/) {
    $c->render_later;
    unless ($body->{stream}) {
      $seen->{answer} = sub { $seen->{answered} = 1; $c->render(json => completion($model)) };
      return;
    }
    $c->res->headers->content_type('text/event-stream');
    $c->write_chunk($FIRST_FRAME => sub { });
    $seen->{answer} = sub {
      $seen->{answered} = 1;
      $c->write_chunk($LAST_FRAMES => sub { $_[0]->finish });
    };
    return;
  }

  # big-*: a complete stream of more bytes than a connection nobody reads from can buffer.
  if ($model =~ /^big-/) {
    $c->res->headers->content_type('text/event-stream');
    $seen->{answered} = 1;
    $c->write_chunk(($BIG_FRAME x $BIG_FRAMES) . $LAST_FRAMES => sub { $_[0]->finish });
    return;
  }

  $seen->{answered} = 1;
  if ($body->{stream}) {
    $c->res->headers->content_type('text/event-stream');
    $c->render(status => 200, data => $FIRST_FRAME . $LAST_FRAMES);
    return;
  }
  $c->render(json => completion($model));
});

my $t = Test::Mojo->new($app);
my $upstream_url = $t->ua->server->nb_url->clone;
$upstream_url->path('/__fake_upstream/v1');

sub add_node {
  my ($model, %extra) = @_;
  ok $skeid->add_node(
    id        => $model,
    url       => "$upstream_url",
    model     => $model,
    engine    => 'openai',
    healthy   => 1,
    max_conns => 1,
    %extra,
  ), "$model node added";
  $skeid->call_function('pricing.set', {
    model   => $model,
    pricing => { input_per_million => 3, output_per_million => 15 },
  });
}

# Runs the loop until $cond holds. The guard only bounds a failing run; a passing one returns on
# the first poll that sees the condition.
sub run_until {
  my ($cond, $max) = @_;
  return 1 if $cond->();
  my $met = 0;
  my $guard = Mojo::IOLoop->timer(($max // 2) => sub { Mojo::IOLoop->stop });
  my $poll = Mojo::IOLoop->recurring(0.005 => sub {
    return unless $cond->();
    $met = 1;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($_) for $guard, $poll;
  return $met;
}

# Runs the loop for a fixed, short window: for showing that something did not happen.
sub run_for {
  my ($seconds) = @_;
  Mojo::IOLoop->timer($seconds => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  return;
}

sub settle_loop {
  my $settled = 0;
  Mojo::IOLoop->next_tick(sub {
    $settled = 1;
    Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
  });
  Mojo::IOLoop->start unless $settled;
}

sub live_since {
  my ($from) = @_;
  return scalar grep { defined } @client_controllers[$from .. $#client_controllers];
}

# The liveness check of t/50-proxy-request-lifecycle.t: reuse both keep-alive connections with a
# request that captures no chat controller, then anything still alive is Skeid-owned.
sub released_since {
  my ($from, $name) = @_;
  $t->get_ok('/health')->status_is(200);
  my $flushed = 0;
  my $health = $t->ua->server->nb_url->clone;
  $health->path('/health');
  $app->ua->get($health => sub {
    $flushed = 1;
    Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
  });
  Mojo::IOLoop->start unless $flushed;
  settle_loop();
  is live_since($from), 0, $name;
}

sub paired_metrics {
  my ($id, $started, $name) = @_;
  my $metrics = $skeid->node_metrics($id);
  is $metrics->{started}, $started, "$name: expected request.start count";
  is $metrics->{inflight}, 0, "$name: no request remains in flight";
  is $metrics->{ok} + $metrics->{error} + $metrics->{aborted}, $metrics->{started},
    "$name: every request.start has exactly one request.finish";
  return $metrics;
}

# What the registry snapshot tells a fronting tier about the node: no failure, so it is not
# steered away from a node that did nothing wrong.
sub no_node_failure {
  my ($id, $name) = @_;
  my ($row) = grep { $_->{id} eq $id } @{$skeid->registry_snapshot->{nodes}};
  is $row->{errors_in_window}, 0, "$name: no error in the registry snapshot's window";
  is $row->{last_failure_at}, undef, "$name: no failure time in the registry snapshot";
}

sub near {
  my ($got, $expected, $name) = @_;
  my $ok = defined($got) && abs($got - $expected) < 1e-12;
  ok($ok, $name) or diag(sprintf('got %s, expected %.10f', $got // 'undef', $expected));
}

sub seen_upstream { my ($model) = @_; return grep { $_->{model} eq $model } @upstream }

# A raw client: sends one request and can hang up at any moment. $opt{deaf} stops it reading
# once the request is out, so the answer backs up on the proxy's side of the connection.
sub open_client {
  my ($path, $body, %opt) = @_;
  my $json = encode_json($body);
  my $client = { buffer => '', closed => 0 };
  Mojo::IOLoop->client({ address => '127.0.0.1', port => $t->ua->server->nb_url->port } => sub {
    my ($loop, $err, $stream) = @_;
    return $client->{error} = $err if $err;
    $client->{stream} = $stream;
    $stream->on(read  => sub { $client->{buffer} .= $_[1] });
    $stream->on(close => sub { $client->{closed} = 1; delete $client->{stream} });
    my $request = join("\r\n",
      'POST ' . $path . ' HTTP/1.1',
      'Host: 127.0.0.1',
      'Content-Type: application/json',
      'Content-Length: ' . length($json),
      '', '') . $json;
    $stream->write($request => sub { $_[0]->stop if $opt{deaf} });
  });
  return $client;
}

sub hang_up {
  my ($client) = @_;
  my $stream = $client->{stream} or return;
  $stream->close;
  return;
}

sub chat { my ($model, %extra) = @_; return { model => $model, messages => [{ role => 'user', content => 'hi' }], %extra } }

subtest 'hanging up while waiting for capacity stops the wait and takes no slot' => sub {
  add_node('wait-model');
  ok $skeid->start_request('wait-model'), 'the only slot is taken';

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  my $client = open_client('/v1/chat/completions', chat('wait-model'));
  ok run_until(sub { $skeid->busy_polls('wait-model') >= 2 }), 'the request is waiting for capacity';

  hang_up($client);
  ok run_until(sub { !live_since($from) }, 1), 'the abandoned request was let go';
  my $polls = $skeid->busy_polls('wait-model');
  run_for(0.05);
  is $skeid->busy_polls('wait-model'), $polls, 'no admission poll after the client hung up';

  $skeid->finish_request('wait-model', ok => 1);
  run_for(0.05);
  is scalar(seen_upstream('wait-model')), 0, 'the freed slot was not used to call upstream for nobody';
  paired_metrics('wait-model', 1, 'abandoned wait');
  is scalar(@usage_events), $events, 'a request that never reached upstream records no usage event';
  released_since($from, 'controller of the abandoned wait was destroyed');
};

subtest 'hanging up on a JSON request cancels the upstream call' => sub {
  add_node('hold-json');

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  my $client = open_client('/v1/chat/completions', chat('hold-json'));
  ok run_until(sub { scalar seen_upstream('hold-json') }), 'the request reached upstream';
  my ($seen) = seen_upstream('hold-json');

  hang_up($client);
  ok run_until(sub { $seen->{hung_up} }, 1), 'upstream saw its connection close';

  my $metrics = $skeid->node_metrics('hold-json');
  is $metrics->{inflight}, 0, 'the slot is free as soon as the client is gone';
  is scalar(@usage_events) - $events, 1, 'one usage event for the abandoned request';
  my $event = $usage_events[-1] || {};
  is $event->{node_id}, 'hold-json', 'usage event names the node';
  is $event->{ok}, 0, 'usage event is marked failed';
  is $event->{error_type}, 'client_abort', 'usage event names the cause';
  is $event->{status_code}, 499, 'usage event carries the client-closed status';

  # An upstream that was not cancelled answers now; its completion must not finish or bill again.
  $seen->{answer}->() if $seen->{answer};
  run_for(0.05);
  $metrics = paired_metrics('hold-json', 1, 'aborted JSON request');
  is $metrics->{aborted}, 1, 'counted once, as aborted';
  is $metrics->{error}, 0, 'a client that hung up is not a node error';
  no_node_failure('hold-json', 'aborted JSON request');
  is scalar(@usage_events) - $events, 1, 'still one usage event after the upstream ended';
  released_since($from, 'controller of the aborted JSON request was destroyed');
};

my %FACE = (
  openai    => [ '/v1/chat/completions', sub { chat($_[0], stream => \1) } ],
  anthropic => [ '/v1/messages',         sub { chat($_[0], stream => \1, max_tokens => 16) } ],
  ollama    => [ '/api/chat',            sub { chat($_[0]) } ],
);

for my $face (qw(openai anthropic ollama)) {
  subtest "hanging up on a stream cancels the upstream call and bills what it reported ($face)" => sub {
    my $model = 'hold-stream-' . $face;
    my ($path, $body) = @{$FACE{$face}};
    add_node($model);

    my $from = scalar @client_controllers;
    my $events = scalar @usage_events;
    my $client = open_client($path, $body->($model));
    ok run_until(sub { $client->{buffer} =~ /"ok"/ }), 'the client received the first content';
    my ($seen) = seen_upstream($model);

    hang_up($client);
    ok run_until(sub { $seen->{hung_up} }, 1), 'upstream saw its connection close';

    is $skeid->node_metrics($model)->{inflight}, 0, 'the slot is free as soon as the client is gone';
    is scalar(@usage_events) - $events, 1, 'one usage event for the abandoned stream';
    my $event = $usage_events[-1] || {};
    is $event->{api_format}, $face, 'usage event names the face';
    is $event->{ok}, 0, 'usage event is marked failed';
    is $event->{error_type}, 'client_abort', 'usage event names the cause';
    is $event->{status_code}, 499, 'usage event carries the client-closed status';
    is $event->{input_tokens}, 7, 'input tokens the stream had reported';
    is $event->{output_tokens}, 1, 'output tokens the stream had reported so far';
    is $event->{content_bytes}, 2, 'content bytes relayed so far';
    near($event->{cost_total_usd}, 7 / 1e6 * 3 + 1 / 1e6 * 15, 'priced from the usage reported so far');

    $seen->{answer}->() if $seen->{answer};
    run_for(0.05);
    my $metrics = paired_metrics($model, 1, 'aborted stream');
    is $metrics->{aborted}, 1, 'counted once, as aborted';
    is $metrics->{error}, 0, 'a client that hung up is not a node error';
    no_node_failure($model, 'aborted stream');
    is scalar(@usage_events) - $events, 1, 'still one usage event after the upstream ended';
    released_since($from, 'controller of the aborted stream was destroyed');
  };
}

subtest 'an abandoned stream whose upstream ends on its own releases its controller' => sub {
  add_node('hold-ending');

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  my $client = open_client('/v1/chat/completions', chat('hold-ending', stream => \1));
  ok run_until(sub { $client->{buffer} =~ /"ok"/ }), 'the client received the first content';
  my ($seen) = seen_upstream('hold-ending');

  hang_up($client);
  run_for(0.03);
  # Whatever the proxy did about the upstream call, the upstream is over after this.
  $seen->{answer}->() if $seen->{answer};
  run_for(0.05);

  paired_metrics('hold-ending', 1, 'abandoned stream, upstream ended');
  is scalar(@usage_events) - $events, 1, 'one usage event';
  released_since($from, 'controller, drain callback and queue were released');
};

subtest 'hanging up while a finished stream is still being written out' => sub {
  add_node('big-stream');

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  my $client = open_client('/v1/chat/completions', chat('big-stream', stream => \1), deaf => 1);
  ok run_until(sub { scalar(@usage_events) > $events }, 10), 'the upstream ended and the request was metered';
  is live_since($from), 1, 'the answer is still being written to a client that does not read';
  is $usage_events[-1]{ok}, 1, 'the upstream completed, so the request is metered as ok';

  hang_up($client);
  # The completed upstream transaction may still sit on its kept-alive connection and hold the
  # controller until that connection is used again; the client transaction is what goes now.
  ok run_until(sub { my $c = $client_controllers[-1]; !$c || !$c->tx }, 1),
    'the proxy noticed the closed connection';

  my $metrics = paired_metrics('big-stream', 1, 'abort after the upstream ended');
  is $metrics->{ok}, 1, 'the finish that already happened stands';
  is scalar(@usage_events) - $events, 1, 'the abort adds no second usage event';
  released_since($from, 'controller and the unwritten queue were released');
};

subtest 'hanging up while the node key is being resolved never reaches upstream' => sub {
  add_node('key-model', api_key_ref => 'secret/skeid/remote/abort');

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  my $client = open_client('/v1/chat/completions', chat('key-model'));
  ok run_until(sub { scalar @{$broker->held} }), 'the request is waiting for its node key';
  is $skeid->node_metrics('key-model')->{inflight}, 1, 'and holds a slot while it does';

  hang_up($client);
  # The controller is still held by the pending key resolution; its transaction is not.
  ok run_until(sub { my $c = $client_controllers[-1]; !$c || !$c->tx }, 1),
    'the proxy noticed the closed connection';
  is $broker->release('sk-test-vault-key'), 1, 'the key arrives after the client is gone';
  run_for(0.05);

  is scalar(seen_upstream('key-model')), 0, 'upstream was not called for nobody';
  paired_metrics('key-model', 1, 'abort during key resolution');
  is scalar(@usage_events), $events, 'a request that never reached upstream records no usage event';
  released_since($from, 'controller was destroyed');
};

# The key does not resolve either: refusing would record a usage event and render on a
# transaction nobody holds any more.
for my $case ([ 'JSON', {} ], [ 'stream', { stream => \1 } ]) {
  my ($label, $extra) = @$case;
  subtest 'hanging up while an unresolvable node key is being resolved refuses nobody, '.$label => sub {
    my $model = 'nokey-'.lc($label);
    add_node($model, api_key_ref => 'secret/skeid/remote/abort-'.lc($label));

    my $from = scalar @client_controllers;
    my $events = scalar @usage_events;
    my $client = open_client('/v1/chat/completions', chat($model, %$extra));
    ok run_until(sub { scalar @{$broker->held} }), 'the request is waiting for its node key';

    hang_up($client);
    ok run_until(sub { my $c = $client_controllers[-1]; !$c || !$c->tx }, 1),
      'the proxy noticed the closed connection';
    my @warnings;
    {
      local $SIG{__WARN__} = sub { push @warnings, join('', @_) };
      is $broker->release(undef), 1, 'the vault has no key, after the client is gone';
      run_for(0.05);
    }

    is scalar(seen_upstream($model)), 0, 'upstream was not called for nobody';
    paired_metrics($model, 1, 'abort during unresolvable key resolution');
    is scalar(@usage_events), $events, 'no refusal is recorded for a client that is gone';
    is scalar(grep { /request|transaction|Can't call|Can.t use/i } @warnings), 0,
      'nothing was rendered on the destroyed transaction'
      or diag explain \@warnings;
    released_since($from, 'controller was destroyed');
  };
}

subtest 'hanging up while the upstream connection is being opened' => sub {
  add_node('hold-connecting');

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  # The server notices the closed connection at the one moment no read can put it: the upstream
  # transaction exists and has no connection yet. Closing the server side from the user agent's
  # start event is what reading the client's EOF does, at a chosen time.
  my $closed_at_start = 0;
  $app->ua->once(start => sub {
    my ($ua, $tx) = @_;
    $closed_at_start = defined($tx->connection) ? -1 : 1;
    Mojo::IOLoop->stream($last_client_connection)->close;
  });
  my $client = open_client('/v1/chat/completions', chat('hold-connecting'));
  ok run_until(sub { $closed_at_start }), 'the client connection closed as the upstream call started';
  is $closed_at_start, 1, 'the upstream transaction had no connection yet';
  ok run_until(sub { !live_since($from) || grep { $_->{hung_up} } seen_upstream('hold-connecting') }, 1),
    'the upstream call ended';

  $_->{answer} && $_->{answer}->() for seen_upstream('hold-connecting');
  run_for(0.05);
  my $metrics = paired_metrics('hold-connecting', 1, 'abort while connecting');
  is $metrics->{aborted}, 1, 'counted once, as aborted';
  is $metrics->{error}, 0, 'a client that hung up is not a node error';
  no_node_failure('hold-connecting', 'abort while connecting');
  is scalar(@usage_events) - $events, 1, 'one usage event: the upstream call had been started';
  is $usage_events[-1]{error_type}, 'client_abort', 'usage event names the cause';
  released_since($from, 'controller was destroyed');
};

subtest 'a request that completes is not taken for an abort' => sub {
  add_node('plain-model', max_conns => 4);

  my $from = scalar @client_controllers;
  my $events = scalar @usage_events;
  $t->post_ok('/v1/chat/completions' => json => chat('plain-model'))
    ->status_is(200)->json_is('/choices/0/message/content' => 'ok');
  $t->post_ok('/v1/chat/completions' => json => chat('plain-model', stream => \1))
    ->status_is(200)->content_like(qr/\[DONE\]/);
  $t->post_ok('/v1/messages' => json => chat('plain-model', stream => \1, max_tokens => 16))
    ->status_is(200)->content_like(qr/message_stop/);

  released_since($from, 'completed controllers were destroyed');
  my $metrics = paired_metrics('plain-model', 3, 'completed requests');
  is $metrics->{ok}, 3, 'all three finished ok';
  my @events = @usage_events[$events .. $#usage_events];
  is scalar(@events), 3, 'one usage event each';
  is scalar(grep { $_->{ok} && !length($_->{error_type} // '') && $_->{status_code} == 200 } @events), 3,
    'none is marked as an abort';
};

done_testing;
