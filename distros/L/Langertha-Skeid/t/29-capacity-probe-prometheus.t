use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Langertha::Skeid;
use Langertha::Skeid::CapacityProbe;
use Langertha::Skeid::CapacityProbe::Prometheus;

# The active probe (ADR 0009): vLLM and SGLang already publish how loaded they are, including
# work this Skeid never sent them. That is the number inflight is trying and failing to
# reconstruct when a second frontend shares the node.

# --- parsing, without a server ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'gpu-1', url => 'http://gpu-1:8000/v1', model => 'm');
  my $probe = Langertha::Skeid::CapacityProbe::Prometheus->new(skeid => $skeid, node_id => 'gpu-1');

  my $values = $probe->parse_metrics(<<'METRICS');
# HELP vllm:num_requests_running Number of requests currently running
# TYPE vllm:num_requests_running gauge
vllm:num_requests_running{model_name="qwen3-32b"} 3.0
vllm:num_requests_waiting{model_name="qwen3-32b"} 1.0
vllm:gpu_cache_usage_perc{model_name="qwen3-32b"} 0.42
some_broken_line_without_a_value
vllm:nan_metric{x="y"} NaN
METRICS

  is $values->{'vllm:num_requests_running'}, 3, 'a gauge is read';
  is $values->{'vllm:num_requests_waiting'}, 1, 'labels are ignored';
  ok !exists $values->{'vllm:nan_metric'}, 'NaN is not a number to admit on';
  ok !exists $values->{some_broken_line_without_a_value}, 'a malformed line is skipped, not fatal';

  my $summed = $probe->parse_metrics(<<'METRICS');
vllm:num_requests_running{model_name="a"} 2
vllm:num_requests_running{model_name="b"} 5
METRICS
  is $summed->{'vllm:num_requests_running'}, 7,
    'several series of one metric are summed -- a per-model breakdown still adds up to what '
    . 'the node is doing';

  # Metrics usually sit beside the API, so naming the node is usually enough.
  is $probe->url, 'http://gpu-1:8000/metrics', 'the metrics URL is derived from the node URL';
  my $explicit = Langertha::Skeid::CapacityProbe::Prometheus->new(
    skeid => $skeid, node_id => 'gpu-1', config => { url => 'http://side-car:9100/m' });
  is $explicit->url, 'http://side-car:9100/m', 'and an explicit one wins';
}

