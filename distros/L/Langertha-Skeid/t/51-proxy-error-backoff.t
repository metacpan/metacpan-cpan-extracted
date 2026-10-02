use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Time::HiRes qw(time);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# A real HTTP 429 is also reported by Mojo::Transaction::HTTP->error. Capacity headers must be
# observed before that error path returns, otherwise Retry-After is lost and the next request is
# sent straight back to the already rate-limited node.

my %upstream_hits;
my @usage_events;
my $skeid = Langertha::Skeid->new(
  route_wait_timeout_ms => 25,
  route_wait_poll_ms    => 5,
  store_usage_event     => sub { push @usage_events, $_[1]; return { ok => 1 } },
);

my $app = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$app->log->level('fatal');
$app->mode('production');

$app->routes->post('/__rate_limited_upstream/v1/chat/completions' => sub {
  my ($c) = @_;
  my $model = ($c->req->json || {})->{model} // '';
  $upstream_hits{$model}++;
  $c->res->headers->header('Retry-After' => '60');
  $c->render(status => 429,
    json => { error => { message => 'capacity exhausted', type => 'rate_limit_error' } });
});

my $t = Test::Mojo->new($app);
my $upstream = $t->ua->server->nb_url->clone;
$upstream->path('/__rate_limited_upstream/v1');

my @cases = (
  {
    name  => 'OpenAI JSON',
    id    => 'openai-rate',
    model => 'openai-rate-model',
    path  => '/v1/chat/completions',
    body  => sub {
      return {
        model    => 'openai-rate-model',
        stream   => \0,
        messages => [{ role => 'user', content => 'hi' }],
      };
    },
    assert_error => sub {
      my ($body, $which) = @_;
      is ref($body->{error}), 'HASH', "$which keeps the OpenAI error envelope";
      ok length($body->{error}{message} // ''), "$which carries an OpenAI error message";
    },
  },
  {
    name  => 'Anthropic stream',
    id    => 'anthropic-rate',
    model => 'anthropic-rate-model',
    path  => '/v1/messages',
    body  => sub {
      return {
        model      => 'anthropic-rate-model',
        max_tokens => 16,
        stream     => \1,
        messages   => [{ role => 'user', content => 'hi' }],
      };
    },
    assert_error => sub {
      my ($body, $which) = @_;
      is $body->{type}, 'error', "$which keeps the Anthropic error envelope";
      is $body->{error}{type}, 'rate_limit_error', "$which remains an Anthropic rate-limit error";
    },
  },
  {
    name  => 'Ollama stream',
    id    => 'ollama-rate',
    model => 'ollama-rate-model',
    path  => '/api/chat',
    body  => sub {
      return {
        model    => 'ollama-rate-model',
        stream   => \1,
        messages => [{ role => 'user', content => 'hi' }],
      };
    },
    assert_error => sub {
      my ($body, $which) = @_;
      is_deeply [sort keys %$body], ['error'], "$which keeps the Ollama error envelope";
      ok defined($body->{error}) && !ref($body->{error}) && length($body->{error}),
        "$which keeps Ollama's scalar error message";
    },
  },
);

for my $case (@cases) {
  ok $skeid->add_node(
    id        => $case->{id},
    url       => "$upstream",
    model     => $case->{model},
    engine    => 'openai',
    healthy   => 1,
    max_conns => 4,
  ), "$case->{name}: node added";
}

for my $case (@cases) {
  subtest $case->{name} => sub {
    my $events_before = scalar @usage_events;

    $t->post_ok($case->{path} => json => $case->{body}->())->status_is(429);
    $case->{assert_error}->($t->tx->res->json, 'upstream 429');

    is $upstream_hits{$case->{model}}, 1, 'the first request reached the upstream once';
    my $reading = $skeid->capacity_reading($case->{id});
    ok $reading, 'the 429 response created a capacity reading';
    if ($reading) {
      is $reading->{source}, 'ratelimit', 'the reading is identified as rate-limit capacity';
      cmp_ok $reading->{retry_after}, '>', time + 50, 'Retry-After: 60 is retained as a future backoff';
    }
    my ($node) = grep { ($_->{id} // '') eq $case->{id} } @{$skeid->list_nodes};
    is $node->{healthy}, 1, 'rate limiting does not alter node health';

    my $metrics = $skeid->node_metrics($case->{id});
    is $metrics->{started}, 1, 'the upstream request started once';
    is $metrics->{inflight}, 0, 'the upstream request finished before the response returned';
    is $metrics->{ok} + $metrics->{error}, 1, 'request.start and request.finish are paired once';
    is scalar(@usage_events), $events_before + 1, 'the upstream 429 records one usage event';

    $t->post_ok($case->{path} => json => $case->{body}->())->status_is(429);
    $case->{assert_error}->($t->tx->res->json, 'local backoff');

    is $upstream_hits{$case->{model}}, 1, 'the immediate retry is rejected without another upstream call';
    is scalar(@usage_events), $events_before + 1, 'the local admission error does not duplicate usage';
    $metrics = $skeid->node_metrics($case->{id});
    is $metrics->{started}, 1, 'local backoff does not call request.start again';
    is $metrics->{inflight}, 0, 'local backoff leaves no request in flight';
    is $metrics->{ok} + $metrics->{error}, 1, 'local backoff does not call request.finish again';
  };
}

done_testing;
