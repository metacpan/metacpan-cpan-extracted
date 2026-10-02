#!/usr/bin/env perl
# ABSTRACT: Offline tests for Langertha::Runtime::Metrics::OTLP payload shape + MetricsPoll export

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;

use lib path(__FILE__)->parent->child('lib')->stringify;

use Langertha::Runtime::Metrics;
use Langertha::Runtime::Metrics::OTLP;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $otlp = Langertha::Runtime::Metrics::OTLP->new;

# --- Gauge + counter payload shape ---

subtest 'gauge and counter map to OTLP gauge/sum' => sub {
  my $records = [
    { name => 'vllm:num_requests_running', type => 'gauge',
      value => 3, labels => { model_name => 'Qwen/Qwen2.5-7B-Instruct' } },
    { name => 'vllm:prompt_tokens_total', type => 'counter',
      value => 18234, labels => { model_name => 'Qwen/Qwen2.5-7B-Instruct' } },
  ];

  my $payload = $otlp->build_payload($records,
    service_name => 'vllm',
    timestamp    => 1_735_689_600,
  );

  ok(ref($payload) eq 'HASH', 'build_payload returns HashRef');
  ok(exists $payload->{resourceMetrics}, 'payload has resourceMetrics');
  is(scalar @{$payload->{resourceMetrics}}, 1, 'one resourceMetrics entry');

  my $rm = $payload->{resourceMetrics}[0];
  my %res_attrs = map { $_->{key} => $_->{value} } @{ $rm->{resource}{attributes} };
  ok(exists $res_attrs{'service.name'}, 'service.name resource attribute present');
  is($res_attrs{'service.name'}{stringValue}, 'vllm', 'service.name is a stringValue');

  my $sm = $rm->{scopeMetrics}[0];
  is($sm->{scope}{name}, 'langertha', 'scope name defaults to langertha');

  my %by_name = map { $_->{name} => $_ } @{ $sm->{metrics} };
  is(scalar @{ $sm->{metrics} }, 2, 'two metrics emitted');

  # Gauge
  my $gauge = $by_name{'vllm:num_requests_running'};
  ok(exists $gauge->{gauge}, 'gauge record maps to OTLP gauge');
  my $gdp = $gauge->{gauge}{dataPoints}[0];
  is($gdp->{asDouble}, 3, 'gauge value as asDouble');
  like($gdp->{timeUnixNano}, qr/^\d+$/, 'timeUnixNano is a string of digits');
  is($gdp->{timeUnixNano}, '1735689600000000000', 'timeUnixNano = epoch * 1e9');
  my %gattrs = map { $_->{key} => $_->{value}{stringValue} } @{ $gdp->{attributes} };
  is_deeply(\%gattrs, { model_name => 'Qwen/Qwen2.5-7B-Instruct' },
    'labels become stringValue attributes');

  # Counter → monotonic cumulative sum
  my $sum = $by_name{'vllm:prompt_tokens_total'};
  ok(exists $sum->{sum}, 'counter record maps to OTLP sum');
  is($sum->{sum}{aggregationTemporality}, 'AGGREGATION_TEMPORALITY_CUMULATIVE',
    'counter is cumulative');
  is($sum->{sum}{isMonotonic}, JSON->true, 'counter is monotonic');
  is($sum->{sum}{dataPoints}[0]{asDouble}, 18234, 'counter value as asDouble');
};

# --- untyped falls back to gauge ---

subtest 'untyped maps to gauge' => sub {
  my $payload = $otlp->build_payload([
    { name => 'some_untyped', type => 'untyped', value => 1.5, labels => {} },
  ]);
  my $metric = $payload->{resourceMetrics}[0]{scopeMetrics}[0]{metrics}[0];
  ok(exists $metric->{gauge}, 'untyped record maps to OTLP gauge');
  is($metric->{gauge}{dataPoints}[0]{asDouble}, 1.5, 'untyped value preserved');
};

# --- Histogram reconstruction ---

subtest 'histogram series regroup into one OTLP histogram' => sub {
  my $records = [
    { name => 'llama_request_duration_seconds_bucket', type => 'histogram',
      value => 47, labels => { le => '0.5' } },
    { name => 'llama_request_duration_seconds_bucket', type => 'histogram',
      value => 51, labels => { le => '1.0' } },
    { name => 'llama_request_duration_seconds_bucket', type => 'histogram',
      value => 52, labels => { le => '+Inf' } },
    { name => 'llama_request_duration_seconds_sum', type => 'histogram',
      value => 23.4, labels => {} },
    { name => 'llama_request_duration_seconds_count', type => 'histogram',
      value => 52, labels => {} },
  ];

  my $payload = $otlp->build_payload($records, timestamp => 1_735_689_600);
  my $metrics = $payload->{resourceMetrics}[0]{scopeMetrics}[0]{metrics};
  is(scalar @$metrics, 1, 'histogram series collapse to a single metric');

  my $hist = $metrics->[0];
  is($hist->{name}, 'llama_request_duration_seconds', 'metric name is the base name');
  ok(exists $hist->{histogram}, 'maps to OTLP histogram');
  is($hist->{histogram}{aggregationTemporality}, 'AGGREGATION_TEMPORALITY_CUMULATIVE',
    'histogram is cumulative');

  my $dp = $hist->{histogram}{dataPoints}[0];
  is_deeply($dp->{explicitBounds}, [ 0.5, 1.0 ], 'explicitBounds excludes +Inf, sorted');
  is_deeply($dp->{bucketCounts}, [ '47', '51', '52' ],
    'bucketCounts are cumulative strings incl. +Inf bucket');
  is($dp->{count}, '52', 'count is a uint64 string');
  is($dp->{sum}, 23.4, 'sum preserved');
  ok(!exists $dp->{attributes}, 'no le label leaks into data-point attributes');
};