# --- against a metrics endpoint ---
{
  my $running = 0;
  my $waiting = 0;
  my $status  = 200;
  my $polls   = 0;

  my $engine = Mojolicious->new;
  $engine->log->level('fatal');
  $engine->routes->get('/metrics' => sub {
    my ($c) = @_;
    $polls++;
    return $c->render(text => 'down', status => $status) unless $status == 200;
    $c->render(text => join("\n",
      "vllm:num_requests_running{model_name=\"m\"} $running",
      "vllm:num_requests_waiting{model_name=\"m\"} $waiting",
    ));
  });
  my $daemon = Mojo::Server::Daemon->new(app => $engine, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $port = $daemon->ports->[0];

  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 60_000);
  $skeid->add_node(
    id => 'gpu-1', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 8,
    capacity => { probe => 'prometheus', url => "http://127.0.0.1:$port/metrics", interval_ms => 100 },
  );

  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[0]);
  isa_ok $probe, 'Langertha::Skeid::CapacityProbe::Prometheus';

  # Polling is asynchronous by design, so the test drives the loop rather than sleeping in it.
  my $tick = sub {
    $probe->poll;
    my $done = 0;
    Mojo::IOLoop->timer(0.25 => sub { $done = 1; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    return;
  };

  ($running, $waiting) = (3, 1);
  $tick->();
  my $reading = $skeid->capacity_reading('gpu-1');
  ok $reading, 'the probe reported';
  is $reading->{used}, 4,
    'used is running + waiting -- a queued request occupies the node as surely as a running one, '
    . 'and admitting more because they are "only waiting" is how a queue becomes a timeout';
  is $reading->{limit}, 8, 'the limit falls back to max_conns rather than being written twice';
  is $reading->{source}, 'prometheus', 'tagged as measured';
  is $skeid->route_state(model => 'm')->{has_available}, 1, 'with room, the node is admissible';

  ($running, $waiting) = (8, 4);
  $tick->();
  is $skeid->capacity_reading('gpu-1')->{used}, 12, 'a fuller node reports fuller';
  is $skeid->route_state(model => 'm')->{has_available}, 0,
    'and over its limit it is not admitted, even though this process sent it nothing -- which '
    . 'is exactly the case inflight gets wrong when a second frontend shares the node';
  is $skeid->node_metrics('gpu-1')->{inflight}, 0, 'inflight really is zero here';

  # Unreachable must mean unknown, never "same as last time".
  $status = 503;
  $tick->();
  ok !$skeid->capacity_reading('gpu-1'),
    'a failed poll drops the reading rather than keeping a stale one';
  is $skeid->route_state(model => 'm')->{has_available}, 1,
    'so admission degrades to inflight instead of acting on a node it can no longer see';

  $status = 200;
  ($running, $waiting) = (1, 0);
  $tick->();
  is $skeid->capacity_reading('gpu-1')->{used}, 1, 'and recovers when the endpoint comes back';

  # An endpoint that answers but publishes nothing we recognise is the same kind of unknown --
  # most likely the wrong metric names for that engine.
  my $drain = sub {
    Mojo::IOLoop->timer(0.25 => sub { Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
  };

  my $skeid2 = Langertha::Skeid->new;
  $skeid2->add_node(id => 'gpu-2', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 4,
    capacity => { probe => 'prometheus', url => "http://127.0.0.1:$port/metrics",
                  running => 'nothing:like:this', waiting => 'nor:this' });
  Langertha::Skeid::CapacityProbe->for_node($skeid2, $skeid2->nodes->[0])->poll;
  $drain->();
  ok !$skeid2->capacity_reading('gpu-2'), 'unrecognised metric names report nothing';

  # Overriding one name must not silently unset the other: an engine that spells "running"
  # differently usually still spells "waiting" the normal way.
  ($running, $waiting) = (2, 5);
  my $skeid3 = Langertha::Skeid->new;
  $skeid3->add_node(id => 'gpu-3', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 4,
    capacity => { probe => 'prometheus', url => "http://127.0.0.1:$port/metrics",
                  running => 'vllm:num_requests_running' });
  Langertha::Skeid::CapacityProbe->for_node($skeid3, $skeid3->nodes->[0])->poll;
  $drain->();
  is $skeid3->capacity_reading('gpu-3')->{used}, 7,
    'naming one metric leaves the other on its default';
  ($running, $waiting) = (8, 4);

  $probe->stop;
  ok !$skeid->capacity_reading('gpu-1'), 'stopping a probe drops its reading too';
}

# --- what for_node builds, and what it deliberately does not ---
{
  my $skeid = Langertha::Skeid->new;

  $skeid->add_node(id => 'plain', url => 'http://x/v1', model => 'm');
  ok !Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]),
    'a node with no capacity block gets no probe -- that is plain inflight admission, not a '
    . 'probe that reports the same thing';

  $skeid->add_node(id => 'explicit', url => 'http://x/v1', model => 'm',
    capacity => { probe => 'inflight' });
  ok !Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]),
    'nor does asking for inflight by name';

  $skeid->add_node(id => 'cloud', url => 'http://x/v1', model => 'm',
    capacity => { probe => 'ratelimit' });
  ok !Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]),
    'and ratelimit needs nothing running: it is read off responses the proxy already has';

  $skeid->add_node(id => 'bogus', url => 'http://x/v1', model => 'm',
    capacity => { probe => 'telepathy' });
  ok !eval { Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]); 1 },
    'an unknown probe name is a config error, not a silent fallback to counting';
}

# --- custom: Skeid is generic, so this is part of the contract ---
{
  my $skeid = Langertha::Skeid->new;
  my $calls = 0;
  $skeid->add_node(id => 'weird', url => 'http://x/v1', model => 'm', max_conns => 10,
    capacity => {
      probe => 'custom',
      code  => sub {
        my ($probe) = @_;
        $calls++;
        $probe->skeid->set_capacity_reading($probe->node_id,
          source => 'custom', used => 9, limit => 10);
      },
    },
  );

  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]);
  isa_ok $probe, 'Langertha::Skeid::CapacityProbe::Custom';
  $probe->poll;
  is $calls, 1, 'the callback ran';
  is $skeid->capacity_reading('weird')->{used}, 9, 'and reported through the same contract';
  is $skeid->capacity_reading('weird')->{source}, 'custom', 'tagged as custom';

  $skeid->add_node(id => 'broken', url => 'http://x/v1', model => 'm',
    capacity => { probe => 'custom' });
  ok !eval { Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]); 1 },
    'custom without code or class is a config error';

  $skeid->add_node(id => 'inject', url => 'http://x/v1', model => 'm',
    capacity => { probe => 'custom', class => 'Foo/../../etc/passwd' });
  ok !eval { Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]); 1 },
    'a class name out of a config file has to look like one before it is loaded';
}

# --- a dying probe must not take the process with it ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'crashy', url => 'http://x/v1', model => 'm', max_conns => 2,
    capacity => { probe => 'custom', interval_ms => 100, code => sub { die "probe exploded\n" } });

  $skeid->set_capacity_reading('crashy', used => 2, limit => 2);
  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[-1]);

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  ok eval { $probe->start; 1 }, 'a probe that dies on its first poll does not take start() down';
  ok !$skeid->capacity_reading('crashy'),
    'and its reading is dropped, so a broken probe degrades to inflight rather than freezing '
    . 'admission at whatever it last said';
  $probe->stop;
}

done_testing;
