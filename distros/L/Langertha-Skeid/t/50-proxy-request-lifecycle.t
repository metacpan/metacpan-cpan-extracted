use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojo::IOLoop;
use Scalar::Util qw(weaken);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

{
  package Local::LifecycleSkeid;
  use parent 'Langertha::Skeid';

  # Arm capacity release only after the proxy has really selected the busy tier and found no free
  # route. next_tick returns control to the loop before releasing it, while still ordering the
  # release ahead of the retry timer. This exercises the wait callback without racing two clocks.
  sub on_next_busy_route {
    my ($self, $model, $cb) = @_;
    $self->{_lifecycle_on_busy_route}{$model} = $cb;
    return;
  }

  sub call_function {
    my ($self, $name, $args) = @_;
    my $result = $self->SUPER::call_function($name, $args);
    if ($name eq 'route.state' && $result->{has_eligible} && !$result->{has_available}
        && (my $cb = delete $self->{_lifecycle_on_busy_route}{$args->{model}})) {
      Mojo::IOLoop->next_tick($cb);
    }
    return $result;
  }
}

# Recursive admission and stream-drain callbacks must live while work is pending, then release
# their controller. A callback that closes strongly over itself keeps the whole completed request
# graph alive even though admission and the response have both finished.

my @usage_events;
my $skeid = Local::LifecycleSkeid->new(
  route_wait_timeout_ms => 40,
  route_wait_poll_ms    => 5,
  store_usage_event     => sub { push @usage_events, $_[1]; return { ok => 1 } },
);

my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');
$app->mode('production');

my @client_controllers;
$app->hook(before_dispatch => sub {
  my ($c) = @_;
  return unless $c->req->url->path->to_string eq '/v1/chat/completions';
  push @client_controllers, $c;
  weaken($client_controllers[-1]);
});

my @stream_frames = (
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"ok"},"finish_reason":null}]}\n\n},
  qq{data: {"id":"c1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":2,"completion_tokens":1,"total_tokens":3}}\n\n},
  qq{data: [DONE]\n\n},
);

$app->routes->post('/__fake_upstream/v1/chat/completions' => sub {
  my ($c) = @_;
  my $body = $c->req->json || {};
  if ($body->{stream}) {
    $c->res->headers->content_type('text/event-stream; charset=utf-8');
    $c->render(status => 200, data => join('', @stream_frames));
    return;
  }

  $c->render(json => {
    id      => 'chatcmpl-lifecycle',
    object  => 'chat.completion',
    model   => ($body->{model} // ''),
    choices => [{
      index         => 0,
      message       => { role => 'assistant', content => 'ok' },
      finish_reason => 'stop',
    }],
    usage => { prompt_tokens => 2, completion_tokens => 1, total_tokens => 3 },
  });
});

my $t = Test::Mojo->new($app);
my $upstream = $t->ua->server->nb_url->clone;
$upstream->path('/__fake_upstream/v1');

for my $node (
  [ immediate => 'immediate-model', 4 ],
  [ waiting   => 'waiting-model',   1 ],
  [ timeout   => 'timeout-model',   1 ],
  [ stream    => 'stream-model',    1 ],
) {
  my ($id, $model, $max_conns) = @$node;
  ok $skeid->add_node(
    id        => $id,
    url       => "$upstream",
    model     => $model,
    engine    => 'openai',
    healthy   => 1,
    max_conns => $max_conns,
  ), "$id node added";
}

sub settle_loop {
  my $settled = 0;
  Mojo::IOLoop->next_tick(sub {
    $settled = 1;
    Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
  });
  Mojo::IOLoop->start unless $settled;
}

sub released_since {
  my ($from, $name) = @_;
  # Both Test::Mojo's client UA and the proxy's upstream UA may retain their most recently used
  # transaction on a keep-alive connection. Reuse each connection with a request whose callbacks
  # do not capture the chat controller; anything still alive after that is Skeid-owned.
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
  my $live = grep { defined } @client_controllers[$from .. $#client_controllers];
  is $live, 0, $name;
}

sub post_chat {
  my ($model, %extra) = @_;
  return $t->post_ok('/v1/chat/completions' => json => {
    model    => $model,
    messages => [{ role => 'user', content => 'hi' }],
    %extra,
  });
}

sub paired_metrics {
  my ($id, $started, $name) = @_;
  my $metrics = $skeid->node_metrics($id);
  is $metrics->{started}, $started, "$name: expected request.start count";
  is $metrics->{inflight}, 0, "$name: no request remains in flight";
  is $metrics->{ok} + $metrics->{error}, $metrics->{started},
    "$name: every request.start has exactly one request.finish";
}

subtest 'immediate admission releases completed JSON controllers' => sub {
  my $from = scalar @client_controllers;
  for (1 .. 3) {
    post_chat('immediate-model')->status_is(200)->json_is('/choices/0/message/content' => 'ok');
  }
  released_since($from, 'all three completed JSON controllers were destroyed');
  paired_metrics('immediate', 3, 'immediate admission');
  is scalar(@usage_events), 3, 'one usage event per completed JSON request';
};

subtest 'wait retry keeps its controller until capacity returns, then releases it' => sub {
  ok $skeid->start_request('waiting'), 'occupy the waiting node';

  my $from = scalar @client_controllers;
  my $live_while_waiting;
  $skeid->on_next_busy_route('waiting-model' => sub {
    $live_while_waiting = grep { defined } @client_controllers[$from .. $#client_controllers];
    $skeid->finish_request('waiting', ok => 1);
  });

  post_chat('waiting-model')->status_is(200);
  is $live_while_waiting, 1,
    'controller remained live across refused admission until synchronized capacity release';

  released_since($from, 'controller was destroyed after timer-based admission');
  paired_metrics('waiting', 2, 'timer-based admission, including the occupied slot');
  is scalar(@usage_events), 4, 'waited request recorded one usage event';
};

subtest 'timeout and no-eligible failures release their controllers' => sub {
  ok $skeid->start_request('timeout'), 'occupy the timeout node';

  my $from = scalar @client_controllers;
  post_chat('timeout-model')->status_is(429)->json_is('/error/type' => 'rate_limit_error');
  released_since($from, 'timed-out controller was destroyed');

  $skeid->finish_request('timeout', ok => 1);
  paired_metrics('timeout', 1, 'timed-out admission did not start a second request');

  $from = scalar @client_controllers;
  post_chat('missing-model')->status_is(503)->json_is('/error/type' => 'model_not_found');
  released_since($from, 'no-eligible controller was destroyed');
  is scalar(@usage_events), 4, 'admission failures do not create upstream usage events';
};

subtest 'stream completion releases the admission and drain callbacks' => sub {
  my $from = scalar @client_controllers;
  post_chat('stream-model', stream => \1)
    ->status_is(200)
    ->header_is('x-skeid-node' => 'stream')
    ->content_like(qr/\[DONE\]/);

  released_since($from, 'completed streaming controller was destroyed');
  paired_metrics('stream', 1, 'streaming request');
  is scalar(@usage_events), 5, 'completed stream recorded one usage event';
  is $usage_events[-1]{input_tokens}, 2, 'stream usage retained input tokens';
  is $usage_events[-1]{output_tokens}, 1, 'stream usage retained output tokens';
};

done_testing;
