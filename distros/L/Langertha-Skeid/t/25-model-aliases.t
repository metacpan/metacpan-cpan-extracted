use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Time::HiRes qw(time);
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

# Aliases and tiers (ADR 0008): a client-facing model name resolves to an ordered list of node
# selections, tried until one admits the request. The two ways a tier can fail are different
# and the difference is the point -- a tier with no eligible node is hopeless and skipped, a
# tier whose nodes are merely busy is worth waiting for.

# --- plan resolution ---
{
  my $skeid = Langertha::Skeid->new(route_wait_timeout_ms => 1234);

  my $plain = $skeid->route_plan(model => 'no-alias-here')->{tiers};
  is(scalar(@$plain), 1, 'a model without an alias yields one implicit tier');
  is($plain->[0]{model}, 'no-alias-here', 'which selects on the requested name');
  is_deeply($plain->[0]{tags}, [], 'with no tag selector');
  is($plain->[0]{wait_ms}, 1234, 'and inherits the global wait, so aliasless routing is unchanged');

  $skeid->set_model_alias('fast', {
    tiers => [
      { tags => ['local'], model => 'qwen3-32b', wait_ms => 200 },
      { tags => ['cloud'], model => 'llama-3.3-70b' },
    ],
  });
  my $plan = $skeid->route_plan(model => 'fast')->{tiers};
  is(scalar(@$plan), 2, 'an alias yields its tiers in order');
  is($plan->[0]{model}, 'qwen3-32b', 'first tier serves the local model');
  is($plan->[1]{model}, 'llama-3.3-70b', 'second tier serves the cloud model');
  is($plan->[1]{wait_ms}, 0,
    'wait_ms defaults to 0: writing tiers means "try here, then there", waiting is opt-in');

  $skeid->set_model_alias('shorthand', [{ tags => ['local'] }]);
  is($skeid->route_plan(model => 'shorthand')->{tiers}[0]{model}, 'shorthand',
    'a tier without a model selects on the alias name itself');

  ok(!eval { $skeid->set_model_alias('broken', { tiers => [] }); 1 }, 'an alias needs at least one tier');
  ok(!eval { $skeid->set_model_alias('broken', 'nope'); 1 }, 'and has to be tiers, not a scalar');
}

# --- aliases from config, replaced wholesale on reload ---
{
  my $skeid = Langertha::Skeid->new(config_loader => sub {
    return {
      aliases => { fast => { tiers => [{ tags => ['local'], model => 'm-local' }] } },
      nodes   => [{ id => 'n1', url => 'http://x/v1', model => 'm-local', tags => ['local'] }],
    };
  });
  is($skeid->route_plan(model => 'fast')->{tiers}[0]{model}, 'm-local', 'aliases load from config');
}

# --- integration: two upstreams, one alias, real sockets ---
my %served;    # node label => [ models it was asked for ]