# --- Summary reconstruction ---

subtest 'summary series regroup into one OTLP summary' => sub {
  my $records = [
    { name => 'llama_request_duration_summary_sum', type => 'summary',
      value => 23.4, labels => {} },
    { name => 'llama_request_duration_summary_count', type => 'summary',
      value => 52, labels => {} },
    { name => 'llama_request_duration_summary', type => 'summary',
      value => 0.45, labels => { quantile => '0.5' } },
    { name => 'llama_request_duration_summary', type => 'summary',
      value => 0.9, labels => { quantile => '0.99' } },
  ];

  my $payload = $otlp->build_payload($records, timestamp => 1_735_689_600);
  my $metrics = $payload->{resourceMetrics}[0]{scopeMetrics}[0]{metrics};
  is(scalar @$metrics, 1, 'summary series collapse to a single metric');

  my $summary = $metrics->[0];
  is($summary->{name}, 'llama_request_duration_summary', 'metric name is the base name');
  ok(exists $summary->{summary}, 'maps to OTLP summary');

  my $dp = $summary->{summary}{dataPoints}[0];
  is($dp->{count}, '52', 'summary count is a uint64 string');
  is($dp->{sum}, 23.4, 'summary sum preserved');
  is_deeply($dp->{quantileValues},
    [ { quantile => 0.5, value => 0.45 }, { quantile => 0.99, value => 0.9 } ],
    'quantileValues sorted by quantile');
};

# --- to_json round-trip ---

subtest 'to_json round-trips through JSON' => sub {
  my $records = [
    { name => 'vllm:num_requests_running', type => 'gauge',
      value => 3, labels => { model_name => 'Qwen/Qwen2.5-7B-Instruct' } },
  ];
  my $body = $otlp->to_json($records, service_name => 'vllm');
  ok(ref($body) eq '' && length $body, 'to_json returns a string');

  my $decoded = $json->decode($body);
  my $metric = $decoded->{resourceMetrics}[0]{scopeMetrics}[0]{metrics}[0];
  is($metric->{name}, 'vllm:num_requests_running', 'round-trip keeps metric name');
  is($metric->{gauge}{dataPoints}[0]{asDouble}, 3, 'round-trip keeps value');
  is($decoded->{resourceMetrics}[0]{resource}{attributes}[0]{key}, 'service.name',
    'round-trip keeps resource attribute');
};

# --- Argument validation ---

subtest 'build_payload validates input' => sub {
  eval { $otlp->build_payload('not-an-arrayref') };
  ok($@, 'build_payload croaks on non-ArrayRef');
};

# --- export_otlp_f via mock HTTP ---

subtest 'export_otlp_f POSTs the OTLP payload' => sub {
  require Test::MockAsyncHTTP;
  require Langertha::Engine::vLLM;

  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [ HTTP::Response->new(200, 'OK') ],
  );

  my $engine = Langertha::Engine::vLLM->new(
    url         => 'http://localhost:8000/v1',
    _async_http => $mock_http,
  );

  my $records = [
    { name => 'vllm:num_requests_running', type => 'gauge',
      value => 3, labels => { model_name => 'Qwen/Qwen2.5-7B-Instruct' } },
  ];

  my $response;
  eval {
    # The mock transport completes synchronously, so the future is already
    # done — ->get returns the response directly (Loop->await would hand
    # back the Future itself for a done future).
    $response = $engine->export_otlp_f($records,
      endpoint     => 'http://localhost:4318/v1/metrics',
      service_name => 'vllm',
    )->get;
  };
  if ($@) { fail "export_otlp_f: $@"; return; }

  ok($response->is_success, 'export returns the 200 response');
  is($mock_http->request_count, 1, 'one HTTP request sent');

  my $request = ($mock_http->requests)[0];
  is($request->method, 'POST', 'export uses POST');
  is($request->uri, 'http://localhost:4318/v1/metrics', 'export targets the endpoint');
  is($request->header('Content-Type'), 'application/json', 'export sends JSON');

  my $decoded = $json->decode($request->content);
  my $metric = $decoded->{resourceMetrics}[0]{scopeMetrics}[0]{metrics}[0];
  is($metric->{name}, 'vllm:num_requests_running', 'exported body has the metric');
  is($decoded->{resourceMetrics}[0]{resource}{attributes}[0]{value}{stringValue},
    'vllm', 'exported body has service.name');
};

