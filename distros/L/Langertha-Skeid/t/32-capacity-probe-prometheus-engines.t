use strict;
use warnings;
use Test::More;
use Langertha::Skeid;
use Langertha::Skeid::CapacityProbe::Prometheus;

# The Prometheus probe knows three engines by default (vLLM, SGLang, TGI) -- the three open
# inference servers that publish how loaded they are. The defaults are documented in
# Langertha::Skeid::CapacityProbe::Prometheus. This file is a contract test: a realistic
# /metrics blob per engine, parsed and summed the same way the probe does, ends up as the right
# used = running + waiting in set_capacity_reading. No HTTP, no IO loop -- just the parser and
# the set_capacity_reading path the probe writes to.

# Same sum rule the probe's _sum applies: a configured name (or list) wins, otherwise the engine
# default. We use it to mirror what poll() would compute without going through the HTTP path.
# Important: when no configured key is present in the parsed hash, _sum leaves the result undef
# so the probe can recognise "I see metrics but none I understand" as a separate condition.
sub engine_sum {
  my ($values, $running_names, $waiting_names) = @_;
  my ($r, $w);
  for my $name (grep { defined $values->{$_} } @$running_names) {
    $r = ($r // 0) + $values->{$name};
  }
  for my $name (grep { defined $values->{$_} } @$waiting_names) {
    $w = ($w // 0) + $values->{$name};
  }
  return ($r, $w);
}

# --- vLLM ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'vllm', url => 'http://gpu/v1', model => 'm');
  my $probe = Langertha::Skeid::CapacityProbe::Prometheus->new(skeid => $skeid, node_id => 'vllm');

  my $values = $probe->parse_metrics(<<'METRICS');
# HELP vllm:num_requests_running Number of requests currently running on GPU.
# TYPE vllm:num_requests_running gauge
# HELP vllm:num_requests_waiting Number of requests waiting to be processed.
# TYPE vllm:num_requests_waiting gauge
# HELP vllm:gpu_cache_usage_perc GPU KV-cache usage. (0.0 - 1.0)
# TYPE vllm:gpu_cache_usage_perc gauge
# HELP vllm:e2e_request_latency_seconds_count Cumulative count of finished requests.
# TYPE vllm:e2e_request_latency_seconds_count counter
vllm:num_requests_running{model_name="qwen3-32b"} 5.0
vllm:num_requests_waiting{model_name="qwen3-32b"} 2.0
vllm:gpu_cache_usage_perc{model_name="qwen3-32b"} 0.42
vllm:e2e_request_latency_seconds_count{model_name="qwen3-32b"} 1234.0
METRICS

  is $values->{'vllm:num_requests_running'}, 5, 'vLLM: num_requests_running is parsed';
  is $values->{'vllm:num_requests_waiting'}, 2, 'vLLM: num_requests_waiting is parsed';
  ok exists $values->{'vllm:gpu_cache_usage_perc'},
    'vLLM: an unrelated gauge (cache usage) is read by the parser';
  is $values->{'vllm:gpu_cache_usage_perc'}, 0.42, 'vLLM: its value is preserved verbatim';
  is $values->{'vllm:e2e_request_latency_seconds_count'}, 1234,
    'vLLM: a counter is read too -- the parser does not pretend to know what admission asks';

  my ($running, $waiting) = engine_sum(
    $values, ['vllm:num_requests_running'], ['vllm:num_requests_waiting'],
  );
  $skeid->set_capacity_reading('vllm', source => 'prometheus', used => $running + $waiting, limit => 32);
  my $reading = $skeid->capacity_reading('vllm');
  is $reading->{used}, 7, 'vLLM: set_capacity_reading lands on running + waiting (5 + 2)';
  is $reading->{source}, 'prometheus', 'vLLM: the reading is tagged as measured';
}

# --- SGLang ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'sglang', url => 'http://gpu/v1', model => 'm');
  my $probe = Langertha::Skeid::CapacityProbe::Prometheus->new(skeid => $skeid, node_id => 'sglang');

  my $values = $probe->parse_metrics(<<'METRICS');
# HELP sglang:num_running_reqs The number of running requests.
# TYPE sglang:num_running_reqs gauge
# HELP sglang:num_queue_reqs The number of requests in the waiting queue.
# TYPE sglang:num_queue_reqs gauge
# HELP sglang:token_usage Fraction of KV cache used.
# TYPE sglang:token_usage gauge
# HELP sglang:gen_throughput Tokens generated per second.
# TYPE sglang:gen_throughput gauge
sglang:num_running_reqs{model="meta-llama-3-70b"} 7
sglang:num_queue_reqs{model="meta-llama-3-70b"} 3
sglang:token_usage{model="meta-llama-3-70b"} 0.91
sglang:gen_throughput{model="meta-llama-3-70b"} 142.5
METRICS

  is $values->{'sglang:num_running_reqs'}, 7, 'SGLang: num_running_reqs is parsed';
  is $values->{'sglang:num_queue_reqs'}, 3, 'SGLang: num_queue_reqs is parsed';
  ok exists $values->{'sglang:token_usage'}, 'SGLang: an unrelated gauge is read by the parser';
  is $values->{'sglang:gen_throughput'}, 142.5, 'SGLang: a throughput gauge is preserved verbatim';

  my ($running, $waiting) = engine_sum(
    $values, ['sglang:num_running_reqs'], ['sglang:num_queue_reqs'],
  );
  $skeid->set_capacity_reading('sglang', source => 'prometheus', used => $running + $waiting, limit => 32);
  my $reading = $skeid->capacity_reading('sglang');
  is $reading->{used}, 10, 'SGLang: set_capacity_reading lands on running + waiting (7 + 3)';
  is $reading->{source}, 'prometheus', 'SGLang: the reading is tagged as measured';
}