sub _upstream {
  my ($label) = @_;
  my $app = Mojolicious->new;
  $app->log->level('fatal');
  $app->routes->post('/v1/chat/completions' => sub {
    my ($c) = @_;
    my $body = $c->req->json || {};
    push @{ $served{$label} }, ($body->{model} // '');
    $c->render(json => {
      id      => "chatcmpl-$label",
      object  => 'chat.completion',
      model   => ($body->{model} // ''),
      choices => [{ index => 0, message => { role => 'assistant', content => "hi from $label" }, finish_reason => 'stop' }],
      usage   => { prompt_tokens => 3, completion_tokens => 4, total_tokens => 7 },
    });
  });
  my $daemon = Mojo::Server::Daemon->new(app => $app, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  return ($daemon, $daemon->ports->[0]);
}

my ($local_daemon, $local_port) = _upstream('local');
my ($cloud_daemon, $cloud_port) = _upstream('cloud');

my @events;
my $skeid = Langertha::Skeid->new(
  route_wait_poll_ms => 5,
  store_usage_event  => sub { push @events, $_[1]; return { ok => 1 } },
);
$skeid->add_node(id => 'local-1', url => "http://127.0.0.1:$local_port/v1",
  model => 'qwen3-32b', tags => ['local'], max_conns => 1);
$skeid->add_node(id => 'cloud-1', url => "http://127.0.0.1:$cloud_port/v1",
  model => 'llama-3.3-70b', tags => ['cloud'], max_conns => 4);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;

sub _ask {
  my ($model) = @_;
  my $tx;
  my $done = 0;
  my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("http://127.0.0.1:$proxy_port/v1/chat/completions" => json => {
    model    => $model,
    messages => [{ role => 'user', content => 'hi' }],
  } => sub {
    (undef, $tx) = @_;
    $done = 1;
    Mojo::IOLoop->stop;
  });
  Mojo::IOLoop->start unless $done;
  Mojo::IOLoop->remove($guard);
  return $tx;
}

# Local first, cloud only when local cannot take the request.
$skeid->set_model_alias('house-model', {
  tiers => [
    { tags => ['local'], model => 'qwen3-32b',     wait_ms => 0 },
    { tags => ['cloud'], model => 'llama-3.3-70b', wait_ms => 0 },
  ],
});

{
  %served = ();
  @events = ();
  my $tx = _ask('house-model');
  is($tx->res->code, 200, 'aliased request succeeds');
  is($tx->res->headers->header('x-skeid-node'), 'local-1', 'the first tier serves while it has room');
  is_deeply($served{local}, ['qwen3-32b'],
    'the node is asked for the served model, not the name the client used');
  ok(!exists $served{cloud}, 'and the second tier is not touched');

  is(scalar(@events), 1, 'one usage event');
  is($events[0]{model}, 'qwen3-32b', 'usage records the served model, which is what costs money');
  is($events[0]{requested_model}, 'house-model', 'and the requested one, which is what the customer bought');
}

# --- fall-through on saturation ---
{
  %served = ();
  @events = ();
  ok($skeid->start_request('local-1'), 'occupy the only local slot');

  my $t0 = time;
  my $tx = _ask('house-model');
  my $elapsed_ms = int((time - $t0) * 1000);

  is($tx->res->code, 200, 'the request still succeeds');
  is($tx->res->headers->header('x-skeid-node'), 'cloud-1', 'a saturated tier falls through to the next');
  is_deeply($served{cloud}, ['llama-3.3-70b'], 'and the next tier serves its own model');
  cmp_ok($elapsed_ms, '<', 300, "with wait_ms 0 the fall-through is immediate (${elapsed_ms}ms)");
  is($events[0]{requested_model}, 'house-model', 'the alias survives the fall-through in usage');

  $skeid->finish_request('local-1', ok => 1);
}

# --- a tier waits for its own window before giving up on it ---
{
  %served = ();
  $skeid->set_model_alias('patient-model', {
    tiers => [
      { tags => ['local'], model => 'qwen3-32b',     wait_ms => 250 },
      { tags => ['cloud'], model => 'llama-3.3-70b', wait_ms => 0 },
    ],
  });
  ok($skeid->start_request('local-1'), 'occupy the only local slot again');

  my $t0 = time;
  my $tx = _ask('patient-model');
  my $elapsed_ms = int((time - $t0) * 1000);

  is($tx->res->headers->header('x-skeid-node'), 'cloud-1', 'it still ends up on the cloud tier');
  cmp_ok($elapsed_ms, '>=', 200,
    "but only after waiting out the local tier's window (${elapsed_ms}ms) -- this is the knob that "
    . 'trades a little latency for not paying for cloud on a momentary blip');

  $skeid->finish_request('local-1', ok => 1);
}

# --- a tier with nothing eligible is skipped, not waited on ---
{
  %served = ();
  $skeid->set_model_alias('ghost-tier', {
    tiers => [
      { tags => ['nonesuch'], model => 'qwen3-32b',     wait_ms => 5000 },
      { tags => ['cloud'],    model => 'llama-3.3-70b', wait_ms => 0 },
    ],
  });

  my $t0 = time;
  my $tx = _ask('ghost-tier');
  my $elapsed_ms = int((time - $t0) * 1000);

  is($tx->res->headers->header('x-skeid-node'), 'cloud-1', 'an empty tier is skipped');
  cmp_ok($elapsed_ms, '<', 1000,
    "immediately, despite its 5s window (${elapsed_ms}ms) -- waiting cannot conjure a node that does not exist");
}

# --- exhausted plans: 503 when nothing was ever eligible, 429 when everything was busy ---
{
  $skeid->set_model_alias('nowhere', { tiers => [{ tags => ['nonesuch'] }] });
  my $tx = _ask('nowhere');
  is($tx->res->code, 503, 'no eligible node anywhere is a 503 -- a config problem, retrying will not help');
  is($tx->res->json->{error}{type}, 'model_not_found', 'and says so');
}

{
  $skeid->set_model_alias('busy', {
    tiers => [{ tags => ['local'], model => 'qwen3-32b', wait_ms => 50 }],
  });
  ok($skeid->start_request('local-1'), 'saturate the only tier');

  my $tx = _ask('busy');
  is($tx->res->code, 429, 'eligible but never admitted is a 429 -- a load problem, retrying will help');
  is($tx->res->json->{error}{type}, 'rate_limit_error', 'and says that instead');

  $skeid->finish_request('local-1', ok => 1);
}

is($skeid->node_metrics('local-1')->{inflight}, 0, 'no admission leaked across all of the above');
is($skeid->node_metrics('cloud-1')->{inflight}, 0, 'on either node');

done_testing;
