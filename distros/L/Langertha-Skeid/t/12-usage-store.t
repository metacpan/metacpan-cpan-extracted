use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Test::File::ShareDir -share => {
  -dist => { 'Langertha-Skeid' => 'share' },
};
use Langertha::Skeid;

my $tmp = tempdir(CLEANUP => 1);
my $db  = "$tmp/usage.sqlite";

my $skeid = Langertha::Skeid->new(
  usage_store => {
    backend     => 'sqlite',
    sqlite_path => $db,
  },
);

ok(-f $db, 'sqlite usage db created');

my $metrics = $skeid->call_function('metrics.normalize', {
  provider    => 'skeid',
  engine      => 'openaibase',
  model       => 'qwen2.5-7b-instruct',
  route       => '/v1/chat/completions',
  duration_ms => 37,
  usage       => { prompt_tokens => 120, completion_tokens => 30, total_tokens => 150 },
  tool_calls  => [{ function => { name => 'lookup' } }],
});

my $saved = $skeid->call_function('usage.record', {
  api_format   => 'openai',
  endpoint     => '/v1/chat/completions',
  api_key_id   => 'k_demo',
  provider     => 'skeid',
  engine       => 'openaibase',
  model        => 'qwen2.5-7b-instruct',
  node_id      => 'n1',
  status_code  => 200,
  ok           => 1,
  duration_ms  => 37,
  metrics      => $metrics,
});
ok($saved->{ok}, 'usage.record succeeded');

my $report = $skeid->call_function('usage.report', { limit => 10 });
ok($report->{ok}, 'usage.report succeeded');
is($report->{backend}, 'sqlite', 'backend reported');
is($report->{totals}{requests}, 1, 'one request recorded');
is($report->{totals}{input_tokens}, 120, 'input tokens aggregated');
is($report->{totals}{output_tokens}, 30, 'output tokens aggregated');
is($report->{totals}{tool_calls}, 1, 'tool calls aggregated');
ok(($report->{totals}{total_cost_usd} // 0) >= 0, 'cost present');
is($report->{by_key}[0]{api_key_id}, 'k_demo', 'grouped by key');
is($report->{by_model}[0]{model}, 'qwen2.5-7b-instruct', 'grouped by model');
is(scalar(@{$report->{recent}}), 1, 'recent rows returned');

ok(-f $skeid->_schema_file_for_backend('sqlite'), 'sqlite schema file exists');
ok(-f $skeid->_schema_file_for_backend('postgresql'), 'postgresql schema file exists');

done_testing;
