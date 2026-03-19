use strict;
use warnings;
use Test::More;
use Langertha::Skeid;

my $skeid = Langertha::Skeid->new;
ok $skeid->add_node(
  id => 'n1',
  url => 'http://127.0.0.1:21001/v1',
  model => 'qwen2.5',
), 'node added';

is scalar(@{$skeid->list_nodes}), 1, 'one node';
is $skeid->list_nodes->[0]{engine}, 'openaibase', 'default engine normalized to openaibase';

my $pricing = $skeid->set_model_pricing('qwen2.5', {
  input_per_million => 0.2,
  output_per_million => 0.8,
});

is $pricing->{input_per_million}, 0.2, 'pricing set';

my $cost = $skeid->estimate_cost(
  model => 'qwen2.5',
  usage => { prompt_tokens => 1000, completion_tokens => 500 },
);

ok $cost->{total_cost_usd} > 0, 'cost estimated';

my $metrics = $skeid->normalize_metrics(
  provider => 'skeid',
  engine   => 'vllm',
  model    => 'qwen2.5',
  usage    => { prompt_tokens => 100, completion_tokens => 20 },
  tool_calls => [{ function => { name => 'lookup' } }],
);

is $metrics->{tool_calls}, 1, 'tool call counted';
is_deeply $metrics->{tool_names}, ['lookup'], 'tool names normalized';

is $skeid->call_function('nodes.list', {})->{nodes}[0]{id}, 'n1', 'function dispatch works';

ok $skeid->remove_node('n1'), 'node removed';
is scalar(@{$skeid->list_nodes}), 0, 'no nodes left';

{
  my $ok = $skeid->add_node(
    id     => 'n2',
    url    => 'http://127.0.0.1:21001/v1',
    model  => 'qwen2.5',
    engine => 'OpenAIBase',
  );
  ok $ok, 'node added with class-like engine';
  is $skeid->list_nodes->[0]{engine}, 'openaibase', 'class-like engine normalized';
}

{
  eval {
    $skeid->add_node(
      id     => 'bad',
      url    => 'http://127.0.0.1:21001/v1',
      model  => 'qwen2.5',
      engine => 'openai-compatible',
    );
  };
  like $@, qr/unknown engine 'openai-compatible'/, 'legacy engine id rejected';
}

ok $skeid->remove_node('n2'), 'n2 removed';
is scalar(@{$skeid->list_nodes}), 0, 'no nodes left';

ok $skeid->add_node(id => 'route-a', url => 'http://a', model => 'qwen2.5', weight => 1, max_conns => 1), 'route-a added';
ok $skeid->add_node(id => 'route-b', url => 'http://b', model => 'qwen2.5', weight => 1, max_conns => 1), 'route-b added';

my $pick1 = $skeid->call_function('route.next', { model => 'qwen2.5' })->{node};
ok $pick1->{id}, 'route.next returned node';
ok $skeid->call_function('request.start', { id => $pick1->{id} })->{ok}, 'request.start ok';

my $pick2 = $skeid->call_function('route.next', { model => 'qwen2.5' })->{node};
ok $pick2->{id} && $pick2->{id} ne $pick1->{id}, 'routing skips saturated node';

ok $skeid->call_function('request.finish', { id => $pick1->{id}, ok => 1, duration_ms => 12 })->{ok}, 'request.finish ok';
my $m = $skeid->call_function('nodes.metrics', { id => $pick1->{id} })->{metrics};
is $m->{ok}, 1, 'success metric counted';
is $m->{duration_ms_total}, 12, 'duration metric counted';

ok $skeid->call_function('nodes.set_health', { id => 'route-b', healthy => 0 })->{ok}, 'set health works';
my $pick3 = $skeid->call_function('route.next', { model => 'qwen2.5' })->{node};
is $pick3->{id}, 'route-a', 'unhealthy nodes are excluded';

{
  my $state = $skeid->call_function('route.state', { model => 'qwen2.5' });
  is $state->{eligible_count}, 1, 'route.state eligible count';
  is $state->{available_count}, 1, 'route.state available count';
  ok $state->{has_eligible}, 'route.state has eligible';
  ok $state->{has_available}, 'route.state has available';
}

done_testing;