subtest 'export_otlp_f passes extra headers' => sub {
  require Test::MockAsyncHTTP;
  require Langertha::Engine::vLLM;

  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [ HTTP::Response->new(200, 'OK') ],
  );
  my $engine = Langertha::Engine::vLLM->new(
    url         => 'http://localhost:8000/v1',
    _async_http => $mock_http,
  );

  $engine->export_otlp_f(
    [ { name => 'x', type => 'gauge', value => 1, labels => {} } ],
    endpoint => 'http://localhost:4318/v1/metrics',
    headers  => { Authorization => 'Basic Zm9vOmJhcg==' },
  )->get;

  my $request = ($mock_http->requests)[0];
  is($request->header('Authorization'), 'Basic Zm9vOmJhcg==', 'extra header sent');
};

# --- sync wrappers unwrap the Future (karr k164) --------------------------
# poll_metrics / export_otlp drive their _f async form on the private loop and
# MUST return the resolved payload, not the Future itself. Regression guard for
# the missing ->get: before the fix these returned a Future object, so the
# documented sync usage ($vllm->poll_metrics; for (@$records) {...}) died on
# "Not an ARRAY reference".

subtest 'poll_metrics (sync) returns the parsed ArrayRef, not a Future' => sub {
  require Test::MockAsyncHTTP;
  require Langertha::Engine::vLLM;

  my $body = <<'PROM';
# HELP vllm:num_requests_running Number of running requests
# TYPE vllm:num_requests_running gauge
vllm:num_requests_running{model_name="Qwen/Qwen2.5-7B-Instruct"} 3
# HELP vllm:prompt_tokens_total Prompt tokens processed
# TYPE vllm:prompt_tokens_total counter
vllm:prompt_tokens_total{model_name="Qwen/Qwen2.5-7B-Instruct"} 18234
PROM

  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [ { status => 200, content => $body, content_type => 'text/plain' } ],
  );
  my $engine = Langertha::Engine::vLLM->new(
    url         => 'http://localhost:8000/v1',
    _async_http => $mock_http,
  );

  my $records = eval { $engine->poll_metrics('vllm:') };
  if ($@) { fail "poll_metrics (sync): $@"; return; }

  is(ref($records), 'ARRAY',
    'sync poll_metrics returns an ArrayRef (not the Future)');
  my %by_name = map { $_->{name} => $_ } @$records;
  is($by_name{'vllm:num_requests_running'}{value}, 3, 'scraped gauge value');
  is($by_name{'vllm:prompt_tokens_total'}{value}, 18234, 'scraped counter value');
  is($mock_http->request_count, 1, 'one /metrics request sent through the sync wrapper');
  my $request = ($mock_http->requests)[0];
  is($request->uri, 'http://localhost:8000/metrics', 'sync scrape hits the /metrics URL');
};

subtest 'export_otlp (sync) returns the HTTP::Response, not a Future' => sub {
  require Test::MockAsyncHTTP;
  require Langertha::Engine::vLLM;

  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [ HTTP::Response->new(200, 'OK') ],
  );
  my $engine = Langertha::Engine::vLLM->new(
    url         => 'http://localhost:8000/v1',
    _async_http => $mock_http,
  );

  my $response = eval {
    $engine->export_otlp(
      [ { name => 'vllm:num_requests_running', type => 'gauge', value => 3, labels => {} } ],
      endpoint     => 'http://localhost:4318/v1/metrics',
      service_name => 'vllm',
    );
  };
  if ($@) { fail "export_otlp (sync): $@"; return; }

  ok(ref($response) && $response->isa('HTTP::Response'),
    'sync export_otlp returns an HTTP::Response (not the Future)');
  ok($response->is_success, 'response is the mocked 200');
  is($mock_http->request_count, 1, 'one HTTP request sent through the sync wrapper');
};

subtest 'export_otlp_f croaks without endpoint' => sub {
  require Langertha::Engine::vLLM;
  my $engine = Langertha::Engine::vLLM->new(url => 'http://localhost:8000/v1');
  my $ok = eval { $engine->export_otlp_f([])->get; 1 };
  ok(!$ok, 'export without endpoint croaks');
  like($@, qr/requires an endpoint/, 'croak message names the missing option');
};

subtest 'export_otlp_f croaks on non-success response' => sub {
  require Test::MockAsyncHTTP;
  require Langertha::Engine::vLLM;

  my $mock_http = Test::MockAsyncHTTP->new(
    responses => [ HTTP::Response->new(500, 'Internal Server Error') ],
  );
  my $engine = Langertha::Engine::vLLM->new(
    url         => 'http://localhost:8000/v1',
    _async_http => $mock_http,
  );

  my $ok = eval {
    $engine->export_otlp_f(
      [ { name => 'x', type => 'gauge', value => 1, labels => {} } ],
      endpoint => 'http://localhost:4318/v1/metrics',
    )->get;
    1;
  };
  ok(!$ok, 'export croaks on 500');
  like($@, qr/OTLP export failed/, 'croak message names the export');
};

done_testing;