# --- TGI ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'tgi', url => 'http://gpu/v1', model => 'm');
  my $probe = Langertha::Skeid::CapacityProbe::Prometheus->new(skeid => $skeid, node_id => 'tgi');

  my $values = $probe->parse_metrics(<<'METRICS');
# HELP tgi_batch_current_size The number of requests in the current batch.
# TYPE tgi_batch_current_size gauge
# HELP tgi_queue_size The number of requests waiting.
# TYPE tgi_queue_size gauge
# HELP tgi_request_success_total Total number of successful requests.
# TYPE tgi_request_success_total counter
# HELP tgi_request_failure_total Total number of failed requests.
# TYPE tgi_request_failure_total counter
tgi_batch_current_size 4.0
tgi_queue_size 6.0
tgi_request_success_total 9876.0
tgi_request_failure_total 12.0
METRICS

  is $values->{tgi_batch_current_size}, 4, 'TGI: batch_current_size is parsed';
  is $values->{tgi_queue_size}, 6, 'TGI: queue_size is parsed';
  ok exists $values->{tgi_request_success_total},
    'TGI: an unrelated counter (success_total) is read by the parser';
  is $values->{tgi_request_failure_total}, 12, 'TGI: failure_total is preserved verbatim';

  my ($running, $waiting) = engine_sum(
    $values, ['tgi_batch_current_size'], ['tgi_queue_size'],
  );
  $skeid->set_capacity_reading('tgi', source => 'prometheus', used => $running + $waiting, limit => 32);
  my $reading = $skeid->capacity_reading('tgi');
  is $reading->{used}, 10, 'TGI: set_capacity_reading lands on batch + queue (4 + 6)';
  is $reading->{source}, 'prometheus', 'TGI: the reading is tagged as measured';
}

# --- a wrong engine is the same kind of unknown as the wrong URL ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'mixed', url => 'http://gpu/v1', model => 'm');
  my $probe = Langertha::Skeid::CapacityProbe::Prometheus->new(
    skeid  => $skeid,
    node_id => 'mixed',
    config => { running => 'sglang:num_running_reqs', waiting => 'sglang:num_queue_reqs' },
  );

  my $values = $probe->parse_metrics(<<'METRICS');
vllm:num_requests_running{model_name="q"} 5.0
vllm:num_requests_waiting{model_name="q"} 2.0
METRICS

  my ($running, $waiting) = engine_sum(
    $values, ['sglang:num_running_reqs'], ['sglang:num_queue_reqs'],
  );
  ok !defined $running, 'vLLM metrics fed to an SGLang-only recogniser: running is undef';
  ok !defined $waiting, 'vLLM metrics fed to an SGLang-only recogniser: waiting is undef';

  # What the probe's poll() does with this state: forget_capacity, no set_capacity_reading call.
  # Replicating that branch here keeps the test offline.
  $skeid->forget_capacity('mixed') if !defined $running && !defined $waiting;
  ok !$skeid->capacity_reading('mixed'),
    'no recognisable metrics: the probe stays silent, so admission falls back to inflight -- '
    . 'the wrong metric name is the same unknown as the wrong URL';
  is $skeid->route_state(model => 'm')->{has_available}, 1,
    'and without a reading, inflight decides -- the node starts admissible';
}

done_testing;
